# IAO Project Template - Plan v0.1 (Phase 0)

**Phase:** 0 - Project Scaffold & Environment Validation
**Executor:** Claude Code (YOLO mode)
**Goal:** Scaffold a new IAO project from scratch. Validate environment. Produce Phase 0 report. Plan Phase 1.

---

## Quick Start

```bash
# 1. Create project directory
mkdir -p ~/dev/projects/{project-name} && cd ~/dev/projects/{project-name}

# 2. Initialize repo + scaffold
git init && mkdir -p docs/archive pipeline/scripts pipeline/config pipeline/data app

# 3. Copy IAO template files
cp /path/to/iao-template-design-v0.1.md docs/{project}-design-v0.1.md
cp /path/to/iao-template-plan-v0.1.md docs/{project}-plan-v0.1.md

# 4. Create CLAUDE.md version lock
printf "# {Project} - Agent Instructions\n\nRead docs/{project}-design-v0.1.md then docs/{project}-plan-v0.1.md" > CLAUDE.md

# 5. Launch
claude --dangerously-skip-permissions
```

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

## Step 0: Define Project Mandate

Answer these three questions in the design doc:

1. **What does this project build?**
   - One paragraph. What is the output? Who uses it?

2. **What is the cost constraint?**
   - $0 free-tier? Budget cap? Enterprise license OK?

3. **What is the platform constraint (Pillar 8)?**
   - Framework, hosting, database, deployment target.
   - This shapes every tool choice for the rest of the project.

Write answers into `docs/{project}-design-v0.1.md` Section 1.

---

## Step 1: Document Environment

Fill in the design doc hardware and environment sections:

### 1a. Hardware Fleet

| Machine | CPU | GPU | VRAM | RAM | OS | Shell | Role |
|---------|-----|-----|------|-----|----|-------|------|
| {machine-1} | ... | ... | ... | ... | ... | ... | Primary |
| {machine-2} | ... | ... | ... | ... | ... | ... | Secondary |

### 1b. Required Packages

```bash
# System packages
sudo pacman -S {packages} --needed  # or apt, brew, etc.

# npm packages
sudo npm install -g {packages}  # or local installs

# pip packages
pip install {packages}

# Framework-specific
{framework install commands}
```

### 1c. API Keys

```bash
# List every key needed, with the exact env var name
set -gx {KEY_NAME_1} "your-key-here"
set -gx {KEY_NAME_2} "your-key-here"
```

### 1d. Shell Configuration

Document the full shell config file needed for this project.

---

## Step 2: Define Pipeline

Fill in the design doc pipeline section:

### 2a. Pipeline Stages

| Stage | Tool | Input | Output | Runtime |
|-------|------|-------|--------|---------|
| {stage-1} | {tool} | {input} | {output} | {local/API/cloud} |
| {stage-2} | {tool} | {input} | {output} | {local/API/cloud} |
| ... | ... | ... | ... | ... |

### 2b. Progressive Batching Plan (Pillar 6)

| Phase | Batch Size | Purpose |
|-------|-----------|---------|
| 1 | {10%} | Discovery - validate pipeline works |
| 2 | {25%} | Calibration - tune parameters |
| 3 | {50%} | Stress test - zero-intervention target |
| 4 | {75%} | Validation - lock prompts/configs |
| 5 | {100%} | Production run |

---

## Step 3: Scaffold Repository

```bash
cd ~/dev/projects/{project-name}

# Create .gitignore
cat > .gitignore << 'GITIGNORE'
# Data
pipeline/data/
app/build/

# Environment
.env
*.key
*.pem

# IDE
.idea/
.vscode/
*.iml

# OS
.DS_Store
Thumbs.db
GITIGNORE

# Create README with changelog section
cat > README.md << 'README'
# {Project}

{One-line description}

---

## Changelog

README

# Create CLAUDE.md
cat > CLAUDE.md << 'CLAUDE'
# {Project} - Agent Instructions

## Current Iteration: 0.1

Read in order, then execute:
1. docs/{project}-design-v0.1.md
2. docs/{project}-plan-v0.1.md

## Rules
- YOLO - code dangerously, never ask permission
- MUST produce {project}-build + {project}-report + {project}-changelog
- README changelog: NEVER truncate, ALWAYS append
CLAUDE

echo "Repository scaffolded."
```

---

## Step 4: Pre-Flight Validation

Run the standard pre-flight checklist:

```
[ ] Git repo initialized
[ ] Directory structure created (docs/, docs/archive/, pipeline/, app/)
[ ] CLAUDE.md exists at repo root
[ ] Design doc exists in docs/
[ ] Plan doc exists in docs/
[ ] .gitignore exists
[ ] README.md exists with changelog section
[ ] All API keys set and validated
[ ] All tools installed and accessible
[ ] Build tools verified (analyze, build, test as applicable)
[ ] Shell configuration complete
```

Run each validation command from Step 1. All must pass.

---

## Step 5: Produce Phase 0 Report

Write `docs/{project}-report-v0.1.md`:

```markdown
# {Project} - Report v0.1 (Phase 0)

## Project Mandate
- {what it builds}
- Cost constraint: {$0 / budget}
- Platform constraint: {framework + hosting}

## Environment Validation
| Check | Result |
|-------|--------|
| {tool-1} | PASS/FAIL |
| {tool-2} | PASS/FAIL |
| ... | ... |

## Repository State
- docs/ scaffolded
- CLAUDE.md version lock created
- .gitignore configured

## Recommendation
Environment ready for Phase 1. Recommended first batch: {size} {units}.

## Orchestration Report
| Component | Workload | Efficacy |
|-----------|----------|----------|
| Claude Code | 100% | High |
```

Also produce:
- `docs/{project}-build-v0.1.md` (session transcript)
- `docs/{project}-changelog-v0.1.md` (changelog snapshot)
- Append changelog entry to README.md

---

## Step 6: Plan Phase 1

Based on the Phase 0 report:

1. Read the report
2. Define Phase 1 scope (start small - Pillar 6)
3. Write `docs/{project}-plan-v1.2.md` with:
   - Specific tasks for the first batch
   - Success criteria (binary, automatable)
   - Post-flight tests
   - Checkpoint strategy
4. Validate plan against the 14-item checklist (design doc Section 3)

---

## Success Criteria (Phase 0)

```
[ ] Project mandate defined (what, cost, platform)
[ ] Environment documented (hardware, packages, keys, shell)
[ ] Pipeline stages defined with tools
[ ] Progressive batching plan established
[ ] Repository scaffolded (all dirs, files, configs)
[ ] Pre-flight validation passes
[ ] Phase 0 report produced
[ ] Phase 1 plan produced
[ ] Changelog entry appended to README
[ ] Zero interventions
```

---

## Reminder: Formatting Rules

- NO em-dashes. Use " - " (space-hyphen-space).
- Use "->" for arrows.
- Changelog: APPEND only.
