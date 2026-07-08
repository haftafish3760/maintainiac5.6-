import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

const _stitchingHeavyTimeout = Timeout(Duration(minutes: 2));

void main() {
  test(
    'keeps blurred continuation overlap in review-required stitch lane',
    () async {
      final sectionA = receiptStitchingSection(seed: 74, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 75, topTextOffset: 18);
      copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 330);
      final blurredSecond = blurReceiptStitchingShot(sectionB, radius: 10);

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'blurred_overlap_a',
      );
      final second = await writeTempReceiptStitchingImage(
        blurredSecond,
        'blurred_overlap_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expectWeakOverlapRequiresReview(result);
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'requires review when weak overlap could hide a missing middle section',
    () async {
      final sectionA = receiptStitchingSection(seed: 84, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 85, topTextOffset: 18);
      final sectionC = receiptStitchingSection(seed: 86, topTextOffset: 36);
      copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 330);
      copyReceiptStitchingOverlap(from: sectionB, to: sectionC, pixels: 330);

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'missing_middle_a',
      );
      final third = await writeTempReceiptStitchingImage(
        sectionC,
        'missing_middle_c',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, third.path],
      );

      expectWeakOverlapRequiresReview(result);
    },
  );
}

void expectWeakOverlapRequiresReview(ReceiptStitchResult result) {
  expect(result.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
  expect(result.reviewFocusPairLabel, anyOf('', 'Photo 1 to 2'));
  if (result.didStitch) {
    expect(result.pairs.single.confidence, inInclusiveRange(.50, .69));
    expect(result.hasLowConfidenceAutomaticOverlap, isTrue);
    expect(result.assistedReadinessCode, 'stitched_overlap_review_required');
    expect(
      result.privacySafeOcrHandoffSafety,
      containsPair(
        'stitchAssistedReadinessCode',
        'stitched_overlap_review_required',
      ),
    );
    expect(
      result.privacySafeOcrHandoffSafety,
      containsPair('stitchReviewFocusPairLabel', 'Photo 1 to 2'),
    );
  } else {
    expect(result.usedFallback, isTrue, reason: result.detailLabel);
    expect(result.fallbackReasonCode, 'overlap_confidence_low');
    expect(result.failedPairLabel, 'Photo 1 to 2');
    expect(result.assistedReadinessCode, 'stitch_contract_review_required');
  }
}
