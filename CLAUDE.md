# TripleDB - Agent Instructions

## Current Iteration: 10.44

Read in order, then execute:
1. docs/ddd-design-v10.44.md - Section 4 for env setup, Section 13 for formatting rules
2. docs/ddd-plan-v10.44.md

## MCP Servers
- Context7: Flutter/Dart API docs

## Testing
- Puppeteer (npm): Primary. If missing: cd /tmp && mkdir test && cd test && npm init -y && npm install puppeteer
- Browser targets: Chrome Stable + Firefox ESR only
- Playwright MCP: Fallback only

## Formatting
- NEVER use em-dashes. Use " - " (space-hyphen-space) instead.
- Use "->" for arrows, not unicode or "-->".
- See Section 13 for full rules.

## Rules
- YOLO - code dangerously, never ask permission
- Self-heal: max 3 attempts, checkpoint for crash recovery
- MUST produce ddd-build + ddd-report + ddd-changelog
- POST-FLIGHT: Tier 1 + Tier 2 (Flutter iterations)
- README changelog: NEVER truncate, ALWAYS append. Copy to docs/ddd-changelog-v10.44.md

## Agent Permissions
- CAN: flutter build web, firebase deploy, npm install (local), pip install
- CANNOT: sudo (ask Kyle), git add/commit/push (Kyle commits at phase boundaries)
- Sudo interventions do NOT count against zero-intervention target
