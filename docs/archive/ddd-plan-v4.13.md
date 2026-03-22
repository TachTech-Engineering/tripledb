# TripleDB — Phase 4 Plan v4.13

**Phase:** 4 — Validation
**Iteration:** 13 (global project iteration)
**Date:** March 21, 2026
**Goal:** Final validation batch with locked prompts. Prove the pipeline can run end-to-end as a single autonomous session with zero interventions. Scan for leaked secrets. Produce a comprehensive README. Green-light Group B.

---

## What Phase 4 Proves

Phase 1 proved the pipeline works. Phase 2 proved it scales. Phase 3 proved it handles edge cases. Phase 4 proves it's **production-ready:**

- **Prompt lock:** Extraction and normalization prompts are frozen. No tuning allowed.
- **Full dry run:** All steps execute as a single autonomous session — select → download → transcribe → extract → validate → normalize → validate → report.
- **Secret hygiene:** No API keys anywhere in tracked files or git history.
- **README accuracy:** README reflects the actual current state of the project, not stale v1.10 architecture.
- **Group B readiness:** Every item on the readiness checklist is validated.

If Phase 4 passes, Group B production begins.

---

## Autonomy Rules

```
1. AUTO-PROCEED between ALL steps. NEVER ask permission. NEVER ask
   "should I continue?" or "would you like me to proceed?" — the answer
   is ALWAYS yes. The plan document IS your permission. Execute it.
2. SELF-HEAL: diagnose → fix → re-run (max 3 attempts per error, then
   log and skip).
3. SYSTEMIC FAILURE RULE: If 3 consecutive items fail with the SAME
   error message, STOP the batch immediately. Fix the root cause. Then
   restart (resume support will skip already-completed items).
4. Run ALL scripts in FOREGROUND. No background processes. No nohup.
5. TIMEOUT SCALING: clips=120s, episodes=180s, compilations=240s,
   marathons=600s.
6. DECISION POINTS: If you encounter a decision not covered by the plan,
   consult ddd-design-v4.13.md. If still not covered, make the best
   decision, LOG your reasoning in the build doc, and continue. Do NOT
   ask the human.
7. OUTPUT ARTIFACTS (mandatory before session ends):
   a. docs/ddd-report-v4.13.md — metrics, validation, Gemini's recommendation
   b. docs/ddd-build-v4.13.md — full session transcript
   c. README.md — COMPREHENSIVE update (see Step 11 for exact spec)
8. Do NOT run git, flutter, or firebase commands.
9. Working directory is always pipeline/ (relative paths resolve from here).
10. This is Phase 4 — prompts are LOCKED. Do NOT modify extraction_prompt.md
    or any extraction/normalization prompt logic. If results are poor, log
    it as a finding — do NOT tune.
```

---

## Step 0: Pre-Flight Checks

Create `scripts/pre_flight.py` (overwrite existing):

```python
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
```

Run: `python3 scripts/pre_flight.py`

**HARD GATE:** If secret scan fails, remediate BEFORE proceeding. Remove the secret from the file. If it's in git history, log it for Kyle to scrub with `git filter-repo` after the session. Do NOT proceed with secrets in tracked files.

Self-heal any other failures before proceeding to Step 1.

---

## Step 1: Secret Scan Deep Check

Even if pre-flight passed, run a deeper scan to catch secrets that might have been committed and then removed:

```bash
# Check full git history for API key patterns
git -C .. log --all -p | grep -E 'AIza[0-9A-Za-z_-]{35}|ya29\.' | head -20

# Check if GEMINI_API_KEY value appears in any file
grep -r "$GEMINI_API_KEY" .. --include="*.md" --include="*.py" --include="*.json" --include="*.txt" --include="*.yaml" --include="*.yml" 2>/dev/null | grep -v ".git/" | head -10
```

If any matches found:
1. Log the file paths in the build doc
2. If in a tracked file: remove the key, replace with `$GEMINI_API_KEY` or `<REDACTED>`
3. If only in git history: log for Kyle to remediate post-session
4. Continue with the session — history cleanup is a human task

---

## Step 2: Select Phase 4 Batch

```bash
python3 scripts/select_batch.py --count 30 --output config/phase4_batch.txt --seed 456
```

Phase 4 is a validation run — we want a representative mix, NOT marathon-biased. Default distribution is fine (no `--bias-marathons`).

Log the batch composition: how many clips, standard, compilations, marathons.

---

## Step 3: Download Phase 4 Videos

```bash
python3 scripts/phase1_acquire.py --batch config/phase4_batch.txt
```

Target: 28+ of 30 downloaded successfully. Resume support will skip existing files.

---

## Step 4: Transcribe Phase 4 Videos

**CRITICAL:** Verify no GPU contention first:

```bash
nvidia-smi
# If any Python/Ollama process is using GPU memory, kill it:
# kill <PID>
```

```bash
LD_LIBRARY_PATH=/usr/local/lib/ollama/cuda_v12:$LD_LIBRARY_PATH python3 scripts/phase2_transcribe.py --batch config/phase4_batch.txt
```

Target: 28+ of 30 transcribed. If marathons time out, the script's resume support handles retries. If a marathon exceeds session limits, log it and continue — do NOT swap the batch like v3.12 did. Phase 4 validates the pipeline AS-IS.

---

## Step 5: Extract Phase 4 Videos

```bash
python3 scripts/phase3_extract_gemini.py --batch config/phase4_batch.txt
```

**PROMPTS ARE LOCKED.** Do NOT modify `config/extraction_prompt.md` or any extraction logic. If extraction quality drops, log it as a finding in the report.

Monitor for the systemic failure rule: 3 consecutive identical errors = STOP.

---

## Step 6: Re-attempt Previously Failed Videos

Check for any previously failed extractions across all phases:

```bash
# Find extracted files that are empty or have 0 restaurants
python3 -c "
import json, glob
empty = []
for f in sorted(glob.glob('data/extracted/*.json')):
    try:
        data = json.load(open(f))
        if not data.get('restaurants'):
            empty.append(f)
    except:
        empty.append(f)
print(f'Empty/invalid extractions: {len(empty)}')
for f in empty:
    print(f'  {f}')
"
```

Re-attempt any that have valid transcripts. Skip `bawGcAsAA-w` — it's an accepted edge case.

---

## Step 7: Validate All Extractions (~120 videos)

```bash
python3 scripts/validate_extraction.py
```

This is the most important validation run — it covers all Group A data. Expected: ~115+ files with data, 700+ restaurants, 1100+ dishes.

Log the full output in the build doc.

---

## Step 8: Normalize Across All ~120 Videos

The ultimate dedup stress test. With 120 videos including city compilations, "Best of" videos, and marathon overlap, many restaurants will appear 4-7+ times.

```bash
python3 scripts/phase4_normalize.py
```

Expected: significant dedup merges (150+).

---

## Step 9: Validate Normalization

```bash
# Dedup report analysis
python3 -c "
import json
merges = [json.loads(l) for l in open('data/logs/phase-4-dedup-report.jsonl')]
print(f'Total merges: {len(merges)}')
multi = [m for m in merges if m.get('source_count', 0) >= 3]
print(f'Restaurants appearing 3+ times: {len(multi)}')
for m in sorted(multi, key=lambda x: -x.get('source_count', 0))[:15]:
    print(f'  {m.get(\"merged_name\", \"?\")} ({m.get(\"merged_city\", \"?\")}): {m.get(\"source_count\", 0)} appearances')
"

# State distribution
python3 -c "
import json
from collections import Counter
states = Counter()
dishes_per = []
for line in open('data/normalized/restaurants.jsonl'):
    r = json.loads(line)
    states[r.get('state', '?')] += 1
    dishes_per.append(len(r.get('dishes', [])))
for s, c in states.most_common(20):
    print(f'  {s}: {c}')
print(f'Total unique states: {len(states)}')
print(f'Avg dishes/restaurant: {sum(dishes_per)/len(dishes_per):.2f}')
"

# Confidence score distribution
python3 -c "
import json
confidences = []
for line in open('data/normalized/restaurants.jsonl'):
    r = json.loads(line)
    for d in r.get('dishes', []):
        c = d.get('confidence')
        if c is not None:
            confidences.append(c)
if confidences:
    print(f'Dish confidence scores: {len(confidences)} total')
    print(f'  Mean: {sum(confidences)/len(confidences):.3f}')
    print(f'  Min: {min(confidences):.3f}')
    print(f'  <0.7: {sum(1 for c in confidences if c < 0.7)} ({sum(1 for c in confidences if c < 0.7)/len(confidences)*100:.1f}%)')
else:
    print('No confidence scores found in dish data')
"

# Owner/chef null rate
python3 -c "
import json
total = 0
null_count = 0
for line in open('data/normalized/restaurants.jsonl'):
    r = json.loads(line)
    total += 1
    if not r.get('owner_chef'):
        null_count += 1
print(f'Owner/chef: {null_count}/{total} null ({null_count/total*100:.1f}%)')
"

# Spot-check a high-appearance restaurant
python3 -c "
import json
for line in open('data/normalized/restaurants.jsonl'):
    r = json.loads(line)
    if len(r.get('visits', [])) >= 4:
        print(json.dumps(r, indent=2)[:3000])
        break
"
```

---

## Step 10: Group B Readiness Assessment

Run these checks and log results:

```bash
# 1. Verify --all mode exists in key scripts
grep -l "add_argument.*--all" scripts/phase1_acquire.py scripts/phase2_transcribe.py scripts/phase3_extract_gemini.py scripts/phase4_normalize.py 2>/dev/null

# 2. Verify resume support in key scripts
grep -l "already processed\|Skipping.*already\|exists.*skip" scripts/phase1_acquire.py scripts/phase2_transcribe.py scripts/phase3_extract_gemini.py 2>/dev/null

# 3. Count remaining unprocessed videos
python3 -c "
import os, re
processed = set(f.replace('.json','') for f in os.listdir('data/transcripts') if f.endswith('.json'))
total = 0
for line in open('config/playlist_urls.txt'):
    if line.strip() and not line.startswith('#'):
        total += 1
print(f'Total playlist: {total}')
print(f'Processed: {len(processed)}')
print(f'Remaining for Group B: {total - len(processed)}')
"

# 4. Estimate Group B processing time
python3 -c "
import os, re
remaining_count = 0
for line in open('config/playlist_urls.txt'):
    line = line.strip()
    if not line or line.startswith('#'):
        continue
    match = re.search(r'v=([a-zA-Z0-9_-]{11})', line)
    if match and not os.path.exists(f'data/transcripts/{match.group(1)}.json'):
        remaining_count += 1
# Rough estimates based on Group A averages
download_hrs = remaining_count * 30 / 3600  # 30s per video
transcribe_hrs = remaining_count * 5 * 60 / 3600  # 5 min avg
extract_hrs = remaining_count * 30 / 3600  # 30s per extraction (Gemini API)
normalize_hrs = 2  # single batch
total_hrs = download_hrs + transcribe_hrs + extract_hrs + normalize_hrs
print(f'Remaining videos: {remaining_count}')
print(f'Estimated download: {download_hrs:.1f} hrs')
print(f'Estimated transcription: {transcribe_hrs:.1f} hrs')
print(f'Estimated extraction: {extract_hrs:.1f} hrs')
print(f'Estimated normalization: {normalize_hrs} hrs')
print(f'Estimated total: {total_hrs:.1f} hrs ({total_hrs/24:.1f} days)')
"
```

---

## Step 11: Update README.md — COMPREHENSIVE

**This is not optional. This is not a one-liner. Every section listed below must be updated.**

Read the current README.md first:

```bash
cat ../README.md
```

Then update ALL of the following sections:

### 11a. Project Status Table

Update Phase 3 row to ✅ Complete | v3.12 and Phase 4 row to ✅ Complete | v4.13.

### 11b. Architecture Diagram

The current README architecture diagram is STALE. It still lists "Qwen 3.5-9B (local, Ollama)" for normalization. Update it to reflect the actual pipeline:

```
YouTube Playlist (805 videos)
    ↓ yt-dlp
MP3 Audio
    ↓ faster-whisper (CUDA)
Timestamped Transcripts
    ↓ Gemini 2.5 Flash API
Structured Restaurant JSON
    ↓ Gemini 2.5 Flash API
Normalized + Deduplicated JSONL
    ↓ Firecrawl + Playwright (Phase 5)
Enriched Data
    ↓ Firebase Admin SDK (Phase 6)
Cloud Firestore
    ↓ Flutter Web (Phase 7)
tripleDB.com
```

### 11c. Tech Stack Table

Update the Extraction and Normalization rows to show "Gemini 2.5 Flash API" instead of Ollama models.

### 11d. Video Count

Fix "804" → "805" throughout if still stale.

### 11e. Current Metrics

Add or update a metrics section showing current state:

```
- Videos processed: ~120 of 805
- Unique restaurants: [count from normalization]
- Unique dishes: [count]
- States covered: [count]
- Extraction quality: 98% guy_intro, 98% guy_response
```

### 11f. Changelog

Add TWO entries if the v3.12 entry is missing:

```markdown
**v2.11 → v3.12 (Phase 3 Stress Test)**
- **Success:** Achieved zero human interventions. Autonomously healed the batch when marathons exceeded session limits. 98 dedup merges across 89 videos validated cross-video normalization.
- **Challenge:** The 4-hour Global Flavors marathon (`bawGcAsAA-w`) exceeded Gemini Flash's output token limits — accepted as an edge case.
- **Pivot for v4.13:** Prompts locked. Focus shifts to full validation dry run and Group B readiness.

**v3.12 → v4.13 (Phase 4 Validation)**
- **Success:** [fill from results]
- **Challenge:** [fill from results]
- **Outcome:** [Group B green-lit / needs another iteration]
```

### 11g. Footer

```markdown
*Last updated: Phase 4.13 — Validation*
```

### 11h. Verify After Writing

```bash
# Confirm key sections exist
grep -c "Gemini 2.5 Flash" ../README.md  # Should be >= 2 (architecture + tech stack)
grep "Last updated" ../README.md          # Should show Phase 4.13
grep "805" ../README.md                   # Should find video count
```

---

## Step 12: Generate Report Artifacts

### docs/ddd-report-v4.13.md

Must include:
1. Batch details (how many of each video type in Phase 4 batch)
2. Download/transcription/extraction success rates for Phase 4
3. Combined validation metrics (all ~120 videos)
4. Normalization metrics (total unique restaurants, dedup merges, state distribution)
5. Comparison table: v1.10 → v2.11 → v3.12 → v4.13 metrics side by side
6. Confidence score distribution
7. Owner_chef null rate trend
8. Group B readiness assessment (checklist with pass/fail for each item)
9. Issues encountered and self-healing actions taken
10. Count of human interventions (target: 0)
11. **Secret scan results:** PASS/FAIL
12. **Gemini's Recommendation:** Proceed to Group B or re-run?
13. **README Update Confirmation:** Confirm ALL sections updated (not just footer)

### docs/ddd-build-v4.13.md

Chronological log of every command, output, error, and fix.

**These artifacts + README update are the FINAL actions. Do NOT end the session without all three.**

---

## Phase 4.13 Success Criteria

```
[ ] Pre-flight passes (including secret scan)
[ ] Deep secret scan finds no keys in tracked files or recent git history
[ ] Phase 4 batch selected (30 videos, representative mix)
[ ] 28+ of 30 Phase 4 videos downloaded
[ ] 28+ of 30 Phase 4 videos transcribed
[ ] 28+ of 30 Phase 4 videos extracted (with LOCKED prompts — no tuning)
[ ] Combined: 110+ videos with extraction data (of ~120)
[ ] Combined: 700+ unique restaurants
[ ] Combined: 1100+ dishes
[ ] guy_intro capture >= 95%
[ ] guy_response capture >= 95%
[ ] ingredients capture >= 95%
[ ] Normalization dedup merges >= 120
[ ] Restaurants appearing 3+ times: at least 20 found
[ ] State distribution: 45+ states
[ ] Confidence score mean >= 0.8
[ ] Human interventions during session: 0
[ ] Secret scan: PASS
[ ] Group B readiness checklist: all items assessed
[ ] ddd-report-v4.13.md generated with comparison table and recommendation
[ ] ddd-build-v4.13.md generated
[ ] README.md COMPREHENSIVELY updated — CONFIRMED:
    [ ] Project status table updated
    [ ] Architecture diagram corrected (Gemini Flash, not Ollama)
    [ ] Tech stack table corrected
    [ ] Video count: 805
    [ ] Changelog entries added (v3.12 + v4.13)
    [ ] Footer: Phase 4.13
```

---

## GEMINI.md Update

Before launching, update `pipeline/GEMINI.md` to:

```markdown
# TripleDB Pipeline — Agent Instructions

## Current Iteration: 4.13

Read these two documents in order, then execute the plan:

1. ../docs/ddd-design-v4.13.md — Architecture, methodology, locked decisions
2. ../docs/ddd-plan-v4.13.md — Pre-flight checklist and execution steps

Follow the autonomy rules defined in the plan. Begin with Step 0.

## Rules That Never Change
- NEVER run git, flutter, or firebase commands
- NEVER ask permission between steps — auto-proceed on EVERY step
- NEVER ask "should I continue?" or "would you like me to proceed?" — YES, ALWAYS
- If you find yourself typing a question mark, STOP. Re-read the plan. Execute.
- Self-heal errors: diagnose → fix → re-run (max 3 attempts, then skip)
- 3 consecutive identical errors = STOP, fix root cause, restart
- README.md update is the FINAL step — update ALL sections listed in Step 11
- All scripts run from this directory (pipeline/) as working directory
- Transcription MUST be launched with: LD_LIBRARY_PATH=/usr/local/lib/ollama/cuda_v12:$LD_LIBRARY_PATH
- Extraction uses Gemini 2.5 Flash API ($GEMINI_API_KEY), NOT local Ollama
- Prompts are LOCKED — do NOT modify extraction_prompt.md
- Run secret scan in pre-flight — HARD GATE, fix before proceeding
```

---

## Launch Sequence

```bash
# 1. Archive previous iteration
cd ~/dev/projects/tripledb
mv docs/ddd-design-v3.12.md docs/archive/ 2>/dev/null
mv docs/ddd-plan-v3.12.md docs/archive/ 2>/dev/null
mv docs/ddd-report-v3.12.md docs/archive/ 2>/dev/null
mv docs/ddd-build-v3.12.md docs/archive/ 2>/dev/null

# 2. Place new docs
# (copy ddd-design-v4.13.md and ddd-plan-v4.13.md into docs/)

# 3. Update GEMINI.md (paste the template from above)
nano pipeline/GEMINI.md

# 4. Commit the setup
git add .
git commit -m "KT starting 4.13"

# 5. Launch
cd pipeline
gemini
```

Then type:

```
Read GEMINI.md and execute.
```
