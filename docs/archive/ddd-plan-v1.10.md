# TripleDB — Phase 1 Plan v1.10

**Phase:** 1 — Discovery (third attempt)
**Iteration:** 10 (global project iteration)
**Date:** March 21, 2026
**Machine:** NZXTcos — i9-13900K, 64GB DDR4, RTX 2080 SUPER (8GB VRAM), CachyOS
**Goal:** Extract structured restaurant data from 30 transcripts using Gemini Flash API instead of local Ollama. Downloads and transcription are already complete (30/30).

---

## What Changed From v1.9

Local inference on 8GB VRAM failed across two iterations. The qwen3.5:9b model ran at 27%/73% CPU/GPU split, causing 5-10 minute inference times per clip and consistent timeouts on longer videos. Even after reducing context to 4096, slimming the prompt, and chunking transcripts, only 1 partial JSON was produced across two full attempts.

**v1.10 moves extraction to the Gemini Flash API.** Everything else stays local:

| Component | Where | Why |
|-----------|-------|-----|
| yt-dlp (download) | Local | Already working, 30/30 |
| faster-whisper (transcription) | Local CUDA | Already working, 30/30 |
| **Extraction** | **Gemini Flash API** | **1M context, no chunking, ~5-10s per video, free tier** |
| Normalization (Phase 4) | Local Ollama | Small inputs, qwen3.5:9b handles fine |
| Enrichment (Phase 5) | Firecrawl + Playwright MCP | Per-restaurant web lookup |

**Gemini Flash free tier limits:**
- 15 requests per minute
- 1,000,000 tokens per minute
- 1,500 requests per day

30 videos at ~15 RPM = ~2 minutes total API time. Even the full 804-video run fits within daily limits across ~1 hour.

---

## AUTONOMY RULES

```
1. AUTO-PROCEED between steps. Do NOT ask permission.
2. SELF-HEAL: diagnose, fix, re-run (max 3 attempts, then log and skip).
3. Run scripts in FOREGROUND. No background processes.
4. Generate docs/ddd-report-v1.10.md and docs/ddd-build-v1.10.md when done.
5. Do NOT run git commit, git push, or firebase deploy.
```

---

## Step 0: Pre-Flight Checks

Create `scripts/pre_flight.py` and run it:

```python
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
        f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={api_key}",
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
```

**If GEMINI_API_KEY fails:** The key should already be in fish config. Verify:

```bash
echo $GEMINI_API_KEY
```

If empty, add it: `set -x GEMINI_API_KEY "your-key-here"` or check `~/.config/fish/config.fish`.

---

## Step 1: Update the Extraction Prompt

**Replace** `config/extraction_prompt.md` with the FULL prompt including few-shot examples. With Gemini Flash's 1M context window, we have unlimited budget — no need to slim anything.

```markdown
# DDD Video Extraction — System Prompt

You are a structured data extraction agent. Read a transcript from a
"Diners, Drive-Ins and Dives" video and extract all restaurant visits
into structured JSON.

## Show Format

- Host: Guy Fieri
- Each restaurant segment: Guy drives up (guy_intro), enters kitchen,
  chef/owner demonstrates dishes (with ingredients), Guy tastes and
  reacts (guy_response)
- Videos range from 10-minute single-restaurant clips to 4-hour marathons
- Standard episodes have 2-3 restaurants, compilations have 3-8,
  marathons have 10-30+

## Output Schema

Return ONLY a JSON object with this exact structure. No markdown, no
explanation, no preamble.

{
  "video_id": "<provided in user message>",
  "video_title": "<provided in user message>",
  "video_type": "<full_episode|compilation|clip|marathon>",
  "restaurants": [
    {
      "name": "<restaurant name>",
      "city": "<city>",
      "state": "<full state name or abbreviation>",
      "cuisine_type": "<primary cuisine category>",
      "owner_chef": "<primary person Guy interacts with in the kitchen>",
      "guy_intro": "<Guy's introduction when arriving at the restaurant>",
      "segment_number": 1,
      "timestamp_start": 0.0,
      "timestamp_end": 0.0,
      "dishes": [
        {
          "dish_name": "<name of the dish>",
          "description": "<preparation method and key details>",
          "ingredients": ["ingredient1", "ingredient2"],
          "dish_category": "<appetizer|entree|dessert|side|drink|snack>",
          "guy_response": "<Guy's reaction after tasting>",
          "timestamp_start": 0.0,
          "confidence": 0.9
        }
      ],
      "confidence": 0.9
    }
  ]
}

## Extraction Rules

1. Extract EVERY restaurant Guy physically visits. Do NOT extract restaurants merely mentioned.
2. Every restaurant MUST have: name, city, state, at least one dish.
3. For guy_intro: capture what Guy says when he first approaches the restaurant.
4. For owner_chef: the primary person Guy interacts with in the kitchen. For pairs: "Mike and Lisa Rodriguez".
5. For ingredients: extract 3-8 KEY ingredients per dish. Focus on what makes it distinctive. Lowercase.
6. For dish_category: appetizer, entree, dessert, side, drink, or snack.
7. For guy_response: capture Guy's reaction AFTER tasting each dish — verbatim from transcript. Include catchphrases and genuine reactions. Set null only if Guy doesn't taste on camera.
8. For video_type: full_episode (~22 min, 2-3 restaurants), compilation ("Best of" themed), clip (<15 min, 1 restaurant), marathon (1+ hr, many restaurants).
9. Confidence: 0.9-1.0 = clearly stated. 0.7-0.89 = reasonably clear. 0.5-0.69 = inferred. <0.5 = best guess.
10. Segment timestamps: look for transitions ("Next up...", "Our next stop...").

## Example 1: Standard Episode Segment

Transcript excerpt:
[45.2s] We're rolling out to Johnny's Italian Kitchen in Baltimore, Maryland.
[52.1s] Owner Johnny Russo has been making handmade pasta for 30 years.
[120.3s] This is their famous crab ravioli with a brown butter sage sauce.
[145.8s] Oh my God, that is DYNAMITE!

Expected output for this segment:
{
  "name": "Johnny's Italian Kitchen",
  "city": "Baltimore",
  "state": "Maryland",
  "cuisine_type": "Italian",
  "owner_chef": "Johnny Russo",
  "guy_intro": "We're rolling out to Johnny's Italian Kitchen in Baltimore, Maryland, where owner Johnny Russo has been making handmade pasta for 30 years.",
  "segment_number": 1,
  "timestamp_start": 45.2,
  "timestamp_end": null,
  "dishes": [
    {
      "dish_name": "Crab Ravioli with Brown Butter Sage Sauce",
      "description": "Handmade ravioli stuffed with crab meat, served with brown butter and sage sauce",
      "ingredients": ["crab meat", "pasta dough", "brown butter", "sage", "parmesan"],
      "dish_category": "entree",
      "guy_response": "Oh my God, that is DYNAMITE!",
      "timestamp_start": 120.3,
      "confidence": 0.95
    }
  ],
  "confidence": 0.97
}

## Example 2: Multiple Dishes Per Restaurant

{
  "name": "Mama's Soul Food",
  "city": "Memphis",
  "state": "Tennessee",
  "cuisine_type": "Soul Food",
  "owner_chef": "Tyrone Washington",
  "guy_intro": "Here at Mama's Soul Food in Memphis, Tennessee, Chef Tyrone Washington has been serving up the real deal for over twenty years.",
  "segment_number": 1,
  "timestamp_start": 200.0,
  "timestamp_end": null,
  "dishes": [
    {
      "dish_name": "Famous Fried Chicken",
      "description": "Brined overnight in buttermilk, double-dredged in seasoned flour, deep fried",
      "ingredients": ["chicken", "buttermilk", "seasoned flour", "cayenne pepper"],
      "dish_category": "entree",
      "guy_response": "Now THAT is what I'm talking about!",
      "timestamp_start": 215.5,
      "confidence": 0.95
    },
    {
      "dish_name": "Peach Cobbler",
      "description": "Peach cobbler with butter crust, cinnamon, and brown sugar",
      "ingredients": ["peaches", "butter", "cinnamon", "brown sugar", "pie crust"],
      "dish_category": "dessert",
      "guy_response": "That is OUT OF BOUNDS!",
      "timestamp_start": 280.0,
      "confidence": 0.95
    }
  ],
  "confidence": 0.96
}

## Important

- Return ONLY the JSON object. No markdown, no explanations, no preamble.
- If the transcript contains no restaurant visits, return:
  {"video_id": "...", "video_title": "...", "video_type": "...", "restaurants": []}
```

---

## Step 2: Create the Gemini Flash Extraction Script

Create `scripts/phase3_extract_gemini.py`:

```python
#!/usr/bin/env python3
"""
phase3_extract_gemini.py — Extract restaurant data using Gemini Flash API.
No chunking needed — 1M token context handles any transcript in a single call.
"""
import os
import sys
import json
import time
import argparse
import re
import requests
from pathlib import Path

# ── Configuration ────────────────────────────────────────────────────
API_KEY = os.environ.get("GEMINI_API_KEY", "")
API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={API_KEY}"
RATE_LIMIT_DELAY = 4.5        # seconds between requests (stay under 15 RPM)
TIMEOUT = 120                 # 2 minutes per request (generous for cloud API)
MAX_RETRIES = 2

DATA_DIR = Path("data")
EXTRACTED_DIR = DATA_DIR / "extracted"
TRANSCRIPT_DIR = DATA_DIR / "transcripts"
AUDIO_DIR = DATA_DIR / "audio"
LOG_DIR = DATA_DIR / "logs"
PROMPT_PATH = Path("config/extraction_prompt.md")

# ── Helpers ──────────────────────────────────────────────────────────
def load_extraction_prompt():
    with open(PROMPT_PATH) as f:
        return f.read()

def get_video_title(video_id):
    info_path = AUDIO_DIR / f"{video_id}.info.json"
    if info_path.exists():
        try:
            with open(info_path) as f:
                info = json.load(f)
            return info.get("title", video_id)
        except (json.JSONDecodeError, KeyError):
            pass
    return video_id

def get_video_ids_from_batch(batch_file):
    ids = []
    with open(batch_file) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            match = re.search(r'[?&]v=([a-zA-Z0-9_-]{11})', line)
            if match:
                ids.append(match.group(1))
            else:
                clean = line.split('#')[0].strip()
                if len(clean) == 11:
                    ids.append(clean)
    return ids

def load_transcript(video_id):
    path = TRANSCRIPT_DIR / f"{video_id}.json"
    if not path.exists():
        return None, 0
    with open(path) as f:
        data = json.load(f)
    segments = data.get("segments", [])
    lines = []
    for seg in segments:
        start = seg.get("start", 0)
        text = seg.get("text", "").strip()
        if text:
            lines.append(f"[{start:.1f}s] {text}")
    return "\n".join(lines), data.get("duration_seconds", 0)

def call_gemini(system_prompt, user_content):
    """Call Gemini Flash API with JSON output mode."""
    payload = {
        "contents": [
            {
                "parts": [
                    {"text": f"{system_prompt}\n\n---\n\n{user_content}"}
                ]
            }
        ],
        "generationConfig": {
            "responseMimeType": "application/json",
            "temperature": 0.1
        }
    }

    resp = requests.post(API_URL, json=payload, timeout=TIMEOUT)

    if resp.status_code == 429:
        # Rate limited — wait and retry
        print(" RATE LIMITED — waiting 60s...", end="", flush=True)
        time.sleep(60)
        resp = requests.post(API_URL, json=payload, timeout=TIMEOUT)

    if resp.status_code != 200:
        raise Exception(f"API error {resp.status_code}: {resp.text[:300]}")

    data = resp.json()

    # Extract text from Gemini response
    try:
        text = data["candidates"][0]["content"]["parts"][0]["text"]
    except (KeyError, IndexError) as e:
        raise Exception(f"Unexpected response structure: {e}")

    return text

def parse_json_response(raw_text):
    # Direct parse
    try:
        return json.loads(raw_text)
    except json.JSONDecodeError:
        pass

    # Extract from markdown code blocks
    match = re.search(r'```(?:json)?\s*\n?(.*?)\n?```', raw_text, re.DOTALL)
    if match:
        try:
            return json.loads(match.group(1))
        except json.JSONDecodeError:
            pass

    # Find first { ... } block
    start = raw_text.find('{')
    end = raw_text.rfind('}')
    if start != -1 and end != -1 and end > start:
        try:
            return json.loads(raw_text[start:end+1])
        except json.JSONDecodeError:
            pass

    return None

def log_error(video_id, error_msg):
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    with open(LOG_DIR / "phase-3-errors.jsonl", "a") as f:
        f.write(json.dumps({"timestamp": time.time(), "video_id": video_id, "error": error_msg}) + "\n")
        f.flush()

def classify_video_type(duration):
    if duration < 900:
        return "clip"
    elif duration < 1500:
        return "full_episode"
    elif duration < 3600:
        return "compilation"
    else:
        return "marathon"

# ── Main extraction ──────────────────────────────────────────────────
def extract_video(video_id, system_prompt):
    output_path = EXTRACTED_DIR / f"{video_id}.json"

    # Resume: skip if valid output with restaurants exists
    if output_path.exists():
        try:
            with open(output_path) as f:
                existing = json.load(f)
            if existing.get("restaurants"):
                print(f"  Skipping — already extracted ({len(existing['restaurants'])} restaurants)")
                return existing, "skipped"
        except (json.JSONDecodeError, KeyError):
            pass

    full_text, duration = load_transcript(video_id)
    if full_text is None:
        log_error(video_id, "Transcript not found")
        return None, "no_transcript"

    title = get_video_title(video_id)
    vtype = classify_video_type(duration)

    print(f"  {title}")
    print(f"  Type: {vtype} | Duration: {duration:.0f}s | Transcript: {len(full_text)} chars")

    user_content = (
        f"Video ID: {video_id}\n"
        f"Video Title: {title}\n"
        f"Duration: {duration:.0f} seconds\n\n"
        f"Transcript:\n{full_text}"
    )

    for attempt in range(MAX_RETRIES + 1):
        try:
            print(f"  Calling Gemini Flash (attempt {attempt+1})...", end="", flush=True)
            start_time = time.time()
            raw = call_gemini(system_prompt, user_content)
            elapsed = time.time() - start_time
            print(f" done [{elapsed:.1f}s]")

            parsed = parse_json_response(raw)
            if parsed is None:
                # Save raw for debugging
                raw_path = EXTRACTED_DIR / f"{video_id}_raw.txt"
                with open(raw_path, "w") as f:
                    f.write(raw)
                log_error(video_id, f"JSON parse failed (attempt {attempt+1})")
                if attempt < MAX_RETRIES:
                    continue
                return None, "parse_error"

            # Ensure required fields
            if "restaurants" not in parsed:
                parsed["restaurants"] = []
            parsed["video_id"] = video_id
            parsed["video_title"] = title
            if not parsed.get("video_type"):
                parsed["video_type"] = vtype

            with open(output_path, "w") as f:
                json.dump(parsed, f, indent=2)

            r_count = len(parsed["restaurants"])
            d_count = sum(len(r.get("dishes", [])) for r in parsed["restaurants"])
            return parsed, "success" if r_count > 0 else "empty"

        except Exception as e:
            print(f" ERROR: {e}")
            log_error(video_id, f"Attempt {attempt+1}: {str(e)}")
            if attempt < MAX_RETRIES:
                time.sleep(5)
                continue
            return None, "failed"

    return None, "failed"

# ── Main ─────────────────────────────────────────────────────────────
def main():
    if not API_KEY:
        print("❌ GEMINI_API_KEY not set. Add it to your environment.")
        sys.exit(1)

    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--batch", help="File with video URLs")
    group.add_argument("--all", action="store_true", help="Process all transcripts")
    group.add_argument("--video", help="Single video ID")
    args = parser.parse_args()

    EXTRACTED_DIR.mkdir(parents=True, exist_ok=True)
    LOG_DIR.mkdir(parents=True, exist_ok=True)

    system_prompt = load_extraction_prompt()
    print(f"Extraction prompt: {len(system_prompt)} chars (~{len(system_prompt)//4} tokens)")

    if args.video:
        video_ids = [args.video]
    elif args.batch:
        video_ids = get_video_ids_from_batch(args.batch)
    else:
        video_ids = sorted([f.stem for f in TRANSCRIPT_DIR.glob("*.json")])

    print(f"Videos to process: {len(video_ids)}")
    print(f"Backend: Gemini 2.0 Flash API")
    print(f"Rate limit: 1 request per {RATE_LIMIT_DELAY}s")
    print()

    stats = {"total": len(video_ids), "success": 0, "empty": 0, "failed": 0,
             "skipped": 0, "no_transcript": 0, "parse_error": 0,
             "total_restaurants": 0, "total_dishes": 0}

    for i, vid in enumerate(video_ids):
        print(f"[{i+1}/{len(video_ids)}] {vid}")
        result, status = extract_video(vid, system_prompt)
        stats[status] = stats.get(status, 0) + 1

        if result and result.get("restaurants"):
            r_count = len(result["restaurants"])
            d_count = sum(len(r.get("dishes", [])) for r in result["restaurants"])
            stats["total_restaurants"] += r_count
            stats["total_dishes"] += d_count
            print(f"  ✅ {r_count} restaurants, {d_count} dishes")
        elif status == "skipped":
            pass
        else:
            print(f"  ⚠️ {status}")

        # Rate limit (skip delay for skipped videos)
        if status != "skipped" and i < len(video_ids) - 1:
            time.sleep(RATE_LIMIT_DELAY)

        print()

    print("=" * 60)
    print("EXTRACTION SUMMARY")
    print("=" * 60)
    print(f"  Total videos:      {stats['total']}")
    print(f"  Successful:        {stats['success']}")
    print(f"  Empty (no data):   {stats['empty']}")
    print(f"  Failed:            {stats['failed']}")
    print(f"  Parse errors:      {stats['parse_error']}")
    print(f"  Skipped (resume):  {stats['skipped']}")
    print(f"  No transcript:     {stats['no_transcript']}")
    print(f"  Total restaurants: {stats['total_restaurants']}")
    print(f"  Total dishes:      {stats['total_dishes']}")
    print(f"  Avg dishes/rest:   {stats['total_dishes']/max(stats['total_restaurants'],1):.1f}")
    print("=" * 60)

if __name__ == "__main__":
    main()
```

---

## Step 3: Clear Previous Artifacts and Run

```bash
# Clear v1.8 and v1.9 extraction debris
rm -f data/extracted/*.json data/extracted/*_raw.txt
rm -f data/logs/phase-3-errors.jsonl

# Verify API key is set
echo $GEMINI_API_KEY

# Run pre-flight
python3 scripts/pre_flight.py

# Test on single shortest clip first
python3 scripts/phase3_extract_gemini.py --video BwfqvpCAdeQ
```

If the single video produces a JSON with restaurants, immediately run the full batch:

```bash
python3 scripts/phase3_extract_gemini.py --batch config/test_batch.txt
```

**Expected: all 30 videos extracted in ~5-10 minutes total.**

---

## Step 4: Validate Extraction Quality

Create `scripts/validate_extraction.py`:

```python
#!/usr/bin/env python3
"""validate_extraction.py — Check extraction quality."""
import json, glob, os

print("=== EXTRACTION VALIDATION ===\n")

files = sorted([f for f in glob.glob("data/extracted/*.json") if "_raw" not in f])
print(f"Extracted files: {len(files)}\n")

total_r, total_d = 0, 0
empty_videos = []
video_types = {}
guy_intro_count, guy_response_count = 0, 0
ingredient_count, total_dishes_checked = 0, 0

for f in files:
    with open(f) as fh:
        data = json.load(fh)

    vid = data.get("video_id", os.path.basename(f).replace(".json", ""))
    vtype = data.get("video_type", "unknown")
    restaurants = data.get("restaurants", [])
    video_types[vtype] = video_types.get(vtype, 0) + 1

    if not restaurants:
        empty_videos.append(vid)
        continue

    r_count = len(restaurants)
    d_count = 0
    for r in restaurants:
        if r.get("guy_intro"):
            guy_intro_count += 1
        for d in r.get("dishes", []):
            d_count += 1
            total_dishes_checked += 1
            if d.get("guy_response"):
                guy_response_count += 1
            if d.get("ingredients") and len(d["ingredients"]) > 0:
                ingredient_count += 1

    total_r += r_count
    total_d += d_count
    print(f"  {vid}: {vtype} | {r_count} restaurants, {d_count} dishes")

print(f"\n{'='*50}")
print(f"TOTALS")
print(f"{'='*50}")
print(f"  Videos with JSON:    {len(files)}")
print(f"  Videos with data:    {len(files) - len(empty_videos)}")
print(f"  Videos empty:        {len(empty_videos)}")
print(f"  Total restaurants:   {total_r}")
print(f"  Total dishes:        {total_d}")
print(f"  Avg dishes/rest:     {total_d/max(total_r,1):.1f}")
print(f"  Video types:         {video_types}")
print(f"  guy_intro:           {guy_intro_count}/{total_r} ({guy_intro_count/max(total_r,1)*100:.0f}%)")
print(f"  guy_response:        {guy_response_count}/{total_d} ({guy_response_count/max(total_d,1)*100:.0f}%)")
print(f"  ingredients:         {ingredient_count}/{total_dishes_checked} ({ingredient_count/max(total_dishes_checked,1)*100:.0f}%)")

if empty_videos:
    print(f"\n  Empty: {', '.join(empty_videos)}")

print(f"\n{'='*50}")
print(f"SUCCESS CRITERIA")
print(f"{'='*50}")
criteria = [
    ("JSON files >= 28 (of 30)", len(files) >= 28),
    ("Videos with restaurants >= 25", (len(files) - len(empty_videos)) >= 25),
    ("Total restaurants >= 50", total_r >= 50),
    ("Total dishes >= 100", total_d >= 100),
    ("Avg dishes/restaurant >= 2.0", total_d/max(total_r,1) >= 2.0),
    ("guy_intro capture >= 50%", guy_intro_count/max(total_r,1) >= 0.5),
    ("guy_response capture >= 50%", guy_response_count/max(total_d,1) >= 0.5),
    ("ingredients capture >= 60%", ingredient_count/max(total_dishes_checked,1) >= 0.6),
]
all_pass = True
for name, passed in criteria:
    print(f"  {'✅' if passed else '❌'} {name}")
    if not passed:
        all_pass = False

print(f"\n{'✅ ALL CRITERIA MET — ready for Phase 2' if all_pass else '❌ SOME CRITERIA FAILED — review before Phase 2'}")
```

Run it:

```bash
python3 scripts/validate_extraction.py
```

---

## Step 5: Generate Report Artifacts

Create these two files:

**docs/ddd-report-v1.10.md** — metrics, issues, decisions, validation output

**docs/ddd-build-v1.10.md** — chronological log of every action taken

---

## Phase 1.10 Success Criteria

```
[ ] Pre-flight passes (API key works, transcripts exist)
[ ] Single video test produces valid JSON with restaurants
[ ] 28+ of 30 videos produce extracted JSON
[ ] 25+ videos contain at least 1 restaurant
[ ] Total restaurants >= 50
[ ] Total dishes >= 100
[ ] guy_intro capture >= 50%
[ ] guy_response capture >= 50%
[ ] ingredients capture >= 60%
[ ] No hangs (cloud API, no VRAM issues)
[ ] ddd-report-v1.10.md generated
[ ] ddd-build-v1.10.md generated
```

---

## Gemini CLI Opening Prompt

```bash
cd ~/dev/projects/tripledb/pipeline
gemini
```

```
Read GEMINI.md for project context.

We are starting Phase 1.10 — extraction using Gemini Flash API instead
of local Ollama. Downloads and transcription are done (30/30 videos).

Read ../docs/ddd-plan-v1.10.md for the complete plan. It contains:
- Autonomy rules (auto-proceed, self-heal, no permissions)
- Pre-flight script
- Full extraction prompt (with few-shot examples restored)
- Complete Gemini Flash extraction script
- Validation script
- Report templates

IMPORTANT CHANGES FROM v1.8 and v1.9:
- Extraction uses Gemini Flash API (cloud), NOT local Ollama
- Script is scripts/phase3_extract_gemini.py (NOT phase3_extract.py)
- No chunking needed — 1M context handles any transcript
- API key is in $GEMINI_API_KEY environment variable
- Rate limit: 4.5 seconds between requests

Execute Steps 0-5. Follow autonomy rules: auto-proceed, self-heal, 
no permission prompts. Generate report artifacts when done.

Begin with Step 0: create and run scripts/pre_flight.py.
```

---

## Architecture Decision Record

**Decision:** Move extraction from local Ollama to Gemini Flash API.

**Context:** RTX 2080 SUPER (8GB VRAM) cannot run structured extraction with any local model efficiently. Two iterations (v1.8, v1.9) failed despite reducing context, chunking transcripts, switching models, and slimming prompts. The hardware constraint is fundamental.

**Consequences:**
- Extraction now requires internet access
- Free tier sufficient for full 804-video run
- Extraction quality expected to improve (larger model, full context, few-shot examples)
- Pipeline diagram updated: Phase 3 uses cloud API, all other phases remain local
- For Phase 4 normalization, qwen3.5:9b on local Ollama remains viable because normalized inputs are small (<1000 tokens per record)

**Status:** Adopted for v1.10. Reversible if hardware is upgraded.
