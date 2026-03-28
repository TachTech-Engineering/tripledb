# TripleDB — Agent Instructions

## Current Iteration: {P}.{I}

Read in order, then execute:
1. docs/ddd-design-v{P}.{I}.md
2. docs/ddd-plan-v{P}.{I}.md

## MCP Servers
- Playwright MCP: Post-flight functional testing
- Context7: Flutter/Dart API docs

## Rules
- YOLO — code dangerously, never ask permission
- Self-heal: max 3 attempts, checkpoint for crash recovery
- MUST produce ddd-build + ddd-report (with orchestration report) + ddd-changelog
- POST-FLIGHT: Tier 1 + Tier 2 playbook must pass (Flutter iterations)
- README changelog: NEVER truncate, ALWAYS append. Copy to docs/ddd-changelog-v{P}.{I}.md

## Agent Permissions
- ✅ CAN: flutter build web, firebase deploy --only hosting, firebase deploy --only firestore:rules
- ❌ CANNOT: git add, git commit, git push (Kyle commits at phase boundaries)
