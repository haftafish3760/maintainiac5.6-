import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'native receipt camera keeps saved proof size behind first captured receipt',
    () async {
      final androidSettings = await File(
        'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraSettingsDialog.kt',
      ).readAsString();
      final iosSettings = await File(
        'ios/Runner/ReceiptCameraViewControllerSessionSettings.swift',
      ).readAsString();
      final iosCopy = await File(
        'ios/Runner/ReceiptCameraViewControllerSettingsCopy.swift',
      ).readAsString();

      expect(
        androidSettings,
        contains(
          'Receipt Assist, saved-photo, and account preferences stay in Expense Settings.',
        ),
      );
      expect(iosSettings, contains('if !capturedPhotoPaths.isEmpty {'));
      expect(
        iosCopy,
        contains('Saved proof size appears after your first receipt photo is captured. Capture first, then review the saved proof size with real receipt proof.'),
      );
      expect(
        iosCopy,
        contains('Saved proof size stays hidden until there is real receipt proof to review.'),
      );
    },
  );
}
