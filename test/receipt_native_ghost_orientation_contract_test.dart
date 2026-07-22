import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native ghost slices normalize visual orientation before cropping', () {
    final android = File(
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraPreviousSectionGuide.kt',
    ).readAsStringSync();
    final ios = File(
      'ios/Runner/ReceiptCameraViewControllerPreviousSectionGuide.swift',
    ).readAsStringSync();
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();

    expect(gradle, contains('androidx.exifinterface:exifinterface:1.4.2'));
    expect(android, contains('ExifInterface(file.absolutePath)'));
    expect(android, contains('ExifInterface.ORIENTATION_ROTATE_90'));
    expect(android, contains('ExifInterface.ORIENTATION_TRANSPOSE'));
    expect(android, contains('receiptGhostBitmapWithVisualOrientation(file)'));
    expect(ios, contains('func normalizedReceiptGhostGuideImage'));
    expect(ios, contains('normalizedReceiptGhostGuideImage(image) ?? image'));
    expect(ios, contains('orientation: .up'));
  });
}
