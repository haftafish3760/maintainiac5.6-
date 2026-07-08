import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

const _stitchingHeavyTimeout = Timeout(Duration(minutes: 2));

void main() {
  test(
    'stitches faded worn receipt sections with delayed overlap and drift',
    () async {
      final sectionA = addReceiptStitchingWear(
        fadeReceiptStitchingInk(
          receiptStitchingSection(seed: 88, topTextOffset: 0),
          amount: .28,
        ),
        seed: 880,
        wrinkleCount: 12,
        smudgeCount: 7,
      );
      final sectionB = addReceiptStitchingWear(
        fadeReceiptStitchingInk(
          receiptStitchingSection(seed: 89, topTextOffset: 22),
          amount: .30,
        ),
        seed: 890,
        wrinkleCount: 10,
        smudgeCount: 6,
      );
      copyReceiptStitchingOverlap(
        from: sectionA,
        to: sectionB,
        pixels: 335,
        dstY: 72,
      );
      final shiftedSecond = shiftReceiptStitchingShot(sectionB, dx: 36, dy: 0);

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'worn_faded_drift_a',
      );
      final second = await writeTempReceiptStitchingImage(
        shiftedSecond,
        'worn_faded_drift_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
      expect(result.overlapPixels.single, greaterThan(320));
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      await _expectStitchedImageMatchesReportedSize(result);
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'stitches adjacent receipt sections with changed brightness',
    () async {
      final sectionA = addReceiptStitchingWear(
        receiptStitchingSection(seed: 92, topTextOffset: 0),
        seed: 920,
        wrinkleCount: 8,
        smudgeCount: 4,
      );
      final sectionB = addReceiptStitchingWear(
        receiptStitchingSection(seed: 93, topTextOffset: 16),
        seed: 930,
        wrinkleCount: 8,
        smudgeCount: 4,
      );
      copyReceiptStitchingOverlap(
        from: sectionA,
        to: sectionB,
        pixels: 320,
        dstY: 48,
      );
      final shiftedAndBrighterSecond = adjustReceiptStitchingBrightness(
        shiftReceiptStitchingShot(sectionB, dx: 30, dy: 0),
        delta: 42,
      );

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'worn_brightness_a',
      );
      final second = await writeTempReceiptStitchingImage(
        shiftedAndBrighterSecond,
        'worn_brightness_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
      expect(result.pairs.single.overlapPixels, greaterThan(280));
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      await _expectStitchedImageMatchesReportedSize(result);
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'stitches adjacent receipt sections with dimmed continuation',
    () async {
      final sectionA = addReceiptStitchingWear(
        receiptStitchingSection(seed: 94, topTextOffset: 0),
        seed: 940,
        wrinkleCount: 9,
        smudgeCount: 5,
      );
      final sectionB = addReceiptStitchingWear(
        receiptStitchingSection(seed: 95, topTextOffset: 18),
        seed: 950,
        wrinkleCount: 9,
        smudgeCount: 5,
      );
      copyReceiptStitchingOverlap(
        from: sectionA,
        to: sectionB,
        pixels: 318,
        dstY: 54,
      );
      final shiftedAndDimmedSecond = adjustReceiptStitchingBrightness(
        shiftReceiptStitchingShot(sectionB, dx: -28, dy: 0),
        delta: -38,
      );

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'worn_dimmed_a',
      );
      final second = await writeTempReceiptStitchingImage(
        shiftedAndDimmedSecond,
        'worn_dimmed_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
      expect(result.pairs.single.overlapPixels, greaterThan(275));
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      await _expectStitchedImageMatchesReportedSize(result);
    },
    timeout: _stitchingHeavyTimeout,
  );
}

Future<void> _expectStitchedImageMatchesReportedSize(
  ReceiptStitchResult result,
) async {
  final stitchedPath = result.stitchedPath;
  expect(stitchedPath, isNotNull);
  final decoded = img.decodeImage(await File(stitchedPath!).readAsBytes());
  expect(decoded, isNotNull);
  expect(decoded!.width, result.stitchedWidth);
  expect(decoded.height, result.stitchedHeight);
  expect(result.ocrSourcePaths, [stitchedPath]);
}
