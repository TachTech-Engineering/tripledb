# TripleDB — Design v7.33

---

# Part 1: IAO — Iterative Agentic Orchestration

## The Eight Pillars of IAO

1. **Plan-Report Loop** — design + plan in → build + report out
2. **Zero-Intervention Target** — pre-answer every decision in the plan
3. **Self-Healing Loops** — diagnose → fix → re-run (max 3, then skip)
4. **Versioned Artifacts as Source of Truth** — GEMINI.md is the version lock
5. **Artifacts Travel Forward** — current in `docs/`, previous in `docs/archive/`
6. **Methodology Co-Evolution** — IAO evolves through the Plan-Report loop
7. **Separation of Interactive and Unattended** — agent vs bash + tmux
8. **Progressive Trust Through Graduated Batches** — earn confidence, don't assume it

## IAO Iteration History

| Iteration | Phase | Interventions | Key Learning |
|-----------|-------|---------------|--------------|
| v0.7 | Setup | N/A | Monorepo scaffolded. |
| v1.8–v1.10 | Discovery | 10–20+ | Gemini Flash API solved extraction. |
| v2.11 | Calibration | 20+ | CUDA path is shell-level. |
| v3.12 | Stress Test | **0** | Autonomous batch healing. |
| v4.13 | Validation | **0** | Group B green-lit. |
| v5.14–v5.15 | Production | **0** | 773 videos, 14-hour unattended run. |
| v6.26–v6.29 | Firestore + Polish | **0** | 1,102 loaded, 916 geocoded, app polished. |
| v8.17–v8.25 | Flutter App | **0** | tripledb.net live. |
| v7.30 | Enrichment Discovery | **0** | 50-restaurant batch: 66.7% match. |
| v7.31 | Enrichment Production | **1** | 625 enriched. API key not pre-set. |
| v7.32 | Enrichment Refinement | **0** | 83 recovered, 126 false positives removed. 582 verified enriched. |

## Artifact Spec

| Direction | File | Author | Purpose |
|-----------|------|--------|---------|
| Input | `ddd-design-v{P}.{I}.md` | Claude | Living architecture, locked decisions |
| Input | `ddd-plan-v{P}.{I}.md` | Claude | Execution steps, success criteria |
| Output | `ddd-build-v{P}.{I}.md` | Gemini | Full session transcript |
| Output | `ddd-report-v{P}.{I}.md` | Gemini | Metrics, recommendation |
| Output | `README.md` (updated) | Gemini | All standard sections |

## Agent Restrictions

```
1. Git READ commands allowed. Git WRITE commands and firebase deploy FORBIDDEN.
2. flutter build web and flutter run ARE ALLOWED for testing.
3. NEVER ask permission — auto-proceed on EVERY step.
4. Self-heal errors: diagnose → fix → re-run (max 3 attempts, then skip).
5. 3 consecutive identical errors = STOP, fix root cause, restart.
6. MCP: Context7 ALLOWED. No other MCP servers.
7. MUST produce ddd-build and ddd-report artifacts before ending.
8. FULL PROJECT ACCESS: The agent may read and write files ANYWHERE under
   ~/dev/projects/tripledb/ — including pipeline/, app/, docs/, and project root.
   This is explicitly granted. Do not restrict yourself to pipeline/ only.
9. Google Places API key: $GOOGLE_PLACES_API_KEY — NEVER hardcode, NEVER commit.
   If not set, print error and HALT. Do NOT ask interactively.
10. Build log is MANDATORY — full transcript of every command and output.
11. CHECKPOINT after every major step (see Checkpoint Protocol below).
```

## Checkpoint Protocol (NEW — v7.33)

Long-running iterations risk losing progress to terminal crashes, session timeouts, or network drops. Every plan step that produces durable output must write a checkpoint file.

### Mechanism

```
data/checkpoints/v{P}.{I}_checkpoint.json
```

Format:
```json
{
  "iteration": "7.33",
  "last_completed_step": 3,
  "step_name": "Backfill google_current_name",
  "timestamp": "2026-03-28T14:22:00Z",
  "metrics": {
    "records_processed": 582,
    "names_differing": 47
  }
}
```

### Rules

1. **Write checkpoint after each numbered plan step completes.** Not after substeps — after the whole step.
2. **On session start, read the checkpoint file.** If it exists and `last_completed_step > 0`, skip to the next step. Log what was skipped and why.
3. **Checkpoint is advisory, not blocking.** If the checkpoint file is corrupt or missing, start from Step 0. Do not error.
4. **Scripts also have internal resume support.** Checkpointing is for step-level recovery. Scripts handle record-level resume independently (e.g., skipping already-processed restaurant IDs).
5. **Delete the checkpoint file at the end of the iteration** (after all artifacts are written). It should not persist into the next iteration.

### Recovery Flow

```
1. Agent starts. Reads checkpoint.
2. Checkpoint says last_completed_step=3.
3. Agent logs: "Resuming from checkpoint. Steps 0-3 already complete. Starting Step 4."
4. Agent executes Steps 4 onward.
5. On completion, agent deletes checkpoint.
```

## ADR Registry

| ADR | Project | Status | Iterations |
|-----|---------|--------|------------|
| ADR-001 | TripleDB | Active | v0.7 → v7.33 (current) |

---

# Part 2: ADR-001 — TripleDB

## Mandate

Process 805 YouTube DDD videos into a structured, searchable restaurant database at tripledb.net. Phase 7 extends the dataset with real-world enrichment. v7.33 adds historical preservation of closed/renamed restaurants and improves data provenance.

## Pipeline Architecture

```
YouTube Playlist (805 videos)
    ↓ yt-dlp (local)
MP3 Audio
    ↓ faster-whisper large-v3 (local CUDA)
Timestamped Transcripts
    ↓ Gemini 2.5 Flash API (cloud)
Extracted Restaurant JSON
    ↓ Gemini 2.5 Flash API (cloud)
Normalized JSONL
    ↓ Nominatim (OpenStreetMap)
Geocoded Data
    ↓ Google Places API (New) — enrichment + name resolution
Enriched Data (ratings, open/closed, websites, AKA names)
    ↓ Firebase Admin SDK
Cloud Firestore
    ↓ Flutter Web
tripledb.net
```

## Phase Status

| IAO Iteration | Phase | Focus | Status |
|---|---|---|---|
| v0.7–v4.13 | 0-4 | Pipeline refinement | ✅ Complete |
| v5.14–v5.15 | 5 | Production run | ✅ Complete |
| v6.26–v6.29 | 6 | Firestore, geocoding, polish | ✅ Complete |
| v8.17–v8.25 | 8 | Flutter app | ✅ Complete |
| v7.30–v7.32 | 7 | Enrichment (discovery → production → refinement) | ✅ Complete |
| v7.33 | 7 | AKA names, closed restaurant UX, checkpointing | 🔧 Current |

## v7.33 Scope — Three Deliverables

### Deliverable 1: `google_current_name` Field (AKA)

**Problem:** Many DDD restaurants have been renamed, changed ownership, or closed and been replaced by a new business at the same address. The v7.31/v7.32 enrichment matched these based on location, but the app has no way to show the relationship between the DDD name and the current name.

Examples from v7.32:
- "Mamo's" (DDD) → "Fat Mo's" (Google) — same location, different name
- "Katalina's" (DDD) → "Catalina's 2" (Google) — spelling/branding variant
- "Joe's BBQ Shack" (DDD) → "Joe's Original BBQ" (Google) — minor rebrand

**Solution:** Add `google_current_name` to every enriched restaurant document. When the DDD name differs from the Google name, the app displays both.

**Schema addition:**
```json
{
  "name": "Mamo's",                    // DDD name (always preserved, NEVER overwritten)
  "google_current_name": "Fat Mo's",   // What Google Places calls it today
  "name_changed": true                  // Computed: name != google_current_name
}
```

**Data source:** The Google Places API `displayName.text` field, which we already fetch during enrichment but didn't persist. For the 582 already-enriched records, we need to either:
- Re-fetch from Places API using stored `google_place_id` (preferred — 582 Detail calls, free tier)
- Use the `places_cache.json` if it contains the display name (check first)

**Display rules:**
- If `name_changed == false` or `google_current_name` is null → show `name` only
- If `name_changed == true` and `still_open == true` → show "**{name}** (now {google_current_name})"
- If `name_changed == true` and `still_open == false` → show "**{name}** (closed)" with no current name
- Search must index BOTH `name` and `google_current_name`

### Deliverable 2: Closed Restaurant UX

**Problem:** 30 permanently closed restaurants are in the dataset but the app doesn't let users filter or visually distinguish them. Users searching for "great BBQ near me" shouldn't get a closed restaurant as a top result without knowing it's closed.

**Solution:**

**Map:**
- Open restaurants: Red pin (#DD3333) — existing
- Closed restaurants: Grey pin (#888888) — new
- Filter toggle: "Show closed" checkbox (default: ON for historical completeness)
- When "Show closed" is OFF, closed restaurants are excluded from map pins AND cluster counts

**List (Home Page):**
- Closed restaurants show a "Permanently Closed" badge in muted red
- "Top 3 Near You" section EXCLUDES closed restaurants (users want somewhere to eat, not a history lesson)
- Search results INCLUDE closed restaurants but with the badge

**Explore Page:**
- New stat: "X restaurants permanently closed since filming"
- Breakdown by state or time period if data supports it

**Restaurant Detail Page:**
- If `still_open == false`: prominent banner at top: "This restaurant has permanently closed"
- If `still_open == true` and `business_status == "CLOSED_TEMPORARILY"`: yellow banner: "Temporarily closed"
- If `name_changed == true`: subtitle showing the name change

### Deliverable 3: Checkpoint Protocol

See the Checkpoint Protocol section above. Implementation is in the plan — the agent writes checkpoint JSON after each step and reads it on session start.

## Data Model (Firestore — Updated for v7.33)

### Collection: `restaurants` — new/modified fields

```json
{
  "name": "Mamo's",                         // DDD original name (NEVER overwritten)
  "google_current_name": "Fat Mo's",        // NEW: Google Places displayName
  "name_changed": true,                      // NEW: computed boolean
  "still_open": false,                       // Existing (from v7.31)
  "business_status": "CLOSED_PERMANENTLY",  // Existing
  "google_place_id": "ChIJ...",             // Existing
  "google_rating": 4.6,                     // Existing
  "google_rating_count": 1247,              // Existing
  "google_maps_url": "...",                 // Existing
  "website_url": "...",                     // Existing
  "formatted_address": "...",              // Existing
  "photo_references": [...],               // Existing
  "enriched_at": "...",                    // Existing
  "enrichment_source": "google_places_api", // Existing
  "enrichment_match_score": 0.92,          // Existing
  "enrichment_verified": true,              // Existing (from v7.32)
  "latitude": 35.1396,
  "longitude": -90.0541,
  "cuisine_type": "Soul Food",
  "owner_chef": "Tyrone Washington",
  "visits": [ ... ],
  "dishes": [ ... ],
  "created_at": "...",
  "updated_at": "..."
}
```

## Current State (After v7.32)

### Pipeline Data
- **Unique restaurants:** 1,102
- **Enriched (verified):** 582 (52.8%)
  - Auto-accepted: 342
  - LLM-verified YES: 112
  - LLM-verified UNCERTAIN: 26 (kept, flagged)
  - Refined matches: 83
  - False positives removed: 126
- **Not enriched:** 520
  - Final no-match: 379
  - Skipped (null name): 15
  - Other: 126 (removed false positives)
- **Geocoded:** 1,006/1,102 (91.3%)
- **Permanently closed:** 30
- **Temporarily closed:** 11

### App (tripledb.net)
- Live with enrichment UI (ratings, open/closed badges, links)
- 1,006 map pins with clustering
- Trivia includes enrichment facts
- No AKA/name-change display yet
- No closed-restaurant filter yet

### Firestore
- Project: tripledb-e0f77
- `restaurants`: 1,102 docs (582 with enrichment)
- `videos`: 773 docs

## Repository Structure

```
~/dev/projects/tripledb/               ← PROJECT ROOT (agent has FULL access)
├── docs/                              ← Current iteration artifacts
│   └── archive/
├── pipeline/
│   ├── scripts/
│   ├── config/
│   ├── data/
│   │   ├── normalized/
│   │   ├── enriched/
│   │   │   ├── restaurants_enriched.jsonl
│   │   │   └── places_cache.json
│   │   ├── checkpoints/               ← NEW: checkpoint files
│   │   └── logs/
│   └── GEMINI.md
├── app/
│   ├── lib/
│   └── GEMINI.md
├── GEMINI.md
├── .gitignore
└── README.md
```

## Known Gotchas

1. **fish shell:** No heredocs. Use `printf`, `cat <<'EOF'`, or temp files.
2. **Working directory:** Agent has FULL access to ~/dev/projects/tripledb/. Navigate freely.
3. **Google Places API key:** `$GOOGLE_PLACES_API_KEY` — halt if not set.
4. **Cloudflare WARP TLS:** Disconnect if Python requests fails.
5. **Places API rate limit:** 0.15s courtesy delay.
6. **Build log is MANDATORY.** Full transcript.
7. **README at PROJECT ROOT.** ~/dev/projects/tripledb/README.md.
8. **Checkpoint after every step.** Write to data/checkpoints/.
9. **Never overwrite `name` field.** DDD original name is sacred. `google_current_name` is the mutable field.
10. **`name_changed` is computed.** Set it based on fuzzy comparison of `name` vs `google_current_name`. Threshold: if similarity < 0.95, set `name_changed = true`.

## GEMINI.md Template

```markdown
# TripleDB — Agent Instructions

## Current Iteration: 7.33

IMPORTANT: Read documents in this EXACT order before executing:

1. ../docs/ddd-design-v7.33.md — Architecture, AKA field, closed UX, checkpoint protocol
2. ../docs/ddd-plan-v7.33.md — Execution steps

Do NOT begin execution until both files have been read.

## Rules That Never Change
- Git READ commands allowed. Git WRITE commands and firebase deploy FORBIDDEN.
- flutter build web and flutter run ARE ALLOWED.
- NEVER ask permission — auto-proceed on EVERY step.
- Context7 MCP allowed. No other MCP servers.
- MUST produce ddd-build-v7.33.md AND ddd-report-v7.33.md before ending.
- ddd-build must be a FULL session transcript — not a summary.
- README.md is at PROJECT ROOT (~/dev/projects/tripledb/README.md).
- FULL PROJECT ACCESS: agent can read/write ANYWHERE under ~/dev/projects/tripledb/.
- $GOOGLE_PLACES_API_KEY must be set. If not, print error and HALT.
- CHECKPOINT after every numbered plan step. Write to pipeline/data/checkpoints/.
- NEVER overwrite the `name` field on restaurant documents.
```
