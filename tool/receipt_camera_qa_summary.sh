#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  cat >&2 <<'USAGE'
Usage: tool/receipt_camera_qa_summary.sh <quick|milestone|full|batch-name>

Summarizes a completed detached receipt camera QA batch without live log
monitoring. The normal camera modes map to receipt_camera_qa_<mode>.
USAGE
  exit 64
fi

name="$1"
case "$name" in
  quick | milestone | full) name="receipt_camera_qa_$name" ;;
  *[!A-Za-z0-9_.-]* | "")
    echo "Batch name must use only letters, numbers, dot, dash, or underscore." >&2
    exit 64
    ;;
esac

root="/tmp/maintainiac_receipt_quiet_batch/$name"
log_file="$root/run.log"

bash tool/receipt_quiet_batch_status.sh "$name"

if [[ ! -f "$log_file" ]]; then
  echo "summary=missing_log"
  exit 66
fi

status="$(cat "$root/status.txt" 2>/dev/null || echo unknown)"
if [[ "$status" == "running" ]]; then
  echo "summary=batch_still_running"
  exit 70
fi

if [[ "$status" == "passed" ]]; then
  echo "summary=passed_no_actionable_failures"
  exit 0
fi

echo "summary=failed_actionable_lines"
if command -v rg >/dev/null 2>&1; then
  rg -n \
    '\\[E\\]|To run this test again|Expected:|Actual:|Which:|Some tests failed|Error:|FAIL|failed' \
    "$log_file" |
    tail -80
else
  grep -En \
    '\\[E\\]|To run this test again|Expected:|Actual:|Which:|Some tests failed|Error:|FAIL|failed' \
    "$log_file" |
    tail -80
fi
