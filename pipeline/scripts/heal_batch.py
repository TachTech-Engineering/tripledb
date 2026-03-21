#!/usr/bin/env python3
import os
import re

# Load all transcribed IDs
transcribed = set(f.replace('.json', '') for f in os.listdir('data/transcripts') if f.endswith('.json'))

# Load current batch
with open('config/phase3_batch.txt') as f:
    batch_lines = f.readlines()

new_batch_lines = []
needed = 0

# Keep only those that are transcribed or keep the header
for line in batch_lines:
    if line.startswith('#'):
        new_batch_lines.append(line)
        continue
    match = re.search(r'[?&]v=([a-zA-Z0-9_-]{11})', line)
    if match:
        vid = match.group(1)
        if vid in transcribed:
            new_batch_lines.append(line)
        else:
            needed += 1

print(f"Removed {needed} untranscribed videos from batch.")

# Find replacement clips from playlist
with open('config/playlist_urls.txt') as f:
    all_lines = f.readlines()

added = 0
for line in all_lines:
    if line.startswith('#'): continue
    match = re.search(r'[?&]v=([a-zA-Z0-9_-]{11})', line)
    if not match: continue
    vid = match.group(1)
    
    # Check if it's a clip (duration < 900)
    dur_match = re.search(r'\[(\d+):(\d+):(\d+)\]', line)
    if dur_match:
        duration = int(dur_match.group(1))*3600 + int(dur_match.group(2))*60 + int(dur_match.group(3))
    else:
        dur_match = re.search(r'\[(\d+):(\d+)\]', line)
        duration = int(dur_match.group(1))*60 + int(dur_match.group(2)) if dur_match else 0
        
    if 0 < duration < 600 and vid not in transcribed:
        new_batch_lines.append(line)
        added += 1
        if added >= needed:
            break

with open('config/phase3_batch.txt', 'w') as f:
    f.writelines(new_batch_lines)

print(f"Added {added} new clips to batch.")
