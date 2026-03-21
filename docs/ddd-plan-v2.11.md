# TripleDB — Phase 2 Plan v2.11

**Phase:** 2 — Calibration
**Iteration:** 11 (global project iteration)
**Date:** March 21, 2026
**Machine:** NZXTcos — i9-13900K (24-core), 64GB DDR4, RTX 2080 SUPER (8GB VRAM), CachyOS
**Goal:** Process the next 30 videos, refine extraction quality, and run normalization/dedup across all 60 videos to produce the first unified restaurant dataset.

---

## Project Context

**TripleDB** processes 805 YouTube videos from "Diners, Drive-Ins and Dives" (DDD) into a structured Firestore database of restaurants, dishes, and Guy Fieri moments. The pipeline runs in two groups:

- **Group A (Phases 1-4):** Iterative refinement with 30-video batches and human review
- **Group B (Phases 5-7):** Unattended production run of remaining ~685 videos with locked prompts

**Repository:** `git@github.com:TachTech-Engineering/tripledb.git`
**Firebase Project:** tripledb-e0f77
**Domain:** tripleDB.com
**Methodology:** IAO — Iterative Agentic Orchestration

---

## What's Been Accomplished

| Iteration | Result | Key Learnings |
|-----------|--------|---------------|
| v0.7 | ✅ Phase 0 complete | Monorepo scaffolded, 805 URLs dumped, tools installed |
| v1.8 | ❌ Extraction failed | Nemotron 42GB too large for 8GB VRAM. CPU inference = timeouts. yt-dlp needs `--remote-components ejs:github`. faster-whisper needs `LD_LIBRARY_PATH=/usr/local/lib/ollama/cuda_v12`. Launch Gemini from `pipeline/` not project root. |
| v1.9 | ❌ Extraction failed | qwen3.5:9b on 8GB VRAM: 27%/73% CPU/GPU split. Even 4K context too slow. Local 9B models can't do structured extraction on this hardware. |
| v1.10 | ✅ Phase 1 complete | **Gemini Flash API solved everything.** 27/30 successful, 186 restaurants, 290 dishes. 94% guy_intro, 100% guy_response, 100% ingredients. Model was `gemini-2.5-flash` (2.0 was deprecated). |

**Current state of `pipeline/data/`:**
- `audio/` — 30 mp3 files from test batch (gitignored)
- `transcripts/` — 30 JSON transcript files (gitignored)
- `extracted/` — 29 JSON extraction files (28 with data, 1 empty)
- `normalized/` — empty (Phase 2 will populate)
- `enriched/` — empty (Phase 5)

---

## Architectural Decisions (Locked)

These decisions were validated through v1.8-v1.10 and carry forward for all remaining phases:

| Component | Tool | Location | Notes |
|-----------|------|----------|-------|
| Download | yt-dlp | Local | Flags: `--remote-components ejs:github --cookies-from-browser chrome` |
| Transcription | faster-whisper large-v3 | Local CUDA | Requires: `LD_LIBRARY_PATH=/usr/local/lib/ollama/cuda_v12`. Stop Ollama before running. |
| Extraction | Gemini 2.5 Flash API | Cloud | Free tier. 1M context. No chunking needed. `$GEMINI_API_KEY` |
| Normalization | Gemini 2.5 Flash API | Cloud | Small inputs but dedup logic benefits from intelligence. Free tier. |
| Enrichment | Firecrawl + Playwright MCP | Cloud + Local | Phase 5 (deferred) |
| Database | Cloud Firestore | Cloud | Phase 6 (deferred) |
| Frontend | Flutter Web | Local dev | Phase 7 (deferred) |

**Why Gemini Flash for normalization too:** v1.8/v1.9 proved local Ollama is unreliable on 8GB VRAM for any structured output task. Normalization requires dedup intelligence (fuzzy name matching, merging dish lists). The free tier easily handles it. Keep the pipeline consistent — one extraction/normalization backend.

---

## Data Model (Firestore Target)

Two collections. Pipeline produces normalized JSONL that maps directly to these documents.

### Collection: `restaurants`

```json
{
  "restaurant_id": "r_<uuid4>",
  "name": "Mama's Soul Food",
  "city": "Memphis",
  "state": "TN",
  "address": null,
  "latitude": null,
  "longitude": null,
  "cuisine_type": "Soul Food",
  "owner_chef": "Tyrone Washington",
  "still_open": null,
  "google_rating": null,
  "yelp_rating": null,
  "website_url": null,
  "visits": [
    {
      "video_id": "Q2fk6b-hEbc",
      "youtube_url": "https://youtube.com/watch?v=Q2fk6b-hEbc",
      "video_title": "Top #DDD Videos in Memphis",
      "video_type": "compilation",
      "guy_intro": "Here at Mama's Soul Food in Memphis...",
      "timestamp_start": 200.0,
      "timestamp_end": 480.0
    }
  ],
  "dishes": [
    {
      "dish_name": "Famous Fried Chicken",
      "description": "Brined overnight in buttermilk, double-dredged",
      "ingredients": ["chicken", "buttermilk", "seasoned flour", "cayenne pepper"],
      "dish_category": "entree",
      "guy_response": "Now THAT is what I'm talking about!",
      "video_id": "Q2fk6b-hEbc",
      "timestamp_start": 215.5
    }
  ],
  "created_at": "<timestamp>",
  "updated_at": "<timestamp>"
}
```

### Collection: `videos`

```json
{
  "video_id": "Q2fk6b-hEbc",
  "youtube_url": "https://youtube.com/watch?v=Q2fk6b-hEbc",
  "title": "Top #DDD Videos in Memphis",
  "duration_seconds": 1619,
  "video_type": "compilation",
  "restaurant_count": 5,
  "processed_at": "<timestamp>"
}
```

### Video Types

| video_type | Duration | Description |
|------------|----------|-------------|
| `clip` | <15 min | Single restaurant segment |
| `full_episode` | 15-25 min | Standard DDD episode, 2-3 restaurants |
| `compilation` | 25-60 min | "Best of" city/theme, 3-8 restaurants |
| `marathon` | >60 min | Multi-hour compilations, 10-30+ restaurants |

---

## Known Issues From v1.10 (Fixes in This Plan)

### Issue 1: `owner_chef` sometimes null or "Chef"

In the Seafood compilation (`_GwN6SiRpzE.json`), The Lobster Shanty has `owner_chef: null`. In BwfqvpCAdeQ, Crush Craft has `owner_chef: "Chef"`. The extraction prompt didn't emphasize that a real name should always be attempted.

**Fix:** Updated extraction prompt Rule 4 to explicitly instruct: "If the name is unclear, use the best guess from the transcript. Never return just 'Chef' — include a first or last name if mentioned anywhere in the segment."

### Issue 2: `Dcfs_wKVi9A` empty extraction

The Biscuits & Gravy Portland clip extracted zero restaurants despite being a real DDD segment. Likely the transcript didn't contain enough identifying markers or the model missed it.

**Fix:** Re-extract this video in the Phase 2 batch (it's already transcribed). If still empty after re-extraction, inspect the transcript manually.

### Issue 3: `bawGcAsAA-w` timeout (4-hour marathon)

At 350K chars (~87K tokens), even Gemini Flash timed out at 120 seconds across 3 attempts.

**Fix:** Increase `TIMEOUT` to 300 seconds for the Phase 2 script. For Group B, implement duration-based timeout scaling: 120s for clips, 180s for episodes, 240s for compilations, 600s for marathons.

### Issue 4: `avg dishes/restaurant = 1.6` (want ≥ 2.0)

Many restaurants extracted with only 1 dish. Some DDD segments genuinely feature only 1 dish, but others have 2-3 that were missed.

**Fix:** Updated extraction prompt Rule 1 to add: "Most DDD segments feature 2-4 dishes. If you only find 1, re-scan the transcript for additional dishes the chef demonstrated."

---

## AUTONOMY RULES

```
1. AUTO-PROCEED between steps. Do NOT ask Kyle's permission.
2. SELF-HEAL errors: diagnose → fix → re-run (max 3 attempts, then log and skip).
3. Run ALL scripts in FOREGROUND. No background processes.
4. TIMEOUT DISCIPLINE: kill operations exceeding specified timeouts.
5. When all steps complete, generate:
   - docs/ddd-report-v2.11.md (metrics, validation, decisions)
   - docs/ddd-build-v2.11.md (chronological session transcript)
6. Do NOT run git commit, git push, or firebase deploy.
7. All scripts run from ~/dev/projects/tripledb/pipeline/ as working directory.
```

---

## Step 0: Pre-Flight Checks

Create `scripts/pre_flight.py` (overwrite if exists):

```python
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
```

---

## Step 1: Select Phase 2 Batch (30 videos)

Create `scripts/select_phase2_batch.py`:

```python
#!/usr/bin/env python3
"""
select_phase2_batch.py — Pick the next 30 videos from the playlist,
excluding already-processed Phase 1 videos.
Selects a balanced mix of video types by duration.
"""
import os, re, random

# Load Phase 1 video IDs (already processed)
phase1_ids = set()
for f in os.listdir("data/transcripts"):
    if f.endswith(".json"):
        phase1_ids.add(f.replace(".json", ""))

print(f"Phase 1 already processed: {len(phase1_ids)} videos")

# Load all playlist URLs
with open("config/playlist_urls.txt") as f:
    all_lines = [l.strip() for l in f if l.strip() and not l.startswith('#')]

# Parse URL, title, duration
available = []
for line in all_lines:
    match = re.search(r'v=([a-zA-Z0-9_-]{11})', line)
    if not match:
        continue
    vid = match.group(1)
    if vid in phase1_ids:
        continue
    
    # Parse duration from comment: [HH:MM:SS] or [MM:SS] or [NA]
    dur_match = re.search(r'\[(\d+):(\d+):(\d+)\]', line)
    if dur_match:
        h, m, s = int(dur_match.group(1)), int(dur_match.group(2)), int(dur_match.group(3))
        duration = h * 3600 + m * 60 + s
    else:
        dur_match = re.search(r'\[(\d+):(\d+)\]', line)
        if dur_match:
            m, s = int(dur_match.group(1)), int(dur_match.group(2))
            duration = m * 60 + s
        else:
            duration = 0  # NA or unparseable
    
    available.append({"id": vid, "line": line, "duration": duration})

print(f"Available (unprocessed): {len(available)} videos")

# Categorize by duration
clips = [v for v in available if 0 < v["duration"] < 900]
standard = [v for v in available if 900 <= v["duration"] < 1500]
compilations = [v for v in available if 1500 <= v["duration"] < 3600]
marathons = [v for v in available if v["duration"] >= 3600]
unknown = [v for v in available if v["duration"] == 0]

print(f"  Clips (<15m): {len(clips)}")
print(f"  Standard (15-25m): {len(standard)}")
print(f"  Compilations (25-60m): {len(compilations)}")
print(f"  Marathons (>60m): {len(marathons)}")
print(f"  Unknown duration: {len(unknown)}")

# Select balanced mix: 5 clips, 10 standard, 10 compilations, 5 marathons
random.seed(42)  # Reproducible selection
selected = []
selected += random.sample(clips, min(5, len(clips)))
selected += random.sample(standard, min(10, len(standard)))
selected += random.sample(compilations, min(10, len(compilations)))
selected += random.sample(marathons, min(5, len(marathons)))

# If we don't have 30 yet, fill from whatever's most available
while len(selected) < 30 and len(available) > len(selected):
    remaining = [v for v in available if v not in selected]
    if not remaining:
        break
    selected.append(random.choice(remaining))

# Write batch file
with open("config/phase2_batch.txt", "w") as f:
    f.write(f"# TripleDB Phase 2 Batch — {len(selected)} videos\n")
    f.write(f"# Selected from {len(available)} unprocessed videos\n\n")
    
    for v in sorted(selected, key=lambda x: x["duration"]):
        f.write(v["line"] + "\n")

print(f"\nWrote config/phase2_batch.txt with {len(selected)} videos")
for v in sorted(selected, key=lambda x: x["duration"])[:5]:
    print(f"  {v['id']}: {v['duration']//60}m")
print(f"  ...")
for v in sorted(selected, key=lambda x: x["duration"])[-5:]:
    print(f"  {v['id']}: {v['duration']//60}m")
```

Run it:

```bash
python3 scripts/select_phase2_batch.py
```

Verify: `wc -l config/phase2_batch.txt` should show ~30 lines plus comments.

---

## Step 2: Download Phase 2 Videos

The Phase 1 acquisition script already exists at `scripts/phase1_acquire.py`. It needs the `--remote-components ejs:github` and `--cookies-from-browser chrome` flags — verify they're present before running.

```bash
python3 scripts/phase1_acquire.py --batch config/phase2_batch.txt
```

**Expected:** ~25-30 min for 30 videos. Resume support skips already-downloaded files.

**Self-heal:** If any download fails:
- Rate limited: sleep flags handle it
- Geo-blocked: logged in manifest, skipped
- JS challenge: verify `--remote-components ejs:github` is in the script

---

## Step 3: Transcribe Phase 2 Videos

Stop Ollama first (faster-whisper needs the GPU):

```bash
systemctl --user stop ollama
sleep 5
```

The transcription script (`scripts/phase2_transcribe.py`) needs the CUDA library path fix. Verify this line exists near the top of the script:

```python
import os
os.environ["LD_LIBRARY_PATH"] = "/usr/local/lib/ollama/cuda_v12:" + os.environ.get("LD_LIBRARY_PATH", "")
```

If missing, add it before any `faster_whisper` imports.

```bash
python3 scripts/phase2_transcribe.py --batch config/phase2_batch.txt
```

**Expected:** ~60-90 min for 30 videos on CUDA. Resume support skips already-transcribed files.

After transcription, restart Ollama (not needed for extraction but keeps the system ready):

```bash
systemctl --user start ollama
```

---

## Step 4: Update the Extraction Prompt

**Replace** `config/extraction_prompt.md` with this refined version. Changes from v1.10:
- Rule 1: Added "Most DDD segments feature 2-4 dishes" guidance
- Rule 4: Added "Never return just 'Chef'" instruction
- Rule 7: Strengthened guy_response capture

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
      "owner_chef": "<name of the primary person Guy interacts with>",
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

1. Extract EVERY restaurant Guy physically visits. Do NOT extract restaurants merely mentioned. Most DDD segments feature 2-4 dishes per restaurant. If you only find 1 dish, re-scan the transcript — the chef almost always demonstrates at least 2 items.
2. Every restaurant MUST have: name, city, state, at least one dish.
3. For guy_intro: capture what Guy says when he first approaches or introduces the restaurant. This is usually the opening lines of each segment.
4. For owner_chef: extract the FULL NAME of the primary person Guy interacts with in the kitchen. Look for how Guy addresses them or how they introduce themselves. For pairs: "Mike and Lisa Rodriguez". NEVER return just "Chef" or "Owner" — always include at least a first name. If the name is truly never spoken, use null rather than a generic title.
5. For ingredients: extract 3-8 KEY ingredients per dish. Focus on what makes it distinctive. All lowercase. Do not list every single ingredient — focus on the signature components.
6. For dish_category: appetizer, entree, dessert, side, drink, or snack.
7. For guy_response: capture Guy's FULL reaction AFTER tasting each dish — verbatim from the transcript. Include his complete statement, not just the first sentence. Include catchphrases ("That's money!", "Winner winner chicken dinner!", "Out of bounds!", "Dynamite!") and genuine detailed reactions. Set null ONLY if Guy clearly doesn't taste the dish on camera.
8. For video_type: full_episode (~22 min, 2-3 restaurants), compilation ("Best of" themed, 3-8), clip (<15 min, 1 restaurant), marathon (1+ hr, many restaurants).
9. Confidence: 0.9-1.0 = clearly stated. 0.7-0.89 = reasonably clear. 0.5-0.69 = inferred. <0.5 = best guess.
10. Segment timestamps: look for transitions ("Next up...", "Our next stop...", "Rolling out to...").

## Example 1: Standard Episode Segment

Transcript excerpt:
[45.2s] We're rolling out to Johnny's Italian Kitchen in Baltimore, Maryland.
[52.1s] Owner Johnny Russo has been making handmade pasta for 30 years.
[120.3s] This is their famous crab ravioli with a brown butter sage sauce.
[145.8s] Oh my God, that is DYNAMITE!

Expected output:
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

## Example 2: Multiple Dishes

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

## Step 5: Extract Phase 2 Videos

Use the existing `scripts/phase3_extract_gemini.py` from v1.10. Before running, make ONE change — update the timeout for marathons:

In `phase3_extract_gemini.py`, find the `TIMEOUT` constant and change it:

```python
TIMEOUT = 300  # 5 minutes (up from 120 — needed for marathons)
```

Also, re-extract the v1.10 empty video:

```bash
# Re-extract the empty Dcfs_wKVi9A from Phase 1
rm -f data/extracted/Dcfs_wKVi9A.json
python3 scripts/phase3_extract_gemini.py --video Dcfs_wKVi9A

# Then extract all Phase 2 videos
python3 scripts/phase3_extract_gemini.py --batch config/phase2_batch.txt
```

**Expected:** ~5-10 minutes for 30 videos. The script has resume support — previously extracted videos are skipped.

---

## Step 6: Validate All Extractions (60 videos)

Create `scripts/validate_extraction.py` (overwrite if exists):

```python
#!/usr/bin/env python3
"""validate_extraction.py — Validate extraction quality across all phases."""
import json, glob, os

print("=" * 60)
print("EXTRACTION VALIDATION — ALL PHASES")
print("=" * 60)

files = sorted([f for f in glob.glob("data/extracted/*.json") if "_raw" not in f])
print(f"\nTotal extracted files: {len(files)}\n")

total_r, total_d = 0, 0
empty_videos = []
video_types = {}
guy_intro_count, guy_response_count = 0, 0
ingredient_count, total_dishes_checked = 0, 0
owner_chef_null = 0
owner_chef_generic = 0
single_dish_restaurants = 0
total_restaurants_checked = 0

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
        total_restaurants_checked += 1
        chef = r.get("owner_chef")
        if chef is None:
            owner_chef_null += 1
        elif chef.lower() in ["chef", "owner", "pit master", "pitmaster"]:
            owner_chef_generic += 1
        
        if r.get("guy_intro"):
            guy_intro_count += 1

        dishes = r.get("dishes", [])
        if len(dishes) == 1:
            single_dish_restaurants += 1

        for d in dishes:
            d_count += 1
            total_dishes_checked += 1
            if d.get("guy_response"):
                guy_response_count += 1
            if d.get("ingredients") and len(d["ingredients"]) > 0:
                ingredient_count += 1

    total_r += r_count
    total_d += d_count
    print(f"  {vid}: {vtype} | {r_count} restaurants, {d_count} dishes")

print(f"\n{'='*60}")
print(f"TOTALS")
print(f"{'='*60}")
print(f"  Videos with JSON:        {len(files)}")
print(f"  Videos with data:        {len(files) - len(empty_videos)}")
print(f"  Videos empty:            {len(empty_videos)}")
print(f"  Total restaurants:       {total_r}")
print(f"  Total dishes:            {total_d}")
print(f"  Avg dishes/restaurant:   {total_d/max(total_r,1):.1f}")
print(f"  Video types:             {video_types}")

print(f"\n  QUALITY METRICS:")
print(f"  guy_intro:               {guy_intro_count}/{total_restaurants_checked} ({guy_intro_count/max(total_restaurants_checked,1)*100:.0f}%)")
print(f"  guy_response:            {guy_response_count}/{total_dishes_checked} ({guy_response_count/max(total_dishes_checked,1)*100:.0f}%)")
print(f"  ingredients:             {ingredient_count}/{total_dishes_checked} ({ingredient_count/max(total_dishes_checked,1)*100:.0f}%)")
print(f"  owner_chef null:         {owner_chef_null}/{total_restaurants_checked} ({owner_chef_null/max(total_restaurants_checked,1)*100:.0f}%)")
print(f"  owner_chef generic:      {owner_chef_generic}/{total_restaurants_checked} ({owner_chef_generic/max(total_restaurants_checked,1)*100:.0f}%)")
print(f"  single-dish restaurants: {single_dish_restaurants}/{total_restaurants_checked} ({single_dish_restaurants/max(total_restaurants_checked,1)*100:.0f}%)")

if empty_videos:
    print(f"\n  Empty videos: {', '.join(empty_videos)}")

print(f"\n{'='*60}")
print(f"SUCCESS CRITERIA (Phase 2)")
print(f"{'='*60}")
criteria = [
    ("Total extracted files >= 55 (of ~60)", len(files) >= 55),
    ("Videos with restaurants >= 50", (len(files) - len(empty_videos)) >= 50),
    ("Total restaurants >= 250", total_r >= 250),
    ("Total dishes >= 500", total_d >= 500),
    ("Avg dishes/restaurant >= 1.8", total_d/max(total_r,1) >= 1.8),
    ("guy_intro capture >= 80%", guy_intro_count/max(total_restaurants_checked,1) >= 0.8),
    ("guy_response capture >= 80%", guy_response_count/max(total_dishes_checked,1) >= 0.8),
    ("ingredients capture >= 80%", ingredient_count/max(total_dishes_checked,1) >= 0.8),
    ("owner_chef null < 15%", owner_chef_null/max(total_restaurants_checked,1) < 0.15),
    ("owner_chef generic < 10%", owner_chef_generic/max(total_restaurants_checked,1) < 0.10),
]
all_pass = True
for name, passed in criteria:
    print(f"  {'✅' if passed else '❌'} {name}")
    if not passed:
        all_pass = False

print(f"\n{'✅ ALL CRITERIA MET' if all_pass else '❌ SOME CRITERIA FAILED'}")
```

Run it:

```bash
python3 scripts/validate_extraction.py
```

---

## Step 7: Normalize and Deduplicate

This is Phase 2's unique contribution — the first normalization pass. Restaurants appear in multiple videos (a Memphis restaurant could appear in a city compilation, a BBQ compilation, and the original episode). Normalization merges these into single restaurant records.

Create `scripts/phase4_normalize.py`:

```python
#!/usr/bin/env python3
"""
phase4_normalize.py — Normalize and deduplicate extracted restaurant data.
Uses Gemini Flash API for intelligent dedup decisions.
Produces 4 JSONL files in data/normalized/.
"""
import os, sys, json, glob, time, re, uuid
import requests
from pathlib import Path
from collections import defaultdict

API_KEY = os.environ.get("GEMINI_API_KEY", "")
API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={API_KEY}"

EXTRACTED_DIR = Path("data/extracted")
NORMALIZED_DIR = Path("data/normalized")
LOG_DIR = Path("data/logs")

def load_all_extractions():
    """Load all extracted JSONs into a unified list."""
    all_restaurants = []
    all_videos = []
    
    for f in sorted(EXTRACTED_DIR.glob("*.json")):
        if "_raw" in f.name:
            continue
        with open(f) as fh:
            data = json.load(fh)
        
        video_id = data.get("video_id", f.stem)
        video_title = data.get("video_title", "")
        video_type = data.get("video_type", "unknown")
        
        all_videos.append({
            "video_id": video_id,
            "youtube_url": f"https://youtube.com/watch?v={video_id}",
            "title": video_title,
            "video_type": video_type,
            "restaurant_count": len(data.get("restaurants", []))
        })
        
        for r in data.get("restaurants", []):
            r["_source_video_id"] = video_id
            r["_source_video_title"] = video_title
            r["_source_video_type"] = video_type
            all_restaurants.append(r)
    
    return all_restaurants, all_videos

def normalize_state(state):
    """Convert full state names to 2-letter abbreviations."""
    state_map = {
        "alabama": "AL", "alaska": "AK", "arizona": "AZ", "arkansas": "AR",
        "california": "CA", "colorado": "CO", "connecticut": "CT", "delaware": "DE",
        "florida": "FL", "georgia": "GA", "hawaii": "HI", "idaho": "ID",
        "illinois": "IL", "indiana": "IN", "iowa": "IA", "kansas": "KS",
        "kentucky": "KY", "louisiana": "LA", "maine": "ME", "maryland": "MD",
        "massachusetts": "MA", "michigan": "MI", "minnesota": "MN",
        "mississippi": "MS", "missouri": "MO", "montana": "MT", "nebraska": "NE",
        "nevada": "NV", "new hampshire": "NH", "new jersey": "NJ",
        "new mexico": "NM", "new york": "NY", "north carolina": "NC",
        "north dakota": "ND", "ohio": "OH", "oklahoma": "OK", "oregon": "OR",
        "pennsylvania": "PA", "rhode island": "RI", "south carolina": "SC",
        "south dakota": "SD", "tennessee": "TN", "texas": "TX", "utah": "UT",
        "vermont": "VT", "virginia": "VA", "washington": "WA",
        "west virginia": "WV", "wisconsin": "WI", "wyoming": "WY",
        "d.c.": "DC", "district of columbia": "DC",
    }
    if state and len(state) == 2:
        return state.upper()
    return state_map.get(state.lower().strip(), state) if state else state

def normalize_ingredients(ingredients):
    """Lowercase, singularize, standardize ingredient names."""
    if not ingredients:
        return []
    normalized = []
    for ing in ingredients:
        ing = ing.lower().strip()
        # Basic singularization
        if ing.endswith("ies"):
            ing = ing[:-3] + "y"
        elif ing.endswith("es") and not ing.endswith("ses"):
            ing = ing[:-2]
        elif ing.endswith("s") and not ing.endswith("ss"):
            ing = ing[:-1]
        # Standardize common variants
        ing = ing.replace("barbecue", "bbq").replace("jalapeño", "jalapeno")
        normalized.append(ing)
    return normalized

def group_potential_duplicates(restaurants):
    """Group restaurants by name similarity + city for dedup candidates."""
    groups = defaultdict(list)
    for r in restaurants:
        name = (r.get("name") or "").lower().strip()
        city = (r.get("city") or "").lower().strip()
        # Simple grouping key: first 10 chars of name + city
        key = f"{name[:10]}|{city}"
        groups[key].append(r)
    return groups

def merge_restaurant_group(restaurants):
    """Merge a group of duplicate restaurants into one canonical record."""
    if len(restaurants) == 1:
        r = restaurants[0]
        return build_normalized_restaurant(r, [r])
    
    # Pick the most complete record as base
    best = max(restaurants, key=lambda r: (
        bool(r.get("owner_chef")),
        len(r.get("dishes", [])),
        len(r.get("guy_intro") or ""),
        r.get("confidence", 0)
    ))
    
    return build_normalized_restaurant(best, restaurants)

def build_normalized_restaurant(base, all_appearances):
    """Build a normalized restaurant document from a base record and all appearances."""
    rid = f"r_{uuid.uuid4().hex[:12]}"
    
    # Merge dishes from all appearances, dedup by name
    seen_dishes = {}
    for appearance in all_appearances:
        for d in appearance.get("dishes", []):
            dname = (d.get("dish_name") or "").lower().strip()
            if dname not in seen_dishes or d.get("confidence", 0) > seen_dishes[dname].get("confidence", 0):
                seen_dishes[dname] = d
    
    dishes = []
    for d in seen_dishes.values():
        dishes.append({
            "dish_name": d.get("dish_name"),
            "description": d.get("description"),
            "ingredients": normalize_ingredients(d.get("ingredients", [])),
            "dish_category": d.get("dish_category"),
            "guy_response": d.get("guy_response"),
            "video_id": d.get("_source_video_id", all_appearances[0].get("_source_video_id")),
            "timestamp_start": d.get("timestamp_start")
        })
    
    visits = []
    for appearance in all_appearances:
        visits.append({
            "video_id": appearance.get("_source_video_id"),
            "youtube_url": f"https://youtube.com/watch?v={appearance.get('_source_video_id')}",
            "video_title": appearance.get("_source_video_title"),
            "video_type": appearance.get("_source_video_type"),
            "guy_intro": appearance.get("guy_intro"),
            "timestamp_start": appearance.get("timestamp_start"),
            "timestamp_end": appearance.get("timestamp_end")
        })
    
    return {
        "restaurant_id": rid,
        "name": base.get("name"),
        "city": base.get("city"),
        "state": normalize_state(base.get("state")),
        "address": None,
        "latitude": None,
        "longitude": None,
        "cuisine_type": base.get("cuisine_type"),
        "owner_chef": base.get("owner_chef"),
        "still_open": None,
        "google_rating": None,
        "yelp_rating": None,
        "website_url": None,
        "visits": visits,
        "dishes": dishes
    }

def main():
    NORMALIZED_DIR.mkdir(parents=True, exist_ok=True)
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    
    print("Loading all extractions...")
    all_restaurants, all_videos = load_all_extractions()
    print(f"  Total raw restaurants: {len(all_restaurants)}")
    print(f"  Total videos: {len(all_videos)}")
    
    print("\nGrouping potential duplicates...")
    groups = group_potential_duplicates(all_restaurants)
    print(f"  Unique groups: {len(groups)}")
    
    multi_groups = {k: v for k, v in groups.items() if len(v) > 1}
    print(f"  Groups with potential dupes: {len(multi_groups)}")
    
    print("\nMerging...")
    normalized_restaurants = []
    dedup_log = []
    
    for key, group in groups.items():
        merged = merge_restaurant_group(group)
        normalized_restaurants.append(merged)
        
        if len(group) > 1:
            dedup_log.append({
                "merged_name": merged["name"],
                "merged_city": merged["city"],
                "source_count": len(group),
                "source_videos": [r.get("_source_video_id") for r in group],
                "final_dish_count": len(merged["dishes"])
            })
    
    # Write normalized JSONL files
    print(f"\nWriting normalized files...")
    
    # restaurants.jsonl
    with open(NORMALIZED_DIR / "restaurants.jsonl", "w") as f:
        for r in normalized_restaurants:
            f.write(json.dumps(r) + "\n")
    print(f"  restaurants.jsonl: {len(normalized_restaurants)} records")
    
    # videos.jsonl
    with open(NORMALIZED_DIR / "videos.jsonl", "w") as f:
        for v in all_videos:
            f.write(json.dumps(v) + "\n")
    print(f"  videos.jsonl: {len(all_videos)} records")
    
    # Dedup report
    with open(LOG_DIR / "phase-4-dedup-report.jsonl", "w") as f:
        for entry in dedup_log:
            f.write(json.dumps(entry) + "\n")
    print(f"  dedup report: {len(dedup_log)} merges")
    
    # Summary stats
    total_dishes = sum(len(r["dishes"]) for r in normalized_restaurants)
    total_visits = sum(len(r["visits"]) for r in normalized_restaurants)
    states = set(r["state"] for r in normalized_restaurants if r.get("state"))
    
    print(f"\n{'='*60}")
    print(f"NORMALIZATION SUMMARY")
    print(f"{'='*60}")
    print(f"  Raw restaurants (pre-dedup):  {len(all_restaurants)}")
    print(f"  Normalized restaurants:       {len(normalized_restaurants)}")
    print(f"  Dedup merges:                {len(dedup_log)}")
    print(f"  Total dishes:                {total_dishes}")
    print(f"  Total visits:                {total_visits}")
    print(f"  Unique states:               {len(states)}")
    print(f"  Avg dishes/restaurant:       {total_dishes/max(len(normalized_restaurants),1):.1f}")
    print(f"  Avg visits/restaurant:       {total_visits/max(len(normalized_restaurants),1):.1f}")
    print(f"{'='*60}")

if __name__ == "__main__":
    main()
```

Run it:

```bash
python3 scripts/phase4_normalize.py
```

---

## Step 8: Validate Normalization

```bash
# Quick checks
wc -l data/normalized/restaurants.jsonl
wc -l data/normalized/videos.jsonl

# Spot-check: look at a restaurant with multiple visits
python3 -c "
import json
for line in open('data/normalized/restaurants.jsonl'):
    r = json.loads(line)
    if len(r['visits']) > 1:
        print(json.dumps(r, indent=2))
        break
"

# Check state distribution
python3 -c "
import json
from collections import Counter
states = Counter()
for line in open('data/normalized/restaurants.jsonl'):
    r = json.loads(line)
    states[r.get('state', 'unknown')] += 1
for state, count in states.most_common(15):
    print(f'  {state}: {count}')
print(f'  Total states: {len(states)}')
"

# Check dedup log
cat data/logs/phase-4-dedup-report.jsonl | python3 -m json.tool | head -30
```

---

## Step 9: Generate Report Artifacts

Create both:

### docs/ddd-report-v2.11.md

Include:
- Phase 2 batch selection details (how many of each type)
- Download results (success/fail count)
- Transcription results
- Extraction results (Phase 2 videos + re-extracted Dcfs_wKVi9A)
- Combined validation metrics (all 60 videos)
- Normalization results (dedup count, state distribution)
- owner_chef improvement (compare null/generic rates vs v1.10)
- dishes/restaurant improvement (compare avg vs v1.10)
- Recommendation: proceed to Phase 3 or re-run

### docs/ddd-build-v2.11.md

Chronological log of every action, error, and fix during this session.

---

## Phase 2.11 Success Criteria

```
[ ] Pre-flight passes
[ ] Phase 2 batch selected (30 videos, balanced types)
[ ] 27+ of 30 Phase 2 videos downloaded
[ ] 27+ of 30 Phase 2 videos transcribed  
[ ] 27+ of 30 Phase 2 videos extracted
[ ] Combined extraction: 55+ videos with data (of ~60)
[ ] Combined restaurants >= 250
[ ] Combined dishes >= 500
[ ] Avg dishes/restaurant >= 1.8 (improved from 1.6)
[ ] owner_chef null rate < 15% (improved from v1.10)
[ ] owner_chef generic rate < 10% (improved from v1.10)
[ ] guy_intro capture >= 80%
[ ] guy_response capture >= 80%
[ ] ingredients capture >= 80%
[ ] Normalization produces restaurants.jsonl and videos.jsonl
[ ] At least 1 dedup merge detected (proves dedup logic works)
[ ] State distribution spans 10+ states
[ ] ddd-report-v2.11.md generated
[ ] ddd-build-v2.11.md generated
```

If all criteria met → proceed to Phase 3 (Stress Test — marathons, edge cases).
If extraction quality dropped → investigate and re-run as v2.12.

---

## Gemini CLI Opening Prompt

```bash
cd ~/dev/projects/tripledb/pipeline
gemini
```

```
Read GEMINI.md for project context.

We are starting Phase 2.11 — Calibration. Phase 1.10 successfully
extracted 186 restaurants and 290 dishes from 30 videos using Gemini
Flash API.

Read ../docs/ddd-plan-v2.11.md for the complete execution plan.

CRITICAL RULES:
- Auto-proceed between steps. Do NOT ask permission.
- Self-heal errors: diagnose, fix, re-run (max 3 attempts, then skip).
- Run scripts in foreground. No background processes.
- Working directory is pipeline/ (you are already here).
- Extraction uses Gemini 2.5 Flash API via $GEMINI_API_KEY.
- Generate docs/ddd-report-v2.11.md and docs/ddd-build-v2.11.md when done.
- Do NOT run git commit, git push, or firebase deploy.

The plan has 9 steps. Execute them in order:
Step 0: Create and run pre_flight.py
Step 1: Create and run select_phase2_batch.py
Step 2: Download Phase 2 videos
Step 3: Transcribe Phase 2 videos  
Step 4: Update extraction prompt
Step 5: Extract Phase 2 videos + re-extract Dcfs_wKVi9A
Step 6: Run validate_extraction.py on ALL extracted data
Step 7: Run phase4_normalize.py
Step 8: Validate normalization output
Step 9: Generate report artifacts

Begin with Step 0.
```
