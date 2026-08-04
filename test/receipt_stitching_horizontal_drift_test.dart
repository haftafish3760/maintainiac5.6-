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

      expect(
        result.didStitch,
        isTrue,
        reason: '${result.detailLabel}; ${_pairEvidence(result)}',
      );
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
      printOnFailure(
        '${result.fallbackReasonCode}; '
        '${result.pairs.map((pair) => 'overlap=${pair.overlapPixels} '
            'y=${pair.verticalOffsetPixels} confidence=${pair.confidence}').join(' | ')}',
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
      expect(result.overlapPixels.single, greaterThan(430));
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      await _expectStitchedImageMatchesReportedSize(result);
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'preserves cumulative horizontal drift across three receipt sections',
    () async {
      final sectionA = receiptStitchingSection(seed: 120, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 121, topTextOffset: 18);
      final sectionC = receiptStitchingSection(seed: 122, topTextOffset: 36);
      _drawHorizontalAlignmentMarks(sectionA, seed: 1);
      _drawHorizontalAlignmentMarks(sectionB, seed: 2);
      copyReceiptStitchingOverlap(
        from: sectionA,
        to: sectionB,
        pixels: 340,
        dstX: 108,
      );
      _blankTopOverlapEdge(sectionB, width: 108);
      copyReceiptStitchingOverlap(
        from: sectionB,
        to: sectionC,
        pixels: 340,
        dstX: 108,
      );
      _blankTopOverlapEdge(sectionC, width: 108);

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'cumulative_horizontal_a',
      );
      final second = await writeTempReceiptStitchingImage(
        sectionB,
        'cumulative_horizontal_b',
      );
      final third = await writeTempReceiptStitchingImage(
        sectionC,
        'cumulative_horizontal_c',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path, third.path],
      );
      // ignore: avoid_print
      print('VISUAL DEBUG ${_pairEvidence(result)}');
      expect(
        result.didStitch,
        isTrue,
        reason: '${result.detailLabel}; ${_pairEvidence(result)}',
      );
      expect(result.pairs, hasLength(2));
      expect(result.overlapPixels, hasLength(2));
      expect(
        result.pairs.map((pair) => pair.verticalOffsetPixels),
        everyElement(lessThan(100)),
        reason: 'The copied overlap begins at the top of each continuation.',
      );
      expect(result.stitchedWidth, greaterThan(900));
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      await _expectStitchedImageMatchesReportedSize(result);
    },
    timeout: _stitchingHeavyTimeout,
  );
}

String _pairEvidence(ReceiptStitchResult result) => result.pairs
    .map(
      (pair) =>
          '${pair.summaryLabel}; scale ${pair.scaleCorrection.toStringAsFixed(3)}; perspective ${pair.perspectiveCorrection.toStringAsFixed(3)}; continuity ${pair.continuityCorrelation.toStringAsFixed(3)} (${pair.continuityMatchingBands}/${pair.continuityDetailedBands}); geometry ${pair.geometryCorrelation.toStringAsFixed(3)} (${pair.geometryMatchingCells}/${pair.geometryDetailedCells}); visual ${pair.visualConfidence.toStringAsFixed(3)}',
    )
    .join('; ');

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

void _blankTopOverlapEdge(img.Image image, {required int width}) {
  img.fillRect(
    image,
    x1: 0,
    y1: 0,
    x2: width.clamp(0, image.width - 1),
    y2: 360,
    color: img.ColorRgb8(255, 255, 255),
  );
}

void _drawHorizontalAlignmentMarks(img.Image image, {required int seed}) {
  final startY = image.height - 318;
  for (var index = 0; index < 8; index++) {
    final x = 72 + ((index * 91 + seed * 17) % 680);
    final y = startY + index * 31;
    img.fillRect(
      image,
      x1: x,
      y1: y,
      x2: (x + 28 + index * 3).clamp(0, image.width - 1),
      y2: (y + 18).clamp(0, image.height - 1),
      color: img.ColorRgb8(12, 12, 12),
    );
  }
}
