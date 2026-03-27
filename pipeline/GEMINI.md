# TripleDB Pipeline — Agent Instructions

## Current Iteration: 7.32

IMPORTANT: Read documents in this EXACT order before executing:

1. ../docs/ddd-design-v7.32.md — Architecture, v7.31 results, refinement strategy
2. ../docs/ddd-plan-v7.32.md — Refined search + LLM verification steps

Do NOT begin execution until both files have been read.

## Rules That Never Change
- Git READ commands allowed. Git WRITE commands and firebase deploy FORBIDDEN.
- flutter build web and flutter run ARE ALLOWED.
- NEVER ask permission — auto-proceed on EVERY step.
- Context7 MCP allowed. No other MCP servers.
- MUST produce ddd-build-v7.32.md AND ddd-report-v7.32.md before ending.
- ddd-build must be a FULL session transcript — not a summary.
- README.md is at PROJECT ROOT (~/dev/projects/tripledb/README.md).
- Pipeline scripts run from ~/dev/projects/tripledb/pipeline/.
- Flutter app runs from ~/dev/projects/tripledb/app/.
- $GOOGLE_PLACES_API_KEY and $GEMINI_API_KEY must be set.
  If not set, print the missing variable name and HALT. Do NOT ask interactively.
