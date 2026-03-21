import requests
import json
import sys
import time

with open("config/extraction_prompt.md") as f:
    sys_prompt = f.read()
with open("data/transcripts/BwfqvpCAdeQ.json") as f:
    transcript = json.load(f)

text = "Video ID: BwfqvpCAdeQ\nTranscript:\n" + "\n".join([f"[{seg['start']}] {seg['text']}" for seg in transcript["segments"]])

resp = requests.post("http://localhost:11434/api/chat", json={
    "model": "qwen3.5:9b",
    "messages": [
        {"role": "system", "content": sys_prompt},
        {"role": "user", "content": text}
    ],
    "stream": True,
    "options": {
        "temperature": 0.1,
        "num_ctx": 8192,
        "stop": ["<|endoftext|>", "<|im_end|>", "<|im_start|>"]
    }
}, stream=True, timeout=120)

with open("data/extracted/test_output.txt", "w") as f:
    start = time.time()
    for line in resp.iter_lines():
        if line:
            chunk = json.loads(line)
            content = chunk["message"]["content"]
            f.write(content)
            f.flush()
            sys.stdout.write(content)
            sys.stdout.flush()
        if time.time() - start > 60:
            print("\nStopping after 60 seconds")
            break
