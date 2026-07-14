import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'native ghost slices normalize visual orientation before cropping',
    () async {
      final android = await File(
        'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraPreviousSectionGuide.kt',
      ).readAsString();
      final ios = await File(
        'ios/Runner/ReceiptCameraViewControllerPreviousSectionGuide.swift',
      ).readAsString();
      final gradle = await File('android/app/build.gradle.kts').readAsString();

      expect(gradle, contains('androidx.exifinterface:exifinterface:1.4.2'));
      expect(android, contains('ExifInterface(file.absolutePath)'));
      expect(android, contains('ExifInterface.ORIENTATION_ROTATE_90'));
      expect(android, contains('ExifInterface.ORIENTATION_ROTATE_180'));
      expect(android, contains('ExifInterface.ORIENTATION_ROTATE_270'));
      expect(android, contains('ExifInterface.ORIENTATION_TRANSPOSE'));
      expect(android, contains('ExifInterface.ORIENTATION_TRANSVERSE'));
      expect(
        android,
        contains(
          'receiptGhostBitmapWithVisualOrientation(file) ?: return null',
        ),
      );

      expect(ios, contains('func normalizedReceiptGhostGuideImage'));
      expect(
        ios,
        contains(
          'let normalizedImage = normalizedReceiptGhostGuideImage(image) ?? image',
        ),
      );
      expect(ios, contains('orientation: .up'));
    },
  );
}
