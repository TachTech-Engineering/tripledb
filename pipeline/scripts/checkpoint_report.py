#!/usr/bin/env python3
"""checkpoint_report.py — Generate checkpoint report during production runs."""
import json, os, glob, time
from datetime import datetime

def generate_checkpoint(phase_name, processed_count, total_count, failed_count=0, skipped_count=0):
    """Write a checkpoint report to data/logs/."""
    os.makedirs("data/logs", exist_ok=True)

    # Gather current metrics
    transcript_count = len(glob.glob("data/transcripts/*.json"))
    extraction_count = len([f for f in glob.glob("data/extracted/*.json") if "_raw" not in f])

    report = {
        "checkpoint": processed_count,
        "phase": phase_name,
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "videos_processed": processed_count,
        "videos_total": total_count,
        "videos_remaining": total_count - processed_count,
        "videos_failed": failed_count,
        "videos_skipped": skipped_count,
        "success_rate": (processed_count - failed_count) / max(processed_count, 1),
        "transcripts_on_disk": transcript_count,
        "extractions_on_disk": extraction_count,
    }

    checkpoint_file = f"data/logs/checkpoint-{phase_name}-{processed_count}.json"
    with open(checkpoint_file, "w") as f:
        json.dump(report, f, indent=2)

    print(f"\n{'='*50}")
    print(f"CHECKPOINT: {phase_name} — {processed_count}/{total_count}")
    print(f"  Success rate: {report['success_rate']:.1%}")
    print(f"  Failed: {failed_count} | Skipped: {skipped_count}")
    print(f"  Report: {checkpoint_file}")
    print(f"{'='*50}\n")

    # Automatic pause conditions
    if processed_count >= 50:
        recent_fail_rate = failed_count / processed_count
        if recent_fail_rate > 0.10:
            print(f"⚠️  PAUSE: Failure rate {recent_fail_rate:.1%} exceeds 10% threshold")
            print("Review logs before continuing.")
            return False  # Signal to pause

    return True  # Signal to continue


if __name__ == "__main__":
    # Standalone: generate a summary checkpoint
    generate_checkpoint("summary", 0, 0)