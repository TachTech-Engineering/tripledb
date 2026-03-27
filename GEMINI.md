# TripleDB — Agent Instructions

## Current Iteration: 6.26

IMPORTANT: Read documents in this EXACT order before executing:

1. docs/ddd-design-v6.26.md — Architecture, Firestore schema, state inference
2. docs/ddd-plan-v6.26.md — Execution steps

Do NOT begin execution until both files have been read.

## Rules That Never Change
- Git READ commands allowed (pull, log, status, diff, show)
- Git WRITE commands forbidden (add, commit, push, checkout, branch)
- firebase deploy forbidden — Kyle deploys manually
- flutter build web IS ALLOWED for testing
- NEVER ask permission — auto-proceed on EVERY step
- Context7 MCP allowed. No other MCP servers.
- MUST produce ddd-build-v6.26.md AND ddd-report-v6.26.md before ending
- This iteration spans pipeline/ AND app/ directories
