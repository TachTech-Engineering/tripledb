# TripleDB — Agent Instructions

## Current Iteration: 9.37

Read these two documents in order, then execute the plan:

1. docs/ddd-design-v9.37.md — Post-flight protocol, location-on-consent, changelog protection
2. docs/ddd-plan-v9.37.md — Execution steps

## MCP Servers Available
- Playwright MCP: Browser automation for post-flight verification
- Context7: Flutter/Dart docs for self-healing

## Rules That Never Change
- NEVER run git add, git commit, git push, or firebase deploy
- NEVER ask permission — auto-proceed on EVERY step
- Self-heal: diagnose → fix → re-run (max 3, then skip)
- MUST produce ddd-build-v9.37.md AND ddd-report-v9.37.md before ending
- CHECKPOINT after every numbered step
- README changelog: NEVER truncate — count must be ≥ 22
- POST-FLIGHT: MANDATORY for this iteration — must pass all gates
