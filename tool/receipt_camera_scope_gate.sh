#!/usr/bin/env bash
set -euo pipefail

changed_files="$(
  git diff --name-only --diff-filter=ACMRTUXB HEAD --
  git diff --name-only --cached --diff-filter=ACMRTUXB --
)"

if [[ -z "${changed_files//[$'\n'[:space:]]/}" ]]; then
  echo "Receipt camera scope gate: no tracked changes to check."
  exit 0
fi

failed=0
while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  case "$path" in
    android/app/src/main/kotlin/com/maintainiac/ReceiptCamera*.kt | \
    android/app/src/main/kotlin/com/maintainiac/MainActivity.kt | \
    ios/Runner/ReceiptCamera*.swift | \
    ios/Runner/AppDelegate.swift | \
    docs/receipt_bug_regression_ledger.md | \
    lib/shared/receipts/* | \
    lib/shared/widgets/receipt_capture/* | \
    test/helpers/receipt_native_* | \
    test/helpers/receipt_stitching_* | \
    test/receipt_camera_* | \
    test/receipt_native_* | \
    test/receipt_stitching_* | \
    tool/android_receipt_camera_* | \
    tool/ios_receipt_camera_* | \
    tool/receipt_bug_regression_ledger_gate.dart | \
    tool/receipt_camera_* | \
    tool/receipt_fast_guard_gate.sh | \
    test/receipt_fast_guard_gate_contract_test.dart)
      ;;
    *)
      printf 'SCOPE_FAIL %s\n' "$path" >&2
      failed=1
      ;;
  esac
done <<< "$changed_files"

if [[ "$failed" -ne 0 ]]; then
  echo "Receipt camera scope gate failed: tracked changes left the camera lane." >&2
  exit 1
fi

echo "Receipt camera scope gate: tracked changes stay in the camera lane."
