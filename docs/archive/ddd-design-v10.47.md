# TripleDB - Design v10.47

**ADR-001 | Living Architecture Document**
**Last Updated:** Phase 10, Iteration 47 (Template Revision)
**Author:** Kyle Thompson, Managing Partner & Solutions Architect @ TachTech Engineering

---

Sections not revised here (Pillars 1-9, pipeline, data model, app architecture, locked decisions, scripts, repo structure, gotchas, current state) are carried forward from v10.46. This iteration revises the IAO template and UAT design to incorporate Technology Radar recommendations and a reproducible environment setup.

---

# 1. What This Iteration Fixes

The v10.46 IAO template shipped with the TripleDB dev stack only (Claude Code, Gemini CLI, Puppeteer, Gemini Flash). The Technology Radar (v10.45) scored 13 tools and recommended Trial/Adopt actions for several - but none of those recommendations landed in the deliverables.

This iteration fixes that with three additions:

1. **Compatibility Matrix** - layer-by-layer tool options table with pros/cons for each pipeline stage
2. **Requirements Manifest** - exported package lists + install script for reproducible environment setup from a fresh CachyOS machine
3. **Radar-informed tool stack** - OpenClaw, NemoClaw/Nemotron, and Playwright MCP wired into the template as first-class options

---

# 2. Compatibility Matrix

The compatibility matrix is the core addition to the IAO template. New projects select one tool per layer at Phase 0, informed by this matrix. The matrix is opinionated but not prescriptive - projects can mix and match.

## Layer: Orchestration

Manages agent execution, plan reading, artifact generation, and the iteration loop.

| Tool | Type | Cost | Strengths | Weaknesses | Best For |
|------|------|------|-----------|------------|----------|
| `Claude Code (Opus)` | Cloud agent (Anthropic) | Subscription | Complex debugging, self-healing, 1M context. 10 consecutive zero-intervention iterations on TripleDB. | Cloud-dependent. Subscription cost. | Dev: interactive problem-solving, complex refactors |
| `Claude Code (Sonnet)` | Cloud agent (Anthropic) | Subscription (cheaper) | Same capabilities, lower cost per token. Good for routine tasks. | Less capable on complex multi-step debugging. | Dev: routine iterations, documentation, simple fixes |
| `Gemini CLI` | Cloud agent (Google) | Free tier | Free. 25 zero-intervention iterations on TripleDB (v0.7-v8.25). | Less capable at complex debugging than Opus. | UAT: auto-chain batch execution in tmux |
| `OpenClaw` | Local agent framework | Free (OSS) | 188K GitHub stars. Self-evolving. Runs locally. Spawns sub-agents. | Early ecosystem. CVE-2026-25253 (WebSocket vuln). Requires NemoClaw for security. | Multi-agent workflows, always-on agents |
| `NemoClaw (OpenShell)` | Security sandbox for OpenClaw | Free (OSS, NVIDIA) | Policy-based governance. Sandboxed execution. Skill verification. Runs Nemotron locally. | Early alpha (March 2026). Not production-ready. CUDA-optimized. | Enterprise agent governance, security-sensitive projects |

**Recommended combinations:**

| Use Case | Primary | Secondary | Notes |
|----------|---------|-----------|-------|
| Standard IAO project | Claude Code (Opus) | Gemini CLI (UAT) | Proven across 46 iterations |
| Cost-sensitive project | Claude Code (Sonnet) | Gemini CLI (UAT) | Route complex tasks to Opus API |
| Security-sensitive project | Claude Code (Opus) | NemoClaw + OpenClaw | OpenShell sandbox for agent governance |
| Multi-agent project | OpenClaw + NemoClaw | Claude Code (debug) | Swarm topology for parallel tasks |
| Offline/air-gapped | NemoClaw + Nemotron | N/A | Fully local, no cloud dependency |

## Layer: LLM Inference

The model that does extraction, normalization, summarization, and other language tasks.

| Tool | Type | Cost | VRAM Req | Context | Strengths | Weaknesses | Best For |
|------|------|------|----------|---------|-----------|------------|----------|
| `Gemini 2.5 Flash API` | Cloud API (Google) | Free tier | None | 1M tokens | Battle-tested. Free. 1M context eliminates chunking. | Cloud-dependent. Rate limits possible at scale. | Primary extraction/normalization |
| `Nemotron 3 Nano 4B` | Local (NVIDIA) | Free (OSS) | 4-8 GB | ~8K | Fits on most GPUs. Fast inference. | Small context. Lower quality on complex extraction. | Quick local tasks, offline fallback |
| `Nemotron 3 Super 120B` | Local (NVIDIA) | Free (OSS) | 16+ GB | ~32K | High quality. Runs on P3 Ultra (16GB). | Slow on consumer GPUs. Needs quantization for 16GB. | Complex extraction when offline. P3 Ultra benchmarking. |
| `Claude Sonnet API` | Cloud API (Anthropic) | Per-token | None | 200K | High quality. Good at structured output. | Costs money per token. | Verification passes, quality-sensitive tasks |
| `Ollama (local models)` | Local runtime | Free | Varies | Varies | Run any GGUF model. Easy setup. | TripleDB v1.8-v1.9: local models struggled with structured extraction. | Normalization, simple tasks, offline |

**Recommended combinations:**

| Use Case | Primary | Secondary | Notes |
|----------|---------|-----------|-------|
| Standard pipeline | Gemini 2.5 Flash | None | $0, proven across 15 iterations |
| Offline/private data | Nemotron 3 Super (P3 Ultra) | Nemotron 3 Nano (NZXT) | All local, $0 |
| Quality-critical | Gemini 2.5 Flash | Claude Sonnet (verification) | Flash extracts, Sonnet verifies |
| Client-site deployment | Nemotron 3 Nano | Gemini Flash (fallback) | Local-first for data sensitivity |

## Layer: Browser Automation

Testing, scraping, post-flight verification, and agent-driven web interaction.

| Tool | Type | Cost | MCP | Strengths | Weaknesses | Best For |
|------|------|------|-----|-----------|------------|----------|
| `Playwright MCP` | MCP server | Free | Yes | Agent-native. Agent drives browser through MCP calls. Multi-browser (Chromium, Firefox, WebKit). | Requires system deps on Arch (libwoff1, etc). Needs `sudo pacman` to install deps. | Agent-driven browser automation, scraping, MCP-integrated post-flight |
| `Puppeteer (npm)` | npm package | Free | No | Battle-tested (v9.37-v9.43). /tmp fallback pattern. Chrome + Firefox. | Not MCP-native - agent writes scripts, not direct browser calls. No WebKit. | Scripted post-flight testing, error boundary testing |
| `Lighthouse CLI` | npx CLI | Free | Optional | Performance/a11y/SEO scoring. JSON output. | Flutter canvas limits some metrics. | Hardening iterations, Tier 3 audits |

**Recommended combinations:**

| Use Case | Primary | Secondary | Notes |
|----------|---------|-----------|-------|
| MCP-integrated testing | Playwright MCP | Puppeteer (fallback) | Install Playwright deps in requirements manifest |
| Scripted test suites | Puppeteer | Lighthouse (audits) | Proven pattern, /tmp fallback |
| Full hardening | Playwright MCP + Lighthouse | Puppeteer (fallback) | All three for comprehensive coverage |

**Playwright deps on CachyOS/Arch:**

```bash
# Required system packages for Playwright browsers
sudo pacman -S --needed nss at-spi2-core cups libdrm mesa libxkbcommon libxcomposite libxdamage libxrandr pango cairo alsa-lib

# Install Playwright browsers
npx playwright install chromium firefox
```

These must be in the requirements manifest so a junior dev doesn't hit the same deps wall that blocked Playwright in v9.37-v9.42.

## Layer: Data Storage

| Tool | Type | Cost | Strengths | Weaknesses | Best For |
|------|------|------|-----------|------------|----------|
| `Cloud Firestore` | NoSQL (Google) | Free tier (Spark) | Denormalized docs. Real-time sync. Free tier generous. | Vendor lock-in. Complex queries need composite indexes. | Mobile-first apps, real-time data |
| `Supabase (Postgres)` | SQL (OSS) | Free tier | SQL power. Row-level security. Self-hostable. | More complex schema management. | Relational data, complex queries |
| `SQLite (local)` | Local file DB | Free | Zero config. Embedded. | Single-writer. Not cloud-native. | Prototyping, local-first apps, pipeline intermediate storage |
| `Firebase Realtime DB` | JSON tree (Google) | Free tier | Simple. Fast for shallow reads. | Not suitable for complex queries. | Simple key-value, chat-style data |

## Layer: Frontend

| Tool | Type | Cost | Strengths | Weaknesses | Best For |
|------|------|------|-----------|------------|----------|
| `Flutter Web` | Cross-platform (Google) | Free | Single codebase: web + mobile + desktop. | Canvas rendering limits Lighthouse FCP. Large bundle (2.8MB). | Mobile-first apps targeting web + app stores |
| `Next.js` | React framework | Free | SSR/SSG. Excellent Lighthouse scores. Vercel hosting. | Web-only (no native mobile from same codebase). | Content-heavy sites, SEO-critical apps |
| `SvelteKit` | Svelte framework | Free | Small bundle. Fast. | Smaller ecosystem than React. | Performance-critical web apps |

## Layer: Hosting

| Tool | Type | Cost | Strengths | Weaknesses | Best For |
|------|------|------|-----------|------------|----------|
| `Firebase Hosting` | Static CDN (Google) | Free tier | Preview channels. Custom domains. SSL auto. | Static only (no SSR). | Flutter Web, SPAs |
| `Vercel` | Edge hosting | Free tier | SSR support. Git deploy. Edge functions. | Framework-opinionated (Next.js preferred). | Next.js, React apps |
| `Cloudflare Pages` | Static CDN | Free tier | Fast. Workers for edge compute. | Less Firebase integration. | Static sites, JAMstack |

## Layer: Batch Execution

| Tool | Type | Cost | Strengths | Weaknesses | Best For |
|------|------|------|-----------|------------|----------|
| `tmux + bash` | Terminal multiplexer | Free | Session persistence. Crash recovery. 14-hour production run proven. | Manual session management. | Long-running pipeline batches, UAT auto-chain |
| `screen` | Terminal multiplexer | Free | Similar to tmux. | Less feature-rich than tmux. | Legacy systems |
| `nohup + systemd` | System service | Free | Auto-restart. Logging. | More setup than tmux. | Production services, always-on agents |

---

# 3. Requirements Manifest Approach

## The Problem

The v9.43 environment setup section documents packages in prose. A junior dev on a fresh CachyOS machine has to read markdown, copy commands, and hope they don't miss anything. This failed in TripleDB v1.8-v2.11 (89% of interventions were environment-related).

## The Solution

Export the actual installed packages from a working machine into manifest files. New machines install from the manifests. The setup becomes deterministic.

### Manifest Files

```
requirements/
  pacman-native.txt       # pacman -Qqen output (native repo packages)
  pacman-foreign.txt      # pacman -Qqem output (AUR packages)
  aur-packages.txt        # yay -Qqm output
  npm-global.txt          # npm list -g with versions
  pip-packages.txt        # pip freeze output
  flutter-version.txt     # flutter --version
  flutter-doctor.txt      # flutter doctor -v
  fish-config-sanitized.fish  # fish config with API keys redacted
  claude-mcp.json         # Claude Code MCP server config
  gemini-settings.json    # Gemini CLI MCP + settings
  system-info.txt         # hostname, OS, kernel, GPU
  install.fish            # One-shot install script
```

### Export Script

Run `fish export-requirements.fish` on a working machine (NZXTcos, P3, or laptop). Produces the `requirements/` directory. Commit to repo.

### Install Script

A junior dev on a fresh CachyOS machine runs:

```bash
# Clone the project
git clone git@github.com:TachTech-Engineering/{project}.git
cd {project}

# Run the install script
fish requirements/install.fish

# Follow the "Next Steps" output:
# 1. Copy fish config, add API keys
# 2. Copy MCP configs
# 3. Reload shell
# 4. Setup SSH
```

The install script:
1. Installs all pacman packages from manifests
2. Installs yay if missing, then AUR packages
3. Configures Flutter group permissions
4. Installs global npm packages
5. Installs pip packages
6. Downloads Puppeteer browser
7. Runs Flutter doctor
8. Verifies every tool with pass/fail output
9. Prints "Next Steps" for manual items (API keys, SSH)

### Playwright Deps in Manifest

The Playwright system deps that blocked v9.37-v9.42 go into `pacman-native.txt` via the export script. When the install script runs, they're installed alongside everything else. No more "Playwright MCP skipped due to missing deps."

### What the Install Script Does NOT Do

- Does not set API keys (security - manual step)
- Does not configure SSH keys (security - manual step)
- Does not run `sudo` without the user present (the script itself needs sudo for pacman, but the user runs it interactively)
- Does not clone the project repo (chicken-and-egg - the script IS in the repo)

---

# 4. Revised IAO Template Spec

The IAO template (iao-template-design-v0.1.md) is revised to include:

## New Sections

1. **Compatibility Matrix** - full matrix from Section 2 above, integrated into the template as "Section X: Tool Selection"
2. **Requirements Manifest** - the export/install pattern from Section 3, integrated as "Section Y: Environment Setup"
3. **Playwright MCP setup** - system deps, browser install, MCP config, with the CachyOS/Arch-specific commands
4. **OpenClaw/NemoClaw setup** - installation, sandbox creation, Nemotron model download, policy config
5. **Fresh machine walkthrough** - step-by-step from CachyOS ISO to first `claude --dangerously-skip-permissions`

## Revised Quick Start

The 5-command quick start becomes a 7-command quick start for fresh machines:

```bash
# 1. Clone the project (or create new)
git clone git@github.com:TachTech-Engineering/{project}.git
cd {project}

# 2. Install all dependencies from manifests
fish requirements/install.fish

# 3. Configure environment (API keys, SSH)
cp requirements/fish-config-sanitized.fish ~/.config/fish/config.fish
nano ~/.config/fish/config.fish  # Add your API keys
source ~/.config/fish/config.fish

# 4. Configure MCP servers
mkdir -p ~/.config/claude
cp requirements/claude-mcp.json ~/.config/claude/mcp.json

# 5. Verify everything works
flutter analyze && flutter build web && echo "Ready"

# 6. Create CLAUDE.md version lock
printf "# {Project} - Agent Instructions\n\nRead docs/{project}-design-v0.1.md then docs/{project}-plan-v0.1.md" > CLAUDE.md

# 7. Launch
claude --dangerously-skip-permissions
```

## Revised Template Sections (full list)

1. What IAO Is
2. The Nine Pillars (project-agnostic)
3. Compatibility Matrix (tool options per layer)
4. Plan Quality Checklist (14 items from retrospective)
5. Failure Mode Reference (19 modes, condensed)
6. Top 10 Lessons Learned (universal)
7. Environment Setup (requirements manifest approach)
8. Fresh Machine Walkthrough (CachyOS -> first iteration)
9. CLAUDE.md Template
10. GEMINI.md Template
11. Artifact Naming Convention
12. Markdown Formatting Rules
13. Quick Start (7 commands)
14. Placeholder sections (Hardware, Pipeline, Data Model, Technology Radar)

---

# 5. Revised UAT Design Spec

The UAT design doc (ddd-design-uat.md) is revised to include:

1. **Compatibility matrix reference** - the UAT uses specific tools from the matrix (Gemini CLI for orchestration, Gemini Flash for LLM, Puppeteer for testing, tmux for batch execution). The matrix is referenced so Gemini understands the alternatives.
2. **Playwright MCP as option** - if Playwright deps are installed (via requirements manifest), Gemini can use Playwright MCP for browser automation instead of Puppeteer scripts.
3. **Nemotron as offline fallback** - if Gemini Flash API is unreachable (rate limit, network issue), the design doc specifies falling back to Nemotron 3 Nano 4B via Ollama for normalization tasks (not extraction - context window too small).

---

# 6. Markdown Formatting Rules

Unchanged. No em-dashes. Changelog >= 32 after v10.47.

---

# CLAUDE.md Template (v10.47)

```markdown
# TripleDB - Agent Instructions

## Current Iteration: 10.47 (Template Revision)

Revise IAO template + UAT design with compatibility matrix, requirements manifest, OpenClaw/NemoClaw/Playwright integration.

Read in order, then execute:
1. docs/ddd-design-v10.47.md
2. docs/ddd-plan-v10.47.md

## Formatting
- NEVER use em-dashes. Use " - " instead. Use "->" for arrows.

## Rules
- YOLO - code dangerously, never ask permission
- MUST produce revised: iao-template-design-v0.1.md, iao-template-plan-v0.1.md, ddd-design-uat.md
- MUST also produce: ddd-build, ddd-report, ddd-changelog, README update, export-requirements.fish
- POST-FLIGHT: Tier 1 only (no Flutter code changes)
- README changelog: NEVER truncate, ALWAYS append, >= 32. Copy to docs/ddd-changelog-v10.47.md

## Agent Permissions
- CAN: create files in docs/ and repo root
- CANNOT: modify app/ or pipeline/ code, sudo, git add/commit/push
```
