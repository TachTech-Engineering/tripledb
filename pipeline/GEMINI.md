# TripleDB Pipeline — Agent Instructions

## Current Iteration: 7.30

Read these two documents in order, then execute the plan:

1. ../docs/ddd-design-v7.30.md — Architecture, methodology, locked decisions
2. ../docs/ddd-plan-v7.30.md — Pre-flight checklist and execution steps

Follow the autonomy rules defined in the plan. Begin with Step 0.

## Rules That Never Change
- Git READ commands allowed (pull, log, status, diff, show)
- Git WRITE commands forbidden (add, commit, push, checkout, branch)
- firebase deploy forbidden — Kyle deploys manually
- NEVER ask permission between steps — auto-proceed on EVERY step
- NEVER ask "should I continue?" or "would you like me to proceed?" — YES, ALWAYS
- If you find yourself typing a question mark, STOP. Re-read the plan. Execute.
- Self-heal errors: diagnose → fix → re-run (max 3 attempts, then skip)
- 3 consecutive identical errors = STOP, fix root cause, restart
- README.md update is the FINAL step — comprehensive, including IAO methodology
- All scripts run from this directory (pipeline/) as working directory
- Google Places API key: $GOOGLE_PLACES_API_KEY (never hardcode, never commit)
