import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android receipt camera bridge uses CameraX method channel', () async {
    final activity = await File(
      'android/app/src/main/kotlin/com/maintainiac/MainActivity.kt',
    ).readAsString();
    final cameraActivity = await File(
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt',
    ).readAsString();
    final gradle = await File('android/app/build.gradle.kts').readAsString();
    final manifest = await File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsString();

    expect(activity, contains('maintainiac/receipt_camera'));
    expect(activity, contains('ProcessCameraProvider'));
    expect(activity, contains('providerFuture.get()'));
    expect(activity, contains('CameraCharacteristics.LENS_FACING_BACK'));
    expect(activity, contains('readCapabilities'));
    expect(activity, contains('captureReceipt'));
    expect(activity, contains('ReceiptCameraActivity::class.java'));
    expect(activity, contains('startActivityForResult'));
    expect(activity, contains('originalPhotoPaths'));
    expect(activity, contains('native_camera_cancelled'));
    expect(activity, contains('receiptCaptureDiagnostics'));
    expect(activity, contains('extraCaptureDiagnostics'));
    expect(activity, contains('captureSurface'));
    expect(activity, contains('maintainiac_native_android'));
    expect(activity, contains('CameraCharacteristics'));
    expect(activity, contains('CONTROL_ZOOM_RATIO_RANGE'));
    expect(activity, contains('CONTROL_AE_COMPENSATION_RANGE'));
    expect(activity, contains('SCALER_STREAM_CONFIGURATION_MAP'));
    expect(activity, contains('ImageFormat.JPEG'));
    expect(activity, contains('maxJpegStillSize'));
    expect(activity, contains('maxStillSize?.width'));
    expect(activity, contains('maxStillSize?.height'));
    expect(activity, isNot(contains('MediaStore.ACTION_IMAGE_CAPTURE')));

    expect(cameraActivity, contains('ProcessCameraProvider'));
    expect(cameraActivity, contains('BitmapFactory'));
    expect(cameraActivity, contains('PreviewView'));
    expect(cameraActivity, contains('ImageCapture'));
    expect(cameraActivity, contains('ImageAnalysis'));
    expect(cameraActivity, contains('ImageProxy'));
    expect(cameraActivity, contains('settingsStatusStrip'));
    expect(cameraActivity, contains('buildSettingsStatusStrip'));
    expect(cameraActivity, contains('settingsStatusText'));
    expect(cameraActivity, contains('val assist = if (assistedReceiptFill)'));
    expect(cameraActivity, contains('"Assist on"'));
    expect(cameraActivity, contains('"Manual fill"'));
    expect(cameraActivity, contains('OCR reads original first'));
    expect(cameraActivity, contains('updateSettingsStatusStrip()'));
    expect(cameraActivity, contains('receiptFrameGuide'));
    expect(cameraActivity, contains('LiveReceiptFraming'));
    expect(cameraActivity, contains('CameraSelector.DEFAULT_BACK_CAMERA'));
    expect(cameraActivity, contains('CAPTURE_MODE_MAXIMIZE_QUALITY'));
    expect(cameraActivity, contains('setJpegQuality(98)'));
    expect(cameraActivity, contains('setTargetRotation'));
    expect(cameraActivity, contains('enableTorch'));
    expect(cameraActivity, contains('ScaleGestureDetector'));
    expect(cameraActivity, contains('setZoomRatio'));
    expect(cameraActivity, contains('FocusMeteringAction'));
    expect(cameraActivity, contains('startFocusAndMetering'));
    expect(cameraActivity, contains('text = "Use Photo"'));
    expect(cameraActivity, contains('"Use Photo (1)"'));
    expect(cameraActivity, contains(r'"Use Photos ($count)"'));
    expect(
      cameraActivity,
      contains('contentDescription = "Use captured receipt photos"'),
    );
    expect(cameraActivity, contains('tapFocusEnabled'));
    expect(cameraActivity, contains('pinchZoomEnabled'));
    expect(cameraActivity, contains('exposureSliderEnabled'));
    expect(cameraActivity, contains('exposureResetEnabled'));
    expect(
      cameraActivity,
      contains('intent.getBooleanExtra("tapFocusEnabled", true)'),
    );
    expect(
      cameraActivity,
      contains('intent.getBooleanExtra("pinchZoomEnabled", true)'),
    );
    expect(
      cameraActivity,
      contains('intent.getBooleanExtra("exposureSliderEnabled", true)'),
    );
    expect(
      cameraActivity,
      contains('intent.getBooleanExtra("exposureResetEnabled", true)'),
    );
    expect(cameraActivity, contains('override fun onBackPressed()'));
    expect(cameraActivity, contains('OnBackInvokedCallback'));
    expect(
      cameraActivity,
      contains('OnBackInvokedDispatcher.PRIORITY_DEFAULT'),
    );
    expect(cameraActivity, contains('registerSystemBackHandler()'));
    expect(cameraActivity, contains('unregisterSystemBackHandler()'));
    expect(cameraActivity, contains('requestCloseCamera'));
    expect(cameraActivity, contains('private fun requestCloseCamera()'));
    expect(cameraActivity, contains('if (closeResultDelivered) {'));
    expect(cameraActivity, contains('closeRetryCount += 1'));
    expect(manifest, contains('android:enableOnBackInvokedCallback="true"'));
    expect(cameraActivity, contains('!isFinishing && !isDestroyed'));
    expect(cameraActivity, contains('pendingCloseAfterCapture'));
    expect(
      cameraActivity,
      contains('Finishing this receipt photo before closing.'),
    );
    expect(cameraActivity, contains('closeAction = "back_no_photo_cancel"'));
    expect(cameraActivity, contains('closeResultDelivered = true'));
    expect(
      cameraActivity,
      contains(
        'finishWithCapturedPhotos(closeReason = "back_returned_captured_sections")',
      ),
    );
    expect(cameraActivity, contains('closingCamera = true'));
    expect(cameraActivity, contains('latestAutoCaptureStatus = "closing"'));
    expect(cameraActivity, contains('if (capturedPhotoPaths.isEmpty())'));
    expect(cameraActivity, contains('finishWithCapturedPhotos()'));
    expect(cameraActivity, contains('runCatching'));
    expect(cameraActivity, contains('unbindAll'));
    expect(cameraActivity, contains('exposureCompensationRange'));
    expect(cameraActivity, contains('setExposureCompensationIndex'));
    expect(cameraActivity, contains('buildImageAnalysis'));
    expect(cameraActivity, contains('!tooFarTooCloseWarningEnabled'));
    expect(cameraActivity, contains('!edgeDetectionEnabled'));
    expect(cameraActivity, contains('!receiptFullyVisibleWarningEnabled'));
    expect(cameraActivity, contains('!autoExposureAssistEnabled'));
    expect(cameraActivity, contains('analyzeLiveFrame'));
    expect(cameraActivity, contains('motionBlurWarningEnabled'));
    expect(cameraActivity, contains('shadowWarningEnabled'));
    expect(cameraActivity, contains('textTooSmallWarningEnabled'));
    expect(cameraActivity, contains('perspectiveCorrectionEnabled'));
    expect(cameraActivity, contains('manualCropAfterCapture'));
    expect(cameraActivity, contains('autoCropSuggestionEnabled'));
    expect(cameraActivity, contains('grayscalePreviewEnabled'));
    expect(cameraActivity, contains('contrastBoostEnabled'));
    expect(cameraActivity, contains('shadowReductionEnabled'));
    expect(cameraActivity, contains('adaptiveThresholdEnabled'));
    expect(cameraActivity, contains('orientationCorrectionEnabled'));
    expect(cameraActivity, contains('OCR reads the original photo first.'));
    expect(
      cameraActivity,
      contains(
        'Smaller backup copies are made after the receipt has been read.',
      ),
    );
    expect(cameraActivity, contains('The shutter button always works.'));
    expect(
      cameraActivity,
      contains('intent.getBooleanExtra("autoCropSuggestionEnabled", true)'),
    );
    expect(
      cameraActivity,
      contains('intent.getBooleanExtra("orientationCorrectionEnabled", true)'),
    );
    expect(
      cameraActivity,
      contains('intent.getBooleanExtra("shadowWarningEnabled", true)'),
    );
    expect(
      cameraActivity,
      contains('intent.getBooleanExtra("textTooSmallWarningEnabled", true)'),
    );
    expect(cameraActivity, contains('sampleLiveLumaGrid'));
    expect(cameraActivity, contains('evaluateLiveMotion'));
    expect(cameraActivity, contains('estimateShadowScore'));
    expect(cameraActivity, contains('latestShadowScore'));
    expect(cameraActivity, contains('"shadow_risk"'));
    expect(
      cameraActivity,
      contains('Receipt has heavy shadows. Move it into even light.'),
    );
    expect(cameraActivity, contains('latestMotionSignal'));
    expect(cameraActivity, contains('latestMotionScore'));
    expect(
      cameraActivity,
      contains('Hold steady so the receipt text stays sharp.'),
    );
    expect(cameraActivity, contains('autoAdjustExposureForLiveFrame'));
    expect(
      cameraActivity,
      contains('autoAdjustExposureForLiveFrame(brightness, now, framing)'),
    );
    expect(cameraActivity, contains('waiting_for_receipt_target'));
    expect(cameraActivity, contains('brightness <= 96.0'));
    expect(cameraActivity, contains('brightness <= 58.0'));
    expect(cameraActivity, contains('brightness >= 246.0'));
    expect(cameraActivity, contains('brightness >= 252.0'));
    expect(cameraActivity, contains('"bright_receipt_ok"'));
    expect(cameraActivity, contains('lastAutoExposureAdjustmentAt'));
    expect(cameraActivity, contains('lastAutoExposureDecision'));
    expect(cameraActivity, contains('lastAutoExposureBrightnessBucket'));
    expect(cameraActivity, contains('lastAutoExposureCandidate'));
    expect(cameraActivity, contains('autoExposureCandidateFrameCount'));
    expect(cameraActivity, contains('stableAutoExposureCandidate'));
    expect(cameraActivity, contains('requiredFrames: Int = 2'));
    expect(
      cameraActivity,
      contains(
        'stableAutoExposureCandidate("fallback_brighten", requiredFrames = 4)',
      ),
    );
    expect(
      cameraActivity,
      contains(
        'stableAutoExposureCandidate("fallback_dim", requiredFrames = 4)',
      ),
    );
    expect(cameraActivity, contains('stabilizing_'));
    expect(cameraActivity, contains('lastAutoExposureIndex'));
    expect(
      cameraActivity,
      contains('nowMs - lastAutoExposureAdjustmentAt < 900L'),
    );
    expect(cameraActivity, contains('brightened_strong'));
    expect(cameraActivity, contains('dimmed_strong'));
    expect(cameraActivity, contains('autoExposureAssistEnabled'));
    expect(cameraActivity, contains('userExposureOverride'));
    expect(cameraActivity, contains('autoExposureAdjustmentCount'));
    expect(cameraActivity, contains('tapFocusCount'));
    expect(cameraActivity, contains('tapFocusSuppressedAfterZoomCount'));
    expect(cameraActivity, contains('suppressTapFocusUntilMs'));
    expect(
      cameraActivity,
      contains('suppressTapFocusUntilMs = System.currentTimeMillis() + 350L'),
    );
    expect(
      cameraActivity,
      contains('lastFocusStatus = "tap_focus_suppressed_after_zoom"'),
    );
    expect(cameraActivity, contains('zoomChangeCount'));
    expect(cameraActivity, contains('manualExposureChangeCount'));
    expect(cameraActivity, contains('lastFocusStatus'));
    expect(
      cameraActivity,
      contains(
        'focusMode = intent.getStringExtra("focusMode") ?: "continuous"',
      ),
    );
    expect(
      cameraActivity,
      contains(
        'exposureMode = intent.getStringExtra("exposureMode") ?: "auto"',
      ),
    );
    expect(
      cameraActivity,
      contains(
        'whiteBalanceMode = intent.getStringExtra("whiteBalanceMode") ?: "auto"',
      ),
    );
    expect(
      cameraActivity,
      contains('val shouldLockFocus = focusMode == "locked"'),
    );
    expect(
      cameraActivity,
      contains('val shouldLockExposure = exposureMode == "locked"'),
    );
    expect(
      cameraActivity,
      contains('val shouldLockWhiteBalance = whiteBalanceMode == "locked"'),
    );
    expect(cameraActivity, contains('not_supported_cameraX'));
    expect(cameraActivity, contains('builder.disableAutoCancel()'));
    expect(cameraActivity, contains('focusLockAttemptCount'));
    expect(cameraActivity, contains('focusLockSuccessCount'));
    expect(cameraActivity, contains('exposureLockSuccessCount'));
    expect(cameraActivity, contains('lastFocusStatus = "locked"'));
    expect(
      cameraActivity,
      contains('Focus locked. Tap the shutter when the receipt is readable.'),
    );
    expect(cameraActivity, contains('maybeAutoCapture'));
    expect(cameraActivity, contains('autoCaptureAllowed'));
    expect(
      cameraActivity,
      contains(
        'intent.getBooleanExtra("autoCaptureAllowed", autoCaptureEnabled)',
      ),
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
    expect(cameraActivity, contains('closingCamera'));
    expect(cameraActivity, contains('captureInFlight || closingCamera'));
    expect(cameraActivity, contains('"closing"'));
    expect(
      cameraActivity,
      contains(r'"ready_${autoCaptureStableFrameCount}_of_3"'),
    );
    expect(cameraActivity, contains('Receipt looks steady. Taking photo.'));
    expect(cameraActivity, contains('"waiting_for_edges"'));
    expect(cameraActivity, contains('"waiting_for_steady"'));
    expect(cameraActivity, contains('"waiting_for_light"'));
    expect(cameraActivity, contains('brightnessBucket'));
    expect(cameraActivity, contains('latestBrightnessBucket'));
    expect(cameraActivity, contains('exposureAssistStatus'));
    expect(cameraActivity, contains('"manual_override"'));
    expect(cameraActivity, contains('"auto_adjusted"'));
    expect(cameraActivity, contains('averageLuma'));
    expect(cameraActivity, contains('estimateReceiptFraming'));
    expect(cameraActivity, contains('applyLiveFraming'));
    expect(cameraActivity, contains('latestFramingSignal'));
    expect(cameraActivity, contains('latestFramingConfidence'));
    expect(cameraActivity, contains('latestEdgeCoverage'));
    expect(cameraActivity, contains('latestPerspectiveReadiness'));
    expect(cameraActivity, contains('perspectiveReadinessFor'));
    expect(cameraActivity, contains('perspective_skipped_cut_off_risk'));
    expect(cameraActivity, contains('perspective_ready_safe_bounds'));
    expect(cameraActivity, contains('framingConfidenceBucket'));
    expect(cameraActivity, contains('framingGuidanceCopy'));
    expect(cameraActivity, contains('"strong_edges"'));
    expect(cameraActivity, contains('"usable_edges"'));
    expect(cameraActivity, contains('"edge_detection_off"'));
    expect(cameraActivity, contains('"off"'));
    expect(cameraActivity, contains('edgeDetectionEnabled'));
    expect(cameraActivity, contains('edgeOverlayEnabled'));
    expect(
      cameraActivity,
      contains('intent.getBooleanExtra("edgeDetectionEnabled", true)'),
    );
    expect(
      cameraActivity,
      contains('intent.getBooleanExtra("edgeOverlayEnabled", true)'),
    );
    expect(
      cameraActivity,
      contains(
        'Place the receipt inside the frame. Manual capture still works.',
      ),
    );
    expect(
      cameraActivity,
      contains('Receipt edges found. Hold steady and tap the shutter.'),
    );
    expect(
      cameraActivity,
      contains('Move closer until receipt text fills the guide.'),
    );
    expect(
      cameraActivity,
      contains(
        'Full receipt may be cut off. Leave a little paper edge visible.',
      ),
    );
    expect(
      cameraActivity,
      contains('Receipt looks dark. Add light or raise Brightness.'),
    );
    expect(
      cameraActivity,
      contains('Receipt is very bright. Tilt it or lower Brightness.'),
    );
    expect(cameraActivity, contains('latestReadabilitySignal'));
    expect(cameraActivity, contains('latestFrameBrightness'));
    expect(cameraActivity, contains('Brightness'));
    expect(cameraActivity, contains('Reset'));
    expect(cameraActivity, contains('AlertDialog.Builder'));
    expect(cameraActivity, contains('Let Maintainiac help fill this receipt'));
    expect(cameraActivity, contains('Long receipt mode'));
    expect(cameraActivity, contains('Automatic capture'));
    expect(
      cameraActivity,
      contains(
        'Waits for 3 steady readable frames. Manual shutter always works.',
      ),
    );
    expect(
      cameraActivity,
      contains(
        'Automatic capture is on. Hold steady, or tap the shutter anytime.',
      ),
    );
    expect(cameraActivity, contains('Auto brightness assist'));
    expect(cameraActivity, contains('Manual Brightness still wins.'));
    expect(cameraActivity, contains('Find receipt edges'));
    expect(cameraActivity, contains('Image cleanup'));
    expect(cameraActivity, contains('Crop, straighten, grayscale, contrast'));
    expect(cameraActivity, contains('Receipt edge guidance is on.'));
    expect(
      cameraActivity,
      contains(
        'Receipt edge guidance is off. Take the clearest photo you can.',
      ),
    );
    expect(cameraActivity, contains('Receipt guidance warnings'));
    expect(cameraActivity, contains('Warn about shake, glare, low light'));
    expect(cameraActivity, contains('receiptGuidanceWarningsEnabled'));
    expect(cameraActivity, contains('setReceiptGuidanceWarningsEnabled'));
    expect(cameraActivity, contains('Review style'));
    expect(cameraActivity, contains('Save-space backup'));
    expect(cameraActivity, contains('Take receipt photo'));
    expect(cameraActivity, contains('Receipt camera settings'));
    expect(cameraActivity, contains('doneButton'));
    expect(cameraActivity, contains('Finish'));
    expect(cameraActivity, contains('finishWithCapturedPhotos'));
    expect(cameraActivity, contains('capturedPhotoPaths'));
    expect(cameraActivity, contains(r'"Use Photos ($count)"'));
    expect(
      cameraActivity,
      contains(r'Section ${capturedPhotoPaths.size} saved'),
    );
    expect(cameraActivity, contains('previousSectionGuidePhotoPath'));
    expect(cameraActivity, contains('buildPreviousSectionGuide'));
    expect(cameraActivity, contains('updatePreviousSectionGuide'));
    expect(cameraActivity, contains('previousSectionGuidePanel'));
    expect(cameraActivity, contains('previousSectionGuideImage'));
    expect(cameraActivity, contains('Previous receipt section overlap guide'));
    expect(
      cameraActivity,
      contains('Repeat 3-5 readable lines near the top of this photo.'),
    );
    expect(cameraActivity, contains('receipt_camera'));
    expect(cameraActivity, contains('originalPhotoPaths'));
    expect(cameraActivity, contains('nativeCaptureDiagnostics'));
    expect(cameraActivity, contains('photoByteSize'));
    expect(cameraActivity, contains('photoByteSizeBucket'));
    expect(cameraActivity, contains('latestCapturedPhotoWidth'));
    expect(cameraActivity, contains('latestCapturedPhotoHeight'));
    expect(cameraActivity, contains('latestCapturedMegapixelBucket'));
    expect(cameraActivity, contains('latestCapturedByteBucket'));
    expect(cameraActivity, contains('latestCapturedBrightnessBucket'));
    expect(cameraActivity, contains('latestCapturedSharpnessBucket'));
    expect(cameraActivity, contains('latestCapturedQualitySignal'));
    expect(cameraActivity, contains('latestCapturedExposureMismatch'));
    expect(cameraActivity, contains('sampleCapturedBitmapQuality'));
    expect(cameraActivity, contains('live_ok_capture_too_dark'));
    expect(
      cameraActivity,
      contains(
        'liveBucket == "lighting_ok" && capturedBrightnessBucket == "captured_too_dark"',
      ),
    );
    expect(
      cameraActivity,
      contains(
        'liveBucket == "lighting_ok" && capturedBrightnessBucket == "captured_dim"',
      ),
    );
    expect(
      cameraActivity,
      contains(
        'liveBucket == "dark_assisted" && capturedBrightnessBucket == "captured_readable"',
      ),
    );
    expect(
      cameraActivity,
      contains(
        'liveBucket == "bright_receipt_ok" && capturedBrightnessBucket == "captured_readable"',
      ),
    );
    expect(cameraActivity, isNot(contains('liveBucket == "normal"')));
    expect(cameraActivity, isNot(contains('liveBucket == "dark"')));
    expect(cameraActivity, isNot(contains('liveBucket == "bright"')));
    expect(cameraActivity, contains('recordCapturedPhotoQuality'));
    expect(cameraActivity, contains('megapixelBucket'));
    expect(cameraActivity, contains('very_large_over_8mb'));
    expect(cameraActivity, contains('photoCount'));
    expect(cameraActivity, contains('maxSectionCount'));
    expect(cameraActivity, contains('captureQualityMode'));
    expect(cameraActivity, contains('exposureCompensationIndex'));
    expect(cameraActivity, contains('zoomRatio'));
    expect(
      cameraActivity,
      contains('"exposureSliderEnabled" to exposureSliderEnabled'),
    );
    expect(
      cameraActivity,
      contains('"exposureResetEnabled" to exposureResetEnabled'),
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
    expect(cameraActivity, contains('"closeAction" to closeAction'));
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
    expect(cameraActivity, contains('"whiteBalanceMode" to whiteBalanceMode'));
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
      contains('intent.getStringExtra("storageSafetyLevel") ?: dataSaverLevel'),
    );
    expect(
      cameraActivity,
      contains('intent.getBooleanExtra("storageConstrained", false)'),
    );
    expect(
      cameraActivity,
      contains('intent.getStringExtra("storageSafetyReason") ?: "normal"'),
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
    expect(cameraActivity, contains('ocrUsesOriginalFirst'));
    expect(cameraActivity, contains('hasPreviousSectionGuide'));
    expect(cameraActivity, isNot(contains('MediaStore.ACTION_IMAGE_CAPTURE')));
    expect(cameraActivity, isNot(contains('ACTION_IMAGE_CAPTURE')));

    expect(manifest, contains('.ReceiptCameraActivity'));
    expect(manifest, contains('android:exported="false"'));

    expect(gradle, contains('androidx.camera:camera-core'));
    expect(gradle, contains('androidx.camera:camera-camera2'));
    expect(gradle, contains('androidx.camera:camera-lifecycle'));
    expect(gradle, contains('androidx.camera:camera-view'));
  });
}
