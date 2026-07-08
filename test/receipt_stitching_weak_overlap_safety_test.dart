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

  test(
    'requires review when a middle section is missing from a longer stack',
    () async {
      final sectionA = receiptStitchingSection(seed: 104, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 105, topTextOffset: 18);
      final sectionC = receiptStitchingSection(seed: 106, topTextOffset: 36);
      final sectionD = receiptStitchingSection(seed: 107, topTextOffset: 54);
      copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 330);
      copyReceiptStitchingOverlap(from: sectionB, to: sectionC, pixels: 330);
      copyReceiptStitchingOverlap(from: sectionC, to: sectionD, pixels: 330);

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'missing_middle_stack_a',
      );
      final third = await writeTempReceiptStitchingImage(
        sectionC,
        'missing_middle_stack_c',
      );
      final fourth = await writeTempReceiptStitchingImage(
        sectionD,
        'missing_middle_stack_d',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, third.path, fourth.path],
      );

      expectWeakOverlapRequiresReview(result);
      if (result.didStitch) {
        expect(result.ocrSourcePaths, [result.stitchedPath]);
        expect(
          result.assistedReadinessCode,
          'stitched_overlap_review_required',
        );
      } else {
        expect(result.ocrSourcePaths, [first.path, third.path, fourth.path]);
        expect(result.reviewPathLabel, '3 receipt sections top to bottom');
      }
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'requires review when receipt sections are provided in reverse order',
    () async {
      final sectionA = receiptStitchingSection(seed: 87, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 88, topTextOffset: 18);
      copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 330);

      final first = await writeTempReceiptStitchingImage(
        sectionB,
        'reverse_order_b',
      );
      final second = await writeTempReceiptStitchingImage(
        sectionA,
        'reverse_order_a',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expectWeakOverlapRequiresReview(result);
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'requires review when a continuation edge is severely cropped',
    () async {
      final sectionA = receiptStitchingSection(seed: 98, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 99, topTextOffset: 18);
      copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 330);
      final clippedSecond = clipReceiptStitchingSide(
        sectionB,
        left: 170,
        right: 170,
      );

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'severe_crop_a',
      );
      final second = await writeTempReceiptStitchingImage(
        clippedSecond,
        'severe_crop_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expectWeakOverlapRequiresReview(result);
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'requires review when the previous section edge is severely cropped',
    () async {
      final sectionA = receiptStitchingSection(seed: 102, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 103, topTextOffset: 18);
      copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 330);
      final clippedFirst = clipReceiptStitchingSide(
        sectionA,
        left: 165,
        right: 165,
      );

      final first = await writeTempReceiptStitchingImage(
        clippedFirst,
        'severe_previous_crop_a',
      );
      final second = await writeTempReceiptStitchingImage(
        sectionB,
        'severe_previous_crop_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expectWeakOverlapRequiresReview(result);
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'requires review when repeated-line vertical edges are clipped',
    () async {
      final sectionA = receiptStitchingSection(seed: 108, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 109, topTextOffset: 18);
      copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 330);
      final clippedFirst = clipReceiptStitchingVerticalEdge(
        sectionA,
        bottom: 220,
      );
      final clippedSecond = clipReceiptStitchingVerticalEdge(
        sectionB,
        top: 210,
      );

      final first = await writeTempReceiptStitchingImage(
        clippedFirst,
        'vertical_edge_crop_a',
      );
      final second = await writeTempReceiptStitchingImage(
        clippedSecond,
        'vertical_edge_crop_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expectWeakOverlapRequiresReview(result);
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'requires review when boilerplate footer bands look like overlap',
    () async {
      final firstSection = receiptStitchingBoilerplateSection(
        seed: 118,
        label: 'returns',
      );
      final laterSection = receiptStitchingBoilerplateSection(
        seed: 119,
        label: 'survey',
      );

      final first = await writeTempReceiptStitchingImage(
        firstSection,
        'boilerplate_footer_a',
      );
      final second = await writeTempReceiptStitchingImage(
        laterSection,
        'boilerplate_footer_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expectWeakOverlapRequiresReview(result);
    },
    timeout: _stitchingHeavyTimeout,
  );
}

void expectWeakOverlapRequiresReview(ReceiptStitchResult result) {
  expect(result.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
  expect(result.reviewFocusPairLabel, anyOf('', 'Photo 1 to 2'));
  if (result.didStitch) {
    final reviewPairs = result.pairs
        .where(
          (pair) =>
              !pair.usedManualAdjustment &&
              pair.overlapPixels > 0 &&
              pair.confidence >= .50 &&
              pair.confidence < .70,
        )
        .toList(growable: false);
    expect(reviewPairs, isNotEmpty);
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
