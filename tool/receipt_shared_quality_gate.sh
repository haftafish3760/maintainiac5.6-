#!/usr/bin/env bash
set -euo pipefail

mode="${1:-full}"

usage() {
  cat >&2 <<'USAGE'
Usage: tool/receipt_shared_quality_gate.sh [fast|pure-dart|fuel|camera|full] [camera-mode]

Modes:
  fast       Run guardrails and contract smoke checks only.
  pure-dart  Run reusable parser/fixture QA without camera/native phases.
  fuel       Run the fuel synthetic milestone plus fuel-focused parser tests.
  camera     Delegate to tool/receipt_camera_qa_gate.sh with an optional camera mode.
  full       Run the expensive shared receipt quality gate.
USAGE
  exit 64
}

case "$mode" in
  fast)
    bash tool/receipt_fast_guard_gate.sh
    flutter test \
      test/receipt_quality_gate_contract_test.dart \
      test/fuel_synthetic_parser_runner_contract_test.dart \
      test/receipt_qa_runner_contract_test.dart \
      -r compact
    ;;
  pure-dart)
    dart analyze \
      tool/maintainiac_source_audit.dart \
      tool/receipt_qa_fixtures.dart \
      tool/receipt_qa_external_fixture_loader.dart \
      tool/receipt_qa_fixture_manifest.dart \
      tool/receipt_qa_report_models.dart \
      tool/receipt_qa_scoring.dart \
      tool/receipt_qa_scoring_checks.dart \
      tool/receipt_qa_scoring_matchers.dart \
      tool/receipt_qa_scoring_privacy.dart \
      tool/receipt_qa_scoring_review.dart \
      tool/receipt_qa_runner.dart
    bash tool/receipt_fast_guard_gate.sh
    dart tool/maintainiac_source_audit.dart
    dart tool/receipt_external_fixture_schema_gate.dart
    dart run tool/receipt_qa_runner.dart --fail-under=1.0 --summary-json
    flutter test \
      test/receipt_qa_runner_contract_test.dart \
      test/receipt_qa_runner_pack_focus_test.dart \
      test/fuel_synthetic_parser_runner_contract_test.dart \
      test/receipt_quality_gate_contract_test.dart \
      -r compact
    ;;
  fuel)
    flutter analyze \
      tool/fuel_synthetic_parser_runner.dart \
      lib/screens/expenses/data/expense_receipt_fuel_parser.dart \
      lib/screens/expenses/data/fuel_parser_improvement_metadata.dart \
      lib/screens/expenses/data/fuel_economy_metrics.dart
    flutter test \
      test/fuel_synthetic_parser_runner_contract_test.dart \
      test/expense_receipt_parser_fuel_formats_test.dart \
      test/expense_receipt_parser_fuel_synthetic_matrix_test.dart \
      test/fuel_parser_improvement_metadata_test.dart \
      test/fuel_economy_metrics_test.dart \
      -r compact
    ;;
  camera)
    bash tool/receipt_camera_qa_gate.sh "${2:-milestone}"
    ;;
  full)
    bash tool/receipt_quality_gate.sh
    ;;
  *)
    usage
    ;;
esac
