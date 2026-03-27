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
