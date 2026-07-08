import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

const _longStackTimeout = Timeout(Duration(minutes: 3));

void main() {
  test(
    'stitches five ordered long-receipt sections into one OCR source',
    () async {
      final files = await _writeFiveSectionStack('five_section_stack');

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [for (final file in files) file.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs, hasLength(4));
      expect(result.overlapPixels, hasLength(4));
      expect(
        result.pairs.map((pair) => pair.confidence),
        everyElement(greaterThanOrEqualTo(.50)),
      );
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(result.ocrSourcePaths, [result.stitchedPath]);
      final normalizedSectionHeight = (1500 * result.stitchedWidth / 900)
          .round();
      expect(
        result.stitchedHeight,
        normalizedSectionHeight * files.length - result.overlapPixelTotal,
      );

      final decoded = img.decodeImage(
        await File(result.stitchedPath!).readAsBytes(),
      );
      expect(decoded, isNotNull);
      expect(decoded!.width, result.stitchedWidth);
      expect(decoded.height, result.stitchedHeight);
      expect(result.stitchedPixelCount, lessThan(16000000));
    },
    timeout: _longStackTimeout,
  );

  test(
    'falls back before writing a five-section stitch over the pixel cap',
    () async {
      final files = await _writeFiveSectionStack('five_section_cap');

      final pixelCapResult =
          await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
            paths: [for (final file in files) file.path],
            maxOutputPixels: 900000,
          );

      expectOutputTooLargeFallback(pixelCapResult, files);
      expect(pixelCapResult.pairs, isEmpty);
      expect(pixelCapResult.stitchedPixelCount, greaterThan(900000));
      expect(
        pixelCapResult.sourcePreservationCode,
        'original_sections_preserved_ordered_ocr_sources',
      );
      expect(
        pixelCapResult.assistedReadinessCode,
        'stitch_contract_review_required',
      );

      final heightCapResult =
          await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
            paths: [for (final file in files) file.path],
            maxOutputHeight: 3000,
          );

      expectOutputTooLargeFallback(heightCapResult, files);
      expect(heightCapResult.pairs, isEmpty);
      expect(heightCapResult.stitchedHeight, greaterThan(3000));
      expect(
        heightCapResult.assistedReadinessCode,
        'stitch_contract_review_required',
      );
    },
    timeout: _longStackTimeout,
  );
}

void expectOutputTooLargeFallback(
  ReceiptStitchResult result,
  List<File> files,
) {
  expect(result.usedFallback, isTrue, reason: result.detailLabel);
  expect(result.didStitch, isFalse);
  expect(result.fallbackReasonCode, 'output_too_large');
  expect(result.stitchedPath, isNull);
  expect(result.ocrSourcePaths, [for (final file in files) file.path]);
  expect(result.ocrSourceContractCode, 'fallback_derived_stitch_too_large');
  expect(result.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
}

Future<List<File>> _writeFiveSectionStack(String prefix) async {
  final sections = [
    for (var index = 0; index < 5; index++)
      receiptStitchingSection(seed: 100 + index, topTextOffset: index * 14),
  ];
  for (var index = 1; index < sections.length; index++) {
    copyReceiptStitchingOverlap(
      from: sections[index - 1],
      to: sections[index],
      pixels: 335,
      dstY: index.isEven ? 24 : 0,
    );
  }
  final files = <File>[];
  for (var index = 0; index < sections.length; index++) {
    files.add(
      await writeTempReceiptStitchingImage(sections[index], '${prefix}_$index'),
    );
  }
  return files;
}
