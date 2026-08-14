import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

void main() {
  test(
    'falls back with output dimensions when receipt would be too large',
    () async {
      final sectionA = receiptStitchingSection(seed: 30, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 31, topTextOffset: 14);
      copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 320);

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'too_large_a',
      );
      final second = await writeTempReceiptStitchingImage(
        sectionB,
        'too_large_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
        maxOutputHeight: 100,
      );

      expect(result.usedFallback, isTrue);
      expect(result.warning, contains('too long'));
      expect(result.fallbackReasonCode, 'output_too_large');
      expect(result.diagnosticReasonLabel, 'output_too_large');
      expect(result.stitchedWidth, greaterThan(0));
      expect(result.stitchedHeight, greaterThan(100));
      expect(result.pairs, isEmpty);
      expect(result.failedPairIndex, isNull);
      expect(result.hasValidOcrSourceContract, isTrue);
      expect(result.ocrSourceContractCode, 'fallback_ordered_sources_ready');
      expect(
        result.privacySafeOcrHandoffSafety,
        containsPair('stitchOcrSourceContractReady', true),
      );
    },
  );

  test(
    'falls back before stitching when output pixel cap would be exceeded',
    () async {
      final sectionA = receiptStitchingSection(seed: 70, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 71, topTextOffset: 14);
      copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 320);

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'pixel_cap_a',
      );
      final second = await writeTempReceiptStitchingImage(
        sectionB,
        'pixel_cap_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
        maxOutputPixels: 500000,
      );

      expect(result.usedFallback, isTrue);
      expect(result.fallbackReasonCode, 'output_too_large');
      expect(result.ocrSourcePaths, [first.path, second.path]);
      expect(result.stitchedWidth, greaterThan(0));
      expect(result.stitchedHeight, greaterThan(0));
      expect(result.stitchedPixelCount, greaterThan(500000));
      expect(result.stitchedPath, isNull);
      expect(result.warning, contains('too long'));
      expect(result.hasValidOcrSourceContract, isTrue);
      expect(result.ocrSourceContractCode, 'fallback_ordered_sources_ready');
    },
  );

  test('device target-width budget bounds proof and matching work', () async {
    final sectionA = receiptStitchingSection(seed: 80, topTextOffset: 0);
    final sectionB = receiptStitchingSection(seed: 81, topTextOffset: 14);
    copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 320);

    final first = await writeTempReceiptStitchingImage(
      sectionA,
      'device_width_a',
    );
    final second = await writeTempReceiptStitchingImage(
      sectionB,
      'device_width_b',
    );

    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: [first.path, second.path],
      manualOverlapFractions: const [320 / 1500],
      maxTargetWidth: 720,
    );

    expect(result.didStitch, isTrue);
    expect(result.stitchedWidth, 720);
    expect(result.stitchedPixelCount, lessThan(16000000));
  });
}
