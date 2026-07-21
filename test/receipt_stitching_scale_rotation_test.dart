import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

const _stitchingHeavyTimeout = Timeout(Duration(minutes: 2));

void main() {
  test(
    'stitches receipt sections when the next photo is closer',
    () async {
      final sectionA = receiptStitchingSection(seed: 40, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 41, topTextOffset: 18);
      copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 340);
      final closerSecond = scaleReceiptStitchingShot(sectionB, scale: 1.12);

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'scale_close_a',
      );
      final second = await writeTempReceiptStitchingImage(
        closerSecond,
        'scale_close_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
      expect(result.pairs.single.diagnosticCode, isNotEmpty);
      expect(result.pairs.single.userCheckLabel, contains('Photo 1 to 2'));
      expect(result.ocrSourcePaths, hasLength(1));
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'stitches receipt sections when the next photo is farther away',
    () async {
      final sectionA = receiptStitchingSection(seed: 50, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 51, topTextOffset: 18);
      copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 340);
      final fartherSecond = scaleReceiptStitchingShot(sectionB, scale: .90);

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'scale_far_a',
      );
      final second = await writeTempReceiptStitchingImage(
        fartherSecond,
        'scale_far_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
      expect(result.pairs.single.diagnosticCode, isNotEmpty);
      expect(result.ocrSourcePaths, hasLength(1));
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'stitches receipt sections with slight handheld rotation',
    () async {
      final sectionA = receiptStitchingSection(seed: 60, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 61, topTextOffset: 18);
      copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 340);
      final rotatedSecond = rotateReceiptStitchingShot(sectionB, degrees: 1.2);

      final first = await writeTempReceiptStitchingImage(sectionA, 'rotate_a');
      final second = await writeTempReceiptStitchingImage(
        rotatedSecond,
        'rotate_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
      expect(result.pairs.single.summaryLabel, contains('%'));
      expect(result.pairs.single.diagnosticCode, isNotEmpty);
      expect(result.ocrSourcePaths, hasLength(1));
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'stitches receipt sections with stronger handheld rotation',
    () async {
      final sectionA = receiptStitchingSection(seed: 62, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 63, topTextOffset: 18);
      copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 340);
      final rotatedSecond = rotateReceiptStitchingShot(sectionB, degrees: 2.0);

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'rotate_stronger_a',
      );
      final second = await writeTempReceiptStitchingImage(
        rotatedSecond,
        'rotate_stronger_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'stitches receipt sections with rough handheld rotation',
    () async {
      final sectionA = receiptStitchingSection(seed: 66, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 67, topTextOffset: 18);
      copyReceiptStitchingOverlap(
        from: sectionA,
        to: sectionB,
        pixels: 340,
        dstY: 18,
      );
      final rotatedSecond = rotateReceiptStitchingShot(sectionB, degrees: 4.0);

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'rotate_rough_a',
      );
      final second = await writeTempReceiptStitchingImage(
        rotatedSecond,
        'rotate_rough_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
      expect(result.overlapPixels.single, greaterThan(240));
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'stitches receipt sections with modest horizontal handheld drift',
    () async {
      for (final drift in const [18, -18]) {
        final sectionA = receiptStitchingSection(
          seed: 64 + drift.abs(),
          topTextOffset: 0,
        );
        final sectionB = receiptStitchingSection(
          seed: 65 + drift.abs(),
          topTextOffset: 18,
        );
        copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 340);
        final shiftedSecond = shiftReceiptStitchingShot(
          sectionB,
          dx: drift,
          dy: 0,
        );

        final first = await writeTempReceiptStitchingImage(
          sectionA,
          'shift_${drift}_a',
        );
        final second = await writeTempReceiptStitchingImage(
          shiftedSecond,
          'shift_${drift}_b',
        );

        final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
          paths: [first.path, second.path],
        );

        expect(
          result.didStitch,
          isTrue,
          reason: 'drift=$drift ${result.detailLabel}',
        );
        expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
        expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      }
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'stitches receipt sections with combined scale rotation and drift',
    () async {
      final sectionA = receiptStitchingSection(seed: 130, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 131, topTextOffset: 18);
      copyReceiptStitchingOverlap(
        from: sectionA,
        to: sectionB,
        pixels: 340,
        dstY: 24,
      );
      final transformedSecond = shiftReceiptStitchingShot(
        rotateReceiptStitchingShot(
          scaleReceiptStitchingShot(sectionB, scale: 1.06),
          degrees: .8,
        ),
        dx: 24,
        dy: 0,
      );

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'combined_transform_a',
      );
      final second = await writeTempReceiptStitchingImage(
        transformedSecond,
        'combined_transform_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
      expect(result.pairs.single.diagnosticCode, isNotEmpty);
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'stitches three sections with mixed handheld transforms',
    () async {
      final sectionA = receiptStitchingSection(seed: 180, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 181, topTextOffset: 16);
      final sectionC = receiptStitchingSection(seed: 182, topTextOffset: 32);
      copyReceiptStitchingOverlap(
        from: sectionA,
        to: sectionB,
        pixels: 330,
        dstY: 18,
      );
      copyReceiptStitchingOverlap(
        from: sectionB,
        to: sectionC,
        pixels: 350,
        dstY: 24,
      );
      final transformedSecond = shiftReceiptStitchingShot(
        rotateReceiptStitchingShot(
          scaleReceiptStitchingShot(sectionB, scale: 1.06),
          degrees: .8,
        ),
        dx: 18,
        dy: 0,
      );
      final transformedThird = shiftReceiptStitchingShot(
        rotateReceiptStitchingShot(
          scaleReceiptStitchingShot(sectionC, scale: .94),
          degrees: -.8,
        ),
        dx: -18,
        dy: 0,
      );

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'mixed_transform_stack_a',
      );
      final second = await writeTempReceiptStitchingImage(
        transformedSecond,
        'mixed_transform_stack_b',
      );
      final third = await writeTempReceiptStitchingImage(
        transformedThird,
        'mixed_transform_stack_c',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path, third.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs, hasLength(2));
      expect(result.overlapPixels, hasLength(2));
      expect(
        result.pairs.every((pair) => pair.confidence >= .50),
        isTrue,
        reason: result.pairDiagnosticsLabel,
      );
      expect(result.pairDiagnosticsLabel, contains('Photo 1 to 2'));
      expect(result.pairDiagnosticsLabel, contains('Photo 2 to 3'));
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(result.ocrSourcePaths, hasLength(1));
    },
    timeout: _stitchingHeavyTimeout,
  );
}
