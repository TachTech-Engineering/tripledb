# TripleDB — Phase 9 Plan v9.41

**Phase:** 9 — App Optimization (Methodology Update)
**Iteration:** 41 (global)
**Executor:** Claude Code (YOLO mode — `claude --dangerously-skip-permissions`)
**Date:** March 2026
**Goal:** Update all methodology artifacts to Nine Pillars, update agent restrictions (CAN deploy, CANNOT git), overhaul README with Ruflo-style formatting, update CLAUDE.md template. No Flutter code changes.

---

## Read Order

```
1. docs/ddd-design-v9.41.md — Full living ADR with Nine Pillars, updated agent permissions
2. docs/ddd-plan-v9.41.md — This file. Execution steps.
```

---

## Autonomy Rules

```
1. AUTO-PROCEED. NEVER ask permission. YOLO — code dangerously.
2. SELF-HEAL: max 3 attempts per error. Checkpoint for crash recovery.
3. Git READ only. NEVER git add/commit/push.
4. flutter build web and firebase deploy ARE ALLOWED.
5. FULL PROJECT ACCESS under ~/dev/projects/tripledb/.
6. MANDATORY: ddd-build + ddd-report (with orchestration report) + README.
7. CHECKPOINT after every numbered step.
8. POST-FLIGHT: Tier 1 only (no Flutter code changes = Tier 2 exempt).
9. CHANGELOG: APPEND only, ≥ 26 entries after update.
10. Orchestration Report REQUIRED in ddd-report.
```

---

## What This Iteration Changes

| Item | Change |
|------|--------|
| Design doc | Eight Pillars → Nine Pillars. Agent permissions updated. README formatting guide added. |
| CLAUDE.md | Updated template with CAN/CANNOT permissions table |
| README.md | Full overhaul with Ruflo-style badges, flow diagram, architecture table, updated stats |
| `docs/` | v9.40 artifacts archived, v9.41 artifacts placed |

## What This Iteration Does NOT Change

| Item | Why |
|------|-----|
| Any Flutter code | No app changes — methodology only |
| Any pipeline code | No pipeline changes |
| pubspec.yaml | No dependency changes |
| firestore.rules | Already deployed in v9.40 |
| firebase.json | Already correct from v9.40 |

---

## Step 0: Pre-Flight

```bash
cd ~/dev/projects/tripledb

# Verify docs are in place
ls docs/ddd-design-v9.41.md
ls docs/ddd-plan-v9.41.md

# Verify v9.40 artifacts exist (to archive)
ls docs/ddd-design-v9.40.md
ls docs/ddd-plan-v9.40.md
ls docs/ddd-report-v9.40.md
ls docs/ddd-build-v9.40.md

# Baseline: app still builds
cd app
flutter analyze
# Expected: 0 issues (confirmed in v9.40)

flutter build web
# Expected: success

cd ..

# Count current changelog entries
grep -c '^\*\*v' README.md
# Expected: 25 (from v9.40)

# Initialize checkpoint
mkdir -p pipeline/data/checkpoints
```

**Write checkpoint after Step 0.**

---

## Step 1: Archive v9.40 Artifacts

```bash
cd ~/dev/projects/tripledb

# Create archive dir if missing
mkdir -p docs/archive

# Move v9.40 docs to archive
mv docs/ddd-design-v9.40.md docs/archive/
mv docs/ddd-plan-v9.40.md docs/archive/
mv docs/ddd-report-v9.40.md docs/archive/
mv docs/ddd-build-v9.40.md docs/archive/
```

**Verify:** `ls docs/` should show only v9.41 design + plan (no v9.40 files).

**Write checkpoint after Step 1.**

---

## Step 2: Update CLAUDE.md

Replace the contents of `~/dev/projects/tripledb/CLAUDE.md` with:

```markdown
# TripleDB — Agent Instructions

## Current Iteration: 9.41

Methodology update. Nine Pillars. No Flutter code changes.

Read in order, then execute:
1. docs/ddd-design-v9.41.md
2. docs/ddd-plan-v9.41.md

## MCP Servers
- Playwright MCP: Post-flight functional testing
- Context7: Flutter/Dart API docs

## Rules
- YOLO — code dangerously, never ask permission
- Self-heal: max 3 attempts, checkpoint for crash recovery
- MUST produce ddd-build + ddd-report (with orchestration report)
- POST-FLIGHT: Tier 1 only (no Flutter code changes this iteration)
- README changelog: NEVER truncate, ALWAYS append, ≥ 26 after update

## Agent Permissions
- ✅ CAN: flutter build web, firebase deploy --only hosting, firebase deploy --only firestore:rules
- ❌ CANNOT: git add, git commit, git push (Kyle commits at phase boundaries)
```

**Write checkpoint after Step 2.**

---

## Step 3: Overhaul README.md

This is the primary deliverable of v9.41. The README must be completely rewritten to reflect the project's actual state (41 iterations, production app, 1,102 restaurants) while adopting polished formatting.

### README Structure (top to bottom)

**Section 1: Title + Badges**

```markdown
# 🍔 TripleDB

**Every restaurant from Diners, Drive-Ins and Dives — structured, searchable, and mapped.**

🌐 [tripledb.net](https://tripledb.net) · 📺 805 Episodes · 🍔 1,102 Restaurants · 🍽️ 2,286 Dishes · 📍 1,006 Mapped · 💰 $0 Cost
```

**Section 2: What TripleDB Is (2-3 sentences)**

Keep the existing description but update for current state. Mention it's live at tripledb.net.

**Section 3: Pipeline Architecture (ASCII flow diagram)**

Use the flow diagram from design doc Section 5. This replaces the old "Architecture" section.

**Section 4: Architecture Table (layered)**

```markdown
| Layer | Technology | Purpose |
|-------|-----------|---------|
| 🎙️ Acquisition | yt-dlp + faster-whisper (CUDA) | YouTube → timestamped transcripts |
| 🧠 Extraction | Gemini 2.5 Flash API (free tier) | Transcripts → structured restaurant JSON |
| 📍 Enrichment | Google Places API + Nominatim | Ratings, coords, open/closed status |
| 🗄️ Storage | Cloud Firestore (Spark) | Denormalized restaurant documents |
| 📱 Frontend | Flutter Web + Firebase Hosting | Mobile-first responsive app |
| 🔒 Security | Firestore rules + cookie consent | Read-only public, GDPR/CCPA compliant |
| 🤖 Orchestration | Claude Code / Gemini CLI | IAO methodology (Nine Pillars) |
```

**Section 5: Features**

What you can do on tripledb.net:
- Search by anything (dish, cuisine, city, chef, ingredients)
- Find a diner nearby (location-aware, consent-gated)
- Watch the exact YouTube timestamp where Guy walks in
- See Google-verified ratings and open/closed status
- Discover 70+ trivia facts about the show
- Browse restaurants that changed names (AKA badges)

**Section 6: Project Status (phase table)**

Update with ALL phases through Phase 9 complete. Phase 10 as next.

**Section 7: Data at a Glance**

Quick stats table: videos, restaurants, dishes, geocoded, enriched, closed, name changes, cost.

**Section 8: Tech Stack**

Condensed version of the locked decisions table.

**Section 9: IAO Methodology**

Brief (5-line) description of IAO with link concept: "See `docs/ddd-design-v9.41.md` for the full Nine Pillars framework."

**Section 10: Hardware**

Both machines (NZXT primary + ThinkStation secondary).

**Section 11: Cost**

The zero-cost table.

**Section 12: Repo Structure**

Updated tree.

**Section 13: Changelog**

CRITICAL INSTRUCTIONS FOR THE AGENT:
- The existing changelog has 25 entries (v0.7 through v9.40)
- APPEND v9.41 entry at the bottom
- The final changelog MUST have ≥ 26 entries
- VERIFY: first entry is v0.7 or v1.10 (whichever is first)
- VERIFY: last entry is v9.41
- NEVER remove, rewrite, or summarize existing entries
- If the README is being rewritten, PRESERVE the full changelog text verbatim

### Changelog Entry to APPEND:

```markdown
**v9.41 (Phase 9 — Nine Pillars + README Overhaul)**
- **Nine Pillars of IAO:** Methodology evolved from Eight to Nine Pillars. New Pillar 8
  (Mobile-First Flutter + Firebase, Zero-Cost by Design) elevated from tech stack choice
  to architectural principle. Continuous Improvement renumbered to Pillar 9.
- **Agent permissions updated:** Agents CAN now run flutter build web and firebase deploy.
  Agents CANNOT git add/commit/push. Kyle commits at phase boundaries.
- **README overhaul:** Full rewrite with feature badges, ASCII pipeline diagram, layered
  architecture table, and updated project stats reflecting 41 iterations of development.
- **CLAUDE.md template v2:** Updated with CAN/CANNOT permissions table.
```

**Section 14: Footer**

```markdown
---

*Built with [IAO](docs/ddd-design-v9.41.md) — Iterative Agentic Orchestration*
*Phase 9.41 — Methodology Update*
```

### README Verification Checklist

```bash
# After writing README:
grep -c '^\*\*v' README.md          # ≥ 26
grep 'v0.7\|v1.10' README.md | head -1  # First entry exists
grep 'v9.41' README.md | head -1    # Last entry exists
wc -l README.md                      # Sanity check (should be 200-400 lines)
```

**Write checkpoint after Step 3.**

---

## Step 4: Build + Deploy

Even though no Flutter code changed, rebuild to confirm nothing broke:

```bash
cd ~/dev/projects/tripledb/app
flutter analyze
# Expected: 0 issues

flutter build web
# Expected: success

firebase deploy --only hosting
# Deploy the updated app (README changes don't affect the app, but this
# ensures hosting is current)
```

**Write checkpoint after Step 4.**

---

## Step 5: Post-Flight

### Tier 1 — Standard Health (REQUIRED)

| Gate | Check | Expected |
|------|-------|----------|
| Gate 1 | `flutter analyze` | 0 issues |
| Gate 2 | `flutter build web` | Success |
| Gate 3 | Changelog count | ≥ 26 entries |
| Gate 4 | First changelog entry preserved | v0.7 or v1.10 present |
| Gate 5 | Last changelog entry present | v9.41 present |

### Tier 2 — EXEMPT

No Flutter code changes in this iteration. Tier 2 playbook is not required.

### Additional Verification

```bash
cd ~/dev/projects/tripledb

# CLAUDE.md updated
grep "9.41" CLAUDE.md
grep "CANNOT.*git" CLAUDE.md

# Design doc in place
ls docs/ddd-design-v9.41.md

# v9.40 archived
ls docs/archive/ddd-design-v9.40.md

# README has badges
grep "tripledb.net" README.md
grep "1,102" README.md
grep "Nine Pillars" README.md
```

**Write checkpoint after Step 5.**

---

## Step 6: Generate Artifacts + Cleanup

### docs/ddd-build-v9.41.md (MANDATORY — FULL TRANSCRIPT)

Must include:
- Pre-flight output (flutter analyze, build, changelog count)
- Archive step confirmation
- CLAUDE.md content (full)
- README.md content (full — the entire rewritten README)
- Build + deploy output
- Tier 1 gate results
- Additional verification results

### docs/ddd-report-v9.41.md (MANDATORY)

Must include:
1. **Changes summary:** What was updated and why
2. **Nine Pillars:** Confirmation of pillar evolution (8 → 9)
3. **Agent permissions:** Old vs new restrictions
4. **README overhaul:** Key formatting changes adopted
5. **Post-flight:** Tier 1 results
6. **Changelog:** Entry count + integrity check
7. **Orchestration Report:** Tools used, workload %, efficacy
8. **Interventions:** Target 0
9. **Claude's Recommendation:** Next steps (Phase 10 or more dev?)

Delete checkpoint.

---

## Success Criteria

```
[ ] Pre-flight passes (flutter analyze 0 issues, build success)
[ ] v9.40 artifacts archived to docs/archive/
[ ] CLAUDE.md updated with v9.41 + CAN/CANNOT permissions
[ ] README.md overhauled:
    [ ] Feature badges at top
    [ ] ASCII pipeline flow diagram
    [ ] Layered architecture table
    [ ] Updated stats (1,102 restaurants, 582 enriched, etc.)
    [ ] Phase status table current through Phase 9
    [ ] IAO methodology section
    [ ] Hardware section (both machines)
    [ ] Changelog ≥ 26 entries
    [ ] First entry (v0.7 or v1.10) preserved
    [ ] Last entry (v9.41) present
    [ ] Footer with IAO link
[ ] flutter build web: success (rebuild confirmation)
[ ] firebase deploy --only hosting: success
[ ] TIER 1: All gates pass
[ ] Orchestration report in ddd-report
[ ] Artifacts generated (build + report)
[ ] Interventions: 0
```

---

## Launch Sequence

```bash
cd ~/dev/projects/tripledb

# Archive v9.40
mv docs/ddd-design-v9.40.md docs/archive/ 2>/dev/null
mv docs/ddd-plan-v9.40.md docs/archive/ 2>/dev/null
mv docs/ddd-report-v9.40.md docs/archive/ 2>/dev/null
mv docs/ddd-build-v9.40.md docs/archive/ 2>/dev/null

# Place new docs
cp /path/to/ddd-design-v9.41.md docs/
cp /path/to/ddd-plan-v9.41.md docs/

# Update CLAUDE.md
cat > CLAUDE.md << 'EOF'
# TripleDB — Agent Instructions

## Current Iteration: 9.41

Methodology update. Nine Pillars. No Flutter code changes.

Read in order, then execute:
1. docs/ddd-design-v9.41.md
2. docs/ddd-plan-v9.41.md

## MCP Servers
- Playwright MCP: Post-flight functional testing
- Context7: Flutter/Dart API docs

## Rules
- YOLO — code dangerously, never ask permission
- Self-heal: max 3 attempts, checkpoint for crash recovery
- MUST produce ddd-build + ddd-report (with orchestration report)
- POST-FLIGHT: Tier 1 only (no Flutter code changes this iteration)
- README changelog: NEVER truncate, ALWAYS append, ≥ 26 after update

## Agent Permissions
- ✅ CAN: flutter build web, firebase deploy --only hosting, firebase deploy --only firestore:rules
- ❌ CANNOT: git add, git commit, git push (Kyle commits at phase boundaries)
EOF

# NOTE: fish shell — no heredocs. Write CLAUDE.md via editor or echo instead.
# The above is for reference. Use: nano CLAUDE.md or printf commands.

# Commit (Kyle does this manually)
git add .
git commit -m "KT starting 9.41 — Nine Pillars, methodology update, README overhaul"

# Launch YOLO
claude --dangerously-skip-permissions
```

Then: `Read CLAUDE.md and execute.`

After completion:
```bash
cd ~/dev/projects/tripledb
git add .
git commit -m "KT completed 9.41 — Nine Pillars established, README overhauled"
git push
```

---

## Reminder: README Changelog APPEND Rule

**CRITICAL — READ THIS BEFORE TOUCHING README.md:**

The README changelog currently has 25 entries. After this iteration it must have ≥ 26. The executing agent must:

1. Read the ENTIRE existing changelog section
2. PRESERVE every existing entry verbatim (do not summarize, rewrite, or remove)
3. APPEND the v9.41 entry at the bottom
4. Verify the count: `grep -c '^\*\*v' README.md` → ≥ 26

The full historical changelog text from v0.7 through v9.40 must survive the README rewrite intact. If the agent rewrites the README from scratch, it must copy-paste the changelog from the old README before overwriting.
