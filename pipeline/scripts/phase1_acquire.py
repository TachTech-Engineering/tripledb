import argparse
import csv
import json
import os
import re
import subprocess
import time
from urllib.parse import urlparse, parse_qs

def extract_video_id(url):
    """Extracts YouTube video ID from URL."""
    parsed_url = urlparse(url)
    if parsed_url.hostname in ('youtu.be', 'www.youtu.be'):
        return parsed_url.path[1:]
    if parsed_url.hostname in ('youtube.com', 'www.youtube.com'):
        if parsed_url.path == '/watch':
            qs = parse_qs(parsed_url.query)
            if 'v' in qs:
                return qs['v'][0]
        if parsed_url.path.startswith(('/embed/', '/v/', '/shorts/')):
            return parsed_url.path.split('/')[2]
    match = re.search(r'(?:v=|\/)([0-9A-Za-z_-]{11}).*', url)
    if match:
        return match.group(1)
    return None

def main():
    parser = argparse.ArgumentParser(description="Phase 1: Acquire DDD Audio")
    parser.add_argument('--batch', type=str, help='Path to batch URL file')
    parser.add_argument('--all', action='store_true', help='Process all URLs in config/playlist_urls.txt')
    args = parser.parse_args()

    if args.all:
        url_file = 'config/playlist_urls.txt'
    elif args.batch:
        url_file = args.batch
    else:
        print("Error: Must provide --batch <file> or --all")
        return

    urls = []
    if os.path.exists(url_file):
        with open(url_file, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    urls.append(line)
    else:
        print(f"Error: URL file not found: {url_file}")
        return

    total_urls = len(urls)
    success_count = 0
    skipped_count = 0
    failed_count = 0

    os.makedirs('data/audio', exist_ok=True)
    manifest_path = 'data/audio/manifest.csv'
    
    # Track existing entries in manifest to avoid duplicates if appending
    existing_videos = set()
    manifest_mode = 'a' if os.path.exists(manifest_path) else 'w'
    if os.path.exists(manifest_path):
        with open(manifest_path, 'r', newline='', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                existing_videos.add(row['video_id'])

    with open(manifest_path, manifest_mode, newline='', encoding='utf-8') as f:
        fieldnames = ['video_id', 'title', 'duration_seconds', 'youtube_url', 'download_status']
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        if manifest_mode == 'w':
            writer.writeheader()

        for idx, url in enumerate(urls, 1):
            video_id = extract_video_id(url)
            if not video_id:
                print(f"Skipping {idx}/{total_urls}: Could not extract video ID from {url}")
                failed_count += 1
                continue
            
            audio_path = f"data/audio/{video_id}.mp3"
            info_json_path = f"data/audio/{video_id}.info.json"
            
            if os.path.exists(audio_path):
                print(f"Downloading {idx}/{total_urls}: {video_id}... skipped (already exists)")
                skipped_count += 1
                if video_id not in existing_videos:
                    # Attempt to read title and duration if we have info.json
                    title, duration = "", ""
                    if os.path.exists(info_json_path):
                        try:
                            with open(info_json_path, 'r', encoding='utf-8') as info_f:
                                info = json.load(info_f)
                                title = info.get('title', '')
                                duration = info.get('duration', '')
                        except Exception:
                            pass
                    writer.writerow({
                        'video_id': video_id,
                        'title': title,
                        'duration_seconds': duration,
                        'youtube_url': url,
                        'download_status': 'skipped'
                    })
                    f.flush()
                continue

            print(f"Downloading {idx}/{total_urls}: {video_id}...", end=' ', flush=True)
            start_time = time.time()
            
            cmd = [
                "yt-dlp",
                "-x",
                "--audio-format", "mp3",
                "--audio-quality", "0",
                "--cookies-from-browser", "chrome",
                "--remote-components", "ejs:github",
                "--sleep-interval", "5",
                "--max-sleep-interval", "30",
                "--output", "data/audio/%(id)s.%(ext)s",
                "--write-info-json",
                "--no-overwrites",
                url
            ]
            
            try:
                result = subprocess.run(cmd, capture_output=True, text=True, check=False, timeout=600)
                elapsed = time.time() - start_time
                
                status = "failed"
                title = ""
                duration = ""
                
                if result.returncode == 0:
                    status = "success"
                    success_count += 1
                    
                    if os.path.exists(info_json_path):
                        with open(info_json_path, 'r', encoding='utf-8') as info_f:
                            try:
                                info = json.load(info_f)
                                title = info.get('title', '')
                                duration = info.get('duration', '')
                            except Exception:
                                pass
                    
                    print(f"done [{elapsed:.1f}s]")
                else:
                    failed_count += 1
                    err_out = result.stderr.lower()
                    if "unavailable" in err_out or "video is unavailable" in err_out or "private video" in err_out:
                        status = "unavailable"
                        print(f"unavailable [{elapsed:.1f}s]")
                    elif "geo-blocked" in err_out or "blocked in your country" in err_out:
                        status = "geo-blocked"
                        print(f"geo-blocked [{elapsed:.1f}s]")
                    else:
                        status = f"failed: {result.stderr.strip().split(chr(10))[-1][:50]}"
                        print(f"failed [{elapsed:.1f}s]")
                        print(f"  Error: {result.stderr.strip()}")

                writer.writerow({
                    'video_id': video_id,
                    'title': title,
                    'duration_seconds': duration,
                    'youtube_url': url,
                    'download_status': status
                })
                f.flush()

            except Exception as e:
                elapsed = time.time() - start_time
                failed_count += 1
                print(f"crash [{elapsed:.1f}s]")
                print(f"  Exception: {str(e)}")
                writer.writerow({
                    'video_id': video_id,
                    'title': "",
                    'duration_seconds': "",
                    'youtube_url': url,
                    'download_status': "failed: script crash"
                })
                f.flush()

    print("\n--- Download Summary ---")
    print(f"Total urls: {total_urls}")
    print(f"Success:    {success_count}")
    print(f"Skipped:    {skipped_count}")
    print(f"Failed:     {failed_count}")

if __name__ == '__main__':
    main()
