import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native camera reset keeps Receipt Assist opt-in', () async {
    final android = await File(
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraSettingsDialog.kt',
    ).readAsString();
    final ios = await File(
      'ios/Runner/ReceiptCameraViewControllerSessionSettings.swift',
    ).readAsString();

    expect(android, contains('assistedReceiptFill = false'));
    expect(ios, contains('assistedReceiptFill = false'));
    expect(android, isNot(contains('assistedReceiptFill = true')));
    expect(ios, isNot(contains('assistedReceiptFill = true')));
  });
}
