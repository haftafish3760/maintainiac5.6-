import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('active receipt camera docs keep continuous focus primary', () {
    const activeDocs = [
      'docs/receipt_camera_ocr_product_standard.md',
      'docs/receipt_real_device_test_script.md',
      'docs/receipt_camera_ocr_state_of_art_spec.md',
      'docs/receipt_camera_ocr_pipeline_handoff_report.md',
      'docs/receipt_native_camera_service_spec.md',
      'docs/receipt_camera_ocr_handoff_2026_07_03.md',
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
        isNot(contains('tap-focus')),
        reason: '$path must not keep tap-focus wording in active docs.',
      );
      expect(
        text,
        isNot(contains('tap the receipt text')),
        reason: '$path must not ask users to tap receipt text for focus.',
      );
      expect(
        text,
        isNot(contains('tap to focus')),
        reason: '$path must not list tap-to-focus behavior as active flow.',
      );
      expect(
        text,
        isNot(contains('- tap focus.')),
        reason: '$path must not list tap focus as an active camera control.',
      );
      expect(
        text,
        isNot(contains('focus lock after sharp')),
        reason: '$path must not list focus lock as an active camera control.',
      );
      expect(
        text,
        isNot(contains('auto exposure lock')),
        reason:
            '$path must not list exposure lock as an active camera control.',
      );
      expect(
        text,
        isNot(contains('white balance auto/locked/manual')),
        reason: '$path must not list white-balance lock as an active control.',
      );
    }
  });
}
