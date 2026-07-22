#!/usr/bin/env bash
set -euo pipefail

# PDF gate. Keep this focused on PDF behavior, storage, privacy/security,
# invoice generation, import/export, and receipt PDF contracts. Avoid
# fragile PDF UI tests until those screens stabilize.

bash -n tool/pdf_quality_gate.sh
bash -n tool/pdf_render_smoke_gate.sh
bash -n tool/pdf_golden_snapshot_gate.sh
python3 -m py_compile tool/pdf_render_pixel_assertions.py

pdf_test_targets=(
  test/app_document_export_manifest_test.dart
  test/app_document_export_package_writer_test.dart
  test/app_document_store_test.dart
  test/app_generated_pdf_export_estimator_test.dart
  test/app_generated_pdf_export_quota_test.dart
  test/app_generated_pdf_export_request_test.dart
  test/app_generated_pdf_export_verifier_test.dart
  test/app_generated_pdf_preview_screen_test.dart
  test/app_generated_pdf_report_renderer_test.dart
  test/app_generated_pdf_service_test.dart
  test/app_generated_pdf_share_content_test.dart
  test/cloud_backup_manifest_test.dart
  test/cloud_backup_pdf_policy_test.dart
  test/document_engine_entrypoint_contract_test.dart
  test/expense_export_pdf_images_test.dart
  test/incoming_receipt_share_pdf_hardening_test.dart
  test/incoming_receipt_share_test.dart
  test/invoice_pdf_export_verifier_contract_test.dart
  test/invoice_pdf_preview_action_tracking_test.dart
  test/invoice_template_pdf_factory_test.dart
  test/pdf_health_diagnostics_test.dart
  test/receipt_ocr_service_pdf_inspector_test.dart
  test/receipt_ocr_service_pdf_security_test.dart
  test/receipt_pdf_hardening_test.dart
  test/receipt_pdf_import_copy_test.dart
  test/receipt_pdf_inspector_edge_cases_test.dart
  test/receipt_pdf_inspector_security_flags_test.dart
  test/receipt_pdf_performance_profile_test.dart
  test/receipt_pdf_torture_storage_test.dart
  test/receipt_pdf_torture_test.dart
  test/receipt_pdf_viewer_accessibility_test.dart
  test/receipt_pdf_viewer_hardening_test.dart
  test/receipt_pdf_viewer_preflight_test.dart
  test/receipt_proof_storage_hardening_test.dart
  test/receipt_proof_storage_lifecycle_test.dart
)

dart analyze \
  tool/generate_sample_receipt_pdf.dart \
  lib/shared/document_engine \
  lib/shared/pdf \
  lib/shared/documents \
  lib/shared/widgets/receipt_capture \
  lib/screens/invoices/data \
  "${pdf_test_targets[@]}"

dart run tool/generate_sample_receipt_pdf.dart /tmp/maintainiac_gate_receipt_a.pdf >/dev/null
dart run tool/generate_sample_receipt_pdf.dart /tmp/maintainiac_gate_receipt_b.pdf >/dev/null
cmp -s /tmp/maintainiac_gate_receipt_a.pdf /tmp/maintainiac_gate_receipt_b.pdf

bash tool/pdf_render_smoke_gate.sh
bash tool/pdf_golden_snapshot_gate.sh

flutter test "${pdf_test_targets[@]}" -r compact

git diff --check
