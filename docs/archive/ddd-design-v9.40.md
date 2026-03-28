# TripleDB — Design v9.40

**ADR-001 | Living Architecture Document**
**Last Updated:** Phase 9, Iteration 40
**Author:** Kyle Thompson, Managing Partner & Solutions Architect @ TachTech Engineering
**Repository:** `git@github.com:TachTech-Engineering/tripledb.git`
**Live Site:** [tripledb.net](https://tripledb.net)
**Firebase Project:** tripledb-e0f77

---

# Table of Contents

1. [Project Mandate](#1-project-mandate)
2. [IAO Methodology — The Eight Pillars](#2-iao-methodology)
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
13. [Work Remaining to MVP](#13-remaining-work)
14. [Phase 10 — UAT Handoff Architecture](#14-phase-10)

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

# 2. IAO Methodology — The Eight Pillars

## What IAO Is

Iterative Agentic Orchestration — a development methodology where LLM agents execute project phases autonomously while humans review versioned artifacts between iterations. Each iteration produces a plan (input) and a report (output). The report informs the next plan. The methodology itself evolves alongside the project.

## Pillar 1 — Artifact Loop

Every iteration produces four markdown artifacts: design (living architecture), plan (execution steps), build (full session transcript), and report (metrics + recommendation). These are the single source of truth — not chat history, not memory, not git diffs. The report informs the next plan. The design accumulates decisions across iterations. Previous artifacts are archived to `docs/archive/` and only the current iteration's docs live in `docs/`. Agents never see outdated instructions, but the full history is preserved.

Each iteration report includes an **Orchestration Report**: a breakdown of which agents, MCP servers, APIs, and scripts were used, their approximate workload share, and their efficacy. Example: "Claude Code 60% — 0 self-heal cycles. Puppeteer 15% — 6/6 tests passed. Google Places API 20% — 582 matches at $0." This feeds Pillar 8's retrospective.

### Artifact Spec

| Direction | File | Author | Purpose |
|-----------|------|--------|---------|
| Input | `ddd-design-v{P}.{I}.md` | Claude (chat) | Living architecture, locked decisions |
| Input | `ddd-plan-v{P}.{I}.md` | Claude (chat) | Execution steps, success criteria, playbook |
| Output | `ddd-build-v{P}.{I}.md` | Executing agent | Full session transcript |
| Output | `ddd-report-v{P}.{I}.md` | Executing agent | Metrics, orchestration report, recommendation |
| Output | `README.md` (updated) | Executing agent | Status, metrics, changelog (APPEND only) |

## Pillar 2 — Agentic Orchestration

The primary agent orchestrates a constellation of LLMs, MCP servers, scripts, APIs, and sub-agents to understand the design, execute the plan, capture the build, and produce the report. The version lock file (`CLAUDE.md` or `GEMINI.md`) at project root points to the current design and plan docs — the launch command never changes. Git commits mark iteration boundaries: `"KT starting {P}.{I}"` and `"KT completed {P}.{I}"`.

**Two-Environment Model:**

| Environment | Agent | Scope | Mode |
|-------------|-------|-------|------|
| **Dev (MVP)** | Claude Code | ALL phases — pipeline, app, enrichment, everything | YOLO. Kyle + Claude troubleshoot, debug, iterate, tighten plans. |
| **UAT** | Gemini CLI | ALL phases — same pipeline, same app, same enrichment | YOLO. Gemini executes battle-hardened plans. Single session, auto-chain artifacts, zero human review. |

Claude is the R&D lab. Gemini is the factory floor. If Gemini hits a wall in UAT, the plan wasn't tight enough — it goes back to Claude in dev.

**Tool Ecosystem:**

| Tool | Category | Purpose |
|------|----------|---------|
| Claude Code (Opus) | Primary executor (Dev) | Problem-solving, debugging, complex refactors |
| Gemini CLI | Primary executor (UAT) | Batch execution of proven plans |
| Gemini 2.5 Flash API | LLM API | Extraction, normalization, LLM verification |
| Playwright MCP | Browser automation | Post-flight functional testing |
| Puppeteer (npm) | Browser automation | Fallback for Playwright |
| Context7 MCP | Documentation | Flutter/Dart API docs |
| Firebase Admin SDK | Database | Firestore CRUD |
| Google Places API (New) | Enrichment | Ratings, open/closed, websites |
| Nominatim | Geocoding | City → lat/lng |
| faster-whisper | Local ML | CUDA transcription |
| yt-dlp | Media | YouTube → mp3 |
| tmux + bash | Unattended runner | Group B production batches |

## Pillar 3 — Zero-Intervention Target

Every question the agent asks during execution is a failure in the plan document. Pre-answer every decision point. Pre-set every environment variable. Pre-document every gotcha. Measure plan quality by counting interventions — zero is the floor, not the ceiling.

If the agent encounters an uncovered situation, it makes the best decision, logs its reasoning in the build log, and continues. YOLO mode (`claude --dangerously-skip-permissions` for Dev, `gemini` with full autonomy rules for UAT) is the default execution model — code dangerously, move fast, and let the post-flight catch what the pre-flight missed. Asking the human is a last resort reserved for situations where continuing would be destructive.

## Pillar 4 — Pre-Flight Verification

Before execution begins, validate the environment: API keys set and reachable, services responding, dependencies installed, git status clean, previous iteration archived. After the iteration completes and Kyle deploys, verify that `git push`, `flutter build web`, and `firebase deploy` timestamps are more recent than the build artifact timestamp. If any deployment step is stale, the iteration isn't live.

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

## Pillar 5 — Self-Healing Execution

Errors are inevitable. When one occurs: diagnose → fix → re-run. Max 3 attempts per error, then log and skip. If 3 consecutive items fail with the same error, STOP the batch, fix the root cause, restart. Never burn through hundreds of items with a known systemic failure.

**Checkpoint scaffolding:** Long-running iterations write a JSON checkpoint file (`pipeline/data/checkpoints/v{P}.{I}_checkpoint.json`) after each completed step. On session start, the agent reads the checkpoint and skips completed steps. If the terminal crashes, the session hangs, or the agent is interrupted, relaunch picks up at the next step. The checkpoint is deleted after all artifacts are written.

```json
{
  "iteration": "9.40",
  "last_completed_step": 2,
  "step_name": "Firestore Security Rules",
  "timestamp": "2026-03-28T14:22:00Z"
}
```

## Pillar 6 — Progressive Batching

Start small. Each batch is bigger and harder. 30 → 60 → 90 → 120 → 805 videos. 50 → 1,102 restaurants for enrichment. By the time you run the production batch, every failure mode has been seen, logged, and handled.

Once proven through graduated batches, graduate execution from interactive agent (Group A) to unattended bash + tmux scripts (Group B) to eliminate token spend on repetitive work.

## Pillar 7 — Post-Flight Functional Testing

Two-tier verification after every iteration that touches frontend code.

**Tier 1 — Standard Health:**
- App bootstraps (not white screen)
- Browser console has zero uncaught errors
- Changelog integrity (≥ expected count)

**Tier 2 — Iteration Playbook:**
Playwright/Puppeteer executes a functional test sequence specific to that iteration's deliverables — clicking buttons, verifying state changes, confirming persistence, reading the accessibility tree. Every plan includes a `## Post-Flight Playbook` section.

Flutter Web renders to `<canvas>` — screenshots prove nothing. Accessibility tree verification and interactive user-like actions are required.

## Pillar 8 — Continuous Improvement

IAO evolves alongside every project and crystallizes into institutional knowledge at project close. At project end, the agent performs a structured retrospective:

1. **Archive Review** — scan `docs/archive/` to assess plan quality and intervention patterns
2. **Tool Efficacy** — synthesize orchestration reports into a tools matrix
3. **Architectural Documents** — produce final ADRs, environment setup, onboarding docs
4. **Horizon Scan** — identify new agents, MCP servers, or AI tools available since inception

The pillars themselves are artifacts of this process: 6 (v3.12) → 8 (v5.14) → 9 (v9.37) → 8 refined (v9.40).

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
| v7.32 | ✅ | Refined search: 83 recovered. LLM verification: 126 false positives removed | Enriched: 582, Closed: 30, Geocoded: 1006 |
| v7.33 | ✅ | AKA names backfilled (283 changes). Grey pins, closed filter, checkpointing | Enriched: 582, Names: 283, Closed: 30 |
| v7.34 | ✅ | Cookie consent (GDPR/CCPA). Firebase Analytics consent mode v2. Name threshold 0.90 | Enriched: 582, Names: 279, Closed: 34 |

## Phase 8 — Flutter App

| Iter | Status | Key Result | Enrichment State |
|------|--------|------------|-----------------|
| v8.17–21 | ✅ | Pass 1: scaffold + core features (thin QA) | N/A |
| v8.22–25 | ✅ | Pass 2: design tokens, component patterns. Lighthouse A11y 92, SEO 100 | N/A |

## Phase 9 — App Optimization

| Iter | Status | Executor | Key Result | Enrichment State |
|------|--------|----------|------------|-----------------|
| v9.35 | ✅ | Claude Code | Riverpod 2→3, geolocator 10→14, 70+ trivia, 15 nearby | Enriched: 582 |
| v9.36 | ✅ | Claude Code | White screen crash fix (lazy init, deferred DOM) | Enriched: 582 |
| v9.37 | ✅ | Claude Code | Post-flight protocol v1 (Pillar 7 established) | Enriched: 582 |
| v9.38 | ✅ | Claude Code | Cookie banner fix (Secure flag, RFC 1123, robust parsing). Functional playbook | Enriched: 582 |
| v9.39 | ✅ | Claude Code | 3 bug fixes: Unknown filter, dedup, location-on-consent. 7/7 playbook pass | Enriched: 582 |
| v9.40 | 🔧 | Claude Code | dart:html → package:web. Firestore security rules. FINAL DEV ITERATION | Enriched: 582 |

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

See design doc v9.39 Section 7 for full tech stack, design tokens, app structure, cookie consent flow, and Firebase Analytics events. All unchanged in v9.40 except:

- `dart:html` → `package:web` in `cookie_consent_service.dart`
- Firestore security rules added

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
| UAT executor | Gemini CLI (YOLO) | v10.41 (planned) |
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
│   ├── screenshots/
│   └── archive/                 ← ALL previous iterations
├── pipeline/
│   ├── GEMINI.md                ← Version lock (UAT/legacy)
│   ├── scripts/
│   ├── config/
│   └── data/                    ← gitignored
├── app/
│   ├── pubspec.yaml
│   ├── firestore.rules          ← NEW in v9.40
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
| 11 | README changelog: NEVER truncate, post-flight verifies count |
| 12 | Nearby filter: exclude Unknown/None city/state, dedup by name |
| 13 | Location consent: request BEFORE dismissing banner (widget must be mounted) |
| 14 | Firestore rules: `firebase deploy --only firestore:rules` separate from hosting |

---

# 12. Current State (After v9.39)

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
| Total API cost | $0 |

---

# 13. Work Remaining to MVP

| Item | Priority | Status |
|------|----------|--------|
| `dart:html` → `package:web` | P1 | **v9.40 (this iteration)** |
| Firestore security rules | P1 | **v9.40 (this iteration)** |
| Verify cookie + location on production | P0 | Manual after v9.39 deploy |

After v9.40, all P0/P1 items are resolved. App is production-ready for Phase 10 UAT handoff.

---

# 14. Phase 10 — UAT Handoff Architecture

## What Phase 10 Is

Phase 10 transitions TripleDB from Dev (Claude Code, interactive, problem-solving) to UAT (Gemini CLI, autonomous, batch execution). The UAT environment proves that the plans are tight enough for a less expensive, less capable agent to execute perfectly from artifacts alone.

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

Each phase produces build + report artifacts. The report auto-feeds into the next phase's plan. Gemini does NOT stop between phases — it reads the report, generates the next plan, and continues. A single tmux session burns through the entire pipeline.

## UAT Success Criteria

- All phases complete with 0 interventions
- Final QA report matches Dev metrics (1,102 restaurants, 582 enriched, etc.)
- tripledb.net (staging) is functional and matches Dev deployment
- Total execution time logged
- Total token spend logged
- Any failures are documented and fed back to Claude in Dev for plan tightening

## Phase 10 Deliverables

1. **UAT design doc** — comprehensive ADR for the UAT environment (derived from this Dev design doc)
2. **UAT plan doc** — Phase 0 setup + auto-chain instructions for all subsequent phases
3. **UAT GEMINI.md** — version lock for Gemini CLI
4. **Retrospective report** — Pillar 8 archive review, tool efficacy, lessons learned
5. **Horizon scan** — new tools/agents to evaluate for next project

---

# CLAUDE.md Template

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
- NEVER git add/commit/push or firebase deploy
- YOLO — code dangerously, never ask permission
- Self-heal: max 3 attempts, checkpoint for crash recovery
- MUST produce ddd-build + ddd-report (with orchestration report)
- POST-FLIGHT: Tier 1 + Tier 2 playbook must pass (Flutter iterations)
- README changelog: NEVER truncate, ALWAYS append
```
