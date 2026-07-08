import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

const _stitchingHeavyTimeout = Timeout(Duration(minutes: 2));

void main() {
  test('stitches receipt sections when the next photo is closer', () async {
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
  });

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
  );

  test('stitches receipt sections with slight handheld rotation', () async {
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
  });

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
}
