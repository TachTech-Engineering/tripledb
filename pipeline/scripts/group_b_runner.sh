#!/usr/bin/env bash
# group_b_runner.sh — Unattended production run for remaining ~685 videos.
# Run in tmux: tmux new -s tripledb './scripts/group_b_runner.sh 2>&1 | tee data/logs/group_b_run.log'

set -euo pipefail
cd "$(dirname "$0")/.."  # Ensure we're in pipeline/

TOTAL_START=$(date +%s)
LOG_DIR="data/logs"
mkdir -p "$LOG_DIR"

echo "=========================================="
echo "TripleDB Group B Production Run"
echo "Started: $(date)"
echo "=========================================="

# ── Phase 1: Download remaining videos ──────────────────────
echo ""
echo "=== Phase 1: Download ==="
python3 scripts/phase1_acquire.py --all
echo "Download complete: $(date)"

# ── Phase 2: Transcribe all ─────────────────────────────────
echo ""
echo "=== Phase 2: Transcribe ==="
# Kill any GPU-hogging processes
pkill -f "ollama" 2>/dev/null || true
sleep 2

# Verify GPU is free
nvidia-smi --query-compute-apps=pid --format=csv,noheader | while read pid; do
    if [ -n "$pid" ]; then
        echo "WARNING: GPU process $pid still running, killing..."
        kill "$pid" 2>/dev/null || true
    fi
done

LD_LIBRARY_PATH=/usr/local/lib/ollama/cuda_v12:${LD_LIBRARY_PATH:-} \
    python3 scripts/phase2_transcribe.py --all
echo "Transcription complete: $(date)"

# ── Phase 3: Extract all ────────────────────────────────────
echo ""
echo "=== Phase 3: Extract ==="
python3 scripts/phase3_extract_gemini.py --all
echo "Extraction complete: $(date)"

# ── Phase 4: Normalize ──────────────────────────────────────
echo ""
echo "=== Phase 4: Normalize ==="
python3 scripts/phase4_normalize.py
echo "Normalization complete: $(date)"

# ── Validate ────────────────────────────────────────────────
echo ""
echo "=== Validation ==="
python3 scripts/validate_extraction.py

TOTAL_END=$(date +%s)
ELAPSED=$(( (TOTAL_END - TOTAL_START) / 3600 ))
echo ""
echo "=========================================="
echo "Group B Production Run Complete"
echo "Finished: $(date)"
echo "Total runtime: ${ELAPSED} hours"
echo "=========================================="
echo ""
echo "NEXT STEPS:"
echo "  1. Review data/logs/group_b_run.log"
echo "  2. Run: python3 scripts/validate_extraction.py"
echo "  3. Review normalization: wc -l data/normalized/restaurants.jsonl"
echo "  4. Proceed to Phase 6 (Enrichment)"