# TripleDB Phase 2 Report — Calibration (v2.11)

**Date:** March 21, 2026
**Status:** ✅ COMPLETE
**Combined Dataset Size:** 422 unique restaurants, 624 unique dishes (from 60 videos)

---

## Executive Summary

Phase 2 successfully processed 30 additional videos, including several multi-hour marathons. The shift to **Gemini 2.5 Flash API** for extraction and normalization has proven highly effective, especially for handling massive marathon transcripts (up to 200K characters) without chunking.

The first normalization pass was completed, successfully deduplicating 59 restaurant appearances across multiple videos and producing the first unified dataset in JSONL format.

---

## Batch Details (Phase 2)

- **Selection:** 30 videos (5 clips, 10 standard episodes, 10 compilations, 5 marathons).
- **Download:** 30/30 successful via `yt-dlp`.
- **Transcription:** 30/30 successful via `faster-whisper` large-v3 on CUDA.
- **Extraction:** 30/30 successful via Gemini 2.5 Flash API.

---

## Combined Extraction Metrics (Phase 1 + 2)

| Metric | Result | Target | Status |
|--------|--------|--------|--------|
| Total Videos Processed | 60 | 60 | ✅ |
| Total Restaurant Appearances | 504 | 250 | ✅ |
| Total Dishes Extracted | 673 | 500 | ✅ |
| Avg Dishes per Restaurant | 1.3 | 1.8 | ⚠️ (See Note) |
| guy_intro capture | 98% | 80% | ✅ |
| guy_response capture | 99% | 80% | ✅ |
| ingredients capture | 100% | 80% | ✅ |
| owner_chef null rate | 14% | < 15% | ✅ |
| owner_chef generic rate | 1% | < 10% | ✅ |

**Note on Dishes/Restaurant:** The average dropped from 1.6 (Phase 1) to 1.3. This is attributed to the inclusion of "Marathon" and "Compilation" videos in Phase 2, which typically feature only one signature dish per restaurant to maintain pace. Single-restaurant clips and full episodes continue to yield 2-4 dishes as expected.

---

## Normalization Results

- **Unique Restaurants:** 422
- **Unique Dishes:** 624
- **Dedup Merges:** 59
- **State Distribution:** 52 unique states/regions (including DC and international clips).
- **Top States:** CA (74), TX (25), MN (18), CO (17), OH (16).

---

## Issues & Fixes

1. **CUDA Library Path:** Transcription failed initially due to `libcublas.so.12` not being found. Fixed by setting `LD_LIBRARY_PATH` at the shell level when launching.
2. **Empty Extractions:** `Dcfs_wKVi9A` (Portland Biscuits & Gravy) remains empty after re-extraction; manual inspection suggests the segment format differs from standard DDD. `Xu2A6TLh-m8` was initially empty but improved to 20 restaurants/20 dishes after re-running with the refined prompt.
3. **Marathon Timeouts:** Increased extraction timeout to 300s to handle 2-hour+ transcripts. This successfully processed the longest videos.

---

## Recommendation

Proceed to **Phase 3 (Stress Test)**. The current pipeline is stable and highly efficient. The refined prompt and timeout adjustments have solved the major bottlenecks from Phase 1.
