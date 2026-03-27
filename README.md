# TripleDB

**Every restaurant from Diners, Drive-Ins and Dives — structured, searchable, and mapped.**

TripleDB processes 805 YouTube videos from Guy Fieri's "Diners, Drive-Ins and Dives" (DDD) into a structured Firestore database of restaurants, dishes, ingredients, and iconic Guy Fieri moments. The name is a triple play: **Triple D** (the show's nickname) + **DB** (database).

🌐 **tripledb.net** · 📂 **Phase 6.26** · 🔧 **Status: Firestore Load + App Wiring (Current)**

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
review versioned artifacts between iterations. IAO emerged through 26 iterations
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

---

## Architecture

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
    ↓ fix_unknown_states.py
State Inference & Quality Fixes
    ↓ Firebase Admin SDK
Cloud Firestore (restaurants, videos)
    ↓ Flutter Web (Riverpod)
tripledb.net
```

Most inference runs locally on an NVIDIA RTX 2080 SUPER. Extraction uses the Gemini Flash API (free tier) to leverage its massive context window. Gemini CLI orchestrates the pipeline and app development.

---

## Project Status

| Phase | Name | Status | Iteration |
|------:|------|--------|-----------|
| 0 | Setup & Scaffolding | ✅ Complete | v0.7 |
| 1-4 | Pipeline Calibration | ✅ Complete | v4.13 |
| 5 | Production Run (805 videos) | ✅ Complete | v5.15 |
| 8 | Flutter App Build (QA) | ✅ Complete | v8.25 |
| 6 | Firestore Load + Wiring | 🔧 Current | v6.26 |
| 7 | Enrichment (Geocode, Ratings) | ⏳ Deferred | v7.27+ |

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
│   ├── ddd-design-v6.26.md        # Current iteration design (Input)
│   ├── ddd-plan-v6.26.md          # Current iteration plan (Input)
│   ├── ddd-build-v6.26.md         # Current iteration build log (Output)
│   └── ddd-report-v6.26.md        # Current iteration report (Output)
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
| Frontend | Flutter Web + Riverpod | tripledb.net |
| Orchestration | Gemini CLI | Agentic execution |

---

## Current Metrics

- **Videos processed:** 773 of 805
- **Unique restaurants:** 1,102
- **Unique dishes:** ~2,286
- **States covered:** 63
- **Dedup merges:** 432
- **App Build:** Stable (v8.25 QA passed)

## Changelog

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

*Last updated: Phase 6.26 — Firestore Load + App Wiring*
