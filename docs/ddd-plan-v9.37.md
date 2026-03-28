# TripleDB — Phase 9 Plan v9.37

**Phase:** 9 — App Optimization
**Iteration:** 37 (global)
**Executor:** Claude Code
**Date:** March 2026
**Goal:** Implement the Post-Flight Verification Protocol using Playwright MCP, wire location permission into the cookie consent flow, add changelog integrity gate. This iteration REQUIRES post-flight to pass before completion.

---

## Read Order

```
1. docs/ddd-design-v9.37.md — Post-flight spec, location-on-consent design, changelog gate
2. docs/ddd-plan-v9.37.md — This file. Execution steps.
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
   a. docs/ddd-build-v9.37.md — FULL transcript
   b. docs/ddd-report-v9.37.md — metrics, post-flight results
   c. README.md — COMPREHENSIVE update, changelog ≥ 22 entries
8. CHECKPOINT after every numbered step.
9. POST-FLIGHT is MANDATORY. The iteration is NOT complete until post-flight passes.
10. MCP SERVERS: Playwright MCP for post-flight. Context7 for Flutter docs.
11. CHANGELOG: NEVER truncate. ALWAYS append. Verify count ≥ 22 after writing.
```

---

## Step 0: Pre-Flight + Checkpoint Setup

```bash
cd ~/dev/projects/tripledb

# Verify project structure
ls app/lib/main.dart app/lib/services/cookie_consent_service.dart app/lib/pages/main_page.dart

# Current state check
cd app
flutter analyze
flutter build web

# Verify v9.36 fix is in place
grep -c "ProviderContainer" lib/main.dart
# Expected: 0 (removed in v9.36)

grep "_ensureInitialized" lib/services/cookie_consent_service.dart
# Expected: matches (lazy init from v9.36)

# Verify Playwright MCP is available
# (Claude Code should have access to Playwright tools)

# Initialize checkpoint
mkdir -p ~/dev/projects/tripledb/pipeline/data/checkpoints
```

Initialize checkpoint. Check for existing checkpoint (resume if crash recovery).

**Write checkpoint after Step 0.**

---

## Step 1: Wire Location Permission into Cookie Consent

### 1a. Read current consent flow

```bash
cat ~/dev/projects/tripledb/app/lib/pages/main_page.dart
cat ~/dev/projects/tripledb/app/lib/widgets/cookie_consent_banner.dart
cat ~/dev/projects/tripledb/app/lib/services/cookie_consent_service.dart
cat ~/dev/projects/tripledb/app/lib/providers/location_providers.dart
cat ~/dev/projects/tripledb/app/lib/services/location_service.dart
```

Understand:
- Where the consent callback fires (in `main_page.dart` or `cookie_consent_banner.dart`)
- How location is currently requested (in `location_providers.dart` or `location_service.dart`)
- What triggers the `nearbyRestaurants` provider to refresh

### 1b. Update the consent callback

Find the function that runs when user clicks "Accept All" or saves custom preferences. Add location permission request when Preferences category is enabled:

```dart
// In the consent handler (wherever _applyConsent or equivalent lives):

Future<void> _applyConsent(Map<String, bool> prefs) async {
  // 1. Save cookie preferences
  final cookieService = ref.read(cookieServiceProvider);
  cookieService.setPreferences(prefs);

  // 2. Update analytics
  final analyticsService = ref.read(analyticsServiceProvider);
  await analyticsService.updateConsent(prefs['analytics'] ?? false);

  // 3. Log consent event
  await analyticsService.logConsentGiven(prefs);

  // 4. Request location if Preferences enabled
  if (prefs['preferences'] == true) {
    _requestLocationAfterConsent();
  }

  // 5. Dismiss banner
  ref.read(hasConsentedProvider.notifier).set(true);
}

void _requestLocationAfterConsent() {
  // Use post-frame callback to ensure widget tree is stable
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      // Check current permission status
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Request permission — this shows the browser prompt
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        // Permission granted — refresh location provider to populate nearby
        ref.invalidate(userLocationProvider);
      }
    } catch (e) {
      // Location is optional — fail silently
      debugPrint('Location permission after consent failed: $e');
    }
  });
}
```

**Key points:**
- `requestPermission()` triggers the browser's geolocation prompt
- If user has already granted in a prior session, it returns immediately (no second prompt)
- If denied or errored, the app continues fine — "Nearby" section just shows "Enable location" message
- The `ref.invalidate(userLocationProvider)` causes Riverpod to re-fetch the user's position, which triggers `nearbyRestaurants` to recompute

### 1c. Update "Accept All" shortcut

The "Accept All" button should pass `{'essential': true, 'analytics': true, 'preferences': true}` through the same `_applyConsent` function, which now includes the location request.

### 1d. Update Customize modal description

The Preferences category description should mention location:

```dart
CookieCategory(
  id: 'preferences',
  title: 'Preferences',
  description: 'Remembers your settings, location for nearby restaurants, and recent searches.',
  isRequired: false,
),
```

### 1e. Handle "Decline" path

When user declines, `{'essential': true, 'analytics': false, 'preferences': false}` is passed. The `_applyConsent` function checks `prefs['preferences'] == true` — which is false — so NO location request fires. Correct.

### 1f. Verify geolocator import

Ensure `Geolocator` is importable wherever the consent callback lives:
```dart
import 'package:geolocator/geolocator.dart';
```

### 1g. Regenerate codegen if needed

```bash
cd ~/dev/projects/tripledb/app
dart run build_runner build --delete-conflicting-outputs
```

### 1h. Analyze

```bash
flutter analyze
# Must be 0 errors
```

**Write checkpoint after Step 1.**

---

## Step 2: Build + Post-Flight Verification

This is the first real execution of the Post-Flight Protocol.

### 2a. Build

```bash
cd ~/dev/projects/tripledb/app
flutter build web
```

Must succeed.

### 2b. Serve locally

```bash
cd ~/dev/projects/tripledb/app
python3 -m http.server 8080 -d build/web &
SERVER_PID=$!
echo "Local server PID: $SERVER_PID"
sleep 3
```

### 2c. Execute Post-Flight via Playwright MCP

Use Playwright MCP tools to execute each gate:

**GATE 1: App Bootstraps**

```
1. Navigate to http://localhost:8080
2. Wait 10 seconds for Flutter to load
3. Check: is the page blank/white? (Look for ANY visible text or UI elements)
4. Read browser console: are there any "Uncaught Error" or "TypeError" messages?
5. Take screenshot → save reference for build log
```

If Gate 1 fails (white screen, uncaught errors):
- Read the console error message
- Fix the issue (self-heal)
- Rebuild (`flutter build web`)
- Re-serve and re-test
- Max 3 attempts

**GATE 2: Core Navigation**

```
1. Find and click/navigate to the Map tab
2. Verify: map container or canvas is present
3. Find and click/navigate to the Explore tab
4. Verify: text content about restaurants/stats is visible
5. Find and click/navigate to the List tab
6. Verify: at least one restaurant card is visible
```

**GATE 3: Critical Features**

```
1. Verify: trivia card is visible with rotating text
2. Find the search bar
3. Type "BBQ" into the search field
4. Verify: search results appear (at least 1 result)
```

**GATE 4: Cookie Banner**

```
1. Open a new browser context (clean — no cookies)
2. Navigate to http://localhost:8080
3. Wait for load
4. Verify: cookie consent banner is visible at the bottom
5. Click "Accept All"
6. Verify: banner disappears
7. Reload the page
8. Verify: banner does NOT reappear (cookie persisted)
```

**GATE 5: Console Clean**

```
1. Read all browser console messages
2. Count error-level messages (red)
3. Verify: zero errors
4. Log any warnings for the build report
```

**GATE 6: Changelog Integrity**

```bash
cd ~/dev/projects/tripledb
grep -c '^\*\*v' README.md
# Must be ≥ 22

grep 'v0.7' README.md | head -1
# Must find earliest entry

grep 'v9.37' README.md | head -1
# Must find latest entry
```

### 2d. Kill local server

```bash
kill $SERVER_PID 2>/dev/null
```

### 2e. Log results

Record pass/fail for every gate item in the build log. If any gate failed, record the failure, the fix applied, and the re-test result.

**Write checkpoint after Step 2.**

---

## Step 3: Update README.md

```bash
cd ~/dev/projects/tripledb
```

### CRITICAL CHANGELOG RULE

```
The changelog section must contain ALL existing entries PLUS the new v9.37 entry.
APPEND v9.37 at the bottom. Do NOT remove any existing entries.
After writing, run: grep -c '^\*\*v' README.md
The count MUST be ≥ 22. If not, the post-flight FAILS.
```

### New changelog entry to APPEND:

```markdown
**v9.37 (Phase 9 — Post-Flight Protocol + Location Consent)**
- **Post-Flight Protocol (Pillar 9):** Automated runtime verification using Playwright MCP.
  Serves release build locally, navigates app, checks rendering, reads console for errors.
  6 gates: bootstrap, navigation, features, cookies, console, changelog integrity.
  Prevents white-screen deploys like v9.35. Permanent part of IAO methodology.
- **Location on consent:** Accepting cookie preferences now triggers browser geolocation
  permission request. Grants location → populates "Nearby Restaurants" immediately.
  Decline → no location prompt. Reduces permission fatigue from 2 prompts to 1 flow.
- **Changelog gate:** Post-flight verifies README changelog entry count ≥ 22. Agent
  cannot declare iteration complete if changelog has been truncated.
```

### Also update:

- IAO Pillar count: "Eight Pillars" → "Nine Pillars" (add Pillar 9 section)
- Iteration history: add v9.37 row
- Phase 9 status: v9.35–v9.37
- Footer: `*Last updated: Phase 9.37 — Post-Flight Protocol + Location Consent*`

### Verify changelog integrity:

```bash
grep -c '^\*\*v' README.md
# Must be ≥ 22

grep 'v0.7' README.md | head -1
grep 'v4.13' README.md | head -1
grep 'v7.32' README.md | head -1
grep 'v9.37' README.md | head -1
```

If ANY grep fails to find a match, the changelog was truncated. Restore from `docs/archive/` references and the changelog text in this plan.

**Write checkpoint after Step 3.**

---

## Step 4: Generate Artifacts + Cleanup

### docs/ddd-build-v9.37.md (MANDATORY — FULL TRANSCRIPT)

Must include:
- Pre-flight output
- Consent flow changes (files modified, code added)
- `flutter analyze` + `flutter build web` output
- **Full post-flight results**: gate-by-gate pass/fail with screenshots
- Any errors encountered during post-flight and fixes applied
- Changelog entry count verification
- README changes summary

### docs/ddd-report-v9.37.md (MANDATORY)

Must include:
1. **Location-on-consent:** Implementation details, which files changed
2. **Post-flight results:** Gate-by-gate table with pass/fail
3. **Post-flight protocol:** Documented as permanent IAO Pillar 9
4. **Screenshot references:** Home page, console (if captured)
5. **Changelog:** Entry count, verified oldest/newest
6. **Build status:** analyze + build results
7. **Human interventions:** count (target: 0)
8. **Claude's Recommendation:** Post-flight confidence level, next steps
9. **README Update Confirmation**

### Cleanup

Delete checkpoint file after all artifacts written.

---

## Success Criteria

```
[ ] Pre-flight passes
[ ] Location permission wired into cookie consent:
    [ ] "Accept All" triggers location request
    [ ] "Customize" with Preferences ON triggers location on save
    [ ] "Decline" does NOT trigger location
    [ ] Location failure is silent (app still works)
    [ ] Preferences description mentions location
[ ] flutter analyze: 0 errors
[ ] flutter build web: success
[ ] POST-FLIGHT passed (ALL 6 gates):
    [ ] Gate 1: App bootstraps (not white screen)
    [ ] Gate 2: Core navigation (Map, Explore, List)
    [ ] Gate 3: Critical features (trivia, search)
    [ ] Gate 4: Cookie banner (appears, dismisses, persists)
    [ ] Gate 5: Console clean (zero errors)
    [ ] Gate 6: Changelog integrity (≥ 22 entries)
[ ] README at project root updated:
    [ ] Nine Pillars (Pillar 9 added)
    [ ] Changelog ≥ 22 entries (v0.7–v9.37)
    [ ] Iteration history includes v9.37
    [ ] Footer: Phase 9.37
[ ] ddd-build-v9.37.md generated (FULL transcript with post-flight results)
[ ] ddd-report-v9.37.md generated
[ ] Checkpoint cleared
[ ] Human interventions: 0
```

---

## Launch Sequence

```bash
# 1. Archive previous iteration
cd ~/dev/projects/tripledb
mv docs/ddd-design-v9.36.md docs/archive/ 2>/dev/null
mv docs/ddd-plan-v9.36.md docs/archive/ 2>/dev/null
mv docs/ddd-report-v9.36.md docs/archive/ 2>/dev/null
mv docs/ddd-build-v9.36.md docs/archive/ 2>/dev/null

# 2. Place new docs
cp /path/to/ddd-design-v9.37.md docs/
cp /path/to/ddd-plan-v9.37.md docs/

# 3. Update CLAUDE.md
cat > CLAUDE.md << 'EOF'
# TripleDB — Agent Instructions

## Current Iteration: 9.37

Read these two documents in order, then execute the plan:

1. docs/ddd-design-v9.37.md — Post-flight protocol, location-on-consent, changelog gate
2. docs/ddd-plan-v9.37.md — Execution steps

## MCP Servers Available
- Playwright MCP: Browser automation for post-flight verification
- Context7: Flutter/Dart API docs

## Rules That Never Change
- NEVER run git add, git commit, git push, or firebase deploy
- NEVER ask permission — auto-proceed on EVERY step
- Self-heal: diagnose → fix → re-run (max 3, then skip)
- MUST produce ddd-build-v9.37.md AND ddd-report-v9.37.md before ending
- CHECKPOINT after every numbered step
- README changelog: NEVER truncate — count must be ≥ 22
- POST-FLIGHT is MANDATORY — all 6 gates must pass
EOF

# 4. Commit
git add .
git commit -m "KT starting 9.37 — post-flight protocol + location consent"

# 5. Launch Claude Code
cd ~/dev/projects/tripledb
claude
```

Then: `Read CLAUDE.md and execute.`

After completion:
```bash
cd ~/dev/projects/tripledb
git add .
git commit -m "KT completed 9.37 — post-flight verified, location-on-consent"
git push

cd app
flutter build web
firebase deploy --only hosting

# VERIFY: tripledb.net in incognito
# 1. Cookie banner appears
# 2. Accept All → location prompt fires
# 3. Nearby restaurants populate with distances
```
