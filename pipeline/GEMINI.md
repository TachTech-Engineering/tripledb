# TripleDB Pipeline — Agent Instructions

## Current Iteration: 5.14

Read these two documents in order, then execute the plan:

1. ../docs/ddd-design-v5.14.md — Architecture, methodology, locked decisions
2. ../docs/ddd-plan-v5.14.md — Pre-flight checklist and execution steps

Follow the autonomy rules defined in the plan. Begin with Step 0.

## Rules That Never Change
- NEVER run git, flutter, or firebase commands
  (Exception: read-only git in pre-flight secret scan only)
- NEVER ask permission between steps — auto-proceed on EVERY step
- NEVER ask "should I continue?" or "would you like me to proceed?" — YES, ALWAYS
- If you find yourself typing a question mark, STOP. Re-read the plan. Execute.
- Self-heal errors: diagnose → fix → re-run (max 3 attempts, then skip)
- 3 consecutive identical errors = STOP, fix root cause, restart
- README.md update is the FINAL step — must include IAO methodology section
- All scripts run from this directory (pipeline/) as working directory
- Transcription: LD_LIBRARY_PATH=/usr/local/lib/ollama/cuda_v12:$LD_LIBRARY_PATH
- Extraction: Gemini 2.5 Flash API ($GEMINI_API_KEY), NOT local Ollama
- Prompts are LOCKED — do NOT modify extraction_prompt.md