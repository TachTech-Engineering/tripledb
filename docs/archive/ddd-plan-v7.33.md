# TripleDB — Phase 7 Plan v7.33

**Phase:** 7 — Enrichment
**Iteration:** 33 (global)
**Date:** March 2026
**Goal:** Backfill `google_current_name` for all 582 enriched restaurants, build closed-restaurant filtering and AKA display in the Flutter app, and implement step-level checkpointing for crash recovery.

---

## What Phase 7.33 Produces

1. **`google_current_name` on all enriched records** — fetched from Places API using stored `google_place_id`, merged to Firestore.
2. **`name_changed` computed boolean** — true when DDD name differs significantly from Google's current name.
3. **Closed restaurant UX** — grey map pins, filter toggle, "Permanently Closed" banners, excluded from "Near You."
4. **AKA display** — "Mamo's (now Fat Mo's)" on cards, detail page, and search results.
5. **Checkpoint protocol** — JSON checkpoint after every step, read on resume.

---

## Read Order

```
1. docs/ddd-design-v7.33.md — AKA field spec, closed UX spec, checkpoint protocol
2. docs/ddd-plan-v7.33.md — This file. Execution steps.
```

Read both before executing. Log confirmation in build log.

---

## Autonomy Rules

```
1. AUTO-PROCEED between ALL steps. NEVER ask permission.
2. SELF-HEAL: diagnose → fix → re-run (max 3 attempts, then skip).
3. SYSTEMIC FAILURE: 3 consecutive identical errors = STOP, fix, restart.
4. Git READ allowed. Git WRITE and firebase deploy FORBIDDEN.
5. flutter build web and flutter run ARE ALLOWED.
6. MCP: Context7 ALLOWED. No other MCP servers.
7. FULL PROJECT ACCESS: Read/write ANYWHERE under ~/dev/projects/tripledb/.
8. MANDATORY ARTIFACTS before session ends:
   a. docs/ddd-build-v7.33.md — FULL transcript
   b. docs/ddd-report-v7.33.md — metrics, recommendation
   c. README.md — COMPREHENSIVE update at PROJECT ROOT
9. $GOOGLE_PLACES_API_KEY must be set. If not, print:
   "ERROR: GOOGLE_PLACES_API_KEY not set. Export it and re-run."
   Then HALT. Do NOT ask interactively.
10. CHECKPOINT after every numbered step. See Step 0b for implementation.
11. NEVER overwrite the `name` field on restaurant documents. It is the DDD
    original name and must be preserved exactly as extracted from transcripts.
```

---

## Step 0: Pre-Flight + Checkpoint Setup

### 0a. Pre-Flight Checks

```bash
cd ~/dev/projects/tripledb/pipeline

# Standard pre-flight
python3 scripts/pre_flight.py

# API key check
if [ -z "$GOOGLE_PLACES_API_KEY" ]; then
    echo "ERROR: GOOGLE_PLACES_API_KEY not set. Export it and re-run."
    exit 1
fi
echo "GOOGLE_PLACES_API_KEY: SET"

# API connectivity
python3 -c "
import os, requests
key = os.environ.get('GOOGLE_PLACES_API_KEY', '')
r = requests.post(
    'https://places.googleapis.com/v1/places:searchText',
    headers={'Content-Type': 'application/json', 'X-Goog-Api-Key': key,
             'X-Goog-FieldMask': 'places.id,places.displayName'},
    json={'textQuery': 'In-N-Out Burger Irvine CA'}, timeout=10)
print(f'Places API: {r.status_code}')
"

# Current state
wc -l data/enriched/restaurants_enriched.jsonl
# Expected: ~708 (582 verified + some from refined matches)
echo "Firestore enriched docs: 582"
echo "Records with google_place_id: should match enriched count"
```

### 0b. Initialize Checkpoint System

```bash
mkdir -p data/checkpoints
```

Create a checkpoint helper — write this inline or as a small utility:

```python
# Checkpoint utility — use throughout the iteration
import json
from datetime import datetime, timezone
from pathlib import Path

CHECKPOINT_PATH = Path("data/checkpoints/v7.33_checkpoint.json")

def write_checkpoint(step: int, step_name: str, metrics: dict = None):
    cp = {
        "iteration": "7.33",
        "last_completed_step": step,
        "step_name": step_name,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "metrics": metrics or {}
    }
    CHECKPOINT_PATH.parent.mkdir(parents=True, exist_ok=True)
    CHECKPOINT_PATH.write_text(json.dumps(cp, indent=2))
    print(f"  [CHECKPOINT] Step {step} ({step_name}) saved.")

def read_checkpoint() -> dict | None:
    if CHECKPOINT_PATH.exists():
        return json.loads(CHECKPOINT_PATH.read_text())
    return None

def delete_checkpoint():
    if CHECKPOINT_PATH.exists():
        CHECKPOINT_PATH.unlink()
        print("  [CHECKPOINT] Cleared.")
```

Check for existing checkpoint (crash recovery):

```python
cp = read_checkpoint()
if cp:
    last = cp["last_completed_step"]
    print(f"  [RESUME] Found checkpoint. Steps 0-{last} already complete.")
    print(f"  [RESUME] Last step: {cp['step_name']} at {cp['timestamp']}")
    print(f"  [RESUME] Starting from Step {last + 1}.")
else:
    print("  [FRESH START] No checkpoint found. Starting from Step 0.")
```

If checkpoint exists and `last_completed_step >= N`, skip to Step N+1. Log what was skipped.

**Write checkpoint after Step 0 completes.**

---

## Step 1: Backfill `google_current_name` for Enriched Records

### 1a. Check cache first

The `places_cache.json` from v7.30–v7.32 may already contain Google's `displayName` for cached results. Check:

```bash
python3 -c "
import json
cache = json.load(open('data/enriched/places_cache.json'))
# Check if cache entries contain displayName
sample_key = list(cache.keys())[0] if cache else None
if sample_key:
    print(f'Sample cache key: {sample_key}')
    print(f'Sample value keys: {list(cache[sample_key].keys())[:10]}')
else:
    print('Cache is empty')
print(f'Total cache entries: {len(cache)}')
"
```

If the cache contains `displayName` or the full enrichment record, extract `google_current_name` from cache without re-querying the API. If not, proceed with API fetches.

### 1b. Create `scripts/phase7_backfill_names.py`

This script reads `restaurants_enriched.jsonl`, and for each record:
1. Uses `google_place_id` to fetch `displayName` from Places API (if not in cache)
2. Compares DDD `name` with Google `displayName` using fuzzy matching
3. Sets `google_current_name` and `name_changed` fields
4. Writes updated records

```python
#!/usr/bin/env python3
"""
phase7_backfill_names.py — Backfill google_current_name for enriched restaurants.

Uses stored google_place_id to fetch the current Google displayName,
then compares with our DDD name to set name_changed flag.

Usage:
    python3 scripts/phase7_backfill_names.py
    python3 scripts/phase7_backfill_names.py --dry-run
"""
import argparse, json, os, sys, time
from datetime import datetime, timezone
from difflib import SequenceMatcher
from pathlib import Path
import requests

API_KEY = os.environ.get("GOOGLE_PLACES_API_KEY", "")
ENRICHED_PATH = Path("data/enriched/restaurants_enriched.jsonl")
NORMALIZED_PATH = Path("data/normalized/restaurants.jsonl")
NAMES_OUTPUT = Path("data/enriched/name_backfill.jsonl")
CACHE_PATH = Path("data/enriched/places_cache.json")

NAME_CHANGE_THRESHOLD = 0.95  # Below this = name_changed: true
REQUEST_DELAY = 0.15
REQUEST_TIMEOUT = 15

def fetch_display_name(place_id: str) -> str | None:
    """Fetch just the displayName for a place_id."""
    resource = place_id if place_id.startswith("places/") else f"places/{place_id}"
    url = f"https://places.googleapis.com/v1/{resource}"
    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": API_KEY,
        "X-Goog-FieldMask": "displayName",
    }
    try:
        resp = requests.get(url, headers=headers, timeout=REQUEST_TIMEOUT)
        if resp.status_code == 429:
            time.sleep(60)
            resp = requests.get(url, headers=headers, timeout=REQUEST_TIMEOUT)
        if resp.status_code == 200:
            return resp.json().get("displayName", {}).get("text")
        return None
    except Exception as e:
        print(f"    Fetch error: {e}")
        return None

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    if not API_KEY:
        print("ERROR: GOOGLE_PLACES_API_KEY not set. HALTING.")
        sys.exit(1)

    # Load enriched records
    enriched = []
    with open(ENRICHED_PATH) as f:
        for line in f:
            if line.strip():
                enriched.append(json.loads(line))
    print(f"Enriched records: {len(enriched)}")

    # Load normalized data for DDD names
    normalized = {}
    with open(NORMALIZED_PATH) as f:
        for line in f:
            if line.strip():
                r = json.loads(line)
                normalized[r.get("restaurant_id", "")] = r

    # Load cache
    cache = json.loads(CACHE_PATH.read_text()) if CACHE_PATH.exists() else {}

    # Resume: check what's already been backfilled
    already_done = set()
    if NAMES_OUTPUT.exists():
        with open(NAMES_OUTPUT) as f:
            for line in f:
                if line.strip():
                    already_done.add(json.loads(line).get("restaurant_id", ""))
    remaining = [r for r in enriched if r.get("restaurant_id") not in already_done]
    print(f"Already backfilled: {len(already_done)}, Remaining: {len(remaining)}")

    if args.dry_run:
        print(f"[DRY RUN] Would backfill names for {len(remaining)} records.")
        return

    NAMES_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    out = open(NAMES_OUTPUT, "a")

    stats = {"fetched": 0, "cached": 0, "name_changed": 0, "name_same": 0,
             "no_place_id": 0, "error": 0}

    for i, record in enumerate(remaining):
        rid = record.get("restaurant_id", "?")
        place_id = record.get("google_place_id", "")
        ddd_name = normalized.get(rid, {}).get("name", record.get("name", ""))

        if not place_id:
            stats["no_place_id"] += 1
            continue

        # Try cache first (check if we stored displayName somewhere)
        google_name = None
        cache_key = f"name|{place_id}"
        if cache_key in cache:
            google_name = cache[cache_key]
            stats["cached"] += 1
        else:
            time.sleep(REQUEST_DELAY)
            google_name = fetch_display_name(place_id)
            if google_name:
                cache[cache_key] = google_name
                stats["fetched"] += 1
            else:
                stats["error"] += 1

        if not google_name:
            continue

        # Compare names
        similarity = SequenceMatcher(None, ddd_name.lower().strip(),
                                     google_name.lower().strip()).ratio()
        name_changed = similarity < NAME_CHANGE_THRESHOLD

        result = {
            "restaurant_id": rid,
            "ddd_name": ddd_name,
            "google_current_name": google_name,
            "name_changed": name_changed,
            "name_similarity": round(similarity, 3),
        }

        out.write(json.dumps(result) + "\n")
        out.flush()

        if name_changed:
            stats["name_changed"] += 1
            print(f"[{i+1}/{len(remaining)}] ✏️  {ddd_name} → {google_name} ({similarity:.3f})")
        else:
            stats["name_same"] += 1
            if (i + 1) % 50 == 0:
                print(f"[{i+1}/{len(remaining)}] Processing... ({stats['name_same']} same, {stats['name_changed']} changed)")

    out.close()
    # Save cache
    CACHE_PATH.write_text(json.dumps(cache, indent=2))

    total = sum(stats.values())
    print(f"\n{'='*50}")
    print(f"Name Backfill Complete")
    print(f"{'='*50}")
    print(f"  Total processed:    {total}")
    print(f"  API fetched:        {stats['fetched']}")
    print(f"  From cache:         {stats['cached']}")
    print(f"  Name changed:       {stats['name_changed']}")
    print(f"  Name same:          {stats['name_same']}")
    print(f"  No place_id:        {stats['no_place_id']}")
    print(f"  Errors:             {stats['error']}")

if __name__ == "__main__":
    main()
```

### 1c. Run the backfill

```bash
cd ~/dev/projects/tripledb/pipeline

python3 scripts/phase7_backfill_names.py --dry-run
python3 scripts/phase7_backfill_names.py
```

**Expected runtime:** If cache misses all 582, that's ~582 × 0.15s = ~1.5 min. With cache hits, faster.

**Expected results:**
- ~530–550 names identical (name_same)
- ~30–50 names changed (name_changed)
- Closed restaurants are more likely to show name changes

### 1d. Verify

```bash
wc -l data/enriched/name_backfill.jsonl

# Show name changes
python3 -c "
import json
records = [json.loads(l) for l in open('data/enriched/name_backfill.jsonl')]
changed = [r for r in records if r.get('name_changed')]
print(f'Total: {len(records)}, Name changed: {len(changed)}')
print()
for r in changed[:15]:
    print(f'  {r[\"ddd_name\"]} → {r[\"google_current_name\"]} ({r[\"name_similarity\"]:.3f})')
"
```

**Write checkpoint after Step 1.**

---

## Step 2: Load Names to Firestore

Create a small loader script or use inline Python to merge `google_current_name` and `name_changed` into Firestore:

```bash
cd ~/dev/projects/tripledb/pipeline

python3 -c "
import json
import firebase_admin
from firebase_admin import firestore

if not firebase_admin._apps:
    firebase_admin.initialize_app()
db = firestore.client()

records = [json.loads(l) for l in open('data/enriched/name_backfill.jsonl')]
print(f'Loading {len(records)} name records to Firestore...')

updated = 0
for i, rec in enumerate(records):
    rid = rec['restaurant_id']
    doc_ref = db.collection('restaurants').document(rid)
    doc_ref.set({
        'google_current_name': rec['google_current_name'],
        'name_changed': rec['name_changed'],
        'updated_at': firestore.SERVER_TIMESTAMP,
    }, merge=True)
    updated += 1
    if (i + 1) % 100 == 0:
        print(f'  {i+1}/{len(records)} updated')

print(f'Done. Updated {updated} documents.')

# Verify
from google.cloud.firestore_v1.base_query import FieldFilter
changed = db.collection('restaurants').where(filter=FieldFilter('name_changed', '==', True)).get()
print(f'Documents with name_changed=true: {len(changed)}')
for doc in changed[:5]:
    d = doc.to_dict()
    print(f'  {d.get(\"name\")} → {d.get(\"google_current_name\")}')
"
```

**Write checkpoint after Step 2.**

---

## Step 3: Update Flutter App — Closed Restaurant UX

```bash
cd ~/dev/projects/tripledb/app
```

### 3a. Update Restaurant Model

In `lib/models/restaurant_models.dart`, add:

```dart
final String? googleCurrentName;
final bool nameChanged;
```

Update `fromFirestore`:
```dart
googleCurrentName: data['google_current_name'] as String?,
nameChanged: data['name_changed'] as bool? ?? false,
```

### 3b. Map Page — Grey Pins + Filter Toggle

In `lib/pages/map_page.dart`:

**Pin color logic:**
```dart
Color pinColor = restaurant.stillOpen == false
    ? const Color(0xFF888888)  // Grey for closed
    : const Color(0xFFDD3333); // Red for open
```

**Filter toggle:** Add a `showClosed` state variable (default: true). When false, filter out restaurants where `stillOpen == false` from the markers list AND from cluster counts.

```dart
// In the provider or local state:
final showClosed = useState(true);

// Filter markers:
final visibleRestaurants = showClosed.value
    ? allRestaurants
    : allRestaurants.where((r) => r.stillOpen != false).toList();
```

Add a toggle button to the map UI (e.g., a chip or icon button in the top-right corner):
```dart
FilterChip(
  label: Text('Show closed'),
  selected: showClosed.value,
  onSelected: (val) => showClosed.value = val,
)
```

### 3c. Home Page — Exclude Closed from "Near You"

In the "Top 3 Near You" logic (likely in `lib/providers/restaurant_providers.dart` or `lib/pages/home_page.dart`):

```dart
// Filter out closed restaurants from nearby recommendations
final nearbyOpen = nearby.where((r) => r.stillOpen != false).toList();
```

### 3d. Restaurant Card — Badges

In `lib/widgets/restaurant/restaurant_card.dart`:

```dart
// Closed badge
if (restaurant.stillOpen == false)
  Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: Color(0xFFDD3333).withOpacity(0.15),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text('Permanently Closed',
      style: TextStyle(color: Color(0xFFDD3333), fontSize: 12, fontWeight: FontWeight.w600)),
  ),

// AKA name
if (restaurant.nameChanged && restaurant.googleCurrentName != null)
  Text('Now: ${restaurant.googleCurrentName}',
    style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
```

### 3e. Restaurant Detail Page — Banners

In `lib/pages/restaurant_detail_page.dart`:

At the top of the detail content, before the name:

```dart
// Permanently closed banner
if (restaurant.stillOpen == false)
  Container(
    width: double.infinity,
    padding: EdgeInsets.all(12),
    color: Color(0xFFDD3333).withOpacity(0.1),
    child: Row(
      children: [
        Icon(Icons.info_outline, color: Color(0xFFDD3333), size: 18),
        SizedBox(width: 8),
        Text('This restaurant has permanently closed',
          style: TextStyle(color: Color(0xFFDD3333), fontWeight: FontWeight.w600)),
      ],
    ),
  ),

// Temporarily closed banner
if (restaurant.businessStatus == 'CLOSED_TEMPORARILY')
  Container(
    width: double.infinity,
    padding: EdgeInsets.all(12),
    color: Color(0xFFDA7E12).withOpacity(0.1),
    child: Row(
      children: [
        Icon(Icons.schedule, color: Color(0xFFDA7E12), size: 18),
        SizedBox(width: 8),
        Text('Temporarily closed',
          style: TextStyle(color: Color(0xFFDA7E12), fontWeight: FontWeight.w600)),
      ],
    ),
  ),

// Name change subtitle
if (restaurant.nameChanged && restaurant.googleCurrentName != null)
  Padding(
    padding: EdgeInsets.only(top: 4),
    child: Text('Now known as: ${restaurant.googleCurrentName}',
      style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic)),
  ),
```

### 3f. Search — Index Both Names

Ensure the search logic checks both `name` and `google_current_name`. In the search provider or wherever search filtering happens:

```dart
bool matchesQuery(Restaurant r, String query) {
  final q = query.toLowerCase();
  return r.name.toLowerCase().contains(q) ||
         (r.googleCurrentName?.toLowerCase().contains(q) ?? false) ||
         // ... existing fields (city, cuisine, dishes, etc.)
}
```

### 3g. Explore Page — Closed Stats

In `lib/pages/explore_page.dart`, add to the enrichment stats section:

```dart
// Closed restaurants stat
final closedCount = restaurants.where((r) => r.stillOpen == false).length;
// Name changes stat
final renamedCount = restaurants.where((r) => r.nameChanged).length;
```

Display these alongside existing enrichment stats.

### 3h. Trivia — New Facts

In `lib/providers/trivia_providers.dart`, add:

```dart
// "X DDD restaurants have been renamed since filming"
// "X DDD restaurants are now permanently closed"
// "{name} is now known as {google_current_name}" (random example)
```

### 3i. Build and Test

```bash
cd ~/dev/projects/tripledb/app

flutter pub get
flutter analyze
flutter build web
```

Optionally `flutter run -d chrome` to verify:
- [ ] Map shows grey pins for closed restaurants
- [ ] "Show closed" toggle works (hides grey pins)
- [ ] "Top 3 Near You" excludes closed restaurants
- [ ] Restaurant cards show "Permanently Closed" badge when applicable
- [ ] Restaurant cards show "Now: {name}" for name-changed restaurants
- [ ] Detail page shows closed/renamed banners
- [ ] Search finds restaurants by both DDD name and current Google name
- [ ] Explore page shows closed + renamed counts
- [ ] Non-enriched restaurants render correctly (all new fields are null-safe)

Log pass/fail for each.

**Write checkpoint after Step 3.**

---

## Step 4: Update README.md

```bash
cd ~/dev/projects/tripledb
```

### 4a. Current Metrics

```markdown
### Live Dataset (tripledb.net)
- **1,102** unique restaurants across **62** states and territories
- **2,286** dishes with ingredients and Guy's reactions
- **582** restaurants enriched with Google ratings, open/closed status, and websites
- **~XX** restaurants renamed or changed ownership since filming
- **30** permanently closed restaurants identified
- **1,006** restaurants with map coordinates (91.3%)
- **432** cross-video dedup merges
```

Fill `~XX` with actual name_changed count.

### 4b. IAO Iteration History

Add v7.33:
```
| v7.33 | AKA Names + Closed UX | ✅ | google_current_name backfill. Grey pins for closed. Filter toggle. Checkpointing. |
```

### 4c. Changelog

```markdown
**v7.32 → v7.33 (Phase 7 AKA Names + Closed Restaurant UX)**
- **AKA field:** Backfilled `google_current_name` for all 582 enriched restaurants.
  XX restaurants have been renamed since filming. App shows "now known as" for these.
- **Closed UX:** Grey map pins for closed restaurants, "Show closed" filter toggle,
  "Permanently Closed" banners on cards and detail pages. Closed excluded from "Near You."
- **Checkpointing:** Step-level checkpoint protocol for crash recovery across iterations.
- **Outcome:** Phase 7 enrichment complete. Data provenance and historical preservation achieved.
```

### 4d. Phase Status

```
| 7 | Enrichment | ✅ Complete | v7.30–v7.33 |
```

### 4e. Footer

```markdown
*Last updated: Phase 7.33 — AKA Names + Closed Restaurant UX*
```

### 4f. Verify

```bash
grep "7.33" README.md | head -3
grep "google_current_name\|AKA\|closed" README.md | head -5
grep "Last updated" README.md
```

**Write checkpoint after Step 4.**

---

## Step 5: Generate Artifacts + Cleanup

### docs/ddd-build-v7.33.md (MANDATORY — FULL TRANSCRIPT)

Must include:
- Pre-flight output
- Checkpoint system initialization
- Name backfill output (total, changed count, sample name changes)
- Firestore name load output
- Flutter changes (files modified, what was added)
- flutter analyze + build output
- Data flow verification results (map pins, filter, badges, search)
- README changes summary
- Any errors and fixes

**Write to:** `~/dev/projects/tripledb/docs/ddd-build-v7.33.md`

### docs/ddd-report-v7.33.md (MANDATORY)

Must include:
1. **Name backfill results:** total processed, names changed, names same, sample changes
2. **Name change analysis:** most dramatic name changes, common patterns (rebrand vs replacement)
3. **Closed restaurant summary:** total closed, closed + renamed vs closed + same name
4. **Firestore state:** enriched count, name_changed count, coordinate count
5. **App UI changes:** list of modifications, build status
6. **Checkpoint protocol:** confirmed working, file location
7. **API cost:** expected $0
8. **Comparison table:** v7.31 → v7.32 → v7.33 coverage metrics
9. **Human interventions:** count (target: 0)
10. **Gemini's Recommendation:** Phase 7 wrap-up? What's next?
11. **README Update Confirmation**

**Write to:** `~/dev/projects/tripledb/docs/ddd-report-v7.33.md`

### Cleanup checkpoint

```python
# After all artifacts are written:
delete_checkpoint()
```

---

## Success Criteria

```
[ ] Pre-flight passes
[ ] Checkpoint system initialized and functional
[ ] phase7_backfill_names.py created with resume support
[ ] google_current_name backfilled for all enriched records
[ ] name_changed computed correctly (threshold: 0.95 similarity)
[ ] Firestore updated with name fields (merge, no overwrites)
[ ] Flutter app:
    [ ] Restaurant model includes googleCurrentName, nameChanged
    [ ] Map: grey pins for closed restaurants
    [ ] Map: "Show closed" filter toggle works
    [ ] Home: "Near You" excludes closed
    [ ] Cards: "Permanently Closed" badge
    [ ] Cards: "Now: {name}" for renamed restaurants
    [ ] Detail: closed/renamed banners
    [ ] Search: indexes both DDD name and current name
    [ ] Explore: closed + renamed stats
    [ ] Trivia: new facts
    [ ] flutter analyze: 0 errors
    [ ] flutter build web: success
    [ ] All features null-safe for non-enriched restaurants
[ ] README at project root fully updated:
    [ ] Metrics with name_changed count
    [ ] Iteration history includes v7.33
    [ ] Changelog for v7.33
    [ ] Phase 7: ✅ Complete v7.30–v7.33
    [ ] Footer: Phase 7.33
[ ] ddd-build-v7.33.md generated (FULL transcript)
[ ] ddd-report-v7.33.md generated
[ ] Checkpoint file deleted after completion
[ ] Human interventions: 0
```

---

## Launch Sequence

```bash
# 1. Archive previous iteration
cd ~/dev/projects/tripledb
mv docs/ddd-design-v7.32.md docs/archive/ 2>/dev/null
mv docs/ddd-plan-v7.32.md docs/archive/ 2>/dev/null
mv docs/ddd-report-v7.32.md docs/archive/ 2>/dev/null
mv docs/ddd-build-v7.32.md docs/archive/ 2>/dev/null

# 2. Place new docs
cp /path/to/ddd-design-v7.33.md docs/
cp /path/to/ddd-plan-v7.33.md docs/

# 3. Verify API key
echo $GOOGLE_PLACES_API_KEY

# 4. Update GEMINI.md
nano pipeline/GEMINI.md

# 5. Commit
git add .
git commit -m "KT starting 7.33"

# 6. Launch (in Konsole)
cd pipeline
gemini
```

Then: `Read GEMINI.md and execute.`

After completion:
```bash
cd ~/dev/projects/tripledb
git add .
git commit -m "KT completed 7.33 and README updated"
git push

cd app
flutter build web
firebase deploy --only hosting
```
