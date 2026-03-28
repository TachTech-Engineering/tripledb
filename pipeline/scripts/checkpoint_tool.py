import json
import sys
from datetime import datetime, timezone
from pathlib import Path

CP = Path("data/checkpoints/v7.34_checkpoint.json")

def write_cp(step, name, metrics=None):
    CP.parent.mkdir(parents=True, exist_ok=True)
    CP.write_text(json.dumps({
        "iteration": "7.34",
        "last_completed_step": step,
        "step_name": name,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "metrics": metrics or {}
    }, indent=2))
    print(f"  [CHECKPOINT] Step {step} ({name}) saved.")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python checkpoint_tool.py <step_number> <step_name> [metrics_json]")
        sys.exit(1)
    
    step = int(sys.argv[1])
    name = sys.argv[2]
    metrics = json.loads(sys.argv[3]) if len(sys.argv) > 3 else None
    write_cp(step, name, metrics)
