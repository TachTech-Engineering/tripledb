# TripleDB — App Design v8.25

---

# Part 1: IAO × MCP v4 — Flutter Build (Second Pass)

## Phase Mapping

| IAO Iteration | MCP Phase | Focus | Status |
|---|---|---|---|
| v8.22 | 1 — Discovery | Rescrape with Playwright fallback | ✅ Complete |
| v8.23 | 2 — Synthesis | Design tokens, brief, component patterns | ✅ Complete |
| v8.24 | 3 — Implementation | Gap fixes + apply design contract to codebase | ✅ Complete |
| v8.25 | 4 — QA | Lighthouse, Playwright, functional testing | 🔧 Current |

After v8.25, the app is design-complete and validated. Firestore wiring happens once production data is ready.

## Implementation Summary (v8.24)

14 files modified. All 8 component patterns fulfilled. Token coverage 100%. Key changes:
- Full theme rewrite from design-tokens.json (Outfit + Inter, DDD red/orange palette)
- Cuisine emoji placeholders for restaurant images
- Video type badges replacing season/episode
- 3-tab bottom nav (Map / List / Explore) replacing Saved
- ExplorePage with trivia, top states, most visited, cuisine breakdown
- CartoDB dark map tiles with primary-colored pins
- Dark mode toggle via Riverpod

Known issues from v8.24 to validate in QA:
- YouTube deep links depend on data quality (may break on malformed timestamps)
- Directions/Website buttons are no-op (enrichment fields not yet available)
- Map geolocation fallback behavior when permission denied
- Mobile text overflow potential in restaurant cards and detail pages

## Artifact Spec

| Direction | File | Author | Mandatory |
|-----------|------|--------|-----------|
| Input | `docs/ddd-design-v8.25.md` | Claude | ✅ |
| Input | `docs/ddd-plan-v8.25.md` | Claude | ✅ |
| Output | `docs/ddd-build-v8.25.md` | Gemini | ✅ HARD REQUIREMENT |
| Output | `docs/ddd-report-v8.25.md` | Gemini | ✅ HARD REQUIREMENT |

## Agent Restrictions

```
1. Git READ commands allowed (pull, log, status, diff, show).
   Git WRITE commands forbidden (add, commit, push, checkout, branch).
   firebase deploy forbidden.
   flutter build and flutter run ARE ALLOWED.
2. NEVER ask permission — the plan IS the permission.
3. Self-heal errors: diagnose → fix → re-run (max 3 attempts, then skip).
4. MCP ALLOWED: Playwright (visual screenshots), Lighthouse (audits), Context7 (docs).
   MCP NOT ALLOWED: Firecrawl.
5. EVERY session ends with ddd-build and ddd-report artifacts. No exceptions.
6. QA fixes are ALLOWED — if a visual issue is found, fix it, then re-verify.
   Log every fix in the build log with before/after.
7. Do NOT change design tokens or component patterns. If something looks wrong,
   check whether the code matches the pattern first. Only fix code, not specs.
```

## Pre-Flight Requirements

```
1. NODE_EXTRA_CA_CERTS is set and cert file exists
2. flutter build web succeeds (must test against production build, NOT debug)
3. python3 available (for serving production build locally)
4. MCP servers: Playwright ✅, Lighthouse ✅, Context7 ✅
```

---

# Part 2: tripleDB.net — QA Specification

## What QA Validates

| Category | What | How |
|----------|------|-----|
| Visual fidelity | Do widgets match component patterns? | Playwright screenshots vs design brief |
| Responsive design | Does it work on mobile, tablet, desktop? | Playwright at 3 viewport sizes |
| Design token compliance | Are colors, fonts, spacing from tokens? | Visual inspection of screenshots |
| Functionality | Does search work? Trivia cycle? Map render? | Playwright interaction testing |
| Performance | Load time, render performance | Lighthouse Performance score |
| Accessibility | Screen reader support, contrast ratios | Lighthouse Accessibility score |
| SEO | Meta tags, structured data | Lighthouse SEO score |
| Best practices | HTTPS, no console errors | Lighthouse Best Practices score |

## Viewport Sizes

| Name | Width × Height | Represents |
|------|---------------|------------|
| Mobile | 375 × 812 | iPhone 13 / standard mobile |
| Tablet | 768 × 1024 | iPad / standard tablet |
| Desktop | 1440 × 900 | Standard laptop/desktop |

## Lighthouse Targets

| Category | Target | Acceptable |
|----------|--------|------------|
| Performance | ≥80 | ≥60 |
| Accessibility | ≥90 | ≥80 |
| Best Practices | ≥90 | ≥80 |
| SEO | ≥90 | ≥80 |

These targets are for a production build served locally, NOT the debug dev server.

## Pages to Test

| Page | Route | Key Validations |
|------|-------|-----------------|
| Home (List tab) | `/` | Search bar, trivia card, nearby section |
| Map tab | `/map` | Map renders, pins visible, dark tiles |
| Explore tab | `/explore` | Stats computed, trivia cycles |
| Search results | `/search?q=brisket` | Results appear, cards formatted |
| Restaurant detail | `/restaurant/{id}` | Hero placeholder, dishes, visits, YouTube links |
| Dark mode | Toggle | All pages render correctly in dark theme |

## GEMINI.md Template

```markdown
# TripleDB App — Agent Instructions

## Current Iteration: 8.25

IMPORTANT: Read documents in this EXACT order before executing:

1. docs/ddd-design-v8.25.md — QA specification, targets, known issues
2. docs/ddd-plan-v8.25.md — QA execution steps
3. design-brief/design-tokens.json — Token values to verify against
4. design-brief/component-patterns.md — Widget specs to verify against

Do NOT begin execution until all 4 files have been read.

## Rules That Never Change
- Git READ commands allowed (pull, log, status, diff, show)
- Git WRITE commands forbidden (add, commit, push, checkout, branch)
- firebase deploy forbidden
- flutter build and flutter run ARE ALLOWED
- NEVER ask permission — auto-proceed on EVERY step
- MCP allowed: Playwright, Lighthouse, Context7. NOT Firecrawl.
- MUST produce ddd-build-v8.25.md AND ddd-report-v8.25.md before ending
- QA fixes allowed — fix issues found, log before/after
- Do NOT modify design tokens or component patterns
```
