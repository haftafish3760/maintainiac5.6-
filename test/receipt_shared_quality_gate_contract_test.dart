import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared receipt QA gate exposes canonical reusable lane entrypoints', () {
    final script = File('tool/receipt_shared_quality_gate.sh').readAsStringSync();

    expect(script, contains('tool/receipt_fast_guard_gate.sh'));
    expect(script, contains('tool/receipt_qa_runner.dart'));
    expect(script, contains('tool/fuel_synthetic_parser_runner.dart'));
    expect(script, contains('--preset=milestone'));
    expect(script, contains('--summary-json'));
    expect(script, contains('tool/receipt_camera_qa_gate.sh'));
    expect(script, contains('tool/receipt_quality_gate.sh'));
    expect(
      script,
      contains('test/fuel_synthetic_parser_runner_contract_test.dart'),
    );
    expect(script, contains('test/receipt_qa_runner_contract_test.dart'));
    expect(script, contains('test/receipt_quality_gate_contract_test.dart'));
  });

  test('receipt QA backbone doc points every lane at a reusable shared command', () {
    final doc = File('docs/receipt_qa_backbone.md').readAsStringSync();

    expect(doc, contains('tool/receipt_shared_quality_gate.sh fast'));
    expect(doc, contains('tool/receipt_shared_quality_gate.sh pure-dart'));
    expect(doc, contains('tool/receipt_shared_quality_gate.sh fuel'));
    expect(doc, contains('tool/receipt_shared_quality_gate.sh camera'));
    expect(doc, contains('tool/receipt_shared_quality_gate.sh full'));
    expect(doc, contains('Pass logs are evidence, not executable QA.'));
    expect(doc, contains('Keep executable QA in `tool/` and `test/`.'));
  });
}
