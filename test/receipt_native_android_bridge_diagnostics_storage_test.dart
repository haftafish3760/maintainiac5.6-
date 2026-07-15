import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_android_bridge_source_readers.dart';

void main() {
  test(
    'Android native receipt camera reports diagnostics storage and platform dependencies',
    () async {
      final sources = await readAndroidReceiptCameraBridgeSources();
      final cameraActivity = sources.cameraActivity;
      final gradle = sources.gradle;
      final manifest = sources.manifest;

      expect(
        cameraActivity,
        contains('"exposureSliderEnabled" to exposureSliderEnabled'),
      );
      expect(
        cameraActivity,
        contains('"exposureResetEnabled" to exposureResetEnabled'),
      );
      expect(
        cameraActivity,
        contains('"nativeControlContractTags" to nativeControlContractTags'),
      );
      expect(cameraActivity, contains('manualShutterAlwaysAvailable'));
      expect(
        cameraActivity,
        contains('"autoCaptureAllowed" to autoCaptureAllowed'),
      );
      expect(
        cameraActivity,
        contains(
          '"autoCaptureCurrentlyAllowed" to isAutoCaptureCurrentlyAllowed()',
        ),
      );
      expect(
        cameraActivity,
        contains(
          '"autoCaptureSafetyPolicy" to "optional_manual_shutter_always_available"',
        ),
      );
      expect(
        cameraActivity,
        contains(
          '"manualCapturePolicy" to "guidance_advisory_manual_shutter_always_allowed"',
        ),
      );
      expect(cameraActivity, contains('"closeAction" to closeAction'));
      expect(
        cameraActivity,
        contains('"closeCapturedPhotoPolicy" to closeCapturedPhotoPolicy'),
      );
      expect(
        cameraActivity,
        contains('"closeDuringCapturePolicy" to closeDuringCapturePolicy'),
      );
      expect(
        cameraActivity,
        contains('"closeNoPhotoPolicy" to closeNoPhotoPolicy'),
      );
      expect(
        cameraActivity,
        contains(
          '"capturedPhotoReviewDestination" to capturedPhotoReviewDestination',
        ),
      );
      expect(
        cameraActivity,
        contains('Back keeps captured photos and opens receipt photo review.'),
      );
      expect(
        cameraActivity,
        contains('Back closes the camera when no receipt photo was captured.'),
      );
      expect(
        cameraActivity,
        contains('"closeCapturedPhotoOutcome" to closeCapturedPhotoOutcome()'),
      );
      expect(
        cameraActivity,
        contains('"nextReceiptSectionNumber" to nextReceiptSectionNumber()'),
      );
      expect(
        cameraActivity,
        contains(
          'if (previousSectionReasonCode == "missing_bottom_edge_and_totals")',
        ),
      );
      expect(cameraActivity, contains('"Add Bottom"'));
      expect(
        cameraActivity,
        contains('Add bottom receipt section with overlap from this photo'),
      );
      expect(
        cameraActivity,
        contains('"nextReceiptSectionNumber" to nextReceiptSectionNumber()'),
      );
      expect(
        cameraActivity,
        contains(
          'internal fun ReceiptCameraActivity.closeCapturedPhotoOutcome()',
        ),
      );
      expect(cameraActivity, contains('"waiting_for_in_flight_capture"'));
      expect(cameraActivity, contains('"capture_failed_after_close"'));
      expect(
        cameraActivity,
        contains('"capture_failed_returned_existing_sections"'),
      );
      expect(
        cameraActivity.indexOf(
          'closeAction == "back_capture_failed_returned_existing_sections"',
        ),
        lessThan(
          cameraActivity.indexOf('closeAction.contains("capture_failed")'),
        ),
      );
      expect(
        cameraActivity,
        contains('"closeResultDelivered" to closeResultDelivered'),
      );
      expect(
        cameraActivity,
        contains('"lastAutoExposureDecision" to lastAutoExposureDecision'),
      );
      expect(
        cameraActivity,
        contains(
          '"lastPreCaptureExposureDecision" to lastPreCaptureExposureDecision',
        ),
      );
      expect(
        cameraActivity,
        contains(
          '"lastPreCaptureExposureSkipReason" to lastPreCaptureExposureSkipReason',
        ),
      );
      expect(
        cameraActivity,
        contains(
          'internal fun ReceiptCameraActivity.preCaptureExposureOutcome()',
        ),
      );
      expect(
        cameraActivity,
        contains('"preCaptureExposureOutcome" to preCaptureExposureOutcome()'),
      );
      expect(cameraActivity, contains('"lifted_for_dim_receipt"'));
      expect(cameraActivity, contains('"kept_native_auto"'));
      expect(cameraActivity, contains('"aborted_camera_closing"'));
      expect(
        cameraActivity,
        contains(
          '"preCaptureExposureAdjustmentCount" to preCaptureExposureAdjustmentCount',
        ),
      );
      expect(
        cameraActivity,
        contains('preCaptureExposureAdjustmentConfirmedCount'),
      );
      expect(
        cameraActivity,
        contains(
          '"preCaptureExposureAdjustmentConfirmedCount" to preCaptureExposureAdjustmentConfirmedCount',
        ),
      );
      expect(
        cameraActivity,
        contains(
          'internal var preCaptureExposurePolicy = "receipt_paper_metering_dim_rescue_v2_manual_slider"',
        ),
      );
      expect(
        cameraActivity,
        contains('intent.getStringExtra("preCaptureExposurePolicy")'),
      );
      expect(
        cameraActivity,
        contains('"preCaptureExposurePolicy" to preCaptureExposurePolicy'),
      );
      expect(
        cameraActivity,
        contains(
          'latestFrameBrightness <= 55.0 -> (current + 4).coerceAtMost(range.upper)',
        ),
      );
      expect(
        cameraActivity,
        contains(
          'latestFrameBrightness <= 70.0 -> (current + 3).coerceAtMost(range.upper)',
        ),
      );
      expect(
        cameraActivity,
        contains(
          'latestFrameBrightness <= 104.0 -> (current + 1).coerceAtMost(range.upper)',
        ),
      );
      expect(
        cameraActivity,
        isNot(contains('latestFrameBrightness <= 138.0 ->')),
      );
      expect(
        cameraActivity,
        isNot(contains('latestFrameBrightness <= 150.0 ->')),
      );
      expect(cameraActivity, contains('latestFrameBrightness in 104.0..238.0'));
      expect(
        cameraActivity,
        contains(
          'brightness in autoCaptureMinBrightness..autoCaptureMaxBrightness',
        ),
      );
      expect(cameraActivity, contains('"brightened_before_capture"'));
      expect(cameraActivity, contains('"dimmed_before_capture"'));
      expect(
        cameraActivity,
        contains('"pre_capture_brightened_still_too_dark"'),
      );
      expect(cameraActivity, contains('"pre_capture_brightened_still_dim"'));
      expect(
        cameraActivity,
        contains(
          '"lastPreCaptureExposureTargetIndex" to lastPreCaptureExposureTargetIndex',
        ),
      );
      expect(
        cameraActivity,
        contains(
          '"lastAutoExposureBrightnessBucket" to lastAutoExposureBrightnessBucket',
        ),
      );
      expect(
        cameraActivity,
        contains('"lastAutoExposureCandidate" to lastAutoExposureCandidate'),
      );
      expect(
        cameraActivity,
        contains(
          '"autoExposureCandidateFrameCount" to autoExposureCandidateFrameCount',
        ),
      );
      expect(
        cameraActivity,
        contains('"lastAutoExposureIndex" to lastAutoExposureIndex'),
      );
      expect(cameraActivity, contains('"focusMode" to focusMode'));
      expect(cameraActivity, contains('"exposureMode" to exposureMode'));
      expect(
        cameraActivity,
        contains('"whiteBalanceMode" to whiteBalanceMode'),
      );
      expect(cameraActivity, contains('"whiteBalanceLockEnabled" to false'));
      expect(
        cameraActivity,
        isNot(contains('"whiteBalanceLockEnabled" to whiteBalanceLockEnabled')),
      );
      expect(
        cameraActivity,
        contains('"focusLockAttemptCount" to focusLockAttemptCount'),
      );
      expect(
        cameraActivity,
        contains('"focusLockSuccessCount" to focusLockSuccessCount'),
      );
      expect(
        cameraActivity,
        contains('"exposureLockSuccessCount" to exposureLockSuccessCount'),
      );
      expect(
        cameraActivity,
        contains('"whiteBalanceLockStatus" to whiteBalanceLockStatus'),
      );
      expect(
        cameraActivity,
        contains(
          'intent.getStringExtra("storageSafetyLevel") ?: dataSaverLevel',
        ),
      );
      expect(
        cameraActivity,
        contains('intent.getBooleanExtra("storageConstrained", false)'),
      );
      expect(
        cameraActivity,
        contains('intent.getStringExtra("storageSafetyReason") ?: "normal"'),
      );
      expect(
        cameraActivity,
        contains(
          'intent.getStringExtra("workloadProtectionPolicy")\n'
          '        ?: "balanced_workload"',
        ),
      );
      expect(cameraActivity, contains('storageSafetyDetail'));
      expect(cameraActivity, contains('Keeps long receipts lighter'));
      expect(
        cameraActivity,
        contains('"storageSafetyLevel" to storageSafetyLevel'),
      );
      expect(
        cameraActivity,
        contains('"storageConstrained" to storageConstrained'),
      );
      expect(
        cameraActivity,
        contains('"storageSafetyReason" to storageSafetyReason'),
      );
      expect(
        cameraActivity,
        contains('"workloadProtectionPolicy" to workloadProtectionPolicy'),
      );
      expect(cameraActivity, contains('ocrUsesOriginalFirst'));
      expect(
        cameraActivity,
        contains('"saveOriginalTemporarily" to saveOriginalTemporarily'),
      );
      expect(
        cameraActivity,
        contains(
          '"queueAcceptedCaptureLocally" to queueAcceptedCaptureLocally',
        ),
      );
      expect(
        cameraActivity,
        contains('"ocrUsesOriginalFirst" to ocrUsesOriginalFirst'),
      );
      expect(cameraActivity, contains('hasPreviousSectionGuide'));
      expect(
        cameraActivity,
        isNot(contains('MediaStore.ACTION_IMAGE_CAPTURE')),
      );
      expect(cameraActivity, isNot(contains('ACTION_IMAGE_CAPTURE')));

      expect(manifest, contains('.ReceiptCameraActivity'));
      expect(manifest, contains('android:exported="false"'));

      expect(gradle, contains('androidx.camera:camera-core'));
      expect(gradle, contains('androidx.camera:camera-camera2'));
      expect(gradle, contains('androidx.camera:camera-lifecycle'));
      expect(gradle, contains('androidx.camera:camera-view'));
    },
  );
}
