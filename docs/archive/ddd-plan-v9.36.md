# TripleDB — Phase 9 Plan v9.36

**Phase:** 9 — App Optimization
**Iteration:** 36 (global)
**Executor:** Claude Code
**Date:** March 2026
**Goal:** Fix production white screen crash on tripledb.net, restore complete README changelog (v0.7–v9.36), verify cookie consent banner on mobile and desktop.

---

## 🚨 PRODUCTION INCIDENT — tripledb.net IS DOWN

The site shows a white screen with an `Uncaught Error` in the browser console. The minified stack trace points to provider initialization code. The app fails to bootstrap entirely — no Flutter rendering occurs.

**DO NOT move to changelog or other work until the app renders correctly in `flutter run -d chrome --release`.**

---

## Read Order

```
1. docs/ddd-design-v9.36.md — White screen diagnosis, root causes, changelog spec
2. docs/ddd-plan-v9.36.md — This file. Fix steps.
```

Read both fully before executing.

---

## Autonomy Rules

```
1. AUTO-PROCEED between ALL steps. NEVER ask permission.
2. SELF-HEAL: diagnose → fix → re-run (max 3, then skip).
3. 3 consecutive identical errors = STOP.
4. Git READ allowed. Git WRITE and firebase deploy FORBIDDEN.
5. flutter build web and flutter run ARE ALLOWED.
6. FULL PROJECT ACCESS under ~/dev/projects/tripledb/.
7. MANDATORY ARTIFACTS before session ends:
   a. docs/ddd-build-v9.36.md — FULL transcript
   b. docs/ddd-report-v9.36.md — metrics, root cause analysis
   c. README.md — COMPREHENSIVE update with FULL changelog
8. CHECKPOINT after every numbered step.
9. CHANGELOG RULE: NEVER truncate. ALWAYS append. See Step 3 for full text.
```

---

## Step 0: Diagnose the Crash

### 0a. Reproduce locally in DEBUG mode (readable stack traces)

```bash
cd ~/dev/projects/tripledb/app
flutter run -d chrome
```

Debug mode gives UNMINIFIED stack traces. The browser console will show the actual class name, method, and error message that's causing the crash. **Copy the full error output to the build log.**

### 0b. If debug mode works fine, reproduce in RELEASE mode

```bash
flutter run -d chrome --release
```

If it crashes in release but not debug, the issue is likely:
- Tree-shaking removed something needed at runtime
- `dart:html` behaves differently in release JS compilation
- A Riverpod 3 provider that works lazily in debug but eagerly in release

### 0c. Read main.dart initialization code

```bash
cat ~/dev/projects/tripledb/app/lib/main.dart
```

Look for:
1. Code that runs BEFORE `runApp()` — anything accessing providers, cookies, or analytics here is suspect
2. `ProviderContainer` or manual provider reads before `ProviderScope` is in the widget tree
3. `CookieConsentService()` constructor being called in `main()`
4. `AnalyticsService` initialization before widget tree

### 0d. Read cookie_provider.dart

```bash
cat ~/dev/projects/tripledb/app/lib/providers/cookie_provider.dart
```

Check if the `@riverpod` codegen'd providers reference `CookieConsentService` which calls `dart:html` `document.cookie` during construction. In Riverpod 3, providers may be resolved differently than 2.x.

### 0e. Check for Riverpod 3 eager initialization

Riverpod 3 changed provider lifecycle. Providers that were lazy in 2.x may now be eagerly evaluated. Look for:
- `ref.watch()` calls in providers that transitively reach `CookieConsentService`
- `ProviderScope(overrides: [...])` that force early resolution
- Any `ProviderContainer()` created outside the widget tree

**Log the FULL error message and stack trace from debug mode. This is the most important diagnostic.**

**Write checkpoint after Step 0.**

---

## Step 1: Fix the White Screen Crash

Based on the diagnostic from Step 0, apply the appropriate fix. The design doc outlines the most likely causes. Here are the fixes for each:

### Fix A: Cookie service initialization crash (MOST LIKELY)

If the error points to `CookieConsentService`, `dart:html`, or `document.cookie`:

**Root cause:** `CookieConsentService()` constructor calls `document.cookie` via `dart:html`. In Riverpod 3 with `@riverpod` codegen, the `cookieServiceProvider` may be resolved during provider graph construction, which happens before the browser DOM is fully ready in release mode.

**Fix:** Make the cookie service lazy and add error handling:

```dart
// In cookie_consent_service.dart:
class CookieConsentService {
  Map<String, bool> _current = {};
  bool _initialized = false;

  // Don't read cookie in constructor — defer to first access
  CookieConsentService();

  void _ensureInitialized() {
    if (!_initialized) {
      try {
        _current = _readCookie() ?? {};
      } catch (e) {
        _current = {};  // Fail gracefully — treat as first visit
      }
      _initialized = true;
    }
  }

  bool get hasConsented {
    _ensureInitialized();
    return _current.isNotEmpty;
  }

  bool hasConsent(String category) {
    _ensureInitialized();
    if (category == 'essential') return true;
    return _current[category] ?? false;
  }

  // ... rest of methods also call _ensureInitialized() first
}
```

### Fix B: Riverpod 3 provider resolution order

If the error is a `StateError` or `ProviderException` from Riverpod:

**Fix:** Ensure no providers are accessed in `main()` before `runApp(ProviderScope(...))`. Move ALL initialization into the widget tree:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Do NOT access any Riverpod providers here.
  // Do NOT create CookieConsentService here.
  // Do NOT initialize AnalyticsService here.

  runApp(
    ProviderScope(
      child: const TripleDBApp(),
    ),
  );
}
```

Then in the root widget or a startup widget, use `ref.watch` to lazily initialize:

```dart
class TripleDBApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // These are now lazy — resolved when first watched
    final cookieService = ref.watch(cookieServiceProvider);
    final analyticsService = ref.watch(analyticsServiceProvider);

    // Initialize analytics consent based on cookie state
    // (do this in a listener or initState, not in build)

    return MaterialApp.router(
      // ...
    );
  }
}
```

### Fix C: dart:html in WASM/release build

If the error specifically mentions `dart:html` or `HtmlDocument`:

**Fix:** Guard all `dart:html` usage behind a `kIsWeb` check and wrap in try-catch:

```dart
import 'package:flutter/foundation.dart' show kIsWeb;

Map<String, bool>? _readCookie() {
  if (!kIsWeb) return null;
  try {
    // dart:html cookie access
  } catch (e) {
    return null;
  }
}
```

### After applying the fix:

```bash
cd ~/dev/projects/tripledb/app

# 1. Regenerate codegen if providers changed
dart run build_runner build --delete-conflicting-outputs

# 2. Analyze
flutter analyze

# 3. Test in debug
flutter run -d chrome
# Verify: app loads, no console errors

# 4. Test in RELEASE (critical — this is what production uses)
flutter run -d chrome --release
# Verify: app loads, no console errors

# 5. Build for deployment
flutter build web
```

**ALL THREE must pass: debug, release, and build. If release still crashes, repeat diagnosis.**

**Write checkpoint after Step 1.**

---

## Step 2: Verify Cookie Banner + App Features

After the white screen is fixed and the app loads:

### 2a. Cookie banner verification

```
flutter run -d chrome --release
```

Open in incognito/private window:

- [ ] Cookie banner appears at bottom of screen
- [ ] "Accept All" dismisses banner
- [ ] Page reload: banner does NOT reappear
- [ ] New incognito window: banner DOES appear (new session)
- [ ] "Decline" works — dismisses banner
- [ ] "Customize" opens modal with toggles
- [ ] "Manage cookies" link accessible somewhere in the app

### 2b. Core features still work

- [ ] Restaurant list loads with data
- [ ] Map shows pins with clustering
- [ ] Search returns results
- [ ] Trivia rotates (70+ facts, "Fact X of Y")
- [ ] "Nearby Restaurants" shows 10+ results with distance
- [ ] Restaurant detail page loads
- [ ] Dark mode toggle works
- [ ] "Show closed" filter works on map

### 2c. Mobile viewport check

In Chrome DevTools, toggle device toolbar (Ctrl+Shift+M) and check:
- iPhone 12/13 viewport (390×844)
- Galaxy S21 viewport (360×800)

Verify cookie banner renders correctly on narrow viewports.

Log all pass/fail results.

**Write checkpoint after Step 2.**

---

## Step 3: Restore Complete README Changelog

```bash
cd ~/dev/projects/tripledb
```

### CRITICAL CHANGELOG RULE

```
The changelog section in README.md must contain ALL entries listed below.
APPEND the new v9.36 entry at the bottom.
Do NOT remove, summarize, or truncate ANY existing entry.
If the current README has fewer entries than listed here, REPLACE the entire
changelog section with this complete text plus the new v9.36 entry.
Count the entries after writing — there must be at least 20 entries
(v0.7 through v9.36).
```

### Complete Changelog Text (COPY THIS VERBATIM INTO README.md)

```markdown
## Changelog

**v0.7 (Phase 0 — Setup)**
- Monorepo scaffolded with `pipeline/`, `app/`, and `docs/` directories.
- 805 YouTube playlist URLs collected. IAO methodology established.
- Learned: fish shell has no heredocs — use `printf` or `nano`.

**v1.8 (Phase 1 — Discovery, Attempt 1)**
- **Failure:** Nemotron 3 Super (120B, 42GB) could not run on 8GB VRAM RTX 2080 SUPER.
  Model spilled to CPU RAM, causing indefinite timeout loops during context pre-filling.

**v1.9 (Phase 1 — Discovery, Attempt 2)**
- **Pivot:** Swapped Nemotron for qwen3.5:9b. Added transcript chunking for 8K context window.
- Extraction still too slow — 5-10 minutes per video with frequent timeouts.

**v1.10 (Phase 1 — Discovery, Attempt 3)**
- **Pivot:** Shifted extraction to Gemini 2.5 Flash API (free tier, 1M token context).
- 93% extraction success rate. 186 restaurants, 290 dishes from 30 videos.

**v2.11 (Phase 2 — Calibration)**
- 60-video dataset: 422 unique restaurants, 624 dishes. Gemini Flash handles 200K-char transcripts.
- CUDA `LD_LIBRARY_PATH` must be set at shell level, not Python level.
- Marathon extraction timeout increased to 300 seconds.

**v3.12 (Phase 3 — Stress Test)**
- **Zero interventions** achieved for the first time. Autonomous batch healing.
- 511 restaurants, 896 dishes, 98 dedup merges. 4-hour marathon logged as edge case.

**v4.13 (Phase 4 — Validation)**
- 608 restaurants, 1,015 dishes, 162 dedup merges. Zero interventions.
- Extraction and normalization prompts locked for production. Group B green-lit.

**v5.14 (Phase 5 — Production Setup)**
- Fixed null-name restaurant merging bug (14 records collapsed into one entity).
- Built Group B runner: `group_b_runner.sh` + `checkpoint_report.py`.
- Hang detection: 600-second `signal.alarm` around `model.transcribe`.
- IAO Eight Pillars documented in README.

**v5.15 (Phase 5 — Production Run)**
- 14-hour unattended run via tmux. 778 downloaded, 774 transcribed, 773 extracted.
- 4 videos exceeded 600s timeout — skipped. Resume support confirmed.

**v6.26 (Phase 6 — Firestore Load)**
- 1,102 unique restaurants loaded to Firestore. State inference: UNKNOWN reduced from 126 to 33.
- App wired to Firestore. Search, trivia, and list views functional.

**v6.27 (Phase 6 — Geolocation Fix)**
- Fixed geolocation prompt but broke Firestore with temporary bypass. Reverted in v6.28.
- Downgraded geolocator to 10.x for Flutter compatibility.

**v6.28 (Phase 6 — Geocoding)**
- 916/1,102 restaurants geocoded via Nominatim at 1 req/sec. Map showing pins across the US.

**v8.17–v8.25 (Phase 8 — Flutter App)**
- Two-pass app build. Pass 1: scaffold + core features. Pass 2: design tokens, component patterns.
- DDD Red (#DD3333), Orange (#DA7E12), Outfit + Inter fonts. Lighthouse A11y 92, SEO 100.
- 3-tab bottom nav (Map/List/Explore), restaurant detail with YouTube deep links, dark mode.

**v6.29 (Phase 6 — Polish)**
- Trivia state count fixed (excludes UNKNOWN → shows 62 states).
- Map pin clustering via `flutter_map_marker_cluster`. Orange clusters with counts.
- Explore page: multi-cuisine string splitting for accurate counts.

**v7.30 (Phase 7 — Enrichment Discovery)**
- Google Places API (New) enrichment pipeline built. 50-restaurant discovery batch.
- 66.7% match rate. 90% of matches rated 4.0+. 4 coordinate backfills. API cost: $0.

**v7.31 (Phase 7 — Enrichment Production)**
- Full run on 1,102 restaurants. 625 enriched at 55.9% match. 32 permanently closed identified.
- App UI: rating badges, open/closed status, website and Google Maps links.
- 1 intervention (API key not set in environment).

**v7.32 (Phase 7 — Enrichment Refinement)**
- Refined search on 462 no-match restaurants (4 query passes). 83 recovered, 18% recovery rate.
- Gemini Flash LLM verification: 112 confirmed, 126 false positives removed, 26 uncertain.
- Net enrichment: 582 verified. Geocoding coverage: 91.3%.

**v7.33 (Phase 7 — AKA Names + Closed UX)**
- `google_current_name` backfilled for all enriched restaurants. 283 genuine name changes.
- Grey map pins for closed restaurants. "Show closed" filter toggle. Closed banners on detail pages.
- "Now known as" display for renamed restaurants. Step-level checkpointing introduced.

**v7.34 (Phase 7 — Cookies + Analytics + Polish)**
- Cookie consent: accept/decline/customize with 3 categories. 365-day cookie, SameSite=Lax.
- Firebase Analytics with consent mode v2. Events gated by user consent.
- Name-change threshold tightened 0.95 → 0.90 (86 reclassified, 279 genuine remain).
- 26 UNCERTAIN records resolved (15 kept, 11 removed).

**v9.35 (Phase 9 — App Optimization)**
- **Executor change:** Gemini CLI → Claude Code.
- Riverpod 2.x → 3.x migration. Geolocator 10.x → 14.x upgrade.
- Trivia expanded from ~9 facts to 70-80+ with no-repeat shuffle system.
- "Nearby Restaurants": 15 results with distance in miles, "Show all nearby" → 50.

**v9.36 (Phase 9 — Production Fix)**
- **CRITICAL:** Fixed white screen crash on tripledb.net caused by [ROOT CAUSE FROM STEP 1].
- Restored complete README changelog (v0.7–v9.36) — all 20+ entries preserved.
- Verified cookie consent banner on mobile and desktop.
```

**IMPORTANT:** Replace the `[ROOT CAUSE FROM STEP 1]` placeholder with the actual fix description from Step 1.

### After writing the changelog, VERIFY:

```bash
# Count changelog entries — must be at least 20
grep -c "^\*\*v" README.md
# Expected: 21 or more

# Verify earliest entry exists
grep "v0.7" README.md

# Verify latest entry exists
grep "v9.36" README.md

# Verify mid-range entry exists
grep "v4.13" README.md
grep "v7.32" README.md
```

If any of these checks fail, the changelog was truncated. Fix before proceeding.

### Also update in README:

- Phase 9 status: show v9.35–v9.36
- IAO iteration history: add v9.36 row with root cause fix description
- Footer: `*Last updated: Phase 9.36 — Production Fix + Changelog Restoration*`

**Write checkpoint after Step 3.**

---

## Step 4: Final Build + Verify

```bash
cd ~/dev/projects/tripledb/app

flutter analyze    # 0 errors
flutter build web  # Must succeed

# CRITICAL: Test in release mode
flutter run -d chrome --release
# Must load without white screen
```

If all pass, the app is ready for Kyle to deploy:
```bash
firebase deploy --only hosting
```

**Write checkpoint after Step 4.**

---

## Step 5: Generate Artifacts + Cleanup

### docs/ddd-build-v9.36.md (MANDATORY — FULL TRANSCRIPT)

Must include:
- Debug mode error output (FULL stack trace — this is the most valuable diagnostic)
- Root cause analysis
- Exact code changes that fixed the crash
- Cookie banner verification results
- Feature verification checklist
- Changelog entry count verification
- flutter analyze + build output
- Release mode test result

### docs/ddd-report-v9.36.md (MANDATORY)

Must include:
1. **Root cause:** Exact error, exact file, exact line
2. **Fix applied:** What was changed and why
3. **Verification:** Debug + release + build all pass
4. **Cookie banner:** Mobile + desktop status
5. **Changelog:** Entry count, earliest/latest verified
6. **Human interventions:** count (target: 0)
7. **Claude's Recommendation:** Confidence level in the fix, next steps
8. **README Update Confirmation**

### Cleanup

Delete checkpoint file.

---

## Success Criteria

```
[ ] White screen crash diagnosed (full error captured in build log)
[ ] Root cause identified and fixed
[ ] flutter run -d chrome: app loads ✅
[ ] flutter run -d chrome --release: app loads ✅
[ ] flutter build web: succeeds ✅
[ ] Cookie banner appears on first visit (incognito)
[ ] Cookie accept/decline/customize all work
[ ] Core features verified (list, map, search, trivia, nearby, detail)
[ ] README changelog: 20+ entries, v0.7 through v9.36
[ ] README changelog verification: grep confirms earliest/latest/mid entries
[ ] ddd-build-v9.36.md generated (FULL transcript with stack trace)
[ ] ddd-report-v9.36.md generated
[ ] Checkpoint cleared
[ ] Human interventions: 0
```

---

## Launch Sequence

```bash
# 1. Archive previous iteration
cd ~/dev/projects/tripledb
mv docs/ddd-design-v9.35.md docs/archive/ 2>/dev/null
mv docs/ddd-plan-v9.35.md docs/archive/ 2>/dev/null
mv docs/ddd-report-v9.35.md docs/archive/ 2>/dev/null
mv docs/ddd-build-v9.35.md docs/archive/ 2>/dev/null

# 2. Place new docs
cp /path/to/ddd-design-v9.36.md docs/
cp /path/to/ddd-plan-v9.36.md docs/

# 3. Update CLAUDE.md
cat > CLAUDE.md << 'EOF'
# TripleDB — Agent Instructions

## Current Iteration: 9.36

CRITICAL: This iteration fixes a PRODUCTION CRASH. Priority 1 is getting tripledb.net loading again.

Read these two documents in order, then execute the plan:

1. docs/ddd-design-v9.36.md
2. docs/ddd-plan-v9.36.md

## Rules That Never Change
- NEVER run git add, git commit, git push, or firebase deploy
- NEVER ask permission — auto-proceed on EVERY step
- Self-heal: diagnose → fix → re-run (max 3, then skip)
- MUST produce ddd-build-v9.36.md AND ddd-report-v9.36.md before ending
- CHECKPOINT after every numbered step
- README changelog: NEVER truncate — ALWAYS append — 20+ entries required
EOF

# 4. Commit
git add .
git commit -m "KT starting 9.36 — fix white screen crash"

# 5. Launch Claude Code
cd ~/dev/projects/tripledb
claude
```

Then: `Read CLAUDE.md and execute.`

After completion:
```bash
cd ~/dev/projects/tripledb
git add .
git commit -m "KT completed 9.36 — white screen fix + changelog restoration"
git push

cd app
flutter build web
firebase deploy --only hosting

# VERIFY: open tripledb.net in incognito — should load with cookie banner
```
