#!/usr/bin/env bash
set -euo pipefail

bash -n \
  tool/android_receipt_camera_compile_gate.sh \
  tool/ios_receipt_camera_compile_gate.sh \
  tool/receipt_camera_pipeline_gate.sh \
  tool/receipt_camera_changed_gate.sh \
  tool/receipt_camera_failure_to_regression.sh \
  tool/receipt_camera_qa_gate.sh \
  tool/receipt_camera_qa_summary.sh \
  tool/receipt_camera_real_device_snapshot.sh \
  tool/receipt_camera_scope_gate.sh \
  tool/receipt_camera_stitch_gate.sh \
  tool/receipt_start_camera_qa_gate.sh \
  tool/receipt_cleanup_log_gate.sh \
  tool/receipt_doc_size_gate.sh \
  tool/receipt_fast_guard_gate.sh \
  tool/receipt_ocr_pipeline_run.sh \
  tool/receipt_quiet_batch.sh \
  tool/receipt_quiet_batch_status.sh \
  tool/receipt_quality_gate.sh \
  tool/receipt_start_ocr_pipeline.sh \
  tool/receipt_start_quiet_quality_gate.sh

bash tool/receipt_cleanup_log_gate.sh
bash tool/receipt_doc_size_gate.sh

dart analyze \
  tool/receipt_bug_regression_ledger_gate.dart \
  tool/receipt_bug_regression_ledger_archive.dart \
  tool/receipt_external_dataset_local_audit.dart \
  tool/receipt_external_dataset_gate.dart \
  tool/receipt_external_fixture_schema_gate.dart \
  tool/receipt_real_device_matrix_gate.dart \
  tool/receipt_quiet_batch_policy_gate.dart \
  lib/shared/widgets/receipt_capture \
  lib/shared/receipts \
  lib/shared/firebase/maintainiac_firestore_documents.dart \
  lib/shared/firebase/maintainiac_firestore_upload_queue.dart \
  lib/screens/expenses/data/expense_export_handoff.dart \
  lib/screens/expenses/data/expense_screen_telemetry.dart \
  test/expense_telemetry_ocr_source_redaction_contract_test.dart \
  test/expense_telemetry_redaction_contract_guard_test.dart \
  test/expense_release_one_blueprint_test.dart \
  test/firestore_data_model_guard_test.dart \
  test/receipt_camera_release_one_blueprint_test.dart \
  test/maintainiac_production_operating_directive_test.dart

dart tool/maintainiac_source_audit.dart --max-line-length=220
dart tool/maintainiac_source_audit.dart --tests-only --max-line-length=220
dart tool/receipt_bug_regression_ledger_gate.dart
dart tool/receipt_external_dataset_gate.dart
dart tool/receipt_external_dataset_local_audit.dart
dart tool/receipt_external_fixture_schema_gate.dart
dart tool/receipt_real_device_matrix_gate.dart
dart tool/receipt_quiet_batch_policy_gate.dart

RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST='test/receipt_camera_qa_gate_contract_test.dart' \
  bash tool/receipt_camera_changed_gate.sh --print-mode >/dev/null
RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST='tool/receipt_camera_qa_gate.sh' \
  bash tool/receipt_camera_changed_gate.sh --print-mode >/dev/null
RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST='tool/receipt_quiet_batch_status.sh' \
  bash tool/receipt_camera_changed_gate.sh --print-mode >/dev/null
RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST='tool/receipt_external_fixture_schema_gate.dart' \
  bash tool/receipt_camera_changed_gate.sh --print-mode >/dev/null
RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST='tool/receipt_external_dataset_local_audit.dart' \
  bash tool/receipt_camera_changed_gate.sh --print-mode >/dev/null
RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST='tool/receipt_external_dataset_gate.dart' \
  bash tool/receipt_camera_changed_gate.sh --print-mode >/dev/null
bash tool/receipt_camera_qa_gate.sh --print-plan quick >/dev/null
bash tool/receipt_camera_qa_gate.sh --print-plan stitch >/dev/null
bash tool/receipt_camera_qa_gate.sh --print-plan milestone >/dev/null
bash tool/receipt_camera_qa_gate.sh --print-plan full >/dev/null

if [[ -f tool/codex_rate_limit_probe.py ]]; then
  python3 -m py_compile tool/codex_rate_limit_probe.py
fi

dart tool/receipt_camera_io_guard.dart
dart tool/receipt_camera_footprint_audit.dart

flutter test \
  test/expense_telemetry_ocr_source_redaction_contract_test.dart \
  test/expense_telemetry_redaction_contract_guard_test.dart \
  test/expense_receipt_parser_assisted_review_test.dart \
  test/expense_receipt_parser_ocr_diagnostics_test.dart \
  test/expense_release_one_blueprint_test.dart \
  test/firestore_data_model_guard_test.dart \
  test/maintainiac_production_operating_directive_test.dart \
  test/receipt_camera_release_one_blueprint_test.dart \
  test/maintainiac_source_audit_contract_test.dart \
  test/receipt_doc_size_gate_contract_test.dart \
  test/receipt_external_dataset_local_audit_test.dart \
  test/receipt_external_dataset_gate_test.dart \
  test/receipt_external_fixture_schema_gate_test.dart \
  test/receipt_bug_regression_ledger_archive_test.dart \
  test/receipt_fast_guard_gate_contract_test.dart \
  test/receipt_camera_qa_gate_contract_test.dart \
  test/receipt_camera_qa_gate_execution_test.dart \
  test/receipt_camera_footprint_audit_test.dart \
  test/receipt_camera_result_test.dart \
  test/receipt_photo_review_retake_order_test.dart \
  test/receipt_real_device_matrix_gate_test.dart \
  test/receipt_quiet_batch_policy_gate_contract_test.dart \
  test/receipt_quality_gate_contract_test.dart \
  -r compact

git diff --check
