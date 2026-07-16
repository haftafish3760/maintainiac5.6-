import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native camera reset preserves receipt and storage preferences', () async {
    final android = await File(
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraSettingsDialog.kt',
    ).readAsString();
    final ios = await File(
      'ios/Runner/ReceiptCameraViewControllerSessionSettings.swift',
    ).readAsString();

    final androidReset = android.substring(
      android.indexOf(
        'internal fun ReceiptCameraActivity.resetReceiptCameraDefaults()',
      ),
    );
    final iosReset = ios.substring(
      ios.indexOf('func resetReceiptCameraDefaults()'),
    );

    for (final reset in [androidReset, iosReset]) {
      expect(reset, contains('longReceiptMode = false'));
      expect(reset, contains('autoCaptureEnabled = false'));
      expect(reset, isNot(contains('assistedReceiptFill =')));
      expect(reset, isNot(contains('reviewDepth =')));
      expect(reset, isNot(contains('dataSaverLevel =')));
    }
  });
}
