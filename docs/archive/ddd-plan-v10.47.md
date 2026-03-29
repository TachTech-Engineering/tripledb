# TripleDB - Phase 10 Plan v10.47

**Phase:** 10 - Template Revision
**Iteration:** 47 (global)
**Executor:** Claude Code (YOLO mode - `claude --dangerously-skip-permissions`)
**Date:** March 2026
**Goal:** Revise IAO template and UAT design with compatibility matrix (OpenClaw, NemoClaw, Nemotron, Playwright MCP as options), requirements manifest approach (export/install scripts), and fresh-machine walkthrough.

---

## Read Order

```
1. docs/ddd-design-v10.47.md - Compatibility matrix (Section 2), requirements manifest (Section 3), revised specs (Sections 4-5)
2. docs/ddd-plan-v10.47.md - This file. Execution steps.
```

---

## Autonomy Rules

```
1. AUTO-PROCEED. NEVER ask permission. YOLO.
2. SELF-HEAL: max 3 attempts per error.
3. Git READ only. NEVER git add/commit/push.
4. NO Flutter or pipeline code changes. Template/doc revisions only.
5. MANDATORY: revised templates + ddd-build + ddd-report + ddd-changelog + README.
6. FORMATTING: No em-dashes. Use " - " instead. Use "->" for arrows.
7. CHANGELOG: APPEND only, >= 32. Copy to docs/ddd-changelog-v10.47.md.
```

---

## What This Iteration Produces

| # | Artifact | Filename | Action |
|---|----------|----------|--------|
| 1 | IAO Template Design (revised) | `docs/iao-template-design-v0.1.md` | OVERWRITE with compatibility matrix, requirements manifest, fresh-machine walkthrough |
| 2 | IAO Template Plan (revised) | `docs/iao-template-plan-v0.1.md` | OVERWRITE with 7-command quick start, requirements-based setup |
| 3 | UAT Design (revised) | `docs/ddd-design-uat.md` | UPDATE with compatibility matrix reference, Playwright MCP option, Nemotron fallback |
| 4 | UAT Plan (unchanged) | `docs/ddd-plan-uat-v0.1.md` | No changes needed |
| 5 | Requirements Export Script | `export-requirements.fish` | NEW - repo root, executable |
| 6 | Build Log | `docs/ddd-build-v10.47.md` | Standard |
| 7 | Report | `docs/ddd-report-v10.47.md` | Standard |
| 8 | Changelog | `docs/ddd-changelog-v10.47.md` | Standard |

---

## Step 0: Pre-Flight

```bash
cd ~/dev/projects/tripledb

# Verify docs
ls docs/ddd-design-v10.47.md
ls docs/ddd-plan-v10.47.md

# Archive v10.46
mkdir -p docs/archive
mv docs/ddd-design-v10.46.md docs/archive/ 2>/dev/null
mv docs/ddd-plan-v10.46.md docs/archive/ 2>/dev/null
mv docs/ddd-report-v10.46.md docs/archive/ 2>/dev/null
mv docs/ddd-build-v10.46.md docs/archive/ 2>/dev/null
mv docs/ddd-changelog-v10.46.md docs/archive/ 2>/dev/null
# NOTE: do NOT archive ddd-design-uat.md, ddd-plan-uat-v0.1.md, iao-template-*.md
# These are being revised in-place, not replaced.

# Changelog count
grep -c '^\*\*v' README.md
# Expected: 31

# Verify existing deliverables that need revision
ls docs/iao-template-design-v0.1.md
ls docs/iao-template-plan-v0.1.md
ls docs/ddd-design-uat.md
ls docs/ddd-plan-uat-v0.1.md
```

**Write checkpoint after Step 0.**

---

## Step 1: Create Requirements Export Script

Place `export-requirements.fish` at the repository root.

The script (provided in the design doc and as a separate artifact) does:
1. Exports pacman packages (native + AUR separately)
2. Exports npm global packages with versions
3. Exports pip packages (freeze format)
4. Captures Flutter version + doctor output
5. Copies fish config (sanitized - API keys redacted)
6. Copies MCP configs (claude-mcp.json, gemini-settings.json)
7. Captures system info (hostname, OS, kernel, GPU)
8. Generates `requirements/install.fish` - the one-shot install script

The install script handles:
1. All pacman packages from manifest
2. yay installation + AUR packages
3. Flutter group permissions
4. Global npm packages
5. pip packages from freeze file
6. Puppeteer browser download
7. Flutter doctor
8. Verification with pass/fail for every tool
9. "Next Steps" instructions for manual items (API keys, SSH, MCP configs)

**Include Playwright system deps** in the pacman package list:
```
nss at-spi2-core cups libdrm mesa libxkbcommon libxcomposite libxdamage libxrandr pango cairo alsa-lib
```

These must be captured by the export script (they'll be in `pacman-native.txt` if installed) so that Playwright MCP works on fresh machines.

**Write checkpoint after Step 1.**

---

## Step 2: Revise IAO Template Design (iao-template-design-v0.1.md)

OVERWRITE the existing file with the expanded version per design doc Section 4.

### New sections to add:

**Section: Compatibility Matrix**

Copy the full matrix from design doc Section 2 into the template. This is the primary addition - it transforms the template from "here's one tool stack" to "here are your options at each layer."

Each layer table must include:
- Orchestration: Claude Code (Opus/Sonnet), Gemini CLI, OpenClaw, NemoClaw
- LLM Inference: Gemini Flash, Nemotron 3 (Nano/Super), Claude Sonnet API, Ollama
- Browser Automation: Playwright MCP, Puppeteer, Lighthouse
- Data Storage: Firestore, Supabase, SQLite, Realtime DB
- Frontend: Flutter, Next.js, SvelteKit
- Hosting: Firebase, Vercel, Cloudflare Pages
- Batch Execution: tmux, screen, nohup/systemd

Each layer also has a "Recommended combinations" sub-table for common use cases.

**Section: Environment Setup (Requirements Manifest)**

Document the export/install pattern:
- Run `export-requirements.fish` on a working machine
- Commit `requirements/` to repo
- On new machine: `fish requirements/install.fish`
- Manual steps: API keys, SSH, MCP configs

Include the list of manifest files and what each contains.

**Section: Fresh Machine Walkthrough**

Step-by-step from a fresh CachyOS machine to first YOLO launch:

```
1. Install CachyOS (from ISO, select KDE Plasma + Wayland)
2. First boot: open Konsole
3. Install fish: sudo pacman -S fish
4. Set fish as default: chsh -s /usr/bin/fish
5. Log out, log back in, open Konsole (now fish)
6. Install git: sudo pacman -S git
7. Setup SSH key for GitHub
8. Clone the project repo
9. Run requirements/install.fish
10. Copy fish config + add API keys
11. Copy MCP configs
12. Reload shell
13. Verify: flutter analyze && flutter build web
14. Read CLAUDE.md, launch: claude --dangerously-skip-permissions
```

**Section: OpenClaw/NemoClaw Setup Guide**

For projects that select OpenClaw as orchestration layer:

```bash
# Install NemoClaw (single command)
nemoclaw init --model local:nemotron-3-nano-4b --policy strict

# For P3 Ultra (16GB VRAM) - run the larger model
nemoclaw init --model local:nemotron-3-super-120b --policy strict

# Connect to sandbox
nemoclaw my-agent connect

# Status check
nemoclaw my-agent status
```

Include the policy YAML reference for customizing agent permissions.

**Section: Playwright MCP Setup Guide**

For projects using Playwright MCP:

```bash
# System deps (Arch/CachyOS)
sudo pacman -S --needed nss at-spi2-core cups libdrm mesa \
  libxkbcommon libxcomposite libxdamage libxrandr pango cairo alsa-lib

# Install Playwright browsers
npx playwright install chromium firefox

# Claude MCP config (~/.config/claude/mcp.json)
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest", "--headless"]
    }
  }
}

# Verify
npx playwright --version
```

### Revised Quick Start (7 commands)

Replace the 5-command quick start with the 7-command version from design doc Section 4.

### Size Target

500-650 lines. The compatibility matrix adds ~150 lines. The environment/walkthrough sections add ~100 lines. The tool setup guides add ~80 lines.

**Write checkpoint after Step 2.**

---

## Step 3: Revise IAO Template Plan (iao-template-plan-v0.1.md)

OVERWRITE with revised Phase 0 plan that uses the requirements manifest approach.

### Key changes:

1. **Quick Start** - 7 commands instead of 5 (adds install.fish and MCP config)
2. **Step 1 (Document Environment)** - now includes "run export-requirements.fish on your working machine" and "commit requirements/ to repo"
3. **Step 2 (Define Pipeline)** - now references the compatibility matrix for tool selection at each layer
4. **Step 3 (Scaffold Repository)** - now includes requirements/ directory in the scaffold
5. **Step 4 (Pre-Flight)** - now runs `fish requirements/install.fish` as the first validation step on new machines

### Size Target

200-300 lines.

**Write checkpoint after Step 3.**

---

## Step 4: Revise UAT Design (ddd-design-uat.md)

UPDATE (not overwrite) the existing UAT design with three additions:

### 4a. Compatibility Matrix Reference

Add a section that references the compatibility matrix and states which tools the UAT uses:

```markdown
## Tool Selection (from Compatibility Matrix)

| Layer | Tool Selected | Alternative |
|-------|--------------|-------------|
| Orchestration | Gemini CLI | OpenClaw + NemoClaw (future) |
| LLM | Gemini 2.5 Flash | Nemotron 3 Nano via Ollama (offline fallback) |
| Browser | Puppeteer (primary) | Playwright MCP (if deps installed) |
| Storage | Local JSONL (no Firestore writes) | N/A |
| Frontend | Flutter Web | N/A |
| Hosting | Firebase preview channel | N/A |
| Batch | tmux | N/A |

See iao-template-design-v0.1.md Section 3 for the full matrix.
```

### 4b. Playwright MCP Option

Add a note that if Playwright system deps are installed (via requirements manifest), Gemini can use Playwright MCP for browser automation alongside or instead of Puppeteer scripts.

### 4c. Nemotron Fallback

Add a section documenting the Nemotron offline fallback:

```markdown
## LLM Fallback: Nemotron 3 Nano 4B

If Gemini Flash API is unreachable during UAT execution:
1. Check network connectivity
2. If rate-limited or offline, fall back to Nemotron 3 Nano 4B via Ollama
3. Nemotron handles normalization tasks only (8K context too small for extraction)
4. Extraction MUST use Gemini Flash - if Flash is down, STOP the phase

Ollama with Nemotron:
  ollama pull nemotron-3-nano-4b
  ollama run nemotron-3-nano-4b
```

**Write checkpoint after Step 4.**

---

## Step 5: Update README + Generate Standard Artifacts

### 5a. APPEND Changelog Entry

```markdown
**v10.47 (Phase 10 - Template Revision + Compatibility Matrix)**
- **Compatibility matrix:** Layer-by-layer tool options table added to IAO template. Covers
  orchestration (Claude Code, Gemini CLI, OpenClaw, NemoClaw), LLM inference (Gemini Flash,
  Nemotron 3 Nano/Super, Claude Sonnet, Ollama), browser automation (Playwright MCP, Puppeteer,
  Lighthouse), storage, frontend, hosting, and batch execution. Recommended combinations per
  use case.
- **Requirements manifest:** Export script (export-requirements.fish) captures pacman, AUR, npm,
  pip packages + configs from working machine. Install script (requirements/install.fish)
  reproduces the environment on a fresh CachyOS machine with verification.
- **Fresh machine walkthrough:** Step-by-step from CachyOS ISO to first YOLO launch, targeting
  junior devs setting up from scratch.
- **OpenClaw/NemoClaw integration:** Added as orchestration layer options with setup guides.
  NemoClaw + Nemotron 3 Super for security-sensitive and offline projects.
- **Playwright MCP promoted:** From Hold to primary MCP browser automation. System deps included
  in requirements manifest to prevent the v9.37-v9.42 installation failures.
- **Nemotron 3 as LLM fallback:** Gemini Flash primary, Nemotron 3 Nano as offline/private
  secondary for normalization tasks.
```

### 5b. Verify

```bash
grep -c '^\*\*v' README.md          # >= 32
grep '^\*\*v0\.7' README.md | head -1
grep '^\*\*v10\.47' README.md | head -1
```

### 5c. Generate Versioned Changelog + Standard Artifacts

Copy changelog to `docs/ddd-changelog-v10.47.md`. Generate build + report.

---

## Post-Flight: Tier 1

| Gate | Check | Expected |
|------|-------|----------|
| 1 | Changelog count >= 32 | PASS |
| 2 | First entry (v0.7) preserved | PASS |
| 3 | Last entry (v10.47) present | PASS |
| 4 | `docs/ddd-changelog-v10.47.md` exists | PASS |
| 5 | `docs/iao-template-design-v0.1.md` revised (has "Compatibility Matrix") | PASS |
| 6 | `docs/iao-template-plan-v0.1.md` revised (has 7-command quick start) | PASS |
| 7 | `docs/ddd-design-uat.md` updated (has Nemotron fallback) | PASS |
| 8 | `export-requirements.fish` exists at repo root | PASS |
| 9 | No em-dashes in any artifact | PASS |

---

## Success Criteria

```
[ ] Pre-flight passes
[ ] v10.46 artifacts archived (design, plan, report, build, changelog only - NOT the deliverables)
[ ] REQUIREMENTS EXPORT SCRIPT:
    [ ] export-requirements.fish at repo root
    [ ] Executable (chmod +x)
    [ ] Exports: pacman, AUR, npm, pip, flutter, fish config, MCP configs, system info
    [ ] Generates install.fish inside requirements/
    [ ] install.fish has 8-step install + verification
[ ] IAO TEMPLATE DESIGN (revised):
    [ ] Compatibility matrix with all 7 layers
    [ ] OpenClaw/NemoClaw in orchestration layer
    [ ] Nemotron 3 (Nano + Super) in LLM layer
    [ ] Playwright MCP in browser automation layer
    [ ] Recommended combinations tables
    [ ] Requirements manifest section
    [ ] Fresh machine walkthrough (CachyOS -> first YOLO)
    [ ] OpenClaw/NemoClaw setup guide
    [ ] Playwright MCP setup guide (with CachyOS/Arch deps)
    [ ] 7-command quick start
    [ ] 500-650 lines
[ ] IAO TEMPLATE PLAN (revised):
    [ ] 7-command quick start
    [ ] References requirements manifest
    [ ] References compatibility matrix for tool selection
    [ ] 200-300 lines
[ ] UAT DESIGN (updated):
    [ ] Tool selection table referencing compatibility matrix
    [ ] Playwright MCP option documented
    [ ] Nemotron fallback documented
[ ] README changelog >= 32
[ ] docs/ddd-changelog-v10.47.md generated
[ ] NO em-dashes in any artifact
[ ] Interventions: 0
```

---

## Launch Sequence

```bash
cd ~/dev/projects/tripledb

# Archive v10.46 iteration artifacts (NOT the deliverables)
mv docs/ddd-design-v10.46.md docs/archive/ 2>/dev/null
mv docs/ddd-plan-v10.46.md docs/archive/ 2>/dev/null
mv docs/ddd-report-v10.46.md docs/archive/ 2>/dev/null
mv docs/ddd-build-v10.46.md docs/archive/ 2>/dev/null
mv docs/ddd-changelog-v10.46.md docs/archive/ 2>/dev/null

# Place new docs
cp /path/to/ddd-design-v10.47.md docs/
cp /path/to/ddd-plan-v10.47.md docs/

# Place export script at repo root
cp /path/to/export-requirements.fish ./
chmod +x export-requirements.fish

# Update CLAUDE.md (use editor)

# Commit
git add .
git commit -m "KT starting 10.47 - template revision, compatibility matrix, requirements manifest"

# Launch YOLO
claude --dangerously-skip-permissions
```

Then: `Read CLAUDE.md and execute.`

After completion:
```bash
cd ~/dev/projects/tripledb

# Run the export script on this machine to generate initial manifests
fish export-requirements.fish

# Review
ls requirements/
wc -l docs/iao-template-design-v0.1.md  # target: 500-650

git add .
git commit -m "KT completed 10.47 - compatibility matrix, requirements manifest, tool integrations"
git push
```

---

## Reminder

- NO em-dashes. Use " - " instead.
- README changelog: APPEND only, >= 32.
