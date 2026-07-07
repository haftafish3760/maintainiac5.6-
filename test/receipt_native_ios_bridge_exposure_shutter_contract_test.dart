import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_ios_bridge_source_readers.dart';

void main() {
  test(
    'iOS native receipt camera keeps exposure shutter and retired lock contracts',
    () async {
      final sources = await readIosReceiptCameraBridgeSources();
      final cameraController = sources.cameraController;
      final captureController = await File(
        'ios/Runner/ReceiptCameraViewControllerCapture.swift',
      ).readAsString();

      expect(cameraController, contains('autoAdjustExposureForLiveFrame'));
      expect(cameraController, contains('autoAdjustExposureForLiveFrame('));
      expect(cameraController, contains('framing: framing'));
      expect(cameraController, contains('waiting_for_receipt_target'));
      expect(
        cameraController,
        contains('resetExperimentalReceiptQualityGuidanceIfNeeded()'),
      );
      expect(
        cameraController,
        contains('currentGuidance.hasPrefix("Receipt has heavy shadows")'),
      );
      expect(
        'Receipt has heavy shadows'.allMatches(cameraController).length,
        greaterThanOrEqualTo(2),
        reason:
            'Shadow guidance must be emitted and cleared on recovery.',
      );
      expect(
        cameraController,
        contains('currentGuidance.hasPrefix("Lens may be smudged")'),
      );
      expect(
        cameraController,
        contains(
          'let hasReceiptTarget = !edgeDetectionEnabled || hasUsableLiveFramingBounds(framing)',
        ),
      );
      expect(
        cameraController,
        contains(
          'if !hasReceiptTarget {\n      latestMotionSignal = "waiting_for_receipt_target"',
        ),
      );
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
      expect(
        cameraController,
        contains('latestFrameBrightness.isFinite, latestFrameBrightness >= 0'),
      );
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
