import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('active receipt camera docs keep continuous focus primary', () {
    const activeDocs = [
      'docs/receipt_camera_ocr_product_standard.md',
      'docs/receipt_real_device_test_script.md',
      'docs/receipt_camera_ocr_state_of_art_spec.md',
      'docs/receipt_camera_ocr_pipeline_handoff_report.md',
    ];

    for (final path in activeDocs) {
      final text = File(path).readAsStringSync().toLowerCase();

      expect(
        text,
        contains('continuous autofocus'),
        reason: '$path must name continuous autofocus as the product path.',
      );
      expect(
        text,
        isNot(contains('tap-to-focus')),
        reason: '$path must not reintroduce tap-focus-first guidance.',
      );
      expect(
        text,
        isNot(contains('tap the receipt text')),
        reason: '$path must not ask users to tap receipt text for focus.',
      );
    }
  });
}
