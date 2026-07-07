#!/usr/bin/env bash
set -euo pipefail

detached=false
if [[ "${1:-}" == "--detached" ]]; then
  detached=true
  shift
fi

if [[ $# -ne 0 ]]; then
  cat >&2 <<'USAGE'
Usage: tool/receipt_camera_changed_gate.sh [--detached]

Runs the smallest safe receipt camera QA mode for tracked camera-lane changes.
Untracked files are intentionally ignored so unrelated handoff drafts do not
force camera QA. Use --detached to start the chosen gate without log streaming.
USAGE
  exit 64
fi

bash tool/receipt_camera_scope_gate.sh

changed_files="$(
  git diff --name-only --diff-filter=ACMRTUXB HEAD --
  git diff --name-only --cached --diff-filter=ACMRTUXB --
)"

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
    lib/shared/widgets/receipt_capture/*stitch* | \
    lib/shared/widgets/receipt_capture/*native* | \
    lib/shared/widgets/receipt_capture/*review* | \
    lib/shared/widgets/receipt_capture/*handoff* | \
    lib/shared/receipts/*stitch* | \
    test/receipt_stitching_* | \
    test/receipt_native_* | \
    test/receipt_camera_result_* | \
    test/receipt_camera_ocr_source_handoff_test.dart)
      if [[ "$mode" == "quick" ]]; then
        mode="milestone"
      fi
      ;;
  esac
done <<< "$changed_files"

echo "Receipt camera changed gate: selected $mode for tracked camera changes."

if [[ "$detached" == "true" ]]; then
  exec bash tool/receipt_start_camera_qa_gate.sh "$mode"
fi

exec bash tool/receipt_camera_qa_gate.sh "$mode"
