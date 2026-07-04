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

  test('fast guard includes real-device matrix gate', () {
    final fastGate = File('tool/receipt_fast_guard_gate.sh').readAsStringSync();

    expect(fastGate, contains('tool/receipt_real_device_matrix_gate.dart'));
  });
}
