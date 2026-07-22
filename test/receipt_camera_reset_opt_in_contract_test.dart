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

    expect(
      android,
      contains(
        'Expense and account preferences are deliberately not reset here',
      ),
    );
    expect(ios, contains('camera reset must preserve it'));
    expect(android, isNot(contains('assistedReceiptFill =')));
    expect(ios, isNot(contains('assistedReceiptFill =')));
  });
}
