import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';
import 'helpers/receipt_stitching_long_stack_helpers.dart';
import 'helpers/receipt_stitching_result_reason.dart';

const _longStackTimeout = Timeout(Duration(minutes: 3));

void main() {
  test(
    'stitches five ordered long-receipt sections into one OCR source',
    () async {
      final files = await _writeFiveSectionStack('five_section_stack');

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [for (final file in files) file.path],
      );
      expect(
        result.didStitch,
        isTrue,
        reason: receiptStitchingResultReason(result),
      );
      expect(result.pairs, hasLength(4));
      expect(result.overlapPixels, hasLength(4));
      expect(
        result.pairs.map((pair) => pair.confidence),
        everyElement(greaterThanOrEqualTo(.50)),
      );
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(result.ocrSourcePaths, [result.stitchedPath]);
      final unrotatedExpectedHeight = _expectedStitchedHeightForUniformSections(
        sectionWidth: 900,
        sectionHeight: 1500,
        result: result,
      );
      expect(
        result.stitchedHeight,
        closeTo(unrotatedExpectedHeight, unrotatedExpectedHeight * .02),
        reason: receiptStitchingResultReason(result),
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
      expect(pixelCapResult.assistedReadinessCode, 'ordered_sections_ready');

      final heightCapResult =
          await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
            paths: [for (final file in files) file.path],
            maxOutputHeight: 3000,
          );

      expectOutputTooLargeFallback(heightCapResult, files);
      // The conservative preflight can prove the cap immediately, or the
      // running estimate can cross it after one or more verified joins.
      // Either route must preserve any evidence already evaluated.
      expect(heightCapResult.pairs.length, lessThan(files.length));
      expect(
        heightCapResult.pairs.map((pair) => pair.pairIndex),
        orderedEquals(
          List<int>.generate(heightCapResult.pairs.length, (index) => index),
        ),
      );
      expect(heightCapResult.stitchedHeight, greaterThan(3000));
      expect(heightCapResult.assistedReadinessCode, 'ordered_sections_ready');
    },
    timeout: _longStackTimeout,
  );

  test(
    'stitches five ordered long-receipt sections with handheld drift',
    () async {
      final files = await _writeFiveSectionStackWithDrift('five_section_drift');

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [for (final file in files) file.path],
      );
      expect(
        result.didStitch,
        isTrue,
        reason: receiptStitchingResultReason(result),
      );
      expect(result.pairs, hasLength(4));
      expect(result.overlapPixels, hasLength(4));
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(result.ocrSourcePaths, [result.stitchedPath]);
      expect(
        result.pairs.map((pair) => pair.confidence),
        everyElement(greaterThanOrEqualTo(.50)),
      );
      expect(
        result.sourcePreservationCode,
        'original_sections_preserved_derived_stitched_ocr_artifact',
      );
      expect(result.stitchedPixelCount, lessThan(16000000));
    },
    timeout: _longStackTimeout,
  );

  test(
    'stitches four faded worn long-receipt sections with delayed overlap',
    () async {
      final files = await _writeFadedWornSectionStack(
        'four_section_faded_worn',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [for (final file in files) file.path],
      );

      expect(
        result.didStitch,
        isTrue,
        reason: receiptStitchingResultReason(result),
      );
      expect(result.pairs, hasLength(3));
      expect(result.overlapPixels, hasLength(3));
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(result.ocrSourcePaths, [result.stitchedPath]);
      expect(
        result.pairs.map((pair) => pair.confidence),
        everyElement(greaterThanOrEqualTo(.50)),
      );
      expect(result.stitchedPixelCount, lessThan(16000000));
    },
    timeout: _longStackTimeout,
  );

  test(
    'stitches four long-receipt sections with mixed handheld transforms',
    () async {
      final files = await _writeMixedTransformStack('four_section_mixed');

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [for (final file in files) file.path],
        textEvidence: _mixedTransformTextEvidence(files),
      );

      expect(
        result.didStitch,
        isTrue,
        reason: receiptStitchingResultReason(result),
      );
      expect(result.pairs, hasLength(3));
      expect(result.overlapPixels, hasLength(3));
      expect(result.ocrSourcePaths, [result.stitchedPath]);
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(
        result.pairs.map((pair) => pair.confidence),
        everyElement(greaterThanOrEqualTo(.50)),
      );
      expect(
        result.pairs.map((pair) => pair.diagnosticCode),
        everyElement(isNotEmpty),
      );
      expect(result.stitchedPixelCount, lessThan(16000000));
    },
    timeout: _longStackTimeout,
  );

  test(
    'stitches phone-window captures cropped from one tall receipt',
    () async {
      final files = await writePhoneWindowStack('phone_window_tall_receipt');

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [for (final file in files) file.path],
      );

      expect(
        result.didStitch,
        isTrue,
        reason: receiptStitchingResultReason(result),
      );
      expect(result.pairs, hasLength(3));
      expect(result.overlapPixels, hasLength(3));
      expect(
        result.pairs.map((pair) => pair.confidence),
        everyElement(greaterThanOrEqualTo(.50)),
      );
      expect(result.ocrSourcePaths, [result.stitchedPath]);
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(result.stitchedPixelCount, lessThan(16000000));
    },
    timeout: _longStackTimeout,
  );

  test(
    'stitches six phone-window captures with alternating side crops',
    () async {
      final files = await writeSixPhoneWindowStack(
        'six_phone_window_side_crops',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [for (final file in files) file.path],
      );
      expect(
        result.didStitch,
        isTrue,
        reason: receiptStitchingResultReason(result),
      );
      expect(result.pairs, hasLength(5));
      expect(result.overlapPixels, hasLength(5));
      expect(
        result.pairs.map((pair) => pair.confidence),
        everyElement(greaterThanOrEqualTo(.50)),
      );
      expect(result.ocrSourcePaths, [result.stitchedPath]);
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(result.stitchedPixelCount, lessThan(16000000));
    },
    timeout: _longStackTimeout,
  );

  test(
    'stitches six phone-window captures with mixed exposure and side crops',
    () async {
      final files = await writeSixPhoneWindowExposureStack(
        'six_phone_window_exposure_crops',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [for (final file in files) file.path],
      );

      expect(
        result.didStitch,
        isTrue,
        reason: receiptStitchingResultReason(result),
      );
      expect(result.pairs, hasLength(5));
      expect(result.overlapPixels, hasLength(5));
      expect(
        result.pairs.map((pair) => pair.confidence),
        everyElement(greaterThanOrEqualTo(.50)),
      );
      expect(result.ocrSourcePaths, [result.stitchedPath]);
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(result.stitchedPixelCount, lessThan(16000000));
    },
    timeout: _longStackTimeout,
  );
}

int _expectedStitchedHeightForUniformSections({
  required int sectionWidth,
  required int sectionHeight,
  required ReceiptStitchResult result,
}) {
  final firstHeight = (sectionHeight * result.stitchedWidth / sectionWidth)
      .round();
  var expectedHeight = firstHeight;
  for (var index = 0; index < result.pairs.length; index++) {
    final pair = result.pairs[index];
    final transformedWidth = (result.stitchedWidth * pair.scaleCorrection)
        .round()
        .clamp(320, 3200);
    final transformedHeight = (sectionHeight * transformedWidth / sectionWidth)
        .round();
    expectedHeight += transformedHeight - result.overlapPixels[index];
  }
  return expectedHeight;
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
  expect(result.ocrSourceContractCode, 'fallback_ordered_sources_ready');
  expect(result.requiresOcrSourceReviewBeforeAssistedRead, isFalse);
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

Future<List<File>> _writeFiveSectionStackWithDrift(String prefix) async {
  final sections = [
    for (var index = 0; index < 5; index++)
      receiptStitchingSection(seed: 140 + index, topTextOffset: index * 12),
  ];
  for (var index = 1; index < sections.length; index++) {
    copyReceiptStitchingOverlap(
      from: sections[index - 1],
      to: sections[index],
      pixels: 340,
      dstY: index.isEven ? 18 : 0,
    );
  }
  final drifted = [
    sections[0],
    shiftReceiptStitchingShot(sections[1], dx: 24, dy: 0),
    shiftReceiptStitchingShot(sections[2], dx: -18, dy: 0),
    shiftReceiptStitchingShot(sections[3], dx: 30, dy: 0),
    shiftReceiptStitchingShot(sections[4], dx: -24, dy: 0),
  ];
  final files = <File>[];
  for (var index = 0; index < drifted.length; index++) {
    files.add(
      await writeTempReceiptStitchingImage(drifted[index], '${prefix}_$index'),
    );
  }
  return files;
}

Future<List<File>> _writeFadedWornSectionStack(String prefix) async {
  final sections = [
    for (var index = 0; index < 4; index++)
      fadeReceiptStitchingInk(
        addReceiptStitchingWear(
          receiptStitchingSection(seed: 180 + index, topTextOffset: index * 16),
          seed: 310 + index,
          wrinkleCount: 7,
          smudgeCount: 4,
        ),
        amount: .42 + (index * .03),
      ),
  ];
  for (var index = 1; index < sections.length; index++) {
    copyReceiptStitchingOverlap(
      from: sections[index - 1],
      to: sections[index],
      pixels: 330,
      dstY: index.isEven ? 42 : 24,
    );
  }
  final drifted = [
    sections[0],
    shiftReceiptStitchingShot(sections[1], dx: 18, dy: 0),
    shiftReceiptStitchingShot(sections[2], dx: -15, dy: 0),
    shiftReceiptStitchingShot(sections[3], dx: 21, dy: 0),
  ];
  final files = <File>[];
  for (var index = 0; index < drifted.length; index++) {
    files.add(
      await writeTempReceiptStitchingImage(drifted[index], '${prefix}_$index'),
    );
  }
  return files;
}

Future<List<File>> _writeMixedTransformStack(String prefix) async {
  final sections = [
    for (var index = 0; index < 4; index++)
      receiptStitchingSection(seed: 220 + index, topTextOffset: index * 18),
  ];
  for (var index = 1; index < sections.length; index++) {
    copyReceiptStitchingOverlap(
      from: sections[index - 1],
      to: sections[index],
      pixels: 340 + (index * 8),
      dstY: index.isEven ? 30 : 12,
    );
  }
  final transformed = [
    sections[0],
    shiftReceiptStitchingShot(
      scaleReceiptStitchingShot(sections[1], scale: 1.06),
      dx: 18,
      dy: 0,
    ),
    rotateReceiptStitchingShot(
      shiftReceiptStitchingShot(sections[2], dx: -16, dy: 0),
      degrees: .8,
    ),
    shiftReceiptStitchingShot(
      scaleReceiptStitchingShot(sections[3], scale: .94),
      dx: 21,
      dy: 0,
    ),
  ];
  final files = <File>[];
  for (var index = 0; index < transformed.length; index++) {
    files.add(
      await writeTempReceiptStitchingImage(
        transformed[index],
        '${prefix}_$index',
      ),
    );
  }
  return files;
}

List<ReceiptStitchTextEvidence> _mixedTransformTextEvidence(List<File> files) {
  const lines = [
    ['ITEM A 1.00', 'ITEM B 2.00', 'ITEM C 3.00', 'ITEM D 4.00'],
    ['ITEM C 3.00', 'ITEM D 4.00', 'ITEM E 5.00', 'ITEM F 6.00'],
    ['ITEM E 5.00', 'ITEM F 6.00', 'ITEM G 7.00', 'ITEM H 8.00'],
    ['ITEM G 7.00', 'ITEM H 8.00', 'ITEM I 9.00', 'TOTAL 45.00'],
  ];
  const baseCenters = [.07, .15, .82, .90];
  const scales = [1.0, 1.06, 1.0, .94];
  const angles = [0.0, 0.0, .8, 0.0];
  return [
    for (var index = 0; index < files.length; index++)
      ReceiptStitchTextEvidence(
        path: files[index].path,
        lines: lines[index],
        positionedLines: [
          for (var lineIndex = 0; lineIndex < lines[index].length; lineIndex++)
            ReceiptStitchTextLineEvidence(
              text: lines[index][lineIndex],
              left: .12,
              top: (baseCenters[lineIndex] * scales[index] - .018).clamp(
                0.0,
                1.0,
              ),
              right: (.88 * scales[index]).clamp(0.0, 1.0),
              bottom: (baseCenters[lineIndex] * scales[index] + .018).clamp(
                0.0,
                1.0,
              ),
              angleDegrees: angles[index],
            ),
        ],
      ),
  ];
}
