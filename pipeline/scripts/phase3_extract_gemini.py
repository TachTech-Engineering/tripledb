#!/usr/bin/env python3
"""
phase3_extract_gemini.py — Extract restaurant data using Gemini Flash API.
No chunking needed — 1M token context handles any transcript in a single call.
"""
import os
import sys
import json
import time
import argparse
import re
import requests
from pathlib import Path

# ── Configuration ────────────────────────────────────────────────────
API_KEY = os.environ.get("GEMINI_API_KEY", "")
API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={API_KEY}"
RATE_LIMIT_DELAY = 4.5        # seconds between requests (stay under 15 RPM)
TIMEOUT = 120                 # 2 minutes per request (generous for cloud API)
MAX_RETRIES = 2

DATA_DIR = Path("data")
EXTRACTED_DIR = DATA_DIR / "extracted"
TRANSCRIPT_DIR = DATA_DIR / "transcripts"
AUDIO_DIR = DATA_DIR / "audio"
LOG_DIR = DATA_DIR / "logs"
PROMPT_PATH = Path("config/extraction_prompt.md")

# ── Helpers ──────────────────────────────────────────────────────────
def load_extraction_prompt():
    with open(PROMPT_PATH) as f:
        return f.read()

def get_video_title(video_id):
    info_path = AUDIO_DIR / f"{video_id}.info.json"
    if info_path.exists():
        try:
            with open(info_path) as f:
                info = json.load(f)
            return info.get("title", video_id)
        except (json.JSONDecodeError, KeyError):
            pass
    return video_id

def get_video_ids_from_batch(batch_file):
    ids = []
    with open(batch_file) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            match = re.search(r'[?&]v=([a-zA-Z0-9_-]{11})', line)
            if match:
                ids.append(match.group(1))
            else:
                clean = line.split('#')[0].strip()
                if len(clean) == 11:
                    ids.append(clean)
    return ids

def load_transcript(video_id):
    path = TRANSCRIPT_DIR / f"{video_id}.json"
    if not path.exists():
        return None, 0
    with open(path) as f:
        data = json.load(f)
    segments = data.get("segments", [])
    lines = []
    for seg in segments:
        start = seg.get("start", 0)
        text = seg.get("text", "").strip()
        if text:
            lines.append(f"[{start:.1f}s] {text}")
    return "\n".join(lines), data.get("duration_seconds", 0)

def call_gemini(system_prompt, user_content):
    """Call Gemini Flash API with JSON output mode."""
    payload = {
        "contents": [
            {
                "parts": [
                    {"text": f"{system_prompt}\n\n---\n\n{user_content}"}
                ]
            }
        ],
        "generationConfig": {
            "responseMimeType": "application/json",
            "temperature": 0.1
        }
    }

    resp = requests.post(API_URL, json=payload, timeout=TIMEOUT)

    if resp.status_code == 429:
        # Rate limited — wait and retry
        print(" RATE LIMITED — waiting 60s...", end="", flush=True)
        time.sleep(60)
        resp = requests.post(API_URL, json=payload, timeout=TIMEOUT)

    if resp.status_code != 200:
        raise Exception(f"API error {resp.status_code}: {resp.text[:300]}")

    data = resp.json()

    # Extract text from Gemini response
    try:
        text = data["candidates"][0]["content"]["parts"][0]["text"]
    except (KeyError, IndexError) as e:
        raise Exception(f"Unexpected response structure: {e}")

    return text

def parse_json_response(raw_text):
    # Direct parse
    try:
        return json.loads(raw_text)
    except json.JSONDecodeError:
        pass

    # Extract from markdown code blocks
    match = re.search(r'```(?:json)?\s*\n?(.*?)\n?```', raw_text, re.DOTALL)
    if match:
        try:
            return json.loads(match.group(1))
        except json.JSONDecodeError:
            pass

    # Find first { ... } block
    start = raw_text.find('{')
    end = raw_text.rfind('}')
    if start != -1 and end != -1 and end > start:
        try:
            return json.loads(raw_text[start:end+1])
        except json.JSONDecodeError:
            pass

    return None

def log_error(video_id, error_msg):
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    with open(LOG_DIR / "phase-3-errors.jsonl", "a") as f:
        f.write(json.dumps({"timestamp": time.time(), "video_id": video_id, "error": error_msg}) + "\n")
        f.flush()

def classify_video_type(duration):
    if duration < 900:
        return "clip"
    elif duration < 1500:
        return "full_episode"
    elif duration < 3600:
        return "compilation"
    else:
        return "marathon"

# ── Main extraction ──────────────────────────────────────────────────
def extract_video(video_id, system_prompt):
    output_path = EXTRACTED_DIR / f"{video_id}.json"

    # Resume: skip if valid output with restaurants exists
    if output_path.exists():
        try:
            with open(output_path) as f:
                existing = json.load(f)
            if existing.get("restaurants"):
                print(f"  Skipping — already extracted ({len(existing['restaurants'])} restaurants)")
                return existing, "skipped"
        except (json.JSONDecodeError, KeyError):
            pass

    full_text, duration = load_transcript(video_id)
    if full_text is None:
        log_error(video_id, "Transcript not found")
        return None, "no_transcript"

    title = get_video_title(video_id)
    vtype = classify_video_type(duration)

    print(f"  {title}")
    print(f"  Type: {vtype} | Duration: {duration:.0f}s | Transcript: {len(full_text)} chars")

    user_content = (
        f"Video ID: {video_id}\n"
        f"Video Title: {title}\n"
        f"Duration: {duration:.0f} seconds\n\n"
        f"Transcript:\n{full_text}"
    )

    for attempt in range(MAX_RETRIES + 1):
        try:
            print(f"  Calling Gemini Flash (attempt {attempt+1})...", end="", flush=True)
            start_time = time.time()
            raw = call_gemini(system_prompt, user_content)
            elapsed = time.time() - start_time
            print(f" done [{elapsed:.1f}s]")

            parsed = parse_json_response(raw)
            if parsed is None:
                # Save raw for debugging
                raw_path = EXTRACTED_DIR / f"{video_id}_raw.txt"
                with open(raw_path, "w") as f:
                    f.write(raw)
                log_error(video_id, f"JSON parse failed (attempt {attempt+1})")
                if attempt < MAX_RETRIES:
                    continue
                return None, "parse_error"

            # Ensure required fields
            if "restaurants" not in parsed:
                parsed["restaurants"] = []
            parsed["video_id"] = video_id
            parsed["video_title"] = title
            if not parsed.get("video_type"):
                parsed["video_type"] = vtype

            with open(output_path, "w") as f:
                json.dump(parsed, f, indent=2)

            r_count = len(parsed["restaurants"])
            d_count = sum(len(r.get("dishes", [])) for r in parsed["restaurants"])
            return parsed, "success" if r_count > 0 else "empty"

        except Exception as e:
            print(f" ERROR: {e}")
            log_error(video_id, f"Attempt {attempt+1}: {str(e)}")
            if attempt < MAX_RETRIES:
                time.sleep(5)
                continue
            return None, "failed"

    return None, "failed"

# ── Main ─────────────────────────────────────────────────────────────
def main():
    if not API_KEY:
        print("❌ GEMINI_API_KEY not set. Add it to your environment.")
        sys.exit(1)

    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--batch", help="File with video URLs")
    group.add_argument("--all", action="store_true", help="Process all transcripts")
    group.add_argument("--video", help="Single video ID")
    args = parser.parse_args()

    EXTRACTED_DIR.mkdir(parents=True, exist_ok=True)
    LOG_DIR.mkdir(parents=True, exist_ok=True)

    system_prompt = load_extraction_prompt()
    print(f"Extraction prompt: {len(system_prompt)} chars (~{len(system_prompt)//4} tokens)")

    if args.video:
        video_ids = [args.video]
    elif args.batch:
        video_ids = get_video_ids_from_batch(args.batch)
    else:
        video_ids = sorted([f.stem for f in TRANSCRIPT_DIR.glob("*.json")])

    print(f"Videos to process: {len(video_ids)}")
    print(f"Backend: Gemini 2.5 Flash API")
    print(f"Rate limit: 1 request per {RATE_LIMIT_DELAY}s")
    print()

    stats = {"total": len(video_ids), "success": 0, "empty": 0, "failed": 0,
             "skipped": 0, "no_transcript": 0, "parse_error": 0,
             "total_restaurants": 0, "total_dishes": 0}

    for i, vid in enumerate(video_ids):
        print(f"[{i+1}/{len(video_ids)}] {vid}")
        result, status = extract_video(vid, system_prompt)
        stats[status] = stats.get(status, 0) + 1

        if result and result.get("restaurants"):
            r_count = len(result["restaurants"])
            d_count = sum(len(r.get("dishes", [])) for r in result["restaurants"])
            stats["total_restaurants"] += r_count
            stats["total_dishes"] += d_count
            print(f"  ✅ {r_count} restaurants, {d_count} dishes")
        elif status == "skipped":
            pass
        else:
            print(f"  ⚠️ {status}")

        # Rate limit (skip delay for skipped videos)
        if status != "skipped" and i < len(video_ids) - 1:
            time.sleep(RATE_LIMIT_DELAY)

        print()

    print("=" * 60)
    print("EXTRACTION SUMMARY")
    print("=" * 60)
    print(f"  Total videos:      {stats['total']}")
    print(f"  Successful:        {stats['success']}")
    print(f"  Empty (no data):   {stats['empty']}")
    print(f"  Failed:            {stats['failed']}")
    print(f"  Parse errors:      {stats['parse_error']}")
    print(f"  Skipped (resume):  {stats['skipped']}")
    print(f"  No transcript:     {stats['no_transcript']}")
    print(f"  Total restaurants: {stats['total_restaurants']}")
    print(f"  Total dishes:      {stats['total_dishes']}")
    print(f"  Avg dishes/rest:   {stats['total_dishes']/max(stats['total_restaurants'],1):.1f}")
    print("=" * 60)

if __name__ == "__main__":
    main()
