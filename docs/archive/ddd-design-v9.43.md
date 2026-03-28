# TripleDB — Design v9.43

**ADR-001 | Living Architecture Document**
**Last Updated:** Phase 9, Iteration 43
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

The pillars evolved through 43 iterations: 6 (v3.12) → 8 (v5.14) → 9 (v9.41).

---

## Pillar 1 — Artifact Loop

Every iteration produces **five** artifacts: design (living architecture), plan (execution steps), build (full session transcript), report (metrics + recommendation), and **changelog** (versioned snapshot). These are the single source of truth — not chat history, not memory, not git diffs. The report informs the next plan. The design accumulates decisions across iterations.

Previous artifacts are archived to `docs/archive/` and only the current iteration's docs live in `docs/`. Agents never see outdated instructions, but the full history is preserved.

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

### Changelog Resilience

The README changelog is the most fragile artifact — agents repeatedly attempt to truncate it. A versioned changelog copy is produced after each iteration:

1. After updating `README.md`, copy the full changelog section to `docs/ddd-changelog-v{P}.{I}.md`
2. Post-flight verifies BOTH the README changelog count AND the docs copy exist
3. If the README changelog is ever corrupted, reconstruct from the latest `ddd-changelog-v{P}.{I}.md`
4. The changelog file in `docs/` is archived alongside other artifacts

---

## Pillar 2 — Agentic Orchestration

The primary agent orchestrates a constellation of LLMs, MCP servers, scripts, APIs, and sub-agents. The version lock file (`CLAUDE.md` or `GEMINI.md`) at project root points to the current design and plan docs.

**Agent Permissions:**

| Action | Allowed? | Notes |
|--------|----------|-------|
| `flutter build web` | ✅ YES | Agents build freely |
| `firebase deploy --only hosting` | ✅ YES | Agents deploy hosting |
| `firebase deploy --only firestore:rules` | ✅ YES | Agents deploy rules |
| `npm install` (local, non-global) | ✅ YES | Project-level installs |
| `pip install --break-system-packages` | ✅ YES | Python packages |
| `sudo` (any command) | ❌ NEVER | See Sudo Exception below |
| `npm install -g` (global) | ❌ REQUIRES SUDO | Agent must ask Kyle |
| `git add / commit / push` | ❌ NEVER | Kyle commits at PHASE boundaries |
| Ask the human a question | ❌ LAST RESORT | Exception: sudo operations (see below) |

### Sudo Exception (v9.43)

YOLO mode does not grant sudo privileges. When the agent encounters an operation that requires sudo (global npm install, system package install, permission fix), it must:

1. **Log the exact command** it needs Kyle to run (e.g., `sudo npm install -g puppeteer`)
2. **Pause and ask Kyle** to execute it — this is an approved exception to the zero-intervention pillar
3. **Continue execution** after Kyle confirms
4. **Record the intervention** as a "sudo intervention" in the report (distinct from a plan failure)

Sudo interventions do NOT count against the zero-intervention target. They are infrastructure operations, not plan quality failures.

### Dependency Recovery (v9.43)

When a required tool is missing or misconfigured, the agent should:

1. Check if it can install locally (e.g., `npm install puppeteer` in a temp directory) — do this first
2. If local install works, proceed with the local version
3. If a global install is truly needed, invoke the sudo exception
4. **Always reference the Environment Setup section (Section 4) of the design doc** to verify the correct installation method
5. Log the missing dependency in the build log so the design doc can be updated

The CLAUDE.md and GEMINI.md templates include a reference to Section 4 so agents can self-diagnose missing components.

**Git Commit Model:** Kyle commits at **phase boundaries**, not iteration boundaries.

**Two-Environment Model:**

| Environment | Agent | Scope | Mode |
|-------------|-------|-------|------|
| **Dev** | Claude Code | ALL phases | YOLO. Kyle + Claude iterate. |
| **UAT** | Gemini CLI | ALL phases | YOLO. Single session, auto-chain, zero human review. |

Dev never ends. Phase 10 is UAT handoff for TripleDB specifically.

**Tool Ecosystem:**

| Tool | Category | Purpose |
|------|----------|---------|
| Claude Code (Opus) | Primary executor (Dev) | Problem-solving, debugging, complex refactors |
| Gemini CLI | Primary executor (UAT) | Batch execution of proven plans |
| Gemini 2.5 Flash API | LLM API | Extraction, normalization, LLM verification |
| Puppeteer (npm) | Browser automation | Post-flight testing, error boundary testing, browser compat |
| Playwright MCP | Browser automation | MCP-integrated alternative (fallback if Puppeteer unavailable) |
| Context7 MCP | Documentation | Flutter/Dart API docs |
| Lighthouse CLI (npx) | Performance audit | Perf, a11y, SEO, best practices scoring |
| tmux + bash | Unattended runner | Batch pipeline execution (Phases 5+), UAT auto-chain, long-running tasks |
| Firebase Admin SDK | Database | Firestore CRUD |
| Google Places API (New) | Enrichment | Ratings, open/closed, websites |
| Nominatim | Geocoding | City → lat/lng |
| faster-whisper | Local ML | CUDA transcription |
| yt-dlp | Media | YouTube → mp3 |

### tmux in IAO (v9.43)

tmux is a primary execution component, not just a convenience tool:

- **Dev (Group B):** Production batches (Phase 5: 14-hour transcription run) execute in tmux sessions. Detach and reconnect without losing state.
- **UAT:** The entire Gemini CLI auto-chain (Phase 0 → Phase 9) runs in a single tmux session. If SSH drops, the session persists.
- **Post-flight:** Long Lighthouse audits and multi-browser Puppeteer test suites run in tmux to avoid terminal timeouts.
- **Crash recovery:** tmux session persists after terminal crash — the agent's checkpoint file + tmux scrollback = full reconstruction.

### Browser Testing Tool Decision (v9.43)

**Primary: Puppeteer (npm).** Puppeteer is the standard browser testing tool for all iterations. It integrates naturally with npm, works headless on CachyOS, and was battle-tested across v9.37–v9.42 (17 tests, 0 false negatives).

**Fallback: Playwright MCP.** If Playwright MCP is loaded in the agent's MCP configuration, it may be used as an alternative. However, Playwright requires additional system dependencies (`libwoff1`, etc.) that are not always available on CachyOS and caused test skips in v9.42.

Agents should NOT spend time debugging Playwright installation issues. If Puppeteer works, use Puppeteer.

---

## Pillar 3 — Zero-Intervention Target

Every question the agent asks during execution is a failure in the plan document — **with one exception:** sudo operations (see Pillar 2, Sudo Exception).

Pre-answer every decision point. Pre-set every environment variable. Pre-document every gotcha. Measure plan quality by counting interventions — zero is the floor.

Sudo interventions are tracked separately and do not count against plan quality. They are infrastructure friction, not planning failures.

If the agent encounters an uncovered situation, it makes the best decision, logs its reasoning in the build log, and continues. YOLO mode (`claude --dangerously-skip-permissions`) is the default.

---

## Pillar 4 — Pre-Flight Verification

Before execution begins, validate the environment: API keys, dependencies, git status, previous iteration archived. After completion, verify deployment timestamps.

### Standard Pre-Flight Checklist

```
[ ] Previous docs archived to docs/archive/
[ ] New design + plan in docs/
[ ] CLAUDE.md (or GEMINI.md) updated
[ ] git status clean ("KT starting {P}.{I}" committed)
[ ] API keys set ($GOOGLE_PLACES_API_KEY, $GEMINI_API_KEY as needed)
[ ] flutter analyze: 0 errors (baseline)
[ ] flutter build web: success (baseline)
[ ] Puppeteer available: npx puppeteer --version OR local node_modules check
[ ] Pipeline pre_flight.py passes (if pipeline iteration)
```

---

## Pillar 5 — Self-Healing Execution

Errors are inevitable. When one occurs: diagnose → fix → re-run. Max 3 attempts per error, then log and skip. If 3 consecutive items fail with the same error, STOP.

**Checkpoint scaffolding:** Long-running iterations write a JSON checkpoint file after each completed step. On relaunch, skip completed steps.

**Dependency self-heal:** If a required tool is missing, attempt local install first. If that fails, invoke sudo exception (Pillar 2). Never silently skip a dependency — either fix it or log the gap.

---

## Pillar 6 — Progressive Batching

Start small. 30 → 60 → 90 → 120 → 805 videos. 50 → 1,102 restaurants for enrichment. Graduate from interactive agent (Group A) to unattended tmux + bash (Group B) when proven.

---

## Pillar 7 — Post-Flight Functional Testing

Three-tier verification.

**Tier 1 — Standard Health:**
- App bootstraps (not white screen)
- Browser console has zero uncaught errors
- Changelog integrity (≥ expected count)
- Versioned changelog snapshot exists in `docs/`

**Tier 2 — Iteration Playbook:**
Puppeteer executes a functional test sequence specific to that iteration's deliverables. Every plan that touches Flutter code includes a `## Post-Flight Playbook` section. Uses the accessibility tree, not screenshots.

**Browser targets for all Tier 2 testing:**
- **Chrome Stable** (as defined in fish config PATH — the system chromium package)
- **Firefox ESR** (installed via `pacman -S firefox-esr` or equivalent)
- No Chromium dev/canary, Edge, Brave, or Safari. Two browsers only.

**Tier 2 exemption:** Documentation-only iterations skip Tier 2.

**Tier 3 — Hardening Audit:**
Comprehensive audit covering performance (Lighthouse), error boundaries, security (headers, CSP, Firestore rules pen test, dependency vulnerability scan), browser compatibility, and best practice assessment (BPA). Produces a scored baseline. See Section 13.

---

## Pillar 8 — Mobile-First Flutter + Firebase (Zero-Cost by Design)

Flutter single codebase: web → Play Store → App Store. Firebase free tier covers hosting, Firestore, and Analytics. Mobile-first responsive design scales up to desktop.

Cost is a design constraint. Every tool choice favors free-tier or zero-cost.

**Package Upgrade Policy (v9.43):**

When `flutter pub outdated` shows available major version upgrades:
1. Agent evaluates breaking changes from the package changelog
2. If the upgrade is straightforward (API-compatible or well-documented migration), **proceed with the upgrade in the current iteration**
3. If the upgrade requires significant refactoring (>30 minutes), defer to a dedicated iteration
4. All upgrades must pass `flutter analyze` (0 issues) and `flutter build web` (success) before commit
5. Log every upgrade in the build log with before/after versions

This replaces the previous approach of indefinitely deferring upgrades.

---

## Pillar 9 — Continuous Improvement

IAO evolves alongside every project. At project end, structured retrospective:

1. **Archive Review** — plan quality and intervention patterns
2. **Tool Efficacy** — orchestration reports → tools matrix
3. **Vulnerability & BPA** — dependency CVE scan + best practice assessment across codebase
4. **Technology Radar** — deep analysis of new agents, LLMs, MCP servers (see Section 14)

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
| v9.38 | ✅ | Claude Code | Cookie banner fix (Secure flag, RFC 1123, robust parsing) | Enriched: 582 |
| v9.39 | ✅ | Claude Code | 3 bug fixes: Unknown filter, dedup, location-on-consent | Enriched: 582 |
| v9.40 | ✅ | Claude Code | dart:html → package:web. Firestore security rules | Enriched: 582 |
| v9.41 | ✅ | Claude Code | Nine Pillars, methodology update, README overhaul | Enriched: 582 |
| v9.42 | ✅ | Claude Code | Hardening audit: 7 fixed (security headers, cache, CSP), 5 deferred | Enriched: 582 |
| v9.43 | 🔧 | Claude Code | Package upgrades, trivia expansion (150+), preferences→location, Firefox ESR | Enriched: 582 |

---

# 4. Environment Setup (From Scratch)

Target: CachyOS (Arch Linux) with KDE Plasma, Wayland, fish shell.

## Hardware Fleet

### NZXTcos — Primary Dev Machine (Phases 0–7, 9)

| Component | Spec |
|-----------|------|
| System | NZXT MS-7E06 (MSI PRO Z790-P WIFI DDR4) |
| CPU | Intel Core i9-13900K (24-core, 8P+16E, 5.8 GHz boost) |
| RAM | 64 GB DDR4 |
| GPU 1 | NVIDIA GeForce RTX 2080 SUPER (8 GB VRAM) — CUDA transcription |
| GPU 2 | Intel UHD Graphics 770 (integrated) |
| Storage | 912 GB ext4 |
| Display | 27" 1920x1080 60Hz external |
| OS | CachyOS x86_64 (kernel 6.19.7-1-cachyos) |
| DE | KDE Plasma 6.6.2, KWin (Wayland) |
| Shell | fish 4.5.0 |
| Terminal | Konsole 25.12.3 |
| Role | Pipeline execution, CUDA transcription, all dev phases, primary workstation |

### tsP3-cos — Benchmarking & ADR Composition

| Component | Spec |
|-----------|------|
| System | Lenovo ThinkStation P3 Ultra SFF G2 (30J6000JUS) |
| CPU | Intel Core Ultra 9 285 (24-core, 6.5 GHz boost) |
| RAM | 64 GB DDR5 |
| GPU 1 | NVIDIA RTX 2000 Ada Generation (16 GB VRAM) |
| GPU 2 | Intel Graphics (integrated, 2.0 GHz) |
| Storage | 912 GB ext4 |
| Display | Triple 63" 1920x1080 60Hz external |
| OS | CachyOS x86_64 (kernel 6.19.7-1-cachyos) |
| DE | KDE Plasma 6.6.3, KWin (Wayland) |
| Shell | fish 4.5.0 |
| Terminal | Konsole 25.12.3 |
| Role | Benchmarking, ADR composition, 16GB VRAM for larger model evaluation |

### auraX9cos — Mobile Dev (Phase 8, RSA Conference)

| Component | Spec |
|-----------|------|
| System | Lenovo ThinkPad X9-14 Gen 1 (21QACTO1WW) |
| CPU | Intel Core Ultra 7 268V (8-core, 3.7 GHz boost) |
| RAM | 32 GB |
| GPU | Intel Arc Graphics 130V / 140V @ 2.0 GHz |
| Storage | 469 GB |
| Display | 14" 1920x1200 60Hz |
| Battery | Yes (laptop) |
| OS | CachyOS x86_64 (kernel 6.18.9-3-cachyos) |
| DE | KDE Plasma 6.6.3, KWin (Wayland) |
| Shell | bash 5.3.9 (fish not configured on this machine) |
| Terminal | Konsole 25.12.3 |
| Role | Phase 8 Flutter scaffold (RSA Conference, San Francisco). Travel machine. |

## One-Shot Install Commands

Paste these blocks into fish shell on a fresh Arch/CachyOS machine:

### System Packages (pacman)

```fish
sudo pacman -S base-devel git fish tmux python python-pip nodejs npm \
  nvidia nvidia-utils cuda cudnn chromium firefox-esr jq --needed
```

**Note:** `firefox-esr` provides the Extended Support Release for stable browser testing. If `firefox-esr` is not in the standard repos, use `yay -S firefox-esr-bin` from the AUR.

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

### npm Global Packages (requires sudo on Arch)

```fish
sudo npm install -g @anthropic-ai/claude-code puppeteer firebase-tools @google/gemini-cli
```

**Important:** Global npm installs on Arch require `sudo` because the global prefix is `/usr/lib`. Agents cannot run this command — Kyle must run it during machine setup or when the agent invokes the sudo exception.

### pip Packages

```fish
pip install --break-system-packages faster-whisper requests firebase-admin yt-dlp google-cloud-firestore
```

### Puppeteer Browser Download

After global install, ensure Puppeteer downloads its bundled Chromium:
```fish
npx puppeteer browsers install chrome
```

If this fails due to permissions, the agent can use a local Puppeteer install in `/tmp` as a fallback (see v9.42 build log for the pattern).

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

# Chrome Stable for testing (the system chromium package)
set -gx CHROME_EXECUTABLE (which chromium)
```

## SSH, MCP, Firebase, GCP

Unchanged from v9.42. See `docs/archive/ddd-design-v9.42.md` Section 4 for full details.

---

# 5. Pipeline Architecture

```
YouTube Playlist (805 videos)
    ↓ yt-dlp (local)               --remote-components ejs:github
MP3 Audio                           --cookies-from-browser chrome
    ↓ faster-whisper large-v3       LD_LIBRARY_PATH=/usr/local/lib/
      (local CUDA, tmux session)    ollama/cuda_v12:$LD_LIBRARY_PATH
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

Unchanged from v9.42. See `docs/archive/ddd-design-v9.42.md` Section 6.

---

# 7. App Architecture

## Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Framework | Flutter Web | 3.x |
| State management | Riverpod 3.x with codegen | 3.3.1 |
| Routing | GoRouter | 14.x → **17.x (v9.43)** |
| Database | Cloud Firestore | — |
| Map | flutter_map | 7.x → **8.x (v9.43)** |
| Geolocation | geolocator | 14.0.2 |
| Analytics | Firebase Analytics + consent mode v2 | — |
| Cookie access | `package:web` (`dart:js_interop`) | 1.1.1 |
| Fonts | google_fonts | 6.x → **8.x (v9.43)** |
| Hosting | Firebase Hosting | — |
| Security rules | Firestore read-only public, write denied | v9.40 |
| Security headers | CSP, HSTS, X-Frame-Options, etc. | v9.42 |

## Cookie Consent Flow

1. App bootstraps → `CookieConsentService` reads `tripledb_consent` via `package:web`
2. No cookie → show banner (Accept All / Save Preferences / Reject Non-Essential)
3. Accept All → write cookie → enable Analytics → request geolocation
4. **Save Preferences** → write cookie with selected preferences → **if preferences radio is enabled, force-enable geolocation** (v9.43)
5. Reject → write cookie with `analytics=false` → skip Analytics → skip geolocation
6. On reload → cookie persists → banner suppressed → respect stored preferences

## Trivia System (v9.43)

- **Target: 150+ unique facts** (up from ~55 in v9.35)
- Facts sourced from actual data: restaurant counts by state, cuisine distribution, Guy Fieri quotes, closed restaurant stats, name changes, rating distributions, multi-visit restaurants, etc.
- **Deduplication:** Facts stored in a `Set<String>` or equivalent. Random selection from the full pool with no repeats until all facts shown.
- **Randomization:** Use `List.shuffle()` with a fresh `Random()` instance on each session. Display pool rotates — never show the same fact twice in a row, never show duplicates.

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
| Map | flutter_map 8.x + CartoDB dark | v9.43 |
| Analytics | Firebase Analytics + consent mode v2 | v7.34 |
| Cookie access | `package:web` + `dart:js_interop` | v9.40 |
| Firestore rules | Read-only public, write denied | v9.40 |
| Security headers | CSP, HSTS, X-Frame, Referrer, Permissions | v9.42 |
| Browser testing tool | Puppeteer (npm) | v9.43 |
| Browser test targets | Chrome Stable + Firefox ESR | v9.43 |
| Batch execution | tmux + bash | v5.14 |
| Dev executor | Claude Code (YOLO) | v9.35 |
| UAT executor | Gemini CLI (YOLO) | Phase 10 (planned) |
| Restaurant `name` field | NEVER overwritten | v7.33 |

---

# 9. Scripts Inventory

Unchanged from v9.42. See `docs/archive/ddd-design-v9.42.md` Section 9.

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
│   ├── ddd-changelog-v{P}.{I}.md
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
| 11 | README changelog: NEVER truncate, post-flight verifies count + docs copy |
| 12 | Nearby filter: exclude Unknown/None city/state, dedup by name |
| 13 | Location consent: request BEFORE dismissing banner (widget must be mounted) |
| 14 | Firestore rules: `firebase deploy --only firestore:rules` separate from hosting |
| 15 | Agent git restriction: agents NEVER git add/commit/push |
| 16 | Konsole terminal: run Claude Code from Konsole, NOT IDE terminal (crashes) |
| 17 | Lighthouse on Flutter Web: `--force-renderer-accessibility` flag needed |
| 18 | CSP headers: Firebase Hosting sets via `firebase.json` headers, test locally first |
| 19 | Global npm install: requires `sudo` on Arch — agent invokes sudo exception |
| 20 | Puppeteer fallback: if global install missing, use local `/tmp` install pattern |
| 21 | Firefox on Flutter Web: `Invalid language tag: "undefined"` — upstream Flutter bug |
| 22 | Trivia dedup: use Set-based pool, shuffle with fresh Random(), no repeats |

---

# 12. Current State (After v9.42)

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
| Lighthouse A11y | 93 |
| Lighthouse SEO | 100 |
| Security headers | 7 deployed (CSP, HSTS, etc.) |
| Total API cost | $0 |
| Total iterations | 42 (v0.7 – v9.42) |

---

# 13. Hardening Framework

Unchanged from v9.42 except:

- **Vulnerability scanning** added to Domain 3 (Security): `flutter pub outdated` + CVE check against known databases
- **Best Practice Assessment (BPA)** added as a cross-cutting concern: code quality patterns, Dart analysis rules, accessibility compliance, error handling consistency
- **Browser targets narrowed:** Chrome Stable + Firefox ESR only. No Chromium dev builds, Edge, Brave, or Safari.

---

# 14. Technology Radar

Unchanged from v9.42. Full radar evaluation is a Phase 10 deliverable.

---

# 15. README Formatting Guide

Unchanged from v9.42 except:
- Changelog count threshold: ≥ 28 after v9.43
- Hardware section must reflect all 3 machines

---

# 16. Phase 10 — UAT Handoff Architecture

Unchanged from v9.42. Prerequisites now include:
- v9.43 package upgrades complete
- Trivia expansion deployed
- Preferences → location fix deployed
- Firefox ESR testing passing

---

# CLAUDE.md Template (v9.43)

```markdown
# TripleDB — Agent Instructions

## Current Iteration: {P}.{I}

Read in order, then execute:
1. docs/ddd-design-v{P}.{I}.md — Section 4 has environment setup if any tool is missing
2. docs/ddd-plan-v{P}.{I}.md

## MCP Servers
- Context7: Flutter/Dart API docs

## Testing
- Puppeteer (npm): Post-flight testing. If missing, install locally: cd /tmp && mkdir test && cd test && npm init -y && npm install puppeteer
- Browser targets: Chrome Stable + Firefox ESR only
- Playwright MCP: Fallback only. Do NOT debug Playwright installation issues.

## Rules
- YOLO — code dangerously, never ask permission
- Self-heal: max 3 attempts, checkpoint for crash recovery
- MUST produce ddd-build + ddd-report + ddd-changelog
- POST-FLIGHT: Tier 1 + Tier 2 playbook must pass (Flutter iterations)
- README changelog: NEVER truncate, ALWAYS append. Copy to docs/ddd-changelog-v{P}.{I}.md

## Agent Permissions
- ✅ CAN: flutter build web, firebase deploy --only hosting, firebase deploy --only firestore:rules
- ✅ CAN: npm install (local/project-level), pip install --break-system-packages
- ❌ CANNOT: sudo (anything). Ask Kyle to run sudo commands.
- ❌ CANNOT: git add, git commit, git push (Kyle commits at phase boundaries)
- Sudo interventions do NOT count against zero-intervention target

## Package Upgrades
- If flutter pub outdated shows major upgrades, evaluate and proceed if straightforward
- Must pass flutter analyze (0 issues) + flutter build web after upgrade
```
