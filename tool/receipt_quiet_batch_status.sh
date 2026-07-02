#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  cat >&2 <<'USAGE'
Usage: tool/receipt_quiet_batch_status.sh <name>

Prints quiet-batch status metadata only. It never tails or prints run.log.
USAGE
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
pid_file="$root/pid"
log_file="$root/run.log"
runner_started_file="$root/runner_started"
runner_finished_file="$root/runner_finished"

if [[ ! -d "$root" ]]; then
  echo "Batch '$name' has no quiet-batch directory at $root."
  exit 66
fi

status="unknown"
if [[ -f "$status_file" ]]; then
  status="$(cat "$status_file")"
fi

pid="unknown"
if [[ -f "$pid_file" ]]; then
  pid="$(cat "$pid_file")"
fi

running="false"
if [[ "$status" == "running" ]] &&
  [[ "$pid" != "unknown" ]] &&
  kill -0 "$pid" 2>/dev/null; then
  running="true"
fi

exit_code="pending"
if [[ -f "$exit_code_file" ]]; then
  exit_code="$(cat "$exit_code_file")"
fi

runner_started="false"
if [[ -f "$runner_started_file" ]]; then
  runner_started="true"
fi

runner_finished="false"
if [[ -f "$runner_finished_file" ]]; then
  runner_finished="true"
fi

if [[ "$status" == "running" && "$running" == "false" && "$exit_code" == "pending" ]]; then
  status="stale"
fi

echo "name=$name"
echo "status=$status"
echo "running=$running"
echo "pid=$pid"
echo "exit_code=$exit_code"
echo "runner_started=$runner_started"
echo "runner_finished=$runner_finished"
echo "log=$log_file"
