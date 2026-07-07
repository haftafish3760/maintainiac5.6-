#!/usr/bin/env bash
set -euo pipefail

mode="${1:-milestone}"

case "$mode" in
  quick | milestone | full) ;;
  *)
    echo "Usage: tool/receipt_start_camera_qa_gate.sh [quick|milestone|full]" >&2
    exit 64
    ;;
esac

batch_name="receipt_camera_qa_${mode}"
batch_root="/tmp/maintainiac_receipt_quiet_batch/$batch_name"
payload="$batch_root/receipt_camera_qa_gate.sh"
mkdir -p "$batch_root"
cp tool/receipt_camera_qa_gate.sh "$payload"
command_line="/bin/bash $(printf '%q' "$payload") $(printf '%q' "$mode")"

exec bash tool/receipt_quiet_batch.sh \
  "$batch_name" \
  /bin/bash -lc "$command_line"
