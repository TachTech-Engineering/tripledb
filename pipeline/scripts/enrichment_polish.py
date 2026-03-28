import json
import firebase_admin
from firebase_admin import firestore, credentials
from google.cloud.firestore_v1 import DELETE_FIELD
from pathlib import Path
import os

# Initialize Firestore
if not firebase_admin._apps:
    # Check for credentials file, otherwise use default
    cred_path = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS')
    if cred_path and os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
    else:
        firebase_admin.initialize_app()

db = firestore.client()

# 3a. Tighten name-change threshold to 0.90
def step_3a():
    print("--- Step 3a: Tightening name-change threshold to 0.90 ---")
    backfill_path = Path('data/enriched/name_backfill.jsonl')
    if not backfill_path.exists():
        print(f"Error: {backfill_path} not found.")
        return

    records = [json.loads(l) for l in open(backfill_path)]
    print(f'Total name backfill records: {len(records)}')

    reclassified = 0
    still_changed = 0
    
    # We'll batch updates to Firestore
    batch = db.batch()
    batch_count = 0

    for rec in records:
        rid = rec['restaurant_id']
        sim = rec.get('name_similarity', 1.0)
        old_changed = rec.get('name_changed', False)
        new_changed = sim < 0.90

        if old_changed and not new_changed:
            # Was flagged as changed at 0.95, but not at 0.90 → suppress AKA display
            doc_ref = db.collection('restaurants').document(rid)
            batch.update(doc_ref, {'name_changed': False})
            batch_count += 1
            reclassified += 1
        elif new_changed:
            still_changed += 1
        
        if batch_count >= 400:
            batch.commit()
            batch = db.batch()
            batch_count = 0

    if batch_count > 0:
        batch.commit()

    print(f'Reclassified (0.95→0.90): {reclassified} records now name_changed=false')
    print(f'Still name_changed=true: {still_changed}')
    return {"reclassified": reclassified, "still_changed": still_changed}

# 3b. Resolve 26 UNCERTAIN records
def step_3b():
    print("--- Step 3b: Resolving UNCERTAIN records ---")
    verified_path = Path('data/logs/phase7-verified.jsonl')
    if not verified_path.exists():
        print(f"Error: {verified_path} not found.")
        return

    verified = [json.loads(l) for l in open(verified_path)]
    uncertain = [r for r in verified if r.get('classification') == 'UNCERTAIN']
    print(f'UNCERTAIN records found in logs: {len(uncertain)}')

    keep = []
    remove = []
    
    # Remove enrichment from low-confidence UNCERTAIN records
    remove_fields = {
        'google_place_id': DELETE_FIELD, 'google_rating': DELETE_FIELD,
        'google_rating_count': DELETE_FIELD, 'google_maps_url': DELETE_FIELD,
        'website_url': DELETE_FIELD, 'formatted_address': DELETE_FIELD,
        'business_status': DELETE_FIELD, 'still_open': DELETE_FIELD,
        'photo_references': DELETE_FIELD, 'enriched_at': DELETE_FIELD,
        'enrichment_source': DELETE_FIELD, 'enrichment_match_score': DELETE_FIELD,
        'google_current_name': DELETE_FIELD, 'name_changed': DELETE_FIELD,
    }

    batch = db.batch()
    batch_count = 0

    for rec in uncertain:
        rid = rec['restaurant_id']
        score = rec.get('match_score', 0)
        if score >= 0.80:
            keep.append(rec)
        else:
            remove.append(rec)
            doc_ref = db.collection('restaurants').document(rid)
            batch.update(doc_ref, remove_fields)
            batch_count += 1
            print(f'  Removing enrichment: {rec.get("name", rid)} (score: {score})')

    if batch_count > 0:
        batch.commit()

    # Log resolution
    res_path = Path('data/logs/phase7-uncertain-resolved.jsonl')
    with open(res_path, 'w') as f:
        for rec in keep:
            rec['resolution'] = 'kept'
            f.write(json.dumps(rec) + '\n')
        for rec in remove:
            rec['resolution'] = 'removed'
            f.write(json.dumps(rec) + '\n')

    print(f'Keep (score >= 0.80): {len(keep)}')
    print(f'Remove (score < 0.80): {len(remove)}')
    print(f'Resolution logged to {res_path}')
    return {"kept": len(keep), "removed": len(remove)}

# 3c. Consolidate enrichment logs
def step_3c():
    print("--- Step 3c: Consolidating enrichment logs ---")
    log_dir = Path('data/logs')
    summary = {
        'enrichment_phase': '7.30-7.34',
        'total_restaurants': 1102,
        'log_files': {}
    }

    for logfile in sorted(log_dir.glob('phase7-*.jsonl')):
        count = sum(1 for _ in open(logfile))
        summary['log_files'][logfile.name] = count

    # Count final enriched in Firestore (proxy from enriched JSONL if available)
    enriched_path = Path('data/enriched/restaurants_enriched.jsonl')
    if enriched_path.exists():
        enriched = [json.loads(l) for l in open(enriched_path)]
        summary['enriched_records_at_start_of_polish'] = len(enriched)
        summary['with_rating'] = sum(1 for r in enriched if r.get('google_rating'))
        summary['permanently_closed'] = sum(1 for r in enriched if r.get('business_status') == 'CLOSED_PERMANENTLY')

    with open(log_dir / 'phase7-enrichment-summary.json', 'w') as f:
        json.dump(summary, f, indent=2)

    print(json.dumps(summary, indent=2))
    return summary

if __name__ == "__main__":
    metrics_3a = step_3a()
    metrics_3b = step_3b()
    metrics_3c = step_3c()
    
    # Optional: Update the checkpoint with metrics
    print(f"\nPOLISH_METRICS: {json.dumps({'3a': metrics_3a, '3b': metrics_3b, '3c': metrics_3c})}")
