Read these two documents in order, then execute the plan:

1. ../docs/ddd-design-v4.13.md — Architecture, methodology, locked decisions
2. ../docs/ddd-plan-v4.13.md — Pre-flight checklist and execution steps

Follow the autonomy rules defined in the plan. Begin with Step 0.

## Rules That Never Change
- NEVER run git, flutter, or firebase commands
- NEVER ask permission between steps — auto-proceed on EVERY step
- NEVER ask "should I continue?" or "would you like me to proceed?" — YES, ALWAYS
- If you find yourself typing a question mark, STOP. Re-read the plan. Execute.
- Self-heal errors: diagnose → fix → re-run (max 3 attempts, then skip)
- 3 consecutive identical errors = STOP, fix root cause, restart
- README.md update is the FINAL step — update ALL sections listed in Step 11
- All scripts run from this directory (pipeline/) as working directory
- Transcription MUST be launched with: LD_LIBRARY_PATH=/usr/local/lib/ollama/cuda_v12:$LD_LIBRARY_PATH
- Extraction uses Gemini 2.5 Flash API ($GEMINI_API_KEY), NOT local Ollama
- Prompts are LOCKED — do NOT modify extraction_prompt.md
- Run secret scan in pre-flight — HARD GATE, fix before proceeding
