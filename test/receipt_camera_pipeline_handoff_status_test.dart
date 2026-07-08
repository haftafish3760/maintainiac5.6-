import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('active OCR pipeline handoff report stays evidence-first instead of percentage-first', () {
    final report = File(
      'docs/receipt_camera_ocr_pipeline_handoff_report.md',
    ).readAsStringSync();

    expect(report, contains('## Current Status Rule'));
    expect(report, contains('Do not treat this handoff as a live percentage scoreboard.'));
    expect(report, contains('docs/receipt_camera_completion_map.md'));
    expect(report, contains('docs/receipt_camera_roadmap.md'));
    expect(report, contains('docs/receipt_camera_ocr_master_pass_plan.md'));
    expect(
      report,
      contains('The current late lane is non-UI hardening and milestone validation'),
    );
    expect(
      report,
      contains('Real-device capture proof still requires manual receipt flows'),
    );
    expect(report, isNot(contains('## Current Completion Estimate')));
    expect(report, isNot(contains('Native camera foundation: about 55-60%')));
    expect(report, isNot(contains('Whole local receipt camera/OCR/parser system: about 45-50%')));
    expect(report, isNot(contains('roughly 55-60% done')));
  });
}
