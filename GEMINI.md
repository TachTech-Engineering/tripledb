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
