# TripleDB — Design v5.14

---

# Part 1: IAO — Iterative Agentic Orchestration

## What IAO Is

A development methodology where LLM agents execute pipeline phases autonomously while humans review versioned artifacts between iterations. Each iteration produces a plan (input) and a report (output). The report informs the next plan. The methodology itself evolves alongside the project.

IAO emerged organically through 13 iterations of the TripleDB project. What started as "give the agent a prompt and hope" evolved into a rigorous, repeatable framework for building data pipelines with agentic assistance. The principles below are battle-tested — each one exists because its absence caused a measurable failure.

## The Eight Pillars of IAO

### Pillar 1: Plan-Report Loop
Every iteration begins with two input artifacts (design doc + plan doc) and produces two output artifacts (build log + report). The design doc is the living architecture — it accumulates decisions and learnings across iterations. The plan doc is disposable — fresh each time, informed by the previous report. The build log is the raw transcript. The report is structured metrics + a recommendation. These four artifacts are the complete record of every iteration.

**Why it matters:** Without structured artifacts, knowledge lives only in chat history and human memory. Both are lossy. The artifact trail means any new agent (or human) can reconstruct the full project history from docs alone.

### Pillar 2: Zero-Intervention Target
Every question the agent asks the human during execution is a failure in the plan document. Measure plan quality by counting interventions. Zero is the target. Pre-answer every decision point in the plan. If the agent encounters an uncovered situation, the plan should instruct it to make the best decision, log its reasoning, and continue — not to ask.

**Why it matters:** Human intervention breaks the feedback loop. It introduces unlogged context, creates dependencies on availability, and prevents the pipeline from running unattended. v2.11 had 20+ interventions. v3.12 and v4.13 had zero. The plan docs got better because every intervention was analyzed and pre-answered in the next iteration.

### Pillar 3: Self-Healing Loops
When an error occurs: diagnose → fix → re-run. Max 3 attempts per error, then log and skip. If 3 consecutive items fail with the same error, STOP the batch, fix the root cause, restart. Never burn through hundreds of items with a known systemic failure.

**Why it matters:** Errors are inevitable in data pipelines. The question is whether the pipeline collapses at the first error or handles it gracefully. Self-healing with bounded retries and systemic failure detection gives you resilience without infinite loops. v3.12's autonomous batch healing (swapping marathons for clips) proved the agent can make structural decisions, not just retry.

### Pillar 4: Versioned Artifacts as Source of Truth
`GEMINI.md` is the version lock — it points to the current design and plan docs. Updating it is the first step of every iteration. The launch command is always the same: `cd pipeline && gemini` → "Read GEMINI.md and execute." Git commits mark iteration boundaries: `"KT starting {P}.{I}"` (setup) and `"KT completed {P}.{I} and README updated"` (close). The git log IS the iteration history.

**Why it matters:** Without a version lock, agents read stale instructions. Without commit boundaries, you can't tell where one iteration ends and the next begins. The GEMINI.md pattern gives you a single file to update that cascades to the entire agent context.

### Pillar 5: Artifacts Travel Forward, Not Backward
Only the current iteration's docs live in `docs/`. Previous iterations go to `docs/archive/`. The design doc accumulates learnings (additive). The plan doc is fresh each time (disposable). This prevents the agent from reading outdated instructions while preserving the full history for human review.

**Why it matters:** Agents are literal. If they can see the Phase 2 plan alongside the Phase 4 plan, they may follow the wrong one. Archiving previous iterations eliminates ambiguity. The design doc carries forward everything that matters; the plan doc carries only what's next.

### Pillar 6: Methodology Co-Evolution
The methodology itself is an artifact that evolves alongside the project. Each iteration refines not just the pipeline code but the development process. Error taxonomies, autonomy rules, pre-flight checks, artifact specs — all of these were born from specific failures and refined through subsequent iterations.

**Why it matters:** Most methodologies are defined upfront and followed. IAO is defined by what works and discards what doesn't. The Plan-Report loop applies to the methodology itself: each report identifies process failures, and the next design doc incorporates fixes.

### Pillar 7: Separation of Interactive and Unattended Execution
Interactive execution (Group A) uses an LLM orchestrator for iterative refinement — reviewing output, tuning prompts, debugging edge cases. Unattended execution (Group B) uses hardened bash scripts with checkpoint reporting. An LLM orchestrator adds fragility (session timeouts, API hiccups) without adding value when prompts are locked and scripts are proven.

**Why it matters:** The temptation is to use the LLM for everything. But a 70-hour production run doesn't benefit from an agent that might crash, hallucinate a fix, or ask a question at 3 AM. The right tool for Group A (agent) is the wrong tool for Group B (bash + tmux). Knowing when to graduate from interactive to unattended is a key design decision.

### Pillar 8: Progressive Trust Through Graduated Batches
Start with 30 videos. Then 60. Then 90. Then 120. Each batch is bigger and harder — more edge cases, more overlap, more stress. Each batch validates the pipeline AND the methodology. By the time you run the full 685-video production batch, every failure mode has been seen, logged, and handled.

**Why it matters:** Running 805 videos on day one would have buried us in undiagnosed failures. The graduated batches turned every failure into a learning and every learning into a plan improvement. By Phase 4, the pipeline ran with zero interventions on a batch including 4-hour marathons. That confidence was earned, not assumed.

## IAO Iteration History

| Iteration | Phase | Interventions | Key Learning |
|-----------|-------|---------------|--------------|
| v0.7 | Setup | N/A | Monorepo scaffolded. fish shell has no heredocs. |
| v1.8 | Discovery | 20+ | 8GB VRAM can't run Nemotron 42GB. CUDA path must be shell-level. |
| v1.9 | Discovery | 20+ | Local 9B models too slow for structured extraction on this hardware. |
| v1.10 | Discovery | ~10 | Gemini 2.5 Flash API solved extraction. 186 restaurants from 30 videos. |
| v2.11 | Calibration | 20+ | Marathons need 300s timeout. CUDA path is shell-level, not Python. |
| v3.12 | Stress Test | **0** | Autonomous batch healing. 98 dedup merges. Zero-intervention target met. |
| v4.13 | Validation | **0** | 608 restaurants, 162 merges. Group B green-lit. Prompts locked. |

## Artifact Spec

| Direction | File | Author | Purpose |
|-----------|------|--------|---------|
| Input | `ddd-design-v{P}.{I}.md` | Claude | Living architecture, locked decisions, IAO methodology |
| Input | `ddd-plan-v{P}.{I}.md` | Claude | Pre-flight checklist, execution steps, success criteria, launch instructions |
| Output | `ddd-build-v{P}.{I}.md` | Gemini | Full session transcript — all commands, outputs, errors, fixes |
| Output | `ddd-report-v{P}.{I}.md` | Gemini | Metrics, validation results, issues, Gemini's recommendation for next phase |
| Output | `README.md` (updated) | Gemini | Comprehensive update: status table, architecture, metrics, IAO methodology, changelog, footer |

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

## Agent Restrictions

```
1. NEVER run git, flutter, or firebase commands.
   EXCEPTION: pre-flight secret scan may use read-only git commands
   (git ls-files, git log) to detect leaked secrets. No git write
   operations (add, commit, push, checkout, branch) under any circumstance.
2. NEVER ask permission, ask "should I proceed?", or pause for confirmation.
   The plan document IS the permission. Execute it.
3. Self-heal errors: diagnose → fix → re-run (max 3 attempts, then skip).
4. 3 consecutive identical errors = STOP, fix root cause, restart.
5. If a decision point arises not covered by the plan or design doc,
   make the best decision, LOG the reasoning in the build doc, continue.
6. README update is comprehensive — not a one-liner. Every section specified
   in the plan must be updated.
```

## README Update Specification

Every iteration must update ALL of the following in README.md:

1. **Project Status table** — current phase row to ✅ Complete with iteration number
2. **Architecture diagram** — if any pipeline component changed
3. **IAO Methodology section** — add/update the Eight Pillars and iteration history
4. **Changelog section** — new entry in established format
5. **Current metrics** — restaurant count, video count, dish count, state count
6. **Footer** — `*Last updated: Phase {P}.{I} — {Phase Name}*`
7. **Stale references** — fix anything that references deprecated tools/approaches

## ADR Registry

| ADR | Project | Status | Iterations |
|-----|---------|--------|------------|
| ADR-001 | TripleDB | Active | v0.7 → v5.14 (current) |

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
Normalized JSONL                     Null-name/null-state filtering.
    ↓ Firecrawl + Playwright MCP     Phase 5+ (deferred to post-production)
Enriched Data
    ↓ Firebase Admin SDK             Phase 6 (deferred)
Cloud Firestore
    ↓ Flutter Web                    Phase 7 (deferred)
tripleDB.com
```

## Execution Groups

**Group A — Iterative Refinement (Phases 0-4) — COMPLETE**

| Phase | Name | Videos | Status | Key Metric |
|-------|------|--------|--------|------------|
| 0 | Setup | 0 | ✅ v0.7 | Monorepo scaffolded, 805 URLs |
| 1 | Discovery | 30 | ✅ v1.10 | 186 restaurants, 290 dishes |
| 2 | Calibration | 30 | ✅ v2.11 | 422 restaurants, 624 dishes (cumulative) |
| 3 | Stress Test | 31 | ✅ v3.12 | 511 restaurants, 896 dishes, 98 dedup merges |
| 4 | Validation | 30 | ✅ v4.13 | 608 restaurants, 1015 dishes, 162 dedup merges |

**Group B — Production Run (Phase 5+)**

| Phase | Name | Scope | Status |
|-------|------|-------|--------|
| 5.14 | Production Setup | Bash runner, checkpoint reporting, data quality fixes, README | 🔧 Current |
| 5.15 | Production Run | 685 remaining videos (download → transcribe → extract → normalize) | ⏳ Next (tmux, unattended) |
| 6 | Enrichment | Geocode, ratings, open/closed via Firecrawl | ⏳ Deferred |
| 7 | Firestore Load | JSONL → Firestore documents | ⏳ Deferred |
| 8 | Flutter App | tripleDB.com | ⏳ Deferred |

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
      "timestamp_start": 215.5
    }
  ],
  "created_at": "<timestamp>",
  "updated_at": "<timestamp>"
}
```

### Firestore Indexes (Phase 7)

| Fields | Purpose |
|--------|---------|
| state ASC, google_rating DESC | Filter by state, sort by rating |
| cuisine_type ASC, state ASC | Filter by cuisine and state |
| still_open ASC, state ASC | Find open restaurants by state |

GeoPoint `location` field enables proximity queries via `geoflutterfire_plus` in Flutter.

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

## Normalization Rules

### Null Filtering (NEW — fix from v4.13 data quality findings)
- Restaurants with null name: EXCLUDE from normalized output, log to `phase-4-null-records.jsonl`
- Restaurants with null/Unknown state: attempt to infer from city name or video title, else log and include with state="UNKNOWN"
- Do NOT merge null-name restaurants together — they are distinct failures, not duplicates

### Ingredient Normalization
- Lowercase: "Brisket" → "brisket"
- Singular: "tomatoes" → "tomato"
- Strip brand names: "Frank's Red Hot" → "hot sauce"
- Standardize: "bbq sauce" = "barbecue sauce" → "bbq sauce"

### State Normalization
- Full name → abbreviation: "California" → "CA", "New York" → "NY"
- Null/empty → "UNKNOWN" (do not leave as None)

### Dedup Rules
- Fuzzy match: Levenshtein distance < 3 for names in the same city
- "Joe's BBQ" and "Joes BBQ" in Austin = same restaurant
- "Joe's BBQ" in Austin and "Joe's BBQ" in Dallas = different
- NULL names are NEVER merged — each is a distinct extraction failure
- When merging: keep the most complete record, merge dishes from all videos
- Log all merges to `data/logs/phase-4-dedup-report.jsonl`
- Flag ambiguous merges to `data/logs/phase-4-review-needed.jsonl`

## Hardware & Constraints

```
NZXT MS-7E06 Desktop
CPU:  Intel Core i9-13900K (24-core, 5.8 GHz boost)
RAM:  64 GB DDR4
GPU:  NVIDIA GeForce RTX 2080 SUPER (8 GB VRAM)
OS:   CachyOS x86_64 / KDE Plasma 6.6.2 / Wayland
Shell: Fish 4.5.0
IDE:  Antigravity (VS Code fork)
Storage: 1 TB NVMe — 755 GB free (12% used)
```

**8GB VRAM constraint:** Local LLM inference is limited to models ≤6GB quantized. Extraction uses Gemini Flash API (cloud). This decision is permanent unless hardware is upgraded.

**Storage estimate for full run:** ~13 GB total (12 GB audio + 400 MB transcripts + 25 MB extracted + 50 MB normalized). No storage concerns.

## Scripts Inventory

| Script | Purpose | Status |
|--------|---------|--------|
| `scripts/pre_flight.py` | Environment + secret validation | ✅ Active |
| `scripts/phase1_acquire.py` | yt-dlp batch downloader | ✅ Active |
| `scripts/phase2_transcribe.py` | faster-whisper CUDA transcription | ✅ Active |
| `scripts/phase3_extract_gemini.py` | Gemini Flash API extraction | ✅ Active |
| `scripts/phase4_normalize.py` | Dedup + normalization | ✅ Active (needs null-name fix) |
| `scripts/select_batch.py` | Batch selection (generalized) | ✅ Active |
| `scripts/validate_extraction.py` | Extraction quality metrics | ✅ Active |
| `scripts/heal_batch.py` | Swap failed videos for alternatives | ✅ Active |
| `scripts/group_b_runner.sh` | Unattended production runner | 🆕 v5.14 |
| `scripts/checkpoint_report.py` | Periodic progress reporting | 🆕 v5.14 |

## Known Gotchas

1. **CUDA path:** `LD_LIBRARY_PATH=/usr/local/lib/ollama/cuda_v12:$LD_LIBRARY_PATH` at shell level.
2. **fish shell:** No heredocs. Use `printf` or `nano`.
3. **yt-dlp flags:** Always `--remote-components ejs:github --cookies-from-browser chrome`.
4. **GPU contention:** Stop Ollama before transcription. Kill orphaned Python/CUDA processes.
5. **Working directory:** Launch Gemini from `pipeline/` not project root.
6. **Marathon timeouts:** ≥600s for videos >60 min.
7. **Gemini model:** `gemini-2.5-flash` (not 2.0).
8. **3 consecutive identical errors:** STOP batch, fix root cause, restart.
9. **README update:** MUST include IAO methodology section + all standard sections.
10. **Secret scan:** Run before any commit. API keys in git history = automatic revocation.
11. **No permission prompts:** Agent NEVER asks "should I proceed?"
12. **No git commands:** Agent NEVER runs git. Exception: read-only git in pre-flight secret scan.
13. **Null-name restaurants:** NEVER merge. Each is a distinct extraction failure.

## Current State (After v4.13)

- **Videos processed:** 120 of 805
- **Unique restaurants:** 608
- **Unique dishes:** 1015
- **Dedup merges:** 162
- **States covered:** 57 (includes 32 "None" + 30 "Unknown" — data quality issue)
- **Extraction quality:** 98% guy_intro, 98% guy_response, 100% ingredients
- **Owner_chef null:** 11.7% (below 15% target)
- **Remaining for Group B:** 685 videos
- **Estimated Group B runtime:** ~70 hours (2.9 days)
- **Data quality issues to fix:** null-name merging (14 records), null/unknown states (62 records)
- **Git history issue:** 1 leaked API key needs `git filter-repo` remediation

## GEMINI.md Template

```markdown
# TripleDB Pipeline — Agent Instructions

## Current Iteration: {P}.{I}

Read these two documents in order, then execute the plan:

1. ../docs/ddd-design-v{P}.{I}.md — Architecture, methodology, locked decisions
2. ../docs/ddd-plan-v{P}.{I}.md — Pre-flight checklist and execution steps

Follow the autonomy rules defined in the plan. Begin with Step 0.

## Rules That Never Change
- NEVER run git, flutter, or firebase commands
  (Exception: read-only git in pre-flight secret scan only)
- NEVER ask permission between steps — auto-proceed on EVERY step
- NEVER ask "should I continue?" or "would you like me to proceed?" — YES, ALWAYS
- If you find yourself typing a question mark, STOP. Re-read the plan. Execute.
- Self-heal errors: diagnose → fix → re-run (max 3 attempts, then skip)
- 3 consecutive identical errors = STOP, fix root cause, restart
- README.md update is the FINAL step — comprehensive, including IAO methodology
- All scripts run from this directory (pipeline/) as working directory
- Transcription: LD_LIBRARY_PATH=/usr/local/lib/ollama/cuda_v12:$LD_LIBRARY_PATH
- Extraction: Gemini 2.5 Flash API ($GEMINI_API_KEY), NOT local Ollama
```
