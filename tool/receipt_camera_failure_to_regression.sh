#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  cat >&2 <<'USAGE'
Usage: tool/receipt_camera_failure_to_regression.sh <phase> <log-file>

Creates a categorized regression task for a failed receipt camera QA phase.
USAGE
  exit 64
fi

camera_phase="$1"
log_file="$2"

case "$camera_phase" in
  native_camera_compile)
    phase="native_camera_compile"
    ;;
  camera_pipeline_contracts | camera_stitching | camera_stitch_gate | \
  camera_changed_gate | \
  camera_quick_gate | camera_milestone_gate | camera_full_gate)
    phase="camera_pipeline_contracts"
    ;;
  *)
    echo "Unknown receipt camera failure phase: $camera_phase" >&2
    exit 64
    ;;
esac

if [[ ! -f "$log_file" ]]; then
  echo "Receipt camera failure log not found: $log_file" >&2
  exit 66
fi

run_name="receipt_camera_qa_failure"
root="/tmp/maintainiac_receipt_ocr_pipeline/$run_name"
failure_report="$root/failure_report.txt"

mkdir -p "$root"
{
  printf 'CAMERA_PHASE %s\n' "$camera_phase"
  printf 'FAILED_PHASE %s\n' "$phase"
  printf 'LOG %s\n' "$log_file"
} > "$failure_report"

exec dart run tool/receipt_pipeline_failure_to_regression.dart "$run_name"
