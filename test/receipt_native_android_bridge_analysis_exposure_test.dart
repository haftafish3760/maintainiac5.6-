import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_android_bridge_source_readers.dart';

void main() {
  test('Android native receipt camera keeps live analysis and exposure guardrails', () async {
    final sources = await readAndroidReceiptCameraBridgeSources();
    final cameraActivity = sources.cameraActivity;

    expect(cameraActivity, contains('autoCropSuggestionEnabled'));
    expect(cameraActivity, contains('grayscalePreviewEnabled'));
    expect(cameraActivity, contains('contrastBoostEnabled'));
    expect(cameraActivity, contains('shadowReductionEnabled'));
    expect(cameraActivity, contains('adaptiveThresholdEnabled'));
    expect(cameraActivity, contains('orientationCorrectionEnabled'));
    expect(
      cameraActivity,
      contains('OCR reads the temporary full-quality photo first.'),
    );
    expect(cameraActivity, contains('OCR reads temp full-quality first'));
    expect(cameraActivity, isNot(contains('OCR reads original first')));
    expect(
      cameraActivity,
      contains(
        'Smaller saved proof copies are made after the receipt has been read.',
      ),
    );
    expect(
      cameraActivity,
      contains('The shutter button always works immediately.'),
    );
    expect(
      cameraActivity,
      contains('lastCaptureBlockReason = "capture_in_flight"'),
    );
    expect(
      cameraActivity,
      contains('lastCaptureBlockReason = "closing_camera"'),
    );
    expect(
      cameraActivity,
      contains('lastCaptureBlockReason = "camera_surface_inactive"'),
    );
    expect(cameraActivity, contains('captureBlockedSurfaceInactiveCount += 1'));
    expect(cameraActivity, isNot(contains('if (!isAutoCaptureReady')));
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
      contains('intent.getBooleanExtra("dirtyLensWarningEnabled", true)'),
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
    expect(cameraActivity, contains('!dirtyLensWarningEnabled &&'));
    expect(cameraActivity, contains('"dirty_lens_or_haze"'));
    expect(
      cameraActivity,
      contains('Lens may be smudged. Wipe it if the receipt looks hazy.'),
    );
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
    expect(
      cameraActivity,
      contains(
        '!brightness.isFinite() || !motionScore.isFinite() || !shadowScore.isFinite()',
      ),
    );
    expect(cameraActivity, contains('"readability_unknown"'));
    expect(cameraActivity, contains('applyLiveFraming(framing)'));
    expect(cameraActivity, contains('hasUsableLiveFramingBounds(framing)'));
    expect(
      cameraActivity,
      contains(
        'if (!framing.found) {\n        latestFramingSignal = "receipt_not_found"',
      ),
    );
    expect(
      cameraActivity,
      contains(
        'if (!hasUsableLiveFramingBounds(framing)) {\n        latestFramingSignal = "receipt_bounds_invalid"',
      ),
    );
    expect(
      cameraActivity,
      contains('return "perspective_skipped_invalid_bounds"'),
    );
    expect(cameraActivity, contains('autoAdjustExposureForLiveFrame'));
    expect(
      cameraActivity,
      contains('autoAdjustExposureForLiveFrame(brightness, now, framing)'),
    );
    expect(cameraActivity, contains('waiting_for_receipt_target'));
    expect(cameraActivity, contains('brightness <= 150.0'));
    expect(cameraActivity, contains('brightness <= 138.0'));
    expect(cameraActivity, contains('brightness <= 104.0'));
    expect(cameraActivity, contains('brightness >= 250.0'));
    expect(cameraActivity, contains('brightness >= 252.0'));
    expect(cameraActivity, contains('brightness >= 254.0'));
    expect(
      cameraActivity,
      contains('!brightness.isFinite() || brightness < 0.0 -> "unknown"'),
    );
    expect(
      cameraActivity,
      contains('if (!brightness.isFinite() || brightness < 0.0)'),
    );
    expect(cameraActivity, contains('if (!liveBrightness.isFinite() ||'));
    expect(cameraActivity, contains('if (liveBucket == "unknown")'));
    expect(cameraActivity, contains('"bright_receipt_ok"'));
    expect(cameraActivity, contains('lastAutoExposureAdjustmentAt'));
    expect(cameraActivity, contains('lastAutoExposureDecision'));
    expect(cameraActivity, contains('prepareExposureBeforeCapture'));
    expect(cameraActivity, contains('!latestFrameBrightness.isFinite()'));
    expect(cameraActivity, contains('Camera2Interop.Extender(this)'));
    expect(cameraActivity, contains('CONTROL_AF_MODE_CONTINUOUS_PICTURE'));
    expect(
      cameraActivity,
      contains('intent.getBooleanExtra("continuousFocusEnabled"'),
    );
    expect(cameraActivity, contains('"continuousFocusEnabled" to'));
    expect(cameraActivity, contains('lastPreCaptureExposureDecision'));
    expect(cameraActivity, contains('lastPreCaptureExposureSkipReason'));
    expect(cameraActivity, contains('receiptStillCaptureMode'));
    expect(
      cameraActivity,
      contains('stillCaptureModeLabel = "receipt_latency_light_device"'),
    );
    expect(
      cameraActivity,
      contains('ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY'),
    );
    expect(
      cameraActivity,
      contains('stillCaptureModeLabel = "receipt_fast_document_shutter"'),
    );
    expect(
      cameraActivity,
      isNot(contains('ImageCapture.CAPTURE_MODE_MAXIMIZE_QUALITY')),
    );
    expect(
      cameraActivity,
      contains(
        'val lightReady = brightness in autoCaptureMinBrightness..autoCaptureMaxBrightness',
      ),
    );
    expect(cameraActivity, contains('latestFrameBrightness <= 55.0'));
    expect(cameraActivity, contains('latestFrameBrightness <= 70.0'));
    expect(cameraActivity, contains('latestFrameBrightness <= 104.0'));
    expect(cameraActivity, contains('latestFrameBrightness <= 138.0'));
    expect(cameraActivity, contains('latestFrameBrightness <= 150.0'));
    expect(cameraActivity, contains('latestFrameBrightness >= 238.0'));
    expect(cameraActivity, contains('"native_auto_exposure_kept_for_capture"'));
    expect(
      cameraActivity,
      contains('"pre_capture_dimming_skipped_native_auto"'),
    );
    expect(cameraActivity, isNot(contains('latestFrameBrightness >= 248.0')));
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
        'stableAutoExposureCandidate("fallback_dim", requiredFrames = 5)',
      ),
    );
    expect(
      cameraActivity,
      contains('stableAutoExposureCandidate("dim", requiredFrames = 5)'),
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
    expect(cameraActivity, contains('preCaptureExposureAdjustmentCount'));
    expect(cameraActivity, contains('tapFocusCount'));
    expect(cameraActivity, contains('tapFocusSuppressedAfterZoomCount'));
    expect(cameraActivity, contains('suppressTapFocusUntilMs'));
    expect(
      cameraActivity,
      isNot(
        contains('suppressTapFocusUntilMs = System.currentTimeMillis() + 350L'),
      ),
    );
    expect(
      cameraActivity,
      isNot(contains('lastFocusStatus = "tap_focus_suppressed_after_zoom"')),
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
    expect(cameraActivity, contains('whiteBalanceLockEnabled = false'));
    expect(
      cameraActivity,
      isNot(
        contains(
          'intent.getBooleanExtra("whiteBalanceLockEnabled", whiteBalanceMode == "locked")',
        ),
      ),
    );
    expect(
      cameraActivity,
      contains('intent.getBooleanExtra("saveOriginalTemporarily", true)'),
    );
    expect(
      cameraActivity,
      contains('intent.getBooleanExtra("queueAcceptedCaptureLocally", true)'),
    );
    expect(
      cameraActivity,
      contains('intent.getBooleanExtra("ocrUsesOriginalFirst", true)'),
    );
    expect(
      cameraActivity,
      isNot(contains('val shouldLockFocus = focusMode == "locked"')),
    );
    expect(
      cameraActivity,
      isNot(contains('val shouldLockExposure = exposureMode == "locked"')),
    );
    expect(
      cameraActivity,
      isNot(contains('val shouldLockWhiteBalance = whiteBalanceLockEnabled')),
    );
    expect(cameraActivity, isNot(contains('not_supported_cameraX')));
    expect(cameraActivity, isNot(contains('builder.disableAutoCancel()')));
    expect(cameraActivity, contains('focusLockAttemptCount'));
    expect(cameraActivity, contains('focusLockSuccessCount'));
    expect(cameraActivity, contains('exposureLockSuccessCount'));
    expect(cameraActivity, isNot(contains('lastFocusStatus = "locked"')));
    expect(
      cameraActivity,
      isNot(
        contains('Focus locked. Tap the shutter when the receipt is readable.'),
      ),
    );
  });
}
