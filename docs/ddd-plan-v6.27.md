# TripleDB — Design + Plan v6.27

**Phase:** 6 — Bug Fix
**Iteration:** 27 (global)
**Goal:** Fix geolocation (location services) not working on iOS Safari and Android Chrome. The "Top 3 Near You" and map "Near Me" features require browser geolocation API access.

---

## Read Order

```
1. This file (docs/ddd-plan-v6.27.md)
2. app/lib/services/location_service.dart (or equivalent)
3. app/lib/providers/location_providers.dart
4. app/lib/pages/home_page.dart (NearbySection)
5. app/lib/pages/map_page.dart (Near Me FAB)
```

---

## Known Causes of Mobile Geolocation Failure

### 1. Missing HTTPS
Geolocation API requires HTTPS on all modern browsers. Firebase Hosting provides this — verify tripledb.net loads over HTTPS (it should).

### 2. Missing Permissions Headers
Flutter Web needs the geolocation permission policy. Check `app/web/index.html` for:
```html
<meta http-equiv="Permissions-Policy" content="geolocation=(self)">
```

### 3. Geolocator Web Plugin Missing
The `geolocator` package needs the web implementation. Check `pubspec.yaml` for:
```yaml
dependencies:
  geolocator: ^13.0.0  # or whatever version
  geolocator_web: ^4.0.0  # THIS IS OFTEN MISSING
```

If `geolocator_web` is not listed, the web platform has no geolocation implementation and silently fails.

### 4. JavaScript Geolocation Not Loaded
Flutter Web CanvasKit may not auto-include the geolocation JS. Check if the app uses the `geolocator` package's web API or raw `dart:html` / `package:web` for geolocation.

### 5. iOS Safari Specific
Safari requires a user gesture (tap) before requesting geolocation. If the app requests location on page load without user interaction, Safari blocks it silently.

### 6. Permission Request Timing
If the app calls `Geolocator.getCurrentPosition()` before the user taps anything, mobile browsers deny it. The request must be triggered by a user action (button tap).

---

## Autonomy Rules

```
1. AUTO-PROCEED. NEVER ask permission.
2. SELF-HEAL: diagnose → fix → re-run (max 3 attempts, then log).
3. MCP: Context7 ALLOWED for Flutter/geolocator docs.
4. Git READ allowed. Git WRITE forbidden. firebase deploy forbidden.
5. flutter build web and flutter run -d chrome ARE ALLOWED for testing.
6. MANDATORY ARTIFACTS:
   a. docs/ddd-build-v6.27.md
   b. docs/ddd-report-v6.27.md
7. Working directory: app/
```

---

## Step 0: Diagnose

Read ALL of these and log findings:

```bash
# 1. Check if geolocator_web is in pubspec
grep -i "geolocator" pubspec.yaml

# 2. Check web/index.html for permissions policy
grep -i "geolocation\|permission" web/index.html

# 3. Check how location is requested in code
grep -rn "getCurrentPosition\|requestPermission\|isLocationServiceEnabled\|Geolocator" lib/

# 4. Check if location request is tied to user gesture or fires on load
grep -rn "initState\|didChangeDependencies\|build.*location\|onPressed.*location" lib/

# 5. Check for any error handling around geolocation
grep -rn "catch\|LocationPermission\|denied\|serviceDisabled" lib/
```

Log ALL output. Identify which of the 6 known causes applies.

---

## Step 1: Fix Web Index

Ensure `app/web/index.html` has the permissions policy meta tag in the `<head>`:

```html
<meta http-equiv="Permissions-Policy" content="geolocation=(self)">
```

Also ensure there's no Content-Security-Policy blocking geolocation.

---

## Step 2: Fix Dependencies

Ensure `pubspec.yaml` includes the web geolocation plugin:

```yaml
dependencies:
  geolocator: ^13.0.0
  geolocator_web: ^4.0.0
```

Run `flutter pub get` after adding.

---

## Step 3: Fix Permission Flow

The location request MUST follow this pattern for mobile browsers:

```dart
// 1. Check if location services are enabled
bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
if (!serviceEnabled) {
  // Show "Enable location services" message
  return;
}

// 2. Check permission status
LocationPermission permission = await Geolocator.checkPermission();
if (permission == LocationPermission.denied) {
  // Request permission — THIS MUST BE FROM A USER GESTURE (button tap)
  permission = await Geolocator.requestPermission();
  if (permission == LocationPermission.denied) {
    // Show "Location permission denied" message
    return;
  }
}

if (permission == LocationPermission.deniedForever) {
  // Show "Open settings to enable location" message
  return;
}

// 3. Get position
Position position = await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.high,
);
```

**CRITICAL:** Step 2 (requestPermission) MUST be triggered by a user tap, not by page load or initState. If the current code requests permission in a provider's build/init, move it behind the "Enable location" button tap.

---

## Step 4: Test on Chrome Mobile Emulator

```bash
flutter run -d chrome
```

Open Chrome DevTools → Toggle Device Toolbar → select iPhone 12 or Pixel 5. Click the "Enable location" button. Verify the permission prompt appears.

If using `flutter build web` + local server:
```bash
flutter build web
cd build/web
python3 -m http.server 8080
```

Note: localhost geolocation works on Chrome but may not on Safari. The real test is on the deployed HTTPS site.

---

## Step 5: Build and Verify

```bash
flutter analyze
flutter build web
```

---

## Step 6: Generate Artifacts

### docs/ddd-build-v6.27.md
- Diagnostic output from Step 0
- Root cause identified
- Every file changed with what changed and why
- Test results

### docs/ddd-report-v6.27.md
- Root cause (which of the 6 known causes)
- Fix applied
- Files modified
- Test results (Chrome mobile emulator)
- Known limitation: real mobile testing requires HTTPS deploy
- Recommendation: deploy and test on actual iOS/Android device

---

## Success Criteria

```
[ ] Root cause diagnosed and logged
[ ] web/index.html has geolocation permissions policy
[ ] geolocator_web in pubspec.yaml (if missing)
[ ] Location request triggered by user gesture, not page load
[ ] Proper permission denied / service disabled error handling
[ ] flutter analyze: 0 errors
[ ] flutter build web: success
[ ] Chrome mobile emulator shows permission prompt on button tap
[ ] ddd-build-v6.27.md generated
[ ] ddd-report-v6.27.md generated
```

---

## GEMINI.md Content

```markdown
# TripleDB App — Agent Instructions

## Current Iteration: 6.27

Read docs/ddd-plan-v6.27.md then execute. This is a bug fix iteration.

Start by reading the location-related source files listed in the plan,
then run the diagnostic commands in Step 0.

## Rules
- Git READ allowed. Git WRITE and firebase deploy forbidden.
- flutter build web and flutter run ARE ALLOWED for testing.
- Context7 MCP allowed for Flutter/geolocator docs.
- NEVER ask permission — diagnose, fix, test, report.
- MUST produce ddd-build-v6.27.md AND ddd-report-v6.27.md before ending.
```

---

## Launch

```bash
cd ~/dev/projects/tripledb/app
# Place this file in docs/
# Update GEMINI.md
nano GEMINI.md
gemini
```

Then: `Read GEMINI.md and execute.`

After Gemini completes:
```bash
flutter build web
firebase deploy --only hosting
```

Then test on your actual phone — open tripledb.net in Safari/Chrome, tap "Enable location," confirm the permission prompt appears and nearby restaurants populate.
