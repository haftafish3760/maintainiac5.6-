import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS receipt camera bridge uses AVFoundation method channel', () async {
    final appDelegate = await File(
      'ios/Runner/AppDelegate.swift',
    ).readAsString();
    final cameraController = await File(
      'ios/Runner/ReceiptCameraViewController.swift',
    ).readAsString();
    final xcodeProject = await File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsString();

    expect(appDelegate, contains('import AVFoundation'));
    expect(appDelegate, contains('maintainiac/receipt_camera'));
    expect(appDelegate, contains('FlutterMethodChannel'));
    expect(appDelegate, contains('readCapabilities'));
    expect(appDelegate, contains('captureReceipt'));
    expect(appDelegate, contains('ReceiptCameraViewController'));
    expect(appDelegate, contains('present(controller, animated: true)'));
    expect(appDelegate, contains('originalPhotoPaths'));
    expect(appDelegate, contains('native_camera_cancelled'));
    expect(appDelegate, contains('captureDiagnostics": diagnostics'));
    expect(appDelegate, contains('AVCaptureDevice.DiscoverySession'));
    expect(appDelegate, contains('AVCaptureDevice.authorizationStatus'));
    expect(appDelegate, contains('maxAvailableVideoZoomFactor'));
    expect(appDelegate, contains('maxStillDimensions'));
    expect(appDelegate, contains('highResolutionStillImageDimensions'));
    expect(appDelegate, contains('"maxStillWidth": stillDimensions.width'));
    expect(appDelegate, contains('"maxStillHeight": stillDimensions.height'));
    expect(appDelegate, contains('minExposureTargetBias'));
    expect(appDelegate, contains('maxExposureTargetBias'));
    expect(appDelegate, contains('isFocusPointOfInterestSupported'));
    expect(
      appDelegate,
      contains('isLockingFocusWithCustomLensPositionSupported'),
    );
    expect(appDelegate, contains('isExposureModeSupported(.custom)'));
    expect(appDelegate, contains('isWhiteBalanceModeSupported(.locked)'));
    expect(
      appDelegate,
      contains('isLockingWhiteBalanceWithCustomDeviceGainsSupported'),
    );
    expect(appDelegate, contains('hasTorch'));
    expect(appDelegate, contains('hasFlash'));
    expect(appDelegate, contains('"engine": "avFoundation"'));
    expect(appDelegate, isNot(contains('UIImagePickerController')));
    expect(appDelegate, isNot(contains('PHPickerViewController')));

    expect(cameraController, contains('AVCaptureSession'));
    expect(cameraController, contains('UIImage(data: data)'));
    expect(cameraController, contains('AVCaptureVideoPreviewLayer'));
    expect(cameraController, contains('AVCapturePhotoOutput'));
    expect(cameraController, contains('AVCaptureVideoDataOutput'));
    expect(cameraController, contains('receiptFrameGuide'));
    expect(cameraController, contains('LiveReceiptFraming'));
    expect(
      cameraController,
      contains('AVCaptureVideoDataOutputSampleBufferDelegate'),
    );
    expect(cameraController, contains('AVCapturePhotoCaptureDelegate'));
    expect(cameraController, contains('AVCaptureDevice.default'));
    expect(cameraController, contains('photoOutput.capturePhoto'));
    expect(cameraController, contains('UITapGestureRecognizer'));
    expect(cameraController, contains('UIPinchGestureRecognizer'));
    expect(
      cameraController,
      contains('tapGesture.isEnabled = tapFocusEnabled'),
    );
    expect(
      cameraController,
      contains('pinchGesture.isEnabled = pinchZoomEnabled'),
    );
    expect(cameraController, contains('focusPointOfInterest'));
    expect(cameraController, contains('exposurePointOfInterest'));
    expect(cameraController, contains('videoZoomFactor'));
    expect(cameraController, contains('minExposureTargetBias'));
    expect(cameraController, contains('maxExposureTargetBias'));
    expect(cameraController, contains('setExposureTargetBias'));
    expect(cameraController, contains('tapFocusEnabled'));
    expect(cameraController, contains('pinchZoomEnabled'));
    expect(cameraController, contains('exposureSliderEnabled'));
    expect(cameraController, contains('exposureResetEnabled'));
    expect(
      cameraController,
      contains('arguments["tapFocusEnabled"] as? Bool ?? true'),
    );
    expect(
      cameraController,
      contains('arguments["pinchZoomEnabled"] as? Bool ?? true'),
    );
    expect(
      cameraController,
      contains('arguments["exposureSliderEnabled"] as? Bool ?? true'),
    );
    expect(
      cameraController,
      contains('arguments["exposureResetEnabled"] as? Bool ?? true'),
    );
    expect(cameraController, contains('configureVideoAnalysisIfNeeded'));
    expect(cameraController, contains('tooFarTooCloseWarningEnabled ||'));
    expect(cameraController, contains('receiptFullyVisibleWarningEnabled ||'));
    expect(cameraController, contains('autoExposureAssistEnabled'));
    expect(cameraController, contains('captureOutput('));
    expect(cameraController, contains('motionBlurWarningEnabled'));
    expect(cameraController, contains('shadowWarningEnabled'));
    expect(cameraController, contains('textTooSmallWarningEnabled'));
    expect(cameraController, contains('perspectiveCorrectionEnabled'));
    expect(cameraController, contains('manualCropAfterCapture'));
    expect(cameraController, contains('autoCropSuggestionEnabled'));
    expect(cameraController, contains('grayscalePreviewEnabled'));
    expect(cameraController, contains('contrastBoostEnabled'));
    expect(cameraController, contains('shadowReductionEnabled'));
    expect(cameraController, contains('adaptiveThresholdEnabled'));
    expect(cameraController, contains('orientationCorrectionEnabled'));
    expect(
      cameraController,
      contains('arguments["shadowWarningEnabled"] as? Bool ?? true'),
    );
    expect(
      cameraController,
      contains('arguments["textTooSmallWarningEnabled"] as? Bool ?? true'),
    );
    expect(
      cameraController,
      contains('arguments["autoCropSuggestionEnabled"] as? Bool ?? true'),
    );
    expect(
      cameraController,
      contains('arguments["orientationCorrectionEnabled"] as? Bool ?? true'),
    );
    expect(cameraController, contains('sampleLiveLumaGrid'));
    expect(cameraController, contains('evaluateLiveMotion'));
    expect(cameraController, contains('estimateShadowScore'));
    expect(cameraController, contains('latestShadowScore'));
    expect(cameraController, contains('"shadow_risk"'));
    expect(
      cameraController,
      contains('Receipt has heavy shadows. Move it into even light.'),
    );
    expect(cameraController, contains('latestMotionSignal'));
    expect(cameraController, contains('latestMotionScore'));
    expect(
      cameraController,
      contains('Hold steady so the receipt text stays sharp.'),
    );
    expect(cameraController, contains('averageLuma'));
    expect(cameraController, contains('applyLiveReadability'));
    expect(cameraController, contains('estimateReceiptFraming'));
    expect(cameraController, contains('applyLiveFraming'));
    expect(cameraController, contains('latestFramingSignal'));
    expect(cameraController, contains('latestFramingConfidence'));
    expect(cameraController, contains('latestEdgeCoverage'));
    expect(cameraController, contains('latestPerspectiveReadiness'));
    expect(cameraController, contains('perspectiveReadiness(for:'));
    expect(cameraController, contains('perspective_skipped_cut_off_risk'));
    expect(cameraController, contains('perspective_ready_safe_bounds'));
    expect(cameraController, contains('framingConfidenceBucket'));
    expect(cameraController, contains('framingGuidanceCopy'));
    expect(cameraController, contains('"strong_edges"'));
    expect(cameraController, contains('"usable_edges"'));
    expect(cameraController, contains('"edge_detection_off"'));
    expect(cameraController, contains('"off"'));
    expect(cameraController, contains('edgeDetectionEnabled'));
    expect(cameraController, contains('edgeOverlayEnabled'));
    expect(
      cameraController,
      contains('arguments["edgeDetectionEnabled"] as? Bool ?? true'),
    );
    expect(
      cameraController,
      contains('arguments["edgeOverlayEnabled"] as? Bool ?? true'),
    );
    expect(
      cameraController,
      contains(
        'Place the receipt inside the frame. Manual capture still works.',
      ),
    );
    expect(
      cameraController,
      contains('Receipt edges found. Hold steady and tap the shutter.'),
    );
    expect(
      cameraController,
      contains('Move closer until receipt text fills the guide.'),
    );
    expect(
      cameraController,
      contains(
        'Full receipt may be cut off. Leave a little paper edge visible.',
      ),
    );
    expect(cameraController, contains('autoAdjustExposureForLiveFrame'));
    expect(cameraController, contains('autoAdjustExposureForLiveFrame('));
    expect(cameraController, contains('framing: framing'));
    expect(cameraController, contains('waiting_for_receipt_target'));
    expect(cameraController, contains('brightness <= 96'));
    expect(cameraController, contains('brightness <= 58'));
    expect(cameraController, contains('brightness >= 246'));
    expect(cameraController, contains('brightness >= 252'));
    expect(cameraController, contains('"bright_receipt_ok"'));
    expect(cameraController, contains('lastAutoExposureAdjustmentAt'));
    expect(cameraController, contains('lastAutoExposureDecision'));
    expect(cameraController, contains('lastAutoExposureBrightnessBucket'));
    expect(cameraController, contains('lastAutoExposureCandidate'));
    expect(cameraController, contains('autoExposureCandidateFrameCount'));
    expect(cameraController, contains('stableAutoExposureCandidate'));
    expect(cameraController, contains('requiredFrames: Int = 2'));
    expect(
      cameraController,
      contains(
        'stableAutoExposureCandidate("fallback_brighten", requiredFrames: 4)',
      ),
    );
    expect(
      cameraController,
      contains(
        'stableAutoExposureCandidate("fallback_dim", requiredFrames: 4)',
      ),
    );
    expect(cameraController, contains('stabilizing_'));
    expect(cameraController, contains('lastAutoExposureBias'));
    expect(
      cameraController,
      contains('nowMs - lastAutoExposureAdjustmentAt >= 900'),
    );
    expect(cameraController, contains('brightened_strong'));
    expect(cameraController, contains('dimmed_strong'));
    expect(cameraController, contains('autoExposureAssistEnabled'));
    expect(cameraController, contains('userExposureOverride'));
    expect(cameraController, contains('autoExposureAdjustmentCount'));
    expect(cameraController, contains('tapFocusCount'));
    expect(cameraController, contains('tapFocusSuppressedAfterZoomCount'));
    expect(cameraController, contains('suppressTapFocusUntil'));
    expect(
      cameraController,
      contains('suppressTapFocusUntil = Date().addingTimeInterval(0.35)'),
    );
    expect(
      cameraController,
      contains('lastFocusStatus = "tap_focus_suppressed_after_zoom"'),
    );
    expect(cameraController, contains('zoomChangeCount'));
    expect(cameraController, contains('manualExposureChangeCount'));
    expect(cameraController, contains('lastFocusStatus'));
    expect(
      cameraController,
      contains('focusMode = arguments["focusMode"] as? String ?? "continuous"'),
    );
    expect(
      cameraController,
      contains('exposureMode = arguments["exposureMode"] as? String ?? "auto"'),
    );
    expect(
      cameraController,
      contains(
        'whiteBalanceMode = arguments["whiteBalanceMode"] as? String ?? "auto"',
      ),
    );
    expect(
      cameraController,
      contains('let shouldLockFocus = focusMode == "locked"'),
    );
    expect(
      cameraController,
      contains('let shouldLockExposure = exposureMode == "locked"'),
    );
    expect(
      cameraController,
      contains('let shouldLockWhiteBalance = whiteBalanceMode == "locked"'),
    );
    expect(cameraController, contains('lockFocusAndExposureIfSupported'));
    expect(
      cameraController,
      contains('cameraDevice.isFocusModeSupported(.locked)'),
    );
    expect(
      cameraController,
      contains('cameraDevice.isExposureModeSupported(.locked)'),
    );
    expect(
      cameraController,
      contains('cameraDevice.isWhiteBalanceModeSupported(.locked)'),
    );
    expect(
      cameraController,
      contains('cameraDevice.whiteBalanceMode = .locked'),
    );
    expect(cameraController, contains('focusLockAttemptCount'));
    expect(cameraController, contains('focusLockSuccessCount'));
    expect(cameraController, contains('exposureLockSuccessCount'));
    expect(cameraController, contains('whiteBalanceLockAttemptCount'));
    expect(cameraController, contains('whiteBalanceLockSuccessCount'));
    expect(cameraController, contains('whiteBalanceLockStatus'));
    expect(cameraController, contains('? "locked"'));
    expect(
      cameraController,
      contains('Focus locked. Tap the shutter when the receipt is readable.'),
    );
    expect(cameraController, contains('maybeAutoCapture'));
    expect(cameraController, contains('autoCaptureAllowed'));
    expect(
      cameraController,
      contains(
        'arguments["autoCaptureAllowed"] as? Bool ?? autoCaptureEnabled',
      ),
    );
    expect(
      cameraController,
      contains('Manual capture is safest for this device or storage mode.'),
    );
    expect(cameraController, contains('autoCaptureBlockedMessage'));
    expect(cameraController, contains('autoCaptureStableFrameCount'));
    expect(cameraController, contains('autoCaptureTriggerCount'));
    expect(cameraController, contains('latestAutoCaptureStatus'));
    expect(cameraController, contains('closingCamera'));
    expect(cameraController, contains('!closingCamera'));
    expect(cameraController, contains('"closing"'));
    expect(
      cameraController,
      contains('"ready_\\(autoCaptureStableFrameCount)_of_3"'),
    );
    expect(cameraController, contains('Receipt looks steady. Taking photo.'));
    expect(cameraController, contains('"waiting_for_edges"'));
    expect(cameraController, contains('"waiting_for_steady"'));
    expect(cameraController, contains('"waiting_for_light"'));
    expect(cameraController, contains('brightnessBucket'));
    expect(cameraController, contains('latestBrightnessBucket'));
    expect(cameraController, contains('exposureAssistStatus'));
    expect(cameraController, contains('"manual_override"'));
    expect(cameraController, contains('"auto_adjusted"'));
    expect(
      cameraController,
      contains('Receipt looks dark. Add light or raise Brightness.'),
    );
    expect(
      cameraController,
      contains('Receipt is very bright. Tilt it or lower Brightness.'),
    );
    expect(cameraController, contains('latestReadabilitySignal'));
    expect(cameraController, contains('latestFrameBrightness'));
    expect(cameraController, contains('Brightness'));
    expect(cameraController, contains('Reset'));
    expect(cameraController, contains('settingsSummary'));
    expect(cameraController, contains('Assisted receipt fill'));
    expect(cameraController, contains('Long receipt mode'));
    expect(cameraController, contains('Automatic capture'));
    expect(
      cameraController,
      contains(
        'Automatic capture is on. Hold steady, or tap the shutter anytime.',
      ),
    );
    expect(
      cameraController,
      contains('Automatic capture waits for several steady, readable frames.'),
    );
    expect(cameraController, contains('auto brightness assist'));
    expect(cameraController, contains('Auto brightness assist'));
    expect(cameraController, contains('Receipt edge guidance'));
    expect(cameraController, contains('Image cleanup'));
    expect(cameraController, contains('crop, straighten, grayscale, contrast'));
    expect(cameraController, contains('isAutoCaptureCurrentlyAllowed'));
    expect(
      cameraController,
      contains('Turn receipt edge guidance on before using automatic capture.'),
    );
    expect(
      cameraController,
      contains(
        'Receipt edge guidance is off, so automatic capture is held back.',
      ),
    );
    expect(
      cameraController,
      contains('latestAutoCaptureStatus = "edge_detection_off"'),
    );
    expect(cameraController, contains('Turn receipt edge guidance off'));
    expect(cameraController, contains('Receipt edge guidance is on.'));
    expect(
      cameraController,
      contains(
        'Receipt edge guidance is off. Take the clearest photo you can.',
      ),
    );
    expect(cameraController, contains('receipt guidance warnings'));
    expect(cameraController, contains('Receipt guidance warnings'));
    expect(cameraController, contains('receiptGuidanceWarningsEnabled'));
    expect(cameraController, contains('setReceiptGuidanceWarningsEnabled'));
    expect(cameraController, contains('Review style'));
    expect(cameraController, contains('Save-space backup'));
    expect(cameraController, contains('Take receipt photo'));
    expect(cameraController, contains('Receipt camera settings'));
    expect(cameraController, contains('doneButton'));
    expect(cameraController, contains('Finish receipt photos'));
    expect(cameraController, contains('finishWithCapturedPhotos'));
    expect(cameraController, contains('@objc private func cancelCapture()'));
    expect(cameraController, contains('if closeResultDelivered {'));
    expect(cameraController, contains('closeRetryCount += 1'));
    expect(cameraController, contains('presentingViewController != nil'));
    expect(cameraController, contains('pendingCloseAfterCapture'));
    expect(
      cameraController,
      contains('Finishing this receipt photo before closing.'),
    );
    expect(
      cameraController,
      contains(
        'finishWithCapturedPhotos(closeReason: "back_returned_captured_sections")',
      ),
    );
    expect(cameraController, contains('closeAction = "back_no_photo_cancel"'));
    expect(cameraController, contains('closeResultDelivered = true'));
    expect(cameraController, contains('capturedPhotoPaths'));
    expect(cameraController, contains('Done (\\(capturedPhotoPaths.count))'));
    expect(
      cameraController,
      contains('Section \\(capturedPhotoPaths.count) saved'),
    );
    expect(cameraController, contains('previousSectionGuidePhotoPath'));
    expect(cameraController, contains('buildPreviousSectionGuide'));
    expect(cameraController, contains('updatePreviousSectionGuide'));
    expect(cameraController, contains('previousSectionGuidePanel'));
    expect(cameraController, contains('previousSectionGuideImageView'));
    expect(
      cameraController,
      contains('Previous receipt section overlap guide'),
    );
    expect(
      cameraController,
      contains('Repeat 3-5 readable lines near the top of this photo.'),
    );
    expect(cameraController, contains('receipt_camera'));
    expect(cameraController, contains('HighResolutionPhoto'));
    expect(cameraController, contains('photoQualityPrioritization'));
    expect(cameraController, contains('maxPhotoQualityPrioritization'));
    expect(cameraController, contains('nativeCaptureDiagnostics'));
    expect(cameraController, contains('maintainiac_native_ios'));
    expect(cameraController, contains('photoByteSize'));
    expect(cameraController, contains('photoByteSizeBucket'));
    expect(cameraController, contains('latestCapturedPhotoWidth'));
    expect(cameraController, contains('latestCapturedPhotoHeight'));
    expect(cameraController, contains('latestCapturedMegapixelBucket'));
    expect(cameraController, contains('latestCapturedByteBucket'));
    expect(cameraController, contains('latestCapturedBrightnessBucket'));
    expect(cameraController, contains('latestCapturedSharpnessBucket'));
    expect(cameraController, contains('latestCapturedQualitySignal'));
    expect(cameraController, contains('latestCapturedExposureMismatch'));
    expect(cameraController, contains('sampleCapturedImageQuality'));
    expect(cameraController, contains('live_ok_capture_too_dark'));
    expect(
      cameraController,
      contains(
        'liveBucket == "lighting_ok" && capturedBrightnessBucket == "captured_too_dark"',
      ),
    );
    expect(
      cameraController,
      contains(
        'liveBucket == "lighting_ok" && capturedBrightnessBucket == "captured_dim"',
      ),
    );
    expect(
      cameraController,
      contains(
        'liveBucket == "too_dark_warning" || liveBucket == "dark_assisted"',
      ),
    );
    expect(
      cameraController,
      contains(
        'liveBucket == "glare_warning" || liveBucket == "bright_receipt_ok"',
      ),
    );
    expect(cameraController, isNot(contains('liveBucket == "normal"')));
    expect(cameraController, isNot(contains('liveBucket == "dark"')));
    expect(cameraController, isNot(contains('liveBucket == "bright"')));
    expect(cameraController, contains('recordCapturedPhotoQuality'));
    expect(cameraController, contains('megapixelBucket'));
    expect(cameraController, contains('very_large_over_8mb'));
    expect(cameraController, contains('photoCount'));
    expect(cameraController, contains('maxSectionCount'));
    expect(cameraController, contains('captureQualityMode'));
    expect(cameraController, contains('exposureTargetBias'));
    expect(cameraController, contains('videoZoomFactor'));
    expect(
      cameraController,
      contains('"exposureSliderEnabled": exposureSliderEnabled'),
    );
    expect(
      cameraController,
      contains('"exposureResetEnabled": exposureResetEnabled'),
    );
    expect(cameraController, contains('manualShutterAlwaysAvailable'));
    expect(
      cameraController,
      contains('"autoCaptureAllowed": autoCaptureAllowed'),
    );
    expect(
      cameraController,
      contains(
        '"autoCaptureCurrentlyAllowed": isAutoCaptureCurrentlyAllowed()',
      ),
    );
    expect(cameraController, contains('"closeAction": closeAction'));
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
    expect(cameraController, contains('"focusMode": focusMode'));
    expect(cameraController, contains('"exposureMode": exposureMode'));
    expect(cameraController, contains('"whiteBalanceMode": whiteBalanceMode'));
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
      contains('"whiteBalanceLockAttemptCount": whiteBalanceLockAttemptCount'),
    );
    expect(
      cameraController,
      contains('"whiteBalanceLockSuccessCount": whiteBalanceLockSuccessCount'),
    );
    expect(
      cameraController,
      contains('"whiteBalanceLockStatus": whiteBalanceLockStatus'),
    );
    expect(
      cameraController,
      contains('arguments["storageSafetyLevel"] as? String ?? dataSaverLevel'),
    );
    expect(
      cameraController,
      contains('arguments["storageConstrained"] as? Bool ?? false'),
    );
    expect(
      cameraController,
      contains('arguments["storageSafetyReason"] as? String ?? "normal"'),
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
    expect(cameraController, contains('ocrUsesOriginalFirst'));
    expect(cameraController, contains('hasPreviousSectionGuide'));
    expect(cameraController, isNot(contains('UIImagePickerController')));
    expect(cameraController, isNot(contains('PHPickerViewController')));

    expect(xcodeProject, contains('ReceiptCameraViewController.swift'));
    expect(
      xcodeProject,
      contains('ReceiptCameraViewController.swift in Sources'),
    );
  });
}
