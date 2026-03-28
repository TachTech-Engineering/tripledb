# TripleDB — Design v9.39

**ADR-001 | Living Architecture Document**
**Last Updated:** Phase 9, Iteration 39
**Author:** Kyle Thompson, Managing Partner & Solutions Architect @ TachTech Engineering
**Repository:** `git@github.com:TachTech-Engineering/tripledb.git`
**Live Site:** [tripledb.net](https://tripledb.net)
**Firebase Project:** tripledb-e0f77

---

# Table of Contents

1. [Project Mandate](#1-project-mandate)
2. [IAO Methodology — The Eight Pillars](#2-iao-methodology)
3. [Iteration History](#3-iteration-history)
4. [Environment Setup (From Scratch)](#4-environment-setup)
5. [Pipeline Architecture](#5-pipeline-architecture)
6. [Data Model](#6-data-model)
7. [App Architecture](#7-app-architecture)
8. [Locked Architectural Decisions](#8-locked-decisions)
9. [Scripts & Tools Inventory](#9-scripts-inventory)
10. [Repository Structure](#10-repository-structure)
11. [Known Gotchas](#11-known-gotchas)
12. [Current State](#12-current-state)
13. [Work Remaining to MVP](#13-remaining-work)

---

# 1. Project Mandate

## What TripleDB Is

A passion project that processes 805 YouTube videos from Guy Fieri's "Diners, Drive-Ins and Dives" (DDD) into a structured Firestore database of restaurants, dishes, ingredients, and iconic Guy Fieri moments. The name is a triple play: **Triple D** (the show's nickname) + **DB** (database).

The output is a Flutter Web app at **tripledb.net** where users can:

- **Find a diner near them** — browser geolocation with distance in miles
- **Search by anything** — dish name, cuisine type, city, chef, ingredients
- **Watch the moment** — deep link to the exact YouTube timestamp where Guy walks in
- **See what's still open** — Google-verified open/closed status, ratings, current names
- **Explore the data** — trivia, stats, state rankings, cuisine breakdowns

## Why It Exists

Built as a personal project for finding the best diners after long motorcycle rides. Also serves as a live reference implementation of the IAO (Iterative Agentic Orchestration) methodology — a development framework where LLM agents execute pipeline phases autonomously while humans review versioned artifacts between iterations.

## Cost Model

| Component | Cost |
|-----------|------|
| All local inference (faster-whisper, Ollama) | Free |
| Gemini CLI orchestration | Free tier |
| Gemini 2.5 Flash API (extraction, normalization, verification) | Free tier |
| Google Places API (enrichment) | Free tier (~2,100 calls) |
| Nominatim geocoding | Free (OpenStreetMap) |
| Cloud Firestore | Free tier (Spark plan) |
| Firebase Hosting | Free tier |
| Firebase Analytics | Free tier |
| **Total project cost** | **$0** |

---

# 2. IAO Methodology — The Eight Pillars

## What IAO Is

Iterative Agentic Orchestration — a development methodology where LLM agents execute project phases autonomously while humans review versioned artifacts between iterations. Each iteration produces a plan (input) and a report (output). The report informs the next plan. The methodology itself evolves alongside the project.

IAO emerged organically through 38 iterations of the TripleDB project. What started as "give the agent a prompt and hope" evolved into a rigorous, repeatable framework for building data pipelines and applications with agentic assistance.

## Pillar 1 — Artifact Loop

Every iteration produces four markdown artifacts: design (living architecture), plan (execution steps), build (full session transcript), and report (metrics + recommendation). These are the single source of truth — not chat history, not memory, not git diffs. The report informs the next plan. The design accumulates decisions across iterations. Previous artifacts are archived to `docs/archive/` and only the current iteration's docs live in `docs/` — agents never see outdated instructions, but the full history is preserved for human review and retrospectives.

Each iteration report includes an **Orchestration Report** section: a breakdown of which agents, MCP servers, APIs, and scripts were used in that iteration, their approximate share of the workload, and their efficacy. Example: "Claude Code (primary executor, 60%) — 0 self-heal cycles. Puppeteer (post-flight, 15%) — 6/6 tests passed. Google Places API (enrichment, 20%) — 582 matches at $0. Context7 (docs, 5%) — consulted for API changes." This creates a running record of which tools deliver value and which underperform, feeding directly into Pillar 8.

### Artifact Spec

| Direction | File | Author | Purpose |
|-----------|------|--------|---------|
| Input | `ddd-design-v{P}.{I}.md` | Claude (chat) | Living architecture, locked decisions, IAO methodology |
| Input | `ddd-plan-v{P}.{I}.md` | Claude (chat) | Execution steps, success criteria, post-flight playbook |
| Output | `ddd-build-v{P}.{I}.md` | Claude Code / Gemini | Full session transcript — every command, output, error, fix |
| Output | `ddd-report-v{P}.{I}.md` | Claude Code / Gemini | Metrics, orchestration report, recommendation |
| Output | `README.md` (updated) | Executing agent | Status, metrics, changelog (APPEND only, never truncate) |

### Git Workflow Per Iteration

```
1. Move previous docs to docs/archive/
2. Place new ddd-design and ddd-plan in docs/
3. Update CLAUDE.md version pointer
4. git add . && git commit -m "KT starting {P}.{I}"
5. claude --dangerously-skip-permissions → "Read CLAUDE.md and execute."
6. Agent executes autonomously, produces build + report + README update
7. Human reviews report
8. git add . && git commit -m "KT completed {P}.{I} and README updated"
9. git push && cd app && flutter build web && firebase deploy --only hosting
10. Human + Claude decide: next phase or re-run adjusted iteration
```

## Pillar 2 — Agentic Orchestration

The primary agent orchestrates a constellation of LLMs, MCP servers, scripts, APIs, and sub-agents to understand the design, execute the plan, capture the build, and produce the report. The version lock file (`CLAUDE.md`) at project root points to the current design and plan docs — the launch command never changes. Git commits mark iteration boundaries: `"KT starting {P}.{I}"` and `"KT completed {P}.{I}"`.

**Tool ecosystem (current):**

| Tool | Category | Purpose | Used In |
|------|----------|---------|---------|
| Claude Code (Opus) | Primary executor | Reads plan, edits code, runs commands, produces artifacts | v9.35+ |
| Gemini CLI (legacy) | Primary executor | Same role, shell-only access | v0.7–v7.34 |
| Gemini 2.5 Flash API | LLM API | Extraction, normalization, LLM match verification | v1.10+ |
| Playwright MCP | Browser automation | Post-flight functional testing | v9.37+ |
| Puppeteer (npm) | Browser automation | Fallback for Playwright, headless testing | v9.38 |
| Context7 MCP | Documentation | Flutter/Dart API docs, package compatibility | v6.29+ |
| Firebase Admin SDK | Database | Firestore CRUD, batch operations | v6.26+ |
| Google Places API (New) | Enrichment API | Ratings, open/closed, websites, addresses | v7.30+ |
| Nominatim | Geocoding API | City → lat/lng coordinates | v6.28 |
| faster-whisper | Local ML | CUDA-accelerated audio transcription | v1.10+ |
| yt-dlp | Media tool | YouTube → mp3 download | v0.7+ |
| tmux + bash | Unattended runner | Group B production batch execution | v5.15 |
| Firecrawl / Playwright | Web scraping | Design reference site scraping | v8.22 |

## Pillar 3 — Zero-Intervention Target

Every question the agent asks during execution is a failure in the plan document. Pre-answer every decision point. Pre-set every environment variable. Pre-document every gotcha. Measure plan quality by counting interventions — zero is the floor, not the ceiling.

If the agent encounters an uncovered situation, it makes the best decision, logs its reasoning in the build log, and continues. YOLO mode (`claude --dangerously-skip-permissions`) is the default execution model — code dangerously, move fast, and let the post-flight catch what the pre-flight missed. Asking the human is a last resort reserved for situations where continuing would be destructive.

**Intervention history:** v2.11 had 20+ interventions. v3.12 achieved zero. That's the standard.

## Pillar 4 — Pre-Flight Verification

Before execution begins, validate the full environment: API keys set and reachable, services responding, dependencies installed, git status clean, previous iteration archived, working directories correct.

After the iteration completes and Kyle deploys, verify that `git push`, `flutter build web`, and `firebase deploy` timestamps are more recent than the build artifact timestamp. If any deployment step is stale, the iteration isn't live — flag it.

### Standard Pre-Flight Checklist

```
[ ] Previous iteration docs archived to docs/archive/
[ ] New design + plan docs placed in docs/
[ ] CLAUDE.md updated with current iteration pointer
[ ] git status clean (committed: "KT starting {P}.{I}")
[ ] $GOOGLE_PLACES_API_KEY set (if enrichment iteration)
[ ] $GEMINI_API_KEY set (if LLM verification iteration)
[ ] Firebase project accessible (tripledb-e0f77)
[ ] flutter analyze: 0 errors
[ ] flutter build web: success (baseline before changes)
[ ] Pipeline pre_flight.py passes (if pipeline iteration)
```

## Pillar 5 — Self-Healing Loops

Errors are inevitable in data pipelines and app development. When one occurs: diagnose → fix → re-run. Max 3 attempts per error, then log and skip. If 3 consecutive items fail with the same error, STOP the batch, fix the root cause, restart. Never burn through hundreds of items with a known systemic failure.

Self-healing applies to code errors, API failures, build breaks, and post-flight test failures alike. v3.12's autonomous batch healing — swapping marathons for clips when session limits were hit — proved the agent can make structural decisions, not just retry.

## Pillar 6 — Progressive Batching

Start small. Each batch is bigger and harder — more edge cases, more overlap, more stress. 30 → 60 → 90 → 120 → 805 videos. 50 → 1,102 restaurants for enrichment. By the time you run the production batch, every failure mode has been seen, logged, and handled.

Once the pipeline is proven through graduated batches, graduate execution from interactive agent (Group A) to unattended bash + tmux scripts (Group B) to eliminate token spend on repetitive work. The right tool for iterative tuning (agent) is the wrong tool for a 14-hour production run (bash + tmux).

## Pillar 7 — Post-Flight Functional Testing

Two-tier verification after every iteration that touches frontend or deployment code.

**Tier 1 — Standard Health:**
- App bootstraps without white screen
- Browser console has zero uncaught errors
- Changelog integrity (entry count ≥ expected)

**Tier 2 — Iteration Playbook:**
Playwright/Puppeteer executes a functional test sequence specific to that iteration's deliverables — clicking buttons, verifying state changes, confirming persistence, reading the accessibility tree. Every plan includes a `## Post-Flight Playbook` section.

Flutter Web renders to `<canvas>` — screenshots of the canvas prove nothing about interactive functionality. Accessibility tree verification and interactive user-like actions are required. Born from v9.35's white-screen deploy and v9.37's screenshot-only gap.

## Pillar 8 — Continuous Improvement

IAO itself evolves alongside every project and crystallizes into institutional knowledge at project close. At the end of each project (or major phase), the agent performs a structured retrospective:

1. **Archive Review** — agentically scan the entire `docs/archive/` folder to assess plan execution quality, intervention patterns, and methodology gaps across all iterations
2. **Tool Efficacy Assessment** — synthesize the orchestration reports from every iteration into a tools matrix: what delivered value, what underperformed, what to adopt for the next project
3. **Architectural Documents** — produce a final set of locked ADRs, environment setup guides, and onboarding docs for the next project
4. **Horizon Scan** — review which new agents, MCP servers, or AI tools have become available since project inception that could benefit future work

The pillars themselves are artifacts of this process: 6 (v3.12) → 8 (v5.14) → 9 (v9.37) → 8 refined (v9.39). What doesn't work gets cut. What's missing gets added. The methodology is defined by results, not by theory.

---

# 3. Iteration History

| Iteration | Phase | Focus | Executor | Interventions | Key Result |
|-----------|-------|-------|----------|---------------|------------|
| v0.7 | 0 Setup | Monorepo scaffold | Gemini | N/A | 805 URLs, fish shell gotchas |
| v1.8 | 1 Discovery | Nemotron extraction | Gemini | 20+ | FAIL: 42GB model on 8GB VRAM |
| v1.9 | 1 Discovery | Qwen 3.5-9B extraction | Gemini | 20+ | Too slow for structured extraction |
| v1.10 | 1 Discovery | Gemini Flash extraction | Gemini | ~10 | 186 restaurants, 290 dishes |
| v2.11 | 2 Calibration | 60-video dataset | Gemini | 20+ | 422 restaurants, CUDA path fix |
| v3.12 | 3 Stress Test | Marathons, edge cases | Gemini | **0** | Zero interventions achieved |
| v4.13 | 4 Validation | Prompts locked | Gemini | **0** | 608 restaurants, Group B green-lit |
| v5.14 | 5 Production Setup | Runner infrastructure | Gemini | **0** | group_b_runner.sh, checkpointing |
| v5.15 | 5 Production Run | 805 videos | Gemini | **0** | 773 extracted, 14-hour unattended |
| v6.26 | 6 Firestore Load | JSONL → Firestore | Gemini | **0** | 1,102 restaurants loaded |
| v6.27 | 6 Geolocation Fix | Browser geolocation | Gemini | **0** | Broke Firestore (reverted v6.28) |
| v6.28 | 6 Geocoding | Nominatim batch | Gemini | **0** | 916/1102 geocoded |
| v8.17–21 | 8 Flutter App Pass 1 | Scaffold + core features | Gemini | **0** | App live (thin QA) |
| v8.22–25 | 8 Flutter App Pass 2 | Design tokens, polish | Gemini | **0** | Lighthouse A11y 92, SEO 100 |
| v6.29 | 6 Polish | Trivia, clustering | Gemini | **0** | Map clustering, state count fix |
| v7.30 | 7 Enrichment Discovery | 50-restaurant batch | Gemini | **0** | 66.7% match, pipeline proven |
| v7.31 | 7 Enrichment Production | 1,102 restaurants | Gemini | **1** | 625 enriched, API key missing |
| v7.32 | 7 Enrichment Refinement | Refined search + LLM verify | Gemini | **0** | 83 recovered, 126 false pos removed |
| v7.33 | 7 AKA Names + Closed UX | Name backfill, grey pins | Gemini | **0** | 283 name changes, closed filter |
| v7.34 | 7 Cookies + Analytics | Consent banner, Firebase Analytics | Gemini | **0** | GDPR/CCPA compliant |
| v9.35 | 9 App Optimization | Riverpod 3, trivia, proximity | Claude Code | **0** | First Claude Code iteration |
| v9.36 | 9 Production Fix | White screen crash | Claude Code | **0** | Lazy init + deferred DOM access |
| v9.37 | 9 Post-Flight Protocol | Playwright verification | Claude Code | **0** | Pillar 7 established (v1) |
| v9.38 | 9 Cookie Banner Fix | Debug + functional playbook | Claude Code | **0** | Robust cookie parsing, 6/6 tests |

---

# 4. Environment Setup (From Scratch)

## Operating System

CachyOS (Arch Linux derivative) with KDE Plasma 6.6.3 on Wayland. Fish shell 4.5.0.

### Base System Packages (pacman)

```bash
sudo pacman -S base-devel git fish tmux python python-pip nodejs npm \
  nvidia nvidia-utils cuda cudnn \
  firefox chromium \
  --needed
```

### AUR Packages (yay)

```bash
yay -S visual-studio-code-bin  # or antigravity-bin (VS Code fork Kyle uses)
yay -S google-cloud-cli
yay -S firebase-tools
```

## Flutter SDK

```bash
# Install via official method
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
echo 'set -gx PATH ~/flutter/bin $PATH' >> ~/.config/fish/config.fish

# Verify
flutter doctor
flutter --version
# Expected: 3.41+ stable
```

## Node.js / npm

```bash
# Already installed via pacman
node --version   # v20+
npm --version    # 10+

# Global tools
npm install -g firebase-tools
npm install -g puppeteer  # For post-flight testing
```

## Python Dependencies

```bash
pip install --break-system-packages \
  faster-whisper \
  requests \
  firebase-admin \
  yt-dlp
```

## CUDA Setup (for faster-whisper transcription)

```bash
# CUDA libs for faster-whisper — set in fish config
echo 'set -gx LD_LIBRARY_PATH /usr/local/lib/ollama/cuda_v12 $LD_LIBRARY_PATH' >> ~/.config/fish/config.fish

# Verify
python3 -c "import faster_whisper; print('faster-whisper OK')"
nvidia-smi  # Should show GPU
```

## Firebase CLI

```bash
firebase login
firebase use tripledb-e0f77

# Verify
firebase projects:list | grep tripledb
```

## Google Cloud / API Keys

```bash
# Google Places API key (for enrichment)
echo 'set -gx GOOGLE_PLACES_API_KEY "your-key-here"' >> ~/.config/fish/config.fish

# Gemini API key (for extraction, normalization, LLM verification)
echo 'set -gx GEMINI_API_KEY "your-key-here"' >> ~/.config/fish/config.fish

# Firebase Application Default Credentials
gcloud auth application-default login
```

**GCP Console steps:**
1. Enable Places API (New) on project tripledb-e0f77
2. Enable Gemini API
3. Create API key restricted to Places API (New) + Generative Language API
4. Store in fish config as above — NEVER commit to git

## Cloudflare WARP (if applicable)

```bash
# TLS certificate for WARP gateway
echo 'set -gx NODE_EXTRA_CA_CERTS "/etc/ssl/certs/Gateway_CA_-_Cloudflare_Managed_G1_3d028af29af87d79a8b3245461f04241.pem"' >> ~/.config/fish/config.fish

# If Python requests fails with TLS errors, temporarily disconnect WARP:
# warp-cli disconnect
```

## Claude Code (Executing Agent)

```bash
# Install Claude Code CLI
npm install -g @anthropic-ai/claude-code

# Verify
claude --version

# Launch in YOLO mode (no permission prompts — Pillar 3)
cd ~/dev/projects/tripledb
claude --dangerously-skip-permissions
```

## MCP Server Configuration

### Claude Code MCP config (`~/.config/claude/mcp.json` or project-level):

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/context7-mcp"]
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp", "--headless"]
    }
  }
}
```

### Gemini CLI MCP config (legacy — `~/.config/gemini/settings.json`):

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/context7-mcp"]
    }
  }
}
```

## yt-dlp Configuration

```bash
# Cookies for age-restricted DDD content
# yt-dlp reads cookies from Chrome browser
yt-dlp --cookies-from-browser chrome --remote-components ejs:github <url>

# 600s timeout for marathon videos
```

## Repository Clone + First Run

```bash
mkdir -p ~/dev/projects
cd ~/dev/projects
git clone git@github.com:TachTech-Engineering/tripledb.git
cd tripledb

# Verify structure
ls app/ pipeline/ docs/ CLAUDE.md README.md

# Flutter app setup
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter build web

# Pipeline setup
cd ../pipeline
python3 scripts/pre_flight.py
```

---

# 5. Pipeline Architecture

```
YouTube Playlist (805 videos)
    ↓ yt-dlp (local)               Flags: --remote-components ejs:github
MP3 Audio                                  --cookies-from-browser chrome
    ↓ faster-whisper large-v3       Launch: LD_LIBRARY_PATH=/usr/local/lib/
      (local CUDA)                          ollama/cuda_v12:$LD_LIBRARY_PATH
Timestamped Transcripts
    ↓ Gemini 2.5 Flash API          Free tier. 1M context. No chunking.
      (cloud)                        Timeout: 120s clips, 300s marathons.
Extracted Restaurant JSON
    ↓ Gemini 2.5 Flash API          Dedup by name+city. Merge dishes/visits.
      (cloud)
Normalized JSONL (1,102 restaurants)
    ↓ Nominatim (OpenStreetMap)      1 req/sec. Cache in geocode_cache.json.
Geocoded Data (1,006 with coordinates)
    ↓ Google Places API (New)        Text Search → Place Details.
      (cloud)                        Fuzzy match ≥ 0.70. Free tier.
Enriched Data (582 verified)
    ↓ Firebase Admin SDK             Merge updates. Never overwrite originals.
Cloud Firestore (1,102 restaurants, 773 videos)
    ↓ Flutter Web
tripledb.net
```

### Video Types

| Type | Duration | Typical Restaurants |
|------|----------|-------------------|
| `clip` | <15 min | 1 |
| `full_episode` | 15-25 min | 2-3 |
| `compilation` | 25-60 min | 3-8 |
| `marathon` | >60 min | 10-30+ |

### Normalization Rules

- **Null-name filtering:** Restaurants with empty/null names excluded from dedup (each is a distinct extraction failure)
- **Ingredient normalization:** lowercase, singular, strip brand names
- **State normalization:** Full name → abbreviation, null → "UNKNOWN"
- **Dedup:** Fuzzy match (Levenshtein < 3) for same name+city. Log all merges.
- **NULL names NEVER merged** — each is a distinct extraction failure

### Enrichment Match Validation

| Score | Action |
|-------|--------|
| ≥ 0.85 + city match | Auto-accept |
| 0.70–0.84 or city mismatch | Review bucket (LLM verified in v7.32) |
| < 0.70 | Reject |

---

# 6. Data Model

## Firestore Collection: `restaurants` (1,102 documents)

```json
{
  "restaurant_id": "r_<uuid4>",
  "name": "Mama's Soul Food",
  "google_current_name": "Fat Mo's",
  "name_changed": true,
  "city": "Memphis",
  "state": "TN",
  "formatted_address": "123 Main St, Memphis, TN 38103",
  "latitude": 35.1396,
  "longitude": -90.0541,
  "cuisine_type": "Soul Food",
  "owner_chef": "Tyrone Washington",
  "still_open": true,
  "business_status": "OPERATIONAL",
  "google_place_id": "ChIJ...",
  "google_rating": 4.6,
  "google_rating_count": 1247,
  "google_maps_url": "https://maps.google.com/?cid=...",
  "website_url": "https://example.com",
  "photo_references": ["AfLeUg..."],
  "enriched_at": "<timestamp>",
  "enrichment_source": "google_places_api",
  "enrichment_match_score": 0.92,
  "enrichment_verified": true,
  "visits": [
    {
      "video_id": "Q2fk6b-hEbc",
      "youtube_url": "https://youtube.com/watch?v=Q2fk6b-hEbc",
      "video_title": "Top #DDD Videos in Memphis",
      "video_type": "compilation",
      "guy_intro": "Here at Mama's Soul Food in Memphis...",
      "timestamp_start": 200.0,
      "timestamp_end": 480.0
    }
  ],
  "dishes": [
    {
      "dish_name": "Famous Fried Chicken",
      "description": "Brined overnight in buttermilk, double-dredged",
      "ingredients": ["chicken", "buttermilk", "seasoned flour"],
      "dish_category": "entree",
      "guy_response": "Now THAT is what I'm talking about!",
      "video_id": "Q2fk6b-hEbc",
      "timestamp_start": 215.5
    }
  ],
  "created_at": "<timestamp>",
  "updated_at": "<timestamp>"
}
```

## Firestore Collection: `videos` (773 documents)

```json
{
  "video_id": "<11-char YouTube ID>",
  "youtube_url": "https://youtube.com/watch?v=<id>",
  "title": "<video title>",
  "duration_seconds": 1619,
  "video_type": "compilation",
  "restaurant_count": 5,
  "processed_at": "<timestamp>"
}
```

---

# 7. App Architecture

## Tech Stack

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_riverpod` | 3.3.1 | State management (migrated from 2.x in v9.35) |
| `riverpod_annotation` | 4.0.2 | Codegen annotations |
| `riverpod_generator` | 4.0.3 | Provider code generation |
| `go_router` | 14.x | Deep-linking (`/restaurant/{id}`, `/search?q=...`) |
| `google_fonts` | 6.x | Outfit (headings) + Inter (body) |
| `flutter_map` | 7.x | Map widget with CartoDB dark tiles |
| `flutter_map_marker_cluster` | 1.4.x | Pin clustering (orange clusters, red individual) |
| `geolocator` | 14.0.2 | Browser geolocation (upgraded from 10.x in v9.35) |
| `cloud_firestore` | 5.x | Firestore data source |
| `firebase_core` | 3.x | Firebase initialization |
| `firebase_analytics` | 12.2.0 | Event tracking with consent mode v2 |
| `url_launcher` | 6.x | External links (website, Google Maps, YouTube) |
| `collection` | 1.19.x | `groupBy` and collection utilities |

## Design Tokens

| Token | Value | Usage |
|-------|-------|-------|
| DDD Red | `#DD3333` | Primary brand, open restaurant pins |
| DDD Orange | `#DA7E12` | Accent, rating stars, cluster bubbles |
| Dark Surface | `#1E1E1E` | Cookie banner, dark mode backgrounds |
| Closed Grey | `#888888` | Closed restaurant pins |
| Heading Font | Outfit | Trivia, section headers |
| Body Font | Inter | Card text, descriptions |

## App Structure

```
app/lib/
├── main.dart                           ← ProviderScope, Firebase init
├── models/restaurant_models.dart       ← Restaurant + NearbyRestaurant
├── providers/
│   ├── restaurant_providers.dart       ← Data, search, filtered, nearby
│   ├── location_providers.dart         ← User location, nearby computation
│   ├── trivia_providers.dart           ← 70-80+ facts, shuffle no-repeat
│   ├── cookie_provider.dart            ← Cookie consent + analytics providers
│   └── router_provider.dart            ← GoRouter config
├── services/
│   ├── data_service.dart               ← Firestore queries
│   ├── location_service.dart           ← Geolocator wrapper
│   ├── analytics_service.dart          ← Firebase Analytics + consent mode v2
│   └── cookie_consent_service.dart     ← Browser cookie read/write (dart:html)
├── theme/app_theme.dart                ← DDD design tokens
├── pages/
│   ├── home_page.dart                  ← List tab, nearby, search
│   ├── map_page.dart                   ← Map, pins, clustering, show-closed toggle
│   ├── explore_page.dart               ← Stats, enrichment info, manage cookies
│   ├── search_results_page.dart        ← Search results with proximity sort
│   ├── restaurant_detail_page.dart     ← Detail with ratings, badges, links
│   └── main_page.dart                  ← Bottom nav, cookie banner overlay
└── widgets/
    ├── search/search_bar_widget.dart
    ├── restaurant/restaurant_card.dart ← Closed badge, AKA name, distance
    ├── restaurant/dish_card.dart
    ├── restaurant/visit_card.dart
    ├── trivia/trivia_card.dart         ← "Fact X of Y" counter
    └── cookie_consent_banner.dart      ← Accept/Decline/Customize + location
```

## Cookie Consent Flow

```
First visit → Cookie banner at bottom of screen
  ├─ "Accept All" → Set all cookies → Request location → Populate nearby
  ├─ "Customize" → Modal with toggles → If Preferences ON → Request location
  └─ "Decline" → Essential only → No analytics, no location request

Categories:
  Essential (always on): App functionality
  Analytics (opt-in): Firebase Analytics page views, searches, feature usage
  Preferences (opt-in): Dark mode, location for nearby restaurants, search history

Cookie: tripledb_consent, 365 days, SameSite=Lax, Secure (HTTPS only)
```

## Firebase Analytics Events

| Event | Parameters | Gated By |
|-------|-----------|----------|
| `page_view` | `page_name` | Analytics consent |
| `search` | `search_term`, `result_count` | Analytics consent |
| `view_restaurant` | `restaurant_id`, `restaurant_name` | Analytics consent |
| `filter_toggle` | `filter_name`, `enabled` | Analytics consent |
| `external_link` | `link_type` | Analytics consent |
| `consent_given` | `analytics`, `preferences` | Always (essential) |

---

# 8. Locked Architectural Decisions

| Decision | Tool | Rationale | Locked Since |
|----------|------|-----------|-------------|
| Audio extraction | yt-dlp (local) | Free, reliable, handles age-restriction | v0.7 |
| Transcription | faster-whisper large-v3 (CUDA) | Best quality, runs on RTX 2080 SUPER | v1.10 |
| Extraction | Gemini 2.5 Flash API | 1M context, free tier, seconds per call | v1.10 |
| Normalization | Gemini 2.5 Flash API | Handles fuzzy dedup at scale | v2.11 |
| Geocoding | Nominatim (OpenStreetMap) | Free, 1 req/sec, cached | v6.28 |
| Enrichment | Google Places API (New) | All fields in one API, free tier | v7.30 |
| Database | Cloud Firestore | Free tier, real-time, Flutter SDK | v6.26 |
| Frontend | Flutter Web + Firebase Hosting | Single codebase, free hosting | v8.17 |
| State management | Riverpod 3.x with codegen | Modern, type-safe, auto-dispose | v9.35 |
| Routing | GoRouter 14.x | Deep linking, web URL support | v8.17 |
| Map | flutter_map 7.x + CartoDB dark tiles | Free, no API key, dark mode | v8.17 |
| Geolocation | geolocator 14.x | Browser Geolocation API | v9.35 |
| Analytics | Firebase Analytics + consent mode v2 | Free, GDPR-compliant | v7.34 |
| Privacy | Custom cookie consent (dart:html) | No external dependency, DDD-themed | v7.34 |
| Orchestration (current) | Claude Code + YOLO mode | Direct file access, MCP support | v9.35 |
| Orchestration (legacy) | Gemini CLI | Shell-only, Context7 MCP | v0.7–v7.34 |
| DDD `name` field | NEVER overwritten | Original DDD name is sacred | v7.33 |

---

# 9. Scripts & Tools Inventory

## Pipeline Scripts (`pipeline/scripts/`)

| Script | Purpose | Status |
|--------|---------|--------|
| `pre_flight.py` | Environment + secret validation | ✅ Active |
| `phase1_acquire.py` | yt-dlp batch downloader (600s timeout) | ✅ Active |
| `phase2_transcribe.py` | faster-whisper CUDA transcription | ✅ Active |
| `phase3_extract_gemini.py` | Gemini Flash API extraction | ✅ Active |
| `phase4_normalize.py` | Dedup + normalization | ✅ Active |
| `phase6_load_firestore.py` | JSONL → Firestore loader | ✅ Active |
| `geocode_restaurants.py` | Nominatim city→lat/lng | ✅ Active |
| `fix_unknown_states.py` | City → state inference | ✅ Active |
| `phase7_enrich.py` | Google Places API enrichment | ✅ Active |
| `phase7_load_enriched.py` | Enriched data → Firestore merge | ✅ Active |
| `phase7_refine.py` | Multi-pass refined search for no-matches | ✅ Active |
| `phase7_verify_reviews.py` | Gemini Flash LLM match verification | ✅ Active |
| `phase7_backfill_names.py` | google_current_name backfill | ✅ Active |
| `validate_extraction.py` | Extraction quality metrics | ✅ Active |
| `validate_enrichment.py` | Enrichment quality metrics | ✅ Active |
| `group_b_runner.sh` | Unattended tmux production runner | ✅ Active |
| `checkpoint_report.py` | Progress reporting for batch runs | ✅ Active |
| `checkpoint_tool.py` | Step-level checkpoint read/write | ✅ Active |
| `select_batch.py` | Batch selection for graduated runs | ✅ Active |
| `heal_batch.py` | Swap failed videos for alternatives | ✅ Active |
| `enrichment_polish.py` | Name threshold + UNCERTAIN resolution | ✅ Active |
| `clean_false_positives.py` | Remove false positive enrichment from Firestore | ✅ Active |

---

# 10. Repository Structure

```
~/dev/projects/tripledb/               ← PROJECT ROOT
├── CLAUDE.md                          ← Version lock (current iteration pointer)
├── README.md                          ← Public-facing, changelog (NEVER truncate)
├── .gitignore
├── docs/                              ← Current iteration artifacts ONLY
│   ├── ddd-design-v{P}.{I}.md
│   ├── ddd-plan-v{P}.{I}.md
│   ├── ddd-build-v{P}.{I}.md
│   ├── ddd-report-v{P}.{I}.md
│   ├── screenshots/                   ← Post-flight screenshots
│   └── archive/                       ← ALL previous iteration docs
├── pipeline/
│   ├── GEMINI.md                      ← Legacy version lock
│   ├── scripts/                       ← All Python pipeline scripts
│   ├── config/
│   │   ├── playlist_urls.txt          ← 805 YouTube URLs
│   │   └── extraction_prompt.md       ← Gemini Flash extraction prompt (LOCKED)
│   └── data/                          ← ALL gitignored
│       ├── audio/                     ← 778 mp3 files
│       ├── transcripts/               ← 774 JSON files
│       ├── extracted/                 ← 773 JSON files
│       ├── normalized/                ← restaurants.jsonl, videos.jsonl
│       ├── enriched/                  ← restaurants_enriched.jsonl, places_cache.json, name_backfill.jsonl
│       ├── checkpoints/               ← Step-level checkpoint JSON
│       └── logs/                      ← Enrichment logs, verification logs
├── app/                               ← Flutter Web application
│   ├── GEMINI.md                      ← Legacy version lock (app context)
│   ├── pubspec.yaml
│   ├── lib/                           ← Dart source (see App Architecture section)
│   ├── web/                           ← Web entry point, index.html, firebase config
│   ├── build/web/                     ← Built output (gitignored)
│   ├── assets/data/
│   │   └── sample_restaurants.jsonl   ← 50 geocoded records (fallback)
│   ├── design-brief/                  ← Scrapes, tokens, component patterns from v8
│   ├── docs/                          ← App-specific iteration docs
│   │   └── archive/
│   └── firebase.json
```

---

# 11. Known Gotchas

| # | Gotcha | Details |
|---|--------|---------|
| 1 | **CUDA path** | `LD_LIBRARY_PATH=/usr/local/lib/ollama/cuda_v12:$LD_LIBRARY_PATH` at SHELL level, not Python level |
| 2 | **fish shell** | No heredocs (`<< EOF`), no process substitution (`<(...)`). Use `printf`, `cat <<'EOF'` (in bash), or temp files |
| 3 | **yt-dlp flags** | Always `--remote-components ejs:github --cookies-from-browser chrome`. 600s timeout on subprocess |
| 4 | **GPU contention** | Stop Ollama before transcription. Kill orphaned Python/CUDA processes (`nvidia-smi`) |
| 5 | **dart:html deprecation** | `cookie_consent_service.dart` uses deprecated `dart:html`. Migration to `package:web` + `dart:js_interop` is a future task |
| 6 | **Cookie Secure flag** | Conditional on HTTPS. Local HTTP testing writes cookies without Secure flag (v9.38 fix) |
| 7 | **Cookie expires format** | Must be RFC 1123 (`Thu, 27 Mar 2027 00:00:00 GMT`), NOT ISO 8601 (v9.38 fix) |
| 8 | **Flutter canvas rendering** | DOM inspection sees nothing — use Playwright accessibility tree snapshots for testing |
| 9 | **Riverpod 3 auto-retry** | Left at default. Disable with `ProviderScope(retry: (_, __) => null)` if it causes issues |
| 10 | **Cloudflare WARP TLS** | Python `requests` may fail with TLS errors. Disconnect WARP temporarily |
| 11 | **Nominatim rate limit** | 1 req/sec. Cache results in `geocode_cache.json` |
| 12 | **Places API rate limit** | 100 req/s. 0.15s courtesy delay in scripts |
| 13 | **Restaurant `name` field** | NEVER overwrite. DDD original name is sacred. `google_current_name` is the mutable field |
| 14 | **README changelog** | NEVER truncate. ALWAYS append. Post-flight Gate verifies count ≥ expected |
| 15 | **Build log mandatory** | Full transcript. Every command, every output. NOT optional |
| 16 | **Working directories** | Pipeline: `~/dev/projects/tripledb/pipeline/`. App: `~/dev/projects/tripledb/app/`. Docs/README: project root |
| 17 | **tmux for batch runs** | `tmux new -s tripledb './scripts/group_b_runner.sh 2>&1 \| tee data/logs/group_b_run.log'` |
| 18 | **Manifest CSV whitespace** | `phase2_transcribe.py` must `.strip()` video_id from manifest rows |

---

# 12. Current State (After v9.38)

## Pipeline Data

| Metric | Value |
|--------|-------|
| Videos in playlist | 805 |
| Videos downloaded | 778 |
| Videos transcribed | 774 |
| Videos extracted | 773 |
| 4 un-transcribed | `-POlklcD08A`, `fPyZJ3nc4aU`, `nW3-eBVkZMY`, `sU2ltGDqFos` (exceeded 600s timeout) |
| Unique restaurants | 1,102 |
| Unique dishes | 2,286 |
| Total visits | 2,336 |
| Dedup merges | 432 |
| States (valid, excl. UNKNOWN) | 62 |
| UNKNOWN state restaurants | 33 |

## Enrichment

| Metric | Value |
|--------|-------|
| Enriched (verified) | 582 (52.8%) |
| Auto-accepted (≥0.85) | 342 |
| LLM-verified (YES) | 112 |
| LLM-verified (UNCERTAIN, kept) | 15 |
| Refined matches (v7.32) | 83 |
| Not enriched (no match) | 379 |
| Skipped (null name) | 15 |
| False positives removed | 137 (126 v7.32 + 11 v7.34) |
| Permanently closed | 30 |
| Temporarily closed | 11 |
| Genuine name changes (0.90 threshold) | 279 |
| Geocoded (Nominatim + Google backfill) | 1,006 (91.3%) |
| Avg Google rating (enriched) | 4.4 stars |
| API cost (total enrichment) | $0 |

## App (tripledb.net)

- Live with full Firestore data
- Cookie consent banner (Accept/Decline/Customize)
- Firebase Analytics with consent mode v2
- 1,006 map pins with clustering (orange clusters, red open, grey closed)
- "Show closed" filter toggle
- "Nearby Restaurants" showing 15 results with distance in miles
- Search with proximity tiebreaker
- 70-80+ trivia facts with no-repeat shuffle and "Fact X of Y" counter
- Restaurant detail with ratings, badges, YouTube deep links, website/Maps links
- "Now known as" for renamed restaurants
- "Permanently Closed" banners
- Dark mode toggle
- Location permission tied to cookie Preferences consent

## Firestore

- Project: tripledb-e0f77
- `restaurants`: 1,102 documents (582 with enrichment fields)
- `videos`: 773 documents

---

# 13. Work Remaining to MVP

## Must-Have (MVP Blockers)

| Item | Priority | Effort |
|------|----------|--------|
| Verify cookie banner + location flow on production (tripledb.net) | P0 | Manual test |
| `dart:html` → `package:web` migration for WASM compatibility | P1 | 1 iteration |
| Firestore security rules (currently wide open) | P1 | 1 iteration |

## Should-Have (Post-MVP Polish)

| Item | Priority | Effort |
|------|----------|--------|
| Photos integration (Places Photos API → app UI) | P2 | 1 iteration |
| YouTube embedded player on detail pages | P2 | 1 iteration |
| Firestore pagination/lazy loading for list view | P2 | 1 iteration |
| Accessibility: semantic labels on map pins, screen reader support | P2 | 1 iteration |
| Unit + widget tests (trivia generator, haversine, cookie service) | P2 | 1 iteration |

## Nice-to-Have (Future)

| Item | Priority | Effort |
|------|----------|--------|
| Google Play / App Store deployment | P3 | 2-3 iterations |
| Saved favorites / road trip planner | P3 | 2 iterations |
| User accounts (Firebase Auth) | P3 | 2 iterations |
| Resolve 379 unmatched restaurants (manual review tool) | P3 | 1 iteration |
| Resolve 33 UNKNOWN state restaurants | P3 | 1 iteration |
| flutter_map 7.x → 8.x upgrade | P3 | 1 iteration |

---

# CLAUDE.md Template

```markdown
# TripleDB — Agent Instructions

## Current Iteration: {P}.{I}

Read these two documents in order, then execute the plan:

1. docs/ddd-design-v{P}.{I}.md
2. docs/ddd-plan-v{P}.{I}.md

## MCP Servers
- Playwright MCP: Post-flight functional testing
- Context7: Flutter/Dart API docs

## Rules That Never Change
- NEVER run git add, git commit, git push, or firebase deploy
- NEVER ask permission — YOLO mode, code dangerously
- Self-heal: diagnose → fix → re-run (max 3, then skip)
- 3 consecutive identical errors = STOP
- MUST produce ddd-build and ddd-report before ending
- ddd-build must be FULL transcript
- CHECKPOINT after every numbered step
- README changelog: NEVER truncate — ALWAYS append
- POST-FLIGHT: Tier 1 + Tier 2 playbook must pass (if Flutter iteration)
- Include Orchestration Report in ddd-report
```
