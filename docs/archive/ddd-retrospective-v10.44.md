# TripleDB - Retrospective v10.44

## 43 Iterations, 10 Phases, 9 Pillars

**Author:** Claude Code (Opus 4.6) executing Pillar 9 archive review
**Date:** March 28, 2026
**Scope:** v0.7 through v9.43 (all archived artifacts)
**Data Sources:** 29 reports, 27 build logs, design doc iteration history, comparison tables in v4.13 and v5.14 reports

---

## 1. Intervention Timeline

### Full Timeline

| Iter | Phase | Executor | Interventions | Sudo | Self-Heal | Category | Notes |
|------|-------|----------|---------------|------|-----------|----------|-------|
| v0.7 | 0 - Setup | Gemini CLI | Unknown | 0 | 0 | - | No archived report |
| v1.8 | 1 - Discovery | Gemini CLI | Multiple | 0 | 0 | Environment, LLM | Failed: Nemotron 42GB on 8GB VRAM, timeout loops |
| v1.9 | 1 - Discovery | Gemini CLI | Multiple | 0 | 0 | LLM | Failed: Qwen 3.5-9B too slow for structured extraction |
| v1.10 | 1 - Discovery | Gemini CLI | ~10 | 0 | 0 | Environment | Gemini Flash API solved extraction. CUDA path issues. |
| v2.11 | 2 - Calibration | Gemini CLI | 20+ | 0 | 1-2 | Environment | CUDA LD_LIBRARY_PATH must be shell-level, not Python |
| v3.12 | 3 - Stress Test | Gemini CLI | 0 | 0 | 1 | - | First zero-intervention. Auto-healed batch swap. |
| v4.13 | 4 - Validation | Gemini CLI | 0 | 0 | 1 | - | Prompts locked. Group B green-lit. |
| v5.14 | 5 - Production | Gemini CLI | 0 | 0 | 0 | - | Runner infra, null-name fix |
| v5.15 | 5 - Production | Gemini CLI | Unknown | 0 | 0 | - | 14-hour unattended tmux run. No archived report. |
| v6.26 | 6 - Firestore | Gemini CLI | 2 | 0 | 0 | Environment | Firebase re-auth + hung flutterfire process |
| v6.27 | 6 - Geolocation | Gemini CLI | Unknown | 0 | 0 | Frontend | Reverted in v6.28 - broke Firestore |
| v6.28 | 6 - Geocoding | Gemini CLI | Unknown | 0 | 0 | - | 916/1,102 geocoded |
| v6.29 | 6 - Polish | Gemini CLI | 0 | 0 | 0 | - | State count fix, clustering |
| v7.30 | 7 - Enrichment | Gemini CLI | 0 | 0 | 0 | - | Discovery batch: 50 restaurants |
| v7.31 | 7 - Enrichment | Gemini CLI | 1 | 0 | 0 | API | Missing GOOGLE_PLACES_API_KEY |
| v7.32 | 7 - Enrichment | Gemini CLI | 0 | 0 | 0 | - | Refined search + LLM verification |
| v7.33 | 7 - Enrichment | Gemini CLI | 0 | 0 | 0 | - | AKA names, checkpointing |
| v7.34 | 7 - Enrichment | Gemini CLI | 0 | 0 | 2 | - | Cookie consent, analytics. 2 self-heals. |
| v8.17 | 8 - Flutter | Gemini CLI | Unknown | 0 | 0 | - | Pass 1 batch (v8.17-v8.21). No individual reports for v8.17-v8.20. |
| v8.18 | 8 - Flutter | Gemini CLI | Unknown | 0 | 0 | - | Part of Pass 1 batch |
| v8.19 | 8 - Flutter | Gemini CLI | Unknown | 0 | 0 | - | Part of Pass 1 batch |
| v8.20 | 8 - Flutter | Gemini CLI | Unknown | 0 | 0 | - | Part of Pass 1 batch |
| v8.21 | 8 - Flutter | Gemini CLI | 0 | 0 | 0 | - | QA pass. Fixed null handling in models. |
| v8.22 | 8 - Flutter | Gemini CLI | 0 | 0 | 0 | - | Discovery. Firecrawl cert errors (worked around). |
| v8.23 | 8 - Flutter | Gemini CLI | 0 | 0 | 0 | - | Synthesis (doc-only, no code) |
| v8.24 | 8 - Flutter | Gemini CLI | 0 | 0 | 0 | - | Implementation. Theme + design tokens. |
| v8.25 | 8 - Flutter | Gemini CLI | 0 | 0 | 0 | - | QA Pass 2. Lighthouse A11y 92, SEO 100. |
| v9.35 | 9 - Optimization | Claude Code | 0 | 0 | 0 | - | Riverpod 2->3, geolocator 10->14, 70+ trivia |
| v9.36 | 9 - Optimization | Claude Code | 0 | 0 | 0 | - | White screen crash fix (lazy init, deferred DOM) |
| v9.37 | 9 - Optimization | Claude Code | 0 | 0 | 0 | - | Post-flight protocol v1 established |
| v9.38 | 9 - Optimization | Claude Code | 0 | 0 | 0 | - | Cookie banner fix (Secure flag, RFC 1123) |
| v9.39 | 9 - Optimization | Claude Code | 0 | 0 | 0 | - | 3 bug fixes: Unknown filter, dedup, location consent |
| v9.40 | 9 - Optimization | Claude Code | 0 | 0 | 0 | - | dart:html -> package:web. Firestore rules. |
| v9.41 | 9 - Optimization | Claude Code | 0 | 0 | 0 | - | Nine Pillars methodology update |
| v9.42 | 9 - Optimization | Claude Code | 0 | 0 | 0 | - | Hardening audit: 7 fixed, 5 deferred |
| v9.43 | 9 - Optimization | Claude Code | 0 | 0 | 0 | - | Package upgrades, 151 trivia, prefs->location |

### Intervention Analysis

**Total known interventions:** ~36 across 43 iterations
- v1.8: Multiple (failed iteration)
- v1.9: Multiple (failed iteration)
- v1.10: ~10
- v2.11: 20+
- v6.26: 2
- v7.31: 1

**Interventions by phase:**

| Phase | Iterations | Total Interventions | Avg per Iteration |
|-------|-----------|-------------------|-------------------|
| 0 - Setup | 1 | Unknown | - |
| 1 - Discovery | 3 | ~10 + multiple (2 failed) | High |
| 2 - Calibration | 1 | 20+ | 20+ |
| 3 - Stress Test | 1 | 0 | 0 |
| 4 - Validation | 1 | 0 | 0 |
| 5 - Production | 2 | 0 | 0 |
| 6 - Firestore | 4 | 2 | 0.5 |
| 7 - Enrichment | 5 | 1 | 0.2 |
| 8 - Flutter | 9 | 0 | 0 |
| 9 - Optimization | 9 | 0 | 0 |

**Trend:** Interventions front-loaded in Phases 1-2 (environment + LLM selection). After v3.12 established zero-intervention, only 3 interventions across 30+ remaining iterations. Phase 9 (Claude Code) achieved a perfect 9-iteration zero-intervention streak.

**Zero-intervention norm:** Established at v3.12 (iteration 5 of 43). Only 3 interventions after that point (v6.26: 2 infrastructure, v7.31: 1 API key).

**Category breakdown:**
- Environment: ~32 (CUDA paths, npm permissions, Firebase auth, hung processes)
- LLM: ~4 (wrong model selection for hardware in v1.8, v1.9)
- API: 1 (missing API key in v7.31)
- Frontend: 0 (all frontend issues self-healed or resolved autonomously)

**Key insight:** 89% of all interventions occurred in Phase 1-2 and were environment-related. Once the environment was stable, the pipeline was essentially autonomous.

---

## 2. Tool Efficacy Matrix

### Primary Tools

| Tool | First Used | Last Used | Iterations | Avg Workload | Efficacy | Notable Issues |
|------|-----------|----------|------------|-------------|---------|----------------|
| Gemini CLI | v0.7 | v8.25 | ~25 | 80-100% | High | v1.8-v1.9 failures were LLM choice, not CLI |
| Claude Code (Opus) | v9.35 | v9.43 | 9 | 60-100% | High | 0 interventions across 9 iterations |
| Gemini 2.5 Flash API | v1.10 | v7.34 | ~15 | 20-40% | High | Free tier, 1M context, solved extraction |
| faster-whisper (CUDA) | v1.8 | v5.15 | ~8 | 30-50% | High | CUDA LD_LIBRARY_PATH gotcha, otherwise reliable |
| yt-dlp | v0.7 | v5.15 | ~8 | 10-20% | High | 600s timeout for long videos, no other issues |
| Google Places API (New) | v7.30 | v7.33 | 4 | 20-30% | High | 582 verified enrichments at $0 cost |
| Firebase Admin SDK | v6.26 | v7.34 | ~8 | 10-20% | High | No issues after initial auth fix |
| Nominatim | v6.28 | v7.30 | 3 | 15-20% | High | 1 req/sec rate limit, 94.6% success |
| tmux + bash | v5.14 | v5.15 | 2 | 50% | High | 14-hour unattended run succeeded |
| Flutter SDK | v8.17 | v9.43 | 18 | 30-50% | High | 0 analyze errors maintained throughout |

### Testing Tools

| Tool | First Used | Last Used | Iterations | Avg Workload | Efficacy | Notable Issues |
|------|-----------|----------|------------|-------------|---------|----------------|
| Puppeteer (npm) | v9.37 | v9.43 | 7 | 15-30% | High | /tmp local install pattern when global unavailable |
| Playwright MCP | v9.37 | v9.42 | ~4 | 0-15% | Low | System deps missing, consistently skipped |
| Lighthouse CLI | v9.42 | v9.43 | 2 | 10-15% | Medium | Flutter canvas limits FCP/LCP scoring |
| Context7 MCP | v9.35 | v9.43 | 9 | 0-5% | Medium | Available but rarely invoked |

### Deprecated/Failed Tools

| Tool | Iterations | Reason for Failure |
|------|-----------|-------------------|
| Nemotron 3 Super (120B) | v1.8 | 42GB model on 8GB VRAM = timeout loops |
| Qwen 3.5-9B (Ollama) | v1.9 | Too slow for structured extraction |
| Firecrawl | v8.22 | Certificate errors on all target sites |

### Key Insights

1. **Highest efficacy-per-cost:** Gemini 2.5 Flash API. Free tier, solved the core extraction problem that local LLMs couldn't handle. Zero API cost across ~15 iterations.

2. **Most friction:** Local LLM inference (v1.8-v1.9). The VRAM constraint on the RTX 2080 SUPER made large models unusable. This was the single biggest source of early interventions.

3. **Adopted but underutilized:** Playwright MCP and Context7 MCP. Playwright was consistently blocked by system deps. Context7 was available but Claude Code rarely needed external Flutter docs.

4. **Recommended stack for next project:** Claude Code (Opus) for dev, Gemini CLI for batch execution, Gemini 2.5 Flash for API tasks, Puppeteer for testing. Skip Playwright MCP and local LLM inference unless VRAM >= 16GB.

---

## 3. Pillar Evolution

### Timeline

| Version | Iteration | Pillar Count | Changes | Trigger |
|---------|-----------|-------------|---------|---------|
| v1 | v3.12 | 6 | Initial: Artifact Loop, Orchestration, Zero-Intervention, Pre-Flight, Self-Healing, Progressive Batching | First zero-intervention iteration proved the methodology worked |
| v2 | v5.14 | 8 | Added: Post-Flight Testing (Pillar 7), Continuous Improvement (Pillar 8) | Production run needed formal testing and retrospective mechanisms |
| v3 | v9.41 | 9 | Added: Mobile-First Flutter/Firebase (Pillar 8). Renumbered CI to Pillar 9. | Phase 8-9 proved Flutter/Firebase was a core architectural decision, not just implementation |
| v3.1 | v9.42 | 9 | Tier 3 hardening added to Post-Flight. 5th artifact (changelog) added to Artifact Loop. | Hardening audit revealed need for formal security tier. Changelog corruption risk. |
| v3.2 | v9.43 | 9 | Sudo exception. Package upgrade policy. Browser targets locked (Chrome Stable + Firefox ESR). | v9.42 sudo friction. Package upgrades needed governance. |
| v3.3 | v10.44 | 9 | Em-dash rule. Retrospective framework formalized. GEMINI.md template. | UAT handoff prep. AI-generated text tells. |

### Analysis

**What triggered each evolution:**
- v1 (6 pillars): Organic - the methodology was implicit in the first 5 iterations, then documented when v3.12 achieved zero-intervention
- v2 (8 pillars): Need-driven - production batches (v5.15) needed crash recovery and quality gates that didn't exist in the methodology
- v3 (9 pillars): Recognition - Flutter/Firebase wasn't just an implementation choice, it was an architectural constraint (zero-cost, single codebase) that shaped every decision
- v3.1-v3.3: Refinement - each iteration surfaced edge cases (sudo, packages, formatting) that the methodology didn't cover

**Redundancy check:** No redundant pillars. Pre-Flight (4) and Post-Flight (7) are complementary, not overlapping - one validates inputs, the other validates outputs.

**Gap analysis:**
- **Observability:** No pillar covers monitoring after deployment. Firebase Analytics is configured but no alerting or dashboard governance exists.
- **Rollback:** Self-Healing covers execution errors but not "the deploy is bad, roll back." v6.27 was manually reverted - no documented rollback procedure.
- **Multi-agent coordination:** Pillar 2 assumes single-agent-primary. If UAT runs Gemini CLI while dev runs Claude Code simultaneously, there's no conflict resolution.

**Portability to other projects:** The Nine Pillars are project-agnostic except Pillar 8 (Mobile-First Flutter/Firebase). For a non-Flutter project (e.g., SOC Alpha), Pillar 8 would become "Platform Constraints" - whatever the project's non-negotiable architectural decisions are.

---

## 4. Plan Quality Analysis

### Iteration Classification

**Clean (0 interventions, 0 self-heal):**
v5.14, v6.29, v7.30, v7.32, v7.33, v8.21-v8.25, v9.35-v9.43

**Self-healed (0 interventions, >0 self-heal):**
v2.11 (1-2 self-heals), v3.12 (1 batch swap), v4.13 (1 re-extraction), v7.34 (2 self-heals)

**Intervention-required (>0 interventions):**
v1.10 (~10), v6.26 (2), v7.31 (1)

**Failed (did not achieve goal):**
v1.8 (Nemotron VRAM), v1.9 (Qwen too slow)

### Patterns in Good Plans

1. **Environment fully specified:** Clean iterations had all paths, keys, and versions documented. No "figure it out at runtime."
2. **Progressive scope:** Plans that started with a small test batch (v3.12: 30 videos, v7.30: 50 restaurants) before full runs had 0 interventions.
3. **Explicit error responses:** Plans that documented "if X fails, do Y" (e.g., v9.42 Puppeteer /tmp fallback) self-healed without intervention.
4. **Binary success criteria:** "flutter analyze: 0 issues" is testable. "App works well" is not.
5. **Post-flight automation:** Plans with specific Puppeteer test scripts caught regressions before the report was written.

### Patterns in Bad Plans

1. **Hardware assumptions:** v1.8 assumed 8GB VRAM could run 42GB model. No pre-flight VRAM check.
2. **Missing API keys:** v7.31 needed GOOGLE_PLACES_API_KEY but the plan didn't include a pre-flight validation step.
3. **Implicit environment state:** v1.10 and v2.11 assumed CUDA paths were set. They weren't.
4. **No fallback strategy:** v1.8 and v1.9 had no "if the model doesn't fit, try this instead."

### IAO Plan Quality Checklist

```
[ ] All environment variables documented with exact names and expected values
[ ] All tool versions pinned (not "latest")
[ ] Hardware requirements validated (VRAM, disk, RAM) with pre-flight check
[ ] API keys validated in pre-flight (not just "set as needed")
[ ] Every likely error has a documented response (if X, then Y)
[ ] Batch size starts small and graduates (30 -> 60 -> 90 -> full)
[ ] Success criteria are binary and automatable (pass/fail, not subjective)
[ ] Post-flight tests are specific scripts, not "verify it works"
[ ] Rollback procedure documented for destructive steps
[ ] Checkpoint strategy defined for long-running operations
[ ] Self-heal budget specified (max 3 attempts per error)
[ ] Previous iteration's report reviewed for gotchas to carry forward
[ ] All file paths are absolute or relative to documented root
[ ] Secret scan included in pre-flight
```

---

## 5. Failure Mode Catalog

| ID | Category | Description | Iterations | Root Cause | Resolution | Prevention |
|----|----------|-------------|------------|-----------|-----------|-----------|
| F1 | Environment | CUDA LD_LIBRARY_PATH not set at shell level | v1.10, v2.11 | Set in Python script but faster-whisper reads it at load time | Set in fish config: `set -x LD_LIBRARY_PATH /usr/lib/cuda/lib64` | Pre-flight checklist item |
| F2 | LLM | Nemotron 3 Super 120B on 8GB VRAM | v1.8 | Model size (42GB) exceeds GPU memory (8GB) | Switched to Gemini Flash API | Pre-flight VRAM check. Progressive model sizing. |
| F3 | LLM | Qwen 3.5-9B too slow for structured extraction | v1.9 | Small model can't reliably produce structured JSON from long transcripts | Switched to Gemini Flash API | Benchmark model on small batch before committing |
| F4 | Environment | npm global install needs sudo on Arch Linux | v9.42 | System npm prefix requires root | `/tmp` local install pattern | Sudo exception policy. Document in design doc Section 4. |
| F5 | Environment | Firebase CLI auth expired | v6.26 | Token expiry during long iteration gap | `firebase login --reauth` | Pre-flight auth validation |
| F6 | Environment | Hung flutterfire process | v6.26 | Lost terminal session left process running | Manual kill | Pre-flight: check for orphan processes |
| F7 | API | Missing GOOGLE_PLACES_API_KEY | v7.31 | Key not exported before pipeline run | Human provided key | Pre-flight key validation step |
| F8 | Frontend | White screen crash on app load | v9.36 | Riverpod 3.x eager provider initialization + DOM access before runApp() | Lazy init pattern, deferred DOM access | Migration checklist for major package upgrades |
| F9 | Frontend | Cookie banner broken (Secure flag on HTTP) | v9.38 | `Secure` cookie attribute rejected on localhost HTTP | RFC 1123 expires format, conditional Secure flag | Test on both HTTP and HTTPS during post-flight |
| F10 | Frontend | Geolocation fix broke Firestore data | v6.27 | Code change had unintended side effect on data layer | Full revert in v6.28 | Isolate data-layer changes from UI changes |
| F11 | Pipeline | False positive enrichment matches | v7.32 | Name similarity matching too loose | LLM verification pass (Gemini Flash) removed 126 false positives | Two-pass verification: algorithmic match + LLM confirm |
| F12 | Pipeline | Null-name restaurants merged incorrectly | v5.14 | Empty/null names grouped as "same restaurant" by dedup | Filter null names before dedup | Input validation before normalization |
| F13 | Pipeline | Marathon video timeouts | v1.10, v3.12, v4.13 | 4+ hour videos exceed extraction timeout | Background execution with polling, 600s signal.alarm | Timeout budget based on video duration |
| F14 | Testing | Playwright MCP system deps missing | v9.37-v9.42 | Arch Linux doesn't ship Playwright browser deps | Skipped, used Puppeteer instead | Puppeteer primary. Playwright fallback only. |
| F15 | Testing | Puppeteer module not found (global) | v9.42 | npm global path not in Node module resolution | `/tmp` local install: `cd /tmp && mkdir test && npm init -y && npm install puppeteer` | Document fallback pattern in design doc |
| F16 | Methodology | Changelog count not verified | v9.41 | No post-flight check for changelog entry count | Added >= 29 threshold check | Post-flight Tier 1: `grep -c '^\*\*v' README.md` |
| F17 | Pipeline | Empty extractions (no restaurant data) | v1.10, v3.12, v4.13 | Compilation videos with no clear restaurant segments | Accept as edge case, skip | Classify video types in manifest |
| F18 | Frontend | Trivia text overlap on mobile | v8.25 | Fixed-size containers on small viewports | Responsive layout fix | Test at 375px width in post-flight |
| F19 | Environment | GPU contention (stuck Python process) | v3.12 | Previous transcription process not cleaned up | Kill orphan PIDs before batch start | Pre-flight: `pkill -f faster-whisper` |

### Category Summary

| Category | Count | Peak Phase | Status |
|----------|-------|-----------|--------|
| Environment | 6 (F1, F4, F5, F6, F15, F19) | Phase 1-2 | Mitigated by pre-flight checklist |
| LLM | 2 (F2, F3) | Phase 1 | Resolved by switching to API |
| API | 1 (F7) | Phase 7 | Mitigated by pre-flight key check |
| Frontend | 4 (F8, F9, F10, F18) | Phase 6, 8-9 | Mitigated by post-flight testing |
| Pipeline | 4 (F11, F12, F13, F17) | Phase 1-5, 7 | Mitigated by progressive batching + verification |
| Testing | 2 (F14, F15) | Phase 9 | Mitigated by Puppeteer-primary policy |
| Methodology | 1 (F16) | Phase 9 | Mitigated by threshold checks |

---

## 6. Top 10 Lessons Learned

### Lesson 1: Progressive Batching Prevents Catastrophic Failures

**Evidence:** v1.8 (failed at 30 videos), v3.12 (succeeded at 90 with zero interventions), v5.15 (succeeded at 805 unattended)
**Impact:** Without progressive batching, the first production run would have been 805 videos with untested prompts and an unstable CUDA setup. Every failure would have been at scale.
**Rule:** Never run the full dataset first. Graduate through 30 -> 60 -> 90 -> 120 -> full. Each batch must achieve zero interventions before the next.

### Lesson 2: The Plan IS the Permission - Interventions Measure Plan Quality

**Evidence:** v2.11 (20+ interventions, plan assumed CUDA worked), v3.12 (0 interventions, plan documented every path). v9.35-v9.43 (9 consecutive zero-intervention iterations).
**Impact:** Every intervention is a plan gap. Tracking interventions created a feedback loop that improved plan quality over time.
**Rule:** Count interventions. Zero is the target. If interventions > 0, the failure is in the plan, not the agent.

### Lesson 3: Local LLM Inference is Free but VRAM is the Hard Constraint

**Evidence:** v1.8 (Nemotron 42GB on 8GB VRAM), v1.9 (Qwen 9B too slow). API-based Gemini Flash solved it at $0.
**Impact:** Two failed iterations and multiple interventions before discovering that "free local inference" was more expensive in time than "free tier API inference."
**Rule:** Check VRAM before selecting a local model. If model_size > 0.8 * VRAM, use an API. Free-tier APIs (Gemini Flash) are genuinely free and more reliable.

### Lesson 4: Post-Flight Must Test Behavior, Not Appearance

**Evidence:** v9.37 (established Puppeteer protocol), v9.38 (caught cookie bug via a11y tree), v8.25 (Lighthouse caught SEO metadata gap)
**Impact:** Screenshot-based testing would have missed the cookie Secure flag issue, the white screen race condition, and the a11y tree structure. Behavioral testing caught all three.
**Rule:** Use accessibility tree inspection and DOM state assertions. Never rely on visual screenshots for automated testing. Puppeteer + a11y tree is the correct primitive.

### Lesson 5: Changelog Resilience Requires Redundancy

**Evidence:** v9.41 (changelog count check added), v9.42 (versioned changelog copies introduced after near-truncation)
**Impact:** A single README changelog is a single point of failure. One bad agent run could truncate 28 entries of project history.
**Rule:** After every iteration: (1) append to README, (2) copy to `docs/ddd-changelog-v{P}.{I}.md`, (3) verify count >= threshold. Three redundant copies.

### Lesson 6: Cookie and Consent Systems Are Multi-Iteration Debugging Sagas

**Evidence:** v7.34 (initial cookie consent), v9.38 (Secure flag + RFC 1123 + fragile parsing fix), v9.39 (Accept All async race condition)
**Impact:** What should have been a simple GDPR banner took 3 iterations across 2 phases. Each fix exposed a deeper issue: first the Secure flag, then the date format, then the async race.
**Rule:** Cookie/consent implementations touch HTTP headers, browser security policy, async state management, and legal compliance simultaneously. Budget 2-3 iterations, not 1.

### Lesson 7: Agent Executor Choice Matters Less Than Plan Quality

**Evidence:** Gemini CLI (v0.7-v8.25): 0-20+ interventions depending on plan. Claude Code (v9.35-v9.43): 0 interventions with tight plans. Both achieved zero-intervention when plans were good.
**Impact:** The temptation is to attribute success to the "better" agent. But Gemini CLI achieved zero-intervention at v3.12 and Claude Code achieved it from v9.35. The common factor was plan quality.
**Rule:** Invest in plan quality over agent selection. A good plan makes any capable agent succeed. A bad plan makes any agent fail.

### Lesson 8: Free-Tier at Scale is Possible but Requires Disciplined Tool Selection

**Evidence:** 43 iterations, 1,102 restaurants, 582 enriched, live app at tripledb.net - total cost: $0.
**Impact:** Every tool in the stack was selected for its free tier: Gemini Flash API, Google Places API, Nominatim, Firebase Spark, local CUDA transcription.
**Rule:** Start with the cost constraint and select tools that fit. Don't select tools and hope the cost works out. Free-tier viability must be validated in the discovery phase (Phase 1).

### Lesson 9: Security Hardening is a Quick Win When Done via Configuration

**Evidence:** v9.42 (7 security findings fixed in a single iteration via firebase.json headers: CSP, HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy)
**Impact:** All 7 security headers were configuration changes in firebase.json. No application code modified. The entire hardening audit ran autonomously with zero interventions.
**Rule:** Prioritize configuration-level security (HTTP headers, firestore.rules) over application-level security. It's faster, less risky, and easier to audit.

### Lesson 10: The Methodology Must Evolve - Static Processes Atrophy

**Evidence:** Pillars: 6 (v3.12) -> 8 (v5.14) -> 9 (v9.41). Sub-versions: v3.1 (v9.42), v3.2 (v9.43), v3.3 (v10.44). Each evolution was triggered by a real gap.
**Impact:** If the methodology had stayed at 6 pillars, there would be no post-flight testing (bugs in production), no changelog resilience (data loss risk), no sudo exception (blocked iterations).
**Rule:** Review and update the methodology at project milestones, not just at project close. Each phase should ask: "What did we learn that the methodology doesn't capture yet?"

---

## 7. Recommendations for Phase 10 Track B (Technology Radar)

Based on the retrospective data, the Technology Radar (v10.45) should prioritize:

1. **Local LLM re-evaluation on ThinkStation P3 Ultra (16GB VRAM):** v1.8-v1.9 failed on 8GB VRAM. The P3 Ultra has 16GB. Models that were impossible on NZXTcos may now be viable. Test OpenClaw/NemoClaw against Gemini Flash on extraction quality.

2. **Claude Code vs. Gemini CLI head-to-head:** Both achieved zero-intervention but on different task types. Claude Code handled complex debugging (v9.36 white screen, v9.38 cookies). Gemini CLI handled batch execution (v5.15 production run). The radar should score each on their demonstrated strengths.

3. **Puppeteer vs. Playwright re-evaluation:** Playwright MCP was consistently blocked by system deps. Either fix the deps or drop Playwright entirely. Don't carry a "fallback" that never works.

4. **MCP server triage:** Context7 was available for 9 iterations but rarely invoked. Either demonstrate its value in a benchmark or remove it from the stack.

5. **Ruflo/swarm architecture assessment:** 25K stars, 313 MCP tools. The question isn't "is it impressive" - it's "does it fit IAO's single-agent-primary model?" Score on Architecture Fit axis.

6. **Cost model validation:** Verify that Gemini Flash free tier still holds at the scale UAT will require. Check if Google Places API free tier has changed.
