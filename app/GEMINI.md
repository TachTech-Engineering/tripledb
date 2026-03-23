# TripleDB App — Agent Instructions

## Current Iteration: 8.22

Read these two documents in order, then execute the plan:

1. docs/ddd-design-v8.22.md — App architecture, methodology
2. docs/ddd-plan-v8.22.md — Discovery redo execution steps

Follow the autonomy rules defined in the plan. Begin with Step 0.

## Rules That Never Change
- NEVER run git or firebase deploy commands
- NEVER ask permission — auto-proceed on EVERY step
- If you find yourself typing a question mark, STOP. Re-read the plan. Execute.
- Self-heal errors: diagnose → fix → re-run (max 3 attempts, then skip)
- MCP servers are phase-restricted — only Firecrawl + Playwright this phase
- MUST produce ddd-build-v8.22.md AND ddd-report-v8.22.md before ending
- Build on existing code — do NOT recreate the app scaffold
- Do NOT modify any Flutter code this phase — Discovery only
