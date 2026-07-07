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

  test('zero manual overlap pixels do not block automatic stitching', () async {
    final sectionA = receiptStitchingSection(seed: 19, topTextOffset: 0);
    final sectionB = receiptStitchingSection(seed: 20, topTextOffset: 20);
    copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 320);
    final first = await writeTempReceiptStitchingImage(
      sectionA,
      'manual_zero_pixels_a',
    );
    final second = await writeTempReceiptStitchingImage(
      sectionB,
      'manual_zero_pixels_b',
    );

    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: [first.path, second.path],
      manualOverlapPixels: const [0],
    );

    expect(result.didStitch, isTrue, reason: result.detailLabel);
    expect(result.usedManualAdjustment, isFalse);
    expect(result.pairs.single.usedManualAdjustment, isFalse);
    expect(result.fallbackReasonCode, isEmpty);
    expect(result.ocrSourcePaths, hasLength(1));
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

  test(
    'manual overlap supports multi-section long receipt stitching',
    () async {
      final sectionA = receiptStitchingSection(seed: 21, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 22, topTextOffset: 24);
      final sectionC = receiptStitchingSection(seed: 23, topTextOffset: 48);
      copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 240);
      copyReceiptStitchingOverlap(from: sectionB, to: sectionC, pixels: 280);

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'manual_multi_a',
      );
      final second = await writeTempReceiptStitchingImage(
        sectionB,
        'manual_multi_b',
      );
      final third = await writeTempReceiptStitchingImage(
        sectionC,
        'manual_multi_c',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path, third.path],
        manualOverlapPixels: const [240, 280],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.usedManualAdjustment, isTrue);
      expect(result.overlapPixels, [240, 280]);
      expect(result.pairs, hasLength(2));
      expect(result.pairs.every((pair) => pair.usedManualAdjustment), isTrue);
      expect(result.ocrSourcePaths, hasLength(1));
    },
  );

  test(
    'manual overlap can guide one pair while auto matching handles the next',
    () async {
      final sectionA = receiptStitchingSection(seed: 31, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 32, topTextOffset: 18);
      final sectionC = receiptStitchingSection(seed: 33, topTextOffset: 36);
      copyReceiptStitchingOverlap(from: sectionB, to: sectionC, pixels: 260);

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'manual_then_auto_a',
      );
      final second = await writeTempReceiptStitchingImage(
        sectionB,
        'manual_then_auto_b',
      );
      final third = await writeTempReceiptStitchingImage(
        sectionC,
        'manual_then_auto_c',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path, third.path],
        manualOverlapPixels: const [220],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.overlapPixels, hasLength(2));
      expect(result.overlapPixels.first, 220);
      expect(result.pairs, hasLength(2));
      expect(result.pairs.first.usedManualAdjustment, isTrue);
      expect(result.pairs.last.usedManualAdjustment, isFalse);
      expect(result.pairs.last.confidence, greaterThanOrEqualTo(.50));
      expect(result.usedManualAdjustment, isTrue);
      expect(result.ocrSourcePaths, hasLength(1));
    },
  );
}
