# TripleDB — Complete Changelog (v0.7 → v9.35)

This is the authoritative changelog. Every iteration plan must APPEND to this list. Never truncate or replace previous entries.

---

**v0.7 (Phase 0 — Setup)**
- Monorepo scaffolded with `pipeline/`, `app/`, and `docs/` directories.
- 805 YouTube playlist URLs collected and stored in `config/playlist_urls.txt`.
- IAO methodology established: plan-report loop, GEMINI.md version lock.
- Learned: fish shell has no heredocs — use `printf` or `nano`.

**v1.8 (Phase 1 — Discovery, Attempt 1)**
- **Failure:** Nemotron 3 Super (120B, 42GB) could not run on 8GB VRAM RTX 2080 SUPER. Model spilled to CPU RAM, causing indefinite timeout loops during context pre-filling.
- Acquisition (Phase 1) and Transcription (Phase 2) confirmed stable.

**v1.9 (Phase 1 — Discovery, Attempt 2)**
- **Pivot:** Swapped Nemotron for `qwen3.5:9b` (lighter model). Added transcript chunking for 8K context window.
- **Result:** Extraction still too slow — 5-10 minutes per video with frequent timeouts on longer episodes.

**v1.10 (Phase 1 — Discovery, Attempt 3)**
- **Pivot:** Shifted extraction to Gemini 2.5 Flash API (free tier, 1M token context). Eliminated chunking entirely.
- **Result:** 93% extraction success rate across 30-video test batch. 186 restaurants, 290 dishes extracted.
- 20+ human interventions — each analyzed and pre-answered in subsequent plans.

**v2.11 (Phase 2 — Calibration)**
- Normalized and deduplicated 60-video dataset via Gemini Flash API. 422 unique restaurants, 624 dishes.
- **Challenge:** `faster-whisper` failed due to `libcublas.so.12` missing at runtime. `LD_LIBRARY_PATH` must be set at shell level, not Python level.
- **Pivot:** Marathon extraction timeout increased to 300 seconds. Gemini Flash handles 200K-character transcripts without chunking.
- 20+ interventions — CUDA path and marathon timeouts were the main causes.

**v3.12 (Phase 3 — Stress Test)**
- **Zero interventions achieved** for the first time. Autonomous batch healing: swapped 8 un-transcribed marathons for clips to stay within session limits.
- 31 videos processed (marathon-heavy batch). 511 unique restaurants, 896 dishes, 98 dedup merges.
- 4-hour marathon `bawGcAsAA-w` exceeded Gemini output limits — logged as accepted edge case.
- GPU contention self-healed: killed orphaned 4GB Python process blocking CUDA.

**v4.13 (Phase 4 — Validation)**
- 30 more videos (including 4 marathons). 608 unique restaurants, 1,015 dishes, 162 dedup merges.
- **Zero interventions.** Extraction prompt and normalization prompt locked for production.
- Group B readiness assessment: all 10 criteria passed. Green-lit for unattended production run.
- Owner/chef null rate dropped below 15% target (11.7%).

**v5.14 (Phase 5 — Production Setup)**
- Fixed null-name restaurant merging bug (14 records were being collapsed into one entity).
- Built Group B runner infrastructure: `group_b_runner.sh` for tmux, `checkpoint_report.py` for progress.
- Verified `--all` mode and resume support across all pipeline scripts.
- Injected 600-second `signal.alarm` around `model.transcribe` for hang detection.
- 5-video test batch validated end-to-end through the runner.
- Documented IAO methodology as "Eight Pillars" in README.

**v5.15 (Phase 5 — Production Run)**
- 14-hour unattended production run via tmux. 778 downloaded, 774 transcribed, 773 extracted.
- Resume support confirmed: runner picked up where it left off after an interrupted test.
- 4 videos exceeded 600s transcription timeout — logged and skipped.

**v6.26 (Phase 6 — Firestore Load)**
- 1,102 unique restaurants loaded to Cloud Firestore. State inference reduced UNKNOWN from 126 to 33.
- Flutter app wired to Firestore data source. Search, trivia, and list views functional.

**v6.27 (Phase 6 — Geolocation Fix)**
- Fixed geolocation prompt but broke Firestore connectivity with a temporary bypass.
- Downgraded geolocator to 10.x for Flutter 3.11 compatibility.
- Reverted Firestore bypass in v6.28.

**v6.28 (Phase 6 — Geocoding)**
- 916/1,102 restaurants geocoded via Nominatim (OpenStreetMap) at 1 req/sec.
- Firestore restored and verified. Map showing pins across the US.
- Geocode cache implemented to avoid redundant API calls.

**v8.17–v8.21 (Phase 8 — Flutter App, Pass 1)**
- Scraped 4 reference restaurant finder sites for design inspiration.
- Design tokens produced. App scaffold built with search, trivia, map, and nearby features.
- QA was thin — Lighthouse skipped, no build logs for v8.17–v8.20.

**v8.22–v8.25 (Phase 8 — Flutter App, Pass 2)**
- Proper scrapes with Playwright fallback (4/4 sites, cookie workarounds).
- Full design contract: DDD Red (#DD3333), Orange (#DA7E12), Outfit + Inter fonts.
- 14 files modified implementing all 8 component patterns from design brief.
- Lighthouse: Accessibility 92, SEO 100. Playwright screenshots. 3 bugs found and fixed.

**v6.29 (Phase 6 — Polish)**
- Fixed trivia state count: excluded "UNKNOWN" states, now correctly shows 62.
- Added map pin clustering via `flutter_map_marker_cluster`. Orange cluster bubbles with counts.
- Updated Explore page to split multi-cuisine strings for accurate counts.
- README comprehensively updated with IAO Eight Pillars and full iteration history.

**v7.30 (Phase 7 — Enrichment Discovery)**
- Built Google Places API (New) enrichment pipeline: Text Search → Place Details flow.
- 50-restaurant discovery batch: 66.7% match rate. 63.3% of matches scored ≥ 0.90.
- 4 coordinate backfills from Google where Nominatim had failed.
- 90% of matched restaurants rated 4.0+ on Google. 1 permanently closed identified.
- API cost: $0 (free tier). Fuzzy match validation with auto-accept/review/reject tiers.

**v7.31 (Phase 7 — Enrichment Production)**
- Full enrichment run on all 1,102 restaurants. 625 enriched at 55.9% match rate.
- 32 permanently closed restaurants identified. 8 coordinate backfills.
- Firestore merge updates verified: enrichment fields added, existing data preserved.
- Flutter app updated: ratings badges, open/closed status, website/Google Maps links.
- 1 human intervention: GOOGLE_PLACES_API_KEY was not set in environment.

**v7.32 (Phase 7 — Enrichment Refinement)**
- **Part A:** Refined search on 462 no-match restaurants. 4 query passes (exact name, owner/chef, cuisine, DDD keywords). 83 newly matched, 18% recovery rate.
- **Part B:** Gemini Flash LLM verification of 253 review-bucket matches. 112 confirmed (YES), 126 false positives removed (NO), 26 uncertain (kept, flagged).
- Enriched count adjusted: 625 → 582 (net decrease due to false positive cleanup).
- Geocoding coverage improved to 91.3% (1,006/1,102).

**v7.33 (Phase 7 — AKA Names + Closed Restaurant UX)**
- Backfilled `google_current_name` for all enriched restaurants via Places API `displayName`.
- 283 genuine name changes identified in verified set (threshold: 0.95 similarity).
- Grey map pins (#888888) for closed restaurants. "Show closed" filter toggle.
- "Permanently Closed" banners on cards and detail pages. Closed excluded from "Near You."
- "Now known as" display for renamed restaurants. Both names searchable.
- Step-level checkpointing protocol implemented for crash recovery.

**v7.34 (Phase 7 — Cookies + Analytics + Enrichment Polish)**
- GDPR/CCPA-compliant cookie consent system: accept/decline/customize with 3 categories (Essential, Analytics, Preferences). 365-day browser cookie with SameSite=Lax.
- Firebase Analytics integrated with consent mode v2. Events: page_view, search, view_restaurant, filter_toggle, external_link, consent_given. All gated by user consent.
- Name-change threshold tightened from 0.95 to 0.90: 86 records reclassified, 279 genuine rebrands remain.
- 26 UNCERTAIN records resolved: 15 kept (score ≥ 0.80), 11 removed.
- Enrichment logs consolidated into `phase7-enrichment-summary.json`.

**v9.35 (Phase 9 — App Optimization)**
- **Executor change:** Gemini CLI → Claude Code. First iteration with new executor.
- **Riverpod 2.x → 3.x:** `flutter_riverpod` 2.6.1 → 3.3.1, `riverpod_annotation` 4.0.2, `riverpod_generator` 4.0.3. All StateProvider eliminated. Zero legacy imports remaining.
- **Geolocator 10.x → 14.x:** Updated `getCurrentPosition()` to `LocationSettings` API.
- **Trivia:** Expanded from ~9 facts to 70-80+. Dynamic generation from dataset (40-50 computed facts) + 15 curated Guy Fieri/show facts. Shuffle-based no-repeat system with "Fact X of Y" counter.
- **Proximity:** "Top 3 Near You" → "Nearby Restaurants" showing 15 with distance in miles. "Show all nearby" expands to 50. Search results sorted by proximity as tiebreaker.
- Zero self-heal cycles. Zero human interventions.
