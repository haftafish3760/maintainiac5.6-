#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: tool/receipt_quiet_batch_final_summary.sh <name>" >&2
  exit 64
fi

name="$1"
case "$name" in
  *[!A-Za-z0-9_.-]* | "")
    echo "Batch name must use only letters, numbers, dot, dash, or underscore." >&2
    exit 64
    ;;
esac

root="/tmp/maintainiac_receipt_quiet_batch/$name"
status_file="$root/status.txt"
exit_code_file="$root/exit_code"
log_file="$root/run.log"

if [[ ! -f "$status_file" ]]; then
  echo "missing batch=$name"
  exit 66
fi

status="$(cat "$status_file")"
exit_code="$(cat "$exit_code_file" 2>/dev/null || true)"
echo "batch=$name status=$status exit=${exit_code:-pending}"

if [[ "$status" == "running" ]]; then
  exit 0
fi

if [[ -f "$log_file" ]]; then
  if [[ "$status" == "passed" ]]; then
    grep -E '^(START|END|EXIT_CODE|.*: PASS$|PASS )' "$log_file" || true
  else
    tail -80 "$log_file"
  fi
fi

if [[ "$status" == "failed" ]]; then
  exit "${exit_code:-1}"
fi
