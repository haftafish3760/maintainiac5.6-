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
}
