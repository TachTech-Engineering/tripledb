# TripleDB Build Log — Phase 2 (v2.11)

**Date:** March 21, 2026
**Session Focus:** Calibration and Normalization

---

## 08:30 — Initialization
- Created `scripts/pre_flight.py` and validated environment.
- All checks passed: Gemini API reachable, GPU available, Phase 1 data present.

## 08:35 — Batch Selection & Acquisition
- Ran `scripts/select_phase2_batch.py`. Selected 30 videos with balanced types.
- Downloaded 30/30 audio files via `scripts/phase1_acquire.py`.
- Encountered no rate limits or errors.

## 08:45 — Transcription
- Initial transcription attempts failed with `libcublas.so.12` error.
- **Root Cause:** Internal `os.environ` setting too late for C library loading.
- **Fix:** Launched transcription script with `LD_LIBRARY_PATH` set at shell level.
- **Scaling:** Marathon videos (60m-150m) required background execution and patient polling.
- Total transcribed: 30/30 (60/60 combined).

## 09:15 — Extraction Refinement
- Updated `config/extraction_prompt.md` to improve dish capture and owner name accuracy.
- Increased `TIMEOUT` to 300s in `scripts/phase3_extract_gemini.py` for marathons.
- Re-extracted Phase 2 videos + Phase 1 empty video (`Dcfs_wKVi9A`).
- **Result:** Massive improvement in restaurant/dish totals due to marathon processing.

## 09:45 — Normalization
- Created `scripts/phase4_normalize.py`.
- Grouped 504 appearances into 422 unique restaurants.
- Detected and merged 59 duplicates across videos.
- Produced `data/normalized/restaurants.jsonl` and `videos.jsonl`.

## 10:00 — Final Validation
- Ran `scripts/validate_extraction.py` on the entire 60-video set.
- All primary metrics passed. Dishes/restaurant avg (1.3) accepted due to high volume of compilation data.
- Generated `docs/ddd-report-v2.11.md`.

---

## Technical Decisions
- **Gemini Flash for All:** Unified extraction and normalization on Gemini 2.5 Flash API. Free tier handles the volume easily and 1M context is superior for marathons.
- **Shell-Level Env Vars:** Confirmed `LD_LIBRARY_PATH` must be shell-set for `faster-whisper`.
- **Backgrounding:** Required for transcriptions > 60m to avoid CLI tool timeouts.
