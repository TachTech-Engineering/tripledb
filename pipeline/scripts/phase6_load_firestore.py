#!/usr/bin/env python3
"""phase6_load_firestore.py — Load normalized JSONL into Cloud Firestore."""
import json
import os
import sys
import time
from datetime import datetime

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError:
    print("ERROR: firebase-admin not installed. Run: pip install firebase-admin --break-system-packages")
    sys.exit(1)

def main():
    # Initialize Firebase
    cred_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    if not cred_path or not os.path.isfile(cred_path):
        print(f"ERROR: Service account key not found at {cred_path}")
        print("Set GOOGLE_APPLICATION_CREDENTIALS in fish config")
        sys.exit(1)

    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred, {"projectId": os.environ.get("GOOGLE_CLOUD_PROJECT", "tripledb-e0f77")})
    db = firestore.client()

    now = datetime.utcnow().isoformat() + "Z"

    # Load restaurants
    restaurants_path = "data/normalized/restaurants.jsonl"
    print(f"\n=== Loading restaurants from {restaurants_path} ===")
    restaurant_count = 0
    batch = db.batch()
    batch_count = 0

    with open(restaurants_path) as f:
        for line in f:
            r = json.loads(line)
            doc_id = r.get("restaurant_id", f"r_{restaurant_count}")
            r["created_at"] = now
            r["updated_at"] = now

            ref = db.collection("restaurants").document(doc_id)
            batch.set(ref, r)
            batch_count += 1
            restaurant_count += 1

            # Firestore batch limit is 500
            if batch_count >= 450:
                batch.commit()
                print(f"  Committed batch: {restaurant_count} restaurants so far")
                batch = db.batch()
                batch_count = 0
                time.sleep(0.5)  # Rate limit courtesy

    if batch_count > 0:
        batch.commit()
        print(f"  Committed final batch: {restaurant_count} restaurants total")

    # Load videos
    videos_path = "data/normalized/videos.jsonl"
    print(f"\n=== Loading videos from {videos_path} ===")
    video_count = 0
    batch = db.batch()
    batch_count = 0

    with open(videos_path) as f:
        for line in f:
            v = json.loads(line)
            doc_id = v.get("video_id", f"v_{video_count}")
            v["loaded_at"] = now

            ref = db.collection("videos").document(doc_id)
            batch.set(ref, v)
            batch_count += 1
            video_count += 1

            if batch_count >= 450:
                batch.commit()
                print(f"  Committed batch: {video_count} videos so far")
                batch = db.batch()
                batch_count = 0
                time.sleep(0.5)

    if batch_count > 0:
        batch.commit()
        print(f"  Committed final batch: {video_count} videos total")

    # Summary
    print(f"\n=== Firestore Load Summary ===")
    print(f"Restaurants loaded: {restaurant_count}")
    print(f"Videos loaded: {video_count}")
    print(f"Project: {os.environ.get('GOOGLE_CLOUD_PROJECT', 'unknown')}")
    print(f"Timestamp: {now}")

if __name__ == "__main__":
    main()