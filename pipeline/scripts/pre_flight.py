#!/usr/bin/env python3
"""pre_flight.py — Validate environment before extraction."""
import os, sys, json

checks = []

# 1. Gemini API key set?
api_key = os.environ.get("GEMINI_API_KEY", "")
if api_key and len(api_key) > 10:
    checks.append(("GEMINI_API_KEY", "PASS"))
else:
    checks.append(("GEMINI_API_KEY", "FAIL — not set or too short"))

# 2. Gemini API reachable?
try:
    import requests
    resp = requests.post(
        f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}",
        json={
            "contents": [{"parts": [{"text": "Reply with exactly: {\"test\": true}"}]}],
            "generationConfig": {"responseMimeType": "application/json"}
        },
        timeout=30
    )
    if resp.status_code == 200:
        data = resp.json()
        text = data["candidates"][0]["content"]["parts"][0]["text"]
        parsed = json.loads(text)
        checks.append(("Gemini Flash API", f"PASS — got valid JSON response"))
    else:
        checks.append(("Gemini Flash API", f"FAIL — HTTP {resp.status_code}: {resp.text[:200]}"))
except Exception as e:
    checks.append(("Gemini Flash API", f"FAIL — {e}"))

# 3. Transcripts exist?
transcript_dir = "data/transcripts"
if os.path.isdir(transcript_dir):
    count = len([f for f in os.listdir(transcript_dir) if f.endswith('.json')])
    checks.append(("Transcripts", f"PASS — {count} files"))
else:
    checks.append(("Transcripts", "FAIL — directory missing"))

# 4. Extraction prompt exists?
prompt_path = "config/extraction_prompt.md"
if os.path.isfile(prompt_path):
    size = os.path.getsize(prompt_path)
    checks.append(("Extraction prompt", f"PASS — {size} bytes"))
else:
    checks.append(("Extraction prompt", "FAIL — file missing"))

# 5. requests library available?
try:
    import requests
    checks.append(("requests library", "PASS"))
except ImportError:
    checks.append(("requests library", "FAIL — pip install requests --break-system-packages"))

# 6. Test batch exists?
batch_path = "config/test_batch.txt"
if os.path.isfile(batch_path):
    lines = [l for l in open(batch_path) if l.strip() and not l.startswith('#')]
    checks.append(("Test batch", f"PASS — {len(lines)} URLs"))
else:
    checks.append(("Test batch", "FAIL — file missing"))

print("\n=== PRE-FLIGHT CHECK RESULTS ===")
all_pass = True
for name, result in checks:
    icon = "✅" if "PASS" in result else "❌"
    print(f"  {icon} {name}: {result}")
    if "FAIL" in result:
        all_pass = False

if all_pass:
    print("\n✅ ALL CHECKS PASSED — ready to extract")
else:
    print("\n❌ FIX FAILURES BEFORE PROCEEDING")
    sys.exit(1)
