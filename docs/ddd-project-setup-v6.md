# TripleDB — Project Setup Guide v6

**Project:** TripleDB — Agentic Data Extraction for Diners, Drive-Ins and Dives
**Author:** Kyle Thompson, Solutions Architect @ TachTech Engineering
**Date:** March 2026
**Domain:** tripleDB.com
**Repository:** github.com/TachTech-Engineering/tripledb
**Firebase Project:** tripledb-e0f77

This document takes you from a blank CachyOS machine to a fully configured development environment ready to run the TripleDB pipeline. Follow every step in order. At the end, you will have every tool installed, the monorepo scaffolded, and the project pushed to GitHub.

---

## What TripleDB Does

TripleDB processes 804 YouTube videos from "Diners, Drive-Ins and Dives" into a structured Firestore database of restaurants, dishes, and the iconic Guy Fieri moments that make each visit memorable. The input is a single YouTube playlist containing episodes, compilations, clips, and multi-hour marathons. The output is a searchable restaurant database powering a Flutter Web app at tripleDB.com.

The pipeline runs in two groups:

**Group A — Iterative Refinement (4 batches of ~30 videos each)**

| Phase | Name          | Goal                                                           |
|------:|---------------|----------------------------------------------------------------|
|     0 | Setup         | Machine config, repo scaffold, playlist dump (THIS DOCUMENT)   |
|     1 | Discovery     | "Does the pipeline work at all?" — first 30 videos             |
|     2 | Calibration   | "Is extraction accurate?" — tune prompts on next 30            |
|     3 | Stress Test   | "Does it handle marathons, compilations, edge cases?" — next 30|
|     4 | Validation    | "Is end-to-end clean?" — lock prompts, dry run enrichment      |

**Group B — Production Run (~684 remaining videos, unattended)**

| Phase | Name          | Goal                                                           |
|------:|---------------|----------------------------------------------------------------|
|   5-7 | Production    | Process remainder with locked prompts, checkpoint reports every 50 videos, automated hang detection. Enrichment + Firestore load + Flutter app after extraction completes. |

Group A prompts are written iteratively — each phase's prompts are born from reviewing the previous phase's output. This document covers Phase 0 only. Phase 1-4 prompt artifacts will be created as separate versioned markdown files during execution.

---

## Part 1: Machine Setup (Run Once)

**Hardware:** Desktop (NZXT MS-7E06), MSI PRO Z790-P WIFI DDR4, 13th Gen Intel Core i9-13900K (24-core, 5.8 GHz boost), 64GB DDR4, NVIDIA GeForce RTX 2080 SUPER (8GB VRAM), CachyOS x86_64.

### 1.1 SSH Keys and GitHub Authentication

You need SSH keys to push code to GitHub without entering your password every time.

**Option A: Import Existing Keys from Bitwarden**

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

Copy your private key to `~/.ssh/id_ed25519` and public key to `~/.ssh/id_ed25519.pub` from your password manager.

**Option B: Generate New SSH Keys**

```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
```

**Both Options — Lock Down Permissions**

SSH silently refuses keys with loose permissions. This is the #1 first-time setup mistake:

```bash
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

If you skip this, you'll see:
```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
```

Create or update `~/.ssh/config`:

```
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes
```

```bash
chmod 600 ~/.ssh/config
```

Add your public key to GitHub:

```bash
cat ~/.ssh/id_ed25519.pub
# Copy the output → GitHub.com → Settings → SSH and GPG keys → New SSH key
```

Verify:

```bash
ssh -T git@github.com
# Expected: "Hi username! You've successfully authenticated..."
# If "Permission denied (publickey)": check key permissions and that the public key is added to GitHub.
```

### 1.2 Git Global Identity

```bash
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"
```

Without this, `git commit` fails with `Author identity unknown`.

### 1.3 Core Toolchain

```bash
yay -S git google-chrome nodejs npm python python-pip ffmpeg
```

| Package         | Why It's Needed                                                                    |
|-----------------|------------------------------------------------------------------------------------|
| `git`           | Version control. Multi-branch workflow for autonomous overnight execution.          |
| `google-chrome` | Required by Playwright MCP for web scraping in enrichment.                         |
| `nodejs` + `npm`| Runtime for Gemini CLI and MCP servers.                                            |
| `python`        | All pipeline scripts are Python.                                                   |
| `python-pip`    | Installs faster-whisper, yt-dlp, firebase-admin, requests.                         |
| `ffmpeg`        | Audio codec library required by faster-whisper.                                    |

Verify:

```bash
git --version && node --version && npm --version && python3 --version && pip --version && ffmpeg -version | head -1
```

### 1.4 Fish Shell Environment

Edit `~/.config/fish/config.fish`:

```fish
# ── TripleDB Environment ──────────────────────────────────────────

# Chrome path for Playwright MCP
set -x CHROME_EXECUTABLE /usr/bin/google-chrome-stable

# Gemini API key (get from https://aistudio.google.com/apikey)
set -x GEMINI_API_KEY "your-gemini-api-key-here"

# Firebase / GCP project
set -x GOOGLE_CLOUD_PROJECT "tripledb-e0f77"

# Firebase service account credentials
set -x GOOGLE_APPLICATION_CREDENTIALS "$HOME/.config/gcloud/tripledb-sa.json"

# Ollama — local inference server
set -x OLLAMA_HOST "http://localhost:11434"

# PATH
fish_add_path $HOME/.local/bin

# ── Corporate Proxy (uncomment if needed) ────────────────────────
# set -x NODE_EXTRA_CA_CERTS "/path/to/your/ca-bundle.crt"
```

```bash
source ~/.config/fish/config.fish
```

### 1.5 Ollama Installation and Model Setup

Ollama serves local LLMs. Two models: Nemotron 3 Super for extraction, Qwen 3.5-9B for normalization. All inference is local — zero API costs.

```bash
curl -fsSL https://ollama.com/install.sh | sh
systemctl --user enable --now ollama
```

Pull models:

```bash
# Nemotron 3 Super — NVIDIA 120B MoE, 12B active params, 1M context window.
# Used in Phase 3 to extract structured restaurant data from transcripts.
ollama pull nemotron-super

# Qwen 3.5-9B — Alibaba's efficient 9B model.
# Used in Phase 4 to deduplicate and schema-validate extracted data.
ollama pull qwen3.5:9b
```

Verify:

```bash
ollama list
# Expected: both models listed
```

**VRAM/RAM on this machine:**

| Model             | VRAM (Q4 quant)          | RAM Fallback | Notes                                          |
|-------------------|--------------------------|--------------|-------------------------------------------------|
| Nemotron 3 Super  | ~8 GB (fits 2080 SUPER)  | ~12 GB       | MoE — 12B active params. Fits with Q4_K_M      |
| Qwen 3.5-9B      | ~6 GB                    | ~8 GB        | Fits easily in VRAM                             |
| **Sequential use**| One at a time on GPU     | ~20 GB       | 64GB RAM = no pressure                          |

The RTX 2080 SUPER has 8 GB VRAM — enough for Q4-quantized inference. Ollama uses CUDA automatically. Verify with `nvidia-smi` while a model is running.

### 1.6 faster-whisper Installation

faster-whisper is a CTranslate2-optimized Whisper implementation. 4x faster than vanilla Whisper. The large-v3 model handles noisy restaurant audio (sizzling pans, background music, crowd noise).

```bash
pip install faster-whisper --break-system-packages
```

Test (first run downloads the ~3 GB model):

```python
# Save as test_whisper.py and run: python3 test_whisper.py
from faster_whisper import WhisperModel

model = WhisperModel("large-v3", device="cuda", compute_type="float16")
print("faster-whisper loaded successfully — model: large-v3, device: cuda")
```

With the RTX 2080 SUPER, CUDA transcription is ~4x faster than CPU. A full 804-video run takes ~35-45 hours on CUDA vs. ~150+ hours on CPU.

If you see `CUDA out of memory`: the GPU is occupied by an Ollama model. Stop Ollama before running Whisper (`systemctl --user stop ollama`), or fall back to `device="cpu"` with `compute_type="int8"`. The pipeline phases are sequential — Whisper (Phase 2) finishes before Ollama (Phase 3) starts, so GPU contention only happens during testing.

### 1.7 yt-dlp Installation

```bash
pip install yt-dlp --break-system-packages
```

Verify:

```bash
yt-dlp --version
# Expected: a date-based version like 2026.03.10
# If "command not found": ensure ~/.local/bin is in PATH
```

**YouTube Premium Cookies (recommended):**

Premium avoids ad interruptions in downloaded audio, producing cleaner transcripts:

```bash
# Extract cookies from Chrome (easiest)
yt-dlp --cookies-from-browser chrome "https://www.youtube.com/watch?v=dQw4w9WgXcQ" --simulate

# Or export cookies.txt for headless/overnight use
yt-dlp --cookies cookies.txt "https://www.youtube.com/watch?v=dQw4w9WgXcQ" --simulate
```

### 1.8 Gemini CLI and GSD Installation

Gemini CLI is the orchestrator for interactive pipeline development (Group A phases). GSD provides structured phase execution.

```bash
sudo npm install -g @google/gemini-cli
sudo npx get-shit-done-cc --gemini --global
```

**Gemini API Key:** [Google AI Studio](https://aistudio.google.com/apikey) → Create API Key → add to fish config as `GEMINI_API_KEY`.

**First Launch:**

```bash
gemini
# Accept trust dialog → /mcp (verify servers) → /quit
```

**GSD Skills Validation Workaround:**

```bash
for f in ~/.gemini/agents/gsd-*.md; sed -i '/^skills:$/,/^[^ ]/{ /^skills:$/d; /^  - /d; }' $f; end
```

GSD agent files include a `skills:` YAML key that Gemini CLI doesn't support. This `sed` strips it. Re-run after GSD updates.

### 1.9 Agency Agents Installation

Specialized agent personas as markdown system prompts. Each pipeline phase gets a dedicated persona.

```bash
git clone https://github.com/msitarzewski/agency-agents.git ~/.agency-agents
cd ~/.agency-agents
./scripts/convert.sh --tool gemini
./scripts/install.sh --tool gemini
```

Verify:

```bash
ls ~/.gemini/agents/
# Expected: list of .md agent persona files
```

The DDD-specific personas (ddd-transcriber, ddd-extractor, etc.) are defined in `docs/ddd-design-architecture-v6.md` and live in `pipeline/agents/`.

### 1.10 MCP Server Configuration

Create or update `~/.gemini/settings.json`:

```json
{
  "security": {
    "auth": {
      "selectedType": "gemini-api-key"
    }
  },
  "mcpServers": {
    "firecrawl": {
      "command": "npx",
      "args": ["-y", "firecrawl-mcp"],
      "env": {
        "FIRECRAWL_API_KEY": "your-firecrawl-api-key"
      }
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"],
      "env": {
        "CHROME_PATH": "/usr/bin/google-chrome-stable"
      }
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@context7/mcp-server"]
    }
  }
}
```

The `security.auth` block is required — it tells Gemini CLI to use your `GEMINI_API_KEY`.

Verify:

```bash
gemini
# Inside: /mcp → all 3 servers green → /quit
```

### 1.11 Firebase / Firestore Setup

The Firebase project is already provisioned:

| Field          | Value                |
|----------------|----------------------|
| Project name   | tripledb             |
| Project ID     | tripledb-e0f77       |
| Project number | 288006285184         |
| Parent org     | tachtech             |

**Install Firebase Admin SDK:**

```bash
pip install firebase-admin --break-system-packages
```

**Download the service account key:**

1. [Firebase Console](https://console.firebase.google.com/) → tripledb project
2. Project Settings → Service accounts
3. Generate new private key → Download JSON

```bash
mkdir -p ~/.config/gcloud
mv ~/Downloads/tripledb-*.json ~/.config/gcloud/tripledb-sa.json
chmod 600 ~/.config/gcloud/tripledb-sa.json
```

**Enable Cloud Firestore:**

1. Firebase Console → Build → Firestore Database
2. Create database → Production mode
3. Region: us-west1 (nearest to Southern California)

Firebase Spark (free) plan: 1 GiB storage, 50K reads/day. TripleDB is ~10 MB with ~5,000 documents. You'll never hit these limits.

### 1.12 Python Utility Libraries

```bash
pip install requests --break-system-packages
```

### 1.13 Verify Everything

```bash
git --version
node --version && npm --version
python3 --version && pip --version
ffmpeg -version | head -1
ollama list                    # nemotron-super and qwen3.5:9b listed
yt-dlp --version
python3 -c "from faster_whisper import WhisperModel; print('faster-whisper OK')"
python3 -c "import requests; print('requests OK')"
python3 -c "import firebase_admin; print('Firebase Admin SDK OK')"
gemini                         # /mcp → all green → /quit
```

If anything fails: `command not found` = not installed or PATH issue. `ModuleNotFoundError` = re-run pip install with `--break-system-packages`.

---

## Part 2: Project Scaffolding

### Step 1: Create Monorepo Structure

```bash
mkdir -p ~/dev/projects/tripledb
cd ~/dev/projects/tripledb

# Shared docs
mkdir -p docs

# Pipeline
mkdir -p pipeline/scripts
mkdir -p pipeline/agents
mkdir -p pipeline/config
mkdir -p pipeline/data/audio
mkdir -p pipeline/data/transcripts
mkdir -p pipeline/data/extracted
mkdir -p pipeline/data/normalized
mkdir -p pipeline/data/enriched
mkdir -p pipeline/data/logs

# Flutter app (Phase 7 — deferred)
flutter create app
cd app
mkdir -p design-brief/scrapes design-brief/review
mkdir -p lib/{models,providers,services,theme,utils,pages}
mkdir -p lib/widgets/{map,search,cards,detail}
mkdir -p assets/{images,logos,data}
cd ..
```

Resulting structure:

```
tripledb/
├── docs/
│   ├── ddd-project-setup-v6.md
│   ├── ddd-design-architecture-v6.md
│   └── ddd-phase-prompts-v6.md
│
├── pipeline/
│   ├── scripts/                       # Python scripts (created per phase)
│   ├── agents/                        # DDD agent personas
│   ├── config/
│   │   ├── playlist_urls.txt          # 804 URLs from playlist dump
│   │   ├── test_batch.txt             # 30 test video URLs
│   │   ├── firestore_schema.json      # Firestore document model
│   │   └── extraction_prompt.md       # Nemotron prompt template
│   ├── data/
│   │   ├── audio/                     # {video_id}.mp3 files (gitignored)
│   │   ├── transcripts/               # {video_id}.json (gitignored)
│   │   ├── extracted/                 # {video_id}.json
│   │   ├── normalized/                # restaurants.jsonl, dishes.jsonl, etc.
│   │   ├── enriched/                  # Same files with enrichment data
│   │   └── logs/                      # Error logs, checkpoint reports
│   └── GEMINI.md                      # Pipeline agent instructions
│
├── app/                               # Flutter Web (Phase 7 — deferred)
│   ├── design-brief/
│   ├── lib/
│   ├── assets/
│   ├── web/
│   ├── pubspec.yaml
│   ├── firebase.json
│   └── GEMINI.md                      # App agent instructions (deferred)
│
├── GEMINI.md                          # Root agent router
├── .gitignore
└── README.md
```

### Step 2: Create Root GEMINI.md

Copy from `docs/ddd-design-architecture-v6.md` Section 4.1.

### Step 3: Create pipeline/GEMINI.md

Copy from `docs/ddd-design-architecture-v6.md` Section 4.2.

### Step 4: Create app/GEMINI.md

Copy from `docs/ddd-design-architecture-v6.md` Section 4.3.

### Step 5: Create .gitignore

```bash
cat > .gitignore << 'EOF'
# Audio files — too large for git (each mp3 is 10-25 MB)
pipeline/data/audio/*.mp3

# YouTube info JSON (written by yt-dlp --write-info-json)
pipeline/data/audio/*.info.json

# Transcripts — large, reproducible from mp3s
pipeline/data/transcripts/

# Runtime logs
pipeline/data/logs/

# Model files
*.gguf
*.bin

# Python
__pycache__/
*.pyc
*.pyo
.venv/

# Secrets
.env
*.key
*.pem
*-sa.json
*-credentials.json

# OS
.DS_Store
Thumbs.db

# IDE
.idea/
.vscode/
*.swp
*.swo

# Flutter build output
app/build/

# Keep empty dirs
!**/.gitkeep
EOF
```

### Step 6: Git Init and Push

```bash
cd ~/dev/projects/tripledb
git init
git branch -m master main
find pipeline/data -type d -empty -exec touch {}/.gitkeep \;
touch pipeline/scripts/.gitkeep pipeline/agents/.gitkeep pipeline/config/.gitkeep
git remote add origin git@github.com:TachTech-Engineering/tripledb.git
git add .
git commit -m "KT initial scaffold"
git push -u origin main
```

### Step 7: Dump the Playlist

This is Phase 0's core deliverable — the master URL list:

```bash
cd ~/dev/projects/tripledb/pipeline
yt-dlp --flat-playlist --print "%(url)s  # %(title)s [%(duration_string)s]" \
  "https://www.youtube.com/playlist?list=PLpfv1AIjenVO8kwgeqkC8FzeIkx0jr9fO" \
  > config/playlist_urls.txt
```

Verify:

```bash
wc -l config/playlist_urls.txt
# Expected: ~804 lines
head -5 config/playlist_urls.txt
# Expected: YouTube URLs with title/duration comments
```

### Step 8: Create Test Batch

Manually pick 30 video URLs from `playlist_urls.txt` — a representative sample:

- ~10 standard episodes (~22 min)
- ~10 compilations (15-40 min)
- ~5 clips (<15 min)
- ~5 marathons (1+ hrs)

```bash
# Copy selected lines from playlist_urls.txt to test_batch.txt
nano config/test_batch.txt
```

### Step 9: Project Scaffolding Checklist

```
[ ] All tools installed and verified (Part 1 complete)
[ ] Monorepo directory structure created
[ ] Root GEMINI.md created
[ ] pipeline/GEMINI.md created (from architecture doc Section 4.2)
[ ] app/GEMINI.md placeholder created (from architecture doc Section 4.3)
[ ] flutter create app executed successfully
[ ] .gitignore created
[ ] Git initialized and pushed to GitHub
[ ] Ollama running with both models pulled
[ ] MCP servers configured and verified (3 green)
[ ] Firestore enabled in Firebase Console
[ ] Firebase service account key installed
[ ] playlist_urls.txt generated (~804 URLs)
[ ] test_batch.txt curated (30 representative videos)
[ ] Test yt-dlp download of one video works
[ ] Test faster-whisper transcription of a short audio clip works
[ ] Test Ollama inference with nemotron-super works
[ ] Test Ollama inference with qwen3.5:9b works
```

---

## Known Issues and Workarounds

### Ollama Model Pull Stalls

```bash
OLLAMA_KEEP_ALIVE=0 ollama pull nemotron-super
```

If pulls keep failing, download the GGUF from HuggingFace and import with `ollama create`.

### GPU Contention: faster-whisper vs Ollama

The RTX 2080 SUPER's 8 GB VRAM fits one workload at a time. Stop Ollama before running Whisper:

```bash
systemctl --user stop ollama
# Run transcription
systemctl --user start ollama
```

Pipeline phases are sequential, so this only matters during interactive testing.

### yt-dlp YouTube Throttling

```bash
yt-dlp --sleep-interval 5 --max-sleep-interval 30 [URL]
```

Premium cookies help. See section 1.7.

### yt-dlp tv.youtube.com URLs

YouTube TV URLs (`tv.youtube.com`) are NOT supported by yt-dlp. Only regular `youtube.com/watch?v=` URLs work. The playlist dump produces standard YouTube URLs automatically.

### Nemotron 3 Super OOM

Try smaller quantization: `ollama pull nemotron-super:q4_k_m` (~25% less RAM).

### Qwen 3.5 Thinking Mode

Disable `<think>` blocks in output by adding `/no_think` to the system prompt or `enable_thinking: false` in the Ollama API call.

### pip --break-system-packages

Required on Arch/CachyOS. Safe for user packages. If you see `externally-managed-environment`: you forgot the flag.

### Node.js TLS Errors with MCP

Behind a corporate proxy or Cloudflare Gateway:

```bash
set -x NODE_EXTRA_CA_CERTS "/etc/ssl/certs/ca-certificates.crt"
```

---

## Cost Estimate

| Component          | Cost                                    |
|--------------------|-----------------------------------------|
| yt-dlp downloads   | Free (Premium subscription separate)    |
| faster-whisper     | Free (local CUDA)                       |
| Nemotron 3 Super   | Free (local Ollama)                     |
| Qwen 3.5-9B       | Free (local Ollama)                     |
| Firecrawl MCP      | API credits only (enrichment phase)     |
| Firestore          | Free tier (1 GiB, 50K reads/day)        |
| Firebase Hosting   | Free tier (Spark plan)                  |
| Gemini CLI         | Free tier                               |
| **Total**          | **Near-zero marginal cost**             |
