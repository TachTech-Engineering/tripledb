# TripleDB — Phase 7 Plan v7.31

**Phase:** 7 — Enrichment
**Iteration:** 31 (global)
**Date:** March 2026
**Goal:** Run the full enrichment pipeline on all 1,102 restaurants, load results to Firestore, update the Flutter app to surface enrichment data (ratings, open/closed badges, Google Maps links), and bring README current.

---

## What Phase 7.31 Produces

1. **Full enrichment run** — all 1,102 restaurants through `phase7_enrich.py --all` (resume support auto-skips the 30 already enriched in v7.30).
2. **Firestore update** — all enriched records merged into Firestore via `phase7_load_enriched.py --all`.
3. **App UI updates** — restaurant detail page shows Google rating, open/closed badge, website link, and Google Maps link. Explore page shows enrichment stats.
4. **Validation report** — comprehensive enrichment metrics from `validate_enrichment.py`.
5. **README fully current** — including the v7.30 update that was missed and v7.31 results.

---

## Read Order

```
1. docs/ddd-design-v7.31.md — Architecture, v7.30 results, enrichment schema
2. docs/ddd-plan-v7.31.md — This file. Execution steps.
```

Read both before executing. Log confirmation in build log.

---

## Autonomy Rules

```
1. AUTO-PROCEED between ALL steps. NEVER ask permission. NEVER ask
   "should I continue?" or "would you like me to proceed?" — the answer
   is ALWAYS yes. The plan document IS your permission. Execute it.
2. SELF-HEAL: diagnose → fix → re-run (max 3 attempts per error, then
   log and skip).
3. SYSTEMIC FAILURE RULE: If 3 consecutive restaurants fail with the SAME
   error (e.g., API auth failure, quota exceeded), STOP immediately.
   Fix the root cause. Then restart (resume support skips completed items).
4. Git READ commands allowed. Git WRITE commands and firebase deploy forbidden.
5. flutter build web and flutter run ARE ALLOWED for testing.
6. MCP: Context7 ALLOWED for Python/Flutter/Dart docs. No other MCP servers.
7. MANDATORY ARTIFACTS before session ends:
   a. docs/ddd-build-v7.31.md — FULL session transcript (every command,
      every output, every error, every fix). This is NOT optional.
   b. docs/ddd-report-v7.31.md — metrics, validation, recommendation
   c. README.md — COMPREHENSIVE update at PROJECT ROOT
8. Working directories:
   - Pipeline scripts: cd ~/dev/projects/tripledb/pipeline/
   - Flutter app: cd ~/dev/projects/tripledb/app/
   - README and docs: cd ~/dev/projects/tripledb/
   Navigate between them as needed. Do NOT assume everything is in pipeline/.
9. Google Places API key is in $GOOGLE_PLACES_API_KEY. NEVER hardcode it.
   If the env var is not set, STOP and log — do NOT proceed without it.
```

---

## Step 0: Pre-Flight Checks

```bash
cd ~/dev/projects/tripledb/pipeline

# Standard pre-flight
python3 scripts/pre_flight.py

# Verify Google Places API key
echo "GOOGLE_PLACES_API_KEY set: $([ -n "$GOOGLE_PLACES_API_KEY" ] && echo YES || echo NO)"

# Verify current enrichment state (should show 30 from v7.30)
wc -l data/enriched/restaurants_enriched.jsonl
# Expected: 30

# Verify cache from v7.30
python3 -c "import json; c=json.load(open('data/enriched/places_cache.json')); print(f'Cache entries: {len(c)}')"

# Verify total restaurants
wc -l data/normalized/restaurants.jsonl
# Expected: 1102

# Quick API connectivity test
python3 -c "
import os, requests
key = os.environ.get('GOOGLE_PLACES_API_KEY', '')
r = requests.post(
    'https://places.googleapis.com/v1/places:searchText',
    headers={
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': key,
        'X-Goog-FieldMask': 'places.id,places.displayName'
    },
    json={'textQuery': 'In-N-Out Burger Irvine CA'},
    timeout=10
)
print(f'API test: {r.status_code}')
"

# Verify existing scripts are intact
ls -la scripts/phase7_enrich.py scripts/phase7_load_enriched.py scripts/validate_enrichment.py
```

Log all output. If API test fails, check WARP status and key validity before proceeding.

---

## Step 1: Run Full Enrichment

This is the production run. Resume support auto-skips the 30 restaurants already in `restaurants_enriched.jsonl`.

```bash
cd ~/dev/projects/tripledb/pipeline

python3 scripts/phase7_enrich.py --all
```

**Expected behavior:**
- Loads 1,102 restaurants from `data/normalized/restaurants.jsonl`
- Skips ~30 already enriched
- Processes ~1,072 remaining
- Runtime: ~10-15 minutes (0.15s delay × ~2 API calls × ~1,050 valid restaurants)
- Cache file grows as matches are found

**Monitor for:**
- Consecutive error counter — if it hits 3, the script STOPs automatically
- Rate limit 429 responses — the script handles these with 60s sleep
- Match rate tracking in the summary output

After completion, capture the full summary output in the build log.

---

## Step 2: Validate Enrichment

```bash
cd ~/dev/projects/tripledb/pipeline

python3 scripts/validate_enrichment.py
```

Capture full output. Expected metrics to log:

| Metric | Expected Range |
|--------|---------------|
| Total enriched | 700–750 |
| Match rate | 63–70% |
| Auto-accepted (≥0.85) | 400–500 |
| Review needed | 100–150 |
| No match | 300–400 |
| Coordinate backfills | 35–70 |
| OPERATIONAL | ~90% of enriched |
| CLOSED_PERMANENTLY | ~3–5% of enriched |
| Avg Google rating | ~4.2–4.5 |
| Website URL fill rate | ~60–70% of enriched |

Also run these spot checks:

```bash
# Count enriched records
wc -l data/enriched/restaurants_enriched.jsonl

# Check review log
wc -l data/logs/phase7-review-needed.jsonl

# Check no-match log
wc -l data/logs/phase7-no-match.jsonl

# Sample of highest-rated
python3 -c "
import json
records = [json.loads(l) for l in open('data/enriched/restaurants_enriched.jsonl')]
rated = [r for r in records if r.get('google_rating')]
rated.sort(key=lambda x: x['google_rating'], reverse=True)
print('Top 5 rated:')
for r in rated[:5]:
    print(f'  {r.get(\"google_rating\")} ({r.get(\"google_rating_count\")} reviews) — {r.get(\"restaurant_id\")}')
"

# Sample of permanently closed
python3 -c "
import json
records = [json.loads(l) for l in open('data/enriched/restaurants_enriched.jsonl')]
closed = [r for r in records if r.get('business_status') == 'CLOSED_PERMANENTLY']
print(f'Permanently closed: {len(closed)}')
for r in closed[:10]:
    print(f'  {r.get(\"restaurant_id\")} — {r.get(\"formatted_address\", \"?\")[:60]}')
"
```

---

## Step 3: Load Enrichment to Firestore

```bash
cd ~/dev/projects/tripledb/pipeline

# Dry run first — verify what will be updated
python3 scripts/phase7_load_enriched.py --all --dry-run

# Review dry-run output. If it looks correct, run for real:
python3 scripts/phase7_load_enriched.py --all
```

**Key behavior:**
- Merges enrichment fields into existing Firestore documents (does NOT overwrite dishes, visits, etc.)
- Only backfills lat/lng if the document currently has null coordinates
- Sets `updated_at` timestamp on every enriched document
- Skips documents that already have `enriched_at` set (resume support)

**Verify a few records after load:**

```bash
python3 -c "
import firebase_admin
from firebase_admin import credentials, firestore

if not firebase_admin._apps:
    firebase_admin.initialize_app()
db = firestore.client()

# Count enriched documents
from google.cloud.firestore_v1.base_query import FieldFilter
enriched = db.collection('restaurants').where(filter=FieldFilter('enriched_at', '!=', None)).get()
print(f'Enriched documents in Firestore: {len(enriched)}')

# Sample 3 enriched records
for doc in enriched[:3]:
    d = doc.to_dict()
    print(f\"  {d.get('name')} — Rating: {d.get('google_rating')}, Status: {d.get('business_status')}, Dishes: {len(d.get('dishes', []))}\")

# Verify a non-enriched record still has its data intact
non_enriched = db.collection('restaurants').where(filter=FieldFilter('enriched_at', '==', None)).limit(1).get()
for doc in non_enriched:
    d = doc.to_dict()
    print(f\"  Non-enriched check: {d.get('name')} — Dishes: {len(d.get('dishes', []))}, Visits: {len(d.get('visits', []))}\")
"
```

---

## Step 4: Update Flutter App to Surface Enrichment Data

Navigate to the app directory:

```bash
cd ~/dev/projects/tripledb/app
```

### 4a. Update Restaurant Model

Check `lib/models/restaurant_models.dart`. Add fields if not already present:

```dart
// New enrichment fields
final double? googleRating;
final int? googleRatingCount;
final String? googleMapsUrl;
final String? websiteUrl;
final String? formattedAddress;
final String? businessStatus;
final bool? stillOpen;
```

Ensure the `fromFirestore` factory constructor maps these fields from the Firestore document.

### 4b. Update Restaurant Detail Page

In `lib/pages/restaurant_detail_page.dart`, add:

1. **Google rating badge** — show star icon + rating + review count (e.g., "⭐ 4.6 (1,247 reviews)")
2. **Open/closed status** — green "Open" badge if `stillOpen == true`, red "Permanently Closed" if `stillOpen == false`, nothing if null
3. **Website link** — if `websiteUrl` is not null, show a tappable link
4. **Google Maps link** — if `googleMapsUrl` is not null, show a "View on Google Maps" button
5. **Formatted address** — show `formattedAddress` if available (prefer over raw `city, state`)

Style these consistent with the existing design tokens:
- DDD Red `#DD3333` for closed badges
- DDD Orange `#DA7E12` for rating stars
- Outfit font for headings, Inter for body

### 4c. Update Explore Page

In `lib/pages/explore_page.dart`, add enrichment stats section:

- "**X** restaurants rated on Google" (count of non-null `googleRating`)
- "**X** permanently closed" (count of `stillOpen == false`)
- "Average Google rating: **X.X**"

### 4d. Update Trivia Provider

In `lib/providers/trivia_providers.dart`, add new trivia facts:

- "**X** DDD restaurants are still open today!"
- "The average Google rating of a DDD restaurant is **X.X** ⭐"
- "Guy has visited **X** restaurants that are now permanently closed"

Compute these dynamically from the Firestore data.

### 4e. Build and Verify

```bash
cd ~/dev/projects/tripledb/app

flutter pub get
flutter analyze
flutter build web
```

Both analyze and build must pass. If there are errors, self-heal (fix the code, re-run).

Optionally run `flutter run -d chrome` to visually verify:
- [ ] Restaurant detail page shows rating, status, links
- [ ] Explore page shows enrichment stats
- [ ] Trivia rotates new enrichment facts
- [ ] Non-enriched restaurants still render correctly (null-safe)

Log results.

---

## Step 5: Update README.md

**IMPORTANT:** README is at PROJECT ROOT: `~/dev/projects/tripledb/README.md`

```bash
cd ~/dev/projects/tripledb
```

### 5a. Header

```markdown
# TripleDB

**Every restaurant from Diners, Drive-Ins and Dives — structured, searchable, and mapped.**

🌐 **[tripledb.net](https://tripledb.net)** · 📂 **31 iterations** · 🔧 **Status: Live + Enriched**
```

### 5b. Project Status Table

Update ALL phases through v7.31:

```markdown
| Phase | Name | Status | Iteration |
|-------|------|--------|-----------|
| 0 | Setup & Scaffolding | ✅ Complete | v0.7 |
| 1 | Discovery (30 videos) | ✅ Complete | v1.10 |
| 2 | Calibration (30 videos) | ✅ Complete | v2.11 |
| 3 | Stress Test (30 videos) | ✅ Complete | v3.12 |
| 4 | Validation (30 videos) | ✅ Complete | v4.13 |
| 5 | Production Run (805 videos) | ✅ Complete | v5.14–v5.15 |
| 6 | Firestore + Geocoding + Polish | ✅ Complete | v6.26–v6.29 |
| 8 | Flutter App | ✅ Complete | v8.17–v8.25 |
| 7 | Enrichment | ✅ Complete | v7.30–v7.31 |
```

### 5c. Architecture Diagram

Must show the full pipeline including Google Places API:

```markdown
YouTube Playlist (805 videos)
    ↓ yt-dlp (local)
MP3 Audio
    ↓ faster-whisper large-v3 (local CUDA)
Timestamped Transcripts
    ↓ Gemini 2.5 Flash API (cloud)
Extracted Restaurant JSON
    ↓ Gemini 2.5 Flash API (cloud)
Normalized + Deduplicated JSONL
    ↓ Nominatim (OpenStreetMap)
Geocoded Data
    ↓ Google Places API (New)
Enriched Data (ratings, open/closed, websites, addresses)
    ↓ Firebase Admin SDK
Cloud Firestore
    ↓ Flutter Web
tripledb.net
```

### 5d. Current Metrics

Update with actual numbers from the enrichment run:

```markdown
### Live Dataset (tripledb.net)
- **1,102** unique restaurants across **62** states and territories
- **2,286** dishes with ingredients and Guy's reactions
- **2,336** video appearances from **773** processed YouTube videos
- **~XXX** restaurants enriched with Google ratings, open/closed status, and websites
- **~XXX** restaurants with map coordinates (Nominatim + Google backfill)
- **~XXX** permanently closed restaurants identified
- **432** cross-video dedup merges
```

Replace `~XXX` with actual numbers from validation.

### 5e. IAO Eight Pillars Section

Confirm the section exists (should be there from v6.29). Add v7.30 and v7.31 to the iteration history table:

```markdown
| v7.30 | Enrichment Discovery | ✅ | Google Places API pipeline. 50-restaurant batch. 66.7% match. |
| v7.31 | Enrichment Production | ✅ | Full run on 1,102 restaurants. ~XXX enriched. |
```

### 5f. Changelog

Add TWO entries (v7.30 was missed in the last iteration):

```markdown
**v6.29 → v7.30 (Phase 7 Enrichment Discovery)**
- **Success:** Built Google Places API (New) enrichment pipeline with Text Search → Place Details
  flow, fuzzy match validation (SequenceMatcher ≥0.70), caching, and resume support.
  Discovery batch of 50 restaurants enriched with ratings, open/closed status, and websites.
- **Key finding:** 66.7% match rate. 90% of matched restaurants rated 4.0+. 4 coordinate
  backfills from Google where Nominatim failed.
- **Outcome:** Pipeline validated for v7.31 full production run.

**v7.30 → v7.31 (Phase 7 Enrichment Production)**
- **Success:** [fill from actual results — enriched count, match rate, closed count,
  coordinate backfills, Firestore merge, app UI updates]
- **Key finding:** [most interesting stat from the run]
- **Outcome:** Enrichment complete. tripledb.net shows ratings, open/closed, and links.
```

### 5g. Tech Stack Table

Add Google Places API row:

```markdown
| Enrichment | Google Places API (New) | Ratings, open/closed, websites, addresses |
```

### 5h. Footer

```markdown
*Last updated: Phase 7.31 — Enrichment Production*
```

### 5i. Fix Stale References

Check for and fix:
- "804 videos" → "805 videos"
- "tripleDB.com" → "tripledb.net"
- Any remaining "Ollama" or "Qwen" references for extraction/normalization
- "Phase 1.10" or other outdated phase references in header
- Any reference to enrichment being "pending" or "deferred"

### 5j. Verify After Writing

```bash
cd ~/dev/projects/tripledb
grep "Google Places" README.md | head -3
grep "7.31" README.md | head -3
grep "Last updated" README.md
grep -c "Eight Pillars" README.md   # Should be >= 1
grep "tripledb.net" README.md | head -3
```

---

## Step 6: Generate Artifacts

### docs/ddd-build-v7.31.md (MANDATORY — HARD REQUIREMENT)

This file is the FULL session transcript. It must include:
- Pre-flight output (verbatim)
- Enrichment run output (summary stats at minimum, key milestones)
- Validation output (verbatim)
- Firestore load output (dry-run + live)
- Firestore verification queries and results
- Flutter model/page changes (file names, what was changed)
- `flutter analyze` output
- `flutter build web` output
- README changes (summary of sections updated)
- Any errors encountered and how they were fixed

**Write this file to:** `~/dev/projects/tripledb/docs/ddd-build-v7.31.md`

### docs/ddd-report-v7.31.md (MANDATORY)

Must include:
1. **Full enrichment results** — total enriched, match rate, auto/review/no-match breakdown
2. **Match score distribution** — histogram
3. **Rating distribution** — histogram
4. **Business status breakdown** — OPERATIONAL, CLOSED_PERMANENTLY, CLOSED_TEMPORARILY
5. **Coordinate backfill results** — how many of the ~182 null-coord restaurants gained coordinates
6. **API cost** — confirm $0 or actual cost
7. **Comparison: v7.30 discovery vs v7.31 production** — did the match rate hold?
8. **Firestore merge verification** — enriched count, integrity confirmed
9. **App UI updates** — what was added, build status
10. **Sample enriched records** — 5 high-confidence, 3 edge cases
11. **Known issues / remaining gaps** — unmatched restaurants, data quality notes
12. **Human interventions:** count (target: 0)
13. **Gemini's Recommendation:** What should the next iteration focus on?
14. **README Update Confirmation:** ALL sections confirmed updated

**Write this file to:** `~/dev/projects/tripledb/docs/ddd-report-v7.31.md`

**These artifacts + README update are the FINAL actions. Do NOT end the session without all three.**

---

## Success Criteria

```
[ ] Pre-flight passes (including API connectivity)
[ ] Full enrichment run completed (--all mode, resume skips v7.30 batch)
[ ] Enrichment metrics within expected ranges:
    [ ] Total enriched: 650–750
    [ ] Match rate: 60–70%
    [ ] Coordinate backfills: ≥ 20
    [ ] Errors: ≤ 5
    [ ] API cost: $0
[ ] Firestore merge completed:
    [ ] All enriched records loaded
    [ ] Existing data (dishes, visits) preserved
    [ ] Null coordinates backfilled where Google had data
[ ] Flutter app updated:
    [ ] Restaurant model includes enrichment fields
    [ ] Detail page shows rating, status, website, Google Maps link
    [ ] Explore page shows enrichment stats
    [ ] Trivia includes enrichment facts
    [ ] flutter analyze: 0 errors
    [ ] flutter build web: success
[ ] README.md COMPREHENSIVELY updated at project root:
    [ ] Phase 7 status: ✅ Complete
    [ ] Architecture includes Google Places API
    [ ] Current metrics updated with enrichment stats
    [ ] IAO iteration history includes v7.30 and v7.31
    [ ] Changelog entries for BOTH v7.30 and v7.31
    [ ] Tech stack includes Google Places API
    [ ] Footer: Phase 7.31
    [ ] All stale references fixed
[ ] ddd-build-v7.31.md generated (FULL transcript)
[ ] ddd-report-v7.31.md generated
[ ] Human interventions: 0
```

---

## GEMINI.md Update

Before launching, update `pipeline/GEMINI.md` to:

```markdown
# TripleDB Pipeline — Agent Instructions

## Current Iteration: 7.31

IMPORTANT: Read documents in this EXACT order before executing:

1. ../docs/ddd-design-v7.31.md — Architecture, v7.30 results, enrichment schema
2. ../docs/ddd-plan-v7.31.md — Production enrichment + app updates + README

Do NOT begin execution until both files have been read.

## Rules That Never Change
- Git READ commands allowed (pull, log, status, diff, show)
- Git WRITE commands forbidden (add, commit, push, checkout, branch)
- firebase deploy forbidden — Kyle deploys manually
- flutter build web and flutter run ARE ALLOWED for testing
- NEVER ask permission — auto-proceed on EVERY step
- Context7 MCP allowed. No other MCP servers.
- MUST produce ddd-build-v7.31.md AND ddd-report-v7.31.md before ending
- ddd-build-v7.31.md must be a FULL session transcript — not a summary
- README.md is at PROJECT ROOT (~/dev/projects/tripledb/README.md)
- Pipeline scripts run from pipeline/ directory
- Flutter app runs from app/ directory
- Google Places API key: $GOOGLE_PLACES_API_KEY (never hardcode)
```

---

## Launch Sequence

```bash
# 1. Archive previous iteration
cd ~/dev/projects/tripledb
mv docs/ddd-design-v7.30.md docs/archive/ 2>/dev/null
mv docs/ddd-plan-v7.30.md docs/archive/ 2>/dev/null
mv docs/ddd-report-v7.30.md docs/archive/ 2>/dev/null
mv docs/ddd-build-v7.30.md docs/archive/ 2>/dev/null

# 2. Place new docs
cp /path/to/ddd-design-v7.31.md docs/
cp /path/to/ddd-plan-v7.31.md docs/

# 3. Ensure Google Places API key is set
echo $GOOGLE_PLACES_API_KEY   # Should not be empty

# 4. Update GEMINI.md
nano pipeline/GEMINI.md

# 5. Commit the setup
git add .
git commit -m "KT starting 7.31"

# 6. Launch (in Konsole, NOT IDE terminal)
cd pipeline
gemini
```

Then type:

```
Read GEMINI.md and execute.
```

---

## After v7.31

Once completed, reviewed, and committed:

```bash
# Commit
cd ~/dev/projects/tripledb
git add .
git commit -m "KT completed 7.31 and README updated"
git push

# Deploy
cd app
flutter build web
firebase deploy --only hosting
```

tripledb.net will then show Google ratings, open/closed status, website links, and Google Maps links for all enriched restaurants. The next iteration could focus on:
- **v7.32:** Review the ~100-150 restaurants in the review bucket (0.70-0.84 match scores) — manual or refined search queries
- **Flutter enhancements:** Sort by rating, filter by "still open", Google Maps deep links on map pins
- **Photo integration:** Fetch actual photo URLs from photo_references (requires Places Photos API calls)
- **Remaining 186→~130 null coordinates:** Try alternative geocoding or manual lookup
