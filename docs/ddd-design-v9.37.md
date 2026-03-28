# TripleDB — Design v9.37

---

# Part 1: IAO — Iterative Agentic Orchestration

## The Nine Pillars of IAO (Pillar 9 NEW)

1. **Plan-Report Loop** — design + plan in → build + report out
2. **Zero-Intervention Target** — pre-answer every decision
3. **Self-Healing Loops** — diagnose → fix → re-run (max 3, then skip)
4. **Versioned Artifacts** — CLAUDE.md version lock, git commits mark boundaries
5. **Artifacts Travel Forward** — current in `docs/`, previous in `docs/archive/`
6. **Methodology Co-Evolution** — IAO evolves through the Plan-Report loop
7. **Interactive vs Unattended** — agent for tuning, bash for production
8. **Graduated Batches** — earn confidence, don't assume it
9. **Post-Flight Verification** — (**NEW**) MCP-driven runtime checks before declaring done

### Pillar 9: Post-Flight Verification

**Why it exists:** v9.35 passed `flutter analyze` and `flutter build web` with 0 errors but deployed to a white screen crash in production. Static analysis and compilation are necessary but NOT sufficient. Runtime failures (provider initialization order, DOM readiness, async race conditions, missing config) are only caught by actually running the built app.

**What it requires:** Every iteration that modifies Flutter code must run an automated post-flight checklist AFTER `flutter build web` succeeds. The post-flight serves the release build locally and uses Playwright MCP to navigate the app, verify rendering, and check the console for errors.

**When to skip:** Iterations that only modify pipeline scripts, docs, or README (no Flutter changes) may skip post-flight.

## Iteration History

| Iteration | Phase | Interventions | Executor | Key Learning |
|-----------|-------|---------------|----------|--------------|
| v0.7–v4.13 | 0-4 | 0–20+ | Gemini | Pipeline refinement |
| v5.14–v5.15 | 5 | **0** | Gemini | 773 videos, 14-hour unattended |
| v6.26–v6.29 | 6 | **0** | Gemini | 1,102 loaded, geocoded, polished |
| v8.17–v8.25 | 8 | **0** | Gemini | tripledb.net live |
| v7.30–v7.34 | 7 | **1** | Gemini | Enrichment, cookies, analytics |
| v9.35 | 9 | **0** | Claude Code | Riverpod 3, trivia, proximity |
| v9.36 | 9 | **0** | Claude Code | Fixed white screen crash |
| v9.37 | 9 | target: **0** | Claude Code | Post-flight protocol, location-on-consent |

## Agent Restrictions

```
1. Git READ allowed. Git WRITE and firebase deploy FORBIDDEN.
2. flutter build web and flutter run ARE ALLOWED.
3. NEVER ask permission — auto-proceed on EVERY step.
4. Self-heal: diagnose → fix → re-run (max 3, then skip).
5. 3 consecutive identical errors = STOP.
6. FULL PROJECT ACCESS under ~/dev/projects/tripledb/.
7. MUST produce ddd-build and ddd-report before ending.
8. CHECKPOINT after every numbered step.
9. Build log is MANDATORY — full transcript.
10. README at PROJECT ROOT.
11. CHANGELOG: NEVER truncate. ALWAYS append. Full history preserved.
12. POST-FLIGHT: Required for this iteration. Must pass before declaring complete.
```

---

# Part 2: ADR-001 — TripleDB

## Phase Status

| Phase | Name | Status | Iterations |
|-------|------|--------|------------|
| 0-5 | Pipeline | ✅ Complete | v0.7–v5.15 |
| 6 | Firestore + Polish | ✅ Complete | v6.26–v6.29 |
| 8 | Flutter App | ✅ Complete | v8.17–v8.25 |
| 7 | Enrichment + Analytics | ✅ Complete | v7.30–v7.34 |
| 9 | App Optimization | 🔧 In Progress | v9.35–v9.37 |

## v9.37 Scope — Three Deliverables

### Deliverable 1: Post-Flight Verification Protocol

Automated runtime verification using Playwright MCP after every `flutter build web`. This becomes a permanent part of the IAO methodology for all future iterations.

**MCP tools:**
- **Playwright MCP** — navigate app, check rendering, read console, screenshot
- **Context7** — Flutter/Dart API docs for self-healing

**Post-Flight Checklist (Standard):**

```
POST-FLIGHT CHECKLIST (execute via Playwright MCP)
═══════════════════════════════════════════════════

SETUP:
  [ ] Build: flutter build web (must pass first)
  [ ] Serve: python3 -m http.server 8080 -d build/web &
  [ ] Wait 3 seconds for server to start

GATE 1: App Bootstraps
  [ ] Navigate to http://localhost:8080
  [ ] Wait 10 seconds for Flutter engine to load
  [ ] VERIFY: Page is not blank/white
  [ ] VERIFY: Console has ZERO "Uncaught Error" messages
  [ ] VERIFY: Console has ZERO "TypeError" messages
  [ ] Screenshot: docs/screenshots/postflight_home.png

GATE 2: Core Navigation
  [ ] Navigate to Map tab → VERIFY: map canvas renders
  [ ] Navigate to Explore tab → VERIFY: stats text visible
  [ ] Navigate to List tab → VERIFY: restaurant cards visible

GATE 3: Critical Features
  [ ] VERIFY: Trivia card visible with text
  [ ] VERIFY: Search bar present
  [ ] Search "BBQ" → VERIFY: results appear

GATE 4: Cookie Banner (if touched in iteration)
  [ ] Fresh context (no cookies) → VERIFY: banner visible
  [ ] Click "Accept All" → VERIFY: banner dismisses
  [ ] VERIFY: Location permission prompt fires after accept
  [ ] Reload → VERIFY: banner does NOT reappear

GATE 5: Console Clean
  [ ] Read ALL console messages
  [ ] VERIFY: Zero errors (red)
  [ ] Log any warnings
  [ ] Screenshot: docs/screenshots/postflight_console.png

TEARDOWN:
  [ ] Kill local server

RESULT:
  ALL gates pass → Post-flight PASSED
  ANY gate fails → Fix → Re-run (max 3 attempts)
```

### Deliverable 2: Location Permission on Cookie Consent

**Current flow:**
```
First visit → Cookie banner → Accept/Decline → (later, sometime) → Location prompt
```

Users see two separate permission moments. Many never grant location because the prompt comes at a random time during browsing.

**New flow:**
```
First visit → Cookie banner appears
  ├─ "Accept All" → Set cookies → Request location permission → Populate nearby
  ├─ "Customize" → Modal → If Preferences ON → Request location on save
  └─ "Decline" → Essential only → No location request
```

**Implementation:**

In the consent callback (after user accepts or saves preferences with Preferences enabled):

```dart
void _applyConsent(Map<String, bool> prefs) {
  // 1. Save cookie preferences
  cookieService.setPreferences(prefs);

  // 2. Update analytics consent
  analyticsService.updateConsent(prefs['analytics'] ?? false);

  // 3. If preferences enabled, request location
  if (prefs['preferences'] == true) {
    _requestLocationPermission();
  }

  // 4. Dismiss banner
  ref.read(hasConsentedProvider.notifier).set(true);
}

Future<void> _requestLocationPermission() async {
  try {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      // Trigger location provider refresh — nearby restaurants will populate
      ref.invalidate(userLocationProvider);
    }
  } catch (e) {
    // Graceful failure — location is optional
    debugPrint('Location permission request failed: $e');
  }
}
```

**Key design decisions:**
- Location request is tied to the **Preferences** cookie category (not Analytics)
- If user accepts all → Preferences is ON → location fires immediately
- If user customizes and enables Preferences → location fires on save
- If user declines or disables Preferences → NO location request
- Location failure is silent — the app works fine without it, "Nearby" section just won't populate
- If user already granted location in a previous session, `requestPermission()` returns immediately without a prompt
- The Customize modal description for Preferences should mention location: "Preferences: Remembers your dark mode setting, location for nearby restaurants, and last search"

**Cookie category descriptions (updated):**

| Category | Description |
|----------|------------|
| Essential | Required for the app to function. Cannot be disabled. |
| Analytics | Helps us understand which features you use most. |
| Preferences | Remembers your settings, location for nearby restaurants, and recent searches. |

### Deliverable 3: Changelog Protection (Permanent Rule)

The README changelog has been truncated by agents in almost every iteration. The v9.36 fix restored all 21 entries. This deliverable makes truncation impossible going forward.

**Mechanism:** After writing the README, count changelog entries with `grep -c`. If fewer than the expected count, the post-flight FAILS and the agent must restore the full changelog before proceeding.

**Added to post-flight checklist:**

```
GATE 6: Changelog Integrity
  [ ] grep -c '^\*\*v' README.md → must be ≥ 22 (21 existing + 1 new)
  [ ] grep 'v0.7' README.md → earliest entry exists
  [ ] grep 'v9.37' README.md → latest entry exists
```

## Current State (After v9.36)

### App
- White screen crash FIXED (lazy provider init, deferred cookie DOM access)
- Built but not yet verified via Playwright (v9.36 had no display server)
- Cookie banner: code-reviewed as correct but not runtime-tested by agent
- Kyle deployed after v9.36 — current production status needs verification

### Firestore (unaffected)
- 1,102 restaurants, 582 enriched, 1,006 geocoded

### Known Issues
- Cookie consent doesn't trigger location permission (this iteration fixes it)
- Post-flight verification doesn't exist yet (this iteration creates it)
- Changelog protection not automated (this iteration adds it)

## CLAUDE.md Template

```markdown
# TripleDB — Agent Instructions

## Current Iteration: 9.37

Read these two documents in order, then execute the plan:

1. docs/ddd-design-v9.37.md — Post-flight protocol, location-on-consent, changelog protection
2. docs/ddd-plan-v9.37.md — Execution steps

## MCP Servers Available
- Playwright MCP: Browser automation for post-flight verification
- Context7: Flutter/Dart docs for self-healing

## Rules That Never Change
- NEVER run git add, git commit, git push, or firebase deploy
- NEVER ask permission — auto-proceed on EVERY step
- Self-heal: diagnose → fix → re-run (max 3, then skip)
- MUST produce ddd-build-v9.37.md AND ddd-report-v9.37.md before ending
- CHECKPOINT after every numbered step
- README changelog: NEVER truncate — count must be ≥ 22
- POST-FLIGHT: MANDATORY for this iteration — must pass all gates
```
