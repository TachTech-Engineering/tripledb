# TripleDB — Phase 0 Plan v0.7

**Phase:** 0 — Setup & Scaffolding
**Iteration:** 7 (global project iteration)
**Date:** March 19, 2026
**Machine:** NZXTcos (i9-13900K, 64GB, RTX 2080 SUPER)
**Goal:** Every tool installed, monorepo scaffolded, playlist dumped, test batch curated, ready for Phase 1.

---

## Reference Docs (read but don't execute from — execute from THIS doc)

- `docs/ddd-project-setup-v6.md` — full machine setup detail and known issues
- `docs/ddd-design-architecture-v6.md` — data model, GEMINI.md templates, agent personas, extraction prompt
- `docs/ddd-phase-prompts-v6.md` — execution strategy, Group A/B architecture, sprint plan

---

## Step 1: Verify Core Toolchain

Skip anything already installed. Just verify.

```bash
git --version
node --version && npm --version
python3 --version && pip --version
ffmpeg -version | head -1
```

If any are missing: `yay -S git google-chrome nodejs npm python python-pip ffmpeg`

---

## Step 2: Fish Shell Environment

Verify `~/.config/fish/config.fish` has the TripleDB block. If not, add:

```fish
set -x CHROME_EXECUTABLE /usr/bin/google-chrome-stable
set -x GEMINI_API_KEY "your-gemini-api-key-here"
set -x GOOGLE_CLOUD_PROJECT "tripledb-e0f77"
set -x GOOGLE_APPLICATION_CREDENTIALS "$HOME/.config/gcloud/tripledb-sa.json"
set -x OLLAMA_HOST "http://localhost:11434"
fish_add_path $HOME/.local/bin
```

```bash
source ~/.config/fish/config.fish
```

---

## Step 3: Ollama + Models (start first — downloads take time)

```bash
curl -fsSL https://ollama.com/install.sh | sh
systemctl --user enable --now ollama
ollama pull nemotron-super
ollama pull qwen3.5:9b
```

Let these download in the background. Continue with Steps 4-8 while they pull.

Verify when done:

```bash
ollama list
# Expected: nemotron-super and qwen3.5:9b both listed
```

---

## Step 4: Python Packages

```bash
pip install faster-whisper yt-dlp firebase-admin requests --break-system-packages
```

Verify:

```bash
python3 -c "from faster_whisper import WhisperModel; print('faster-whisper OK')"
yt-dlp --version
python3 -c "import firebase_admin; print('Firebase Admin SDK OK')"
python3 -c "import requests; print('requests OK')"
```

---

## Step 5: Gemini CLI + GSD + MCP

```bash
sudo npm install -g @google/gemini-cli
sudo npx get-shit-done-cc --gemini --global
```

Create `~/.gemini/settings.json`:

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

First launch and verify:

```bash
gemini
# /mcp → all 3 green → /quit
```

GSD skills fix (if validation errors on launch):

```bash
for f in ~/.gemini/agents/gsd-*.md; sed -i '/^skills:$/,/^[^ ]/{ /^skills:$/d; /^  - /d; }' $f; end
```

---

## Step 6: Agency Agents

```bash
git clone https://github.com/msitarzewski/agency-agents.git ~/.agency-agents
cd ~/.agency-agents
./scripts/convert.sh --tool gemini
./scripts/install.sh --tool gemini
```

```bash
ls ~/.gemini/agents/
# Expected: list of .md files
```

---

## Step 7: Firebase Service Account Key

The Firebase project `tripledb-e0f77` already exists. Download the SA key:

1. [Firebase Console](https://console.firebase.google.com/) → tripledb → Project Settings → Service accounts
2. Generate new private key → Download JSON

```bash
mkdir -p ~/.config/gcloud
mv ~/Downloads/tripledb-*.json ~/.config/gcloud/tripledb-sa.json
chmod 600 ~/.config/gcloud/tripledb-sa.json
```

If Firestore isn't enabled yet: Firebase Console → Build → Firestore Database → Create database → Production mode → us-west1.

---

## Step 8: Scaffold the Monorepo

```bash
mkdir -p ~/dev/projects/tripledb
cd ~/dev/projects/tripledb

mkdir -p docs
mkdir -p pipeline/scripts
mkdir -p pipeline/agents
mkdir -p pipeline/config
mkdir -p pipeline/data/audio
mkdir -p pipeline/data/transcripts
mkdir -p pipeline/data/extracted
mkdir -p pipeline/data/normalized
mkdir -p pipeline/data/enriched
mkdir -p pipeline/data/logs

flutter create app
cd app
mkdir -p design-brief/scrapes design-brief/review
mkdir -p lib/{models,providers,services,theme,utils,pages}
mkdir -p lib/widgets/{map,search,cards,detail}
mkdir -p assets/{images,logos,data}
cd ..
```

---

## Step 9: Drop Docs Into Place

Copy the three v6 reference docs into `docs/`:

```bash
cp /path/to/ddd-project-setup-v6.md docs/
cp /path/to/ddd-design-architecture-v6.md docs/
cp /path/to/ddd-phase-prompts-v6.md docs/
cp /path/to/ddd-plan-v0.7.md docs/
```

---

## Step 10: Create GEMINI.md Files

From `docs/ddd-design-architecture-v6.md`:

**Root GEMINI.md** — copy Section 4.1 content to `~/dev/projects/tripledb/GEMINI.md`

**Pipeline GEMINI.md** — copy Section 4.2 content to `~/dev/projects/tripledb/pipeline/GEMINI.md`

**App GEMINI.md** — copy Section 4.3 content to `~/dev/projects/tripledb/app/GEMINI.md`

---

## Step 11: Create Agent Personas

From `docs/ddd-design-architecture-v6.md` Sections 5a-5e, create these files in `pipeline/agents/`:

```bash
# Copy the content blocks from the architecture doc into each file:
nano pipeline/agents/ddd-transcriber.md    # Section 5a
nano pipeline/agents/ddd-extractor.md      # Section 5b
nano pipeline/agents/ddd-normalizer.md     # Section 5c
nano pipeline/agents/ddd-enricher.md       # Section 5d
nano pipeline/agents/ddd-qa-checker.md     # Section 5e
```

---

## Step 12: Create Extraction Prompt Template

From `docs/ddd-design-architecture-v6.md` Section 8, copy the full extraction prompt content to:

```bash
nano pipeline/config/extraction_prompt.md
```

---

## Step 13: Create .gitignore

```bash
cd ~/dev/projects/tripledb
cat > .gitignore << 'EOF'
# Audio files — too large for git
pipeline/data/audio/*.mp3
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

# Flutter build
app/build/

# Keep empty dirs
!**/.gitkeep
EOF
```

---

## Step 14: Git Init and Push

```bash
cd ~/dev/projects/tripledb
git init
git branch -m master main
find pipeline/data -type d -empty -exec touch {}/.gitkeep \;
touch pipeline/scripts/.gitkeep pipeline/config/.gitkeep
git remote add origin git@github.com:TachTech-Engineering/tripledb.git
git add .
git commit -m "KT Phase 0: project scaffold, agent personas, extraction prompt"
git push -u origin main
```

---

## Step 15: Dump the Playlist

```bash
cd ~/dev/projects/tripledb/pipeline
yt-dlp --flat-playlist --print "%(url)s  # %(title)s [%(duration_string)s]" \
  "https://www.youtube.com/playlist?list=PLpfv1AIjenVO8kwgeqkC8FzeIkx0jr9fO" \
  > config/playlist_urls.txt
wc -l config/playlist_urls.txt
# Expected: ~804 lines
head -10 config/playlist_urls.txt
```

---

## Step 16: Curate Test Batch

Open `config/playlist_urls.txt` and pick 30 representative videos. The duration is in brackets at the end of each line.

Target mix:
- ~10 standard episodes (~18-25 min)
- ~10 compilations (~15-40 min)
- ~5 clips (<15 min)
- ~5 marathons (1+ hr)

```bash
nano config/test_batch.txt
# Paste your 30 selected lines
wc -l config/test_batch.txt
# Expected: 30
```

---

## Step 17: Run Gemini Validation

```bash
cd ~/dev/projects/tripledb/pipeline
gemini
```

Paste this:

```
Read GEMINI.md for project context.

## Phase 0: Setup Validation

Verify the following:

1. Read pipeline/GEMINI.md — confirm you understand your role.
2. Verify config/playlist_urls.txt exists:
   wc -l config/playlist_urls.txt
3. Verify config/test_batch.txt exists:
   wc -l config/test_batch.txt
4. Verify agent personas:
   ls agents/
5. Verify extraction prompt:
   head -5 config/extraction_prompt.md
6. Verify Ollama models:
   ollama list
7. Check MCP servers: /mcp

Report results. Do NOT commit or push.
```

---

## Step 18: Phase 0 Commit

```bash
cd ~/dev/projects/tripledb
git checkout -b phase/0-setup
git add docs/ pipeline/config/ pipeline/agents/ GEMINI.md pipeline/GEMINI.md app/GEMINI.md
git commit -m "KT Phase 0: playlist dump (N URLs), test batch (30), agent personas, extraction prompt"
git push -u origin phase/0-setup
```

---

## Phase 0 Completion Checklist

```
[ ] git, node, npm, python3, pip, ffmpeg — all verified
[ ] Fish shell config updated with TripleDB env vars
[ ] Ollama running with nemotron-super and qwen3.5:9b pulled
[ ] faster-whisper, yt-dlp, firebase-admin, requests — pip installed
[ ] Gemini CLI installed, first launch complete
[ ] GSD installed, skills validation fix applied
[ ] Agency Agents cloned and installed for Gemini CLI
[ ] MCP servers configured (3 green in /mcp)
[ ] Firebase SA key at ~/.config/gcloud/tripledb-sa.json
[ ] Firestore enabled in Firebase Console (us-west1)
[ ] Monorepo scaffolded at ~/dev/projects/tripledb
[ ] Root GEMINI.md created
[ ] pipeline/GEMINI.md created
[ ] app/GEMINI.md created
[ ] 5 agent personas in pipeline/agents/
[ ] Extraction prompt at pipeline/config/extraction_prompt.md
[ ] .gitignore created
[ ] Repo pushed to git@github.com:TachTech-Engineering/tripledb.git
[ ] playlist_urls.txt generated (~804 URLs)
[ ] test_batch.txt curated (30 videos, mixed types)
[ ] Gemini validation passed (Step 17)
[ ] Phase 0 committed to phase/0-setup branch
```

When every box is checked, you're ready. Come back and we write `ddd-plan-v1.8.md` together.
