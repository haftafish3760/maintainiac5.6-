import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native cameras gate auto capture on live receipt quality', () {
    final android = File(
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraControls.kt',
    ).readAsStringSync();
    final ios = File(
      'ios/Runner/ReceiptCameraViewControllerLiveReadability.swift',
    ).readAsStringSync();

    for (final source in [android, ios]) {
      expect(source, contains('edgesReady'));
      expect(source, contains('steady'));
      expect(source, contains('lightReady'));
      expect(source, contains('qualityReviewNeeded'));
      expect(source, contains('waiting_for_edges'));
      expect(source, contains('waiting_for_steady'));
      expect(source, contains('waiting_for_light'));
      expect(source, contains('waiting_for_quality_review'));
    }
  });
}
