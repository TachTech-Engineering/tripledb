# TripleDB — Phase 8 Plan v8.17

**Phase:** 8 — Flutter App Build
**Iteration:** 17 (global), Discovery (MCP Phase 1)
**Date:** March 2026
**Goal:** Set up the laptop for Flutter Web development, scrape 4 reference restaurant finder sites, extract UX patterns, and produce the analysis that drives Phase 2 Synthesis.

---

## Part 0: Laptop Setup (Run Once — Before RSA or At Hotel)

This laptop has never run a Flutter MCP build. Complete every step before launching the Discovery phase. This mirrors Part 1 of `gemini-flutter-mcp-v4.md` adapted for a fresh machine.

### 0.1 SSH Keys and GitHub Authentication

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

**If importing from Bitwarden:** copy private key to `~/.ssh/id_ed25519` and public key to `~/.ssh/id_ed25519.pub`.

**If generating new:**
```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
```

Lock permissions:
```bash
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

Create SSH config:
```bash
nano ~/.ssh/config
```

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

Add public key to GitHub (Settings → SSH and GPG Keys → New SSH Key):
```bash
cat ~/.ssh/id_ed25519.pub
```

Test:
```bash
ssh -T git@github.com
# Expected: "Hi username! You've successfully authenticated..."
```

### 0.2 Git Global Identity

```bash
git config --global user.name "Kyle Thompson"
git config --global user.email "your-email@example.com"
```

### 0.3 Core Toolchain

```bash
yay -Syu
yay -S git google-chrome android-studio nodejs npm python
```

| Package | Why |
|---------|-----|
| `git` | Version control |
| `google-chrome` | Flutter Web target + Lighthouse |
| `android-studio` | Android SDK (Flutter depends on it even for web) |
| `nodejs` + `npm` | MCP servers and Gemini CLI |
| `python` | Serve production builds locally |

Verify:
```bash
git --version && node --version && npm --version && python3 --version
```

### 0.4 Android Studio SDK Setup

1. Launch: `android-studio`
2. Run standard setup wizard → choose **Standard**
3. If system image download stalls → **Cancel** (not needed for web)
4. Accept all license agreements
5. **Plugins** → search "Flutter" → **Install** (accept Dart prompt)
6. **Settings → Languages & Frameworks → Android SDK → SDK Tools** → check **Android SDK Command-line Tools (latest)** → **Apply**
7. Close Android Studio

### 0.5 Flutter SDK

```bash
yay -S flutter-bin
```

Grant group permissions:
```bash
sudo groupadd flutterusers
sudo gpasswd -a $USER flutterusers
sudo chown -R :flutterusers /opt/flutter
sudo chmod -R g+w /opt/flutter
```

**Log out and log back in** for group changes to take effect. A new terminal is NOT enough.

### 0.6 Gemini CLI + Firebase Tools + GSD

```bash
sudo npm install -g @google/gemini-cli
sudo npm install -g firebase-tools
sudo npx get-shit-done-cc --gemini --global
```

Verify:
- `gemini` → launches without errors (exit with `/quit`)
- `firebase --version` → prints version
- GSD: verified inside Gemini session with `/gsd:help`

**Fix GSD skills validation errors** (if you see `Unrecognized key(s) in object: 'skills'`):
```fish
for f in ~/.gemini/agents/gsd-*.md; sed -i '/^skills:$/,/^[^ ]/{ /^skills:$/d; /^  - /d; }' $f; end
```

### 0.7 Antigravity IDE Symlink (Optional)

Only if Antigravity is installed on the laptop:
```bash
sudo ln -s /usr/bin/antigravity /usr/bin/agy
```

### 0.8 Fish Shell Environment

Edit `~/.config/fish/config.fish`:

```fish
# ── TripleDB / Flutter Environment ────────────────────────

# Chrome path for Flutter Web
set -x CHROME_EXECUTABLE "/usr/bin/google-chrome-stable"

# Android SDK
set -x ANDROID_HOME "$HOME/Android/Sdk"
set -x PATH $PATH $ANDROID_HOME/platform-tools $ANDROID_HOME/cmdline-tools/latest/bin

# Gemini API key (from aistudio.google.com/apikey — NEVER commit this)
set -x GEMINI_API_KEY "your-new-gemini-api-key"

# Firebase / GCP
set -x GOOGLE_CLOUD_PROJECT "tripledb-e0f77"

# Local bin
fish_add_path $HOME/.local/bin

# OPTIONAL: TLS inspection bypass (Cloudflare Gateway / corporate proxy)
# set -x NODE_EXTRA_CA_CERTS "/etc/ssl/certs/ca-certificates.crt"
```

Reload and accept Flutter licenses:
```bash
source ~/.config/fish/config.fish
flutter doctor --android-licenses
```

Type `y` at each prompt.

### 0.9 Initialize Gemini CLI

```bash
cd ~
gemini
```

When prompted, select **"1. Trust folder"**. Type `/quit`.

### 0.10 MCP Server Configuration

Edit `~/.gemini/settings.json` — replace entire contents:

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
        "FIRECRAWL_API_KEY": "YOUR_FIRECRAWL_KEY"
      }
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"]
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    },
    "lighthouse": {
      "command": "npx",
      "args": ["-y", "lighthouse-mcp"]
    }
  }
}
```

**Firecrawl key:** Get from [firecrawl.dev](https://firecrawl.dev) → API Keys.

### 0.11 Verify Everything

```bash
flutter doctor
```

Expected green checkmarks:
- Flutter (stable channel)
- Android toolchain
- Chrome (web development)
- Android Studio

---

## Part 1: Project Setup

### 1.1 Clone the Repo

```bash
mkdir -p ~/Development/Projects
cd ~/Development/Projects
git clone git@github.com:TachTech-Engineering/tripledb.git
cd tripledb
```

### 1.2 Verify Sample Data

```bash
test -f app/assets/data/sample_restaurants.jsonl && echo "OK" || echo "MISSING — push from desktop first"
```

If `MISSING`: go back to the desktop (or SSH in) and push:
```bash
# ON DESKTOP:
cd ~/Development/Projects/tripledb
head -50 pipeline/data/normalized/restaurants.jsonl > app/assets/data/sample_restaurants.jsonl
git add app/assets/data/sample_restaurants.jsonl
git commit -m "KT add sample data for frontend dev"
git push
```

Then on laptop: `git pull`

### 1.3 Create App Directory Structure

```bash
cd ~/Development/Projects/tripledb/app
mkdir -p docs
mkdir -p design-brief/scrapes/{ddd-locations,flavortown-usa,food-network-ddd,tv-food-maps}
mkdir -p design-brief/review
mkdir -p assets/{data,logos,images}
mkdir -p lib/{models,providers,services,theme,utils,pages}
mkdir -p lib/widgets/{search,restaurant,map,trivia}
```

### 1.4 Flutter Project Initialization

If `app/` doesn't already have a `pubspec.yaml`:
```bash
cd ~/Development/Projects/tripledb
flutter create app
```

If it does exist:
```bash
cd app
flutter pub get
```

### 1.5 Register Assets in pubspec.yaml

Ensure `app/pubspec.yaml` includes:
```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/data/
    - assets/logos/
    - assets/images/
```

```bash
flutter pub get
```

### 1.6 Place Plan and Design Docs

Copy `ddd-design-v8.17.md` and `ddd-plan-v8.17.md` into `app/docs/`.

### 1.7 Create GEMINI.md

```bash
nano GEMINI.md
```

Paste:

```markdown
# TripleDB App — Agent Instructions

## Current Iteration: 8.17

Read these two documents in order, then execute the plan:

1. docs/ddd-design-v8.17.md — App architecture, IAO+MCP methodology
2. docs/ddd-plan-v8.17.md — Discovery phase execution steps

Follow the autonomy rules defined in the plan. Begin with the Pre-Flight Checklist (Part 2).

## Rules That Never Change
- NEVER run git, flutter build, flutter deploy, or firebase commands
- NEVER ask permission between steps — auto-proceed on EVERY step
- If you find yourself typing a question mark, STOP. Re-read the plan. Execute.
- Self-heal errors: diagnose → fix → re-run (max 3 attempts, then skip)
- MCP servers are phase-restricted — only use what the plan allows
- Report artifacts are mandatory — do NOT end without them

## MCP Rules for Phase 8.17 (Discovery)
- ✅ Firecrawl — scrape reference sites
- ✅ Playwright — screenshots of reference sites
- ❌ Context7 — NOT allowed this phase
- ❌ Lighthouse — NOT allowed this phase
```

---

## Part 2: Pre-Flight Checklist

Run through this ENTIRE checklist before launching Gemini for the Discovery phase. Every item must pass.

```
[ ] SSH to GitHub works: ssh -T git@github.com
[ ] Git identity set: git config user.name && git config user.email
[ ] Flutter installed: flutter --version
[ ] Flutter doctor passes: flutter doctor (Chrome + Android toolchain green)
[ ] Flutter licenses accepted: flutter doctor --android-licenses
[ ] Node.js + npm installed: node --version && npm --version
[ ] Gemini CLI installed: gemini → /quit (launches without error)
[ ] Firebase CLI installed: firebase --version
[ ] Fish env loaded: echo $GEMINI_API_KEY (prints key, not empty)
[ ] Chrome path set: echo $CHROME_EXECUTABLE (prints /usr/bin/google-chrome-stable)
[ ] Android SDK path set: echo $ANDROID_HOME (prints path)
[ ] MCP config exists: cat ~/.gemini/settings.json (has all 4 servers)
[ ] Firecrawl API key set in settings.json (not "YOUR_FIRECRAWL_KEY" placeholder)
[ ] Repo cloned: ls ~/Development/Projects/tripledb/app/
[ ] Sample data present: test -f app/assets/data/sample_restaurants.jsonl
[ ] App directory structure created (design-brief/, lib/ subdirs, etc.)
[ ] pubspec.yaml has asset directories registered
[ ] flutter pub get ran successfully
[ ] GEMINI.md created in app/ with v8.17 content
[ ] Design + plan docs placed in app/docs/
[ ] MCP verified: cd app && gemini → /mcp → Firecrawl ✅, Playwright ✅ → /quit
```

---

## Part 3: Discovery Phase Execution

### Autonomy Rules

```
1. AUTO-PROCEED between all steps. NEVER ask permission.
2. SELF-HEAL: diagnose → fix → re-run (max 3 attempts, then log and skip).
3. MCP RESTRICTION: Only Firecrawl and Playwright are allowed in this phase.
   Do NOT use Context7 or Lighthouse. Do NOT build any Flutter code.
4. If a reference site blocks Firecrawl, skip it and note in the report.
   Do NOT ask the human — log it and move on.
5. NEVER run git, flutter, or firebase commands.
6. OUTPUT ARTIFACTS (mandatory before session ends):
   a. docs/ddd-report-v8.17.md — scrape results, UX findings, recommendation
   b. docs/ddd-build-v8.17.md — session transcript
7. Working directory is always app/ (relative paths resolve from here).
```

---

### Step 0: MCP Pre-Flight

Verify MCP servers are connected:

```
/mcp
```

Expected: Firecrawl and Playwright both green. If Firecrawl shows TLS errors: disable VPN/proxy temporarily, or set `NODE_EXTRA_CA_CERTS` in fish config.

---

### Step 1: Scrape Reference Site 1 — DDD Locations

**URL:** `https://dinersdriveinsdiveslocations.com`
**Focus:** Search/filter UX, state browsing, restaurant card layout, mobile nav

#### 1a. Firecrawl Scrape

Scrape the home page and one state page (e.g., California):

```
Firecrawl: scrape https://dinersdriveinsdiveslocations.com
Firecrawl: scrape https://dinersdriveinsdiveslocations.com/california (or equivalent state URL)
```

Save output to `design-brief/scrapes/ddd-locations/scrape.md`

#### 1b. Playwright Screenshots

```
Playwright: screenshot https://dinersdriveinsdiveslocations.com at 1440x900 → design-brief/scrapes/ddd-locations/desktop.png
Playwright: screenshot https://dinersdriveinsdiveslocations.com at 375x812 → design-brief/scrapes/ddd-locations/mobile.png
```

#### 1c. Note Key UX Patterns

Document in scrape.md:
- How search/filter works (dropdown? text input? faceted?)
- Restaurant card layout (what fields shown? image? rating?)
- Navigation structure (state browsing? cuisine tabs?)
- Color palette and typography
- Mobile responsiveness approach

---

### Step 2: Scrape Reference Site 2 — Flavortown USA

**URL:** `https://flavortownusa.com`
**Focus:** Directory layout, "most visited" patterns, Guy Fieri branding energy

#### 2a. Firecrawl Scrape

```
Firecrawl: scrape https://flavortownusa.com
```

Save to `design-brief/scrapes/flavortown-usa/scrape.md`

#### 2b. Playwright Screenshots

```
Playwright: screenshot https://flavortownusa.com at 1440x900 → design-brief/scrapes/flavortown-usa/desktop.png
Playwright: screenshot https://flavortownusa.com at 375x812 → design-brief/scrapes/flavortown-usa/mobile.png
```

#### 2c. Note Key UX Patterns

- "Most visited states" visualization approach
- Restaurant listing format
- Any fun/trivia elements
- How they handle the massive dataset (pagination? infinite scroll? state filtering?)

---

### Step 3: Scrape Reference Site 3 — Food Network DDD

**URL:** `https://www.foodnetwork.com/shows/diners-drive-ins-and-dives`
**Focus:** Official branding (colors, typography, imagery style), episode card layout

#### 3a. Firecrawl Scrape

```
Firecrawl: scrape https://www.foodnetwork.com/shows/diners-drive-ins-and-dives
```

Save to `design-brief/scrapes/food-network-ddd/scrape.md`

#### 3b. Playwright Screenshots

```
Playwright: screenshot https://www.foodnetwork.com/shows/diners-drive-ins-and-dives at 1440x900 → design-brief/scrapes/food-network-ddd/desktop.png
Playwright: screenshot https://www.foodnetwork.com/shows/diners-drive-ins-and-dives at 375x812 → design-brief/scrapes/food-network-ddd/mobile.png
```

#### 3c. Note Key UX Patterns

- Official DDD color palette (reds, yellows, Guy's brand colors)
- Typography choices
- Episode/video card layout
- How they present restaurant info within show context

---

### Step 4: Scrape Reference Site 4 — TV Food Maps

**URL:** `https://www.tvfoodmaps.com`
**Focus:** Map integration, filter by show/cuisine, road trip builder

#### 4a. Firecrawl Scrape

```
Firecrawl: scrape https://www.tvfoodmaps.com
```

Try to also scrape a DDD-specific filtered page if the URL structure allows.

Save to `design-brief/scrapes/tv-food-maps/scrape.md`

#### 4b. Playwright Screenshots

```
Playwright: screenshot https://www.tvfoodmaps.com at 1440x900 → design-brief/scrapes/tv-food-maps/desktop.png
Playwright: screenshot https://www.tvfoodmaps.com at 375x812 → design-brief/scrapes/tv-food-maps/mobile.png
```

#### 4c. Note Key UX Patterns

- Map implementation (Google Maps? Mapbox? Leaflet?)
- How restaurant pins are clustered/displayed
- Filter panel UX (sidebar? dropdown? search?)
- "Road trip" builder interaction model
- How they handle multi-show data (relevant for our multi-video data)

---

### Step 5: Comparative UX Analysis

Read ALL four scrapes and screenshots. Produce `design-brief/ux-analysis.md` with:

#### 5a. Pattern Comparison Table

| UX Pattern | DDD Locations | Flavortown USA | Food Network | TV Food Maps | TripleDB Decision |
|---|---|---|---|---|---|
| Search approach | | | | | |
| Restaurant card fields | | | | | |
| Map integration | | | | | |
| Mobile navigation | | | | | |
| Color palette | | | | | |
| Typography | | | | | |
| Filtering mechanism | | | | | |
| "Near me" feature | | | | | |
| Fun/trivia elements | | | | | |

#### 5b. Design Decisions for TripleDB

Based on the analysis, document these decisions:

1. **Search UX:** Google-style centered search bar (confirmed or revised based on findings)
2. **Color direction:** DDD brand energy vs clean/modern — what balance?
3. **Map approach:** Which map library/style fits best?
4. **Card layout:** What fields to show in compact vs expanded cards?
5. **Mobile strategy:** Bottom nav? Drawer? Tab bar?
6. **Typography:** What font pairings feel right for a food/restaurant finder?
7. **Trivia placement:** Where does the fun-fact widget live? How does it animate?

#### 5c. Stolen Patterns (Best of Each Site)

List specific UX patterns worth adopting from each reference site, with screenshot references.

---

### Step 6: Generate Report Artifacts

#### docs/ddd-report-v8.17.md

Must include:
1. Scrape success/failure for each of the 4 reference sites
2. Screenshot inventory (desktop + mobile for each site)
3. Key UX findings per site
4. Comparative analysis highlights
5. Design decisions for tripleDB.com
6. Recommendation for Phase 2 Synthesis focus areas
7. **Gemini's Recommendation:** Ready for Synthesis or rescrape needed?

#### docs/ddd-build-v8.17.md

Chronological session transcript.

**These artifacts are the FINAL actions. Do NOT end the session without both.**

---

## Phase 8.17 Success Criteria

```
[ ] Laptop fully set up (Part 0 complete — all tools installed and verified)
[ ] Pre-flight checklist passes (Part 2 — every item checked)
[ ] MCP servers verified (Firecrawl + Playwright green)
[ ] Site 1 (DDD Locations): scraped + desktop/mobile screenshots
[ ] Site 2 (Flavortown USA): scraped + desktop/mobile screenshots
[ ] Site 3 (Food Network DDD): scraped + desktop/mobile screenshots
[ ] Site 4 (TV Food Maps): scraped + desktop/mobile screenshots
[ ] UX analysis written (design-brief/ux-analysis.md)
[ ] Pattern comparison table completed
[ ] Design decisions documented for all 7 categories
[ ] ddd-report-v8.17.md generated with recommendation
[ ] ddd-build-v8.17.md generated
[ ] Human interventions: 0
```

---

## Git Workflow

### Before Discovery (after Part 0 + Part 1 + Part 2 pass)

```bash
cd ~/Development/Projects/tripledb
git add .
git commit -m "KT starting 8.17 — laptop setup, app scaffolding, pre-flight pass"
git push
```

### After Discovery (Gemini session complete)

```bash
cd ~/Development/Projects/tripledb
git add .
git commit -m "KT completed 8.17 — discovery scrapes and UX analysis"
git push
```

### Archive Previous Docs (before starting v8.18)

```bash
cd ~/Development/Projects/tripledb
mv docs/ddd-design-v5.14.md docs/archive/
mv docs/ddd-plan-v5.15-5.18.md docs/archive/
git add .
git commit -m "KT archived pre-Phase 8 docs, starting 8.18"
git push
```

---

## Launch Sequence

```bash
# From laptop — run pre-flight first
cd ~/Development/Projects/tripledb
git pull

# Verify sample data
test -f app/assets/data/sample_restaurants.jsonl && echo "OK" || echo "PUSH FROM DESKTOP FIRST"

# Enter app directory
cd app

# Verify Flutter
flutter pub get
flutter analyze

# Launch Gemini
gemini
```

Then type:

```
Read GEMINI.md and execute.
```
