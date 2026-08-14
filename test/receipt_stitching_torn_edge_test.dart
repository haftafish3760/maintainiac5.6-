import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

const _tornEdgeTimeout = Timeout(Duration(minutes: 2));

void main() {
  test(
    'stitches continuation with a moderate torn overlap edge',
    () async {
      final top = receiptStitchingSection(seed: 710, topTextOffset: 0);
      final continuation = receiptStitchingSection(
        seed: 711,
        topTextOffset: 18,
      );
      copyReceiptStitchingOverlap(from: top, to: continuation, pixels: 380);
      _eraseTornLeftEdge(continuation, overlapHeight: 380, maximumDepth: 120);
      final topFile = await writeTempReceiptStitchingImage(
        top,
        'moderate_torn_edge_top',
      );
      final continuationFile = await writeTempReceiptStitchingImage(
        continuation,
        'moderate_torn_edge_continuation',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [topFile.path, continuationFile.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
      expect(result.ocrSourcePaths, [result.stitchedPath]);
      expect(
        result.sourcePreservationCode,
        'original_sections_preserved_derived_stitched_ocr_artifact',
      );
    },
    timeout: _tornEdgeTimeout,
  );

  test(
    'severe torn overlap edge cannot bypass OCR source review',
    () async {
      final top = receiptStitchingSection(seed: 720, topTextOffset: 0);
      final continuation = receiptStitchingSection(
        seed: 721,
        topTextOffset: 18,
      );
      copyReceiptStitchingOverlap(from: top, to: continuation, pixels: 380);
      _eraseTornLeftEdge(continuation, overlapHeight: 380, maximumDepth: 690);
      final topFile = await writeTempReceiptStitchingImage(
        top,
        'severe_torn_edge_top',
      );
      final continuationFile = await writeTempReceiptStitchingImage(
        continuation,
        'severe_torn_edge_continuation',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [topFile.path, continuationFile.path],
      );

      if (result.didStitch) {
        expect(result.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
        expect(result.hasLowConfidenceAutomaticOverlap, isTrue);
        expect(
          result.assistedReadinessCode,
          'stitched_overlap_review_required',
        );
      } else {
        expect(result.usedFallback, isTrue, reason: result.detailLabel);
        expect(result.ocrSourcePaths, [topFile.path, continuationFile.path]);
        expect(result.requiresOcrSourceReviewBeforeAssistedRead, isFalse);
        expect(result.assistedReadinessCode, 'ordered_sections_ready');
      }
    },
    timeout: _tornEdgeTimeout,
  );
}

void _eraseTornLeftEdge(
  img.Image image, {
  required int overlapHeight,
  required int maximumDepth,
}) {
  const bandHeight = 12;
  final half = overlapHeight / 2;
  for (var y = 0; y < overlapHeight; y += bandHeight) {
    final distanceFromCenter = (y - half).abs();
    final depthScale = 1 - (distanceFromCenter / half).clamp(0.0, 1.0);
    final jitter = ((y ~/ bandHeight) % 3) * 9;
    final depth = (maximumDepth * depthScale).round() + jitter;
    img.fillRect(
      image,
      x1: 0,
      y1: y,
      x2: depth.clamp(0, image.width - 1),
      y2: (y + bandHeight - 1).clamp(0, image.height - 1),
      color: img.ColorRgb8(248, 248, 244),
    );
  }
}
