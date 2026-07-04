import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_ios_bridge_source_readers.dart';

void main() {
  test(
    'iOS native receipt camera keeps touch controls live analysis and exposure guardrails',
    () async {
      final sources = await readIosReceiptCameraBridgeSources();
      final cameraController = sources.cameraController;
      final captureController = await File(
        'ios/Runner/ReceiptCameraViewControllerCapture.swift',
      ).readAsString();

      expect(cameraController, contains('LiveReceiptFraming'));
      expect(
        cameraController,
        contains('AVCaptureVideoDataOutputSampleBufferDelegate'),
      );
      expect(cameraController, contains('AVCapturePhotoCaptureDelegate'));
      expect(cameraController, contains('AVCaptureDevice.default'));
      expect(cameraController, contains('photoOutput.capturePhoto'));
      expect(cameraController, isNot(contains('UITapGestureRecognizer')));
      expect(cameraController, contains('UIPinchGestureRecognizer'));
      expect(
        cameraController,
        isNot(contains('tapGesture.isEnabled = tapFocusEnabled')),
      );
      expect(
        cameraController,
        contains('pinchGesture.isEnabled = pinchZoomEnabled'),
      );
      expect(cameraController, isNot(contains('focusPointOfInterest')));
      expect(cameraController, isNot(contains('exposurePointOfInterest')));
      expect(cameraController, contains('videoZoomFactor'));
      expect(cameraController, contains('zoomGestureStartCount += 1'));
      expect(cameraController, contains('lastZoomStatus = "zoom_changed"'));
      expect(cameraController, contains('zoomUnavailableCount += 1'));
      expect(cameraController, contains('effectiveMinZoom'));
      expect(cameraController, contains('effectiveMaxZoom'));
      expect(cameraController, contains('minExposureTargetBias'));
      expect(cameraController, contains('maxExposureTargetBias'));
      expect(cameraController, contains('setExposureTargetBias'));
      expect(cameraController, contains('latestCaptureToSavedMs'));
      expect(cameraController, contains('latestCaptureToReviewReadyMs'));
      expect(cameraController, contains('latestNativeCaptureLatencyBucket'));
      expect(cameraController, contains('captureElapsedSinceStart()'));
      expect(cameraController, contains('captureReviewLatencyBucket('));
      expect(
        cameraController,
        contains(
          '"nativeCaptureResponsivenessPolicy": "manual_shutter_to_review_should_feel_immediate"',
        ),
      );
      expect(cameraController, contains('effectiveMinExposureBias'));
      expect(cameraController, contains('effectiveMaxExposureBias'));
      expect(cameraController, contains('clampExposureBias'));
      expect(cameraController, contains('tapFocusEnabled'));
      expect(cameraController, contains('pinchZoomEnabled'));
      expect(cameraController, contains('exposureSliderEnabled'));
      expect(cameraController, contains('exposureResetEnabled'));
      expect(cameraController, contains('nativeControlContractTags'));
      expect(cameraController, contains('tapFocusEnabled = false'));
      expect(
        cameraController,
        contains('tapToFocusPolicy = "continuous_focus_primary_no_tap_focus"'),
      );
      expect(
        cameraController,
        isNot(contains('arguments["tapFocusEnabled"] as? Bool ?? false')),
      );
      expect(
        cameraController,
        isNot(contains('arguments["tapToFocusPolicy"] as? String')),
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
      expect(
        cameraController,
        contains('arguments["nativeControlContractTags"] as? [String] ?? []'),
      );
      expect(
        cameraController,
        contains('arguments["continuousFocusEnabled"] as? Bool ??'),
      );
      expect(cameraController, contains('configureVideoAnalysisIfNeeded'));
      expect(
        cameraController,
        contains('configureInitialFocusAndExposure(for: device)'),
      );
      expect(cameraController, contains('if continuousFocusEnabled,'));
      expect(
        cameraController,
        contains('device.focusMode = .continuousAutoFocus'),
      );
      expect(
        cameraController,
        contains('lastFocusStatus = "continuous_autofocus_configured"'),
      );
      expect(
        cameraController,
        contains('lastFocusStatus = "continuous_autofocus_unavailable"'),
      );
      expect(cameraController, contains('tooFarTooCloseWarningEnabled ||'));
      expect(
        cameraController,
        contains('receiptFullyVisibleWarningEnabled ||'),
      );
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
        contains('arguments["dirtyLensWarningEnabled"] as? Bool ?? true'),
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
      expect(cameraController, contains('dirtyLensWarningEnabled ||'));
      expect(cameraController, contains('"dirty_lens_or_haze"'));
      expect(
        cameraController,
        contains('Lens may be smudged. Wipe it if the receipt looks hazy.'),
      );
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
      expect(cameraController, contains('if !brightness.isFinite ||'));
      expect(cameraController, contains('if !liveBrightness.isFinite ||'));
      expect(cameraController, contains('if liveBucket == "unknown"'));
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
        contains('Move closer if text looks small; tap shutter if readable.'),
      );
      expect(
        cameraController,
        contains(
          'Receipt may be cut off. Leave paper edge visible, or tap shutter if readable.',
        ),
      );
      expect(cameraController, contains('autoAdjustExposureForLiveFrame'));
      expect(cameraController, contains('autoAdjustExposureForLiveFrame('));
      expect(cameraController, contains('framing: framing'));
      expect(cameraController, contains('waiting_for_receipt_target'));
      expect(cameraController, contains('brightness <= 150'));
      expect(cameraController, contains('brightness <= 138'));
      expect(cameraController, contains('brightness <= 104'));
      expect(cameraController, contains('brightness >= 250'));
      expect(cameraController, contains('brightness >= 252'));
      expect(cameraController, contains('brightness >= 254'));
      expect(cameraController, contains('"bright_receipt_ok"'));
      expect(cameraController, contains('lastAutoExposureAdjustmentAt'));
      expect(cameraController, contains('lastAutoExposureDecision'));
      expect(cameraController, contains('prepareExposureBeforeCapture'));
      expect(cameraController, contains('lastPreCaptureExposureDecision'));
      expect(cameraController, contains('lastPreCaptureExposureSkipReason'));
      expect(cameraController, contains('preCaptureExposureAbortCount += 1'));
      expect(cameraController, contains('lastPreCaptureExposureAbortReason'));
      expect(
        cameraController,
        contains('lastPreCaptureExposureDecision = "aborted_camera_closing"'),
      );
      expect(
        captureController,
        isNot(
          contains('guard let self, self.isCameraUiUsable else { return }'),
        ),
      );
      expect(cameraController, contains('settings.photoQualityPrioritization'));
      expect(
        cameraController,
        contains('stillCaptureModeLabel = "receipt_fast_document_shutter"'),
      );
      expect(
        cameraController,
        isNot(contains('photoQualityPrioritization = .quality')),
      );
      expect(
        cameraController,
        contains('photoQualityPrioritization = .balanced'),
      );
      expect(cameraController, contains('latestFrameBrightness <= 55'));
      expect(cameraController, contains('latestFrameBrightness <= 70'));
      expect(cameraController, contains('latestFrameBrightness >= 238'));
      expect(
        cameraController,
        contains('"native_auto_exposure_kept_for_capture"'),
      );
      expect(
        cameraController,
        contains('"pre_capture_dimming_skipped_native_auto"'),
      );
      expect(cameraController, isNot(contains('latestFrameBrightness >= 248')));
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
          'stableAutoExposureCandidate("fallback_dim", requiredFrames: 5)',
        ),
      );
      expect(
        cameraController,
        contains('stableAutoExposureCandidate("dim", requiredFrames: 5)'),
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
      expect(cameraController, contains('preCaptureExposureAdjustmentCount'));
      expect(cameraController, contains('tapFocusCount'));
      expect(cameraController, contains('tapFocusSuppressedAfterZoomCount'));
      expect(cameraController, contains('suppressTapFocusUntil'));
      expect(
        cameraController,
        isNot(
          contains('suppressTapFocusUntil = Date().addingTimeInterval(0.35)'),
        ),
      );
      expect(
        cameraController,
        isNot(contains('lastFocusStatus = "tap_focus_suppressed_after_zoom"')),
      );
      expect(cameraController, contains('zoomChangeCount'));
      expect(cameraController, contains('manualExposureChangeCount'));
      expect(cameraController, contains('lastFocusStatus'));
      expect(
        cameraController,
        contains(
          'focusMode = arguments["focusMode"] as? String ?? "continuous"',
        ),
      );
      expect(
        cameraController,
        contains(
          'exposureMode = arguments["exposureMode"] as? String ?? "auto"',
        ),
      );
      expect(
        cameraController,
        contains(
          'whiteBalanceMode = arguments["whiteBalanceMode"] as? String ?? "auto"',
        ),
      );
      expect(cameraController, contains('whiteBalanceLockEnabled = false'));
      expect(
        cameraController,
        isNot(
          contains(
            'whiteBalanceLockEnabled = arguments["whiteBalanceLockEnabled"] as? Bool ?? (whiteBalanceMode == "locked")',
          ),
        ),
      );
      expect(
        cameraController,
        isNot(contains('let shouldLockFocus = focusMode == "locked"')),
      );
      expect(
        cameraController,
        isNot(contains('let shouldLockExposure = exposureMode == "locked"')),
      );
      expect(
        cameraController,
        isNot(contains('let shouldLockWhiteBalance = whiteBalanceLockEnabled')),
      );
      expect(
        cameraController,
        isNot(contains('lockFocusAndExposureIfSupported')),
      );
      expect(
        cameraController,
        isNot(contains('cameraDevice.isFocusModeSupported(.locked)')),
      );
      expect(
        cameraController,
        isNot(contains('cameraDevice.isExposureModeSupported(.locked)')),
      );
      expect(
        cameraController,
        isNot(contains('cameraDevice.isWhiteBalanceModeSupported(.locked)')),
      );
      expect(
        cameraController,
        isNot(contains('cameraDevice.whiteBalanceMode = .locked')),
      );
      expect(cameraController, contains('focusLockAttemptCount'));
      expect(cameraController, contains('focusLockSuccessCount'));
      expect(cameraController, contains('exposureLockSuccessCount'));
      expect(cameraController, contains('whiteBalanceLockAttemptCount'));
      expect(cameraController, contains('whiteBalanceLockSuccessCount'));
      expect(cameraController, contains('whiteBalanceLockStatus'));
      expect(cameraController, isNot(contains('? "locked"')));
      expect(
        cameraController,
        isNot(
          contains(
            'Focus locked. Tap the shutter when the receipt is readable.',
          ),
        ),
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
        contains('deviceTier = arguments["deviceTier"] as? String ?? "medium"'),
      );
      expect(
        cameraController,
        contains(
          'devicePolicyLabel = arguments["devicePolicyLabel"] as? String ?? "balanced_receipt_camera"',
        ),
      );
    },
  );
}
