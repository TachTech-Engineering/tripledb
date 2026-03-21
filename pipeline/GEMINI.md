Before launching, update `pipeline/GEMINI.md` to:

```markdown
# TripleDB Pipeline — Agent Instructions

## Current Iteration: 3.12

Read these two documents in order, then execute the plan:

1. ../docs/ddd-design-v3.12.md — Architecture, methodology, locked decisions
2. ../docs/ddd-plan-v3.12.md — Pre-flight checklist and execution steps

Follow the autonomy rules defined in the plan. Begin with Step 0.

## Rules That Never Change
- NEVER run git commit, git push, or firebase deploy
- NEVER ask permission between steps — auto-proceed
- Self-heal errors: diagnose → fix → re-run (max 3 attempts, then skip)
- 3 consecutive identical errors = STOP, fix root cause, restart
- README.md update is the FINAL step of report generation — do not skip it
- All scripts run from this directory (pipeline/) as working directory
- Transcription MUST be launched with: LD_LIBRARY_PATH=/usr/local/lib/ollama/cuda_v12:$LD_LIBRARY_PATH
- Extraction uses Gemini 2.5 Flash API ($GEMINI_API_KEY), NOT local Ollama
