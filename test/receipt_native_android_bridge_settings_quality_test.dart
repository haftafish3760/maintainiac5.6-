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
      expect(cameraActivity, contains('import java.util.UUID'));
      expect(cameraActivity, contains('UUID.randomUUID()'));
      expect(
        cameraActivity,
        isNot(contains(r'"receipt_${System.currentTimeMillis()}.jpg"')),
      );
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
      expect(
        cameraActivity,
        contains("Hold steady for the phone camera's autofocus."),
      );
      expect(
        cameraActivity,
        isNot(contains('continuous autofocus/readability guidance')),
      );
      expect(cameraActivity, isNot(contains('Use focus assist only if')));
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
      expect(cameraActivity, contains('Receipt framing checks'));
      expect(
        cameraActivity,
        contains(
          'Warn when the receipt may be too far away, text may be small',
        ),
      );
      expect(
        cameraActivity,
        contains(
          "The phone's native camera still owns focus, blur, glare, and exposure behavior.",
        ),
      );
      expect(cameraActivity, isNot(contains('Receipt guidance warnings')));
      expect(
        cameraActivity,
        isNot(contains('Warn about shake, glare, low light')),
      );
      expect(
        cameraActivity,
        contains("Hold steady for the phone camera's autofocus."),
      );
      expect(cameraActivity, contains('receiptGuidanceWarningsEnabled'));
      expect(cameraActivity, contains('setReceiptGuidanceWarningsEnabled'));
      expect(
        cameraActivity,
        contains(
          'internal fun ReceiptCameraActivity.hasExperimentalReceiptQualityWarningsEnabled()',
        ),
      );
      expect(
        cameraActivity,
        contains('latestReadabilitySignal = "neutral_workflow_guidance_only"'),
      );
      expect(
        cameraActivity,
        contains('latestMotionSignal = "neutral_workflow_guidance_only"'),
      );
      expect(
        cameraActivity,
        contains('if (!hasExperimentalReceiptQualityWarningsEnabled())'),
      );
      final neutralQualityStart = cameraActivity.indexOf(
        'if (!hasExperimentalReceiptQualityWarningsEnabled())',
      );
      final neutralQualityEnd = cameraActivity.indexOf(
        'if (!brightness.isFinite() || !motionScore.isFinite() || !shadowScore.isFinite())',
        neutralQualityStart,
      );
      expect(neutralQualityStart, greaterThanOrEqualTo(0));
      expect(neutralQualityEnd, greaterThan(neutralQualityStart));
      final neutralQualityBlock = cameraActivity.substring(
        neutralQualityStart,
        neutralQualityEnd,
      );
      expect(
        neutralQualityBlock,
        contains('latestMotionSignal = "neutral_workflow_guidance_only"'),
      );
      expect(neutralQualityBlock, isNot(contains('latestMotionSignal = if')));
      expect(neutralQualityBlock, isNot(contains('"steady"')));
      expect(
        cameraActivity,
        contains(
          '"experimentalReceiptQualityWarningsEnabled" to hasExperimentalReceiptQualityWarningsEnabled()',
        ),
      );
      expect(
        'Receipt has heavy shadows'.allMatches(cameraActivity).length,
        greaterThanOrEqualTo(2),
        reason:
            'Shadow guidance must be emitted, cleared on recovery, and cleared by defensive reset.',
      );
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
      expect(cameraActivity, contains('Receipt details style'));
      expect(
        cameraActivity,
        contains('Choose what Maintainiac shows after OCR reads the receipt.'),
      );
      expect(cameraActivity, contains('"pricesOnly" to "Prices only"'));
      expect(cameraActivity, contains('"detailedLines" to "Detailed lines"'));
      expect(cameraActivity, contains('safeReceiptReviewDepth'));
      expect(cameraActivity, contains('reviewDepth = safeReceiptReviewDepth('));
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
    },
  );
}
