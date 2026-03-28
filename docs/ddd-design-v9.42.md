# TripleDB — Design v9.42

**ADR-001 | Living Architecture Document**
**Last Updated:** Phase 9, Iteration 42
**Author:** Kyle Thompson, Managing Partner & Solutions Architect @ TachTech Engineering
**Repository:** `git@github.com:TachTech-Engineering/tripledb.git`
**Live Site:** [tripledb.net](https://tripledb.net)
**Firebase Project:** tripledb-e0f77

---

# Table of Contents

1. [Project Mandate](#1-project-mandate)
2. [IAO Methodology — The Nine Pillars](#2-iao-methodology)
3. [Iteration History (Phase-Ordered)](#3-iteration-history)
4. [Environment Setup (From Scratch)](#4-environment-setup)
5. [Pipeline Architecture](#5-pipeline-architecture)
6. [Data Model](#6-data-model)
7. [App Architecture](#7-app-architecture)
8. [Locked Architectural Decisions](#8-locked-decisions)
9. [Scripts & Tools Inventory](#9-scripts-inventory)
10. [Repository Structure](#10-repository-structure)
11. [Known Gotchas](#11-known-gotchas)
12. [Current State](#12-current-state)
13. [Hardening Framework](#13-hardening-framework)
14. [Technology Radar](#14-technology-radar)
15. [README Formatting Guide](#15-readme-formatting)
16. [Phase 10 — UAT Handoff Architecture](#16-phase-10)

---

# 1. Project Mandate

## What TripleDB Is

A passion project that processes 805 YouTube videos from Guy Fieri's "Diners, Drive-Ins and Dives" (DDD) into a structured Firestore database of restaurants, dishes, ingredients, and iconic Guy Fieri moments. The name: **Triple D** (the show's nickname) + **DB** (database).

The output is a Flutter Web app at **tripledb.net** where users can find a diner near them, search by anything (dish, cuisine, city, chef, ingredients), watch the exact YouTube timestamp where Guy walks in, see what's still open with Google-verified ratings, and explore trivia and stats.

## Cost Model

| Component | Cost |
|-----------|------|
| Local inference (faster-whisper, Ollama) | Free |
| Gemini CLI orchestration | Free tier |
| Gemini 2.5 Flash API | Free tier |
| Google Places API (enrichment) | Free tier |
| Nominatim geocoding | Free |
| Cloud Firestore | Free tier (Spark) |
| Firebase Hosting + Analytics | Free tier |
| **Total** | **$0** |

---

# 2. IAO Methodology — The Nine Pillars

## What IAO Is

Iterative Agentic Orchestration — a development methodology where LLM agents execute project phases autonomously while humans review versioned artifacts between iterations. Each iteration produces a plan (input) and a report (output). The report informs the next plan. The methodology itself evolves alongside the project.

The pillars evolved through 42 iterations: 6 (v3.12) → 8 (v5.14) → 9 (v9.41).

---

## Pillar 1 — Artifact Loop

Every iteration produces **five** artifacts: design (living architecture), plan (execution steps), build (full session transcript), report (metrics + recommendation), and **changelog** (versioned snapshot). These are the single source of truth — not chat history, not memory, not git diffs. The report informs the next plan. The design accumulates decisions across iterations. Previous artifacts are archived to `docs/archive/` and only the current iteration's docs live in `docs/`. Agents never see outdated instructions, but the full history is preserved.

Each iteration report includes an **Orchestration Report**: a breakdown of which agents, MCP servers, APIs, and scripts were used, their approximate workload share, and their efficacy. This feeds Pillar 9's retrospective.

### Artifact Spec

| Direction | File | Author | Purpose |
|-----------|------|--------|---------|
| Input | `ddd-design-v{P}.{I}.md` | Claude (chat) | Living architecture, locked decisions |
| Input | `ddd-plan-v{P}.{I}.md` | Claude (chat) | Execution steps, success criteria, playbook |
| Output | `ddd-build-v{P}.{I}.md` | Executing agent | Full session transcript |
| Output | `ddd-report-v{P}.{I}.md` | Executing agent | Metrics, orchestration report, recommendation |
| Output | `ddd-changelog-v{P}.{I}.md` | Executing agent | Versioned snapshot of README changelog section |
| Output | `README.md` (updated) | Executing agent | Status, metrics, changelog (APPEND only) |

### Changelog Resilience (v9.42+)

The README changelog has been the single most fragile artifact across 42 iterations — agents repeatedly attempt to truncate it. Starting v9.42, a versioned changelog copy is produced after each iteration:

1. After updating `README.md`, the agent copies the full changelog section to `docs/ddd-changelog-v{P}.{I}.md`
2. Post-flight verifies BOTH the README changelog count AND the docs copy exist
3. If the README changelog is ever corrupted (truncated, rewritten, lost in a bad merge), reconstruct it from the latest `ddd-changelog-v{P}.{I}.md` in `docs/`
4. The changelog file in `docs/` is archived alongside other artifacts to `docs/archive/`
5. This file also serves as a git-independent audit trail for issue tracking and troubleshooting

---

## Pillar 2 — Agentic Orchestration

The primary agent orchestrates a constellation of LLMs, MCP servers, scripts, APIs, and sub-agents to understand the design, execute the plan, capture the build, and produce the report. The version lock file (`CLAUDE.md` or `GEMINI.md`) at project root points to the current design and plan docs — the launch command never changes.

**Agent Permissions:**

| Action | Allowed? | Notes |
|--------|----------|-------|
| `flutter build web` | ✅ YES | Agents build freely |
| `firebase deploy --only hosting` | ✅ YES | Agents deploy hosting |
| `firebase deploy --only firestore:rules` | ✅ YES | Agents deploy rules |
| `git add / commit / push` | ❌ NEVER | Kyle commits at PHASE boundaries |
| Ask the human a question | ❌ LAST RESORT | Only if continuing would be destructive |

**Git Commit Model:** Kyle commits at **phase boundaries**, not iteration boundaries. Commit messages: `"KT starting {P}.{I}"` (pre-launch) and `"KT completed {P}.{I}"` (post-review). This means multiple iterations may land in a single commit. The artifact trail in `docs/archive/` preserves the per-iteration history that git does not. The versioned changelog in `docs/` provides additional resilience against git-level issues.

**Two-Environment Model:**

| Environment | Agent | Scope | Mode |
|-------------|-------|-------|------|
| **Dev** | Claude Code | ALL phases — pipeline, app, enrichment, everything | YOLO. Kyle + Claude troubleshoot, debug, iterate, tighten plans. |
| **UAT** | Gemini CLI | ALL phases — same pipeline, same app, same enrichment | YOLO. Gemini executes battle-hardened plans. Single session, auto-chain artifacts, zero human review. |

Claude is the R&D lab. Gemini is the factory floor. If Gemini hits a wall in UAT, the plan wasn't tight enough — it goes back to Claude in dev.

Dev never ends. Phase 10 is a UAT handoff for TripleDB specifically, but new features, bugs, and new projects always run in Dev.

**Tool Ecosystem:**

| Tool | Category | Purpose |
|------|----------|---------|
| Claude Code (Opus) | Primary executor (Dev) | Problem-solving, debugging, complex refactors |
| Gemini CLI | Primary executor (UAT) | Batch execution of proven plans |
| Gemini 2.5 Flash API | LLM API | Extraction, normalization, LLM verification |
| Playwright MCP | Browser automation | Post-flight functional testing |
| Puppeteer (npm) | Browser automation | Fallback for Playwright |
| Context7 MCP | Documentation | Flutter/Dart API docs |
| Lighthouse MCP / CLI | Performance audit | Perf, a11y, SEO, best practices scoring |
| Firebase Admin SDK | Database | Firestore CRUD |
| Google Places API (New) | Enrichment | Ratings, open/closed, websites |
| Nominatim | Geocoding | City → lat/lng |
| faster-whisper | Local ML | CUDA transcription |
| yt-dlp | Media | YouTube → mp3 |
| tmux + bash | Unattended runner | Group B production batches |

---

## Pillar 3 — Zero-Intervention Target

Every question the agent asks during execution is a failure in the plan document. Pre-answer every decision point. Pre-set every environment variable. Pre-document every gotcha. Measure plan quality by counting interventions — zero is the floor, not the ceiling.

If the agent encounters an uncovered situation, it makes the best decision, logs its reasoning in the build log, and continues. YOLO mode (`claude --dangerously-skip-permissions` for Dev, `gemini` with full autonomy rules for UAT) is the default execution model — code dangerously, move fast, and let the post-flight catch what the pre-flight missed. Asking the human is a last resort reserved for situations where continuing would be destructive.

---

## Pillar 4 — Pre-Flight Verification

Before execution begins, validate the environment: API keys set and reachable, services responding, dependencies installed, git status clean, previous iteration archived. After the iteration completes, verify that `flutter build web` and `firebase deploy` timestamps are more recent than the build artifact timestamp. If any deployment step is stale, the iteration isn't live.

### Standard Pre-Flight Checklist

```
[ ] Previous docs archived to docs/archive/
[ ] New design + plan in docs/
[ ] CLAUDE.md (or GEMINI.md) updated
[ ] git status clean ("KT starting {P}.{I}" committed)
[ ] API keys set ($GOOGLE_PLACES_API_KEY, $GEMINI_API_KEY as needed)
[ ] flutter analyze: 0 errors (baseline)
[ ] flutter build web: success (baseline)
[ ] Pipeline pre_flight.py passes (if pipeline iteration)
```

---

## Pillar 5 — Self-Healing Execution

Errors are inevitable. When one occurs: diagnose → fix → re-run. Max 3 attempts per error, then log and skip. If 3 consecutive items fail with the same error, STOP the batch, fix the root cause, restart. Never burn through hundreds of items with a known systemic failure.

**Checkpoint scaffolding:** Long-running iterations write a JSON checkpoint file (`pipeline/data/checkpoints/v{P}.{I}_checkpoint.json`) after each completed step. On session start, the agent reads the checkpoint and skips completed steps. If the terminal crashes, the session hangs, or the agent is interrupted, relaunch picks up at the next step. The checkpoint is deleted after all artifacts are written.

```json
{
  "iteration": "9.42",
  "last_completed_step": 3,
  "step_name": "Security Audit",
  "timestamp": "2026-03-28T20:00:00Z"
}
```

---

## Pillar 6 — Progressive Batching

Start small. Each batch is bigger and harder. 30 → 60 → 90 → 120 → 805 videos. 50 → 1,102 restaurants for enrichment. By the time you run the production batch, every failure mode has been seen, logged, and handled.

Once proven through graduated batches, graduate execution from interactive agent (Group A) to unattended bash + tmux scripts (Group B) to eliminate token spend on repetitive work.

---

## Pillar 7 — Post-Flight Functional Testing

Two-tier verification after every iteration that touches frontend code.

**Tier 1 — Standard Health:**
- App bootstraps (not white screen)
- Browser console has zero uncaught errors
- Changelog integrity (≥ expected count)
- Versioned changelog snapshot exists in `docs/`

**Tier 2 — Iteration Playbook:**
Playwright/Puppeteer executes a functional test sequence specific to that iteration's deliverables — clicking buttons, verifying state changes, confirming persistence, reading the accessibility tree. Every plan that touches Flutter code includes a `## Post-Flight Playbook` section.

Flutter Web renders to `<canvas>` — screenshots prove nothing. Accessibility tree verification and interactive user-like actions are required.

**Tier 2 exemption:** Iterations that change only documentation (design doc, README, CLAUDE.md) skip Tier 2. Tier 1 still applies if a build is produced.

**Tier 3 — Hardening Audit (v9.42+):**
Dedicated audit pass covering performance, accessibility, security, and compatibility. See Section 13 (Hardening Framework) for the full spec. Tier 3 is run during hardening iterations and produces a scored baseline that subsequent iterations can measure against.

---

## Pillar 8 — Mobile-First Flutter + Firebase (Zero-Cost by Design)

Flutter is not just the tech stack — it's a strategic decision. Single codebase: web today, Play Store and App Store tomorrow. Firebase free tier covers hosting, Firestore, and Analytics. Mobile-first responsive design scales up to desktop, not the other way around.

**Cost is a design constraint, not a happy accident.** Every tool choice favors free-tier or zero-cost:

| Decision Point | Choice | Cost |
|----------------|--------|------|
| Transcription | faster-whisper (local CUDA) | $0 |
| Extraction LLM | Gemini 2.5 Flash API (free tier) | $0 |
| Geocoding | Nominatim (OpenStreetMap) | $0 |
| Enrichment | Google Places API (free tier) | $0 |
| Database | Cloud Firestore (Spark plan) | $0 |
| Hosting | Firebase Hosting (free tier) | $0 |
| Analytics | Firebase Analytics (free tier) | $0 |
| Dev agent | Claude Code (subscription) | Sunk cost |
| UAT agent | Gemini CLI (free tier) | $0 |

**Production at scale:** 805 videos, 1,102 restaurants, 2,286 dishes, live app at tripledb.net = $0 total infrastructure cost.

---

## Pillar 9 — Continuous Improvement

IAO evolves alongside every project and crystallizes into institutional knowledge at project close. At project end, the agent performs a structured retrospective:

1. **Archive Review** — scan `docs/archive/` to assess plan quality and intervention patterns
2. **Tool Efficacy** — synthesize orchestration reports into a tools matrix
3. **Architectural Documents** — produce final ADRs, environment setup, onboarding docs
4. **Technology Radar** — deep analysis of new agents, LLMs, MCP servers, and orchestration frameworks. See Section 14 for the full framework.

The pillars themselves are artifacts of this process: 6 (v3.12) → 8 (v5.14) → 9 (v9.41).

---

# 3. Iteration History (Phase-Ordered)

## Phase 0 — Setup

| Iter | Status | Key Result | Enrichment State |
|------|--------|------------|-----------------|
| v0.7 | ✅ | Monorepo scaffolded, 805 URLs, fish shell gotchas | N/A |

## Phase 1 — Discovery (30 videos)

| Iter | Status | Key Result | Enrichment State |
|------|--------|------------|-----------------|
| v1.8 | ❌ | Nemotron 42GB on 8GB VRAM = timeout loops | N/A |
| v1.9 | ❌ | Qwen 3.5-9B too slow for structured extraction | N/A |
| v1.10 | ✅ | Gemini Flash API solved extraction. 186 restaurants, 290 dishes | N/A |

## Phase 2 — Calibration (60 videos cumulative)

| Iter | Status | Key Result | Enrichment State |
|------|--------|------------|-----------------|
| v2.11 | ✅ | 422 restaurants, 624 dishes. CUDA path must be shell-level. 20+ interventions | N/A |

## Phase 3 — Stress Test (90 videos cumulative)

| Iter | Status | Key Result | Enrichment State |
|------|--------|------------|-----------------|
| v3.12 | ✅ | **Zero interventions.** Autonomous batch healing. 511 restaurants, 98 dedup merges | N/A |

## Phase 4 — Validation (120 videos cumulative)

| Iter | Status | Key Result | Enrichment State |
|------|--------|------------|-----------------|
| v4.13 | ✅ | 608 restaurants, 162 merges. Prompts locked. Group B green-lit | N/A |

## Phase 5 — Production Run (805 videos)

| Iter | Status | Key Result | Enrichment State |
|------|--------|------------|-----------------|
| v5.14 | ✅ | Runner infrastructure, null-name fix, Eight Pillars documented | N/A |
| v5.15 | ✅ | 773 extracted. 14-hour unattended tmux run. 4 timeout skips | N/A |

## Phase 6 — Firestore + Geocoding + Polish

| Iter | Status | Key Result | Enrichment State |
|------|--------|------------|-----------------|
| v6.26 | ✅ | 1,102 restaurants loaded to Firestore. App wired | N/A |
| v6.27 | ⚠️ | Geolocation fix broke Firestore (reverted v6.28) | N/A |
| v6.28 | ✅ | 916/1102 geocoded via Nominatim. Map working | Geocoded: 916 (83.1%) |
| v6.29 | ✅ | Trivia state count fix, map pin clustering, README refresh | Geocoded: 916 |

## Phase 7 — Enrichment + Analytics

| Iter | Status | Key Result | Enrichment State |
|------|--------|------------|-----------------|
| v7.30 | ✅ | Google Places API pipeline built. 50-restaurant batch: 66.7% match | Enriched: 30, Geocoded: 920 |
| v7.31 | ✅ | Full run: 625 enriched at 55.9%. 1 intervention (API key) | Enriched: 625, Closed: 32, Geocoded: 924 |
| v7.32 | ✅ | Refined search: 83 recovered. LLM verification: 126 false positives removed | Enriched: 582, Closed: 30, Geocoded: 1,006 |
| v7.33 | ✅ | AKA names backfilled (283 changes). Grey pins, closed filter, checkpointing | Enriched: 582, Names: 283, Closed: 30 |
| v7.34 | ✅ | Cookie consent (GDPR/CCPA). Firebase Analytics consent mode v2. Name threshold 0.90 | Enriched: 582, Names: 279, Closed: 34 |

## Phase 8 — Flutter App

| Iter | Status | Key Result | Enrichment State |
|------|--------|------------|-----------------|
| v8.17–21 | ✅ | Pass 1: scaffold + core features (thin QA) | N/A |
| v8.22–25 | ✅ | Pass 2: design tokens, component patterns. Lighthouse A11y 92, SEO 100 | N/A |

## Phase 9 — App Optimization + Hardening

| Iter | Status | Executor | Key Result | Enrichment State |
|------|--------|----------|------------|-----------------|
| v9.35 | ✅ | Claude Code | Riverpod 2→3, geolocator 10→14, 70+ trivia, 15 nearby | Enriched: 582 |
| v9.36 | ✅ | Claude Code | White screen crash fix (lazy init, deferred DOM) | Enriched: 582 |
| v9.37 | ✅ | Claude Code | Post-flight protocol v1 (Pillar 7 established) | Enriched: 582 |
| v9.38 | ✅ | Claude Code | Cookie banner fix (Secure flag, RFC 1123, robust parsing). Functional playbook | Enriched: 582 |
| v9.39 | ✅ | Claude Code | 3 bug fixes: Unknown filter, dedup, location-on-consent. 7/7 playbook pass | Enriched: 582 |
| v9.40 | ✅ | Claude Code | dart:html → package:web. Firestore security rules. 7/7 playbook pass | Enriched: 582 |
| v9.41 | ✅ | Claude Code | Nine Pillars, methodology update, README overhaul, CLAUDE.md update | Enriched: 582 |
| v9.42 | 🔧 | Claude Code | Hardening audit: Lighthouse, error boundaries, security, browser compat | Enriched: 582 |

---

# 4. Environment Setup (From Scratch)

Target: CachyOS (Arch Linux) with KDE Plasma, Wayland, fish shell.

## One-Shot Install Commands

Paste these blocks into fish shell on a fresh Arch/CachyOS machine:

### System Packages (pacman)

```fish
sudo pacman -S base-devel git fish tmux python python-pip nodejs npm \
  nvidia nvidia-utils cuda cudnn chromium jq --needed
```

### AUR Packages (yay)

```fish
yay -S flutter-bin android-studio google-cloud-cli visual-studio-code-bin
```

**Note:** After `flutter-bin`, grant group permissions:
```fish
sudo groupadd flutterusers
sudo gpasswd -a $USER flutterusers
sudo chown -R :flutterusers /opt/flutter
sudo chmod -R g+w /opt/flutter
```
Log out and back in for group to apply.

### Android Studio SDK Setup

1. Launch Android Studio → standard setup wizard
2. Plugins → install "Flutter" (accept Dart prompt)
3. Settings → Languages & Frameworks → Android SDK → SDK Tools → check "Android SDK Command-line Tools (latest)" → Apply
4. Close Android Studio

```fish
flutter doctor --android-licenses
```

### npm Global Packages

```fish
npm install -g @anthropic-ai/claude-code puppeteer firebase-tools @google/gemini-cli
```

### pip Packages

```fish
pip install --break-system-packages faster-whisper requests firebase-admin yt-dlp google-cloud-firestore
```

## Fish Shell Configuration

File: `~/.config/fish/config.fish`

```fish
# CachyOS base
source /usr/share/cachyos-fish-config/cachyos-fish-config.fish

# Path
set -gx PATH $HOME/.local/bin $HOME/.npm-global/bin $PATH

# Android SDK
set -gx ANDROID_HOME $HOME/Android/Sdk
set -gx PATH $PATH $ANDROID_HOME/platform-tools $ANDROID_HOME/cmdline-tools/latest/bin

# CUDA (for faster-whisper transcription)
set -gx LD_LIBRARY_PATH /usr/local/lib/ollama/cuda_v12 $LD_LIBRARY_PATH

# API Keys — NEVER screenshot or commit these
set -gx GEMINI_API_KEY "your-gemini-api-key"
set -gx GOOGLE_PLACES_API_KEY "your-places-api-key"
set -gx GOOGLE_CLOUD_PROJECT "tripledb-e0f77"

# Cloudflare WARP TLS (if applicable)
set -gx NODE_EXTRA_CA_CERTS "/etc/ssl/certs/Gateway_CA_-_Cloudflare_Managed_G1_3d028af29af87d79a8b3245461f04241.pem"
```

Reload: `source ~/.config/fish/config.fish`

## SSH Key Setup (GitHub via Bitwarden)

```fish
mkdir -p ~/.ssh; chmod 700 ~/.ssh
# Copy private key from Bitwarden Secure Notes to:
nano ~/.ssh/id_ed25519_sockjt
chmod 600 ~/.ssh/id_ed25519_sockjt
```

File: `~/.ssh/config`
```
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_sockjt
```

Test: `ssh -T git@github.com`

## Claude Code MCP Configuration

File: `~/.config/claude/mcp.json` (or project-level `.mcp.json`):

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest", "--headless"]
    }
  }
}
```

## Gemini CLI MCP Configuration (for UAT)

File: `~/.gemini/settings.json`:

```json
{
  "security": {
    "auth": {
      "selectedType": "gemini-api-key"
    }
  },
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"]
    },
    "lighthouse": {
      "command": "npx",
      "args": ["-y", "lighthouse-mcp"]
    },
    "firecrawl": {
      "command": "npx",
      "args": ["-y", "firecrawl-mcp"],
      "env": {
        "FIRECRAWL_API_KEY": "YOUR_FIRECRAWL_KEY"
      }
    }
  }
}
```

Verify: launch `gemini`, type `/mcp` — all servers should show green.

## Firebase CLI

```fish
firebase login
firebase use tripledb-e0f77
firebase projects:list | grep tripledb
```

## GCP Console Steps

1. Enable **Places API (New)** on project tripledb-e0f77
2. Enable **Generative Language API** (Gemini)
3. Create API key restricted to above APIs
4. Store in fish config (see above)

## Repository Clone + First Run

```fish
mkdir -p ~/dev/projects
cd ~/dev/projects
git clone git@github.com:TachTech-Engineering/tripledb.git
cd tripledb

# Flutter app
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter build web

# Pipeline
cd ../pipeline
python3 scripts/pre_flight.py
```

---

# 5. Pipeline Architecture

```
YouTube Playlist (805 videos)
    ↓ yt-dlp (local)               --remote-components ejs:github
MP3 Audio                           --cookies-from-browser chrome
    ↓ faster-whisper large-v3       LD_LIBRARY_PATH=/usr/local/lib/
      (local CUDA)                  ollama/cuda_v12:$LD_LIBRARY_PATH
Timestamped Transcripts
    ↓ Gemini 2.5 Flash API          Free tier. 1M context. No chunking.
Extracted Restaurant JSON
    ↓ Gemini 2.5 Flash API          Dedup by name+city. Merge dishes.
Normalized JSONL (1,102 restaurants)
    ↓ Nominatim (OpenStreetMap)      1 req/sec. geocode_cache.json.
Geocoded Data (1,006 with coords)
    ↓ Google Places API (New)        Text Search → Place Details. ≥0.70 match.
Enriched Data (582 verified)
    ↓ Firebase Admin SDK             Merge updates. Never overwrite originals.
Cloud Firestore
    ↓ Flutter Web
tripledb.net
```

---

# 6. Data Model

## Collection: `restaurants` (1,102 docs)

```json
{
  "restaurant_id": "r_<uuid4>",
  "name": "Mama's Soul Food",
  "google_current_name": "Fat Mo's",
  "name_changed": true,
  "city": "Memphis", "state": "TN",
  "formatted_address": "123 Main St, Memphis, TN 38103",
  "latitude": 35.1396, "longitude": -90.0541,
  "cuisine_type": "Soul Food",
  "owner_chef": "Tyrone Washington",
  "still_open": true,
  "business_status": "OPERATIONAL",
  "google_place_id": "ChIJ...",
  "google_rating": 4.6, "google_rating_count": 1247,
  "google_maps_url": "...", "website_url": "...",
  "photo_references": ["AfLeUg..."],
  "enriched_at": "<timestamp>",
  "enrichment_source": "google_places_api",
  "enrichment_match_score": 0.92,
  "enrichment_verified": true,
  "visits": [{ "video_id": "...", "guy_intro": "...", "timestamp_start": 200.0 }],
  "dishes": [{ "dish_name": "...", "ingredients": [...], "guy_response": "..." }],
  "created_at": "<timestamp>", "updated_at": "<timestamp>"
}
```

## Collection: `videos` (773 docs)

```json
{
  "video_id": "<11-char YouTube ID>",
  "youtube_url": "...", "title": "...",
  "duration_seconds": 1619, "video_type": "compilation",
  "restaurant_count": 5, "processed_at": "<timestamp>"
}
```

---

# 7. App Architecture

## Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Framework | Flutter Web | 3.x |
| State management | Riverpod 3.x with codegen | 3.3.1 |
| Routing | GoRouter | 14.x |
| Database | Cloud Firestore | — |
| Map | flutter_map 7.x + CartoDB dark tiles | 7.x |
| Geolocation | geolocator | 14.0.2 |
| Analytics | Firebase Analytics + consent mode v2 | — |
| Cookie access | `package:web` (`dart:js_interop`) | 1.1.1 |
| Hosting | Firebase Hosting | — |
| Security rules | Firestore read-only public, write denied | v9.40 |

## Cookie Consent Flow

1. App bootstraps → `CookieConsentService` reads `tripledb_consent` via `package:web`
2. No cookie → show banner (Accept All / Reject Non-Essential)
3. Accept All → write cookie (Secure flag conditional on HTTPS, RFC 1123 expires) → enable Analytics → request geolocation
4. Reject → write cookie with `analytics=false` → skip Analytics → skip geolocation
5. On reload → cookie persists → banner suppressed → respect stored preferences

## Firebase Analytics Events

All events gated on consent. Consent mode v2 (`analytics_storage`, `ad_storage`, `ad_personalization`, `ad_user_data`) defaulted to `denied`, flipped to `granted` only on explicit accept.

## Design Tokens

```dart
static const dddRed = Color(0xFFCC0000);
static const dddYellow = Color(0xFFFFD700);
static const dddBlack = Color(0xFF1A1A1A);
static const dddDark = Color(0xFF2D2D2D);
static const dddCardBg = Color(0xFF3A3A3A);
```

---

# 8. Locked Architectural Decisions

| Decision | Tool | Locked Since |
|----------|------|-------------|
| Audio extraction | yt-dlp (local) | v0.7 |
| Transcription | faster-whisper large-v3 (CUDA) | v1.10 |
| Extraction | Gemini 2.5 Flash API | v1.10 |
| Normalization | Gemini 2.5 Flash API | v2.11 |
| Geocoding | Nominatim | v6.28 |
| Enrichment | Google Places API (New) | v7.30 |
| Database | Cloud Firestore | v6.26 |
| Frontend | Flutter Web + Firebase Hosting | v8.17 |
| State management | Riverpod 3.x with codegen | v9.35 |
| Map | flutter_map 7.x + CartoDB dark | v8.17 |
| Analytics | Firebase Analytics + consent mode v2 | v7.34 |
| Cookie access | `package:web` + `dart:js_interop` | v9.40 |
| Firestore rules | Read-only public, write denied | v9.40 |
| Dev executor | Claude Code (YOLO) | v9.35 |
| UAT executor | Gemini CLI (YOLO) | Phase 10 (planned) |
| Restaurant `name` field | NEVER overwritten | v7.33 |

---

# 9. Scripts Inventory

| Script | Purpose | Status |
|--------|---------|--------|
| `pre_flight.py` | Environment + secret validation | ✅ |
| `phase1_acquire.py` | yt-dlp batch download (600s timeout) | ✅ |
| `phase2_transcribe.py` | faster-whisper CUDA transcription | ✅ |
| `phase3_extract_gemini.py` | Gemini Flash extraction | ✅ |
| `phase4_normalize.py` | Dedup + normalization | ✅ |
| `phase6_load_firestore.py` | JSONL → Firestore | ✅ |
| `geocode_restaurants.py` | Nominatim geocoding | ✅ |
| `phase7_enrich.py` | Google Places enrichment | ✅ |
| `phase7_load_enriched.py` | Enriched → Firestore merge | ✅ |
| `phase7_load_names.py` | google_current_name backfill | ✅ |
| `phase7_refine.py` | Multi-pass refined search | ✅ |
| `phase7_verify_reviews.py` | Gemini Flash LLM verification | ✅ |
| `phase7_backfill_names.py` | google_current_name backfill | ✅ |
| `validate_extraction.py` | Extraction quality metrics | ✅ |
| `validate_enrichment.py` | Enrichment quality metrics | ✅ |
| `group_b_runner.sh` | tmux production runner | ✅ |
| `checkpoint_tool.py` | Step-level checkpoint | ✅ |
| `enrichment_polish.py` | Threshold + UNCERTAIN cleanup | ✅ |
| `clean_false_positives.py` | Remove false pos from Firestore | ✅ |

---

# 10. Repository Structure

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
│   ├── ddd-changelog-v{P}.{I}.md  ← NEW: versioned changelog snapshot
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

# 11. Known Gotchas

| # | Gotcha |
|---|--------|
| 1 | CUDA path: `LD_LIBRARY_PATH` at SHELL level, not Python |
| 2 | fish shell: no heredocs, no process substitution |
| 3 | yt-dlp: always `--remote-components ejs:github --cookies-from-browser chrome` |
| 4 | GPU contention: stop Ollama before transcription |
| 5 | Cookie Secure flag: conditional on HTTPS (v9.38 fix) |
| 6 | Cookie expires: RFC 1123 format, not ISO 8601 (v9.38 fix) |
| 7 | Flutter canvas: use a11y tree for testing, not DOM/screenshots |
| 8 | Riverpod 3 auto-retry: left at default, disable if issues |
| 9 | Cloudflare WARP: disconnect if Python requests TLS fails |
| 10 | Restaurant `name`: NEVER overwrite (DDD original is sacred) |
| 11 | README changelog: NEVER truncate, post-flight verifies count. Versioned copy in `docs/` |
| 12 | Nearby filter: exclude Unknown/None city/state, dedup by name |
| 13 | Location consent: request BEFORE dismissing banner (widget must be mounted) |
| 14 | Firestore rules: `firebase deploy --only firestore:rules` separate from hosting |
| 15 | Agent git restriction: agents NEVER git add/commit/push. Kyle commits at phase boundaries |
| 16 | Konsole terminal: run Claude Code from Konsole, NOT IDE terminal (crashes) |
| 17 | Lighthouse on Flutter Web: `--force-renderer-accessibility` flag needed, canvas occludes DOM |
| 18 | CSP headers: Firebase Hosting sets via `firebase.json` headers array, not meta tags |

---

# 12. Current State (After v9.41)

| Metric | Value |
|--------|-------|
| Videos processed | 773 / 805 |
| Unique restaurants | 1,102 |
| Unique dishes | 2,286 |
| Total visits | 2,336 |
| Dedup merges | 432 |
| States (valid) | 62 |
| Geocoded | 1,006 (91.3%) |
| Enriched (verified) | 582 (52.8%) |
| Permanently closed | 34 |
| Temporarily closed | 11 |
| Genuine name changes | 279 |
| Avg Google rating | 4.4 ⭐ |
| `flutter analyze` | 0 issues |
| Total API cost | $0 |
| Total iterations | 41 (v0.7 – v9.41) |
| Phase 9 status | In Progress (v9.35–v9.42+, hardening) |

---

# 13. Hardening Framework

## What Hardening Is

Hardening iterations (v9.42+) systematically audit and fix the production app across four domains before Phase 10 UAT handoff. The audit produces a scored baseline. Subsequent iterations fix issues found. The number of fix iterations is driven by audit results — not predetermined.

## Domain 1: Performance (Lighthouse)

**Tool:** Lighthouse CLI or Lighthouse MCP server.

**Audit scope:**
- Performance score (target: ≥ 90)
- First Contentful Paint, Largest Contentful Paint, Total Blocking Time, Cumulative Layout Shift
- Bundle size analysis (`build/web/main.dart.js` — is tree-shaking effective?)
- Image optimization (are photo_references lazy-loaded?)
- Font loading strategy (system fonts vs. web fonts)
- Caching headers on Firebase Hosting (`firebase.json` headers config)

**Flutter-specific notes:** Lighthouse struggles with Flutter Web canvas rendering. The `--force-renderer-accessibility` flag and Puppeteer `page.click('flt-semantics-placeholder')` workaround from v9.37 applies here. Performance metrics may undercount paint events because Flutter paints to canvas, not DOM. Use `canvaskit` renderer metrics as the authoritative source.

## Domain 2: Error Boundaries

**Audit scope:**
- Firestore offline: what happens when `cloud.google.com` is unreachable? Does the app show a loading state or crash?
- Location denied: user clicks "Block" on geolocation prompt. Does nearby still show restaurants (fallback to browsing)?
- Cookie blocked: browser has cookies disabled entirely. Does the consent banner handle this gracefully?
- Invalid URL state: user navigates to `/restaurant/nonexistent-id`. 404 handling?
- Empty search results: search for gibberish. Does the UI handle zero-result state?
- Firestore cold start: first load on a slow connection. Is there a skeleton/shimmer state?

**Testing method:** Playwright/Puppeteer with network throttling, permission overrides, and direct URL navigation.

## Domain 3: Security

**Audit scope:**
- **CSP headers:** Content-Security-Policy on Firebase Hosting. Script-src, style-src, connect-src (Firestore, Analytics, Google Maps tiles). Goal: restrictive but functional.
- **Firestore rules pen test:** Attempt writes from browser devtools (`firebase.firestore().collection('restaurants').add({test:1})`). Must fail.
- **Cookie security:** HttpOnly flag feasibility (currently not set — `package:web` cannot set HttpOnly client-side). Secure flag verification on HTTPS. SameSite attribute.
- **Dependency audit:** `flutter pub outdated`, check for known CVEs in dependencies.
- **Firebase Hosting headers:** X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy.
- **Input sanitization:** Search input — does it handle XSS payloads? (Flutter Web's canvas rendering provides natural isolation, but verify.)

## Domain 4: Browser & Device Compatibility

**Audit scope:**
- **Desktop browsers:** Chrome (primary), Firefox, Safari, Edge. Verify app loads, search works, map renders, cookie banner functions.
- **Mobile browsers:** Chrome Android, Safari iOS (if available for testing). Mobile breakpoints on map, restaurant cards, search.
- **Responsive breakpoints:** ≤480px (phone), 481–768px (tablet), 769–1024px (small desktop), ≥1025px (desktop). Verify layout at each.
- **Keyboard navigation:** Tab order, focus indicators, Escape key dismisses modals.
- **Screen reader:** Basic a11y tree verification (already part of Tier 2 post-flight, extend for coverage).

**Testing method:** Playwright with multiple viewport sizes and browser contexts. Manual spot-checks on physical devices if available.

## Audit Output Format

Each domain produces a results table:

```markdown
| Item | Score/Status | Finding | Severity | Fix? |
|------|-------------|---------|----------|------|
| LCP | 2.8s | Over budget (target <2.5s) | P1 | v9.43 |
| CSP | Missing | No Content-Security-Policy header | P1 | v9.43 |
| Firefox map | ✅ | Renders correctly | — | — |
```

Severity: P0 (blocks UAT), P1 (should fix before UAT), P2 (nice to have), P3 (backlog).

The report drives the next iteration. If all findings are P2/P3, proceed to Phase 10. If P0/P1 findings exist, iterate until resolved.

---

# 14. Technology Radar

## What the Radar Is

A structured evaluation of the AI agent and orchestration ecosystem as of mid-2026, scored on architecture fit, cost model alignment, and concrete benefit to TachTech projects (TripleDB, SOC Alpha, Findlay, future engagements). This is Pillar 9's horizon scan expanded to deep analysis depth.

## Evaluation Framework

Each tool is scored on five axes:

| Axis | Weight | What It Measures |
|------|--------|-----------------|
| Architecture Fit | 30% | Does it slot into IAO's single-agent-primary model? Or does it require a paradigm shift? |
| Cost Model | 25% | Free tier? Per-token pricing? Does it violate Pillar 8's zero-cost constraint? |
| Token Efficiency | 20% | How many tokens does it consume per task vs. current approach? Context window utilization? |
| Integration Path | 15% | MCP server available? npm package? Can Claude Code call it today? |
| TachTech Breadth | 10% | Useful beyond TripleDB? SOC Alpha, SIEM, client engagements? |

Rating scale: **Adopt** (use now), **Trial** (test in sandbox), **Assess** (research further), **Hold** (not yet, revisit later).

## Categories to Evaluate (Phase 10)

### A. Agent Orchestration Frameworks

| Tool | Stars | Category | Preliminary Assessment |
|------|-------|----------|----------------------|
| Ruflo (ruvnet/ruflo) | 25K | Multi-agent swarms | Impressive scale. 313 MCP tools, hive-mind architecture. Overkill for single-agent IAO today. Evaluate queen/worker model for SOC Alpha multi-agent threat hunting. |
| Claude Skills | — | Agent capabilities | Native to Claude Code. Skill files in `.claude/` directory. Evaluate for codifying IAO pillars as skills. |
| Gemini CLI Skills | — | Agent capabilities | Similar concept for Gemini. Evaluate for UAT-side skill portability. |

### B. LLM Routing & Specialized Models

| Tool | Category | Preliminary Assessment |
|------|----------|----------------------|
| OpenClaw / NemoClaw | Specialized inference | NVIDIA-optimized models. Evaluate for local inference pipeline (transcription, extraction) — could replace or supplement Gemini Flash for specific tasks. Cost: $0 (local). Token efficiency: needs benchmarking. |
| Claude Sonnet 4.6 | Cost-optimized Claude | Cheaper than Opus for routine tasks. Evaluate for sub-agent routing: Opus for complex decisions, Sonnet for bulk operations. |
| Gemini 2.5 Flash | Existing | Already used. Benchmark against Claude Sonnet for extraction quality per dollar. |
| Local LLMs (Ollama) | On-premise | Previously evaluated (v1.8–v1.9: Nemotron, Qwen). Revisit with newer models for normalization tasks that don't need 1M context. |

### C. MCP Server Ecosystem

| Server | Category | Preliminary Assessment |
|--------|----------|----------------------|
| Context7 | Documentation | Active. Essential for Flutter/Dart docs lookup. |
| Playwright | Browser testing | Active. Critical for Tier 2 + Tier 3 post-flight. |
| Lighthouse MCP | Performance audit | Evaluate for automated Lighthouse scoring in hardening iterations. |
| Firecrawl MCP | Web scraping | Used in early phases. Evaluate for enrichment pipeline improvements. |
| Sequential Thinking MCP | Reasoning | Could benefit complex multi-step troubleshooting in self-heal cycles. |
| Filesystem MCP | File ops | Evaluate for crash recovery — safer file operations than raw bash. |

### D. Orchestration Patterns

| Pattern | Category | Preliminary Assessment |
|---------|----------|----------------------|
| Meta/Hyperagent | Agent-of-agents | An orchestrator LLM that dispatches to specialized sub-agents. Evaluate for Phase 10 UAT: could a meta-agent handle auto-chaining better than GEMINI.md instructions? |
| CLAUDE.md optimization | Prompt engineering | Ruflo's `@claude-flow/guidance` module has structured control planes for CLAUDE.md. Evaluate for reducing context window waste in version lock files. |
| Skill libraries | Reusable patterns | Both Claude and Gemini support skill definitions. Evaluate for packaging IAO pillars as portable skills across projects. |

## Radar Output Format (Phase 10 deliverable)

```markdown
| Tool | Rating | Arch Fit | Cost | Tokens | Integration | Breadth | Action |
|------|--------|----------|------|--------|-------------|---------|--------|
| Ruflo | Assess | 2/5 | 5/5 | 3/5 | 4/5 | 3/5 | POC for SOC Alpha |
| OpenClaw | Trial | 4/5 | 5/5 | ?/5 | 2/5 | 4/5 | Benchmark locally |
| ... | ... | ... | ... | ... | ... | ... | ... |
```

The radar is produced as part of the Phase 10 retrospective. It becomes TachTech institutional knowledge.

---

# 15. README Formatting Guide

The TripleDB README is the public face of the project. Starting v9.41, it adopts formatting elements inspired by production-quality open source READMEs (reference: ruvnet/ruflo) while remaining honest about TripleDB's scope and nature.

## Style Elements to Adopt

### Feature Badges (top of README, below title)

```markdown
🌐 [tripledb.net](https://tripledb.net) · 📺 805 Episodes · 🍔 1,102 Restaurants · 🍽️ 2,286 Dishes · 💰 $0 Cost
```

### ASCII Flow Diagram (pipeline section)

Use the pipeline architecture diagram from Section 5 of this design doc. Keep it readable in both GitHub rendering and raw markdown.

### Layered Architecture Table

```markdown
| Layer | Technology | Purpose |
|-------|-----------|---------|
| 🎙️ Acquisition | yt-dlp + faster-whisper | YouTube → transcripts |
| 🧠 Extraction | Gemini 2.5 Flash API | Transcripts → structured JSON |
| 📍 Enrichment | Google Places API + Nominatim | Ratings, coords, open/closed |
| 🗄️ Storage | Cloud Firestore | Denormalized restaurant docs |
| 📱 Frontend | Flutter Web + Firebase | Mobile-first responsive app |
| 🤖 Orchestration | Claude Code (Dev) / Gemini CLI (UAT) | IAO methodology |
```

### Changelog Section

Mandatory rules (unchanged):
- APPEND only, NEVER truncate
- Count must be ≥ 27 after v9.42
- First entry (v0.7) always preserved
- Last entry always present
- Post-flight verifies count
- Versioned copy in `docs/ddd-changelog-v{P}.{I}.md`

### What NOT to Adopt from Ruflo

- No star/fork/download shields (TripleDB is not an npm package)
- No swarm/hive-mind terminology (single-agent orchestration)
- No marketing language ("leading", "enterprise-grade", "revolutionary")
- Keep it honest — TripleDB is a passion project, not a platform

---

# 16. Phase 10 — UAT Handoff + Technology Radar

## What Phase 10 Is

Phase 10 has two tracks running in parallel:

**Track A — UAT Handoff:** Transition TripleDB from Dev (Claude Code, interactive) to UAT (Gemini CLI, autonomous, batch execution). Proves the plans are tight enough for a cheaper agent to execute from artifacts alone.

**Track B — Technology Radar:** Deep analysis of the AI agent ecosystem. Produces TachTech institutional knowledge: cost models, token benchmarks, architecture fit scoring for every evaluated tool.

## Prerequisites (must be complete before Phase 10)

- Phase 9 hardening iterations complete (all P0/P1 findings resolved)
- Lighthouse scores baselined
- Security headers deployed
- Error boundaries verified

## UAT Environment

| Aspect | Dev | UAT |
|--------|-----|-----|
| Agent | Claude Code (Opus) | Gemini CLI |
| Mode | YOLO interactive | YOLO auto-chain |
| Firebase project | tripledb-e0f77 | TBD (new project or staging) |
| Domain | tripledb.net | staging.tripledb.net or localhost |
| Human review | Between iterations | None — single session burns all phases |
| Artifact generation | Agent produces, Kyle reviews | Agent produces AND chains to next iteration |

## UAT Execution Model

Gemini CLI receives a comprehensive design doc + plan doc for Phase 0 (UAT Setup). The plan includes instructions to auto-generate successive iteration artifacts and auto-chain through ALL phases:

```
Phase 0 (UAT Setup) → Phase 1 (30 videos) → Phase 2 (60) → Phase 3 (90) →
Phase 4 (120, prompts lock) → Phase 5 (805, production batch) →
Phase 6 (Firestore + geocoding) → Phase 7 (enrichment) →
Phase 8 (Flutter app) → Phase 9 (optimization) → QA Report
```

## UAT Success Criteria

- All phases complete with 0 interventions
- Final QA report matches Dev metrics (1,102 restaurants, 582 enriched, etc.)
- tripledb.net (staging) is functional and matches Dev deployment
- Total execution time logged
- Total token spend logged
- Any failures are documented and fed back to Claude in Dev for plan tightening

## Phase 10 Deliverables

1. **UAT design doc** — comprehensive ADR for the UAT environment
2. **UAT plan doc** — Phase 0 setup + auto-chain instructions
3. **UAT GEMINI.md** — version lock for Gemini CLI
4. **Technology Radar** — deep analysis with 5-axis scoring (see Section 14)
5. **Retrospective report** — Pillar 9 archive review, tool efficacy, lessons learned
6. **Hardening baseline** — Lighthouse scores, security audit results, compat matrix

---

# CLAUDE.md Template (v9.42)

```markdown
# TripleDB — Agent Instructions

## Current Iteration: {P}.{I}

Read in order, then execute:
1. docs/ddd-design-v{P}.{I}.md
2. docs/ddd-plan-v{P}.{I}.md

## MCP Servers
- Playwright MCP: Post-flight functional testing
- Context7: Flutter/Dart API docs

## Rules
- YOLO — code dangerously, never ask permission
- Self-heal: max 3 attempts, checkpoint for crash recovery
- MUST produce ddd-build + ddd-report (with orchestration report) + ddd-changelog
- POST-FLIGHT: Tier 1 + Tier 2 playbook must pass (Flutter iterations)
- README changelog: NEVER truncate, ALWAYS append. Copy to docs/ddd-changelog-v{P}.{I}.md

## Agent Permissions
- ✅ CAN: flutter build web, firebase deploy --only hosting, firebase deploy --only firestore:rules
- ❌ CANNOT: git add, git commit, git push (Kyle commits at phase boundaries)
```
