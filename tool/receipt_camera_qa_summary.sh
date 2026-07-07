#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  cat >&2 <<'USAGE'
Usage: tool/receipt_camera_qa_summary.sh <phase2|phase3|phase4|phase5|phase6|phase7|quick|stitch|milestone|full|batch-name>

Summarizes a completed detached receipt camera QA batch without live log
monitoring. The normal camera modes map to receipt_camera_qa_<mode>.
USAGE
  exit 64
fi

requested_name="$1"
name="$requested_name"
failure_phase="camera_pipeline_contracts"
case "$name" in
  phase2)
    name="receipt_camera_qa_phase2"
    failure_phase="camera_phase2_gate"
    ;;
  phase3)
    name="receipt_camera_qa_phase3"
    failure_phase="camera_phase3_gate"
    ;;
  phase4)
    name="receipt_camera_qa_phase4"
    failure_phase="camera_phase4_gate"
    ;;
  phase5)
    name="receipt_camera_qa_phase5"
    failure_phase="camera_phase5_gate"
    ;;
  phase6)
    name="receipt_camera_qa_phase6"
    failure_phase="camera_phase6_gate"
    ;;
  phase7)
    name="receipt_camera_qa_phase7"
    failure_phase="camera_phase7_gate"
    ;;
  quick)
    name="receipt_camera_qa_quick"
    failure_phase="camera_quick_gate"
    ;;
  stitch)
    name="receipt_camera_qa_stitch"
    failure_phase="camera_stitch_gate"
    ;;
  milestone)
    name="receipt_camera_qa_milestone"
    failure_phase="camera_milestone_gate"
    ;;
  full)
    name="receipt_camera_qa_full"
    failure_phase="camera_full_gate"
    ;;
  *[!A-Za-z0-9_.-]* | "")
    echo "Batch name must use only letters, numbers, dot, dash, or underscore." >&2
    exit 64
    ;;
esac

root="/tmp/maintainiac_receipt_quiet_batch/$name"
log_file="$root/run.log"

status_output="$(bash tool/receipt_quiet_batch_status.sh "$name")"
printf '%s\n' "$status_output"
status="$(printf '%s\n' "$status_output" | awk -F= '$1 == "status" { print $2; exit }')"

if [[ ! -f "$log_file" ]]; then
  echo "summary=missing_log"
  exit 66
fi

if [[ "$status" == "running" ]]; then
  echo "summary=batch_still_running"
  exit 70
fi

if [[ "$status" == "stale" ]]; then
  echo "summary=batch_stale_requires_restart"
  case "$requested_name" in
    phase2 | phase3 | phase4 | phase5 | phase6 | phase7 | quick | stitch | milestone | full)
      echo "restart_command=tool/receipt_start_camera_qa_gate.sh $requested_name"
      ;;
    *)
      echo "restart_command=manual_rerun_required_for_batch_$name"
      ;;
  esac
  exit 70
fi

if [[ "$status" == "passed" ]]; then
  echo "summary=passed_no_actionable_failures"
  exit 0
fi

echo "summary=failed_actionable_lines"
echo "regression_task_command=tool/receipt_camera_failure_to_regression.sh $failure_phase $log_file"
actionable_pattern='\[E\]|To run this test again|Expected:|Actual:|Which:|Some tests failed|Error:|FAIL|failed'
if command -v rg >/dev/null 2>&1; then
  actionable_lines="$(rg -n "$actionable_pattern" "$log_file" || true)"
else
  actionable_lines="$(grep -En "$actionable_pattern" "$log_file" || true)"
fi

if [[ -n "$actionable_lines" ]]; then
  printf '%s\n' "$actionable_lines" | tail -80
else
  echo "summary_detail=no_actionable_patterns_found_check_log_path"
  echo "log_path=$log_file"
fi
