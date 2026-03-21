#!/usr/bin/env python3
"""
phase3_extract.py — Extract restaurant data from DDD transcripts.
Uses qwen3.5:9b via Ollama with streaming, chunking, and hard timeouts.
"""
import os
import sys
import json
import time
import signal
import argparse
import re
import requests
from pathlib import Path

# ── Configuration ────────────────────────────────────────────────────
MODEL = "qwen3.5:9b"
OLLAMA_URL = "http://localhost:11434/api/chat"
NUM_CTX = 4096
TEMPERATURE = 0.1
MAX_CHUNK_CHARS = 10000       # ~2500 tokens, leaves room for prompt + response
TIMEOUT_PER_CHUNK = 600       # 10 minutes per chunk — kill if exceeded
MAX_RETRIES = 2               # retry each chunk up to 2 times
DATA_DIR = Path("data")
EXTRACTED_DIR = DATA_DIR / "extracted"
TRANSCRIPT_DIR = DATA_DIR / "transcripts"
AUDIO_DIR = DATA_DIR / "audio"
LOG_DIR = DATA_DIR / "logs"
PROMPT_PATH = Path("config/extraction_prompt.md")

# ── Timeout handler ──────────────────────────────────────────────────
class TimeoutError(Exception):
    pass

def timeout_handler(signum, frame):
    raise TimeoutError("Ollama request timed out")

# ── Helpers ──────────────────────────────────────────────────────────
def load_extraction_prompt():
    with open(PROMPT_PATH) as f:
        return f.read()

def get_video_title(video_id):
    """Try to get title from yt-dlp info.json, fall back to video_id."""
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
    """Extract video IDs from a batch file of URLs."""
    ids = []
    with open(batch_file) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            # Extract video ID from URL
            match = re.search(r'[?&]v=([a-zA-Z0-9_-]{11})', line)
            if match:
                ids.append(match.group(1))
            else:
                # Maybe it's just a video ID
                clean = line.split('#')[0].strip()
                if len(clean) == 11:
                    ids.append(clean)
    return ids

def load_transcript(video_id):
    """Load transcript and return full text with timestamps."""
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
    full_text = "\n".join(lines)
    return full_text, data.get("duration_seconds", 0)

def chunk_transcript(full_text, max_chars=MAX_CHUNK_CHARS):
    """Split transcript into chunks at natural pause boundaries."""
    if len(full_text) <= max_chars:
        return [full_text]

    chunks = []
    lines = full_text.split("\n")
    current_chunk = []
    current_size = 0

    for line in lines:
        line_len = len(line) + 1  # +1 for newline
        if current_size + line_len > max_chars and current_chunk:
            chunks.append("\n".join(current_chunk))
            current_chunk = []
            current_size = 0
        current_chunk.append(line)
        current_size += line_len

    if current_chunk:
        chunks.append("\n".join(current_chunk))

    return chunks

def call_ollama_streaming(system_prompt, user_content):
    """Call Ollama with streaming, hard timeout, and JSON extraction."""
    signal.signal(signal.SIGALRM, timeout_handler)
    signal.alarm(TIMEOUT_PER_CHUNK)

    try:
        resp = requests.post(OLLAMA_URL, json={
            "model": MODEL,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_content}
            ],
            "stream": True,
            "options": {
                "temperature": TEMPERATURE,
                "num_ctx": NUM_CTX,
                "stop": ["<|endoftext|>", "<|im_end|>", "<|im_start|>"]
            }
        }, stream=True, timeout=TIMEOUT_PER_CHUNK)

        full_response = ""
        token_count = 0
        for line in resp.iter_lines():
            if line:
                try:
                    chunk = json.loads(line)
                    content = chunk.get("message", {}).get("content", "")
                    full_response += content
                    token_count += 1
                    # Print a dot every 50 tokens to show progress
                    if token_count % 50 == 0:
                        print(".", end="", flush=True)
                except json.JSONDecodeError:
                    continue

        signal.alarm(0)  # Cancel alarm
        return full_response

    except TimeoutError:
        signal.alarm(0)
        raise
    except requests.exceptions.Timeout:
        signal.alarm(0)
        raise TimeoutError("Request timed out")
    except Exception as e:
        signal.alarm(0)
        raise

def parse_json_response(raw_text):
    """Try to parse JSON from response, handle common issues."""
    # Direct parse
    try:
        return json.loads(raw_text)
    except json.JSONDecodeError:
        pass

    # Try to extract JSON from markdown code blocks
    match = re.search(r'```(?:json)?\s*\n?(.*?)\n?```', raw_text, re.DOTALL)
    if match:
        try:
            return json.loads(match.group(1))
        except json.JSONDecodeError:
            pass

    # Try to find the first { ... } block
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
    log_path = LOG_DIR / "phase-3-errors.jsonl"
    with open(log_path, "a") as f:
        entry = {"timestamp": time.time(), "video_id": video_id, "error": error_msg}
        f.write(json.dumps(entry) + "\n")
        f.flush()

def save_raw(video_id, raw_text):
    path = EXTRACTED_DIR / f"{video_id}_raw.txt"
    with open(path, "w") as f:
        f.write(raw_text)

# ── Main extraction logic ────────────────────────────────────────────
def extract_video(video_id, system_prompt):
    """Extract restaurants from a single video transcript."""
    output_path = EXTRACTED_DIR / f"{video_id}.json"

    # Resume: skip if valid output exists
    if output_path.exists():
        try:
            with open(output_path) as f:
                existing = json.load(f)
            if existing.get("restaurants"):
                print(f"  Skipping {video_id} — already extracted")
                return existing, "skipped"
        except (json.JSONDecodeError, KeyError):
            pass  # Re-process corrupt files

    # Load transcript
    full_text, duration = load_transcript(video_id)
    if full_text is None:
        log_error(video_id, "Transcript file not found")
        return None, "no_transcript"

    title = get_video_title(video_id)
    chunks = chunk_transcript(full_text)

    print(f"  Transcript: {len(full_text)} chars, {len(chunks)} chunk(s), {duration:.0f}s duration")

    all_restaurants = []

    for i, chunk in enumerate(chunks):
        chunk_label = f"chunk {i+1}/{len(chunks)}"

        user_content = (
            f"Video ID: {video_id}\n"
            f"Video Title: {title}\n"
            f"Chunk: {i+1} of {len(chunks)}\n\n"
            f"Transcript:\n{chunk}"
        )

        for attempt in range(MAX_RETRIES + 1):
            try:
                print(f"  [{chunk_label}] Sending to {MODEL} (attempt {attempt+1})", end="", flush=True)
                start_time = time.time()
                raw = call_ollama_streaming(system_prompt, user_content)
                elapsed = time.time() - start_time
                print(f" [{elapsed:.1f}s]")

                parsed = parse_json_response(raw)
                if parsed is None:
                    save_raw(video_id, raw)
                    log_error(video_id, f"JSON parse failed on {chunk_label}. Raw saved.")
                    print(f"  [{chunk_label}] JSON parse failed — raw saved")
                    if attempt < MAX_RETRIES:
                        print(f"  [{chunk_label}] Retrying...")
                        continue
                    break

                restaurants = parsed.get("restaurants", [])
                print(f"  [{chunk_label}] Extracted {len(restaurants)} restaurant(s)")
                all_restaurants.extend(restaurants)
                break  # Success — move to next chunk

            except TimeoutError:
                elapsed = time.time() - start_time
                print(f" TIMEOUT [{elapsed:.1f}s]")
                log_error(video_id, f"Timeout on {chunk_label} (attempt {attempt+1})")
                if attempt < MAX_RETRIES:
                    print(f"  [{chunk_label}] Retrying after timeout...")
                    continue
                print(f"  [{chunk_label}] Max retries — skipping chunk")
                break

            except Exception as e:
                print(f" ERROR: {e}")
                log_error(video_id, f"Error on {chunk_label}: {str(e)}")
                if attempt < MAX_RETRIES:
                    continue
                break

    # Build final output
    result = {
        "video_id": video_id,
        "video_title": title,
        "video_type": classify_video_type(duration, len(all_restaurants)),
        "restaurants": all_restaurants
    }

    # Save regardless of restaurant count (empty = valid, means no restaurants found)
    with open(output_path, "w") as f:
        json.dump(result, f, indent=2)

    status = "success" if all_restaurants else "empty"
    return result, status

def classify_video_type(duration, restaurant_count):
    if duration < 900:       # < 15 min
        return "clip"
    elif duration < 1500:    # < 25 min
        return "full_episode"
    elif duration < 3600:    # < 60 min
        return "compilation"
    else:
        return "marathon"

# ── Main ─────────────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--batch", help="File with video URLs/IDs")
    group.add_argument("--all", action="store_true", help="Process all transcripts")
    group.add_argument("--video", help="Single video ID")
    args = parser.parse_args()

    EXTRACTED_DIR.mkdir(parents=True, exist_ok=True)
    LOG_DIR.mkdir(parents=True, exist_ok=True)

    system_prompt = load_extraction_prompt()
    print(f"Extraction prompt: {len(system_prompt)} chars")

    # Get video IDs
    if args.video:
        video_ids = [args.video]
    elif args.batch:
        video_ids = get_video_ids_from_batch(args.batch)
    else:
        video_ids = [f.stem for f in TRANSCRIPT_DIR.glob("*.json")]

    print(f"Videos to process: {len(video_ids)}")
    print(f"Model: {MODEL} | Context: {NUM_CTX} | Timeout: {TIMEOUT_PER_CHUNK}s")
    print()

    stats = {"total": len(video_ids), "success": 0, "empty": 0, "failed": 0,
             "skipped": 0, "total_restaurants": 0, "total_dishes": 0}

    for i, vid in enumerate(video_ids):
        print(f"[{i+1}/{len(video_ids)}] Extracting {vid}...")
        try:
            result, status = extract_video(vid, system_prompt)
            stats[status] = stats.get(status, 0) + 1
            if result and result.get("restaurants"):
                r_count = len(result["restaurants"])
                d_count = sum(len(r.get("dishes", [])) for r in result["restaurants"])
                stats["total_restaurants"] += r_count
                stats["total_dishes"] += d_count
                print(f"  ✅ {r_count} restaurants, {d_count} dishes\n")
            elif status == "skipped":
                print()
            else:
                print(f"  ⚠️ {status}\n")
        except Exception as e:
            print(f"  ❌ Unexpected error: {e}\n")
            log_error(vid, f"Unexpected: {str(e)}")
            stats["failed"] += 1

    print("=" * 60)
    print("EXTRACTION SUMMARY")
    print("=" * 60)
    print(f"  Total videos:      {stats['total']}")
    print(f"  Successful:        {stats['success']}")
    print(f"  Empty (no data):   {stats['empty']}")
    print(f"  Failed:            {stats['failed']}")
    print(f"  Skipped (resume):  {stats['skipped']}")
    print(f"  Total restaurants: {stats['total_restaurants']}")
    print(f"  Total dishes:      {stats['total_dishes']}")
    print("=" * 60)

if __name__ == "__main__":
    main()