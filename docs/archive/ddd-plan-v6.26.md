# TripleDB — Phase 6 Plan v6.26

**Phase:** 6 — Firestore Load + App Wiring
**Iteration:** 26 (global)
**Date:** March 2026
**Goal:** Fix UNKNOWN states in normalized data, load 1,102 restaurants into Cloud Firestore, wire the tripledb.net app to read from Firestore instead of sample data.

---

## Read Order (CRITICAL)

```
1. docs/ddd-design-v6.26.md  — Architecture, Firestore schema, state inference
2. docs/ddd-plan-v6.26.md    — This file. Execution steps.
```

Read both before executing. Log confirmation in build log.

---

## Autonomy Rules

```
1. AUTO-PROCEED between all steps. NEVER ask permission.
2. SELF-HEAL: diagnose → fix → re-run (max 3 attempts, then log and skip).
3. MCP: Context7 ALLOWED for Flutter/Dart/Firebase docs. No other MCP servers.
4. Git READ commands allowed (pull, log, status, diff, show).
   Git WRITE commands forbidden. firebase deploy forbidden.
5. flutter build web IS ALLOWED for testing.
6. This iteration works in BOTH pipeline/ and app/ directories.
   Scripts run from pipeline/. Flutter commands run from app/.
7. MANDATORY ARTIFACTS before session ends:
   a. docs/ddd-build-v6.26.md — FULL transcript
   b. docs/ddd-report-v6.26.md — Metrics, Firestore load results
8. Working directory: start in pipeline/ for Steps 0-4, switch to app/ for Steps 5-8.
```

---

## Step 0: Pre-Flight

### 0a. Verify Normalized Data

```bash
cd ~/dev/projects/tripledb/pipeline
wc -l data/normalized/restaurants.jsonl
wc -l data/normalized/videos.jsonl
```

Expected: ~1102 restaurants, ~773 videos.

### 0b. Verify Firebase Credentials

```bash
echo $GOOGLE_CLOUD_PROJECT
# Expected: tripledb-e0f77

echo $GOOGLE_APPLICATION_CREDENTIALS
# Expected: path to service account JSON

test -f "$GOOGLE_APPLICATION_CREDENTIALS" && echo "SA KEY OK" || echo "SA KEY MISSING"
```

If the service account key is missing, check `~/.config/gcloud/tripledb-sa.json`. If that doesn't exist, Kyle needs to download it from Firebase Console → Project Settings → Service Accounts → Generate New Private Key.

### 0c. Verify Firebase Admin SDK

```bash
pip list 2>/dev/null | grep firebase-admin || echo "MISSING — install with: pip install firebase-admin --break-system-packages"
```

If missing:
```bash
pip install firebase-admin --break-system-packages
```

### 0d. Read Input Documents

Read both docs. Log:
```
Read [filename] — [one-line summary]
```

---

## Step 1: Fix UNKNOWN States

Create `scripts/fix_unknown_states.py` in `pipeline/scripts/`:

```python
#!/usr/bin/env python3
"""fix_unknown_states.py — Resolve UNKNOWN states via city-name lookup and video title parsing."""
import json
import os
import re
from collections import Counter

# Major US city → state mapping (top 200+)
CITY_STATE_MAP = {
    "new york": "NY", "los angeles": "CA", "chicago": "IL", "houston": "TX",
    "phoenix": "AZ", "philadelphia": "PA", "san antonio": "TX", "san diego": "CA",
    "dallas": "TX", "san jose": "CA", "austin": "TX", "jacksonville": "FL",
    "fort worth": "TX", "columbus": "OH", "charlotte": "NC", "san francisco": "CA",
    "indianapolis": "IN", "seattle": "WA", "denver": "CO", "washington": "DC",
    "nashville": "TN", "oklahoma city": "OK", "el paso": "TX", "boston": "MA",
    "portland": "OR", "las vegas": "NV", "memphis": "TN", "louisville": "KY",
    "baltimore": "MD", "milwaukee": "WI", "albuquerque": "NM", "tucson": "AZ",
    "fresno": "CA", "sacramento": "CA", "mesa": "AZ", "kansas city": "MO",
    "atlanta": "GA", "omaha": "NE", "colorado springs": "CO", "raleigh": "NC",
    "long beach": "CA", "virginia beach": "VA", "miami": "FL", "oakland": "CA",
    "minneapolis": "MN", "tampa": "FL", "tulsa": "OK", "arlington": "TX",
    "new orleans": "LA", "wichita": "KS", "cleveland": "OH", "bakersfield": "CA",
    "aurora": "CO", "anaheim": "CA", "honolulu": "HI", "santa ana": "CA",
    "riverside": "CA", "corpus christi": "TX", "lexington": "KY", "stockton": "CA",
    "pittsburgh": "PA", "saint paul": "MN", "st. paul": "MN", "anchorage": "AK",
    "cincinnati": "OH", "henderson": "NV", "greensboro": "NC", "plano": "TX",
    "lincoln": "NE", "orlando": "FL", "irvine": "CA", "newark": "NJ",
    "toledo": "OH", "durham": "NC", "chula vista": "CA", "fort wayne": "IN",
    "st. louis": "MO", "saint louis": "MO", "scottsdale": "AZ", "reno": "NV",
    "norfolk": "VA", "gilbert": "AZ", "boise": "ID", "richmond": "VA",
    "spokane": "WA", "des moines": "IA", "montgomery": "AL", "modesto": "CA",
    "fayetteville": "NC", "tacoma": "WA", "shreveport": "LA", "fontana": "CA",
    "moreno valley": "CA", "glendale": "AZ", "akron": "OH", "huntsville": "AL",
    "savannah": "GA", "knoxville": "TN", "charleston": "SC", "key largo": "FL",
    "key west": "FL", "lahaina": "HI", "maui": "HI", "kailua": "HI",
    "geyserville": "CA", "buffalo": "NY", "fairfield": "CT", "portsmouth": "NH",
    "boulder": "CO", "santa fe": "NM", "sedona": "AZ", "asheville": "NC",
    "chattanooga": "TN", "madison": "WI", "providence": "RI", "salt lake city": "UT",
    "birmingham": "AL", "columbia": "SC", "detroit": "MI", "ann arbor": "MI",
    "santa cruz": "CA", "monterey": "CA", "pasadena": "CA", "burbank": "CA",
    "manhattan beach": "CA", "redondo beach": "CA", "hermosa beach": "CA",
    "venice beach": "CA", "brooklyn": "NY", "queens": "NY", "bronx": "NY",
    "harlem": "NY", "hoboken": "NJ", "jersey city": "NJ", "atlantic city": "NJ",
    "cape may": "NJ", "asbury park": "NJ", "newport": "RI", "mystic": "CT",
    "bar harbor": "ME", "portland": "ME", "burlington": "VT",
}

def infer_state(restaurant, videos_by_id):
    """Try to infer state from city name or video title."""
    city = (restaurant.get("city") or "").strip().lower()

    # Direct city lookup
    if city in CITY_STATE_MAP:
        return CITY_STATE_MAP[city]

    # Partial match (city contains a known city name)
    for known_city, state in CITY_STATE_MAP.items():
        if known_city in city or city in known_city:
            return state

    # Video title parsing — look for state names in titles
    state_names = {
        "alabama": "AL", "alaska": "AK", "arizona": "AZ", "arkansas": "AR",
        "california": "CA", "colorado": "CO", "connecticut": "CT", "delaware": "DE",
        "florida": "FL", "georgia": "GA", "hawaii": "HI", "idaho": "ID",
        "illinois": "IL", "indiana": "IN", "iowa": "IA", "kansas": "KS",
        "kentucky": "KY", "louisiana": "LA", "maine": "ME", "maryland": "MD",
        "massachusetts": "MA", "michigan": "MI", "minnesota": "MN", "mississippi": "MS",
        "missouri": "MO", "montana": "MT", "nebraska": "NE", "nevada": "NV",
        "new hampshire": "NH", "new jersey": "NJ", "new mexico": "NM", "new york": "NY",
        "north carolina": "NC", "north dakota": "ND", "ohio": "OH", "oklahoma": "OK",
        "oregon": "OR", "pennsylvania": "PA", "rhode island": "RI", "south carolina": "SC",
        "south dakota": "SD", "tennessee": "TN", "texas": "TX", "utah": "UT",
        "vermont": "VT", "virginia": "VA", "washington": "WA", "west virginia": "WV",
        "wisconsin": "WI", "wyoming": "WY",
    }

    for visit in restaurant.get("visits", []):
        title = (visit.get("video_title") or "").lower()
        for state_name, abbrev in state_names.items():
            if state_name in title:
                return abbrev

    return None

def main():
    restaurants_path = "data/normalized/restaurants.jsonl"
    videos_path = "data/normalized/videos.jsonl"

    # Load videos for title lookup
    videos_by_id = {}
    if os.path.isfile(videos_path):
        with open(videos_path) as f:
            for line in f:
                v = json.loads(line)
                videos_by_id[v.get("video_id")] = v

    # Load and fix restaurants
    restaurants = []
    fixed = 0
    still_unknown = 0
    with open(restaurants_path) as f:
        for line in f:
            r = json.loads(line)
            if r.get("state") == "UNKNOWN" or not r.get("state"):
                inferred = infer_state(r, videos_by_id)
                if inferred:
                    print(f"  Fixed: {r.get('name', '?')} ({r.get('city', '?')}) → {inferred}")
                    r["state"] = inferred
                    fixed += 1
                else:
                    still_unknown += 1
            restaurants.append(r)

    # Write back
    with open(restaurants_path, "w") as f:
        for r in restaurants:
            f.write(json.dumps(r) + "\n")

    # Summary
    states = Counter(r.get("state", "?") for r in restaurants)
    print(f"\n--- State Fix Summary ---")
    print(f"Fixed: {fixed}")
    print(f"Still UNKNOWN: {still_unknown}")
    print(f"Total states: {len(states)}")
    print(f"UNKNOWN remaining: {states.get('UNKNOWN', 0)}")

if __name__ == "__main__":
    main()
```

Run it:

```bash
python3 scripts/fix_unknown_states.py
```

Log the output. Check how many were resolved:

```bash
python3 -c "
import json
from collections import Counter
states = Counter()
for line in open('data/normalized/restaurants.jsonl'):
    r = json.loads(line)
    states[r.get('state', '?')] += 1
print(f'UNKNOWN: {states.get(\"UNKNOWN\", 0)}')
print(f'Total states: {len(states)}')
for s, c in states.most_common(10):
    print(f'  {s}: {c}')
"
```

Target: UNKNOWN < 30 (down from 126).

---

## Step 2: Create Firestore Load Script

Create `scripts/phase6_load_firestore.py` in `pipeline/scripts/`:

```python
#!/usr/bin/env python3
"""phase6_load_firestore.py — Load normalized JSONL into Cloud Firestore."""
import json
import os
import sys
import time
from datetime import datetime

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError:
    print("ERROR: firebase-admin not installed. Run: pip install firebase-admin --break-system-packages")
    sys.exit(1)

def main():
    # Initialize Firebase
    cred_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    if not cred_path or not os.path.isfile(cred_path):
        print(f"ERROR: Service account key not found at {cred_path}")
        print("Set GOOGLE_APPLICATION_CREDENTIALS in fish config")
        sys.exit(1)

    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred, {"projectId": os.environ.get("GOOGLE_CLOUD_PROJECT", "tripledb-e0f77")})
    db = firestore.client()

    now = datetime.utcnow().isoformat() + "Z"

    # Load restaurants
    restaurants_path = "data/normalized/restaurants.jsonl"
    print(f"\n=== Loading restaurants from {restaurants_path} ===")
    restaurant_count = 0
    batch = db.batch()
    batch_count = 0

    with open(restaurants_path) as f:
        for line in f:
            r = json.loads(line)
            doc_id = r.get("restaurant_id", f"r_{restaurant_count}")
            r["created_at"] = now
            r["updated_at"] = now

            ref = db.collection("restaurants").document(doc_id)
            batch.set(ref, r)
            batch_count += 1
            restaurant_count += 1

            # Firestore batch limit is 500
            if batch_count >= 450:
                batch.commit()
                print(f"  Committed batch: {restaurant_count} restaurants so far")
                batch = db.batch()
                batch_count = 0
                time.sleep(0.5)  # Rate limit courtesy

    if batch_count > 0:
        batch.commit()
        print(f"  Committed final batch: {restaurant_count} restaurants total")

    # Load videos
    videos_path = "data/normalized/videos.jsonl"
    print(f"\n=== Loading videos from {videos_path} ===")
    video_count = 0
    batch = db.batch()
    batch_count = 0

    with open(videos_path) as f:
        for line in f:
            v = json.loads(line)
            doc_id = v.get("video_id", f"v_{video_count}")
            v["loaded_at"] = now

            ref = db.collection("videos").document(doc_id)
            batch.set(ref, v)
            batch_count += 1
            video_count += 1

            if batch_count >= 450:
                batch.commit()
                print(f"  Committed batch: {video_count} videos so far")
                batch = db.batch()
                batch_count = 0
                time.sleep(0.5)

    if batch_count > 0:
        batch.commit()
        print(f"  Committed final batch: {video_count} videos total")

    # Summary
    print(f"\n=== Firestore Load Summary ===")
    print(f"Restaurants loaded: {restaurant_count}")
    print(f"Videos loaded: {video_count}")
    print(f"Project: {os.environ.get('GOOGLE_CLOUD_PROJECT', 'unknown')}")
    print(f"Timestamp: {now}")

if __name__ == "__main__":
    main()
```

---

## Step 3: Verify Firebase Setup

Before running the load, verify Firestore is accessible:

```bash
python3 -c "
import firebase_admin
from firebase_admin import credentials, firestore
import os

cred = credentials.Certificate(os.environ['GOOGLE_APPLICATION_CREDENTIALS'])
firebase_admin.initialize_app(cred, {'projectId': 'tripledb-e0f77'})
db = firestore.client()

# Test write
db.collection('_test').document('ping').set({'status': 'ok'})
doc = db.collection('_test').document('ping').get()
print(f'Firestore connection: {\"OK\" if doc.exists else \"FAILED\"}')

# Cleanup
db.collection('_test').document('ping').delete()
print('Test document cleaned up')
"
```

If this fails, troubleshoot before proceeding:
- Check `GOOGLE_APPLICATION_CREDENTIALS` path
- Check that Firestore is enabled in Firebase Console
- Check service account has Firestore permissions

---

## Step 4: Load Data into Firestore

```bash
python3 scripts/phase6_load_firestore.py
```

Expected output: ~1102 restaurants loaded, ~773 videos loaded, in batches of 450.

### Verify Load

```bash
python3 -c "
import firebase_admin
from firebase_admin import credentials, firestore
import os

cred = credentials.Certificate(os.environ['GOOGLE_APPLICATION_CREDENTIALS'])
firebase_admin.initialize_app(cred, {'projectId': 'tripledb-e0f77'})
db = firestore.client()

restaurants = db.collection('restaurants').limit(5).stream()
count = 0
for doc in restaurants:
    d = doc.to_dict()
    print(f'  {d.get(\"name\")} ({d.get(\"city\")}, {d.get(\"state\")}) — {len(d.get(\"dishes\",[]))} dishes')
    count += 1

total = len(list(db.collection('restaurants').stream()))
print(f'\nTotal restaurants in Firestore: {total}')
videos_total = len(list(db.collection('videos').stream()))
print(f'Total videos in Firestore: {videos_total}')
"
```

---

## Step 5: Wire App to Firestore

Switch to the app directory:

```bash
cd ~/dev/projects/tripledb/app
```

### 5a. Add Firebase Dependencies

Add to `pubspec.yaml` if not already present:

```yaml
dependencies:
  firebase_core: ^3.0.0
  cloud_firestore: ^5.0.0
```

```bash
flutter pub get
```

### 5b. Configure FlutterFire

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=tripledb-e0f77
```

This generates `lib/firebase_options.dart`. Follow the prompts — select Web platform.

### 5c. Update main.dart

Add Firebase initialization before `runApp`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: TripleDBApp()));
}
```

### 5d. Update Data Service

Modify `lib/services/data_service.dart` to read from Firestore instead of the local JSON asset:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> loadRestaurants() async {
    final snapshot = await _db.collection('restaurants').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> loadVideos() async {
    final snapshot = await _db.collection('videos').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
```

Adapt this to match the existing provider structure. The key is that the `restaurantProvider` now awaits Firestore instead of loading a JSON asset. The rest of the provider chain (search, nearby, trivia, explore) doesn't change.

### 5e. Keep Sample Data Fallback

Don't remove `assets/data/sample_restaurants.jsonl`. Keep it as a fallback for offline development. The data service can check Firebase availability and fall back to local JSON:

```dart
try {
  return await _loadFromFirestore();
} catch (e) {
  print('Firestore unavailable, falling back to sample data');
  return await _loadFromAsset();
}
```

---

## Step 6: Update Trivia Provider

The trivia widget currently computes from sample data (50 restaurants). With 1,102 restaurants, update the trivia facts to reflect the full dataset. The trivia provider should compute from whatever the data service returns — if it's already doing this, no change needed. If it's hardcoded, fix it.

Verify these facts compute correctly from the live data:
- Total restaurant count (~1,102)
- Total dish count (~2,286)
- Total states (~60+)
- Most-visited restaurant (Full Belly Deli, 16 visits)
- Most common cuisine type
- State with most diners (CA, 124)

---

## Step 7: Build and Test

```bash
cd ~/dev/projects/tripledb/app
flutter analyze
flutter build web
cd build/web
python3 -m http.server 8080
```

Open in browser. Verify:
- [ ] App loads without errors
- [ ] Search returns results from full dataset (not just 50)
- [ ] "brisket" search returns many results (not 5)
- [ ] Trivia shows accurate counts (~1,102 restaurants)
- [ ] Map shows pins across the US (not just a few)
- [ ] Restaurant detail pages load with dishes and visits
- [ ] YouTube timestamp links are formatted correctly

Stop the server after testing.

---

## Step 8: Update README

The root `README.md` is still at v2.11. Update it to reflect the current state. This should include:
- Phase status table updated through v6.26
- Architecture diagram corrected (Gemini Flash, not Ollama)
- Current metrics (1,102 restaurants, 2,286 dishes, 773 videos)
- IAO methodology section (Eight Pillars)
- Changelog entries for v3.12 through v6.26
- tripledb.net domain reference
- Footer: Phase 6.26

---

## Step 9: Generate Artifacts

### docs/ddd-build-v6.26.md (MANDATORY)

Full transcript including:
- Pre-flight results
- State fix script output (how many fixed, how many remaining)
- Firestore connection test
- Firestore load output (batch commits, counts)
- Firestore verification (sample documents, total counts)
- App dependency changes
- FlutterFire configuration
- Code changes to data_service.dart and main.dart
- flutter analyze and flutter build web output
- Visual verification results

### docs/ddd-report-v6.26.md (MANDATORY)

Must include:

1. **State fix results:**
   | Metric | Before | After |
   |---|---|---|
   | UNKNOWN states | 126 | XX |
   | Total unique states | 63 | XX |

2. **Firestore load results:**
   | Collection | Documents | Status |
   |---|---|---|
   | restaurants | XX | ✅/❌ |
   | videos | XX | ✅/❌ |

3. **App wiring changes:** files modified with descriptions
4. **Build status:** flutter analyze + flutter build web
5. **Visual verification:** checklist with pass/fail
6. **Data accuracy:** do trivia counts match normalized JSONL?
7. **Known issues:** any Firestore query performance concerns, missing data
8. **Gemini's Recommendation:** Ready for production deploy?
9. **Human interventions:** count (target: 0)

---

## Phase 6.26 Success Criteria

```
[ ] Pre-flight passes (normalized data exists, Firebase credentials valid)
[ ] State fix script created and run
    [ ] UNKNOWN states reduced to < 30
[ ] Firestore load script created
    [ ] Firebase connection verified
    [ ] ~1102 restaurants loaded
    [ ] ~773 videos loaded
[ ] App wired to Firestore
    [ ] firebase_core + cloud_firestore added
    [ ] FlutterFire configured
    [ ] main.dart updated with Firebase.initializeApp
    [ ] data_service.dart reads from Firestore
    [ ] Sample data fallback preserved
[ ] Trivia computes from full dataset
[ ] flutter analyze: 0 errors
[ ] flutter build web: success
[ ] Visual verification: search, trivia, map all show full dataset
[ ] README updated to current state
[ ] ddd-build-v6.26.md generated
[ ] ddd-report-v6.26.md generated
[ ] Human interventions: 0
```

---

## GEMINI.md Content

Place in project ROOT (`~/dev/projects/tripledb/GEMINI.md`) since this iteration spans both pipeline/ and app/:

```markdown
# TripleDB — Agent Instructions

## Current Iteration: 6.26

IMPORTANT: Read documents in this EXACT order before executing:

1. docs/ddd-design-v6.26.md — Architecture, Firestore schema, state inference
2. docs/ddd-plan-v6.26.md — Execution steps

Do NOT begin execution until both files have been read.

## Rules That Never Change
- Git READ commands allowed (pull, log, status, diff, show)
- Git WRITE commands forbidden (add, commit, push, checkout, branch)
- firebase deploy forbidden — Kyle deploys manually
- flutter build web IS ALLOWED for testing
- NEVER ask permission — auto-proceed on EVERY step
- Context7 MCP allowed. No other MCP servers.
- MUST produce ddd-build-v6.26.md AND ddd-report-v6.26.md before ending
- This iteration spans pipeline/ AND app/ directories
```

---

## Launch Sequence

```bash
cd ~/dev/projects/tripledb

# Place docs in root docs/ (this spans both subsystems)
# (copy ddd-design-v6.26.md and ddd-plan-v6.26.md into docs/)

# Update root GEMINI.md
nano GEMINI.md

# Launch from root (not pipeline/ or app/)
gemini
```

Then type:

```
Read GEMINI.md and execute.
```

After Gemini completes, review the report, then deploy:

```bash
cd app
flutter build web
firebase deploy --only hosting
```

Then commit everything:

```bash
cd ~/dev/projects/tripledb
git add .
git commit -m "KT completed 6.26 — Firestore loaded, app wired to live data"
git push
```
