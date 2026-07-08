import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

const _stitchingHeavyTimeout = Timeout(Duration(minutes: 2));

void main() {
  test(
    'stitches receipt sections with wider handheld horizontal drift',
    () async {
      final sectionA = receiptStitchingSection(seed: 80, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 81, topTextOffset: 18);
      copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 340);
      final shiftedSecond = shiftReceiptStitchingShot(sectionB, dx: 72, dy: 0);

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'wide_shift_a',
      );
      final second = await writeTempReceiptStitchingImage(
        shiftedSecond,
        'wide_shift_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(
        result.pairs.single.confidence,
        greaterThanOrEqualTo(.55),
        reason:
            'Selected horizontal offset must be reflected in confidence scoring.',
      );
      expect(result.overlapPixels.single, greaterThan(120));
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      await _expectStitchedImageMatchesReportedSize(result);
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'stitches receipt sections when ghost delayed overlap starts deep in continuation',
    () async {
      final sectionA = receiptStitchingSection(seed: 82, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 83, topTextOffset: 18);
      copyReceiptStitchingOverlap(
        from: sectionA,
        to: sectionB,
        pixels: 330,
        dstY: 156,
      );

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'deep_delayed_overlap_a',
      );
      final second = await writeTempReceiptStitchingImage(
        sectionB,
        'deep_delayed_overlap_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
      expect(result.overlapPixels.single, greaterThan(430));
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
