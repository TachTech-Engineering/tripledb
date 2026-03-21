#!/usr/bin/env python3
"""
select_batch.py — Select the next N unprocessed videos from the playlist.
Excludes already-transcribed videos. Writes to config/phase3_batch.txt.
"""
import os, re, random, argparse

parser = argparse.ArgumentParser()
parser.add_argument("--count", type=int, default=30, help="Number of videos to select")
parser.add_argument("--output", default="config/phase3_batch.txt", help="Output file")
parser.add_argument("--seed", type=int, default=123, help="Random seed for reproducibility")
parser.add_argument("--bias-marathons", action="store_true", help="Oversample marathons for stress testing")
args = parser.parse_args()

# Already processed
processed_ids = set()
if os.path.isdir("data/transcripts"):
    for f in os.listdir("data/transcripts"):
        if f.endswith(".json"):
            processed_ids.add(f.replace(".json", ""))
print(f"Already processed: {len(processed_ids)} videos")

# Parse playlist
with open("config/playlist_urls.txt") as f:
    all_lines = [l.strip() for l in f if l.strip() and not l.startswith('#')]

available = []
for line in all_lines:
    match = re.search(r'v=([a-zA-Z0-9_-]{11})', line)
    if not match:
        continue
    vid = match.group(1)
    if vid in processed_ids:
        continue
    dur_match = re.search(r'\[(\d+):(\d+):(\d+)\]', line)
    if dur_match:
        duration = int(dur_match.group(1))*3600 + int(dur_match.group(2))*60 + int(dur_match.group(3))
    else:
        dur_match = re.search(r'\[(\d+):(\d+)\]', line)
        duration = int(dur_match.group(1))*60 + int(dur_match.group(2)) if dur_match else 0
    available.append({"id": vid, "line": line, "duration": duration})

print(f"Available: {len(available)} videos")

clips = [v for v in available if 0 < v["duration"] < 900]
standard = [v for v in available if 900 <= v["duration"] < 1500]
compilations = [v for v in available if 1500 <= v["duration"] < 3600]
marathons = [v for v in available if v["duration"] >= 3600]
unknown = [v for v in available if v["duration"] == 0]

print(f"  Clips: {len(clips)} | Standard: {len(standard)} | Compilations: {len(compilations)} | Marathons: {len(marathons)} | Unknown: {len(unknown)}")

random.seed(args.seed)
selected = []

if args.bias_marathons:
    # Phase 3 stress test: heavy on marathons and compilations
    selected += random.sample(marathons, min(8, len(marathons)))
    selected += random.sample(compilations, min(12, len(compilations)))
    selected += random.sample(standard, min(5, len(standard)))
    selected += random.sample(clips, min(3, len(clips)))
    remaining = [v for v in available if v not in selected]
    while len(selected) < args.count and remaining:
        selected.append(remaining.pop(random.randint(0, len(remaining)-1)))
else:
    selected += random.sample(clips, min(5, len(clips)))
    selected += random.sample(standard, min(10, len(standard)))
    selected += random.sample(compilations, min(10, len(compilations)))
    selected += random.sample(marathons, min(5, len(marathons)))
    remaining = [v for v in available if v not in selected]
    while len(selected) < args.count and remaining:
        selected.append(remaining.pop(random.randint(0, len(remaining)-1)))

with open(args.output, "w") as f:
    f.write(f"# TripleDB Phase 3 Batch — {len(selected)} videos (stress test: marathon-heavy)\n\n")
    for v in sorted(selected, key=lambda x: x["duration"]):
        f.write(v["line"] + "\n")

print(f"\nWrote {args.output} with {len(selected)} videos")
types = {"clip": 0, "standard": 0, "compilation": 0, "marathon": 0}
for v in selected:
    if v["duration"] < 900: types["clip"] += 1
    elif v["duration"] < 1500: types["standard"] += 1
    elif v["duration"] < 3600: types["compilation"] += 1
    else: types["marathon"] += 1
print(f"  Mix: {types}")
