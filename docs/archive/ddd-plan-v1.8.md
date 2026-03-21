# TripleDB — Phase 1 Plan v1.8

**Phase:** 1 — Discovery
**Iteration:** 8 (global project iteration)
**Date:** March 20, 2026
**Machine:** NZXTcos (i9-13900K, 64GB, RTX 2080 SUPER)
**Goal:** "Does the pipeline work at all?" — download 30 test videos, transcribe them, run first extraction on 10, evaluate quality.

---

## Reference Docs

- `docs/ddd-design-architecture-v6.md` — data model, extraction prompt, agent personas
- `docs/ddd-project-setup-v6.md` — tool config and known issues
- `docs/ddd-phase-prompts-v6.md` — execution strategy, Group A/B architecture

---

## Pre-Flight Checklist

```
[ ] Phase 0 complete: all boxes checked in ddd-plan-v0.7.md
[ ] playlist_urls.txt exists (805 URLs)
[ ] test_batch.txt exists (30 videos: 5 clips, 10 standard, 10 compilations, 5 marathons)
[ ] Ollama running: ollama list shows nemotron-super + qwen3.5:9b
[ ] faster-whisper importable: python3 -c "from faster_whisper import WhisperModel; print('OK')"
[ ] yt-dlp current: yt-dlp --version
[ ] GPU available: nvidia-smi shows RTX 2080 SUPER
```

---

## Step 1: Download Test Batch (est. ~30 min)

### 1a. Create the download script

Open Gemini CLI from the pipeline directory:

```bash
cd ~/dev/projects/tripledb/pipeline
gemini
```

Paste this prompt:

```
Read GEMINI.md for project context.

## Phase 1: Create Download Script

Create scripts/phase1_acquire.py that:

1. Accepts a --batch flag pointing to a URL file (one URL per line).
   Lines starting with # are comments and should be skipped.
   Example: python3 scripts/phase1_acquire.py --batch config/test_batch.txt

2. Also accepts --all flag to process config/playlist_urls.txt.
   Example: python3 scripts/phase1_acquire.py --all

3. For each URL, runs yt-dlp with these flags:
   - -x (extract audio only)
   - --audio-format mp3
   - --audio-quality 0 (highest quality VBR)
   - --cookies-from-browser chrome
   - --sleep-interval 5 --max-sleep-interval 30
   - --output "data/audio/%(id)s.%(ext)s"
   - --write-info-json
   - --no-overwrites

4. Resume support: if data/audio/{video_id}.mp3 already exists, skip.

5. After all downloads, generates data/audio/manifest.csv with columns:
   video_id, title, duration_seconds, youtube_url, download_status

   download_status is one of: success, skipped (already exists),
   failed (with error reason), unavailable

6. Prints progress: "Downloading 1/30: [title]... done [15s]"

7. At the end prints summary: total, success, skipped, failed.

8. Error handling:
   - Unavailable video: log "unavailable" in manifest, continue
   - Rate limited: the sleep flags handle this
   - Geo-blocked: log "geo-blocked" in manifest, continue
   - yt-dlp crash: log error, continue to next

Present the script for review. Do NOT commit.
```

### 1b. Review and run

Review the script, then run it:

```bash
python3 scripts/phase1_acquire.py --batch config/test_batch.txt
```

Expected: ~30 mp3 files in `data/audio/`, each named by video ID (e.g., `fqi0tOGh7r0.mp3`).

### 1c. Verify downloads

```bash
ls -lh data/audio/*.mp3 | wc -l
# Expected: ~30 (some may fail)

ls -lh data/audio/*.mp3 | head -5
# Check file sizes: clips ~5-10 MB, standard ~15-25 MB, marathons ~100+ MB

cat data/audio/manifest.csv | head -10
# Verify manifest looks correct
```

Spot-check: play 30 seconds of 3 random mp3s to confirm they're real DDD content.

```bash
# Quick audio check (if mpv or vlc installed)
mpv --length=30 data/audio/fqi0tOGh7r0.mp3
```

---

## Step 2: Transcribe Test Batch (est. ~30-90 min on CUDA)

### 2a. Stop Ollama to free GPU

```bash
systemctl --user stop ollama
```

Faster-whisper and Ollama both want the RTX 2080 SUPER's 8GB VRAM. They can't share. Whisper runs first, then we restart Ollama for extraction.

### 2b. Create the transcription script

Back in Gemini CLI (or start a new session):

```
Read GEMINI.md for project context. Load the agent persona from
agents/ddd-transcriber.md.

## Phase 1: Create Transcription Script

Create scripts/phase2_transcribe.py that:

1. Accepts --batch (file of URLs/video IDs) or --all (uses manifest).
   In --batch mode, extract video IDs from the URLs in the batch file.
   In --all mode, read video IDs from data/audio/manifest.csv where
   download_status = "success".
   Example: python3 scripts/phase2_transcribe.py --batch config/test_batch.txt

2. For each video ID, checks if data/audio/{video_id}.mp3 exists.
   If not, skip with warning.

3. Transcribes using faster-whisper:
   ```python
   from faster_whisper import WhisperModel

   model = WhisperModel("large-v3", device="cuda", compute_type="float16")

   segments, info = model.transcribe(
       mp3_path,
       language="en",
       beam_size=5,
       vad_filter=True,
       vad_parameters=dict(
           min_silence_duration_ms=500,
           speech_pad_ms=400
       )
   )
   ```

4. Output: one JSON file per video at data/transcripts/{video_id}.json:
   ```json
   {
     "video_id": "fqi0tOGh7r0",
     "source_file": "data/audio/fqi0tOGh7r0.mp3",
     "model": "large-v3",
     "language": "en",
     "duration_seconds": 1619.0,
     "segments": [
       {
         "start": 0.0,
         "end": 4.2,
         "text": "Welcome to Diners, Drive-Ins and Dives.",
         "confidence": 0.95
       }
     ],
     "low_confidence_count": 3,
     "total_segments": 450
   }
   ```

5. Flag segments with average confidence < 0.7 by adding
   "low_confidence": true to those segments.

6. Resume support: if data/transcripts/{video_id}.json exists and is
   valid JSON, skip that video.

7. Print progress: "Transcribing fqi0tOGh7r0 (1/30)... done (450 segments,
   3 low-confidence) [2m 15s]"

8. Error handling: log failures to data/logs/phase-2-errors.jsonl,
   continue to next file.

9. At the end, print summary: total processed, total segments,
   total low-confidence segments, total errors.

10. Load the model ONCE at startup, not per-file. Model loading takes
    ~10-15 seconds and should only happen once.

Present the script for review. Do NOT commit.
```

### 2c. Run transcription

```bash
python3 scripts/phase2_transcribe.py --batch config/test_batch.txt
```

**Time estimates for the 30-video test batch (CUDA):**
- 5 clips (~10 min each): ~5 min total
- 10 standard (~22 min each): ~15 min total
- 10 compilations (~30 min avg): ~20 min total
- 5 marathons (1-4 hrs each): ~30-60 min total
- **Total: ~60-90 min on CUDA**

Let it run. If CUDA OOM errors occur, the script should fall back or you can restart with `device="cpu"`.

### 2d. Verify transcripts

```bash
ls data/transcripts/*.json | wc -l
# Expected: matches successful download count

# Check a standard episode transcript
python3 -c "
import json
with open('data/transcripts/otZTFDdvnrU.json') as f:
    t = json.load(f)
print(f'Segments: {t[\"total_segments\"]}')
print(f'Duration: {t[\"duration_seconds\"]:.0f}s')
print(f'Low confidence: {t[\"low_confidence_count\"]}')
print(f'First segment: {t[\"segments\"][0][\"text\"]}')
"

# Check a marathon transcript
python3 -c "
import json
with open('data/transcripts/bawGcAsAA-w.json') as f:
    t = json.load(f)
print(f'Segments: {t[\"total_segments\"]}')
print(f'Duration: {t[\"duration_seconds\"]:.0f}s')
print(f'Low confidence: {t[\"low_confidence_count\"]}')
"
```

**What to look for:**
- Standard episodes: ~300-500 segments, ~1300s duration
- Marathons: ~3000-10000 segments, ~15000s duration for the 4-hr one
- Low confidence segments: ideally <10% of total
- First segment text should be recognizable DDD content

---

## Step 3: First Extraction — 10 Videos (est. ~20-30 min)

### 3a. Restart Ollama

```bash
systemctl --user start ollama
# Wait a few seconds for model to be available
ollama list
```

### 3b. Create the extraction script

```
Read GEMINI.md for project context. Load the agent persona from
agents/ddd-extractor.md. Read the extraction prompt template from
config/extraction_prompt.md.

## Phase 1: Create Extraction Script

Create scripts/phase3_extract.py that:

1. Accepts --batch (file of URLs/video IDs) or --all (processes all
   transcripts in data/transcripts/).
   Example: python3 scripts/phase3_extract.py --batch config/test_batch.txt

2. When --batch is used, only processes videos whose IDs appear in
   the batch file. Extracts video_id from URLs.

3. For each video ID, reads data/transcripts/{video_id}.json.
   If transcript doesn't exist, skip with warning.

4. Builds the full transcript text from segments:
   ```python
   full_text = "\n".join(
       f"[{seg['start']:.1f}s] {seg['text']}"
       for seg in transcript["segments"]
   )
   ```

5. Sends to Ollama via the chat API:
   ```python
   import requests
   import json

   response = requests.post("http://localhost:11434/api/chat", json={
       "model": "nemotron-super",
       "messages": [
           {"role": "system", "content": extraction_prompt},
           {"role": "user", "content": f"Video ID: {video_id}\nVideo Title: {title}\n\nTranscript:\n{full_text}"}
       ],
       "stream": False,
       "options": {
           "temperature": 0.1,
           "num_ctx": 32768
       }
   })
   ```

6. The system prompt is the content of config/extraction_prompt.md.
   The user message includes video_id, video_title (from manifest or
   info.json), and the full transcript.

7. Parses the JSON response. If the response isn't valid JSON,
   tries to extract JSON from markdown code blocks in the response.

8. Output: one JSON per video at data/extracted/{video_id}.json.

9. Validates each extraction:
   - Must have a "restaurants" array
   - Each restaurant must have name, city, state, and at least one dish
   - Logs validation failures to data/logs/phase-3-errors.jsonl
   - Saves even invalid extractions with a "_invalid" suffix for review

10. Resume support: skip videos with existing valid output.

11. Handles Ollama errors:
    - Timeout (>300s for marathons, >120s for others): retry once, log, skip
    - Invalid JSON response: save raw response as {video_id}_raw.txt, log, skip
    - Connection refused: abort with "Is Ollama running?"

12. Prints progress: "Extracting fqi0tOGh7r0 (1/10)... done (3 restaurants,
    8 dishes) [2m 15s]"

13. Summary at end: videos processed, total restaurants, total dishes,
    validation failures.

Present the script for review. Do NOT commit.
```

### 3c. Run extraction on 10 videos only

For the first extraction test, pick 10 videos that represent the mix. Create a mini batch:

```bash
# Pick 3 clips, 4 standard, 2 compilations, 1 marathon
head -8 config/test_batch.txt > config/extract_test_10.txt
# Then add a couple more from the compilations and one marathon
# Or just manually create it with 10 URLs from test_batch.txt
nano config/extract_test_10.txt
```

Suggested 10 for first extraction:

```
# First extraction test — 10 videos
https://www.youtube.com/watch?v=BwfqvpCAdeQ  # Clip: Lao Rice Ball [9:27]
https://www.youtube.com/watch?v=ILVeTE6416Q  # Clip: Hot Dogs Reseda [10:57]
https://www.youtube.com/watch?v=CFSLE4rFbPI  # Clip: Cheeseburger NYC [12:54]
https://www.youtube.com/watch?v=5FlI4pCEnbA  # Standard: Fred's Texas Cafe [21:17]
https://www.youtube.com/watch?v=r8OqkxuHO5Y  # Standard: BBQ Portland [22:02]
https://www.youtube.com/watch?v=eut9zhDgvIk  # Standard: Pittsburgh Pancakes [22:55]
https://www.youtube.com/watch?v=2Y4A0FQVhEU  # Standard: Pizza Dallas [23:53]
https://www.youtube.com/watch?v=fqi0tOGh7r0  # Compilation: Cleveland [26:59]
https://www.youtube.com/watch?v=8n8C91eU1Os  # Compilation: Southern BBQ [26:06]
https://www.youtube.com/watch?v=CgPqS91kAWo  # Marathon: Best of Season 8 [1:00:03]
```

Run:

```bash
python3 scripts/phase3_extract.py --batch config/extract_test_10.txt
```

---

## Step 4: Review Extraction Quality

This is the most important step in Phase 1. The extraction output determines if the pipeline is viable or needs fundamental changes.

### 4a. Quick stats

```bash
# Count restaurants and dishes across all extractions
python3 -c "
import json, glob
total_r, total_d = 0, 0
for f in sorted(glob.glob('data/extracted/*.json')):
    with open(f) as fh:
        data = json.load(fh)
    r = len(data.get('restaurants', []))
    d = sum(len(rest.get('dishes', [])) for rest in data.get('restaurants', []))
    print(f'{f.split(\"/\")[-1]}: {r} restaurants, {d} dishes')
    total_r += r
    total_d += d
print(f'\nTotal: {total_r} restaurants, {total_d} dishes from {len(glob.glob(\"data/extracted/*.json\"))} videos')
"
```

**Expected ranges:**
- Clips: 1 restaurant, 1-3 dishes each
- Standard episodes: 2-3 restaurants, 5-10 dishes total
- Compilations: 3-8 restaurants
- Marathon (1 hr): 8-15 restaurants

### 4b. Deep review — pick 3 extractions

Open 3 extraction JSONs and verify against the actual video:

```bash
# Pick one clip, one standard, one compilation
cat data/extracted/CFSLE4rFbPI.json | python3 -m json.tool | head -50
cat data/extracted/5FlI4pCEnbA.json | python3 -m json.tool | head -80
cat data/extracted/fqi0tOGh7r0.json | python3 -m json.tool | head -100
```

**Review checklist for each extraction:**

```
[ ] Restaurant name — correct? (cross-reference with video title)
[ ] City/State — correct?
[ ] cuisine_type — reasonable?
[ ] owner_chef — captured? Correct name?
[ ] guy_intro — captured the arrival moment? Verbatim from transcript?
[ ] video_type — correctly classified? (clip/full_episode/compilation/marathon)
[ ] dishes:
    [ ] dish_name — real dish name from the video?
    [ ] description — accurate preparation details?
    [ ] ingredients — 3-8 key ingredients? Lowercase? Reasonable?
    [ ] dish_category — correct? (entree/dessert/side/etc)
    [ ] guy_response — captured? Verbatim? Not null when it shouldn't be?
    [ ] timestamp_start — roughly correct?
[ ] confidence scores — do they correlate with actual certainty?
[ ] segment_number — correct ordering?
```

### 4c. Check the marathon extraction

The 1-hour "Best of Season 8" is the stress test:

```bash
cat data/extracted/CgPqS91kAWo.json | python3 -m json.tool | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(f'Video type: {data.get(\"video_type\", \"?\")}')
print(f'Restaurants: {len(data.get(\"restaurants\", []))}')
for r in data.get('restaurants', []):
    dishes = len(r.get('dishes', []))
    print(f'  {r.get(\"name\", \"?\")} — {r.get(\"city\", \"?\")}, {r.get(\"state\", \"?\")} — {dishes} dishes')
"
```

### 4d. Identify issues

Write down every issue you find. Common Phase 1 problems:

| Issue | Likely Cause | Fix |
|-------|-------------|-----|
| Restaurant name wrong | Transcript was unclear | Lower confidence threshold, flag for review |
| guy_response always null | Extraction prompt doesn't emphasize capture | Revise prompt rule 7 |
| ingredients empty | Extraction prompt too vague on ingredients | Add more specific extraction examples |
| video_type always "full_episode" | Prompt doesn't distinguish types well | Add title-based classification hint |
| Marathon extraction truncated | Context window too small | Increase num_ctx to 65536 or higher |
| JSON parsing errors | Nemotron output isn't clean JSON | Add JSON extraction from markdown blocks |

---

## Step 5: Commit

```bash
cd ~/dev/projects/tripledb
git checkout -b phase/1-discovery
git add pipeline/scripts/phase1_acquire.py
git add pipeline/scripts/phase2_transcribe.py
git add pipeline/scripts/phase3_extract.py
git add pipeline/config/extract_test_10.txt
git add pipeline/data/audio/manifest.csv
git add pipeline/data/extracted/
# Do NOT add mp3s or transcripts — they're gitignored
git commit -m "KT Phase 1.8: download + transcribe + first extraction of 30 test videos"
git push -u origin phase/1-discovery
```

---

## Phase 1 Success Criteria

Before moving to Phase 2, ALL of these must be true:

```
[ ] Download script works: 28+ of 30 videos downloaded successfully
[ ] Transcription works: all downloaded videos transcribed, <10% low-confidence segments
[ ] Extraction produces valid JSON: 8+ of 10 extractions are valid, parseable JSON
[ ] Restaurant names are mostly correct: >80% match actual video content
[ ] Dishes are real: >80% of extracted dishes match what's actually in the video
[ ] guy_intro captured in >50% of restaurants (Phase 2 will push this higher)
[ ] guy_response captured in >50% of dishes (Phase 2 will push this higher)
[ ] ingredients present in >60% of dishes (Phase 2 will push this higher)
[ ] Marathon extraction doesn't crash or truncate
[ ] No blocking errors that prevent batch processing
```

If these are met: write `ddd-report-v1.8.md` with metrics and observations, then create `ddd-plan-v2.9.md` for Phase 2 Calibration.

If extraction quality is too low: revise `config/extraction_prompt.md`, re-run extraction on the same 10 videos, evaluate again. This becomes `ddd-plan-v1.9.md` (Phase 1, iteration 9 — still Discovery, second attempt).

---

## Time Estimate

| Step | Est. Time | Notes |
|------|-----------|-------|
| 1. Download 30 videos | ~30 min | YouTube throttling |
| 2. Transcribe 30 videos | ~60-90 min | CUDA, marathon is the long pole |
| 3. Extract 10 videos | ~20-30 min | Nemotron on GPU |
| 4. Review extraction | ~30-60 min | Manual, most important step |
| **Total** | **~2.5-3.5 hrs** | |
