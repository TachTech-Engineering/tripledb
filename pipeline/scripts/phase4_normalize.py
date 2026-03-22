#!/usr/bin/env python3
"""
phase4_normalize.py — Normalize and deduplicate extracted restaurant data.
Uses intelligent matching and merging.
Produces 4 JSONL files in data/normalized/.
"""
import os, sys, json, glob, time, re, uuid
from pathlib import Path
from collections import defaultdict

EXTRACTED_DIR = Path("data/extracted")
NORMALIZED_DIR = Path("data/normalized")
LOG_DIR = Path("data/logs")

def load_all_extractions():
    """Load all extracted JSONs into a unified list."""
    all_restaurants = []
    all_videos = []
    
    for f in sorted(EXTRACTED_DIR.glob("*.json")):
        if "_raw" in f.name:
            continue
        try:
            with open(f) as fh:
                data = json.load(fh)
        except json.JSONDecodeError:
            continue
        
        video_id = data.get("video_id", f.stem)
        video_title = data.get("video_title", "")
        video_type = data.get("video_type", "unknown")
        
        all_videos.append({
            "video_id": video_id,
            "youtube_url": f"https://youtube.com/watch?v={video_id}",
            "title": video_title,
            "video_type": video_type,
            "restaurant_count": len(data.get("restaurants", []))
        })
        
        for r in data.get("restaurants", []):
            r["_source_video_id"] = video_id
            r["_source_video_title"] = video_title
            r["_source_video_type"] = video_type
            all_restaurants.append(r)
    
    return all_restaurants, all_videos

def normalize_state(state):
    """Convert full state names to 2-letter abbreviations."""
    if not state: return None
    state_map = {
        "alabama": "AL", "alaska": "AK", "arizona": "AZ", "arkansas": "AR",
        "california": "CA", "colorado": "CO", "connecticut": "CT", "delaware": "DE",
        "florida": "FL", "georgia": "GA", "hawaii": "HI", "idaho": "ID",
        "illinois": "IL", "indiana": "IN", "iowa": "IA", "kansas": "KS",
        "kentucky": "KY", "louisiana": "LA", "maine": "ME", "maryland": "MD",
        "massachusetts": "MA", "michigan": "MI", "minnesota": "MN",
        "mississippi": "MS", "missouri": "MO", "montana": "MT", "nebraska": "NE",
        "nevada": "NV", "new hampshire": "NH", "new jersey": "NJ",
        "new mexico": "NM", "new york": "NY", "north carolina": "NC",
        "north dakota": "ND", "ohio": "OH", "oklahoma": "OK", "oregon": "OR",
        "pennsylvania": "PA", "rhode island": "RI", "south carolina": "SC",
        "south dakota": "SD", "tennessee": "TN", "texas": "TX", "utah": "UT",
        "vermont": "VT", "virginia": "VA", "washington": "WA",
        "west virginia": "WV", "wisconsin": "WI", "wyoming": "WY",
        "d.c.": "DC", "district of columbia": "DC",
    }
    s = state.lower().strip().replace(".", "")
    if len(s) == 2:
        return s.upper()
    return state_map.get(s, state)

def normalize_ingredients(ingredients):
    """Lowercase, singularize, standardize ingredient names."""
    if not ingredients:
        return []
    normalized = []
    for ing in ingredients:
        ing = ing.lower().strip()
        # Basic singularization
        if ing.endswith("ies"):
            ing = ing[:-3] + "y"
        elif ing.endswith("es") and not ing.endswith("ses"):
            ing = ing[:-2]
        elif ing.endswith("s") and not ing.endswith("ss"):
            ing = ing[:-1]
        # Standardize common variants
        ing = ing.replace("barbecue", "bbq").replace("jalapeño", "jalapeno")
        normalized.append(ing)
    return normalized

def group_potential_duplicates(restaurants):
    """Group restaurants by name similarity + city for dedup candidates."""
    groups = defaultdict(list)
    for r in restaurants:
        name = (r.get("name") or "").lower().strip()
        # Remove common DDD suffixes and noise
        name = re.sub(r' (restaurant|cafe|grill|bar|kitchen|bbq|pit)$', '', name)
        name = re.sub(r'[^a-z0-9]', '', name)
        
        city = (r.get("city") or "").lower().strip()
        city = re.sub(r'[^a-z0-9]', '', city)
        
        # Key: cleaned name + city
        key = f"{name}|{city}"
        groups[key].append(r)
    return groups

def build_normalized_restaurant(base, all_appearances):
    """Build a normalized restaurant document from a base record and all appearances."""
    rid = f"r_{uuid.uuid4().hex[:12]}"
    
    # Merge dishes from all appearances, dedup by name
    seen_dishes = {}
    for appearance in all_appearances:
        for d in appearance.get("dishes", []):
            dname = (d.get("dish_name") or "").lower().strip()
            # Clean dish name for matching
            dname_clean = re.sub(r'[^a-z0-9]', '', dname)
            if dname_clean not in seen_dishes or d.get("confidence", 0) > seen_dishes[dname_clean].get("confidence", 0):
                seen_dishes[dname_clean] = d
    
    dishes = []
    for d in seen_dishes.values():
        dishes.append({
            "dish_name": d.get("dish_name"),
            "description": d.get("description"),
            "ingredients": normalize_ingredients(d.get("ingredients", [])),
            "dish_category": d.get("dish_category"),
            "guy_response": d.get("guy_response"),
            "video_id": d.get("_source_video_id", all_appearances[0].get("_source_video_id")),
            "timestamp_start": d.get("timestamp_start")
        })
    
    visits = []
    for appearance in all_appearances:
        visits.append({
            "video_id": appearance.get("_source_video_id"),
            "youtube_url": f"https://youtube.com/watch?v={appearance.get('_source_video_id')}",
            "video_title": appearance.get("_source_video_title"),
            "video_type": appearance.get("_source_video_type"),
            "guy_intro": appearance.get("guy_intro"),
            "timestamp_start": appearance.get("timestamp_start"),
            "timestamp_end": appearance.get("timestamp_end")
        })
    
    return {
        "restaurant_id": rid,
        "name": base.get("name"),
        "city": base.get("city"),
        "state": normalize_state(base.get("state")),
        "address": None,
        "latitude": None,
        "longitude": None,
        "cuisine_type": base.get("cuisine_type"),
        "owner_chef": base.get("owner_chef"),
        "still_open": None,
        "google_rating": None,
        "yelp_rating": None,
        "website_url": None,
        "visits": visits,
        "dishes": dishes,
        "created_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "updated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    }

def main():
    NORMALIZED_DIR.mkdir(parents=True, exist_ok=True)
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    
    print("Loading all extractions...")
    all_restaurants, all_videos = load_all_extractions()
    print(f"  Total raw restaurant appearances: {len(all_restaurants)}")
    print(f"  Total source videos: {len(all_videos)}")
    
    valid_restaurants = []
    null_records = []
    for r in all_restaurants:
        name = r.get("name") or ""
        if not name.strip() or name.strip().lower() in ("none", "null", "unknown", "n/a"):
            null_records.append(r)
        else:
            state = r.get("state") or ""
            if not state.strip() or state.strip().lower() in ("none", "null", "unknown"):
                state = "UNKNOWN"
            r["state"] = state
            valid_restaurants.append(r)

    if null_records:
        with open(LOG_DIR / "phase-4-null-records.jsonl", "w") as f:
            for r in null_records:
                f.write(json.dumps(r) + "\n")
        print(f"  Filtered {len(null_records)} null-name restaurants (logged to phase-4-null-records.jsonl)")
    
    print("\nGrouping potential duplicates...")
    groups = group_potential_duplicates(valid_restaurants)
    print(f"  Unique restaurant-city pairs: {len(groups)}")
    
    print("\nMerging and normalizing...")
    normalized_restaurants = []
    dedup_log = []
    
    for key, group in groups.items():
        # Pick the most complete record as base
        best = max(group, key=lambda r: (
            bool(r.get("owner_chef")),
            len(r.get("dishes", [])),
            len(r.get("guy_intro") or ""),
            r.get("confidence", 0)
        ))
        
        merged = build_normalized_restaurant(best, group)
        normalized_restaurants.append(merged)
        
        if len(group) > 1:
            dedup_log.append({
                "merged_name": merged["name"],
                "merged_city": merged["city"],
                "source_count": len(group),
                "source_videos": [r.get("_source_video_id") for r in group],
                "final_dish_count": len(merged["dishes"])
            })
    
    # Write normalized JSONL files
    print(f"\nWriting normalized files...")
    
    with open(NORMALIZED_DIR / "restaurants.jsonl", "w") as f:
        for r in normalized_restaurants:
            f.write(json.dumps(r) + "\n")
    print(f"  restaurants.jsonl: {len(normalized_restaurants)} records")
    
    with open(NORMALIZED_DIR / "videos.jsonl", "w") as f:
        for v in all_videos:
            f.write(json.dumps(v) + "\n")
    print(f"  videos.jsonl: {len(all_videos)} records")
    
    with open(LOG_DIR / "phase-4-dedup-report.jsonl", "w") as f:
        for entry in dedup_log:
            f.write(json.dumps(entry) + "\n")
    print(f"  dedup report: {len(dedup_log)} merges")
    
    # Summary stats
    total_dishes = sum(len(r["dishes"]) for r in normalized_restaurants)
    total_visits = sum(len(r["visits"]) for r in normalized_restaurants)
    states = set(r["state"] for r in normalized_restaurants if r.get("state"))
    
    print(f"\n{'='*60}")
    print(f"NORMALIZATION SUMMARY")
    print(f"{'='*60}")
    print(f"  Raw appearances:              {len(all_restaurants)}")
    print(f"  Normalized restaurants:       {len(normalized_restaurants)}")
    print(f"  Dedup merges:                {len(dedup_log)}")
    print(f"  Total dishes:                {total_dishes}")
    print(f"  Total visits:                {total_visits}")
    print(f"  Unique states:               {len(states)}")
    print(f"  Avg dishes/restaurant:       {total_dishes/max(len(normalized_restaurants),1):.1f}")
    print(f"  Avg visits/restaurant:       {total_visits/max(len(normalized_restaurants),1):.1f}")
    print(f"{'='*60}")

if __name__ == "__main__":
    main()
