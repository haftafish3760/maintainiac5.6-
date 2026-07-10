import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

const _stainedOverlapTimeout = Timeout(Duration(minutes: 2));

void main() {
  test(
    'stitches continuation with a moderate overlap stain',
    () async {
      final top = receiptStitchingSection(seed: 730, topTextOffset: 0);
      final continuation = receiptStitchingSection(
        seed: 731,
        topTextOffset: 18,
      );
      copyReceiptStitchingOverlap(from: top, to: continuation, pixels: 380);
      img.fillCircle(
        continuation,
        x: 185,
        y: 205,
        radius: 92,
        color: img.ColorRgba8(118, 86, 54, 72),
      );
      final topFile = await writeTempReceiptStitchingImage(
        top,
        'moderate_stain_top',
      );
      final continuationFile = await writeTempReceiptStitchingImage(
        continuation,
        'moderate_stain_continuation',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [topFile.path, continuationFile.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
      expect(result.ocrSourcePaths, [result.stitchedPath]);
    },
    timeout: _stainedOverlapTimeout,
  );

  test(
    'severe overlap staining cannot bypass OCR source review',
    () async {
      final top = receiptStitchingSection(seed: 740, topTextOffset: 0);
      final continuation = receiptStitchingSection(
        seed: 741,
        topTextOffset: 18,
      );
      copyReceiptStitchingOverlap(from: top, to: continuation, pixels: 380);
      for (var x = 90; x < continuation.width; x += 150) {
        img.fillCircle(
          continuation,
          x: x,
          y: 205 + ((x ~/ 150).isEven ? 34 : -26),
          radius: 118,
          color: img.ColorRgba8(92, 68, 48, 210),
        );
      }
      final topFile = await writeTempReceiptStitchingImage(
        top,
        'severe_stain_top',
      );
      final continuationFile = await writeTempReceiptStitchingImage(
        continuation,
        'severe_stain_continuation',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [topFile.path, continuationFile.path],
      );

      expect(result.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
      if (result.didStitch) {
        expect(result.hasLowConfidenceAutomaticOverlap, isTrue);
        expect(
          result.assistedReadinessCode,
          'stitched_overlap_review_required',
        );
      } else {
        expect(result.usedFallback, isTrue, reason: result.detailLabel);
        expect(result.ocrSourcePaths, [topFile.path, continuationFile.path]);
        expect(result.assistedReadinessCode, 'stitch_contract_review_required');
      }
    },
    timeout: _stainedOverlapTimeout,
  );
}
