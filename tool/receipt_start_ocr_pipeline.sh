#!/usr/bin/env bash
set -euo pipefail

batch_name="${1:-receipt_ocr_pipeline}"
batch_root="/tmp/maintainiac_receipt_quiet_batch/$batch_name"
payload="$batch_root/receipt_ocr_pipeline_run.sh"
payload_scripts="$batch_root/pipeline_scripts"
mkdir -p "$batch_root"
sed '' tool/receipt_ocr_pipeline_run.sh > "$payload"
rm -rf "$payload_scripts"
mkdir -p "$payload_scripts/tool"
for script in \
  tool/android_receipt_camera_compile_gate.sh \
  tool/ios_receipt_camera_compile_gate.sh \
  tool/receipt_camera_pipeline_gate.sh \
  tool/receipt_cleanup_log_gate.sh \
  tool/receipt_doc_size_gate.sh \
  tool/receipt_fast_guard_gate.sh \
  tool/receipt_quality_gate.sh \
  tool/receipt_regression_report.sh
do
  sed '' "$script" > "$payload_scripts/$script"
done
command_line="RECEIPT_PIPELINE_SCRIPT_ROOT=$(printf '%q' "$payload_scripts") /bin/bash $(printf '%q' "$payload") $(printf '%q' "$batch_name")"

exec bash tool/receipt_quiet_batch.sh \
  "$batch_name" \
  /bin/bash -lc "$command_line"
