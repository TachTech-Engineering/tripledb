# TripleDB App — Agent Instructions

## Current Iteration: 6.29

IMPORTANT: Read documents in this EXACT order before executing:

1. docs/ddd-design-v6.29.md — Current state, known issues, tech stack
2. docs/ddd-plan-v6.29.md — Polish execution steps

Do NOT begin execution until both files have been read.

## Rules That Never Change
- Git READ commands allowed (pull, log, status, diff, show)
- Git WRITE commands forbidden (add, commit, push, checkout, branch)
- firebase deploy forbidden — Kyle deploys manually
- flutter build web and flutter run ARE ALLOWED for testing
- NEVER ask permission — auto-proceed on EVERY step
- Context7 MCP allowed. No other MCP servers.
- MUST produce ddd-build-v6.29.md AND ddd-report-v6.29.md before ending
- Build on existing code — do NOT recreate the app scaffold
```
