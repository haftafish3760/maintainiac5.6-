import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_android_bridge_source_readers.dart';

void main() {
  test('Android bridge keeps session and auto-capture diagnostics', () async {
    final sources = await readAndroidReceiptCameraBridgeSources();
    final cameraActivity = sources.cameraActivity;

    expect(cameraActivity, contains('maybeAutoCapture'));
    expect(cameraActivity, contains('autoCaptureAllowed'));
    expect(
      cameraActivity,
      contains('!autoCaptureEnabled || !isAutoCaptureCurrentlyAllowed()'),
    );
    expect(
      cameraActivity,
      contains('if (autoCaptureEnabled) "not_allowed" else "off"'),
    );
    expect(cameraActivity, contains('autoCaptureBlockedMessage()'));
    expect(cameraActivity, contains('val alreadyBlocked'));
    expect(
      cameraActivity,
      contains(
        'intent.getBooleanExtra("autoCaptureAllowed", autoCaptureEnabled)',
      ),
    );
    expect(
      cameraActivity,
      contains('deviceTier = intent.getStringExtra("deviceTier") ?: "medium"'),
    );
    expect(
      cameraActivity,
      contains(
        'devicePolicyLabel = intent.getStringExtra("devicePolicyLabel") ?: "balanced_receipt_camera"',
      ),
    );
    expect(
      cameraActivity,
      contains('readyHoldMs = intent.getIntExtra("readyHoldMs", 700)'),
    );
    expect(
      cameraActivity,
      contains('requestedAutoCaptureStableFrameTarget = intent.getIntExtra('),
    );
    expect(
      cameraActivity,
      contains('autoCaptureStableFrameTarget = if (autoCaptureAllowed)'),
    );
    expect(
      cameraActivity,
      contains('requestedAutoCaptureStableFrameTarget.coerceIn(2, 8)'),
    );
    expect(
      cameraActivity,
      contains('autoCaptureMaxMotionScore = finiteDoubleExtra('),
    );
    expect(
      cameraActivity,
      contains('autoCaptureMinBrightness = finiteDoubleExtra('),
    );
    expect(
      cameraActivity,
      contains('autoCaptureMaxBrightness = finiteDoubleExtra('),
    );
    expect(
      cameraActivity,
      contains('requestedAutoCaptureCooldownMs = intent.getIntExtra('),
    );
    expect(
      cameraActivity,
      contains('autoCaptureCooldownMs = if (autoCaptureAllowed)'),
    );
    expect(
      cameraActivity,
      contains('requestedAutoCaptureCooldownMs.coerceIn(1200, 6000).toLong()'),
    );
    expect(
      cameraActivity,
      contains(
        'assistedShotCount = intent.getIntExtra("assistedShotCount", 4)',
      ),
    );
    expect(
      cameraActivity,
      contains(
        'bestShotCandidateCount = intent.getIntExtra("bestShotCandidateCount", 3)',
      ),
    );
    expect(
      cameraActivity,
      contains(
        'cameraResolutionTier = intent.getStringExtra("cameraResolutionTier") ?: "high"',
      ),
    );
    expect(
      cameraActivity,
      contains(
        'cameraWorkloadTier = intent.getStringExtra("cameraWorkloadTier") ?: "balanced"',
      ),
    );
    expect(
      cameraActivity,
      contains(
        'maxLiveAnalysisPixels = intent.getIntExtra("maxLiveAnalysisPixels", 0)',
      ),
    );
    expect(
      cameraActivity,
      contains(
        'maxLocalPhotoBytes = intent.getIntExtra("maxLocalPhotoBytes", maxLocalPhotoBytes)',
      ),
    );
    expect(
      cameraActivity,
      contains(
        'nativeCaptureMemoryPolicy = intent.getStringExtra("nativeCaptureMemoryPolicy")',
      ),
    );
    expect(
      cameraActivity,
      contains(
        'sessionMaxZoom = finiteDoubleExtra("maxZoom", 1.0).coerceAtLeast(sessionMinZoom)',
      ),
    );
    expect(
      cameraActivity,
      contains('motionScore in 0.0..autoCaptureMaxMotionScore'),
    );
    expect(cameraActivity, contains('hasUsableLiveFramingBounds(framing)'));
    expect(
      cameraActivity,
      contains(
        'brightness in autoCaptureMinBrightness..autoCaptureMaxBrightness',
      ),
    );
    expect(
      cameraActivity,
      contains(
        r'ready_${autoCaptureStableFrameCount}_of_$autoCaptureStableFrameTarget',
      ),
    );
    expect(
      cameraActivity,
      contains('autoCaptureCooldownUntilMs = nowMs + autoCaptureCooldownMs'),
    );
    expect(
      cameraActivity,
      contains('System.currentTimeMillis() + autoCaptureCooldownMs'),
    );
    expect(
      cameraActivity,
      isNot(contains('System.currentTimeMillis() + 2600L')),
    );
    expect(
      cameraActivity,
      contains('Manual capture is safest for this device or storage mode.'),
    );
    expect(cameraActivity, contains('autoCaptureBlockedMessage'));
    expect(cameraActivity, contains('isAutoCaptureCurrentlyAllowed'));
    expect(
      cameraActivity,
      contains('Turn receipt edge guidance on before using automatic capture.'),
    );
    expect(
      cameraActivity,
      contains(
        'Receipt edge guidance is off, so automatic capture is held back.',
      ),
    );
    expect(
      cameraActivity,
      contains('latestAutoCaptureStatus = "edge_detection_off"'),
    );
    expect(cameraActivity, contains('autoCaptureStableFrameCount'));
    expect(cameraActivity, contains('autoCaptureTriggerCount'));
    expect(cameraActivity, contains('latestAutoCaptureStatus'));
    expect(
      cameraActivity,
      contains('"captureReadinessCode" to captureReadinessCode()'),
    );
    expect(
      cameraActivity,
      contains('"captureReadinessLabel" to captureReadinessLabel()'),
    );
    expect(cameraActivity, contains('"manualCaptureAllowed" to true'));
    expect(
      cameraActivity,
      contains('"stableFrameCount" to autoCaptureStableFrameCount'),
    );
    expect(
      cameraActivity,
      contains('"requiredStableFrames" to autoCaptureStableFrameTarget'),
    );
    expect(
      cameraActivity,
      contains('fun ReceiptCameraActivity.captureReadinessCode()'),
    );
    expect(cameraActivity, contains('"manual_only_check_framing"'));
    expect(
      cameraActivity,
      contains('"manual_only_quality_retake_recommended"'),
    );
    expect(cameraActivity, contains('"waiting_for_quality_review"'));
    expect(cameraActivity, contains('"manual_only_quality_review"'));
    expect(
      cameraActivity,
      contains(
        'receiptQualityReviewReadabilitySignals().contains(latestReadabilitySignal)',
      ),
    );
    expect(cameraActivity, isNot(contains('latestReadabilitySignal ==')));
    expect(cameraActivity, contains('closingCamera'));
    expect(cameraActivity, contains('captureInFlight'));
    expect(cameraActivity, contains('"closing"'));
    expect(
      cameraActivity,
      contains(
        r'"ready_${autoCaptureStableFrameCount}_of_$autoCaptureStableFrameTarget"',
      ),
    );
    expect(cameraActivity, contains('Receipt looks steady. Taking photo.'));
    expect(cameraActivity, contains('"waiting_for_edges"'));
    expect(cameraActivity, contains('"waiting_for_steady"'));
    expect(cameraActivity, contains('"waiting_for_light"'));
    expect(cameraActivity, contains('brightnessBucket'));
    expect(cameraActivity, contains('latestBrightnessBucket'));
    expect(cameraActivity, contains('"deviceTier" to deviceTier'));
    expect(
      cameraActivity,
      contains('"devicePolicyLabel" to devicePolicyLabel'),
    );
    expect(
      cameraActivity,
      contains('"cameraResolutionTier" to cameraResolutionTier'),
    );
    expect(
      cameraActivity,
      contains('"cameraWorkloadTier" to cameraWorkloadTier'),
    );
    expect(cameraActivity, contains('"readyHoldMs" to readyHoldMs'));
    expect(
      cameraActivity,
      contains('"assistedShotCount" to assistedShotCount'),
    );
    expect(
      cameraActivity,
      contains('"bestShotCandidateCount" to bestShotCandidateCount'),
    );
    expect(
      cameraActivity,
      contains('"maxLiveAnalysisPixels" to maxLiveAnalysisPixels'),
    );
    expect(
      cameraActivity,
      contains('"maxLocalPhotoBytes" to maxLocalPhotoBytes'),
    );
    expect(
      cameraActivity,
      contains('totalCapturedByteSize + savedByteSize > maxLocalPhotoBytes'),
    );
    expect(
      cameraActivity,
      contains('pendingCloseAfterCapture && capturedPhotoPaths.isNotEmpty()'),
    );
    expect(cameraActivity, contains('if (shouldReturnExistingSections)'));
    expect(cameraActivity, contains('outputFile.delete()'));
    expect(cameraActivity, contains('"native_capture_over_byte_budget"'));
    expect(
      cameraActivity,
      contains('"nativeCaptureMemoryPolicy" to nativeCaptureMemoryPolicy'),
    );
    expect(cameraActivity, contains('"maxCleanupPixels" to maxCleanupPixels'));
    expect(
      cameraActivity,
      contains(
        'maxStitchOutputPixels = intent.getIntExtra("maxStitchOutputPixels", 14000000).coerceAtLeast(0)',
      ),
    );
    expect(
      cameraActivity,
      contains(
        'maxStitchOutputHeight = intent.getIntExtra("maxStitchOutputHeight", 18000).coerceAtLeast(0)',
      ),
    );
    expect(
      cameraActivity,
      contains('"maxStitchOutputPixels" to maxStitchOutputPixels'),
    );
    expect(
      cameraActivity,
      contains('"maxStitchOutputHeight" to maxStitchOutputHeight'),
    );
    expect(cameraActivity, contains('"sessionMinZoom" to sessionMinZoom'));
    expect(cameraActivity, contains('"sessionMaxZoom" to sessionMaxZoom'));
    expect(
      cameraActivity,
      contains('"sessionMinExposureOffset" to sessionMinExposureOffset'),
    );
    expect(
      cameraActivity,
      contains('"sessionMaxExposureOffset" to sessionMaxExposureOffset'),
    );
    expect(cameraActivity, contains('exposureAssistStatus'));
  });
}
