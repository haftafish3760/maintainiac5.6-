import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
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

  test('receipt quality scores rank sharper higher resolution photos higher', () {
    const strong = ReceiptPhotoQualityCheck(
      width: 1800,
      height: 2400,
      focusScore: 16,
      isLikelyReadable: true,
    );
    const weak = ReceiptPhotoQualityCheck(
      width: 700,
      height: 900,
      focusScore: 5,
      isLikelyReadable: false,
    );

    expect(strong.reviewScore, greaterThan(weak.reviewScore));
    expect(strong.reviewScoreLabel, endsWith('%'));
    expect(weak.reviewScore, inInclusiveRange(0, 100));
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
