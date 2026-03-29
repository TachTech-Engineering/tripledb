# TripleDB - Phase 10 Plan v10.46

**Phase:** 10 - Retrospective + Technology Radar + UAT Handoff (CAPSTONE)
**Iteration:** 46 (global)
**Executor:** Claude Code (YOLO mode - `claude --dangerously-skip-permissions`)
**Date:** March 2026
**Goal:** Produce the 4 Track C deliverables (UAT design + plan, IAO template design + plan). Close Phase 10. No Flutter code changes.

---

## Read Order

```
1. docs/ddd-design-v10.46.md - Sections 4-7 are the specs for each deliverable artifact
2. docs/ddd-plan-v10.46.md - This file. Execution steps.
```

---

## Autonomy Rules

```
1. AUTO-PROCEED. NEVER ask permission. YOLO.
2. SELF-HEAL: max 3 attempts per error. Checkpoint for crash recovery.
3. Git READ only. NEVER git add/commit/push.
4. NO Flutter or pipeline code changes. Documentation only.
5. FULL PROJECT ACCESS under ~/dev/projects/tripledb/.
6. MANDATORY: 4 Track C artifacts + ddd-build + ddd-report + ddd-changelog + README.
7. CHECKPOINT after every numbered step.
8. POST-FLIGHT: Tier 1 only (no Flutter changes = Tier 2 exempt).
9. CHANGELOG: APPEND only, >= 31 entries after update. Copy to docs/ddd-changelog-v10.46.md.
10. FORMATTING: NEVER use em-dashes. Use " - " instead. Use "->" for arrows.
11. Orchestration Report REQUIRED in ddd-report.
```

---

## What This Iteration Produces

| # | Artifact | Filename | Pair |
|---|----------|----------|------|
| 1 | UAT Design | `docs/ddd-design-uat.md` | TripleDB UAT (Gemini) |
| 2 | UAT Plan | `docs/ddd-plan-uat-v0.1.md` | TripleDB UAT (Gemini) |
| 3 | IAO Template Design | `docs/iao-template-design-v0.1.md` | New Project (Claude) |
| 4 | IAO Template Plan | `docs/iao-template-plan-v0.1.md` | New Project (Claude) |
| 5 | Build Log | `docs/ddd-build-v10.46.md` | Standard |
| 6 | Report | `docs/ddd-report-v10.46.md` | Standard |
| 7 | Changelog | `docs/ddd-changelog-v10.46.md` | Standard |

---

## Step 0: Pre-Flight

```bash
cd ~/dev/projects/tripledb

# Verify docs
ls docs/ddd-design-v10.46.md
ls docs/ddd-plan-v10.46.md

# Archive v10.45
mkdir -p docs/archive
mv docs/ddd-design-v10.45.md docs/archive/ 2>/dev/null
mv docs/ddd-plan-v10.45.md docs/archive/ 2>/dev/null
mv docs/ddd-report-v10.45.md docs/archive/ 2>/dev/null
mv docs/ddd-build-v10.45.md docs/archive/ 2>/dev/null
mv docs/ddd-changelog-v10.45.md docs/archive/ 2>/dev/null
mv docs/ddd-radar-v10.45.md docs/archive/ 2>/dev/null

# Changelog count
grep -c '^\*\*v' README.md
# Expected: 30

# Initialize checkpoint
mkdir -p pipeline/data/checkpoints
```

**Write checkpoint after Step 0.**

---

## Step 1: Produce UAT Design Doc (ddd-design-uat.md)

Follow the spec in design doc Section 4. This is the comprehensive architecture document that Gemini CLI reads before executing.

### Data Sources

The agent should read and synthesize from:
- `docs/ddd-design-v10.46.md` (current design, UAT spec)
- `docs/archive/ddd-design-v9.43.md` (full pipeline, data model, app architecture, gotchas, env setup)
- `docs/archive/ddd-retrospective-v10.44.md` (failure modes, lessons, plan quality checklist)
- `docs/archive/ddd-radar-v10.45.md` (tool ratings, recommended stack)

### Key Content

1. Project overview - TripleDB + what UAT proves
2. Nine Pillars adapted for Gemini (Pillar 2: Gemini is executor, tmux is runtime)
3. Pipeline architecture (layered table from v10.45 README)
4. Data model (restaurant + video schemas from v9.43)
5. Environment setup (full fish config, pacman/npm/pip packages)
6. **Phase chain with entry/exit criteria** for all 10 phases:
   - Phases 0-5: full pipeline execution (transcription, extraction, normalization)
   - Phase 6: Firestore load -> **LOCAL JSONL ONLY, no Firestore writes**
   - Phase 7: Enrichment -> **LOCAL JSONL ONLY, no Firestore writes**
   - Phase 8: Flutter build + **preview channel deploy** (`firebase hosting:channel:deploy uat`)
   - Phase 9: Post-flight testing against preview URL
7. Auto-chain logic (report -> next plan -> execute -> repeat)
8. Success criteria (metric targets matching dev)
9. Em-dash sweep as Phase 0 first task
10. All 22 known gotchas
11. GEMINI.md content

### Firestore Write Prohibition

The UAT design doc must contain an explicit, impossible-to-miss rule:

```
## CRITICAL: NO FIRESTORE WRITES

Pipeline scripts MUST NOT call any Firebase Admin SDK write methods:
- No db.collection().add()
- No db.collection().set()
- No db.collection().update()
- No db.collection().delete()
- No batch.commit()

Pipeline scripts produce LOCAL JSONL files only. Validation is by diff
against dev pipeline output, not by writing to Firestore.

The Flutter app reads from production Firestore (which already has correct data).
```

### Size Target

The UAT design doc should be 400-600 lines. Comprehensive enough for zero-intervention execution, concise enough to fit in Gemini's context window.

**Write checkpoint after Step 1.**

---

## Step 2: Produce UAT Plan Doc (ddd-plan-uat-v0.1.md)

Follow the spec in design doc Section 5. This is Phase 0 - the plan that bootstraps UAT and auto-chains into Phase 1.

### Key Content

1. Pre-flight (env validation - every tool, every key, every path)
2. Em-dash sweep (grep + replace across all .md and .dart files)
3. Environment validation (flutter analyze, flutter build web, Puppeteer, firebase auth)
4. GEMINI.md creation
5. Phase 0 report generation
6. Auto-chain trigger to Phase 1

### Auto-Chain Spec

```
After completing Phase N:
1. Write docs/ddd-report-uat-vN.X.md
2. Write docs/ddd-changelog-uat-vN.X.md
3. Read the report
4. Generate docs/ddd-plan-uat-v{N+1}.{X+1}.md
5. Execute the new plan immediately
6. Repeat until Phase 9 complete or 3 consecutive identical failures trigger STOP
```

### tmux Instruction

The plan must specify that the entire session runs in tmux:
```bash
tmux new-session -s tripledb-uat
cd ~/dev/projects/tripledb
gemini
# "Read GEMINI.md and execute."
```

### Size Target

200-300 lines. Phase 0 is a setup phase - the plan should be tight.

**Write checkpoint after Step 2.**

---

## Step 3: Produce IAO Template Design Doc (iao-template-design-v0.1.md)

Follow the spec in design doc Section 6. This is the generic, project-agnostic IAO methodology document.

### Key Content

1. **What IAO Is** - methodology explanation (3 paragraphs, no TripleDB references)
2. **Nine Pillars** - full descriptions, project-agnostic
   - Pillar 8 is "Platform Constraints" not "Mobile-First Flutter"
   - All examples use placeholders like "{your-project}" not "TripleDB"
3. **Plan Quality Checklist** - 14 items from retrospective, verbatim
4. **Failure Mode Reference** - 19 modes condensed and generalized (not TripleDB-specific details)
5. **Top 10 Lessons** - universal principles, not TripleDB case studies
6. **CLAUDE.md Template** - generic with `{project}` placeholders
7. **GEMINI.md Template** - generic for UAT
8. **Artifact Naming Convention** - `{project}-{type}-v{P}.{I}.md`
9. **Markdown Formatting Rules** - em-dash prohibition, conventions
10. **Quick Start** - 5 commands (see design doc Section 7)

### Tone

Written for Kyle handing the file to Claude Code on day 1 of a new engagement. Concise, opinionated, actionable. Not a textbook.

### What to Omit

- No TripleDB content (no restaurants, no DDD, no Guy Fieri)
- No hardware specs (placeholder: "## Hardware Fleet\n\nDocument your machines here.")
- No pipeline stages (placeholder: "## Pipeline Architecture\n\nDocument your pipeline here.")
- No technology radar scores (placeholder: "## Technology Radar\n\nRun your own radar at project close.")

### Size Target

300-400 lines. Dense, no filler.

**Write checkpoint after Step 3.**

---

## Step 4: Produce IAO Template Plan Doc (iao-template-plan-v0.1.md)

Follow the spec in design doc Section 7. Phase 0 scaffold plan for any new project.

### Key Content

1. Quick Start (5 commands from design doc Section 7)
2. Phase 0 steps:
   - Define project mandate
   - Document environment
   - Define pipeline
   - Scaffold repository
   - Pre-flight validation
   - Phase 0 report
   - Phase 1 plan generation
3. Autonomy rules (standard IAO)
4. Success criteria (repo created, CLAUDE.md written, pre-flight passes)

### Tone

Copy-paste ready. Kyle replaces `{project-name}` and `{Project}` placeholders and launches.

### Size Target

150-200 lines. Phase 0 is lean.

**Write checkpoint after Step 4.**

---

## Step 5: Update CLAUDE.md

Update to v10.46 capstone template from the design doc.

**Write checkpoint after Step 5.**

---

## Step 6: Update README + Generate Standard Artifacts

### 6a. APPEND Changelog Entry

```markdown
**v10.46 (Phase 10 - Track C Capstone)**
- **UAT handoff artifacts:** Produced ddd-design-uat.md and ddd-plan-uat-v0.1.md for Gemini CLI
  to replay the full TripleDB pipeline from scratch. Same Firebase project, hosting preview
  channel, no Firestore writes. Pipeline validated by JSONL diff against dev output.
- **IAO Project Template:** Produced iao-template-design-v0.1.md and iao-template-plan-v0.1.md -
  generic Nine Pillars framework for any new TachTech project. Includes plan quality checklist
  (14 items), failure mode catalog (19 modes), top 10 lessons. Quick start: 5 commands to scaffold.
- **Phase 10 complete.** Three tracks delivered across 3 iterations: Retrospective (v10.44),
  Technology Radar (v10.45), UAT Handoff + IAO Template (v10.46).
```

### 6b. Update Phase Table

Phase 10: Complete (v10.44-v10.46). Tracks A, B, C all done.

### 6c. Verify

```bash
grep -c '^\*\*v' README.md          # >= 31
grep '^\*\*v0\.7' README.md | head -1
grep '^\*\*v10\.46' README.md | head -1
```

### 6d. Generate Versioned Changelog

Copy changelog to `docs/ddd-changelog-v10.46.md`.

### 6e. Generate Build + Report

Standard artifacts per Pillar 1. The report should include:
- Confirmation all 4 Track C artifacts produced
- Line counts for each artifact
- Phase 10 completion summary (3 tracks, 3 iterations)
- Recommendation for what comes next (UAT execution, or more dev features)
- Final orchestration report

Delete checkpoint.

---

## Post-Flight: Tier 1

| Gate | Check | Expected |
|------|-------|----------|
| 1 | Changelog count >= 31 | PASS |
| 2 | First entry (v0.7) preserved | PASS |
| 3 | Last entry (v10.46) present | PASS |
| 4 | `docs/ddd-changelog-v10.46.md` exists | PASS |
| 5 | `docs/ddd-design-uat.md` exists | PASS |
| 6 | `docs/ddd-plan-uat-v0.1.md` exists | PASS |
| 7 | `docs/iao-template-design-v0.1.md` exists | PASS |
| 8 | `docs/iao-template-plan-v0.1.md` exists | PASS |
| 9 | No em-dashes in any new artifact | PASS |
| 10 | Phase 10 marked complete in README | PASS |

Tier 2: EXEMPT (no Flutter code changes).

---

## Success Criteria

```
[ ] Pre-flight passes
[ ] v10.45 artifacts archived
[ ] UAT DESIGN (ddd-design-uat.md):
    [ ] Nine Pillars adapted for Gemini
    [ ] Pipeline architecture with phase chain
    [ ] Firestore write prohibition (explicit, bold, unmissable)
    [ ] Environment setup (complete, copy-pasteable)
    [ ] Auto-chain logic documented
    [ ] Em-dash sweep in Phase 0
    [ ] GEMINI.md content
    [ ] 400-600 lines
[ ] UAT PLAN (ddd-plan-uat-v0.1.md):
    [ ] Phase 0 steps (env validation, em-dash sweep, GEMINI.md)
    [ ] Auto-chain trigger to Phase 1
    [ ] tmux session instruction
    [ ] 200-300 lines
[ ] IAO TEMPLATE DESIGN (iao-template-design-v0.1.md):
    [ ] Nine Pillars (project-agnostic, Pillar 8 = Platform Constraints)
    [ ] Plan Quality Checklist (14 items)
    [ ] Failure Mode Reference (19 modes, condensed)
    [ ] Top 10 Lessons (universal)
    [ ] CLAUDE.md + GEMINI.md templates (generic)
    [ ] Quick Start (5 commands)
    [ ] No TripleDB-specific content
    [ ] 300-400 lines
[ ] IAO TEMPLATE PLAN (iao-template-plan-v0.1.md):
    [ ] Quick Start commands
    [ ] Phase 0 scaffold steps
    [ ] Copy-paste ready with {project-name} placeholders
    [ ] 150-200 lines
[ ] CLAUDE.md updated to v10.46 capstone
[ ] README:
    [ ] Changelog >= 31 entries
    [ ] Phase 10 marked complete
[ ] docs/ddd-changelog-v10.46.md generated
[ ] Standard artifacts (build + report) produced
[ ] NO em-dashes in any artifact
[ ] Interventions: 0
```

---

## Launch Sequence

```bash
cd ~/dev/projects/tripledb

# Archive v10.45
mv docs/ddd-design-v10.45.md docs/archive/ 2>/dev/null
mv docs/ddd-plan-v10.45.md docs/archive/ 2>/dev/null
mv docs/ddd-report-v10.45.md docs/archive/ 2>/dev/null
mv docs/ddd-build-v10.45.md docs/archive/ 2>/dev/null
mv docs/ddd-changelog-v10.45.md docs/archive/ 2>/dev/null
mv docs/ddd-radar-v10.45.md docs/archive/ 2>/dev/null

# Place new docs
cp /path/to/ddd-design-v10.46.md docs/
cp /path/to/ddd-plan-v10.46.md docs/

# Update CLAUDE.md (use editor)
# Content: see design doc CLAUDE.md Template (v10.46)

# Commit
git add .
git commit -m "KT starting 10.46 - Phase 10 capstone, 4 Track C deliverables"

# Launch YOLO
claude --dangerously-skip-permissions
```

Then: `Read CLAUDE.md and execute.`

After completion:
```bash
cd ~/dev/projects/tripledb

# Review the 4 deliverables
wc -l docs/ddd-design-uat.md docs/ddd-plan-uat-v0.1.md docs/iao-template-design-v0.1.md docs/iao-template-plan-v0.1.md

# Quick sanity check
grep -c 'em-dash\|NEVER.*write\|JSONL.*only' docs/ddd-design-uat.md
grep -c '{project}' docs/iao-template-design-v0.1.md

git add .
git commit -m "KT completed 10.46 - Phase 10 complete. UAT + IAO template delivered."
git push
```

---

## What Happens After Phase 10

| Path | Description |
|------|------------|
| **UAT execution** | Kyle launches Gemini CLI in tmux with `GEMINI.md` -> full pipeline replay, preview channel deploy, JSONL diff validation. This is a separate session, not an IAO iteration. |
| **Dev continues** | New features, data quality improvements, re-enrichment. Dev is permanent. |
| **New project** | Kyle copies `iao-template-design-v0.1.md` + `iao-template-plan-v0.1.md`, replaces placeholders, launches Claude Code. SOC Alpha, Findlay, HelloHippo, whatever's next. |

Phase 10 is the end of the TripleDB IAO journey. Everything after is either UAT validation or a new beginning.

---

## Reminder: Formatting Rules

- NO em-dashes anywhere. Use " - " (space-hyphen-space).
- Use "->" for arrows.
- README changelog: APPEND only, >= 31 after update.
- Copy changelog to docs/ddd-changelog-v10.46.md.
