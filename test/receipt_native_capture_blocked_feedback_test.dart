import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory.current.path;
  final android = File(
    '$root/android/app/src/main/kotlin/com/maintainiac/'
    'ReceiptCameraCaptureClose.kt',
  ).readAsStringSync();
  final androidExposure = File(
    '$root/android/app/src/main/kotlin/com/maintainiac/'
    'ReceiptCameraPreCaptureExposure.kt',
  ).readAsStringSync();
  final androidAnalysis = File(
    '$root/android/app/src/main/kotlin/com/maintainiac/'
    'ReceiptCameraAnalysis.kt',
  ).readAsStringSync();
  final iosSession = File(
    '$root/ios/Runner/ReceiptCameraViewControllerSessionSettings.swift',
  ).readAsStringSync();
  final ios = File(
    '$root/ios/Runner/ReceiptCameraViewControllerCapture.swift',
  ).readAsStringSync();
  final reviewCaptureActions = File(
    '$root/lib/shared/widgets/receipt_capture/'
    'receipt_photo_review_capture_actions.dart',
  ).readAsStringSync();

  for (final source in [android, ios]) {
    test(
      'manual capture reports blocked states without affecting auto capture',
      () {
        expect(source, contains('reportManualCaptureBlocked'));
        expect(source, contains('capture_in_flight'));
        expect(source, contains('closing_camera'));
        expect(source, contains('camera_surface_inactive'));
        expect(source, contains('camera_surface_inactive_after_prepare'));
        expect(source, contains('no_camera'));
        expect(source, contains('Saving the last receipt photo. Please wait.'));
        expect(
          source,
          contains('Opening receipt photo review. Your photo is being kept.'),
        );
        expect(
          source,
          contains(
            'Receipt camera is still getting ready. Try again in a moment.',
          ),
        );
        expect(
          source,
          contains(
            'Receipt camera is unavailable. Check camera permission, then try again.',
          ),
        );
      },
    );

    test('only intentional manual capture updates guidance', () {
      expect(source, contains('manual_shutter'));
      expect(source, contains('manual_add_photo'));
      expect(
        source,
        contains(
          'trigger == "manual_shutter" || trigger == "manual_add_photo"',
        ),
      );
      expect(source, contains('auto_capture'));
      expect(source, contains('lastCaptureTrigger'));
      expect(source, contains('return'));
    });
  }

  test('exposure preparation cannot leave a manual shutter stuck disabled', () {
    for (final source in [androidExposure, ios]) {
      expect(
        source,
        contains('camera_surface_inactive_during_exposure_prepare'),
      );
      expect(source, contains('captureBlockedSurfaceInactiveCount += 1'));
      expect(source, contains('lastCaptureTrigger'));
      expect(source, contains('reportManualCaptureBlocked'));
      expect(source, contains('shutterButton.isEnabled = true'));
    }
  });

  test('camera startup failure leaves an actionable recovery state', () {
    for (final source in [androidAnalysis, iosSession]) {
      expect(
        source,
        contains('lastCaptureBlockReason = "camera_start_failed"'),
      );
      expect(
        source,
        contains('latestAutoCaptureStatus = "camera_unavailable"'),
      );
      expect(source, contains('shutterButton.isEnabled = true'));
      expect(
        source,
        contains(
          'Receipt camera could not open. Check permission, then go back and try again.',
        ),
      );
    }
  });

  test('unavailable native camera returns an actionable recovery choice', () {
    expect(reviewCaptureActions, contains('!nativeCapabilities.canOpenReceiptCamera'));
    expect(
      reviewCaptureActions,
      contains(
        'Receipt camera is unavailable right now. Check permission, then try again or add a photo from your device.',
      ),
    );
  });
}
