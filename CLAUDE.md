# TripleDB - Agent Instructions

## Current Iteration: 10.45

Read in order, then execute:
1. docs/ddd-design-v10.45.md - Section 4 for env setup, Section 13 for formatting rules
2. docs/ddd-plan-v10.45.md

## MCP Servers
- Context7: Flutter/Dart API docs (use sparingly - try without it first)

## Testing
- Puppeteer (npm): Primary. If missing: cd /tmp && mkdir test && cd test && npm init -y && npm install puppeteer
- Browser targets: Chrome Stable + Firefox ESR only

## Formatting
- NEVER use em-dashes. Use " - " (space-hyphen-space) instead.
- Use "->" for arrows, not unicode or "-->".
- See Section 13 for full rules.

## Plan Quality (from retrospective)
- All env vars documented with exact names
- Hardware requirements validated in pre-flight
- API keys validated in pre-flight (not "set as needed")
- Every likely error has a documented response
- Success criteria are binary and automatable
- Post-flight tests are specific scripts
- Checkpoint strategy defined for long-running ops
- See docs/archive/ddd-retrospective-v10.44.md Section 4 for full 14-item checklist

## Rules
- YOLO - code dangerously, never ask permission
- Self-heal: max 3 attempts, checkpoint for crash recovery
- MUST produce ddd-build + ddd-report + ddd-changelog
- POST-FLIGHT: Tier 1 + Tier 2 (Flutter iterations)
- README changelog: NEVER truncate, ALWAYS append. Copy to docs/ddd-changelog-v10.45.md

## Agent Permissions
- CAN: flutter build web, firebase deploy, npm install (local), pip install
- CANNOT: sudo (ask Kyle), git add/commit/push (Kyle commits at phase boundaries)
- Sudo interventions do NOT count against zero-intervention target
