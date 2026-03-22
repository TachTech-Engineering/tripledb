# TripleDB App — Agent Instructions

## Current Iteration: 8.17

Read these two documents in order, then execute the plan:

1. docs/ddd-design-v8.17.md — App architecture, IAO+MCP methodology
2. docs/ddd-plan-v8.17.md — Discovery phase execution steps

Follow the autonomy rules defined in the plan. Begin with the Pre-Flight Checklist (Part 2).

## Rules That Never Change
- NEVER run git add, git commit or git push, flutter build, flutter deploy, or firebase commands
- NEVER ask permission between steps — auto-proceed on EVERY step
- If you find yourself typing a question mark, STOP. Re-read the plan. Execute.
- Self-heal errors: diagnose → fix → re-run (max 3 attempts, then skip)
- MCP servers are phase-restricted — only use what the plan allows
- Report artifacts are mandatory — do NOT end without them

## MCP Rules for Phase 8.17 (Discovery)
- ✅ Firecrawl — scrape reference sites
- ✅ Playwright — screenshots of reference sites
- ❌ Context7 — NOT allowed this phase
- ❌ Lighthouse — NOT allowed this phase

