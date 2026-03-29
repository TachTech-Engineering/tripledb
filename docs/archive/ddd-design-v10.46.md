# TripleDB - Design v10.46

**ADR-001 | Living Architecture Document**
**Last Updated:** Phase 10, Iteration 46 (CAPSTONE)
**Author:** Kyle Thompson, Managing Partner & Solutions Architect @ TachTech Engineering
**Repository:** `git@github.com:TachTech-Engineering/tripledb.git`
**Live Site:** [tripledb.net](https://tripledb.net)
**Firebase Project:** tripledb-e0f77

---

# Table of Contents

1. [Phase 10 Summary](#1-phase-10-summary)
2. [Track C Architecture](#2-track-c-architecture)
3. [UAT Environment Spec](#3-uat-environment-spec)
4. [UAT Design Doc Spec](#4-uat-design-doc-spec)
5. [UAT Plan Doc Spec](#5-uat-plan-doc-spec)
6. [IAO Template Design Spec](#6-iao-template-design-spec)
7. [IAO Template Plan Spec](#7-iao-template-plan-spec)
8. [Current State](#8-current-state)
9. [Markdown Formatting Rules](#9-markdown-formatting)

---

Sections not repeated here (Pillars 1-9, environment setup, pipeline, data model, app architecture, locked decisions, scripts, repo structure, gotchas) are carried forward from v10.45. Reference `docs/archive/ddd-design-v10.45.md` and the full chain back through v9.43 for complete content.

---

# 1. Phase 10 Summary

```
Track A: Retrospective (v10.44) - COMPLETE
    19 failure modes, 14-item plan quality checklist, 10 lessons learned

Track B: Technology Radar + README (v10.45) - COMPLETE
    13 tools scored, 5 Adopt / 5 Trial / 2 Assess / 1 Hold

Track C: UAT Handoff + IAO Template (v10.46) - THIS ITERATION (CAPSTONE)
    4 deliverable artifacts produced
```

Phase 10 closes after v10.46. Dev continues for TripleDB features. UAT runs independently.

---

# 2. Track C Architecture

## What Track C Produces

4 artifacts in 2 pairs:

**Pair 1 - TripleDB UAT (for Gemini CLI):**

| Artifact | Filename | Purpose |
|----------|----------|---------|
| UAT Design | `ddd-design-uat.md` | Architecture for Gemini to replay the full TripleDB pipeline |
| UAT Plan | `ddd-plan-uat-v0.1.md` | Phase 0 setup + auto-chain instructions through all phases |

**Pair 2 - IAO Project Template (for Claude Code on any new project):**

| Artifact | Filename | Purpose |
|----------|----------|---------|
| Template Design | `iao-template-design-v0.1.md` | Generic Nine Pillars framework for any TachTech project |
| Template Plan | `iao-template-plan-v0.1.md` | Phase 0 scaffold plan for a brand-new IAO project |

## What Track C Does NOT Produce

- No Flutter code changes
- No pipeline code changes
- No Firebase configuration changes
- No deployments (the UAT artifacts are produced, not executed)

Gemini executes the UAT artifacts later, in a separate session. This iteration only writes the plans.

---

# 3. UAT Environment Spec

## Approach: Same Project, Hosting Preview Channel, No Firestore Writes

| Aspect | Dev | UAT |
|--------|-----|-----|
| Firebase project | tripledb-e0f77 | tripledb-e0f77 (same) |
| Hosting | Production (`firebase deploy --only hosting`) | Preview channel (`firebase hosting:channel:deploy uat`) |
| Firestore reads | Production collections | Production collections (same data) |
| Firestore writes | Pipeline scripts write via Admin SDK | **DISABLED** - pipeline produces local JSONL only |
| Domain | tripledb.net | Auto-generated preview URL |
| Preview expiry | N/A | 7 days (default, extendable) |
| Agent | Claude Code | Gemini CLI |
| Mode | YOLO interactive | YOLO auto-chain in tmux |
| Human review | Between iterations | None - single session |

## Why No Firestore Writes

- Production Firestore already has 1,102 restaurants, 582 enriched, all correct
- Gemini proving it can produce identical JSONL output is sufficient validation
- Admin SDK bypasses security rules - a write bug could corrupt production data
- Diff validation (UAT JSONL vs. dev JSONL) is a stronger test than "did the write succeed"

## UAT Validation Strategy

Instead of writing to Firestore, Gemini validates by:

1. **Pipeline output diff:** Compare UAT-generated JSONL files against dev artifacts in `pipeline/data/`
2. **Metric matching:** UAT report must show 1,102 restaurants, 582 enriched, 1,006 geocoded, etc.
3. **App build:** `flutter build web` succeeds, app deployed to preview channel, reads from production Firestore
4. **Preview channel verification:** Puppeteer tests against the preview URL confirm app loads, search works, map renders

## Preview Channel Commands

```bash
# Deploy to preview channel (Gemini runs this)
cd ~/dev/projects/tripledb/app
firebase hosting:channel:deploy uat --expires 7d

# Output: https://tripledb-e0f77--uat-HASH.web.app

# Verify preview channel
curl -sI https://tripledb-e0f77--uat-HASH.web.app

# Clean up after validation (Kyle runs this manually)
firebase hosting:channel:delete uat
```

---

# 4. UAT Design Doc Spec (ddd-design-uat.md)

The UAT design doc is derived from the dev design doc but adapted for Gemini CLI's execution model. It must contain:

## Required Sections

1. **Project overview** - what TripleDB is, what the UAT proves
2. **Nine Pillars (UAT adaptation)** - same pillars but with Gemini-specific notes:
   - Pillar 2: Gemini CLI is the executor, tmux is the runtime
   - Pillar 3: Zero-intervention is mandatory (no human available)
   - Pillar 7: Puppeteer for post-flight (local `/tmp` install pattern)
3. **Pipeline architecture** - layered table + data flow from dev design doc
4. **Data model** - restaurant and video schemas
5. **Environment setup** - fish config, API keys, npm packages, pip packages
6. **Phase chain** - all 10 phases with entry/exit criteria:
   ```
   Phase 0: Setup (clone repo, install deps, verify env)
   Phase 1: Discovery (30 videos)
   Phase 2: Calibration (60 cumulative)
   Phase 3: Stress Test (90 cumulative)
   Phase 4: Validation (120, prompts lock)
   Phase 5: Production (805, tmux batch)
   Phase 6: Firestore load + geocoding (LOCAL JSONL ONLY, no Firestore writes)
   Phase 7: Enrichment (LOCAL JSONL ONLY, no Firestore writes)
   Phase 8: Flutter app build + preview channel deploy
   Phase 9: Optimization + post-flight
   ```
7. **Firestore write prohibition** - explicit rule: pipeline produces JSONL, never calls Firebase Admin SDK write methods
8. **Auto-chain logic** - how report from Phase N feeds into Phase N+1 plan
9. **Success criteria** - metric targets matching dev (1,102 restaurants, 582 enriched, etc.)
10. **Em-dash sweep** - first task in Phase 0: replace all em-dashes in every file
11. **Known gotchas** - all 22 from dev design doc
12. **Hardware note** - which machine Gemini runs on (NZXTcos for CUDA, P3 for benchmarking)

## What to Omit

- No iteration history (UAT starts fresh)
- No technology radar (already completed)
- No retrospective framework (UAT is not a retrospective)
- No CLAUDE.md template (UAT uses GEMINI.md)

---

# 5. UAT Plan Doc Spec (ddd-plan-uat-v0.1.md)

Phase 0 setup plan that bootstraps the UAT environment and auto-chains into Phase 1.

## Required Steps

```
Step 0: Pre-Flight
  - Verify machine (NZXTcos or P3)
  - Verify fish config (API keys, CUDA path, Chrome path)
  - Verify npm packages (puppeteer, firebase-tools)
  - Verify pip packages (faster-whisper, yt-dlp, firebase-admin, requests)
  - Verify repo cloned and on main branch
  - Verify tmux session is active

Step 1: Em-Dash Sweep
  - grep -rn for em-dashes across all .md and .dart files
  - Replace all occurrences with " - "
  - Verify zero remaining: grep returns 0 matches

Step 2: Environment Validation
  - flutter analyze: 0 issues
  - flutter build web: success
  - Puppeteer available (global or local /tmp fallback)
  - firebase login status: authenticated
  - firebase use tripledb-e0f77: confirmed
  - GOOGLE_PLACES_API_KEY: set and reachable
  - GEMINI_API_KEY: set and reachable
  - faster-whisper: importable with CUDA
  - yt-dlp: version check

Step 3: Create GEMINI.md
  - Write version lock pointing to ddd-design-uat.md + ddd-plan-uat-v0.1.md

Step 4: Produce Phase 0 Report
  - Document all pre-flight results
  - Confirm environment ready for Phase 1

Step 5: Auto-Chain to Phase 1
  - Generate ddd-plan-uat-v1.1.md (30-video discovery plan)
  - Begin Phase 1 execution without stopping
```

## Auto-Chain Logic

After each phase completes:
1. Agent writes ddd-report for the current phase
2. Agent reads the report and identifies the next phase
3. Agent generates ddd-plan for the next phase based on design doc phase chain
4. Agent executes the new plan immediately
5. Repeat until Phase 9 complete or 3 consecutive identical failures

## tmux Requirement

The entire UAT session runs in tmux:
```bash
tmux new-session -s tripledb-uat
# Inside tmux:
cd ~/dev/projects/tripledb
gemini  # or however Gemini CLI is launched with YOLO autonomy
# Paste: "Read GEMINI.md and execute."
```

If SSH drops, reconnect: `tmux attach -t tripledb-uat`

---

# 6. IAO Template Design Spec (iao-template-design-v0.1.md)

A generic, project-agnostic IAO methodology template. This is institutional knowledge extraction - everything TachTech learned across 46 iterations of TripleDB, distilled into a reusable starting point for any new project.

## Required Sections

1. **What IAO Is** - 3-paragraph explanation of the methodology
2. **The Nine Pillars** - full pillar descriptions, project-agnostic:
   - Pillar 1: Artifact Loop (5 artifacts per iteration)
   - Pillar 2: Agentic Orchestration (agent permissions, sudo exception, two-environment model)
   - Pillar 3: Zero-Intervention Target (plan IS the permission)
   - Pillar 4: Pre-Flight Verification (standard checklist, project-specific additions)
   - Pillar 5: Self-Healing Execution (3 attempts, checkpoint scaffolding)
   - Pillar 6: Progressive Batching (start small, graduate to production)
   - Pillar 7: Post-Flight Testing (Tier 1 health, Tier 2 playbook, Tier 3 hardening)
   - **Pillar 8: Platform Constraints** (NOT "Mobile-First Flutter" - generic: "your non-negotiable architectural decisions that shape every tool choice")
   - Pillar 9: Continuous Improvement (archive review, tool efficacy, vulnerability/BPA, technology radar)
3. **Plan Quality Checklist** - the 14-item checklist from the retrospective, verbatim
4. **Failure Mode Reference** - condensed catalog of the 19 failure modes, categorized, with prevention strategies. Project teams can use this as a "what to watch for" guide.
5. **Top 10 Lessons Learned** - from the retrospective, reframed as universal principles (not TripleDB-specific examples)
6. **CLAUDE.md Template** - generic version with placeholders for project name, iteration number, MCP servers
7. **GEMINI.md Template** - generic version for UAT
8. **Artifact Naming Convention** - `{project}-{type}-v{P}.{I}.md`
9. **Markdown Formatting Rules** - em-dash prohibition, arrow conventions, changelog rules
10. **Quick Start** - 5 commands to scaffold a new IAO project (see Section 7)

## What to Omit

- No TripleDB-specific content (no restaurant schemas, no DDD references, no Guy Fieri)
- No hardware specs (placeholder: "document your fleet here")
- No pipeline architecture (placeholder: "document your pipeline here")
- No technology radar scores (placeholder: "run your own radar at project close")

## Tone

Concise, actionable, opinionated. This is a methodology guide, not a textbook. Written for a Solutions Architect who wants to hand it to Claude Code and start building.

---

# 7. IAO Template Plan Spec (iao-template-plan-v0.1.md)

Phase 0 scaffold plan for a brand-new IAO project. Kyle copies this file, replaces the placeholders, and launches Claude Code.

## Quick Start (5 commands)

```bash
# 1. Create project directory
mkdir -p ~/dev/projects/{project-name} && cd ~/dev/projects/{project-name}

# 2. Initialize repo + scaffold
git init && mkdir -p docs/archive pipeline/scripts pipeline/config pipeline/data app

# 3. Copy IAO template files
cp /path/to/iao-template-design-v0.1.md docs/{project}-design-v0.1.md
cp /path/to/iao-template-plan-v0.1.md docs/{project}-plan-v0.1.md

# 4. Create CLAUDE.md version lock
echo "# {Project} - Agent Instructions\n\nRead docs/{project}-design-v0.1.md then docs/{project}-plan-v0.1.md" > CLAUDE.md

# 5. Launch
claude --dangerously-skip-permissions
```

## Phase 0 Plan Steps

```
Step 0: Define Project Mandate
  - What does this project build?
  - What is the cost constraint?
  - What is the platform constraint (Pillar 8)?

Step 1: Document Environment
  - Hardware fleet (which machines, what GPUs, what VRAM)
  - OS and shell (CachyOS/fish or whatever)
  - Required packages (pacman, npm, pip)
  - API keys needed
  - MCP servers to configure

Step 2: Define Pipeline
  - What are the pipeline stages?
  - What tool at each stage?
  - What is the progressive batching plan?

Step 3: Scaffold Repository
  - Create directory structure
  - Create .gitignore
  - Create CLAUDE.md (version lock)
  - Create README.md (with changelog section)
  - Initial git commit

Step 4: Pre-Flight Validation
  - Run the standard pre-flight checklist from the design doc
  - Verify all tools are installed and accessible
  - Verify all API keys are set

Step 5: Produce Phase 0 Report
  - Document everything from Steps 0-4
  - Recommend Phase 1 scope (progressive batching: start small)
  - Generate ddd-changelog-v0.1.md

Step 6: Plan Phase 1
  - Based on Phase 0 report, produce the Phase 1 plan
  - Define the first batch size (Pillar 6: start small)
  - Define success criteria (binary, automatable)
```

---

# 8. Current State (After v10.45)

| Metric | Value |
|--------|-------|
| Videos processed | 773 / 805 |
| Unique restaurants | 1,102 |
| Unique dishes | 2,286 |
| Total visits | 2,336 |
| Geocoded | 1,006 (91.3%) |
| Enriched (verified) | 582 (52.8%) |
| Trivia facts | 151 |
| `flutter analyze` | 0 issues |
| Security headers | 7 deployed |
| Total API cost | $0 |
| Total iterations | 45 (v0.7 - v10.45) |
| Retrospective | Complete (v10.44) |
| Technology Radar | Complete (v10.45) |
| Phase 10 Track A+B | Complete |

---

# 9. Markdown Formatting Rules

Unchanged from v10.45. No em-dashes. Use " - " instead. Changelog threshold: >= 31 after v10.46.

---

# CLAUDE.md Template (v10.46)

```markdown
# TripleDB - Agent Instructions

## Current Iteration: 10.46 (CAPSTONE)

Phase 10 Track C. Produce 4 deliverable artifacts. No Flutter code changes.

Read in order, then execute:
1. docs/ddd-design-v10.46.md - Sections 4-7 are the specs for each deliverable
2. docs/ddd-plan-v10.46.md - Execution steps

## Formatting
- NEVER use em-dashes. Use " - " (space-hyphen-space) instead.
- Use "->" for arrows, not unicode or "-->".
- See Section 9 for full rules.

## Rules
- YOLO - code dangerously, never ask permission
- MUST produce: ddd-design-uat.md, ddd-plan-uat-v0.1.md, iao-template-design-v0.1.md, iao-template-plan-v0.1.md
- MUST also produce: ddd-build, ddd-report, ddd-changelog, README update
- POST-FLIGHT: Tier 1 only (no Flutter code changes)
- README changelog: NEVER truncate, ALWAYS append, >= 31. Copy to docs/ddd-changelog-v10.46.md

## Agent Permissions
- CAN: read all files in repo, create new files in docs/
- CANNOT: modify app/ or pipeline/ code, sudo, git add/commit/push
```
