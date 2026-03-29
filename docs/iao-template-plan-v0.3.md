# IAO Project Template - Plan v0.3 (Phase 0)

**Phase:** 0 - Project Scaffold & Environment Validation
**Executor:** Claude Code (YOLO mode) or Gemini CLI
**Goal:** Scaffold a new IAO project from a YouTube playlist URL. Install dependencies. Validate environment. Produce Phase 0 report. Plan Phase 1.

---

## What This Template Builds

An IAO project converts a YouTube playlist into a dual-purpose system: a structured Firestore database of transcribed, normalized, and enriched data - and a Flutter Web application for searching, browsing, and visualizing that data. The pipeline downloads video audio, transcribes it locally with CUDA-accelerated whisper models, extracts structured entities via LLM, normalizes and deduplicates across the corpus, enriches with external APIs and web crawling, and loads the result into Cloud Firestore. The Flutter app reads from Firestore and deploys to Firebase Hosting at zero cost.

The process is fully agentic. An LLM agent (Claude Code or Gemini CLI) reads a design doc and plan doc, then executes the pipeline autonomously. The human architect sets direction between iterations. The artifacts are the contract.

**Input:** A YouTube playlist URL and a project name.
**Output:** A live web app backed by structured data extracted from every video in the playlist.

---

## Quick Start (7 Commands)

```fish
# 1. Clone the project
git clone https://github.com/{org}/{project}.git
cd {project}

# 2. Install all dependencies from manifests
fish requirements/install.fish

# 3. Configure environment (API keys)
cp requirements/fish-config-sanitized.fish ~/.config/fish/config.fish
nano ~/.config/fish/config.fish
source ~/.config/fish/config.fish

# 4. Configure MCP servers
mkdir -p ~/.config/claude ~/.gemini
cp requirements/gemini-settings.json ~/.gemini/settings.json
nano ~/.gemini/settings.json

# 5. Verify everything works
flutter analyze && flutter build web && echo "Ready"

# 6. Create CLAUDE.md version lock
printf '# {Project} - Agent Instructions\n\nRead docs/{project}-design-v0.1.md then docs/{project}-plan-v0.1.md' > CLAUDE.md

# 7. Launch
claude --dangerously-skip-permissions
```

If you do not have Claude Code, use Gemini CLI (free) - see the design doc Section 12.

---

## Autonomy Rules

```
1. AUTO-PROCEED. NEVER ask permission. YOLO.
2. SELF-HEAL: max 3 attempts per error. Checkpoint after every step.
3. Git READ only. NEVER git add/commit/push.
4. FORMATTING: No em-dashes. Use " - " instead. Use "->" for arrows.
5. MANDATORY: produce {project}-build + {project}-report + {project}-changelog
```

---

## Step 0: Provide YouTube Playlist URL

The first input to any IAO project built from this template is a YouTube playlist URL. This drives everything.

```fish
# Validate the playlist URL with yt-dlp (no download, just metadata)
yt-dlp --flat-playlist --print "%(id)s %(title)s" "{PLAYLIST_URL}" | head -10

# Expected: list of video IDs and titles
# If yt-dlp fails, the URL is invalid or the playlist is private.
```

Record in the design doc:
- Playlist URL
- Video count (from yt-dlp output)
- Content description (what the videos contain, what entities to extract)

---

## Step 1: Install Environment

Run the install script from the project repo. This handles everything - pacman packages, AUR packages, Playwright deps, npm tools, pip packages, GPU detection.

```fish
cd ~/dev/projects/{project}
fish requirements/install.fish
```

Follow the prompts. Review the verification output. If any core tool shows FAIL, fix it before proceeding.

After install, configure manually:

```fish
# Copy fish config and add your API keys
cp requirements/fish-config-sanitized.fish ~/.config/fish/config.fish
nano ~/.config/fish/config.fish
# Replace REDACTED values: GEMINI_API_KEY, GOOGLE_PLACES_API_KEY, etc.
source ~/.config/fish/config.fish

# Copy MCP configs and add your API keys
mkdir -p ~/.config/claude ~/.gemini
cp requirements/gemini-settings.json ~/.gemini/settings.json
nano ~/.gemini/settings.json
# Add your Firecrawl API key and any other keys
```

---

## Step 2: Hardware Fleet

| Machine | Type | CPU | GPU | VRAM | RAM | Disk | OS | Kernel | Shell | Plasma | Display | Terminal | IP |
|---------|------|-----|-----|------|-----|------|----|--------|-------|--------|---------|----------|----|
| NZXTcos | Desktop (MSI PRO Z790-P WIFI DDR4) | Intel i9-13900K (32T, 5.8 GHz) | NVIDIA RTX 2080 SUPER + Intel UHD 770 | 8 GB | 64 GB DDR4 | 912 GB | CachyOS | 6.19.7-1 | fish 4.5.0 | 6.6.2 | 27" 1920x1080 | konsole 25.12.3 | 172.31.255.245/26 |
| tsP3-cos | Desktop (ThinkStation P3 Ultra SFF G2) | Intel Core Ultra 9 285 (24C, 6.5 GHz) | NVIDIA RTX 2000 Ada + Intel iGPU | 16 GB | 64 GB DDR5 | 912 GB | CachyOS | 6.19.7-1 | fish 4.5.0 | 6.6.3 | 3x 63" 1920x1080 | konsole 25.12.3 | 172.31.255.246/26 |
| auraX9cos | Laptop (ThinkPad X9-14 Gen 1) | Intel Core Ultra 7 268V (8C, 4.9 GHz) | Intel Arc 130V/140V | Shared | 32 GB | 470 GB | CachyOS | 6.18.9-3 | bash 5.3.9 | 6.6.3 | 14" 1920x1200 | konsole 25.12.3 | 172.31.255.226/26 |
| p14s | Laptop (ThinkPad P14s Gen 4) | AMD Ryzen 7 PRO 7840U (16T, 5.13 GHz) | AMD Radeon 780M | Integrated | 11 GB | 468 GB | CachyOS | 6.19.3-2 | fish 4.5.0 | - | 14" 1920x1200 | cockpit-bridge 3.14.3 | 172.31.255.238/26 |

### Machine Roles

| Role | Machine | Why |
|------|---------|-----|
| Primary dev (Phases 0-7, 9) | NZXTcos | CUDA for transcription, 8 GB VRAM, 64 GB RAM |
| Benchmarking + large model inference | tsP3-cos | 16 GB VRAM (Nemotron Super 120B), triple displays for ADR composition |
| Mobile dev (Phase 8, travel) | auraX9cos | Portable, Intel Arc, no CUDA. Flutter build + deploy only. |
| Colleague onboarding | p14s | AMD, no CUDA. Runs all non-transcription phases. Remote via Cockpit :9090. |

### GPU Rules

- **Transcription** (faster-whisper/ctranslate2) requires NVIDIA CUDA. NZXTcos or tsP3-cos only.
- **Local LLM inference** (Nemotron, Qwen via Ollama) requires NVIDIA. NZXTcos for models <= 8 GB. tsP3-cos for models <= 16 GB.
- **auraX9cos and p14s:** No CUDA. Run extraction (Gemini Flash API), normalization, Flutter build, deploy. Transcription output is shared via git.

---

## Step 3: Pipeline Architecture

### Platform Constraints (Locked - Pillar 8)

Non-negotiable. Every project from this template uses:

| Layer | Tool | Rationale |
|-------|------|-----------|
| Frontend | Flutter Web | Single codebase for web + mobile. Zero-cost via Firebase. |
| Database | Cloud Firestore | Denormalized document store. Free tier (Spark). Real-time sync. |
| Hosting | Firebase Hosting | Static CDN. Preview channels for UAT. SSL auto. $0. |

### Pipeline Stages

| Stage | Tool | Input | Output | Runtime | Machine |
|-------|------|-------|--------|---------|---------|
| Acquisition | yt-dlp | Playlist URL | MP3 audio files | Local, no LLM | Any |
| Transcription | faster-whisper (CUDA) | MP3 audio | Timestamped transcript JSON | Local, NVIDIA GPU | NZXTcos / tsP3-cos |
| Extraction | Gemini 2.5 Flash API | Transcript JSON | Structured entity JSON | Cloud API, free tier | Any |
| Normalization | Gemini 2.5 Flash API | Entity JSON | Deduplicated JSONL | Cloud API, free tier | Any |
| Geocoding | Google Places API + Nominatim | Entity names/addresses | Lat/lng coordinates | API calls | Any |
| Enrichment | Gemini Flash + Google Places | Base entities | Enriched entities (ratings, hours, status) | API + LLM verification | Any |
| Browser crawl (Phase 8) | Firecrawl MCP | 4 reference site URLs | Design patterns for Flutter UI | MCP server | Any |
| LLM verification | Gemini Flash / Claude Sonnet | Enriched data | Verified data | Cloud API | Any |
| Firestore load | Firebase Admin SDK | Verified JSONL | Firestore documents | Local script | Any |
| Flutter build | Flutter SDK | Dart source | Web build | Local | Any |
| Deploy | Firebase CLI | Web build | Live site | Local | Any |
| Batch execution | tmux | Long-running phases | Session persistence + crash recovery | Local | Any |

### Orchestration Options

| Tool | Cost | Best For |
|------|------|----------|
| Claude Code (Opus 4.6) | Subscription | Primary dev. Complex debugging, self-healing. Run from Konsole, NOT IDE terminal. |
| Claude Code (Sonnet 4.6) | Subscription (cheaper) | Routine iterations, documentation-only phases. |
| Gemini CLI | Free | UAT auto-chain in tmux. Free alternative for colleagues without Claude Code license. |
| OpenClaw + NemoClaw | Free (OSS) | Multi-agent workflows. Security sandbox via OpenShell. Early alpha (March 2026). |
| Hyperagents (Meta FAIR) | Free (OSS) | Agent-of-agents orchestration. Dispatches to specialized sub-agents. Assess status - research only. |

### LLM Inference Options

| Tool | Cost | VRAM | Context | Best For |
|------|------|------|---------|----------|
| Gemini 2.5 Flash API | Free tier | None | 1M tokens | Primary extraction and normalization. Proven across 15+ iterations. |
| Nemotron 3 Nano 4B | Free (local) | 4-8 GB | ~8K | Offline normalization fallback. 8K context too small for extraction. NZXTcos. |
| Nemotron 3 Super 120B | Free (local) | 16+ GB | ~32K | Complex offline extraction. tsP3-cos only (16 GB VRAM). |
| Qwen 3.5-9B (Ollama) | Free (local) | ~8 GB | ~32K | Alternative local model. Struggled with structured extraction in early iterations - benchmark first. NZXTcos. |
| Claude Sonnet API | Per-token | None | 200K | Quality-critical verification passes. |

### Browser Automation + MCP Servers

| Tool | MCP | Best For |
|------|-----|----------|
| Firecrawl MCP | Yes | Phase 8: crawl 4 reference sites for Flutter UI design inspiration. Requires API key from firecrawl.dev. |
| Playwright MCP | Yes | Agent-driven browser testing. Post-flight verification. System deps handled by install.fish. |
| Puppeteer (npm) | No | Scripted post-flight testing. /tmp local install fallback pattern. |
| Lighthouse CLI | Optional | Hardening audits. Performance/a11y/SEO scoring. `npx lighthouse`. |
| Context7 MCP | Yes | Documentation lookup for framework APIs. Self-heal fallback. |

---

## Step 4: Scaffold Repository

```fish
cd ~/dev/projects/{project-name}

# Initialize repo + create directory structure
git init
mkdir -p docs/archive pipeline/scripts pipeline/config pipeline/data app requirements

# Create .gitignore
printf '%s\n' \
  '# Data' \
  'pipeline/data/' \
  'app/build/' \
  '' \
  '# Environment' \
  '.env' \
  '*.key' \
  '*.pem' \
  '' \
  '# IDE' \
  '.idea/' \
  '.vscode/' \
  '*.iml' \
  '' \
  '# OS' \
  '.DS_Store' \
  'Thumbs.db' \
  > .gitignore

# Create README with changelog section
printf '%s\n' \
  '# {Project}' \
  '' \
  '{One-line description}' \
  '' \
  '---' \
  '' \
  '## Changelog' \
  '' \
  > README.md

# Create CLAUDE.md version lock
printf '%s\n' \
  '# {Project} - Agent Instructions' \
  '' \
  '## Current Iteration: 0.1' \
  '' \
  'Read in order, then execute:' \
  '1. docs/{project}-design-v0.1.md' \
  '2. docs/{project}-plan-v0.1.md' \
  '' \
  '## Rules' \
  '- YOLO - code dangerously, never ask permission' \
  '- MUST produce {project}-build + {project}-report + {project}-changelog' \
  '- README changelog: NEVER truncate, ALWAYS append' \
  > CLAUDE.md
```

If using Gemini CLI as executor, also create `GEMINI.md` from the design doc Section 15 template.

---

## Step 5: Pre-Flight Validation

Every item must pass before launching the agent.

### Repository Checks

```
[ ] Git repo initialized
[ ] Directory structure created (docs/, docs/archive/, pipeline/, app/, requirements/)
[ ] CLAUDE.md (or GEMINI.md) exists at repo root
[ ] Design doc exists in docs/
[ ] Plan doc exists in docs/
[ ] .gitignore exists
[ ] README.md exists with changelog section
```

### Tool Verification

```fish
# Core
git --version && fish --version && tmux -V && node --version && npm --version && python3 --version

# Agents
claude --version
gemini --version

# Pipeline
yt-dlp --version
python3 -c "import faster_whisper; print('faster-whisper OK')"  # NVIDIA machines only
flutter --version && flutter analyze
firebase --version

# Browser automation
npx playwright --version
npx puppeteer --version
google-chrome-stable --version
firefox-esr --version

# API keys (must return valid JSON, not error)
curl -s "https://generativelanguage.googleapis.com/v1beta/models?key=$GEMINI_API_KEY" | head -1
```

### Playlist Validation

```fish
# Validate the YouTube playlist URL
yt-dlp --flat-playlist --print "%(id)s" "{PLAYLIST_URL}" | wc -l
# Must return a number > 0
```

---

## Step 6: Produce Phase 0 Report

Write `docs/{project}-report-v0.1.md`:

```markdown
# {Project} - Report v0.1 (Phase 0)

## Project Mandate
- What it builds: {description}
- Playlist URL: {url}
- Video count: {count}
- Cost constraint: $0 (free-tier everything)
- Platform: Flutter Web + Firestore + Firebase Hosting

## Hardware
- Primary dev machine: {hostname} ({GPU}, {VRAM})
- Colleague machine: {hostname} ({GPU})
- CUDA available: Yes/No

## Environment Validation
| Check | Result |
|-------|--------|
| git | PASS/FAIL |
| fish | PASS/FAIL |
| node + npm | PASS/FAIL |
| flutter | PASS/FAIL |
| firebase | PASS/FAIL |
| yt-dlp | PASS/FAIL |
| faster-whisper | PASS/FAIL/SKIP (no CUDA) |
| claude-code | PASS/FAIL |
| gemini-cli | PASS/FAIL |
| Playwright | PASS/FAIL |
| Puppeteer | PASS/FAIL |
| GEMINI_API_KEY | PASS/FAIL |
| Playlist URL | PASS/FAIL ({count} videos) |

## Repository State
- docs/ scaffolded
- CLAUDE.md version lock created
- .gitignore configured
- requirements/ committed

## Recommendation
Environment ready for Phase 1. Recommended first batch: 30 videos (10% of {total}).

## Orchestration Report
| Component | Workload | Efficacy |
|-----------|----------|----------|
| {executor} | 100% | High/Medium/Low |
```

Also produce:
- `docs/{project}-build-v0.1.md` (session transcript / command log)
- `docs/{project}-changelog-v0.1.md` (changelog snapshot)
- Append changelog entry to README.md

---

## Step 7: Plan Phase 1

Based on the Phase 0 report:

1. Read the report
2. Define Phase 1 scope: first 10% of the playlist (discovery batch)
3. Write `docs/{project}-plan-v1.2.md` with:
   - Specific video IDs for the first batch
   - Pipeline commands for each stage
   - Success criteria (binary, automatable)
   - Post-flight tests (Tier 1 + Tier 2)
   - Checkpoint strategy for long-running operations
4. Validate plan against the 14-item checklist (design doc Section 4)

**Progressive batching (Pillar 6):**

| Phase | Batch Size | Purpose |
|-------|-----------|---------|
| 1 | 10% | Discovery - validate pipeline works end-to-end |
| 2 | 25% | Calibration - tune prompts and extraction parameters |
| 3 | 50% | Stress test - zero-intervention target |
| 4 | 75% | Validation - lock prompts and configs |
| 5 | 100% | Production run - tmux, unattended |

---

## Success Criteria (Phase 0)

```
[ ] YouTube playlist URL validated (yt-dlp returns video list)
[ ] install.fish completed with 0 FAIL results (SKIP is OK for non-CUDA machines)
[ ] API keys set and validated (GEMINI_API_KEY, GOOGLE_PLACES_API_KEY)
[ ] MCP configs copied and keys added (Firecrawl, Playwright, Context7)
[ ] Repository scaffolded (all dirs, files, configs)
[ ] Pre-flight validation passes (all tools, all keys)
[ ] Phase 0 report produced
[ ] Phase 1 plan produced
[ ] Changelog entry appended to README
[ ] Zero interventions (or interventions documented if manual execution)
```

---

## Reminder: Formatting Rules

- NO em-dashes. Use " - " (space-hyphen-space).
- Use "->" for arrows.
- Changelog: APPEND only.
- fish shell: NO heredocs. Use printf or echo.
- Run Claude Code from Konsole, NOT IDE terminal.
