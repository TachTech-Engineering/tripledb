# TripleDB - UAT Design Document

**Purpose:** Architecture document for Gemini CLI to replay the full TripleDB pipeline from scratch.
**Executor:** Gemini CLI (YOLO mode, tmux, zero human intervention)
**Source Project:** tripledb-e0f77
**Repository:** `git@github.com:TachTech-Engineering/tripledb.git`
**Derived From:** Dev design docs v0.7 through v10.46

---

# Table of Contents

1. [Project Overview](#1-project-overview)
2. [What UAT Proves](#2-what-uat-proves)
3. [Nine Pillars (UAT Adaptation)](#3-nine-pillars-uat-adaptation)
4. [Pipeline Architecture](#4-pipeline-architecture)
5. [Data Model](#5-data-model)
6. [Environment Setup](#6-environment-setup)
7. [Phase Chain](#7-phase-chain)
8. [CRITICAL: No Firestore Writes](#8-critical-no-firestore-writes)
9. [Auto-Chain Logic](#9-auto-chain-logic)
10. [Success Criteria](#10-success-criteria)
11. [Known Gotchas](#11-known-gotchas)
12. [Hardware Note](#12-hardware-note)
13. [GEMINI.md Content](#13-geminmd-content)

---

# 1. Project Overview

TripleDB processes 805 YouTube videos from Guy Fieri's "Diners, Drive-Ins and Dives" into a structured Firestore database of 1,102 restaurants, 2,286 dishes, and 2,336 visits. The pipeline chain: YouTube -> MP3 -> transcripts -> extracted JSON -> normalized JSONL -> geocoded -> enriched -> Firestore -> Flutter Web app at tripledb.net.

The entire pipeline was built across 46 iterations using Iterative Agentic Orchestration (IAO) - a methodology where LLM agents execute project phases autonomously while humans review versioned artifacts between iterations. Dev used Claude Code (Opus). UAT uses Gemini CLI.

---

# 2. What UAT Proves

UAT validates that the TripleDB pipeline is **reproducible by a different agent** with zero human intervention. Specifically:

1. **Pipeline reproducibility:** Gemini CLI can execute every pipeline stage and produce output matching dev artifacts
2. **Plan completeness:** The design + plan docs contain everything needed - no tribal knowledge required
3. **IAO portability:** The Nine Pillars methodology works with Gemini CLI, not just Claude Code
4. **Zero-intervention execution:** The entire pipeline runs in a single tmux session with no human input

UAT does NOT prove:
- That Gemini CLI is "better" than Claude Code (Lesson 7: agent choice matters less than plan quality)
- That the pipeline should be re-run (production data is already correct)
- That Firestore needs new data (UAT produces local JSONL only)

---

# 3. Nine Pillars (UAT Adaptation)

## Pillar 1 - Artifact Loop

Every phase produces five artifacts: design (this doc - shared across all phases), plan, build, report, and changelog. The report informs the next plan. UAT artifacts use the naming convention `ddd-{type}-uat-v{P}.{I}.md`.

| Direction | File | Author | Purpose |
|-----------|------|--------|---------|
| Input | `ddd-design-uat.md` | Claude Code (v10.46) | Living architecture (this file) |
| Input | `ddd-plan-uat-v{P}.{I}.md` | Gemini CLI | Phase-specific execution steps |
| Output | `ddd-build-uat-v{P}.{I}.md` | Gemini CLI | Session transcript |
| Output | `ddd-report-uat-v{P}.{I}.md` | Gemini CLI | Metrics + recommendation |
| Output | `ddd-changelog-uat-v{P}.{I}.md` | Gemini CLI | Changelog snapshot |

## Pillar 2 - Agentic Orchestration

**UAT-specific:** Gemini CLI is the sole executor. tmux is the runtime environment. There is no human available for questions.

| Environment | Agent | Mode | Runtime |
|-------------|-------|------|---------|
| UAT | Gemini CLI | YOLO auto-chain | tmux session |

**Tool Ecosystem (UAT):**

| Tool | Category | Purpose |
|------|----------|---------|
| Gemini CLI | Primary executor | All phases, auto-chain |
| Gemini 2.5 Flash API | LLM API | Extraction, normalization, verification |
| faster-whisper (CUDA) | Local ML | Transcription |
| yt-dlp | Media | YouTube -> MP3 |
| Nominatim | Geocoding | City -> lat/lng |
| Google Places API (New) | Enrichment | Ratings, status, websites |
| Puppeteer (npm) | Browser testing | Post-flight verification |
| tmux | Runtime | Session persistence, crash recovery |
| Firebase CLI | Hosting | Preview channel deploy |

**Agent Permissions:**

| Action | Allowed? | Notes |
|--------|----------|-------|
| Pipeline scripts (Python) | YES | All pipeline stages |
| `flutter build web` | YES | Build the app |
| `firebase hosting:channel:deploy uat` | YES | Preview channel only |
| `npm install` (local) | YES | Project-level |
| `pip install --break-system-packages` | YES | Python packages |
| `sudo` (any) | NO | No human available |
| `firebase deploy --only hosting` | NO | Production deploy forbidden |
| Firestore write operations | NO | See Section 8 |
| `git add / commit / push` | NO | Kyle reviews after UAT |

## Pillar 3 - Zero-Intervention Target

**UAT-specific:** Zero-intervention is mandatory, not aspirational. There is no human available. Every decision must be pre-answered in this document or the phase plan. If the agent encounters an uncovered situation, it makes the best decision, logs reasoning, and continues.

The plan IS the permission. If Gemini needs to ask a question, the plan has failed.

## Pillar 4 - Pre-Flight Verification

Before each phase, validate:

```
[ ] Previous phase artifacts written
[ ] API keys set ($GOOGLE_PLACES_API_KEY, $GEMINI_API_KEY)
[ ] CUDA available (nvidia-smi returns 0)
[ ] flutter analyze: 0 errors
[ ] Puppeteer available
[ ] Firebase authenticated (firebase login:list)
[ ] tmux session active
[ ] Checkpoint file from previous phase (if any)
```

## Pillar 5 - Self-Healing Execution

Max 3 attempts per error, then log and skip. If 3 consecutive items fail with the same error, STOP and write a failure report.

Checkpoint scaffolding: write JSON checkpoint after each completed step. On crash recovery, skip completed steps.

## Pillar 6 - Progressive Batching

Same graduation as dev:
- Phase 1: 30 videos
- Phase 2: 60 cumulative
- Phase 3: 90 cumulative
- Phase 4: 120 cumulative (prompts lock)
- Phase 5: 805 (full production run in tmux)
- Phase 7: 50 restaurants (enrichment discovery), then full 1,102

## Pillar 7 - Post-Flight Testing

**UAT-specific:** Puppeteer tests run against the preview channel URL, not production.

**Tier 1 - Health:**
- App loads at preview URL (not white screen)
- Console has zero uncaught errors
- Changelog integrity

**Tier 2 - Functional:**
- Search returns results
- Map renders with pins
- Restaurant detail page loads
- YouTube deep links present

Puppeteer install pattern if global unavailable:
```bash
cd /tmp && mkdir -p puppeteer-test && cd puppeteer-test && npm init -y && npm install puppeteer
```

## Pillar 8 - Mobile-First Flutter + Firebase (Zero-Cost by Design)

Unchanged from dev. Flutter Web, Firebase Hosting (preview channel for UAT), Firestore Spark plan. Total cost target: $0.

## Pillar 9 - Continuous Improvement

UAT is itself a Pillar 9 exercise - validating the methodology by having a different agent execute it. The UAT report feeds back into the IAO template for future projects.

---

# 4. Pipeline Architecture

## Layered Pipeline Table

| Stage | Tool | Input | Output | Runtime |
|-------|------|-------|--------|---------|
| `acquisition` | yt-dlp | YouTube playlist (805 URLs) | MP3 audio files | Local, tmux batch |
| `transcription` | faster-whisper large-v3 | MP3 audio | Timestamped JSON transcripts | Local CUDA (RTX 2080S or RTX 2000 Ada), tmux |
| `extraction` | Gemini 2.5 Flash API | Transcripts (1M context) | Structured restaurant JSON | Free tier API call |
| `normalization` | Gemini 2.5 Flash API | Raw restaurant JSON | Deduplicated JSONL (target: 1,102) | Free tier API call |
| `geocoding` | Nominatim (OpenStreetMap) | City/state pairs | Lat/lng coordinates (target: 1,006) | Free, 1 req/sec, cached |
| `enrichment` | Google Places API (New) | Restaurant name + location | Ratings, status, URLs (target: 582) | Free tier |
| `storage` | **LOCAL JSONL ONLY** | Enriched JSONL | Local files in `pipeline/data/` | **NO FIRESTORE WRITES** |
| `frontend` | Flutter Web | Firestore reads (production data) | Preview channel app | Firebase Hosting preview |

## Data Flow

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
Normalized JSONL (target: 1,102 restaurants)
    | Nominatim (OpenStreetMap)      1 req/sec. geocode_cache.json.
    v
Geocoded Data (target: 1,006 with coords)
    | Google Places API (New)        Text Search -> Place Details. >=0.70 match.
    v
Enriched Data (target: 582 verified)
    | LOCAL JSONL FILES ONLY         *** NO FIRESTORE WRITES ***
    v
pipeline/data/ (local validation)
    | diff against dev output
    v
PASS/FAIL

Flutter Web (reads production Firestore)
    | firebase hosting:channel:deploy uat
    v
Preview channel URL (7-day expiry)
```

---

# 5. Data Model

## Collection: `restaurants` (1,102 docs in production)

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

| Field | Type | Description |
|-------|------|-------------|
| `restaurant_id` | string | Unique identifier (r_<uuid4>) |
| `name` | string | Original DDD name (NEVER overwritten) |
| `google_current_name` | string | Current name from Google Places API |
| `name_changed` | boolean | Whether name differs from original |
| `city` | string | City location |
| `state` | string | State abbreviation |
| `formatted_address` | string | Full address from Google Places |
| `latitude` / `longitude` | number | Geocoded coordinates |
| `cuisine_type` | string | Cuisine category |
| `owner_chef` | string | Owner or chef name from transcript |
| `still_open` | boolean | Open/closed status |
| `business_status` | string | Google Places status enum |
| `google_place_id` | string | Google Places identifier |
| `google_rating` | number | Google rating (0-5) |
| `google_rating_count` | number | Number of Google ratings |
| `enrichment_match_score` | number | Name match confidence (0-1, threshold >=0.70) |
| `enrichment_verified` | boolean | LLM verification pass result |
| `visits` | array | Video appearances with timestamps |
| `dishes` | array | Dishes with ingredients and Guy's reaction |

## Collection: `videos` (773 docs in production)

```json
{
  "video_id": "<11-char YouTube ID>",
  "youtube_url": "...", "title": "...",
  "duration_seconds": 1619, "video_type": "compilation",
  "restaurant_count": 5, "processed_at": "<timestamp>"
}
```

**UAT note:** The pipeline produces these schemas as local JSONL. UAT validates by diffing field counts, restaurant counts, and enrichment metrics against dev output - not by writing to Firestore.

---

# 6. Environment Setup

## Target Machine

**Primary: NZXTcos** (RTX 2080 SUPER, 8GB VRAM, CUDA transcription)
**Alternative: tsP3-cos** (RTX 2000 Ada, 16GB VRAM, benchmarking)

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

# API Keys
set -gx GEMINI_API_KEY "your-gemini-api-key"
set -gx GOOGLE_PLACES_API_KEY "your-places-api-key"
set -gx GOOGLE_CLOUD_PROJECT "tripledb-e0f77"

# Cloudflare WARP TLS (if applicable)
set -gx NODE_EXTRA_CA_CERTS "/etc/ssl/certs/Gateway_CA_-_Cloudflare_Managed_G1_3d028af29af87d79a8b3245461f04241.pem"

# Chrome Stable for testing
set -gx CHROME_EXECUTABLE (which chromium)
```

## System Packages (pacman)

```fish
sudo pacman -S base-devel git fish tmux python python-pip nodejs npm \
  nvidia nvidia-utils cuda cudnn chromium firefox-esr jq --needed
```

## AUR Packages (yay)

```fish
yay -S flutter-bin android-studio google-cloud-cli visual-studio-code-bin
```

After `flutter-bin`:
```fish
sudo groupadd flutterusers
sudo gpasswd -a $USER flutterusers
sudo chown -R :flutterusers /opt/flutter
sudo chmod -R g+w /opt/flutter
```

## npm Global Packages (requires sudo)

```fish
sudo npm install -g puppeteer firebase-tools @google/gemini-cli
```

## pip Packages

```fish
pip install --break-system-packages faster-whisper requests firebase-admin yt-dlp google-cloud-firestore
```

## Puppeteer Browser Download

```fish
npx puppeteer browsers install chrome
```

Fallback if permissions fail:
```fish
cd /tmp && mkdir -p puppeteer-test && cd puppeteer-test && npm init -y && npm install puppeteer
```

## Validation Commands

```fish
nvidia-smi                          # CUDA available
python -c "from faster_whisper import WhisperModel; print('OK')"
yt-dlp --version
flutter analyze                     # 0 issues
flutter build web                   # success
firebase login:list                 # authenticated
firebase use tripledb-e0f77         # correct project
echo $GEMINI_API_KEY | head -c 5    # key set
echo $GOOGLE_PLACES_API_KEY | head -c 5  # key set
npx puppeteer --version || node -e "require('puppeteer')"  # available
```

---

# 7. Phase Chain

## Phase 0: Setup

**Entry:** Fresh clone on target machine, tmux session active.
**Tasks:**
1. Em-dash sweep (first task - see below)
2. Environment validation (all commands from Section 6)
3. Create GEMINI.md (see Section 13)
4. Write Phase 0 report

**Exit:** All tools validated, GEMINI.md created, zero issues.

### Em-Dash Sweep (Phase 0, Step 1)

```bash
# Detect em-dashes in all markdown and Dart files
grep -rn $'\xe2\x80\x94' --include='*.md' --include='*.dart' .

# Replace all occurrences with " - "
find . -name '*.md' -o -name '*.dart' | xargs sed -i 's/\xe2\x80\x94/ - /g'

# Verify zero remaining
grep -rn $'\xe2\x80\x94' --include='*.md' --include='*.dart' .
# Expected: 0 matches
```

## Phase 1: Discovery (30 videos)

**Entry:** Phase 0 complete, environment validated.
**Tasks:**
1. Download 30 videos (yt-dlp)
2. Transcribe 30 videos (faster-whisper, CUDA)
3. Extract restaurants (Gemini Flash API)
4. Normalize and deduplicate
5. Validate output against dev metrics (proportional)

**Exit:** ~186 restaurants extracted, extraction prompts working, JSONL output valid.

## Phase 2: Calibration (60 cumulative)

**Entry:** Phase 1 complete, extraction working.
**Tasks:**
1. Download next 30 videos
2. Transcribe, extract, normalize
3. Validate cumulative counts

**Exit:** ~422 restaurants, extraction stable, CUDA path confirmed.

## Phase 3: Stress Test (90 cumulative)

**Entry:** Phase 2 complete, zero interventions in Phase 2.
**Tasks:**
1. Download next 30 videos
2. Full pipeline pass
3. Zero-intervention target: if any intervention needed, stop and diagnose

**Exit:** ~511 restaurants, zero interventions, batch healing demonstrated.

## Phase 4: Validation (120 cumulative)

**Entry:** Phase 3 complete, zero interventions.
**Tasks:**
1. Download next 30 videos
2. Full pipeline pass
3. Lock extraction and normalization prompts

**Exit:** ~608 restaurants, prompts locked, ready for production.

## Phase 5: Production Run (805 videos)

**Entry:** Phase 4 complete, prompts locked.
**Tasks:**
1. Download remaining 685 videos (tmux batch)
2. Transcribe all (tmux, 14+ hours expected)
3. Extract and normalize full corpus
4. Checkpoint every 50 videos

**Exit:** 773+ extracted (4 timeout skips expected), 1,102 unique restaurants in JSONL.

## Phase 6: Geocoding + LOCAL JSONL Storage

**Entry:** Phase 5 complete, 1,102 restaurants in JSONL.

**CRITICAL: NO FIRESTORE WRITES. See Section 8.**

**Tasks:**
1. Geocode via Nominatim (1 req/sec, cache results)
2. Write geocoded JSONL to `pipeline/data/`
3. Validate: target 1,006 geocoded (91.3%)

**Exit:** Geocoded JSONL in `pipeline/data/`. NO Firestore operations.

## Phase 7: Enrichment (LOCAL JSONL ONLY)

**Entry:** Phase 6 complete, geocoded JSONL ready.

**CRITICAL: NO FIRESTORE WRITES. See Section 8.**

**Tasks:**
1. Enrichment discovery batch: 50 restaurants (Google Places API)
2. Full enrichment run: 1,102 restaurants
3. LLM verification pass (Gemini Flash) to remove false positives
4. Write enriched JSONL to `pipeline/data/`
5. Validate: target 582 verified enrichments

**Exit:** Enriched JSONL in `pipeline/data/`. Diff against dev output. NO Firestore operations.

## Phase 8: Flutter Build + Preview Channel Deploy

**Entry:** Phase 7 complete, all JSONL validated.
**Tasks:**
1. `flutter analyze` - 0 issues
2. `flutter build web` - success
3. `firebase hosting:channel:deploy uat --expires 7d`
4. Record preview URL

**Exit:** App deployed to preview channel. Reads from production Firestore (existing correct data).

## Phase 9: Post-Flight + Completion

**Entry:** Phase 8 complete, preview URL available.
**Tasks:**
1. Puppeteer tests against preview URL:
   - App loads (not white screen)
   - Search works
   - Map renders with pins
   - Restaurant detail loads
   - YouTube deep links present
   - Console: zero uncaught errors
2. Generate final UAT report with:
   - Metric comparison (UAT vs dev)
   - JSONL diff results
   - Preview channel URL
   - Total interventions (target: 0)
3. Generate final changelog

**Exit:** UAT complete. All metrics match dev within tolerance.

---

# 8. CRITICAL: NO FIRESTORE WRITES

## This rule is absolute and non-negotiable.

Pipeline scripts MUST NOT call any Firebase Admin SDK write methods:
- No `db.collection().add()`
- No `db.collection().set()`
- No `db.collection().update()`
- No `db.collection().delete()`
- No `batch.commit()`

Pipeline scripts produce LOCAL JSONL files only. Validation is by diff against dev pipeline output, not by writing to Firestore.

## Why

- Production Firestore already has 1,102 restaurants, 582 enriched, all correct
- Gemini proving it can produce identical JSONL output is sufficient validation
- Admin SDK bypasses Firestore security rules - a write bug could corrupt production data
- Diff validation (UAT JSONL vs. dev JSONL) is a stronger test than "did the write succeed"

## What the Flutter App Reads

The Flutter app deployed to the preview channel reads from **production Firestore** (which already has correct data). This is intentional - the app layer is already validated. UAT validates the pipeline layer.

## Validation Strategy

Instead of writing to Firestore, validate by:

1. **Pipeline output diff:** Compare UAT-generated JSONL against dev artifacts in `pipeline/data/`
2. **Metric matching:** UAT report must show targets: 1,102 restaurants, 582 enriched, 1,006 geocoded
3. **App build:** `flutter build web` succeeds
4. **Preview channel:** App deployed, reads production Firestore, Puppeteer tests pass

---

# 9. Auto-Chain Logic

After completing each phase, Gemini CLI auto-chains to the next:

```
1. Complete Phase N execution
2. Write ddd-report-uat-v{N}.{X}.md (metrics, recommendation)
3. Write ddd-changelog-uat-v{N}.{X}.md
4. Read the report
5. Generate ddd-plan-uat-v{N+1}.{X+1}.md based on this design doc's phase chain
6. Execute the new plan immediately
7. Repeat until Phase 9 complete
```

**Stop conditions:**
- Phase 9 complete (success)
- 3 consecutive identical failures (write failure report and stop)
- Firestore write attempt detected (stop immediately, this is a critical error)

**tmux persistence:**
```bash
tmux new-session -s tripledb-uat
cd ~/dev/projects/tripledb
gemini
# Paste: "Read GEMINI.md and execute."
```

If SSH drops: `tmux attach -t tripledb-uat`

---

# 10. Success Criteria

| Metric | Dev Value | UAT Target | Tolerance |
|--------|-----------|------------|-----------|
| Videos downloaded | 778 | 778 | exact |
| Videos transcribed | 774 | 770+ | 4 timeout skips OK |
| Videos extracted | 773 | 770+ | same tolerance |
| Unique restaurants | 1,102 | 1,050-1,150 | +/- 5% |
| Unique dishes | 2,286 | 2,100-2,500 | +/- 10% |
| Geocoded | 1,006 (91.3%) | 950+ (86%+) | geocoding is deterministic |
| Enriched (verified) | 582 (52.8%) | 550+ (50%+) | API results may vary |
| `flutter analyze` | 0 issues | 0 issues | exact |
| `flutter build web` | success | success | exact |
| Preview channel | N/A | deployed | must work |
| Puppeteer tests | N/A | all pass | must pass |
| Interventions | N/A | 0 | zero is mandatory |
| Firestore writes | N/A | 0 | zero is mandatory |

---

# 11. Known Gotchas

All 22 gotchas from dev, plus UAT-specific additions:

| # | Gotcha | UAT Note |
|---|--------|----------|
| 1 | CUDA path: `LD_LIBRARY_PATH` at SHELL level, not Python | Validate in Phase 0 pre-flight |
| 2 | fish shell: no heredocs, no process substitution | Use `printf` or temp files |
| 3 | yt-dlp: always `--remote-components ejs:github --cookies-from-browser chrome` | Chrome must be logged into YouTube |
| 4 | GPU contention: stop Ollama before transcription | `pkill -f ollama` in pre-flight |
| 5 | Cookie Secure flag: conditional on HTTPS | Preview channel is HTTPS, OK |
| 6 | Cookie expires: RFC 1123 format, not ISO 8601 | No code changes in UAT |
| 7 | Flutter canvas: use a11y tree for testing, not DOM/screenshots | Puppeteer `page.accessibility.snapshot()` |
| 8 | Riverpod 3 auto-retry: left at default | No code changes in UAT |
| 9 | Cloudflare WARP: disconnect if Python requests TLS fails | Check `NODE_EXTRA_CA_CERTS` |
| 10 | Restaurant `name`: NEVER overwrite | DDD original is sacred |
| 11 | README changelog: NEVER truncate | Post-flight verifies count |
| 12 | Nearby filter: exclude Unknown/None city/state, dedup by name | Handled in app code |
| 13 | Location consent: request BEFORE dismissing banner | No code changes in UAT |
| 14 | Firestore rules: read-only public, write denied | UAT does not deploy rules |
| 15 | Agent git restriction: agents NEVER git add/commit/push | Kyle reviews after UAT |
| 16 | Konsole terminal: run Gemini CLI from Konsole, NOT IDE terminal | Crashes in IDE terminal |
| 17 | Lighthouse on Flutter Web: `--force-renderer-accessibility` | For Tier 2 audits |
| 18 | CSP headers: Firebase Hosting via `firebase.json` | Preview channel inherits |
| 19 | Global npm install: requires `sudo` on Arch | Pre-install before UAT |
| 20 | Puppeteer fallback: use local `/tmp` install pattern | See Section 6 |
| 21 | Firefox on Flutter Web: `Invalid language tag: "undefined"` | Upstream Flutter bug, P2 |
| 22 | Trivia dedup: Set-based pool, shuffle, no repeats | No code changes in UAT |
| 23 | **UAT: NO FIRESTORE WRITES** | See Section 8. This is the #1 gotcha. |
| 24 | **UAT: Preview channel URL is auto-generated** | Record it for Puppeteer tests |
| 25 | **UAT: Em-dash sweep is Phase 0 Step 1** | Before any other work |
| 26 | **UAT: tmux session must persist entire run** | All phases in one session |

---

# 12. Hardware Note

| Machine | Role in UAT | GPU | VRAM |
|---------|------------|-----|------|
| NZXTcos | Primary (CUDA transcription) | RTX 2080 SUPER | 8 GB |
| tsP3-cos | Alternative (larger models) | RTX 2000 Ada | 16 GB |

**Recommendation:** Run UAT on NZXTcos to match dev conditions exactly. Use tsP3-cos only if NZXTcos is unavailable or for benchmarking larger local models.

**Critical VRAM note:** The RTX 2080 SUPER has 8GB VRAM. faster-whisper large-v3 fits. Do NOT attempt to run local LLMs (Nemotron, Qwen) on this GPU - use Gemini Flash API for extraction/normalization. This was Lesson 3 from the retrospective.

---

# 13. GEMINI.md Content

Place this file at the repository root as `GEMINI.md`:

```markdown
# TripleDB - UAT Agent Instructions

## Executor: Gemini CLI (YOLO, tmux, auto-chain)

Read docs/ddd-design-uat.md (this is the architecture for ALL phases).
Then read and execute docs/ddd-plan-uat-v0.1.md (Phase 0 setup).

After Phase 0, auto-chain: report -> next plan -> execute -> repeat.
See ddd-design-uat.md Section 9 for auto-chain logic.

## CRITICAL RULES
1. NO FIRESTORE WRITES. Pipeline produces local JSONL only.
2. NO git add/commit/push. Kyle reviews after UAT.
3. NO sudo. All deps must be pre-installed.
4. NO human questions. Zero-intervention is mandatory.
5. NO em-dashes. Use " - " (space-hyphen-space).
6. Use "->" for arrows.

## Formatting
- NEVER use em-dashes. Use " - " instead.
- Changelog: APPEND only, copy to docs/ddd-changelog-uat-v{P}.{I}.md

## Stop Conditions
- Phase 9 complete (success)
- 3 consecutive identical failures (write failure report)
- Firestore write detected (critical error, stop immediately)
```

---

# Formatting Rules

- NO em-dashes anywhere. Use " - " (space-hyphen-space).
- Use "->" for arrows, not unicode arrows or "-->".
- Changelog: APPEND only, never truncate.
- All file paths relative to `~/dev/projects/tripledb/`.
