import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test(
    'receipt quality scoring gives real receipts a bounded review score',
    () {
      const unreadable = ReceiptPhotoQualityCheck(
        width: 0,
        height: 0,
        focusScore: 0,
        isLikelyReadable: false,
      );
      const blurry = ReceiptPhotoQualityCheck(
        width: 900,
        height: 1100,
        focusScore: 5,
        isLikelyReadable: false,
      );
      const readable = ReceiptPhotoQualityCheck(
        width: 1600,
        height: 2200,
        focusScore: 14,
        isLikelyReadable: true,
      );

      expect(unreadable.reviewScore, 0);
      expect(blurry.reviewScore, inInclusiveRange(1, 60));
      expect(readable.reviewScore, greaterThan(blurry.reviewScore));
      expect(readable.reviewScore, inInclusiveRange(80, 100));
      expect(blurry.focusLabel, 'may be blurry');
      expect(blurry.reviewTitle, 'Retake Recommended');
      expect(blurry.reviewGuidance, contains('continuous autofocus'));
      expect(blurry.reviewGuidance, isNot(contains('focus assist')));
      expect(blurry.reviewGuidance, isNot(contains('tap focus')));
      expect(readable.focusLabel, 'sharp');
    },
  );

  test('review guidance separates soft warnings from critical retakes', () {
    const soft = ReceiptPhotoQualityCheck(
      width: 1600,
      height: 2200,
      focusScore: 7,
      brightness: 130,
      contrast: 30,
      cropScore: .7,
      textBandScore: 10,
      isLikelyReadable: false,
    );
    const glare = ReceiptPhotoQualityCheck(
      width: 1600,
      height: 2200,
      focusScore: 14,
      brightness: 250,
      contrast: 30,
      cropScore: .7,
      textBandScore: 10,
      isLikelyReadable: false,
    );

    expect(soft.needsReview, isTrue);
    expect(soft.hasCriticalIssue, isFalse);
    expect(soft.canContinueWithReview, isTrue);
    expect(soft.reviewTitle, 'Check Before Continuing');
    expect(soft.reviewGuidance, contains('Zoom in and check'));
    expect(soft.reviewScoreMeaningLabel, contains('Photo check'));
    expect(soft.reviewScoreMeaningLabel, contains('guidance only'));
    expect(glare.hasCriticalIssue, isTrue);
    expect(glare.canContinueWithReview, isFalse);
    expect(glare.reviewTitle, 'Retake Recommended');
    expect(glare.reviewGuidance, contains('Reduce glare'));
    expect(glare.reviewActionCode, 'retake_recommended_continue_allowed');
    expect(glare.reviewActionFamily, 'retake');
    expect(glare.reviewScoreMeaningLabel, contains('Retake is safer'));
    expect(glare.reviewScoreMeaningLabel, contains('Next is still available'));
    expect(glare.nextReviewActionLabel, contains('Next still works'));
  });

  test('photo review exposes stable action codes for UI flow', () {
    const ready = ReceiptPhotoQualityCheck(
      width: 1800,
      height: 2600,
      focusScore: 15,
      brightness: 148,
      contrast: 36,
      cropScore: .70,
      textBandScore: 12,
      isLikelyReadable: true,
    );
    const cropReview = ReceiptPhotoQualityCheck(
      width: 1500,
      height: 2100,
      focusScore: 10,
      brightness: 126,
      contrast: 24,
      cropScore: .22,
      textBandScore: 9,
      isLikelyReadable: false,
    );
    const closerReview = ReceiptPhotoQualityCheck(
      width: 820,
      height: 1300,
      focusScore: 12,
      brightness: 128,
      contrast: 24,
      cropScore: .62,
      textBandScore: 5,
      isLikelyReadable: true,
    );

    expect(ready.reviewActionCode, 'continue_to_receipt_details');
    expect(ready.reviewActionFamily, 'continue');
    expect(ready.nextReviewActionLabel, 'Tap Next for receipt details');
    expect(cropReview.reviewActionCode, 'crop_or_retake_then_next');
    expect(cropReview.reviewActionFamily, 'review');
    expect(cropReview.nextReviewActionLabel, contains('Crop or retake'));
    expect(
      closerReview.reviewActionCode,
      'check_readability_or_add_closer_photo',
    );
    expect(closerReview.reviewActionFamily, 'review');
    expect(closerReview.nextReviewActionLabel, contains('closer photo'));
  });

  test(
    'capture readiness keeps manual capture available while gating auto',
    () {
      const ready = ReceiptPhotoQualityCheck(
        width: 1800,
        height: 2600,
        focusScore: 15,
        brightness: 148,
        contrast: 36,
        cropScore: .70,
        textBandScore: 12,
        isLikelyReadable: true,
      );

      final autoOff = ready.captureReadiness(autoCaptureEnabled: false);
      final waiting = ready.captureReadiness(
        autoCaptureEnabled: true,
        stableFrameCount: 2,
        requiredStableFrames: 3,
      );
      final readyForAuto = ready.captureReadiness(
        autoCaptureEnabled: true,
        stableFrameCount: 3,
        requiredStableFrames: 3,
      );

      expect(autoOff.code, 'manual_ready_auto_capture_off');
      expect(autoOff.manualCaptureAllowed, isTrue);
      expect(autoOff.autoCaptureAllowed, isFalse);
      expect(waiting.code, 'auto_capture_waiting_for_stability');
      expect(waiting.manualCaptureAllowed, isTrue);
      expect(waiting.autoCaptureAllowed, isFalse);
      expect(readyForAuto.code, 'auto_capture_ready');
      expect(readyForAuto.manualCaptureAllowed, isTrue);
      expect(readyForAuto.autoCaptureAllowed, isTrue);
      expect(
        readyForAuto.diagnostics,
        containsPair('captureReadinessCode', 'auto_capture_ready'),
      );
    },
  );

  test('capture readiness clamps malformed stability thresholds', () {
    const ready = ReceiptPhotoQualityCheck(
      width: 1800,
      height: 2600,
      focusScore: 15,
      brightness: 148,
      contrast: 36,
      cropScore: .70,
      textBandScore: 12,
      isLikelyReadable: true,
    );

    final decision = ready.captureReadiness(
      autoCaptureEnabled: true,
      stableFrameCount: -5,
      requiredStableFrames: 0,
    );

    expect(decision.code, 'auto_capture_waiting_for_stability');
    expect(decision.manualCaptureAllowed, isTrue);
    expect(decision.autoCaptureAllowed, isFalse);
    expect(decision.stableFrameCount, 0);
    expect(decision.requiredStableFrames, 1);
    expect(decision.diagnostics, containsPair('stableFrameCount', 0));
    expect(decision.diagnostics, containsPair('requiredStableFrames', 1));
  });

  test('capture readiness blocks auto capture for risky photos only', () {
    const glare = ReceiptPhotoQualityCheck(
      width: 1600,
      height: 2200,
      focusScore: 14,
      brightness: 250,
      contrast: 30,
      cropScore: .7,
      textBandScore: 10,
      isLikelyReadable: false,
    );
    const cutOff = ReceiptPhotoQualityCheck(
      width: 1600,
      height: 2200,
      focusScore: 14,
      brightness: 135,
      contrast: 34,
      cropScore: .22,
      textBandScore: 12,
      isLikelyReadable: false,
    );

    final glareDecision = glare.captureReadiness(
      autoCaptureEnabled: true,
      stableFrameCount: 4,
      requiredStableFrames: 3,
    );
    final cutOffDecision = cutOff.captureReadiness(
      autoCaptureEnabled: true,
      stableFrameCount: 4,
      requiredStableFrames: 3,
    );

    expect(glareDecision.code, 'manual_only_quality_retake_recommended');
    expect(glareDecision.manualCaptureAllowed, isTrue);
    expect(glareDecision.autoCaptureAllowed, isFalse);
    expect(cutOffDecision.code, 'manual_only_check_framing');
    expect(cutOffDecision.manualCaptureAllowed, isTrue);
    expect(cutOffDecision.autoCaptureAllowed, isFalse);
  });

  test('capture readiness blocks auto capture for review-needed photos', () {
    const soft = ReceiptPhotoQualityCheck(
      width: 1600,
      height: 2200,
      focusScore: 7,
      brightness: 132,
      contrast: 30,
      cropScore: .70,
      textBandScore: 12,
      isLikelyReadable: false,
    );
    const lowContrast = ReceiptPhotoQualityCheck(
      width: 1600,
      height: 2200,
      focusScore: 14,
      brightness: 132,
      contrast: 12,
      cropScore: .70,
      textBandScore: 12,
      isLikelyReadable: false,
    );
    const dim = ReceiptPhotoQualityCheck(
      width: 1600,
      height: 2200,
      focusScore: 14,
      brightness: 86,
      contrast: 30,
      cropScore: .70,
      textBandScore: 12,
      isLikelyReadable: true,
    );

    for (final quality in [soft, lowContrast, dim]) {
      final decision = quality.captureReadiness(
        autoCaptureEnabled: true,
        stableFrameCount: 4,
        requiredStableFrames: 3,
      );

      expect(decision.code, 'manual_only_quality_review');
      expect(decision.manualCaptureAllowed, isTrue);
      expect(decision.autoCaptureAllowed, isFalse);
      expect(decision.label, contains('sharpness'));
      expect(decision.label, contains('light'));
      expect(decision.label, contains('text'));
    }
  });

  test('bright readable receipt paper is not treated as glare failure', () {
    const brightReadable = ReceiptPhotoQualityCheck(
      width: 1800,
      height: 2600,
      focusScore: 15,
      brightness: 234,
      contrast: 34,
      cropScore: .72,
      textBandScore: 12,
      isLikelyReadable: true,
    );

    expect(brightReadable.isBrightButReadable, isTrue);
    expect(brightReadable.isTooBright, isFalse);
    expect(brightReadable.hasCriticalIssue, isFalse);
    expect(brightReadable.needsReview, isFalse);
    expect(brightReadable.lightLabel, 'bright but usable');
    expect(brightReadable.reviewGuidance, contains('bright but usable'));
    expect(
      brightReadable.nextReviewActionLabel,
      'Tap Next for receipt details',
    );
  });

  test('receipt framing warnings do not fight readable dark borders', () {
    const readableWithDarkBorder = ReceiptPhotoQualityCheck(
      width: 1600,
      height: 2200,
      focusScore: 14,
      brightness: 135,
      contrast: 34,
      cropScore: .32,
      textBandScore: 12,
      isLikelyReadable: true,
    );
    const possiblyCutOff = ReceiptPhotoQualityCheck(
      width: 1600,
      height: 2200,
      focusScore: 14,
      brightness: 135,
      contrast: 34,
      cropScore: .22,
      textBandScore: 12,
      isLikelyReadable: false,
    );

    expect(readableWithDarkBorder.isPoorlyFramed, isFalse);
    expect(readableWithDarkBorder.needsReview, isFalse);
    expect(possiblyCutOff.isPoorlyFramed, isTrue);
    expect(possiblyCutOff.hasCriticalIssue, isFalse);
    expect(possiblyCutOff.reviewGuidance, contains('If every line'));
  });

  test('likely readable receipt photos are not scored like weak photos', () {
    const readableButTightFrame = ReceiptPhotoQualityCheck(
      width: 1100,
      height: 1800,
      focusScore: 10,
      brightness: 132,
      contrast: 24,
      cropScore: .31,
      textBandScore: 7,
      isLikelyReadable: true,
    );
    const darkReceipt = ReceiptPhotoQualityCheck(
      width: 1600,
      height: 2200,
      focusScore: 14,
      brightness: 62,
      contrast: 30,
      cropScore: .72,
      textBandScore: 12,
      isLikelyReadable: false,
    );

    expect(readableButTightFrame.reviewScore, greaterThanOrEqualTo(82));
    expect(readableButTightFrame.needsReview, isFalse);
    expect(readableButTightFrame.reviewBandLabel, 'Readable receipt photo');
    expect(
      readableButTightFrame.reviewScoreMeaningLabel,
      contains('Tap Next if the receipt text is readable'),
    );
    expect(readableButTightFrame.qualityEvidenceLabel, contains('photo check'));
    expect(darkReceipt.hasCriticalIssue, isTrue);
    expect(darkReceipt.reviewTitle, 'Retake Recommended');
    expect(darkReceipt.nextReviewActionLabel, contains('Next still works'));
  });

  test(
    'processor can accept readable receipts with one weak heuristic',
    () async {
      final processor =
          await File(
            'lib/shared/widgets/receipt_capture/receipt_image_processor.dart',
          ).readAsString() +
          await File(
            'lib/shared/widgets/receipt_capture/receipt_image_processor_quality_helpers.dart',
          ).readAsString();

      expect(processor, contains('final readableCore ='));
      expect(processor, contains('final strongTextEvidence ='));
      expect(processor, contains('final strongShapeEvidence ='));
      expect(processor, contains('final borderlineReadable ='));
      expect(
        processor,
        contains('(readableCore && readableCrop && readableLines)'),
      );

      const readableWithWeakBands = ReceiptPhotoQualityCheck(
        width: 1600,
        height: 2200,
        focusScore: 11,
        brightness: 132,
        contrast: 24,
        cropScore: .24,
        textBandScore: 5,
        isLikelyReadable: true,
      );
      const trulyWeak = ReceiptPhotoQualityCheck(
        width: 760,
        height: 880,
        focusScore: 5,
        brightness: 86,
        contrast: 11,
        cropScore: .18,
        textBandScore: 3,
        isLikelyReadable: false,
      );

      expect(readableWithWeakBands.reviewScore, greaterThanOrEqualTo(82));
      expect(readableWithWeakBands.shouldRetakeBeforeOcr, isFalse);
      expect(
        readableWithWeakBands.reviewActionCode,
        'check_readability_or_add_closer_photo',
      );
      expect(
        readableWithWeakBands.nextReviewActionLabel,
        'Check readability or add a closer photo',
      );
      expect(trulyWeak.shouldRetakeBeforeOcr, isTrue);
    },
  );
}
