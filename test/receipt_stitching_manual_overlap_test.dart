import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_stitching_image_helpers.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test(
    'manual overlap can stitch when automatic matching is uncertain',
    () async {
      final first = await writeTempReceiptStitchingImage(
        receiptStitchingSection(seed: 4, topTextOffset: 0),
        'manual_a',
      );
      final second = await writeTempReceiptStitchingImage(
        receiptStitchingSection(seed: 12, topTextOffset: 37),
        'manual_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
        manualOverlapPixels: const [260],
      );

      expect(result.didStitch, isTrue);
      expect(result.usedManualAdjustment, isTrue);
      expect(result.overlapPixels, [260]);
      expect(result.pairs.single.usedManualAdjustment, isTrue);
      expect(result.pairs.single.summaryLabel, contains('manual match'));
      expect(result.pairs.single.diagnosticCode, 'manual_overlap');
      expect(result.pairs.single.userCheckLabel, contains('manual overlap'));
      expect(result.ocrSourcePaths, hasLength(1));
      expect(result.detailLabel, contains('Manual match was used'));
    },
  );

  test('manual overlap fraction can drive stitching from review UI', () async {
    final first = await writeTempReceiptStitchingImage(
      receiptStitchingSection(seed: 7, topTextOffset: 0),
      'manual_fraction_a',
    );
    final second = await writeTempReceiptStitchingImage(
      receiptStitchingSection(seed: 9, topTextOffset: 28),
      'manual_fraction_b',
    );

    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: [first.path, second.path],
      manualOverlapFractions: const [.22],
    );

    expect(result.didStitch, isTrue);
    expect(result.usedManualAdjustment, isTrue);
    expect(result.overlapPixels.single, greaterThan(40));
    expect(result.ocrSourcePaths, hasLength(1));
  });

  test('zero manual overlap fraction does not claim manual match', () async {
    final sectionA = receiptStitchingSection(seed: 17, topTextOffset: 0);
    final sectionB = receiptStitchingSection(seed: 18, topTextOffset: 20);
    copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 320);
    final first = await writeTempReceiptStitchingImage(
      sectionA,
      'manual_zero_a',
    );
    final second = await writeTempReceiptStitchingImage(
      sectionB,
      'manual_zero_b',
    );

    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: [first.path, second.path],
      manualOverlapFractions: const [0],
    );

    expect(result.didStitch, isTrue, reason: result.detailLabel);
    expect(result.usedManualAdjustment, isFalse);
    expect(result.pairs.single.usedManualAdjustment, isFalse);
    expect(result.matchConfidenceLabel, isNot('Manual match'));
  });

  test(
    'manual overlap falls back when the requested overlap is unsafe',
    () async {
      final first = await writeTempReceiptStitchingImage(
        receiptStitchingSection(seed: 5, topTextOffset: 0),
        'manual_bad_a',
      );
      final second = await writeTempReceiptStitchingImage(
        receiptStitchingSection(seed: 6, topTextOffset: 0),
        'manual_bad_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
        manualOverlapPixels: const [999999],
      );

      expect(result.usedFallback, isTrue);
      expect(result.warning, contains('outside the safe range'));
      expect(result.fallbackReasonCode, 'manual_overlap_unsafe');
      expect(result.diagnosticReasonLabel, 'manual_overlap_unsafe');
      expect(result.failedPairIndex, 0);
      expect(result.ocrSourcePaths, [first.path, second.path]);
    },
  );

  test('manual overlap fraction rejects non-finite values safely', () async {
    final first = await writeTempReceiptStitchingImage(
      receiptStitchingSection(seed: 8, topTextOffset: 0),
      'manual_non_finite_a',
    );
    final second = await writeTempReceiptStitchingImage(
      receiptStitchingSection(seed: 10, topTextOffset: 0),
      'manual_non_finite_b',
    );

    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: [first.path, second.path],
      manualOverlapFractions: const [double.infinity],
    );

    expect(result.usedFallback, isTrue);
    expect(result.fallbackReasonCode, 'manual_overlap_unsafe');
    expect(result.diagnosticReasonLabel, 'manual_overlap_unsafe');
    expect(result.failedPairIndex, 0);
    expect(result.ocrSourcePaths, [first.path, second.path]);
  });
}
