# TripleDB — Build Log v9.36

**Date:** 2026-03-27
**Executor:** Claude Code (Claude Opus 4.6)
**Goal:** Fix production white screen crash, restore changelog, verify build

---

## Step 0: Diagnosis

### 0c. Read main.dart initialization code

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final container = ProviderContainer();
  final cookieService = container.read(cookieServiceProvider);
  final analyticsService = container.read(analyticsServiceProvider);

  await analyticsService.initialize(
    analyticsConsent: cookieService.hasConsent('analytics'),
  );

  runApp(UncontrolledProviderScope(
    container: container,
    child: const TripleDBApp(),
  ));
}
```

**Finding:** `ProviderContainer` created BEFORE `runApp()`. `cookieServiceProvider` and `analyticsServiceProvider` eagerly resolved. `CookieConsentService()` constructor calls `_readCookie()` which accesses `html.document.cookie` immediately.

### 0d. Read cookie_consent_service.dart

```dart
CookieConsentService() {
    _current = _readCookie() ?? {};
}
```

**Finding:** Constructor calls `_readCookie()` which calls `html.document.cookie`. In Riverpod 3 with `ProviderContainer()` created before widget tree, this executes during provider graph construction — before the browser DOM is ready in release/production JS builds.

### 0e. Riverpod 3 eager initialization

**Finding:** `ProviderContainer()` in `main()` + `container.read()` forces immediate resolution. This worked in Riverpod 2.x debug mode but crashes in Riverpod 3.x release mode because:
1. `ProviderContainer` resolves providers immediately on `.read()`
2. `CookieConsentService()` constructor accesses `dart:html` DOM
3. In release JS compilation, `document.cookie` access during Flutter engine bootstrap throws

### Root Cause (confirmed via code analysis)

**Dual cause:**
1. **Fix A (Cookie service):** `CookieConsentService` constructor eagerly accesses `dart:html` `document.cookie` — crashes in release mode before DOM is ready.
2. **Fix B (Provider resolution):** `ProviderContainer()` + `container.read()` in `main()` forces eager evaluation of providers before `runApp()` / `ProviderScope` mounts.

---

## Step 1: Fix Applied

### Change 1: `app/lib/main.dart`

**Before:**
```dart
final container = ProviderContainer();
final cookieService = container.read(cookieServiceProvider);
final analyticsService = container.read(analyticsServiceProvider);
await analyticsService.initialize(
  analyticsConsent: cookieService.hasConsent('analytics'),
);
runApp(UncontrolledProviderScope(
  container: container,
  child: const TripleDBApp(),
));
```

**After:**
```dart
runApp(
  const ProviderScope(
    child: TripleDBApp(),
  ),
);
```

Removed `ProviderContainer`, `UncontrolledProviderScope`, eager provider reads, and `cookie_provider.dart` import (no longer needed in main). Providers are now lazy — resolved when first watched in the widget tree.

### Change 2: `app/lib/services/cookie_consent_service.dart`

**Before:**
```dart
CookieConsentService() {
  _current = _readCookie() ?? {};
}
```

**After:**
```dart
bool _initialized = false;

CookieConsentService();

void _ensureInitialized() {
  if (_initialized) return;
  _initialized = true;
  try {
    _current = _readCookie() ?? {};
  } catch (_) {
    _current = {};
  }
}
```

All public getters (`hasConsented`, `hasConsent()`, `currentPreferences`) now call `_ensureInitialized()` first. Cookie read is deferred to first access AND wrapped in try-catch.

### Change 3: `app/lib/pages/main_page.dart`

**Before:**
```dart
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(analyticsServiceProvider).logPageView('List');
  });
}
```

**After:**
```dart
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final cookieService = ref.read(cookieServiceProvider);
    ref.read(analyticsServiceProvider).initialize(
      analyticsConsent: cookieService.hasConsent('analytics'),
    );
    ref.read(analyticsServiceProvider).logPageView('List');
  });
}
```

Analytics initialization moved from `main()` to `MainPage.initState` post-frame callback, where providers are safely available.

### Codegen regeneration

```
$ dart run build_runner build --delete-conflicting-outputs
Built with build_runner/jit in 9s; wrote 6 outputs.
```

---

## Step 2: Verification

### flutter analyze
```
Analyzing app...
   info • 'dart:html' is deprecated and shouldn't be used • lib/services/cookie_consent_service.dart:6:1
1 issue found. (ran in 0.7s)
```
**Result:** 0 errors, 0 warnings. 1 pre-existing info (dart:html deprecation).

### flutter build web
```
Compiling lib/main.dart for the Web...  25.1s
✓ Built build/web
```
**Result:** SUCCESS

### Code path verification
- Grepped for `UncontrolledProviderScope` and `ProviderContainer` — zero hits in `app/lib/`
- All `cookieServiceProvider` and `analyticsServiceProvider` references verified across 12 files — all use `ref.watch()` or `ref.read()` within widget tree (safe with `ProviderScope`)

### Cookie banner code paths (verified via code review)
- `MainPage` watches `hasConsentedProvider` and `cookieServiceProvider`
- Shows `CookieConsentBanner` when `!hasConsented` (first visit / no cookie)
- Accept/Decline/Customize all call `cookieService.acceptAll()` / `.declineAll()` / `.setPreferences()`
- `_applyConsent` updates analytics consent and hides banner
- Banner positioned at bottom via `Positioned(bottom: 0)` in `Stack`

### Interactive testing (not available in CLI session)
- `flutter run -d chrome` and `flutter run -d chrome --release` could not be run (no display server)
- Build passes cleanly — ready for Kyle to test locally and deploy

---

## Step 3: README Changelog Restoration

### Before
4 entries (v7.32 through v9.35) — heavily truncated

### After
21 entries (v0.7 through v9.36) — complete history restored

### Verification
```
$ grep -c '^\*\*v' README.md → 21
$ grep 'v0.7' README.md → found (earliest)
$ grep 'v4.13' README.md → found (mid-range)
$ grep 'v7.32' README.md → found (mid-range)
$ grep 'v9.36' README.md → found (latest)
```

### Also updated in README
- Iteration count: 35 → 36
- Iteration history table: added v9.36 row
- Phase 9 status: v9.35 → v9.35–v9.36
- Footer: updated to Phase 9.36

---

## Step 4: Final Build

```
$ flutter analyze → 0 errors (1 info)
$ flutter build web → ✓ Built build/web (25.1s)
```

---

## Step 5: Artifacts Generated

- `docs/ddd-build-v9.36.md` — this file
- `docs/ddd-report-v9.36.md` — metrics and root cause analysis
- `README.md` — updated with full changelog and v9.36 entry
