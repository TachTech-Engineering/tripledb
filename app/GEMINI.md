# TripleDB App — Agent Instructions

## Current Iteration: 8.24

IMPORTANT: Read documents in this EXACT order before executing:

1. docs/ddd-design-v8.24.md — Architecture, gap analysis, widget tree
2. docs/ddd-plan-v8.24.md — Implementation execution steps
3. design-brief/design-tokens.json — Color, typography, spacing tokens
4. design-brief/design-brief.md — Creative direction and aesthetic rules
5. design-brief/component-patterns.md — Widget composition blueprints

Do NOT begin execution until all 5 files have been read.

## Rules That Never Change
- Git READ commands allowed (pull, log, status, diff, show)
- Git WRITE commands forbidden (add, commit, push, checkout, branch)
- firebase deploy forbidden
- flutter build and flutter run ARE ALLOWED for testing
- NEVER ask permission — auto-proceed on EVERY step
- Context7 MCP allowed for Flutter/Dart docs. No other MCP servers.
- MUST produce ddd-build-v8.24.md AND ddd-report-v8.24.md before ending
- Every code change must trace to a design token or component pattern
- Build on existing code — do NOT recreate the app scaffold
