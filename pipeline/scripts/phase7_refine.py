#!/usr/bin/env python3
"""
phase7_refine.py — Refined Google Places search for no-match restaurants.

Reads the no-match log from v7.31 and tries alternative query patterns
to recover matches that the original name+city+state search missed.

Usage:
    python3 scripts/phase7_refine.py
    python3 scripts/phase7_refine.py --dry-run
"""
import argparse, json, os, sys, time
from datetime import datetime, timezone
from difflib import SequenceMatcher
from pathlib import Path
import requests

API_KEY = os.environ.get("GOOGLE_PLACES_API_KEY", "")
SEARCH_URL = "https://places.googleapis.com/v1/places:searchText"
DETAIL_URL = "https://places.googleapis.com/v1/places/{place_id}"

SEARCH_FIELDS = "places.id,places.displayName,places.formattedAddress,places.location"
DETAIL_FIELDS = (
    "id,displayName,formattedAddress,location,rating,userRatingCount,"
    "websiteUri,currentOpeningHours,businessStatus,googleMapsUri,photos"
)

MATCH_THRESHOLD = 0.70
REQUEST_DELAY = 0.15
REQUEST_TIMEOUT = 15

NO_MATCH_LOG = Path("data/logs/phase7-no-match.jsonl")
NORMALIZED_PATH = Path("data/normalized/restaurants.jsonl")
ENRICHED_PATH = Path("data/enriched/restaurants_enriched.jsonl")
CACHE_PATH = Path("data/enriched/places_cache.json")
LOG_DIR = Path("data/logs")

def fuzzy_match(a: str, b: str) -> float:
    return SequenceMatcher(None, a.lower().strip(), b.lower().strip()).ratio()

def search_place(query: str) -> dict | None:
    """Single Text Search call. Returns first result or None."""
    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": API_KEY,
        "X-Goog-FieldMask": SEARCH_FIELDS,
    }
    try:
        resp = requests.post(
            SEARCH_URL,
            headers=headers,
            json={"textQuery": query},
            timeout=REQUEST_TIMEOUT,
        )
        if resp.status_code == 429:
            print("    Rate limited. Sleeping 60s...")
            time.sleep(60)
            resp = requests.post(SEARCH_URL, headers=headers,
                                json={"textQuery": query}, timeout=REQUEST_TIMEOUT)
        if resp.status_code != 200:
            return None
        places = resp.json().get("places", [])
        return places[0] if places else None
    except Exception as e:
        print(f"    Search error: {e}")
        return None

def get_details(place_id: str) -> dict | None:
    """Fetch Place Details for a matched place."""
    resource = place_id if place_id.startswith("places/") else f"places/{place_id}"
    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": API_KEY,
        "X-Goog-FieldMask": DETAIL_FIELDS,
    }
    try:
        resp = requests.get(f"https://places.googleapis.com/v1/{resource}",
                           headers=headers, timeout=REQUEST_TIMEOUT)
        if resp.status_code == 429:
            time.sleep(60)
            resp = requests.get(f"https://places.googleapis.com/v1/{resource}",
                               headers=headers, timeout=REQUEST_TIMEOUT)
        return resp.json() if resp.status_code == 200 else None
    except Exception as e:
        print(f"    Details error: {e}")
        return None

def build_queries(restaurant: dict) -> list[tuple[int, str]]:
    """Build up to 4 query variants. Returns list of (pass_number, query_string)."""
    name = restaurant.get("name", "")
    city = restaurant.get("city", "") or ""
    state = restaurant.get("state", "") or ""
    owner = restaurant.get("owner_chef", "") or ""
    cuisine = restaurant.get("cuisine_type", "") or ""

    # Clean null-like values
    if str(city).lower() in ("none", "null", "unknown", "n/a", ""):
        city = ""
    if str(owner).lower() in ("none", "null", "unknown", "n/a", ""):
        owner = ""
    if str(cuisine).lower() in ("none", "null", "unknown", "n/a", ""):
        cuisine = ""

    queries = []

    # Pass 1: Exact name in quotes with city and state
    if city:
        queries.append((1, f'"{name}" "{city}" {state}'))
    else:
        queries.append((1, f'"{name}" {state} restaurant'))

    # Pass 2: Owner/chef name (often more unique than restaurant name)
    if owner:
        if city:
            queries.append((2, f'"{owner}" restaurant {city} {state}'))
        else:
            queries.append((2, f'"{owner}" restaurant {state}'))

    # Pass 3: Name + cuisine + state (for null-city records)
    if cuisine:
        queries.append((3, f'"{name}" {cuisine} {state}'))

    # Pass 4: DDD-aware search (Google indexes show appearances)
    queries.append((4, f'"{name}" Diners Drive-Ins and Dives'))

    return queries

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    if not API_KEY:
        print("ERROR: GOOGLE_PLACES_API_KEY not set. HALTING.")
        sys.exit(1)

    # Load no-match records
    no_match_ids = set()
    if NO_MATCH_LOG.exists():
        with open(NO_MATCH_LOG) as f:
            for line in f:
                line = line.strip()
                if line:
                    rec = json.loads(line)
                    no_match_ids.add(rec.get("restaurant_id", rec.get("name", "")))
    print(f"No-match records to refine: {len(no_match_ids)}")

    # Load full restaurant data (for owner_chef, cuisine_type)
    all_restaurants = {}
    with open(NORMALIZED_PATH) as f:
        for line in f:
            line = line.strip()
            if line:
                r = json.loads(line)
                all_restaurants[r.get("restaurant_id", "")] = r

    # Filter to no-match restaurants with full data
    targets = []
    for rid in no_match_ids:
        if rid in all_restaurants:
            targets.append(all_restaurants[rid])
    print(f"Targets with full data: {len(targets)}")

    # Check for already-refined records (resume support)
    refined_log = LOG_DIR / "phase7-refined-matches.jsonl"
    already_refined = set()
    if refined_log.exists():
        with open(refined_log) as f:
            for line in f:
                if line.strip():
                    already_refined.add(json.loads(line).get("restaurant_id", ""))
    final_no_match_log = LOG_DIR / "phase7-final-no-match.jsonl"
    already_final = set()
    if final_no_match_log.exists():
        with open(final_no_match_log) as f:
            for line in f:
                if line.strip():
                    already_final.add(json.loads(line).get("restaurant_id", ""))
    skip_ids = already_refined | already_final
    remaining = [r for r in targets if r.get("restaurant_id") not in skip_ids]
    print(f"Already processed: {len(skip_ids)}, Remaining: {len(remaining)}")

    if args.dry_run:
        print(f"\n[DRY RUN] Would attempt refined search on {len(remaining)} restaurants.")
        # Show a few sample queries
        for r in remaining[:3]:
            queries = build_queries(r)
            print(f"  {r['name']} ({r.get('city')}, {r.get('state')}):")
            for pn, q in queries:
                print(f"    Pass {pn}: {q}")
        return

    # Prepare output files
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    refined_file = open(refined_log, "a")
    final_file = open(final_no_match_log, "a")
    enriched_file = open(ENRICHED_PATH, "a")

    cache = {}
    if CACHE_PATH.exists():
        try:
            cache = json.loads(CACHE_PATH.read_text())
        except:
            pass

    stats = {"refined": 0, "still_no_match": 0, "error": 0,
             "coord_backfill": 0, "by_pass": {1: 0, 2: 0, 3: 0, 4: 0}}

    try:
        for i, restaurant in enumerate(remaining):
            rid = restaurant.get("restaurant_id", "?")
            name = restaurant.get("name", "?")
            print(f"[{i+1}/{len(remaining)}] {name} ({restaurant.get('city')}, {restaurant.get('state')})")

            queries = build_queries(restaurant)
            matched = False

            for pass_num, query in queries:
                time.sleep(REQUEST_DELAY)
                result = search_place(query)

                if not result:
                    continue

                google_name = result.get("displayName", {}).get("text", "")
                score = fuzzy_match(name, google_name)

                if score >= MATCH_THRESHOLD:
                    # Got a match — fetch details
                    time.sleep(REQUEST_DELAY)
                    place_id = result.get("id", "")
                    details = get_details(place_id)

                    if details:
                        location = details.get("location", {})
                        photos = details.get("photos", [])

                        enriched = {
                            "restaurant_id": rid,
                            "google_place_id": place_id,
                            "google_rating": details.get("rating"),
                            "google_rating_count": details.get("userRatingCount"),
                            "google_maps_url": details.get("googleMapsUri"),
                            "website_url": details.get("websiteUri"),
                            "formatted_address": details.get("formattedAddress"),
                            "business_status": details.get("businessStatus"),
                            "still_open": {"OPERATIONAL": True, "CLOSED_TEMPORARILY": True,
                                          "CLOSED_PERMANENTLY": False}.get(details.get("businessStatus")),
                            "photo_references": [p.get("name", "") for p in photos[:3]],
                            "latitude": location.get("latitude"),
                            "longitude": location.get("longitude"),
                            "enriched_at": datetime.now(timezone.utc).isoformat(),
                            "enrichment_source": "google_places_api",
                            "enrichment_match_score": round(score, 3),
                            "enrichment_query_pass": pass_num,
                        }

                        # Coordinate backfill check
                        if enriched.get("latitude") and not restaurant.get("latitude"):
                            stats["coord_backfill"] += 1

                        enriched_file.write(json.dumps(enriched) + "\n")
                        enriched_file.flush()
                        refined_file.write(json.dumps({"restaurant_id": rid,
                            "name": name, "pass": pass_num, "score": round(score, 3),
                            "google_name": google_name}) + "\n")
                        refined_file.flush()

                        stats["refined"] += 1
                        stats["by_pass"][pass_num] += 1
                        print(f"    ✅ Matched on pass {pass_num} (score: {score:.3f}) → {google_name}")
                        matched = True
                        break

            if not matched:
                final_file.write(json.dumps({"restaurant_id": rid, "name": name,
                    "city": restaurant.get("city"), "state": restaurant.get("state")}) + "\n")
                final_file.flush()
                stats["still_no_match"] += 1
                print(f"    ❌ No match after {len(queries)} passes")

    finally:
        refined_file.close()
        final_file.close()
        enriched_file.close()
        if cache:
             CACHE_PATH.write_text(json.dumps(cache, indent=2))

    total = stats["refined"] + stats["still_no_match"] + stats["error"]
    print(f"\n{'='*50}")
    print(f"Refinement Complete")
    print(f"{'='*50}")
    print(f"  Total processed:     {total}")
    print(f"  Newly matched:       {stats['refined']}")
    print(f"  Still no match:      {stats['still_no_match']}")
    print(f"  Errors:              {stats['error']}")
    print(f"  Coord backfills:     {stats['coord_backfill']}")
    print(f"  By pass: 1={stats['by_pass'][1]}, 2={stats['by_pass'][2]}, "
          f"3={stats['by_pass'][3]}, 4={stats['by_pass'][4]}")
    if total > 0:
        print(f"  Recovery rate:       {stats['refined']/total*100:.1f}%")

if __name__ == "__main__":
    main()
