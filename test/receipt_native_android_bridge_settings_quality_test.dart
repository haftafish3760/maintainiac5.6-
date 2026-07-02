import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_android_bridge_source_readers.dart';

void main() {
  test(
    'Android native receipt camera keeps settings quality and long receipt contracts',
    () async {
      final sources = await readAndroidReceiptCameraBridgeSources();
      final cameraActivity = sources.cameraActivity;

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
        contains('Move closer if text looks small; tap shutter if readable.'),
      );
      expect(
        cameraActivity,
        contains(
          'Receipt may be cut off. Leave paper edge visible, or tap shutter if readable.',
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
      expect(cameraActivity, contains('ScrollView(this)'));
      expect(cameraActivity, contains('addView(content)'));
      expect(
        cameraActivity,
        contains('Let Maintainiac help fill this receipt'),
      );
      expect(cameraActivity, contains('Long receipt mode'));
      expect(cameraActivity, contains('if (!canUseLongReceiptMode())'));
      expect(
        cameraActivity,
        contains('internal fun ReceiptCameraActivity.canUseLongReceiptMode()'),
      );
      expect(cameraActivity, contains('if (it && !canUseLongReceiptMode())'));
      expect(
        cameraActivity,
        contains(
          'Long receipt mode is unavailable for this device or storage setting.',
        ),
      );
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
      final guidanceToggleStart = cameraActivity.indexOf(
        'internal fun ReceiptCameraActivity.receiptGuidanceWarningsEnabled()',
      );
      final nextCaptureFileFunction = cameraActivity.indexOf(
        'internal fun ReceiptCameraActivity.newReceiptCaptureFile()',
        guidanceToggleStart,
      );
      final guidanceToggleEnd = nextCaptureFileFunction == -1
          ? cameraActivity.length
          : nextCaptureFileFunction;
      expect(guidanceToggleStart, greaterThanOrEqualTo(0));
      expect(guidanceToggleEnd, greaterThan(guidanceToggleStart));
      final guidanceToggleBlock = cameraActivity.substring(
        guidanceToggleStart,
        guidanceToggleEnd,
      );
      expect(guidanceToggleBlock, contains('shadowWarningEnabled'));
      expect(guidanceToggleBlock, contains('dirtyLensWarningEnabled'));
      expect(guidanceToggleBlock, contains('textTooSmallWarningEnabled'));
      expect(cameraActivity, contains('Receipt details style'));
      expect(
        cameraActivity,
        contains('Choose what Maintainiac shows after OCR reads the receipt.'),
      );
      expect(cameraActivity, contains('"pricesOnly" to "Prices only"'));
      expect(cameraActivity, contains('"detailedLines" to "Detailed lines"'));
      expect(cameraActivity, contains('Save-space proof size'));
      expect(
        cameraActivity,
        contains(
          'OCR reads the clear source first. This only changes the smaller saved proof kept for proof and cloud backup.',
        ),
      );
      expect(cameraActivity, contains('"original" to "Local original"'));
      expect(cameraActivity, contains('"light" to "High quality"'));
      expect(cameraActivity, contains('"balanced" to "Normal proof"'));
      expect(cameraActivity, contains('"strong" to "Low storage"'));
      expect(cameraActivity, contains('"maximum" to "Tiny proof"'));
      expect(
        cameraActivity,
        contains('internal fun ReceiptCameraActivity.settingChoiceGroup('),
      );
      expect(cameraActivity, contains('orientation = LinearLayout.VERTICAL'));
      expect(cameraActivity, contains('dataSaverLevel = selected'));
      expect(cameraActivity, contains('reviewDepth = selected'));
      expect(cameraActivity, contains('Take receipt photo'));
      expect(
        cameraActivity,
        contains(r'Add receipt section ${nextReceiptSectionNumber()}'),
      );
      expect(
        cameraActivity,
        contains('internal fun ReceiptCameraActivity.addSectionButtonTitle()'),
      );
      expect(
        cameraActivity,
        contains(
          'internal fun ReceiptCameraActivity.addSectionButtonAccessibilityLabel()',
        ),
      );
      expect(cameraActivity, contains('"Add Bottom"'));
      expect(
        cameraActivity,
        contains('Add bottom receipt section with overlap from this photo'),
      );
      expect(
        cameraActivity,
        contains('addPhotoButton.text = addSectionButtonTitle()'),
      );
      expect(
        cameraActivity,
        contains(
          'addPhotoButton.contentDescription = addSectionButtonAccessibilityLabel()',
        ),
      );
      expect(cameraActivity, contains('Add Next'));
      expect(cameraActivity, contains('controls.add("add_photo")'));
      expect(cameraActivity, contains('Receipt camera settings'));
      expect(cameraActivity, contains('doneButton'));
      expect(cameraActivity, contains('Finish'));
      expect(cameraActivity, contains('finishWithCapturedPhotos'));
      expect(cameraActivity, contains('capturedPhotoPaths'));
      expect(cameraActivity, contains(r'"Next ($count photos)"'));
      expect(
        cameraActivity,
        contains(r'Section ${capturedPhotoPaths.size} saved'),
      );
      expect(cameraActivity, contains('previousSectionGuidePhotoPath'));
      expect(cameraActivity, contains('previousSectionMissingBottomAndTotals'));
      expect(cameraActivity, contains('previousSectionGhostGuidePolicy'));
      expect(cameraActivity, contains('missing_bottom_edge_and_totals'));
      expect(cameraActivity, contains('buildPreviousSectionGuide'));
      expect(cameraActivity, contains('updatePreviousSectionGuide'));
      expect(cameraActivity, contains('previousSectionGuidePanel'));
      expect(cameraActivity, contains('previousSectionGuideImage'));
      expect(
        cameraActivity,
        contains('Previous receipt section overlap guide'),
      );
      expect(cameraActivity, contains('previousSectionGhostGuideTitle'));
      expect(cameraActivity, contains('previousSectionGhostGuideInstruction'));
      expect(cameraActivity, contains('Match the bottom section'));
      expect(
        cameraActivity,
        contains(
          'Keep the last readable lines in the top ghost slice, then repeat 3-5 readable lines so subtotal, total, and final lines can be matched.',
        ),
      );
      expect(
        cameraActivity,
        contains(
          'Repeat 3-5 readable lines near the top ghost slice of this photo.',
        ),
      );
      expect(
        cameraActivity,
        contains('bottom_overlap_ghost_at_top_repeat_3_to_5_lines'),
      );
      expect(cameraActivity, contains('receipt_camera'));
      expect(cameraActivity, contains('originalPhotoPaths'));
      expect(cameraActivity, contains('nativeCaptureDiagnostics'));
      expect(cameraActivity, contains('photoByteSize'));
      expect(cameraActivity, contains('photoByteSizeBucket'));
      expect(cameraActivity, contains('latestCapturedPhotoWidth'));
      expect(cameraActivity, contains('latestCapturedPhotoHeight'));
      expect(cameraActivity, contains('latestCapturedAverageLuma'));
      expect(cameraActivity, contains('latestCapturedEdgeScore'));
      expect(cameraActivity, contains('latestCapturedBottomEdgeScore'));
      expect(cameraActivity, contains('receiptBottomEdgeDetected'));
      expect(cameraActivity, contains('receiptBottomEdgeStatus'));
      expect(
        cameraActivity,
        contains(
          '"receiptTotalsTextEvidenceStatus" to "not_evaluated_native_capture"',
        ),
      );
      expect(cameraActivity, contains('return "bottom_visible"'));
      expect(cameraActivity, contains('return "bottom_soft_or_missing"'));
      expect(cameraActivity, contains('roundedDiagnostic(sample.averageLuma)'));
      expect(cameraActivity, contains('roundedDiagnostic(sample.edgeScore)'));
      expect(
        cameraActivity,
        contains('roundedDiagnostic(sample.bottomEdgeScore)'),
      );
      expect(cameraActivity, contains('latestCapturedMegapixelBucket'));
      expect(cameraActivity, contains('latestCapturedByteBucket'));
      expect(cameraActivity, contains('latestCapturedBrightnessBucket'));
      expect(cameraActivity, contains('latestCapturedSharpnessBucket'));
      expect(cameraActivity, contains('latestCapturedQualitySignal'));
      expect(cameraActivity, contains('latestCapturedExposureMismatch'));
      expect(
        cameraActivity,
        contains('return "saved_photo_darker_than_preview_watch"'),
      );
      expect(
        cameraActivity,
        contains('return "saved_photo_brighter_than_preview_watch"'),
      );
      expect(cameraActivity, contains('capturedLightingEvidence'));
      expect(cameraActivity, contains('capture_dim_review_needed'));
      expect(cameraActivity, contains('bottom_lighting_risk'));
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
      expect(cameraActivity, contains('receiptSectionCount'));
      expect(cameraActivity, contains('nextReceiptSectionNumber'));
      expect(cameraActivity, contains('top_to_bottom_numbered_sections'));
      expect(
        cameraActivity,
        contains('bottom_overlap_ghost_at_top_repeat_3_to_5_lines'),
      );
      expect(cameraActivity, contains('previousSectionGhostGuideVisible'));
      expect(cameraActivity, contains('previousSectionGhostGuideTitle'));
      expect(cameraActivity, contains('previousSectionGhostGuideInstruction'));
      expect(cameraActivity, contains('previousSectionGhostSliceBitmap'));
      expect(
        cameraActivity,
        contains('previousSectionGhostSourceStartFraction'),
      );
      expect(
        cameraActivity,
        contains('previousSectionGhostSourceHeightFraction'),
      );
      expect(
        cameraActivity,
        contains('previousSectionGhostOverlayTopFraction'),
      );
      expect(
        cameraActivity,
        contains('previousSectionGhostOverlayHeightFraction'),
      );
      expect(cameraActivity, contains('previousSectionGhostOpacity'));
      expect(cameraActivity, contains('previousSectionGhostSlicePercent'));
      expect(cameraActivity, contains('maxSectionCount'));
      expect(cameraActivity, contains('captureQualityMode'));
      expect(cameraActivity, contains('exposureCompensationIndex'));
      expect(cameraActivity, contains('zoomRatio'));
      expect(
        cameraActivity,
        contains('"zoomGestureStartCount" to zoomGestureStartCount'),
      );
      expect(
        cameraActivity,
        contains('"zoomUnavailableCount" to zoomUnavailableCount'),
      );
      expect(cameraActivity, contains('"lastZoomStatus" to lastZoomStatus'));
      expect(cameraActivity, contains('"lastZoomRatio" to lastZoomRatio'));
    },
  );
}
