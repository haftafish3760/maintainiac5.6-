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
