# TripleDB - Agent Instructions

## Current Iteration: 10.46 (CAPSTONE)

Phase 10 Track C. Produce 4 deliverable artifacts. No Flutter code changes.

Read in order, then execute:
1. docs/ddd-design-v10.46.md - Sections 4-7 are the specs for each deliverable
2. docs/ddd-plan-v10.46.md - Execution steps

## Formatting
- NEVER use em-dashes. Use " - " (space-hyphen-space) instead.
- Use "->" for arrows, not unicode or "-->".
- See Section 9 for full rules.

## Rules
- YOLO - code dangerously, never ask permission
- MUST produce: ddd-design-uat.md, ddd-plan-uat-v0.1.md, iao-template-design-v0.1.md, iao-template-plan-v0.1.md
- MUST also produce: ddd-build, ddd-report, ddd-changelog, README update
- POST-FLIGHT: Tier 1 only (no Flutter code changes)
- README changelog: NEVER truncate, ALWAYS append, >= 31. Copy to docs/ddd-changelog-v10.46.md

## Agent Permissions
- CAN: read all files in repo, create new files in docs/
- CANNOT: modify app/ or pipeline/ code, sudo, git add/commit/push
