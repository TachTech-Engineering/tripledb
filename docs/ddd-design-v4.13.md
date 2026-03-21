# TripleDB — Design v4.13

---

# Part 1: IAO — Iterative Agentic Orchestration

## What IAO Is

A development methodology where LLM agents execute pipeline phases autonomously while humans review versioned artifacts between iterations. Each iteration produces a plan (input) and a report (output). The report informs the next plan. The methodology itself evolves alongside the project.

## Core Principles (Proven Through v0.7–v3.12)

**1. Plan-Report Loop.** Every iteration begins with a design doc (what the system is) and a plan doc (what to do). Every iteration produces a build log (what happened) and a report (metrics + recommendation). These four artifacts are the complete record.

**2. Zero Human Intervention Target.** Every question the agent asks the human during execution is a failure in the plan document. Measure plan quality by counting interventions. Zero is the target. v3.12 achieved zero — this is now the baseline, not the aspiration.

**3. Absolute Autonomy.** The agent NEVER asks permission, NEVER asks "should I proceed?", NEVER pauses for confirmation between steps. The plan document IS the permission. If a step is in the plan, execute it. If a decision point arises, consult this design doc for locked decisions. If neither doc covers it, make the best decision, log it, and continue. Asking the human is a last resort reserved for situations where continuing would be destructive (e.g., deleting data with no backup). v2.11 had 20+ interventions. v3.12 had 0. Zero is now the floor.

**4. Self-Healing Loops.** When an error occurs: diagnose → fix → re-run. Max 3 attempts per error, then log and skip. If 3 consecutive items fail with the same error, STOP the batch, fix the root cause, restart. Never burn through 30 items with a known systemic failure.

**5. GEMINI.md Is the Version Lock.** The agent reads `GEMINI.md` which points to the current design and plan docs. Updating GEMINI.md is the first step of every iteration. Committing it is the gate. The launch command is always: `cd pipeline && gemini` → "Read GEMINI.md and execute."

**6. Git Commits Mark Iteration Boundaries.** Two commits per iteration: `"KT starting {P}.{I}"` (setup) and `"KT completed {P}.{I} and README updated"` (close). The git log IS the iteration history.

**7. Artifacts Travel Forward, Not Backward.** Only the current iteration's docs live in `docs/`. Previous iterations go to `docs/archive/`. The design doc accumulates learnings. The plan doc is fresh each time.

**8. Secret Hygiene.** API keys, tokens, and credentials NEVER appear in committed files. Every iteration's pre-flight includes a secret scan. If a key is found in any tracked file, pre-flight FAILS. The agent must remediate before proceeding. This is a hard gate — no exceptions.

## Artifact Spec

| Direction | File | Author | Purpose |
|-----------|------|--------|---------|
| Input | `ddd-design-v{P}.{I}.md` | Claude | Living architecture, locked decisions, IAO methodology |
| Input | `ddd-plan-v{P}.{I}.md` | Claude | Pre-flight checklist, execution steps, success criteria, launch instructions |
| Output | `ddd-build-v{P}.{I}.md` | Gemini | Full session transcript — all commands, outputs, errors, fixes |
| Output | `ddd-report-v{P}.{I}.md` | Gemini | Metrics, validation results, issues, Gemini's recommendation for next phase |
| Output | `README.md` (updated) | Gemini | Changelog entry, project status table, metrics, footer update. MUST be comprehensive. |

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

Every `ddd-report-v{P}.{I}.md` must end with these sections:

**Gemini's Recommendation:** The agent's assessment of whether to proceed to the next phase or re-run with adjustments. Include specific reasoning and any metrics that didn't meet targets.

**README Update Confirmation:** Confirm that README.md was updated with changelog entry, project status table, current metrics, and footer timestamp. If README was NOT updated, the report is incomplete.

## README Update Specification

The README.md update is NOT a one-liner. Every iteration must update ALL of the following:

1. **Project Status table** — update the current phase row to ✅ Complete with iteration number
2. **Architecture diagram** — if any pipeline component changed, update it
3. **Changelog section** — add a new entry in the established format:
   ```
   **v{prev} → v{curr} (Phase N Name)**
   - **Success:** [what worked]
   - **Challenge:** [what was hard]
   - **Pivot for v{curr}:** [what changed]
   ```
4. **Current metrics** — update any metrics mentioned in README body (restaurant count, video count, etc.)
5. **Footer** — update to `*Last updated: Phase {P}.{I} — {Phase Name}*`
6. **Stale references** — fix any references to deprecated tools/approaches (e.g., if README still says Ollama/Qwen for normalization, fix it to Gemini Flash API)

## What Has Been Resolved

- **Intervention rate:** v2.11 had 20+, v3.12 achieved 0. Solved via exhaustive pre-answering in plan docs.
- **CUDA path:** Solved — shell-level `LD_LIBRARY_PATH` before Python launch.
- **Marathon handling:** Accepted edge case for 4+ hour videos. Will chunk in Group B if needed.
- **Batch healing:** v3.12 proved autonomous batch modification works (swapping marathons for clips).

## What Still Needs Validation (Phase 4 Focus)

- **Prompt lock readiness:** Are extraction and normalization prompts stable enough for 685 unattended videos?
- **End-to-end dry run:** Can all 7 steps (select → download → transcribe → extract → validate → normalize → validate) run as a single autonomous session?
- **Owner_chef capture:** 16% null in v3.12 — can prompt tuning reduce this, or is it structural?
- **Marathon chunking:** Need a strategy for Group B marathons that exceed single-call token limits.
- **Secret scanning:** Verify no API keys in git history before Group B begins.

## ADR Registry

| ADR | Project | Status | Iterations |
|-----|---------|--------|------------|
| ADR-001 | TripleDB | Active | v0.7 → v4.13 (current) |

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
      (cloud)                        Timeout: 120s clips, 180s episodes,
Extracted Restaurant JSON                    240s compilations, 600s marathons.
    ↓ Gemini 2.5 Flash API          Dedup by name+city. Merge dishes/visits.
      (cloud)                        Fuzzy match: Levenshtein < 3.
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
| 3 | Stress Test | 31 | ✅ v3.12 | 511 restaurants, 896 dishes, 98 dedup merges |
| 4 | Validation | 30 | 🔧 v4.13 | Lock prompts, full dry run, Group B readiness |

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
  "location": "<GeoPoint — for proximity queries via geoflutterfire_plus>",
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
      "timestamp_start": 215.5,
      "confidence": 0.95
    }
  ],
  "created_at": "<timestamp>",
  "updated_at": "<timestamp>"
}
```

### Firestore Indexes (Phase 6)

| Fields | Purpose |
|--------|---------|
| state ASC, google_rating DESC | Filter by state, sort by rating |
| cuisine_type ASC, state ASC | Filter by cuisine and state |
| still_open ASC, state ASC | Find open restaurants by state |

GeoPoint `location` field enables proximity queries via `geoflutterfire_plus` in Flutter. Phase 6 populates this from lat/lng during Firestore load.

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

## Normalization Rules (Bake Into Prompt and Scripts)

### Ingredient Normalization
- Lowercase: "Brisket" → "brisket"
- Singular: "tomatoes" → "tomato"
- Strip brand names: "Frank's Red Hot" → "hot sauce"
- Standardize: "bbq sauce" = "barbecue sauce" → "bbq sauce"

### State Normalization
- Full name → abbreviation: "California" → "CA", "New York" → "NY"

### Dedup Rules
- Fuzzy match: Levenshtein distance < 3 for names in the same city
- "Joe's BBQ" and "Joes BBQ" in Austin = same restaurant
- "Joe's BBQ" in Austin and "Joe's BBQ" in Dallas = different
- When merging: keep the most complete record, merge dishes from all videos
- Log all merges to `data/logs/phase-4-dedup-report.jsonl`
- Flag ambiguous merges to `data/logs/phase-4-review-needed.jsonl`

### Confidence Scores
- Retained from extraction through normalization
- 0.9-1.0 = clearly stated, 0.7-0.89 = reasonably clear, 0.5-0.69 = inferred, <0.5 = best guess
- Used in Phase 4 validation to identify low-quality records
- Dropped at Firestore load (Phase 6) — not user-facing

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

**8GB VRAM constraint:** Local LLM inference (Ollama) is limited to models ≤6GB quantized for GPU-only inference. This is why extraction uses Gemini Flash API (cloud). This decision is permanent unless hardware is upgraded.

## Scripts Inventory

| Script | Phase | Purpose | Status |
|--------|-------|---------|--------|
| `scripts/pre_flight.py` | All | Environment + secret validation | ✅ Active |
| `scripts/phase1_acquire.py` | 1 | yt-dlp batch downloader | ✅ Active |
| `scripts/phase2_transcribe.py` | 2 | faster-whisper CUDA transcription | ✅ Active |
| `scripts/phase3_extract_gemini.py` | 3 | Gemini Flash API extraction | ✅ Active |
| `scripts/phase4_normalize.py` | 4 | Dedup + normalization | ✅ Active |
| `scripts/select_batch.py` | All | Batch selection (generalized) | ✅ Active |
| `scripts/validate_extraction.py` | All | Extraction quality metrics | ✅ Active |
| `scripts/heal_batch.py` | All | Swap failed videos for alternatives | ✅ Active (new in v3.12) |
| `scripts/secret_scan.py` | All | Scan tracked files for leaked secrets | 🆕 v4.13 |

## Known Gotchas (Bake Into Every Plan)

1. **CUDA path:** `LD_LIBRARY_PATH=/usr/local/lib/ollama/cuda_v12:$LD_LIBRARY_PATH` at shell level, not Python level.
2. **fish shell:** No heredocs. Use `printf` or `nano`.
3. **yt-dlp flags:** Always `--remote-components ejs:github --cookies-from-browser chrome`.
4. **GPU contention:** Stop Ollama before transcription. Kill orphaned Python/CUDA processes.
5. **Working directory:** Launch Gemini from `pipeline/` not project root.
6. **Marathon timeouts:** ≥600s for videos >60 min. Consider chunking for 4+ hour videos.
7. **Gemini model:** `gemini-2.5-flash` (not 2.0).
8. **3 consecutive identical errors:** STOP batch, fix root cause, restart.
9. **README update:** MUST be comprehensive (status table + changelog + metrics + footer). Final step.
10. **Secret scan:** Run before ANY git operation. API keys in git history = automatic revocation by Google.
11. **No permission prompts:** Agent NEVER asks "should I proceed?" — the plan IS the permission.

## Current State (After v3.12)

- **Videos processed:** 89 of 805 (31 in Phase 3, cumulative 89)
- **Unique restaurants:** 511
- **Unique dishes:** 896
- **Dedup merges:** 98
- **States covered:** 52
- **Extraction quality:** 98% guy_intro, 98% guy_response, 100% ingredients
- **Owner_chef null:** 16% (above 12% target — structural in compilations)
- **Avg dishes/restaurant:** ~1.75 (below 2.0 target — compilation format effect)
- **Remaining in Group A:** ~30 videos (Phase 4)
- **Remaining in Group B:** ~685 videos
- **Accepted edge cases:** `bawGcAsAA-w` (4-hr marathon, parse_error — token limit)

## Group B Readiness Checklist (Validate in Phase 4)

```
[ ] Extraction prompt locked — no further tuning after Phase 4
[ ] Normalization prompt locked
[ ] All scripts have --all mode for full playlist processing
[ ] All scripts have resume support (skip completed items)
[ ] Secret scan passes — no keys in any tracked file or git history
[ ] Marathon chunking strategy documented (for videos exceeding token limits)
[ ] Checkpoint reporting implemented (every 50 videos)
[ ] Automatic pause conditions defined (failure rate >10%, hang >30min, disk >90%)
[ ] Telegram notification integration tested
[ ] README fully current with accurate architecture, metrics, and changelog
```

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
- NEVER run git, flutter, or firebase commands
- NEVER ask permission between steps — auto-proceed on EVERY step
- NEVER ask "should I continue?" or "would you like me to proceed?" — YES, ALWAYS
- Self-heal errors: diagnose → fix → re-run (max 3 attempts, then skip)
- 3 consecutive identical errors = STOP, fix root cause, restart
- README.md update is the FINAL step — comprehensive, not a one-liner
- All scripts run from this directory (pipeline/) as working directory
- Transcription MUST be launched with: LD_LIBRARY_PATH=/usr/local/lib/ollama/cuda_v12:$LD_LIBRARY_PATH
- Extraction uses Gemini 2.5 Flash API ($GEMINI_API_KEY), NOT local Ollama
- Run secret_scan.py before generating report — HARD GATE
```
