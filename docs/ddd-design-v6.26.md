# TripleDB — Design v6.26

---

# Part 1: What This Iteration Does

v6.26 is the convergence iteration — the data pipeline meets the frontend. Three objectives:

1. **Quality fixes** — resolve 126 UNKNOWN states via city-name inference, review dedup quality
2. **Firestore load** — push 1,102 normalized restaurants + 773 videos into Cloud Firestore
3. **App wiring** — swap the sample JSON provider for a Firestore provider, redeploy tripledb.net

After v6.26, tripledb.net serves live data from the full 805-video pipeline.

## Current State

### Pipeline (After v5.15 Production Run)
- 778/805 videos downloaded
- 774 transcribed (4 marathons exceeded 600s timeout — accepted)
- 773 extracted
- 1,102 unique restaurants after normalization (432 dedup merges)
- 2,286 dishes, 2,336 visits, 63 states
- Data quality: 98% guy_intro, 98% guy_response, 100% ingredients, 11.9% null owner_chef

### Quality Issues to Fix
- **126 UNKNOWN states** (11.4%) — most resolvable from city names
- **42 null-name records** — already filtered from normalized output
- **"UNKNOWN" appearing twice** in state distribution — display bug in counter (same 126 records)

### App (After v8.25 QA)
- Live at tripledb.net with sample data (50 restaurants)
- Design tokens applied (DDD red/orange, Outfit + Inter)
- All 8 component patterns implemented
- Lighthouse: Accessibility 92, SEO 100
- Running against `assets/data/sample_restaurants.jsonl`

### Firestore
- Project: `tripledb-e0f77`
- Collections needed: `restaurants`, `videos`
- Schema: matches normalized JSONL structure (defined in pipeline design docs)

## Phase Mapping

| IAO Iteration | Phase | Focus | Status |
|---|---|---|---|
| v0.7–v4.13 | 0-4 | Pipeline iterative refinement (Group A) | ✅ Complete |
| v5.14–v5.15 | 5 | Production run (Group B) | ✅ Complete |
| v6.26 | 6 | Quality fixes + Firestore load + App wiring | 🔧 Current |
| v8.17–v8.25 | 8 | Flutter app build (two passes) | ✅ Complete |
| v7.27+ | 7 | Enrichment (geocode, ratings, open/closed) | ⏳ Deferred |

## Artifact Spec

| Direction | File | Author | Mandatory |
|-----------|------|--------|-----------|
| Input | `docs/ddd-design-v6.26.md` | Claude | ✅ |
| Input | `docs/ddd-plan-v6.26.md` | Claude | ✅ |
| Output | `docs/ddd-build-v6.26.md` | Gemini | ✅ HARD REQUIREMENT |
| Output | `docs/ddd-report-v6.26.md` | Gemini | ✅ HARD REQUIREMENT |

## Agent Restrictions

```
1. Git READ commands allowed (pull, log, status, diff, show).
   Git WRITE commands forbidden (add, commit, push, checkout, branch).
   firebase deploy forbidden (Kyle deploys manually).
2. flutter build web IS ALLOWED for testing.
3. NEVER ask permission — the plan IS the permission.
4. Self-heal errors: diagnose → fix → re-run (max 3 attempts, then skip).
5. MCP: Context7 ALLOWED. No other MCP servers needed.
6. EVERY session ends with ddd-build and ddd-report artifacts. No exceptions.
7. Work spans BOTH pipeline/ and app/ directories this iteration.
```

---

# Part 2: Firestore Schema

## Collection: `restaurants`

Document ID: `restaurant_id` field value (e.g., `r_d0ab62fe2a03`)

```json
{
  "restaurant_id": "r_d0ab62fe2a03",
  "name": "Desert Oak Barbecue",
  "city": "El Paso",
  "state": "TX",
  "address": null,
  "latitude": null,
  "longitude": null,
  "cuisine_type": "Barbecue",
  "owner_chef": "Rich Funk and Suzanne",
  "still_open": null,
  "google_rating": null,
  "yelp_rating": null,
  "website_url": null,
  "visits": [...],
  "dishes": [...],
  "created_at": "<timestamp>",
  "updated_at": "<timestamp>"
}
```

Null fields are stored as null in Firestore. The app handles nulls gracefully — no-op buttons for missing URLs, hidden sections for missing ratings.

## Collection: `videos`

Document ID: `video_id` field value (e.g., `Q2fk6b-hEbc`)

```json
{
  "video_id": "Q2fk6b-hEbc",
  "youtube_url": "https://youtube.com/watch?v=Q2fk6b-hEbc",
  "title": "Top #DDD Videos in Memphis",
  "duration_seconds": 1619,
  "video_type": "compilation",
  "restaurant_count": 5,
  "processed_at": "<timestamp>"
}
```

---

# Part 3: State Inference Strategy

The 126 UNKNOWN-state restaurants can be resolved by:

1. **City-name lookup** — a mapping of well-known US cities to states:
   - "Reno" → NV, "Boston" → MA, "Key Largo" → FL, "Memphis" → TN
   - "Minneapolis" → MN, "Atlanta" → GA, "Philadelphia" → PA
   - Cover the top 200 US cities and this resolves 80%+ of unknowns

2. **Video title parsing** — many compilation titles contain state names:
   - "Top #DDD Videos in Tennessee" → restaurants in that video get TN
   - "Best of El Paso" → TX

3. **Remaining unknowns** — any that can't be resolved stay as "UNKNOWN"
   and are displayed in the app without a state filter match

The fix goes in `scripts/phase4_normalize.py` as an additional pass AFTER dedup, BEFORE writing output. It does NOT re-run extraction — only patches the normalized JSONL.

---

# Part 4: App Provider Swap

The app currently loads data from:
```
assets/data/sample_restaurants.jsonl (50 records)
```

After Firestore load, it should read from:
```
Cloud Firestore → restaurants collection (1,102 records)
```

The swap is in `lib/services/data_service.dart` — replace the JSON asset loader with a Firestore query. The Riverpod providers upstream of this service don't change. The UI doesn't change. Only the data source changes.

### Required Package
```yaml
# Add to app/pubspec.yaml
dependencies:
  cloud_firestore: ^5.0.0
  firebase_core: ^3.0.0
```

### Firebase Config
The app needs `firebase_options.dart` generated by FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=tripledb-e0f77
```

This creates the platform config files. Run from `app/`.

## GEMINI.md Template

```markdown
# TripleDB — Agent Instructions

## Current Iteration: 6.26

IMPORTANT: Read documents in this EXACT order before executing:

1. docs/ddd-design-v6.26.md — Architecture, Firestore schema, state inference
2. docs/ddd-plan-v6.26.md — Execution steps

Do NOT begin execution until both files have been read.

## Rules That Never Change
- Git READ commands allowed (pull, log, status, diff, show)
- Git WRITE commands forbidden (add, commit, push, checkout, branch)
- firebase deploy forbidden — Kyle deploys manually
- flutter build web IS ALLOWED for testing
- NEVER ask permission — auto-proceed on EVERY step
- Context7 MCP allowed. No other MCP servers.
- MUST produce ddd-build-v6.26.md AND ddd-report-v6.26.md before ending
- This iteration spans pipeline/ AND app/ directories
```
