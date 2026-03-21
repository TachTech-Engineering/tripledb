# TripleDB Phase 1 (Iteration 8) - Execution Report

## Overview
- **Phase:** 1 — Discovery (Iteration 1.8)
- **Goal:** End-to-end validation of the pipeline on a 30-video test batch.
- **Result:** **INCOMPLETE / FAILED** at Phase 3 (Extraction).
- **Date:** March 20, 2026

## Successes
- **Phase 1 (Acquisition)**: 100% success. `yt-dlp` successfully downloaded all 30 test batch videos. 
  - *Issue Resolved:* Encountered YouTube JS challenge failures. Resolved by adding `--remote-components ejs:github` to the yt-dlp arguments.
  - *Time Spent:* ~20 minutes.
- **Phase 2 (Transcription)**: 100% success. `faster-whisper` (large-v3) transcribed all 30 videos. 
  - *Issue Resolved:* Script initially crashed due to a missing `libcublas.so.12` library. Resolved by dynamically preloading Ollama's bundled CUDA path (`LD_LIBRARY_PATH=/usr/local/lib/ollama/cuda_v12`).
  - *Quality Check:* Spot checks on clips, standard episodes, and a 4-hour marathon showed excellent segmentation and 0% low-confidence segments.
  - *Time Spent:* ~2.5 hours.

## Problems & Loops (Phase 3 - Extraction)
Phase 3 suffered from critical hardware/model mismatch issues leading to an indefinite timeout and hanging loop.

1. **Model Size vs. Hardware:** The `GEMINI.md` architecture specified `Nemotron 3 Super` (a 120B parameter MoE model, ~42GB footprint) for extraction. The available hardware is an RTX 2080 Super with 8GB VRAM. The model spilled entirely into system RAM, resulting in CPU-bound inference.
2. **Timeout Loops:** Due to CPU inference, pre-filling a large context window (e.g., 32k tokens) for standard and marathon transcripts took longer than the python `requests` timeout and longer than the Gemini CLI tool execution limit (5 minutes). This caused repeated cancellation loops.
3. **Model Swapping (`qwen3.5:9b`):** We attempted to switch to `qwen3.5:9b`, which fits inside the 8GB VRAM. However, processing long transcripts with a 32k context window still caused severe memory pressure and hanging.
4. **JSON Output Failures:** When the model did manage a response early in testing, it output conversational text and markdown instead of strict JSON, causing validation failures. We attempted to enforce `format: "json"` via the Ollama API.
5. **Context Reduction & Chunking Fixes Applied:** 
   - Slimmed down the `extraction_prompt.md` by removing few-shot examples (~3000 tokens saved).
   - Implemented a chunking mechanism in `phase3_extract.py` to split transcripts > 12,000 characters at natural pauses (>5s).
   - Reduced `num_ctx` to 16384 and set the timeout to 600s.
6. **Final Hang:** Even after applying the chunking and prompt fixes, the `qwen3.5:9b` model hung indefinitely on the first chunk of the shortest clip (`BwfqvpCAdeQ`), indicating a potential deeper issue with the Ollama service state, VRAM fragmentation, or context allocation on this specific machine state.

## Time & Utilization Summary
- **Phase 1 (Download):** ~20 mins.
- **Phase 2 (Transcription):** ~2.5 hours.
- **Phase 3 (Extraction):** ~3+ hours (Spent troubleshooting timeouts, VRAM limits, and prompt chunking).
- **Agent Utilization:** High utilization during script authoring and debugging. Background tasks were used heavily to bypass the 5-minute interactive shell limits.

## Recommendations for Plan v1.9
To successfully execute Phase 1.9, the following architectural and script changes must be carried forward:

1. **Permanently Adopt Qwen:** `qwen3.5:9b` (or a similar <8GB model like `llama3:8b`) must be the official Extraction LLM. `Nemotron 3 Super` is fundamentally incompatible with the current hardware constraints.
2. **Strict Context Limits:** Hardcap the Ollama `num_ctx` to `8192` to guarantee it stays within the RTX 2080's VRAM. 
3. **Refine Chunking:** The chunking logic added to `phase3_extract.py` is essential. Ensure chunks are strictly sized to leave at least 2048 tokens free for the JSON generation response.
4. **Streaming Output:** Modify the `phase3_extract.py` script to use `stream: True` when calling the Ollama API, writing the output to a buffer. This will immediately show if the model is actually generating tokens or if the system is hung in the pre-fill stage.
5. **System Health:** Before starting v1.9, completely restart the Ollama service (`systemctl --user restart ollama` or equivalent) to clear any fragmented VRAM/RAM states left over from the v1.8 crash loops.