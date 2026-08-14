import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_artifact_expectations.dart';
import 'helpers/receipt_stitching_image_helpers.dart';

const _stitchingHeavyTimeout = Timeout(Duration(minutes: 2));

void main() {
  for (final narrowTop in [true, false]) {
    test(
      'stitches or preserves a receipt pair with ${narrowTop ? 'top' : 'bottom'} camera-angle taper',
      () async {
        final firstSection = receiptStitchingSection(
          seed: narrowTop ? 730 : 731,
          topTextOffset: 0,
        );
        final secondSection = receiptStitchingSection(
          seed: narrowTop ? 732 : 733,
          topTextOffset: 18,
        );
        copyReceiptStitchingOverlap(
          from: firstSection,
          to: secondSection,
          pixels: 380,
        );
        final angledSecond = keystoneReceiptStitchingShot(
          secondSection,
          narrowEdgeWidthFraction: .84,
          narrowTop: narrowTop,
        );
        final first = await writeTempReceiptStitchingImage(
          firstSection,
          'perspective_${narrowTop ? 'top' : 'bottom'}_a',
        );
        final second = await writeTempReceiptStitchingImage(
          angledSecond,
          'perspective_${narrowTop ? 'top' : 'bottom'}_b',
        );

        final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
          paths: [first.path, second.path],
        );

        if (result.didStitch) {
          expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
          if (narrowTop) {
            expect(
              result.pairs.single.perspectiveCorrection.abs(),
              greaterThanOrEqualTo(.03),
            );
          } else {
            // The shared rows are already square at the top of this section.
            // Do not warp a safe join merely because the far edge tapers.
            expect(result.pairs.single.perspectiveCorrection, 0);
          }
          expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
        } else {
          _expectSafeOrderedFallback(result, [first.path, second.path]);
        }
      },
      timeout: _stitchingHeavyTimeout,
    );
  }
}

void _expectSafeOrderedFallback(
  ReceiptStitchResult result,
  List<String> paths,
) {
  expect(result.usedFallback, isTrue, reason: result.detailLabel);
  expect(result.ocrSourcePaths, paths);
  expect(result.hasValidOcrSourceContract, isTrue);
  expect(result.ocrSourceContractCode, 'fallback_ordered_sources_ready');
  expect(result.requiresOcrSourceReviewBeforeAssistedRead, isFalse);
}
