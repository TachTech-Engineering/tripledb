# TripleDB App — Agent Instructions

## Current Iteration: 8.25

IMPORTANT: Read documents in this EXACT order before executing:

1. docs/ddd-design-v8.25.md — QA specification, targets, known issues
2. docs/ddd-plan-v8.25.md — QA execution steps
3. design-brief/design-tokens.json — Token values to verify against
4. design-brief/component-patterns.md — Widget specs to verify against

Do NOT begin execution until all 4 files have been read.

## Rules That Never Change
- Git READ commands allowed (pull, log, status, diff, show)
- Git WRITE commands forbidden (add, commit, push, checkout, branch)
- firebase deploy forbidden
- flutter build and flutter run ARE ALLOWED
- NEVER ask permission — auto-proceed on EVERY step
- MCP allowed: Playwright, Lighthouse, Context7. NOT Firecrawl.
- MUST produce ddd-build-v8.25.md AND ddd-report-v8.25.md before ending
- QA fixes allowed — fix issues found, log before/after
- Do NOT modify design tokens or component patterns
