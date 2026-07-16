import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native receipt cameras retain pinch zoom and disable tap focus', () {
    final android = File(
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraControls.kt',
    ).readAsStringSync();
    final ios = File(
      'ios/Runner/ReceiptCameraViewControllerControls.swift',
    ).readAsStringSync();

    expect(android, contains('ScaleGestureDetector('));
    expect(android, contains('MotionEvent.ACTION_DOWN'));
    expect(android, contains('setZoomRatio(nextZoom)'));
    expect(android, isNot(contains('FocusMeteringAction')));

    expect(ios, contains('UIPinchGestureRecognizer'));
    expect(ios, contains('cameraDevice.videoZoomFactor = nextZoom'));
    expect(ios, isNot(contains('focusPointOfInterest')));
  });
}
