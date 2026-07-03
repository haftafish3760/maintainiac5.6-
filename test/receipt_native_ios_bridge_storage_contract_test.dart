import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_ios_bridge_source_readers.dart';

void main() {
  test(
    'iOS native receipt camera reports close exposure storage and Xcode contracts',
    () async {
      final sources = await readIosReceiptCameraBridgeSources();
      final cameraController = sources.cameraController;
      final xcodeProject = sources.xcodeProject;

      expect(cameraController, contains('"closeAction": closeAction'));
      expect(
        cameraController,
        contains(
          '"closeCapturedPhotoPolicy": "back_returns_captured_sections_before_cancel"',
        ),
      );
      expect(
        cameraController,
        contains('"closeCapturedPhotoOutcome": closeCapturedPhotoOutcome()'),
      );
      expect(cameraController, contains('func closeCapturedPhotoOutcome()'));
      expect(cameraController, contains('"waiting_for_in_flight_capture"'));
      expect(cameraController, contains('"capture_failed_after_close"'));
      expect(
        cameraController,
        contains('"closeResultDelivered": closeResultDelivered'),
      );
      expect(
        cameraController,
        contains('"lastAutoExposureDecision": lastAutoExposureDecision'),
      );
      expect(
        cameraController,
        contains(
          '"lastPreCaptureExposureDecision": lastPreCaptureExposureDecision',
        ),
      );
      expect(
        cameraController,
        contains(
          '"lastPreCaptureExposureSkipReason": lastPreCaptureExposureSkipReason',
        ),
      );
      expect(cameraController, contains('func preCaptureExposureOutcome()'));
      expect(
        cameraController,
        contains('"preCaptureExposureOutcome": preCaptureExposureOutcome()'),
      );
      expect(cameraController, contains('"lifted_for_dim_receipt"'));
      expect(cameraController, contains('"kept_native_auto"'));
      expect(
        cameraController,
        contains(
          '"preCaptureExposureAdjustmentCount": preCaptureExposureAdjustmentCount',
        ),
      );
      expect(
        cameraController,
        contains('preCaptureExposureAdjustmentConfirmedCount'),
      );
      expect(
        cameraController,
        contains(
          '"preCaptureExposureAdjustmentConfirmedCount": preCaptureExposureAdjustmentConfirmedCount',
        ),
      );
      expect(
        cameraController,
        contains(
          'var preCaptureExposurePolicy = "receipt_paper_metering_dim_rescue_v2_manual_slider"',
        ),
      );
      expect(
        cameraController,
        contains('arguments["preCaptureExposurePolicy"]'),
      );
      expect(
        cameraController,
        contains('"preCaptureExposurePolicy": preCaptureExposurePolicy'),
      );
      expect(cameraController, contains('if latestFrameBrightness <= 55'));
      expect(cameraController, contains('return min(current + 1.25, maxBias)'));
      expect(cameraController, contains('if latestFrameBrightness <= 70'));
      expect(cameraController, contains('return min(current + 1.0, maxBias)'));
      expect(cameraController, contains('if latestFrameBrightness <= 104'));
      expect(cameraController, contains('if latestFrameBrightness <= 138'));
      expect(cameraController, contains('if latestFrameBrightness <= 150'));
      expect(cameraController, contains('return min(current + 0.5, maxBias)'));
      expect(
        cameraController,
        contains(
          'if latestFrameBrightness >= 150 && latestFrameBrightness <= 238',
        ),
      );
      expect(
        cameraController,
        contains('brightness >= autoCaptureMinBrightness'),
      );
      expect(cameraController, contains('"brightened_before_capture"'));
      expect(cameraController, contains('"dimmed_before_capture"'));
      expect(
        cameraController,
        contains('"pre_capture_brightened_still_too_dark"'),
      );
      expect(cameraController, contains('"pre_capture_brightened_still_dim"'));
      expect(
        cameraController,
        contains(
          '"lastAutoExposureBrightnessBucket": lastAutoExposureBrightnessBucket',
        ),
      );
      expect(
        cameraController,
        contains('"lastAutoExposureCandidate": lastAutoExposureCandidate'),
      );
      expect(
        cameraController,
        contains(
          '"autoExposureCandidateFrameCount": autoExposureCandidateFrameCount',
        ),
      );
      expect(
        cameraController,
        contains('"lastAutoExposureBias": Double(lastAutoExposureBias)'),
      );
      expect(
        cameraController,
        contains(
          '"lastPreCaptureExposureTargetBias": Double(lastPreCaptureExposureTargetBias)',
        ),
      );
      expect(cameraController, contains('"focusMode": focusMode'));
      expect(cameraController, contains('"exposureMode": exposureMode'));
      expect(
        cameraController,
        contains('"whiteBalanceMode": whiteBalanceMode'),
      );
      expect(
        cameraController,
        contains('"whiteBalanceLockEnabled": whiteBalanceLockEnabled'),
      );
      expect(
        cameraController,
        contains('"focusLockAttemptCount": focusLockAttemptCount'),
      );
      expect(
        cameraController,
        contains('"focusLockSuccessCount": focusLockSuccessCount'),
      );
      expect(
        cameraController,
        contains('"exposureLockSuccessCount": exposureLockSuccessCount'),
      );
      expect(
        cameraController,
        contains(
          '"whiteBalanceLockAttemptCount": whiteBalanceLockAttemptCount',
        ),
      );
      expect(
        cameraController,
        contains(
          '"whiteBalanceLockSuccessCount": whiteBalanceLockSuccessCount',
        ),
      );
      expect(
        cameraController,
        contains('"whiteBalanceLockStatus": whiteBalanceLockStatus'),
      );
      expect(
        cameraController,
        contains(
          'arguments["storageSafetyLevel"] as? String ?? dataSaverLevel',
        ),
      );
      expect(cameraController, contains('switch dataSaverLevel'));
      expect(
        cameraController,
        contains('arguments["storageConstrained"] as? Bool ?? false'),
      );
      expect(
        cameraController,
        contains('arguments["storageSafetyReason"] as? String ?? "normal"'),
      );
      expect(
        cameraController,
        contains(
          'arguments["workloadProtectionPolicy"] as? String ?? "balanced_workload"',
        ),
      );
      expect(cameraController, contains('storageSafetyDetail'));
      expect(cameraController, contains('Keeps long receipts lighter'));
      expect(
        cameraController,
        contains('"storageSafetyLevel": storageSafetyLevel'),
      );
      expect(
        cameraController,
        contains('"storageConstrained": storageConstrained'),
      );
      expect(
        cameraController,
        contains('"storageSafetyReason": storageSafetyReason'),
      );
      expect(
        cameraController,
        contains('"workloadProtectionPolicy": workloadProtectionPolicy'),
      );
      expect(cameraController, contains('ocrUsesOriginalFirst'));
      expect(
        cameraController,
        contains('"saveOriginalTemporarily": saveOriginalTemporarily'),
      );
      expect(
        cameraController,
        contains('"queueAcceptedCaptureLocally": queueAcceptedCaptureLocally'),
      );
      expect(
        cameraController,
        contains('"ocrUsesOriginalFirst": ocrUsesOriginalFirst'),
      );
      expect(cameraController, contains('hasPreviousSectionGuide'));
      expect(cameraController, isNot(contains('UIImagePickerController')));
      expect(cameraController, isNot(contains('PHPickerViewController')));

      expect(xcodeProject, contains('ReceiptCameraViewController.swift'));
      expect(
        xcodeProject,
        contains('ReceiptCameraViewController.swift in Sources'),
      );
    },
  );
}
