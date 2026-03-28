# TripleDB - Technology Radar v10.45

**Author:** Claude Code (Opus 4.6)
**Date:** March 28, 2026
**Data Sources:** 44-iteration archive review (v10.44 retrospective), 14-tool efficacy matrix, 19 failure modes, 10 lessons learned
**Scope:** 13 tools evaluated across 5 axes for continued use in TripleDB and broader TachTech projects

---

## Methodology

Each tool scored on five axes with empirically-derived weights:

| Axis | Weight | What It Measures |
|------|--------|-----------------|
| Architecture Fit | 0.30 | How well the tool fits IAO's single-agent-primary, plan-driven iteration model |
| Cost Model | 0.25 | Total cost of ownership including free-tier viability at scale |
| Token Efficiency | 0.20 | Context window consumption per invocation; overhead on LLM context budget |
| Integration Path | 0.15 | Time-to-working from current state; compatibility with existing stack |
| TachTech Breadth | 0.10 | Applicability across TachTech's project portfolio (TripleDB, SOC Alpha, client engagements) |

**Scoring:** 1 = poor fit, 2 = marginal, 3 = acceptable, 4 = good, 5 = excellent.
**Weighted total:** (Arch x 0.30) + (Cost x 0.25) + (Tokens x 0.20) + (Integ x 0.15) + (Breadth x 0.10) = composite score out of 5.0.
**Rating thresholds:** Adopt (>= 4.0), Trial (3.0-3.9), Assess (2.0-2.9), Hold (< 2.0).

---

## Category A: Agent Orchestration Frameworks

### Ruflo (ruvnet/ruflo)

| Axis | Score | Rationale |
|------|-------|-----------|
| Architecture Fit | 2/5 | Swarm/hive-mind model with queen/worker topology. IAO uses single-agent-primary (Lesson 7: agent choice matters less than plan quality). Overkill for TripleDB. Could fit SOC Alpha multi-agent threat hunting. |
| Cost Model | 5/5 | Open source, MIT license. npm package. $0. |
| Token Efficiency | 3/5 | Swarm coordination overhead - queen agent + N workers consume more tokens than single agent. Token routing (cheap model for simple tasks) is a genuine feature. |
| Integration Path | 4/5 | npm package, MCP server available, Claude Code compatible. `npx ruflo@latest init` works today. |
| TachTech Breadth | 3/5 | Relevant for SOC Alpha (multi-agent security ops). Overkill for TripleDB and simple SIEM engagements. |

**Composite: 3.20 | Rating: Trial**

**Retrospective evidence:** IAO achieved 9 consecutive zero-intervention iterations (v9.35-v9.43) with single-agent Claude Code. Lesson 7 confirmed that plan quality, not agent topology, drives success. Queen/worker swarm adds coordination overhead with no demonstrated benefit for plan-driven iteration work.

**Cost analysis:** $0 across 44 iterations of single-agent execution. Ruflo adds $0 for the framework itself but would increase per-iteration token spend for queen-worker coordination messages.

**Action:** POC on SOC Alpha. Evaluate queen/worker topology for parallel threat hunting agents. Do NOT adopt for TripleDB - single-agent IAO is sufficient.

---

### Claude Skills / CLAUDE.md Optimization

| Axis | Score | Rationale |
|------|-------|-----------|
| Architecture Fit | 5/5 | Native to Claude Code. CLAUDE.md IS the IAO version lock. Skills extend it with structured capabilities. |
| Cost Model | 5/5 | Built into Claude Code subscription. $0 incremental. |
| Token Efficiency | 4/5 | Skills load on-demand, not always in context. Reduces CLAUDE.md bloat. |
| Integration Path | 5/5 | Already using CLAUDE.md. Skills are a natural extension. |
| TachTech Breadth | 4/5 | Every TachTech project uses CLAUDE.md. Skills are portable. |

**Composite: 4.70 | Rating: Adopt**

**Retrospective evidence:** CLAUDE.md evolved from a simple version lock (v0.7) to a 20-line control plane (v10.44) with CAN/CANNOT permissions, formatting rules, and plan quality references. Skills are the next evolution - packaging pre-flight, post-flight, and changelog verification as reusable invocable units.

**Cost analysis:** $0. CLAUDE.md is read once per conversation. Skills load only when invoked.

**Action:** Package IAO pillars as Claude Skills for v10.46. Pre-flight, post-flight, and changelog verification become reusable skill files.

---

### Gemini CLI Skills

| Axis | Score | Rationale |
|------|-------|-----------|
| Architecture Fit | 4/5 | GEMINI.md mirrors CLAUDE.md. Skills would extend UAT execution model. |
| Cost Model | 5/5 | Free tier. |
| Token Efficiency | 3/5 | Gemini's context management is less efficient than Claude's for long plans. |
| Integration Path | 3/5 | GEMINI.md exists but skill ecosystem is less mature than Claude's. |
| TachTech Breadth | 2/5 | Only used for UAT. Not primary dev tool. |

**Composite: 3.65 | Rating: Trial**

**Retrospective evidence:** Gemini CLI executed 25 iterations (v0.7-v8.25) with high efficacy when plans were good (Lesson 7). The skill system could reduce GEMINI.md complexity for UAT auto-chain execution.

**Cost analysis:** $0. Free-tier Gemini CLI usage across all iterations.

**Action:** Evaluate during Phase 10 Track C (UAT). If Gemini CLI supports structured skill loading, adopt for UAT-specific skills.

---

## Category B: LLM Routing & Specialized Models

### NemoClaw / OpenClaw (NVIDIA)

| Axis | Score | Rationale |
|------|-------|-----------|
| Architecture Fit | 2/5 | OpenClaw is an "always-on agent OS" with self-evolving capabilities. IAO uses plan-driven iterations, not always-on agents. NemoClaw adds enterprise security sandbox (OpenShell) - interesting for SOC Alpha. |
| Cost Model | 5/5 | Open source. Nemotron 3 Nano 4B runs locally on P3 Ultra (16GB VRAM). Nemotron 3 Super 120B needs cloud or DGX. |
| Token Efficiency | 3/5 | Local inference = $0 per token. But Nemotron 3 Nano 4B quality for structured extraction is unknown. Retrospective failure F2/F3: local LLMs struggled with structured extraction on 8GB VRAM. |
| Integration Path | 2/5 | Early alpha (announced GTC March 16, 2026 - 12 days ago). "Not production-ready" per NVIDIA. CLI-based, not MCP. Would need custom integration. |
| TachTech Breadth | 4/5 | OpenShell security sandbox directly relevant to TachTech's cybersecurity practice. Policy-based agent governance aligns with enterprise client needs (Cintas, Findlay). |

**Composite: 3.05 | Rating: Trial**

**Retrospective evidence:** Failure modes F2 and F3 (v1.8-v1.9) demonstrated that local LLMs failed on 8GB VRAM. Lesson 3: "If model_size > 0.8 * VRAM, use an API." P3 Ultra has 16GB VRAM - Nemotron 3 Nano 4B (4B params, ~8GB) fits within the 0.8x threshold. Worth benchmarking.

**Cost analysis:** $0 for local inference. But Lesson 3 also showed that "free local inference" can be more expensive in time than "free tier API inference." Must benchmark quality-per-second, not just cost.

**Token comparison:** Local inference eliminates API token costs entirely. Gemini Flash API is also $0 (free tier). The comparison is quality and speed, not cost.

**Action:** Install NemoClaw on P3 Ultra. Run `nemoclaw init --model local:nemotron-3-nano-4b --policy strict`. Benchmark against Gemini Flash on 10 extraction tasks from the TripleDB transcript set. Evaluate OpenShell security sandbox for SOC Alpha agent governance. Do NOT adopt for TripleDB production - too early, too different from IAO.

---

### Claude Sonnet 4.6 (Cost-Optimized Routing)

| Axis | Score | Rationale |
|------|-------|-----------|
| Architecture Fit | 4/5 | Same API as Opus. Route simple tasks (changelog generation, README updates) to Sonnet; keep Opus for complex work. |
| Cost Model | 4/5 | Cheaper per token than Opus. Claude Code subscription is flat-rate for interactive use - cost benefit applies to API calls only. |
| Token Efficiency | 4/5 | Smaller context window than Opus but sufficient for most iteration tasks. |
| Integration Path | 5/5 | Same SDK, same MCP support, same CLAUDE.md format. Zero integration work. |
| TachTech Breadth | 4/5 | Universal - every TachTech project can route by task complexity. |

**Composite: 4.15 | Rating: Adopt**

**Retrospective evidence:** Claude Code (Opus) achieved 9 consecutive zero-intervention iterations but many of those (v9.41 Nine Pillars update, v10.44 retrospective) were documentation-only. Sonnet could handle documentation iterations at lower cost when using API-based sub-agents.

**Cost analysis:** Flat-rate subscription covers interactive Claude Code usage. Cost benefit materializes only for API-based sub-agent tasks or batch processing via the Anthropic API.

**Action:** For API-based sub-agent tasks (batch document generation, structured extraction), route to Sonnet. Keep Opus for primary Dev agent (Claude Code interactive).

---

### Gemini 2.5 Flash (Current)

| Axis | Score | Rationale |
|------|-------|-----------|
| Architecture Fit | 5/5 | Already integrated. 1M context window solved the extraction problem that local LLMs couldn't handle (F2, F3). |
| Cost Model | 5/5 | Free tier. Zero cost across 44 iterations and ~15 extraction-heavy iterations. |
| Token Efficiency | 5/5 | 1M context eliminates transcript chunking. Single-pass extraction. |
| Integration Path | 5/5 | Battle-tested across Phases 1-7. API scripts, extraction prompts, and normalization prompts all locked since v4.13. |
| TachTech Breadth | 3/5 | Useful for extraction/normalization tasks. Less relevant for security ops. |

**Composite: 4.75 | Rating: Adopt**

**Retrospective evidence:** Highest efficacy-per-cost tool in the stack (Retrospective Section 2). Solved the core extraction problem at v1.10 after two failed iterations with local LLMs. Free tier sustained across 773 video extractions, 1,102 normalizations, and 112 LLM verification calls.

**Cost analysis:** $0 actual spend. Free tier confirmed viable at TripleDB's scale (805 videos, 1,102 restaurants). Lesson 8: "Start with the cost constraint and select tools that fit."

**Token comparison:** Single API call per video with full transcript in context (~50K-200K tokens per call). No chunking overhead. Compared to local Qwen 3.5-9B (v1.9) which required multiple chunks and was 10x slower.

**Action:** Continue using. No changes needed. Benchmark against Sonnet for extraction quality if cost-optimization routing is adopted.

---

### Local LLMs (Ollama - Revisit)

| Axis | Score | Rationale |
|------|-------|-----------|
| Architecture Fit | 3/5 | Could replace Gemini Flash for normalization tasks that don't need 1M context. P3 Ultra (16GB VRAM) can run models that failed on NZXT (8GB VRAM). |
| Cost Model | 5/5 | $0. Local inference. |
| Token Efficiency | 4/5 | No API overhead. But local generation speed is slower than API. |
| Integration Path | 4/5 | Ollama installed on both machines. Scripts already have Ollama integration from v1.8-v1.9. |
| TachTech Breadth | 4/5 | Client-site inference for data-sensitive engagements (Cintas, Findlay). No data leaves the network. |

**Composite: 3.85 | Rating: Trial**

**Retrospective evidence:** v1.8 (Nemotron 120B, 42GB on 8GB VRAM - F2) and v1.9 (Qwen 3.5-9B too slow - F3) demonstrated local LLM limitations on NZXT. P3 Ultra's 16GB VRAM reopens the possibility. Lesson 3 applies: validate VRAM fit before committing.

**Cost analysis:** $0 for inference. Hardware cost is sunk (P3 Ultra already owned). The real cost is quality risk - if local models produce lower-quality extractions, the pipeline loses accuracy.

**Action:** On P3 Ultra, benchmark Qwen 3.5-14B and Nemotron 3 Nano 4B against Gemini Flash for normalization-only tasks (not extraction - Flash is locked for extraction). Report quality-per-second metrics.

---

## Category C: MCP Server Ecosystem

### Context7 MCP

| Axis | Score | Rationale |
|------|-------|-----------|
| Architecture Fit | 4/5 | Documentation lookup during execution. Useful for package upgrades, API changes. |
| Cost Model | 5/5 | Free. |
| Token Efficiency | 2/5 | Loads full API docs into context (~5K tokens per lookup). Often not needed - v9.43 upgraded 4 packages (flutter_map, go_router, google_fonts, flutter_map_marker_cluster) without invoking Context7. |
| Integration Path | 5/5 | Already configured in mcp.json. |
| TachTech Breadth | 3/5 | Useful for any Flutter/Dart project. Less relevant for non-Flutter work. |

**Composite: 3.65 | Rating: Trial -> Adopt conditionally**

**Retrospective evidence:** Available across 9 Claude Code iterations (v9.35-v9.43). Efficacy rated "Medium" in the tool matrix (Section 2) with 0-5% average workload. v9.43 package upgrade iteration succeeded without Context7, suggesting it's a safety net rather than a primary tool.

**Cost analysis:** $0. But each invocation consumes ~5K context tokens that could be used for code or plan analysis.

**Action:** Keep configured but don't reference in plans unless package upgrades involve breaking API changes. Agent should try without Context7 first, use it as a self-heal fallback when encountering unfamiliar APIs.

---

### Puppeteer (npm)

| Axis | Score | Rationale |
|------|-------|-----------|
| Architecture Fit | 5/5 | Primary browser testing tool. Battle-tested v9.37-v9.43 with 17+ tests and 0 false negatives. |
| Cost Model | 5/5 | Free. npm package. |
| Token Efficiency | 4/5 | Runs as subprocess, not in LLM context. Script-based execution. |
| Integration Path | 5/5 | npm install (local `/tmp` fallback pattern proven at v9.42 - F15 resolved). Chrome Stable + Firefox ESR support confirmed at v9.43. |
| TachTech Breadth | 4/5 | Any web project needs browser testing. |

**Composite: 4.70 | Rating: Adopt**

**Retrospective evidence:** Established as Pillar 7 (Post-Flight Functional Testing) at v9.37. Caught the cookie Secure flag bug (v9.38 - F9), the Accept All async race (v9.39), and verified all package upgrades (v9.43). Lesson 4: "Post-flight must test behavior, not appearance." Puppeteer + a11y tree is the correct primitive.

**Cost analysis:** $0. Local npm install. The `/tmp` fallback pattern (F15) ensures it works even when global npm is restricted.

**Token comparison:** Puppeteer runs as a subprocess - zero context tokens consumed during test execution. Only the results (PASS/FAIL per gate) enter the LLM context. Compare to Playwright MCP which runs every browser action as an in-context MCP call.

**Action:** Continue as primary. Document the local `/tmp` install pattern in every CLAUDE.md and GEMINI.md.

---

### Playwright MCP

| Axis | Score | Rationale |
|------|-------|-----------|
| Architecture Fit | 3/5 | MCP integration is convenient. But system deps (libwoff1, etc.) fail on CachyOS/Arch. |
| Cost Model | 5/5 | Free. |
| Token Efficiency | 3/5 | MCP calls are in-context, consuming tokens for every browser action. More expensive per test than Puppeteer subprocess. |
| Integration Path | 2/5 | Requires system deps not in standard Arch repos. Consistently skipped across v9.37-v9.42 (F14). WebKit testing skipped entirely due to missing deps. |
| TachTech Breadth | 3/5 | Same capability as Puppeteer but less reliable on Arch-based systems. |

**Composite: 3.05 | Rating: Hold**

**Retrospective evidence:** Failure mode F14 - Playwright MCP system deps missing across 6 iterations (v9.37-v9.42). Tool efficacy rated "Low" in the matrix (Section 2). Never successfully used as primary; always fell back to Puppeteer. Lesson 4 confirms behavioral testing (which Puppeteer handles) is what matters.

**Cost analysis:** $0 for the tool. But every failed Playwright attempt costs 1-2 self-heal cycles, consuming agent time and tokens on dep resolution that never succeeds on CachyOS.

**Action:** Drop from CLAUDE.md. Remove "Playwright MCP: Fallback only" line. Puppeteer covers all browser testing needs. Don't waste agent time debugging Playwright deps.

---

### Lighthouse CLI / MCP

| Axis | Score | Rationale |
|------|-------|-----------|
| Architecture Fit | 4/5 | Performance, accessibility, SEO, and best practices auditing. Critical for hardening iterations (v9.42). |
| Cost Model | 5/5 | Free. `npx lighthouse`. |
| Token Efficiency | 4/5 | Runs as CLI subprocess. JSON output parsed by agent. ~2K tokens for summary results. |
| Integration Path | 4/5 | `npx` works reliably. MCP server available but untested - skip until Playwright dep issue is resolved (same Chromium runtime). |
| TachTech Breadth | 4/5 | Any web project benefits from Lighthouse scoring. |

**Composite: 4.15 | Rating: Adopt**

**Retrospective evidence:** v9.42 hardening audit used Lighthouse CLI to establish baselines: A11y 93, SEO 100, Best Practices 77. Note: Flutter canvas rendering prevents Lighthouse FCP/LCP detection in headless mode - Performance score is N/A for Flutter Web apps.

**Cost analysis:** $0. `npx lighthouse` with no installation required.

**Action:** Keep as `npx` CLI. Add to hardening iteration playbooks. Skip MCP variant until Playwright ecosystem deps are resolved.

---

## Category D: Orchestration Patterns

### Meta/Hyperagent (Agent-of-Agents)

| Axis | Score | Rationale |
|------|-------|-----------|
| Architecture Fit | 3/5 | An orchestrator LLM dispatching to specialized sub-agents. IAO's two-environment model (Dev + UAT) is already a lightweight form of this. Could enhance auto-chaining. |
| Cost Model | 3/5 | Extra orchestrator layer = extra token spend. Justified only if sub-agents are cheaper (Sonnet routing). |
| Token Efficiency | 3/5 | Overhead of orchestrator context + routing decisions. |
| Integration Path | 2/5 | No standard tool. Would need custom implementation. |
| TachTech Breadth | 4/5 | SOC Alpha already uses multi-agent architecture (4 parallel agents). |

**Composite: 2.95 | Rating: Assess**

**Retrospective evidence:** Lesson 7 confirms single-agent IAO works well for TripleDB. The two-environment model (Claude Code dev + Gemini CLI UAT) provides agent specialization without runtime coordination overhead. Multi-agent patterns are relevant for SOC Alpha where 4 parallel threat hunting agents need coordination.

**Cost analysis:** No tool to evaluate. Custom implementation cost is unknown. The overhead of an orchestrator layer must be justified by sub-agent cost savings or parallelism gains.

**Action:** Research further. Table for SOC Alpha. Do not implement for TripleDB.

---

### CLAUDE.md Control Planes (@claude-flow/guidance)

| Axis | Score | Rationale |
|------|-------|-----------|
| Architecture Fit | 4/5 | Ruflo's guidance module structures CLAUDE.md into a compiled control plane with gates, trust scoring, and hash-chained proof. IAO's CLAUDE.md is simpler but effective. |
| Cost Model | 5/5 | Open source. |
| Token Efficiency | 3/5 | Structured control plane adds context overhead. Current CLAUDE.md is ~20 lines and works. |
| Integration Path | 3/5 | npm package. Would require rearchitecting CLAUDE.md format. |
| TachTech Breadth | 3/5 | Useful for long-running agents (SOC Alpha). Overkill for iteration-based IAO. |

**Composite: 3.55 | Rating: Assess**

**Retrospective evidence:** Current CLAUDE.md has evolved from simple version lock to a compact control plane with permissions, formatting rules, and plan quality references. The 14-item plan quality checklist (Retrospective Section 4) achieves similar governance to trust scoring - without the framework overhead.

**Cost analysis:** $0 for the package. But adopting it means rearchitecting CLAUDE.md format - a migration cost measured in agent time, not dollars.

**Action:** Read the @claude-flow/guidance docs. Evaluate the trust scoring concept for SOC Alpha agents that run for days without human review. Don't adopt for IAO - our CLAUDE.md is lean and effective.

---

## Summary Table

| Tool | Rating | Composite | Arch | Cost | Tokens | Integ | Breadth | Action |
|------|--------|-----------|------|------|--------|-------|---------|--------|
| Gemini 2.5 Flash | **Adopt** | 4.75 | 5 | 5 | 5 | 5 | 3 | Continue, no changes |
| Claude Skills | **Adopt** | 4.70 | 5 | 5 | 4 | 5 | 4 | Package IAO pillars as skills |
| Puppeteer | **Adopt** | 4.70 | 5 | 5 | 4 | 5 | 4 | Primary browser testing |
| Claude Sonnet 4.6 | **Adopt** | 4.15 | 4 | 4 | 4 | 5 | 4 | Route simple API tasks |
| Lighthouse CLI | **Adopt** | 4.15 | 4 | 5 | 4 | 4 | 4 | Hardening audits |
| Local LLMs (Ollama) | **Trial** | 3.85 | 3 | 5 | 4 | 4 | 4 | Benchmark on P3 Ultra |
| Context7 MCP | **Trial** | 3.65 | 4 | 5 | 2 | 5 | 3 | Keep, use as self-heal fallback |
| Gemini CLI Skills | **Trial** | 3.65 | 4 | 5 | 3 | 3 | 2 | Evaluate during UAT |
| CLAUDE.md Control Planes | **Assess** | 3.55 | 4 | 5 | 3 | 3 | 3 | Read docs, evaluate for SOC Alpha |
| Ruflo | **Trial** | 3.20 | 2 | 5 | 3 | 4 | 3 | POC for SOC Alpha |
| NemoClaw | **Trial** | 3.05 | 2 | 5 | 3 | 2 | 4 | Install on P3, benchmark |
| Playwright MCP | **Hold** | 3.05 | 3 | 5 | 3 | 2 | 3 | Drop from CLAUDE.md |
| Meta/Hyperagent | **Assess** | 2.95 | 3 | 3 | 3 | 2 | 4 | Research for SOC Alpha |

---

## Recommendations for Track C (UAT Handoff)

### Tools to Include in UAT Configuration (GEMINI.md)

| Tool | Role in UAT |
|------|-------------|
| Gemini 2.5 Flash API | Extraction and normalization (locked prompts) |
| Puppeteer (npm) | Post-flight browser testing |
| Lighthouse CLI | Hardening audit verification |
| tmux | Auto-chain execution runtime |

### Tools to Benchmark on P3 Ultra Before UAT

| Tool | Benchmark Task |
|------|---------------|
| Nemotron 3 Nano 4B (NemoClaw) | 10 extraction tasks vs. Gemini Flash |
| Qwen 3.5-14B (Ollama) | 10 normalization tasks vs. Gemini Flash |

### Changes to GEMINI.md Based on Radar Results

1. **Remove** Playwright MCP reference (Hold rating)
2. **Add** Puppeteer `/tmp` install pattern
3. **Add** Lighthouse CLI for hardening iterations
4. **Reference** Plan Quality Checklist (14 items from retrospective)
5. **Add** tmux as required runtime for auto-chain execution

---

## Radar Methodology Notes

### Why These Weights

The weight distribution (Arch 0.30, Cost 0.25, Tokens 0.20, Integ 0.15, Breadth 0.10) reflects IAO's priorities:

1. **Architecture Fit is heaviest (0.30):** A tool that doesn't fit IAO's single-agent, plan-driven model creates friction regardless of cost. Lesson 7: plan quality > tool choice, but a tool that fights the plan model makes every plan worse.

2. **Cost Model is second (0.25):** Lesson 8: "$0 infrastructure is a design constraint, not an accident." Tools that require paid tiers are disqualified for TripleDB and disadvantaged for TachTech client work.

3. **Token Efficiency is third (0.20):** Context window is a shared resource. Tools that consume tokens for coordination (swarm agents, in-context MCP calls) compete with the plan and code that the agent needs to reason about.

4. **Integration Path is fourth (0.15):** Time-to-working matters. A tool that needs custom integration eats into iteration budget. But a well-fitting tool with moderate integration effort (e.g., Claude Skills) is worth it.

5. **TachTech Breadth is lightest (0.10):** TripleDB is the primary context. Breadth is a tiebreaker, not a driver. A tool that's perfect for TripleDB but useless elsewhere still gets adopted.
