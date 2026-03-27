#!/usr/bin/env python3
"""
phase7_load_enriched.py — Merge enriched data into Firestore.

Reads data/enriched/restaurants_enriched.jsonl and updates existing Firestore documents.
Only merges enrichment fields; does NOT overwrite existing properties like 'dishes', 'visits'.
Coordinates are only backfilled if the Firestore document doesn't already have them.

Usage:
    python3 scripts/phase7_load_enriched.py --batch config/enrich_discovery_batch.txt
    python3 scripts/phase7_load_enriched.py --all
    python3 scripts/phase7_load_enriched.py --all --dry-run
"""
import argparse, json, os, sys
from datetime import datetime, timezone
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore

ENRICHED_PATH = Path("data/enriched/restaurants_enriched.jsonl")

# The fields we are allowed to merge into Firestore
ALLOWED_FIELDS = {
    "google_place_id",
    "google_rating",
    "google_rating_count",
    "google_maps_url",
    "website_url",
    "formatted_address",
    "business_status",
    "still_open",
    "photo_references",
    "enriched_at",
    "enrichment_source",
    "enrichment_match_score"
}

def init_firestore():
    """Initialize Firebase Admin SDK using the standard project pattern."""
    if not firebase_admin._apps:
        # Assumes GOOGLE_APPLICATION_CREDENTIALS is set, or runs in authenticated environment
        firebase_admin.initialize_app()
    return firestore.client()

def main():
    parser = argparse.ArgumentParser(description="Merge enriched data into Firestore")
    parser.add_argument("--batch", type=str, help="File with restaurant_ids to load (one per line)")
    parser.add_argument("--all", action="store_true", help="Load all enriched records")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be updated, no writes")
    args = parser.parse_args()

    if not args.batch and not args.all:
        print("ERROR: Specify --batch <file> or --all")
        sys.exit(1)

    if not ENRICHED_PATH.exists():
        print(f"ERROR: {ENRICHED_PATH} not found. Run enrichment first.")
        sys.exit(1)

    print("Loading enriched data from disk...")
    enriched_data = {}
    with open(ENRICHED_PATH) as f:
        for line in f:
            line = line.strip()
            if line:
                r = json.loads(line)
                if "restaurant_id" in r:
                    enriched_data[r["restaurant_id"]] = r

    if args.batch:
        batch_ids = set()
        with open(args.batch) as f:
            for line in f:
                line = line.strip()
                if line:
                    batch_ids.add(line)
        # Filter down to batch items
        enriched_data = {rid: data for rid, data in enriched_data.items() if rid in batch_ids}
        print(f"Filtered to {len(enriched_data)} items from batch file.")

    if not enriched_data:
        print("No records to process. Exiting.")
        return

    print("Initializing Firestore...")
    try:
        db = init_firestore()
    except Exception as e:
        print(f"Firestore init error: {e}")
        print("Make sure GOOGLE_APPLICATION_CREDENTIALS is set and points to a valid service account key.")
        sys.exit(1)

    print(f"Processing {len(enriched_data)} records...")
    updated_count = 0
    skipped_count = 0

    for rid, data in enriched_data.items():
        doc_ref = db.collection("restaurants").document(rid)
        
        # We must fetch the doc to check if it already has coordinates
        # and to verify we aren't re-enriching the same timestamp unnecessarily
        try:
            doc = doc_ref.get()
            if not doc.exists:
                print(f"  [WARN] Document {rid} not found in Firestore. Skipping.")
                skipped_count += 1
                continue
                
            current_data = doc.to_dict()
        except Exception as e:
            print(f"  [ERROR] Failed to fetch {rid}: {e}")
            skipped_count += 1
            continue
            
        # Optional: check if already loaded
        if current_data.get("enriched_at") == data.get("enriched_at"):
            print(f"  [SKIP] {rid} already has this enrichment timestamp.")
            skipped_count += 1
            continue

        # Prepare merge dict
        update_dict = {}
        for key in ALLOWED_FIELDS:
            if key in data:
                update_dict[key] = data[key]
                
        # Conditional coordinate backfill
        if data.get("latitude") and data.get("longitude"):
            # Only apply if Firestore doc lacks coordinates
            if not current_data.get("latitude"):
                update_dict["latitude"] = data["latitude"]
                update_dict["longitude"] = data["longitude"]
                if args.dry_run:
                    print(f"  [DRY-RUN] Would backfill coordinates for {rid}")
        
        update_dict["updated_at"] = datetime.now(timezone.utc).isoformat()
        
        if args.dry_run:
            print(f"  [DRY-RUN] Would merge {len(update_dict)} fields into {rid}")
        else:
            try:
                doc_ref.set(update_dict, merge=True)
                updated_count += 1
                if updated_count % 10 == 0:
                    print(f"  Updated {updated_count} documents...")
            except Exception as e:
                print(f"  [ERROR] Failed to update {rid}: {e}")
                
    print("\n" + "="*40)
    print("Firestore Load Complete")
    print("="*40)
    print(f"  Mode:          {'DRY-RUN' if args.dry_run else 'LIVE'}")
    print(f"  Total records: {len(enriched_data)}")
    print(f"  Updated:       {updated_count}")
    print(f"  Skipped:       {skipped_count}")

if __name__ == "__main__":
    main()
