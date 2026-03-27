# TripleDB — Phase 7 Plan v7.30

**Phase:** 7 — Enrichment
**Iteration:** 30 (global)
**Date:** March 2026
**Goal:** Build the Google Places API enrichment pipeline, validate on a 50-restaurant discovery batch, verify match quality, backfill null coordinates, and confirm Firestore merge updates work. This is the discovery batch — v7.31 runs the full 1,102.

---

## What Phase 7.30 Produces

Phase 7.30 is the enrichment discovery batch — NOT the full production run. It produces:

1. **`scripts/phase7_enrich.py`** — Google Places API enrichment script with Text Search → Place Details flow, match validation, caching, and resume support.
2. **`scripts/phase7_load_enriched.py`** — Firestore merge updater that applies enrichment fields without overwriting existing data.
3. **`scripts/validate_enrichment.py`** — Quality metrics: match rate, rating distribution, coordinate backfill count, business status breakdown.
4. **Discovery batch results** — 50 restaurants enriched, with quality metrics proving the pipeline works.
5. **Confidence** — match validation thresholds proven, cost confirmed as free-tier, ready for v7.31 full run.

---

## Read Order

```
1. docs/ddd-design-v7.30.md — Architecture, enrichment schema, match strategy
2. docs/ddd-plan-v7.30.md — This file. Execution steps.
```

Read both before executing. Log confirmation in build log.

---

## Autonomy Rules

```
1. AUTO-PROCEED between ALL steps. NEVER ask permission. NEVER ask
   "should I continue?" or "would you like me to proceed?" — the answer
   is ALWAYS yes. The plan document IS your permission. Execute it.
2. SELF-HEAL: diagnose → fix → re-run (max 3 attempts per error, then
   log and skip).
3. SYSTEMIC FAILURE RULE: If 3 consecutive restaurants fail with the SAME
   error (e.g., API auth failure, quota exceeded), STOP immediately.
   Fix the root cause. Then restart (resume support skips completed items).
4. Git READ commands allowed. Git WRITE commands and firebase deploy forbidden.
5. MCP: Context7 ALLOWED for Python/API docs. No other MCP servers.
6. MANDATORY ARTIFACTS before session ends:
   a. docs/ddd-build-v7.30.md — full transcript
   b. docs/ddd-report-v7.30.md — metrics and findings
   c. README.md — comprehensive update
7. Working directory: pipeline/ (all scripts run from here).
8. Google Places API key is in $GOOGLE_PLACES_API_KEY. NEVER hardcode it.
   If the env var is not set, STOP and log — do NOT proceed without it.
```

---

## Step 0: Pre-Flight Checks

```bash
cd ~/dev/projects/tripledb/pipeline

# Standard pre-flight
python3 scripts/pre_flight.py

# Verify Google Places API key is set
echo "GOOGLE_PLACES_API_KEY set: $([ -n "$GOOGLE_PLACES_API_KEY" ] && echo YES || echo NO)"

# Verify restaurants.jsonl exists and has expected count
wc -l data/normalized/restaurants.jsonl
# Expected: 1102

# Verify Python dependencies available
python3 -c "import requests; print('requests:', requests.__version__)"
python3 -c "from difflib import SequenceMatcher; print('difflib: OK')"

# Quick API connectivity test (1 request)
python3 -c "
import os, requests
key = os.environ.get('GOOGLE_PLACES_API_KEY', '')
if not key:
    print('ERROR: GOOGLE_PLACES_API_KEY not set')
    exit(1)
r = requests.post(
    'https://places.googleapis.com/v1/places:searchText',
    headers={
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': key,
        'X-Goog-FieldMask': 'places.id,places.displayName'
    },
    json={'textQuery': 'In-N-Out Burger Irvine CA'},
    timeout=10
)
print(f'API test: {r.status_code} ({\"OK\" if r.status_code == 200 else \"FAIL\"})')
if r.status_code == 200:
    data = r.json()
    print(f'  Results: {len(data.get(\"places\", []))} places found')
else:
    print(f'  Error: {r.text[:200]}')
"
```

If the API test returns anything other than 200, STOP. Common fixes:
- 403: Places API (New) not enabled on the GCP project. Kyle must enable it in Cloud Console.
- 401: Invalid API key. Check `$GOOGLE_PLACES_API_KEY`.
- Network error: Cloudflare WARP may be blocking. Try disconnecting WARP.

Log all pre-flight output.

---

## Step 1: Create `scripts/phase7_enrich.py`

Write the enrichment script to `scripts/phase7_enrich.py`. It must support:
- `--batch <file>` — enrich only restaurant IDs listed in the file (one per line)
- `--all` — enrich all restaurants in `data/normalized/restaurants.jsonl`
- `--dry-run` — validate API connectivity and show what would be enriched, no writes
- Resume support: skip restaurants already present in `data/enriched/restaurants_enriched.jsonl`

### Core Logic

```python
#!/usr/bin/env python3
"""
phase7_enrich.py — Enrich restaurants via Google Places API (New).

Usage:
    python3 scripts/phase7_enrich.py --batch config/enrich_batch.txt
    python3 scripts/phase7_enrich.py --all
    python3 scripts/phase7_enrich.py --all --dry-run
"""
import argparse, json, os, sys, time
from datetime import datetime, timezone
from difflib import SequenceMatcher
from pathlib import Path

import requests

# ── Config ──────────────────────────────────────────────────
API_KEY = os.environ.get("GOOGLE_PLACES_API_KEY", "")
PLACES_SEARCH_URL = "https://places.googleapis.com/v1/places:searchText"
PLACES_DETAIL_URL = "https://places.googleapis.com/v1/places/{place_id}"

SEARCH_FIELDS = "places.id,places.displayName,places.formattedAddress,places.location"
DETAIL_FIELDS = (
    "id,displayName,formattedAddress,location,rating,userRatingCount,"
    "websiteUri,currentOpeningHours,businessStatus,googleMapsUri,photos"
)

MATCH_THRESHOLD_AUTO = 0.85    # Auto-accept
MATCH_THRESHOLD_REVIEW = 0.70  # Needs review
REQUEST_DELAY = 0.15           # Seconds between API calls (courtesy)
REQUEST_TIMEOUT = 15           # Seconds per request

NORMALIZED_PATH = Path("data/normalized/restaurants.jsonl")
ENRICHED_PATH = Path("data/enriched/restaurants_enriched.jsonl")
CACHE_PATH = Path("data/enriched/places_cache.json")
LOG_DIR = Path("data/logs")

# ── Helpers ──────────────────────────────────────────────────

def fuzzy_match(name_a: str, name_b: str) -> float:
    """Return similarity ratio between two restaurant names."""
    a = name_a.lower().strip()
    b = name_b.lower().strip()
    return SequenceMatcher(None, a, b).ratio()

def city_in_address(city: str, address: str) -> bool:
    """Check if city appears in the formatted address."""
    if not city or not address:
        return False
    return city.lower().strip() in address.lower()

def load_cache() -> dict:
    """Load place_id cache to avoid re-searching known restaurants."""
    if CACHE_PATH.exists():
        return json.loads(CACHE_PATH.read_text())
    return {}

def save_cache(cache: dict):
    CACHE_PATH.parent.mkdir(parents=True, exist_ok=True)
    CACHE_PATH.write_text(json.dumps(cache, indent=2))

def load_already_enriched() -> set:
    """Return set of restaurant_ids already enriched (for resume)."""
    ids = set()
    if ENRICHED_PATH.exists():
        with open(ENRICHED_PATH) as f:
            for line in f:
                line = line.strip()
                if line:
                    r = json.loads(line)
                    ids.add(r.get("restaurant_id", ""))
    return ids

def search_place(name: str, city: str, state: str) -> dict | None:
    """Text Search for a restaurant. Returns first result or None."""
    query = f"{name} {city} {state} restaurant".strip()
    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": API_KEY,
        "X-Goog-FieldMask": SEARCH_FIELDS,
    }
    try:
        resp = requests.post(
            PLACES_SEARCH_URL,
            headers=headers,
            json={"textQuery": query},
            timeout=REQUEST_TIMEOUT,
        )
        if resp.status_code == 429:
            print("    Rate limited. Sleeping 60s...")
            time.sleep(60)
            resp = requests.post(
                PLACES_SEARCH_URL,
                headers=headers,
                json={"textQuery": query},
                timeout=REQUEST_TIMEOUT,
            )
        if resp.status_code != 200:
            print(f"    Search failed: {resp.status_code} {resp.text[:100]}")
            return None
        places = resp.json().get("places", [])
        return places[0] if places else None
    except requests.exceptions.Timeout:
        print(f"    Search timeout for: {query}")
        return None
    except Exception as e:
        print(f"    Search error: {e}")
        return None

def get_place_details(place_id: str) -> dict | None:
    """Fetch detailed info for a place_id."""
    # place_id from search is like "places/ChIJ..."
    # Detail URL needs just the resource name
    resource_name = place_id if place_id.startswith("places/") else f"places/{place_id}"
    url = f"https://places.googleapis.com/v1/{resource_name}"
    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": API_KEY,
        "X-Goog-FieldMask": DETAIL_FIELDS,
    }
    try:
        resp = requests.get(url, headers=headers, timeout=REQUEST_TIMEOUT)
        if resp.status_code == 429:
            print("    Rate limited on details. Sleeping 60s...")
            time.sleep(60)
            resp = requests.get(url, headers=headers, timeout=REQUEST_TIMEOUT)
        if resp.status_code != 200:
            print(f"    Details failed: {resp.status_code} {resp.text[:100]}")
            return None
        return resp.json()
    except Exception as e:
        print(f"    Details error: {e}")
        return None

def map_business_status(status: str | None) -> bool | None:
    """Map Google businessStatus to still_open boolean."""
    if not status:
        return None
    mapping = {
        "OPERATIONAL": True,
        "CLOSED_TEMPORARILY": True,  # Still exists, temporarily closed
        "CLOSED_PERMANENTLY": False,
    }
    return mapping.get(status)

def enrich_restaurant(restaurant: dict, cache: dict) -> tuple[dict | None, str]:
    """
    Enrich a single restaurant. Returns (enriched_data, status).
    Status: 'enriched', 'review', 'no_match', 'cached', 'error'
    """
    rid = restaurant.get("restaurant_id", "unknown")
    name = restaurant.get("name", "")
    city = restaurant.get("city", "")
    state = restaurant.get("state", "")

    if not name or name.lower() in ("none", "null", "unknown"):
        return None, "skip_null_name"

    # Check cache first
    cache_key = f"{name}|{city}|{state}".lower()
    if cache_key in cache:
        cached = cache[cache_key]
        return cached, "cached"

    # Step 1: Text Search
    time.sleep(REQUEST_DELAY)
    search_result = search_place(name, city, state)
    if not search_result:
        return None, "no_match"

    # Step 2: Validate match
    google_name = search_result.get("displayName", {}).get("text", "")
    google_address = search_result.get("formattedAddress", "")
    match_score = fuzzy_match(name, google_name)
    city_match = city_in_address(city, google_address)

    if match_score < MATCH_THRESHOLD_REVIEW:
        return {
            "restaurant_id": rid,
            "match_score": round(match_score, 3),
            "our_name": name,
            "google_name": google_name,
            "google_address": google_address,
        }, "no_match"

    # Step 3: Get details
    place_id = search_result.get("id", "")  # This is the short ID
    # Actually the search returns the resource name in 'name' field or 'id'
    # The Places API (New) returns 'id' as the place resource ID
    time.sleep(REQUEST_DELAY)
    details = get_place_details(place_id)

    if not details:
        return None, "error"

    # Step 4: Build enrichment record
    location = details.get("location", {})
    photos = details.get("photos", [])
    photo_refs = [p.get("name", "") for p in photos[:3]]  # Max 3 photos

    enriched = {
        "restaurant_id": rid,
        "google_place_id": place_id,
        "google_rating": details.get("rating"),
        "google_rating_count": details.get("userRatingCount"),
        "google_maps_url": details.get("googleMapsUri"),
        "website_url": details.get("websiteUri"),
        "formatted_address": details.get("formattedAddress"),
        "business_status": details.get("businessStatus"),
        "still_open": map_business_status(details.get("businessStatus")),
        "photo_references": photo_refs,
        "latitude": location.get("latitude"),
        "longitude": location.get("longitude"),
        "enriched_at": datetime.now(timezone.utc).isoformat(),
        "enrichment_source": "google_places_api",
        "enrichment_match_score": round(match_score, 3),
    }

    # Cache the result
    cache[cache_key] = enriched
    save_cache(cache)

    status = "enriched" if (match_score >= MATCH_THRESHOLD_AUTO and city_match) else "review"
    return enriched, status

def main():
    parser = argparse.ArgumentParser(description="Enrich restaurants via Google Places API")
    parser.add_argument("--batch", type=str, help="File with restaurant_ids to enrich (one per line)")
    parser.add_argument("--all", action="store_true", help="Enrich all restaurants")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be enriched")
    args = parser.parse_args()

    if not API_KEY:
        print("ERROR: GOOGLE_PLACES_API_KEY not set. Exiting.")
        sys.exit(1)

    if not args.batch and not args.all:
        print("ERROR: Specify --batch <file> or --all")
        sys.exit(1)

    # Load restaurants
    restaurants = []
    with open(NORMALIZED_PATH) as f:
        for line in f:
            line = line.strip()
            if line:
                restaurants.append(json.loads(line))
    print(f"Loaded {len(restaurants)} restaurants from {NORMALIZED_PATH}")

    # Filter to batch if specified
    if args.batch:
        batch_ids = set()
        with open(args.batch) as f:
            for line in f:
                line = line.strip()
                if line:
                    batch_ids.add(line)
        restaurants = [r for r in restaurants if r.get("restaurant_id") in batch_ids]
        print(f"Filtered to {len(restaurants)} restaurants from batch file")

    # Check resume state
    already_done = load_already_enriched()
    remaining = [r for r in restaurants if r.get("restaurant_id") not in already_done]
    print(f"Already enriched: {len(already_done)}")
    print(f"Remaining: {len(remaining)}")

    if args.dry_run:
        print(f"\n[DRY RUN] Would enrich {len(remaining)} restaurants. Exiting.")
        return

    # Prepare output paths
    ENRICHED_PATH.parent.mkdir(parents=True, exist_ok=True)
    LOG_DIR.mkdir(parents=True, exist_ok=True)

    cache = load_cache()
    stats = {"enriched": 0, "review": 0, "no_match": 0, "cached": 0,
             "error": 0, "skip_null_name": 0, "coord_backfill": 0}
    consecutive_errors = 0
    last_error = ""

    review_log = open(LOG_DIR / "phase7-review-needed.jsonl", "a")
    no_match_log = open(LOG_DIR / "phase7-no-match.jsonl", "a")
    enriched_file = open(ENRICHED_PATH, "a")

    try:
        for i, restaurant in enumerate(remaining):
            rid = restaurant.get("restaurant_id", "?")
            name = restaurant.get("name", "?")
            print(f"[{i+1}/{len(remaining)}] {name} ({restaurant.get('city')}, {restaurant.get('state')})")

            enriched, status = enrich_restaurant(restaurant, cache)

            if status == "enriched" or status == "cached":
                # Check coordinate backfill
                if enriched and enriched.get("latitude") and not restaurant.get("latitude"):
                    stats["coord_backfill"] += 1
                    print(f"    Backfilled coordinates: {enriched['latitude']}, {enriched['longitude']}")

                enriched_file.write(json.dumps(enriched) + "\n")
                enriched_file.flush()
                stats[status] += 1
                print(f"    ✅ {status} (score: {enriched.get('enrichment_match_score', '?')})")
                consecutive_errors = 0

            elif status == "review":
                enriched_file.write(json.dumps(enriched) + "\n")
                enriched_file.flush()
                review_log.write(json.dumps(enriched) + "\n")
                review_log.flush()
                stats["review"] += 1
                print(f"    ⚠️  review (score: {enriched.get('enrichment_match_score', '?')})")
                consecutive_errors = 0

            elif status == "no_match":
                if enriched:
                    no_match_log.write(json.dumps(enriched) + "\n")
                else:
                    no_match_log.write(json.dumps({"restaurant_id": rid, "name": name}) + "\n")
                no_match_log.flush()
                stats["no_match"] += 1
                print(f"    ❌ no match")
                consecutive_errors = 0

            elif status == "error":
                stats["error"] += 1
                consecutive_errors += 1
                print(f"    🔴 error (consecutive: {consecutive_errors})")
                if consecutive_errors >= 3:
                    print("\n🛑 3 CONSECUTIVE ERRORS — STOPPING. Fix root cause and restart.")
                    break

            elif status == "skip_null_name":
                stats["skip_null_name"] += 1
                print(f"    ⏭️  skipped (null name)")

    finally:
        enriched_file.close()
        review_log.close()
        no_match_log.close()
        save_cache(cache)

    # Print summary
    total = sum(stats.values())
    print(f"\n{'='*50}")
    print(f"Enrichment Complete")
    print(f"{'='*50}")
    print(f"  Total processed:    {total}")
    print(f"  Enriched (auto):    {stats['enriched']}")
    print(f"  Enriched (cached):  {stats['cached']}")
    print(f"  Review needed:      {stats['review']}")
    print(f"  No match:           {stats['no_match']}")
    print(f"  Errors:             {stats['error']}")
    print(f"  Skipped (null):     {stats['skip_null_name']}")
    print(f"  Coord backfills:    {stats['coord_backfill']}")
    match_rate = (stats['enriched'] + stats['cached'] + stats['review']) / max(total - stats['skip_null_name'], 1) * 100
    print(f"  Match rate:         {match_rate:.1f}%")

if __name__ == "__main__":
    main()
```

**Key implementation notes for Gemini:**
- The script above is a REFERENCE. Write it to `scripts/phase7_enrich.py` adapting as needed for the actual Places API (New) response format.
- Use Context7 to verify the Places API (New) response schema if needed.
- The `id` field from Text Search (New) is the place resource name (e.g., `places/ChIJ...`). Use it directly in the Detail URL.
- `FieldMask` header controls billing — only request fields we need.
- `photos` returns resource names, not URLs. Photo URLs are fetched separately if needed in v7.31. For v7.30, just store the photo resource names.

---

## Step 2: Select Discovery Batch

Create a 50-restaurant discovery batch that covers diverse conditions:

```bash
python3 -c "
import json, random

restaurants = []
with open('data/normalized/restaurants.jsonl') as f:
    for line in f:
        line = line.strip()
        if line:
            restaurants.append(json.loads(line))

# Stratify: some with coords, some without, variety of states
with_coords = [r for r in restaurants if r.get('latitude')]
without_coords = [r for r in restaurants if not r.get('latitude')]

random.seed(42)
batch = []
# 35 with existing coordinates (to validate match quality)
batch.extend(random.sample(with_coords, min(35, len(with_coords))))
# 15 without coordinates (to test backfill)
batch.extend(random.sample(without_coords, min(15, len(without_coords))))

# Write batch file
with open('config/enrich_discovery_batch.txt', 'w') as f:
    for r in batch:
        f.write(r['restaurant_id'] + '\n')

print(f'Discovery batch: {len(batch)} restaurants')
print(f'  With coords: {sum(1 for r in batch if r.get(\"latitude\"))}')
print(f'  Without coords: {sum(1 for r in batch if not r.get(\"latitude\"))}')

# Show a few examples
for r in batch[:5]:
    print(f'  - {r[\"name\"]} ({r.get(\"city\")}, {r.get(\"state\")})')
"
```

---

## Step 3: Run Discovery Batch

```bash
python3 scripts/phase7_enrich.py --batch config/enrich_discovery_batch.txt
```

Monitor output. The script should process 50 restaurants in ~2-3 minutes (0.15s delay × 2 API calls × 50 = ~15s API time + overhead).

After completion, verify:
```bash
# Count enriched records
wc -l data/enriched/restaurants_enriched.jsonl

# Check review log
wc -l data/logs/phase7-review-needed.jsonl
cat data/logs/phase7-review-needed.jsonl | head -5

# Check no-match log
wc -l data/logs/phase7-no-match.jsonl

# Check cache
python3 -c "import json; c=json.load(open('data/enriched/places_cache.json')); print(f'Cache entries: {len(c)}')"
```

### Expected Targets for Discovery Batch

| Metric | Target | Acceptable |
|--------|--------|------------|
| Match rate (enriched + review) | ≥ 80% | ≥ 70% |
| Auto-enriched (score ≥ 0.85) | ≥ 60% | ≥ 50% |
| Coordinate backfills | ≥ 5 of 15 | ≥ 3 |
| Errors | 0 | ≤ 2 |
| API cost | $0 (free tier) | ≤ $5 |

If match rate < 70%, STOP and investigate. Common causes:
- Restaurant closed and replaced → Google returns the new tenant. This is expected for some DDD restaurants (show aired 2006-2024).
- Name variant → try adjusting the search query format.
- Rural/small town → Google may not have the listing.

---

## Step 4: Create `scripts/validate_enrichment.py`

Write a validation script that reads `data/enriched/restaurants_enriched.jsonl` and produces metrics:

```bash
python3 scripts/validate_enrichment.py
```

Output should include:
- Total enriched vs total restaurants
- Match score distribution (histogram buckets: 0.70-0.79, 0.80-0.89, 0.90-1.00)
- Rating distribution (1-2, 2-3, 3-4, 4-5, null)
- Business status breakdown (OPERATIONAL, CLOSED_PERMANENTLY, CLOSED_TEMPORARILY, null)
- Coordinate backfill count (restaurants that gained lat/lng from enrichment)
- Website URL fill rate
- Photo reference fill rate
- Top 10 highest-rated restaurants
- Top 10 lowest-rated restaurants (might be interesting DDD picks)

---

## Step 5: Create `scripts/phase7_load_enriched.py`

Write the Firestore merge updater. This script reads `data/enriched/restaurants_enriched.jsonl` and updates existing Firestore documents with enrichment fields using a **merge** operation (not overwrite).

```python
# Key pattern:
doc_ref = db.collection("restaurants").document(restaurant_id)
doc_ref.set(enrichment_fields, merge=True)
```

Fields to merge:
- `google_place_id`
- `google_rating`
- `google_rating_count`
- `google_maps_url`
- `website_url`
- `formatted_address`
- `business_status`
- `still_open`
- `photo_references`
- `enriched_at`
- `enrichment_source`
- `enrichment_match_score`
- `latitude` and `longitude` — **ONLY if the existing document has null coordinates**. Do NOT overwrite Nominatim coordinates that already exist.
- `updated_at` — set to current timestamp

Must support:
- `--batch <file>` — load only restaurant IDs in the file
- `--all` — load all enriched records
- `--dry-run` — show what would be updated, no writes
- Resume: check `enriched_at` field on Firestore doc to skip already-loaded records

```bash
# Test with discovery batch
python3 scripts/phase7_load_enriched.py --batch config/enrich_discovery_batch.txt --dry-run

# If dry-run looks good, load for real
python3 scripts/phase7_load_enriched.py --batch config/enrich_discovery_batch.txt
```

### Firestore Credential Requirement

The script needs Firebase Admin SDK credentials. Check how `scripts/phase6_load_firestore.py` handles auth — use the same pattern (likely `GOOGLE_APPLICATION_CREDENTIALS` env var or Application Default Credentials).

---

## Step 6: Verify Firestore Updates

After loading the discovery batch to Firestore, verify a few records:

```bash
python3 -c "
import firebase_admin
from firebase_admin import credentials, firestore

# Initialize (use same pattern as phase6_load_firestore.py)
if not firebase_admin._apps:
    firebase_admin.initialize_app()
db = firestore.client()

# Check a few enriched restaurants
enriched_sample = db.collection('restaurants').where('enriched_at', '!=', None).limit(5).get()
for doc in enriched_sample:
    data = doc.to_dict()
    print(f\"{data.get('name')} ({data.get('city')}, {data.get('state')})\")
    print(f\"  Rating: {data.get('google_rating')} ({data.get('google_rating_count')} reviews)\")
    print(f\"  Status: {data.get('business_status')} (still_open: {data.get('still_open')})\")
    print(f\"  Website: {data.get('website_url')}\")
    print(f\"  Match: {data.get('enrichment_match_score')}\")
    print()

# Count enriched vs total
total = db.collection('restaurants').count().get()
# Note: Firestore count() may need aggregation query
print(f'Total documents in restaurants collection: check manually')
"
```

Confirm:
- Enrichment fields are present on the documents
- Existing fields (name, city, dishes, visits) are NOT overwritten
- Null-coordinate restaurants that got backfilled now show coordinates

---

## Step 7: Update README.md

### 7a. Project Status Table

Update Phase 7 row:
```
| 7 | Enrichment (Discovery) | ✅ Complete | v7.30 |
| 7 | Enrichment (Production)| ⏳ Pending  | v7.31 |
```

### 7b. Architecture Diagram

Add the Google Places API enrichment step between Nominatim geocoding and Firebase:

```
    ↓ Nominatim (OpenStreetMap)
Geocoded Data
    ↓ Google Places API (New)          ← NEW
Enriched Data (ratings, open/closed, websites)
    ↓ Firebase Admin SDK
Cloud Firestore
```

### 7c. Current Metrics

```markdown
### Current Metrics (Phase 7.30)

- **Videos processed:** 773 of 805
- **Unique restaurants:** 1,102
- **Unique dishes:** 2,286
- **States (valid):** 62 (excluding UNKNOWN)
- **Geocoded:** 916/1102 (83.1%)
- **Enriched (discovery):** 50/1102 (with Google ratings, open/closed, websites)
- **Match rate:** [from validate_enrichment.py]
- **Coordinate backfills:** [count from enrichment]
```

Update these numbers with actual results from the discovery batch.

### 7d. IAO Methodology Section

Confirm Eight Pillars and iteration history table are present (should already be from v6.29). Add v7.30 row:

```
| v7.30 | Enrichment (Discovery) | ✅ | Google Places API enrichment pipeline. 50-restaurant batch. |
```

### 7e. Changelog

```markdown
**v6.29 → v7.30 (Phase 7 Enrichment Discovery)**
- **Success:** Built Google Places API enrichment pipeline with Text Search → Place Details
  flow, fuzzy match validation, caching, and resume support. Discovery batch of 50 restaurants
  enriched with ratings, open/closed status, website URLs, and validated addresses.
- **Key finding:** [match rate]% match rate. [X] restaurants gained coordinates from Google
  where Nominatim had failed. [Y] permanently closed restaurants identified.
- **Outcome:** Pipeline validated for v7.31 full production run.
```

Fill in actual numbers from the discovery batch results.

### 7f. Footer

```markdown
*Last updated: Phase 7.30 — Enrichment Discovery*
```

### 7g. Verify After Writing

```bash
grep "Google Places" ../README.md | head -3
grep "7.30" ../README.md | head -3
grep "Last updated" ../README.md
```

---

## Step 8: Generate Artifacts

### docs/ddd-report-v7.30.md (MANDATORY)

Must include:
1. **Discovery batch results** — match rate, auto-enriched count, review count, no-match count
2. **Match score distribution** — histogram from validate_enrichment.py
3. **Rating distribution** — how do DDD restaurants rate on Google?
4. **Business status breakdown** — how many are still open vs permanently closed?
5. **Coordinate backfill results** — how many of the 15 null-coord restaurants gained coordinates?
6. **API cost** — confirm $0 (free tier) or actual cost
7. **Comparison table** — before enrichment vs after (for the 50-restaurant batch)
8. **Sample enriched records** — 5 representative examples showing enrichment quality
9. **Firestore merge verification** — confirm existing data preserved
10. **Known issues** — any edge cases, low-match restaurants, API quirks
11. **Human interventions:** count (target: 0)
12. **Gemini's Recommendation:** Ready for v7.31 full production run?
13. **README Update Confirmation:** ALL sections updated

### docs/ddd-build-v7.30.md (MANDATORY)

Full transcript: pre-flight output, script creation, batch selection, enrichment output, validation metrics, Firestore load output, README changes, any errors and fixes.

**These artifacts + README update are the FINAL actions. Do NOT end the session without all three.**

---

## Success Criteria

```
[ ] Pre-flight passes (including Google Places API connectivity)
[ ] phase7_enrich.py created with --batch, --all, --dry-run, resume support
[ ] phase7_load_enriched.py created with --batch, --all, --dry-run, merge updates
[ ] validate_enrichment.py created
[ ] Discovery batch: 50 restaurants selected (35 with coords, 15 without)
[ ] Discovery batch: enrichment completed
[ ] Match rate ≥ 70%
[ ] Coordinate backfill ≥ 3 restaurants
[ ] Errors ≤ 2
[ ] Firestore merge verified (enrichment fields added, existing data preserved)
[ ] Human interventions: 0
[ ] README.md COMPREHENSIVELY updated:
    [ ] Phase 7 in status table
    [ ] Architecture diagram includes Google Places API
    [ ] Current metrics updated with enrichment stats
    [ ] Iteration history includes v7.30
    [ ] Changelog entry added
    [ ] Footer: Phase 7.30
[ ] ddd-report-v7.30.md generated
[ ] ddd-build-v7.30.md generated
```

---

## GEMINI.md Update

Before launching, update `pipeline/GEMINI.md` to:

```markdown
# TripleDB Pipeline — Agent Instructions

## Current Iteration: 7.30

Read these two documents in order, then execute the plan:

1. ../docs/ddd-design-v7.30.md — Architecture, methodology, locked decisions
2. ../docs/ddd-plan-v7.30.md — Pre-flight checklist and execution steps

Follow the autonomy rules defined in the plan. Begin with Step 0.

## Rules That Never Change
- Git READ commands allowed (pull, log, status, diff, show)
- Git WRITE commands forbidden (add, commit, push, checkout, branch)
- firebase deploy forbidden — Kyle deploys manually
- NEVER ask permission between steps — auto-proceed on EVERY step
- NEVER ask "should I continue?" or "would you like me to proceed?" — YES, ALWAYS
- If you find yourself typing a question mark, STOP. Re-read the plan. Execute.
- Self-heal errors: diagnose → fix → re-run (max 3 attempts, then skip)
- 3 consecutive identical errors = STOP, fix root cause, restart
- README.md update is the FINAL step — comprehensive, including IAO methodology
- All scripts run from this directory (pipeline/) as working directory
- Google Places API key: $GOOGLE_PLACES_API_KEY (never hardcode, never commit)
```

---

## Launch Sequence

```bash
# 1. Archive previous iteration
cd ~/dev/projects/tripledb
mv docs/ddd-design-v6.29.md docs/archive/ 2>/dev/null
mv docs/ddd-plan-v6.29.md docs/archive/ 2>/dev/null
mv docs/ddd-report-v6.29.md docs/archive/ 2>/dev/null
mv docs/ddd-build-v6.29.md docs/archive/ 2>/dev/null
mv docs/ddd-kt-v6.29.md docs/archive/ 2>/dev/null

# 2. Place new docs
cp /path/to/ddd-design-v7.30.md docs/
cp /path/to/ddd-plan-v7.30.md docs/

# 3. Ensure Google Places API key is set
echo $GOOGLE_PLACES_API_KEY   # Should not be empty

# 4. Enable Places API (New) in GCP Console if not already:
#    https://console.cloud.google.com/apis/library/places.googleapis.com
#    Project: tripledb-e0f77

# 5. Update GEMINI.md
nano pipeline/GEMINI.md

# 6. Commit the setup
git add .
git commit -m "KT starting 7.30"

# 7. Launch (in Konsole, NOT IDE terminal)
cd pipeline
gemini
```

Then type:

```
Read GEMINI.md and execute.
```

---

## After v7.30: Production Run (v7.31)

Once v7.30 completes, review the report, and confirm match quality:

```bash
# Commit v7.30 results
git add .
git commit -m "KT completed 7.30 and README updated"
git push

# Deploy updated app (if Firestore changes warrant it)
cd ~/dev/projects/tripledb/app
flutter build web
firebase deploy --only hosting
```

Then Claude produces v7.31 design + plan for the full 1,102-restaurant production run. v7.31 should be straightforward — the scripts are proven, the thresholds are validated, and resume support handles interruptions.
