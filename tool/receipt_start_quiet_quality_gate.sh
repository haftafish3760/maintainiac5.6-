#!/usr/bin/env bash
set -euo pipefail

batch_name="${1:-receipt_quality_gate}"
batch_root="/tmp/maintainiac_receipt_quiet_batch/$batch_name"
payload="$batch_root/receipt_quality_gate.sh"
mkdir -p "$batch_root"
sed '' tool/receipt_quality_gate.sh > "$payload"
command_line="/bin/bash $(printf '%q' "$payload")"

exec bash tool/receipt_quiet_batch.sh \
  "$batch_name" \
  /bin/bash -lc "$command_line"
