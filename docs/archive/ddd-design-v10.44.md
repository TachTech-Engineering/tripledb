# TripleDB - Design v10.44

**ADR-001 | Living Architecture Document**
**Last Updated:** Phase 10, Iteration 44
**Author:** Kyle Thompson, Managing Partner & Solutions Architect @ TachTech Engineering
**Repository:** `git@github.com:TachTech-Engineering/tripledb.git`
**Live Site:** [tripledb.net](https://tripledb.net)
**Firebase Project:** tripledb-e0f77

---

# Table of Contents

1. [Project Mandate](#1-project-mandate)
2. [IAO Methodology - The Nine Pillars](#2-iao-methodology)
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
13. [Markdown Formatting Rules](#13-markdown-formatting)
14. [Phase 10 Architecture](#14-phase-10)
15. [Retrospective Framework](#15-retrospective)
16. [Technology Radar Framework](#16-technology-radar)

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

# 2. IAO Methodology - The Nine Pillars

## What IAO Is

Iterative Agentic Orchestration - a development methodology where LLM agents execute project phases autonomously while humans review versioned artifacts between iterations. Each iteration produces a plan (input) and a report (output). The report informs the next plan. The methodology itself evolves alongside the project.

The pillars evolved through 44 iterations: 6 (v3.12) -> 8 (v5.14) -> 9 (v9.41).

---

## Pillar 1 - Artifact Loop

Every iteration produces **five** artifacts: design, plan, build, report, and changelog. These are the single source of truth.

| Direction | File | Author | Purpose |
|-----------|------|--------|---------|
| Input | `ddd-design-v{P}.{I}.md` | Claude (chat) | Living architecture, locked decisions |
| Input | `ddd-plan-v{P}.{I}.md` | Claude (chat) | Execution steps, success criteria, playbook |
| Output | `ddd-build-v{P}.{I}.md` | Executing agent | Full session transcript |
| Output | `ddd-report-v{P}.{I}.md` | Executing agent | Metrics, orchestration report, recommendation |
| Output | `ddd-changelog-v{P}.{I}.md` | Executing agent | Versioned snapshot of README changelog |
| Output | `README.md` (updated) | Executing agent | Status, metrics, changelog (APPEND only) |

Each report includes an **Orchestration Report**: tools used, workload share, efficacy.

### Changelog Resilience

Versioned changelog copy after each iteration. If README corrupted, reconstruct from latest `ddd-changelog-v{P}.{I}.md`.

---

## Pillar 2 - Agentic Orchestration

**Agent Permissions:**

| Action | Allowed? | Notes |
|--------|----------|-------|
| `flutter build web` | YES | Agents build freely |
| `firebase deploy --only hosting` | YES | Agents deploy hosting |
| `firebase deploy --only firestore:rules` | YES | Agents deploy rules |
| `npm install` (local, non-global) | YES | Project-level installs |
| `pip install --break-system-packages` | YES | Python packages |
| `sudo` (any command) | NEVER | Agent must ask Kyle (sudo exception) |
| `npm install -g` (global) | REQUIRES SUDO | Agent must ask Kyle |
| `git add / commit / push` | NEVER | Kyle commits at PHASE boundaries |

### Sudo Exception

YOLO does not grant sudo. When sudo is needed, the agent logs the command, asks Kyle, waits, continues. Sudo interventions are tracked separately - they are infrastructure friction, not plan quality failures.

### Dependency Recovery

1. Try local install first (e.g., `npm install puppeteer` in `/tmp`)
2. If local works, proceed
3. If global install truly needed, invoke sudo exception
4. Reference Section 4 (Environment Setup) for correct installation method

### Two-Environment Model

| Environment | Agent | Mode |
|-------------|-------|------|
| **Dev** | Claude Code | YOLO. Kyle + Claude iterate. |
| **UAT** | Gemini CLI | YOLO. Single session, auto-chain, zero human review. |

Dev never ends. Phase 10 is UAT handoff for TripleDB specifically.

### Tool Ecosystem

| Tool | Category | Purpose |
|------|----------|---------|
| Claude Code (Opus) | Primary executor (Dev) | Problem-solving, debugging, complex refactors |
| Gemini CLI | Primary executor (UAT) | Batch execution of proven plans |
| Gemini 2.5 Flash API | LLM API | Extraction, normalization, LLM verification |
| Puppeteer (npm) | Browser automation | Post-flight testing (primary) |
| Playwright MCP | Browser automation | Fallback only |
| Context7 MCP | Documentation | Flutter/Dart API docs |
| Lighthouse CLI (npx) | Performance audit | Perf, a11y, SEO scoring |
| tmux + bash | Unattended runner | Batch pipeline (Phases 5+), UAT auto-chain |
| Firebase Admin SDK | Database | Firestore CRUD |
| Google Places API (New) | Enrichment | Ratings, open/closed, websites |
| Nominatim | Geocoding | City -> lat/lng |
| faster-whisper | Local ML | CUDA transcription |
| yt-dlp | Media | YouTube -> mp3 |

### tmux in IAO

tmux is a primary execution component: Group B production batches, UAT auto-chain, long-running audits, crash recovery via persistent sessions.

### Browser Testing

**Primary: Puppeteer (npm).** Battle-tested across v9.37-v9.43. Local `/tmp` install pattern if global unavailable.

**Browser targets: Chrome Stable + Firefox ESR only.** No Chromium dev, Edge, Brave, Safari.

---

## Pillar 3 - Zero-Intervention Target

Every question the agent asks is a plan failure - except sudo operations. Measure plan quality by counting interventions. Zero is the floor.

---

## Pillar 4 - Pre-Flight Verification

```
[ ] Previous docs archived to docs/archive/
[ ] New design + plan in docs/
[ ] CLAUDE.md (or GEMINI.md) updated
[ ] git status clean
[ ] API keys set as needed
[ ] flutter analyze: 0 errors (if app iteration)
[ ] flutter build web: success (if app iteration)
[ ] Puppeteer available (global or local fallback)
```

---

## Pillar 5 - Self-Healing Execution

Diagnose -> fix -> re-run. Max 3 attempts. If 3 consecutive identical errors, STOP. Checkpoint files for crash recovery. Missing dependencies: local install first, sudo exception if needed.

---

## Pillar 6 - Progressive Batching

30 -> 60 -> 90 -> 120 -> 805 videos. Graduate from interactive agent to unattended tmux + bash when proven.

---

## Pillar 7 - Post-Flight Functional Testing

**Tier 1 - Standard Health:** App loads, console clean, changelog count + versioned copy.

**Tier 2 - Iteration Playbook:** Puppeteer functional tests against Chrome Stable + Firefox ESR. Accessibility tree, not screenshots.

**Tier 3 - Hardening Audit:** Lighthouse, error boundaries, security, browser compat. Hardening iterations only.

---

## Pillar 8 - Mobile-First Flutter + Firebase (Zero-Cost by Design)

Flutter single codebase. Firebase free tier. Cost is a design constraint.

**Package Upgrade Policy:** Agent evaluates breaking changes. Proceed if straightforward (<30 min). Defer if significant refactoring needed. Must pass analyze + build.

---

## Pillar 9 - Continuous Improvement

IAO evolves alongside every project. Structured retrospective at project close:

1. **Archive Review** - plan quality, intervention patterns across ALL iterations
2. **Tool Efficacy** - synthesize orchestration reports into scored matrix
3. **Vulnerability & BPA** - dependency CVE scan + best practice assessment
4. **Technology Radar** - deep analysis with 5-axis scoring (see Section 16)
5. **Pillar Evolution** - document how the methodology itself changed

---

# 3. Iteration History (Phase-Ordered)

## Phase 0 - Setup

| Iter | Status | Key Result | Enrichment State |
|------|--------|------------|-----------------|
| v0.7 | Done | Monorepo scaffolded, 805 URLs, fish shell gotchas | N/A |

## Phase 1 - Discovery (30 videos)

| Iter | Status | Key Result | Enrichment State |
|------|--------|------------|-----------------|
| v1.8 | Failed | Nemotron 42GB on 8GB VRAM = timeout loops | N/A |
| v1.9 | Failed | Qwen 3.5-9B too slow for structured extraction | N/A |
| v1.10 | Done | Gemini Flash API solved extraction. 186 restaurants, 290 dishes | N/A |

## Phase 2 - Calibration (60 videos cumulative)

| Iter | Status | Key Result | Enrichment State |
|------|--------|------------|-----------------|
| v2.11 | Done | 422 restaurants, 624 dishes. CUDA path must be shell-level. 20+ interventions | N/A |

## Phase 3 - Stress Test (90 videos cumulative)

| Iter | Status | Key Result | Enrichment State |
|------|--------|------------|-----------------|
| v3.12 | Done | **Zero interventions.** Autonomous batch healing. 511 restaurants, 98 dedup merges | N/A |

## Phase 4 - Validation (120 videos cumulative)

| Iter | Status | Key Result | Enrichment State |
|------|--------|------------|-----------------|
| v4.13 | Done | 608 restaurants, 162 merges. Prompts locked. Group B green-lit | N/A |

## Phase 5 - Production Run (805 videos)

| Iter | Status | Key Result | Enrichment State |
|------|--------|------------|-----------------|
| v5.14 | Done | Runner infrastructure, null-name fix, Eight Pillars documented | N/A |
| v5.15 | Done | 773 extracted. 14-hour unattended tmux run. 4 timeout skips | N/A |

## Phase 6 - Firestore + Geocoding + Polish

| Iter | Status | Key Result | Enrichment State |
|------|--------|------------|-----------------|
| v6.26 | Done | 1,102 restaurants loaded to Firestore. App wired | N/A |
| v6.27 | Reverted | Geolocation fix broke Firestore (reverted v6.28) | N/A |
| v6.28 | Done | 916/1102 geocoded via Nominatim. Map working | Geocoded: 916 (83.1%) |
| v6.29 | Done | Trivia state count fix, map pin clustering, README refresh | Geocoded: 916 |

## Phase 7 - Enrichment + Analytics

| Iter | Status | Key Result | Enrichment State |
|------|--------|------------|-----------------|
| v7.30 | Done | Google Places API pipeline built. 50-restaurant batch: 66.7% match | Enriched: 30, Geocoded: 920 |
| v7.31 | Done | Full run: 625 enriched at 55.9%. 1 intervention (API key) | Enriched: 625, Closed: 32, Geocoded: 924 |
| v7.32 | Done | Refined search: 83 recovered. LLM verification: 126 false positives removed | Enriched: 582, Closed: 30, Geocoded: 1,006 |
| v7.33 | Done | AKA names backfilled (283 changes). Grey pins, closed filter, checkpointing | Enriched: 582, Names: 283, Closed: 30 |
| v7.34 | Done | Cookie consent (GDPR/CCPA). Firebase Analytics consent mode v2. Name threshold 0.90 | Enriched: 582, Names: 279, Closed: 34 |

## Phase 8 - Flutter App

| Iter | Status | Key Result | Enrichment State |
|------|--------|------------|-----------------|
| v8.17-21 | Done | Pass 1: scaffold + core features (thin QA) | N/A |
| v8.22-25 | Done | Pass 2: design tokens, component patterns. Lighthouse A11y 92, SEO 100 | N/A |

## Phase 9 - App Optimization + Hardening

| Iter | Status | Executor | Key Result | Enrichment State |
|------|--------|----------|------------|-----------------|
| v9.35 | Done | Claude Code | Riverpod 2->3, geolocator 10->14, 70+ trivia, 15 nearby | Enriched: 582 |
| v9.36 | Done | Claude Code | White screen crash fix (lazy init, deferred DOM) | Enriched: 582 |
| v9.37 | Done | Claude Code | Post-flight protocol v1 (Pillar 7 established) | Enriched: 582 |
| v9.38 | Done | Claude Code | Cookie banner fix (Secure flag, RFC 1123, robust parsing) | Enriched: 582 |
| v9.39 | Done | Claude Code | 3 bug fixes: Unknown filter, dedup, location-on-consent | Enriched: 582 |
| v9.40 | Done | Claude Code | dart:html -> package:web. Firestore security rules | Enriched: 582 |
| v9.41 | Done | Claude Code | Nine Pillars, methodology update, README overhaul | Enriched: 582 |
| v9.42 | Done | Claude Code | Hardening audit: 7 fixed (security headers, cache, CSP), 5 deferred | Enriched: 582 |
| v9.43 | Done | Claude Code | Package upgrades (flutter_map 8, go_router 17), 151 trivia, prefs->location | Enriched: 582 |

## Phase 10 - Retrospective + Technology Radar + UAT Handoff

| Iter | Status | Executor | Key Result | Enrichment State |
|------|--------|----------|------------|-----------------|
| v10.44 | Active | Claude Code | Pillar 9 retrospective: archive review across 43 iterations | Enriched: 582 |

---

# 4. Environment Setup (From Scratch)

Target: CachyOS (Arch Linux) with KDE Plasma, Wayland, fish shell.

## Hardware Fleet

### NZXTcos - Primary Dev Machine (Phases 0-7, 9)

| Component | Spec |
|-----------|------|
| System | NZXT MS-7E06 (MSI PRO Z790-P WIFI DDR4) |
| CPU | Intel Core i9-13900K (24-core, 8P+16E, 5.8 GHz boost) |
| RAM | 64 GB DDR4 |
| GPU 1 | NVIDIA GeForce RTX 2080 SUPER (8 GB VRAM) - CUDA transcription |
| GPU 2 | Intel UHD Graphics 770 (integrated) |
| Storage | 912 GB ext4 |
| Display | 27" 1920x1080 60Hz external |
| OS | CachyOS x86_64 (kernel 6.19.7-1-cachyos) |
| Shell | fish 4.5.0, Konsole 25.12.3 |
| Role | Pipeline execution, CUDA transcription, all dev phases, primary workstation |

### tsP3-cos - Benchmarking & ADR Composition

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
| Shell | fish 4.5.0, Konsole 25.12.3 |
| Role | Benchmarking, ADR composition, 16GB VRAM for model evaluation (OpenClaw, NemoClaw) |

### auraX9cos - Mobile Dev (Phase 8, RSA Conference)

| Component | Spec |
|-----------|------|
| System | Lenovo ThinkPad X9-14 Gen 1 (21QACTO1WW) |
| CPU | Intel Core Ultra 7 268V (8-core, 3.7 GHz boost) |
| RAM | 32 GB |
| GPU | Intel Arc Graphics 130V / 140V @ 2.0 GHz |
| Storage | 469 GB |
| Display | 14" 1920x1200 60Hz |
| OS | CachyOS x86_64 (kernel 6.18.9-3-cachyos) |
| Shell | bash 5.3.9 (fish not configured), Konsole 25.12.3 |
| Role | Phase 8 Flutter scaffold (RSA Conference, San Francisco). Travel machine. |

## Install Commands

Unchanged from v9.43. See `docs/archive/ddd-design-v9.43.md` Section 4 for full one-shot install blocks. Key packages: `pacman -S chromium firefox-esr`, `sudo npm install -g puppeteer firebase-tools @anthropic-ai/claude-code @google/gemini-cli`.

---

# 5-11. Pipeline, Data Model, App Architecture, Locked Decisions, Scripts, Repo Structure, Gotchas

Carried forward from v9.43 without changes. Reference `docs/archive/ddd-design-v9.43.md` Sections 5-11 for full content.

**Key additions from v9.43 that remain active:**
- flutter_map 8.2.2, go_router 17.1.0, google_fonts 8.0.2
- 151 trivia facts with Set-based dedup and shuffle rotation
- Save Preferences -> force-enable location
- Security headers: CSP, HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy
- Browser test targets: Chrome Stable + Firefox ESR only
- Puppeteer primary, Playwright fallback
- 22 known gotchas

---

# 12. Current State (After v9.43)

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
| Avg Google rating | 4.4 stars |
| Trivia facts | 151 |
| `flutter analyze` | 0 issues |
| Lighthouse A11y | 93 |
| Lighthouse SEO | 100 |
| Security headers | 7 deployed |
| Total API cost | $0 |
| Total iterations | 43 (v0.7 - v9.43) |
| Phase 9 status | Complete (v9.35-v9.43) |

---

# 13. Markdown Formatting Rules

All artifacts produced by agents (design, plan, build, report, changelog, README, CLAUDE.md, GEMINI.md) must follow these formatting rules.

## Em-Dash Prohibition (v10.44)

**NEVER use em-dashes ( --- ) in any artifact.** Always use a regular hyphen with spaces ( - ) instead. Em-dashes are a dead giveaway for AI-generated text.

| Wrong | Right |
|-------|-------|
| `Phase 9 --- App Optimization` | `Phase 9 - App Optimization` |
| `Claude is the R&D lab --- Gemini is the factory` | `Claude is the R&D lab - Gemini is the factory` |
| `Zero-cost --- not by accident` | `Zero-cost - not by accident` |

This applies to ALL text in ALL artifacts. No exceptions. The UAT agent (Gemini CLI) must also sweep existing files for em-dashes and replace them as part of Phase 10 execution.

**Detection command:**
```bash
grep -rn '\xe2\x80\x94' docs/ README.md CLAUDE.md GEMINI.md app/lib/ 2>/dev/null
# Should return 0 matches after cleanup
```

## Other Formatting Rules

- Use `" - "` (space-hyphen-space) for parenthetical asides
- Use `-` for list items
- Use `->` for arrows in flow descriptions (not `-->` or unicode arrows)
- Use `*` for emphasis, `**` for strong emphasis
- NEVER truncate the README changelog
- Changelog count threshold: >= 29 after v10.44

---

# 14. Phase 10 Architecture

## What Phase 10 Is

Phase 10 has three sequential tracks:

```
Track A: Retrospective (v10.44)
    |
    v
Track B: Technology Radar (v10.45)
    |
    v
Track C: UAT Handoff (v10.46+)
```

### Track A - Retrospective (v10.44, this iteration)

Pillar 9 archive review across all 43 iterations. Produces:
- Intervention timeline (which iterations had interventions, why)
- Tool efficacy matrix (aggregated from all orchestration reports)
- Pillar evolution timeline (6 -> 8 -> 9 with change rationale at each step)
- Plan quality analysis (what made good plans vs. bad plans)
- Top 10 lessons learned
- Failure mode catalog (categorized by root cause)

### Track B - Technology Radar (v10.45)

Deep analysis of the AI agent ecosystem. See Section 16 for the full framework. Uses retrospective data from Track A to ground tool scoring in actual project experience. The ThinkStation P3 Ultra (16GB VRAM) runs local model benchmarks.

Produces:
- 5-axis scored radar for every evaluated tool
- Cost model comparison (Opus vs. Sonnet vs. Flash vs. local)
- Token efficiency benchmarks
- TachTech institutional knowledge document

### Track C - UAT Handoff (v10.46+)

Uses radar results to configure the UAT environment. Produces:
- GEMINI.md version lock
- UAT design doc (derived from this dev design doc)
- UAT plan doc (Phase 0 setup + auto-chain through all phases)
- Staging Firebase project configuration
- Em-dash cleanup sweep (Gemini's first UAT task)
- End-to-end UAT execution in a single tmux session

### Phase 10 Prerequisites (all met after v9.43)

| Prerequisite | Status |
|-------------|--------|
| flutter analyze: 0 issues | Done |
| Security headers deployed | Done (v9.42) |
| Package upgrades complete | Done (v9.43) |
| Trivia expansion deployed | Done (v9.43, 151 facts) |
| Preferences -> location fix | Done (v9.43) |
| Firefox ESR testing passing | Done (v9.43) |
| Hardening P0/P1 findings resolved | Done (v9.42) |

---

# 15. Retrospective Framework

## What the Retrospective Produces

The retrospective is a structured analysis of 43 iterations across 10 phases. It transforms the archive trail into institutional knowledge.

## Deliverable 1: Intervention Timeline

Scan all build logs and reports in `docs/archive/` for intervention counts. Produce a table:

| Iter | Phase | Interventions | Sudo | Root Cause |
|------|-------|---------------|------|------------|
| v0.7 | 0 | ? | 0 | (review archive) |
| v1.8 | 1 | ? | 0 | (review archive) |
| ... | ... | ... | ... | ... |
| v9.43 | 9 | 0 | 0 | N/A |

**Analysis questions:**
- Which phases had the most interventions?
- What was the trend over time? (should decrease as plans get tighter)
- What categories of interventions were most common? (environment, API, logic, testing)
- At what iteration did zero-intervention become the norm?

## Deliverable 2: Tool Efficacy Matrix

Aggregate all orchestration reports from every iteration that includes one. Produce:

| Tool | Iterations Used | Total Workload | Avg Efficacy | Notable Failures |
|------|----------------|----------------|-------------|-----------------|
| Claude Code (Opus) | v9.35-v9.43 | 60-100% | High | None |
| Gemini CLI | v0.7-v7.34 | 80-100% | High | v1.8-v1.9 (local LLM failures) |
| Puppeteer | v9.37-v9.43 | 15-20% | High | Permission errors (v9.42) |
| Playwright MCP | v9.37-v9.42 | 0-15% | Low | System deps missing, skipped |
| ... | ... | ... | ... | ... |

## Deliverable 3: Pillar Evolution Timeline

| Version | Iteration | Pillars | What Changed |
|---------|-----------|---------|-------------|
| v1 | v3.12 | 6 | Initial methodology documented |
| v2 | v5.14 | 8 | Added Progressive Batching + Continuous Improvement |
| v3 | v9.41 | 9 | Added Mobile-First Flutter/Firebase (Zero-Cost). Renumbered CI to 9 |
| v3.1 | v9.42 | 9 | Added Tier 3 (hardening). 5th artifact (changelog). |
| v3.2 | v9.43 | 9 | Sudo exception. Package upgrade policy. Browser targets locked. |
| v3.3 | v10.44 | 9 | Em-dash rule. Retrospective framework formalized. |

## Deliverable 4: Plan Quality Analysis

What separates a good IAO plan from a bad one? Analyze patterns across 43 iterations:

**Good plan indicators:**
- Zero interventions
- Zero self-heal cycles
- All post-flight tests pass first try
- Agent completes in a single session

**Bad plan indicators:**
- Multiple interventions
- Agent asks clarifying questions
- Post-flight failures requiring re-work
- Missing pre-flight items discovered during execution

Produce a checklist of "plan quality patterns" that can be applied to future projects.

## Deliverable 5: Failure Mode Catalog

Categorize every failure, error, and intervention across 43 iterations:

| Category | Examples | Frequency | Mitigation |
|----------|---------|-----------|-----------|
| Environment | CUDA path, npm permissions, missing deps | High (early) | Pre-flight checklist, Section 4 |
| API | Rate limits, key issues, tier limits | Medium | Pre-flight key validation |
| Logic | False positives, dedup errors, wrong thresholds | Medium | Progressive batching |
| Frontend | White screen, cookie bugs, a11y failures | Medium (Phase 9) | Tier 2 playbook |
| Testing | Playwright deps, Puppeteer module not found | Low (Phase 9) | Puppeteer primary, local fallback |
| Methodology | Changelog truncation, missing artifacts | Low | Post-flight verification |

## Deliverable 6: Top 10 Lessons Learned

Distill the entire archive into 10 actionable lessons. These become the opening section of the UAT design doc so Gemini CLI inherits the institutional knowledge.

---

# 16. Technology Radar Framework

## Evaluation Axes

Each tool scored on five axes:

| Axis | Weight | What It Measures |
|------|--------|-----------------|
| Architecture Fit | 30% | Slots into IAO's single-agent-primary model? |
| Cost Model | 25% | Free tier? Per-token? Violates zero-cost constraint? |
| Token Efficiency | 20% | Tokens per task vs. current approach? |
| Integration Path | 15% | MCP server? npm package? Callable today? |
| TachTech Breadth | 10% | Useful beyond TripleDB? SOC Alpha, SIEM, clients? |

Rating: **Adopt** (use now) / **Trial** (test in sandbox) / **Assess** (research) / **Hold** (not yet)

## Categories to Evaluate

### A. Agent Orchestration Frameworks

- Ruflo (ruvnet/ruflo) - 25K stars, swarm architecture, 313 MCP tools
- Claude Skills / CLAUDE.md optimization
- Gemini CLI Skills

### B. LLM Routing & Specialized Models

- OpenClaw / NemoClaw - NVIDIA-optimized local inference
- Claude Sonnet 4.6 - cheaper than Opus for routine tasks
- Gemini 2.5 Flash - already used, benchmark against Sonnet
- Local LLMs (Ollama) - revisit with newer models on P3 Ultra (16GB VRAM)

### C. MCP Server Ecosystem

- Context7 (active), Playwright (fallback), Lighthouse, Firecrawl
- Sequential Thinking MCP, Filesystem MCP

### D. Orchestration Patterns

- Meta/Hyperagent (agent-of-agents)
- CLAUDE.md control planes (Ruflo's @claude-flow/guidance)
- Skill libraries (portable IAO pillars across projects)

## Radar Output (v10.45 deliverable)

```
| Tool | Rating | Arch | Cost | Tokens | Integ | Breadth | Action |
|------|--------|------|------|--------|-------|---------|--------|
| Ruflo | ? | ?/5 | ?/5 | ?/5 | ?/5 | ?/5 | ? |
| ... | ... | ... | ... | ... | ... | ... | ... |
```

---

# CLAUDE.md Template (v10.44)

```markdown
# TripleDB - Agent Instructions

## Current Iteration: {P}.{I}

Read in order, then execute:
1. docs/ddd-design-v{P}.{I}.md - Section 4 for env setup, Section 13 for formatting rules
2. docs/ddd-plan-v{P}.{I}.md

## MCP Servers
- Context7: Flutter/Dart API docs

## Testing
- Puppeteer (npm): Primary. If missing: cd /tmp && mkdir test && cd test && npm init -y && npm install puppeteer
- Browser targets: Chrome Stable + Firefox ESR only
- Playwright MCP: Fallback only

## Formatting
- NEVER use em-dashes. Use " - " (space-hyphen-space) instead.
- Use "->" for arrows, not unicode or "-->".
- See Section 13 for full rules.

## Rules
- YOLO - code dangerously, never ask permission
- Self-heal: max 3 attempts, checkpoint for crash recovery
- MUST produce ddd-build + ddd-report + ddd-changelog
- POST-FLIGHT: Tier 1 + Tier 2 (Flutter iterations)
- README changelog: NEVER truncate, ALWAYS append. Copy to docs/ddd-changelog-v{P}.{I}.md

## Agent Permissions
- CAN: flutter build web, firebase deploy, npm install (local), pip install
- CANNOT: sudo (ask Kyle), git add/commit/push (Kyle commits at phase boundaries)
- Sudo interventions do NOT count against zero-intervention target
```

---

# GEMINI.md Template (v10.44)

```markdown
# TripleDB - UAT Agent Instructions

## Current Phase: UAT Execution

Read in order, then execute:
1. docs/ddd-design-uat.md - Full UAT architecture
2. docs/ddd-plan-uat-phase0.md - Phase 0 setup + auto-chain instructions

## UAT Rules
- YOLO - full autonomy, zero human review
- Auto-chain: report from Phase N feeds into plan for Phase N+1
- Em-dash sweep: replace all " --- " with " - " in every file touched
- MUST produce ddd-build + ddd-report + ddd-changelog per phase
- All phases execute in a single tmux session
- If any phase fails with 3+ consecutive identical errors, STOP and produce failure report

## Formatting
- NEVER use em-dashes. Use " - " (space-hyphen-space) instead.
- See design doc Section 13 for full rules.

## Environment
- Firebase project: TBD (staging, not tripledb-e0f77)
- Domain: staging.tripledb.net or localhost
- MCP: Context7, Playwright (optional)

## Success Criteria
- All phases complete with 0 interventions
- Final metrics match Dev: 1,102 restaurants, 582 enriched, etc.
- Total execution time and token spend logged
```
