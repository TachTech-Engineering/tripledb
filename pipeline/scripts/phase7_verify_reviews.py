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
            print(f"    Gemini error code: {resp.status_code}")
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
    # Note: restaurants_enriched.jsonl may have multiple entries for same ID if refined search matched.
    # We want the LATEST one or the one with the best match score.
    # Actually, review-needed records already have an entry in enriched_map.
    enriched_map = {}
    with open(ENRICHED_PATH) as f:
        for line in f:
            if line.strip():
                r = json.loads(line)
                rid = r.get("restaurant_id", "")
                enriched_map[rid] = r # Latest entry wins

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
                "gemini_response": response,
            }

            if classification == "NO":
                # False positive — log for removal
                false_pos_file.write(json.dumps(result) + "\n")
                false_pos_file.flush()
                print(f"    ❌ NO — {response.splitlines()[0][:80]}")
            elif classification == "YES":
                print(f"    ✅ YES — {response.splitlines()[0][:80]}")
            else:
                print(f"    ❓ UNCERTAIN — {response.splitlines()[0][:80]}")

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
