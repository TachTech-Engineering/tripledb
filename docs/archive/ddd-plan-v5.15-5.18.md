# TripleDB — Phase 5 Production Plan v5.15–5.18

**Phase:** 5 — Production Run (Graduated)
**Iterations:** 15–18
**Date:** March 2026
**Goal:** Process remaining ~685 videos in graduated timeout passes, then do a final quality/normalization sweep before Phase 6.

---

## Why Graduated Passes

A single 70-hour run with a 1800s timeout would work but wastes time waiting on marathons while hundreds of clips sit unprocessed behind them. Instead:

| Iteration | Timeout | Target Content | Expected Yield |
|-----------|---------|---------------|----------------|
| v5.15 | 600s (10 min) | Clips, episodes, short compilations | ~500-550 videos |
| v5.16 | 1200s (20 min) | Longer compilations, short marathons | ~80-120 videos |
| v5.17 | 1800s (30 min) | Full marathons | ~30-50 videos |
| v5.18 | N/A | Quality sweep — normalize all, feed reports to Claude | Cleanup only |

Each pass uses `--all` mode with resume support. Already-processed videos are skipped automatically. The timeout only affects transcription and extraction — downloads are fast regardless.

---

## Runner Modification

Replace `scripts/group_b_runner.sh` with a version that accepts a timeout parameter:

```bash
#!/usr/bin/env bash
# group_b_runner.sh — Graduated production run.
# Usage: ./scripts/group_b_runner.sh [TIMEOUT_SECONDS]
# Default: 600
#
# Run in tmux:
#   tmux new -s tripledb './scripts/group_b_runner.sh 600 2>&1 | tee data/logs/group_b_5.15.log'

set -euo pipefail
cd "$(dirname "$0")/.."  # Ensure we're in pipeline/

TIMEOUT=${1:-600}
TOTAL_START=$(date +%s)
LOG_DIR="data/logs"
mkdir -p "$LOG_DIR"

echo "=========================================="
echo "TripleDB Group B Production Run"
echo "Timeout: ${TIMEOUT}s"
echo "Started: $(date)"
echo "=========================================="

# ── Phase 1: Download remaining videos ──────────────────────
echo ""
echo "=== Phase 1: Download ==="
python3 scripts/phase1_acquire.py --all
DOWNLOAD_END=$(date +%s)
echo "Download complete: $(date) ($(( (DOWNLOAD_END - TOTAL_START) / 60 )) min)"

# ── Phase 2: Transcribe ────────────────────────────────────
echo ""
echo "=== Phase 2: Transcribe (timeout: ${TIMEOUT}s) ==="

# Kill any GPU-hogging processes
pkill -f "ollama" 2>/dev/null || true
sleep 2
nvidia-smi --query-compute-apps=pid --format=csv,noheader 2>/dev/null | while read pid; do
    if [ -n "$pid" ]; then
        echo "WARNING: GPU process $pid still running, killing..."
        kill "$pid" 2>/dev/null || true
    fi
done
sleep 2

LD_LIBRARY_PATH=/usr/local/lib/ollama/cuda_v12:${LD_LIBRARY_PATH:-} \
    TRANSCRIBE_TIMEOUT=$TIMEOUT \
    python3 scripts/phase2_transcribe.py --all

TRANSCRIBE_END=$(date +%s)
echo "Transcription complete: $(date) ($(( (TRANSCRIBE_END - DOWNLOAD_END) / 60 )) min)"

# ── Phase 3: Extract ────────────────────────────────────────
echo ""
echo "=== Phase 3: Extract (timeout: ${TIMEOUT}s) ==="
EXTRACT_TIMEOUT=$TIMEOUT python3 scripts/phase3_extract_gemini.py --all

EXTRACT_END=$(date +%s)
echo "Extraction complete: $(date) ($(( (EXTRACT_END - TRANSCRIBE_END) / 60 )) min)"

# ── Validate ────────────────────────────────────────────────
echo ""
echo "=== Validation ==="
python3 scripts/validate_extraction.py

# ── Summary ─────────────────────────────────────────────────
TOTAL_END=$(date +%s)
ELAPSED_MIN=$(( (TOTAL_END - TOTAL_START) / 60 ))
ELAPSED_HR=$(( ELAPSED_MIN / 60 ))

echo ""
echo "=========================================="
echo "Production Run Complete"
echo "Timeout: ${TIMEOUT}s"
echo "Finished: $(date)"
echo "Total runtime: ${ELAPSED_HR}h ${ELAPSED_MIN}m"
echo "=========================================="
echo ""
echo "Counts:"
echo "  Audio files:  $(ls data/audio/*.mp3 2>/dev/null | wc -l)"
echo "  Transcripts:  $(ls data/transcripts/*.json 2>/dev/null | wc -l)"
echo "  Extractions:  $(ls data/extracted/*.json 2>/dev/null | wc -l)"
echo ""
echo "NEXT: Review this log, then relaunch with higher timeout or proceed to normalization."
```

**IMPORTANT:** The scripts need to respect the `TRANSCRIBE_TIMEOUT` and `EXTRACT_TIMEOUT` environment variables. Before launching, verify:

```bash
# Check that phase2_transcribe.py reads TRANSCRIBE_TIMEOUT
grep -n "TRANSCRIBE_TIMEOUT\|signal.alarm\|timeout" scripts/phase2_transcribe.py

# Check that phase3_extract_gemini.py reads EXTRACT_TIMEOUT
grep -n "EXTRACT_TIMEOUT\|timeout" scripts/phase3_extract_gemini.py
```

If the scripts use hardcoded timeouts, update them to read from env:

**phase2_transcribe.py** — find the `signal.alarm(600)` line and replace with:
```python
timeout_seconds = int(os.environ.get("TRANSCRIBE_TIMEOUT", "600"))
signal.alarm(timeout_seconds)
```

**phase3_extract_gemini.py** — find the `timeout=300` in the requests call and replace with:
```python
timeout_seconds = int(os.environ.get("EXTRACT_TIMEOUT", "300"))
resp = requests.post(..., timeout=timeout_seconds)
```

---

## v5.15 — First Pass (Clips, Episodes, Short Compilations)

**Timeout:** 600s
**Expected:** Processes ~500-550 of 685 remaining videos (everything under ~20 min of audio)
**Runtime estimate:** 8-12 hours

### Launch

```bash
cd ~/dev/projects/tripledb
git add .
git commit -m "KT starting 5.15"

cd pipeline
tmux new -s tripledb './scripts/group_b_runner.sh 600 2>&1 | tee data/logs/group_b_5.15.log'
```

### After Completion

```bash
# Check results
tail -50 data/logs/group_b_5.15.log

# Count what got processed vs skipped
echo "Transcripts: $(ls data/transcripts/*.json | wc -l)"
echo "Extractions: $(ls data/extracted/*.json | wc -l)"

# See what was skipped (timed out)
grep -c "timed out\|Timed out\|timeout\|TIMEOUT" data/logs/group_b_5.15.log

# Commit
git add docs/ scripts/ config/ README.md
git commit -m "KT completed 5.15 — first production pass (600s timeout)"
git push
```

---

## v5.16 — Second Pass (Longer Compilations)

**Timeout:** 1200s
**Expected:** Processes ~80-120 videos that were skipped in v5.15
**Runtime estimate:** 12-20 hours

### Launch

```bash
cd ~/dev/projects/tripledb/pipeline
tmux new -s tripledb './scripts/group_b_runner.sh 1200 2>&1 | tee data/logs/group_b_5.16.log'
```

### After Completion

```bash
tail -50 data/logs/group_b_5.16.log
echo "Transcripts: $(ls data/transcripts/*.json | wc -l)"
echo "Extractions: $(ls data/extracted/*.json | wc -l)"
grep -c "timed out\|Timed out" data/logs/group_b_5.16.log

git add docs/ scripts/ config/ README.md
git commit -m "KT completed 5.16 — second pass (1200s timeout)"
git push
```

---

## v5.17 — Third Pass (Marathons)

**Timeout:** 1800s
**Expected:** Processes ~30-50 remaining marathon videos
**Runtime estimate:** 15-30 hours

### Launch

```bash
cd ~/dev/projects/tripledb/pipeline
tmux new -s tripledb './scripts/group_b_runner.sh 1800 2>&1 | tee data/logs/group_b_5.17.log'
```

### After Completion

```bash
tail -50 data/logs/group_b_5.17.log
echo "Transcripts: $(ls data/transcripts/*.json | wc -l)"
echo "Extractions: $(ls data/extracted/*.json | wc -l)"

# Identify any remaining unprocessed videos
python3 -c "
import os, re
processed = set(f.replace('.json','') for f in os.listdir('data/extracted') if f.endswith('.json'))
total = 0
remaining = []
for line in open('config/playlist_urls.txt'):
    if not line.strip() or line.startswith('#'):
        continue
    total += 1
    match = re.search(r'v=([a-zA-Z0-9_-]{11})', line)
    if match and match.group(1) not in processed:
        remaining.append(line.strip()[:80])
print(f'Total: {total}')
print(f'Processed: {len(processed)}')
print(f'Remaining: {total - len(processed)}')
for r in remaining[:20]:
    print(f'  {r}')
"

git add docs/ scripts/ config/ README.md
git commit -m "KT completed 5.17 — third pass (1800s timeout)"
git push
```

Any videos still unprocessed after 1800s are genuine edge cases (4+ hour marathons exceeding token limits). Log them and move on — they can be manually chunked later or accepted as gaps.

---

## v5.18 — Quality Sweep & Normalization

This is NOT a tmux run. This is a Gemini CLI interactive session (or manual + Claude review) to:

1. **Run final normalization** across ALL ~800 processed videos
2. **Generate comprehensive quality report** for Claude review
3. **Identify remaining data quality issues** before Phase 6

### Step 1: Full Normalization

```bash
cd ~/dev/projects/tripledb/pipeline
python3 scripts/phase4_normalize.py
```

### Step 2: Generate Quality Report

```bash
python3 scripts/validate_extraction.py > data/logs/full_validation_report.txt 2>&1

python3 -c "
import json
from collections import Counter

restaurants = [json.loads(l) for l in open('data/normalized/restaurants.jsonl')]
print(f'=== FULL DATASET QUALITY REPORT ===')
print(f'Total restaurants: {len(restaurants)}')
print(f'Total dishes: {sum(len(r.get(\"dishes\",[])) for r in restaurants)}')
print(f'Total visits: {sum(len(r.get(\"visits\",[])) for r in restaurants)}')
print()

# State distribution
states = Counter(r.get('state','?') for r in restaurants)
print(f'States: {len(states)} unique')
print(f'  UNKNOWN: {states.get(\"UNKNOWN\", 0)}')
for s, c in states.most_common(10):
    print(f'  {s}: {c}')
print()

# Null fields
null_name = sum(1 for r in restaurants if not r.get('name'))
null_chef = sum(1 for r in restaurants if not r.get('owner_chef'))
null_cuisine = sum(1 for r in restaurants if not r.get('cuisine_type'))
print(f'Null name: {null_name}')
print(f'Null owner_chef: {null_chef} ({null_chef/len(restaurants)*100:.1f}%)')
print(f'Null cuisine: {null_cuisine}')
print()

# Dishes per restaurant
dishes_per = [len(r.get('dishes',[])) for r in restaurants]
print(f'Dishes/restaurant: avg={sum(dishes_per)/len(dishes_per):.2f}, min={min(dishes_per)}, max={max(dishes_per)}')
zero_dish = sum(1 for d in dishes_per if d == 0)
print(f'Restaurants with 0 dishes: {zero_dish}')
print()

# Multi-visit restaurants
multi = [r for r in restaurants if len(r.get('visits',[])) >= 3]
print(f'Restaurants with 3+ visits: {len(multi)}')
for r in sorted(multi, key=lambda x: -len(x.get('visits',[])))[:10]:
    print(f'  {r[\"name\"]} ({r.get(\"city\",\"?\")}): {len(r[\"visits\"])} visits, {len(r.get(\"dishes\",[]))} dishes')

# Dedup report
try:
    merges = [json.loads(l) for l in open('data/logs/phase-4-dedup-report.jsonl')]
    print(f'\nDedup merges: {len(merges)}')
except:
    print('\nNo dedup report found')

# Null records log
try:
    nulls = [json.loads(l) for l in open('data/logs/phase-4-null-records.jsonl')]
    print(f'Null-name records filtered: {len(nulls)}')
except:
    print('No null records log found')
" > data/logs/full_quality_report.txt 2>&1

cat data/logs/full_quality_report.txt
```

### Step 3: Upload Reports to Claude

After the quality report is generated, upload these files to a new Claude conversation:

1. `data/logs/full_quality_report.txt`
2. `data/logs/full_validation_report.txt`
3. `data/logs/phase-4-dedup-report.jsonl` (or a summary if too large)
4. `data/logs/phase-4-null-records.jsonl`
5. `docs/ddd-design-v5.14.md` (for context)
6. A sample of `data/normalized/restaurants.jsonl` (first 50 lines)

Ask Claude to:
- Identify remaining data quality issues
- Flag suspicious dedup merges (false positives)
- Identify restaurants with 0 dishes that should have dishes
- Recommend any final normalization fixes before Phase 6
- Assess whether the dataset is ready for Firestore load

### Step 4: Apply Fixes and Final Normalize

Based on Claude's recommendations, apply any fixes to `phase4_normalize.py` and re-run.

### Step 5: Commit

```bash
cd ~/dev/projects/tripledb
git add docs/ scripts/ config/ README.md
git commit -m "KT completed 5.18 — final quality sweep, ready for Phase 6"
git push
```

---

## Timing Estimate

| Pass | Runtime | Cumulative |
|------|---------|------------|
| v5.15 (600s) | 8-12 hrs | 8-12 hrs |
| v5.16 (1200s) | 12-20 hrs | 20-32 hrs |
| v5.17 (1800s) | 15-30 hrs | 35-62 hrs |
| v5.18 (quality) | 1-2 hrs (interactive) | 36-64 hrs |

Total: roughly 2-3 days of wall clock time, mostly unattended.

---

## Between Passes Checklist

After each tmux run completes:

```
[ ] Review the log: tail -100 data/logs/group_b_5.XX.log
[ ] Count processed: ls data/transcripts/*.json | wc -l
[ ] Count extractions: ls data/extracted/*.json | wc -l
[ ] Check for errors: grep -c "ERROR\|FAIL\|error" data/logs/group_b_5.XX.log
[ ] Check timeouts: grep -c "timed out\|Timed out" data/logs/group_b_5.XX.log
[ ] Commit results: git add . && git commit -m "KT completed 5.XX" && git push
[ ] Launch next pass (if applicable)
```

---

## Script Pre-Check Before First Launch

Before launching v5.15, verify the timeout env vars are wired up:

```bash
# 1. Update phase2_transcribe.py timeout to read from env
grep "signal.alarm" scripts/phase2_transcribe.py
# Should show: signal.alarm(int(os.environ.get("TRANSCRIBE_TIMEOUT", "600")))
# If hardcoded, fix it.

# 2. Update phase3_extract_gemini.py timeout to read from env
grep "timeout=" scripts/phase3_extract_gemini.py
# Should show: timeout=int(os.environ.get("EXTRACT_TIMEOUT", "300"))
# If hardcoded, fix it.

# 3. Make runner executable
chmod +x scripts/group_b_runner.sh

# 4. Test runner syntax
bash -n scripts/group_b_runner.sh && echo "Syntax OK"
```
