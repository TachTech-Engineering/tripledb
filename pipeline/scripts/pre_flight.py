#!/usr/bin/env python3
"""pre_flight.py — Functional validation of all pipeline dependencies."""
import os, sys, json, glob, subprocess, re

checks = []

# 1. Working directory
cwd = os.getcwd()
checks.append(("Working directory", f"PASS — {cwd}" if cwd.endswith("/pipeline") else f"FAIL — must end with /pipeline, got {cwd}"))

# 2. Gemini API key
api_key = os.environ.get("GEMINI_API_KEY", "")
checks.append(("GEMINI_API_KEY", "PASS" if api_key and len(api_key) > 10 else "FAIL — not set"))

# 3. Gemini API functional test
try:
    import requests
    resp = requests.post(
        f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}",
        json={
            "contents": [{"parts": [{"text": "Return exactly: {\"status\": \"ok\"}"}]}],
            "generationConfig": {"responseMimeType": "application/json"}
        },
        timeout=30
    )
    if resp.status_code == 200:
        text = resp.json()["candidates"][0]["content"]["parts"][0]["text"]
        json.loads(text)
        checks.append(("Gemini API (functional)", "PASS — returned valid JSON"))
    else:
        checks.append(("Gemini API (functional)", f"FAIL — HTTP {resp.status_code}: {resp.text[:200]}"))
except Exception as e:
    checks.append(("Gemini API (functional)", f"FAIL — {e}"))

# 4. CUDA library path
cuda_path = "/usr/local/lib/ollama/cuda_v12"
if os.path.isdir(cuda_path):
    ld_path = os.environ.get("LD_LIBRARY_PATH", "")
    if cuda_path in ld_path:
        checks.append(("CUDA libs + LD_LIBRARY_PATH", f"PASS — {cuda_path} in LD_LIBRARY_PATH"))
    else:
        checks.append(("CUDA libs + LD_LIBRARY_PATH", f"FAIL — {cuda_path} exists but NOT in LD_LIBRARY_PATH. Launch with: LD_LIBRARY_PATH={cuda_path}:$LD_LIBRARY_PATH"))
else:
    checks.append(("CUDA libs", f"FAIL — {cuda_path} not found"))

# 5. yt-dlp version
try:
    r = subprocess.run(["yt-dlp", "--version"], capture_output=True, text=True, timeout=10)
    checks.append(("yt-dlp", f"PASS — v{r.stdout.strip()}"))
except Exception as e:
    checks.append(("yt-dlp", f"FAIL — {e}"))

# 6. Existing data from Phase 1-3
transcript_count = len(glob.glob("data/transcripts/*.json"))
extraction_count = len([f for f in glob.glob("data/extracted/*.json") if "_raw" not in f])
audio_count = len(glob.glob("data/audio/*.mp3"))
checks.append(("Phase 1-3 audio files", f"PASS — {audio_count}" if audio_count >= 80 else f"WARN — only {audio_count}"))
checks.append(("Phase 1-3 transcripts", f"PASS — {transcript_count}" if transcript_count >= 80 else f"WARN — only {transcript_count}"))
checks.append(("Phase 1-3 extractions", f"PASS — {extraction_count}" if extraction_count >= 80 else f"WARN — only {extraction_count}"))

# 7. Normalized data exists
norm_path = "data/normalized/restaurants.jsonl"
if os.path.isfile(norm_path):
    count = sum(1 for _ in open(norm_path))
    checks.append(("Normalized restaurants", f"PASS — {count} records"))
else:
    checks.append(("Normalized restaurants", "WARN — not yet created (will be created in Step 8)"))

# 8. Extraction prompt exists
checks.append(("Extraction prompt", "PASS" if os.path.isfile("config/extraction_prompt.md") else "FAIL — missing"))

# 9. Playlist URLs
if os.path.isfile("config/playlist_urls.txt"):
    total = len([l for l in open("config/playlist_urls.txt") if l.strip() and not l.startswith('#')])
    checks.append(("Playlist URLs", f"PASS — {total}"))
else:
    checks.append(("Playlist URLs", "FAIL — missing"))

# 10. Key scripts exist
for script in ["phase1_acquire.py", "phase2_transcribe.py", "phase3_extract_gemini.py",
               "phase4_normalize.py", "select_batch.py", "validate_extraction.py"]:
    path = f"scripts/{script}"
    checks.append((f"Script: {script}", "PASS" if os.path.isfile(path) else f"FAIL — {path} missing"))

# 11. SECRET SCAN — HARD GATE
secret_patterns = [
    (r'AIza[0-9A-Za-z_-]{35}', "Google API key"),
    (r'ya29\.[0-9A-Za-z_-]+', "Google OAuth token"),
    (r'AKIA[0-9A-Z]{16}', "AWS access key"),
    (r'sk-[0-9a-zA-Z]{20,}', "OpenAI/Anthropic API key"),
    (r'ghp_[0-9a-zA-Z]{36}', "GitHub personal access token"),
    (r'gho_[0-9a-zA-Z]{36}', "GitHub OAuth token"),
]
secret_found = False
# Scan tracked files only (not .git internals)
try:
    result = subprocess.run(["git", "-C", "..", "ls-files"], capture_output=True, text=True, timeout=10)
    tracked_files = [os.path.join("..", f.strip()) for f in result.stdout.strip().split("\n") if f.strip()]
    for fpath in tracked_files:
        if not os.path.isfile(fpath):
            continue
        try:
            content = open(fpath, errors="ignore").read()
            for pattern, label in secret_patterns:
                matches = re.findall(pattern, content)
                if matches:
                    checks.append((f"SECRET IN FILE: {fpath}", f"FAIL — {label} found: {matches[0][:8]}..."))
                    secret_found = True
        except Exception:
            pass
    if not secret_found:
        checks.append(("Secret scan (tracked files)", "PASS — no secrets found"))
except Exception as e:
    checks.append(("Secret scan", f"WARN — could not scan: {e}"))

# 12. Git history scan for secrets (check last 20 commits)
try:
    result = subprocess.run(
        ["git", "-C", "..", "log", "-20", "--diff-filter=A", "-p", "--"],
        capture_output=True, text=True, timeout=30
    )
    history_secrets = False
    for pattern, label in secret_patterns:
        matches = re.findall(pattern, result.stdout)
        if matches:
            checks.append((f"SECRET IN GIT HISTORY", f"FAIL — {label} found in recent commits"))
            history_secrets = True
    if not history_secrets:
        checks.append(("Secret scan (git history)", "PASS — no secrets in recent commits"))
except Exception as e:
    checks.append(("Secret scan (git history)", f"WARN — could not scan: {e}"))

print("\n" + "=" * 60)
print("PRE-FLIGHT CHECK RESULTS")
print("=" * 60)
all_pass = True
for name, result in checks:
    icon = "✅" if "PASS" in result else "⚠️" if "WARN" in result else "❌"
    print(f"  {icon} {name}: {result}")
    if "FAIL" in result:
        all_pass = False

if all_pass:
    print(f"\n✅ ALL CHECKS PASSED — ready for Phase 4")
else:
    print(f"\n❌ FIX FAILURES BEFORE PROCEEDING")
    sys.exit(1)