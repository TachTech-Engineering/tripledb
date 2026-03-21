# TripleDB

**Every restaurant from Diners, Drive-Ins and Dives — structured, searchable, and mapped.**

TripleDB processes 804 YouTube videos from Guy Fieri's "Diners, Drive-Ins and Dives" (DDD) into a structured Firestore database of restaurants, dishes, ingredients, and iconic Guy Fieri moments. The name is a triple play: **Triple D** (the show's nickname) + **DB** (database).

🌐 **tripleDB.com** · 📂 **Phase 1.8** · 🔧 **Status: Phase 1 Discovery (Iterating to v1.9)**

---

## What This Builds

A searchable database and Flutter Web app where you can:

- **Find a diner near you** — share your location or enter a zip code
- **Search by anything** — dish name, cuisine type, city, chef, ingredients ("ground beef" → hamburgers, meatloaf, etc.)
- **Watch the moment** — deep link to the exact YouTube timestamp where Guy walks into the restaurant
- **Query Guy's greatest hits** — how many times has he said "That's out of bounds!"?

---

## Architecture

```
YouTube Playlist (804 videos)
    ↓ yt-dlp
MP3 Audio
    ↓ faster-whisper (CUDA)
Timestamped Transcripts
    ↓ Qwen 3.5-9B (local, Ollama)
Structured Restaurant JSON
    ↓ Qwen 3.5-9B (local, Ollama)
Normalized + Deduplicated JSONL
    ↓ Firecrawl + Playwright
Enriched Data (addresses, ratings, open/closed)
    ↓ Firebase Admin SDK
Cloud Firestore
    ↓ Flutter Web
tripleDB.com
```

All inference runs locally on an NVIDIA RTX 2080 SUPER. Zero cloud API costs for extraction. Gemini CLI orchestrates the pipeline on its free tier.

---

## Project Status

| Phase | Name | Status | Iteration |
|------:|------|--------|-----------|
| 0 | Setup & Scaffolding | ✅ Complete | v0.7 |
| 1 | Discovery (30 videos) | 🔧 In Progress | v1.8 |
| 2 | Calibration (30 videos) | ⏳ Pending | — |
| 3 | Stress Test (30 videos) | ⏳ Pending | — |
| 4 | Validation (30 videos) | ⏳ Pending | — |
| 5-7 | Production Run (~684 videos) | ⏳ Pending | — |

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
├── docs/                          # Architecture docs + plan/report artifacts
│   ├── ddd-project-setup-v6.md    # Machine setup guide
│   ├── ddd-design-architecture-v6.md  # Data model, personas, prompts
│   ├── ddd-phase-prompts-v6.md    # Execution strategy
│   └── ddd-plan-v0.7.md           # Current phase plan
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

Plan and report documents follow `{phase}.{iteration}` versioning:

```
ddd-plan-v0.7.md     ← Phase 0, iteration 7
ddd-report-v0.7.md   ← Phase 0 results

ddd-plan-v1.8.md     ← Phase 1 Discovery
ddd-report-v1.8.md

ddd-plan-v2.9.md     ← Phase 2 Calibration, attempt 1
ddd-report-v2.9.md
ddd-plan-v2.10.md    ← Phase 2, attempt 2 (prompt revised)
ddd-report-v2.10.md
```

The iteration counter is global — it never resets. The full project history is the artifact trail.

---

## Tech Stack

| Component | Tool | Purpose |
|-----------|------|---------|
| Audio Download | yt-dlp | YouTube → mp3 |
| Transcription | faster-whisper (CUDA) | mp3 → timestamped JSON |
| Extraction | Qwen 3.5-9B (Ollama) | Transcript → restaurant JSON |
| Normalization | Qwen 3.5-9B (Ollama) | Dedupe, validate, schema-conform |
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
| Firestore | Free tier (Spark) |
| Firebase Hosting | Free tier |
| Firecrawl MCP | API credits only |
| **Total** | **Near-zero** |

---

## Changelog

**v1.8 → v1.9 (Phase 1 Discovery)**
- **Success:** Acquisition (Phase 1) and Transcription (Phase 2) are 100% stable. yt-dlp successfully bypasses JS challenges, and faster-whisper efficiently leverages the RTX 2080 Super for high-quality, timestamped segmentation.
- **Challenge:** Extraction (Phase 3) hit a hard wall with the 120B `Nemotron 3 Super` model. The 42GB footprint spilled entirely into system RAM, causing indefinite timeout loops during context pre-filling. 
- **Pivot for v1.9:** Swapping out Nemotron for the much faster, VRAM-friendly `qwen3.5:9b` for Extraction. Prompt engineering has been slimmed down (few-shots removed) and a transcript chunking mechanism added to `phase3_extract.py` to stay strictly within an 8k context window, keeping the entire pipeline operating smoothly on the GPU.

---

## Author

**Kyle Thompson** — Solutions Architect @ TachTech Engineering

Built as a passion project for finding the best diners after long motorcycle rides.

---

*Last updated: Phase 0.7 — Setup & Scaffolding*
