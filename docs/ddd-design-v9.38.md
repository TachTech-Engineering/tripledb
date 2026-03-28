# TripleDB — Design v9.38

---

## v9.38 Scope — Cookie Banner Fix + Functional Post-Flight

### Problem

Cookie consent banner doesn't render on tripledb.net. The v9.37 post-flight "passed" because it only verified the page loaded and took a screenshot — it never clicked the banner, verified dismissal, or confirmed cookie persistence. A screenshot of a Flutter canvas proves nothing about interactive functionality.

### Root Fix: Post-Flight Must Be Functional

The Post-Flight Verification Protocol (Pillar 9) is redesigned as a TWO-TIER system:

**Tier 1 — Standard Health (same every iteration):**
- App bootstraps (not white screen)
- Console has zero uncaught errors
- Changelog integrity

**Tier 2 — Iteration Functional Tests (unique per plan):**
- Playwright executes a PLAYBOOK of user-like actions that exercise the iteration's deliverables
- Each action has an expected outcome — click, verify state change, confirm persistence
- If Playwright can't verify the outcome, the gate FAILS
- Every plan includes a `## Post-Flight Playbook` section defining Tier 2 tests

### Why Screenshots Don't Work for Flutter Web

Flutter Web renders to a `<canvas>` element. The DOM contains a `<flt-glass-pane>` wrapping a canvas — all UI is pixels, not DOM elements. Standard DOM inspection sees nothing meaningful.

**Playwright MCP's accessibility snapshot mode** reads the semantics tree that Flutter exposes for screen readers. This gives structured access to buttons, text fields, and interactive elements WITHOUT parsing the canvas. This is the correct approach.

If accessibility snapshots don't work, fall back to:
1. Coordinate-based clicking (find positions from snapshot)
2. JavaScript execution inside the Flutter context
3. Puppeteer with `page.accessibility.snapshot()` for the semantics tree

### Cookie Banner Debug Strategy

Investigate in order:
1. `hasConsentedProvider` returning `true` from a stale cookie set during development
2. Banner conditional logic inverted or missing in `main_page.dart`
3. Banner behind main content in Stack (wrong z-order — must be LAST child)
4. Banner widget removed from widget tree during v9.35/v9.36 refactors
5. Riverpod 3 provider not being `ref.watch()`ed in `build()` method

### Agent Restrictions

```
1. Git READ allowed. Git WRITE and firebase deploy FORBIDDEN.
2. flutter build web and flutter run ARE ALLOWED.
3. NEVER ask permission.
4. Self-heal: max 3 attempts.
5. FULL PROJECT ACCESS under ~/dev/projects/tripledb/.
6. MUST produce ddd-build and ddd-report before ending.
7. CHECKPOINT after every numbered step.
8. POST-FLIGHT: Tier 1 AND Tier 2 must BOTH pass.
9. CHANGELOG: ≥ 23 entries after update.
10. If Playwright MCP unavailable: install Puppeteer via npm and use it.
    Do NOT skip functional testing.
```

### CLAUDE.md Template

```markdown
# TripleDB — Agent Instructions

## Current Iteration: 9.38

BUG FIX: Cookie banner does not render. Debug, fix, and FUNCTIONALLY verify.

1. docs/ddd-design-v9.38.md — Debug strategy, functional post-flight spec
2. docs/ddd-plan-v9.38.md — Steps with Playwright playbook

## MCP Servers
- Playwright MCP: REQUIRED for functional testing
- Context7: Flutter docs

## Rules
- NEVER git add/commit/push or firebase deploy
- POST-FLIGHT Tier 1 + Tier 2 must BOTH pass
- Tier 2 = actually click buttons, verify state changes, confirm cookie persistence
- If Playwright MCP unavailable, npm install puppeteer and use that
- CHANGELOG ≥ 23 entries
```
