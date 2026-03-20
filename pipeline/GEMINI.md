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
