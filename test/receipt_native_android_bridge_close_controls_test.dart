import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_android_bridge_source_readers.dart';

void main() {
  test('Android native receipt camera protects back close and touch controls', () async {
    final sources = await readAndroidReceiptCameraBridgeSources();
    final cameraActivity = sources.cameraActivity;
    final manifest = sources.manifest;

    expect(cameraActivity, contains('setJpegQuality(stillCaptureJpegQuality)'));
    expect(
      cameraActivity,
      contains('"stillCaptureMode" to stillCaptureModeLabel'),
    );
    expect(
      cameraActivity,
      contains('"stillCaptureJpegQuality" to stillCaptureJpegQuality'),
    );
    expect(cameraActivity, contains('SystemClock.elapsedRealtime()'));
    expect(cameraActivity, contains('latestCaptureToSavedMs'));
    expect(cameraActivity, contains('latestCaptureToReviewReadyMs'));
    expect(cameraActivity, contains('latestNativeCaptureLatencyBucket'));
    expect(cameraActivity, contains('captureElapsedSinceStart()'));
    expect(cameraActivity, contains('captureReviewLatencyBucket('));
    expect(
      cameraActivity,
      contains(
        '"nativeCaptureResponsivenessPolicy" to "manual_shutter_to_review_should_feel_immediate"',
      ),
    );
    expect(cameraActivity, contains('settingsContractVersion'));
    expect(
      cameraActivity,
      contains('"settingsContractVersion" to settingsContractVersion'),
    );
    expect(
      cameraActivity,
      contains('intent.getStringExtra("settingsContractVersion")'),
    );
    expect(cameraActivity, contains('latestCapturedVerticalQualitySignal'));
    expect(cameraActivity, contains('capturedVerticalQualitySignal'));
    expect(cameraActivity, contains('latestFramingWidthRatio'));
    expect(cameraActivity, contains('latestFramingHeightRatio'));
    expect(
      cameraActivity,
      contains('"latestFramingWidthRatio" to latestFramingWidthRatio'),
    );
    expect(
      cameraActivity,
      contains('"latestFramingHeightRatio" to latestFramingHeightRatio'),
    );
    expect(cameraActivity, contains('bottom_soft_blur_risk'));
    expect(cameraActivity, contains('latestCapturedBottomLuma'));
    expect(cameraActivity, contains('latestCapturedBottomTopLumaDelta'));
    expect(cameraActivity, contains('latestCapturedBottomTopLumaDeltaBucket'));
    expect(cameraActivity, contains('capturedBottomTopLumaDelta(sample)'));
    expect(cameraActivity, contains('capturedBottomTopLumaDeltaBucket('));
    expect(
      cameraActivity,
      contains(
        'if (sample.bottomLuma < 0.0 || sample.topLuma < 0.0) return -10000.0',
      ),
    );
    expect(
      cameraActivity,
      contains('!delta.isFinite() || delta < -999.0 -> "unknown"'),
    );
    expect(cameraActivity, contains('bottom_darker_than_top'));
    expect(cameraActivity, contains('bottom_brighter_than_top'));
    expect(cameraActivity, contains('setTargetRotation'));
    expect(cameraActivity, contains('enableTorch'));
    expect(cameraActivity, contains('ScaleGestureDetector'));
    expect(cameraActivity, contains('setZoomRatio'));
    expect(
      cameraActivity,
      contains('override fun onScaleBegin(detector: ScaleGestureDetector)'),
    );
    expect(
      cameraActivity,
      contains('receiptFrameGuide.setOnTouchListener(previewTouchListener)'),
    );
    expect(cameraActivity, contains('lastZoomStatus = "zoom_changed"'));
    expect(cameraActivity, contains('!zoomState.zoomRatio.isFinite()'));
    expect(cameraActivity, contains('!detector.scaleFactor.isFinite()'));
    expect(cameraActivity, contains('lastZoomStatus = "zoom_invalid_scale"'));
    expect(cameraActivity, contains('MotionEvent.ACTION_DOWN'));
    expect(
      cameraActivity,
      contains('requestDisallowInterceptTouchEvent(true)'),
    );
    expect(
      cameraActivity,
      contains('requestDisallowInterceptTouchEvent(false)'),
    );
    expect(cameraActivity, contains('MotionEvent.ACTION_POINTER_DOWN'));
    expect(cameraActivity, contains('MotionEvent.ACTION_MOVE'));
    expect(cameraActivity, contains('view.performClick()'));
    expect(cameraActivity, contains('effectiveMinZoom'));
    expect(cameraActivity, contains('effectiveMaxZoom'));
    expect(cameraActivity, isNot(contains('FocusMeteringAction')));
    expect(cameraActivity, isNot(contains('startFocusAndMetering')));
    expect(cameraActivity, contains('text = "Next"'));
    expect(cameraActivity, contains('text = "Add Next"'));
    expect(cameraActivity, contains('"Next"'));
    expect(cameraActivity, contains('"manual_add_photo"'));
    expect(cameraActivity, contains(r'"Next ($count photos)"'));
    expect(
      cameraActivity,
      contains(
        'contentDescription = "Review captured receipt photos in Maintainiac"',
      ),
    );
    expect(
      cameraActivity,
      contains(
        r'"Add receipt section ${nextReceiptSectionNumber()} if this receipt continues"',
      ),
    );
    expect(cameraActivity, contains('tapFocusEnabled'));
    expect(cameraActivity, contains('pinchZoomEnabled'));
    expect(cameraActivity, contains('exposureSliderEnabled'));
    expect(cameraActivity, contains('exposureResetEnabled'));
    expect(cameraActivity, contains('nativeControlContractTags'));
    expect(cameraActivity, contains('tapFocusEnabled = false'));
    expect(
      cameraActivity,
      contains('tapToFocusPolicy = "continuous_focus_primary_no_tap_focus"'),
    );
    expect(
      cameraActivity,
      isNot(contains('intent.getBooleanExtra("tapFocusEnabled", false)')),
    );
    expect(
      cameraActivity,
      isNot(contains('intent.getStringExtra("tapToFocusPolicy")')),
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
    expect(
      cameraActivity,
      contains('intent.getStringArrayListExtra("nativeControlContractTags")'),
    );
    expect(cameraActivity, contains('override fun onBackPressed()'));
    expect(cameraActivity, contains('override fun onKeyUp'));
    expect(cameraActivity, contains('KeyEvent.KEYCODE_BACK'));
    expect(cameraActivity, contains('OnBackInvokedCallback'));
    expect(
      cameraActivity,
      contains('OnBackInvokedDispatcher.PRIORITY_DEFAULT'),
    );
    expect(cameraActivity, contains('registerSystemBackHandler()'));
    expect(cameraActivity, contains('unregisterSystemBackHandler()'));
    expect(cameraActivity, contains('requestCloseCamera'));
    expect(
      cameraActivity,
      contains(
        'internal fun ReceiptCameraActivity.requestCloseCamera(backDispatchPath: String = "unknown")',
      ),
    );
    expect(cameraActivity, contains('lastBackDispatchPath = backDispatchPath'));
    expect(
      cameraActivity,
      contains('"lastBackDispatchPath" to lastBackDispatchPath'),
    );
    expect(cameraActivity, contains('bottomReviewButton'));
    expect(
      cameraActivity,
      contains(
        'bottomReviewButton.isEnabled = capturedPhotoPaths.isNotEmpty()',
      ),
    );
    expect(
      cameraActivity,
      contains('setOnClickListener { finishWithCapturedPhotos() }'),
    );
    expect(cameraActivity, contains('if (closeResultDelivered) {'));
    expect(cameraActivity, contains('closeRetryCount += 1'));
    expect(manifest, contains('android:enableOnBackInvokedCallback="true"'));
    expect(cameraActivity, contains('!isFinishing && !isDestroyed'));
    expect(cameraActivity, contains('pendingCloseAfterCapture'));
    expect(
      cameraActivity,
      contains('Saving this receipt photo before opening review.'),
    );
    expect(
      cameraActivity,
      contains('latestAutoCaptureStatus = "closing_after_capture"'),
    );
    expect(
      cameraActivity,
      contains('cancelWithoutCapturedPhoto("back_capture_failed_cancel")'),
    );
    expect(
      cameraActivity,
      contains(
        'internal fun ReceiptCameraActivity.cancelWithoutCapturedPhoto(reason: String)',
      ),
    );
    expect(
      cameraActivity,
      contains('cancelWithoutCapturedPhoto("back_no_photo_cancel")'),
    );
    expect(
      cameraActivity,
      contains('cancelWithoutCapturedPhoto("done_no_photo_cancel")'),
    );
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
    expect(
      cameraActivity,
      contains(r'Next photo is section ${capturedPhotoPaths.size + 1}'),
    );
    expect(cameraActivity, contains('Line up the ghost guide at the top'));
    expect(cameraActivity, isNot(contains('tap Done')));
    expect(cameraActivity, isNot(contains('Use captured receipt photos')));
    final requestCloseStart = cameraActivity.indexOf(
      'internal fun ReceiptCameraActivity.requestCloseCamera(backDispatchPath: String = "unknown")',
    );
    final inFlightCloseStart = cameraActivity.indexOf(
      'if (captureInFlight) {',
      requestCloseStart,
    );
    final normalClosingStart = cameraActivity.indexOf(
      'closingCamera = true',
      requestCloseStart,
    );
    expect(requestCloseStart, greaterThanOrEqualTo(0));
    expect(inFlightCloseStart, greaterThan(requestCloseStart));
    expect(normalClosingStart, greaterThan(inFlightCloseStart));
    final requestCloseBlock = cameraActivity.substring(
      requestCloseStart,
      cameraActivity.indexOf(
        'internal fun ReceiptCameraActivity.cancelWithoutCapturedPhoto(reason: String)',
        requestCloseStart,
      ),
    );
    expect(
      requestCloseBlock.indexOf(
        'cancelWithoutCapturedPhoto("back_no_photo_cancel")',
      ),
      lessThan(
        requestCloseBlock.indexOf(
          'finishWithCapturedPhotos(closeReason = "back_returned_captured_sections")',
        ),
      ),
    );
    expect(cameraActivity, contains('runCatching'));
    expect(cameraActivity, contains('unbindAll'));
    expect(
      cameraActivity,
      contains('internal fun ReceiptCameraActivity.isCameraSurfaceActive()'),
    );
    expect(
      cameraActivity,
      contains('lifecycleRegistry.currentState != Lifecycle.State.DESTROYED'),
    );
    expect(
      cameraActivity,
      contains('if (!isCameraSurfaceActive()) return@addListener'),
    );
    expect(
      cameraActivity,
      contains('if (!isCameraSurfaceActive() || closeResultDelivered) return'),
    );
    expect(
      cameraActivity,
      contains('if (!isCameraSurfaceActive() || closeResultDelivered) {'),
    );
    expect(cameraActivity, contains('captureInFlight = false'));
    expect(cameraActivity, contains('pendingCloseAfterCapture = false'));
    expect(cameraActivity, contains('preCaptureExposureAbortCount += 1'));
    expect(
      cameraActivity,
      contains('lastPreCaptureExposureAbortReason = if (closeResultDelivered)'),
    );
    expect(cameraActivity, contains('exposureCompensationRange'));
    expect(cameraActivity, contains('setExposureCompensationIndex'));
    expect(cameraActivity, contains('effectiveExposureRange'));
    expect(cameraActivity, contains('clampExposureIndex'));
    expect(cameraActivity, contains('ceil(sessionMinExposureOffset).toInt()'));
    expect(cameraActivity, contains('floor(sessionMaxExposureOffset).toInt()'));
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
  });
}
