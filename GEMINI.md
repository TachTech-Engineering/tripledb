# TripleDB — Agent Instructions

## Current Iteration: 7.34

IMPORTANT: Read documents in this EXACT order before executing:

1. ../docs/ddd-design-v7.34.md — Cookies, analytics, enrichment polish specs
2. ../docs/ddd-plan-v7.34.md — Execution steps

## Rules That Never Change
- Git READ allowed. Git WRITE and firebase deploy FORBIDDEN.
- flutter build web and flutter run ARE ALLOWED.
- NEVER ask permission — auto-proceed on EVERY step.
- Context7 MCP allowed. No other MCP servers.
- FULL PROJECT ACCESS under ~/dev/projects/tripledb/.
- MUST produce ddd-build-v7.34.md AND ddd-report-v7.34.md before ending.
- CHECKPOINT after every numbered step.
- README.md is at PROJECT ROOT.
- $GOOGLE_PLACES_API_KEY must be set. If not, print error and HALT.
- ddd-build must be FULL transcript.
