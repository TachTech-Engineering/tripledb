# TripleDB — Design + Plan v6.28

**Phase:** 6 — Geocoding + Firestore Restore
**Iteration:** 28 (global)
**Goal:** Geocode all 1,102 restaurants with lat/lng coordinates, restore the Firestore connection that v6.27 disabled, reload Firestore with geocoded data, verify map pins and "Near Me" work.

---

## The Actual Problem

v6.27 diagnosed a "geolocation bug" but the real issue is simpler: **0 out of 1,102 restaurants have latitude/longitude coordinates.** The map is blank because there are no coordinates to plot. "Near Me" returns nothing because there's no data to calculate distances against. The geolocation code is fine — the data is empty.

Additionally, v6.27 disabled Firestore as a "temporary bypass" and downgraded geolocator. Both need to be reverted.

## What v6.28 Does

1. **Geocode** — add lat/lng to all restaurants using city+state → coordinates lookup
2. **Revert Firestore bypass** — restore `data_service.dart` to read from Firestore
3. **Revert geolocator downgrade** — restore geolocator 13.x (or keep 10.x if stable)
4. **Reload Firestore** — push geocoded data into Firestore
5. **Verify** — map shows pins, "Near Me" shows nearby restaurants

## Geocoding Strategy

We have `city` and `state` for ~1,070 of 1,102 restaurants (33 UNKNOWN state). Rather than calling a geocoding API 1,102 times, we batch by unique city+state pairs:

- ~400 unique city+state combinations (many restaurants share a city)
- Use the **Gemini Flash API** (already configured, free tier) to batch-geocode
- Send batches of 50 city+state pairs, ask for lat/lng JSON response
- Write coordinates back to restaurants.jsonl
- Restaurants with UNKNOWN state or unresolvable cities get null coordinates (acceptable — map just skips them)

Alternative: **Nominatim API** (OpenStreetMap, free, no key needed, 1 req/sec rate limit). Either works.

---

## Read Order

```
1. This file (docs/ddd-plan-v6.28.md)
2. pipeline/scripts/phase6_load_firestore.py (existing loader)
3. app/lib/services/data_service.dart (to see what v6.27 broke)
4. app/lib/services/location_service.dart
```

---

## Autonomy Rules

```
1. AUTO-PROCEED. NEVER ask permission.
2. SELF-HEAL: diagnose → fix → re-run (max 3 attempts, then skip).
3. MCP: Context7 ALLOWED. No other MCP servers.
4. Git READ allowed. Git WRITE and firebase deploy forbidden.
5. flutter build web IS ALLOWED for testing.
6. This iteration works in BOTH pipeline/ and app/.
7. MANDATORY ARTIFACTS:
   a. docs/ddd-build-v6.28.md
   b. docs/ddd-report-v6.28.md
```

---

## Step 0: Pre-Flight

```bash
cd ~/dev/projects/tripledb/pipeline

# Verify normalized data
wc -l data/normalized/restaurants.jsonl
# Expected: 1102

# Verify Gemini API key
echo $GEMINI_API_KEY
# Should print a key

# Verify no restaurants have coordinates yet
python3 -c "
import json
coords = 0
total = 0
for line in open('data/normalized/restaurants.jsonl'):
    r = json.loads(line)
    total += 1
    if r.get('latitude') and r.get('longitude'):
        coords += 1
print(f'With coordinates: {coords}/{total}')
"
# Expected: 0/1102

# Verify Firebase credentials
echo $GOOGLE_APPLICATION_CREDENTIALS
test -f "$GOOGLE_APPLICATION_CREDENTIALS" && echo "SA KEY OK" || echo "MISSING"
```

---

## Step 1: Create Geocoding Script

Create `pipeline/scripts/geocode_restaurants.py`:

```python
#!/usr/bin/env python3
"""geocode_restaurants.py — Add lat/lng to restaurants using Nominatim (OpenStreetMap) geocoding."""
import json
import os
import time
import urllib.request
import urllib.parse

def geocode_city_state(city, state):
    """Look up coordinates for a city+state via Nominatim API."""
    if not city or not state or state == "UNKNOWN":
        return None, None

    query = f"{city}, {state}, USA"
    params = urllib.parse.urlencode({
        "q": query,
        "format": "json",
        "limit": 1,
        "countrycodes": "us",
    })
    url = f"https://nominatim.openstreetmap.org/search?{params}"

    try:
        req = urllib.request.Request(url, headers={"User-Agent": "TripleDB/1.0 (tripledb.net)"})
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode())
            if data:
                return float(data[0]["lat"]), float(data[0]["lon"])
    except Exception as e:
        print(f"  ⚠️ Geocode failed for '{query}': {e}")

    return None, None

def main():
    restaurants_path = "data/normalized/restaurants.jsonl"

    # Load all restaurants
    restaurants = []
    with open(restaurants_path) as f:
        for line in f:
            restaurants.append(json.loads(line))

    print(f"Total restaurants: {len(restaurants)}")

    # Build unique city+state pairs
    city_state_pairs = set()
    for r in restaurants:
        city = (r.get("city") or "").strip()
        state = (r.get("state") or "").strip()
        if city and state and state != "UNKNOWN":
            city_state_pairs.add((city, state))

    print(f"Unique city+state pairs to geocode: {len(city_state_pairs)}")

    # Geocode each unique pair (with caching)
    coord_cache = {}
    geocoded = 0
    failed = 0

    for i, (city, state) in enumerate(sorted(city_state_pairs), 1):
        key = f"{city}|{state}"
        if key in coord_cache:
            continue

        lat, lng = geocode_city_state(city, state)
        coord_cache[key] = (lat, lng)

        if lat and lng:
            geocoded += 1
            if geocoded % 50 == 0:
                print(f"  Geocoded {geocoded}/{len(city_state_pairs)} ({i} processed)")
        else:
            failed += 1

        # Nominatim rate limit: 1 request per second
        time.sleep(1.1)

    print(f"\nGeocoding complete: {geocoded} resolved, {failed} failed")

    # Apply coordinates to restaurants
    applied = 0
    for r in restaurants:
        city = (r.get("city") or "").strip()
        state = (r.get("state") or "").strip()
        key = f"{city}|{state}"

        if key in coord_cache:
            lat, lng = coord_cache[key]
            if lat and lng:
                r["latitude"] = lat
                r["longitude"] = lng
                applied += 1

    print(f"Coordinates applied to {applied}/{len(restaurants)} restaurants")

    # Write back
    with open(restaurants_path, "w") as f:
        for r in restaurants:
            f.write(json.dumps(r) + "\n")

    # Save cache for future use
    cache_path = "data/logs/geocode_cache.json"
    os.makedirs("data/logs", exist_ok=True)
    with open(cache_path, "w") as f:
        json.dump({k: list(v) for k, v in coord_cache.items()}, f, indent=2)
    print(f"Cache saved to {cache_path}")

    # Summary
    with_coords = sum(1 for r in restaurants if r.get("latitude") and r.get("longitude"))
    print(f"\n=== Geocoding Summary ===")
    print(f"Restaurants with coordinates: {with_coords}/{len(restaurants)}")
    print(f"Restaurants without coordinates: {len(restaurants) - with_coords}")

if __name__ == "__main__":
    main()
```

---

## Step 2: Run Geocoding

```bash
cd ~/dev/projects/tripledb/pipeline
python3 scripts/geocode_restaurants.py
```

This will take approximately **7-10 minutes** (400 unique cities × 1.1 second rate limit). Do NOT interrupt it.

Expected: ~1,050+ restaurants get coordinates (those with valid city+state). ~50 remain without (UNKNOWN state or unresolvable cities).

Verify:

```bash
python3 -c "
import json
coords = 0
total = 0
for line in open('data/normalized/restaurants.jsonl'):
    r = json.loads(line)
    total += 1
    if r.get('latitude') and r.get('longitude'):
        coords += 1
print(f'With coordinates: {coords}/{total}')
"
```

Target: >950/1102 with coordinates.

---

## Step 3: Reload Firestore

The geocoded restaurants need to replace the old (coordinateless) data in Firestore:

```bash
python3 scripts/phase6_load_firestore.py
```

This uses batch `.set()` which overwrites existing documents. All 1,102 restaurants get reloaded with their new lat/lng fields.

Verify a sample document has coordinates:

```bash
python3 -c "
import firebase_admin
from firebase_admin import credentials, firestore
import os

cred = credentials.Certificate(os.environ['GOOGLE_APPLICATION_CREDENTIALS'])
firebase_admin.initialize_app(cred, {'projectId': 'tripledb-e0f77'})
db = firestore.client()

for doc in db.collection('restaurants').limit(3).stream():
    d = doc.to_dict()
    print(f'{d.get(\"name\")} ({d.get(\"city\")}, {d.get(\"state\")}): lat={d.get(\"latitude\")}, lng={d.get(\"longitude\")}')
"
```

---

## Step 4: Restore Firestore in App

Switch to app/:

```bash
cd ~/dev/projects/tripledb/app
```

### 4a. Fix data_service.dart

The current file has Firestore commented out and bypassed. Restore it:

```dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant_models.dart';

class DataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Restaurant>> loadRestaurants() async {
    try {
      final snapshot = await _db.collection('restaurants').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Restaurant.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Firestore error, falling back to sample data: $e');
      return await loadSampleRestaurants();
    }
  }

  Future<List<Restaurant>> loadSampleRestaurants() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/sample_restaurants.jsonl');
      final lines = jsonString.split('\n');
      final restaurants = <Restaurant>[];
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final json = jsonDecode(line) as Map<String, dynamic>;
        restaurants.add(Restaurant.fromJson(json));
      }
      return restaurants;
    } catch (e) {
      debugPrint('Error loading sample restaurants: $e');
      return [];
    }
  }
}
```

This tries Firestore first, falls back to local sample data if Firestore fails. No more "temporary bypass."

### 4b. Verify Firebase is initialized in main.dart

Check that `main.dart` still has:
```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

If v6.27 removed this, restore it.

### 4c. Update sample data with coordinates

Copy the first 50 geocoded restaurants to the sample file so local dev also has coordinates:

```bash
cd ~/dev/projects/tripledb
head -50 pipeline/data/normalized/restaurants.jsonl > app/assets/data/sample_restaurants.jsonl
```

---

## Step 5: Verify Geolocator Version

Check what version v6.27 left in pubspec.yaml:

```bash
grep -i "geolocator" app/pubspec.yaml
```

If it's at `^10.1.0` and the location service works, keep it for stability. If you want to try upgrading back to `^13.0.0`, do it in a separate iteration after map pins are confirmed working. Don't change two things at once.

---

## Step 6: Build and Test

```bash
cd ~/dev/projects/tripledb/app
flutter pub get
flutter analyze
flutter build web
cd build/web
python3 -m http.server 8080
```

Open in browser. Verify:

```
[ ] Map page shows pins across the US (not blank)
[ ] Zooming in shows individual restaurant pins
[ ] Tapping a pin shows the restaurant preview bottom sheet
[ ] "Near Me" FAB triggers location permission prompt
[ ] After granting permission, map centers on your location
[ ] "Top 3 Near You" on home page shows restaurants with distances
[ ] Search for "Memphis" shows restaurants with Tennessee coordinates
[ ] Trivia shows ~1,102 restaurants (not 50)
```

Stop server after testing.

---

## Step 7: Generate Artifacts

### docs/ddd-build-v6.28.md
- Geocoding script output (how many resolved, how many failed)
- Firestore reload output
- data_service.dart restoration
- flutter analyze + build output
- Verification checklist results

### docs/ddd-report-v6.28.md
- Geocoding results: X/1102 with coordinates
- Firestore status: restored and reloaded
- v6.27 regressions fixed (Firestore bypass removed, data_service restored)
- Map verification: pins visible yes/no
- Near Me verification: working yes/no
- Recommendation: ready for deploy?

---

## Success Criteria

```
[ ] Geocoding script created and run
    [ ] >950/1102 restaurants have lat/lng
    [ ] Cache saved for future use
[ ] Firestore reloaded with geocoded data
    [ ] Sample document verified with coordinates
[ ] data_service.dart restored to use Firestore (not bypassed)
[ ] Firebase.initializeApp confirmed in main.dart
[ ] Sample data updated with coordinates
[ ] flutter analyze: 0 errors
[ ] flutter build web: success
[ ] Map shows pins across the US
[ ] Near Me triggers location prompt
[ ] ddd-build-v6.28.md generated
[ ] ddd-report-v6.28.md generated
```

---

## GEMINI.md Content

```markdown
# TripleDB — Agent Instructions

## Current Iteration: 6.28

Read docs/ddd-plan-v6.28.md then execute.

This iteration spans pipeline/ (geocoding + Firestore reload) and app/ (restore Firestore connection).

## Rules
- Git READ allowed. Git WRITE and firebase deploy forbidden.
- flutter build web IS ALLOWED for testing.
- Context7 MCP allowed for Flutter/Firebase docs.
- NEVER ask permission — diagnose, fix, test, report.
- MUST produce ddd-build-v6.28.md AND ddd-report-v6.28.md before ending.
- Start in pipeline/ for Steps 0-3, switch to app/ for Steps 4-6.
```

---

## Launch

```bash
cd ~/dev/projects/tripledb
# Place this file in docs/
nano GEMINI.md
gemini
```

Then: `Read GEMINI.md and execute.`

After Gemini completes:
```bash
cd app
flutter build web
firebase deploy --only hosting
git add .
git commit -m "KT completed 6.28 — geocoded restaurants, restored Firestore, map working"
git push
```

Then test on your phone — tripledb.net should show a map full of pins and "Near Me" should actually find diners near you.
