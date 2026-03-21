#!/usr/bin/env python3
"""pre_flight.py — Validate environment before Phase 2."""
import os, sys, json, glob

checks = []

# 1. Working directory
cwd = os.getcwd()
if cwd.endswith("/pipeline"):
    checks.append(("Working directory", f"PASS — {cwd}"))
else:
    checks.append(("Working directory", f"FAIL — expected to end with /pipeline, got {cwd}"))

# 2. Gemini API key
api_key = os.environ.get("GEMINI_API_KEY", "")
if api_key and len(api_key) > 10:
    checks.append(("GEMINI_API_KEY", "PASS"))
else:
    checks.append(("GEMINI_API_KEY", "FAIL — not set"))

# 3. Gemini API reachable
try:
    import requests
    resp = requests.post(
        f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}",
        json={
            "contents": [{"parts": [{"text": "Reply with exactly: {\"status\": \"ok\"}"}]}],
            "generationConfig": {"responseMimeType": "application/json"}
        },
        timeout=30
    )
    if resp.status_code == 200:
        checks.append(("Gemini 2.5 Flash API", "PASS"))
    else:
        checks.append(("Gemini 2.5 Flash API", f"FAIL — HTTP {resp.status_code}"))
except Exception as e:
    checks.append(("Gemini 2.5 Flash API", f"FAIL — {e}"))

# 4. Phase 1 transcripts exist
transcript_count = len(glob.glob("data/transcripts/*.json"))
checks.append(("Phase 1 transcripts", f"PASS — {transcript_count} files" if transcript_count >= 28 else f"FAIL — only {transcript_count}"))

# 5. Phase 1 extractions exist
extraction_count = len([f for f in glob.glob("data/extracted/*.json") if "_raw" not in f])
checks.append(("Phase 1 extractions", f"PASS — {extraction_count} files" if extraction_count >= 25 else f"FAIL — only {extraction_count}"))

# 6. yt-dlp available
try:
    import subprocess
    r = subprocess.run(["yt-dlp", "--version"], capture_output=True, text=True, timeout=10)
    checks.append(("yt-dlp", f"PASS — v{r.stdout.strip()}"))
except Exception as e:
    checks.append(("yt-dlp", f"FAIL — {e}"))

# 7. faster-whisper available
try:
    os.environ.setdefault("LD_LIBRARY_PATH", "")
    if "/usr/local/lib/ollama/cuda_v12" not in os.environ["LD_LIBRARY_PATH"]:
        os.environ["LD_LIBRARY_PATH"] = "/usr/local/lib/ollama/cuda_v12:" + os.environ["LD_LIBRARY_PATH"]
    from faster_whisper import WhisperModel
    checks.append(("faster-whisper", "PASS"))
except Exception as e:
    checks.append(("faster-whisper", f"FAIL — {e}"))

# 8. Ollama available (for potential Phase 4 use)
try:
    r = subprocess.run(["ollama", "list"], capture_output=True, text=True, timeout=10)
    checks.append(("Ollama", f"PASS" if "qwen3.5" in r.stdout else "WARN — qwen3.5:9b not found"))
except Exception as e:
    checks.append(("Ollama", f"WARN — {e} (not critical for Phase 2)"))

# 9. GPU available
try:
    r = subprocess.run(["nvidia-smi", "--query-gpu=memory.free", "--format=csv,noheader,nounits"],
                       capture_output=True, text=True, timeout=10)
    free_mb = int(r.stdout.strip().split('\n')[0])
    checks.append(("GPU VRAM", f"PASS — {free_mb}MB free"))
except Exception as e:
    checks.append(("GPU", f"WARN — {e} (GPU needed for transcription only)"))

# 10. Playlist URLs exist
playlist_path = "config/playlist_urls.txt"
if os.path.isfile(playlist_path):
    total = len([l for l in open(playlist_path) if l.strip() and not l.startswith('#')])
    checks.append(("Playlist URLs", f"PASS — {total} total URLs"))
else:
    checks.append(("Playlist URLs", "FAIL — config/playlist_urls.txt missing"))

# 11. Extraction prompt exists
if os.path.isfile("config/extraction_prompt.md"):
    checks.append(("Extraction prompt", "PASS"))
else:
    checks.append(("Extraction prompt", "FAIL — config/extraction_prompt.md missing"))

print("\n=== PRE-FLIGHT CHECK RESULTS ===")
all_pass = True
for name, result in checks:
    icon = "✅" if "PASS" in result else "⚠️" if "WARN" in result else "❌"
    print(f"  {icon} {name}: {result}")
    if "FAIL" in result:
        all_pass = False

if all_pass:
    print("\n✅ ALL CHECKS PASSED — ready for Phase 2")
else:
    print("\n❌ FIX FAILURES BEFORE PROCEEDING")
    sys.exit(1)
