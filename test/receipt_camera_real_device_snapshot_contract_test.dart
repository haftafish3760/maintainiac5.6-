import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'real-device snapshot script records metadata without touching phone UI',
    () {
      final script = File(
        'tool/receipt_camera_real_device_snapshot.sh',
      ).readAsStringSync();

      expect(script, contains('metadata_only_no_install_no_ui_navigation'));
      expect(script, contains('flutter devices'));
      expect(script, contains('adb devices -l'));
      expect(script, contains('xcrun xctrace list devices'));
      expect(
        script,
        contains('/tmp/maintainiac_receipt_camera_device_snapshot'),
      );
      expect(
        script,
        contains('do not treat this metadata snapshot as capture proof'),
      );
      expect(script, isNot(contains('flutter install')));
      expect(script, isNot(contains('flutter run')));
      expect(script, isNot(contains('adb shell input')));
      expect(script, isNot(contains('uiautomator')));
    },
  );

  test('camera gates include real-device snapshot syntax coverage', () {
    final cameraGate = File(
      'tool/receipt_camera_qa_gate.sh',
    ).readAsStringSync();
    final fastGate = File('tool/receipt_fast_guard_gate.sh').readAsStringSync();

    expect(cameraGate, contains('tool/receipt_camera_real_device_snapshot.sh'));
    expect(fastGate, contains('tool/receipt_camera_real_device_snapshot.sh'));
  });
}
