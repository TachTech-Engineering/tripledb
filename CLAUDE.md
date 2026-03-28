# TripleDB — Agent Instructions

## Current Iteration: 9.36

IMPORTANT: This iteration fixes a PRODUCTION CRASH. Priority 1 is getting tripledb.net loading again.

Read these two documents in order, then execute the plan:

1. docs/ddd-design-v9.36.md — White screen diagnosis, changelog spec
2. docs/ddd-plan-v9.36.md — Fix steps

## Rules That Never Change
- NEVER run git add, git commit, git push, or firebase deploy
- NEVER ask permission — auto-proceed on EVERY step
- Self-heal: diagnose → fix → re-run (max 3, then skip)
- 3 consecutive identical errors = STOP
- MUST produce ddd-build-v9.36.md AND ddd-report-v9.36.md before ending
- CHECKPOINT after every numbered step
- README.md is at project root
- CHANGELOG: NEVER truncate. ALWAYS append. Full history must be preserved.
