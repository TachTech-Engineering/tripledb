# TripleDB — Design v7.32

---

# Part 1: IAO — Iterative Agentic Orchestration

## What IAO Is

A development methodology where LLM agents execute pipeline phases autonomously while humans review versioned artifacts between iterations. Each iteration produces a plan (input) and a report (output). The report informs the next plan. The methodology itself evolves alongside the project.

## The Eight Pillars of IAO

### Pillar 1: Plan-Report Loop
Every iteration: design doc + plan doc in → build log + report out. The four artifacts are the complete record.

### Pillar 2: Zero-Intervention Target
Every question the agent asks during execution is a failure in the plan. Zero is the target.

### Pillar 3: Self-Healing Loops
Diagnose → fix → re-run. Max 3 attempts, then skip. 3 consecutive identical errors = STOP.

### Pillar 4: Versioned Artifacts as Source of Truth
GEMINI.md is the version lock. Git commits mark boundaries.

### Pillar 5: Artifacts Travel Forward, Not Backward
Current docs in `docs/`, previous in `docs/archive/`.

### Pillar 6: Methodology Co-Evolution
The methodology evolves alongside the project.

### Pillar 7: Separation of Interactive and Unattended Execution
Interactive (Group A) uses LLM orchestrator. Unattended (Group B) uses bash + tmux.

### Pillar 8: Progressive Trust Through Graduated Batches
Start small. Validate. Scale. v7.30 → v7.31 → v7.32 follows this pattern.

## IAO Iteration History

| Iteration | Phase | Interventions | Key Learning |
|-----------|-------|---------------|--------------|
| v0.7 | Setup | N/A | Monorepo scaffolded. fish shell has no heredocs. |
| v1.8–v1.9 | Discovery | 20+ | Local LLMs can't handle extraction on 8GB VRAM. |
| v1.10 | Discovery | ~10 | Gemini 2.5 Flash API solved extraction. 186 restaurants. |
| v2.11 | Calibration | 20+ | Marathons need 300s timeout. CUDA path is shell-level. |
| v3.12 | Stress Test | **0** | Autonomous batch healing. 98 dedup merges. |
| v4.13 | Validation | **0** | 608 restaurants, 162 merges. Group B green-lit. |
| v5.14–v5.15 | Production | **0** | 773 videos extracted. 14-hour unattended run. |
| v6.26–v6.29 | Firestore + Polish | **0** | 1,102 loaded, 916 geocoded, app polished. |
| v8.17–v8.25 | Flutter App | **0** | tripledb.net live. Lighthouse A11y 92, SEO 100. |
| v7.30 | Enrichment Discovery | **0** | Google Places pipeline. 50-restaurant batch: 66.7% match. |
| v7.31 | Enrichment Production | **1** | 625/1102 enriched at 55.9%. API key missing from env. |

## Artifact Spec

| Direction | File | Author | Purpose |
|-----------|------|--------|---------|
| Input | `ddd-design-v{P}.{I}.md` | Claude | Living architecture, locked decisions |
| Input | `ddd-plan-v{P}.{I}.md` | Claude | Execution steps, success criteria |
| Output | `ddd-build-v{P}.{I}.md` | Gemini | Full session transcript |
| Output | `ddd-report-v{P}.{I}.md` | Gemini | Metrics, recommendation |
| Output | `README.md` (updated) | Gemini | All standard sections |

## Agent Restrictions

```
1. Git READ commands allowed. Git WRITE commands and firebase deploy FORBIDDEN.
2. flutter build web and flutter run ARE ALLOWED for testing.
3. NEVER ask permission — auto-proceed on EVERY step.
4. Self-heal errors: diagnose → fix → re-run (max 3 attempts, then skip).
5. 3 consecutive identical errors = STOP, fix root cause, restart.
6. MCP: Context7 ALLOWED. No other MCP servers.
7. MUST produce ddd-build and ddd-report artifacts before ending.
8. Working directories:
   - Pipeline scripts: ~/dev/projects/tripledb/pipeline/
   - Flutter app: ~/dev/projects/tripledb/app/
   - README and docs: ~/dev/projects/tripledb/ (PROJECT ROOT)
9. Google Places API key: $GOOGLE_PLACES_API_KEY — NEVER hardcode, NEVER commit.
   If the env var is not set, print "STOP: export GOOGLE_PLACES_API_KEY=<your key>"
   and halt execution. Do NOT ask the human for the key interactively.
10. Build log is MANDATORY — full transcript of every command and output.
```

## ADR Registry

| ADR | Project | Status | Iterations |
|-----|---------|--------|------------|
| ADR-001 | TripleDB | Active | v0.7 → v7.32 (current) |

---

# Part 2: ADR-001 — TripleDB

## Mandate

Process 805 YouTube DDD videos into a structured, searchable restaurant database at tripledb.net. Phase 7 extends the dataset with real-world enrichment via Google Places API.

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
Geocoded Data (916 + 8 backfilled = 924 with coords)
    ↓ Google Places API (New)               ← v7.30–v7.31
    ↓ Google Places API (New) — Refined     ← v7.32 (NEW)
Enriched Data
    ↓ Firebase Admin SDK
Cloud Firestore
    ↓ Flutter Web
tripledb.net
```

## Phase Status

| IAO Iteration | Phase | Focus | Status |
|---|---|---|---|
| v0.7–v4.13 | 0-4 | Pipeline refinement (Group A) | ✅ Complete |
| v5.14–v5.15 | 5 | Production run (Group B) | ✅ Complete |
| v6.26–v6.29 | 6 | Firestore, geocoding, polish | ✅ Complete |
| v8.17–v8.25 | 8 | Flutter app | ✅ Complete |
| v7.30 | 7 | Enrichment discovery (50) | ✅ Complete |
| v7.31 | 7 | Enrichment production (1,102) | ✅ Complete |
| v7.32 | 7 | Enrichment refinement (no-match + review) | 🔧 Current |

## Enrichment State After v7.31

### Summary

| Category | Count | % of 1,102 |
|----------|-------|------------|
| Enriched — auto-accepted (≥0.85) | 342 | 31.0% |
| Enriched — review bucket (0.70–0.84) | 253 | 23.0% |
| No match (<0.70 or no result) | 462 | 41.9% |
| Skipped (null/invalid names) | 15 | 1.4% |
| Not attempted (errors/other) | 30 | 2.7% |
| **Total** | **1,102** | **100%** |

### v7.32 Targets

**Part A: Refine No-Match (462 restaurants)**

The v7.31 search query was `"{name} {city} {state} restaurant"`. Many no-matches are caused by:

1. **Name variants:** The show transcript says "Big Jim's BBQ" but Google has "Big Jim's Barbecue & Grill."
2. **Closed + replaced:** Restaurant closed since filming. Google returns the new tenant at that address.
3. **Missing city data:** Restaurants with city="None" or "Unknown" produce weak queries.
4. **Very small/rural:** Some DDD restaurants are tiny rural spots that Google doesn't index.
5. **Chain confusion:** Common names like "Joe's Diner" return the wrong location.

**Refinement strategy — try alternative query patterns in priority order:**

| Pass | Query Pattern | Rationale |
|------|---------------|-----------|
| 1 | `"{name}" "{city}" {state}` | Exact name match (quotes) — catches variants Google auto-corrects |
| 2 | `"{owner_chef}" restaurant {city} {state}` | Chef name is often more unique than restaurant name |
| 3 | `"{name}" {cuisine_type} {state}` | Cuisine + state for restaurants with null city |
| 4 | `"{name}" Diners Drive-Ins Dives` | Google often indexes DDD appearances as keywords |

For each no-match restaurant, try passes 1–4 in order. Stop on the first match that scores ≥ 0.70. If all 4 fail, the restaurant is genuinely unresolvable via API and gets logged as final-no-match.

**Expected yield:** 15–25% of the 462 no-matches (70–115 restaurants) should resolve with refined queries, based on the distribution of failure causes.

**Part B: Verify Review Bucket (253 restaurants)**

These are already enriched (data is in Firestore) but with medium-confidence match scores (0.70–0.84). The risk is false positives — wrong restaurant matched to the right record.

**Verification strategy — use Gemini 2.5 Flash API to batch-validate:**

For each review-bucket record, send a prompt to Gemini Flash:
```
Given:
- Our record: {name}, {city}, {state}, cuisine: {cuisine_type}, owner: {owner_chef}
- Google result: {google_name}, {formatted_address}, rating: {google_rating}

Are these the same restaurant? Answer ONLY: YES, NO, or UNCERTAIN.
Reasoning (one sentence):
```

This leverages the fact that Gemini Flash is free tier and can reason about contextual matches that fuzzy string matching cannot (e.g., "Katalina's" vs "Catalina's 2" — different restaurant or spelling variant?).

**Classification:**
- `YES` → keep enrichment, upgrade match confidence to "verified"
- `NO` → remove enrichment from Firestore, move to no-match log
- `UNCERTAIN` → keep enrichment, flag for Kyle's manual review (expected: < 20 records)

**Expected yield:** ~200 of 253 verified as correct, ~30 removed as false positives, ~23 flagged for manual review.

### Enrichment Fields (unchanged from v7.31)

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
  "photo_references": ["AfLeUg..."],
  "latitude": 35.1396,
  "longitude": -90.0541,
  "enriched_at": "<timestamp>",
  "enrichment_source": "google_places_api",
  "enrichment_match_score": 0.92
}
```

New field for v7.32:
```json
{
  "enrichment_verified": true,          // Set on review-bucket records after LLM verification
  "enrichment_verify_method": "gemini_flash",  // How it was verified
  "enrichment_query_pass": 2            // Which refined query pass succeeded (for newly matched)
}
```

### Match Validation Rules (unchanged)

- ≥ 0.85 + city match → auto-accept
- 0.70–0.84 or city mismatch → review bucket
- < 0.70 → reject

### Cost Estimate for v7.32

| API | Calls | Free Tier | Cost |
|-----|-------|-----------|------|
| Places Text Search | ~1,848 (462 × 4 passes max) | 10,000/month | $0 |
| Places Details | ~115 (estimated new matches) | 10,000/month | $0 |
| Gemini Flash API | ~253 (review verification) | Free tier | $0 |
| **Total** | | | **$0** |

Worst case: if every no-match restaurant exhausts all 4 query passes = 1,848 search calls. Still within free tier.

## Scripts Inventory

| Script | Purpose | Status |
|--------|---------|--------|
| `scripts/phase7_enrich.py` | Google Places API enrichment | ✅ Active |
| `scripts/phase7_load_enriched.py` | Enriched data → Firestore merge | ✅ Active |
| `scripts/validate_enrichment.py` | Enrichment quality metrics | ✅ Active |
| `scripts/phase7_refine.py` | Refined search for no-match restaurants | 🆕 v7.32 |
| `scripts/phase7_verify_reviews.py` | LLM verification of review bucket | 🆕 v7.32 |

## Repository Structure

```
~/dev/projects/tripledb/               ← PROJECT ROOT
├── docs/                              ← Current iteration artifacts
│   └── archive/                       ← Previous iteration docs
├── pipeline/
│   ├── scripts/
│   ├── config/
│   ├── data/
│   │   ├── normalized/                ← restaurants.jsonl (1,102)
│   │   ├── enriched/                  ← restaurants_enriched.jsonl (625), places_cache.json
│   │   └── logs/
│   │       ├── phase7-no-match.jsonl          ← 462 records from v7.31
│   │       ├── phase7-review-needed.jsonl     ← 253 records from v7.31
│   │       ├── phase7-refined-matches.jsonl   ← NEW: newly matched from refined search
│   │       ├── phase7-final-no-match.jsonl    ← NEW: truly unresolvable
│   │       ├── phase7-verified.jsonl          ← NEW: review bucket verification results
│   │       └── phase7-false-positives.jsonl   ← NEW: records to remove from Firestore
│   └── GEMINI.md
├── app/
├── GEMINI.md
├── .gitignore
└── README.md
```

## Known Gotchas

1. **Working directories:** Pipeline scripts from `pipeline/`. README at project root. Navigate as needed.
2. **fish shell:** No heredocs. Use `printf` or `nano`.
3. **Google Places API key:** `$GOOGLE_PLACES_API_KEY` — if not set, print error and HALT. Do not ask interactively.
4. **Gemini API key:** `$GEMINI_API_KEY` — needed for review verification. Same rule: halt if not set.
5. **Cloudflare WARP TLS:** Disconnect WARP if Python `requests` fails with TLS errors.
6. **Resume support:** Both new scripts must support resume (skip already-processed records).
7. **Places API rate limit:** 0.15s courtesy delay between requests.
8. **Gemini Flash rate limit:** Free tier may have requests/minute limits. Add 1s delay between verification calls.
9. **Build log is MANDATORY.** Full transcript. Every command, every output.
10. **README at PROJECT ROOT.** Not `pipeline/README.md`.

## Current State (After v7.31)

### Pipeline Data
- **Videos processed:** 773 of 805
- **Unique restaurants:** 1,102
- **Unique dishes:** 2,286
- **States (valid):** 62 (excluding 33 UNKNOWN)
- **Geocoded:** 924/1102 (83.8%) — 916 Nominatim + 8 Google backfill
- **Enriched:** 625/1102 (56.7%)
  - Auto-accepted: 342
  - Review bucket: 253
  - Avg Google rating: 4.4
  - Permanently closed: 32
  - Temporarily closed: 11
- **Not enriched:** 477
  - No match: 462
  - Skipped (null): 15

### App (tripledb.net)
- Live with enrichment UI (ratings, open/closed badges, website/Maps links)
- 924 map pins with clustering
- Trivia includes enrichment facts

### Firestore
- Project: tripledb-e0f77
- `restaurants`: 1,102 docs (625 with enrichment fields)
- `videos`: 773 docs

## GEMINI.md Template

```markdown
# TripleDB Pipeline — Agent Instructions

## Current Iteration: 7.32

IMPORTANT: Read documents in this EXACT order before executing:

1. ../docs/ddd-design-v7.32.md — Architecture, v7.31 results, refinement strategy
2. ../docs/ddd-plan-v7.32.md — Execution steps for refined search + review verification

Do NOT begin execution until both files have been read.

## Rules That Never Change
- Git READ commands allowed. Git WRITE commands and firebase deploy FORBIDDEN.
- flutter build web and flutter run ARE ALLOWED for testing.
- NEVER ask permission — auto-proceed on EVERY step.
- Context7 MCP allowed. No other MCP servers.
- MUST produce ddd-build-v7.32.md AND ddd-report-v7.32.md before ending.
- ddd-build must be a FULL session transcript — not a summary.
- README.md is at PROJECT ROOT (~/dev/projects/tripledb/README.md).
- Pipeline scripts run from ~/dev/projects/tripledb/pipeline/.
- $GOOGLE_PLACES_API_KEY and $GEMINI_API_KEY must be set. If not, print an
  error message and HALT. Do NOT ask the human for the key interactively.
```
