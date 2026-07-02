import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt quality gate requires perfect pure Dart QA score', () {
    final script = File('tool/receipt_quality_gate.sh').readAsStringSync();

    expect(script, contains('dart run tool/receipt_qa_runner.dart'));
    expect(script, contains('--fail-under=1.0'));
    expect(script, contains('--summary-json'));
    expect(script, isNot(contains('--json')));
    expect(script, isNot(contains('--fail-under=0.95')));
    expect(script, contains('bash tool/receipt_fast_guard_gate.sh'));
    expect(script, contains('bash tool/receipt_formatter_projection_gate.sh'));
    expect(script, contains('tool/receipt_camera_footprint_audit.dart'));
    expect(script, contains('tool/receipt_qa_report_models.dart'));
    expect(script, contains('tool/receipt_qa_fixture_manifest.dart'));
    expect(script, contains('tool/receipt_qa_scoring.dart'));
    expect(script, contains('tool/receipt_qa_scoring_review.dart'));
    expect(script, contains('tool/receipt_qa_fixtures_long_receipt.dart'));
    expect(script, contains('flutter test'));
    expect(script, contains('test/receipt_qa_runner_contract_test.dart'));
    expect(script, contains('test/receipt_qa_runner_pack_focus_test.dart'));
    expect(script, contains('test/receipt_camera_footprint_audit_test.dart'));
    expect(script, contains('bash tool/receipt_camera_pipeline_gate.sh'));
  });
}
