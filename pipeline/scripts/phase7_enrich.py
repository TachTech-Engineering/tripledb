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
    if city.lower().strip() in ["none", "null", "unknown"]:
        return True # If city is fundamentally unknown, don't let it fail the address check
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
    """Text Search for a restaurant. Returns first result or None. Raises Exception on API error."""
    # Build query safely, omitting None/Unknown values
    query_parts = [name]
    if city and city.lower() not in ["none", "null", "unknown"]:
        query_parts.append(city)
    if state and state.lower() not in ["none", "null", "unknown"]:
        query_parts.append(state)
    query_parts.append("restaurant")
    query = " ".join(query_parts).strip()
    
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
            raise Exception(f"API Error {resp.status_code}")
        places = resp.json().get("places", [])
        return places[0] if places else None
    except requests.exceptions.Timeout:
        print(f"    Search timeout for: {query}")
        raise
    except Exception as e:
        if not str(e).startswith("API Error"):
            print(f"    Search error: {e}")
        raise

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
            raise Exception(f"API Error {resp.status_code}")
        return resp.json()
    except Exception as e:
        if not str(e).startswith("API Error"):
            print(f"    Details error: {e}")
        raise

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
    Status: 'enriched', 'review', 'no_match', 'cached', 'error', 'skip_null_name'
    """
    rid = restaurant.get("restaurant_id", "unknown")
    name = restaurant.get("name", "")
    city = restaurant.get("city", "")
    state = restaurant.get("state", "")

    if not name or name.lower() in ("none", "null", "unknown") or name.lower().startswith("unknown restaurant"):
        return None, "skip_null_name"

    # Check cache first
    cache_key = f"{name}|{city}|{state}".lower()
    if cache_key in cache:
        cached = cache[cache_key]
        return cached, "cached"

    # Step 1: Text Search
    try:
        time.sleep(REQUEST_DELAY)
        search_result = search_place(name, city, state)
    except Exception:
        return None, "error"
        
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
