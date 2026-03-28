# 🍔 TripleDB

**Every restaurant from Diners, Drive-Ins and Dives — structured, searchable, and mapped.**

🌐 [tripledb.net](https://tripledb.net) · 📺 805 Episodes · 🍔 1,102 Restaurants · 🍽️ 2,286 Dishes · 📍 1,006 Mapped · 💰 $0 Cost

---

## What TripleDB Is

TripleDB processes 805 YouTube videos from Guy Fieri's "Diners, Drive-Ins and Dives" (DDD) into a structured Firestore database of restaurants, dishes, ingredients, and iconic Guy Fieri moments. The name is a triple play: **Triple D** (the show's nickname) + **DB** (database). It's live at [tripledb.net](https://tripledb.net) — a Flutter Web app where you can search by anything, find a diner near you, and watch the exact moment Guy walks in.

---

## Pipeline Architecture

| Stage | Tool | Input | Output | Runtime |
|-------|------|-------|--------|---------|
| `acquisition` | yt-dlp | YouTube playlist (805 URLs) | MP3 audio files | Local, tmux batch |
| `transcription` | faster-whisper large-v3 | MP3 audio | Timestamped JSON transcripts | Local CUDA (RTX 2080S), tmux |
| `extraction` | Gemini 2.5 Flash API | Transcripts (1M context) | Structured restaurant JSON | Free tier API call |
| `normalization` | Gemini 2.5 Flash API | Raw restaurant JSON | Deduplicated JSONL (1,102) | Free tier API call |
| `geocoding` | Nominatim (OpenStreetMap) | City/state pairs | Lat/lng coordinates (1,006) | Free, 1 req/sec, cached |
| `enrichment` | Google Places API (New) | Restaurant name + location | Ratings, status, URLs (582) | Free tier |
| `storage` | Firebase Admin SDK | Enriched JSONL | Cloud Firestore documents | Free tier (Spark) |
| `frontend` | Flutter Web | Firestore reads | tripledb.net | Firebase Hosting |
| `orchestration` | Claude Code / Gemini CLI | Design + plan docs | Build + report artifacts | tmux for batch/UAT |

```
YouTube Playlist (805 videos)
    | yt-dlp (local, tmux)          --remote-components ejs:github
    v                                --cookies-from-browser chrome
MP3 Audio
    | faster-whisper large-v3       LD_LIBRARY_PATH=/usr/local/lib/
    v (local CUDA, tmux session)    ollama/cuda_v12:$LD_LIBRARY_PATH
Timestamped Transcripts
    | Gemini 2.5 Flash API          Free tier. 1M context. No chunking.
    v
Extracted Restaurant JSON
    | Gemini 2.5 Flash API          Dedup by name+city. Merge dishes.
    v
Normalized JSONL (1,102 restaurants)
    | Nominatim (OpenStreetMap)      1 req/sec. geocode_cache.json.
    v
Geocoded Data (1,006 with coords)
    | Google Places API (New)        Text Search -> Place Details. >=0.70 match.
    v
Enriched Data (582 verified)
    | Firebase Admin SDK             Merge updates. Never overwrite originals.
    v
Cloud Firestore
    | Flutter Web
    v
tripledb.net
```

### Execution Model

| Mode | Agent | Runtime | Use Case |
|------|-------|---------|----------|
| Group A (interactive) | Claude Code or Gemini CLI | Terminal (Konsole) | Phases 1-4: iterative refinement, 30-video batches |
| Group B (unattended) | bash scripts | tmux session | Phase 5: 805-video production run, 14-hour execution |
| UAT (auto-chain) | Gemini CLI | tmux session | Phase 10+: all phases in a single session, zero human review |
| Post-flight | Puppeteer | Subprocess | Browser testing after each iteration |

---

## Architecture

| Layer | Technology | Purpose |
|-------|-----------|---------|
| 🎙️ Acquisition | yt-dlp + faster-whisper (CUDA) | YouTube → timestamped transcripts |
| 🧠 Extraction | Gemini 2.5 Flash API (free tier) | Transcripts → structured restaurant JSON |
| 📍 Enrichment | Google Places API + Nominatim | Ratings, coords, open/closed status |
| 🗄️ Storage | Cloud Firestore (Spark) | Denormalized restaurant documents |
| 📱 Frontend | Flutter Web + Firebase Hosting | Mobile-first responsive app |
| 🔒 Security | Firestore rules + cookie consent | Read-only public, GDPR/CCPA compliant |
| 🤖 Orchestration | Claude Code / Gemini CLI | IAO methodology, tmux for batch and UAT |

---

## Features

What you can do on [tripledb.net](https://tripledb.net):

- **Search by anything** — dish name, cuisine type, city, chef, ingredients ("ground beef" → hamburgers, meatloaf, etc.)
- **Find a diner nearby** — location-aware, consent-gated, proximity-sorted
- **Watch the exact moment** — deep link to the YouTube timestamp where Guy walks in
- **See Google-verified ratings** — star ratings and open/closed status from Google Places
- **Discover 150+ trivia facts** — rotating facts about the show with no-repeat system
- **Browse name changes** — restaurants that changed names get "Now known as" badges

---

## Project Status

| Phase | Name | Status | Iteration |
|-------|------|--------|-----------|
| 0 | Setup & Scaffolding | ✅ Complete | v0.7 |
| 1 | Discovery (30 videos) | ✅ Complete | v1.10 |
| 2 | Calibration (60 videos) | ✅ Complete | v2.11 |
| 3 | Stress Test (90 videos) | ✅ Complete | v3.12 |
| 4 | Validation (120 videos) | ✅ Complete | v4.13 |
| 5 | Production Run (805 videos) | ✅ Complete | v5.14–v5.15 |
| 6 | Firestore + Geocoding + Polish | ✅ Complete | v6.26–v6.29 |
| 8 | Flutter App | ✅ Complete | v8.17–v8.25 |
| 7 | Enrichment + Analytics | ✅ Complete | v7.30–v7.34 |
| 9 | App Optimization | ✅ Complete | v9.35–v9.43 |
| 10 | Retrospective + Radar + UAT | ✅ Complete | v10.44-v10.46 (Tracks A+B+C) |

**Phase 10 complete.** Three tracks across 3 iterations: Retrospective (v10.44), Technology Radar (v10.45), UAT Handoff + IAO Template (v10.46). UAT artifacts ready for Gemini CLI. IAO Project Template ready for any new TachTech project.

---

## Data at a Glance

| Metric | Value |
|--------|-------|
| Videos processed | 773 / 805 |
| Unique restaurants | 1,102 |
| Unique dishes | 2,286 |
| Total visits | 2,336 |
| Geocoded | 1,006 (91.3%) |
| Enriched (verified) | 582 (52.8%) |
| Permanently closed | 34 |
| Genuine name changes | 279 |
| States & territories | 62 |
| Avg Google rating | 4.4 ⭐ |
| Total API cost | **$0** |

---

## Tech Stack

| Component | Tool | Purpose |
|-----------|------|---------|
| Transcription | faster-whisper (CUDA) | mp3 → timestamped JSON |
| Extraction | Gemini 2.5 Flash API | Transcript → restaurant JSON |
| Normalization | Gemini 2.5 Flash API | Dedupe, validate, schema-conform |
| Geocoding | Nominatim (OpenStreetMap) | City → lat/lng |
| Enrichment | Google Places API (New) | Ratings, status, websites, addresses |
| Database | Cloud Firestore | Live data serving |
| State Management | Riverpod 3.x with codegen | Reactive state |
| Frontend | Flutter Web + Firebase Hosting | tripledb.net |
| Analytics | Firebase Analytics + consent mode v2 | Consent-gated events |
| Privacy | Custom cookie consent | GDPR/CCPA compliant, 3 categories |
| Security | Firestore rules | Read-only public, write denied |
| Dev Orchestration | Claude Code (Opus) | Interactive YOLO execution |
| Batch Execution | tmux + bash | Production pipeline runs, UAT auto-chain |
| UAT Orchestration | Gemini CLI | Batch autonomous execution |

---

## IAO Methodology

TripleDB is built using **Iterative Agentic Orchestration (IAO)** — a development methodology where LLM agents execute project phases autonomously while humans review versioned artifacts between iterations. Every iteration produces five artifacts: design, plan, build, report, and changelog. The report informs the next plan. The methodology itself evolves alongside the project.

IAO crystallized through 46 iterations into the **Nine Pillars**: Artifact Loop, Agentic Orchestration, Zero-Intervention Target, Pre-Flight Verification, Self-Healing Execution, Progressive Batching, Post-Flight Functional Testing, Mobile-First Flutter + Firebase (Zero-Cost by Design), and Continuous Improvement.

Bulk pipeline processing and UAT auto-chain execution run in tmux sessions for crash resilience and unattended operation. The Phase 5 production run (805 videos, 14 hours) and all Phase 10 UAT execution are tmux-driven. 46 iterations produced 19 cataloged failure modes, a 14-item plan quality checklist, and 10 lessons learned. See `docs/archive/ddd-retrospective-v10.44.md`.

See `docs/ddd-design-v10.46.md` for the full Nine Pillars framework. See `docs/iao-template-design-v0.1.md` for the project-agnostic IAO methodology template.

---

## Technology Radar

Evaluated 13 tools across 5 axes (architecture fit, cost, token efficiency, integration, TachTech breadth). Full analysis in `docs/ddd-radar-v10.45.md`.

| Tool | Rating | Action |
|------|--------|--------|
| Gemini 2.5 Flash | Adopt | Continue, no changes |
| Claude Skills | Adopt | Package IAO pillars as skills |
| Puppeteer | Adopt | Primary browser testing |
| Lighthouse CLI | Adopt | Hardening audits |
| Claude Sonnet 4.6 | Adopt | Route simple API tasks |
| Local LLMs (Ollama) | Trial | Benchmark on P3 Ultra |
| Context7 MCP | Trial | Keep, use as self-heal fallback |
| Gemini CLI Skills | Trial | Evaluate during UAT |
| Ruflo | Trial | POC for SOC Alpha |
| NemoClaw | Trial | Benchmark on P3 Ultra |
| Playwright MCP | Hold | Dropped - Puppeteer covers all needs |

---

## Hardware

| Machine | Role | Specs |
|---------|------|-------|
| NZXT (Primary) | Dev + pipeline + deployment | AMD Ryzen, RTX 2080 SUPER 8GB, 32GB RAM, CachyOS |
| ThinkStation (Secondary) | Backup + parallel runs | Xeon, Quadro, 32GB RAM, CachyOS |

---

## Cost

| Component | Cost |
|-----------|------|
| Local inference (faster-whisper, Ollama) | Free |
| Gemini 2.5 Flash API (extraction) | Free tier |
| Google Places API (enrichment) | Free tier |
| Nominatim geocoding | Free |
| Cloud Firestore (Spark plan) | Free tier |
| Firebase Hosting + Analytics | Free tier |
| **Total infrastructure** | **$0** |

---

## Repo Structure

```
~/dev/projects/tripledb/
├── CLAUDE.md                    ← Version lock (Dev)
├── README.md                    ← Public, changelog (NEVER truncate)
├── .gitignore
├── docs/                        ← Current iteration only
│   ├── ddd-design-v{P}.{I}.md
│   ├── ddd-plan-v{P}.{I}.md
│   ├── ddd-build-v{P}.{I}.md
│   ├── ddd-report-v{P}.{I}.md
│   ├── screenshots/
│   └── archive/                 ← ALL previous iterations
├── pipeline/
│   ├── GEMINI.md                ← Version lock (UAT/legacy)
│   ├── scripts/
│   ├── config/
│   └── data/                    ← gitignored
├── app/
│   ├── pubspec.yaml
│   ├── firestore.rules
│   ├── firebase.json
│   ├── lib/
│   ├── web/
│   └── build/web/               ← gitignored
```

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

**v9.40 (Phase 9 — dart:html Migration + Firestore Security Rules — FINAL DEV ITERATION)**
- **dart:html → package:web:** Migrated `cookie_consent_service.dart` from deprecated `dart:html`
  to `package:web` + `dart:js_interop`. Eliminates the persistent analyzer deprecation warning
  (`info • 'dart:html' is deprecated`) and enables future WASM compilation. All cookie
  read/write/HTTPS-detection functions verified via 7/7 post-flight playbook.
- **Firestore security rules:** Created `firestore.rules` with read-only public access.
  `restaurants` and `videos` collections allow public reads, deny all client writes.
  Admin SDK writes (pipeline scripts) bypass rules. Default deny on all other collections.
  `firebase.json` updated to reference rules file.
- **Final dev iteration:** Phase 9 complete. All P0/P1 items resolved. `flutter analyze` shows
  0 errors, 0 warnings, 0 infos. App is production-ready for Phase 10 UAT handoff to Gemini CLI.

**v9.41 (Phase 9 — Nine Pillars + README Overhaul)**
- **Nine Pillars of IAO:** Methodology evolved from Eight to Nine Pillars. New Pillar 8
  (Mobile-First Flutter + Firebase, Zero-Cost by Design) elevated from tech stack choice
  to architectural principle. Continuous Improvement renumbered to Pillar 9.
- **Agent permissions updated:** Agents CAN now run flutter build web and firebase deploy.
  Agents CANNOT git add/commit/push. Kyle commits at phase boundaries.
- **README overhaul:** Full rewrite with feature badges, ASCII pipeline diagram, layered
  architecture table, and updated project stats reflecting 41 iterations of development.
- **CLAUDE.md template v2:** Updated with CAN/CANNOT permissions table.

**v9.42 (Phase 9 — Hardening Audit)**
- **Lighthouse baseline:** Accessibility 93, SEO 100, Best Practices 77, FCP 1.5s (local) / 0.8s
  (prod), CLS 0. Performance score N/A (Flutter canvas rendering prevents Lighthouse FCP detection
  in headless). Bundle size 2.8MB (tree-shaken icons 99.4% reduction). No source maps in build.
- **Error boundary testing:** 5/5 PASS — Firestore offline (graceful degradation), location denied
  (app loads without distance), cookies disabled (app functional), invalid URL (GoRouter handles),
  empty search (no crash). No white screens. No inline fixes needed.
- **Security hardening:** 6 security headers deployed to Firebase Hosting — X-Frame-Options: DENY,
  X-Content-Type-Options: nosniff, Referrer-Policy: strict-origin-when-cross-origin,
  Permissions-Policy (camera/mic blocked, geolocation self), HSTS 1 year, and CSP with allowlists
  for Flutter CanvasKit, Firestore, Analytics, map tiles, and fonts. Cache headers: JS/CSS
  immutable 1-year, index.html no-cache. Firestore rules pen-tested (writes blocked).
  Dependency audit: no CVEs, 5 major upgrades available (deferred).
- **Browser compatibility:** Chromium PASS across 4 viewports (375x667, 768x1024, 1024x768,
  1920x1080). No horizontal scroll. Keyboard navigation 10/10 focus changes. Firefox: app loads
  but Flutter runtime `Invalid language tag: "undefined"` error (upstream Flutter bug, P2).
  WebKit: skipped (missing system deps on CachyOS).
- **Versioned changelog:** Introduced `ddd-changelog-v{P}.{I}.md` as 5th artifact for resilience.

**v9.43 (Phase 9 — Package Upgrades + Trivia + Preferences Fix)**
- **Package upgrades:** flutter_map 7.0.2→8.2.2, flutter_map_marker_cluster 1.4.0→8.2.2,
  go_router 14.8.1→17.1.0, google_fonts 6.3.3→8.0.2. Zero breaking changes.
  flutter analyze: 0 issues. flutter build web: success.
- **Trivia expansion:** Increased from ~55 to 151 unique facts. 65 curated + 86 dynamic
  data-driven facts. Fixed duplicate display with Set-based dedup. Implemented shuffle-based
  rotation with no-repeat guarantee at cycle boundary.
- **Save Preferences → location:** Clicking Save Preferences with geolocation enabled now
  correctly triggers the browser location prompt, matching Accept All behavior. Fixed by
  reordering: location request fires before modal dismissal.
- **Firefox ESR testing:** Added Firefox ESR to browser test matrix. Chrome Stable + Firefox ESR
  are the two supported test targets. Firefox: app loads, renders, no blocking errors. A11y tree
  not accessible via Puppeteer BiDi (CDP required) — documented as test gap.
- **Browser test results:** Chrome 9/9 PASS. Firefox 6/6 PASS + 1 SKIP (a11y CDP limitation).

**v10.44 (Phase 10 - Retrospective)**
- **Pillar 9 retrospective:** Comprehensive archive review across 43 iterations and 10 phases.
  Produced intervention timeline (36 total interventions, 89% in Phases 1-2), tool efficacy
  matrix (14 tools scored), pillar evolution history (6 -> 8 -> 9), plan quality analysis
  with IAO checklist (14 items), failure mode catalog (19 categorized failures), and top 10
  lessons learned distilled into actionable rules.
- **Em-dash formatting rule:** Established standard - no em-dashes in any artifact. Baked into
  CLAUDE.md, GEMINI.md templates, and design doc Section 13.
- **Phase 10 architecture:** Three sequential tracks defined - Retrospective (v10.44),
  Technology Radar (v10.45), UAT Handoff (v10.46+).

**v10.45 (Phase 10 - Technology Radar + README Overhaul)**
- **Technology Radar:** 13 tools scored across 5 axes (architecture fit, cost, token efficiency,
  integration, TachTech breadth). 5 tools rated Adopt (Claude Skills, Gemini Flash, Puppeteer,
  Lighthouse, Sonnet 4.6). 5 rated Trial (Ruflo, NemoClaw, Local LLMs, Context7, Gemini Skills).
  2 rated Assess. 1 rated Hold (Playwright - dropped).
- **README pipeline overhaul:** Replaced ASCII-only pipeline diagram with Ruflo-style layered
  pipeline table showing stage, tool, input, output, and runtime. Added execution model table
  (Group A/B/UAT with tmux callouts).
- **tmux visibility:** Added tmux to README tech stack, architecture layer, IAO methodology
  section, and pipeline table. tmux is a primary component for bulk processing and UAT execution.
- **Retrospective integrated:** Plan quality checklist (14 items) referenced in CLAUDE.md template.
  Retrospective highlights added to README. Track C deliverable spec finalized - 4 artifacts:
  UAT design + plan (Gemini), IAO Project Template design + plan (Claude, any new project).
- **Phase 10 Track B complete.** Ready for Track C (UAT Handoff + IAO Template).

**v10.46 (Phase 10 - Track C Capstone)**
- **UAT handoff artifacts:** Produced ddd-design-uat.md and ddd-plan-uat-v0.1.md for Gemini CLI
  to replay the full TripleDB pipeline from scratch. Same Firebase project, hosting preview
  channel, no Firestore writes. Pipeline validated by JSONL diff against dev output.
- **IAO Project Template:** Produced iao-template-design-v0.1.md and iao-template-plan-v0.1.md -
  generic Nine Pillars framework for any new TachTech project. Includes plan quality checklist
  (14 items), failure mode catalog (19 modes), top 10 lessons. Quick start: 5 commands to scaffold.
- **Phase 10 complete.** Three tracks delivered across 3 iterations: Retrospective (v10.44),
  Technology Radar (v10.45), UAT Handoff + IAO Template (v10.46).

---

## Author

**Kyle Thompson** — Solutions Architect @ TachTech Engineering

Built as a passion project for finding the best diners after long motorcycle rides.

---

*Built with [IAO](docs/ddd-design-v10.46.md) - Iterative Agentic Orchestration*
*Phase 10.46 - UAT Handoff + IAO Template across 46 iterations*
