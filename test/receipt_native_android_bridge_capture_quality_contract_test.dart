import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_android_bridge_source_readers.dart';

void main() {
  test(
    'Android native receipt camera keeps capture quality and long receipt contracts',
    () async {
      final sources = await readAndroidReceiptCameraBridgeSources();
      final cameraActivity = sources.cameraActivity;

      expect(cameraActivity, contains('Take receipt photo'));
      expect(cameraActivity, contains('Add another receipt photo'));
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
      expect(cameraActivity, contains('Add Photo'));
      expect(cameraActivity, contains('controls.add("add_photo")'));
      expect(cameraActivity, contains('Receipt camera settings'));
      expect(cameraActivity, contains('doneButton'));
      expect(cameraActivity, contains('doneButton.visibility = View.GONE'));
      expect(cameraActivity, contains('doneButton.isEnabled = false'));
      expect(cameraActivity, contains('Finish'));
      expect(cameraActivity, contains('finishWithCapturedPhotos'));
      expect(cameraActivity, contains('capturedPhotoPaths'));
      expect(cameraActivity, contains(r'else -> "Done ($count)"'));
      expect(
        cameraActivity,
        contains('Opening receipt photo review. Captured photos are kept.'),
      );
      expect(cameraActivity, contains('previousSectionGuidePhotoPath'));
      expect(cameraActivity, contains('previousSectionMissingBottomAndTotals'));
      expect(cameraActivity, contains('previousSectionGhostGuidePolicy'));
      expect(cameraActivity, contains('?.lowercase()'));
      expect(cameraActivity, contains('missing_bottom_edge_and_totals'));
      expect(cameraActivity, contains('buildPreviousSectionGuide'));
      expect(cameraActivity, contains('updatePreviousSectionGuide'));
      expect(cameraActivity, contains('previousSectionGuidePanel'));
      expect(cameraActivity, contains('previousSectionGuideImage'));
      expect(cameraActivity, contains('!guideFile.isAbsolute'));
      expect(cameraActivity, contains('!guideFile.isFile'));
      expect(
        cameraActivity,
        contains('!isPreviousSectionGuideImagePath(guidePath)'),
      );
      expect(cameraActivity, contains('isPreviousSectionGuideImagePath'));
      expect(cameraActivity, isNot(contains('setImageURI(Uri.fromFile')));
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
        contains('if (!value.isFinite() || value < 0.0) return -1.0'),
      );
      expect(
        cameraActivity,
        contains('roundedDiagnostic(sample.bottomEdgeScore)'),
      );
      expect(cameraActivity, contains('latestCapturedMegapixelBucket'));
      expect(cameraActivity, contains('latestCapturedByteBucket'));
      expect(cameraActivity, contains('latestCapturedBrightnessBucket'));
      expect(cameraActivity, contains('latestCapturedSharpnessBucket'));
      expect(cameraActivity, contains('!luma.isFinite() || luma < 0.0'));
      expect(
        cameraActivity,
        contains('!edgeScore.isFinite() || edgeScore < 0.0'),
      );
      expect(cameraActivity, contains('latestCapturedQualitySignal'));
      expect(cameraActivity, contains('latestCapturedExposureMismatch'));
      expect(cameraActivity, contains('!liveBrightnessAtShutter.isFinite()'));
      expect(cameraActivity, contains('!capturedAverageLuma.isFinite()'));
      expect(
        cameraActivity,
        contains('!delta.isFinite() || delta <= -9999.0 -> "unknown"'),
      );
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
      expect(cameraActivity, contains('previousSectionGhostGuideVisible'));
      expect(cameraActivity, contains('previousSectionGhostGuideTitle'));
      expect(cameraActivity, contains('previousSectionGhostGuideInstruction'));
      expect(cameraActivity, contains('previousSectionGhostSliceBitmap'));
      expect(
        cameraActivity,
        contains(
          'val sourceStartFraction = boundedFraction(previousSectionGhostSourceStartFraction, 0.80)',
        ),
      );
      expect(
        cameraActivity,
        contains(
          'val sourceHeightFraction = boundedFraction(previousSectionGhostSourceHeightFraction, 0.20)',
        ),
      );
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
      expect(
        cameraActivity,
        contains(
          'internal fun ReceiptCameraActivity.finiteDoubleExtra(key: String, fallback: Double): Double',
        ),
      );
      expect(
        cameraActivity,
        contains('return if (value.isFinite()) value else fallback'),
      );
      expect(cameraActivity, contains('finiteDoubleExtra("minZoom", 1.0)'));
      expect(cameraActivity, contains('finiteDoubleExtra("maxZoom", 1.0)'));
      expect(
        cameraActivity,
        contains('autoCaptureMaxMotionScore = finiteDoubleExtra('),
      );
      expect(cameraActivity, contains('"autoCaptureMaxMotionScore"'));
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
