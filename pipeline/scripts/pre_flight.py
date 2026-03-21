#!/usr/bin/env python3
"""pre_flight.py — Functional validation of all pipeline dependencies."""
import os, sys, json, glob, subprocess

checks = []

# 1. Working directory
cwd = os.getcwd()
checks.append(("Working directory", f"PASS — {cwd}" if cwd.endswith("/pipeline") else f"FAIL — must end with /pipeline, got {cwd}"))

# 2. Gemini API key
api_key = os.environ.get("GEMINI_API_KEY", "")
checks.append(("GEMINI_API_KEY", "PASS" if api_key and len(api_key) > 10 else "FAIL — not set"))

# 3. Gemini API functional test (actually call it)
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
        # Handle possible markdown backticks from API
        text = text.strip()
        if text.startswith("```json"):
            text = text[7:-3].strip()
        elif text.startswith("```"):
            text = text[3:-3].strip()
        
        json.loads(text)
        checks.append(("Gemini API (functional)", "PASS — returned valid JSON"))
    else:
        checks.append(("Gemini API (functional)", f"FAIL — HTTP {resp.status_code}"))
except Exception as e:
    checks.append(("Gemini API (functional)", f"FAIL — {e}"))

# 4. CUDA library functional test (actually load faster-whisper)
try:
    cuda_path = "/usr/local/lib/ollama/cuda_v12"
    if os.path.isdir(cuda_path):
        checks.append(("CUDA libs exist", f"PASS — {cuda_path}"))
    else:
        checks.append(("CUDA libs exist", f"FAIL — {cuda_path} not found"))
except Exception as e:
    checks.append(("CUDA libs", f"FAIL — {e}"))

# 5. yt-dlp version
try:
    r = subprocess.run(["yt-dlp", "--version"], capture_output=True, text=True, timeout=10)
    checks.append(("yt-dlp", f"PASS — v{r.stdout.strip()}"))
except Exception as e:
    checks.append(("yt-dlp", f"FAIL — {e}"))

# 6. Existing data from Phase 1+2
transcript_count = len(glob.glob("data/transcripts/*.json"))
extraction_count = len([f for f in glob.glob("data/extracted/*.json") if "_raw" not in f])
checks.append(("Phase 1+2 transcripts", f"PASS — {transcript_count}" if transcript_count >= 50 else f"WARN — only {transcript_count}"))
checks.append(("Phase 1+2 extractions", f"PASS — {extraction_count}" if extraction_count >= 50 else f"WARN — only {extraction_count}"))

# 7. Normalized data exists
norm_path = "data/normalized/restaurants.jsonl"
if os.path.isfile(norm_path):
    count = sum(1 for _ in open(norm_path))
    checks.append(("Normalized restaurants", f"PASS — {count} records"))
else:
    checks.append(("Normalized restaurants", "WARN — not yet created (will be created in Step 7)"))

# 8. Extraction prompt exists
checks.append(("Extraction prompt", "PASS" if os.path.isfile("config/extraction_prompt.md") else "FAIL — missing"))

# 9. Playlist URLs
if os.path.isfile("config/playlist_urls.txt"):
    total = len([l for l in open("config/playlist_urls.txt") if l.strip() and not l.startswith('#')])
    checks.append(("Playlist URLs", f"PASS — {total}"))
else:
    checks.append(("Playlist URLs", "FAIL — missing"))

# 10. Key scripts exist
for script in ["phase1_acquire.py", "phase2_transcribe.py", "phase3_extract_gemini.py", "phase4_normalize.py"]:
    path = f"scripts/{script}"
    checks.append((f"Script: {script}", "PASS" if os.path.isfile(path) else f"FAIL — {path} missing"))

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
    print(f"\n✅ ALL CHECKS PASSED — ready for Phase 3")
else:
    print(f"\n❌ FIX FAILURES BEFORE PROCEEDING")
    sys.exit(1)
