# TripleDB — Phase 7 Plan v7.34

**Phase:** 7 — Enrichment
**Iteration:** 34 (global)
**Date:** March 2026
**Goal:** Implement cookie consent system with accept/deny/customize, wire Firebase Analytics with consent mode v2, polish enrichment data (tighten name-change threshold, resolve UNCERTAIN records, consolidate logs).

---

## Read Order

```
1. docs/ddd-design-v7.34.md — Cookie architecture, analytics events, enrichment polish spec
2. docs/ddd-plan-v7.34.md — This file. Execution steps.
```

Read both before executing. Log confirmation in build log.

---

## Autonomy Rules

```
1. AUTO-PROCEED between ALL steps. NEVER ask permission.
2. SELF-HEAL: diagnose → fix → re-run (max 3, then skip).
3. SYSTEMIC FAILURE: 3 consecutive identical errors = STOP.
4. Git READ allowed. Git WRITE and firebase deploy FORBIDDEN.
5. flutter build web and flutter run ARE ALLOWED.
6. MCP: Context7 ALLOWED. No other MCP servers.
7. FULL PROJECT ACCESS: read/write ANYWHERE under ~/dev/projects/tripledb/.
8. MANDATORY ARTIFACTS before session ends:
   a. docs/ddd-build-v7.34.md — FULL transcript
   b. docs/ddd-report-v7.34.md — metrics, recommendation
   c. README.md — COMPREHENSIVE update at PROJECT ROOT
9. CHECKPOINT after every numbered step → pipeline/data/checkpoints/v7.34_checkpoint.json
10. $GOOGLE_PLACES_API_KEY must be set for enrichment polish steps.
    If not set, print error and HALT. Do NOT ask interactively.
```

---

## Step 0: Pre-Flight + Checkpoint Setup

```bash
cd ~/dev/projects/tripledb

# Verify project structure
ls -la app/lib/main.dart pipeline/scripts/ docs/ README.md

# Check current Firebase dependencies
grep -E "firebase_core|firebase_analytics" app/pubspec.yaml

# Check if firebase_analytics is already a dependency
# If not, we'll add it in Step 2

# Verify Flutter SDK
cd app
flutter --version
flutter pub get
flutter analyze

# Initialize checkpoint
cd ~/dev/projects/tripledb/pipeline
mkdir -p data/checkpoints
```

Initialize checkpoint system (reuse `checkpoint_tool.py` from v7.33 or write inline):

```python
import json
from datetime import datetime, timezone
from pathlib import Path

CP = Path("data/checkpoints/v7.34_checkpoint.json")

def write_cp(step, name, metrics=None):
    CP.parent.mkdir(parents=True, exist_ok=True)
    CP.write_text(json.dumps({"iteration": "7.34", "last_completed_step": step,
        "step_name": name, "timestamp": datetime.now(timezone.utc).isoformat(),
        "metrics": metrics or {}}, indent=2))
    print(f"  [CHECKPOINT] Step {step} ({name}) saved.")

# Check for existing checkpoint
cp = json.loads(CP.read_text()) if CP.exists() else None
if cp:
    print(f"  [RESUME] Steps 0-{cp['last_completed_step']} complete. Starting Step {cp['last_completed_step']+1}.")
else:
    print("  [FRESH START]")
```

**Write checkpoint after Step 0.**

---

## Step 1: Build Cookie Consent Service

```bash
cd ~/dev/projects/tripledb/app
```

### 1a. Create `lib/services/cookie_consent_service.dart`

This service reads/writes the `tripledb_consent` browser cookie and exposes consent state to the rest of the app.

```dart
// lib/services/cookie_consent_service.dart

// IMPORTANT: dart:html is web-only. Guard with conditional import or kIsWeb.
import 'dart:convert';
import 'dart:html' as html;  // Web-only

class CookieConsentService {
  static const String _cookieName = 'tripledb_consent';
  static const int _expiryDays = 365;

  // Default: all optional categories OFF (GDPR-compliant)
  static const Map<String, bool> _defaults = {
    'essential': true,      // Always on, not toggleable
    'analytics': false,     // Firebase Analytics — opt-in
    'preferences': false,   // Dark mode, location, search history — opt-in
  };

  Map<String, bool> _current = {};

  CookieConsentService() {
    _current = _readCookie() ?? {};
  }

  /// Whether the consent banner has been shown (cookie exists)
  bool get hasConsented => _current.isNotEmpty;

  /// Check consent for a specific category
  bool hasConsent(String category) {
    if (category == 'essential') return true;
    return _current[category] ?? _defaults[category] ?? false;
  }

  /// Get all current preferences
  Map<String, bool> get currentPreferences =>
      Map.from(_defaults)..addAll(_current);

  /// Accept all cookies
  void acceptAll() {
    _current = {'essential': true, 'analytics': true, 'preferences': true};
    _writeCookie();
  }

  /// Decline all optional cookies
  void declineAll() {
    _current = {'essential': true, 'analytics': false, 'preferences': false};
    _writeCookie();
  }

  /// Set custom preferences
  void setPreferences(Map<String, bool> prefs) {
    _current = {'essential': true, ...prefs};
    _current['essential'] = true;  // Force essential on
    _writeCookie();
  }

  Map<String, bool>? _readCookie() {
    final cookies = html.document.cookie ?? '';
    for (final cookie in cookies.split(';')) {
      final parts = cookie.trim().split('=');
      if (parts.length == 2 && parts[0].trim() == _cookieName) {
        try {
          final decoded = Uri.decodeComponent(parts[1]);
          return Map<String, bool>.from(jsonDecode(decoded));
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }

  void _writeCookie() {
    final value = Uri.encodeComponent(jsonEncode(_current));
    final expiry = DateTime.now().add(Duration(days: _expiryDays));
    final expires = expiry.toUtc().toIso8601String();
    html.document.cookie =
        '$_cookieName=$value; expires=$expires; path=/; SameSite=Lax; Secure';
  }
}
```

**IMPORTANT for Gemini:** The `dart:html` import makes this file web-only. If the app ever targets mobile, this needs conditional imports. For now (Flutter Web only), this is fine. Use Context7 to verify `dart:html` cookie handling in Flutter Web if needed.

### 1b. Create `lib/widgets/cookie_consent_banner.dart`

A bottom-sheet banner that appears on first visit. Three buttons: Accept All, Decline, Customize.

**Styling requirements:**
- Background: `#1E1E1E` (dark surface)
- Accent: `#DA7E12` (DDD orange) for Accept All button
- Text: white, Inter font, 14px body
- Position: bottom of screen, above bottom nav
- Z-index: above everything (use Overlay or positioned Stack)
- Animate in from bottom on first show
- "Customize" opens a modal with toggle switches for each category

```dart
// Key structure:
class CookieConsentBanner extends StatelessWidget {
  // Shows:
  // "🍪 We use cookies to improve your experience."
  // "Essential cookies keep the app working. Analytics cookies help us
  //  understand which features you use most."
  //
  // [Accept All]  [Decline]  [Customize]
  //
  // Accept All: orange filled button
  // Decline: text button
  // Customize: text button → opens modal
}

class CookieSettingsModal extends StatelessWidget {
  // Shows toggle switches:
  // Essential — ON (greyed out, not toggleable)
  // Analytics — OFF (toggleable)
  // Preferences — OFF (toggleable)
  //
  // [Save Preferences] button
}
```

### 1c. Wire into `main.dart`

In `lib/main.dart` or the root widget:
1. Initialize `CookieConsentService` early (before Firebase Analytics init)
2. If `!cookieService.hasConsented` → show `CookieConsentBanner` as an overlay
3. After user responds → dismiss banner, apply consent to Firebase Analytics

### 1d. Add "Manage Cookies" link

In the app's footer or settings area (wherever feels natural — possibly in the Explore tab or a settings icon), add a "Manage cookies" link that re-opens the `CookieSettingsModal` so returning users can change preferences.

**Write checkpoint after Step 1.**

---

## Step 2: Integrate Firebase Analytics with Consent Mode v2

### 2a. Add firebase_analytics dependency

```bash
cd ~/dev/projects/tripledb/app
```

Check version compatibility first using Context7:
- Current: `firebase_core: 3.x`
- Need: `firebase_analytics` compatible with `firebase_core 3.x`

Add to `pubspec.yaml`:
```yaml
dependencies:
  firebase_analytics: ^11.0.0  # Verify exact version with Context7
```

```bash
flutter pub get
```

### 2b. Create `lib/services/analytics_service.dart`

```dart
// lib/services/analytics_service.dart

import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  bool _enabled = false;

  /// Call this ONCE on app start, BEFORE any events
  Future<void> initialize({required bool analyticsConsent}) async {
    _enabled = analyticsConsent;
    await _analytics.setConsent(
      analyticsStorage: analyticsConsent
          ? ConsentStatus.granted
          : ConsentStatus.denied,
    );
    // Also set ad-related consent to denied (we don't use ads)
    // If setConsent supports ad_storage, set it to denied
  }

  /// Update consent (e.g., user changes cookie preferences)
  Future<void> updateConsent(bool granted) async {
    _enabled = granted;
    await _analytics.setConsent(
      analyticsStorage: granted
          ? ConsentStatus.granted
          : ConsentStatus.denied,
    );
  }

  /// Track page view
  Future<void> logPageView(String pageName) async {
    if (!_enabled) return;
    await _analytics.logEvent(name: 'page_view', parameters: {
      'page_name': pageName,
    });
  }

  /// Track search
  Future<void> logSearch(String term, int resultCount) async {
    if (!_enabled) return;
    await _analytics.logEvent(name: 'search', parameters: {
      'search_term': term,
      'result_count': resultCount,
    });
  }

  /// Track restaurant detail view
  Future<void> logViewRestaurant(String id, String name) async {
    if (!_enabled) return;
    await _analytics.logEvent(name: 'view_restaurant', parameters: {
      'restaurant_id': id,
      'restaurant_name': name,
    });
  }

  /// Track filter toggle
  Future<void> logFilterToggle(String filterName, bool enabled) async {
    if (!_enabled) return;
    await _analytics.logEvent(name: 'filter_toggle', parameters: {
      'filter_name': filterName,
      'enabled': enabled.toString(),
    });
  }

  /// Track external link tap
  Future<void> logExternalLink(String linkType) async {
    if (!_enabled) return;
    await _analytics.logEvent(name: 'external_link', parameters: {
      'link_type': linkType,
    });
  }

  /// Track consent response
  Future<void> logConsentGiven(Map<String, bool> prefs) async {
    // Always log consent events (even if analytics denied, this is essential)
    await _analytics.logEvent(name: 'consent_given', parameters: {
      'analytics': (prefs['analytics'] ?? false).toString(),
      'preferences': (prefs['preferences'] ?? false).toString(),
    });
  }
}
```

### 2c. Wire analytics into the app

**Provide via Riverpod:**
Create a provider for `AnalyticsService` and `CookieConsentService` so they're accessible throughout the app.

**Add analytics calls to:**
- Tab navigation (Map, List, Explore) → `logPageView`
- Search bar submission → `logSearch`
- Restaurant card tap → `logViewRestaurant`
- "Show closed" toggle → `logFilterToggle`
- Website/Maps/YouTube link taps → `logExternalLink`
- Detail page open → `logViewRestaurant`

**Consent flow in main.dart:**
```dart
// 1. Initialize Firebase
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

// 2. Read cookie consent
final cookieService = CookieConsentService();

// 3. Set consent BEFORE any analytics
final analyticsService = AnalyticsService();
await analyticsService.initialize(
  analyticsConsent: cookieService.hasConsent('analytics'),
);

// 4. If first visit, show banner
// (handled by widget layer — banner calls analyticsService.updateConsent on response)
```

### 2d. Enable Firebase Analytics in Firebase Console

This is a Kyle-side step. The plan should note:
- Go to Firebase Console → tripledb-e0f77 → Analytics
- Enable Google Analytics if not already enabled
- Link to a Google Analytics property (or create one)
- The Flutter SDK handles the rest once enabled

**If Analytics is already enabled on the project, no action needed.**

### 2e. Verify Firebase Analytics configuration

After wiring, check `web/index.html` for the Firebase config. The `firebase_analytics` package should auto-configure via `flutterfire configure`, but verify that the measurement ID or analytics config is present.

```bash
grep -i "analytics\|measurement" app/web/index.html
grep -i "analytics" app/lib/firebase_options.dart
```

**Write checkpoint after Step 2.**

---

## Step 3: Enrichment Polish

```bash
cd ~/dev/projects/tripledb/pipeline
```

### 3a. Tighten name-change threshold to 0.90

The v7.33 backfill stored `name_similarity` in `data/enriched/name_backfill.jsonl`. Re-classify records:

```python
import json
import firebase_admin
from firebase_admin import firestore

if not firebase_admin._apps:
    firebase_admin.initialize_app()
db = firestore.client()

# Read backfill data
records = [json.loads(l) for l in open('data/enriched/name_backfill.jsonl')]
print(f'Total name backfill records: {len(records)}')

# Reclassify at 0.90 threshold (was 0.95)
reclassified = 0
still_changed = 0
for rec in records:
    rid = rec['restaurant_id']
    sim = rec.get('name_similarity', 1.0)
    old_changed = rec.get('name_changed', False)
    new_changed = sim < 0.90

    if old_changed and not new_changed:
        # Was flagged as changed at 0.95, but not at 0.90 → suppress AKA display
        db.collection('restaurants').document(rid).set(
            {'name_changed': False}, merge=True)
        reclassified += 1
    elif new_changed:
        still_changed += 1

print(f'Reclassified (0.95→0.90): {reclassified} records now name_changed=false')
print(f'Still name_changed=true: {still_changed}')
print(f'Expected: ~{still_changed} genuine rebrands/renames shown in app')
```

Log the reclassification count and verify a few examples.

### 3b. Resolve 26 UNCERTAIN records

```python
import json
import firebase_admin
from firebase_admin import firestore
from google.cloud.firestore_v1 import DELETE_FIELD

if not firebase_admin._apps:
    firebase_admin.initialize_app()
db = firestore.client()

# Read verified log
verified = [json.loads(l) for l in open('data/logs/phase7-verified.jsonl')]
uncertain = [r for r in verified if r.get('classification') == 'UNCERTAIN']
print(f'UNCERTAIN records: {len(uncertain)}')

keep = []
remove = []
for rec in uncertain:
    rid = rec['restaurant_id']
    score = rec.get('match_score', 0)
    if score >= 0.80:
        keep.append(rec)
    else:
        remove.append(rec)

print(f'Keep (score >= 0.80): {len(keep)}')
print(f'Remove (score < 0.80): {len(remove)}')

# Remove enrichment from low-confidence UNCERTAIN records
remove_fields = {
    'google_place_id': DELETE_FIELD, 'google_rating': DELETE_FIELD,
    'google_rating_count': DELETE_FIELD, 'google_maps_url': DELETE_FIELD,
    'website_url': DELETE_FIELD, 'formatted_address': DELETE_FIELD,
    'business_status': DELETE_FIELD, 'still_open': DELETE_FIELD,
    'photo_references': DELETE_FIELD, 'enriched_at': DELETE_FIELD,
    'enrichment_source': DELETE_FIELD, 'enrichment_match_score': DELETE_FIELD,
    'google_current_name': DELETE_FIELD, 'name_changed': DELETE_FIELD,
}

for rec in remove:
    rid = rec['restaurant_id']
    db.collection('restaurants').document(rid).update(remove_fields)
    print(f'  Cleaned: {rec.get("name", rid)}')

# Log resolution
with open('data/logs/phase7-uncertain-resolved.jsonl', 'w') as f:
    for rec in keep:
        rec['resolution'] = 'kept'
        f.write(json.dumps(rec) + '\n')
    for rec in remove:
        rec['resolution'] = 'removed'
        f.write(json.dumps(rec) + '\n')

print(f'Resolution logged to phase7-uncertain-resolved.jsonl')
```

### 3c. Consolidate enrichment logs

```python
import json, glob
from pathlib import Path

log_dir = Path('data/logs')
summary = {
    'enrichment_phase': '7.30-7.34',
    'total_restaurants': 1102,
    'log_files': {}
}

for logfile in sorted(log_dir.glob('phase7-*.jsonl')):
    count = sum(1 for _ in open(logfile))
    summary['log_files'][logfile.name] = count

# Count final enriched in Firestore (from enriched JSONL as proxy)
enriched_path = Path('data/enriched/restaurants_enriched.jsonl')
if enriched_path.exists():
    enriched = [json.loads(l) for l in open(enriched_path)]
    summary['enriched_records'] = len(enriched)
    summary['with_rating'] = sum(1 for r in enriched if r.get('google_rating'))
    summary['permanently_closed'] = sum(1 for r in enriched if r.get('business_status') == 'CLOSED_PERMANENTLY')

with open(log_dir / 'phase7-enrichment-summary.json', 'w') as f:
    json.dump(summary, f, indent=2)

print(json.dumps(summary, indent=2))
```

**Write checkpoint after Step 3.**

---

## Step 4: Build, Test, Verify

```bash
cd ~/dev/projects/tripledb/app

flutter pub get
flutter analyze
flutter build web
```

Both must pass with 0 errors.

Optionally `flutter run -d chrome` and verify:
- [ ] Cookie consent banner appears on first load
- [ ] "Accept All" dismisses banner, enables analytics
- [ ] "Decline" dismisses banner, disables analytics
- [ ] "Customize" opens modal with category toggles
- [ ] On page reload, banner does NOT reappear (cookie persists)
- [ ] "Manage cookies" link accessible somewhere in the app
- [ ] Firebase Analytics events visible in Firebase Console debug view
  (Note: may take up to 24 hours to appear in production; debug view is near-real-time)
- [ ] Closed restaurants still show grey pins and badges correctly
- [ ] Name changes reflect tightened threshold (fewer "Now known as" labels)
- [ ] Non-enriched restaurants unaffected by changes

Log pass/fail for each item.

**Write checkpoint after Step 4.**

---

## Step 5: Update README.md

```bash
cd ~/dev/projects/tripledb
```

### 5a. Project Status

```
| 7 | Enrichment + Analytics | ✅ Complete | v7.30–v7.34 |
```

### 5b. Current Metrics

Update with actual numbers:
```markdown
### Live Dataset (tripledb.net)
- **1,102** unique restaurants across **62** states and territories
- **~XXX** restaurants enriched with Google ratings and open/closed status
- **~XX** genuine name changes displayed (tightened from 0.90 threshold)
- **30** permanently closed restaurants identified
- **1,006** restaurants with map coordinates (91.3%)
- Cookie consent with accept/deny/customize
- Firebase Analytics with consent mode v2
```

### 5c. IAO Iteration History

Add v7.34:
```
| v7.34 | Cookies + Analytics + Polish | ✅ | Cookie consent banner, Firebase Analytics consent mode v2, name threshold tightened to 0.90, 26 UNCERTAIN resolved. |
```

### 5d. Changelog

```markdown
**v7.33 → v7.34 (Phase 7 Cookies + Analytics + Polish)**
- **Cookies:** GDPR/CCPA-compliant cookie consent banner with accept/deny/customize.
  Three categories: Essential (always on), Analytics (opt-in), Preferences (opt-in).
  Returning visitors recognized via persistent cookie.
- **Analytics:** Firebase Analytics integrated with consent mode v2. Tracking page views,
  searches, restaurant views, filter toggles, and external link taps — only when user consents.
- **Polish:** Name-change threshold tightened from 0.95 to 0.90, reducing false "Now known as"
  labels. 26 UNCERTAIN records resolved (X kept, X removed). Enrichment logs consolidated.
```

### 5e. Tech Stack

Add:
```
| Analytics | Firebase Analytics | Page views, search, restaurant views (consent-gated) |
| Privacy | Custom cookie consent | GDPR/CCPA-compliant, 3 categories, 365-day cookie |
```

### 5f. Footer

```markdown
*Last updated: Phase 7.34 — Cookies + Analytics + Enrichment Polish*
```

### 5g. Verify

```bash
grep "7.34" README.md | head -3
grep -i "cookie\|consent\|analytics" README.md | head -5
grep "Last updated" README.md
```

**Write checkpoint after Step 5.**

---

## Step 6: Generate Artifacts + Cleanup

### docs/ddd-build-v7.34.md (MANDATORY — FULL TRANSCRIPT)

Must include:
- Pre-flight output
- Cookie consent service creation (files created, key code)
- Firebase Analytics integration (dependency added, version, consent wiring)
- Enrichment polish results (reclassified count, UNCERTAIN resolution, log consolidation)
- flutter analyze + build output
- Verification results (pass/fail checklist)
- README changes summary
- Errors and fixes

**Write to:** `~/dev/projects/tripledb/docs/ddd-build-v7.34.md`

### docs/ddd-report-v7.34.md (MANDATORY)

Must include:
1. **Cookie consent:** implementation details, categories, banner behavior
2. **Firebase Analytics:** events tracked, consent mode integration, verification
3. **Name-change reclassification:** old count vs new count at 0.90 threshold
4. **UNCERTAIN resolution:** X kept, X removed, reasoning
5. **Enrichment log consolidation:** summary JSON contents
6. **Final enrichment state:** total enriched, total with name_changed, total closed
7. **App build status:** analyze + build results
8. **API cost:** expected $0
9. **Human interventions:** count (target: 0)
10. **Gemini's Recommendation:** Phase 7 complete? What's next?
11. **README Update Confirmation**

**Write to:** `~/dev/projects/tripledb/docs/ddd-report-v7.34.md`

### Cleanup

```python
delete_checkpoint()
```

---

## Success Criteria

```
[ ] Pre-flight passes
[ ] Checkpoint system active
[ ] Cookie consent service created (dart:html cookie read/write)
[ ] Cookie consent banner renders on first visit
[ ] Accept All / Decline / Customize all work correctly
[ ] Cookie persists across page reloads (banner doesn't reappear)
[ ] "Manage cookies" accessible for returning visitors
[ ] firebase_analytics added and compatible with firebase_core 3.x
[ ] Firebase Analytics consent mode v2 integrated
[ ] Analytics events fire ONLY when user has accepted analytics cookies
[ ] Events tracked: page_view, search, view_restaurant, filter_toggle, external_link
[ ] Name-change threshold tightened to 0.90:
    [ ] Fewer restaurants show "Now known as"
    [ ] Genuine rebrands still displayed correctly
[ ] 26 UNCERTAIN records resolved:
    [ ] High-confidence kept
    [ ] Low-confidence removed from Firestore
[ ] Enrichment logs consolidated into summary JSON
[ ] flutter analyze: 0 errors
[ ] flutter build web: success
[ ] README at project root fully updated:
    [ ] Phase 7 status reflects v7.30–v7.34
    [ ] Metrics updated
    [ ] Changelog for v7.34
    [ ] Tech stack includes analytics + privacy
    [ ] Footer: Phase 7.34
[ ] ddd-build-v7.34.md generated (FULL transcript)
[ ] ddd-report-v7.34.md generated
[ ] Checkpoint cleared
[ ] Human interventions: 0
```

---

## Launch Sequence

```bash
# 1. Archive previous iteration
cd ~/dev/projects/tripledb
mv docs/ddd-design-v7.33.md docs/archive/ 2>/dev/null
mv docs/ddd-plan-v7.33.md docs/archive/ 2>/dev/null
mv docs/ddd-report-v7.33.md docs/archive/ 2>/dev/null
mv docs/ddd-build-v7.33.md docs/archive/ 2>/dev/null

# 2. Place new docs
cp /path/to/ddd-design-v7.34.md docs/
cp /path/to/ddd-plan-v7.34.md docs/

# 3. Verify API key (needed for enrichment polish)
echo $GOOGLE_PLACES_API_KEY

# 4. Optional: Enable Firebase Analytics in Firebase Console
#    Console → tripledb-e0f77 → Analytics → Enable
#    (May already be enabled from initial project setup)

# 5. Update GEMINI.md
nano pipeline/GEMINI.md

# 6. Commit
git add .
git commit -m "KT starting 7.34"

# 7. Launch (in Konsole)
cd pipeline
gemini
```

Then: `Read GEMINI.md and execute.`

After completion:
```bash
cd ~/dev/projects/tripledb
git add .
git commit -m "KT completed 7.34 and README updated"
git push

cd app
flutter build web
firebase deploy --only hosting
```

**NOTE for Kyle:** After deploying, check Firebase Console → Analytics → DebugView to verify events are flowing. Visit tripledb.net, accept cookies, navigate around, and events should appear within minutes in debug mode.
