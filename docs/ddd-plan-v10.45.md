# TripleDB - Phase 10 Plan v10.45

**Phase:** 10 - Retrospective + Technology Radar + UAT Handoff
**Iteration:** 45 (global)
**Executor:** Claude Code (YOLO mode - `claude --dangerously-skip-permissions`)
**Date:** March 2026
**Goal:** Produce scored technology radar (13 tools, 5-axis evaluation). Overhaul README pipeline section with Ruflo-style layered table. Add tmux visibility across README tech stack, architecture, and IAO sections. Update phase status.

---

## Read Order

```
1. docs/ddd-design-v10.45.md - Section 5 = new pipeline architecture. Section 15 = scored radar.
2. docs/ddd-plan-v10.45.md - This file. Execution steps.
```

---

## Autonomy Rules

```
1. AUTO-PROCEED. NEVER ask permission. YOLO.
2. SELF-HEAL: max 3 attempts per error. Checkpoint for crash recovery.
3. Git READ only. NEVER git add/commit/push.
4. NO Flutter code changes this iteration. README + documentation only.
5. FULL PROJECT ACCESS under ~/dev/projects/tripledb/.
6. MANDATORY: ddd-build + ddd-report + ddd-changelog + README.
7. CHECKPOINT after every numbered step.
8. POST-FLIGHT: Tier 1 only (no Flutter changes = Tier 2 exempt).
9. CHANGELOG: APPEND only, >= 30 entries after update. Copy to docs/ddd-changelog-v10.45.md.
10. FORMATTING: NEVER use em-dashes. Use " - " instead.
11. Orchestration Report REQUIRED in ddd-report.
```

---

## What This Iteration Produces

| Deliverable | Description |
|-------------|------------|
| Technology Radar document | `docs/ddd-radar-v10.45.md` - 13 tools scored across 5 axes |
| README overhaul | Pipeline table, tmux visibility, radar summary, phase status |
| Standard artifacts | ddd-build, ddd-report, ddd-changelog |

## What This Iteration Does NOT Change

| Item | Why |
|------|-----|
| Any Flutter code | Documentation only |
| Any pipeline code | Documentation only |
| firebase.json | No deployment changes |
| pubspec.yaml | No dependency changes |

---

## Step 0: Pre-Flight

```bash
cd ~/dev/projects/tripledb

# Verify docs
ls docs/ddd-design-v10.45.md
ls docs/ddd-plan-v10.45.md

# Archive v10.44
mkdir -p docs/archive
mv docs/ddd-design-v10.44.md docs/archive/ 2>/dev/null
mv docs/ddd-plan-v10.44.md docs/archive/ 2>/dev/null
mv docs/ddd-report-v10.44.md docs/archive/ 2>/dev/null
mv docs/ddd-build-v10.44.md docs/archive/ 2>/dev/null
mv docs/ddd-changelog-v10.44.md docs/archive/ 2>/dev/null
mv docs/ddd-retrospective-v10.44.md docs/archive/ 2>/dev/null

# Changelog count
grep -c '^\*\*v' README.md
# Expected: 29

# Initialize checkpoint
mkdir -p pipeline/data/checkpoints
```

**Write checkpoint after Step 0.**

---

## Step 1: Produce Technology Radar Document

Create `docs/ddd-radar-v10.45.md` containing the full scored analysis from the design doc Section 15.

### Structure

```markdown
# TripleDB - Technology Radar v10.45

## Methodology
[5-axis framework, scoring, rating thresholds]

## Category A: Agent Orchestration
[Ruflo, Claude Skills, Gemini CLI Skills - full analysis per tool]

## Category B: LLM Routing
[NemoClaw/OpenClaw, Claude Sonnet 4.6, Gemini Flash, Local LLMs - full analysis per tool]

## Category C: MCP Servers
[Context7, Puppeteer, Playwright, Lighthouse - full analysis per tool]

## Category D: Orchestration Patterns
[Meta/Hyperagent, CLAUDE.md Control Planes - full analysis per tool]

## Summary Table
[13-tool radar with composite scores and actions]

## Recommendations for Track C (UAT Handoff)
- Which tools to include in UAT configuration
- Which tools to benchmark on P3 Ultra before UAT
- What changes to GEMINI.md based on radar results
```

### Key Data Points to Include

For each tool, the radar doc should include:
- The 5-axis scores from the design doc
- **Evidence from retrospective:** Reference specific iteration data that supports the score (e.g., "Playwright skipped in v9.42 due to missing libwoff1 deps" -> Integration = 2/5)
- **Cost analysis:** Actual $ spent (or saved) using this tool across 44 iterations
- **Token comparison:** Where applicable, estimate tokens consumed per task (e.g., Context7 loads ~5K tokens of API docs per lookup)
- **Concrete action:** What happens next with this tool - not vague "evaluate further" but specific ("Install NemoClaw on tsP3-cos, run `nemoclaw init --model local:nemotron-3-nano-4b`, benchmark against Gemini Flash on 10 extraction tasks")

### NemoClaw/OpenClaw Notes

From web research (March 2026):
- Announced at GTC March 16, 2026 - 12 days ago
- Early alpha, "not production-ready" per NVIDIA
- Runs Nemotron 3 Nano 4B locally (fits P3 Ultra 16GB VRAM)
- Nemotron 3 Super 120B needs cloud/DGX (too large for P3 Ultra)
- OpenShell security sandbox - policy-based agent governance
- Hardware-agnostic claim but CUDA-optimized in practice
- OpenClaw has 188K GitHub stars, fastest-growing open source project
- CVE-2026-25253 WebSocket vulnerability (critical) - NemoClaw addresses this
- Installation: `nemoclaw init --model local:nemotron-3-nano-4b --policy strict`

**Write checkpoint after Step 1.**

---

## Step 2: Overhaul README Pipeline Section

### 2a. Read Current README

```bash
cd ~/dev/projects/tripledb
cat README.md
```

### 2b. Replace Pipeline Section

Replace the existing "Pipeline Architecture" section with:

1. **Layered Pipeline Table** (from design doc Section 5)
   - Use backtick-formatted stage names (Ruflo style)
   - Include Input, Output, and Runtime columns
   - Runtime column calls out tmux for batch/UAT stages

2. **Data Flow Diagram** (refined ASCII from design doc Section 5)
   - Add tmux annotations to acquisition and transcription steps
   - Use `|` and `v` instead of unicode arrows

3. **Execution Model table** (from design doc Section 5)
   - Group A (interactive), Group B (tmux batch), UAT (tmux auto-chain), Post-flight (Puppeteer)

### 2c. Example of Final Pipeline Section

```markdown
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

[Data flow diagram from design doc]
```

**Write checkpoint after Step 2.**

---

## Step 3: Add tmux Visibility Across README

### 3a. Tech Stack Table

Add tmux row:

```markdown
| tmux + bash | Batch Execution | Production pipeline runs, UAT auto-chain |
```

### 3b. Architecture/Layers Table

If a layered architecture table exists, ensure the orchestration layer mentions tmux:

```markdown
| Orchestration | Claude Code (Dev) / Gemini CLI (UAT) | IAO methodology, tmux for batch and UAT |
```

### 3c. IAO Methodology Section

Add a sentence about tmux:

> Bulk pipeline processing and UAT auto-chain execution run in tmux sessions for crash resilience and unattended operation. The Phase 5 production run (805 videos, 14 hours) and all Phase 10 UAT execution are tmux-driven.

### 3d. Verify tmux Mentions

```bash
grep -c 'tmux' README.md
# Should be >= 4 mentions after update (tech stack, architecture, IAO, pipeline table)
```

**Write checkpoint after Step 3.**

---

## Step 4: Add Radar Summary + Track C Preview to README

### 4a. Radar Summary

Add a brief "Technology Radar" section to the README with the summary table:

```markdown
## Technology Radar

Evaluated 13 tools across 5 axes (architecture fit, cost, token efficiency, integration, TachTech breadth). Full analysis in `docs/ddd-radar-v10.45.md`.

| Tool | Rating | Action |
|------|--------|--------|
| Claude Skills | Adopt | Package IAO pillars as skills |
| Gemini 2.5 Flash | Adopt | Continue, no changes |
| Puppeteer | Adopt | Primary browser testing |
| Lighthouse CLI | Adopt | Hardening audits |
| Claude Sonnet 4.6 | Adopt | Route simple API tasks |
| Ruflo | Trial | POC for SOC Alpha |
| NemoClaw | Trial | Benchmark on P3 Ultra |
| Local LLMs (Ollama) | Trial | Benchmark on P3 Ultra |
| Playwright MCP | Hold | Dropped - Puppeteer covers all needs |
```

### 4b. Phase 10 Track C Preview

Add a brief note below the phase status table:

> **Phase 10 Track C (next):** UAT handoff produces 4 artifacts - a UAT design + plan pair for Gemini CLI to replay the TripleDB pipeline from scratch, and an IAO Project Template design + plan pair for Claude Code to bootstrap any new TachTech project using the Nine Pillars methodology.

Keep it brief. The full architecture lives in the design doc.

### 4c. Retrospective Highlights

If the README has an IAO methodology section, add a one-liner referencing the retrospective:

> 43 iterations produced 19 cataloged failure modes, a 14-item plan quality checklist, and 10 lessons learned. See `docs/archive/ddd-retrospective-v10.44.md`.

**Write checkpoint after Step 4.**

---

## Step 5: Update Phase Status + CLAUDE.md

### 5a. Phase Table

Update the README phase table:
- Phase 9: Complete (v9.35-v9.43)
- Phase 10: Active - Track A (Retrospective) complete, Track B (Radar) complete

### 5b. CLAUDE.md

Update to v10.45 template. Key changes from v10.44:
- Playwright MCP removed (Hold rating)
- Context7 MCP: "use sparingly - try without it first"

**Write checkpoint after Step 5.**

---

## Step 6: Post-Flight + Artifacts

### Tier 1 - Standard Health

| Gate | Check | Expected |
|------|-------|----------|
| 1 | Changelog count | >= 30 |
| 2 | First entry preserved | v0.7 present |
| 3 | Last entry present | v10.45 present |
| 4 | `docs/ddd-changelog-v10.45.md` exists | Yes |
| 5 | `docs/ddd-radar-v10.45.md` exists | Yes |
| 6 | No em-dashes in new artifacts | Verified |
| 7 | tmux mentions in README >= 4 | Verified |

### Tier 2 - EXEMPT (no Flutter code changes)

### Changelog Entry to APPEND

```markdown
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
```

### Artifacts to Generate

| Artifact | File |
|----------|------|
| Technology Radar | `docs/ddd-radar-v10.45.md` |
| Build log | `docs/ddd-build-v10.45.md` |
| Report | `docs/ddd-report-v10.45.md` |
| Versioned changelog | `docs/ddd-changelog-v10.45.md` |

Delete checkpoint.

---

## Success Criteria

```
[ ] Pre-flight passes
[ ] v10.44 artifacts archived (including retrospective)
[ ] TECHNOLOGY RADAR:
    [ ] docs/ddd-radar-v10.45.md produced
    [ ] 13 tools scored with 5-axis methodology
    [ ] Evidence from retrospective data cited
    [ ] Cost analysis included
    [ ] Concrete actions defined (not vague)
    [ ] Summary table with ratings
[ ] README OVERHAUL:
    [ ] Pipeline section has layered table (Ruflo-style)
    [ ] Pipeline section has refined data flow diagram
    [ ] Execution model table present (Group A/B/UAT)
    [ ] tmux in tech stack table
    [ ] tmux in architecture/layers section
    [ ] tmux in IAO methodology blurb
    [ ] tmux mentions >= 4 in README
    [ ] Radar summary table in README
    [ ] Track C preview in README (4-artifact deliverable)
    [ ] Retrospective highlights in README
    [ ] Phase 10 status updated
[ ] RETROSPECTIVE INTEGRATION:
    [ ] Plan quality checklist referenced in CLAUDE.md template
    [ ] Retrospective highlights in README IAO section
[ ] CLAUDE.md updated (Playwright removed, plan quality checklist added)
[ ] README changelog >= 30 entries
[ ] docs/ddd-changelog-v10.45.md generated
[ ] NO em-dashes in any produced artifact
[ ] Orchestration report in ddd-report
[ ] Interventions: 0
```

---

## Launch Sequence

```bash
cd ~/dev/projects/tripledb

# Archive v10.44
mv docs/ddd-design-v10.44.md docs/archive/ 2>/dev/null
mv docs/ddd-plan-v10.44.md docs/archive/ 2>/dev/null
mv docs/ddd-report-v10.44.md docs/archive/ 2>/dev/null
mv docs/ddd-build-v10.44.md docs/archive/ 2>/dev/null
mv docs/ddd-changelog-v10.44.md docs/archive/ 2>/dev/null
mv docs/ddd-retrospective-v10.44.md docs/archive/ 2>/dev/null

# Place new docs
cp /path/to/ddd-design-v10.45.md docs/
cp /path/to/ddd-plan-v10.45.md docs/

# Update CLAUDE.md (use editor)
# Content: see design doc CLAUDE.md Template (v10.45)

# Commit
git add .
git commit -m "KT starting 10.45 - technology radar + README overhaul"

# Launch YOLO
claude --dangerously-skip-permissions
```

Then: `Read CLAUDE.md and execute.`

After completion:
```bash
cd ~/dev/projects/tripledb

# Review the radar
cat docs/ddd-radar-v10.45.md

# Verify README pipeline table looks right
head -100 README.md

# Verify tmux visibility
grep -c 'tmux' README.md

git add .
git commit -m "KT completed 10.45 - radar scored, README overhauled, tmux visible"
git push
```

---

## Reminder: Formatting Rules

- NO em-dashes anywhere. Use " - " (space-hyphen-space).
- Use "->" for arrows.
- README changelog: APPEND only, >= 30 after update.
- Copy changelog to docs/ddd-changelog-v10.45.md.
