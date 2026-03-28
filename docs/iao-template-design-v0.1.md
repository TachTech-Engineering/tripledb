# IAO Project Template - Design v0.1

**Iterative Agentic Orchestration - A Methodology for Agent-Driven Software Projects**
**Author:** TachTech Engineering
**Version:** 0.1 (distilled from 46 iterations of production use)

---

# Table of Contents

1. [What IAO Is](#1-what-iao-is)
2. [The Nine Pillars](#2-the-nine-pillars)
3. [Plan Quality Checklist](#3-plan-quality-checklist)
4. [Failure Mode Reference](#4-failure-mode-reference)
5. [Top 10 Lessons Learned](#5-top-10-lessons-learned)
6. [CLAUDE.md Template](#6-claudemd-template)
7. [GEMINI.md Template](#7-geminimd-template)
8. [Artifact Naming Convention](#8-artifact-naming-convention)
9. [Markdown Formatting Rules](#9-markdown-formatting-rules)
10. [Quick Start](#10-quick-start)

---

# 1. What IAO Is

Iterative Agentic Orchestration (IAO) is a development methodology where LLM agents execute project phases autonomously while humans review versioned artifacts between iterations. Each iteration produces a plan (input) and a report (output). The report informs the next plan. The methodology itself evolves alongside the project.

IAO is not a framework, a platform, or a library. It is a set of principles - encoded as markdown files - that structure how an AI agent and a human architect collaborate. The agent does the work. The human sets the direction. The artifacts are the contract between them.

The methodology crystallized through 46 production iterations into nine pillars. These pillars are project-agnostic: they apply to web apps, data pipelines, security tools, or any project where an LLM agent is the primary executor. What changes per project is the platform constraint (Pillar 8) and the specific tools. The methodology stays the same.

---

# 2. The Nine Pillars

## Pillar 1 - Artifact Loop

Every iteration produces **five** artifacts:

| Direction | File | Author | Purpose |
|-----------|------|--------|---------|
| Input | `{project}-design-v{P}.{I}.md` | Human + Agent (chat) | Living architecture, locked decisions |
| Input | `{project}-plan-v{P}.{I}.md` | Human + Agent (chat) | Execution steps, success criteria |
| Output | `{project}-build-v{P}.{I}.md` | Executing agent | Session transcript |
| Output | `{project}-report-v{P}.{I}.md` | Executing agent | Metrics, orchestration report, recommendation |
| Output | `{project}-changelog-v{P}.{I}.md` | Executing agent | Versioned snapshot of changelog |

The design doc is the living architecture - it accumulates decisions across iterations. The plan is disposable - each iteration gets a fresh one. The report informs the next plan.

Previous artifacts are archived to `docs/archive/`. Only the current iteration's docs live in `docs/`. Agents never see outdated instructions, but the full history is preserved.

Each report includes an **Orchestration Report**: which agents, APIs, and scripts were used, their workload share, and their efficacy. This feeds Pillar 9.

**Changelog resilience:** The README changelog is the most fragile artifact. After every iteration: (1) append to README, (2) copy to `docs/{project}-changelog-v{P}.{I}.md`, (3) verify count >= threshold.

## Pillar 2 - Agentic Orchestration

The primary agent orchestrates LLMs, MCP servers, scripts, APIs, and sub-agents. The version lock file (`CLAUDE.md` or `GEMINI.md`) at project root points to the current design and plan docs.

**Agent Permissions:**

| Action | Allowed? | Notes |
|--------|----------|-------|
| Build commands | YES | Agents build freely |
| Deploy commands | YES | Agents deploy to configured targets |
| Local package installs | YES | Project-level installs |
| `sudo` (any command) | NO | Human must run sudo operations |
| `git add / commit / push` | NO | Human commits at phase boundaries |
| Ask the human a question | LAST RESORT | Exception: sudo operations |

**Sudo Exception:** When the agent needs sudo, it logs the exact command, pauses, and asks the human. Sudo interventions do NOT count against the zero-intervention target.

**Two-Environment Model:**

| Environment | Agent | Mode |
|-------------|-------|------|
| Dev | Claude Code (or primary agent) | YOLO interactive. Human + agent iterate. |
| UAT | Gemini CLI (or secondary agent) | YOLO auto-chain. Single session, zero human review. |

**Git Commit Model:** The human commits at phase boundaries, not iteration boundaries.

## Pillar 3 - Zero-Intervention Target

Every question the agent asks during execution is a failure in the plan document (except sudo operations). Pre-answer every decision point. Pre-set every environment variable. Pre-document every gotcha.

Measure plan quality by counting interventions - zero is the floor. If interventions > 0, the failure is in the plan, not the agent.

YOLO mode is the default for both dev and UAT.

## Pillar 4 - Pre-Flight Verification

Before execution begins, validate the environment:

```
[ ] Previous docs archived to docs/archive/
[ ] New design + plan in docs/
[ ] CLAUDE.md (or GEMINI.md) updated
[ ] git status clean
[ ] API keys set and validated
[ ] Build tools verified (analyze, build, test)
[ ] Testing tools available
[ ] Pipeline pre-flight passes (if applicable)
```

Project-specific additions go below the standard checklist.

## Pillar 5 - Self-Healing Execution

Errors are inevitable. When one occurs: diagnose -> fix -> re-run. Max 3 attempts per error, then log and skip. If 3 consecutive items fail with the same error, STOP.

**Checkpoint scaffolding:** Long-running iterations write a JSON checkpoint file after each completed step. On crash/relaunch, skip completed steps.

**Dependency self-heal:** If a required tool is missing, attempt local install first. If that fails, invoke sudo exception (Pillar 2). Never silently skip a dependency.

## Pillar 6 - Progressive Batching

Start small. Graduate to production scale only after the small batch achieves zero interventions.

Example progression: 10% -> 25% -> 50% -> 100% of the dataset. Each batch must achieve zero interventions before the next. This prevents catastrophic failures at scale.

## Pillar 7 - Post-Flight Functional Testing

Three-tier verification:

**Tier 1 - Standard Health:**
- App bootstraps (not blank screen)
- Console has zero uncaught errors
- Changelog integrity verified (count >= threshold)
- Versioned changelog snapshot exists

**Tier 2 - Iteration Playbook:**
Automated tests specific to the iteration's deliverables. Uses accessibility tree inspection, not screenshots. Browser targets: define your 2 primary browsers.

Documentation-only iterations are Tier 2 exempt.

**Tier 3 - Hardening Audit:**
Comprehensive audit: performance, error boundaries, security headers, dependency vulnerabilities, browser compatibility.

## Pillar 8 - Platform Constraints

Your non-negotiable architectural decisions that shape every tool choice. This pillar is project-specific - define it in your design doc.

Examples:
- "Flutter Web + Firebase, zero-cost by design"
- "React + AWS, enterprise compliance required"
- "Python CLI, air-gapped deployment"

Cost is often a design constraint. Document it here. Every tool choice should respect the constraint defined in Pillar 8.

## Pillar 9 - Continuous Improvement

IAO evolves alongside every project. At project milestones, conduct structured retrospective:

1. **Archive Review** - plan quality trends, intervention patterns
2. **Tool Efficacy** - orchestration reports -> tools matrix
3. **Vulnerability & BPA** - dependency CVE scan + best practice assessment
4. **Technology Radar** - evaluate new agents, LLMs, MCP servers across 5 axes (architecture fit, cost, token efficiency, integration, breadth)

The methodology must evolve. Static processes atrophy. Each phase should ask: "What did we learn that the methodology doesn't capture yet?"

---

# 3. Plan Quality Checklist

Validate every plan against these 14 items before execution:

```
[ ] All environment variables documented with exact names and expected values
[ ] All tool versions pinned (not "latest")
[ ] Hardware requirements validated (VRAM, disk, RAM) with pre-flight check
[ ] API keys validated in pre-flight (not just "set as needed")
[ ] Every likely error has a documented response (if X, then Y)
[ ] Batch size starts small and graduates (Pillar 6)
[ ] Success criteria are binary and automatable (pass/fail, not subjective)
[ ] Post-flight tests are specific scripts, not "verify it works"
[ ] Rollback procedure documented for destructive steps
[ ] Checkpoint strategy defined for long-running operations
[ ] Self-heal budget specified (max 3 attempts per error)
[ ] Previous iteration's report reviewed for gotchas to carry forward
[ ] All file paths are absolute or relative to documented root
[ ] Secret scan included in pre-flight
```

A plan that fails any of these items will likely require intervention. Fix the plan before executing it.

---

# 4. Failure Mode Reference

19 failure modes cataloged across 46 iterations, organized by category. Use this as a "what to watch for" guide.

## Environment Failures (6 modes)

| ID | Description | Prevention |
|----|-------------|------------|
| F1 | Runtime paths not set at shell level (set in script but tool reads at load time) | Pre-flight checklist: validate paths in shell config |
| F2 | Model too large for GPU VRAM | Pre-flight VRAM check. If model_size > 0.8 * VRAM, use API. |
| F3 | Global package install needs elevated permissions | Sudo exception policy. Document in design doc. |
| F4 | Auth token expired between iterations | Pre-flight auth validation |
| F5 | Orphan process holding GPU/resource | Pre-flight: check for and kill orphan processes |
| F6 | Testing tool missing system dependencies | Primary tool + fallback pattern. Don't debug dep issues. |

## Pipeline Failures (4 modes)

| ID | Description | Prevention |
|----|-------------|------------|
| F7 | False positive data matches (similarity too loose) | Two-pass verification: algorithmic match + LLM confirm |
| F8 | Null/empty values merged incorrectly | Input validation before normalization |
| F9 | Timeout on large inputs | Timeout budget based on input size, checkpoint every N items |
| F10 | Empty outputs (no data extracted from valid input) | Classify input types, accept edge cases, skip gracefully |

## Frontend Failures (4 modes)

| ID | Description | Prevention |
|----|-------------|------------|
| F11 | Blank screen crash on app load | Lazy init pattern, deferred DOM access, never access browser APIs before framework init |
| F12 | Cookie/consent broken by security flags | Test on both HTTP and HTTPS, use RFC-compliant date formats |
| F13 | Data-layer change has unintended UI side effect | Isolate data-layer changes from UI changes |
| F14 | Responsive layout broken on small viewports | Test at minimum viewport width in post-flight |

## API Failures (1 mode)

| ID | Description | Prevention |
|----|-------------|------------|
| F15 | Missing API key at runtime | Pre-flight key validation step (not "set as needed") |

## Testing Failures (2 modes)

| ID | Description | Prevention |
|----|-------------|------------|
| F16 | Testing tool blocked by system deps | Define primary + fallback. Don't waste time debugging dep issues. |
| F17 | Testing tool not in module resolution path | Local install fallback pattern (temp directory) |

## Methodology Failures (2 modes)

| ID | Description | Prevention |
|----|-------------|------------|
| F18 | Changelog count not verified | Post-flight Tier 1: verify count >= threshold |
| F19 | LLM model too slow for structured extraction | Benchmark model on small batch before committing. Free-tier APIs often outperform local. |

---

# 5. Top 10 Lessons Learned

Universal principles distilled from production use. Not project-specific.

**Lesson 1: Progressive Batching Prevents Catastrophic Failures.**
Never run the full dataset first. Graduate through small -> medium -> large -> full. Each batch must achieve zero interventions before the next.

**Lesson 2: The Plan IS the Permission.**
Every intervention is a plan gap. Count interventions. Zero is the target. If interventions > 0, the failure is in the plan, not the agent. Invest in plan quality over agent selection.

**Lesson 3: Free-Tier at Scale is Possible but Requires Discipline.**
Start with the cost constraint and select tools that fit. Don't select tools and hope the cost works out. Free-tier viability must be validated in the discovery phase.

**Lesson 4: Post-Flight Must Test Behavior, Not Appearance.**
Use accessibility tree inspection and state assertions. Never rely on visual screenshots for automated testing. Behavioral testing catches issues screenshots miss.

**Lesson 5: Changelog Resilience Requires Redundancy.**
A single changelog is a single point of failure. After every iteration: append, copy to versioned file, verify count. Three redundant copies.

**Lesson 6: Multi-Iteration Debugging Sagas Happen.**
Some features (consent systems, auth flows, complex state) touch multiple layers simultaneously. Budget 2-3 iterations, not 1. Each fix may expose a deeper issue.

**Lesson 7: Agent Choice Matters Less Than Plan Quality.**
A good plan makes any capable agent succeed. A bad plan makes any agent fail. The common factor in zero-intervention iterations is always plan quality, not the specific agent.

**Lesson 8: Local Inference is Free but Hardware is the Hard Constraint.**
Check hardware limits before selecting a local model. If the model doesn't fit, use a free-tier API. "Free local" is more expensive in time than "free-tier API" when hardware is insufficient.

**Lesson 9: Configuration-Level Security is a Quick Win.**
HTTP headers, firewall rules, and access control configs are faster, less risky, and easier to audit than application-level security changes. Prioritize configuration over code.

**Lesson 10: The Methodology Must Evolve.**
Review and update the methodology at project milestones, not just at project close. Each phase should ask: "What did we learn that the methodology doesn't capture yet?" Static processes atrophy.

---

# 6. CLAUDE.md Template

Place at project root. Replace `{project}`, `{P}`, `{I}` with your values.

```markdown
# {Project} - Agent Instructions

## Current Iteration: {P}.{I}

Read in order, then execute:
1. docs/{project}-design-v{P}.{I}.md - Architecture and environment setup
2. docs/{project}-plan-v{P}.{I}.md - Execution steps

## Testing
- Puppeteer (npm): Primary. If missing: cd /tmp && mkdir test && cd test && npm init -y && npm install puppeteer
- Browser targets: {browser-1} + {browser-2}

## Formatting
- NEVER use em-dashes. Use " - " (space-hyphen-space) instead.
- Use "->" for arrows, not unicode or "-->".

## Plan Quality
- All env vars documented with exact names
- Hardware requirements validated in pre-flight
- API keys validated in pre-flight (not "set as needed")
- Every likely error has a documented response
- Success criteria are binary and automatable
- Post-flight tests are specific scripts
- Checkpoint strategy defined for long-running ops

## Rules
- YOLO - code dangerously, never ask permission
- MUST produce {project}-build + {project}-report + {project}-changelog
- POST-FLIGHT: Tier 1 + Tier 2 (code-change iterations)
- README changelog: NEVER truncate, ALWAYS append. Copy to docs/{project}-changelog-v{P}.{I}.md

## Agent Permissions
- CAN: build, deploy, local package installs
- CANNOT: sudo (ask human), git add/commit/push (human commits at phase boundaries)
```

---

# 7. GEMINI.md Template

Place at project root for UAT execution.

```markdown
# {Project} - UAT Agent Instructions

## Executor: Gemini CLI (YOLO, tmux, auto-chain)

Read docs/{project}-design-uat.md (architecture for ALL phases).
Then read and execute docs/{project}-plan-uat-v0.1.md (Phase 0 setup).

After Phase 0, auto-chain: report -> next plan -> execute -> repeat.

## CRITICAL RULES
1. NO writes to production data stores. Pipeline produces local output only.
2. NO git add/commit/push. Human reviews after UAT.
3. NO sudo. All deps must be pre-installed.
4. NO human questions. Zero-intervention is mandatory.
5. NO em-dashes. Use " - " (space-hyphen-space).

## Stop Conditions
- Final phase complete (success)
- 3 consecutive identical failures (write failure report)
- Production data write detected (critical error, stop immediately)
```

---

# 8. Artifact Naming Convention

```
{project}-{type}-v{P}.{I}.md

Where:
  {project}  = project short name (lowercase, hyphenated)
  {type}     = design | plan | build | report | changelog
  {P}        = phase number (0-N)
  {I}        = global iteration number (monotonically increasing)
```

Examples:
- `myapp-design-v0.1.md` (Phase 0, iteration 1)
- `myapp-plan-v3.12.md` (Phase 3, iteration 12)
- `myapp-report-v5.15.md` (Phase 5, iteration 15)

Archive: `docs/archive/{project}-{type}-v{P}.{I}.md`

UAT artifacts: `{project}-{type}-uat-v{P}.{I}.md`

---

# 9. Markdown Formatting Rules

These rules prevent AI-generated text tells and maintain consistency:

1. **No em-dashes.** Use " - " (space-hyphen-space) instead. Detection: `grep -rn $'\xe2\x80\x94'`
2. **Arrows:** Use `->` for arrows. Not unicode arrows, not `-->`.
3. **Changelog:** APPEND only, never truncate. Count >= threshold after each update.
4. **Tables:** Use standard markdown pipe tables. No HTML.
5. **Code blocks:** Use triple backtick with language hint (```bash, ```json, ```markdown).
6. **Headers:** Use `#` hierarchy. No more than 3 levels of nesting.

---

# 10. Quick Start

5 commands to scaffold a new IAO project:

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

Then: "Read CLAUDE.md and execute."

---

## Hardware Fleet

Document your machines here. Include: CPU, GPU, VRAM, RAM, OS, shell.

---

## Pipeline Architecture

Document your pipeline here. Include: stages, tools, inputs, outputs, runtime.

---

## Technology Radar

Run your own radar at project close. Score tools on 5 axes: architecture fit, cost model, token efficiency, integration path, breadth. Rate as Adopt (>=4.0), Trial (3.0-3.9), Assess (2.0-2.9), Hold (<2.0).
