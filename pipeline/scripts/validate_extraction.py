#!/usr/bin/env python3
"""validate_extraction.py — Check extraction quality."""
import json, glob, os

print("=== EXTRACTION VALIDATION ===\n")

files = sorted([f for f in glob.glob("data/extracted/*.json") if "_raw" not in f])
print(f"Extracted files: {len(files)}\n")

total_r, total_d = 0, 0
empty_videos = []
video_types = {}
guy_intro_count, guy_response_count = 0, 0
ingredient_count, total_dishes_checked = 0, 0

for f in files:
    with open(f) as fh:
        data = json.load(fh)

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
        if r.get("guy_intro"):
            guy_intro_count += 1
        for d in r.get("dishes", []):
            d_count += 1
            total_dishes_checked += 1
            if d.get("guy_response"):
                guy_response_count += 1
            if d.get("ingredients") and len(d["ingredients"]) > 0:
                ingredient_count += 1

    total_r += r_count
    total_d += d_count
    print(f"  {vid}: {vtype} | {r_count} restaurants, {d_count} dishes")

print(f"\n{'='*50}")
print(f"TOTALS")
print(f"{'='*50}")
print(f"  Videos with JSON:    {len(files)}")
print(f"  Videos with data:    {len(files) - len(empty_videos)}")
print(f"  Videos empty:        {len(empty_videos)}")
print(f"  Total restaurants:   {total_r}")
print(f"  Total dishes:        {total_d}")
print(f"  Avg dishes/rest:     {total_d/max(total_r,1):.1f}")
print(f"  Video types:         {video_types}")
print(f"  guy_intro:           {guy_intro_count}/{total_r} ({guy_intro_count/max(total_r,1)*100:.0f}%)")
print(f"  guy_response:        {guy_response_count}/{total_d} ({guy_response_count/max(total_d,1)*100:.0f}%)")
print(f"  ingredients:         {ingredient_count}/{total_dishes_checked} ({ingredient_count/max(total_dishes_checked,1)*100:.0f}%)")

if empty_videos:
    print(f"\n  Empty: {', '.join(empty_videos)}")

print(f"\n{'='*50}")
print(f"SUCCESS CRITERIA")
print(f"{'='*50}")
criteria = [
    ("JSON files >= 28 (of 30)", len(files) >= 28),
    ("Videos with restaurants >= 25", (len(files) - len(empty_videos)) >= 25),
    ("Total restaurants >= 50", total_r >= 50),
    ("Total dishes >= 100", total_d >= 100),
    ("Avg dishes/restaurant >= 1.5", total_d/max(total_r,1) >= 1.5),
    ("guy_intro capture >= 50%", guy_intro_count/max(total_r,1) >= 0.5),
    ("guy_response capture >= 50%", guy_response_count/max(total_d,1) >= 0.5),
    ("ingredients capture >= 60%", ingredient_count/max(total_dishes_checked,1) >= 0.6),
]
all_pass = True
for name, passed in criteria:
    print(f"  {'✅' if passed else '❌'} {name}")
    if not passed:
        all_pass = False

print(f"\n{'✅ ALL CRITERIA MET — ready for Phase 2' if all_pass else '❌ SOME CRITERIA FAILED — review before Phase 2'}")
