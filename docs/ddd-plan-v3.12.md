# TripleDB — Phase 3 Plan v3.12

**Phase:** 3 — Stress Test
**Iteration:** 12 (global project iteration)
**Date:** March 21, 2026
**Goal:** Push the pipeline to its limits with marathons, edge cases, and heavy dedup overlap. Validate that extraction, normalization, and scripts can handle the worst-case content from the full 805-video playlist. Achieve near-zero human intervention.

---

## What Phase 3 Proves

Phase 1 proved the pipeline works. Phase 2 proved it scales to 60 videos. Phase 3 proves it can handle the hardest content in the playlist:

- **4-hour marathons** (350K+ char transcripts) — the `bawGcAsAA-w` video that timed out in v1.10
- **Compilations with heavy restaurant overlap** — same restaurant in 5+ videos
- **Edge cases** — behind-the-scenes clips, international locations, unusual formats
- **Dedup stress** — 90 total videos should surface significant cross-video duplicates

If Phase 3 passes, the pipeline is ready for Group B production.

---

## Autonomy Rules

```
1. AUTO-PROCEED between all steps. Never ask permission.
2. SELF-HEAL: diagnose → fix → re-run (max 3 attempts per error, then log and skip).
3. SYSTEMIC FAILURE RULE: If 3 consecutive items fail with the SAME error
   message, STOP the batch immediately. Fix the root cause. Then restart
   the batch (resume support will skip already-completed items).
4. Run ALL scripts in FOREGROUND. No background processes.
5. TIMEOUT SCALING: clips=120s, episodes=180s, compilations=240s, marathons=600s.
6. OUTPUT ARTIFACTS (mandatory before session ends):
   a. docs/ddd-report-v3.12.md — metrics, validation, Gemini's recommendation
   b. docs/ddd-build-v3.12.md — full session transcript
   c. README.md — updated changelog + footer (FINAL step, do NOT skip)
7. Do NOT run git commit, git push, or firebase deploy.
8. Working directory is always pipeline/ (relative paths resolve from here).
9. When encountering a decision point (which model, which path, which config),
   consult ddd-design-v3.12.md for locked decisions. Do NOT ask the human.
```

---

## Step 0: Pre-Flight Checks

Create `scripts/pre_flight.py` (overwrite existing):

```python
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
```

Run: `python3 scripts/pre_flight.py`

Self-heal any failures before proceeding to Step 1.

---

## Step 1: Select Phase 3 Batch

Create `scripts/select_batch.py` (generalized version, replaces select_phase2_batch.py):

```python
#!/usr/bin/env python3
"""
select_batch.py — Select the next N unprocessed videos from the playlist.
Excludes already-transcribed videos. Writes to config/phase3_batch.txt.
"""
import os, re, random, argparse

parser = argparse.ArgumentParser()
parser.add_argument("--count", type=int, default=30, help="Number of videos to select")
parser.add_argument("--output", default="config/phase3_batch.txt", help="Output file")
parser.add_argument("--seed", type=int, default=123, help="Random seed for reproducibility")
parser.add_argument("--bias-marathons", action="store_true", help="Oversample marathons for stress testing")
args = parser.parse_args()

# Already processed
processed_ids = set()
for f in os.listdir("data/transcripts"):
    if f.endswith(".json"):
        processed_ids.add(f.replace(".json", ""))
print(f"Already processed: {len(processed_ids)} videos")

# Parse playlist
with open("config/playlist_urls.txt") as f:
    all_lines = [l.strip() for l in f if l.strip() and not l.startswith('#')]

available = []
for line in all_lines:
    match = re.search(r'v=([a-zA-Z0-9_-]{11})', line)
    if not match:
        continue
    vid = match.group(1)
    if vid in processed_ids:
        continue
    dur_match = re.search(r'\[(\d+):(\d+):(\d+)\]', line)
    if dur_match:
        duration = int(dur_match.group(1))*3600 + int(dur_match.group(2))*60 + int(dur_match.group(3))
    else:
        dur_match = re.search(r'\[(\d+):(\d+)\]', line)
        duration = int(dur_match.group(1))*60 + int(dur_match.group(2)) if dur_match else 0
    available.append({"id": vid, "line": line, "duration": duration})

print(f"Available: {len(available)} videos")

clips = [v for v in available if 0 < v["duration"] < 900]
standard = [v for v in available if 900 <= v["duration"] < 1500]
compilations = [v for v in available if 1500 <= v["duration"] < 3600]
marathons = [v for v in available if v["duration"] >= 3600]
unknown = [v for v in available if v["duration"] == 0]

print(f"  Clips: {len(clips)} | Standard: {len(standard)} | Compilations: {len(compilations)} | Marathons: {len(marathons)} | Unknown: {len(unknown)}")

random.seed(args.seed)
selected = []

if args.bias_marathons:
    # Phase 3 stress test: heavy on marathons and compilations
    selected += random.sample(marathons, min(8, len(marathons)))
    selected += random.sample(compilations, min(12, len(compilations)))
    selected += random.sample(standard, min(5, len(standard)))
    selected += random.sample(clips, min(3, len(clips)))
    remaining = [v for v in available if v not in selected]
    while len(selected) < args.count and remaining:
        selected.append(remaining.pop(random.randint(0, len(remaining)-1)))
else:
    selected += random.sample(clips, min(5, len(clips)))
    selected += random.sample(standard, min(10, len(standard)))
    selected += random.sample(compilations, min(10, len(compilations)))
    selected += random.sample(marathons, min(5, len(marathons)))
    remaining = [v for v in available if v not in selected]
    while len(selected) < args.count and remaining:
        selected.append(remaining.pop(random.randint(0, len(remaining)-1)))

with open(args.output, "w") as f:
    f.write(f"# TripleDB Phase 3 Batch — {len(selected)} videos (stress test: marathon-heavy)\n\n")
    for v in sorted(selected, key=lambda x: x["duration"]):
        f.write(v["line"] + "\n")

print(f"\nWrote {args.output} with {len(selected)} videos")
types = {"clip": 0, "standard": 0, "compilation": 0, "marathon": 0}
for v in selected:
    if v["duration"] < 900: types["clip"] += 1
    elif v["duration"] < 1500: types["standard"] += 1
    elif v["duration"] < 3600: types["compilation"] += 1
    else: types["marathon"] += 1
print(f"  Mix: {types}")
```

Run with marathon bias for stress testing:

```bash
python3 scripts/select_batch.py --bias-marathons --output config/phase3_batch.txt
```

Also add the v1.10 failed marathon explicitly if not already selected:

```bash
# Check if bawGcAsAA-w is in the batch
grep "bawGcAsAA-w" config/phase3_batch.txt
# If not found, append it:
grep "bawGcAsAA-w" config/playlist_urls.txt >> config/phase3_batch.txt
```

---

## Step 2: Download Phase 3 Videos

```bash
python3 scripts/phase1_acquire.py --batch config/phase3_batch.txt
```

Expected: ~30 min. Resume support skips existing files.

---

## Step 3: Transcribe Phase 3 Videos

**CRITICAL:** Set the CUDA library path at the shell level. Do NOT rely on Python's `os.environ`.

```bash
systemctl --user stop ollama 2>/dev/null
sleep 5
LD_LIBRARY_PATH=/usr/local/lib/ollama/cuda_v12:$LD_LIBRARY_PATH python3 scripts/phase2_transcribe.py --batch config/phase3_batch.txt
```

Expected: ~90-120 min (marathon-heavy batch). Resume support skips existing transcripts.

After transcription, optionally restart Ollama:

```bash
systemctl --user start ollama 2>/dev/null
```

---

## Step 4: Extract Phase 3 Videos

Ensure `scripts/phase3_extract_gemini.py` has `TIMEOUT = 300` (or higher for this marathon-heavy batch). If the 4-hour Global Flavors video is in the batch, consider temporarily setting `TIMEOUT = 600`.

Also ensure the extraction prompt at `config/extraction_prompt.md` includes the v2.11 refinements (Rule 1: re-scan for additional dishes, Rule 4: never return just "Chef"). If the prompt was overwritten during Phase 2, restore it from the design doc.

```bash
python3 scripts/phase3_extract_gemini.py --batch config/phase3_batch.txt
```

Expected: ~10-20 min (marathons take longer per video due to larger transcripts).

Monitor for the systemic failure rule: if 3 consecutive extractions fail with the same error (e.g., timeout), stop and investigate before continuing.

---

## Step 5: Re-attempt Previously Failed Videos

```bash
# Re-attempt the v1.10 marathon that timed out
python3 scripts/phase3_extract_gemini.py --video bawGcAsAA-w

# Re-attempt the empty Dcfs_wKVi9A if still empty
rm -f data/extracted/Dcfs_wKVi9A.json
python3 scripts/phase3_extract_gemini.py --video Dcfs_wKVi9A
```

If `bawGcAsAA-w` still times out at 300s, try 600s:

```python
# Temporarily in the script or via a one-liner:
TIMEOUT=600 python3 -c "
import sys; sys.path.insert(0, 'scripts')
import phase3_extract_gemini as ex
ex.TIMEOUT = 600
ex.EXTRACTED_DIR.mkdir(parents=True, exist_ok=True)
ex.LOG_DIR.mkdir(parents=True, exist_ok=True)
prompt = ex.load_extraction_prompt()
result, status = ex.extract_video('bawGcAsAA-w', prompt)
print(f'Result: {status}')
"
```

If it still fails: accept it as an edge case. A 4-hour marathon with 350K characters may exceed what a single API call can handle. Log it and move on — we can chunk it manually in Phase 4 if needed.

---

## Step 6: Validate All Extractions (90 videos)

Run the validation script on all extracted data:

```bash
python3 scripts/validate_extraction.py
```

Expected: ~90 files, 600+ restaurants, 900+ dishes.

---

## Step 7: Normalize Across All 90 Videos

This is the real dedup stress test. With 90 videos including multiple city compilations and "Best of" videos, many restaurants will appear 3-5 times.

```bash
python3 scripts/phase4_normalize.py
```

Expected: significant dedup merges (100+). Check the dedup report:

```bash
wc -l data/logs/phase-4-dedup-report.jsonl
python3 -c "
import json
merges = [json.loads(l) for l in open('data/logs/phase-4-dedup-report.jsonl')]
print(f'Total merges: {len(merges)}')
multi = [m for m in merges if m['source_count'] >= 3]
print(f'Restaurants appearing 3+ times: {len(multi)}')
for m in sorted(multi, key=lambda x: -x['source_count'])[:10]:
    print(f'  {m[\"merged_name\"]} ({m[\"merged_city\"]}): {m[\"source_count\"]} appearances')
"
```

---

## Step 8: Validate Normalization

```bash
# State distribution
python3 -c "
import json
from collections import Counter
states = Counter()
for line in open('data/normalized/restaurants.jsonl'):
    r = json.loads(line)
    states[r.get('state', '?')] += 1
for s, c in states.most_common(20):
    print(f'  {s}: {c}')
print(f'Total unique states: {len(states)}')
"

# Spot-check a multi-appearance restaurant
python3 -c "
import json
for line in open('data/normalized/restaurants.jsonl'):
    r = json.loads(line)
    if len(r.get('visits', [])) >= 3:
        print(json.dumps(r, indent=2)[:2000])
        break
"
```

---

## Step 9: Generate Report Artifacts

### docs/ddd-report-v3.12.md

Must include:
1. Batch details (how many of each video type)
2. Download/transcription/extraction success rates
3. Combined validation metrics (all 90 videos)
4. Normalization metrics (total unique restaurants, dedup merges, state distribution)
5. Comparison table: v1.10 → v2.11 → v3.12 metrics side by side
6. Issues encountered and self-healing actions taken
7. Count of human interventions (target: <5)
8. **Gemini's Recommendation:** Should we proceed to Phase 4 or re-run?
9. **README Update Confirmation:** Confirm README.md was updated.

### docs/ddd-build-v3.12.md

Chronological log of every command, output, error, and fix.

### README.md Update

Add a changelog entry in the same format as existing entries:

```markdown
**v2.11 → v3.12 (Phase 3 Stress Test)**
- **Success:** [what worked]
- **Challenge:** [what was hard]
- **Pivot for v3.12:** [what changed]
```

Update the footer:

```markdown
*Last updated: Phase 3.12 — Stress Test*
```

Update the Project Status table: Phase 3 row → ✅ Complete | v3.12

**This README update is the FINAL action of the session. Do not end without it.**

---

## Phase 3.12 Success Criteria

```
[ ] Pre-flight passes
[ ] Phase 3 batch selected (30 videos, marathon-heavy)
[ ] 25+ of 30 Phase 3 videos downloaded
[ ] 25+ of 30 Phase 3 videos transcribed
[ ] 25+ of 30 Phase 3 videos extracted
[ ] bawGcAsAA-w (4-hr marathon) either extracted or logged as accepted edge case
[ ] Combined: 80+ videos with extraction data (of ~90)
[ ] Combined: 600+ unique restaurants
[ ] Combined: 900+ dishes
[ ] guy_intro capture >= 90% (improved from 98%)
[ ] guy_response capture >= 90%
[ ] ingredients capture >= 90%
[ ] owner_chef null < 12% (improved from 14%)
[ ] Normalization dedup merges >= 80
[ ] Restaurants appearing 3+ times: at least 5 found
[ ] State distribution: 40+ states
[ ] Human interventions during session: < 5
[ ] ddd-report-v3.12.md generated with Gemini's recommendation
[ ] ddd-build-v3.12.md generated
[ ] README.md updated (changelog + footer) — CONFIRMED
```

---

## GEMINI.md Update

Before launching, update `pipeline/GEMINI.md` to:

```markdown
# TripleDB Pipeline — Agent Instructions

## Current Iteration: 3.12

Read these two documents in order, then execute the plan:

1. ../docs/ddd-design-v3.12.md — Architecture, methodology, locked decisions
2. ../docs/ddd-plan-v3.12.md — Pre-flight checklist and execution steps

Follow the autonomy rules defined in the plan. Begin with Step 0.

## Rules That Never Change
- NEVER run git commit, git push, or firebase deploy
- NEVER ask permission between steps — auto-proceed
- Self-heal errors: diagnose → fix → re-run (max 3 attempts, then skip)
- 3 consecutive identical errors = STOP, fix root cause, restart
- README.md update is the FINAL step of report generation — do not skip it
- All scripts run from this directory (pipeline/) as working directory
- Transcription MUST be launched with: LD_LIBRARY_PATH=/usr/local/lib/ollama/cuda_v12:$LD_LIBRARY_PATH
- Extraction uses Gemini 2.5 Flash API ($GEMINI_API_KEY), NOT local Ollama
```

---

## Launch Sequence

```bash
# 1. Archive previous iteration
cd ~/dev/projects/tripledb
mv docs/ddd-design-v2.11.md docs/archive/ 2>/dev/null
mv docs/ddd-plan-v2.11.md docs/archive/ 2>/dev/null
mv docs/ddd-report-v2.11.md docs/archive/ 2>/dev/null
mv docs/ddd-build-v2.11.md docs/archive/ 2>/dev/null

# 2. Place new docs
# (copy ddd-design-v3.12.md and ddd-plan-v3.12.md into docs/)

# 3. Update GEMINI.md (paste the template from Step above)
nano pipeline/GEMINI.md

# 4. Commit the setup
git add .
git commit -m "KT starting 3.12"

# 5. Launch
cd pipeline
gemini
```

Then type:

```
Read GEMINI.md and execute.
```
