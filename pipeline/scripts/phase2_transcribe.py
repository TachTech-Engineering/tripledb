import argparse
import csv
import json
import os
import re
import time

# Preload Ollama's CUDA libraries to fix missing libcublas.so.12
cuda_path = '/usr/local/lib/ollama/cuda_v12'
if os.path.exists(cuda_path):
    os.environ['LD_LIBRARY_PATH'] = f"{cuda_path}:{os.environ.get('LD_LIBRARY_PATH', '')}"

from faster_whisper import WhisperModel

def extract_video_id(url):
    """Extracts YouTube video ID from URL or returns the ID if already in ID format."""
    # Check if it looks like a direct ID (11 chars, no slashes or dots)
    if len(url) == 11 and re.match(r'^[0-9A-Za-z_-]{11}$', url):
        return url
        
    match = re.search(r'(?:v=|\/)([0-9A-Za-z_-]{11}).*', url)
    if match:
        return match.group(1)
    return None

def main():
    parser = argparse.ArgumentParser(description="Phase 2: Transcribe DDD Audio")
    parser.add_argument('--batch', type=str, help='Path to batch URL file')
    parser.add_argument('--all', action='store_true', help='Process all successful downloads in data/audio/manifest.csv')
    args = parser.parse_args()

    video_ids = []
    
    if args.all:
        manifest_path = 'data/audio/manifest.csv'
        if not os.path.exists(manifest_path):
            print(f"Error: Manifest not found at {manifest_path}")
            return
        with open(manifest_path, 'r', newline='', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                if row.get('download_status') == 'success':
                    video_ids.append(row['video_id'])
    elif args.batch:
        if not os.path.exists(args.batch):
            print(f"Error: Batch file not found: {args.batch}")
            return
        with open(args.batch, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    vid = extract_video_id(line)
                    if vid:
                        video_ids.append(vid)
                    else:
                        print(f"Warning: Could not extract video ID from {line}")
    else:
        print("Error: Must provide --batch <file> or --all")
        return

    if not video_ids:
        print("No videos to process.")
        return

    os.makedirs('data/transcripts', exist_ok=True)
    os.makedirs('data/logs', exist_ok=True)
    error_log_path = 'data/logs/phase-2-errors.jsonl'

    total_videos = len(video_ids)
    processed_count = 0
    total_segments_all = 0
    total_low_confidence_all = 0
    error_count = 0

    print("Loading faster-whisper large-v3 model on CUDA...")
    try:
        model = WhisperModel("large-v3", device="cuda", compute_type="float16")
    except Exception as e:
        print(f"Failed to load model on CUDA. Is GPU available? Error: {e}")
        print("Trying CPU fallback...")
        try:
            model = WhisperModel("large-v3", device="cpu", compute_type="int8")
        except Exception as e2:
            print(f"Failed to load model on CPU. Error: {e2}")
            return

    for idx, video_id in enumerate(video_ids, 1):
        mp3_path = f"data/audio/{video_id}.mp3"
        json_path = f"data/transcripts/{video_id}.json"

        # Check for existing transcript
        if os.path.exists(json_path):
            try:
                with open(json_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    if "segments" in data:
                        print(f"Transcribing {video_id} ({idx}/{total_videos})... skipped (already exists)")
                        continue
            except Exception:
                pass # Invalid JSON, re-process

        if not os.path.exists(mp3_path):
            print(f"Warning: Missing audio for {video_id} ({idx}/{total_videos}), skipping.")
            continue

        print(f"Transcribing {video_id} ({idx}/{total_videos})...", end=' ', flush=True)
        start_time = time.time()

        try:
            segments_generator, info = model.transcribe(
                mp3_path,
                language="en",
                beam_size=5,
                vad_filter=True,
                vad_parameters=dict(
                    min_silence_duration_ms=500,
                    speech_pad_ms=400
                )
            )

            segments = []
            low_confidence_count = 0

            for seg in segments_generator:
                is_low_confidence = seg.avg_logprob < -0.35 # Rough equivalent to < 0.7 probability
                
                segment_dict = {
                    "start": seg.start,
                    "end": seg.end,
                    "text": seg.text.strip(),
                    "confidence": round(min(1.0, max(0.0, 1.0 + (seg.avg_logprob / 2))), 2) # convert logprob to 0-1 approximate
                }

                if segment_dict["confidence"] < 0.7:
                    segment_dict["low_confidence"] = True
                    low_confidence_count += 1

                segments.append(segment_dict)

            elapsed = time.time() - start_time
            num_segments = len(segments)

            output_data = {
                "video_id": video_id,
                "source_file": mp3_path,
                "model": "large-v3",
                "language": "en",
                "duration_seconds": info.duration,
                "segments": segments,
                "low_confidence_count": low_confidence_count,
                "total_segments": num_segments
            }

            with open(json_path, 'w', encoding='utf-8') as f:
                json.dump(output_data, f, indent=2, ensure_ascii=False)

            processed_count += 1
            total_segments_all += num_segments
            total_low_confidence_all += low_confidence_count

            print(f"done ({num_segments} segments, {low_confidence_count} low-confidence) [{elapsed:.1f}s]")

        except Exception as e:
            elapsed = time.time() - start_time
            error_count += 1
            print(f"failed [{elapsed:.1f}s]")
            print(f"  Error: {str(e)}")
            
            error_record = {
                "timestamp": time.time(),
                "video_id": video_id,
                "error": str(e)
            }
            with open(error_log_path, 'a', encoding='utf-8') as f:
                f.write(json.dumps(error_record) + "\n")

    print("\n--- Transcription Summary ---")
    print(f"Total processed: {processed_count}")
    print(f"Total segments:  {total_segments_all}")
    print(f"Low confidence:  {total_low_confidence_all}")
    print(f"Errors:          {error_count}")

if __name__ == '__main__':
    main()
