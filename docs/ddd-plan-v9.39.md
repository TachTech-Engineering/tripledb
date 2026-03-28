# TripleDB — Phase 9 Plan v9.39

**Phase:** 9 — App Optimization
**Iteration:** 39 (global)
**Executor:** Claude Code (YOLO mode)
**Date:** March 2026
**Goal:** Fix three bugs visible in production: Unknown city/state in nearby results, duplicate restaurants in nearby, Accept All not triggering location. Post-flight playbook verifies all three.

---

## Read Order

```
1. docs/ddd-design-v9.39.md — Full living ADR with Eight Pillars, environment setup, current state
2. docs/ddd-plan-v9.39.md — This file. Bug fix steps + playbook.
```

Read both fully before executing.

---

## Autonomy Rules

```
1. AUTO-PROCEED. NEVER ask permission. YOLO mode — code dangerously.
2. SELF-HEAL: max 3 attempts per error.
3. Git READ only. No write, no deploy.
4. flutter build web and flutter run ARE ALLOWED.
5. FULL PROJECT ACCESS under ~/dev/projects/tripledb/.
6. MANDATORY: ddd-build + ddd-report (with orchestration report) + README update.
7. CHECKPOINT after every numbered step.
8. POST-FLIGHT: Tier 1 + Tier 2 playbook must BOTH pass.
9. CHANGELOG: APPEND only, ≥ 24 entries after update.
10. Orchestration Report REQUIRED in ddd-report — tools used, workload %, efficacy.
```

---

## The Three Bugs

### Bug 1: Unknown City/State in Nearby Results

**Symptom:** "Big Pig's Barbecue — Unknown, NJ • 22 mi" appears in nearby results. Restaurants with city="Unknown" or state="Unknown" or null values for either field are shown alongside properly located restaurants.

**Root cause:** The `nearbyRestaurants` provider filters for `stillOpen != false` and `latitude != null` but does NOT filter for valid city/state values. Restaurants with "Unknown" city were geocoded (they have lat/lng from state-level or approximate geocoding) but their display data is meaningless for a "nearby" recommendation.

**Fix:** Add city/state validation to the nearby provider. Filter out restaurants where:
- `city` is null, empty, "Unknown", "None", or "UNKNOWN"
- `state` is null, empty, "Unknown", "None", or "UNKNOWN"

```dart
final validNearby = restaurants.where((r) =>
  r.stillOpen != false &&
  r.latitude != null &&
  r.longitude != null &&
  r.city != null &&
  r.city!.isNotEmpty &&
  !['unknown', 'none', 'n/a'].contains(r.city!.toLowerCase()) &&
  r.state != null &&
  r.state!.isNotEmpty &&
  !['unknown', 'none', 'n/a'].contains(r.state!.toLowerCase())
).toList();
```

### Bug 2: Duplicate Restaurants in Nearby Results

**Symptom:** "Belly and Snout" appears twice at 32 mi — once as "Unknown, CA" and once as "Rancho Cucamonga, CA." Same restaurant, two entries.

**Root cause:** The normalized dataset may have duplicate restaurant_ids (unlikely) or the restaurant appears in the list twice due to how the Firestore data maps. More likely: the restaurant has two entries in the JSONL/Firestore with slightly different data (one from extraction, one from enrichment or normalization edge case).

**Fix:** Deduplicate the nearby list by `restaurant_id` before display:

```dart
// After sorting by distance, before take(N):
final seen = <String>{};
final deduped = <NearbyRestaurant>[];
for (final nr in sorted) {
  if (seen.add(nr.restaurant.restaurantId)) {
    deduped.add(nr);
  }
}
return deduped.take(nearbyCount).toList();
```

Also investigate: query Firestore to check if "Belly and Snout" actually has two documents or if the Dart model is creating duplicates during mapping.

### Bug 3: Accept All Doesn't Trigger Location

**Symptom:** Clicking "Accept All" on the cookie banner dismisses the banner but does NOT prompt for browser location permission.

**Root cause candidates (investigate in order):**
1. The `_requestLocationAfterConsent()` method from v9.37 was added to `cookie_consent_banner.dart` but the code path isn't being reached — perhaps the "Accept All" button calls a different callback that doesn't go through `_applyConsent()`
2. The Geolocator `requestPermission()` call is wrapped in a try-catch that silently fails — the permission may be throwing an error (e.g., geolocator 14.x API change)
3. The `addPostFrameCallback` defers the call but the widget is already disposed by the time it fires (banner dismisses → widget removed from tree → callback fires on dead widget)
4. The code was written but never actually compiled into the deployed build (stale deploy)

**Fix:** Read the actual code flow, add debug logging, trace why `requestPermission()` isn't firing. The most likely fix is ensuring the location request happens BEFORE the banner is dismissed (not after via post-frame callback on a widget that's about to be removed):

```dart
// In _applyConsent or Accept All handler:
Future<void> _handleAcceptAll() async {
  final cookieService = ref.read(cookieServiceProvider);
  cookieService.acceptAll();

  // Update analytics
  ref.read(analyticsServiceProvider).updateConsent(true);

  // Request location BEFORE dismissing banner
  if (cookieService.hasConsent('preferences')) {
    await _requestLocation();
  }

  // NOW dismiss banner (after location request has been initiated)
  ref.read(hasConsentedProvider.notifier).set(true);
}

Future<void> _requestLocation() async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      // Refresh location → triggers nearby recomputation
      ref.invalidate(userLocationProvider);
    }
  } catch (e) {
    debugPrint('Location request failed: $e');
  }
}
```

Key change: `await _requestLocation()` is called BEFORE `ref.read(hasConsentedProvider.notifier).set(true)` — so the banner is still mounted when the location request fires.

---

## Step 0: Pre-Flight

```bash
cd ~/dev/projects/tripledb

# Verify project
ls app/lib/providers/location_providers.dart
ls app/lib/widgets/cookie_consent_banner.dart

# Baseline build
cd app
flutter analyze
flutter build web

# Initialize checkpoint
mkdir -p ~/dev/projects/tripledb/pipeline/data/checkpoints
```

Check for existing checkpoint (resume support).

**Write checkpoint after Step 0.**

---

## Step 1: Read Current Code + Diagnose All Three Bugs

### 1a. Read nearby provider

```bash
cat ~/dev/projects/tripledb/app/lib/providers/location_providers.dart
```

Or whichever file contains the `nearbyRestaurants` provider. Document:
- What filtering is applied (stillOpen, latitude, etc.)
- Whether city/state validation exists
- Whether deduplication exists
- How the list is sorted and truncated

### 1b. Read cookie consent banner

```bash
cat ~/dev/projects/tripledb/app/lib/widgets/cookie_consent_banner.dart
```

Document:
- What "Accept All" calls
- Whether `_requestLocationAfterConsent()` exists
- Whether location request happens before or after banner dismissal
- Whether `Geolocator` is imported

### 1c. Read restaurant model

```bash
cat ~/dev/projects/tripledb/app/lib/models/restaurant_models.dart
```

Check: Is `city` nullable? How does `fromFirestore` handle null/empty city values?

### 1d. Check for Belly and Snout duplicates in Firestore

```bash
cd ~/dev/projects/tripledb/pipeline
python3 -c "
import json
restaurants = [json.loads(l) for l in open('data/normalized/restaurants.jsonl')]
belly = [r for r in restaurants if 'belly' in r.get('name','').lower() and 'snout' in r.get('name','').lower()]
for r in belly:
    print(f\"{r.get('restaurant_id')} | {r.get('name')} | {r.get('city')} | {r.get('state')} | lat={r.get('latitude')}\")
print(f'Count: {len(belly)}')
"
```

Log all findings for each bug.

**Write checkpoint after Step 1.**

---

## Step 2: Fix Bug 1 — Filter Unknown City/State from Nearby

In the `nearbyRestaurants` provider (likely in `location_providers.dart`):

Add a helper function:

```dart
bool _hasValidLocation(Restaurant r) {
  if (r.latitude == null || r.longitude == null) return false;
  if (r.city == null || r.city!.isEmpty) return false;
  if (r.state == null || r.state!.isEmpty) return false;
  final invalidValues = ['unknown', 'none', 'n/a', 'null'];
  if (invalidValues.contains(r.city!.toLowerCase())) return false;
  if (invalidValues.contains(r.state!.toLowerCase())) return false;
  return true;
}
```

Use it in the nearby provider:

```dart
final validRestaurants = restaurants.where((r) =>
  r.stillOpen != false && _hasValidLocation(r)
).toList();
```

This also applies to search results with proximity sorting — unknown-city restaurants shouldn't appear with distances.

**Write checkpoint after Step 2.**

---

## Step 3: Fix Bug 2 — Deduplicate Nearby Results

In the same nearby provider, after sorting by distance and before taking top N:

```dart
// Deduplicate by restaurant_id
final seen = <String>{};
final deduped = <NearbyRestaurant>[];
for (final nr in sorted) {
  final id = nr.restaurant.restaurantId;
  if (id != null && seen.add(id)) {
    deduped.add(nr);
  }
}
return deduped.take(nearbyCount).toList();
```

This keeps the closest instance of any duplicate and discards the rest.

**Write checkpoint after Step 3.**

---

## Step 4: Fix Bug 3 — Accept All → Location Permission

### 4a. Read the current Accept All flow

Trace exactly what happens when the user taps "Accept All":
1. Which callback fires?
2. Does it call `_applyConsent` or a separate function?
3. Is `_requestLocationAfterConsent` called?
4. Is `Geolocator` imported in the file?
5. Does the banner dismiss BEFORE or AFTER the location request?

### 4b. Add debug logging (temporary)

```dart
print('🍪 ACCEPT_ALL tapped');
print('🍪 Preferences consent: ${prefs['preferences']}');
print('🍪 About to request location...');
// ... location request code ...
print('🍪 Location request completed');
print('🍪 Dismissing banner');
```

### 4c. Apply the fix

The most likely issue is the banner dismissing before the location request fires. Fix by making the Accept All handler async and awaiting the location request before dismissing:

```dart
Future<void> _handleAcceptAll() async {
  final prefs = {'essential': true, 'analytics': true, 'preferences': true};

  // 1. Save cookie
  final cookieService = ref.read(cookieServiceProvider);
  cookieService.setPreferences(prefs);

  // 2. Update analytics consent
  final analyticsService = ref.read(analyticsServiceProvider);
  await analyticsService.updateConsent(true);
  await analyticsService.logConsentGiven(prefs);

  // 3. Request location BEFORE dismissing banner
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled) {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        ref.invalidate(userLocationProvider);
      }
    }
  } catch (e) {
    debugPrint('Location request failed: $e');
  }

  // 4. NOW dismiss banner
  ref.read(hasConsentedProvider.notifier).set(true);
}
```

### 4d. Remove debug logging

After confirming the fix works, remove all `🍪` prints.

### 4e. Rebuild

```bash
cd ~/dev/projects/tripledb/app
dart run build_runner build --delete-conflicting-outputs
flutter analyze   # 0 errors
flutter build web
```

**Write checkpoint after Step 4.**

---

## Step 5: Post-Flight — Tier 1 (Standard Health)

```bash
cd ~/dev/projects/tripledb/app
python3 -m http.server 8080 -d build/web &
SERVER_PID=$!
sleep 3
```

**GATE 1: App Bootstraps**
- Navigate to http://localhost:8080, wait 10s
- NOT white screen, accessibility tree has content

**GATE 2: Console Clean**
- 0 uncaught errors

**GATE 3: Changelog**
```bash
grep -c '^\*\*v' ~/dev/projects/tripledb/README.md
# ≥ 24
```

---

## Step 6: Post-Flight — Tier 2 (Iteration Playbook)

### TEST 1: No "Unknown" in Nearby Results (BUG 1 FIX)

```
CONTEXT: App loaded (any context)
ACTION:  Navigate to the List/Home tab
CHECK:   Read accessibility tree or page content for "Nearby Restaurants" section
EXPECT:  ZERO cards showing "Unknown" in the city or state fields
         All nearby cards have real city names (e.g., "Temecula, CA", "Long Beach, CA")
PASS:    No "Unknown" text in nearby section
FAIL:    Any card shows "Unknown" city or state
```

### TEST 2: No Duplicate Restaurants in Nearby (BUG 2 FIX)

```
CONTEXT: Same session
ACTION:  Read all restaurant names in the Nearby section
CHECK:   Count occurrences of each name
EXPECT:  Every restaurant name appears AT MOST ONCE
PASS:    No duplicates
FAIL:    Any restaurant name appears more than once
```

### TEST 3: Cookie Banner Accept → Location Permission (BUG 3 FIX)

```
CONTEXT: Fresh browser context (no cookies)
ACTION:  Navigate to http://localhost:8080
WAIT:    10s for Flutter load
CHECK:   Cookie banner visible
ACTION:  Click "Accept All"
WAIT:    3s
CHECK 1: Banner dismissed
CHECK 2: Geolocation permission was requested (check via page.evaluate
         or verify that the browser's permission state for geolocation
         changed from 'prompt' to 'granted' or that an API call was made)
PASS:    Banner dismissed AND location was requested
FAIL:    Banner didn't dismiss, OR location was never requested
```

**Note on verifying location request in headless:** In headless Puppeteer/Playwright, geolocation permissions can be pre-granted:

```javascript
const context = await browser.createBrowserContext();
// DON'T grant geolocation — we want to verify the app REQUESTS it
const page = await context.newPage();

// Listen for permission requests
page.on('dialog', dialog => {
  console.log('PERMISSION DIALOG:', dialog.message());
});

// Or check if Geolocation API was called
await page.evaluateOnNewDocument(() => {
  const original = navigator.geolocation.getCurrentPosition;
  navigator.geolocation.getCurrentPosition = function(...args) {
    console.log('GEOLOCATION_REQUESTED');
    return original.apply(this, args);
  };
});
```

If headless testing can't verify location was requested, log this as "requires manual verification" and provide instructions for Kyle.

### TEST 4: Cookie Banner Accept → Cookie Persists

```
CONTEXT: Same session as Test 3
ACTION:  Reload page
CHECK:   Banner does NOT reappear
PASS:    Cookie persisted
FAIL:    Banner shows again
```

### TEST 5: Decline Path Still Works

```
CONTEXT: Fresh browser context
ACTION:  Navigate, wait for banner, click "Decline"
CHECK:   document.cookie contains tripledb_consent with analytics:false, preferences:false
PASS:    Decline correctly restricts
FAIL:    Wrong values or no cookie
```

### Playbook Results Table

| Test | Bug | Description | Result | Notes |
|------|-----|------------|--------|-------|
| 1 | Bug 1 | No "Unknown" in nearby | | |
| 2 | Bug 2 | No duplicates in nearby | | |
| 3 | Bug 3 | Accept All → location request | | |
| 4 | — | Cookie persists on reload | | |
| 5 | — | Decline writes correct prefs | | |

**Tests 1-3 are BUG-SPECIFIC. If any fail, the bug isn't fixed — go back to Step 2/3/4.**

```bash
kill $SERVER_PID 2>/dev/null
```

**Write checkpoint after Step 6.**

---

## Step 7: Update README

```bash
cd ~/dev/projects/tripledb
```

APPEND changelog entry:

```markdown
**v9.39 (Phase 9 — Nearby Filtering + Location Consent Fix)**
- **Bug 1 fix:** Filtered "Unknown" city/state restaurants from nearby results. Only restaurants
  with valid, real city and state values appear in "Nearby Restaurants" and proximity-sorted search.
- **Bug 2 fix:** Deduplicated nearby results by restaurant_id. No restaurant appears twice.
- **Bug 3 fix:** Accept All cookie consent now correctly triggers browser location permission
  request before dismissing the banner. Location grant populates "Nearby Restaurants" immediately.
- **Design doc:** Comprehensive living ADR with Eight Pillars, full environment setup guide,
  complete project state, and work remaining to MVP.
```

Verify:
```bash
grep -c '^\*\*v' README.md   # ≥ 24
grep 'v0.7' README.md | head -1
grep 'v9.39' README.md | head -1
```

Update: iteration history, phase 9 status, footer.

**Write checkpoint after Step 7.**

---

## Step 8: Generate Artifacts + Cleanup

### docs/ddd-build-v9.39.md (MANDATORY — FULL TRANSCRIPT)

Must include:
- Pre-flight output
- Code analysis for all three bugs (exact code found, exact problem identified)
- Belly and Snout Firestore duplicate investigation results
- Code changes for each bug fix
- Debug logging + removal
- Build output
- Tier 1 + Tier 2 playbook results

### docs/ddd-report-v9.39.md (MANDATORY)

Must include:
1. Bug 1: root cause + fix + verification
2. Bug 2: root cause + fix + verification (include Firestore duplicate findings)
3. Bug 3: root cause + fix + verification
4. Post-flight: Tier 1 gates + Tier 2 playbook table
5. Changelog: entry count
6. **Orchestration Report:** tools used, workload %, efficacy (Pillar 1 requirement)
7. Interventions: target 0
8. Claude's Recommendation

Delete checkpoint.

---

## Success Criteria

```
[ ] Pre-flight passes
[ ] Bug 1 fixed: No "Unknown" city/state in nearby results
[ ] Bug 2 fixed: No duplicate restaurants in nearby results
[ ] Bug 3 fixed: Accept All triggers location permission
[ ] Debug logging removed
[ ] flutter analyze: 0 errors
[ ] flutter build web: success
[ ] TIER 1: App loads, console clean, changelog ≥ 24
[ ] TIER 2 PLAYBOOK:
    [ ] Test 1: No "Unknown" in nearby (BUG 1)
    [ ] Test 2: No duplicates (BUG 2)
    [ ] Test 3: Accept All → location request (BUG 3)
    [ ] Test 4: Cookie persists
    [ ] Test 5: Decline correct
[ ] README changelog ≥ 24 entries
[ ] Orchestration report in ddd-report
[ ] Artifacts generated
[ ] Interventions: 0
```

---

## Launch Sequence

```bash
cd ~/dev/projects/tripledb

# Archive
mv docs/ddd-design-v9.38.md docs/archive/ 2>/dev/null
mv docs/ddd-plan-v9.38.md docs/archive/ 2>/dev/null
mv docs/ddd-report-v9.38.md docs/archive/ 2>/dev/null
mv docs/ddd-build-v9.38.md docs/archive/ 2>/dev/null

# Place new docs
cp /path/to/ddd-design-v9.39.md docs/
cp /path/to/ddd-plan-v9.39.md docs/

# Update CLAUDE.md
cat > CLAUDE.md << 'EOF'
# TripleDB — Agent Instructions

## Current Iteration: 9.39

Three bug fixes: Unknown city in nearby, duplicate restaurants, Accept All → location.

1. docs/ddd-design-v9.39.md — Full living ADR
2. docs/ddd-plan-v9.39.md — Bug fix steps + playbook

## MCP Servers
- Playwright MCP: Post-flight functional testing
- Context7: Flutter/Dart docs

## Rules
- NEVER git add/commit/push or firebase deploy
- YOLO mode — code dangerously, never ask permission
- POST-FLIGHT: Tier 1 + Tier 2 playbook must pass
- CHANGELOG ≥ 24 entries
- Include Orchestration Report in ddd-report
EOF

# Commit
git add .
git commit -m "KT starting 9.39 — nearby filtering + location consent fix"

# Launch YOLO
claude --dangerously-skip-permissions
```

Then: `Read CLAUDE.md and execute.`

After completion:
```bash
cd ~/dev/projects/tripledb
git add .
git commit -m "KT completed 9.39 — nearby fixed, location consent working"
git push

cd app && flutter build web && firebase deploy --only hosting

# VERIFY in incognito:
# 1. No "Unknown" cities in nearby results
# 2. No duplicate restaurants
# 3. Accept All → location prompt fires → nearby populates with distances
```
