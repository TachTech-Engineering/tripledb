# IAO Project Template - Design v0.3

**Iterative Agentic Orchestration - A Methodology for Agent-Driven Software Projects**
**Author:** TachTech Engineering
**Version:** 0.3 (distilled from 48 iterations of production use)

---

# Table of Contents

1. [What IAO Is](#1-what-iao-is)
2. [The Nine Pillars](#2-the-nine-pillars)
3. [Compatibility Matrix](#3-compatibility-matrix)
4. [Plan Quality Checklist](#4-plan-quality-checklist)
5. [Failure Mode Reference](#5-failure-mode-reference)
6. [Top 10 Lessons Learned](#6-top-10-lessons-learned)
7. [Environment Setup](#7-environment-setup)
8. [Fresh Machine Walkthrough](#8-fresh-machine-walkthrough)
9. [Remote Access Setup](#9-remote-access-setup)
10. [IDE Setup](#10-ide-setup)
11. [Tool Setup Guides](#11-tool-setup-guides)
12. [Non-Claude-Code Execution Guide](#12-non-claude-code-execution-guide)
13. [fish Shell Notes](#13-fish-shell-notes)
14. [CLAUDE.md Template](#14-claudemd-template)
15. [GEMINI.md Template](#15-geminimd-template)
16. [Artifact Naming Convention](#16-artifact-naming-convention)
17. [Markdown Formatting Rules](#17-markdown-formatting-rules)
18. [Quick Start](#18-quick-start)

---

# 1. What IAO Is

Iterative Agentic Orchestration (IAO) is a development methodology where LLM agents execute project phases autonomously while humans review versioned artifacts between iterations. Each iteration produces a plan (input) and a report (output). The report informs the next plan. The methodology itself evolves alongside the project.

IAO is not a framework, a platform, or a library. It is a set of principles - encoded as markdown files - that structure how an AI agent and a human architect collaborate. The agent does the work. The human sets the direction. The artifacts are the contract between them.

The methodology crystallized through 48 production iterations into nine pillars. These pillars are project-agnostic: they apply to web apps, data pipelines, security tools, or any project where an LLM agent is the primary executor. What changes per project is the platform constraint (Pillar 8) and the specific tools. The methodology stays the same.

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

# 3. Compatibility Matrix

New projects select one tool per layer at Phase 0, informed by this matrix. The matrix is opinionated but not prescriptive - projects can mix and match.

## Layer: Orchestration

Manages agent execution, plan reading, artifact generation, and the iteration loop.

| Tool | Type | Cost | Strengths | Weaknesses | Best For |
|------|------|------|-----------|------------|----------|
| Claude Code (Opus) | Cloud agent | Subscription | Complex debugging, self-healing, 1M context | Cloud-dependent, subscription cost | Dev: interactive problem-solving |
| Claude Code (Sonnet) | Cloud agent | Subscription (cheaper) | Same capabilities, lower cost per token | Less capable on complex multi-step debugging | Dev: routine iterations, documentation |
| Gemini CLI | Cloud agent | Free tier | Free, auto-chain in tmux | Less capable at complex debugging | UAT: batch execution in tmux |
| OpenClaw | Local agent framework | Free (OSS) | 188K stars, self-evolving, spawns sub-agents | Early ecosystem, CVE-2026-25253 (WebSocket vuln) | Multi-agent workflows, always-on agents |
| NemoClaw (OpenShell) | Security sandbox for OpenClaw | Free (OSS, NVIDIA) | Policy-based governance, sandboxed execution | Early alpha (March 2026), CUDA-optimized | Enterprise agent governance |

**Recommended combinations:**

| Use Case | Primary | Secondary | Notes |
|----------|---------|-----------|-------|
| Standard IAO project | Claude Code (Opus) | Gemini CLI (UAT) | Proven across 46+ iterations |
| Cost-sensitive project | Claude Code (Sonnet) | Gemini CLI (UAT) | Route complex tasks to Opus API |
| Security-sensitive project | Claude Code (Opus) | NemoClaw + OpenClaw | OpenShell sandbox for agent governance |
| Multi-agent project | OpenClaw + NemoClaw | Claude Code (debug) | Swarm topology for parallel tasks |
| Offline/air-gapped | NemoClaw + Nemotron | N/A | Fully local, no cloud dependency |

## Layer: LLM Inference

The model that does extraction, normalization, summarization, and other language tasks.

| Tool | Type | Cost | VRAM Req | Context | Best For |
|------|------|------|----------|---------|----------|
| Gemini 2.5 Flash API | Cloud API (Google) | Free tier | None | 1M tokens | Primary extraction/normalization |
| Nemotron 3 Nano 4B | Local (NVIDIA) | Free (OSS) | 4-8 GB | ~8K | Quick local tasks, offline fallback |
| Nemotron 3 Super 120B | Local (NVIDIA) | Free (OSS) | 16+ GB | ~32K | Complex extraction when offline |
| Claude Sonnet API | Cloud API (Anthropic) | Per-token | None | 200K | Verification passes, quality-sensitive tasks |
| Ollama (local models) | Local runtime | Free | Varies | Varies | Normalization, simple tasks, offline |

**Recommended combinations:**

| Use Case | Primary | Secondary | Notes |
|----------|---------|-----------|-------|
| Standard pipeline | Gemini 2.5 Flash | None | $0, proven across 15+ iterations |
| Offline/private data | Nemotron 3 Super | Nemotron 3 Nano | All local, $0, requires 16GB VRAM |
| Quality-critical | Gemini 2.5 Flash | Claude Sonnet (verification) | Flash extracts, Sonnet verifies |

## Layer: Browser Automation

Testing, scraping, post-flight verification, and agent-driven web interaction.

| Tool | Type | MCP | Best For |
|------|------|-----|----------|
| Playwright MCP | MCP server | Yes | Agent-driven browser automation, MCP-integrated post-flight |
| Puppeteer (npm) | npm package | No | Scripted post-flight testing, /tmp fallback pattern |
| Lighthouse CLI | npx CLI | Optional | Hardening iterations, Tier 3 audits |

**Note:** Playwright MCP requires explicit system deps on Arch/CachyOS. See Section 11 for setup. Playwright was promoted from Hold to primary MCP browser automation after the requirements manifest approach solved the dep installation failures from previous iterations.

**Recommended combinations:**

| Use Case | Primary | Secondary |
|----------|---------|-----------|
| MCP-integrated testing | Playwright MCP | Puppeteer (fallback) |
| Scripted test suites | Puppeteer | Lighthouse (audits) |
| Full hardening | Playwright MCP + Lighthouse | Puppeteer (fallback) |

## Layer: Data Storage

| Tool | Type | Cost | Best For |
|------|------|------|----------|
| Cloud Firestore | NoSQL (Google) | Free tier (Spark) | Mobile-first apps, real-time data |
| Supabase (Postgres) | SQL (OSS) | Free tier | Relational data, complex queries |
| SQLite (local) | Local file DB | Free | Prototyping, pipeline intermediate storage |
| Firebase Realtime DB | JSON tree (Google) | Free tier | Simple key-value, chat-style data |

## Layer: Frontend

| Tool | Type | Best For |
|------|------|----------|
| Flutter Web | Cross-platform (Google) | Mobile-first apps targeting web + app stores |
| Next.js | React framework | Content-heavy sites, SEO-critical apps |
| SvelteKit | Svelte framework | Performance-critical web apps |

## Layer: Hosting

| Tool | Type | Best For |
|------|------|----------|
| Firebase Hosting | Static CDN (Google) | Flutter Web, SPAs, preview channels |
| Vercel | Edge hosting | Next.js, React apps, SSR |
| Cloudflare Pages | Static CDN | Static sites, JAMstack |

## Layer: Batch Execution

| Tool | Type | Best For |
|------|------|----------|
| tmux + fish | Terminal multiplexer | Long-running pipeline batches, UAT auto-chain |
| screen | Terminal multiplexer | Legacy systems |
| nohup + systemd | System service | Production services, always-on agents |

---

# 4. Plan Quality Checklist

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

# 5. Failure Mode Reference

19 failure modes cataloged across 48 iterations, organized by category. Use this as a "what to watch for" guide.

## Environment Failures (6 modes)

| ID | Description | Prevention |
|----|-------------|------------|
| F1 | Runtime paths not set at shell level (set in script but tool reads at load time) | Pre-flight checklist: validate paths in shell config |
| F2 | Model too large for GPU VRAM | Pre-flight VRAM check. If model_size > 0.8 * VRAM, use API. |
| F3 | Global package install needs elevated permissions | Sudo exception policy. Document in design doc. |
| F4 | Auth token expired between iterations | Pre-flight auth validation |
| F5 | Orphan process holding GPU/resource | Pre-flight: check for and kill orphan processes |
| F6 | Testing tool missing system dependencies | Requirements manifest captures deps. Install script handles them explicitly. |

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
| F16 | Testing tool blocked by system deps | Requirements manifest installs deps explicitly. Primary + fallback tools. |
| F17 | Testing tool not in module resolution path | Local install fallback pattern (temp directory) |

## Methodology Failures (2 modes)

| ID | Description | Prevention |
|----|-------------|------------|
| F18 | Changelog count not verified | Post-flight Tier 1: verify count >= threshold |
| F19 | LLM model too slow for structured extraction | Benchmark model on small batch before committing. Free-tier APIs often outperform local. |

---

# 6. Top 10 Lessons Learned

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

# 7. Environment Setup

## Requirements Manifest Approach

The problem: documenting packages in prose leads to missed dependencies. 89% of all interventions in production were environment-related (Phases 1-2). The solution: export actual installed packages from a working machine into manifest files. New machines install from the manifests. Setup becomes deterministic.

### Manifest Files

```
requirements/
  pacman-native.txt        # pacman -Qqen output (native repo packages)
  pacman-foreign.txt       # pacman -Qqem output (AUR packages)
  aur-packages.txt         # yay -Qqm output
  npm-global.txt           # npm list -g with versions
  pip-packages.txt         # pip freeze output
  flutter-version.txt      # flutter --version
  flutter-doctor.txt       # flutter doctor -v
  fish-config-sanitized.fish  # fish config with API keys redacted
  claude-mcp.json          # Claude Code MCP server config (keys redacted)
  gemini-settings.json     # Gemini CLI MCP + settings (keys redacted)
  system-info.txt          # hostname, OS, kernel, GPU
  install.fish             # One-shot install script
```

### Export Script

Run `fish export-requirements.fish` on a working machine. Produces the `requirements/` directory. Commit to repo.

The export script sanitizes API keys in fish config and MCP configs before writing to the manifest. The install script tells the user to add their own keys as a manual step.

### Install Script

A colleague on a fresh CachyOS machine runs:

```fish
git clone https://github.com/{org}/{project}.git
cd {project}
fish requirements/install.fish
```

The install script handles:
1. All pacman packages from manifest
2. Playwright browser system deps (explicitly - they are implicit deps on working machines but missing on fresh installs)
3. yay installation + AUR packages (core vs optional split)
4. Flutter group permissions
5. npm global packages (@latest for agent tools, pinned for infrastructure)
6. pip packages (CUDA packages skipped on AMD/Intel GPU machines)
7. Test browser downloads (Playwright + Puppeteer)
8. GPU detection + CUDA path configuration (NVIDIA only)
9. Flutter doctor
10. Verification with pass/fail/skip for every tool

### What the Install Script Does NOT Do

- Does not set API keys (security - manual step)
- Does not configure SSH keys (security - manual step)
- Does not clone the project repo (the script IS in the repo)
- Does not run without the user present (needs sudo for pacman)

### GPU-Aware Installation

The install script detects GPU type at runtime:

- **NVIDIA GPU detected:** Full install including ctranslate2, faster-whisper, CUDA path config. Prints the exact `set -gx LD_LIBRARY_PATH` command for fish config.
- **AMD/Intel GPU detected:** Skips CUDA-dependent pip packages. Prints a note that transcription phases must run on a CUDA machine. All other phases work on AMD/Intel.

This prevents the VRAM/CUDA failures that caused 20+ interventions in early iterations.

---

# 8. Fresh Machine Walkthrough

Step-by-step from a fresh CachyOS machine to first YOLO launch.

### Phase A: Base OS (5 minutes)

```fish
# 1. Install CachyOS from ISO (select KDE Plasma + Wayland)
# 2. First boot: open Konsole
# 3. Install fish shell
sudo pacman -S fish

# 4. Set fish as default shell
chsh -s /usr/bin/fish

# 5. Log out and back in. Open Konsole (now running fish).
```

### Phase B: Project Clone (5 minutes)

```fish
# 6. Install git
sudo pacman -S git

# 7. Clone via HTTPS (no SSH key needed yet, repo is public)
mkdir -p ~/dev/projects
git clone https://github.com/{org}/{project}.git ~/dev/projects/{project}
cd ~/dev/projects/{project}
```

### Phase C: Automated Install (15-30 minutes)

```fish
# 8. Run the install script
fish requirements/install.fish

# Follow prompts. Enter sudo password when asked.
# Review the verification output at the end.
```

### Phase D: Manual Configuration (10 minutes)

```fish
# 9. Copy fish config and add your API keys
cp requirements/fish-config-sanitized.fish ~/.config/fish/config.fish
nano ~/.config/fish/config.fish
# Replace REDACTED values with your actual keys:
#   GEMINI_API_KEY, GOOGLE_PLACES_API_KEY, etc.
source ~/.config/fish/config.fish

# 10. Copy MCP configs and add your API keys
mkdir -p ~/.config/claude ~/.gemini
cp requirements/gemini-settings.json ~/.gemini/settings.json
nano ~/.gemini/settings.json
# Add your Firecrawl API key and any other keys

# 11. Setup SSH for GitHub (for pushing later)
ssh-keygen -t ed25519 -C "your-email@example.com"
cat ~/.ssh/id_ed25519.pub
# Add the key to GitHub: Settings -> SSH and GPG Keys
```

### Phase E: Verify + Launch (5 minutes)

```fish
# 12. Verify the project builds
cd ~/dev/projects/{project}
flutter analyze
flutter build web

# 13. Read CLAUDE.md, then launch
cat CLAUDE.md
claude --dangerously-skip-permissions
# Then: "Read CLAUDE.md and execute."
```

Total time: ~40 minutes from bare metal to first YOLO launch.

---

# 9. Remote Access Setup

For teams where a colleague needs remote access to a development machine, or where machines are headless.

### UFW Firewall

```fish
# Install UFW
sudo pacman -S ufw

# Default policy: deny incoming, allow outgoing
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH
sudo ufw allow 22/tcp

# Allow Cockpit web console
sudo ufw allow 9090/tcp

# Enable firewall
sudo ufw enable
sudo ufw status verbose
```

### Cockpit Web Console

Cockpit provides a web-based terminal and system management interface. Useful for remote support when SSH is not yet configured on the remote machine.

```fish
# Install Cockpit
sudo pacman -S cockpit

# Enable the Cockpit socket (starts on-demand, not always-on)
sudo systemctl enable --now cockpit.socket

# Access from browser on the same network:
#   https://{machine-ip}:9090
# Login with your Linux username and password.
# The terminal tab gives a full fish shell session.
```

### OpenSSH Server

```fish
# Install and enable SSH
sudo pacman -S openssh
sudo systemctl enable --now sshd

# Create a user account for colleague
sudo useradd -m -G wheel,flutterusers -s /usr/bin/fish {colleague}
sudo passwd {colleague}
```

### WAN Access (Optional)

For access outside the local network:

- **Cloudflare Tunnel:** Zero-trust access without opening ports. Best for persistent access.
- **Tailscale:** Mesh VPN. Install on both machines. Devices see each other by hostname.
- **SSH port forwarding:** Quick and dirty, requires router config.

Choose one based on your security posture. All three are free tier compatible.

---

# 10. IDE Setup

### Antigravity (VS Code Fork)

Antigravity is the IDE. NOT Visual Studio Code. NOT the `visual-studio-code-bin` AUR package.

```fish
# Install Antigravity from AUR
yay -S antigravity
```

**Essential extensions:**
- Flutter + Dart (Flutter development)
- fish shell syntax (shell scripts)
- Markdown All in One (artifact editing)
- GitLens (git history)

**Critical note:** Run Claude Code from Konsole terminal, NOT from the IDE integrated terminal. The IDE terminal has caused agent crashes in production. Always launch from a standalone Konsole window:

```fish
# Correct: Konsole terminal
cd ~/dev/projects/{project}
claude --dangerously-skip-permissions

# Incorrect: IDE integrated terminal (crashes)
```

### Android Studio

Still needed for the Flutter SDK, Android command-line tools, and emulator. Install via JetBrains Toolbox (included in AUR packages). Antigravity is the daily driver for editing. Android Studio provides the SDK toolchain.

---

# 11. Tool Setup Guides

## 11a. Claude Code + Claude Skills

Claude Code is the primary dev orchestration agent.

```fish
# Install (handled by install.fish, but for reference)
sudo npm install -g @anthropic-ai/claude-code@latest

# Launch in YOLO mode
claude --dangerously-skip-permissions

# Version check
claude --version
```

**Claude Skills** extend CLAUDE.md with structured, reusable capabilities. Package IAO pillars as skill files:

```
/skills/
  pre-flight.md      # Standard pre-flight checklist execution
  post-flight.md     # Tier 1 + Tier 2 verification
  changelog.md       # Append, copy, verify pattern
```

Skills are invoked by the agent when the plan references them. They reduce CLAUDE.md size by moving reusable procedures into on-demand files. Skills port across projects - the same pre-flight skill works for any IAO project.

To create a skill: write a markdown file in `/skills/` that describes the procedure, inputs, outputs, and success criteria. Reference it in CLAUDE.md or the plan doc.

## 11b. Gemini CLI + Optimization

Gemini CLI is the UAT orchestration agent and free-tier alternative.

```fish
# Install (handled by install.fish, but for reference)
sudo npm install -g @google/gemini-cli@latest

# Configuration
mkdir -p ~/.gemini
# Copy gemini-settings.json from requirements/ and add your API keys

# Launch
gemini
```

**Context window management:** Gemini CLI's context window is smaller than Claude's. For long plans:
- Keep design docs under 800 lines
- Keep plan docs under 400 lines
- Use section references ("See design doc Section 3") instead of duplicating content

**MCP configuration** lives in `~/.gemini/settings.json`:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"],
      "env": { "CHROME_PATH": "/usr/bin/google-chrome-stable" }
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    }
  }
}
```

## 11c. OpenClaw / NemoClaw

OpenClaw is an open-source agent framework (188K GitHub stars, March 2026). NemoClaw (NVIDIA OpenShell) provides a security sandbox for OpenClaw agents. Both are early alpha - use for evaluation and multi-agent experiments, not production IAO work yet.

**When to consider OpenClaw:**
- Multi-agent workflows where sub-agents run in parallel
- Security-sensitive projects requiring sandboxed agent execution
- Offline/air-gapped environments using Nemotron locally
- Enterprise governance requirements (policy-based agent control)

**Setup (requires NVIDIA GPU for Nemotron):**

```fish
# Install NemoClaw with Nemotron Nano (fits on 8GB VRAM)
nemoclaw init --model local:nemotron-3-nano-4b --policy strict

# For 16GB+ VRAM machines - use the larger model
nemoclaw init --model local:nemotron-3-super-120b --policy strict

# Connect to sandbox
nemoclaw my-agent connect

# Status check
nemoclaw my-agent status
```

**Policy YAML** controls what the agent can do:

```yaml
# Example: restrict file system access
policy:
  name: strict
  filesystem:
    allow: ["/home/user/dev/projects"]
    deny: ["/etc", "/var", "/root"]
  network:
    allow: ["api.anthropic.com", "generativelanguage.googleapis.com"]
    deny: ["*"]
  commands:
    deny: ["rm -rf", "sudo", "git push"]
```

**Brave Search API** (OpenClaw's web search):

```fish
# OpenClaw uses Brave Search for web queries
set -gx BRAVE_API_KEY "your-brave-api-key"
```

**Telegram Bot Integration** (optional - status notifications):

```fish
# OpenClaw can send agent status updates via Telegram
set -gx TELEGRAM_BOT_TOKEN "your-bot-token"
set -gx TELEGRAM_CHAT_ID "your-chat-id"
```

**Known issues (as of March 2026):**
- CVE-2026-25253: WebSocket vulnerability in OpenClaw - NemoClaw mitigates this
- Early alpha, expect breaking changes
- CLI-based, not MCP-native - requires custom integration
- CUDA-optimized only (no AMD/Intel GPU support for local Nemotron)

## 11d. Firecrawl MCP

Firecrawl MCP enables agents to crawl reference websites for design inspiration and component patterns during frontend phases. Critical for Phase 8 (frontend) when the agent needs to study existing sites.

```fish
# Firecrawl runs as an MCP server - no global install needed
# Configure in Claude MCP config (~/.config/claude/mcp.json):
```

```json
{
  "mcpServers": {
    "firecrawl": {
      "command": "npx",
      "args": ["-y", "firecrawl-mcp"],
      "env": {
        "FIRECRAWL_API_KEY": "your-firecrawl-api-key"
      }
    }
  }
}
```

For Gemini CLI, add the same block to `~/.gemini/settings.json` under `mcpServers`.

**API key:** Get a Firecrawl API key at https://firecrawl.dev. Free tier available.

**Reference sites:** In Phase 8 plans, specify 4 reference site URLs the agent should crawl for design patterns:

```markdown
## Reference Sites for Design Inspiration
1. {url-1} - layout patterns
2. {url-2} - navigation patterns
3. {url-3} - data display patterns
4. {url-4} - mobile responsive patterns
```

**Known issue:** Firecrawl had certificate errors in earlier iterations. If you see `UNABLE_TO_VERIFY_LEAF_SIGNATURE`, set:

```fish
set -gx NODE_TLS_REJECT_UNAUTHORIZED 0
# Use ONLY during crawl phase, then unset:
set -e NODE_TLS_REJECT_UNAUTHORIZED
```

## 11e. Playwright MCP

Playwright MCP enables agent-driven browser automation through MCP calls. Primary tool for post-flight testing when running under an MCP-capable agent.

```fish
# System deps (Arch/CachyOS) - REQUIRED before browser install
# These are handled by install.fish Step 2, but for reference:
sudo pacman -S --needed nss at-spi2-core cups libdrm mesa \
  libxkbcommon libxcomposite libxdamage libxrandr pango cairo alsa-lib

# Install Playwright browsers
npx playwright install chromium firefox

# Verify
npx playwright --version
```

**Claude MCP config** (`~/.config/claude/mcp.json`):

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest", "--headless"]
    }
  }
}
```

**Gemini MCP config** (`~/.gemini/settings.json`):

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"],
      "env": { "CHROME_PATH": "/usr/bin/google-chrome-stable" }
    }
  }
}
```

**Why Playwright was promoted from Hold to primary:** The requirements manifest approach (Section 7) now installs system deps explicitly in the install script. This solves the dep wall that blocked Playwright in previous iterations. With deps guaranteed by the manifest, Playwright MCP is the preferred browser automation tool for MCP-capable agents.

---

# 12. Non-Claude-Code Execution Guide

Not every team member has a Claude Code license. This section documents alternative execution paths for each IAO phase.

## Option A: Claude Web UI (claude.ai)

For phases that produce markdown artifacts (design, plan, report):

1. Open claude.ai in a browser
2. Upload the design doc and plan doc as attachments
3. Paste the instruction: "Read the design doc, then read the plan doc, and produce the artifacts specified in the plan."
4. Copy the output artifacts into your project's `docs/` directory
5. Human runs any shell commands from the plan manually

**Limitations:** No filesystem access, no MCP servers, no YOLO mode. The human must execute all commands. Best for documentation-only iterations.

## Option B: Claude API

For automated execution without Claude Code:

```fish
# Using curl with the Anthropic API
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-sonnet-4-20250514",
    "max_tokens": 8192,
    "messages": [{"role": "user", "content": "...plan content..."}]
  }'
```

Requires an API key and scripting to chain multiple calls. More complex but automatable.

## Option C: Gemini CLI (Free Alternative)

Gemini CLI is free and supports YOLO auto-chain execution. It is the recommended alternative for colleagues without Claude Code.

```fish
# Install
sudo npm install -g @google/gemini-cli@latest

# Configure (API key only - no subscription)
set -gx GEMINI_API_KEY "your-key"

# Launch
cd ~/dev/projects/{project}
gemini
# "Read GEMINI.md and execute."
```

Gemini CLI supports MCP servers (Playwright, Firecrawl, Context7, Lighthouse) and can run in tmux for long sessions. See Section 11b for configuration.

## Option D: No LLM Agent (Pure Bash/fish)

Some phases can run without any LLM agent:

| Phase | LLM Required? | Without LLM |
|-------|--------------|-------------|
| Acquisition (download) | No | `yt-dlp` commands from plan doc |
| Transcription | No | `faster-whisper` Python scripts |
| Extraction | Yes | Requires LLM for structured output |
| Normalization | Yes | Requires LLM for dedup/merge logic |
| Geocoding | No | API calls via Python scripts |
| Frontend build | No | `flutter build web` |
| Deploy | No | `firebase deploy --only hosting` |

For LLM-free phases, the plan doc contains copy-paste command blocks:

```fish
# Example: acquisition phase without an agent
cd ~/dev/projects/{project}/pipeline
python3 scripts/phase1_acquire.py --batch-size 30
python3 scripts/phase2_transcribe.py --input data/audio/ --output data/transcripts/
```

The human reads the plan, runs the commands, and writes the report manually.

---

# 13. fish Shell Notes

IAO projects target fish shell on CachyOS/Arch. These notes prevent common gotchas.

## No Heredocs

fish does not support heredocs (`cat << 'EOF'`). This is the single most common failure when porting bash scripts to fish.

**Wrong (bash heredoc - breaks in fish):**
```bash
cat << 'EOF' > output.txt
line 1
line 2
EOF
```

**Correct (fish - echo append pattern):**
```fish
echo 'line 1' > output.txt
echo 'line 2' >> output.txt
```

**Correct (fish - printf for multi-line):**
```fish
printf '%s\n' 'line 1' 'line 2' > output.txt
```

Detection: if `grep -rn 'cat <<\|<<EOF\|<<HEREDOC'` finds matches in a `.fish` file, it will fail.

## Running fish Scripts

```fish
# Option 1: Call fish explicitly
fish script.fish

# Option 2: Make executable
chmod +x script.fish
./script.fish
# Requires #!/usr/bin/env fish shebang

# Gotcha: browser downloads may append (1) to filename
# Rename before using: mv 'script(1).fish' script.fish
```

## fish vs bash Syntax Differences

| Feature | bash | fish |
|---------|------|------|
| Variable assignment | `VAR=value` | `set VAR value` |
| Export | `export VAR=value` | `set -gx VAR value` |
| Conditional | `if [ condition ]; then ... fi` | `if test condition ... end` |
| For loop | `for i in ...; do ... done` | `for i in ... ... end` |
| Command substitution | `$(command)` | `(command)` |
| Heredoc | `cat << 'EOF'` | Not supported - use echo/printf |

## Environment Variable Gotcha

Set environment variables in `~/.config/fish/config.fish`, not in scripts that run before the tool loads. Specifically:

```fish
# These MUST be in config.fish, not in a pipeline script:
set -gx LD_LIBRARY_PATH /usr/lib $LD_LIBRARY_PATH  # CUDA libs
set -gx CHROME_EXECUTABLE /usr/bin/google-chrome-stable
set -gx ANDROID_HOME $HOME/Android/Sdk
```

Tools like `faster-whisper` (ctranslate2) load CUDA libraries at import time. If `LD_LIBRARY_PATH` is set in a Python script, it's too late.

---

# 14. CLAUDE.md Template

Place at project root. Replace `{project}`, `{P}`, `{I}` with your values.

```markdown
# {Project} - Agent Instructions

## Current Iteration: {P}.{I}

Read in order, then execute:
1. docs/{project}-design-v{P}.{I}.md - Architecture and environment setup
2. docs/{project}-plan-v{P}.{I}.md - Execution steps

## Testing
- Playwright MCP: Primary (if configured)
- Puppeteer (npm): Fallback. If missing: cd /tmp && mkdir test && cd test && npm init -y && npm install puppeteer
- Browser targets: google-chrome-stable + firefox-esr

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

# 15. GEMINI.md Template

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

# 16. Artifact Naming Convention

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

# 17. Markdown Formatting Rules

These rules prevent AI-generated text tells and maintain consistency:

1. **No em-dashes.** Use " - " (space-hyphen-space) instead. Detection: `grep -rn $'\xe2\x80\x94'`
2. **Arrows:** Use `->` for arrows. Not unicode arrows, not `-->`.
3. **Changelog:** APPEND only, never truncate. Count >= threshold after each update.
4. **Tables:** Use standard markdown pipe tables. No HTML.
5. **Code blocks:** Use triple backtick with language hint (```bash, ```json, ```markdown).
6. **Headers:** Use `#` hierarchy. No more than 3 levels of nesting.

---

# 18. Quick Start

7 commands to get a new IAO project running on a configured machine:

```fish
# 1. Clone the project (or create new)
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

Then: "Read CLAUDE.md and execute."

---

## Hardware Fleet

| Machine | Type | CPU | GPU | VRAM | RAM | OS / Kernel | Shell | Display | Role |
|---------|------|-----|-----|------|-----|-------------|-------|---------|------|
| NZXTcos | Desktop (MSI PRO Z790-P WIFI DDR4) | Intel i9-13900K (32T, 5.8 GHz) | NVIDIA RTX 2080 SUPER + Intel UHD 770 | 8 GB | 64 GB DDR4 | CachyOS / 6.19.7-1 | fish 4.5.0 | 27" 1920x1080 | Primary dev. CUDA transcription. Phases 0-7, 9. |
| tsP3-cos | Desktop (ThinkStation P3 Ultra SFF G2) | Intel Core Ultra 9 285 (24C, 6.5 GHz) | NVIDIA RTX 2000 Ada + Intel iGPU | 16 GB | 64 GB DDR5 | CachyOS / 6.19.7-1 | fish 4.5.0 | 3x 63" 1920x1080 | Benchmarking, large model inference (Nemotron Super 120B). |
| auraX9cos | Laptop (ThinkPad X9-14 Gen 1) | Intel Core Ultra 7 268V (8C, 4.9 GHz) | Intel Arc 130V/140V | Shared | 32 GB | CachyOS / 6.18.9-3 | bash 5.3.9 | 14" 1920x1200 | Mobile dev. Phase 8 (Flutter). No CUDA. |
| p14s | Laptop (ThinkPad P14s Gen 4) | AMD Ryzen 7 PRO 7840U (16T, 5.13 GHz) | AMD Radeon 780M | Integrated | 11 GB | CachyOS / 6.19.3-2 | fish 4.5.0 | 14" 1920x1200 | Colleague onboarding. No CUDA. Cockpit :9090. |

---

## Pipeline Architecture

Document your pipeline here. Include: stages, tools, inputs, outputs, runtime.

---

## Technology Radar

Run your own radar at project close. Score tools on 5 axes: architecture fit, cost model, token efficiency, integration path, breadth. Rate as Adopt (>=4.0), Trial (3.0-3.9), Assess (2.0-2.9), Hold (<2.0).
