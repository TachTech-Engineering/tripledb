# TripleDB — Design v7.30

---

# Part 1: IAO — Iterative Agentic Orchestration

## What IAO Is

A development methodology where LLM agents execute pipeline phases autonomously while humans review versioned artifacts between iterations. Each iteration produces a plan (input) and a report (output). The report informs the next plan. The methodology itself evolves alongside the project.

IAO emerged organically through 29 iterations of the TripleDB project. What started as "give the agent a prompt and hope" evolved into a rigorous, repeatable framework for building data pipelines with agentic assistance. The principles below are battle-tested — each one exists because its absence caused a measurable failure.

## The Eight Pillars of IAO

### Pillar 1: Plan-Report Loop
Every iteration begins with two input artifacts (design doc + plan doc) and produces two output artifacts (build log + report). The design doc is the living architecture — it accumulates decisions and learnings across iterations. The plan doc is disposable — fresh each time, informed by the previous report. The build log is the raw transcript. The report is structured metrics + a recommendation. These four artifacts are the complete record of every iteration.

**Why it matters:** Without structured artifacts, knowledge lives only in chat history and human memory. Both are lossy. The artifact trail means any new agent (or human) can reconstruct the full project history from docs alone.

### Pillar 2: Zero-Intervention Target
Every question the agent asks the human during execution is a failure in the plan document. Measure plan quality by counting interventions. Zero is the target. Pre-answer every decision point in the plan. If the agent encounters an uncovered situation, the plan should instruct it to make the best decision, log its reasoning, and continue — not to ask.

**Why it matters:** Human intervention breaks the feedback loop. It introduces unlogged context, creates dependencies on availability, and prevents the pipeline from running unattended. v2.11 had 20+ interventions. v3.12 onward achieved zero. The plan docs got better because every intervention was analyzed and pre-answered.

### Pillar 3: Self-Healing Loops
When an error occurs: diagnose → fix → re-run. Max 3 attempts per error, then log and skip. If 3 consecutive items fail with the same error, STOP the batch, fix the root cause, restart. Never burn through hundreds of items with a known systemic failure.

**Why it matters:** Errors are inevitable in data pipelines. The question is whether the pipeline collapses at the first error or handles it gracefully. Self-healing with bounded retries and systemic failure detection gives you resilience without infinite loops.

### Pillar 4: Versioned Artifacts as Source of Truth
`GEMINI.md` is the version lock — it points to the current design and plan docs. Updating it is the first step of every iteration. The launch command is always the same: `cd pipeline && gemini` → "Read GEMINI.md and execute." Git commits mark iteration boundaries: `"KT starting {P}.{I}"` (setup) and `"KT completed {P}.{I} and README updated"` (close). The git log IS the iteration history.

**Why it matters:** Without a version lock, agents read stale instructions. Without commit boundaries, you can't tell where one iteration ends and the next begins.

### Pillar 5: Artifacts Travel Forward, Not Backward
Only the current iteration's docs live in `docs/`. Previous iterations go to `docs/archive/`. The design doc accumulates learnings (additive). The plan doc is fresh each time (disposable). This prevents the agent from reading outdated instructions while preserving the full history.

**Why it matters:** Agents are literal. If they can see the Phase 2 plan alongside the Phase 7 plan, they may follow the wrong one. Archiving eliminates ambiguity.

### Pillar 6: Methodology Co-Evolution
The methodology itself is an artifact that evolves alongside the project. Each iteration refines not just the pipeline code but the development process. Error taxonomies, autonomy rules, pre-flight checks, artifact specs — all born from specific failures and refined through subsequent iterations.

**Why it matters:** Most methodologies are defined upfront and followed. IAO is defined by what works and discards what doesn't.

### Pillar 7: Separation of Interactive and Unattended Execution
Interactive execution (Group A) uses an LLM orchestrator for iterative refinement. Unattended execution (Group B) uses hardened bash scripts with checkpoint reporting. An LLM orchestrator adds fragility without adding value when prompts are locked and scripts are proven.

**Why it matters:** A 70-hour production run doesn't benefit from an agent that might crash at 3 AM. The right tool for Group A (agent) is the wrong tool for Group B (bash + tmux).

### Pillar 8: Progressive Trust Through Graduated Batches
Start small. Each batch is bigger and harder. Each batch validates the pipeline AND the methodology. By the time you run the full production batch, every failure mode has been seen, logged, and handled.

**Why it matters:** Running 1,102 restaurants through enrichment on day one would bury us in undiagnosed API failures, match misses, and data quality issues. A 50-restaurant discovery batch earns the confidence for the full run.

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
7. MCP: Context7 ALLOWED for Flutter/Dart docs. No other MCP servers.
8. MUST produce ddd-build and ddd-report artifacts before ending every session.
9. README update is comprehensive — all sections specified in the plan.
```

## README Update Specification

Every iteration must update ALL of the following in README.md:

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
| ADR-001 | TripleDB | Active | v0.7 → v7.30 (current) |

---

# Part 2: ADR-001 — TripleDB

## Mandate

Process 805 YouTube DDD videos into a structured, searchable restaurant database. Deliver a Flutter Web app at tripledb.net where users can find diners near them, search by any dimension (dish, cuisine, city, chef, ingredient), and watch the exact moment Guy Fieri walks in. **Phase 7 extends the dataset with real-world enrichment: ratings, open/closed status, website URLs, validated addresses, and fill remaining null coordinates.**

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
    ↓ Nominatim (OpenStreetMap)             ← Phase 6.28
Geocoded Data (916/1102)
    ↓ Google Places API (New)               ← Phase 7.30 (NEW)
Enriched Data (ratings, open/closed, photos, addresses)
    ↓ Firebase Admin SDK
Cloud Firestore
    ↓ Flutter Web
tripledb.net
```

## Execution Groups

**Group A — Iterative Refinement (Phases 0-4)**

| Phase | Name | Videos | Status | Key Metric |
|-------|------|--------|--------|------------|
| 0 | Setup | 0 | ✅ v0.7 | Monorepo scaffolded, 805 URLs |
| 1 | Discovery | 30 | ✅ v1.10 | 186 restaurants, 290 dishes |
| 2 | Calibration | 30 | ✅ v2.11 | 422 restaurants, 624 dishes (cumulative) |
| 3 | Stress Test | 30 | ✅ v3.12 | Zero interventions. 98 dedup merges. |
| 4 | Validation | 30 | ✅ v4.13 | 608 restaurants. Prompts locked. Group B green-lit. |

**Group B — Production Run (Phase 5)**

| Phase | Name | Videos | Status |
|-------|------|--------|--------|
| 5 | Production Setup + Run | All | ✅ v5.14–v5.15 | 773 extracted. 14-hour unattended run. |

**Group C — App + Enrichment (Phases 6-8)**

| Phase | Name | Status | Key Metric |
|-------|------|--------|------------|
| 6 | Firestore Load + Geocoding + Polish | ✅ v6.26–v6.29 | 1,102 restaurants loaded, 916 geocoded, map clustered |
| 8 | Flutter App | ✅ v8.17–v8.25 | tripledb.net live. Lighthouse A11y 92, SEO 100. |
| 7 | Enrichment (Discovery) | 🔧 v7.30 (current) | Google Places API: ratings, open/closed, photos |
| 7 | Enrichment (Production) | ⏳ v7.31 | Full run on all 1,102 restaurants |

## Enrichment Architecture (Phase 7 — NEW)

### Why Google Places API

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| Google Places API (New) | Single API for all enrichment fields. Reliable. Well-documented. Free tier covers our volume. | Requires GCP API key with Places API enabled. | ✅ **Selected** |
| Firecrawl | Can scrape any site. Already used in Phase 8. | WARP TLS blocking. Fragile against anti-scraping. Rate-limited. No structured data guarantee. | ❌ Rejected |
| Yelp Fusion API | Good ratings data. | 500 req/day limit on free tier. Missing open/closed. Requires separate API key. | ❌ Rejected |
| Manual enrichment | Perfect accuracy. | 1,102 restaurants. No. | ❌ Rejected |

### Enrichment Data Flow

```
data/normalized/restaurants.jsonl (1,102 records)
    ↓ Read restaurant name + city + state
    ↓ Google Places API Text Search (New)
        query: "{name} {city} {state} restaurant"
        fields: places.id, places.displayName, places.formattedAddress
    ↓ Match validation (fuzzy name match > 70% similarity)
    ↓ Google Places API Place Details (New)
        fields: rating, userRatingCount, websiteUri,
                currentOpeningHours, businessStatus,
                googleMapsUri, photos
    ↓ Write enriched record
data/enriched/restaurants_enriched.jsonl
    ↓ phase7_load_enriched.py (Firestore merge update)
Cloud Firestore (updated documents)
```

### Enrichment Fields Added to Restaurant Schema

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

**Coordinate backfill:** If a restaurant has null lat/lng from Nominatim (186 records), but Google Places returns geometry, use Google's coordinates. This fills gaps without re-running Nominatim.

**Business status mapping:**
- `OPERATIONAL` → `still_open: true`
- `CLOSED_TEMPORARILY` → `still_open: true` (with note)
- `CLOSED_PERMANENTLY` → `still_open: false`
- No result / unmatched → `still_open: null` (preserve existing)

### Cost Estimate

Under the March 2025 Google Maps Platform pricing:
- **Text Search (New) Essentials:** 10,000 free events/month. We need ~1,102. **Free.**
- **Place Details (New) Basic:** 10,000 free events/month. We need ~1,102. **Free.**
- **Place Photos:** 10,000 free events/month. We need ~1,102 (1 photo per restaurant). **Free.**
- **Total estimated cost: $0** (within free tier for a single month's run)
- **Worst case (if free tiers don't stack):** ~$35–55 one-time. Still near-zero.

### API Key Requirements

Kyle must enable the **Places API (New)** on the existing `tripledb-e0f77` GCP project (or a dedicated project) and generate a server-side API key. The key should be:
- Restricted to Places API (New) only
- Stored in `$GOOGLE_PLACES_API_KEY` environment variable
- NEVER committed to git (pre-flight secret scan enforced)

### Match Validation Strategy

Not every Text Search result will be the correct restaurant. Some DDD restaurants have closed and been replaced. Some have common names. The enrichment script must validate matches:

1. **Name similarity:** Fuzzy match (Levenshtein ratio) between our restaurant name and Google's `displayName`. Threshold: ≥ 0.70.
2. **City match:** Google's `formattedAddress` must contain our `city` string (case-insensitive).
3. **Auto-accept:** score ≥ 0.85 AND city match → enrich automatically.
4. **Review bucket:** score 0.70–0.84 OR city mismatch → log to `data/logs/phase7-review-needed.jsonl`.
5. **Reject:** score < 0.70 → skip, log to `data/logs/phase7-no-match.jsonl`.

This is the same graduated-confidence pattern used in Phase 4 dedup: auto-accept high confidence, flag medium, skip low.

## Data Model (Firestore — Updated for Phase 7)

### Collection: `restaurants`

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

### Collection: `videos` (unchanged)

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

**Phase 7 is network-bound, not compute-bound.** Google Places API calls are HTTP requests. No GPU, no CUDA, no VRAM constraints. The rate limiter is API quota, not hardware.

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
| `scripts/phase7_enrich.py` | Google Places API enrichment | 🆕 v7.30 |
| `scripts/phase7_load_enriched.py` | Enriched data → Firestore merge | 🆕 v7.30 |
| `scripts/validate_enrichment.py` | Enrichment quality metrics | 🆕 v7.30 |

## Known Gotchas

1. **CUDA path:** `LD_LIBRARY_PATH=/usr/local/lib/ollama/cuda_v12:$LD_LIBRARY_PATH` at shell level.
2. **fish shell:** No heredocs. Use `printf` or `nano`.
3. **yt-dlp flags:** Always `--remote-components ejs:github --cookies-from-browser chrome`.
4. **GPU contention:** Stop Ollama before transcription. Kill orphaned processes.
5. **Working directory:** Launch Gemini from `pipeline/` not project root.
6. **Gemini model:** `gemini-2.5-flash` (not 2.0).
7. **3 consecutive identical errors:** STOP batch, fix root cause, restart.
8. **README update:** MUST include IAO methodology section + all standard sections.
9. **Secret scan:** Run before any commit. API keys in git history = automatic revocation.
10. **No permission prompts:** Agent NEVER asks "should I proceed?"
11. **No git write commands:** Agent NEVER runs git add/commit/push/checkout/branch.
12. **Null-name restaurants:** NEVER merge. Each is a distinct extraction failure.
13. **Google Places API key:** `$GOOGLE_PLACES_API_KEY` — NEVER in code, NEVER committed.
14. **Cloudflare WARP TLS:** If Python `requests` fails with TLS errors, disconnect WARP temporarily. This was observed during Nominatim geocoding (v6.28).
15. **Places API rate limit:** 100 requests/second. Add 0.1s sleep between requests as a courtesy, but this is not a hard constraint.
16. **Match validation:** NEVER auto-enrich a restaurant with a match score below 0.70. Bad enrichment is worse than no enrichment.

## Current State (After v6.29)

### Pipeline Data
- **Videos processed:** 773 of 805
- **Unique restaurants:** 1,102
- **Unique dishes:** 2,286
- **Total visits:** 2,336
- **Dedup merges:** 432
- **States (valid):** 62 (excluding 33 UNKNOWN)
- **Geocoded:** 916/1102 (83.1%)
- **Enriched:** 0/1102 (0%) — Phase 7 begins enrichment

### App (tripledb.net)
- Live with full Firestore data
- 916 map pins with clustering (orange clusters, red individual pins)
- "Top 3 Near You" with geolocation
- Search across all fields
- Rotating trivia (correct state count: 62)
- Dark mode toggle
- 3-tab bottom nav: Map / List / Explore
- Design tokens: DDD Red (#DD3333), Orange (#DA7E12), Outfit + Inter fonts

### Firestore
- Project: tripledb-e0f77
- Collections: `restaurants` (1,102 docs), `videos` (773 docs)
- 916 restaurants have lat/lng, 186 have null coordinates

### Known Data Gaps (Phase 7 targets)
- 186 restaurants with null coordinates (UNKNOWN state or unresolvable by Nominatim)
- 0 restaurants with Google ratings
- 0 restaurants with open/closed status
- 0 restaurants with website URLs
- 0 restaurants with validated addresses
- 0 restaurants with photo references

## GEMINI.md Template

```markdown
# TripleDB Pipeline — Agent Instructions

## Current Iteration: 7.30

Read these two documents in order, then execute the plan:

1. ../docs/ddd-design-v7.30.md — Architecture, methodology, locked decisions
2. ../docs/ddd-plan-v7.30.md — Pre-flight checklist and execution steps

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
- README.md update is the FINAL step — comprehensive, including IAO methodology
- All scripts run from this directory (pipeline/) as working directory
- Google Places API key: $GOOGLE_PLACES_API_KEY (never hardcode)
```
