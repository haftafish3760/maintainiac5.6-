import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

const _stitchingHeavyTimeout = Timeout(Duration(minutes: 2));

void main() {
  test(
    'stitches ugly four-section receipt with wrinkles fade and exposure drift',
    () async {
      final sectionA = _uglySection(seed: 142, fade: .20, brightness: 0);
      final sectionB = _uglySection(seed: 143, fade: .26, brightness: 34);
      final sectionC = _uglySection(seed: 144, fade: .18, brightness: -26);
      final sectionD = _uglySection(seed: 145, fade: .30, brightness: 18);
      copyReceiptStitchingOverlap(
        from: sectionA,
        to: sectionB,
        pixels: 340,
        dstX: 24,
        dstY: 54,
      );
      copyReceiptStitchingOverlap(
        from: sectionB,
        to: sectionC,
        pixels: 330,
        dstX: -30,
        dstY: 72,
      );
      copyReceiptStitchingOverlap(
        from: sectionC,
        to: sectionD,
        pixels: 318,
        dstX: 18,
        dstY: 42,
      );

      final files = await _writeSections([
        sectionA,
        shiftReceiptStitchingShot(sectionB, dx: 26, dy: 0),
        shiftReceiptStitchingShot(sectionC, dx: -32, dy: 0),
        shiftReceiptStitchingShot(sectionD, dx: 20, dy: 0),
      ], 'ugly_four');

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: files.map((file) => file.path).toList(growable: false),
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.overlapPixels, hasLength(3));
      expect(result.overlapPixelTotal, greaterThan(850));
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(result.ocrSourcePaths, [result.stitchedPath]);
      expect(result.stitchedPixelCount, lessThan(16000000));
      await _expectReadableStitchedArtifact(result);
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'requires review when ugly long receipt loses the overlap band',
    () async {
      final sectionA = _uglySection(seed: 152, fade: .18, brightness: 0);
      final sectionB = _uglySection(seed: 153, fade: .22, brightness: 24);
      copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 330);
      final clippedSecond = clipReceiptStitchingVerticalEdge(
        sectionB,
        top: 260,
      );

      final files = await _writeSections(
        [sectionA, clippedSecond],
        'ugly_missing_overlap',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: files.map((file) => file.path).toList(growable: false),
      );

      expect(result.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
      expect(result.reviewFocusPairLabel, anyOf('', 'Photo 1 to 2'));
      expect(
        result.assistedReadinessCode,
        anyOf(
          'stitched_overlap_review_required',
          'stitch_contract_review_required',
        ),
      );
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'falls back when long receipt includes a repeated middle window',
    () async {
      final sectionA = _uglySection(seed: 162, fade: .16, brightness: 0);
      final sectionB = _uglySection(seed: 163, fade: .21, brightness: 16);
      final sectionC = _uglySection(seed: 164, fade: .24, brightness: -14);
      copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 330);
      copyReceiptStitchingOverlap(from: sectionB, to: sectionC, pixels: 330);

      final files = await _writeSections(
        [sectionA, sectionB, sectionB, sectionC],
        'ugly_repeated_middle',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: files.map((file) => file.path).toList(growable: false),
      );

      expect(result.usedFallback, isTrue);
      expect(result.didStitch, isFalse);
      expect(result.fallbackReasonCode, 'duplicate_section_image');
      expect(result.ocrSourcePaths, files.map((file) => file.path));
      expect(result.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
    },
    timeout: _stitchingHeavyTimeout,
  );
}

img.Image _uglySection({
  required int seed,
  required double fade,
  required int brightness,
}) {
  final section = receiptStitchingSection(
    seed: seed,
    topTextOffset: (seed % 5) * 9,
  );
  final faded = fadeReceiptStitchingInk(section, amount: fade);
  final worn = addReceiptStitchingWear(
    faded,
    seed: seed * 11,
    wrinkleCount: 14,
    smudgeCount: 8,
  );
  return brightness == 0
      ? worn
      : adjustReceiptStitchingBrightness(worn, delta: brightness);
}

Future<List<File>> _writeSections(List<img.Image> sections, String prefix) {
  return Future.wait([
    for (var index = 0; index < sections.length; index++)
      writeTempReceiptStitchingImage(sections[index], '${prefix}_$index'),
  ]);
}

Future<void> _expectReadableStitchedArtifact(ReceiptStitchResult result) async {
  final stitchedPath = result.stitchedPath;
  expect(stitchedPath, isNotNull);
  final decoded = img.decodeImage(await File(stitchedPath!).readAsBytes());
  expect(decoded, isNotNull);
  expect(decoded!.width, result.stitchedWidth);
  expect(decoded.height, result.stitchedHeight);
  expect(decoded.height, greaterThan(3600));
}
