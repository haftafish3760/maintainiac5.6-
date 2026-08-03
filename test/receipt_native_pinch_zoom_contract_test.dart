import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native receipt cameras retain pinch zoom and disable tap focus', () {
    final android = File(
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraControls.kt',
    ).readAsStringSync();
    final androidCameraBinding = File(
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraAnalysis.kt',
    ).readAsStringSync();
    final androidCapture = File(
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraCaptureClose.kt',
    ).readAsStringSync();
    final ios = File(
      'ios/Runner/ReceiptCameraViewControllerControls.swift',
    ).readAsStringSync();

    expect(android, contains('ScaleGestureDetector('));
    final androidActivity = File(
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt',
    ).readAsStringSync();

    expect(androidActivity, contains('override fun dispatchTouchEvent'));
    expect(androidActivity, contains('scaleGestureDetector?.onTouchEvent(event)'));
    expect(
      android,
      isNot(contains('previewView.setOnTouchListener')),
    );
    expect(android, contains('setZoomRatio(nextZoom)'));
    expect(android, contains('pinchZoomGestureStartRatio = nextZoom'));
    expect(
      android,
      contains('completeZoomApplication(zoomRequestId, applied)'),
    );
    expect(
      android,
      contains(
        'capturePhoto(trigger = queuedTrigger, recordUserIntent = false)',
      ),
    );
    expect(androidCapture, contains('if (zoomApplyInFlight)'));
    expect(
      androidCapture,
      contains('pendingCaptureAfterZoomTrigger = trigger'),
    );
    expect(
      androidCapture,
      contains('Applying zoom, then capturing your receipt.'),
    );
    expect(android, isNot(contains('FocusMeteringAction')));
    expect(androidCameraBinding, contains('previewView.viewPort'));
    expect(androidCameraBinding, contains('UseCaseGroup.Builder()'));
    expect(androidCameraBinding, contains('.setViewPort(captureViewPort)'));
    expect(androidCameraBinding, contains('.addUseCase(stillCapture)'));
    expect(
      androidCameraBinding,
      contains('val initialZoom = minZoom.coerceIn(1.0, maxZoom)'),
    );

    expect(ios, contains('UIPinchGestureRecognizer'));
    expect(ios, contains('cameraDevice.videoZoomFactor = nextZoom'));
    expect(ios, isNot(contains('focusPointOfInterest')));
  });
}
