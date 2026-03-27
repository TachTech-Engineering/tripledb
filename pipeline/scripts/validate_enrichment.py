#!/usr/bin/env python3
"""
validate_enrichment.py — Quality metrics for Google Places API enrichment.
Reads data/enriched/restaurants_enriched.jsonl and outputs statistics.
"""

import json
from collections import defaultdict
from pathlib import Path

ENRICHED_PATH = Path("data/enriched/restaurants_enriched.jsonl")

def main():
    if not ENRICHED_PATH.exists():
        print(f"Error: {ENRICHED_PATH} not found.")
        return

    restaurants = []
    with open(ENRICHED_PATH) as f:
        for line in f:
            line = line.strip()
            if line:
                restaurants.append(json.loads(line))

    total = len(restaurants)
    if total == 0:
        print("No enriched restaurants found.")
        return

    # Metrics
    scores = {"0.70-0.79": 0, "0.80-0.89": 0, "0.90-1.00": 0}
    ratings = {"1-2": 0, "2-3": 0, "3-4": 0, "4-5": 0, "null": 0}
    statuses = defaultdict(int)
    coord_backfills = 0
    website_fills = 0
    photo_fills = 0
    
    scored_list = []

    for r in restaurants:
        # Match Score
        score = r.get("enrichment_match_score", 0)
        if 0.70 <= score < 0.80: scores["0.70-0.79"] += 1
        elif 0.80 <= score < 0.90: scores["0.80-0.89"] += 1
        elif 0.90 <= score <= 1.00: scores["0.90-1.00"] += 1
        
        # Ratings
        rating = r.get("google_rating")
        if rating is None: ratings["null"] += 1
        elif 1.0 <= rating < 2.0: ratings["1-2"] += 1
        elif 2.0 <= rating < 3.0: ratings["2-3"] += 1
        elif 3.0 <= rating < 4.0: ratings["3-4"] += 1
        elif 4.0 <= rating <= 5.0: ratings["4-5"] += 1
        
        if rating is not None:
            scored_list.append((r.get("restaurant_id"), r.get("google_name", r.get("name", "Unknown")), rating))

        # Status
        statuses[r.get("business_status", "NULL")] += 1
        
        # Coordinates (Backfill logic was handled in enrichment script, we just count if it has them)
        if r.get("latitude") and r.get("longitude"):
            # We assume for validation script that anything in enriched JSON has valid coords
            coord_backfills += 1 
            
        # Website & Photos
        if r.get("website_url"): website_fills += 1
        if r.get("photo_references"): photo_fills += 1

    print("=" * 50)
    print("ENRICHMENT VALIDATION METRICS")
    print("=" * 50)
    print(f"Total Enriched Records: {total}")
    
    print("\n[Match Score Distribution]")
    for bucket, count in scores.items():
        print(f"  {bucket}: {count} ({(count/total)*100:.1f}%)")
        
    print("\n[Google Rating Distribution]")
    for bucket, count in ratings.items():
        print(f"  {bucket}: {count} ({(count/total)*100:.1f}%)")
        
    print("\n[Business Status]")
    for status, count in statuses.items():
        print(f"  {status}: {count} ({(count/total)*100:.1f}%)")

    print(f"\n[Fill Rates]")
    print(f"  Has Coordinates: {coord_backfills} ({(coord_backfills/total)*100:.1f}%)")
    print(f"  Has Website:     {website_fills} ({(website_fills/total)*100:.1f}%)")
    print(f"  Has Photos:      {photo_fills} ({(photo_fills/total)*100:.1f}%)")

    # Top/Bottom rated
    scored_list.sort(key=lambda x: x[2], reverse=True)
    
    print("\n[Top 5 Highest Rated]")
    for rid, name, rating in scored_list[:5]:
        print(f"  {rating:.1f} - {name}")
        
    print("\n[Bottom 5 Lowest Rated]")
    for rid, name, rating in reversed(scored_list[-5:]):
        print(f"  {rating:.1f} - {name}")
        
if __name__ == "__main__":
    main()
