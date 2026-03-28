# TripleDB - Changelog v10.46

**v0.7 (Phase 0 - Setup)**
- Monorepo scaffolded with `pipeline/`, `app/`, and `docs/` directories.
- 805 YouTube playlist URLs collected. IAO methodology established.
- Learned: fish shell has no heredocs - use `printf` or `nano`.

**v1.8 (Phase 1 - Discovery, Attempt 1)**
- **Failure:** Nemotron 3 Super (120B, 42GB) could not run on 8GB VRAM RTX 2080 SUPER.
  Model spilled to CPU RAM, causing indefinite timeout loops during context pre-filling.

**v1.9 (Phase 1 - Discovery, Attempt 2)**
- **Pivot:** Swapped Nemotron for qwen3.5:9b. Added transcript chunking for 8K context window.
- Extraction still too slow - 5-10 minutes per video with frequent timeouts.

**v1.10 (Phase 1 - Discovery, Attempt 3)**
- **Pivot:** Shifted extraction to Gemini 2.5 Flash API (free tier, 1M token context).
- 93% extraction success rate. 186 restaurants, 290 dishes from 30 videos.

**v2.11 (Phase 2 - Calibration)**
- 60-video dataset: 422 unique restaurants, 624 dishes. Gemini Flash handles 200K-char transcripts.
- CUDA `LD_LIBRARY_PATH` must be set at shell level, not Python level.
- Marathon extraction timeout increased to 300 seconds.

**v3.12 (Phase 3 - Stress Test)**
- **Zero interventions** achieved for the first time. Autonomous batch healing.
- 511 restaurants, 896 dishes, 98 dedup merges. 4-hour marathon logged as edge case.

**v4.13 (Phase 4 - Validation)**
- 608 restaurants, 1,015 dishes, 162 dedup merges. Zero interventions.
- Extraction and normalization prompts locked for production. Group B green-lit.

**v5.14 (Phase 5 - Production Setup)**
- Fixed null-name restaurant merging bug (14 records collapsed into one entity).
- Built Group B runner: `group_b_runner.sh` + `checkpoint_report.py`.
- Hang detection: 600-second `signal.alarm` around `model.transcribe`.
- IAO Eight Pillars documented in README.

**v5.15 (Phase 5 - Production Run)**
- 14-hour unattended run via tmux. 778 downloaded, 774 transcribed, 773 extracted.
- 4 videos exceeded 600s timeout - skipped. Resume support confirmed.

**v6.26 (Phase 6 - Firestore Load)**
- 1,102 unique restaurants loaded to Firestore. State inference: UNKNOWN reduced from 126 to 33.
- App wired to Firestore. Search, trivia, and list views functional.

**v6.27 (Phase 6 - Geolocation Fix)**
- Fixed geolocation prompt but broke Firestore with temporary bypass. Reverted in v6.28.
- Downgraded geolocator to 10.x for Flutter compatibility.

**v6.28 (Phase 6 - Geocoding)**
- 916/1,102 restaurants geocoded via Nominatim at 1 req/sec. Map showing pins across the US.

**v8.17-v8.25 (Phase 8 - Flutter App)**
- Two-pass app build. Pass 1: scaffold + core features. Pass 2: design tokens, component patterns.
- DDD Red (#DD3333), Orange (#DA7E12), Outfit + Inter fonts. Lighthouse A11y 92, SEO 100.
- 3-tab bottom nav (Map/List/Explore), restaurant detail with YouTube deep links, dark mode.

**v6.29 (Phase 6 - Polish)**
- Trivia state count fixed (excludes UNKNOWN -> shows 62 states).
- Map pin clustering via `flutter_map_marker_cluster`. Orange clusters with counts.
- Explore page: multi-cuisine string splitting for accurate counts.

**v7.30 (Phase 7 - Enrichment Discovery)**
- Google Places API (New) enrichment pipeline built. 50-restaurant discovery batch.
- 66.7% match rate. 90% of matches rated 4.0+. 4 coordinate backfills. API cost: $0.

**v7.31 (Phase 7 - Enrichment Production)**
- Full run on 1,102 restaurants. 625 enriched at 55.9% match. 32 permanently closed identified.
- App UI: rating badges, open/closed status, website and Google Maps links.
- 1 intervention (API key not set in environment).

**v7.32 (Phase 7 - Enrichment Refinement)**
- Refined search on 462 no-match restaurants (4 query passes). 83 recovered, 18% recovery rate.
- Gemini Flash LLM verification: 112 confirmed, 126 false positives removed, 26 uncertain.
- Net enrichment: 582 verified. Geocoding coverage: 91.3%.

**v7.33 (Phase 7 - AKA Names + Closed UX)**
- `google_current_name` backfilled for all enriched restaurants. 283 genuine name changes.
- Grey map pins for closed restaurants. "Show closed" filter toggle. Closed banners on detail pages.
- "Now known as" display for renamed restaurants. Step-level checkpointing introduced.

**v7.34 (Phase 7 - Cookies + Analytics + Polish)**
- Cookie consent: accept/decline/customize with 3 categories. 365-day cookie, SameSite=Lax.
- Firebase Analytics with consent mode v2. Events gated by user consent.
- Name-change threshold tightened 0.95 -> 0.90 (86 reclassified, 279 genuine remain).
- 26 UNCERTAIN records resolved (15 kept, 11 removed).

**v9.35 (Phase 9 - App Optimization)**
- **Executor change:** Gemini CLI -> Claude Code.
- Riverpod 2.x -> 3.x migration. Geolocator 10.x -> 14.x upgrade.
- Trivia expanded from ~9 facts to 70-80+ with no-repeat shuffle system.
- "Nearby Restaurants": 15 results with distance in miles, "Show all nearby" -> 50.

**v9.36 (Phase 9 - Production Fix)**
- **CRITICAL:** Fixed white screen crash on tripledb.net caused by eager provider initialization
  in main() before runApp(). CookieConsentService constructor accessed dart:html document.cookie
  during Riverpod 3 provider graph construction, killing the app before Flutter could render.
- Fix: Removed ProviderContainer from main(), switched to standard ProviderScope with lazy
  providers. Made CookieConsentService lazy-initialized with try-catch fallback.
- Restored complete README changelog (v0.7-v9.36) - all 21 entries preserved.

**v9.37 (Phase 9 - Post-Flight Protocol + Location Consent)**
- **Post-Flight Protocol (Pillar 9):** Automated runtime verification using Puppeteer headless
  browser. 6 gates: bootstrap, navigation, features, cookies, console, changelog integrity.
- **Location on consent:** Accepting cookie preferences triggers browser geolocation permission.
- **Changelog gate:** Post-flight verifies README changelog entry count >= 22.

**v9.38 (Phase 9 - Cookie Banner Fix + Functional Post-Flight)**
- **Fix:** Conditional `Secure` flag (only on HTTPS), RFC 1123 date format for `expires`,
  `indexOf`-based cookie parsing instead of `split`.
- **Post-Flight v2:** Two-tier system. Tier 1: health gates. Tier 2: iteration-specific
  functional playbook. Cookie banner verified via 6-test playbook: all 6 PASS.

**v9.39 (Phase 9 - Nearby Filtering + Location Consent Fix)**
- 3 bug fixes: Unknown filter, dedup, location consent. Post-flight: 7/7 PASS.

**v9.40 (Phase 9 - dart:html Migration + Firestore Security Rules)**
- dart:html -> package:web migration. Firestore read-only rules deployed. Final dev iteration.

**v9.41 (Phase 9 - Nine Pillars + README Overhaul)**
- Methodology evolved from Eight to Nine Pillars. CLAUDE.md template v2 with permissions.

**v9.42 (Phase 9 - Hardening Audit)**
- Lighthouse baseline, error boundary testing (5/5 PASS), 6 security headers deployed.
- Versioned changelog introduced as 5th artifact.

**v9.43 (Phase 9 - Package Upgrades + Trivia + Preferences Fix)**
- flutter_map, go_router, google_fonts upgraded. 151 trivia facts. Firefox ESR testing added.

**v10.44 (Phase 10 - Retrospective)**
- Archive review across 43 iterations. 19 failure modes, 14-item plan quality checklist,
  10 lessons learned. Em-dash formatting rule established.

**v10.45 (Phase 10 - Technology Radar + README Overhaul)**
- 13 tools scored across 5 axes. 5 Adopt, 5 Trial, 2 Assess, 1 Hold.
- README pipeline overhaul with layered table. tmux visibility added throughout.

**v10.46 (Phase 10 - Track C Capstone)**
- **UAT handoff artifacts:** Produced ddd-design-uat.md and ddd-plan-uat-v0.1.md for Gemini CLI
  to replay the full TripleDB pipeline from scratch. Same Firebase project, hosting preview
  channel, no Firestore writes. Pipeline validated by JSONL diff against dev output.
- **IAO Project Template:** Produced iao-template-design-v0.1.md and iao-template-plan-v0.1.md -
  generic Nine Pillars framework for any new TachTech project. Includes plan quality checklist
  (14 items), failure mode catalog (19 modes), top 10 lessons. Quick start: 5 commands to scaffold.
- **Phase 10 complete.** Three tracks delivered across 3 iterations: Retrospective (v10.44),
  Technology Radar (v10.45), UAT Handoff + IAO Template (v10.46).
