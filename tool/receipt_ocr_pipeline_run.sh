#!/usr/bin/env bash
set -euo pipefail

run_name="${1:-receipt_ocr_pipeline}"
root="/tmp/maintainiac_receipt_ocr_pipeline/$run_name"
rm -rf "$root"
mkdir -p "$root/phases"

summary="$root/summary.tsv"
status="$root/status.txt"
failure_report="$root/failure_report.txt"
regression_task="$root/regression_tasks/pipeline_failure_regression_task.md"

: > "$summary"
: > "$failure_report"
printf 'running\n' > "$status"

pipeline_code=255
interrupted_signal=""
finish_pipeline() {
  if [[ "$pipeline_code" -eq 0 ]]; then
    printf 'passed\n' > "$status"
  elif [[ -n "$interrupted_signal" ]]; then
    printf 'failed\n' > "$status"
    {
      echo "FAILED_PHASE pipeline_interrupted"
      echo "SIGNAL $interrupted_signal"
      echo "LOG $root"
      echo "NEXT_ACTION inspect the interrupted phase, fix any partial-run cleanup issue, add or extend a regression test for interrupted pipeline finalization, then rerun this pipeline"
    } > "$failure_report"
    write_regression_task pipeline_interrupted "$root" "$regression_task" >> "$failure_report" 2>&1 || true
  elif [[ "$(cat "$status" 2>/dev/null || true)" == "running" ]]; then
    printf 'failed\n' > "$status"
    {
      echo "FAILED_PHASE pipeline_startup_or_unhandled_exit"
      echo "LOG $root"
      echo "NEXT_ACTION inspect pipeline launcher artifacts, fix root cause, add or extend a regression test for the failure family, then rerun this pipeline"
    } > "$failure_report"
    write_regression_task pipeline_startup_or_unhandled_exit "$root" "$regression_task" >> "$failure_report" 2>&1 || true
  fi
}
trap finish_pipeline EXIT
trap 'interrupted_signal=INT; pipeline_code=130; exit 130' INT
trap 'interrupted_signal=TERM; pipeline_code=143; exit 143' TERM

phase() {
  local name="$1"
  shift
  local log="$root/phases/$name.log"
  local code=0

  {
    date '+START %Y-%m-%d %H:%M:%S %Z'
    "$@"
    code=$?
    date '+END %Y-%m-%d %H:%M:%S %Z'
    echo "EXIT_CODE $code"
  } > "$log" 2>&1 || code=$?

  if [[ "$code" -eq 0 ]]; then
    printf '%s\tpassed\t%s\n' "$name" "$log" >> "$summary"
    return 0
  fi

  printf '%s\tfailed\t%s\n' "$name" "$log" >> "$summary"
  {
    echo "FAILED_PHASE $name"
    echo "LOG $log"
    echo "NEXT_ACTION inspect the phase log, fix root cause, add or extend a regression test for the failure family, then rerun this pipeline"
  } > "$failure_report"
  write_regression_task "$name" "$log" "$regression_task" >> "$failure_report" 2>&1 || true
  printf 'failed\n' > "$status"
  return "$code"
}

run_phase() {
  phase "$@" || exit $?
}

failure_family() {
  case "$1" in
    static_guardrails*) echo "static_guardrails_and_source_size" ;;
    pure_receipt_qa) echo "pure_dart_receipt_qa" ;;
    camera_pipeline_contracts) echo "camera_capture_ocr_stitch_contracts" ;;
    native_camera_compile) echo "native_android_ios_camera_bridge" ;;
    full_receipt_quality_gate) echo "full_receipt_quality_gate" ;;
    regression_report) echo "regression_reporting" ;;
    pipeline_interrupted) echo "pipeline_interruption_cleanup" ;;
    pipeline_startup_or_unhandled_exit) echo "pipeline_startup_finalization" ;;
    *) echo "unknown_receipt_ocr_pipeline_family" ;;
  esac
}

ledger_category() {
  case "$1" in
    static_guardrails*) echo "qa_harness" ;;
    pure_receipt_qa) echo "fixture_generation" ;;
    camera_pipeline_contracts) echo "camera_capture_quality" ;;
    native_camera_compile) echo "native_bridge" ;;
    full_receipt_quality_gate) echo "qa_harness" ;;
    regression_report) echo "qa_harness" ;;
    pipeline_interrupted) echo "qa_harness" ;;
    pipeline_startup_or_unhandled_exit) echo "qa_harness" ;;
    *) echo "qa_harness" ;;
  esac
}

write_regression_task() {
  local phase_name="$1"
  local log_path="$2"
  local task_path="$3"
  local task_dir
  task_dir="$(dirname "$task_path")"
  mkdir -p "$task_dir"
  cat > "$task_path" <<TASK
# Receipt OCR Regression Task

Run: \`$run_name\`
Failed phase: \`$phase_name\`
Failure family: \`$(failure_family "$phase_name")\`
Suggested ledger category: \`$(ledger_category "$phase_name")\`
Phase log: \`$log_path\`
Bug ledger: \`docs/receipt_bug_regression_ledger.md\`

## Required Work

- Inspect the phase log and identify the root cause.
- Fix the production code, fixture, script, or contract that caused the failure.
- Add or extend a regression test for the whole failure family, not only the
  single failing example.
- Add a \`BUG-RECEIPT-####\` ledger row with the final category, symptom, root
  cause, fix, regression coverage, and status.
- Rerun \`tool/receipt_start_ocr_pipeline.sh $run_name\` detached through the
  quiet pipeline launcher.

## Regression Standard

The fix is not complete until a future run fails if the same class of bug is
reintroduced.

## Classification Standard

If the suggested category is too broad, choose a more specific allowed category
from the ledger. Do not close the task as an uncategorized bug.
TASK
  echo "Receipt regression task: $task_path"
}

repo_script_path() {
  local script="$1"
  local staged_root="${RECEIPT_PIPELINE_SCRIPT_ROOT:-}"
  if [[ -n "$staged_root" && -f "$staged_root/$script" ]]; then
    printf '%s\n' "$staged_root/$script"
    return
  fi
  printf '%s\n' "$script"
}

run_repo_script() {
  local script="$1"
  shift
  /bin/bash -s "$@" < "$(repo_script_path "$script")"
}

run_phase static_guardrails_cleanup_log run_repo_script tool/receipt_cleanup_log_gate.sh
run_phase static_guardrails_doc_size run_repo_script tool/receipt_doc_size_gate.sh
run_phase static_guardrails_shell_syntax bash -n \
  "$(repo_script_path tool/receipt_fast_guard_gate.sh)" \
  "$(repo_script_path tool/receipt_quality_gate.sh)"
run_phase static_guardrails_external_fixture dart \
  tool/receipt_external_fixture_schema_gate.dart
run_phase static_guardrails_quiet_policy dart \
  tool/receipt_quiet_batch_policy_gate.dart
run_phase static_guardrails_source_audit dart \
  tool/maintainiac_source_audit.dart \
  --max-line-length=220

run_phase pure_receipt_qa bash -lc '
  dart run tool/receipt_qa_runner.dart --fail-under=1.0 --summary-json
'

run_phase camera_pipeline_contracts run_repo_script tool/receipt_camera_pipeline_gate.sh

run_phase native_camera_compile bash -lc '
  run_repo_script() {
    local script="$1"
    shift
    local staged_root="${RECEIPT_PIPELINE_SCRIPT_ROOT:-}"
    local resolved="$script"
    if [[ -n "$staged_root" && -f "$staged_root/$script" ]]; then
      resolved="$staged_root/$script"
    fi
    /bin/bash -s "$@" < "$resolved"
  }
  run_repo_script tool/android_receipt_camera_compile_gate.sh &&
  run_repo_script tool/ios_receipt_camera_compile_gate.sh
'

run_phase full_receipt_quality_gate run_repo_script tool/receipt_quality_gate.sh

run_phase regression_report run_repo_script tool/receipt_regression_report.sh

pipeline_code=0
