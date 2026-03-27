# TripleDB — Agent Instructions

## Current Iteration: 7.33

IMPORTANT: Read documents in this EXACT order before executing:

1. ../docs/ddd-design-v7.33.md — Architecture, AKA field, closed UX, checkpoint protocol
2. ../docs/ddd-plan-v7.33.md — Execution steps

Do NOT begin execution until both files have been read.

## Rules That Never Change
- Git READ commands allowed. Git WRITE commands and firebase deploy FORBIDDEN.
- flutter build web and flutter run ARE ALLOWED.
- NEVER ask permission — auto-proceed on EVERY step.
- Context7 MCP allowed. No other MCP servers.
- MUST produce ddd-build-v7.33.md AND ddd-report-v7.33.md before ending.
- ddd-build must be a FULL session transcript — not a summary.
- README.md is at PROJECT ROOT (~/dev/projects/tripledb/README.md).
- FULL PROJECT ACCESS: agent can read/write ANYWHERE under ~/dev/projects/tripledb/.
- $GOOGLE_PLACES_API_KEY must be set. If not, print error and HALT.
- CHECKPOINT after every numbered plan step. Write to pipeline/data/checkpoints/.
- NEVER overwrite the `name` field on restaurant documents.
