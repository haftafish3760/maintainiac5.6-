import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('real-device receipt camera matrix gate passes active script', () async {
    final result = await Process.run('dart', [
      'tool/receipt_real_device_matrix_gate.dart',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout,
      contains('Receipt real-device matrix gate: required='),
    );
  });

  test('real-device matrix gate stays scoped to receipt camera front-door proof', () {
    final gate = File(
      'tool/receipt_real_device_matrix_gate.dart',
    ).readAsStringSync();

    expect(gate, contains("'Add Receipt'"));
    expect(gate, contains("'Capture Photo'"));
    expect(gate, contains("'Upload Photos'"));
    expect(gate, contains("'Upload PDF/File'"));
    expect(gate, contains("'Paste/Text'"));
    expect(gate, contains("'Receipt Assist question'"));
    expect(gate, contains("'camera opens immediately after the choice'"));
    expect(gate, contains("'preview reads as full-screen'"));
    expect(gate, contains("'settings gear'"));
    expect(gate, contains("'shutter is round and centered'"));
    expect(gate, contains("'preview tap focus stays off limits'"));
    expect(gate, contains("'## Flow 7: PDF Receipt Import'"));
    expect(gate, contains("'Purpose:\\n- Prove PDF receipts are handled safely.'"));
  });

  test('fast guard includes real-device matrix gate', () {
    final fastGate = File('tool/receipt_fast_guard_gate.sh').readAsStringSync();

    expect(fastGate, contains('tool/receipt_real_device_matrix_gate.dart'));
  });

  test('phase9 gate also carries the real-device result gate lane', () {
    final cameraGate = File('tool/receipt_camera_qa_gate.sh').readAsStringSync();
    final changedGate = File(
      'tool/receipt_camera_changed_gate.sh',
    ).readAsStringSync();

    expect(cameraGate, contains('tool/receipt_real_device_result_gate.dart'));
    expect(cameraGate, contains('test/receipt_real_device_result_gate_test.dart'));
    expect(changedGate, contains('tool/receipt_real_device_result_gate.dart'));
    expect(changedGate, contains('test/receipt_real_device_result_gate_test.dart'));
  });
}
