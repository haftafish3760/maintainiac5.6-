#!/usr/bin/env bash
set -euo pipefail

# Expensive top-level receipt gate. Use this after receipt source, parser,
# QA-runner, or gate-composition changes. For docs/log/shell-only guardrail
# edits, use tool/receipt_fast_guard_gate.sh instead.

dart analyze \
  tool/maintainiac_source_audit.dart \
  tool/receipt_camera_io_guard.dart \
  tool/receipt_camera_footprint_audit.dart \
  tool/receipt_qa_fixtures.dart \
  tool/receipt_qa_fixtures_adjustment_retail.dart \
  tool/receipt_qa_fixtures_fuel.dart \
  tool/receipt_qa_fixtures_long_receipt.dart \
  tool/receipt_qa_fixtures_maintenance.dart \
  tool/receipt_qa_report_models.dart \
  tool/receipt_qa_fixture_manifest.dart \
  tool/receipt_qa_scoring.dart \
  tool/receipt_qa_scoring_checks.dart \
  tool/receipt_qa_scoring_matchers.dart \
  tool/receipt_qa_scoring_review.dart \
  tool/fuel_synthetic_parser_runner.dart \
  tool/receipt_qa_runner.dart

bash tool/receipt_fast_guard_gate.sh
bash tool/receipt_cleanup_log_gate.sh
bash tool/receipt_formatter_projection_gate.sh
dart tool/maintainiac_source_audit.dart
dart tool/receipt_camera_io_guard.dart
dart tool/receipt_camera_footprint_audit.dart
dart run tool/receipt_qa_runner.dart --fail-under=1.0 --summary-json
dart run tool/fuel_synthetic_parser_runner.dart --preset=milestone --fail-under=1.0 --summary-json
flutter test \
  test/fuel_synthetic_parser_runner_contract_test.dart \
  test/receipt_qa_runner_contract_test.dart \
  test/receipt_qa_runner_pack_focus_test.dart \
  test/receipt_camera_footprint_audit_test.dart \
  -r compact
bash tool/receipt_camera_pipeline_gate.sh

flutter test \
  test/receipt_ocr_service_test.dart \
  test/receipt_ocr_service_review_contract_test.dart \
  test/receipt_processing_contract_test.dart \
  -r compact
