# TripleDB — Design v3.12

---

# Part 1: IAO — Iterative Agentic Orchestration

## What IAO Is

A development methodology where LLM agents execute pipeline phases autonomously while humans review versioned artifacts between iterations. Each iteration produces a plan (input) and a report (output). The report informs the next plan. The methodology itself evolves alongside the project.

## Core Principles (Proven Through v0.7–v2.11)

**1. Plan-Report Loop.** Every iteration begins with a design doc (what the system is) and a plan doc (what to do). Every iteration produces a build log (what happened) and a report (metrics + recommendation). These four artifacts are the complete record.

**2. Zero Human Intervention Target.** Every question the agent asks the human during execution is a failure in the plan document. Measure plan quality by counting interventions. Zero is the target. v2.11 had 20+ interventions — each one is analyzed and pre-answered in the next iteration's plan.

**3. Self-Healing Loops.** When an error occurs: diagnose → fix → re-run. Max 3 attempts per error, then log and skip. If 3 consecutive items fail with the same error, STOP the batch, fix the root cause, restart. Never burn through 30 items with a known systemic failure.

**4. GEMINI.md Is the Version Lock.** The agent reads `GEMINI.md` which points to the current design and plan docs. Updating GEMINI.md is the first step of every iteration. Committing it is the gate. The launch command is always: `cd pipeline && gemini` → "Read GEMINI.md and execute."

**5. Git Commits Mark Iteration Boundaries.** Two commits per iteration: `"KT starting {P}.{I}"` (setup) and `"KT completed {P}.{I} and README updated"` (close). The git log IS the iteration history.

**6. Artifacts Travel Forward, Not Backward.** Only the current iteration's docs live in `docs/`. Previous iterations go to `docs/archive/`. The design doc accumulates learnings. The plan doc is fresh each time.

## Artifact Spec

| Direction | File | Author | Purpose |
|-----------|------|--------|---------|
| Input | `ddd-design-v{P}.{I}.md` | Claude | Living architecture, locked decisions, IAO methodology |
| Input | `ddd-plan-v{P}.{I}.md` | Claude | Pre-flight checklist, execution steps, success criteria, launch instructions |
| Output | `ddd-build-v{P}.{I}.md` | Gemini | Full session transcript — all commands, outputs, errors, fixes |
| Output | `ddd-report-v{P}.{I}.md` | Gemini | Metrics, validation results, issues, Gemini's recommendation for next phase |
| Output | `README.md` (updated) | Gemini | Changelog entry + footer update. MUST be the final step. |

## Git Workflow Per Iteration

```
1. Move previous docs to docs/archive/
2. Place new ddd-design-v{P}.{I}.md and ddd-plan-v{P}.{I}.md in docs/
3. Update pipeline/GEMINI.md version pointer
4. git add . && git commit -m "KT starting {P}.{I}"
5. cd pipeline && gemini → "Read GEMINI.md and execute."
6. Gemini executes autonomously, produces build + report + README update
7. Human reviews report
8. git add . && git commit -m "KT completed {P}.{I} and README updated"
9. Human + Claude decide: next phase or re-run adjusted iteration
```

## Report Requirements

Every `ddd-report-v{P}.{I}.md` must end with two sections:

**Gemini's Recommendation:** The agent's assessment of whether to proceed to the next phase or re-run with adjustments. Include specific reasoning and any metrics that didn't meet targets.

**README Update:** Confirm that README.md was updated with a changelog entry and footer timestamp. If README was NOT updated, the report is incomplete.

## What Still Needs Iteration

- **Intervention reduction:** v2.11 still required 20+ human interventions. Target: <5 for v3.12.
- **Background process handling:** Long-running tasks (transcription, marathon extraction) hit Gemini CLI's 5-minute shell timeout. Need a pattern for "launch in foreground, Gemini monitors progress."
- **Pre-flight depth:** Current pre-flight checks env vars but doesn't test actual library loading. Need functional tests (import the library, run inference) not just existence checks.
- **Error taxonomy:** Build a classification of error types and pre-baked fixes so the plan can include a troubleshooting lookup table.

## ADR Registry

| ADR | Project | Status | Iterations |
|-----|---------|--------|------------|
| ADR-001 | TripleDB | Active | v0.7 → v3.12 (current) |

---

# Part 2: ADR-001 — TripleDB

## Mandate

Process 805 YouTube DDD videos into a structured, searchable restaurant database. Deliver a Flutter Web app at tripleDB.com where users can find diners near them, search by any dimension (dish, cuisine, city, chef, ingredient), and watch the exact moment Guy Fieri walks in.

## Pipeline Architecture

```
YouTube Playlist (805 videos)
    ↓ yt-dlp (local)               Flags: --remote-components ejs:github
MP3 Audio                                  --cookies-from-browser chrome
    ↓ faster-whisper large-v3       Launch: LD_LIBRARY_PATH=/usr/local/lib/
      (local CUDA)                          ollama/cuda_v12:$LD_LIBRARY_PATH
Timestamped Transcripts
    ↓ Gemini 2.5 Flash API          Free tier. 1M context. No chunking.
      (cloud)                        Timeout: 120s clips, 300s marathons.
Extracted Restaurant JSON
    ↓ Gemini 2.5 Flash API          Dedup by name+city. Merge dishes/visits.
      (cloud)
Normalized JSONL
    ↓ Firecrawl + Playwright MCP     Phase 5 (deferred)
Enriched Data
    ↓ Firebase Admin SDK             Phase 6 (deferred)
Cloud Firestore
    ↓ Flutter Web                    Phase 7 (deferred)
tripleDB.com
```

## Execution Groups

**Group A — Iterative Refinement (Phases 0-4)**

| Phase | Name | Videos | Status | Key Metric |
|-------|------|--------|--------|------------|
| 0 | Setup | 0 | ✅ v0.7 | Monorepo scaffolded, 805 URLs |
| 1 | Discovery | 30 | ✅ v1.10 | 186 restaurants, 290 dishes |
| 2 | Calibration | 30 | ✅ v2.11 | 422 restaurants, 624 dishes (cumulative) |
| 3 | Stress Test | 30 | 🔧 v3.12 | Focus: marathons, edge cases, dedup validation |
| 4 | Validation | 30 | ⏳ Pending | Lock prompts, full dry run |

**Group B — Production Run (Phases 5-7)**

| Phase | Name | Videos | Status |
|-------|------|--------|--------|
| 5 | Enrichment | All | ⏳ | Geocode, ratings, open/closed via Firecrawl |
| 6 | Firestore Load | All | ⏳ | JSONL → Firestore documents |
| 7 | Flutter App | N/A | ⏳ | tripleDB.com |

## Data Model (Firestore Target)

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
      "ingredients": ["chicken", "buttermilk", "seasoned flour"],
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
  "video_id": "<11-char YouTube ID>",
  "youtube_url": "https://youtube.com/watch?v=<id>",
  "title": "<video title>",
  "duration_seconds": 1619,
  "video_type": "compilation",
  "restaurant_count": 5,
  "processed_at": "<timestamp>"
}
```

### Video Types

| Type | Duration | Typical Restaurants |
|------|----------|-------------------|
| `clip` | <15 min | 1 |
| `full_episode` | 15-25 min | 2-3 |
| `compilation` | 25-60 min | 3-8 |
| `marathon` | >60 min | 10-30+ |

## Hardware & Constraints

```
NZXT MS-7E06 Desktop
CPU:  Intel Core i9-13900K (24-core, 5.8 GHz boost)
RAM:  64 GB DDR4
GPU:  NVIDIA GeForce RTX 2080 SUPER (8 GB VRAM)
OS:   CachyOS x86_64 / KDE Plasma 6.6.2 / Wayland
Shell: Fish 4.5.0
IDE:  Antigravity (VS Code fork)
```

**8GB VRAM constraint:** Local LLM inference (Ollama) is limited to models ≤6GB quantized for GPU-only inference. Any model requiring >8GB spills to CPU RAM and becomes impractically slow. This is why extraction uses Gemini Flash API (cloud) instead of local Ollama.

## Scripts Inventory

| Script | Phase | Purpose | Status |
|--------|-------|---------|--------|
| `scripts/pre_flight.py` | All | Environment validation | ✅ Active |
| `scripts/phase1_acquire.py` | 1 | yt-dlp batch downloader | ✅ Active |
| `scripts/phase2_transcribe.py` | 2 | faster-whisper CUDA transcription | ✅ Active |
| `scripts/phase3_extract_gemini.py` | 3 | Gemini Flash API extraction | ✅ Active |
| `scripts/phase3_extract.py` | 3 | Local Ollama extraction (deprecated) | ❌ Deprecated |
| `scripts/phase4_normalize.py` | 4 | Dedup + normalization | ✅ Active |
| `scripts/select_phase2_batch.py` | 2 | Batch selection | ✅ Active (generalize for Phase 3+) |
| `scripts/validate_extraction.py` | All | Extraction quality metrics | ✅ Active |

## Known Gotchas (Bake Into Every Plan)

1. **CUDA path:** `LD_LIBRARY_PATH=/usr/local/lib/ollama/cuda_v12:$LD_LIBRARY_PATH` at shell level, not Python level.
2. **fish shell:** No heredocs. Use `printf` or `nano`.
3. **yt-dlp flags:** Always `--remote-components ejs:github --cookies-from-browser chrome`.
4. **GPU contention:** Stop Ollama before transcription.
5. **Working directory:** Launch Gemini from `pipeline/` not project root.
6. **Marathon timeouts:** ≥300s for videos >60 min.
7. **Gemini model:** `gemini-2.5-flash` (not 2.0).
8. **Agency Agents:** `--tool gemini-cli` not `--tool gemini`.
9. **3 consecutive identical errors:** STOP batch, fix root cause, restart.
10. **README update:** MUST be the final step in every report generation. If Gemini forgets, the report is incomplete.

## Current State (After v2.11)

- **Videos processed:** 60 of 805
- **Unique restaurants:** 422
- **Unique dishes:** 624
- **Dedup merges:** 59
- **States covered:** 52
- **Extraction quality:** 98% guy_intro, 99% guy_response, 100% ingredients
- **Remaining in Group A:** ~60 videos (Phase 3 + Phase 4)
- **Remaining in Group B:** ~685 videos

## GEMINI.md Template

Update `pipeline/GEMINI.md` at the start of each iteration:

```markdown
# TripleDB Pipeline — Agent Instructions

## Current Iteration: {P}.{I}

Read these two documents in order, then execute the plan:

1. ../docs/ddd-design-v{P}.{I}.md — Architecture, methodology, locked decisions
2. ../docs/ddd-plan-v{P}.{I}.md — Pre-flight checklist and execution steps

Follow the autonomy rules defined in the plan. Begin with Step 0.

## Rules That Never Change
- NEVER run git commit, git push, or firebase deploy
- NEVER ask permission between steps — auto-proceed
- Self-heal errors: diagnose → fix → re-run (max 3 attempts, then skip)
- 3 consecutive identical errors = STOP, fix root cause, restart
- README.md update is the FINAL step of report generation — do not skip it
- All scripts run from this directory (pipeline/) as working directory
```
