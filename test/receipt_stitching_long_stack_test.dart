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

  test(
    'stitches five ordered long-receipt sections with handheld drift',
    () async {
      final files = await _writeFiveSectionStackWithDrift('five_section_drift');

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [for (final file in files) file.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
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

      expect(result.didStitch, isTrue, reason: result.detailLabel);
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
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
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
      final files = await _writePhoneWindowStack('phone_window_tall_receipt');

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [for (final file in files) file.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
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
      final files = await _writeSixPhoneWindowStack(
        'six_phone_window_side_crops',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [for (final file in files) file.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
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
    'keeps skipped phone-window middle section review-required',
    () async {
      final files = await _writeSkippedPhoneWindowStack(
        'skipped_phone_window_middle',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [for (final file in files) file.path],
      );

      expect(
        result.requiresOcrSourceReviewBeforeAssistedRead,
        isTrue,
        reason: result.detailLabel,
      );
      expect(
        result.assistedReadinessCode,
        isNot('stitched_overlap_verified_ready'),
      );
      if (result.didStitch) {
        expect(result.hasLowConfidenceAutomaticOverlap, isTrue);
        expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      } else {
        expect(result.usedFallback, isTrue, reason: result.detailLabel);
        expect(result.fallbackReasonCode, 'overlap_confidence_low');
        expect(result.ocrSourcePaths, [for (final file in files) file.path]);
      }
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

Future<List<File>> _writePhoneWindowStack(String prefix) async {
  final tallReceipt = _tallReceiptCanvas();
  final starts = <int>[0, 1120, 2240, 3360];
  final captures = <img.Image>[];
  for (var index = 0; index < starts.length; index++) {
    final window = img.copyCrop(
      tallReceipt,
      x: 0,
      y: starts[index],
      width: tallReceipt.width,
      height: 1500,
    );
    final shifted = index.isOdd
        ? shiftReceiptStitchingShot(window, dx: 18, dy: 0)
        : index == 2
        ? shiftReceiptStitchingShot(window, dx: -15, dy: 0)
        : window;
    captures.add(shifted);
  }

  final files = <File>[];
  for (var index = 0; index < captures.length; index++) {
    files.add(
      await writeTempReceiptStitchingImage(captures[index], '${prefix}_$index'),
    );
  }
  return files;
}

Future<List<File>> _writeSixPhoneWindowStack(String prefix) async {
  final tallReceipt = _tallReceiptCanvas(sectionCount: 6);
  final starts = <int>[0, 1120, 2240, 3360, 4480, 5600];
  final captures = <img.Image>[];
  for (var index = 0; index < starts.length; index++) {
    final window = img.copyCrop(
      tallReceipt,
      x: 0,
      y: starts[index],
      width: tallReceipt.width,
      height: 1500,
    );
    final cropped = index.isEven
        ? clipReceiptStitchingSide(window, right: 42)
        : clipReceiptStitchingSide(window, left: 36);
    captures.add(
      shiftReceiptStitchingShot(cropped, dx: index.isEven ? 16 : -18, dy: 0),
    );
  }
  final files = <File>[];
  for (var index = 0; index < captures.length; index++) {
    files.add(
      await writeTempReceiptStitchingImage(captures[index], '${prefix}_$index'),
    );
  }
  return files;
}

Future<List<File>> _writeSkippedPhoneWindowStack(String prefix) async {
  final tallReceipt = _tallReceiptCanvas(sectionCount: 5);
  final starts = <int>[0, 1120, 3360, 4480];
  final captures = <img.Image>[];
  for (var index = 0; index < starts.length; index++) {
    final window = img.copyCrop(
      tallReceipt,
      x: 0,
      y: starts[index],
      width: tallReceipt.width,
      height: 1500,
    );
    captures.add(
      shiftReceiptStitchingShot(
        index.isEven
            ? clipReceiptStitchingSide(window, right: 38)
            : clipReceiptStitchingSide(window, left: 34),
        dx: index.isEven ? 14 : -16,
        dy: 0,
      ),
    );
  }
  final files = <File>[];
  for (var index = 0; index < captures.length; index++) {
    files.add(
      await writeTempReceiptStitchingImage(captures[index], '${prefix}_$index'),
    );
  }
  return files;
}

img.Image _tallReceiptCanvas({int sectionCount = 4}) {
  const sectionStride = 1120;
  final height = sectionStride * (sectionCount - 1) + 1500;
  final canvas = img.Image(width: 900, height: height, numChannels: 3);
  img.fill(canvas, color: img.ColorRgb8(248, 248, 244));
  for (var index = 0; index < sectionCount; index++) {
    final section = receiptStitchingSection(
      seed: 260 + index,
      topTextOffset: index * 11,
    );
    img.compositeImage(canvas, section, dstX: 0, dstY: index * sectionStride);
  }
  return addReceiptStitchingWear(canvas, seed: 440, wrinkleCount: 11);
}
