# TripleDB — Agent Instructions

## Current Iteration: 9.41

Methodology update. Nine Pillars. No Flutter code changes.

Read in order, then execute:
1. docs/ddd-design-v9.41.md
2. docs/ddd-plan-v9.41.md

## MCP Servers
- Playwright MCP: Post-flight functional testing
- Context7: Flutter/Dart API docs

## Rules
- YOLO — code dangerously, never ask permission
- Self-heal: max 3 attempts, checkpoint for crash recovery
- MUST produce ddd-build + ddd-report (with orchestration report)
- POST-FLIGHT: Tier 1 only (no Flutter code changes this iteration)
- README changelog: NEVER truncate, ALWAYS append, ≥ 26 after update

## Agent Permissions
- ✅ CAN: flutter build web, firebase deploy --only hosting, firebase deploy --only firestore:rules
- ❌ CANNOT: git add, git commit, git push (Kyle commits at phase boundaries)
