# TripleDB

**Every restaurant from Diners, Drive-Ins and Dives — structured, searchable, and mapped.**

TripleDB processes 805 YouTube videos from Guy Fieri's "Diners, Drive-Ins and Dives" (DDD) into a structured Firestore database of restaurants, dishes, ingredients, and iconic Guy Fieri moments. The name is a triple play: **Triple D** (the show's nickname) + **DB** (database).

🌐 **[tripledb.net](https://tripledb.net)** · 📂 **39 iterations** · 🔧 **Status: Live + Optimized**

---

## What This Builds

A searchable database and Flutter Web app where you can:

- **Find a diner near you** — share your location or enter a zip code
- **Search by anything** — dish name, cuisine type, city, chef, ingredients ("ground beef" → hamburgers, meatloaf, etc.)
- **Watch the moment** — deep link to the exact YouTube timestamp where Guy walks into the restaurant
- **Query Guy's greatest hits** — how many times has he said "That's out of bounds!"?

---

## Methodology: Iterative Agentic Orchestration (IAO)

TripleDB is built using **Iterative Agentic Orchestration (IAO)** — a development
methodology where LLM agents execute pipeline phases autonomously while humans
review versioned artifacts between iterations. IAO emerged through 35 iterations
of this project and is now a repeatable framework for building data pipelines
with agentic assistance.

### The Nine Pillars

1. **Plan-Report Loop** — Every iteration starts with a design doc + plan doc
   and produces a build log + report. The four artifacts are the complete record.
   Any new agent or human can reconstruct the full project history from docs alone.

2. **Zero-Intervention Target** — Every question the agent asks during execution
   is a failure in the plan. Pre-answer every decision point. Measure plan quality
   by counting interventions.

3. **Self-Healing Loops** — Errors are inevitable. Diagnose → fix → re-run (max
   3 attempts). 3 consecutive identical errors = stop and fix root cause. Never
   burn through hundreds of items with a known systemic failure.

4. **Versioned Artifacts as Source of Truth** — CLAUDE.md is the version lock.
   Git commits mark iteration boundaries. The launch command never changes:
   `claude` → "Read CLAUDE.md and execute."

5. **Artifacts Travel Forward** — Current docs in `docs/`, previous in
   `docs/archive/`. The design doc accumulates (additive). The plan doc is
   fresh each time (disposable). Agents never see outdated instructions.

6. **Methodology Co-Evolution** — IAO itself evolves through the Plan-Report
   loop. Error taxonomies, autonomy rules, pre-flight checks — all born from
   specific failures and refined through subsequent iterations.

7. **Separation of Interactive and Unattended** — Group A (iterative refinement)
   uses an LLM orchestrator. Group B (production) uses hardened bash scripts.
   The right tool for tuning is the wrong tool for a 70-hour unattended run.

8. **Progressive Trust Through Graduated Batches** — 30 → 60 → 90 → 120 videos.
   Each batch is bigger and harder. By Phase 4, the pipeline ran with zero
   interventions on batches including 4-hour marathons. Confidence was earned.

9. **Post-Flight Verification** — Two-tier system. Tier 1: health gates (app
   bootstraps, console clean, changelog integrity). Tier 2: iteration-specific
   functional playbook — Puppeteer clicks buttons, verifies state changes,
   confirms persistence. Canvas screenshots replaced with accessibility tree
   verification. Born from v9.35's white-screen and v9.37's screenshot-only gap.

### Iteration History

| Iteration | Phase | Status | Key Learning |
|-----------|-------|--------|--------------|
| v0.7 | Setup | ✅ | Monorepo scaffolded. fish shell has no heredocs. |
| v1.10 | Discovery | ✅ | Gemini 2.5 Flash API solved extraction. |
| v4.13 | Validation | ✅ | 608 restaurants, 162 merges. Group B green-lit. |
| v5.15 | Production | ✅ | 773 videos extracted. 14-hour unattended run. |
| v6.26 | Firestore | ✅ | 1,102 restaurants loaded. App wired to Firestore. |
| v6.29 | Polish | ✅ | Trivia fix, map clustering, README refresh. |
| v7.30 | Enrichment Disc. | ✅ | Google Places API pipeline. 50-restaurant batch. |
| v7.31 | Enrichment Prod. | ✅ | Full run on 1,102 restaurants. 625 enriched. |
| v7.32 | Enrichment Ref. | ✅ | Refined search recovered 83 more. 126 false pos removed. |
| v7.33 | AKA + Closed UX | ✅ | "Now known as" labels, grey map pins, closed filter. |
| v7.34 | Cookies + Analytics | ✅ | Cookie consent, Firebase Analytics, enrichment polish. |
| v9.35 | App Optimization | ✅ | Riverpod 2→3, 75+ trivia facts, proximity refactor. First Claude Code iteration. |
| v9.36 | Production Fix | ✅ | Fixed white screen crash (eager provider init before runApp). Changelog restored. |
| v9.37 | Post-Flight + Location | ✅ | Post-flight protocol (Pillar 9), location-on-consent, changelog gate. |
| v9.38 | Cookie Banner Fix | ✅ | Cookie Secure flag + RFC 1123 expires + robust parsing. Functional playbook. |

---

## Architecture

```
YouTube Playlist (805 videos)
    ↓ yt-dlp (local)
MP3 Audio
    ↓ faster-whisper large-v3 (local CUDA)
Timestamped Transcripts
    ↓ Gemini 2.5 Flash API (cloud)
Extracted Restaurant JSON
    ↓ Gemini 2.5 Flash API (cloud)
Normalized + Deduplicated JSONL
    ↓ Nominatim (OpenStreetMap)
Geocoded Data
    ↓ Google Places API (New)
Enriched Data (ratings, open/closed, websites, addresses)
    ↓ Firebase Admin SDK
Cloud Firestore
    ↓ Flutter Web
tripledb.net
```

---

## Project Status

| Phase | Name | Status | Iteration |
|-------|------|--------|-----------|
| 0 | Setup & Scaffolding | ✅ Complete | v0.7 |
| 1 | Discovery (30 videos) | ✅ Complete | v1.10 |
| 2 | Calibration (30 videos) | ✅ Complete | v2.11 |
| 3 | Stress Test (30 videos) | ✅ Complete | v3.12 |
| 4 | Validation (30 videos) | ✅ Complete | v4.13 |
| 5 | Production Run (805 videos) | ✅ Complete | v5.14–v5.15 |
| 6 | Firestore + Geocoding + Polish | ✅ Complete | v6.26–v6.29 |
| 8 | Flutter App | ✅ Complete | v8.17–v8.25 |
| 7 | Enrichment + Analytics | ✅ Complete | v7.30–v7.34 |
| 9 | App Optimization | ✅ Complete | v9.35–v9.37 |

---

## Tech Stack

| Component | Tool | Purpose |
|-----------|------|---------|
| Transcription | faster-whisper (CUDA) | mp3 → timestamped JSON |
| Extraction | Gemini 2.5 Flash API | Transcript → restaurant JSON |
| Normalization | Gemini 2.5 Flash API | Dedupe, validate, schema-conform |
| Database | Cloud Firestore | Live data serving |
| Enrichment | Google Places API (New) | Ratings, status, websites, addresses |
| State Management | flutter_riverpod 3.x | Migrated from 2.x in v9.35 |
| Geolocation | geolocator 14.x | Upgraded from 10.x in v9.35 |
| Frontend | Flutter Web + Riverpod | tripledb.net |
| Analytics | Firebase Analytics | Page views, search, restaurant views (consent-gated) |
| Privacy | Custom cookie consent | GDPR/CCPA-compliant, 3 categories, 365-day cookie |
| Orchestration | Claude Code (v9.35+), Gemini CLI (v0.7–v7.34) | Agentic execution |

---

## Current Metrics

### Live Dataset (tripledb.net)
- **1,102** unique restaurants across **62** states and territories
- **697** restaurants enriched with Google ratings and open/closed status
- **279** genuine name changes displayed (tightened 0.90 threshold)
- **34** permanently closed restaurants identified
- **1,006** restaurants with map coordinates (91.3%)
- **Cookie consent** with accept/deny/customize
- **Firebase Analytics** with consent mode v2
- **75+** rotating trivia facts with no-repeat system
- **15** nearby restaurants shown (proximity-sorted, expandable)

---

## Changelog

**v0.7 (Phase 0 — Setup)**
- Monorepo scaffolded with `pipeline/`, `app/`, and `docs/` directories.
- 805 YouTube playlist URLs collected. IAO methodology established.
- Learned: fish shell has no heredocs — use `printf` or `nano`.

**v1.8 (Phase 1 — Discovery, Attempt 1)**
- **Failure:** Nemotron 3 Super (120B, 42GB) could not run on 8GB VRAM RTX 2080 SUPER.
  Model spilled to CPU RAM, causing indefinite timeout loops during context pre-filling.

**v1.9 (Phase 1 — Discovery, Attempt 2)**
- **Pivot:** Swapped Nemotron for qwen3.5:9b. Added transcript chunking for 8K context window.
- Extraction still too slow — 5-10 minutes per video with frequent timeouts.

**v1.10 (Phase 1 — Discovery, Attempt 3)**
- **Pivot:** Shifted extraction to Gemini 2.5 Flash API (free tier, 1M token context).
- 93% extraction success rate. 186 restaurants, 290 dishes from 30 videos.

**v2.11 (Phase 2 — Calibration)**
- 60-video dataset: 422 unique restaurants, 624 dishes. Gemini Flash handles 200K-char transcripts.
- CUDA `LD_LIBRARY_PATH` must be set at shell level, not Python level.
- Marathon extraction timeout increased to 300 seconds.

**v3.12 (Phase 3 — Stress Test)**
- **Zero interventions** achieved for the first time. Autonomous batch healing.
- 511 restaurants, 896 dishes, 98 dedup merges. 4-hour marathon logged as edge case.

**v4.13 (Phase 4 — Validation)**
- 608 restaurants, 1,015 dishes, 162 dedup merges. Zero interventions.
- Extraction and normalization prompts locked for production. Group B green-lit.

**v5.14 (Phase 5 — Production Setup)**
- Fixed null-name restaurant merging bug (14 records collapsed into one entity).
- Built Group B runner: `group_b_runner.sh` + `checkpoint_report.py`.
- Hang detection: 600-second `signal.alarm` around `model.transcribe`.
- IAO Eight Pillars documented in README.

**v5.15 (Phase 5 — Production Run)**
- 14-hour unattended run via tmux. 778 downloaded, 774 transcribed, 773 extracted.
- 4 videos exceeded 600s timeout — skipped. Resume support confirmed.

**v6.26 (Phase 6 — Firestore Load)**
- 1,102 unique restaurants loaded to Firestore. State inference: UNKNOWN reduced from 126 to 33.
- App wired to Firestore. Search, trivia, and list views functional.

**v6.27 (Phase 6 — Geolocation Fix)**
- Fixed geolocation prompt but broke Firestore with temporary bypass. Reverted in v6.28.
- Downgraded geolocator to 10.x for Flutter compatibility.

**v6.28 (Phase 6 — Geocoding)**
- 916/1,102 restaurants geocoded via Nominatim at 1 req/sec. Map showing pins across the US.

**v8.17–v8.25 (Phase 8 — Flutter App)**
- Two-pass app build. Pass 1: scaffold + core features. Pass 2: design tokens, component patterns.
- DDD Red (#DD3333), Orange (#DA7E12), Outfit + Inter fonts. Lighthouse A11y 92, SEO 100.
- 3-tab bottom nav (Map/List/Explore), restaurant detail with YouTube deep links, dark mode.

**v6.29 (Phase 6 — Polish)**
- Trivia state count fixed (excludes UNKNOWN → shows 62 states).
- Map pin clustering via `flutter_map_marker_cluster`. Orange clusters with counts.
- Explore page: multi-cuisine string splitting for accurate counts.

**v7.30 (Phase 7 — Enrichment Discovery)**
- Google Places API (New) enrichment pipeline built. 50-restaurant discovery batch.
- 66.7% match rate. 90% of matches rated 4.0+. 4 coordinate backfills. API cost: $0.

**v7.31 (Phase 7 — Enrichment Production)**
- Full run on 1,102 restaurants. 625 enriched at 55.9% match. 32 permanently closed identified.
- App UI: rating badges, open/closed status, website and Google Maps links.
- 1 intervention (API key not set in environment).

**v7.32 (Phase 7 — Enrichment Refinement)**
- Refined search on 462 no-match restaurants (4 query passes). 83 recovered, 18% recovery rate.
- Gemini Flash LLM verification: 112 confirmed, 126 false positives removed, 26 uncertain.
- Net enrichment: 582 verified. Geocoding coverage: 91.3%.

**v7.33 (Phase 7 — AKA Names + Closed UX)**
- `google_current_name` backfilled for all enriched restaurants. 283 genuine name changes.
- Grey map pins for closed restaurants. "Show closed" filter toggle. Closed banners on detail pages.
- "Now known as" display for renamed restaurants. Step-level checkpointing introduced.

**v7.34 (Phase 7 — Cookies + Analytics + Polish)**
- Cookie consent: accept/decline/customize with 3 categories. 365-day cookie, SameSite=Lax.
- Firebase Analytics with consent mode v2. Events gated by user consent.
- Name-change threshold tightened 0.95 → 0.90 (86 reclassified, 279 genuine remain).
- 26 UNCERTAIN records resolved (15 kept, 11 removed).

**v9.35 (Phase 9 — App Optimization)**
- **Executor change:** Gemini CLI → Claude Code.
- Riverpod 2.x → 3.x migration. Geolocator 10.x → 14.x upgrade.
- Trivia expanded from ~9 facts to 70-80+ with no-repeat shuffle system.
- "Nearby Restaurants": 15 results with distance in miles, "Show all nearby" → 50.

**v9.36 (Phase 9 — Production Fix)**
- **CRITICAL:** Fixed white screen crash on tripledb.net caused by eager provider initialization in main() before runApp(). CookieConsentService constructor accessed dart:html document.cookie during Riverpod 3 provider graph construction, killing the app before Flutter could render.
- Fix: Removed ProviderContainer from main(), switched to standard ProviderScope with lazy providers. Made CookieConsentService lazy-initialized with try-catch fallback. Moved analytics initialization to widget tree post-frame callback.
- Restored complete README changelog (v0.7–v9.36) — all 21 entries preserved.

**v9.37 (Phase 9 — Post-Flight Protocol + Location Consent)**
- **Post-Flight Protocol (Pillar 9):** Automated runtime verification using Puppeteer headless browser.
  Serves release build locally, navigates app, checks rendering, reads console for errors.
  6 gates: bootstrap, navigation, features, cookies, console, changelog integrity.
  Prevents white-screen deploys like v9.35. Permanent part of IAO methodology.
- **Location on consent:** Accepting cookie preferences now triggers browser geolocation
  permission request. Grants location → populates "Nearby Restaurants" immediately.
  Decline → no location prompt. Reduces permission fatigue from 2 prompts to 1 flow.
- **Changelog gate:** Post-flight verifies README changelog entry count ≥ 22. Agent
  cannot declare iteration complete if changelog has been truncated.

**v9.38 (Phase 9 — Cookie Banner Fix + Functional Post-Flight)**
- **Root cause:** Cookie `Secure` flag silently prevented `document.cookie` writes on HTTP,
  and `_writeCookie()` used ISO 8601 for `expires` instead of RFC 1123. Additionally,
  `_readCookie()` used fragile `split('=')` with `parts.length == 2` check that could fail
  if cookie values contained `=` characters.
- **Fix:** Conditional `Secure` flag (only on HTTPS), RFC 1123 date format for `expires`,
  `indexOf`-based cookie parsing instead of `split`, and `essential` key validation to reject
  malformed/stale cookies.
- **Post-Flight v2:** Two-tier system. Tier 1: health gates. Tier 2: iteration-specific
  Playwright/Puppeteer functional playbook with click-verify-confirm actions. Canvas screenshots
  replaced with accessibility tree verification and interactive button clicking.
- Cookie banner verified via 6-test playbook: renders, dismisses, persists, validates cookie
  structure, fresh context, decline path. All 6 tests PASS.

**v9.39 (Phase 9 — Nearby Filtering + Location Consent Fix)**
- **Bug 1 fix:** Filtered "Unknown" city/state restaurants from nearby results. Only restaurants
  with valid, real city and state values appear in "Nearby Restaurants" and proximity-sorted search.
- **Bug 2 fix:** Deduplicated nearby results by restaurant_id and normalized name. No restaurant
  appears twice. Belly and Snout (3 entries in JSONL with different IDs) now shows once.
- **Bug 3 fix:** Accept All cookie consent now correctly triggers browser location permission
  request before dismissing the banner. Location grant populates "Nearby Restaurants" immediately.
- **Design doc:** Comprehensive living ADR with Eight Pillars, full environment setup guide,
  complete project state, and work remaining to MVP.
- Post-flight: 7/7 tests PASS — no Unknown in nearby, no duplicates, Accept All → location,
  cookie persistence, decline path correct.

---

## Author

**Kyle Thompson** — Solutions Architect @ TachTech Engineering

Built as a passion project for finding the best diners after long motorcycle rides.

---

*Last updated: Phase 9.39 — Nearby Filtering + Location Consent Fix*
