import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt doc size gate covers OCR and Firebase sync docs', () {
    final script = File('tool/receipt_doc_size_gate.sh').readAsStringSync();

    expect(script, contains('expense_command_center_ocr_contract*.md'));
    expect(script, contains('firebase_sync*schema_spec.md'));
    expect(script, contains('receipt_camera_ocr*.md'));
    expect(script, contains('receipt_camera_ocr_handoff_*.md'));
    expect(script, contains('receipt_camera_world_class_readiness.md'));
    expect(script, contains('receipt_real_device_test_script.md'));
    expect(script, contains('500-line receipt doc limit'));
  });
}
