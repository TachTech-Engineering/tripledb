# TripleDB — Phase 1 Plan v1.9

**Phase:** 1 — Discovery (retry)
**Iteration:** 9 (global project iteration)
**Date:** March 20, 2026
**Machine:** NZXTcos — i9-13900K (24-core), 64GB DDR4, RTX 2080 SUPER (8GB VRAM), CachyOS
**Goal:** Complete what v1.8 could not: successful extraction of structured restaurant data from transcripts. Downloads and transcription are already done (30/30). This iteration focuses exclusively on getting extraction working end-to-end.

---

## What Happened in v1.8

Phases 1-2 succeeded: all 30 test videos downloaded and transcribed. Phase 3 (extraction) failed completely — zero extracted JSON files produced. Root causes:

1. **Nemotron model (42GB) too large for 8GB VRAM** — spilled to CPU RAM, inference took 20-45 min per video, triggered timeouts
2. **qwen3.5:9b context window too large** — 32K context at 33%/67% CPU/GPU split caused hangs
3. **Extraction prompt too fat** — few-shot examples consumed ~3,000 tokens of context budget
4. **No chunking** — long transcripts (up to 100K chars for marathons) exceeded any reasonable context window
5. **No streaming** — impossible to distinguish "model is generating slowly" from "model is hung"
6. **Interactive bottleneck** — Gemini kept stopping to ask permission, wasting hours

All of these are fixed in this plan.

---

## AUTONOMY RULES — READ FIRST

```
CRITICAL EXECUTION RULES FOR THIS PHASE:

1. AUTO-PROCEED: When one step completes, immediately begin the next.
   Do NOT pause to ask Kyle's permission between steps.

2. SELF-HEAL: When an error occurs:
   a. Read the error message
   b. Diagnose the root cause
   c. Apply a fix (edit script, adjust config, restart service)
   d. Re-run the failed step
   e. Maximum 3 fix attempts per error
   f. After 3 failures: log the error, skip the item, continue to next

3. NO BACKGROUND PROCESSES: Run all scripts in the foreground so you can
   see stdout/stderr in real time. Do NOT use & or background PIDs.

4. TIMEOUT DISCIPLINE: If any single operation takes longer than the
   specified timeout, kill it, log it, skip it, move on.

5. ARTIFACT GENERATION: When all steps are complete (or all retries
   exhausted), generate these files:
   - docs/ddd-report-v1.9.md (metrics, issues, decisions)
   - docs/ddd-build-v1.9.md (full session transcript of actions taken)

6. GIT: Do NOT run git commit, git push, or firebase deploy.
```

---

## PRE-FLIGHT CHECKS — Step 0

Run ALL of these before touching any pipeline script. If any check fails, fix it before proceeding. This is the self-healing loop for environment validation.

```python
#!/usr/bin/env python3
"""pre_flight.py — Run from pipeline/ directory"""
import subprocess, sys, os, json

checks = []

# 1. Ollama running?
try:
    r = subprocess.run(["ollama", "list"], capture_output=True, text=True, timeout=10)
    if "qwen3.5:9b" in r.stdout:
        checks.append(("Ollama + qwen3.5:9b", "PASS"))
    else:
        checks.append(("Ollama + qwen3.5:9b", "FAIL — model not found"))
except Exception as e:
    checks.append(("Ollama", f"FAIL — {e}"))

# 2. CUDA available?
try:
    r = subprocess.run(["nvidia-smi", "--query-gpu=memory.free",
                        "--format=csv,noheader,nounits"],
                       capture_output=True, text=True, timeout=10)
    free_mb = int(r.stdout.strip().split('\n')[0])
    status = "PASS" if free_mb > 2000 else f"WARN — only {free_mb}MB free"
    checks.append(("GPU VRAM", f"{status} ({free_mb}MB free)"))
except Exception as e:
    checks.append(("GPU", f"FAIL — {e}"))

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

# 5. Test Ollama inference with qwen3.5:9b
try:
    import requests
    resp = requests.post("http://localhost:11434/api/chat", json={
        "model": "qwen3.5:9b",
        "messages": [{"role": "user", "content": "Reply with exactly: {\"test\": true}"}],
        "stream": False,
        "format": "json",
        "options": {"temperature": 0.0, "num_ctx": 4096}
    }, timeout=120)
    data = resp.json()
    content = data.get("message", {}).get("content", "")
    try:
        parsed = json.loads(content)
        checks.append(("Ollama inference test", f"PASS — got valid JSON"))
    except json.JSONDecodeError:
        checks.append(("Ollama inference test", f"FAIL — not valid JSON: {content[:100]}"))
except Exception as e:
    checks.append(("Ollama inference test", f"FAIL — {e}"))

# 6. Test batch file exists?
batch_path = "config/test_batch.txt"
if os.path.isfile(batch_path):
    lines = [l for l in open(batch_path) if l.strip() and not l.startswith('#')]
    checks.append(("Test batch", f"PASS — {len(lines)} URLs"))
else:
    checks.append(("Test batch", "FAIL — file missing"))

print("\n=== PRE-FLIGHT CHECK RESULTS ===")
all_pass = True
for name, result in checks:
    icon = "✅" if "PASS" in result else "⚠️" if "WARN" in result else "❌"
    print(f"  {icon} {name}: {result}")
    if "FAIL" in result:
        all_pass = False

if all_pass:
    print("\n✅ ALL CHECKS PASSED — ready to proceed")
else:
    print("\n❌ SOME CHECKS FAILED — fix before proceeding")
    sys.exit(1)
```

**Instructions:** Create this as `scripts/pre_flight.py`, run it. If any check fails, fix it using the self-healing rules (diagnose, fix, re-run, max 3 attempts). Only proceed to Step 1 when all checks pass.

**Common fixes for failed pre-flight:**
- Ollama not running: `systemctl --user restart ollama && sleep 5`
- qwen3.5:9b not found: `ollama pull qwen3.5:9b`
- Low VRAM: `ollama stop qwen3.5:9b` then restart (clears VRAM), or kill other GPU processes
- Transcripts missing: this shouldn't happen (v1.8 completed transcription), but if so, re-run `python3 scripts/phase2_transcribe.py --batch config/test_batch.txt`

---

## Step 1: Slim the Extraction Prompt

The v1.8 extraction prompt included 3 few-shot examples consuming ~3,000 tokens. With an 8K context window, that leaves only ~5,000 tokens for transcript content — not enough for even a 10-minute clip.

**Replace** the contents of `config/extraction_prompt.md` with this slimmed version:

```markdown
# DDD Video Extraction — System Prompt

You are a structured data extraction agent. Read a transcript from a
"Diners, Drive-Ins and Dives" video and extract all restaurant visits
into structured JSON.

## Show Format

- Host: Guy Fieri
- Each restaurant segment: Guy arrives (guy_intro), enters kitchen,
  chef/owner demonstrates dishes (with ingredients), Guy tastes and
  reacts (guy_response)
- Videos range from 10-minute clips to 4-hour marathons

## Output Schema

Return ONLY a JSON object with this exact structure:

{
  "video_id": "<provided>",
  "video_title": "<provided>",
  "video_type": "<full_episode|compilation|clip|marathon>",
  "restaurants": [
    {
      "name": "<restaurant name>",
      "city": "<city>",
      "state": "<full state name>",
      "cuisine_type": "<primary cuisine>",
      "owner_chef": "<person Guy interacts with>",
      "guy_intro": "<what Guy says arriving at the restaurant>",
      "segment_number": 1,
      "timestamp_start": 0.0,
      "timestamp_end": 0.0,
      "dishes": [
        {
          "dish_name": "<name>",
          "description": "<preparation method>",
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

## Rules

1. Extract EVERY restaurant Guy physically visits. Skip those merely mentioned.
2. Every restaurant MUST have: name, city, state, at least one dish.
3. guy_intro: what Guy says when approaching/arriving at the restaurant.
4. owner_chef: the main person Guy interacts with in the kitchen.
5. ingredients: 3-8 KEY ingredients per dish. Lowercase. What makes it distinctive.
6. dish_category: appetizer, entree, dessert, side, drink, or snack.
7. guy_response: Guy's reaction AFTER tasting. Verbatim. Null only if he doesn't taste on camera.
8. video_type: full_episode (~22 min, 2-3 restaurants), compilation (themed, 3-8), clip (<15 min, 1), marathon (1+ hr, 10-30+).
9. Confidence: 0.9-1.0 = clearly stated. 0.7-0.89 = reasonably clear. <0.7 = inferred.
10. Return ONLY the JSON object. No markdown. No explanation. No preamble.
```

This prompt is ~1,500 characters (~400 tokens). With 8K context, that leaves ~7,500 tokens for transcript + response — roughly 30,000 characters of transcript per chunk.

---

## Step 2: Rewrite the Extraction Script

**Replace** `scripts/phase3_extract.py` entirely with this version. The key changes from v1.8:

1. **Streaming output** — detects hangs in real time
2. **Aggressive chunking** — splits transcripts into chunks that fit 8K context
3. **Hard timeouts** — 5 minutes per chunk, kill and skip
4. **num_ctx = 8192** — fits entirely in 8GB VRAM, no CPU spill
5. **Foreground execution** — no background processes
6. **Self-contained** — reads video titles from info.json or transcript filename

Create the following as `scripts/phase3_extract.py`:

```python
#!/usr/bin/env python3
"""
phase3_extract.py — Extract restaurant data from DDD transcripts.
Uses qwen3.5:9b via Ollama with streaming, chunking, and hard timeouts.
"""
import os
import sys
import json
import time
import signal
import argparse
import re
import requests
from pathlib import Path

# ── Configuration ────────────────────────────────────────────────────
MODEL = "qwen3.5:9b"
OLLAMA_URL = "http://localhost:11434/api/chat"
NUM_CTX = 8192
TEMPERATURE = 0.1
MAX_CHUNK_CHARS = 24000       # ~6000 tokens, leaves room for prompt + response
TIMEOUT_PER_CHUNK = 300       # 5 minutes per chunk — kill if exceeded
MAX_RETRIES = 2               # retry each chunk up to 2 times
DATA_DIR = Path("data")
EXTRACTED_DIR = DATA_DIR / "extracted"
TRANSCRIPT_DIR = DATA_DIR / "transcripts"
AUDIO_DIR = DATA_DIR / "audio"
LOG_DIR = DATA_DIR / "logs"
PROMPT_PATH = Path("config/extraction_prompt.md")

# ── Timeout handler ──────────────────────────────────────────────────
class TimeoutError(Exception):
    pass

def timeout_handler(signum, frame):
    raise TimeoutError("Ollama request timed out")

# ── Helpers ──────────────────────────────────────────────────────────
def load_extraction_prompt():
    with open(PROMPT_PATH) as f:
        return f.read()

def get_video_title(video_id):
    """Try to get title from yt-dlp info.json, fall back to video_id."""
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
    """Extract video IDs from a batch file of URLs."""
    ids = []
    with open(batch_file) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            # Extract video ID from URL
            match = re.search(r'[?&]v=([a-zA-Z0-9_-]{11})', line)
            if match:
                ids.append(match.group(1))
            else:
                # Maybe it's just a video ID
                clean = line.split('#')[0].strip()
                if len(clean) == 11:
                    ids.append(clean)
    return ids

def load_transcript(video_id):
    """Load transcript and return full text with timestamps."""
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
    full_text = "\n".join(lines)
    return full_text, data.get("duration_seconds", 0)

def chunk_transcript(full_text, max_chars=MAX_CHUNK_CHARS):
    """Split transcript into chunks at natural pause boundaries."""
    if len(full_text) <= max_chars:
        return [full_text]

    chunks = []
    lines = full_text.split("\n")
    current_chunk = []
    current_size = 0

    for line in lines:
        line_len = len(line) + 1  # +1 for newline
        if current_size + line_len > max_chars and current_chunk:
            chunks.append("\n".join(current_chunk))
            current_chunk = []
            current_size = 0
        current_chunk.append(line)
        current_size += line_len

    if current_chunk:
        chunks.append("\n".join(current_chunk))

    return chunks

def call_ollama_streaming(system_prompt, user_content):
    """Call Ollama with streaming, hard timeout, and JSON extraction."""
    signal.signal(signal.SIGALRM, timeout_handler)
    signal.alarm(TIMEOUT_PER_CHUNK)

    try:
        resp = requests.post(OLLAMA_URL, json={
            "model": MODEL,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_content}
            ],
            "stream": True,
            "format": "json",
            "options": {
                "temperature": TEMPERATURE,
                "num_ctx": NUM_CTX
            }
        }, stream=True, timeout=TIMEOUT_PER_CHUNK)

        full_response = ""
        token_count = 0
        for line in resp.iter_lines():
            if line:
                try:
                    chunk = json.loads(line)
                    content = chunk.get("message", {}).get("content", "")
                    full_response += content
                    token_count += 1
                    # Print a dot every 50 tokens to show progress
                    if token_count % 50 == 0:
                        print(".", end="", flush=True)
                except json.JSONDecodeError:
                    continue

        signal.alarm(0)  # Cancel alarm
        return full_response

    except TimeoutError:
        signal.alarm(0)
        raise
    except requests.exceptions.Timeout:
        signal.alarm(0)
        raise TimeoutError("Request timed out")
    except Exception as e:
        signal.alarm(0)
        raise

def parse_json_response(raw_text):
    """Try to parse JSON from response, handle common issues."""
    # Direct parse
    try:
        return json.loads(raw_text)
    except json.JSONDecodeError:
        pass

    # Try to extract JSON from markdown code blocks
    match = re.search(r'```(?:json)?\s*\n?(.*?)\n?```', raw_text, re.DOTALL)
    if match:
        try:
            return json.loads(match.group(1))
        except json.JSONDecodeError:
            pass

    # Try to find the first { ... } block
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
    log_path = LOG_DIR / "phase-3-errors.jsonl"
    with open(log_path, "a") as f:
        entry = {"timestamp": time.time(), "video_id": video_id, "error": error_msg}
        f.write(json.dumps(entry) + "\n")
        f.flush()

def save_raw(video_id, raw_text):
    path = EXTRACTED_DIR / f"{video_id}_raw.txt"
    with open(path, "w") as f:
        f.write(raw_text)

# ── Main extraction logic ────────────────────────────────────────────
def extract_video(video_id, system_prompt):
    """Extract restaurants from a single video transcript."""
    output_path = EXTRACTED_DIR / f"{video_id}.json"

    # Resume: skip if valid output exists
    if output_path.exists():
        try:
            with open(output_path) as f:
                existing = json.load(f)
            if existing.get("restaurants"):
                print(f"  Skipping {video_id} — already extracted")
                return existing, "skipped"
        except (json.JSONDecodeError, KeyError):
            pass  # Re-process corrupt files

    # Load transcript
    full_text, duration = load_transcript(video_id)
    if full_text is None:
        log_error(video_id, "Transcript file not found")
        return None, "no_transcript"

    title = get_video_title(video_id)
    chunks = chunk_transcript(full_text)

    print(f"  Transcript: {len(full_text)} chars, {len(chunks)} chunk(s), {duration:.0f}s duration")

    all_restaurants = []

    for i, chunk in enumerate(chunks):
        chunk_label = f"chunk {i+1}/{len(chunks)}"

        user_content = (
            f"Video ID: {video_id}\n"
            f"Video Title: {title}\n"
            f"Chunk: {i+1} of {len(chunks)}\n\n"
            f"Transcript:\n{chunk}"
        )

        for attempt in range(MAX_RETRIES + 1):
            try:
                print(f"  [{chunk_label}] Sending to {MODEL} (attempt {attempt+1})", end="", flush=True)
                start_time = time.time()
                raw = call_ollama_streaming(system_prompt, user_content)
                elapsed = time.time() - start_time
                print(f" [{elapsed:.1f}s]")

                parsed = parse_json_response(raw)
                if parsed is None:
                    save_raw(video_id, raw)
                    log_error(video_id, f"JSON parse failed on {chunk_label}. Raw saved.")
                    print(f"  [{chunk_label}] JSON parse failed — raw saved")
                    if attempt < MAX_RETRIES:
                        print(f"  [{chunk_label}] Retrying...")
                        continue
                    break

                restaurants = parsed.get("restaurants", [])
                print(f"  [{chunk_label}] Extracted {len(restaurants)} restaurant(s)")
                all_restaurants.extend(restaurants)
                break  # Success — move to next chunk

            except TimeoutError:
                elapsed = time.time() - start_time
                print(f" TIMEOUT [{elapsed:.1f}s]")
                log_error(video_id, f"Timeout on {chunk_label} (attempt {attempt+1})")
                if attempt < MAX_RETRIES:
                    print(f"  [{chunk_label}] Retrying after timeout...")
                    continue
                print(f"  [{chunk_label}] Max retries — skipping chunk")
                break

            except Exception as e:
                print(f" ERROR: {e}")
                log_error(video_id, f"Error on {chunk_label}: {str(e)}")
                if attempt < MAX_RETRIES:
                    continue
                break

    # Build final output
    result = {
        "video_id": video_id,
        "video_title": title,
        "video_type": classify_video_type(duration, len(all_restaurants)),
        "restaurants": all_restaurants
    }

    # Save regardless of restaurant count (empty = valid, means no restaurants found)
    with open(output_path, "w") as f:
        json.dump(result, f, indent=2)

    status = "success" if all_restaurants else "empty"
    return result, status

def classify_video_type(duration, restaurant_count):
    if duration < 900:       # < 15 min
        return "clip"
    elif duration < 1500:    # < 25 min
        return "full_episode"
    elif duration < 3600:    # < 60 min
        return "compilation"
    else:
        return "marathon"

# ── Main ─────────────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--batch", help="File with video URLs/IDs")
    group.add_argument("--all", action="store_true", help="Process all transcripts")
    group.add_argument("--video", help="Single video ID")
    args = parser.parse_args()

    EXTRACTED_DIR.mkdir(parents=True, exist_ok=True)
    LOG_DIR.mkdir(parents=True, exist_ok=True)

    system_prompt = load_extraction_prompt()
    print(f"Extraction prompt: {len(system_prompt)} chars")

    # Get video IDs
    if args.video:
        video_ids = [args.video]
    elif args.batch:
        video_ids = get_video_ids_from_batch(args.batch)
    else:
        video_ids = [f.stem for f in TRANSCRIPT_DIR.glob("*.json")]

    print(f"Videos to process: {len(video_ids)}")
    print(f"Model: {MODEL} | Context: {NUM_CTX} | Timeout: {TIMEOUT_PER_CHUNK}s")
    print()

    stats = {"total": len(video_ids), "success": 0, "empty": 0, "failed": 0,
             "skipped": 0, "total_restaurants": 0, "total_dishes": 0}

    for i, vid in enumerate(video_ids):
        print(f"[{i+1}/{len(video_ids)}] Extracting {vid}...")
        try:
            result, status = extract_video(vid, system_prompt)
            stats[status] = stats.get(status, 0) + 1
            if result and result.get("restaurants"):
                r_count = len(result["restaurants"])
                d_count = sum(len(r.get("dishes", [])) for r in result["restaurants"])
                stats["total_restaurants"] += r_count
                stats["total_dishes"] += d_count
                print(f"  ✅ {r_count} restaurants, {d_count} dishes\n")
            elif status == "skipped":
                print()
            else:
                print(f"  ⚠️ {status}\n")
        except Exception as e:
            print(f"  ❌ Unexpected error: {e}\n")
            log_error(vid, f"Unexpected: {str(e)}")
            stats["failed"] += 1

    print("=" * 60)
    print("EXTRACTION SUMMARY")
    print("=" * 60)
    print(f"  Total videos:      {stats['total']}")
    print(f"  Successful:        {stats['success']}")
    print(f"  Empty (no data):   {stats['empty']}")
    print(f"  Failed:            {stats['failed']}")
    print(f"  Skipped (resume):  {stats['skipped']}")
    print(f"  Total restaurants: {stats['total_restaurants']}")
    print(f"  Total dishes:      {stats['total_dishes']}")
    print("=" * 60)

if __name__ == "__main__":
    main()
```

---

## Step 3: Clear Previous Artifacts and Run

```bash
# Clean up v1.8 extraction debris
rm -f data/extracted/*.json data/extracted/*_raw.txt
rm -f data/logs/phase-3-errors.jsonl

# Restart Ollama fresh (clear VRAM fragmentation from v1.8)
systemctl --user restart ollama
sleep 10

# Run pre-flight
python3 scripts/pre_flight.py

# Run extraction — start with the 3 shortest clips
python3 scripts/phase3_extract.py --video BwfqvpCAdeQ
```

If the single-video test produces a JSON with at least 1 restaurant, immediately proceed to the full 10-video batch:

```bash
python3 scripts/phase3_extract.py --batch config/extract_test_10.txt
```

If the single-video test fails again:
- Check `ollama ps` — is qwen3.5:9b loaded? What processor split?
- If showing >50% CPU: there's VRAM contention from other processes. Run `nvidia-smi` and kill non-essential GPU processes
- If the model loads but generates empty JSON: the extraction prompt may need further revision. Try running a raw test:

```bash
ollama run qwen3.5:9b "List 3 famous restaurants. Reply as JSON only."
```

If that produces valid JSON, the issue is in the prompt or transcript content, not the model.

---

## Step 4: Extract All 30 Test Videos

After the 10-video batch succeeds, run the full test batch:

```bash
python3 scripts/phase3_extract.py --batch config/test_batch.txt
```

The script has resume support — it skips videos that already have valid extracted JSON. So the 10 already-extracted videos will be skipped automatically.

**Expected times (GPU inference with 8K context):**
- Clips (<15 min, 1 chunk each): ~1-2 min per video
- Standard episodes (~22 min, 1-2 chunks): ~2-4 min per video
- Compilations (~30 min, 2-3 chunks): ~4-8 min per video
- Marathons (1-4 hrs, 5-20 chunks): ~15-60 min per video

**Total estimated: 1-3 hours for all 30 videos**

---

## Step 5: Validate Extraction Quality

After extraction completes, run this validation:

```python
#!/usr/bin/env python3
"""validate_extraction.py — Run from pipeline/ directory"""
import json, glob, os

print("=== EXTRACTION VALIDATION ===\n")

files = sorted(glob.glob("data/extracted/*.json"))
print(f"Extracted files: {len(files)}")

total_r, total_d = 0, 0
empty_videos = []
video_types = {}
guy_intro_count = 0
guy_response_count = 0
ingredient_count = 0
total_ingredient_lists = 0

for f in files:
    if "_raw" in f:
        continue
    with open(f) as fh:
        data = json.load(fh)

    vid = data.get("video_id", os.path.basename(f))
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
            if d.get("guy_response"):
                guy_response_count += 1
            if d.get("ingredients"):
                ingredient_count += 1
            total_ingredient_lists += 1

    total_r += r_count
    total_d += d_count
    print(f"  {vid}: {vtype} — {r_count} restaurants, {d_count} dishes")

print(f"\n--- TOTALS ---")
print(f"  Videos extracted:    {len(files)}")
print(f"  Videos with data:    {len(files) - len(empty_videos)}")
print(f"  Videos empty:        {len(empty_videos)}")
print(f"  Total restaurants:   {total_r}")
print(f"  Total dishes:        {total_d}")
print(f"  Avg dishes/restaurant: {total_d/max(total_r,1):.1f}")
print(f"  Video types:         {video_types}")
print(f"  guy_intro captured:  {guy_intro_count}/{total_r} ({guy_intro_count/max(total_r,1)*100:.0f}%)")
print(f"  guy_response captured: {guy_response_count}/{total_d} ({guy_response_count/max(total_d,1)*100:.0f}%)")
print(f"  ingredients captured:  {ingredient_count}/{total_ingredient_lists} ({ingredient_count/max(total_ingredient_lists,1)*100:.0f}%)")

if empty_videos:
    print(f"\n  Empty videos: {', '.join(empty_videos)}")

# Success criteria from ddd-plan-v1.8.md
print(f"\n--- SUCCESS CRITERIA ---")
criteria = [
    ("Extracted files >= 25 (of 30)", len(files) >= 25),
    ("Restaurants found > 0", total_r > 0),
    ("Avg dishes/restaurant >= 1.5", total_d/max(total_r,1) >= 1.5),
    ("guy_intro capture > 30%", guy_intro_count/max(total_r,1) > 0.3),
    ("guy_response capture > 30%", guy_response_count/max(total_d,1) > 0.3),
    ("ingredients capture > 40%", ingredient_count/max(total_ingredient_lists,1) > 0.4),
]
for name, passed in criteria:
    print(f"  {'✅' if passed else '❌'} {name}")
```

Create this as `scripts/validate_extraction.py` and run it.

---

## Step 6: Generate Report Artifacts

After validation, create two files:

### docs/ddd-report-v1.9.md

Template:

```markdown
# TripleDB Phase 1 (Iteration 9) - Execution Report

## Overview
- **Phase:** 1 — Discovery (retry)
- **Goal:** Successful extraction from 30 test video transcripts
- **Result:** [PASS/FAIL — fill based on validation output]
- **Date:** [today's date]

## Pre-Flight
- [paste pre_flight.py output]

## Extraction Results
- [paste extraction summary]

## Validation Results
- [paste validate_extraction.py output]

## Issues Encountered & Self-Healing Actions
- [list every error that was hit and how it was resolved]

## Hardware Observations
- Model: qwen3.5:9b
- Context: 8192
- VRAM split: [from ollama ps during extraction]
- Per-video extraction time: [average]

## Architectural Decisions
- [any changes made to scripts or config during execution]

## Recommendation
- [PROCEED to Phase 2 / RE-RUN as v1.10 with changes]
```

### docs/ddd-build-v1.9.md

A chronological log of every action taken during this session — what commands were run, what errors were hit, what fixes were applied. This is the session memory.

---

## Phase 1.9 Success Criteria (lowered from v1.8 to match reality)

```
[ ] Pre-flight passes all checks
[ ] At least 1 video produces valid JSON with restaurants and dishes
[ ] At least 20 of 30 videos produce extracted JSON files
[ ] Total restaurants found > 30
[ ] Total dishes found > 50
[ ] No indefinite hangs (all operations complete or timeout+skip)
[ ] ddd-report-v1.9.md generated with metrics
[ ] ddd-build-v1.9.md generated with session transcript
```

The thresholds are intentionally lower than v1.8's plan — the goal of v1.9 is to prove extraction works AT ALL. Quality tuning (guy_intro capture rates, ingredient accuracy, etc.) is Phase 2's job.

---

## Gemini CLI Opening Prompt

Paste this into Gemini when starting:

```
Read GEMINI.md for project context.

We are starting Phase 1.9 — a retry of Phase 1 Discovery. Phase 1.8 
failed at extraction. Downloads and transcription are already done 
(30/30 videos). This iteration focuses on getting extraction working.

Read docs/ddd-plan-v1.9.md for the complete execution plan. It contains:
- Autonomy rules (auto-proceed, self-heal, no permission prompts)
- Pre-flight check script
- Slimmed extraction prompt
- Complete rewritten extraction script with chunking and streaming
- Validation script
- Report templates

Execute the plan from Step 0 through Step 6. Follow the autonomy rules 
exactly. Do not ask permission between steps. If you hit an error, 
diagnose and fix it yourself (max 3 attempts, then log and skip).

When complete, generate docs/ddd-report-v1.9.md and docs/ddd-build-v1.9.md.

Begin with Step 0: create and run scripts/pre_flight.py.
```
