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
      expect(cameraActivity, contains('updateStableFramingGuidance('));
      expect(cameraActivity, contains('stableFramingGuidanceSignal(signal)'));
      expect(cameraActivity, contains('framingGuidanceCandidateSignal'));
      expect(cameraActivity, contains('framingGuidanceCandidateCount'));
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
        isNot(
          contains(
            'guidance.text = "Place the receipt inside the frame. Manual capture still works."',
          ),
        ),
      );
      expect(
        cameraActivity,
        contains('Receipt edges found. Hold steady and capture when ready.'),
      );
      expect(
        cameraActivity,
        isNot(
          contains(
            'guidance.text = framingGuidanceCopy(framing.confidenceBucket)',
          ),
        ),
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
      expect(cameraActivity, contains('Dialog(this)'));
      expect(cameraActivity, contains('dialog.window?.setLayout('));
      expect(cameraActivity, contains('ViewGroup.LayoutParams.MATCH_PARENT'));
      expect(
        cameraActivity,
        contains(
          'dialog.window?.setBackgroundDrawable(ColorDrawable(Color.rgb(22, 29, 32)))',
        ),
      );
      expect(cameraActivity, isNot(contains('AlertDialog.Builder')));
      expect(cameraActivity, contains('ScrollView(this)'));
      expect(cameraActivity, contains('addView(content)'));
      expect(cameraActivity, contains('Live camera'));
      expect(cameraActivity, isNot(contains('ACCOUNT AND STORAGE')));
      expect(cameraActivity, isNot(contains('RECEIPT ASSIST')));
      expect(cameraActivity, isNot(contains('Long receipt mode')));
      expect(cameraActivity, contains('CAPTURE FLOW'));
      expect(cameraActivity, contains('if (!canUseLongReceiptMode())'));
      expect(
        cameraActivity,
        contains('internal fun ReceiptCameraActivity.canUseLongReceiptMode()'),
      );
      expect(cameraActivity, isNot(contains('if (it && !canUseLongReceiptMode())')));
      expect(cameraActivity, contains('Autofocus and stabilization'));
      expect(
        cameraActivity,
        isNot(contains('continuous autofocus/readability guidance')),
      );
      expect(cameraActivity, isNot(contains('Use focus assist only if')));
      expect(cameraActivity, contains('Automatic capture'));
      expect(cameraActivity, contains('Reset This Camera Session'));
      expect(
        cameraActivity,
        contains(
          '// Expense and account preferences are deliberately not reset here.',
        ),
      );
      expect(cameraActivity, contains('autoCaptureEnabled = false'));
      expect(cameraActivity, contains('edgeDetectionEnabled = true'));
      expect(cameraActivity, contains('autoCropSuggestionEnabled = true'));
      expect(
        cameraActivity,
        contains(
          'Waits for 3 steady readable frames. Manual shutter always works.',
        ),
      );
      expect(
        cameraActivity,
        contains('Automatic capture is on. Hold steady, or capture anytime.'),
      );
      expect(cameraActivity, contains('latestAutoCaptureStatus = "off"'));
      expect(cameraActivity, contains('Automatic brightness help'));
      expect(cameraActivity, contains('textOn = checkedLabel'));
      expect(cameraActivity, contains('textOff = uncheckedLabel'));
      expect(cameraActivity, contains('showText = true'));
      expect(cameraActivity, contains('row.setOnClickListener'));
      expect(cameraActivity, contains('settingSlider('));
      expect(
        cameraActivity,
        contains('Reset returns exposure to automatic.'),
      );
      expect(
        cameraActivity,
        contains('This camera does not expose a supported brightness adjustment.'),
      );
      expect(cameraActivity, isNot(contains('Manual Brightness still wins.')));
      expect(cameraActivity, isNot(contains('Reset brightness')));
      expect(cameraActivity, contains('Find receipt edges'));
      expect(cameraActivity, contains('Receipts with more than one photo'));
      expect(
        cameraActivity,
        isNot(contains('Capture sections from top to bottom')),
      );
      expect(cameraActivity, isNot(contains('IMAGE HANDOFF')));
      expect(cameraActivity, contains('CAMERA CONTROLS'));
      expect(cameraActivity, contains('Autofocus and stabilization'));
      expect(cameraActivity, isNot(contains('Brightness and light')));
      expect(cameraActivity, isNot(contains('PRIVACY AND DIAGNOSTICS')));
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
          'Warn when paper edges may be cut off or the receipt may be too far away.',
        ),
      );
      expect(
        cameraActivity,
        contains(
          'Maintainiac uses the autofocus and stabilization that the phone exposes through its camera API.',
        ),
      );
      expect(
        cameraActivity,
        contains('No mode is required. Capture the first section'),
      );
      expect(cameraActivity, isNot(contains('Receipt guidance warnings')));
      expect(
        cameraActivity,
        isNot(contains('Experimental readability warnings')),
      );
      expect(
        cameraActivity,
        isNot(contains('Experimental dirty lens warning')),
      );
      expect(
        cameraActivity,
        isNot(contains('Warn about shake, glare, low light')),
      );
      expect(
        cameraActivity,
        contains(
          'Maintainiac uses the autofocus and stabilization that the phone exposes through its camera API.',
        ),
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
      expect(cameraActivity, isNot(contains('Receipt details style')));
      expect(cameraActivity, contains('safeReceiptReviewDepth'));
      expect(cameraActivity, contains('reviewDepth = safeReceiptReviewDepth('));
      expect(cameraActivity, isNot(contains('Saved proof size')));
      expect(
        cameraActivity,
        contains('internal fun ReceiptCameraActivity.settingChoiceGroup('),
      );
      expect(cameraActivity, contains('orientation = LinearLayout.VERTICAL'));
      expect(cameraActivity, isNot(contains('dataSaverLevel = selected')));
      expect(cameraActivity, isNot(contains('reviewDepth = selected')));
    },
  );
}
