import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('photo review result counts quality action outcomes', () {
    const readable = ReceiptPhotoQualityCheck(
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

    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/ready.jpg', '/tmp/crop.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/ready.jpg', '/tmp/crop.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded([
        '/tmp/ready.jpg',
        '/tmp/crop.jpg',
      ]),
      photoQualityChecksByPath: const {
        '/tmp/ready.jpg': readable,
        '/tmp/crop.jpg': cropReview,
      },
    );

    expect(
      result.acceptedPhotoQualityOutcomeCounts,
      containsPair('quality_action_continue_to_receipt_details', 1),
    );
    expect(
      result.acceptedPhotoQualityOutcomeCounts,
      containsPair('quality_action_crop_or_retake_then_next', 1),
    );
    expect(
      result.acceptedPhotoQualityOutcomeCounts,
      containsPair('quality_family_continue', 1),
    );
    expect(
      result.acceptedPhotoQualityOutcomeCounts,
      containsPair('quality_family_review', 1),
    );
    expect(result.acceptedPhotoHandoffOutcome, 'possible_partial_receipt');
  });

  test('best shot camera results preserve quality checks by index', () {
    const first = ReceiptPhotoQualityCheck(
      width: 1800,
      height: 2400,
      focusScore: 16,
      isLikelyReadable: true,
    );
    const second = ReceiptPhotoQualityCheck(
      width: 1200,
      height: 1600,
      focusScore: 10,
      isLikelyReadable: true,
    );

    const result = ReceiptCameraResult.bestShotCandidates(
      ['/tmp/best.jpg', '/tmp/backup.jpg'],
      qualityChecks: [first, second],
    );

    expect(result.isBestShotCandidateSet, isTrue);
    expect(result.qualityForIndex(0), first);
    expect(result.qualityForIndex(1), second);
    expect(result.qualityForIndex(2), isNull);
  });

  test(
    'receipt quality scores rank sharper higher resolution photos higher',
    () {
      const strong = ReceiptPhotoQualityCheck(
        width: 1800,
        height: 2400,
        focusScore: 16,
        isLikelyReadable: true,
        brightness: 142,
        contrast: 42,
        cropScore: .78,
        textBandScore: 14,
      );
      const weak = ReceiptPhotoQualityCheck(
        width: 700,
        height: 900,
        focusScore: 5,
        isLikelyReadable: false,
        brightness: 90,
        contrast: 12,
        cropScore: .32,
        textBandScore: 3,
      );

      expect(strong.reviewScore, greaterThan(weak.reviewScore));
      expect(strong.reviewScoreLabel, endsWith('%'));
      expect(weak.reviewScore, inInclusiveRange(0, 100));
      expect(strong.brightnessDistanceFromReceiptIdeal, 8);
      expect(weak.qualityWarnings, isNotEmpty);
      expect(weak.primaryIssueLabel, 'looks blurry');
      expect(weak.hasCriticalIssue, isTrue);
      expect(weak.reviewTitle, 'Retake Recommended');
    },
  );

  test('camera result summarizes best candidate quality and review state', () {
    const dim = ReceiptPhotoQualityCheck(
      width: 1800,
      height: 2400,
      focusScore: 15,
      brightness: 42,
      contrast: 35,
      cropScore: .7,
      textBandScore: 12,
      isLikelyReadable: false,
    );
    const readable = ReceiptPhotoQualityCheck(
      width: 1600,
      height: 2200,
      focusScore: 13,
      brightness: 150,
      contrast: 38,
      cropScore: .76,
      textBandScore: 12,
      isLikelyReadable: true,
    );

    const result = ReceiptCameraResult.bestShotCandidates(
      ['/tmp/dim.jpg', '/tmp/readable.jpg'],
      qualityChecks: [dim, readable],
    );

    expect(result.hasQuestionablePhoto, isTrue);
    expect(result.bestQualityCheck, readable);
    expect(result.qualitySummaryLabel, contains('Best of 2 photos'));
    expect(result.qualitySummaryLabel, contains('looks readable'));
  });

  test('soft but usable photos warn without becoming retake blockers', () {
    const soft = ReceiptPhotoQualityCheck(
      width: 1600,
      height: 2200,
      focusScore: 7,
      brightness: 142,
      contrast: 34,
      cropScore: .72,
      textBandScore: 12,
      isLikelyReadable: false,
    );

    expect(soft.needsReview, isTrue);
    expect(soft.hasCriticalIssue, isFalse);
    expect(soft.canContinueWithReview, isTrue);
    expect(soft.primaryIssueLabel, 'check sharpness');
    expect(soft.reviewTitle, 'Readable receipt photo');
    expect(soft.reviewGuidance, contains('Zoom in and check'));
  });

  test('single camera results may carry a photo quality check', () {
    const quality = ReceiptPhotoQualityCheck(
      width: 1400,
      height: 1900,
      focusScore: 12,
      isLikelyReadable: true,
    );

    const result = ReceiptCameraResult.single(
      ['/tmp/receipt.jpg'],
      qualityChecks: [quality],
    );

    expect(result.isBestShotCandidateSet, isFalse);
    expect(result.qualityForIndex(0), quality);
  });
}
