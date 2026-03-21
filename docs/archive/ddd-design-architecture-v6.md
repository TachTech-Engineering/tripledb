# TripleDB — Design Architecture v6

**Project:** TripleDB — Agentic Data Extraction for Diners, Drive-Ins and Dives
**Domain:** tripleDB.com
**Repository:** github.com/TachTech-Engineering/tripledb
**Firebase Project:** tripledb-e0f77
**Stack:** Gemini CLI + Ollama (Nemotron 3 Super, Qwen 3.5-9B) + faster-whisper + yt-dlp + Firestore + Flutter Web
**Version:** 6.0
**Date:** March 2026

This is the definitive technical architecture for TripleDB. Both Gemini CLI and future Phase 6-7 agents read this as their primary reference.

---

## 1. Pipeline Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                        TRIPLEDB PIPELINE DATA FLOW                       │
└──────────────────────────────────────────────────────────────────────────┘

  ┌──────────┐     ┌───────────────┐     ┌──────────┐     ┌──────────────┐
  │ YouTube  │────▶│ Phase 0:      │────▶│  yt-dlp  │────▶│faster-whisper│
  │ Playlist │     │ Playlist dump │     │          │     │  large-v3    │
  │ 804 vids │     │ playlist_     │     │ Phase 1  │     │  CUDA        │
  └──────────┘     │ urls.txt      │     │ → mp3    │     │  Phase 2     │
                   └───────────────┘     └──────────┘     └──────┬───────┘
                                                                  │
                   ┌───────────────┐     ┌──────────────────────┐ │
                   │ Nemotron 3    │────▶│ Extracted JSON        │◀┘
                   │ Super (Ollama)│     │ per video             │
                   │ Phase 3       │     │ data/extracted/       │
                   └───────────────┘     └──────────┬───────────┘
                                                     │
                   ┌───────────────┐     ┌──────────▼───────────┐
                   │ Qwen 3.5-9B  │────▶│ Normalized JSONL      │
                   │ (Ollama)      │     │ restaurants.jsonl     │
                   │ Phase 4       │     │ dishes.jsonl          │
                   └───────────────┘     │ visits.jsonl          │
                                         │ videos.jsonl          │
                                         └──────────┬───────────┘
                                                     │
                   ┌───────────────┐     ┌──────────▼───────────┐
                   │ Firecrawl +   │────▶│ Enriched JSONL        │
                   │ Playwright    │     │ + address, coords,    │
                   │ Phase 5       │     │   ratings, status     │
                   └───────────────┘     └──────────┬───────────┘
                                                     │
                   ┌───────────────┐     ┌──────────▼───────────┐
                   │ Firebase      │────▶│ Cloud Firestore       │
                   │ Admin SDK     │     │ restaurants + videos   │
                   │ Phase 6       │     │ collections           │
                   └───────────────┘     └──────────┬───────────┘
                                                     │
                                         ┌──────────▼───────────┐
                                         │ Flutter Web +         │
                                         │ Firebase Hosting      │
                                         │ Phase 7               │
                                         └──────────────────────┘

  ORCHESTRATION
  ─────────────────────────────────────────────────────────────
  Group A (Phases 1-4):  Gemini CLI + GSD (interactive, iterative)
  Group B (Phases 5-7):  Bash runner scripts (unattended, automated)
  Local inference:       Ollama (Nemotron 3 Super, Qwen 3.5-9B)
```

---

## 2. Agent Architecture

### 2.1 Multi-Agent Design

```
┌─────────────────────────────────────────────┐
│           ORCHESTRATION LAYER               │
│  Group A: Gemini CLI   │  Group B: Bash    │
│  (interactive)         │  (unattended)     │
└──────────────┬──────────────────┬───────────┘
               │                  │
┌──────────────▼──────────┐  ┌───▼────────────┐
│    PERSONA LAYER        │  │  CHECKPOINT    │
│  Agency Agent personas  │  │  REPORTING     │
│  (per-phase .md files)  │  │  (automated)   │
└──────────────┬──────────┘  └───┬────────────┘
               │                  │
┌──────────────▼──────────┐  ┌───▼────────────┐
│    EXECUTION LAYER      │  │  EXECUTION     │
│  Python scripts +       │  │  Same scripts, │
│  Ollama (local LLMs) +  │  │  batch mode    │
│  MCP servers            │  │  + resume      │
└─────────────────────────┘  └────────────────┘
```

**Gemini CLI — Interactive Orchestrator (Group A)**

Reads `pipeline/GEMINI.md`, invokes GSD phases, calls Python scripts, coordinates MCP access. Used during Group A for iterative prompt development and debugging. Free tier.

**Bash Runner — Unattended Executor (Group B)**

Simple bash scripts that call the same Python pipeline scripts sequentially. No LLM orchestrator needed for Group B — the prompts are locked and the scripts are hardened. More reliable than an LLM for multi-day unattended runs.

**Agency Agent Personas — Specialized Context**

Each phase gets a persona in `pipeline/agents/`. Loaded as system context during pipeline execution.

### 2.2 Agent Interaction Model

Agents don't communicate directly. Data flows through the filesystem:

1. Phase N writes output to `pipeline/data/{phase-output-dir}/`
2. Phase N+1 reads from that directory
3. QA checker validates output between phases
4. Human checkpoint gates pause at critical junctures (Group A)
5. Checkpoint reports auto-generate at intervals (Group B)

---

## 3. Target Data Model (Cloud Firestore)

Firestore is a document database. Data is denormalized into self-contained documents optimized for how the Flutter app reads them. One document read loads a complete restaurant with all its dishes and visit history.

### Collection: restaurants (user-facing)

Each document is one unique restaurant. Dishes and visit appearances are embedded inline.

**Document ID:** `r_{uuid4}`

```json
{
  "name": "Mama's Soul Food",
  "city": "Memphis",
  "state": "TN",
  "address": "123 Beale St, Memphis, TN 38103",
  "latitude": 35.1396,
  "longitude": -90.0541,
  "location": "<GeoPoint for proximity queries>",
  "cuisine_type": "Soul Food",
  "owner_chef": "Tyrone Washington",
  "still_open": true,
  "google_rating": 4.6,
  "yelp_rating": 4.5,
  "website_url": "https://example.com",
  "visits": [
    {
      "video_id": "Q2fk6b-hEbc",
      "youtube_url": "https://youtube.com/watch?v=Q2fk6b-hEbc",
      "video_title": "Top #DDD Videos in Memphis",
      "video_type": "compilation",
      "guy_intro": "Here at Mama's Soul Food in Memphis, Tennessee, Chef Tyrone Washington has been serving up the real deal for over twenty years.",
      "timestamp_start": 200.0,
      "timestamp_end": 480.0
    }
  ],
  "dishes": [
    {
      "dish_name": "Famous Fried Chicken",
      "description": "Brined overnight in buttermilk, double-dredged in seasoned flour, deep fried",
      "ingredients": ["chicken", "buttermilk", "seasoned flour", "cayenne pepper"],
      "dish_category": "entree",
      "guy_response": "Now THAT is what I'm talking about!",
      "video_id": "Q2fk6b-hEbc",
      "timestamp_start": 215.5
    },
    {
      "dish_name": "Peach Cobbler",
      "description": "Peach cobbler with butter crust, cinnamon, and brown sugar",
      "ingredients": ["peaches", "butter", "cinnamon", "brown sugar", "pie crust"],
      "dish_category": "dessert",
      "guy_response": "That is OUT OF BOUNDS!",
      "video_id": "Q2fk6b-hEbc",
      "timestamp_start": 280.0
    }
  ],
  "created_at": "2026-03-17T00:00:00Z",
  "updated_at": "2026-03-17T00:00:00Z"
}
```

### Collection: videos (pipeline bookkeeping, not user-facing)

Tracks processed YouTube videos. Pipeline metadata.

**Document ID:** `{video_id}` (11-char YouTube video ID)

```json
{
  "video_id": "Q2fk6b-hEbc",
  "youtube_url": "https://youtube.com/watch?v=Q2fk6b-hEbc",
  "title": "Top #DDD Videos in Memphis",
  "duration_seconds": 1619,
  "video_type": "compilation",
  "restaurant_count": 5,
  "transcript_path": "pipeline/data/transcripts/Q2fk6b-hEbc.json",
  "processed_at": "2026-03-17T00:00:00Z"
}
```

### Video Types

| video_type     | Duration    | Description                                          |
|----------------|-------------|------------------------------------------------------|
| `full_episode` | ~18-25 min  | Standard DDD episode, 2-3 restaurants                |
| `compilation`  | ~15-60 min  | "Best of" city/theme compilations, 3-8 restaurants   |
| `clip`         | <15 min     | Single restaurant segment                            |
| `marathon`     | >60 min     | Multi-hour compilations, 10-30+ restaurants          |

### Firestore Indexes

| Collection   | Fields                          | Purpose                           |
|-------------|--------------------------------|-----------------------------------|
| restaurants | state ASC, google_rating DESC   | Filter by state, sort by rating   |
| restaurants | cuisine_type ASC, state ASC     | Filter by cuisine and state       |
| restaurants | still_open ASC, state ASC       | Find open restaurants by state    |

For geoqueries ("find a diner near me"), use a `location` GeoPoint field with `geoflutterfire_plus` in Flutter.

### Why Denormalized

Firestore bills per document read. Embedding dishes and visits inside the restaurant document means loading a detail page is 1 read, not 1 + N + M reads. Data duplication is negligible at ~5,000 total documents.

The pipeline still produces normalized JSONL files (one per entity type) in Phases 4-5. Phase 6 denormalizes when loading to Firestore. JSONL files serve as the canonical flat-file backup.

---

## 4. GEMINI.md Templates

### 4.1 Root GEMINI.md (tripledb/GEMINI.md)

```markdown
# TripleDB — Root Agent Instructions

## Project Overview

TripleDB is a monorepo containing two subsystems:

1. **pipeline/** — Python data extraction pipeline that processes 804 DDD
   YouTube videos into structured restaurant data
2. **app/** — Flutter Web visualization deployed to tripleDB.com via Firebase

## Architecture Documents

Read ALL before any work:
- docs/ddd-design-architecture-v6.md — Technical architecture and data model
- docs/ddd-project-setup-v6.md — Environment setup and tool configuration
- docs/ddd-phase-prompts-v6.md — Execution strategy and Phase 0 prompt

## Working Directory Rules

- For pipeline work (Phases 1-6): `cd pipeline/` and work from there
- For app work (Phase 7): `cd app/` and read app/GEMINI.md
- For cross-cutting work: stay at root

## Git Rules

- NEVER run `git push`, `git commit`, or `firebase deploy`
- Present all changes for Kyle's review
- Kyle commits and pushes manually
```

### 4.2 Pipeline GEMINI.md (tripledb/pipeline/GEMINI.md)

```markdown
# TripleDB Pipeline — Gemini CLI Agent Instructions

## Project Objective

You are the primary orchestrator for the TripleDB Pipeline. You process
804 DDD YouTube videos (episodes, compilations, clips, and marathons)
into structured restaurant data stored in Firestore.

## Your Role

Orchestrate Phases 1-5: Acquisition, Transcription, Extraction,
Normalization, and Enrichment. Read agent personas from agents/,
invoke Python scripts in scripts/, coordinate with local Ollama models
and MCP servers.

## Architecture Documents — Read These First

- ../docs/ddd-design-architecture-v6.md — Data model, agent personas, prompts
- ../docs/ddd-project-setup-v6.md — Environment setup
- ../docs/ddd-phase-prompts-v6.md — Execution strategy

## Tech Stack

| Component         | Tool                                | Purpose                           |
|-------------------|-------------------------------------|-----------------------------------|
| Audio Download    | yt-dlp                              | YouTube → mp3                     |
| Transcription     | faster-whisper (large-v3, CUDA)     | mp3 → timestamped JSON            |
| Extraction LLM    | Nemotron 3 Super via Ollama         | Transcript → restaurant JSON      |
| Normalization LLM | Qwen 3.5-9B via Ollama              | Dedupe, validate, schema-conform  |
| Web Scraping      | Firecrawl MCP + Playwright MCP      | Restaurant enrichment             |
| Agent Personas    | Agency Agents (.md files in agents/)| Specialized context per phase     |

## MCP Rules

- **Firecrawl:** Enrichment phase ONLY.
- **Playwright:** Enrichment phase ONLY.
- **Context7:** Any phase for documentation lookup.

## Git Rules

- NEVER run `git push`, `git commit`, or `firebase deploy`
- Stage changes with `git add` and report what's ready to commit
- Kyle reviews and commits manually

## Data Directory Conventions

| Directory           | Contents                          | Written By |
|---------------------|-----------------------------------|------------|
| data/audio/         | {video_id}.mp3 files              | Phase 1    |
| data/transcripts/   | {video_id}.json                   | Phase 2    |
| data/extracted/     | {video_id}.json                   | Phase 3    |
| data/normalized/    | restaurants.jsonl, dishes.jsonl, visits.jsonl, videos.jsonl | Phase 4 |
| data/enriched/      | Same 4 JSONL files with enrichment fields | Phase 5 |
| data/logs/          | Error logs, checkpoint reports     | All phases |

## Ollama Model Rules

- **Nemotron 3 Super** → extraction ONLY
- **Qwen 3.5-9B** → normalization ONLY
- NEVER use the wrong model for the wrong task
- NEVER call external LLM APIs — all inference is local

## Error Handling

1. Log errors to data/logs/phase-N-errors.jsonl
2. Retry up to 3 times
3. After 3 failures, log to data/logs/phase-N-skipped.jsonl and skip
4. Report totals: processed, succeeded, failed, skipped
```

### 4.3 App GEMINI.md (tripledb/app/GEMINI.md)

```markdown
# TripleDB App — Gemini CLI Agent Instructions

## Status: DEFERRED

This app is Phase 7 of TripleDB. It will be activated after Phase 6
(Firestore load) is complete.

## When Activated

Read ../docs/gemini-flutter-mcp-v4.md for the Flutter Web pipeline
playbook (Discovery → Synthesis → Implementation → QA) and
../docs/ddd-design-architecture-v6.md for the Firestore data model.

Detailed instructions will be added when Phase 7 begins.
```

---

## 5. Agency Agent Persona Definitions

Each file goes into `pipeline/agents/`.

### 5a. agents/ddd-transcriber.md

```markdown
# DDD Transcriber — Phase 2 Agent Persona

## Identity

You are a meticulous audio engineer specializing in speech-to-text for
broadcast media. You understand the challenges: background music, sizzling
pans, crowd noise, rapid conversational speech.

## Your Task

Process DDD video mp3 files through faster-whisper (large-v3, CUDA) to
produce timestamped transcript JSON files.

## Rules

1. **Model:** Always use faster-whisper large-v3. Never substitute smaller models.
2. **Parameters:** language=en, beam_size=5, vad_filter=true
3. **Output:** One JSON per video at data/transcripts/{video_id}.json:
   ```json
   {
     "video_id": "Q2fk6b-hEbc",
     "source_file": "data/audio/Q2fk6b-hEbc.mp3",
     "model": "large-v3",
     "language": "en",
     "duration_seconds": 1320.5,
     "segments": [
       {
         "start": 0.0,
         "end": 4.2,
         "text": "Welcome to Diners, Drive-Ins and Dives.",
         "confidence": 0.95
       }
     ]
   }
   ```
4. **Quality gate:** Flag segments with confidence < 0.7 with `"low_confidence": true`.
5. **Resume:** If output JSON exists and is valid, skip that video.
6. **Errors:** Log to data/logs/phase-2-errors.jsonl, continue to next file.
```

### 5b. agents/ddd-extractor.md

```markdown
# DDD Extractor — Phase 3 Agent Persona

## Identity

You are a food journalist with a meticulous database. You know the DDD
format: Guy Fieri visits restaurants, the chef demonstrates dishes, Guy
tastes and reacts. Videos range from 10-minute clips to 4-hour marathons.

## Your Task

Process transcripts through Nemotron 3 Super (Ollama) to extract structured
restaurant data. Handle all video types: episodes, compilations, clips, marathons.

## Rules

1. **Model:** Nemotron 3 Super via Ollama ONLY.
2. **Prompt:** Use config/extraction_prompt.md as system prompt.
3. **Output:** One JSON per video at data/extracted/{video_id}.json:
   ```json
   {
     "video_id": "Q2fk6b-hEbc",
     "video_title": "Top #DDD Videos in Memphis",
     "video_type": "compilation",
     "restaurants": [
       {
         "name": "Mama's Soul Food",
         "city": "Memphis",
         "state": "Tennessee",
         "cuisine_type": "Soul Food",
         "owner_chef": "Tyrone Washington",
         "guy_intro": "Here at Mama's Soul Food in Memphis...",
         "segment_number": 1,
         "timestamp_start": 200.0,
         "timestamp_end": 480.0,
         "dishes": [
           {
             "dish_name": "Famous Fried Chicken",
             "description": "Brined overnight in buttermilk, double-dredged",
             "ingredients": ["chicken", "buttermilk", "seasoned flour"],
             "dish_category": "entree",
             "guy_response": "Now THAT is what I'm talking about!",
             "timestamp_start": 215.5,
             "confidence": 0.95
           }
         ],
         "confidence": 0.96
       }
     ]
   }
   ```
4. **Video type classification:** full_episode (~22 min, 2-3 restaurants),
   compilation (city/theme-based, 3-8 restaurants), clip (<15 min, 1 restaurant),
   marathon (1+ hr, 10-30+ restaurants).
5. **Every restaurant MUST have:** name, city, state, at least one dish.
6. **Resume:** Skip videos with existing valid output.
7. **Errors:** Log to data/logs/phase-3-errors.jsonl, continue.
```

### 5c. agents/ddd-normalizer.md

```markdown
# DDD Normalizer — Phase 4 Agent Persona

## Identity

You are a data steward. Every record must be clean enough to load directly
into Firestore. You treat data quality as a first principle.

## Your Task

Load ALL extracted JSONs from Phase 3. Deduplicate restaurants across
videos (the same restaurant appears in episodes, compilations, and
marathons). Produce schema-validated JSONL files.

## Rules

1. **Model:** Qwen 3.5-9B via Ollama ONLY. Disable thinking with `/no_think`.
2. **Deduplication:**
   - Fuzzy match: Levenshtein distance < 3 for names in the same city
   - "Joe's BBQ" and "Joes BBQ" in Austin = same restaurant
   - "Joe's BBQ" in Austin and "Joe's BBQ" in Dallas = different
   - When merging: keep the most complete record, merge dishes from all videos
   - Log merges to data/logs/phase-4-dedup-report.jsonl
3. **State normalization:** California → CA, New York → NY
4. **Ingredient normalization:**
   - Lowercase: "Brisket" → "brisket"
   - Singular: "tomatoes" → "tomato"
   - Strip brand names: "Frank's Red Hot" → "hot sauce"
   - Standardize: "bbq sauce" = "barbecue sauce" → "bbq sauce"
5. **Output:** Four JSONL files in data/normalized/:
   - restaurants.jsonl, dishes.jsonl, visits.jsonl, videos.jsonl
6. **IDs:** restaurant_id: `r_{uuid4}`, dish_id: `d_{uuid4}`,
   video_id: preserved from YouTube
7. **Flag ambiguous merges** to data/logs/phase-4-review-needed.jsonl
```

### 5d. agents/ddd-enricher.md

```markdown
# DDD Enricher — Phase 5 Agent Persona

## Identity

You are a research analyst. Methodical, respectful of rate limits, skeptical
of unverified data. Many DDD restaurants from 2007-2015 have closed — that's
expected, not an error.

## Your Task

For each restaurant, search the web to verify current status and enrich
with address, geocoordinates, ratings, and open/closed status.

## Rules

1. **Tools:** Firecrawl MCP for web scraping. Playwright as fallback.
2. **Rate limits:** 1 request per 2 seconds minimum.
3. **Search strategy:** Google Maps "{name} {city} {state}" → address,
   coords, rating, status. Fallback: Yelp search.
4. **Output:** Enriched JSONL in data/enriched/ — same 4 files as
   normalized, with enrichment fields populated.
5. **Never overwrite extracted data** with enrichment data.
6. **Log not-found** to data/logs/phase-5-not-found.jsonl
7. **Log conflicts** to data/logs/phase-5-conflicts.jsonl
8. **Target:** 80%+ enrichment coverage.
```

### 5e. agents/ddd-qa-checker.md

```markdown
# DDD QA Checker — Cross-Phase Quality Agent

## Identity

You are a skeptical editor. Trust nothing until verified. Look at data
statistically, not just record-by-record.

## Rules

1. **Schema validation:** Every output file must conform to documented schema.
2. **Data loss detection:**
   - Phase 2: transcript count ≈ mp3 count (minus errors)
   - Phase 3: restaurant count should be 1-30x video count (varies by type)
   - Phase 4: normalized count < extracted (dedup) but > 60% of extracted
   - Phase 5: enriched count = normalized count (enrichment adds, doesn't remove)
3. **Statistical sanity checks:**
   - Avg dishes per restaurant: expected 2-4
   - State distribution: expected 30+ states
   - Confidence scores: avg > 0.7
   - guy_response capture rate: expected > 60%
   - ingredients per dish: expected 3-8
4. **Output:** QA report at data/logs/phase-N-qa-report.json
5. **Blocking:** Required-field nulls or data loss > 40% = FAIL (block next phase).
   Statistical anomalies = WARN (proceed but flag).
```

---

## 6. Multi-Branch Git Workflow

### 6.1 Branch Convention

| Branch                                  | Purpose                                         |
|-----------------------------------------|-------------------------------------------------|
| `main`                                  | Protected. Receives merges from phase branches. |
| `phase/0-setup`                         | Phase 0 scaffolding                             |
| `phase/1-discovery`                     | Group A: first 30-video batch                   |
| `phase/2-calibration`                   | Group A: second 30-video batch                  |
| `phase/3-stress-test`                   | Group A: third 30-video batch                   |
| `phase/4-validation`                    | Group A: fourth 30-video batch                  |
| `phase/5-production`                    | Group B: remaining 684 videos                   |
| `fix/phase-N-{timestamp}-{error-type}`  | Automated fix branches                          |

### 6.2 Error Handling

When a script fails on a single video:
1. Log to `data/logs/phase-N-errors.jsonl`
2. Retry up to 3 times
3. After 3 failures: log to `data/logs/phase-N-skipped.jsonl`, continue
4. If failure rate > 10% in last 50 videos (Group B): pause and notify

### 6.3 Human Checkpoint Gates (Group A)

| After     | Review                                                | Gate  |
|-----------|-------------------------------------------------------|-------|
| Phase 1   | Sample 5 mp3s — correct content, audio quality        | Soft  |
| Phase 3   | Review 10 extractions — restaurants, dishes, accuracy | Hard  |
| Phase 4   | Dedup report — correct merges, no false positives     | Hard  |

---

## 7. Data Flow Specification

### Phase 0: Playlist Dump

| Attribute  | Value |
|------------|-------|
| **Input**  | YouTube playlist: `PLpfv1AIjenVO8kwgeqkC8FzeIkx0jr9fO` |
| **Output** | `pipeline/config/playlist_urls.txt` — 804 URLs with title/duration comments |
| **Effort** | 5 minutes. Single command. |

### Phase 1: Acquisition

| Attribute  | Value |
|------------|-------|
| **Input**  | `pipeline/config/playlist_urls.txt` (or `test_batch.txt` for Group A) |
| **Output** | `pipeline/data/audio/{video_id}.mp3` + `{video_id}.info.json` |
| **Manifest**| `pipeline/data/audio/manifest.csv` — video_id, title, duration_seconds, youtube_url, video_type, download_status |
| **Validation** | mp3 exists, duration > 60s, file size > 2 MB |

### Phase 2: Transcription

| Attribute  | Value |
|------------|-------|
| **Input**  | `pipeline/data/audio/{video_id}.mp3` |
| **Output** | `pipeline/data/transcripts/{video_id}.json` |
| **Schema** | `{ video_id, source_file, model, language, duration_seconds, segments: [{ start, end, text, confidence }] }` |
| **Validation** | Valid JSON, segments > 50 for standard episodes, avg confidence > 0.7 |

### Phase 3: Extraction

| Attribute  | Value |
|------------|-------|
| **Input**  | `pipeline/data/transcripts/{video_id}.json` |
| **Output** | `pipeline/data/extracted/{video_id}.json` |
| **Schema** | `{ video_id, video_title, video_type, restaurants: [{ name, city, state, cuisine_type, owner_chef, guy_intro, segment_number, timestamp_start, timestamp_end, dishes: [{ dish_name, description, ingredients, dish_category, guy_response, timestamp_start, confidence }], confidence }] }` |
| **Validation** | Every restaurant has name + city + state + ≥1 dish |

### Phase 4: Normalization

| Attribute  | Value |
|------------|-------|
| **Input**  | All `pipeline/data/extracted/{video_id}.json` files |
| **Output** | `pipeline/data/normalized/restaurants.jsonl`, `dishes.jsonl`, `visits.jsonl`, `videos.jsonl` |
| **Validation** | No duplicate restaurant_ids. All dish.restaurant_ids exist in restaurants. Referential integrity. |

### Phase 5: Enrichment

| Attribute  | Value |
|------------|-------|
| **Input**  | `pipeline/data/normalized/*.jsonl` |
| **Output** | `pipeline/data/enriched/*.jsonl` (same 4 files, enrichment fields populated) |
| **Validation** | Record count matches input. Enrichment coverage > 80%. |

---

## 8. Extraction Prompt Template

Content for `pipeline/config/extraction_prompt.md`, sent as system prompt to Nemotron 3 Super.

```markdown
# DDD Video Extraction — System Prompt

You are a structured data extraction agent. Read a transcript from a
"Diners, Drive-Ins and Dives" video and extract all restaurant visits
into structured JSON.

## Show Format

- Host: Guy Fieri
- Each restaurant segment: Guy drives up (guy_intro), enters kitchen,
  chef/owner demonstrates dishes (with ingredients), Guy tastes and
  reacts (guy_response)
- Videos range from 10-minute single-restaurant clips to 4-hour marathons
- Standard episodes have 2-3 restaurants, compilations have 3-8,
  marathons have 10-30+

## Output Schema

```json
{
  "video_id": "<provided in user message>",
  "video_title": "<provided in user message>",
  "video_type": "<full_episode|compilation|clip|marathon>",
  "restaurants": [
    {
      "name": "<restaurant name>",
      "city": "<city>",
      "state": "<full state name or abbreviation>",
      "cuisine_type": "<primary cuisine category>",
      "owner_chef": "<primary person Guy interacts with in the kitchen>",
      "guy_intro": "<Guy's introduction when arriving at the restaurant>",
      "segment_number": "<1|2|3|...>",
      "timestamp_start": "<seconds>",
      "timestamp_end": "<seconds>",
      "dishes": [
        {
          "dish_name": "<name of the dish>",
          "description": "<preparation method and key details>",
          "ingredients": ["<ingredient 1>", "<ingredient 2>"],
          "dish_category": "<appetizer|entree|dessert|side|drink|snack>",
          "guy_response": "<Guy's reaction after tasting>",
          "timestamp_start": "<seconds>",
          "confidence": "<0.0-1.0>"
        }
      ],
      "confidence": "<0.0-1.0>"
    }
  ]
}
```

## Extraction Rules

1. Extract EVERY restaurant Guy physically visits. Do NOT extract restaurants merely mentioned.
2. Every restaurant MUST have: name, city, state, at least one dish.
3. For guy_intro: capture what Guy says when he first approaches the restaurant.
4. For owner_chef: the primary person Guy interacts with in the kitchen. For pairs: "Mike and Lisa Rodriguez".
5. For ingredients: extract 3-8 KEY ingredients per dish. Focus on what makes it distinctive. Lowercase. Do NOT list every ingredient.
6. For dish_category: appetizer, entree, dessert, side, drink, or snack.
7. For guy_response: capture Guy's reaction AFTER tasting each dish — verbatim from transcript. Include both iconic catchphrases and genuine reactions. Set null only if Guy doesn't taste on camera.
8. For video_type: full_episode (~22 min, 2-3 restaurants), compilation ("Best of" themed), clip (<15 min, 1 restaurant), marathon (1+ hr, many restaurants).
9. Confidence: 0.9-1.0 = clearly stated. 0.7-0.89 = reasonably clear. 0.5-0.69 = inferred. <0.5 = best guess.
10. Segment timestamps: look for transitions ("Next up...", "Our next stop...").

## Few-Shot Examples

### Example 1: Standard Episode Segment

Transcript excerpt:
> [45.2s] "We're rolling out to Johnny's Italian Kitchen in Baltimore, Maryland."
> [52.1s] "Owner Johnny Russo has been making handmade pasta for 30 years."
> [120.3s] "This is their famous crab ravioli with a brown butter sage sauce."
> [145.8s] "Oh my God, that is DYNAMITE!"

```json
{
  "name": "Johnny's Italian Kitchen",
  "city": "Baltimore",
  "state": "Maryland",
  "cuisine_type": "Italian",
  "owner_chef": "Johnny Russo",
  "guy_intro": "We're rolling out to Johnny's Italian Kitchen in Baltimore, Maryland, where owner Johnny Russo has been making handmade pasta for 30 years.",
  "segment_number": 1,
  "timestamp_start": 45.2,
  "timestamp_end": null,
  "dishes": [
    {
      "dish_name": "Crab Ravioli with Brown Butter Sage Sauce",
      "description": "Handmade ravioli stuffed with crab meat, served with brown butter and sage sauce",
      "ingredients": ["crab meat", "pasta dough", "brown butter", "sage", "parmesan"],
      "dish_category": "entree",
      "guy_response": "Oh my God, that is DYNAMITE!",
      "timestamp_start": 120.3,
      "confidence": 0.95
    }
  ],
  "confidence": 0.97
}
```

### Example 2: Ambiguous Audio

```json
{
  "name": null,
  "city": null,
  "state": null,
  "cuisine_type": "Seafood",
  "owner_chef": null,
  "guy_intro": null,
  "segment_number": 2,
  "timestamp_start": 480.0,
  "timestamp_end": null,
  "dishes": [
    {
      "dish_name": "Fish Tacos",
      "description": "Fish tacos described as incredible",
      "ingredients": ["fish", "tortilla"],
      "dish_category": "entree",
      "guy_response": null,
      "timestamp_start": 510.8,
      "confidence": 0.75
    }
  ],
  "confidence": 0.3
}
```

### Example 3: Multiple Dishes

```json
{
  "name": "Mama's Soul Food",
  "city": "Memphis",
  "state": "Tennessee",
  "cuisine_type": "Soul Food",
  "owner_chef": "Tyrone Washington",
  "guy_intro": "Here at Mama's Soul Food in Memphis, Tennessee, Chef Tyrone Washington has been serving up the real deal for over twenty years.",
  "segment_number": 1,
  "timestamp_start": 200.0,
  "timestamp_end": null,
  "dishes": [
    {
      "dish_name": "Famous Fried Chicken",
      "description": "Brined overnight in buttermilk, double-dredged in seasoned flour, deep fried",
      "ingredients": ["chicken", "buttermilk", "seasoned flour", "cayenne pepper"],
      "dish_category": "entree",
      "guy_response": "Now THAT is what I'm talking about!",
      "timestamp_start": 215.5,
      "confidence": 0.95
    },
    {
      "dish_name": "Five-Cheese Mac and Cheese",
      "description": "Five cheeses, baked until golden brown",
      "ingredients": ["elbow macaroni", "cheddar", "gruyere", "fontina", "parmesan", "cream cheese"],
      "dish_category": "side",
      "guy_response": "That's money right there!",
      "timestamp_start": 260.0,
      "confidence": 0.92
    },
    {
      "dish_name": "Peach Cobbler",
      "description": "Peach cobbler with butter crust",
      "ingredients": ["peaches", "butter", "cinnamon", "brown sugar", "pie crust"],
      "dish_category": "dessert",
      "guy_response": "That is OUT OF BOUNDS!",
      "timestamp_start": 280.0,
      "confidence": 0.95
    }
  ],
  "confidence": 0.96
}
```

## Important

- Return ONLY the JSON object. No markdown, no explanations, no preamble.
- If the transcript contains no restaurant visits, return:
  `{"video_id": "...", "restaurants": [], "error": "No restaurant visits detected"}`
```

---

## 9. Performance Estimates

Based on NZXT desktop (i9-13900K, 64GB RAM, RTX 2080 SUPER).

| Phase | Per-Video | Full Run (804 videos) | Notes |
|-------|-----------|----------------------|-------|
| 0 — Playlist dump | N/A | 5 min | Metadata only |
| 1 — Download | ~30 sec | ~8-12 hrs | YouTube throttling is the bottleneck |
| 2 — Transcribe | ~45s-20min (varies) | ~35-45 hrs | Mix of 10-min clips to 4-hr marathons. CUDA. |
| 3 — Extract | ~1.5-20min (varies) | ~45-55 hrs | Marathons take 15-20 min each |
| 4 — Normalize | N/A | ~1-2 hrs | Single batch, heavy dedup |
| 5 — Enrich | ~10 sec/restaurant | ~3-4 hrs | ~1,000-1,500 unique restaurants |
| **Total** | | **~95-120 hrs (4-5 days)** | **Unattended with resume support** |
