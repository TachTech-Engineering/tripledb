# TripleDB - UAT Plan v0.1 (Phase 0)

**Phase:** 0 - Setup & Environment Validation
**Executor:** Gemini CLI (YOLO mode, tmux session)
**Date:** March 2026
**Goal:** Bootstrap UAT environment, validate all tools, create GEMINI.md, auto-chain to Phase 1.

---

## Read Order

```
1. docs/ddd-design-uat.md - Full UAT architecture (ALL phases reference this)
2. docs/ddd-plan-uat-v0.1.md - This file. Phase 0 execution steps.
```

---

## Autonomy Rules

```
1. AUTO-PROCEED. NEVER ask permission. YOLO.
2. SELF-HEAL: max 3 attempts per error. Checkpoint after every step.
3. Git READ only. NEVER git add/commit/push.
4. NO Firestore writes. EVER. Pipeline produces local JSONL only.
5. NO sudo. All deps must be pre-installed.
6. FORMATTING: No em-dashes. Use " - " instead. Use "->" for arrows.
7. After Phase 0 completes, AUTO-CHAIN to Phase 1.
```

---

## tmux Session

The entire UAT runs in a single tmux session. Start here:

```bash
tmux new-session -s tripledb-uat
cd ~/dev/projects/tripledb
gemini
# Paste: "Read GEMINI.md and execute."
```

If SSH drops: `tmux attach -t tripledb-uat`

---

## Step 0: Em-Dash Sweep

First task before anything else. AI-generated text contains em-dashes that violate formatting rules.

```bash
# Detect
grep -rn $'\xe2\x80\x94' --include='*.md' --include='*.dart' .

# Replace all with " - "
find . \( -name '*.md' -o -name '*.dart' \) -exec sed -i 's/\xe2\x80\x94/ - /g' {} +

# Verify zero remaining
grep -rn $'\xe2\x80\x94' --include='*.md' --include='*.dart' .
# Expected: 0 matches
```

**Success:** grep returns 0 matches.

**Write checkpoint:** `pipeline/data/checkpoints/uat-phase0.json`
```json
{ "phase": 0, "step": 0, "status": "complete", "em_dashes_found": <count>, "em_dashes_remaining": 0 }
```

---

## Step 1: Environment Validation

Run every validation command. All must pass.

### 1a. Hardware & CUDA

```bash
nvidia-smi
# Expected: GPU listed (RTX 2080 SUPER or RTX 2000 Ada), driver loaded

python3 -c "from faster_whisper import WhisperModel; print('faster-whisper OK')"
# Expected: "faster-whisper OK"

echo $LD_LIBRARY_PATH
# Expected: contains /usr/local/lib/ollama/cuda_v12
```

**If CUDA fails:** Check `~/.config/fish/config.fish` for `LD_LIBRARY_PATH`. It MUST be set at shell level, not Python level (Gotcha #1).

### 1b. Pipeline Tools

```bash
yt-dlp --version
# Expected: version string

python3 -c "import requests; print('requests OK')"
python3 -c "import firebase_admin; print('firebase-admin OK')"
python3 -c "from google.cloud import firestore; print('firestore OK')"
```

### 1c. API Keys

```bash
echo $GEMINI_API_KEY | head -c 5
# Expected: first 5 chars of key (not empty)

echo $GOOGLE_PLACES_API_KEY | head -c 5
# Expected: first 5 chars of key (not empty)

# Validate Gemini key is reachable
python3 -c "
import requests
r = requests.get('https://generativelanguage.googleapis.com/v1/models', params={'key': '$GEMINI_API_KEY'})
print('Gemini API: ' + str(r.status_code))
"
# Expected: 200
```

### 1d. Flutter

```bash
flutter analyze
# Expected: No issues found!

flutter build web
# Expected: Compiling lib/main.dart for the Web...  (success)
```

### 1e. Firebase

```bash
firebase login:list
# Expected: shows authenticated user

firebase use tripledb-e0f77
# Expected: Now using project tripledb-e0f77
```

### 1f. Puppeteer

```bash
npx puppeteer --version 2>/dev/null || node -e "require('puppeteer'); console.log('Puppeteer OK')"
# Expected: version or "Puppeteer OK"
```

**If Puppeteer missing:** Use local install fallback:
```bash
cd /tmp && mkdir -p puppeteer-test && cd puppeteer-test && npm init -y && npm install puppeteer
cd ~/dev/projects/tripledb
```

### 1g. Orphan Process Check

```bash
# Kill any leftover transcription processes
pkill -f faster-whisper 2>/dev/null
pkill -f ollama 2>/dev/null
echo "Orphan check complete"
```

### 1h. Cloudflare WARP Check

```bash
# If Python requests fail with TLS errors, Cloudflare WARP may be interfering
python3 -c "import requests; r = requests.get('https://httpbin.org/get'); print('TLS OK:', r.status_code)"
# Expected: TLS OK: 200
```

**If TLS fails:** Disconnect Cloudflare WARP or verify `NODE_EXTRA_CA_CERTS` is set.

**Update checkpoint:**
```json
{ "phase": 0, "step": 1, "status": "complete", "cuda": "pass", "tools": "pass", "keys": "pass", "flutter": "pass", "firebase": "pass", "puppeteer": "pass" }
```

---

## Step 2: Create GEMINI.md

Write `GEMINI.md` to the repository root:

```markdown
# TripleDB - UAT Agent Instructions

## Executor: Gemini CLI (YOLO, tmux, auto-chain)

Read docs/ddd-design-uat.md (this is the architecture for ALL phases).
Then read and execute docs/ddd-plan-uat-v0.1.md (Phase 0 setup).

After Phase 0, auto-chain: report -> next plan -> execute -> repeat.
See ddd-design-uat.md Section 9 for auto-chain logic.

## CRITICAL RULES
1. NO FIRESTORE WRITES. Pipeline produces local JSONL only.
2. NO git add/commit/push. Kyle reviews after UAT.
3. NO sudo. All deps must be pre-installed.
4. NO human questions. Zero-intervention is mandatory.
5. NO em-dashes. Use " - " (space-hyphen-space).
6. Use "->" for arrows.

## Formatting
- NEVER use em-dashes. Use " - " instead.
- Changelog: APPEND only, copy to docs/ddd-changelog-uat-v{P}.{I}.md

## Stop Conditions
- Phase 9 complete (success)
- 3 consecutive identical failures (write failure report)
- Firestore write detected (critical error, stop immediately)
```

**Success:** `GEMINI.md` exists at repo root, contains "NO FIRESTORE WRITES".

---

## Step 3: Produce Phase 0 Report

Write `docs/ddd-report-uat-v0.1.md` with:

```markdown
# TripleDB UAT - Report v0.1 (Phase 0)

## Environment Validation Results

| Check | Result |
|-------|--------|
| CUDA (nvidia-smi) | PASS/FAIL |
| faster-whisper import | PASS/FAIL |
| yt-dlp version | PASS/FAIL |
| Gemini API key | PASS/FAIL |
| Google Places API key | PASS/FAIL |
| flutter analyze | PASS/FAIL |
| flutter build web | PASS/FAIL |
| Firebase auth | PASS/FAIL |
| Firebase project | PASS/FAIL |
| Puppeteer | PASS/FAIL |
| Em-dash sweep | PASS/FAIL (X found, 0 remaining) |
| GEMINI.md created | PASS/FAIL |

## Recommendation

Environment ready for Phase 1. Proceed with 30-video discovery batch.

## Orchestration Report

| Component | Workload | Efficacy |
|-----------|----------|----------|
| Gemini CLI | 100% | TBD |
```

---

## Step 4: Produce Phase 0 Changelog

Write `docs/ddd-changelog-uat-v0.1.md`:

```markdown
# TripleDB UAT Changelog

**v0.1 (Phase 0 - Setup)**
- Environment validated: CUDA, Flutter, Firebase, API keys, Puppeteer all confirmed.
- Em-dash sweep: X occurrences found and replaced. Zero remaining.
- GEMINI.md created with version lock and critical rules.
- Ready for Phase 1 auto-chain.
```

---

## Step 5: Auto-Chain to Phase 1

After completing Steps 0-4, immediately generate and execute the Phase 1 plan:

1. Read the Phase 0 report (Step 3 output)
2. Read ddd-design-uat.md Section 7 (Phase 1: Discovery)
3. Generate `docs/ddd-plan-uat-v1.2.md` with:
   - 30-video download list (first 30 from the 805 playlist)
   - Transcription steps (faster-whisper, CUDA, tmux)
   - Extraction steps (Gemini Flash API)
   - Normalization steps
   - Success criteria: ~186 restaurants, JSONL valid
4. Execute the plan immediately
5. Continue auto-chaining through all phases

---

## Auto-Chain Logic (All Phases)

After completing Phase N:

```
1. Write docs/ddd-report-uat-v{N}.{X}.md
2. Write docs/ddd-changelog-uat-v{N}.{X}.md
3. Read the report
4. Identify next phase from ddd-design-uat.md Section 7
5. Generate docs/ddd-plan-uat-v{N+1}.{X+1}.md
6. Execute the new plan immediately
7. Repeat until Phase 9 complete or 3 consecutive identical failures
```

**Version numbering:** v{Phase}.{GlobalIteration}. Phase 0 = v0.1, Phase 1 = v1.2, Phase 2 = v2.3, etc.

---

## Success Criteria (Phase 0)

```
[ ] Em-dash sweep: 0 remaining
[ ] CUDA: nvidia-smi returns 0
[ ] faster-whisper: importable
[ ] yt-dlp: version check passes
[ ] Gemini API key: set and reachable
[ ] Google Places API key: set
[ ] flutter analyze: 0 issues
[ ] flutter build web: success
[ ] Firebase: authenticated, correct project
[ ] Puppeteer: available (global or /tmp fallback)
[ ] Orphan processes: killed
[ ] TLS: Python requests work
[ ] GEMINI.md: created at repo root
[ ] Phase 0 report: written
[ ] Phase 0 changelog: written
[ ] Auto-chain: Phase 1 plan generated and execution started
```

---

## Reminder: Formatting Rules

- NO em-dashes. Use " - " (space-hyphen-space).
- Use "->" for arrows.
- Changelog: APPEND only.
