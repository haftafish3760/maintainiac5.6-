import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_ios_bridge_source_readers.dart';

void main() {
  test(
    'iOS native receipt camera keeps device settings auto capture and close controls',
    () async {
      final sources = await readIosReceiptCameraBridgeSources();
      final cameraController = sources.cameraController;

      expect(cameraController, contains('arguments["readyHoldMs"]'));
      expect(
        cameraController,
        contains('let requestedAutoCaptureStableFrameTarget ='),
      );
      expect(
        cameraController,
        contains('autoCaptureStableFrameTarget = autoCaptureAllowed'),
      );
      expect(
        cameraController,
        contains('min(max(requestedAutoCaptureStableFrameTarget, 2), 8)'),
      );
      expect(
        cameraController,
        contains('doubleArgument("autoCaptureMaxMotionScore"'),
      );
      expect(
        cameraController,
        contains('doubleArgument("autoCaptureMinBrightness"'),
      );
      expect(
        cameraController,
        contains('doubleArgument("autoCaptureMaxBrightness"'),
      );
      expect(
        cameraController,
        contains('doubleArgument("autoCaptureCooldownMs"'),
      );
      expect(
        cameraController,
        contains('autoCaptureCooldownMs = autoCaptureAllowed'),
      );
      expect(
        cameraController,
        contains('min(max(requestedAutoCaptureCooldownMs, 1200), 6000)'),
      );
      expect(
        cameraController,
        contains('assistedShotCount = min(max(arguments["assistedShotCount"]'),
      );
      expect(
        cameraController,
        contains(
          'bestShotCandidateCount = min(max(arguments["bestShotCandidateCount"]',
        ),
      );
      expect(
        cameraController,
        contains(
          'cameraResolutionTier = arguments["cameraResolutionTier"] as? String ?? "high"',
        ),
      );
      expect(
        cameraController,
        contains(
          'cameraWorkloadTier = arguments["cameraWorkloadTier"] as? String ?? "balanced"',
        ),
      );
      expect(cameraController, contains('maxLiveAnalysisPixels = max('));
      expect(
        cameraController,
        contains(
          'motionScore >= 0 && motionScore <= autoCaptureMaxMotionScore',
        ),
      );
      expect(cameraController, contains('hasUsableLiveFramingBounds(framing)'));
      expect(
        cameraController,
        contains('brightness >= autoCaptureMinBrightness'),
      );
      expect(
        cameraController,
        contains(
          r'ready_\(autoCaptureStableFrameCount)_of_\(autoCaptureStableFrameTarget)',
        ),
      );
      expect(
        cameraController,
        contains('autoCaptureCooldownUntilMs = nowMs + autoCaptureCooldownMs'),
      );
      expect(
        cameraController,
        contains(
          'Date().timeIntervalSince1970 * 1000 + Double(autoCaptureCooldownMs)',
        ),
      );
      expect(
        cameraController,
        isNot(contains('Date().timeIntervalSince1970 * 1000 + 2600')),
      );
      expect(
        cameraController,
        contains(
          'maxLocalPhotoBytes = arguments["maxLocalPhotoBytes"] as? Int ?? maxLocalPhotoBytes',
        ),
      );
      expect(
        cameraController,
        contains(
          'nativeCaptureMemoryPolicy = arguments["nativeCaptureMemoryPolicy"] as? String ?? nativeCaptureMemoryPolicy',
        ),
      );
      expect(
        cameraController,
        contains(
          'sessionMaxZoom = max(doubleArgument("maxZoom", fallback: 1.0), sessionMinZoom)',
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
      expect(
        cameraController,
        contains('"captureReadinessCode": captureReadinessCode()'),
      );
      expect(
        cameraController,
        contains('"captureReadinessLabel": captureReadinessLabel()'),
      );
      expect(cameraController, contains('"manualCaptureAllowed": true'));
      expect(
        cameraController,
        contains('"stableFrameCount": autoCaptureStableFrameCount'),
      );
      expect(
        cameraController,
        contains('"requiredStableFrames": autoCaptureStableFrameTarget'),
      );
      expect(cameraController, contains('func captureReadinessCode()'));
      expect(cameraController, contains('"manual_only_check_framing"'));
      expect(
        cameraController,
        contains('"manual_only_quality_retake_recommended"'),
      );
      expect(cameraController, contains('"waiting_for_quality_review"'));
      expect(cameraController, contains('"manual_only_quality_review"'));
      expect(
        cameraController,
        contains('receiptQualityReviewReadabilitySignals.contains'),
      );
      expect(cameraController, isNot(contains('latestReadabilitySignal ==')));
      expect(cameraController, contains('closingCamera'));
      expect(cameraController, contains('!closingCamera'));
      expect(cameraController, contains('"closing"'));
      expect(
        cameraController,
        contains(
          r'"ready_\(autoCaptureStableFrameCount)_of_\(autoCaptureStableFrameTarget)"',
        ),
      );
      expect(cameraController, contains('Receipt looks steady. Taking photo.'));
      expect(cameraController, contains('"waiting_for_edges"'));
      expect(cameraController, contains('"waiting_for_steady"'));
      expect(cameraController, contains('"waiting_for_light"'));
      expect(cameraController, contains('brightnessBucket'));
      expect(cameraController, contains('latestBrightnessBucket'));
      expect(cameraController, contains('"deviceTier": deviceTier'));
      expect(
        cameraController,
        contains('"devicePolicyLabel": devicePolicyLabel'),
      );
      expect(
        cameraController,
        contains('"cameraResolutionTier": cameraResolutionTier'),
      );
      expect(
        cameraController,
        contains('"cameraWorkloadTier": cameraWorkloadTier'),
      );
      expect(cameraController, contains('"readyHoldMs": readyHoldMs'));
      expect(
        cameraController,
        contains('"assistedShotCount": assistedShotCount'),
      );
      expect(
        cameraController,
        contains('"bestShotCandidateCount": bestShotCandidateCount'),
      );
      expect(
        cameraController,
        contains('"maxLiveAnalysisPixels": maxLiveAnalysisPixels'),
      );
      expect(
        cameraController,
        contains('"maxLocalPhotoBytes": maxLocalPhotoBytes'),
      );
      expect(
        cameraController,
        contains('totalCapturedByteSize + data.count > maxLocalPhotoBytes'),
      );
      expect(
        cameraController,
        contains('pendingCloseAfterCapture && !capturedPhotoPaths.isEmpty'),
      );
      expect(cameraController, contains('if shouldReturnExistingSections'));
      expect(
        cameraController,
        contains('FileManager.default.removeItem(at: url)'),
      );
      expect(cameraController, contains('"native_capture_over_byte_budget"'));
      expect(
        cameraController,
        contains('"nativeCaptureMemoryPolicy": nativeCaptureMemoryPolicy'),
      );
      expect(
        cameraController,
        contains('"maxCleanupPixels": maxCleanupPixels'),
      );
      expect(
        cameraController,
        contains(
          'maxStitchOutputPixels = max(arguments["maxStitchOutputPixels"] as? Int ?? 14000000, 0)',
        ),
      );
      expect(
        cameraController,
        contains(
          'maxStitchOutputHeight = max(arguments["maxStitchOutputHeight"] as? Int ?? 18000, 0)',
        ),
      );
      expect(
        cameraController,
        contains('"maxStitchOutputPixels": maxStitchOutputPixels'),
      );
      expect(
        cameraController,
        contains('"maxStitchOutputHeight": maxStitchOutputHeight'),
      );
      expect(cameraController, contains('"sessionMinZoom": sessionMinZoom'));
      expect(cameraController, contains('"sessionMaxZoom": sessionMaxZoom'));
      expect(
        cameraController,
        contains('"sessionMinExposureOffset": sessionMinExposureOffset'),
      );
      expect(
        cameraController,
        contains('"sessionMaxExposureOffset": sessionMaxExposureOffset'),
      );
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
      expect(cameraController, contains('UUID().uuidString'));
      expect(
        cameraController,
        isNot(
          contains(
            '"receipt_\\(Int(Date().timeIntervalSince1970 * 1000)).jpg"',
          ),
        ),
      );
      expect(cameraController, contains('settingsSummary'));
      expect(cameraController, contains('Assisted receipt fill'));
      expect(cameraController, contains('Long receipt mode'));
      expect(
        cameraController,
        contains("Hold steady for the phone camera's autofocus."),
      );
      expect(
        cameraController,
        isNot(contains('continuous autofocus/readability guidance')),
      );
      expect(cameraController, isNot(contains('Use focus assist only if')));
      expect(cameraController, contains('if !canUseLongReceiptMode()'));
      expect(cameraController, contains('func canUseLongReceiptMode()'));
      expect(
        cameraController,
        contains('if !self.longReceiptMode && !self.canUseLongReceiptMode()'),
      );
      expect(
        cameraController,
        contains(
          'Long receipt mode is unavailable for this device or storage setting.',
        ),
      );
      expect(cameraController, contains('Automatic capture'));
      expect(
        cameraController,
        contains(
          'Automatic capture is on. Hold steady, or tap the shutter anytime.',
        ),
      );
      expect(
        cameraController,
        contains(
          'Automatic capture waits for several steady, readable frames.',
        ),
      );
      expect(cameraController, contains('auto brightness assist'));
      expect(cameraController, contains('Auto brightness assist'));
      expect(cameraController, contains('Receipt edge guidance'));
      expect(cameraController, contains('Image cleanup'));
      expect(
        cameraController,
        contains('crop, straighten, grayscale, contrast'),
      );
      expect(cameraController, contains('isAutoCaptureCurrentlyAllowed'));
      expect(
        cameraController,
        contains(
          'Turn receipt edge guidance on before using automatic capture.',
        ),
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
      expect(cameraController, contains('receipt framing checks'));
      expect(cameraController, contains('Receipt framing checks'));
      expect(cameraController, isNot(contains('Receipt guidance warnings')));
      expect(
        cameraController,
        contains("Hold steady for the phone camera's autofocus."),
      );
      expect(cameraController, contains('receiptGuidanceWarningsEnabled'));
      expect(cameraController, contains('setReceiptGuidanceWarningsEnabled'));
      final guidanceToggleStart = cameraController.indexOf(
        'func receiptGuidanceWarningsEnabled()',
      );
      final guidanceToggleEnd = cameraController.indexOf(
        'func setReceiptGuidanceWarningsEnabled',
        guidanceToggleStart,
      );
      expect(guidanceToggleStart, greaterThanOrEqualTo(0));
      expect(guidanceToggleEnd, greaterThan(guidanceToggleStart));
      final guidanceToggleBlock = cameraController.substring(
        guidanceToggleStart,
        guidanceToggleEnd,
      );
      expect(guidanceToggleBlock, isNot(contains('shadowWarningEnabled')));
      expect(guidanceToggleBlock, isNot(contains('dirtyLensWarningEnabled')));
      expect(guidanceToggleBlock, isNot(contains('glareWarningEnabled')));
      expect(guidanceToggleBlock, isNot(contains('lowLightWarningEnabled')));
      expect(guidanceToggleBlock, isNot(contains('motionBlurWarningEnabled')));
      expect(guidanceToggleBlock, contains('tooFarTooCloseWarningEnabled'));
      expect(
        guidanceToggleBlock,
        contains('receiptFullyVisibleWarningEnabled'),
      );
      expect(guidanceToggleBlock, contains('textTooSmallWarningEnabled'));
      expect(cameraController, contains('Review style'));
      expect(cameraController, contains('Receipt details style: prices only'));
      expect(
        cameraController,
        contains('Receipt details style: detailed lines'),
      );
      expect(cameraController, contains('func setReceiptReviewStyle('));
      expect(cameraController, contains('safeReceiptReviewDepth'));
      expect(cameraController, contains('reviewDepth = value'));
      expect(
        cameraController,
        contains('reviewDepth = safeReceiptReviewDepth('),
      );
      expect(
        cameraController,
        contains(
          'Detailed receipt details are on. OCR will show item details when it can.',
        ),
      );
      expect(
        cameraController,
        contains(
          'Price-only receipt details are on. OCR will focus on line prices and totals.',
        ),
      );
      expect(cameraController, contains('Saved proof size'));
      expect(cameraController, contains('Save-space proof: local original'));
      expect(cameraController, contains('Save-space proof: high quality'));
      expect(cameraController, contains('Save-space proof: normal proof'));
      expect(cameraController, contains('Save-space proof: low storage'));
      expect(cameraController, contains('Save-space proof: tiny proof'));
      expect(
        cameraController,
        contains(
          'OCR reads the temporary full-quality photo first. Smaller saved proof copies are made after the receipt has been read.',
        ),
      );
      expect(cameraController, contains('func setDataSaverLevel('));
      expect(cameraController, contains('dataSaverLevel = value'));
      expect(
        cameraController,
        contains('OCR still reads the temporary full-quality photo first.'),
      );
      expect(cameraController, contains('Receipt camera settings'));
      expect(cameraController, contains('showReceiptCameraSettings'));
      expect(cameraController, isNot(contains('showSettingsPlaceholder')));
      expect(cameraController, contains('capturedPhotoPaths'));
      expect(cameraController, contains('settingsStatusStrip'));
      expect(cameraController, contains('settingsStatusText'));
      expect(cameraController, contains('Maintainiac receipt camera'));
      expect(cameraController, contains("phone's native camera baseline"));
      expect(cameraController, contains('workflow controls layered on top'));
      expect(
        cameraController,
        contains(
          'Capture quality: take the clearest receipt photo for OCR first. Save-space proof size is applied only after receipt assistance uses the clearest source.',
        ),
      );
      expect(cameraController, contains('Assist on'));
      expect(cameraController, contains('Manual fill'));
      expect(
        cameraController,
        contains('OCR reads the temporary full-quality photo first'),
      );
      expect(cameraController, contains('Close settings'));
      expect(cameraController, contains('proof and cloud backup'));
      expect(
        cameraController,
        contains('Manual shutter always works immediately'),
      );
    },
  );
}
