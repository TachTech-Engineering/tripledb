import argparse
import json
import os
import re
import requests
import time
from urllib.parse import urlparse, parse_qs

def extract_video_id(url):
    """Extracts YouTube video ID from URL or returns the ID if already in ID format."""
    if len(url) == 11 and re.match(r'^[0-9A-Za-z_-]{11}$', url):
        return url
    match = re.search(r'(?:v=|\/)([0-9A-Za-z_-]{11}).*', url)
    if match:
        return match.group(1)
    return None

def extract_json_from_text(text):
    """Attempts to extract JSON from markdown code blocks or raw text."""
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass

    # Try markdown code block
    match = re.search(r'```(?:json)?\s*(\{.*?\})\s*```', text, re.DOTALL)
    if match:
        try:
            return json.loads(match.group(1))
        except json.JSONDecodeError:
            pass
            
    # Try finding anything that looks like a JSON object
    match = re.search(r'(\{.*\})', text, re.DOTALL)
    if match:
        try:
            return json.loads(match.group(1))
        except json.JSONDecodeError:
            pass
            
    return None

def validate_extraction(data):
    """Validates the structure of the extracted JSON."""
    if not isinstance(data, dict):
        return False, "Root is not an object"
    
    if "restaurants" not in data:
        return False, "Missing 'restaurants' array"
        
    restaurants = data.get("restaurants")
    if not isinstance(restaurants, list):
        return False, "'restaurants' is not a list"
        
    for r in restaurants:
        if not r.get("name"): return False, "Restaurant missing name"
        if not r.get("city"): return False, "Restaurant missing city"
        if not r.get("state"): return False, "Restaurant missing state"
        
        dishes = r.get("dishes", [])
        if not isinstance(dishes, list) or len(dishes) == 0:
            return False, f"Restaurant '{r.get('name')}' missing dishes"
            
    return True, "Valid"

def get_chunks(segments, max_chars=12000):
    chunks = []
    current_chunk = []
    current_len = 0
    last_end = 0
    
    for seg in segments:
        text = f"[{seg['start']:.1f}s] {seg['text']}"
        line_len = len(text) + 1
        
        gap = seg['start'] - last_end
        if current_len >= max_chars and gap > 5.0 and current_chunk:
            chunks.append(current_chunk)
            current_chunk = []
            current_len = 0
            
        current_chunk.append(seg)
        current_len += line_len
        last_end = seg['end']
        
    if current_chunk:
        chunks.append(current_chunk)
        
    return chunks

def main():
    parser = argparse.ArgumentParser(description="Phase 3: Extract DDD Data")
    parser.add_argument('--batch', type=str, help='Path to batch URL file')
    parser.add_argument('--all', action='store_true', help='Process all transcripts in data/transcripts/')
    args = parser.parse_args()

    video_ids = []
    
    if args.all:
        transcript_dir = 'data/transcripts'
        if not os.path.exists(transcript_dir):
            print(f"Error: Directory not found: {transcript_dir}")
            return
        for f in os.listdir(transcript_dir):
            if f.endswith('.json'):
                video_ids.append(f.replace('.json', ''))
    elif args.batch:
        # Check if the batch argument is a file path or a string literal starting with /dev/fd
        if os.path.exists(args.batch):
            with open(args.batch, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#'):
                        vid = extract_video_id(line)
                        if vid:
                            video_ids.append(vid)
        else:
             print(f"Error: Batch file not found: {args.batch}")
             return
    else:
        print("Error: Must provide --batch <file> or --all")
        return

    if not video_ids:
        print("No videos to process.")
        return

    os.makedirs('data/extracted', exist_ok=True)
    os.makedirs('data/logs', exist_ok=True)
    
    error_log_path = 'data/logs/phase-3-errors.jsonl'
    
    prompt_path = 'config/extraction_prompt.md'
    if not os.path.exists(prompt_path):
        print(f"Error: Extraction prompt not found at {prompt_path}")
        return
        
    with open(prompt_path, 'r', encoding='utf-8') as f:
        system_prompt = f.read()

    # Check if Ollama is running
    try:
        resp = requests.get("http://localhost:11434/api/version", timeout=5)
        resp.raise_for_status()
    except Exception:
        print("Error: Could not connect to Ollama. Is it running?")
        print("Try: systemctl --user start ollama")
        return

    total_videos = len(video_ids)
    processed_count = 0
    total_restaurants = 0
    total_dishes = 0
    validation_failures = 0

    for idx, video_id in enumerate(video_ids, 1):
        transcript_path = f"data/transcripts/{video_id}.json"
        extracted_path = f"data/extracted/{video_id}.json"
        
        # Check for existing valid output
        if os.path.exists(extracted_path):
            try:
                with open(extracted_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    if "restaurants" in data:
                        print(f"Extracting {video_id} ({idx}/{total_videos})... skipped (already exists)")
                        continue
            except Exception:
                pass # Invalid JSON, re-process
                
        if not os.path.exists(transcript_path):
            print(f"Warning: Missing transcript for {video_id} ({idx}/{total_videos}), skipping.")
            continue

        print(f"Extracting {video_id} ({idx}/{total_videos})...", end=' ', flush=True)
        start_time = time.time()
        
        try:
            with open(transcript_path, 'r', encoding='utf-8') as f:
                transcript_data = json.load(f)
                
            segments = transcript_data.get("segments", [])
            duration = transcript_data.get("duration_seconds", 0)
            
            # Fetch title from info JSON if available
            info_json_path = f"data/audio/{video_id}.info.json"
            title = ""
            video_type = "clip" # default
            if os.path.exists(info_json_path):
                with open(info_json_path, 'r', encoding='utf-8') as f:
                    try:
                        info_data = json.load(f)
                        title = info_data.get('title', '')
                    except Exception:
                        pass
            
            full_text = "\n".join(
                f"[{seg['start']:.1f}s] {seg['text']}"
                for seg in segments
            )
            
            if len(full_text) <= 12000:
                chunks = [segments]
            else:
                chunks = get_chunks(segments, 12000)
                
            all_restaurants = []
            
            for chunk_idx, chunk in enumerate(chunks):
                chunk_text = "\n".join(f"[{seg['start']:.1f}s] {seg['text']}" for seg in chunk)
                user_content = f"Video ID: {video_id}\nVideo Title: {title}\n\nTranscript (Part {chunk_idx+1}/{len(chunks)}):\n{chunk_text}"
                
                payload = {
                    "model": "qwen3.5:9b",
                    "messages": [
                        {"role": "system", "content": system_prompt + "\n\nIMPORTANT: Return ONLY the JSON object. Do not include any thinking process, preamble, or markdown formatting. Disable thinking mode."},
                        {"role": "user", "content": user_content}
                    ],
                    "stream": False,
                    "format": "json",
                    "options": {
                        "temperature": 0.1,
                        "num_ctx": 16384
                    }
                }
                
                # Try up to 2 times
                response = None
                for attempt in range(2):
                    try:
                        response = requests.post("http://localhost:11434/api/chat", json=payload, timeout=600)
                        response.raise_for_status()
                        break
                    except requests.exceptions.Timeout:
                        if attempt == 0:
                            print(f"timeout on chunk {chunk_idx+1}... retrying...", end=' ', flush=True)
                        else:
                            raise Exception("Ollama timed out twice")
                            
                if not response:
                    raise Exception("Failed to get response from Ollama")
                    
                response_json = response.json()
                raw_content = response_json["message"]["content"]
                
                extracted_json = extract_json_from_text(raw_content)
                
                if not extracted_json:
                    raw_path = f"data/extracted/{video_id}_raw_{chunk_idx}.txt"
                    with open(raw_path, 'w', encoding='utf-8') as f:
                        f.write(raw_content)
                    raise Exception(f"Failed to parse JSON from response on chunk {chunk_idx+1}. Raw saved to {raw_path}")
                
                extracted_rests = extracted_json.get("restaurants", [])
                if "video_type" in extracted_json and extracted_json["video_type"]:
                    video_type = extracted_json["video_type"]
                all_restaurants.extend(extracted_rests)
            
            final_json = {
                "video_id": video_id,
                "video_title": title,
                "video_type": video_type,
                "restaurants": all_restaurants
            }
            
            is_valid, val_msg = validate_extraction(final_json)
            
            elapsed = time.time() - start_time
            
            if is_valid:
                with open(extracted_path, 'w', encoding='utf-8') as f:
                    json.dump(final_json, f, indent=2, ensure_ascii=False)
                
                rest_count = len(all_restaurants)
                dish_count = sum(len(r.get("dishes", [])) for r in all_restaurants)
                
                processed_count += 1
                total_restaurants += rest_count
                total_dishes += dish_count
                
                print(f"done ({rest_count} restaurants, {dish_count} dishes) [{elapsed:.1f}s]")
            else:
                invalid_path = f"data/extracted/{video_id}_invalid.json"
                with open(invalid_path, 'w', encoding='utf-8') as f:
                    json.dump(final_json, f, indent=2, ensure_ascii=False)
                validation_failures += 1
                raise Exception(f"Validation failed: {val_msg}. Saved to {invalid_path}")
                
        except Exception as e:
            elapsed = time.time() - start_time
            print(f"failed [{elapsed:.1f}s]")
            print(f"  Error: {str(e)}")
            
            error_record = {
                "timestamp": time.time(),
                "video_id": video_id,
                "error": str(e)
            }
            with open(error_log_path, 'a', encoding='utf-8') as f:
                f.write(json.dumps(error_record) + "\n")

    print("\n--- Extraction Summary ---")
    print(f"Total processed:      {processed_count}")
    print(f"Total restaurants:    {total_restaurants}")
    print(f"Total dishes:         {total_dishes}")
    print(f"Validation failures:  {validation_failures}")

if __name__ == '__main__':
    main()
