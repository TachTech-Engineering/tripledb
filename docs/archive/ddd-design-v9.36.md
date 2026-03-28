# TripleDB — Design v9.36

---

# Part 1: IAO

## The Eight Pillars (Summary)

1. Plan-Report Loop — 2. Zero-Intervention Target — 3. Self-Healing — 4. Versioned Artifacts — 5. Artifacts Travel Forward — 6. Methodology Co-Evolution — 7. Interactive vs Unattended — 8. Graduated Batches

## Iteration History

| Iteration | Phase | Interventions | Executor | Key Learning |
|-----------|-------|---------------|----------|--------------|
| v0.7–v4.13 | 0-4 | 0–20+ | Gemini | Pipeline → zero interventions by v3.12 |
| v5.14–v5.15 | 5 | **0** | Gemini | 773 videos, 14-hour unattended run |
| v6.26–v6.29 | 6 | **0** | Gemini | 1,102 loaded, geocoded, polished |
| v8.17–v8.25 | 8 | **0** | Gemini | tripledb.net live |
| v7.30–v7.34 | 7 | **1** | Gemini | Enrichment complete, cookies, analytics |
| v9.35 | 9 | **0** | Claude Code | Riverpod 3, trivia, proximity |
| v9.36 | 9 | target: **0** | Claude Code | **CRITICAL: Fix white screen crash** |

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
| 9 | App Optimization | 🔧 In Progress | v9.35–v9.36 |

## v9.36 Scope — CRITICAL FIX + Changelog

### 🚨 Priority 1: White Screen Crash (PRODUCTION DOWN)

**Symptom:** After `flutter build web` + `firebase deploy`, tripledb.net shows a blank white screen in both desktop and mobile (including incognito). The app fails to bootstrap entirely.

**When it broke:** After v9.35 changes were deployed. The app built successfully locally (`flutter build web` succeeded, `flutter analyze` 0 errors), but the deployed production build crashes on load.

**Most likely root causes (investigate in order):**

1. **Cookie consent service initialization crash:** `CookieConsentService` uses `dart:html` (`document.cookie`) and is initialized in `main.dart` BEFORE `runApp()`. If this throws (e.g., `document` not available during Flutter engine bootstrap, or Riverpod 3 provider scope not ready), the entire app dies silently.

2. **Riverpod 3 initialization order:** The v9.35 migration converted `cookieServiceProvider` and `analyticsServiceProvider` to `@riverpod` codegen. If these are accessed during `main()` before `ProviderScope` is mounted, Riverpod 3 throws a `StateError` that kills the app.

3. **`dart:html` deprecation side effect:** Flutter 3.41+ deprecated `dart:html`. While it still compiles (info-level warning), the production WASM/JS build may handle it differently than `flutter run` debug mode.

4. **Firebase initialization race condition:** If `Firebase.initializeApp()` is called after cookie/analytics providers try to access Firebase, the app crashes.

5. **Missing firebase config in production build:** The `web/index.html` firebase config may be incomplete or mismatched after the Riverpod migration.

**Diagnostic steps:**

```bash
# 1. Check browser console for the actual error
#    Open tripledb.net in Chrome → F12 → Console tab
#    Copy the error message — it will identify the exact failure

# 2. Test locally in release mode (closer to production than debug)
cd ~/dev/projects/tripledb/app
flutter run -d chrome --release

# 3. Check if the issue is specifically the cookie service
#    Temporarily comment out cookie initialization in main.dart
#    Build and test — if app loads, the cookie service is the culprit

# 4. Check the built JS for errors
ls -la build/web/main.dart.js
```

**Fix strategy:**

The fix depends on what the browser console says. But the most likely fix is wrapping the cookie service initialization in a try-catch and deferring it to after the widget tree is mounted:

```dart
// BEFORE (crashes if dart:html fails during bootstrap):
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(...);
  final cookieService = CookieConsentService(); // ← CRASH HERE
  final analyticsService = AnalyticsService();
  await analyticsService.initialize(analyticsConsent: cookieService.hasConsent('analytics'));
  runApp(ProviderScope(child: MyApp()));
}

// AFTER (deferred, safe):
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(...);
  runApp(ProviderScope(child: MyApp()));
  // Cookie and analytics initialization happens inside the widget tree
  // via Riverpod providers that are lazy-loaded when first accessed
}
```

The key insight: Riverpod 3 providers are lazy by default. The `cookieServiceProvider` and `analyticsServiceProvider` should NOT be eagerly initialized in `main()`. They should be accessed when the widget tree first reads them — which happens safely after `runApp()`.

### Priority 2: README Changelog Restoration

**Problem:** Every iteration, the executing agent truncates the changelog to the last 2-3 entries instead of appending. The README currently shows only v7.34 → v9.35 (or fewer).

**Fix:** The plan will include the COMPLETE changelog text (v0.7 through v9.36) and explicit instructions:

```
CRITICAL CHANGELOG RULE:
The changelog section in README.md must contain ALL entries from v0.7 through v9.36.
APPEND the new v9.36 entry at the bottom.
Do NOT remove, summarize, or truncate any existing entries.
If the current README has fewer entries than the reference below, REPLACE
the entire changelog section with the full reference text plus the new entry.
```

### Priority 3: Verify Cookie Banner (After White Screen Fix)

Once the app loads, verify:
- Cookie banner appears on first visit (incognito)
- Accept/Decline/Customize all work
- Banner doesn't reappear after response
- "Manage cookies" link accessible
- Mobile rendering correct (banner positioned above bottom nav)

## Current State (After v9.35 — BROKEN DEPLOY)

### What works locally
- `flutter analyze`: 0 errors (1 info: dart:html deprecated)
- `flutter build web`: succeeds
- `flutter run -d chrome`: needs verification in release mode

### What's broken in production
- tripledb.net: white screen (app fails to bootstrap)
- Cookie banner: never renders (app doesn't get that far)
- All v7.34 and v9.35 features: not visible to users

### Firestore (unaffected)
- 1,102 restaurant docs, 582 enriched — data is fine
- The issue is purely in the Flutter web build/deployment

## CLAUDE.md Template

```markdown
# TripleDB — Agent Instructions

## Current Iteration: 9.36

IMPORTANT: This iteration fixes a PRODUCTION CRASH. Priority 1 is getting tripledb.net loading again.

Read these two documents in order, then execute the plan:

1. docs/ddd-design-v9.36.md — White screen diagnosis, changelog spec
2. docs/ddd-plan-v9.36.md — Fix steps

## Rules That Never Change
- NEVER run git add, git commit, git push, or firebase deploy
- NEVER ask permission — auto-proceed on EVERY step
- Self-heal: diagnose → fix → re-run (max 3, then skip)
- 3 consecutive identical errors = STOP
- MUST produce ddd-build-v9.36.md AND ddd-report-v9.36.md before ending
- CHECKPOINT after every numbered step
- README.md is at project root
- CHANGELOG: NEVER truncate. ALWAYS append. Full history must be preserved.
```
