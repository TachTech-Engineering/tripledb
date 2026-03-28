# TripleDB — Agent Instructions

## Current Iteration: {P}.{I}

Read these two documents in order, then execute the plan:

1. docs/ddd-design-v{P}.{I}.md
2. docs/ddd-plan-v{P}.{I}.md

## MCP Servers
- Playwright MCP: Post-flight functional testing
- Context7: Flutter/Dart API docs

## Rules That Never Change
- NEVER run git add, git commit, git push, or firebase deploy
- NEVER ask permission — YOLO mode, code dangerously
- Self-heal: diagnose → fix → re-run (max 3, then skip)
- 3 consecutive identical errors = STOP
- MUST produce ddd-build and ddd-report before ending
- ddd-build must be FULL transcript
- CHECKPOINT after every numbered step
- README changelog: NEVER truncate — ALWAYS append
- POST-FLIGHT: Tier 1 + Tier 2 playbook must pass (if Flutter iteration)
- Include Orchestration Report in ddd-report
