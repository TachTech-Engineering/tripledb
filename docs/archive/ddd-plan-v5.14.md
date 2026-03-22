# TripleDB — Phase 5 Plan v5.14

**Phase:** 5 — Production Setup
**Iteration:** 14 (global project iteration)
**Date:** March 2026
**Goal:** Fix data quality issues found in v4.13, build the Group B unattended runner infrastructure, validate it with a test batch, and produce a comprehensive README documenting the IAO methodology. After this iteration, Kyle launches the production run in tmux.

---

## What Phase 5.14 Produces

Phase 5.14 is NOT the production run itself — that's a 70-hour unattended operation launched manually in tmux. Phase 5.14 produces the infrastructure and confidence to launch it:

1. **Data quality fixes** — null-name restaurant merging bug, null/unknown state handling
2. **Group B runner script** — `group_b_runner.sh` for tmux execution
3. **Checkpoint reporting** — progress report every 50 videos
4. **Automatic pause conditions** — failure rate, hang detection, disk usage
5. **Test validation** — small batch through the runner to prove it works
6. **Comprehensive README** — with IAO Eight Pillars methodology section
7. **Launch instructions** — exact tmux commands for Kyle

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
4. NEVER run git, flutter, or firebase commands.
   EXCEPTION: pre-flight secret scan may use read-only git commands
   (git ls-files, git log) to detect leaked secrets. No git write
   operations under any circumstance.
5. DECISION POINTS: If you encounter a decision not covered by the plan,
   consult ddd-design-v5.14.md. If still not covered, make the best
   decision, LOG your reasoning in the build doc, and continue.
6. OUTPUT ARTIFACTS (mandatory before session ends):
   a. docs/ddd-report-v5.14.md — metrics, validation, readiness assessment
   b. docs/ddd-build-v5.14.md — full session transcript
   c. README.md — COMPREHENSIVE update including IAO methodology section
7. Working directory is always pipeline/ (relative paths resolve from here).
8. Prompts are LOCKED. Do NOT modify extraction_prompt.md.
```

---

## Step 0: Pre-Flight Checks

Use the same `pre_flight.py` from v4.13 (it includes secret scanning). Run it:

```bash
python3 scripts/pre_flight.py
```

Self-heal any failures. If secret scan fails on tracked files, remediate before proceeding. If secrets are only in git history, log for Kyle's post-session `git filter-repo` cleanup.

---

## Step 1: Fix Null-Name Restaurant Merging

The v4.13 normalization produced "None (None): 14 appearances" — null-name restaurants from different videos were merged as if they were the same entity. This is a bug.

Open `scripts/phase4_normalize.py` and add null-name filtering BEFORE the dedup logic:

```python
# BEFORE dedup grouping — filter out null-name restaurants
valid_restaurants = []
null_records = []
for r in all_restaurants:
    name = r.get("name") or ""
    if not name.strip() or name.strip().lower() in ("none", "null", "unknown", "n/a"):
        null_records.append(r)
    else:
        valid_restaurants.append(r)

# Log null records
if null_records:
    with open("data/logs/phase-4-null-records.jsonl", "w") as f:
        for r in null_records:
            f.write(json.dumps(r) + "\n")
    print(f"  Filtered {len(null_records)} null-name restaurants (logged to phase-4-null-records.jsonl)")

# Continue dedup with valid_restaurants only
```

**Also fix null/unknown state handling.** Before writing the normalized output, ensure:

```python
# State normalization — convert None/empty to "UNKNOWN"
state = r.get("state") or ""
if not state.strip() or state.strip().lower() in ("none", "null", "unknown"):
    # Attempt to infer from video title or city
    # e.g., "Top #DDD Videos in Tennessee" → "TN"
    state = "UNKNOWN"
r["state"] = state
```

After making the fix, re-run normalization on existing data to verify:

```bash
python3 scripts/phase4_normalize.py
```

Check that:
- "None (None)" no longer appears in the dedup report
- Null-name records are logged separately
- State "None" count is reduced (some may become "UNKNOWN" which is acceptable)

```bash
python3 -c "
import json
merges = [json.loads(l) for l in open('data/logs/phase-4-dedup-report.jsonl')]
none_merges = [m for m in merges if not m.get('merged_name') or m.get('merged_name') == 'None']
print(f'Null-name merges: {len(none_merges)} (should be 0)')

from collections import Counter
states = Counter()
for line in open('data/normalized/restaurants.jsonl'):
    r = json.loads(line)
    states[r.get('state', '?')] += 1
print(f'None states: {states.get(\"None\", 0)} (should be 0)')
print(f'UNKNOWN states: {states.get(\"UNKNOWN\", 0)}')
print(f'Total restaurants: {sum(states.values())}')
"
```

---

## Step 2: Create Group B Runner Script

Create `scripts/group_b_runner.sh`:

```bash
#!/usr/bin/env bash
# group_b_runner.sh — Unattended production run for remaining ~685 videos.
# Run in tmux: tmux new -s tripledb './scripts/group_b_runner.sh 2>&1 | tee data/logs/group_b_run.log'

set -euo pipefail
cd "$(dirname "$0")/.."  # Ensure we're in pipeline/

TOTAL_START=$(date +%s)
LOG_DIR="data/logs"
mkdir -p "$LOG_DIR"

echo "=========================================="
echo "TripleDB Group B Production Run"
echo "Started: $(date)"
echo "=========================================="

# ── Phase 1: Download remaining videos ──────────────────────
echo ""
echo "=== Phase 1: Download ==="
python3 scripts/phase1_acquire.py --all
echo "Download complete: $(date)"

# ── Phase 2: Transcribe all ─────────────────────────────────
echo ""
echo "=== Phase 2: Transcribe ==="
# Kill any GPU-hogging processes
pkill -f "ollama" 2>/dev/null || true
sleep 2

# Verify GPU is free
nvidia-smi --query-compute-apps=pid --format=csv,noheader | while read pid; do
    if [ -n "$pid" ]; then
        echo "WARNING: GPU process $pid still running, killing..."
        kill "$pid" 2>/dev/null || true
    fi
done

LD_LIBRARY_PATH=/usr/local/lib/ollama/cuda_v12:${LD_LIBRARY_PATH:-} \
    python3 scripts/phase2_transcribe.py --all
echo "Transcription complete: $(date)"

# ── Phase 3: Extract all ────────────────────────────────────
echo ""
echo "=== Phase 3: Extract ==="
python3 scripts/phase3_extract_gemini.py --all
echo "Extraction complete: $(date)"

# ── Phase 4: Normalize ──────────────────────────────────────
echo ""
echo "=== Phase 4: Normalize ==="
python3 scripts/phase4_normalize.py
echo "Normalization complete: $(date)"

# ── Validate ────────────────────────────────────────────────
echo ""
echo "=== Validation ==="
python3 scripts/validate_extraction.py

TOTAL_END=$(date +%s)
ELAPSED=$(( (TOTAL_END - TOTAL_START) / 3600 ))
echo ""
echo "=========================================="
echo "Group B Production Run Complete"
echo "Finished: $(date)"
echo "Total runtime: ${ELAPSED} hours"
echo "=========================================="
echo ""
echo "NEXT STEPS:"
echo "  1. Review data/logs/group_b_run.log"
echo "  2. Run: python3 scripts/validate_extraction.py"
echo "  3. Review normalization: wc -l data/normalized/restaurants.jsonl"
echo "  4. Proceed to Phase 6 (Enrichment)"
```

Make it executable:

```bash
chmod +x scripts/group_b_runner.sh
```

---

## Step 3: Add Checkpoint Reporting to Pipeline Scripts

Each pipeline script should emit a checkpoint report every 50 videos. Create `scripts/checkpoint_report.py`:

```python
#!/usr/bin/env python3
"""checkpoint_report.py — Generate checkpoint report during production runs."""
import json, os, glob, time
from datetime import datetime

def generate_checkpoint(phase_name, processed_count, total_count, failed_count=0, skipped_count=0):
    """Write a checkpoint report to data/logs/."""
    os.makedirs("data/logs", exist_ok=True)

    # Gather current metrics
    transcript_count = len(glob.glob("data/transcripts/*.json"))
    extraction_count = len([f for f in glob.glob("data/extracted/*.json") if "_raw" not in f])

    report = {
        "checkpoint": processed_count,
        "phase": phase_name,
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "videos_processed": processed_count,
        "videos_total": total_count,
        "videos_remaining": total_count - processed_count,
        "videos_failed": failed_count,
        "videos_skipped": skipped_count,
        "success_rate": (processed_count - failed_count) / max(processed_count, 1),
        "transcripts_on_disk": transcript_count,
        "extractions_on_disk": extraction_count,
    }

    checkpoint_file = f"data/logs/checkpoint-{phase_name}-{processed_count}.json"
    with open(checkpoint_file, "w") as f:
        json.dump(report, f, indent=2)

    print(f"\n{'='*50}")
    print(f"CHECKPOINT: {phase_name} — {processed_count}/{total_count}")
    print(f"  Success rate: {report['success_rate']:.1%}")
    print(f"  Failed: {failed_count} | Skipped: {skipped_count}")
    print(f"  Report: {checkpoint_file}")
    print(f"{'='*50}\n")

    # Automatic pause conditions
    if processed_count >= 50:
        recent_fail_rate = failed_count / processed_count
        if recent_fail_rate > 0.10:
            print(f"⚠️  PAUSE: Failure rate {recent_fail_rate:.1%} exceeds 10% threshold")
            print("Review logs before continuing.")
            return False  # Signal to pause

    return True  # Signal to continue


if __name__ == "__main__":
    # Standalone: generate a summary checkpoint
    generate_checkpoint("summary", 0, 0)
```

**Integration:** The plan does NOT require modifying every pipeline script to call this. Instead, the runner script calls `checkpoint_report.py` between phases. The per-50-video checkpointing is handled by each script's internal logging — the runner captures it all in `group_b_run.log`.

---

## Step 4: Verify --all Mode and Resume Support

Verify that all three core pipeline scripts support `--all` mode:

```bash
# Check --all flag exists
python3 scripts/phase1_acquire.py --help 2>&1 | grep -i "all"
python3 scripts/phase2_transcribe.py --help 2>&1 | grep -i "all"
python3 scripts/phase3_extract_gemini.py --help 2>&1 | grep -i "all"
```

If any script is MISSING `--all` mode, add it. The `--all` flag should:
1. Read ALL video IDs from `config/playlist_urls.txt`
2. Skip already-processed items (resume support)
3. Process remaining items sequentially

Also verify resume support works:

```bash
# This should report "skipped (already exists)" for all 120 processed videos
python3 scripts/phase3_extract_gemini.py --all --dry-run 2>&1 | head -20
```

If `--dry-run` doesn't exist, that's fine — the script's resume logic will handle it during the real run.

---

## Step 5: Test the Runner (Small Batch)

Before Kyle launches the full 70-hour run, validate the runner works end-to-end on a small batch:

```bash
# Create a tiny test batch (5 unprocessed videos)
python3 scripts/select_batch.py --count 5 --output config/test_runner_batch.txt --seed 789

# Run just the download + transcribe + extract for these 5
python3 scripts/phase1_acquire.py --batch config/test_runner_batch.txt
LD_LIBRARY_PATH=/usr/local/lib/ollama/cuda_v12:$LD_LIBRARY_PATH python3 scripts/phase2_transcribe.py --batch config/test_runner_batch.txt
python3 scripts/phase3_extract_gemini.py --batch config/test_runner_batch.txt
```

Verify all 5 completed successfully. If yes, the runner is validated.

Clean up: these 5 videos are now part of the processed set (125 total). That's fine — the production run's `--all` mode will skip them.

---

## Step 6: Verify Hang Detection

The runner should handle a hung process. Verify that the transcription and extraction scripts have internal timeouts:

```bash
grep -n "timeout\|TIMEOUT\|TimeoutError" scripts/phase2_transcribe.py scripts/phase3_extract_gemini.py
```

If no timeout handling exists for individual videos, add a wrapper:

```python
import signal

class VideoTimeout(Exception):
    pass

def timeout_handler(signum, frame):
    raise VideoTimeout("Video processing timed out")

# Before processing each video:
signal.signal(signal.SIGALRM, timeout_handler)
signal.alarm(timeout_seconds)  # 600 for marathons, 120 for clips
try:
    # ... process video ...
    signal.alarm(0)  # Cancel alarm on success
except VideoTimeout:
    print(f"  ⚠️ Timed out after {timeout_seconds}s — skipping")
    log_error(video_id, "timeout", f"Exceeded {timeout_seconds}s")
```

---

## Step 7: Update README.md — COMPREHENSIVE

Read the current README:

```bash
cat ../README.md
```

Then update ALL of the following sections. This is the most important README update in the project — it needs to document IAO as a mature methodology.

### 7a. Add IAO Methodology Section

Add a new top-level section after "What This Builds" and before "Architecture":

```markdown
## Methodology: Iterative Agentic Orchestration (IAO)

TripleDB is built using **Iterative Agentic Orchestration (IAO)** — a development
methodology where LLM agents execute pipeline phases autonomously while humans
review versioned artifacts between iterations. IAO emerged through 14 iterations
of this project and is now a repeatable framework for building data pipelines
with agentic assistance.

### The Eight Pillars

1. **Plan-Report Loop** — Every iteration starts with a design doc + plan doc
   and produces a build log + report. The four artifacts are the complete record.
   Any new agent or human can reconstruct the full project history from docs alone.

2. **Zero-Intervention Target** — Every question the agent asks during execution
   is a failure in the plan. Pre-answer every decision point. Measure plan quality
   by counting interventions. v2.11 had 20+. v3.12 onward: zero.

3. **Self-Healing Loops** — Errors are inevitable. Diagnose → fix → re-run (max
   3 attempts). 3 consecutive identical errors = stop and fix root cause. Never
   burn through hundreds of items with a known systemic failure.

4. **Versioned Artifacts as Source of Truth** — GEMINI.md is the version lock.
   Git commits mark iteration boundaries. The launch command never changes:
   `cd pipeline && gemini` → "Read GEMINI.md and execute."

5. **Artifacts Travel Forward** — Current docs in `docs/`, previous in
   `docs/archive/`. The design doc accumulates (additive). The plan doc is
   fresh each time (disposable). Agents never see outdated instructions.

6. **Methodology Co-Evolution** — IAO itself evolves through the Plan-Report
   loop. Error taxonomies, autonomy rules, pre-flight checks — all born from
   specific failures and refined through subsequent iterations.

7. **Separation of Interactive and Unattended** — Group A (iterative refinement)
   uses an LLM orchestrator. Group B (production) uses hardened bash scripts.
   The right tool for tuning is the wrong tool for a 70-hour unattended run.

8. **Progressive Trust Through Graduated Batches** — 30 → 60 → 90 → 120 videos.
   Each batch is bigger and harder. By Phase 4, the pipeline ran with zero
   interventions on batches including 4-hour marathons. Confidence was earned.

### Iteration History

| Iteration | Phase | Result | Key Learning |
|-----------|-------|--------|--------------|
| v0.7 | Setup | ✅ | Monorepo scaffolded. fish shell has no heredocs. |
| v1.8-v1.9 | Discovery | ❌ | 8GB VRAM can't run large models. Local extraction abandoned. |
| v1.10 | Discovery | ✅ | Gemini Flash API solved extraction. 186 restaurants. |
| v2.11 | Calibration | ✅ | 422 restaurants. 20+ interventions — each one analyzed. |
| v3.12 | Stress Test | ✅ | Zero interventions. Autonomous batch healing. 98 dedup merges. |
| v4.13 | Validation | ✅ | 608 restaurants. Group B green-lit. Prompts locked. |
| v5.14 | Production Setup | 🔧 | Runner infrastructure. Data quality fixes. |
```

### 7b. Project Status Table

Update Phase 4 row to ✅ Complete | v4.13. Add Phase 5 row showing current status.

### 7c. Architecture Diagram

Verify it shows "Gemini 2.5 Flash API" for both extraction and normalization (not Ollama). If v4.13 already fixed this, confirm it's still correct.

### 7d. Tech Stack Table

Same verification — should show Gemini Flash, not Ollama.

### 7e. Current Metrics

```markdown
### Current Metrics (Phase 4.13)

- **Videos processed:** 120 of 805
- **Unique restaurants:** 608
- **Unique dishes:** 1,015
- **Dedup merges:** 162
- **States covered:** 57
- **Extraction quality:** 98% guy_intro, 98% guy_response, 100% ingredients
- **Human interventions (last 2 iterations):** 0
```

### 7f. Changelog

Add entry:

```markdown
**v4.13 → v5.14 (Phase 5 Production Setup)**
- **Success:** Fixed null-name restaurant merging bug that was collapsing 14 distinct
  extraction failures into a single record. Built Group B runner infrastructure with
  checkpoint reporting and hang detection. Documented IAO methodology as Eight Pillars.
- **Challenge:** 62 restaurants with null/unknown state data required inference logic
  and a new "UNKNOWN" category.
- **Outcome:** Group B production run ready for tmux launch.
```

### 7g. Footer

```markdown
*Last updated: Phase 5.14 — Production Setup*
```

### 7h. Verify After Writing

```bash
grep -c "Iterative Agentic Orchestration" ../README.md  # Should be >= 1
grep -c "Eight Pillars" ../README.md                      # Should be >= 1
grep "Last updated" ../README.md                          # Should show 5.14
grep -c "Gemini 2.5 Flash" ../README.md                   # Should be >= 2
```

---

## Step 8: Generate Report Artifacts

### docs/ddd-report-v5.14.md

Must include:
1. Data quality fixes applied and results (null-name, null-state)
2. Updated normalization metrics after fixes
3. Group B runner infrastructure created (list all new files)
4. Test batch validation results
5. --all mode and resume support verification for all scripts
6. Hang detection verification
7. Comparison table: v1.10 → v2.11 → v3.12 → v4.13 → v5.14
8. Group B launch instructions for Kyle
9. Human interventions count (target: 0)
10. **Gemini's Recommendation:** Ready for production launch?
11. **README Update Confirmation:** ALL sections including IAO methodology

### docs/ddd-build-v5.14.md

Chronological log of every command, output, error, and fix.

**These artifacts + README update are the FINAL actions. Do NOT end the session without all three.**

---

## Phase 5.14 Success Criteria

```
[ ] Pre-flight passes (including secret scan)
[ ] Null-name merging bug fixed in phase4_normalize.py
[ ] Null/unknown state handling improved
[ ] Re-normalized data has 0 null-name merges
[ ] group_b_runner.sh created and executable
[ ] checkpoint_report.py created
[ ] All 3 pipeline scripts support --all mode
[ ] All 3 pipeline scripts have resume support
[ ] Hang detection / timeout handling verified in transcription + extraction
[ ] Test batch (5 videos) passes through runner successfully
[ ] Human interventions: 0
[ ] README.md COMPREHENSIVELY updated — CONFIRMED:
    [ ] IAO Methodology section with Eight Pillars added
    [ ] Iteration History table added
    [ ] Project status table updated
    [ ] Current metrics updated
    [ ] Changelog entry added (v4.13 → v5.14)
    [ ] Architecture diagram verified (Gemini Flash)
    [ ] Footer: Phase 5.14
[ ] ddd-report-v5.14.md generated with Group B launch instructions
[ ] ddd-build-v5.14.md generated
```

---

## GEMINI.md Update

Before launching, update `pipeline/GEMINI.md` to:

```markdown
# TripleDB Pipeline — Agent Instructions

## Current Iteration: 5.14

Read these two documents in order, then execute the plan:

1. ../docs/ddd-design-v5.14.md — Architecture, methodology, locked decisions
2. ../docs/ddd-plan-v5.14.md — Pre-flight checklist and execution steps

Follow the autonomy rules defined in the plan. Begin with Step 0.

## Rules That Never Change
- NEVER run git, flutter, or firebase commands
  (Exception: read-only git in pre-flight secret scan only)
- NEVER ask permission between steps — auto-proceed on EVERY step
- NEVER ask "should I continue?" or "would you like me to proceed?" — YES, ALWAYS
- If you find yourself typing a question mark, STOP. Re-read the plan. Execute.
- Self-heal errors: diagnose → fix → re-run (max 3 attempts, then skip)
- 3 consecutive identical errors = STOP, fix root cause, restart
- README.md update is the FINAL step — must include IAO methodology section
- All scripts run from this directory (pipeline/) as working directory
- Transcription: LD_LIBRARY_PATH=/usr/local/lib/ollama/cuda_v12:$LD_LIBRARY_PATH
- Extraction: Gemini 2.5 Flash API ($GEMINI_API_KEY), NOT local Ollama
- Prompts are LOCKED — do NOT modify extraction_prompt.md
```

---

## Launch Sequence

```bash
# 1. Archive previous iteration
cd ~/dev/projects/tripledb
mv docs/ddd-design-v4.13.md docs/archive/ 2>/dev/null
mv docs/ddd-plan-v4.13.md docs/archive/ 2>/dev/null
mv docs/ddd-report-v4.13.md docs/archive/ 2>/dev/null
mv docs/ddd-build-v4.13.md docs/archive/ 2>/dev/null

# 2. Place new docs
# (copy ddd-design-v5.14.md and ddd-plan-v5.14.md into docs/)

# 3. Update GEMINI.md
nano pipeline/GEMINI.md

# 4. Commit the setup
git add .
git commit -m "KT starting 5.14"

# 5. Launch (in Konsole, NOT IDE terminal)
cd pipeline
gemini
```

Then type:

```
Read GEMINI.md and execute.
```

---

## After v5.14: Group B Launch (for Kyle)

Once v5.14 completes and you've reviewed the report:

```bash
# Commit v5.14 results
git add .
git commit -m "KT completed 5.14 and README updated"
git push

# Launch Group B production run in tmux
cd ~/dev/projects/tripledb/pipeline
tmux new -s tripledb './scripts/group_b_runner.sh 2>&1 | tee data/logs/group_b_run.log'

# Detach: Ctrl+B, then D
# Reattach later: tmux attach -t tripledb
# Check progress: tail -f pipeline/data/logs/group_b_run.log
```

Estimated runtime: ~70 hours (2.9 days). The runner has resume support — if it crashes, relaunch the same command and it picks up where it left off.
