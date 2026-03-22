# TripleDB

**Every restaurant from Diners, Drive-Ins and Dives — structured, searchable, and mapped.**

TripleDB processes 805 YouTube videos from Guy Fieri's "Diners, Drive-Ins and Dives" (DDD) into a structured Firestore database of restaurants, dishes, ingredients, and iconic Guy Fieri moments. The name is a triple play: **Triple D** (the show's nickname) + **DB** (database).

🌐 **tripleDB.com** · 📂 **Phase 5.14** · 🔧 **Status: Phase 5 Production Setup (Current)**

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
    ↓ Firecrawl + Playwright
Enriched Data (addresses, ratings, open/closed)
    ↓ Firebase Admin SDK
Cloud Firestore
    ↓ Flutter Web
tripleDB.com
```

Most inference runs locally on an NVIDIA RTX 2080 SUPER. Extraction uses the Gemini Flash API (free tier) to leverage its massive context window. Gemini CLI orchestrates the pipeline.

---

## Project Status

| Phase | Name | Status | Iteration |
|------:|------|--------|-----------|
| 0 | Setup & Scaffolding | ✅ Complete | v0.7 |
| 1 | Discovery (30 videos) | ✅ Complete | v1.10 |
| 2 | Calibration (30 videos) | ✅ Complete | v2.11 |
| 3 | Stress Test (30 videos) | ✅ Complete | v3.12 |
| 4 | Validation (30 videos) | ✅ Complete | v4.13 |
| 5.14 | Production Setup | 🔧 Current | v5.14 |
| 5.15+ | Production Run (~685 videos) | ⏳ Pending | — |
| 6-7 | Enrichment & DB Load | ⏳ Pending | — |

### Execution Model

**Group A (Phases 1-4):** Iterative refinement — 30-video batches with human review after each. Prompts and scripts are tuned between iterations. Orchestrated by Gemini CLI.

**Group B (Phases 5-7):** Unattended production run with locked prompts. Checkpoint reports every 50 videos. Automated hang detection. Runs via bash scripts in tmux.

---

## Data Model

Two Firestore collections:

**`restaurants`** — one document per unique restaurant, dishes and visits embedded:

```json
{
  "name": "Mama's Soul Food",
  "city": "Memphis",
  "state": "TN",
  "cuisine_type": "Soul Food",
  "owner_chef": "Tyrone Washington",
  "still_open": true,
  "google_rating": 4.6,
  "latitude": 35.1396,
  "longitude": -90.0541,
  "dishes": [
    {
      "dish_name": "Famous Fried Chicken",
      "ingredients": ["chicken", "buttermilk", "seasoned flour"],
      "guy_response": "Now THAT is what I'm talking about!"
    }
  ],
  "visits": [
    {
      "video_id": "Q2fk6b-hEbc",
      "guy_intro": "Here at Mama's Soul Food in Memphis...",
      "timestamp_start": 200.0
    }
  ]
}
```

**`videos`** — pipeline bookkeeping for processed YouTube videos.

---

## Repo Structure

```
tripledb/
├── docs/                          # Architecture docs + iteration artifacts
│   ├── archive/                   # Archived docs from previous iterations
│   ├── ddd-design-v5.14.md        # Current iteration design (Input)
│   ├── ddd-plan-v5.14.md          # Current iteration plan (Input)
│   ├── ddd-build-v5.14.md         # Current iteration build log (Output)
│   └── ddd-report-v5.14.md        # Current iteration report (Output)
│
├── pipeline/                      # Python data pipeline
│   ├── scripts/                   # Phase scripts
│   ├── agents/                    # Agent persona .md files
│   ├── config/                    # playlist_urls.txt, extraction prompt
│   ├── data/                      # Audio, transcripts, extracted, normalized, enriched
│   └── GEMINI.md
│
├── app/                           # Flutter Web (Phase 7)
│   ├── lib/
│   ├── assets/
│   └── GEMINI.md
│
├── GEMINI.md                      # Root agent router
└── README.md
```

---

## Artifact Versioning

Each iteration produces a four-artifact chain following `{phase}.{iteration}` versioning:

1. **Design** (`ddd-design-v{P}.{I}.md`) — Living architecture, locked decisions (Input)
2. **Plan** (`ddd-plan-v{P}.{I}.md`) — Pre-flight checklist, execution steps (Input)
3. **Build** (`ddd-build-v{P}.{I}.md`) — Full session transcript, commands, outputs (Output)
4. **Report** (`ddd-report-v{P}.{I}.md`) — Metrics, validation, recommendation (Output)

**Example v5.14 Chain:**
- `ddd-design-v5.14.md`
- `ddd-plan-v5.14.md`
- `ddd-build-v5.14.md`
- `ddd-report-v5.14.md`

The iteration counter is global — it never resets. The full project history is the artifact trail.

---

## Tech Stack

| Component | Tool | Purpose |
|-----------|------|---------|
| Audio Download | yt-dlp | YouTube → mp3 |
| Transcription | faster-whisper (CUDA) | mp3 → timestamped JSON |
| Extraction | Gemini 2.5 Flash API | Transcript → restaurant JSON |
| Normalization | Gemini 2.5 Flash API | Dedupe, validate, schema-conform |
| Enrichment | Firecrawl + Playwright MCP | Address, ratings, geocoords |
| Database | Cloud Firestore | Denormalized restaurant documents |
| Frontend | Flutter Web + Firebase Hosting | tripleDB.com |
| Orchestration | Gemini CLI (Group A) / bash (Group B) | Pipeline execution |

---

## Hardware

```
NZXT MS-7E06 Desktop
CPU: Intel Core i9-13900K (24-core, 5.8 GHz)
RAM: 64 GB DDR4
GPU: NVIDIA GeForce RTX 2080 SUPER (8 GB VRAM)
OS:  CachyOS (Arch-based) / KDE Plasma 6.6.2 / Wayland
```

---

## Cost

| Component | Cost |
|-----------|------|
| All local inference | Free |
| Gemini CLI | Free tier |
| Gemini Flash API | Free tier |
| Firestore | Free tier (Spark) |
| Firebase Hosting | Free tier |
| Firecrawl MCP | API credits only |
| **Total** | **Near-zero** |

---


## Current Metrics

- **Videos processed:** 120 of 805
- **Unique restaurants:** 604
- **Unique dishes:** 985
- **Dedup merges:** 159
- **States covered:** 56
- **Extraction quality:** 98% guy_intro, 98% guy_response, 100% ingredients
- **Human interventions (last 2 iterations):** 0

## Changelog

**v5.14 → v8.21 (Phase 8 Flutter Front End)**
- **Success:** Initial Flutter Web build completed using CanvasKit and Riverpod. Implemented Home Page, auto-cycling Trivia Engine, Search Results, Restaurant Details, and Map visualization.
- **Challenge:** Critical runtime `TypeError` caused by null values in raw JSON fields, and `latlong2` import conflicts.
- **Outcome:** Null-safe data models implemented, layout parity achieved across Desktop and Mobile, and 0 issues in `flutter analyze`. The core app is STABLE and ready for Firestore wiring (Phase 5).



**v4.13 → v5.14 (Phase 5 Production Setup)**
- **Success:** Fixed null-name restaurant merging bug that was collapsing 14 distinct
  extraction failures into a single record. Built Group B runner infrastructure with
  checkpoint reporting and hang detection. Documented IAO methodology as Eight Pillars.
- **Challenge:** 62 restaurants with null/unknown state data required inference logic
  and a new "UNKNOWN" category.
- **Outcome:** Group B production run ready for tmux launch.

**v3.12 → v4.13 (Phase 4 Validation)**
- **Success:** Successfully validated the end-to-end pipeline with locked prompts. Processed 30 validation videos without human intervention, achieving 162 dedup merges across ~120 total processed videos. Secret scan verified no keys in tracked files.
- **Challenge:** Transcription of marathon videos takes significant time, but background execution prevented timeouts. A few videos resulted in empty JSONs due to formatting errors but did not break the pipeline.
- **Outcome:** Group B green-lit. Readiness checklist passed.

**v2.11 → v3.12 (Phase 3 Stress Test)**
- **Success:** Pushed the pipeline through its hardest content, handling heavily overlapping compilation videos. Normalization successfully merged 98 duplicate restaurant appearances across 89 total videos, proving the deduplication logic is solid.
- **Challenge:** Transcribing 4+ hour marathons locally exceeded practical session limits and shell timeouts. The 4-hour `bawGcAsAA-w` video also exceeded Gemini's JSON output token limits during extraction.
- **Pivot for v3.12:** Auto-healed the active batch by swapping out pending massive marathons for shorter clips to meet the 30-video quota within session limits, while correctly handling the massive marathons that *were* already transcribed as accepted edge cases.

**v1.10 → v2.11 (Phase 2 Calibration)**
- **Success:** Normalized and deduplicated the entire 60-video dataset (Phase 1 + Phase 2) via the Gemini 2.5 Flash API, proving the free tier can handle the complex grouping and merging logic with a 1M token context. 422 unique restaurants and 624 unique dishes were extracted successfully. 
- **Challenge:** `faster-whisper` repeatedly failed due to the `libcublas.so.12` library missing at runtime, as the internal `os.environ` change occurred too late for C library loading. Additionally, extraction initially timed out on marathon videos (60-150m length).
- **Pivot for v2.11:** Launched the transcription script with `LD_LIBRARY_PATH` set directly at the shell level. Increased the extraction timeout to 300 seconds, allowing Gemini Flash to successfully process massive transcripts (up to 200K characters) without chunking.

**v1.9 → v1.10 (Phase 1 Discovery)**
- **Challenge:** Local inference on an 8GB VRAM GPU proved insufficient for structured extraction. Even with `qwen3.5:9b`, reduced context limits, and chunked transcripts, inference took 5-10 minutes per video and consistently timed out on longer episodes.
- **Pivot for v1.10:** Shifted the Extraction phase (Phase 3) to the **Gemini 2.5 Flash API**. With its 1M token context window, chunking was eliminated entirely. Entire transcripts are passed in a single API call, returning high-quality structured JSON in seconds. The generous free tier easily handles the entire pipeline, achieving a 93% success rate across the 30-video test batch and resolving the local hardware bottlenecks.

**v1.8 → v1.9 (Phase 1 Discovery)**
- **Success:** Acquisition (Phase 1) and Transcription (Phase 2) are 100% stable. yt-dlp successfully bypasses JS challenges, and faster-whisper efficiently leverages the RTX 2080 Super for high-quality, timestamped segmentation.
- **Challenge:** Extraction (Phase 3) hit a hard wall with the 120B `Nemotron 3 Super` model. The 42GB footprint spilled entirely into system RAM, causing indefinite timeout loops during context pre-filling. 
- **Pivot for v1.9:** Swapping out Nemotron for the much faster, VRAM-friendly `qwen3.5:9b` for Extraction. Prompt engineering has been slimmed down (few-shots removed) and a transcript chunking mechanism added to `phase3_extract.py` to stay strictly within an 8k context window, keeping the entire pipeline operating smoothly on the GPU.

---

## Author

**Kyle Thompson** — Solutions Architect @ TachTech Engineering

Built as a passion project for finding the best diners after long motorcycle rides.

---

*Last updated: Phase 5.14 — Production Setup*