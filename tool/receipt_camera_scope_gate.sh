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
    .gitignore | \
    ios/Runner/ReceiptCamera*.swift | \
    ios/Runner/AppDelegate.swift | \
    docs/receipt_camera_roadmap.md | \
    docs/receipt_camera_completion_map.md | \
    docs/receipt_camera_ocr_pipeline_handoff_report.md | \
    docs/receipt_camera_ocr_product_standard.md | \
    docs/receipt_camera_ocr_master_pass_plan.md | \
    docs/receipt_camera_release_one_blueprint.md | \
    docs/receipt_camera_world_class_readiness.md | \
    docs/receipt_native_camera_service_spec.md | \
    docs/receipt_bug_regression_ledger.md | \
    docs/receipt_bug_regression_ledger_archive_*.md | \
    lib/shared/receipts/* | \
    lib/shared/widgets/receipt_capture/* | \
    test/helpers/receipt_native_* | \
    test/helpers/receipt_recovery_handoff_fixture.dart | \
    test/helpers/receipt_stitching_* | \
    test/receipt_capture_flow_barcode_handoff_test.dart | \
    test/receipt_capture_flow_ocr_source_count_test.dart | \
    test/receipt_attachment_panel_actions_test.dart | \
    test/receipt_camera_dataset_qa_gate_contract_test.dart | \
    test/receipt_camera_* | \
    test/receipt_native_* | \
    test/receipt_ocr_source_* | \
    test/receipt_photo_review_* | \
    test/receipt_photo_section_labels_test.dart | \
    test/receipt_external_dataset_local_audit_test.dart | \
    test/receipt_external_dataset_gate_test.dart | \
    test/receipt_external_fixture_schema_gate_test.dart | \
    test/receipt_stitch_fallback_metadata_test.dart | \
    test/fixtures/receipt_qa/external_dataset_manifest.json | \
    test/receipt_stitching_* | \
    tool/android_receipt_camera_* | \
    tool/ios_receipt_camera_* | \
	    tool/receipt_bug_regression_ledger_archive.dart | \
	    tool/receipt_bug_regression_ledger_gate.dart | \
	    tool/receipt_camera_changed_route_coverage_gate.dart | \
	    tool/receipt_camera_* | \
	    tool/receipt_external_dataset_local_audit.dart | \
	    tool/receipt_external_dataset_gate.dart | \
	    tool/receipt_external_fixture_schema_gate.dart | \
	    tool/receipt_pipeline_failure_to_regression.dart | \
	    tool/receipt_fast_guard_gate.sh | \
	    tool/receipt_quiet_batch.sh | \
	    tool/receipt_quiet_batch_status.sh | \
	    tool/receipt_quiet_batch_final_summary.sh | \
	    tool/receipt_start_camera_qa_gate.sh | \
	    test/receipt_bug_regression_ledger_archive_test.dart | \
	    test/receipt_camera_changed_route_coverage_gate_test.dart | \
	    test/receipt_fast_guard_gate_contract_test.dart | \
	    test/receipt_pipeline_failure_to_regression_test.dart)
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
