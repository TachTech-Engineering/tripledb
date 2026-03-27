# TripleDB

**Every restaurant from Diners, Drive-Ins and Dives — structured, searchable, and mapped.**

TripleDB processes 805 YouTube videos from Guy Fieri's "Diners, Drive-Ins and Dives" (DDD) into a structured Firestore database of restaurants, dishes, ingredients, and iconic Guy Fieri moments. The name is a triple play: **Triple D** (the show's nickname) + **DB** (database).

🌐 **[tripledb.net](https://tripledb.net)** · 📂 **32 iterations** · 🔧 **Status: Live + Enriched**

---

## What This Builds

A searchable database and Flutter Web app where you can:

- **Find a diner near you** — share your location or enter a zip code
- **Search by anything** — dish name, cuisine type, city, chef, ingredients ("ground beef" → hamburgers, meatloaf, etc.)
- **Watch the moment** — deep link to the exact YouTube timestamp where Guy walks into the restaurant
- **Query Guy's greatest hits** — how many times has he said "That's out of bounds!"?

---

## Methodology: Iterative Agentic Orchestration (IAO)

TripleDB is built using **Iterative Agentic Orchestration (IAO)** — a development
methodology where LLM agents execute pipeline phases autonomously while humans
review versioned artifacts between iterations. IAO emerged through 32 iterations
of this project and is now a repeatable framework for building data pipelines
with agentic assistance.

### The Eight Pillars

1. **Plan-Report Loop** — Every iteration starts with a design doc + plan doc
   and produces a build log + report. The four artifacts are the complete record.
   Any new agent or human can reconstruct the full project history from docs alone.

2. **Zero-Intervention Target** — Every question the agent asks during execution
   is a failure in the plan. Pre-answer every decision point. Measure plan quality
   by counting interventions.

3. **Self-Healing Loops** — Errors are inevitable. Diagnose → fix → re-run (max
   3 attempts). 3 consecutive identical errors = stop and fix root cause. Never
   burn through hundreds of items with a known systemic failure.

4. **Versioned Artifacts as Source of Truth** — GEMINI.md is the version lock.
   Git commits mark iteration boundaries. The launch command never changes:
   `gemini` → "Read GEMINI.md and execute."

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

| Iteration | Phase | Status | Key Learning |
|-----------|-------|--------|--------------|
| v0.7 | Setup | ✅ | Monorepo scaffolded. fish shell has no heredocs. |
| v1.10 | Discovery | ✅ | Gemini 2.5 Flash API solved extraction. |
| v4.13 | Validation | ✅ | 608 restaurants, 162 merges. Group B green-lit. |
| v5.15 | Production | ✅ | 773 videos extracted. 14-hour unattended run. |
| v6.26 | Firestore | ✅ | 1,102 restaurants loaded. App wired to Firestore. |
| v6.29 | Polish | ✅ | Trivia fix, map clustering, README refresh. |
| v7.30 | Enrichment Disc. | ✅ | Google Places API pipeline. 50-restaurant batch. |
| v7.31 | Enrichment Prod. | ✅ | Full run on 1,102 restaurants. 625 enriched. |
| v7.32 | Enrichment Ref. | ✅ | Refined search recovered 83 more. 126 false pos removed. |

---

## Architecture

```
YouTube Playlist (805 videos)
    ↓ yt-dlp (local)
MP3 Audio
    ↓ faster-whisper large-v3 (local CUDA)
Timestamped Transcripts
    ↓ Gemini 2.5 Flash API (cloud)
Extracted Restaurant JSON
    ↓ Gemini 2.5 Flash API (cloud)
Normalized + Deduplicated JSONL
    ↓ Nominatim (OpenStreetMap)
Geocoded Data
    ↓ Google Places API (New)
Enriched Data (ratings, open/closed, websites, addresses)
    ↓ Firebase Admin SDK
Cloud Firestore
    ↓ Flutter Web
tripledb.net
```

Most inference runs locally on an NVIDIA RTX 2080 SUPER. Extraction uses the Gemini Flash API (free tier) to leverage its massive context window. Gemini CLI orchestrates the pipeline and app development.

---

## Project Status

| Phase | Name | Status | Iteration |
|-------|------|--------|-----------|
| 0 | Setup & Scaffolding | ✅ Complete | v0.7 |
| 1 | Discovery (30 videos) | ✅ Complete | v1.10 |
| 2 | Calibration (30 videos) | ✅ Complete | v2.11 |
| 3 | Stress Test (30 videos) | ✅ Complete | v3.12 |
| 4 | Validation (30 videos) | ✅ Complete | v4.13 |
| 5 | Production Run (805 videos) | ✅ Complete | v5.14–v5.15 |
| 6 | Firestore + Geocoding + Polish | ✅ Complete | v6.26–v6.29 |
| 8 | Flutter App | ✅ Complete | v8.17–v8.25 |
| 7 | Enrichment | ✅ Complete | v7.30–v7.32 |

### Execution Model

**Group A (Phases 1-4):** Iterative refinement — 30-video batches with human review after each. Prompts and scripts are tuned between iterations. Orchestrated by Gemini CLI.

**Group B (Phases 5-7):** Unattended production run with locked prompts. Checkpoint reports every 50 videos. Automated hang detection. Runs via bash scripts in tmux.

---

## Data Model

Two Firestore collections:

**`restaurants`** — one document per unique restaurant, dishes and visits embedded:

```json
{
  "restaurant_id": "r_d0ab62fe2a03",
  "name": "Desert Oak Barbecue",
  "city": "El Paso",
  "state": "TX",
  "cuisine_type": "Barbecue",
  "owner_chef": "Rich Funk",
  "visits": [...],
  "dishes": [...],
  "created_at": "<timestamp>"
}
```

**`videos`** — metadata for processed YouTube videos.

---

## Repo Structure

```
tripledb/
├── docs/                          # Architecture docs + iteration artifacts
│   ├── ddd-design-v7.32.md        # Current iteration design (Input)
│   ├── ddd-plan-v7.32.md          # Current iteration plan (Input)
│   ├── ddd-build-v7.32.md         # Current iteration build log (Output)
│   └── ddd-report-v7.32.md        # Current iteration report (Output)
│
├── pipeline/                      # Python data pipeline
│   ├── scripts/                   # Phase scripts (Firestore loader, State fixer)
│   ├── data/                      # 1,102 normalized records
│   └── GEMINI.md
│
├── app/                           # Flutter Web
│   ├── lib/                       # Firestore providers
│   └── GEMINI.md
│
├── GEMINI.md                      # Root agent router
└── README.md
```

---

## Tech Stack

| Component | Tool | Purpose |
|-----------|------|---------|
| Transcription | faster-whisper (CUDA) | mp3 → timestamped JSON |
| Extraction | Gemini 2.5 Flash API | Transcript → restaurant JSON |
| Normalization | Gemini 2.5 Flash API | Dedupe, validate, schema-conform |
| Database | Cloud Firestore | Live data serving |
| Enrichment | Google Places API (New) | Ratings, status, websites, addresses |
| Frontend | Flutter Web + Riverpod | tripledb.net |
| Orchestration | Gemini CLI | Agentic execution |

---

## Current Metrics

### Live Dataset (tripledb.net)
- **1,102** unique restaurants across **62** states and territories
- **2,286** dishes with ingredients and Guy's reactions
- **2,336** video appearances from **773** processed YouTube videos
- **582** restaurants enriched with Google ratings, open/closed status, and websites
- **1,006** restaurants with map coordinates (Nominatim + Google backfill)
- **30** permanently closed restaurants identified
- **432** cross-video dedup merges

## Changelog

**v7.31 → v7.32 (Phase 7 Enrichment Refinement)**
- **Part A:** Refined search on 462 no-match restaurants using owner/chef names, cuisine types, and DDD-aware queries. Recovered 83 additional matches.
- **Part B:** Gemini Flash LLM verification of review-bucket matches. 112 confirmed correct, 126 false positives removed from Firestore.
- **Outcome:** Final enrichment coverage: 582/1,102 (52.8%). Geocoding coverage: 91.3%.

**v7.30 → v7.31 (Phase 7 Enrichment Production)**
- **Success:** Ran full enrichment pipeline on 1,102 restaurants. 625 records enriched with Google ratings, open/closed status, and website URLs. Merged results into Firestore.
- **Key finding:** 5.1% of featured restaurants (32) are now permanently closed. Average Google rating for DDD spots is 4.4 stars.
- **Outcome:** Enrichment complete. tripledb.net shows ratings, open/closed, and links.

**v6.29 → v7.30 (Phase 7 Enrichment Discovery)**
- **Success:** Built Google Places API (New) enrichment pipeline with Text Search → Place Details flow, fuzzy match validation (SequenceMatcher ≥0.70), caching, and resume support. Discovery batch of 50 restaurants enriched.
- **Key finding:** 66.7% match rate in discovery. 4 coordinate backfills from Google where Nominatim failed.
- **Outcome:** Pipeline validated for v7.31 full production run.

**v6.26 (Firestore Load + App Wiring)**
- **Success:** Resolved 126 UNKNOWN states via city-name inference. Loaded 1,102 restaurants into Cloud Firestore. Wired Flutter app to live Firestore data via `DataService` and `FirebaseFirestore`.
- **Outcome:** tripledb.net now serves live data from the full pipeline.

**v8.17 → v8.25 (Phase 8 Flutter Front End)**
- **Success:** Completed two-pass QA. Applied design tokens (Outfit + Inter). Optimized for Desktop and Mobile. Resolved critical null-safety issues in model parsing.
- **Outcome:** Production-ready UI with 92 Accessibility and 100 SEO scores.

**v5.14 → v5.15 (Production Run)**
- **Success:** Completed the full 805-video production run using Group B infrastructure.
- **Outcome:** 1,102 unique restaurants extracted and normalized.

---

## Author

**Kyle Thompson** — Solutions Architect @ TachTech Engineering

Built as a passion project for finding the best diners after long motorcycle rides.

---

*Last updated: Phase 7.33 — AKA Names + Closed Restaurant UX*
tfit + Inter). Optimized for Desktop and Mobile. Resolved critical null-safety issues in model parsing.
- **Outcome:** Production-ready UI with 92 Accessibility and 100 SEO scores.

**v5.14 → v5.15 (Production Run)**
- **Success:** Completed the full 805-video production run using Group B infrastructure.
- **Outcome:** 1,102 unique restaurants extracted and normalized.

---

## Author

**Kyle Thompson** — Solutions Architect @ TachTech Engineering

Built as a passion project for finding the best diners after long motorcycle rides.

---

*Last updated: Phase 7.32 — Enrichment Refinement*
