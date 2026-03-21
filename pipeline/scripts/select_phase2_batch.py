#!/usr/bin/env python3
"""
select_phase2_batch.py — Pick the next 30 videos from the playlist,
excluding already-processed Phase 1 videos.
Selects a balanced mix of video types by duration.
"""
import os, re, random

# Load Phase 1 video IDs (already processed)
phase1_ids = set()
for f in os.listdir("data/transcripts"):
    if f.endswith(".json"):
        phase1_ids.add(f.replace(".json", ""))

print(f"Phase 1 already processed: {len(phase1_ids)} videos")

# Load all playlist URLs
with open("config/playlist_urls.txt") as f:
    all_lines = [l.strip() for l in f if l.strip() and not l.startswith('#')]

# Parse URL, title, duration
available = []
for line in all_lines:
    match = re.search(r'v=([a-zA-Z0-9_-]{11})', line)
    if not match:
        continue
    vid = match.group(1)
    if vid in phase1_ids:
        continue
    
    # Parse duration from comment: [HH:MM:SS] or [MM:SS] or [NA]
    dur_match = re.search(r'\[(\d+):(\d+):(\d+)\]', line)
    if dur_match:
        h, m, s = int(dur_match.group(1)), int(dur_match.group(2)), int(dur_match.group(3))
        duration = h * 3600 + m * 60 + s
    else:
        dur_match = re.search(r'\[(\d+):(\d+)\]', line)
        if dur_match:
            m, s = int(dur_match.group(1)), int(dur_match.group(2))
            duration = m * 60 + s
        else:
            duration = 0  # NA or unparseable
    
    available.append({"id": vid, "line": line, "duration": duration})

print(f"Available (unprocessed): {len(available)} videos")

# Categorize by duration
clips = [v for v in available if 0 < v["duration"] < 900]
standard = [v for v in available if 900 <= v["duration"] < 1500]
compilations = [v for v in available if 1500 <= v["duration"] < 3600]
marathons = [v for v in available if v["duration"] >= 3600]
unknown = [v for v in available if v["duration"] == 0]

print(f"  Clips (<15m): {len(clips)}")
print(f"  Standard (15-25m): {len(standard)}")
print(f"  Compilations (25-60m): {len(compilations)}")
print(f"  Marathons (>60m): {len(marathons)}")
print(f"  Unknown duration: {len(unknown)}")

# Select balanced mix: 5 clips, 10 standard, 10 compilations, 5 marathons
random.seed(42)  # Reproducible selection
selected = []
selected += random.sample(clips, min(5, len(clips)))
selected += random.sample(standard, min(10, len(standard)))
selected += random.sample(compilations, min(10, len(compilations)))
selected += random.sample(marathons, min(5, len(marathons)))

# If we don't have 30 yet, fill from whatever's most available
while len(selected) < 30 and len(available) > len(selected):
    remaining = [v for v in available if v not in selected]
    if not remaining:
        break
    selected.append(random.choice(remaining))

# Write batch file
with open("config/phase2_batch.txt", "w") as f:
    f.write(f"# TripleDB Phase 2 Batch — {len(selected)} videos\n")
    f.write(f"# Selected from {len(available)} unprocessed videos\n\n")
    
    for v in sorted(selected, key=lambda x: x["duration"]):
        f.write(v["line"] + "\n")

print(f"\nWrote config/phase2_batch.txt with {len(selected)} videos")
for v in sorted(selected, key=lambda x: x["duration"])[:5]:
    print(f"  {v['id']}: {v['duration']//60}m")
print(f"  ...")
for v in sorted(selected, key=lambda x: x["duration"])[-5:]:
    print(f"  {v['id']}: {v['duration']//60}m")

Run it:

python3 scripts/select_phase2_batch.py
