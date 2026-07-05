#!/usr/bin/env bash
set -euo pipefail

# PDF gate. Keep this focused on PDF behavior, storage, privacy/security,
# invoice generation, import/export, and receipt PDF contracts. Avoid
# fragile PDF UI tests until those screens stabilize.

bash -n tool/pdf_quality_gate.sh
bash -n tool/pdf_render_smoke_gate.sh
bash -n tool/pdf_golden_snapshot_gate.sh
python3 -m py_compile tool/pdf_render_pixel_assertions.py

dart analyze \
  tool/generate_sample_invoice_pdf.dart \
  tool/generate_sample_receipt_pdf.dart \
  tool/generate_long_receipt_pdf.dart \
  lib/shared/pdf \
  lib/shared/documents/app_document_import_service.dart \
  lib/shared/documents/app_document_export_manifest.dart \
  lib/shared/documents/app_document_export_package_writer.dart \
  lib/shared/documents/app_generated_pdf_archive_service.dart \
  lib/shared/documents/app_document_models.dart \
  lib/shared/documents/app_document_store.dart \
  lib/shared/widgets/receipt_capture/receipt_pdf_inspector.dart \
  lib/shared/widgets/receipt_capture/receipt_pdf_inspection.dart \
  lib/shared/widgets/receipt_capture/receipt_pdf_limits.dart \
  lib/shared/widgets/receipt_capture/receipt_pdf_viewer_preview_plan.dart \
  lib/shared/widgets/receipt_capture/receipt_proof_storage.dart \
  lib/screens/invoices/data/invoice_pdf_export_verifier.dart \
  lib/screens/invoices/data/invoice_pdf_privacy_guard.dart \
  lib/screens/invoices/data/invoice_pdf_template_renderer.dart \
  test/app_generated_pdf_archive_recovery_test.dart \
  test/app_generated_pdf_service_test.dart \
  test/app_receipt_pdf_document_test.dart \
  test/app_document_export_manifest_test.dart \
  test/app_document_export_package_writer_test.dart \
  test/app_document_store_test.dart \
  test/cloud_backup_pdf_policy_test.dart \
  test/document_engine_operating_directive_test.dart \
  test/incoming_receipt_share_pdf_hardening_test.dart \
  test/invoice_document_engine_layout_contract_test.dart \
  test/invoice_pdf_export_verifier_contract_test.dart \
  test/invoice_pdf_preview_action_tracking_test.dart \
  test/invoice_template_pdf_factory_test.dart \
  test/invoice_pdf_money_precision_test.dart \
  test/pdf_formatters_contract_test.dart \
  test/pdf_health_diagnostics_test.dart \
  test/pdf_qa_fixture_inventory_test.dart \
  test/pdf_privacy_policy_contract_test.dart \
  test/pdf_security_policy_contract_test.dart \
  test/pdf_text_decoder_contract_test.dart \
  test/pdf_typography_contract_test.dart \
  test/receipt_pdf_hardening_test.dart \
  test/receipt_pdf_import_copy_test.dart \
  test/receipt_pdf_inspector_edge_cases_test.dart \
  test/receipt_pdf_inspector_security_flags_test.dart \
  test/receipt_pdf_performance_profile_test.dart \
  test/receipt_pdf_torture_storage_test.dart \
  test/receipt_pdf_torture_test.dart \
  test/pdf_quality_gate_contract_test.dart \
  test/pdf_cross_platform_contract_test.dart \
  test/pdf_render_gate_invoice_generator_test.dart

dart run tool/generate_sample_invoice_pdf.dart /tmp/maintainiac_gate_invoice_a.pdf >/dev/null
dart run tool/generate_sample_invoice_pdf.dart /tmp/maintainiac_gate_invoice_b.pdf >/dev/null
cmp -s /tmp/maintainiac_gate_invoice_a.pdf /tmp/maintainiac_gate_invoice_b.pdf
dart run tool/generate_sample_receipt_pdf.dart /tmp/maintainiac_gate_receipt_a.pdf >/dev/null
dart run tool/generate_sample_receipt_pdf.dart /tmp/maintainiac_gate_receipt_b.pdf >/dev/null
cmp -s /tmp/maintainiac_gate_receipt_a.pdf /tmp/maintainiac_gate_receipt_b.pdf
dart run tool/generate_long_receipt_pdf.dart /tmp/maintainiac_gate_long_receipt_a.pdf >/dev/null
dart run tool/generate_long_receipt_pdf.dart /tmp/maintainiac_gate_long_receipt_b.pdf >/dev/null
cmp -s /tmp/maintainiac_gate_long_receipt_a.pdf /tmp/maintainiac_gate_long_receipt_b.pdf

bash tool/pdf_render_smoke_gate.sh
bash tool/pdf_golden_snapshot_gate.sh

flutter test \
  test/app_generated_pdf_archive_recovery_test.dart \
  test/app_generated_pdf_service_test.dart \
  test/app_receipt_pdf_document_test.dart \
  test/app_document_export_manifest_test.dart \
  test/app_document_export_package_writer_test.dart \
  test/app_document_store_test.dart \
  test/cloud_backup_pdf_policy_test.dart \
  test/document_engine_operating_directive_test.dart \
  test/incoming_receipt_share_pdf_hardening_test.dart \
  test/invoice_document_engine_layout_contract_test.dart \
  test/invoice_pdf_export_verifier_contract_test.dart \
  test/invoice_pdf_preview_action_tracking_test.dart \
  test/invoice_template_pdf_factory_test.dart \
  test/invoice_pdf_money_precision_test.dart \
  test/pdf_formatters_contract_test.dart \
  test/pdf_health_diagnostics_test.dart \
  test/pdf_qa_fixture_inventory_test.dart \
  test/pdf_privacy_policy_contract_test.dart \
  test/pdf_security_policy_contract_test.dart \
  test/pdf_text_decoder_contract_test.dart \
  test/pdf_typography_contract_test.dart \
  test/receipt_pdf_hardening_test.dart \
  test/receipt_pdf_import_copy_test.dart \
  test/receipt_pdf_inspector_edge_cases_test.dart \
  test/receipt_pdf_inspector_security_flags_test.dart \
  test/receipt_pdf_performance_profile_test.dart \
  test/receipt_pdf_torture_storage_test.dart \
  test/receipt_pdf_torture_test.dart \
  test/pdf_quality_gate_contract_test.dart \
  test/pdf_cross_platform_contract_test.dart \
  test/pdf_render_gate_invoice_generator_test.dart \
  -r compact

git diff --check
