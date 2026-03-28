# TripleDB - Design v10.45

**ADR-001 | Living Architecture Document**
**Last Updated:** Phase 10, Iteration 45
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
15. [Technology Radar - Scored](#15-technology-radar)

---

Sections 1-4 carried forward from v10.44 without changes. Reference `docs/archive/ddd-design-v10.44.md` for full Pillars 1-9, environment setup, and hardware fleet.

**Key Pillar 2 note for this iteration:** tmux is a primary execution component for bulk processing (Dev Group B) and the primary driver for all UAT auto-chain execution. It should appear prominently in the README tech stack, pipeline architecture, and IAO methodology sections.

---

# 5. Pipeline Architecture

## Layered Pipeline Table

| Stage | Tool | Input | Output | Runtime |
|-------|------|-------|--------|---------|
| `acquisition` | yt-dlp | YouTube playlist (805 URLs) | MP3 audio files | Local, tmux batch |
| `transcription` | faster-whisper large-v3 | MP3 audio | Timestamped JSON transcripts | Local CUDA (RTX 2080S), tmux |
| `extraction` | Gemini 2.5 Flash API | Transcripts (1M context) | Structured restaurant JSON | Free tier API call |
| `normalization` | Gemini 2.5 Flash API | Raw restaurant JSON | Deduplicated JSONL (1,102) | Free tier API call |
| `geocoding` | Nominatim (OpenStreetMap) | City/state pairs | Lat/lng coordinates (1,006) | Free, 1 req/sec, cached |
| `enrichment` | Google Places API (New) | Restaurant name + location | Ratings, status, URLs (582) | Free tier, Text Search + Details |
| `storage` | Firebase Admin SDK | Enriched JSONL | Cloud Firestore documents | Free tier (Spark) |
| `frontend` | Flutter Web | Firestore reads | tripledb.net | Firebase Hosting, free tier |
| `orchestration` | Claude Code (Dev) / Gemini CLI (UAT) | Design + plan docs | Build + report artifacts | tmux for batch/UAT |

## Data Flow Diagram

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

## Execution Model

| Mode | Agent | Runtime | Use Case |
|------|-------|---------|----------|
| Group A (interactive) | Claude Code or Gemini CLI | Terminal (Konsole) | Phases 1-4: iterative refinement, 30-video batches |
| Group B (unattended) | bash scripts | tmux session | Phase 5: 805-video production run, 14-hour execution |
| UAT (auto-chain) | Gemini CLI | tmux session | Phase 10+: all phases in a single session, zero human review |
| Post-flight | Puppeteer | Subprocess | Browser testing after each iteration |

---

# 6-11. Data Model, App Architecture, Locked Decisions, Scripts, Repo Structure, Gotchas

Carried forward from v10.44/v9.43. Reference `docs/archive/ddd-design-v9.43.md` Sections 6-11 for full content.

**Locked decision additions for v10.45:**

| Decision | Tool | Locked Since |
|----------|------|-------------|
| Pipeline batch execution | tmux + bash (Group B) | v5.14 |
| UAT auto-chain execution | tmux + Gemini CLI | v10.45 |

---

# 12. Current State (After v10.44)

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
| Total iterations | 44 (v0.7 - v10.44) |
| Retrospective | Complete (19 failure modes, 10 lessons, 14-tool matrix) |

---

# 13. Markdown Formatting Rules

Unchanged from v10.44. No em-dashes. Use " - " instead. Detection: `grep -rn '\xe2\x80\x94'`. Changelog threshold: >= 30 after v10.45.

---

# 14. Phase 10 Architecture

```
Track A: Retrospective (v10.44) - COMPLETE
    |
    v
Track B: Technology Radar + README Overhaul (v10.45) - THIS ITERATION
    |
    v
Track C: UAT Handoff + IAO Template (v10.46+)
```

### Retrospective Findings Integrated into Track B

From `docs/archive/ddd-retrospective-v10.44.md`:

- **Gap analysis confirmed:** Observability, rollback, and multi-agent coordination are gaps. None block UAT but should be addressed in future pillar evolution.
- **Plan Quality Checklist (14 items):** Referenced in CLAUDE.md and GEMINI.md templates. Agents should validate their plans against this checklist.
- **Tool stack recommendation confirmed:** Claude Code (Opus) for dev, Gemini CLI for batch, Gemini Flash for API, Puppeteer for testing. Radar scores align with retrospective data.
- **Pillar portability:** Pillar 8 becomes "Platform Constraints" for non-Flutter projects. This feeds directly into the IAO Project Template (Track C deliverable).

### Track C Deliverables (v10.46+)

The final Phase 10 iteration must produce at minimum **4 artifacts**:

**Pair 1 - TripleDB UAT (for Gemini CLI):**

| Artifact | Purpose |
|----------|---------|
| `ddd-design-uat.md` | Comprehensive UAT architecture derived from the dev design doc. Includes em-dash sweep requirement, all pipeline scripts, environment setup for a staging Firebase project. |
| `ddd-plan-uat-v0.1.md` | Phase 0 UAT setup + auto-chain instructions for Gemini CLI. The plan that boots the entire TripleDB pipeline from scratch in a single tmux session. |

**Pair 2 - IAO Project Template (for Claude Code):**

| Artifact | Purpose |
|----------|---------|
| `iao-template-design-v0.1.md` | Generic IAO project template. Nine Pillars with Pillar 8 as "Platform Constraints" (not Flutter-specific). Plan Quality Checklist from retrospective baked in. Failure mode catalog as reference. Hardware fleet section with placeholder. Em-dash rule. |
| `iao-template-plan-v0.1.md` | Generic Phase 0 plan for any new IAO project. Scaffolds the repo, creates CLAUDE.md, initializes artifacts, runs pre-flight. The plan that Kyle hands to Claude Code on day 1 of any TachTech project. |

The IAO template is the institutional knowledge extraction. Everything learned across 45+ iterations of TripleDB, distilled into a reusable starting point. The retrospective's 10 lessons, 14-item plan quality checklist, and 19 failure modes all feed into this template.

**What the template is NOT:**
- Not a copy of TripleDB's design doc with names changed
- Not a framework or platform (that's Ruflo's job)
- It's a set of markdown files that encode IAO methodology for a fresh project with zero history

---

# 15. Technology Radar - Scored

## Evaluation Methodology

Each tool scored on five axes (weights from v10.44 framework). Scores grounded in retrospective data from v10.44 (43-iteration archive review, 14-tool efficacy matrix, 19 failure modes).

**Scoring:** 1 = poor fit, 2 = marginal, 3 = acceptable, 4 = good, 5 = excellent.
**Weighted total:** (Arch x 0.30) + (Cost x 0.25) + (Tokens x 0.20) + (Integ x 0.15) + (Breadth x 0.10) = composite score out of 5.0.
**Rating:** Adopt (>= 4.0), Trial (3.0-3.9), Assess (2.0-2.9), Hold (< 2.0).

---

## Category A: Agent Orchestration Frameworks

### Ruflo (ruvnet/ruflo)

| Axis | Score | Rationale |
|------|-------|-----------|
| Architecture Fit | 2/5 | Swarm/hive-mind model. IAO uses single-agent-primary. Queen/worker topology is overkill for TripleDB. Could fit SOC Alpha multi-agent threat hunting. |
| Cost Model | 5/5 | Open source, MIT license. npm package. $0. |
| Token Efficiency | 3/5 | Swarm coordination overhead - queen agent + N workers consume more tokens than single agent. Token routing (cheap model for simple tasks) is a genuine feature. |
| Integration Path | 4/5 | npm package, MCP server available, Claude Code compatible. `npx ruflo@latest init` works today. |
| TachTech Breadth | 3/5 | Relevant for SOC Alpha (multi-agent security ops). Overkill for TripleDB and simple SIEM engagements. |

**Composite: 3.20 | Rating: Trial**
**Action:** POC on SOC Alpha. Evaluate queen/worker topology for parallel threat hunting agents. Do not adopt for TripleDB - single-agent IAO is sufficient.

### Claude Skills / CLAUDE.md Optimization

| Axis | Score | Rationale |
|------|-------|-----------|
| Architecture Fit | 5/5 | Native to Claude Code. CLAUDE.md IS the IAO version lock. Skills extend it with structured capabilities. |
| Cost Model | 5/5 | Built into Claude Code subscription. $0 incremental. |
| Token Efficiency | 4/5 | Skills load on-demand, not always in context. Reduces CLAUDE.md bloat. |
| Integration Path | 5/5 | Already using CLAUDE.md. Skills are a natural extension. |
| TachTech Breadth | 4/5 | Every TachTech project uses CLAUDE.md. Skills are portable. |

**Composite: 4.70 | Rating: Adopt**
**Action:** Package IAO pillars as Claude Skills for v10.46. Pre-flight, post-flight, and changelog verification become reusable skill files.

### Gemini CLI Skills

| Axis | Score | Rationale |
|------|-------|-----------|
| Architecture Fit | 4/5 | GEMINI.md mirrors CLAUDE.md. Skills would extend UAT execution model. |
| Cost Model | 5/5 | Free tier. |
| Token Efficiency | 3/5 | Gemini's context management is less efficient than Claude's for long plans. |
| Integration Path | 3/5 | GEMINI.md exists but skill ecosystem is less mature than Claude's. |
| TachTech Breadth | 2/5 | Only used for UAT. Not primary dev tool. |

**Composite: 3.65 | Rating: Trial**
**Action:** Evaluate during Phase 10 Track C (UAT). If Gemini CLI supports structured skill loading, adopt for UAT-specific skills.

---

## Category B: LLM Routing & Specialized Models

### NemoClaw / OpenClaw (NVIDIA)

| Axis | Score | Rationale |
|------|-------|-----------|
| Architecture Fit | 2/5 | OpenClaw is an "always-on agent OS" with self-evolving capabilities. IAO uses plan-driven iterations, not always-on agents. Fundamentally different paradigm. NemoClaw adds enterprise security sandbox (OpenShell) which is interesting for SOC Alpha. |
| Cost Model | 5/5 | Open source. Runs Nemotron 3 Nano 4B locally on P3 Ultra (16GB VRAM). Nemotron 3 Super 120B needs more VRAM (cloud or DGX). |
| Token Efficiency | 3/5 | Local inference = $0 per token. But Nemotron 3 Nano 4B quality for extraction tasks is unknown - v1.8-v1.9 showed local LLMs struggled with structured extraction. |
| Integration Path | 2/5 | Early alpha (March 16, 2026). "Not production-ready" per NVIDIA. CLI-based, not MCP. Would need custom integration. |
| TachTech Breadth | 4/5 | Security sandbox (OpenShell) is directly relevant to TachTech's cybersecurity practice. Policy-based agent governance aligns with enterprise client needs. |

**Composite: 3.05 | Rating: Trial**
**Action:** Install NemoClaw on P3 Ultra. Benchmark Nemotron 3 Nano 4B on TripleDB extraction tasks (compare against Gemini 2.5 Flash). Evaluate OpenShell security sandbox for SOC Alpha agent governance. Do NOT adopt for TripleDB production - too early, too different from IAO.

### Claude Sonnet 4.6 (Cost-Optimized Routing)

| Axis | Score | Rationale |
|------|-------|-----------|
| Architecture Fit | 4/5 | Same API as Opus. Could route simple tasks (changelog generation, README updates) to Sonnet while keeping Opus for complex work. |
| Cost Model | 4/5 | Cheaper per token than Opus. But Claude Code subscription is flat-rate for interactive use - cost benefit only matters for API calls. |
| Token Efficiency | 4/5 | Smaller context window than Opus but sufficient for most iteration tasks. |
| Integration Path | 5/5 | Same SDK, same MCP support, same CLAUDE.md format. Zero integration work. |
| TachTech Breadth | 4/5 | Universal - every TachTech project can route by task complexity. |

**Composite: 4.15 | Rating: Adopt**
**Action:** For API-based sub-agent tasks (batch document generation, structured extraction), route to Sonnet. Keep Opus for primary Dev agent (Claude Code interactive).

### Gemini 2.5 Flash (Current)

| Axis | Score | Rationale |
|------|-------|-----------|
| Architecture Fit | 5/5 | Already integrated. 1M context window solved extraction. |
| Cost Model | 5/5 | Free tier. Zero cost across 43 iterations. |
| Token Efficiency | 5/5 | 1M context eliminates chunking. Single-pass extraction. |
| Integration Path | 5/5 | Battle-tested across Phases 1-7. API, scripts, prompts all locked. |
| TachTech Breadth | 3/5 | Useful for extraction/normalization tasks. Less relevant for security ops. |

**Composite: 4.75 | Rating: Adopt**
**Action:** Continue using. No changes needed. Benchmark against Sonnet for extraction quality.

### Local LLMs (Ollama - Revisit)

| Axis | Score | Rationale |
|------|-------|-----------|
| Architecture Fit | 3/5 | Could replace Gemini Flash for normalization tasks that don't need 1M context. P3 Ultra (16GB VRAM) can run models that failed on NZXT (8GB VRAM). |
| Cost Model | 5/5 | $0. Local inference. |
| Token Efficiency | 4/5 | No API overhead. But local generation speed is slower than API. |
| Integration Path | 4/5 | Ollama installed on both machines. Scripts already have Ollama integration from v1.8-v1.9. |
| TachTech Breadth | 4/5 | Client-site inference for data-sensitive engagements (Cintas, Findlay). |

**Composite: 3.85 | Rating: Trial**
**Action:** On P3 Ultra, benchmark Qwen 3.5-14B and Nemotron 3 Nano 4B against Gemini Flash for normalization-only tasks (not extraction - Flash is locked for extraction). Report quality-per-second metrics.

---

## Category C: MCP Server Ecosystem

### Context7 MCP

| Axis | Score | Rationale |
|------|-------|-----------|
| Architecture Fit | 4/5 | Documentation lookup during execution. Useful for package upgrades, API changes. |
| Cost Model | 5/5 | Free. |
| Token Efficiency | 2/5 | Loads full API docs into context. Often not needed - v9.43 upgraded 5 packages without using it. |
| Integration Path | 5/5 | Already configured in mcp.json. |
| TachTech Breadth | 3/5 | Useful for any Flutter/Dart project. |

**Composite: 3.65 | Rating: Trial -> Adopt conditionally**
**Action:** Keep configured but don't reference in plans unless package upgrades are involved. Agent should try without Context7 first, use it as a self-heal tool.

### Puppeteer (npm)

| Axis | Score | Rationale |
|------|-------|-----------|
| Architecture Fit | 5/5 | Primary browser testing tool. Battle-tested v9.37-v9.43 (17+ tests, 0 false negatives). |
| Cost Model | 5/5 | Free. npm package. |
| Token Efficiency | 4/5 | Runs as subprocess, not in LLM context. Script-based. |
| Integration Path | 5/5 | npm install (local fallback pattern proven). Chrome + Firefox support. |
| TachTech Breadth | 4/5 | Any web project needs browser testing. |

**Composite: 4.70 | Rating: Adopt**
**Action:** Continue as primary. Document the local `/tmp` install pattern in every CLAUDE.md.

### Playwright MCP

| Axis | Score | Rationale |
|------|-------|-----------|
| Architecture Fit | 3/5 | MCP integration is nice. But system deps (libwoff1 etc.) fail on CachyOS. |
| Cost Model | 5/5 | Free. |
| Token Efficiency | 3/5 | MCP calls are in-context, consuming tokens for every browser action. |
| Integration Path | 2/5 | Requires system deps that aren't in standard Arch repos. Consistently skipped in v9.42. |
| TachTech Breadth | 3/5 | Same as Puppeteer but less reliable on Arch. |

**Composite: 3.05 | Rating: Hold**
**Action:** Drop from CLAUDE.md. Puppeteer covers all browser testing needs. Don't waste agent time debugging Playwright deps.

### Lighthouse CLI / MCP

| Axis | Score | Rationale |
|------|-------|-----------|
| Architecture Fit | 4/5 | Performance/a11y/SEO auditing. Critical for hardening iterations. |
| Cost Model | 5/5 | Free. npx lighthouse. |
| Token Efficiency | 4/5 | Runs as CLI subprocess. JSON output parsed by agent. |
| Integration Path | 4/5 | npx works. MCP server available but untested. |
| TachTech Breadth | 4/5 | Any web project benefits from Lighthouse scoring. |

**Composite: 4.15 | Rating: Adopt**
**Action:** Keep as npx CLI. Add to hardening iteration playbooks. Skip MCP until Playwright deps issue is resolved.

---

## Category D: Orchestration Patterns

### Meta/Hyperagent (Agent-of-Agents)

| Axis | Score | Rationale |
|------|-------|-----------|
| Architecture Fit | 3/5 | An orchestrator LLM dispatching to specialized sub-agents. IAO's two-environment model (Dev + UAT) is already a form of this. Could enhance auto-chaining. |
| Cost Model | 3/5 | Extra orchestrator layer = extra token spend. Justified only if sub-agents are cheaper (Sonnet routing). |
| Token Efficiency | 3/5 | Overhead of orchestrator context + routing decisions. |
| Integration Path | 2/5 | No standard tool. Would need custom implementation. |
| TachTech Breadth | 4/5 | SOC Alpha already uses multi-agent architecture (4 parallel agents). |

**Composite: 2.95 | Rating: Assess**
**Action:** Research further. The v10.44 retrospective shows single-agent IAO works well for TripleDB. Multi-agent patterns are relevant for SOC Alpha. Table for next project.

### CLAUDE.md Control Planes (@claude-flow/guidance)

| Axis | Score | Rationale |
|------|-------|-----------|
| Architecture Fit | 4/5 | Ruflo's guidance module structures CLAUDE.md into a compiled control plane with gates, trust scoring, and hash-chained proof. IAO's CLAUDE.md is simpler but effective. |
| Cost Model | 5/5 | Open source. |
| Token Efficiency | 3/5 | Structured control plane adds context overhead. Current CLAUDE.md is ~20 lines and works. |
| Integration Path | 3/5 | npm package. Would require rearchitecting CLAUDE.md format. |
| TachTech Breadth | 3/5 | Useful for long-running agents (SOC Alpha). Overkill for iteration-based IAO. |

**Composite: 3.55 | Rating: Assess**
**Action:** Read the @claude-flow/guidance docs. Evaluate the trust scoring concept for SOC Alpha agents that run for days. Don't adopt for IAO - our CLAUDE.md is lean and works.

---

## Radar Summary Table

| Tool | Rating | Composite | Arch | Cost | Tokens | Integ | Breadth | Action |
|------|--------|-----------|------|------|--------|-------|---------|--------|
| Claude Skills | **Adopt** | 4.70 | 5 | 5 | 4 | 5 | 4 | Package IAO pillars as skills |
| Gemini 2.5 Flash | **Adopt** | 4.75 | 5 | 5 | 5 | 5 | 3 | Continue, no changes |
| Puppeteer | **Adopt** | 4.70 | 5 | 5 | 4 | 5 | 4 | Continue as primary |
| Lighthouse CLI | **Adopt** | 4.15 | 4 | 5 | 4 | 4 | 4 | Keep for hardening |
| Claude Sonnet 4.6 | **Adopt** | 4.15 | 4 | 4 | 4 | 5 | 4 | Route simple tasks |
| Local LLMs (Ollama) | **Trial** | 3.85 | 3 | 5 | 4 | 4 | 4 | Benchmark on P3 Ultra |
| Context7 MCP | **Trial** | 3.65 | 4 | 5 | 2 | 5 | 3 | Keep, use sparingly |
| Gemini CLI Skills | **Trial** | 3.65 | 4 | 5 | 3 | 3 | 2 | Evaluate in UAT |
| Ruflo | **Trial** | 3.20 | 2 | 5 | 3 | 4 | 3 | POC for SOC Alpha |
| NemoClaw | **Trial** | 3.05 | 2 | 5 | 3 | 2 | 4 | Install on P3, benchmark |
| Playwright MCP | **Hold** | 3.05 | 3 | 5 | 3 | 2 | 3 | Drop from CLAUDE.md |
| Meta/Hyperagent | **Assess** | 2.95 | 3 | 3 | 3 | 2 | 4 | Research for SOC Alpha |
| CLAUDE.md Control Planes | **Assess** | 3.55 | 4 | 5 | 3 | 3 | 3 | Read docs, evaluate for SOC Alpha |

---

# README Overhaul Spec (v10.45)

## Changes Required

### 1. Pipeline Architecture Section

Replace the current ASCII-only pipeline diagram with:
- **Layered Pipeline Table** (Ruflo-style, from Section 5 above) - tool names in backtick formatting, input/output/runtime columns
- **Data Flow Diagram** below the table (refined version from Section 5)
- **Execution Model table** (Group A/B/UAT with tmux callouts)

### 2. tmux Visibility

tmux must appear in these README sections:
- **Tech Stack table:** Add row for tmux (batch execution, UAT auto-chain)
- **Architecture table:** Add `orchestration` layer row mentioning tmux
- **IAO Methodology blurb:** Mention tmux for bulk processing and UAT execution
- **Pipeline section:** tmux appears in Runtime column of layered table
- **Phase 5 changelog entry** already mentions tmux - verify it's present

### 3. Technology Radar Summary

Add a brief section to README with the Adopt/Trial/Hold summary table (not the full analysis - that lives in the design doc).

### 4. Phase 10 Status

Update phase table: Phase 10 Active, Track A complete, Track B complete after this iteration.

### 5. Changelog

APPEND v10.45 entry. Count >= 30.

---

# CLAUDE.md Template (v10.45)

```markdown
# TripleDB - Agent Instructions

## Current Iteration: {P}.{I}

Read in order, then execute:
1. docs/ddd-design-v{P}.{I}.md - Section 4 for env setup, Section 13 for formatting rules
2. docs/ddd-plan-v{P}.{I}.md

## Testing
- Puppeteer (npm): Primary. If missing: cd /tmp && mkdir test && cd test && npm init -y && npm install puppeteer
- Browser targets: Chrome Stable + Firefox ESR only

## Formatting
- NEVER use em-dashes. Use " - " (space-hyphen-space) instead.
- Use "->" for arrows, not unicode or "-->".

## Plan Quality (from retrospective)
- All env vars documented with exact names
- Hardware requirements validated in pre-flight
- API keys validated in pre-flight (not "set as needed")
- Every likely error has a documented response
- Success criteria are binary and automatable
- Post-flight tests are specific scripts
- Checkpoint strategy defined for long-running ops
- See docs/archive/ddd-retrospective-v10.44.md Section 4 for full 14-item checklist

## Rules
- YOLO - code dangerously, never ask permission
- MUST produce ddd-build + ddd-report + ddd-changelog
- POST-FLIGHT: Tier 1 + Tier 2 (Flutter iterations)
- README changelog: NEVER truncate, ALWAYS append. Copy to docs/ddd-changelog-v{P}.{I}.md

## Agent Permissions
- CAN: flutter build web, firebase deploy, npm install (local), pip install
- CANNOT: sudo (ask Kyle), git add/commit/push (Kyle commits at phase boundaries)
```

# GEMINI.md Template (v10.45)

Unchanged from v10.44.
