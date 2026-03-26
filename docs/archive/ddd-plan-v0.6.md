# TripleDB — Phase Prompts v6

**Project:** TripleDB — Agentic Data Extraction for Diners, Drive-Ins and Dives
**Author:** Kyle Thompson, Solutions Architect @ TachTech Engineering
**Date:** March 2026
**Domain:** tripleDB.com
**Repository:** github.com/TachTech-Engineering/tripledb
**Firebase Project:** tripledb-e0f77

This is the operational execution document. It defines the execution strategy, contains the Phase 0 prompt, and establishes the framework for Phase 1-7 prompts that will be written iteratively as output is reviewed.

**Prerequisites:**
- `docs/ddd-project-setup-v6.md` — machine and project setup (must be complete)
- `docs/ddd-design-architecture-v6.md` — architecture, data model, agent personas (must be read)

---

## Execution Strategy: Two-Group Architecture

The pipeline runs in two groups with fundamentally different execution models.

### Group A — Iterative Refinement (Human-in-the-loop)

Four batches of ~30 videos each, run interactively with Gemini CLI + GSD. Each batch's primary goal is to refine the pipeline prompts and scripts based on real output. The videos are processed, but the real deliverable is battle-tested code and prompts.

| Phase | Name          | Videos | Primary Goal                                              |
|------:|---------------|--------|-----------------------------------------------------------|
|     0 | Setup         | 0      | Machine config, repo scaffold, playlist dump              |
|     1 | Discovery     | 30     | "Does the pipeline work at all?"                          |
|     2 | Calibration   | 30     | "Is extraction accurate? Are prompts tuned?"              |
|     3 | Stress Test   | 30     | "Does it handle marathons, compilations, edge cases?"     |
|     4 | Validation    | 30     | "Is end-to-end clean? Lock prompts."                      |

After Phase 4: ~120 videos processed, all prompts locked, all scripts hardened.

### Group B — Production Run (Unattended)

Remaining ~684 videos processed by bash runner scripts (no LLM orchestrator). Prompts are locked from Group A. The scripts run unattended for 4-5 days with automated checkpoint reporting.

| Phase | Name          | Videos | Primary Goal                                              |
|------:|---------------|--------|-----------------------------------------------------------|
|   5-7 | Production    | ~684   | Process remainder, enrich, load Firestore, build Flutter app |

### Why Two Groups

An LLM orchestrator (Gemini CLI) is valuable during Group A because you're iterating — reviewing output, tuning prompts, debugging edge cases. That interactive loop benefits from an agent that can read error logs, propose fixes, and adapt.

During Group B, the prompts are locked and the scripts are hardened. An LLM orchestrator adds fragility (session timeouts, API hiccups) without adding value. A bash script running in tmux is more reliable for a 5-day unattended run.

---

## Script Architecture: Two Modes + Resume

Every pipeline script MUST support:

### Test-batch mode

Process a specific list of video IDs (for Group A):

```bash
python3 scripts/phase2_transcribe.py --batch config/test_batch.txt
```

### Full-run mode

Process all videos from the manifest (for Group B):

```bash
python3 scripts/phase2_transcribe.py --all
```

### Resume support

Every script checkpoints progress. If the script crashes at video 400, restarting picks up at 401:

```python
output_path = f"data/extracted/{video_id}.json"
if os.path.exists(output_path):
    try:
        with open(output_path) as f:
            json.load(f)  # Validate it's not corrupt
        print(f"Skipping {video_id} — already processed")
        continue
    except json.JSONDecodeError:
        print(f"Re-processing {video_id} — existing file corrupt")
```

---

## Group B: Checkpoint Reporting

During the production run, the pipeline generates automated reports.

### Checkpoint report (every 50 videos)

Written to `pipeline/data/logs/checkpoint-{N}.json`:

```json
{
  "checkpoint": 50,
  "timestamp": "2026-03-20T04:30:00Z",
  "videos_processed": 50,
  "videos_remaining": 634,
  "videos_failed": 2,
  "videos_skipped": 1,
  "extraction_success_rate": 0.94,
  "avg_dishes_per_restaurant": 3.2,
  "avg_ingredients_per_dish": 4.8,
  "guy_response_capture_rate": 0.72,
  "unique_restaurants_so_far": 145,
  "processing_time_avg_seconds": 180,
  "disk_usage_gb": 12.4
}
```

### Telegram notification with each checkpoint

```python
notify_telegram(f"Checkpoint {N}: {processed}/{total} videos, "
                f"{success_rate:.0%} success, {restaurants} restaurants")
```

### Automatic pause conditions

- Failure rate > 10% in last 50 videos → pause and notify
- Single video hangs > 30 minutes → kill, log, skip, continue
- Disk usage > 90% → pause and notify

---

## Phase 0 — Setup (THIS PHASE)

> Phase 0 is the only phase covered in this document. Subsequent phase
> prompts will be created as separate versioned markdown files during execution.

### What Phase 0 Produces

1. Fully configured machine (Part 1 of setup doc)
2. Scaffolded monorepo pushed to GitHub
3. `pipeline/config/playlist_urls.txt` with all 804 video URLs
4. `pipeline/config/test_batch.txt` with 30 curated test URLs
5. All 3 GEMINI.md files in place
6. Agent persona files copied to `pipeline/agents/`
7. Extraction prompt template at `pipeline/config/extraction_prompt.md`

### Phase 0 Prompt — Paste Into Gemini CLI

```
Read GEMINI.md for project context.

## Phase 0: Setup Validation

Verify the following before we proceed to Phase 1:

1. Read pipeline/GEMINI.md — confirm you understand your role and constraints.
2. Read ../docs/ddd-design-architecture-v6.md — confirm you understand the
   data model, pipeline architecture, and video types.
3. Verify pipeline/config/playlist_urls.txt exists and count the URLs:
   ```bash
   wc -l config/playlist_urls.txt
   ```
   Expected: ~804 lines.
4. Verify pipeline/config/test_batch.txt exists and count:
   ```bash
   wc -l config/test_batch.txt
   ```
   Expected: ~30 lines.
5. Verify agent personas exist in pipeline/agents/:
   ```bash
   ls agents/
   ```
   Expected: ddd-transcriber.md, ddd-extractor.md, ddd-normalizer.md,
   ddd-enricher.md, ddd-qa-checker.md
6. Verify extraction prompt exists:
   ```bash
   cat config/extraction_prompt.md | head -5
   ```
7. Verify Ollama is running and models are available:
   ```bash
   ollama list
   ```
   Expected: nemotron-super and qwen3.5:9b
8. Verify MCP servers: run /mcp in this session.

Report the results. If anything is missing, list what needs to be created
before Phase 1 can begin.

Do NOT commit or push. Present findings for review.
```

### After Phase 0

```bash
git checkout -b phase/0-setup
git add docs/ pipeline/config/ pipeline/agents/ GEMINI.md pipeline/GEMINI.md app/GEMINI.md .gitignore
git commit -m "KT Phase 0: project scaffold, playlist dump, agent personas"
git push -u origin phase/0-setup
```

---

## Phase 1-4 — Group A (PROMPTS TO BE WRITTEN)

Each phase's prompts will be created as a separate versioned markdown file after reviewing the previous phase's output. The files will follow this naming convention:

```
docs/phase-1-discovery-v1.md      (created after Phase 0 review)
docs/phase-2-calibration-v1.md    (created after Phase 1 review)
docs/phase-3-stress-test-v1.md    (created after Phase 2 review)
docs/phase-4-validation-v1.md     (created after Phase 3 review)
```

Each file will contain: copy-paste prompts for Gemini CLI, test batch video selection criteria, review checklists, commit instructions, and lessons learned from the previous phase.

### Phase 1 — Discovery (scope preview)

- Download 30 test videos via yt-dlp
- Transcribe via faster-whisper on CUDA
- Run first extraction with initial prompt against 10 transcripts
- Review: are restaurants correct? Are dishes real? Does guy_intro/guy_response capture correctly?
- Output: first draft of extraction prompt, download script, transcription script

### Phase 2 — Calibration (scope preview)

- Process next 30 videos with revised prompts
- Focus on extraction accuracy and prompt tuning
- Test dedup logic across videos that share restaurants
- Output: refined extraction prompt, dedup logic validated

### Phase 3 — Stress Test (scope preview)

- Process 30 videos including: 4-hour marathons, city compilations, short clips
- Focus on edge cases: unclear restaurant names, multi-chef segments, overlapping audio
- Output: hardened extraction prompt, marathon handling confirmed

### Phase 4 — Validation (scope preview)

- Process 30 more videos with locked prompts
- Run enrichment on ~50-80 unique restaurants
- Full end-to-end dry run: download → transcribe → extract → normalize → enrich
- Output: LOCKED prompts, validated enrichment, green-light for Group B

---

## Phase 5-7 — Group B (PROMPTS TO BE WRITTEN)

Group B prompts will be written after Phase 4 completes and prompts are locked. The architecture is defined here; the specific prompts are deferred.

### Group B Execution Model

```bash
#!/bin/bash
# group_b_runner.sh — runs in tmux, unattended
cd ~/dev/projects/tripledb/pipeline

echo "=== Phase 1: Download remaining videos ==="
python3 scripts/phase1_acquire.py --all

echo "=== Phase 2: Transcribe all ==="
systemctl --user stop ollama  # Free GPU for Whisper
python3 scripts/phase2_transcribe.py --all
systemctl --user start ollama  # Restart for Nemotron

echo "=== Phase 3: Extract all ==="
python3 scripts/phase3_extract.py --all

echo "=== PAUSE: Human review before normalization ==="
notify_telegram "Phases 1-3 complete. Review before Phase 4."
```

Phase 4 (normalization) requires the FULL Phase 3 dataset for dedup, so it waits for human review. Phases 5-6 (enrichment, Firestore load) run after normalization review. Phase 7 (Flutter app) is a separate effort.

### Group B Dev Reports

Every 50 videos, each script generates a checkpoint report (see Checkpoint Reporting section above). The reports track efficacy metrics: extraction success rate, guy_response capture rate, ingredient extraction quality, dedup accuracy.

If any metric degrades significantly compared to Group A baselines, the pipeline pauses and notifies. This catches prompt drift (where edge cases in later videos break assumptions from the test batches).

---

## Sprint Plan (Group A Timeline)

Designed for 8-hour review cycles.

### Block 1 — Thursday Evening → Friday Morning

**Objective:** Pipeline scaffolding + acquire test batch.

- Phase 0 complete (this document)
- Download 30 test videos from test_batch.txt
- Verify audio quality, file naming, manifest
- Morning review: spot-check 5 mp3s

### Block 2 — Friday Morning → Friday Evening

**Objective:** Transcription validated + first extraction.

- Transcribe all 30 test videos (CUDA, ~30-90 min)
- Review 5 transcripts for quality
- Run extraction on 10 transcripts with initial prompt
- **Tune extraction prompt** — expect 2-3 revision rounds
- Evening review: compare 3-4 extractions against actual video

### Block 3 — Friday Evening → Saturday Morning

**Objective:** Extraction finalized + dedup validated.

- Extract all 30 test videos with tuned prompt
- Normalize: validate dedup across video types
- Run QA checker on extraction output
- Morning review: dedup report, guy_response capture rate

### Block 4 — Saturday Morning → Saturday Evening

**Objective:** Enrichment validated + full pipeline dry run.

- Enrich ~50-80 unique restaurants from test batch
- Full end-to-end dry run with final prompts
- Fix remaining issues
- Evening review: green-light or red-light Group B

### Block 5 — Saturday Evening → Sunday Morning

**Objective:** Group B launched and running.

- Start full download of all 804 videos (~8-12 hrs)
- Verify first 10-20 downloads are clean
- Go to bed. Resume support handles any interruptions.
- Sunday morning: check progress before RSA.

### After RSA (~5 days later)

Return to find Phases 1-3 complete (or close). Review output, run Phase 4 (normalization), Phase 5 (enrichment), Phase 6 (Firestore load). Begin Phase 7 (Flutter app).

---

## Quick Reference: File Locations

```
tripledb/
├── docs/
│   ├── ddd-project-setup-v6.md           ← Setup guide (START HERE)
│   ├── ddd-design-architecture-v6.md     ← Architecture, data model, personas
│   ├── ddd-phase-prompts-v6.md           ← Execution strategy (THIS FILE)
│   ├── phase-1-discovery-v1.md           ← (created during Phase 1)
│   ├── phase-2-calibration-v1.md         ← (created during Phase 2)
│   ├── phase-3-stress-test-v1.md         ← (created during Phase 3)
│   ├── phase-4-validation-v1.md          ← (created during Phase 4)
│   └── gemini-flutter-mcp-v4.md          ← Flutter playbook (for Phase 7)
│
├── pipeline/
│   ├── scripts/
│   │   ├── phase1_acquire.py             ← yt-dlp batch downloader
│   │   ├── phase2_transcribe.py          ← faster-whisper (CUDA)
│   │   ├── phase3_extract.py             ← Ollama/Nemotron extraction
│   │   ├── phase4_normalize.py           ← Ollama/Qwen normalization
│   │   ├── phase5_enrich.py              ← Web scraping enrichment
│   │   └── phase6_load.py                ← Firestore loader
│   ├── agents/
│   │   ├── ddd-transcriber.md            ← Phase 2 persona
│   │   ├── ddd-extractor.md              ← Phase 3 persona
│   │   ├── ddd-normalizer.md             ← Phase 4 persona
│   │   ├── ddd-enricher.md               ← Phase 5 persona
│   │   └── ddd-qa-checker.md             ← Cross-phase QA
│   ├── config/
│   │   ├── playlist_urls.txt             ← 804 YouTube URLs
│   │   ├── test_batch.txt                ← 30 test video URLs
│   │   ├── firestore_schema.json         ← Firestore document model
│   │   └── extraction_prompt.md          ← Nemotron prompt template
│   ├── data/
│   │   ├── audio/                        ← {video_id}.mp3 (gitignored)
│   │   ├── transcripts/                  ← {video_id}.json (gitignored)
│   │   ├── extracted/                    ← {video_id}.json
│   │   ├── normalized/                   ← restaurants.jsonl, dishes.jsonl,
│   │   │                                    visits.jsonl, videos.jsonl
│   │   ├── enriched/                     ← Same 4 files + enrichment data
│   │   └── logs/                         ← Errors, checkpoints, QA reports
│   └── GEMINI.md                         ← Pipeline agent instructions
│
├── app/                                  ← Flutter Web (Phase 7 — deferred)
│   ├── design-brief/
│   ├── lib/
│   ├── assets/
│   ├── web/
│   ├── pubspec.yaml
│   └── GEMINI.md                         ← App agent instructions (deferred)
│
├── GEMINI.md                             ← Root agent router
├── .gitignore
└── README.md
```
