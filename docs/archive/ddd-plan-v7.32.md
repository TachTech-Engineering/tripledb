# TripleDB — Phase 7 Plan v7.32

**Phase:** 7 — Enrichment
**Iteration:** 32 (global)
**Date:** March 2026
**Goal:** Recover enrichment for the 462 no-match restaurants using refined search queries (Part A), then verify the 253 review-bucket matches using Gemini Flash LLM validation (Part B). Load new enrichments to Firestore, remove false positives, and update app metrics.

---

## What Phase 7.32 Produces

1. **`scripts/phase7_refine.py`** — Multi-pass refined search for no-match restaurants using owner/chef, cuisine, and DDD-aware query patterns.
2. **`scripts/phase7_verify_reviews.py`** — Gemini Flash LLM verification of the 253 medium-confidence matches. Classifies as YES/NO/UNCERTAIN.
3. **Refined enrichment results** — estimated 70–115 newly matched restaurants from 462 no-matches.
4. **Verified review bucket** — ~200 confirmed correct, ~30 false positives removed, ~23 flagged for manual review.
5. **Firestore updates** — new enrichments merged, false positives cleaned.
6. **Updated app metrics** — explore page and trivia reflect final enrichment counts.

---

## Read Order

```
1. docs/ddd-design-v7.32.md — Architecture, refinement strategy, v7.31 state
2. docs/ddd-plan-v7.32.md — This file. Execution steps.
```

Read both before executing. Log confirmation in build log.

---

## Autonomy Rules

```
1. AUTO-PROCEED between ALL steps. NEVER ask permission.
2. SELF-HEAL: diagnose → fix → re-run (max 3 attempts, then skip).
3. SYSTEMIC FAILURE: 3 consecutive identical errors = STOP, fix, restart.
4. Git READ allowed. Git WRITE and firebase deploy FORBIDDEN.
5. flutter build web and flutter run ARE ALLOWED.
6. MCP: Context7 ALLOWED. No other MCP servers.
7. MANDATORY ARTIFACTS before session ends:
   a. docs/ddd-build-v7.32.md — FULL transcript (every command, every output)
   b. docs/ddd-report-v7.32.md — metrics, verification results, recommendation
   c. README.md — COMPREHENSIVE update at PROJECT ROOT
8. Working directories:
   - Pipeline: ~/dev/projects/tripledb/pipeline/
   - App: ~/dev/projects/tripledb/app/
   - README/docs: ~/dev/projects/tripledb/
9. API keys:
   - $GOOGLE_PLACES_API_KEY — for Places API calls
   - $GEMINI_API_KEY — for Gemini Flash verification calls
   If EITHER is not set, print the exact missing variable name and HALT.
   Do NOT ask the human interactively. They will see the error and re-run.
```

---

## Step 0: Pre-Flight Checks

```bash
cd ~/dev/projects/tripledb/pipeline

# Standard pre-flight
python3 scripts/pre_flight.py

# Verify both API keys are set
echo "GOOGLE_PLACES_API_KEY: $([ -n "$GOOGLE_PLACES_API_KEY" ] && echo SET || echo MISSING)"
echo "GEMINI_API_KEY: $([ -n "$GEMINI_API_KEY" ] && echo SET || echo MISSING)"

# If either is MISSING, print this and HALT:
# "ERROR: Required environment variable(s) not set. Export them and re-run."
# Do NOT continue. Do NOT ask the human.

# Verify enrichment state from v7.31
wc -l data/enriched/restaurants_enriched.jsonl
# Expected: 625

wc -l data/logs/phase7-no-match.jsonl
# Expected: 462

wc -l data/logs/phase7-review-needed.jsonl
# Expected: 253

# Verify normalized data is accessible
wc -l data/normalized/restaurants.jsonl
# Expected: 1102

# Quick Places API connectivity test
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
print(f'Places API: {r.status_code}')
"

# Quick Gemini API connectivity test
python3 -c "
import os, requests
key = os.environ.get('GEMINI_API_KEY', '')
r = requests.post(
    f'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={key}',
    headers={'Content-Type': 'application/json'},
    json={'contents': [{'parts': [{'text': 'Reply with only: OK'}]}]},
    timeout=10
)
print(f'Gemini API: {r.status_code}')
"
```

Log all output. If either API test fails, HALT with a clear error message.

---

## Step 1: Create `scripts/phase7_refine.py` (Part A — No-Match Refinement)

Write the refined search script. It reads `data/logs/phase7-no-match.jsonl`, cross-references the full restaurant data from `data/normalized/restaurants.jsonl` to get owner_chef and cuisine_type, then runs up to 4 search passes per restaurant.

### Core Logic

```python
#!/usr/bin/env python3
"""
phase7_refine.py — Refined Google Places search for no-match restaurants.

Reads the no-match log from v7.31 and tries alternative query patterns
to recover matches that the original name+city+state search missed.

Usage:
    python3 scripts/phase7_refine.py
    python3 scripts/phase7_refine.py --dry-run
"""
import argparse, json, os, sys, time
from datetime import datetime, timezone
from difflib import SequenceMatcher
from pathlib import Path
import requests

API_KEY = os.environ.get("GOOGLE_PLACES_API_KEY", "")
SEARCH_URL = "https://places.googleapis.com/v1/places:searchText"
DETAIL_URL = "https://places.googleapis.com/v1/places/{place_id}"

SEARCH_FIELDS = "places.id,places.displayName,places.formattedAddress,places.location"
DETAIL_FIELDS = (
    "id,displayName,formattedAddress,location,rating,userRatingCount,"
    "websiteUri,currentOpeningHours,businessStatus,googleMapsUri,photos"
)

MATCH_THRESHOLD = 0.70
REQUEST_DELAY = 0.15
REQUEST_TIMEOUT = 15

NO_MATCH_LOG = Path("data/logs/phase7-no-match.jsonl")
NORMALIZED_PATH = Path("data/normalized/restaurants.jsonl")
ENRICHED_PATH = Path("data/enriched/restaurants_enriched.jsonl")
CACHE_PATH = Path("data/enriched/places_cache.json")
LOG_DIR = Path("data/logs")

def fuzzy_match(a: str, b: str) -> float:
    return SequenceMatcher(None, a.lower().strip(), b.lower().strip()).ratio()

def search_place(query: str) -> dict | None:
    """Single Text Search call. Returns first result or None."""
    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": API_KEY,
        "X-Goog-FieldMask": SEARCH_FIELDS,
    }
    try:
        resp = requests.post(
            SEARCH_URL,
            headers=headers,
            json={"textQuery": query},
            timeout=REQUEST_TIMEOUT,
        )
        if resp.status_code == 429:
            print("    Rate limited. Sleeping 60s...")
            time.sleep(60)
            resp = requests.post(SEARCH_URL, headers=headers,
                                json={"textQuery": query}, timeout=REQUEST_TIMEOUT)
        if resp.status_code != 200:
            return None
        places = resp.json().get("places", [])
        return places[0] if places else None
    except Exception as e:
        print(f"    Search error: {e}")
        return None

def get_details(place_id: str) -> dict | None:
    """Fetch Place Details for a matched place."""
    resource = place_id if place_id.startswith("places/") else f"places/{place_id}"
    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": API_KEY,
        "X-Goog-FieldMask": DETAIL_FIELDS,
    }
    try:
        resp = requests.get(f"https://places.googleapis.com/v1/{resource}",
                           headers=headers, timeout=REQUEST_TIMEOUT)
        if resp.status_code == 429:
            time.sleep(60)
            resp = requests.get(f"https://places.googleapis.com/v1/{resource}",
                               headers=headers, timeout=REQUEST_TIMEOUT)
        return resp.json() if resp.status_code == 200 else None
    except Exception as e:
        print(f"    Details error: {e}")
        return None

def build_queries(restaurant: dict) -> list[tuple[int, str]]:
    """Build up to 4 query variants. Returns list of (pass_number, query_string)."""
    name = restaurant.get("name", "")
    city = restaurant.get("city", "") or ""
    state = restaurant.get("state", "") or ""
    owner = restaurant.get("owner_chef", "") or ""
    cuisine = restaurant.get("cuisine_type", "") or ""

    # Clean null-like values
    if city.lower() in ("none", "null", "unknown", "n/a", ""):
        city = ""
    if owner.lower() in ("none", "null", "unknown", "n/a", ""):
        owner = ""
    if cuisine.lower() in ("none", "null", "unknown", "n/a", ""):
        cuisine = ""

    queries = []

    # Pass 1: Exact name in quotes with city and state
    if city:
        queries.append((1, f'"{name}" "{city}" {state}'))
    else:
        queries.append((1, f'"{name}" {state} restaurant'))

    # Pass 2: Owner/chef name (often more unique than restaurant name)
    if owner:
        if city:
            queries.append((2, f'"{owner}" restaurant {city} {state}'))
        else:
            queries.append((2, f'"{owner}" restaurant {state}'))

    # Pass 3: Name + cuisine + state (for null-city records)
    if cuisine:
        queries.append((3, f'"{name}" {cuisine} {state}'))

    # Pass 4: DDD-aware search (Google indexes show appearances)
    queries.append((4, f'"{name}" Diners Drive-Ins and Dives'))

    return queries

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    if not API_KEY:
        print("ERROR: GOOGLE_PLACES_API_KEY not set. HALTING.")
        sys.exit(1)

    # Load no-match records
    no_match_ids = set()
    if NO_MATCH_LOG.exists():
        with open(NO_MATCH_LOG) as f:
            for line in f:
                line = line.strip()
                if line:
                    rec = json.loads(line)
                    no_match_ids.add(rec.get("restaurant_id", rec.get("name", "")))
    print(f"No-match records to refine: {len(no_match_ids)}")

    # Load full restaurant data (for owner_chef, cuisine_type)
    all_restaurants = {}
    with open(NORMALIZED_PATH) as f:
        for line in f:
            line = line.strip()
            if line:
                r = json.loads(line)
                all_restaurants[r.get("restaurant_id", "")] = r

    # Filter to no-match restaurants with full data
    targets = []
    for rid in no_match_ids:
        if rid in all_restaurants:
            targets.append(all_restaurants[rid])
    print(f"Targets with full data: {len(targets)}")

    # Check for already-refined records (resume support)
    refined_log = LOG_DIR / "phase7-refined-matches.jsonl"
    already_refined = set()
    if refined_log.exists():
        with open(refined_log) as f:
            for line in f:
                if line.strip():
                    already_refined.add(json.loads(line).get("restaurant_id", ""))
    final_no_match_log = LOG_DIR / "phase7-final-no-match.jsonl"
    already_final = set()
    if final_no_match_log.exists():
        with open(final_no_match_log) as f:
            for line in f:
                if line.strip():
                    already_final.add(json.loads(line).get("restaurant_id", ""))
    skip_ids = already_refined | already_final
    remaining = [r for r in targets if r.get("restaurant_id") not in skip_ids]
    print(f"Already processed: {len(skip_ids)}, Remaining: {len(remaining)}")

    if args.dry_run:
        print(f"\n[DRY RUN] Would attempt refined search on {len(remaining)} restaurants.")
        # Show a few sample queries
        for r in remaining[:3]:
            queries = build_queries(r)
            print(f"  {r['name']} ({r.get('city')}, {r.get('state')}):")
            for pn, q in queries:
                print(f"    Pass {pn}: {q}")
        return

    # Prepare output files
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    refined_file = open(refined_log, "a")
    final_file = open(final_no_match_log, "a")
    enriched_file = open(ENRICHED_PATH, "a")

    cache = json.loads(CACHE_PATH.read_text()) if CACHE_PATH.exists() else {}

    stats = {"refined": 0, "still_no_match": 0, "error": 0,
             "coord_backfill": 0, "by_pass": {1: 0, 2: 0, 3: 0, 4: 0}}
    consecutive_errors = 0

    try:
        for i, restaurant in enumerate(remaining):
            rid = restaurant.get("restaurant_id", "?")
            name = restaurant.get("name", "?")
            print(f"[{i+1}/{len(remaining)}] {name} ({restaurant.get('city')}, {restaurant.get('state')})")

            queries = build_queries(restaurant)
            matched = False

            for pass_num, query in queries:
                time.sleep(REQUEST_DELAY)
                result = search_place(query)

                if not result:
                    continue

                google_name = result.get("displayName", {}).get("text", "")
                score = fuzzy_match(name, google_name)

                if score >= MATCH_THRESHOLD:
                    # Got a match — fetch details
                    time.sleep(REQUEST_DELAY)
                    place_id = result.get("id", "")
                    details = get_details(place_id)

                    if details:
                        location = details.get("location", {})
                        photos = details.get("photos", [])

                        enriched = {
                            "restaurant_id": rid,
                            "google_place_id": place_id,
                            "google_rating": details.get("rating"),
                            "google_rating_count": details.get("userRatingCount"),
                            "google_maps_url": details.get("googleMapsUri"),
                            "website_url": details.get("websiteUri"),
                            "formatted_address": details.get("formattedAddress"),
                            "business_status": details.get("businessStatus"),
                            "still_open": {"OPERATIONAL": True, "CLOSED_TEMPORARILY": True,
                                          "CLOSED_PERMANENTLY": False}.get(details.get("businessStatus")),
                            "photo_references": [p.get("name", "") for p in photos[:3]],
                            "latitude": location.get("latitude"),
                            "longitude": location.get("longitude"),
                            "enriched_at": datetime.now(timezone.utc).isoformat(),
                            "enrichment_source": "google_places_api",
                            "enrichment_match_score": round(score, 3),
                            "enrichment_query_pass": pass_num,
                        }

                        # Coordinate backfill check
                        if enriched.get("latitude") and not restaurant.get("latitude"):
                            stats["coord_backfill"] += 1

                        enriched_file.write(json.dumps(enriched) + "\n")
                        enriched_file.flush()
                        refined_file.write(json.dumps({"restaurant_id": rid,
                            "name": name, "pass": pass_num, "score": round(score, 3),
                            "google_name": google_name}) + "\n")
                        refined_file.flush()

                        stats["refined"] += 1
                        stats["by_pass"][pass_num] += 1
                        print(f"    ✅ Matched on pass {pass_num} (score: {score:.3f}) → {google_name}")
                        matched = True
                        consecutive_errors = 0
                        break

            if not matched:
                final_file.write(json.dumps({"restaurant_id": rid, "name": name,
                    "city": restaurant.get("city"), "state": restaurant.get("state")}) + "\n")
                final_file.flush()
                stats["still_no_match"] += 1
                print(f"    ❌ No match after {len(queries)} passes")
                consecutive_errors = 0

    finally:
        refined_file.close()
        final_file.close()
        enriched_file.close()
        CACHE_PATH.write_text(json.dumps(cache, indent=2))

    total = stats["refined"] + stats["still_no_match"] + stats["error"]
    print(f"\n{'='*50}")
    print(f"Refinement Complete")
    print(f"{'='*50}")
    print(f"  Total processed:     {total}")
    print(f"  Newly matched:       {stats['refined']}")
    print(f"  Still no match:      {stats['still_no_match']}")
    print(f"  Errors:              {stats['error']}")
    print(f"  Coord backfills:     {stats['coord_backfill']}")
    print(f"  By pass: 1={stats['by_pass'][1]}, 2={stats['by_pass'][2]}, "
          f"3={stats['by_pass'][3]}, 4={stats['by_pass'][4]}")
    if total > 0:
        print(f"  Recovery rate:       {stats['refined']/total*100:.1f}%")

if __name__ == "__main__":
    main()
```

**Implementation notes for Gemini:**
- The script above is a REFERENCE. Write it to `scripts/phase7_refine.py`, adapting as needed.
- The no-match log (`phase7-no-match.jsonl`) from v7.31 may contain just `restaurant_id` and `name`, so the script must cross-reference `restaurants.jsonl` for owner_chef and cuisine_type.
- New matches get APPENDED to `restaurants_enriched.jsonl` (same file as v7.31 results).
- Resume support: track which restaurant_ids have been processed in `phase7-refined-matches.jsonl` and `phase7-final-no-match.jsonl`.

---

## Step 2: Run Part A — Refined Search

```bash
cd ~/dev/projects/tripledb/pipeline

# Dry run first
python3 scripts/phase7_refine.py --dry-run

# If dry run looks correct, run for real
python3 scripts/phase7_refine.py
```

**Expected runtime:** ~5-10 minutes. Each restaurant tries up to 4 search passes (0.15s each) = 0.6s per restaurant × 462 = ~4.6 minutes of API time + overhead.

After completion, verify:

```bash
# Newly matched
wc -l data/logs/phase7-refined-matches.jsonl

# Final no-match (truly unresolvable)
wc -l data/logs/phase7-final-no-match.jsonl

# Total enriched now (should be 625 + newly matched)
wc -l data/enriched/restaurants_enriched.jsonl

# Which passes were most effective?
python3 -c "
import json
matches = [json.loads(l) for l in open('data/logs/phase7-refined-matches.jsonl')]
from collections import Counter
passes = Counter(m.get('pass') for m in matches)
for p in sorted(passes):
    print(f'  Pass {p}: {passes[p]} matches')
print(f'  Total: {len(matches)}')
"
```

### Expected Targets

| Metric | Target | Acceptable |
|--------|--------|------------|
| Newly matched | 70–115 | ≥ 50 |
| Recovery rate | 15–25% | ≥ 10% |
| Pass 1 (exact quotes) | Most effective | — |
| Pass 2 (owner/chef) | Second most | — |
| Coord backfills | ≥ 5 | ≥ 2 |

---

## Step 3: Create `scripts/phase7_verify_reviews.py` (Part B — Review Verification)

Write the LLM verification script. It reads `data/logs/phase7-review-needed.jsonl`, loads the corresponding enrichment data from `restaurants_enriched.jsonl`, and sends each record to Gemini Flash for validation.

### Core Logic

```python
#!/usr/bin/env python3
"""
phase7_verify_reviews.py — Verify review-bucket matches using Gemini Flash.

Reads the 253 review-needed records, compares our data with the Google match,
and asks Gemini Flash whether they're the same restaurant.

Usage:
    python3 scripts/phase7_verify_reviews.py
    python3 scripts/phase7_verify_reviews.py --dry-run
"""
import argparse, json, os, sys, time
from pathlib import Path
import requests

GEMINI_KEY = os.environ.get("GEMINI_API_KEY", "")
GEMINI_URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"

REVIEW_LOG = Path("data/logs/phase7-review-needed.jsonl")
ENRICHED_PATH = Path("data/enriched/restaurants_enriched.jsonl")
NORMALIZED_PATH = Path("data/normalized/restaurants.jsonl")
LOG_DIR = Path("data/logs")

VERIFY_DELAY = 1.0  # 1 second between Gemini calls (rate limit courtesy)

def ask_gemini(prompt: str) -> str:
    """Send a prompt to Gemini Flash. Returns response text or 'ERROR'."""
    try:
        resp = requests.post(
            f"{GEMINI_URL}?key={GEMINI_KEY}",
            headers={"Content-Type": "application/json"},
            json={
                "contents": [{"parts": [{"text": prompt}]}],
                "generationConfig": {"maxOutputTokens": 100, "temperature": 0.1}
            },
            timeout=15,
        )
        if resp.status_code == 429:
            print("    Gemini rate limited. Sleeping 30s...")
            time.sleep(30)
            resp = requests.post(
                f"{GEMINI_URL}?key={GEMINI_KEY}",
                headers={"Content-Type": "application/json"},
                json={
                    "contents": [{"parts": [{"text": prompt}]}],
                    "generationConfig": {"maxOutputTokens": 100, "temperature": 0.1}
                },
                timeout=15,
            )
        if resp.status_code != 200:
            return "ERROR"
        data = resp.json()
        text = data.get("candidates", [{}])[0].get("content", {}).get("parts", [{}])[0].get("text", "")
        return text.strip()
    except Exception as e:
        print(f"    Gemini error: {e}")
        return "ERROR"

def classify_response(response: str) -> str:
    """Parse Gemini's response into YES/NO/UNCERTAIN."""
    upper = response.upper()
    if upper.startswith("YES"):
        return "YES"
    elif upper.startswith("NO"):
        return "NO"
    elif upper.startswith("UNCERTAIN"):
        return "UNCERTAIN"
    # Try to find the classification in the response
    if "YES" in upper and "NO" not in upper:
        return "YES"
    if "NO" in upper and "YES" not in upper:
        return "NO"
    return "UNCERTAIN"

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    if not GEMINI_KEY:
        print("ERROR: GEMINI_API_KEY not set. HALTING.")
        sys.exit(1)

    # Load review-needed records (restaurant_ids)
    review_ids = []
    if REVIEW_LOG.exists():
        with open(REVIEW_LOG) as f:
            for line in f:
                if line.strip():
                    rec = json.loads(line)
                    review_ids.append(rec.get("restaurant_id", ""))
    review_ids = list(set(review_ids))  # dedupe
    print(f"Review-needed records: {len(review_ids)}")

    # Load enriched data (indexed by restaurant_id)
    enriched_map = {}
    with open(ENRICHED_PATH) as f:
        for line in f:
            if line.strip():
                r = json.loads(line)
                enriched_map[r.get("restaurant_id", "")] = r

    # Load normalized data (for our restaurant details)
    normalized_map = {}
    with open(NORMALIZED_PATH) as f:
        for line in f:
            if line.strip():
                r = json.loads(line)
                normalized_map[r.get("restaurant_id", "")] = r

    # Resume support
    verified_log = LOG_DIR / "phase7-verified.jsonl"
    already_verified = set()
    if verified_log.exists():
        with open(verified_log) as f:
            for line in f:
                if line.strip():
                    already_verified.add(json.loads(line).get("restaurant_id", ""))
    remaining = [rid for rid in review_ids if rid not in already_verified]
    print(f"Already verified: {len(already_verified)}, Remaining: {len(remaining)}")

    if args.dry_run:
        print(f"\n[DRY RUN] Would verify {len(remaining)} review-bucket records.")
        return

    LOG_DIR.mkdir(parents=True, exist_ok=True)
    verified_file = open(verified_log, "a")
    false_pos_file = open(LOG_DIR / "phase7-false-positives.jsonl", "a")

    stats = {"yes": 0, "no": 0, "uncertain": 0, "error": 0, "missing": 0}

    try:
        for i, rid in enumerate(remaining):
            ours = normalized_map.get(rid, {})
            theirs = enriched_map.get(rid, {})

            if not ours or not theirs:
                stats["missing"] += 1
                print(f"[{i+1}/{len(remaining)}] {rid} — MISSING DATA, skipping")
                continue

            our_name = ours.get("name", "?")
            our_city = ours.get("city", "?")
            our_state = ours.get("state", "?")
            our_cuisine = ours.get("cuisine_type", "?")
            our_owner = ours.get("owner_chef", "?")

            google_address = theirs.get("formatted_address", "?")
            google_rating = theirs.get("google_rating", "?")
            match_score = theirs.get("enrichment_match_score", "?")

            # For display, try to extract what Google called it
            # (Not directly in enriched data, but we can infer from formatted_address)
            google_place_id = theirs.get("google_place_id", "?")

            prompt = f"""I need to verify if a Google Places result matches a restaurant from the TV show "Diners, Drive-Ins and Dives."

Our database record:
- Name: {our_name}
- City: {our_city}
- State: {our_state}
- Cuisine: {our_cuisine}
- Owner/Chef: {our_owner}

Google Places result:
- Address: {google_address}
- Rating: {google_rating} stars
- Match score: {match_score} (fuzzy name similarity)

Are these the same restaurant? Consider that:
- The restaurant may have changed names slightly since the show aired
- The address should be in or near the listed city
- A mismatch in state is almost certainly wrong

Answer with ONLY one of: YES, NO, or UNCERTAIN
Then provide ONE sentence of reasoning."""

            print(f"[{i+1}/{len(remaining)}] {our_name} ({our_city}, {our_state}) — score: {match_score}")

            time.sleep(VERIFY_DELAY)
            response = ask_gemini(prompt)

            if response == "ERROR":
                stats["error"] += 1
                print(f"    🔴 Error")
                continue

            classification = classify_response(response)
            stats[classification.lower()] += 1

            result = {
                "restaurant_id": rid,
                "name": our_name,
                "classification": classification,
                "match_score": match_score,
                "gemini_response": response[:200],
            }

            if classification == "NO":
                # False positive — log for removal
                false_pos_file.write(json.dumps(result) + "\n")
                false_pos_file.flush()
                print(f"    ❌ NO — {response[:80]}")
            elif classification == "YES":
                print(f"    ✅ YES — {response[:80]}")
            else:
                print(f"    ❓ UNCERTAIN — {response[:80]}")

            verified_file.write(json.dumps(result) + "\n")
            verified_file.flush()

    finally:
        verified_file.close()
        false_pos_file.close()

    total = sum(stats.values())
    print(f"\n{'='*50}")
    print(f"Review Verification Complete")
    print(f"{'='*50}")
    print(f"  Total processed:  {total}")
    print(f"  YES (confirmed):  {stats['yes']}")
    print(f"  NO (false pos):   {stats['no']}")
    print(f"  UNCERTAIN:        {stats['uncertain']}")
    print(f"  Errors:           {stats['error']}")
    print(f"  Missing data:     {stats['missing']}")

if __name__ == "__main__":
    main()
```

**Implementation notes for Gemini:**
- The script above is a REFERENCE. Write it to `scripts/phase7_verify_reviews.py`.
- Temperature 0.1 for deterministic classification.
- Max 100 tokens — we only need YES/NO/UNCERTAIN + one sentence.
- 1s delay between calls to stay well within Gemini Flash free tier rate limits.

---

## Step 4: Run Part B — Review Verification

```bash
cd ~/dev/projects/tripledb/pipeline

# Dry run
python3 scripts/phase7_verify_reviews.py --dry-run

# Run
python3 scripts/phase7_verify_reviews.py
```

**Expected runtime:** ~5 minutes (253 records × 1s delay).

After completion, verify:

```bash
wc -l data/logs/phase7-verified.jsonl
wc -l data/logs/phase7-false-positives.jsonl

# Classification breakdown
python3 -c "
import json
from collections import Counter
results = [json.loads(l) for l in open('data/logs/phase7-verified.jsonl')]
c = Counter(r['classification'] for r in results)
for k in ['YES', 'NO', 'UNCERTAIN']:
    print(f'  {k}: {c.get(k, 0)}')
"
```

### Expected Targets

| Metric | Target | Acceptable |
|--------|--------|------------|
| YES (confirmed) | ~200 | ≥ 170 |
| NO (false positive) | ~30 | 20–50 |
| UNCERTAIN | ~23 | ≤ 40 |

---

## Step 5: Apply Changes to Firestore

### 5a. Load newly matched restaurants from Part A

```bash
cd ~/dev/projects/tripledb/pipeline

# The new matches were already appended to restaurants_enriched.jsonl by phase7_refine.py.
# Load them to Firestore (resume support skips already-loaded records):
python3 scripts/phase7_load_enriched.py --all
```

### 5b. Remove false positives from Part B

Create a small script or use inline Python to remove enrichment fields from false-positive documents in Firestore:

```bash
python3 -c "
import json
import firebase_admin
from firebase_admin import firestore

if not firebase_admin._apps:
    firebase_admin.initialize_app()
db = firestore.client()

# Load false positives
fps = []
with open('data/logs/phase7-false-positives.jsonl') as f:
    for line in f:
        if line.strip():
            fps.append(json.loads(line))

print(f'False positives to clean: {len(fps)}')

# Fields to remove
from google.cloud.firestore_v1 import DELETE_FIELD
remove_fields = {
    'google_place_id': DELETE_FIELD,
    'google_rating': DELETE_FIELD,
    'google_rating_count': DELETE_FIELD,
    'google_maps_url': DELETE_FIELD,
    'website_url': DELETE_FIELD,
    'formatted_address': DELETE_FIELD,
    'business_status': DELETE_FIELD,
    'still_open': DELETE_FIELD,
    'photo_references': DELETE_FIELD,
    'enriched_at': DELETE_FIELD,
    'enrichment_source': DELETE_FIELD,
    'enrichment_match_score': DELETE_FIELD,
}

removed = 0
for fp in fps:
    rid = fp['restaurant_id']
    doc_ref = db.collection('restaurants').document(rid)
    doc = doc_ref.get()
    if doc.exists and doc.to_dict().get('enriched_at'):
        doc_ref.update(remove_fields)
        removed += 1
        print(f'  Cleaned: {fp.get(\"name\", rid)}')

print(f'Removed enrichment from {removed} false-positive documents')
"
```

### 5c. Verify final Firestore state

```bash
python3 -c "
import firebase_admin
from firebase_admin import firestore
from google.cloud.firestore_v1.base_query import FieldFilter

if not firebase_admin._apps:
    firebase_admin.initialize_app()
db = firestore.client()

enriched = db.collection('restaurants').where(filter=FieldFilter('enriched_at', '!=', None)).get()
print(f'Total enriched in Firestore: {len(enriched)}')

# Quick integrity check on a few
for doc in enriched[:3]:
    d = doc.to_dict()
    print(f'  {d.get(\"name\")} — Rating: {d.get(\"google_rating\")}, Dishes: {len(d.get(\"dishes\", []))}')
"
```

---

## Step 6: Update App Metrics

```bash
cd ~/dev/projects/tripledb/app
```

Update the Explore page and trivia to reflect final enrichment counts. The numbers will have changed:
- Total enriched increased (newly matched from Part A minus false positives from Part B)
- Permanently closed count may have changed
- Coordinate backfill count increased

Modify `lib/pages/explore_page.dart` and `lib/providers/trivia_providers.dart` if any values were hardcoded. They should already be computing dynamically from Firestore data — verify this.

```bash
flutter analyze
flutter build web
```

Both must pass.

---

## Step 7: Update README.md

```bash
cd ~/dev/projects/tripledb
```

### 7a. Project Status Table

Phase 7 row should now show v7.30–v7.32:
```
| 7 | Enrichment | ✅ Complete | v7.30–v7.32 |
```

### 7b. Current Metrics

Update with ACTUAL numbers:
```markdown
### Live Dataset (tripledb.net)
- **1,102** unique restaurants across **62** states and territories
- **2,286** dishes with ingredients and Guy's reactions
- **~XXX** restaurants enriched with Google ratings and open/closed status
- **~XXX** confirmed via LLM verification
- **~XXX** permanently closed restaurants identified
- **~XXX** restaurants with map coordinates
```

### 7c. IAO Iteration History

Add v7.32:
```
| v7.32 | Enrichment Refinement | ✅ | Refined search recovered X more. LLM verified 253. X false positives removed. |
```

### 7d. Changelog

```markdown
**v7.31 → v7.32 (Phase 7 Enrichment Refinement)**
- **Part A:** Refined search on 462 no-match restaurants using owner/chef names, cuisine types,
  and DDD-aware queries. Recovered X additional matches across 4 query passes.
- **Part B:** Gemini Flash LLM verification of 253 review-bucket matches. X confirmed correct,
  X false positives removed from Firestore, X flagged as uncertain for manual review.
- **Outcome:** Final enrichment coverage: X/1,102 (XX%). Enrichment phase complete.
```

### 7e. Footer
```markdown
*Last updated: Phase 7.32 — Enrichment Refinement*
```

### 7f. Verify
```bash
grep "7.32" README.md | head -3
grep "Last updated" README.md
```

---

## Step 8: Generate Artifacts

### docs/ddd-build-v7.32.md (MANDATORY — FULL TRANSCRIPT)

Must include:
- Pre-flight output (verbatim)
- Part A: refined search output (summary stats, per-pass breakdown)
- Part B: verification output (YES/NO/UNCERTAIN counts, sample responses)
- Firestore load + false positive cleanup output
- Flutter analyze + build output
- README changes summary
- Any errors and fixes

**Write to:** `~/dev/projects/tripledb/docs/ddd-build-v7.32.md`

### docs/ddd-report-v7.32.md (MANDATORY)

Must include:
1. **Part A results:** newly matched count, recovery rate, per-pass breakdown
2. **Part B results:** verification counts (YES/NO/UNCERTAIN), false positive details
3. **Final enrichment summary:** total enriched, match rate vs v7.31
4. **Rating distribution** (updated with new matches)
5. **Business status** (updated)
6. **Coordinate backfill** (cumulative: v7.31 + v7.32)
7. **API cost** (Places + Gemini, expected: $0)
8. **Firestore state:** enriched count, false positives removed
9. **App build status**
10. **Comparison table:** v7.30 → v7.31 → v7.32
11. **Remaining gaps:** final no-match count, uncertain records for manual review
12. **Human interventions:** count (target: 0)
13. **Gemini's Recommendation:** What next?
14. **README Update Confirmation**

**Write to:** `~/dev/projects/tripledb/docs/ddd-report-v7.32.md`

---

## Success Criteria

```
[ ] Pre-flight passes (both API keys, both connectivity tests)
[ ] Part A — Refined Search:
    [ ] phase7_refine.py created with resume support
    [ ] 462 no-match restaurants processed
    [ ] ≥ 50 newly matched
    [ ] Per-pass breakdown logged
[ ] Part B — Review Verification:
    [ ] phase7_verify_reviews.py created with resume support
    [ ] 253 review-bucket records verified
    [ ] ≥ 170 confirmed (YES)
    [ ] False positives identified and logged
[ ] Firestore updates:
    [ ] New matches loaded
    [ ] False positives cleaned (enrichment fields removed)
    [ ] Integrity verified (dishes/visits intact)
[ ] App:
    [ ] flutter analyze: 0 errors
    [ ] flutter build web: success
    [ ] Metrics compute dynamically (not hardcoded)
[ ] README at project root fully updated:
    [ ] Phase 7: ✅ Complete v7.30–v7.32
    [ ] Current metrics with final enrichment numbers
    [ ] Iteration history includes v7.32
    [ ] Changelog for v7.32
    [ ] Footer: Phase 7.32
[ ] ddd-build-v7.32.md generated (FULL transcript)
[ ] ddd-report-v7.32.md generated
[ ] Human interventions: 0
```

---

## GEMINI.md Update

```markdown
# TripleDB Pipeline — Agent Instructions

## Current Iteration: 7.32

IMPORTANT: Read documents in this EXACT order before executing:

1. ../docs/ddd-design-v7.32.md — Architecture, v7.31 results, refinement strategy
2. ../docs/ddd-plan-v7.32.md — Refined search + LLM verification steps

Do NOT begin execution until both files have been read.

## Rules That Never Change
- Git READ commands allowed. Git WRITE commands and firebase deploy FORBIDDEN.
- flutter build web and flutter run ARE ALLOWED.
- NEVER ask permission — auto-proceed on EVERY step.
- Context7 MCP allowed. No other MCP servers.
- MUST produce ddd-build-v7.32.md AND ddd-report-v7.32.md before ending.
- ddd-build must be a FULL session transcript — not a summary.
- README.md is at PROJECT ROOT (~/dev/projects/tripledb/README.md).
- Pipeline scripts run from ~/dev/projects/tripledb/pipeline/.
- Flutter app runs from ~/dev/projects/tripledb/app/.
- $GOOGLE_PLACES_API_KEY and $GEMINI_API_KEY must be set.
  If not set, print the missing variable name and HALT. Do NOT ask interactively.
```

---

## Launch Sequence

```bash
# 1. Archive previous iteration
cd ~/dev/projects/tripledb
mv docs/ddd-design-v7.31.md docs/archive/ 2>/dev/null
mv docs/ddd-plan-v7.31.md docs/archive/ 2>/dev/null
mv docs/ddd-report-v7.31.md docs/archive/ 2>/dev/null
mv docs/ddd-build-v7.31.md docs/archive/ 2>/dev/null

# 2. Place new docs
cp /path/to/ddd-design-v7.32.md docs/
cp /path/to/ddd-plan-v7.32.md docs/

# 3. Ensure BOTH API keys are set
echo "GOOGLE_PLACES_API_KEY: $([ -n "$GOOGLE_PLACES_API_KEY" ] && echo SET || echo MISSING)"
echo "GEMINI_API_KEY: $([ -n "$GEMINI_API_KEY" ] && echo SET || echo MISSING)"

# 4. Update GEMINI.md
nano pipeline/GEMINI.md

# 5. Commit
git add .
git commit -m "KT starting 7.32"

# 6. Launch (in Konsole, NOT IDE terminal)
cd pipeline
gemini
```

Then: `Read GEMINI.md and execute.`

After completion:
```bash
cd ~/dev/projects/tripledb
git add .
git commit -m "KT completed 7.32 and README updated"
git push

cd app
flutter build web
firebase deploy --only hosting
```
