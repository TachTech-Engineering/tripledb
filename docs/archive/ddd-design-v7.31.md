# TripleDB — Design v7.31

---

# Part 1: IAO — Iterative Agentic Orchestration

## What IAO Is

A development methodology where LLM agents execute pipeline phases autonomously while humans review versioned artifacts between iterations. Each iteration produces a plan (input) and a report (output). The report informs the next plan. The methodology itself evolves alongside the project.

IAO emerged organically through 30 iterations of the TripleDB project. What started as "give the agent a prompt and hope" evolved into a rigorous, repeatable framework for building data pipelines with agentic assistance. The principles below are battle-tested — each one exists because its absence caused a measurable failure.

## The Eight Pillars of IAO

### Pillar 1: Plan-Report Loop
Every iteration begins with two input artifacts (design doc + plan doc) and produces two output artifacts (build log + report). The design doc is the living architecture — it accumulates decisions and learnings across iterations. The plan doc is disposable — fresh each time, informed by the previous report. The build log is the raw transcript. The report is structured metrics + a recommendation. These four artifacts are the complete record of every iteration.

### Pillar 2: Zero-Intervention Target
Every question the agent asks the human during execution is a failure in the plan document. Measure plan quality by counting interventions. Zero is the target. Pre-answer every decision point in the plan.

### Pillar 3: Self-Healing Loops
When an error occurs: diagnose → fix → re-run. Max 3 attempts per error, then log and skip. If 3 consecutive items fail with the same error, STOP the batch, fix the root cause, restart.

### Pillar 4: Versioned Artifacts as Source of Truth
`GEMINI.md` is the version lock. Git commits mark iteration boundaries. The launch command is always: `cd pipeline && gemini` → "Read GEMINI.md and execute."

### Pillar 5: Artifacts Travel Forward, Not Backward
Only the current iteration's docs live in `docs/`. Previous iterations go to `docs/archive/`. The design doc accumulates. The plan doc is fresh each time.

### Pillar 6: Methodology Co-Evolution
The methodology itself evolves alongside the project. Each iteration refines not just the code but the development process.

### Pillar 7: Separation of Interactive and Unattended Execution
Interactive (Group A) uses an LLM orchestrator. Unattended (Group B) uses hardened bash scripts. The right tool for tuning is the wrong tool for a 14-hour unattended run.

### Pillar 8: Progressive Trust Through Graduated Batches
Start small. Each batch validates the pipeline AND the methodology. v7.30 proved enrichment on 50 restaurants. v7.31 runs the full 1,102.

## IAO Iteration History

| Iteration | Phase | Interventions | Key Learning |
|-----------|-------|---------------|--------------|
| v0.7 | Setup | N/A | Monorepo scaffolded. fish shell has no heredocs. |
| v1.8 | Discovery | 20+ | 8GB VRAM can't run Nemotron 42GB. |
| v1.9 | Discovery | 20+ | Local 9B models too slow for structured extraction. |
| v1.10 | Discovery | ~10 | Gemini 2.5 Flash API solved extraction. 186 restaurants. |
| v2.11 | Calibration | 20+ | Marathons need 300s timeout. CUDA path is shell-level. |
| v3.12 | Stress Test | **0** | Autonomous batch healing. 98 dedup merges. |
| v4.13 | Validation | **0** | 608 restaurants, 162 merges. Group B green-lit. |
| v5.14 | Production Setup | **0** | Runner infrastructure. Null-name filtering. |
| v5.15 | Production Run | **0** | 773 videos extracted. 14-hour unattended run. |
| v6.26 | Firestore Load | **0** | 1,102 restaurants loaded. App wired to Firestore. |
| v6.27 | Geolocation Fix | **0** | Broke Firestore with bypass — reverted in v6.28. |
| v6.28 | Geocoding | **0** | 916/1102 geocoded via Nominatim. Map working. |
| v8.17–v8.25 | Flutter App | **0** | Two-pass app build. Lighthouse A11y 92, SEO 100. |
| v6.29 | Polish | **0** | Trivia fix, map clustering, README refresh. |
| v7.30 | Enrichment Discovery | **0** | Google Places API pipeline built. 50-restaurant batch: 66.7% match rate. |

## Artifact Spec

| Direction | File | Author | Purpose |
|-----------|------|--------|---------|
| Input | `ddd-design-v{P}.{I}.md` | Claude | Living architecture, locked decisions, IAO methodology |
| Input | `ddd-plan-v{P}.{I}.md` | Claude | Pre-flight checklist, execution steps, success criteria, launch instructions |
| Output | `ddd-build-v{P}.{I}.md` | Gemini | Full session transcript — all commands, outputs, errors, fixes |
| Output | `ddd-report-v{P}.{I}.md` | Gemini | Metrics, validation results, issues, Gemini's recommendation |
| Output | `README.md` (updated) | Gemini | Status table, architecture, metrics, IAO methodology, changelog, footer |

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
1. Git READ commands allowed: git pull, git log, git status, git diff, git show
   Git WRITE commands forbidden: git add, git commit, git push, git checkout, git branch
   firebase deploy forbidden — Kyle deploys manually.
2. flutter build web and flutter run ARE ALLOWED for testing.
3. NEVER ask permission — auto-proceed on EVERY step.
   The plan document IS the permission. Execute it.
4. Self-heal errors: diagnose → fix → re-run (max 3 attempts, then skip).
5. 3 consecutive identical errors = STOP, fix root cause, restart.
6. If a decision point arises not covered by the plan or design doc,
   make the best decision, LOG the reasoning in the build doc, continue.
7. MCP: Context7 ALLOWED for Python/Flutter/Dart docs. No other MCP servers.
8. MUST produce ddd-build and ddd-report artifacts before ending every session.
9. README update is comprehensive — all sections specified in the plan.
10. Working directory for pipeline scripts: pipeline/
    Working directory for README and docs: project root (~/dev/projects/tripledb/)
    Navigate as needed — do NOT assume all work is in one directory.
```

## README Update Specification

Every iteration must update ALL of the following in README.md (at project root):

1. **Project Status table** — current phase row to ✅ Complete with iteration number
2. **Architecture diagram** — if any pipeline component changed
3. **IAO Methodology section** — add/update the Eight Pillars and iteration history
4. **Changelog section** — new entry in established format
5. **Current metrics** — restaurant count, video count, dish count, state count, enrichment stats
6. **Footer** — `*Last updated: Phase {P}.{I} — {Phase Name}*`
7. **Stale references** — fix anything that references deprecated tools/approaches

## ADR Registry

| ADR | Project | Status | Iterations |
|-----|---------|--------|------------|
| ADR-001 | TripleDB | Active | v0.7 → v7.31 (current) |

---

# Part 2: ADR-001 — TripleDB

## Mandate

Process 805 YouTube DDD videos into a structured, searchable restaurant database. Deliver a Flutter Web app at tripledb.net where users can find diners near them, search by any dimension, and watch the exact moment Guy Fieri walks in. Phase 7 extends the dataset with real-world enrichment: ratings, open/closed status, website URLs, validated addresses, and coordinate backfill.

## Pipeline Architecture

```
YouTube Playlist (805 videos)
    ↓ yt-dlp (local)
MP3 Audio
    ↓ faster-whisper large-v3 (local CUDA)
Timestamped Transcripts
    ↓ Gemini 2.5 Flash API (cloud)
Extracted Restaurant JSON
    ↓ Gemini 2.5 Flash API (cloud)
Normalized JSONL
    ↓ Nominatim (OpenStreetMap)
Geocoded Data (916/1102)
    ↓ Google Places API (New)
Enriched Data (ratings, open/closed, websites, addresses)
    ↓ Firebase Admin SDK
Cloud Firestore
    ↓ Flutter Web
tripledb.net
```

## Phase Status

| IAO Iteration | Phase | Focus | Status |
|---|---|---|---|
| v0.7–v4.13 | 0-4 | Pipeline iterative refinement (Group A) | ✅ Complete |
| v5.14–v5.15 | 5 | Production run (Group B) | ✅ Complete |
| v6.26–v6.29 | 6 | Firestore load, geocoding, polish | ✅ Complete |
| v8.17–v8.25 | 8 | Flutter app (two passes) | ✅ Complete |
| v7.30 | 7 | Enrichment discovery (50 restaurants) | ✅ Complete |
| v7.31 | 7 | Enrichment production (all 1,102) | 🔧 Current |

## Enrichment Architecture (Phase 7)

### v7.30 Discovery Batch Results

| Metric | Result |
|--------|--------|
| Batch size | 50 restaurants |
| Match rate | 66.7% (30/45 valid attempts) |
| Auto-accepted (≥0.85) | 19 |
| Review needed (0.70–0.84) | 11 |
| No match (<0.70 or no result) | 15 |
| Skipped (null name) | 5 |
| Coordinate backfills | 4 of 15 null-coord restaurants |
| API cost | $0 (free tier) |
| OPERATIONAL | 29 (96.7%) |
| CLOSED_PERMANENTLY | 1 (3.3%) |
| Match scores 0.90–1.00 | 63.3% of matches |
| Rating 4.0+ | 90% of enriched restaurants |

### Self-Healing Fixes Applied in v7.30

These are already in the scripts — DO NOT re-implement:

1. **Unmatchable name filtering:** `phase7_enrich.py` now rejects names like "Unknown Restaurant (Big Pork Chop)" before attempting API lookup.
2. **City fallback:** When city is "None" or "Unknown", the script falls back to name-only fuzzy matching instead of failing the city check.
3. **Places API (New) enablement:** Confirmed enabled and distinct from legacy Places API on GCP project `tripledb-e0f77`.

### v7.31 Production Run Expectations

Based on the 66.7% discovery match rate extrapolated to 1,102 restaurants:

| Metric | Expected | Range |
|--------|----------|-------|
| Valid attempts (excluding null names) | ~1,050 | 1,020–1,080 |
| Enriched (auto + review) | ~700 | 650–750 |
| No match | ~350 | 300–400 |
| Coordinate backfills | ~50 | 35–70 |
| Permanently closed | ~35 | 20–50 |
| API calls (search + details) | ~2,100 | 1,800–2,400 |
| API cost | $0 | $0 (free tier, 10k/month cap) |
| Runtime | ~10–15 min | (0.15s delay × 2 calls × 1,050) |

### Enrichment Data Flow

```
data/normalized/restaurants.jsonl (1,102 records)
    ↓ Read restaurant name + city + state
    ↓ Google Places API Text Search (New)
        query: "{name} {city} {state} restaurant"
        fields: places.id, places.displayName, places.formattedAddress, places.location
    ↓ Match validation (fuzzy name ≥ 0.70, city check)
    ↓ Google Places API Place Details (New)
        fields: rating, userRatingCount, websiteUri,
                currentOpeningHours, businessStatus,
                googleMapsUri, photos
    ↓ Write enriched record
data/enriched/restaurants_enriched.jsonl
    ↓ phase7_load_enriched.py (Firestore merge update)
Cloud Firestore (updated documents)
```

### Match Validation Strategy (proven in v7.30)

1. **Name similarity:** Fuzzy match (SequenceMatcher ratio) between our name and Google's `displayName`. Threshold: ≥ 0.70.
2. **City match:** Google's `formattedAddress` contains our `city` (case-insensitive). Falls back to name-only if our city is null/unknown.
3. **Auto-accept:** score ≥ 0.85 AND city match → enrich automatically.
4. **Review bucket:** score 0.70–0.84 OR city mismatch → enrich but log to review file.
5. **Reject:** score < 0.70 → skip, log to no-match file.

### Enrichment Fields on Restaurant Schema

```json
{
  "google_place_id": "ChIJ...",
  "google_rating": 4.6,
  "google_rating_count": 1247,
  "google_maps_url": "https://maps.google.com/?cid=...",
  "website_url": "https://example.com",
  "formatted_address": "123 Main St, Memphis, TN 38103",
  "business_status": "OPERATIONAL",
  "still_open": true,
  "photo_references": ["AfLeUg...", "AfLeUg..."],
  "latitude": 35.1396,
  "longitude": -90.0541,
  "enriched_at": "<timestamp>",
  "enrichment_source": "google_places_api",
  "enrichment_match_score": 0.92
}
```

**Coordinate backfill rule:** If restaurant has null lat/lng AND Google Places returns location, use Google's coordinates. NEVER overwrite existing Nominatim coordinates.

**Business status mapping:**
- `OPERATIONAL` → `still_open: true`
- `CLOSED_TEMPORARILY` → `still_open: true`
- `CLOSED_PERMANENTLY` → `still_open: false`
- No result / unmatched → `still_open: null` (preserve existing)

## Data Model (Firestore — Current)

### Collection: `restaurants` (1,102 docs, 30 enriched after v7.30)

```json
{
  "restaurant_id": "r_<uuid4>",
  "name": "Mama's Soul Food",
  "city": "Memphis",
  "state": "TN",
  "address": null,
  "formatted_address": "123 Main St, Memphis, TN 38103",
  "latitude": 35.1396,
  "longitude": -90.0541,
  "cuisine_type": "Soul Food",
  "owner_chef": "Tyrone Washington",
  "still_open": true,
  "business_status": "OPERATIONAL",
  "google_place_id": "ChIJ...",
  "google_rating": 4.6,
  "google_rating_count": 1247,
  "google_maps_url": "https://maps.google.com/?cid=...",
  "website_url": "https://example.com",
  "photo_references": ["AfLeUg..."],
  "enriched_at": "<timestamp>",
  "enrichment_source": "google_places_api",
  "enrichment_match_score": 0.92,
  "visits": [ ... ],
  "dishes": [ ... ],
  "created_at": "<timestamp>",
  "updated_at": "<timestamp>"
}
```

### Collection: `videos` (773 docs, unchanged)

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

**Laptop:** auraX9cos — CachyOS, used for Flutter development.

**Phase 7.31 is network-bound, not compute-bound.** Google Places API calls are HTTP requests. No GPU needed. Runtime is dominated by the courtesy delay between requests (~10-15 min total).

## Scripts Inventory

| Script | Purpose | Status |
|--------|---------|--------|
| `scripts/pre_flight.py` | Environment + secret validation | ✅ Active |
| `scripts/phase1_acquire.py` | yt-dlp batch downloader | ✅ Active |
| `scripts/phase2_transcribe.py` | faster-whisper CUDA transcription | ✅ Active |
| `scripts/phase3_extract_gemini.py` | Gemini Flash API extraction | ✅ Active |
| `scripts/phase4_normalize.py` | Dedup + normalization | ✅ Active |
| `scripts/phase6_load_firestore.py` | JSONL → Firestore loader | ✅ Active |
| `scripts/geocode_restaurants.py` | Nominatim city→lat/lng | ✅ Active |
| `scripts/fix_unknown_states.py` | City name → state inference | ✅ Active |
| `scripts/group_b_runner.sh` | Unattended production runner | ✅ Active |
| `scripts/checkpoint_report.py` | Progress reporting | ✅ Active |
| `scripts/validate_extraction.py` | Extraction quality metrics | ✅ Active |
| `scripts/phase7_enrich.py` | Google Places API enrichment | ✅ Active (v7.30) |
| `scripts/phase7_load_enriched.py` | Enriched data → Firestore merge | ✅ Active (v7.30) |
| `scripts/validate_enrichment.py` | Enrichment quality metrics | ✅ Active (v7.30) |

## Repository Structure

```
~/dev/projects/tripledb/               ← PROJECT ROOT
├── docs/                              ← Current iteration artifacts
│   └── archive/                       ← Previous iteration docs
├── pipeline/                          ← Python data pipeline
│   ├── scripts/                       ← All pipeline scripts
│   ├── config/                        ← playlist_urls.txt, batch files
│   ├── data/                          ← All gitignored data
│   │   ├── audio/                     ← 778 mp3 files
│   │   ├── transcripts/               ← 774 JSON files
│   │   ├── extracted/                 ← 773 JSON files
│   │   ├── normalized/                ← restaurants.jsonl, videos.jsonl
│   │   ├── enriched/                  ← restaurants_enriched.jsonl, places_cache.json
│   │   └── logs/                      ← Enrichment logs
│   └── GEMINI.md                      ← Version lock (pipeline context)
├── app/                               ← Flutter Web app
│   ├── lib/                           ← Dart source
│   ├── docs/                          ← App iteration artifacts
│   └── GEMINI.md                      ← Version lock (app context)
├── GEMINI.md                          ← Root agent router
├── .gitignore
└── README.md                          ← Must be updated every iteration
```

## Known Gotchas

1. **CUDA path:** `LD_LIBRARY_PATH=/usr/local/lib/ollama/cuda_v12:$LD_LIBRARY_PATH` at shell level.
2. **fish shell:** No heredocs. Use `printf` or `nano`.
3. **yt-dlp flags:** Always `--remote-components ejs:github --cookies-from-browser chrome`.
4. **GPU contention:** Stop Ollama before transcription.
5. **Working directory:** Pipeline scripts from `pipeline/`. README at project root. Navigate as needed.
6. **Gemini model:** `gemini-2.5-flash` (not 2.0).
7. **3 consecutive identical errors:** STOP batch, fix root cause, restart.
8. **README update:** At PROJECT ROOT (`~/dev/projects/tripledb/README.md`), NOT `pipeline/README.md`. Must include IAO methodology + all standard sections.
9. **Secret scan:** Run before any commit.
10. **No permission prompts:** Agent NEVER asks "should I proceed?"
11. **No git write commands:** Agent NEVER runs git add/commit/push/checkout/branch.
12. **Google Places API key:** `$GOOGLE_PLACES_API_KEY` — NEVER hardcode, NEVER commit.
13. **Cloudflare WARP TLS:** Disconnect WARP if Python `requests` fails with TLS errors.
14. **Places API rate limit:** 100 req/s. 0.15s courtesy delay already in script.
15. **Match validation:** NEVER auto-enrich below 0.70 score.
16. **Resume support:** `phase7_enrich.py` skips restaurants already in `restaurants_enriched.jsonl`. The 30 records from v7.30 will be auto-skipped.
17. **Build log is MANDATORY:** `ddd-build-v{P}.{I}.md` must be a full transcript of every command, output, error, and fix. It is NOT optional.

## Current State (After v7.30)

### Pipeline Data
- **Videos processed:** 773 of 805
- **Unique restaurants:** 1,102
- **Unique dishes:** 2,286
- **Total visits:** 2,336
- **Dedup merges:** 432
- **States (valid):** 62 (excluding 33 UNKNOWN)
- **Geocoded:** 916/1102 (83.1%)
- **Enriched:** 30/1102 (2.7%) — from v7.30 discovery batch
- **Cached place lookups:** 30 (in `data/enriched/places_cache.json`)

### App (tripledb.net)
- Live with full Firestore data (30 restaurants have enrichment fields)
- 916 map pins with clustering
- Search, trivia, explore tabs all functional
- Dark mode, YouTube deep links, design tokens applied

### Firestore
- Project: tripledb-e0f77
- Collections: `restaurants` (1,102 docs, 30 enriched), `videos` (773 docs)
- 916 restaurants have lat/lng, 186 have null coordinates

### Known Data Gaps (v7.31 targets)
- 1,072 restaurants without enrichment (30 done in v7.30)
- ~182 restaurants with null coordinates (4 backfilled in v7.30 from original 186)
- 0 restaurants with open/closed status (except 30 from v7.30)
- README stale — v7.30 didn't complete the README update (noted in report §12)

## GEMINI.md Template

```markdown
# TripleDB Pipeline — Agent Instructions

## Current Iteration: 7.31

Read these two documents in order, then execute the plan:

1. ../docs/ddd-design-v7.31.md — Architecture, methodology, locked decisions
2. ../docs/ddd-plan-v7.31.md — Pre-flight checklist and execution steps

Follow the autonomy rules defined in the plan. Begin with Step 0.

## Rules That Never Change
- Git READ commands allowed (pull, log, status, diff, show)
- Git WRITE commands forbidden (add, commit, push, checkout, branch)
- firebase deploy forbidden — Kyle deploys manually
- NEVER ask permission between steps — auto-proceed on EVERY step
- NEVER ask "should I continue?" or "would you like me to proceed?" — YES, ALWAYS
- If you find yourself typing a question mark, STOP. Re-read the plan. Execute.
- Self-heal errors: diagnose → fix → re-run (max 3 attempts, then skip)
- 3 consecutive identical errors = STOP, fix root cause, restart
- README.md is at PROJECT ROOT (~/dev/projects/tripledb/README.md), NOT pipeline/
- README update is the FINAL step — comprehensive, including IAO methodology
- Pipeline scripts run from pipeline/ directory
- Google Places API key: $GOOGLE_PLACES_API_KEY (never hardcode)
- ddd-build artifact is MANDATORY — full session transcript
```
