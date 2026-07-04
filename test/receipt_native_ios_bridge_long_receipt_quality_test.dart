import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_ios_bridge_source_readers.dart';

void main() {
  test(
    'iOS native receipt camera keeps long receipt quality and source diagnostics',
    () async {
      final sources = await readIosReceiptCameraBridgeSources();
      final cameraController = sources.cameraController;

      expect(
        cameraController,
        contains('Next photo is section \\(capturedPhotoPaths.count + 1)'),
      );
      expect(cameraController, contains('Line up the ghost guide at the top'));
      expect(cameraController, contains('tap Next: Review Receipt Details'));
      expect(
        cameraController,
        contains('Saving this receipt photo before opening review.'),
      );
      expect(cameraController, isNot(contains('Use captured receipt photos')));
      expect(cameraController, contains('previousSectionGuidePhotoPath'));
      expect(
        cameraController,
        contains('previousSectionGuidePhotoPath = path.trimmingCharacters('),
      );
      expect(
        cameraController,
        contains('previousSectionMissingBottomAndTotals'),
      );
      expect(cameraController, contains('previousSectionGhostGuidePolicy'));
      expect(cameraController, contains('missing_bottom_edge_and_totals'));
      expect(cameraController, contains('buildPreviousSectionGuide'));
      expect(cameraController, contains('updatePreviousSectionGuide'));
      expect(cameraController, contains('previousSectionGuidePanel'));
      expect(cameraController, contains('previousSectionGuideImageView'));
      expect(
        cameraController,
        contains('Previous receipt section overlap guide'),
      );
      expect(cameraController, contains('previousSectionGhostGuideTitle'));
      expect(
        cameraController,
        contains('previousSectionGhostGuideInstruction'),
      );
      expect(cameraController, contains('Match the bottom section'));
      expect(
        cameraController,
        contains(
          'Keep the last readable lines in the top ghost slice, then repeat 3-5 readable lines so subtotal, total, and final lines can be matched.',
        ),
      );
      expect(
        cameraController,
        contains(
          'Repeat 3-5 readable lines near the top ghost slice of this photo.',
        ),
      );
      expect(
        cameraController,
        contains('bottom_overlap_ghost_at_top_repeat_3_to_5_lines'),
      );
      expect(cameraController, contains('receipt_camera'));
      expect(cameraController, contains('HighResolutionPhoto'));
      expect(cameraController, contains('photoQualityPrioritization'));
      expect(cameraController, contains('maxPhotoQualityPrioritization'));
      expect(cameraController, contains('receipt_fast_document_shutter'));
      expect(
        cameraController,
        contains('"stillCaptureMode": stillCaptureModeLabel'),
      );
      expect(cameraController, contains('latestCapturedVerticalQualitySignal'));
      expect(cameraController, contains('capturedVerticalQualitySignal'));
      expect(cameraController, contains('bottom_soft_blur_risk'));
      expect(cameraController, contains('latestCapturedBottomLuma'));
      expect(cameraController, contains('nativeCaptureDiagnostics'));
      expect(cameraController, contains('maintainiac_native_ios'));
      expect(cameraController, contains('photoByteSize'));
      expect(cameraController, contains('photoByteSizeBucket'));
      expect(cameraController, contains('latestCapturedPhotoWidth'));
      expect(cameraController, contains('latestCapturedPhotoHeight'));
      expect(cameraController, contains('latestCapturedAverageLuma'));
      expect(cameraController, contains('latestCapturedEdgeScore'));
      expect(cameraController, contains('latestCapturedBottomEdgeScore'));
      expect(cameraController, contains('receiptBottomEdgeDetected'));
      expect(cameraController, contains('receiptBottomEdgeStatus'));
      expect(
        cameraController,
        contains(
          '"receiptTotalsTextEvidenceStatus": "not_evaluated_native_capture"',
        ),
      );
      expect(cameraController, contains('return "bottom_visible"'));
      expect(cameraController, contains('return "bottom_soft_or_missing"'));
      expect(
        cameraController,
        contains('latestCapturedQualitySignal = "unknown"'),
      );
      expect(
        cameraController,
        contains('latestCapturedExposureMismatch = "unknown"'),
      );
      expect(
        cameraController,
        contains('roundedDiagnostic(sample.averageLuma)'),
      );
      expect(cameraController, contains('roundedDiagnostic(sample.edgeScore)'));
      expect(
        cameraController,
        contains('if !value.isFinite || value < 0 { return -1 }'),
      );
      expect(
        cameraController,
        contains('roundedDiagnostic(sample.bottomEdgeScore)'),
      );
      expect(cameraController, contains('latestCapturedMegapixelBucket'));
      expect(cameraController, contains('latestCapturedByteBucket'));
      expect(cameraController, contains('if !luma.isFinite || luma < 0'));
      expect(
        cameraController,
        contains('if !edgeScore.isFinite || edgeScore < 0'),
      );
      expect(cameraController, contains('latestCapturedBrightnessBucket'));
      expect(cameraController, contains('latestCapturedSharpnessBucket'));
      expect(cameraController, contains('latestCapturedQualitySignal'));
      expect(cameraController, contains('latestCapturedExposureMismatch'));
      expect(cameraController, contains('!liveBrightnessAtShutter.isFinite'));
      expect(cameraController, contains('!capturedAverageLuma.isFinite'));
      expect(
        cameraController,
        contains('if !delta.isFinite || delta <= -9999 { return "unknown" }'),
      );
      expect(
        cameraController,
        contains('return "saved_photo_darker_than_preview_watch"'),
      );
      expect(
        cameraController,
        contains('return "saved_photo_brighter_than_preview_watch"'),
      );
      expect(cameraController, contains('capturedLightingEvidence'));
      expect(cameraController, contains('capture_dim_review_needed'));
      expect(cameraController, contains('bottom_lighting_risk'));
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
      expect(cameraController, contains('receiptSectionCount'));
      expect(cameraController, contains('nextReceiptSectionNumber'));
      expect(cameraController, contains('top_to_bottom_numbered_sections'));
      expect(
        cameraController,
        contains('bottom_overlap_ghost_at_top_repeat_3_to_5_lines'),
      );
      expect(cameraController, contains('previousSectionGhostGuideVisible'));
      expect(cameraController, contains('previousSectionGhostGuideTitle'));
      expect(
        cameraController,
        contains('previousSectionGhostGuideInstruction'),
      );
      expect(cameraController, contains('previousSectionGhostSliceImage'));
      expect(
        cameraController,
        contains('previousSectionGhostSourceStartFraction'),
      );
      expect(
        cameraController,
        contains('previousSectionGhostSourceHeightFraction'),
      );
      expect(
        cameraController,
        contains('previousSectionGhostOverlayTopFraction'),
      );
      expect(
        cameraController,
        contains('previousSectionGhostOverlayHeightFraction'),
      );
      expect(cameraController, contains('previousSectionGhostOpacity'));
      expect(cameraController, contains('previousSectionGhostSlicePercent'));
      expect(cameraController, contains('.lowercased()'));
      expect(cameraController, contains('maxSectionCount'));
      expect(cameraController, contains('captureQualityMode'));
      expect(cameraController, contains('settingsContractVersion'));
      expect(
        cameraController,
        contains(
          'arguments["settingsContractVersion"] as? String ?? "receipt_native_camera_settings_v1"',
        ),
      );
      expect(
        cameraController,
        contains('"settingsContractVersion": settingsContractVersion'),
      );
      expect(cameraController, contains('exposureTargetBias'));
      expect(cameraController, contains('videoZoomFactor'));
      expect(
        cameraController,
        contains('"zoomGestureStartCount": zoomGestureStartCount'),
      );
      expect(
        cameraController,
        contains('"zoomUnavailableCount": zoomUnavailableCount'),
      );
      expect(cameraController, contains('"lastZoomStatus": lastZoomStatus'));
      expect(cameraController, contains('"lastZoomRatio": lastZoomRatio'));
      expect(
        cameraController,
        contains('"exposureSliderEnabled": exposureSliderEnabled'),
      );
      expect(
        cameraController,
        contains('"exposureResetEnabled": exposureResetEnabled'),
      );
      expect(
        cameraController,
        contains('"nativeControlContractTags": nativeControlContractTags'),
      );
      expect(cameraController, contains('manualShutterAlwaysAvailable'));
      expect(
        cameraController,
        contains('arguments["saveOriginalTemporarily"] as? Bool ?? true'),
      );
      expect(
        cameraController,
        contains('arguments["queueAcceptedCaptureLocally"] as? Bool ?? true'),
      );
      expect(
        cameraController,
        contains('arguments["ocrUsesOriginalFirst"] as? Bool ?? true'),
      );
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
      expect(
        cameraController,
        contains(
          '"autoCaptureSafetyPolicy": "optional_manual_shutter_always_available"',
        ),
      );
      expect(
        cameraController,
        contains(
          '"manualCapturePolicy": "guidance_advisory_manual_shutter_always_allowed"',
        ),
      );
      expect(
        cameraController,
        contains(
          'Off by default. Automatic capture waits for several steady, readable frames. Manual shutter always works.',
        ),
      );
    },
  );
}
