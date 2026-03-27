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