#!/usr/bin/env bash
set -euo pipefail

detached=false
print_mode=false
while [[ $# -gt 0 ]]; do
  case "${1:-}" in
    --detached)
      detached=true
      shift
      ;;
    --print-mode)
      print_mode=true
      shift
      ;;
    *)
      break
      ;;
  esac
done

if [[ $# -ne 0 ]]; then
  cat >&2 <<'USAGE'
Usage: tool/receipt_camera_changed_gate.sh [--detached] [--print-mode]

Runs the smallest safe receipt camera QA mode for tracked camera-lane changes.
Untracked files are intentionally ignored so unrelated handoff drafts do not
force camera QA. Use --detached to start the chosen gate without log streaming.
Use --print-mode for contract tests that prove mode routing without running QA.
USAGE
  exit 64
fi

if [[ -n "${RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST:-}" ]]; then
  changed_files="$RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST"
else
  bash tool/receipt_camera_scope_gate.sh
  changed_files="$(
    git diff --name-only --diff-filter=ACMRTUXB HEAD --
    git diff --name-only --cached --diff-filter=ACMRTUXB --
  )"
fi

if [[ -z "${changed_files//[$'\n'[:space:]]/}" ]]; then
  echo "Receipt camera changed gate: no tracked camera changes; skipping QA rerun."
  exit 0
fi

mode="quick"
while IFS= read -r path; do
  [[ -z "$path" ]] && continue

  case "$path" in
    android/app/src/main/kotlin/com/maintainiac/ReceiptCamera*.kt | \
    android/app/src/main/kotlin/com/maintainiac/MainActivity.kt | \
    ios/Runner/ReceiptCamera*.swift | \
    ios/Runner/AppDelegate.swift)
      mode="full"
      break
      ;;
  esac

  case "$path" in
    tool/receipt_camera_qa_gate.sh | \
    tool/receipt_camera_changed_gate.sh | \
    tool/receipt_camera_qa_summary.sh | \
    tool/receipt_external_dataset_local_audit.dart | \
    tool/receipt_external_fixture_schema_gate.dart | \
    tool/receipt_start_camera_qa_gate.sh | \
    tool/receipt_quiet_batch.sh | \
    tool/receipt_quiet_batch_status.sh | \
    test/receipt_camera_qa_gate_contract_test.dart | \
    test/receipt_camera_qa_gate_execution_test.dart | \
    test/receipt_external_dataset_local_audit_test.dart)
      if [[ "$mode" == "quick" ]]; then
        mode="milestone"
      fi
      ;;
  esac

  case "$path" in
    lib/shared/widgets/receipt_capture/*native* | \
    lib/shared/widgets/receipt_capture/*review* | \
    lib/shared/widgets/receipt_capture/*handoff* | \
    test/receipt_native_* | \
    test/receipt_camera_result_* | \
    test/receipt_camera_ocr_source_handoff_test.dart)
      if [[ "$mode" == "quick" ]]; then
        mode="milestone"
      fi
      ;;
  esac

  case "$path" in
    lib/shared/widgets/receipt_capture/*stitch* | \
    lib/shared/receipts/*stitch* | \
    test/helpers/receipt_stitching_* | \
    test/receipt_stitching_* | \
    test/receipt_stitch_fallback_metadata_test.dart | \
    test/receipt_camera_result_stitch_scanner_test.dart | \
    test/receipt_ocr_source_* | \
    test/receipt_ocr_source_relationship_test.dart | \
    tool/receipt_camera_stitch_gate.sh)
      if [[ "$mode" == "quick" ]]; then
        mode="stitch"
      fi
      ;;
  esac
done <<< "$changed_files"

echo "Receipt camera changed gate: selected $mode for tracked camera changes."

if [[ "$print_mode" == "true" ]]; then
  exit 0
fi

if [[ "$detached" == "true" ]]; then
  exec bash tool/receipt_start_camera_qa_gate.sh "$mode"
fi

exec bash tool/receipt_camera_qa_gate.sh "$mode"
