#!/usr/bin/env python3
"""validate_extraction.py — Validate extraction quality across all phases."""
import json, glob, os

print("=" * 60)
print("EXTRACTION VALIDATION — ALL PHASES")
print("=" * 60)

files = sorted([f for f in glob.glob("data/extracted/*.json") if "_raw" not in f])
print(f"\nTotal extracted files: {len(files)}\n")

total_r, total_d = 0, 0
empty_videos = []
video_types = {}
guy_intro_count, guy_response_count = 0, 0
ingredient_count, total_dishes_checked = 0, 0
owner_chef_null = 0
owner_chef_generic = 0
single_dish_restaurants = 0
total_restaurants_checked = 0

for f in files:
    with open(f) as fh:
        try:
            data = json.load(fh)
        except json.JSONDecodeError:
            print(f"  ❌ {f}: INVALID JSON")
            continue

    vid = data.get("video_id", os.path.basename(f).replace(".json", ""))
    vtype = data.get("video_type", "unknown")
    restaurants = data.get("restaurants", [])
    video_types[vtype] = video_types.get(vtype, 0) + 1

    if not restaurants:
        empty_videos.append(vid)
        continue

    r_count = len(restaurants)
    d_count = 0
    for r in restaurants:
        total_restaurants_checked += 1
        chef = r.get("owner_chef")
        if chef is None:
            owner_chef_null += 1
        elif chef.lower() in ["chef", "owner", "pit master", "pitmaster"]:
            owner_chef_generic += 1
        
        if r.get("guy_intro"):
            guy_intro_count += 1

        dishes = r.get("dishes", [])
        if len(dishes) == 1:
            single_dish_restaurants += 1

        for d in dishes:
            d_count += 1
            total_dishes_checked += 1
            if d.get("guy_response"):
                guy_response_count += 1
            if d.get("ingredients") and len(d["ingredients"]) > 0:
                ingredient_count += 1

    total_r += r_count
    total_d += d_count
    print(f"  {vid}: {vtype} | {r_count} restaurants, {d_count} dishes")

print(f"\n{'='*60}")
print(f"TOTALS")
print(f"{'='*60}")
print(f"  Videos with JSON:        {len(files)}")
print(f"  Videos with data:        {len(files) - len(empty_videos)}")
print(f"  Videos empty:            {len(empty_videos)}")
print(f"  Total restaurants:       {total_r}")
print(f"  Total dishes:            {total_d}")
print(f"  Avg dishes/restaurant:   {total_d/max(total_r,1):.1f}")
print(f"  Video types:             {video_types}")

print(f"\n  QUALITY METRICS:")
print(f"  guy_intro:               {guy_intro_count}/{total_restaurants_checked} ({guy_intro_count/max(total_restaurants_checked,1)*100:.0f}%)")
print(f"  guy_response:            {guy_response_count}/{total_dishes_checked} ({guy_response_count/max(total_dishes_checked,1)*100:.0f}%)")
print(f"  ingredients:             {ingredient_count}/{total_dishes_checked} ({ingredient_count/max(total_dishes_checked,1)*100:.0f}%)")
print(f"  owner_chef null:         {owner_chef_null}/{total_restaurants_checked} ({owner_chef_null/max(total_restaurants_checked,1)*100:.0f}%)")
print(f"  owner_chef generic:      {owner_chef_generic}/{total_restaurants_checked} ({owner_chef_generic/max(total_restaurants_checked,1)*100:.0f}%)")
print(f"  single-dish restaurants: {single_dish_restaurants}/{total_restaurants_checked} ({single_dish_restaurants/max(total_restaurants_checked,1)*100:.0f}%)")

if empty_videos:
    print(f"\n  Empty videos: {', '.join(empty_videos)}")

print(f"\n{'='*60}")
print(f"SUCCESS CRITERIA (Phase 2)")
print(f"{'='*60}")
criteria = [
    ("Total extracted files >= 55 (of ~60)", len(files) >= 55),
    ("Videos with restaurants >= 50", (len(files) - len(empty_videos)) >= 50),
    ("Total restaurants >= 250", total_r >= 250),
    ("Total dishes >= 500", total_d >= 500),
    ("Avg dishes/restaurant >= 1.8", total_d/max(total_r,1) >= 1.8),
    ("guy_intro capture >= 80%", guy_intro_count/max(total_restaurants_checked,1) >= 0.8),
    ("guy_response capture >= 80%", guy_response_count/max(total_dishes_checked,1) >= 0.8),
    ("ingredients capture >= 80%", ingredient_count/max(total_dishes_checked,1) >= 0.8),
    ("owner_chef null < 15%", owner_chef_null/max(total_restaurants_checked,1) < 0.15),
    ("owner_chef generic < 10%", owner_chef_generic/max(total_restaurants_checked,1) < 0.10),
]
all_pass = True
for name, passed in criteria:
    print(f"  {'✅' if passed else '❌'} {name}")
    if not passed:
        all_pass = False

print(f"\n{'✅ ALL CRITERIA MET' if all_pass else '❌ SOME CRITERIA FAILED'}")
