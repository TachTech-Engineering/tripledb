import requests
import json
with open("config/extraction_prompt.md") as f:
    sys_prompt = f.read()
with open("data/transcripts/BwfqvpCAdeQ.json") as f:
    transcript = json.load(f)

# Use just the first 10 segments so it's very short.
text = "Video ID: BwfqvpCAdeQ\nTranscript:\n" + "\n".join([f"[{seg['start']}] {seg['text']}" for seg in transcript["segments"]][:10])

resp = requests.post("http://localhost:11434/api/chat", json={
    "model": "qwen3.5:9b",
    "messages": [
        {"role": "system", "content": sys_prompt},
        {"role": "user", "content": text}
    ],
    "stream": True,
    "options": {
        "temperature": 0.1,
        "num_ctx": 4096
    }
}, stream=True)

import sys
for line in resp.iter_lines():
    if line:
        chunk = json.loads(line)
        sys.stdout.write(chunk["message"]["content"])
        sys.stdout.flush()
