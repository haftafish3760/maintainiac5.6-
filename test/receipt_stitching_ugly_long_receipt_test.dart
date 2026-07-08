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

      final files = await _writeSections([
        sectionA,
        clippedSecond,
      ], 'ugly_missing_overlap');

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

      final files = await _writeSections([
        sectionA,
        sectionB,
        sectionB,
        sectionC,
      ], 'ugly_repeated_middle');

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

  test(
    'stitches folded faded phone-window long receipt sections',
    () async {
      final tallReceipt = _addFoldShadows(
        fadeReceiptStitchingInk(
          tallReceiptStitchingCanvas(sectionCount: 5),
          amount: .24,
        ),
      );
      final starts = <int>[0, 1040, 2080, 3120, 4160];
      final files = <File>[];
      for (var index = 0; index < starts.length; index++) {
        final window = cropReceiptStitchingPhoneWindow(
          tallReceipt,
          y: starts[index],
          height: 1500,
        );
        final adjusted = index.isEven
            ? adjustReceiptStitchingBrightness(window, delta: -18)
            : adjustReceiptStitchingBrightness(window, delta: 22);
        files.add(
          await writeTempReceiptStitchingImage(
            shiftReceiptStitchingShot(
              adjusted,
              dx: index.isEven ? 18 : -22,
              dy: 0,
            ),
            'folded_faded_window_$index',
          ),
        );
      }

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: files.map((file) => file.path).toList(growable: false),
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.overlapPixels, hasLength(4));
      expect(result.overlapPixelTotal, greaterThan(1500));
      expect(result.ocrSourcePaths, [result.stitchedPath]);
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(result.stitchedPixelCount, lessThan(16000000));
      await _expectReadableStitchedArtifact(result);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'stitches narrow wrinkled receipt windows with small repeated overlap',
    () async {
      final tallReceipt = addReceiptStitchingWear(
        fadeReceiptStitchingInk(
          tallReceiptStitchingCanvas(sectionCount: 5),
          amount: .18,
        ),
        seed: 881,
        wrinkleCount: 16,
        smudgeCount: 9,
      );
      final starts = <int>[0, 1220, 2440, 3660, 4880];
      final files = <File>[];
      for (var index = 0; index < starts.length; index++) {
        var window = cropReceiptStitchingPhoneWindow(
          tallReceipt,
          y: starts[index],
          height: 1500,
        );
        window = _narrowPhoneCapture(
          window,
          leftMargin: index.isEven ? 92 : 118,
          rightMargin: index.isEven ? 108 : 84,
        );
        window = shiftReceiptStitchingShot(
          window,
          dx: index.isEven ? 20 : -24,
          dy: 0,
        );
        if (index == 1 || index == 4) {
          window = adjustReceiptStitchingBrightness(window, delta: 20);
        }
        if (index == 2) {
          window = fadeReceiptStitchingInk(window, amount: .10);
        }
        if (index == 3) {
          window = adjustReceiptStitchingBrightness(window, delta: -22);
        }
        files.add(
          await writeTempReceiptStitchingImage(
            window,
            'narrow_wrinkled_low_overlap_$index',
          ),
        );
      }

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: files.map((file) => file.path).toList(growable: false),
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs, hasLength(4));
      expect(result.overlapPixels, hasLength(4));
      expect(result.overlapPixelTotal, greaterThan(800));
      expect(
        result.pairs.map((pair) => pair.confidence),
        everyElement(greaterThanOrEqualTo(.50)),
      );
      expect(result.ocrSourcePaths, [result.stitchedPath]);
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(result.stitchedPixelCount, lessThan(16000000));
      await _expectReadableStitchedArtifact(result);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'stitches dark-framed receipt photos without treating the phone surface as receipt',
    () async {
      final sectionA = _uglySection(seed: 172, fade: .16, brightness: 0);
      final sectionB = _uglySection(seed: 173, fade: .24, brightness: 18);
      copyReceiptStitchingOverlap(
        from: sectionA,
        to: sectionB,
        pixels: 336,
        dstX: 18,
        dstY: 42,
      );

      final first = await writeTempReceiptStitchingImage(
        frameReceiptStitchingShotOnDarkSurface(
          sectionA,
          left: 86,
          top: 52,
          right: 104,
          bottom: 78,
        ),
        'dark_surface_two_a',
      );
      final second = await writeTempReceiptStitchingImage(
        frameReceiptStitchingShotOnDarkSurface(
          shiftReceiptStitchingShot(sectionB, dx: 18, dy: 0),
          left: 64,
          top: 68,
          right: 118,
          bottom: 70,
        ),
        'dark_surface_two_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
      expect(result.overlapPixels.single, greaterThan(260));
      expect(result.ocrSourcePaths, [result.stitchedPath]);
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(result.stitchedWidth, lessThan(1700));
      await _expectReadableStitchedArtifact(result, minHeight: 3000);
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'stitches three dark-framed long receipt photos with alternating drift',
    () async {
      final sectionA = _uglySection(seed: 182, fade: .18, brightness: -8);
      final sectionB = _uglySection(seed: 183, fade: .22, brightness: 24);
      final sectionC = _uglySection(seed: 184, fade: .20, brightness: -18);
      copyReceiptStitchingOverlap(
        from: sectionA,
        to: sectionB,
        pixels: 320,
        dstX: 24,
        dstY: 54,
      );
      copyReceiptStitchingOverlap(
        from: sectionB,
        to: sectionC,
        pixels: 312,
        dstX: -26,
        dstY: 48,
      );

      final files = await _writeSections([
        frameReceiptStitchingShotOnDarkSurface(
          shiftReceiptStitchingShot(sectionA, dx: 14, dy: 0),
          left: 92,
          top: 48,
          right: 74,
          bottom: 72,
        ),
        frameReceiptStitchingShotOnDarkSurface(
          shiftReceiptStitchingShot(sectionB, dx: -22, dy: 0),
          left: 70,
          top: 64,
          right: 112,
          bottom: 84,
        ),
        frameReceiptStitchingShotOnDarkSurface(
          shiftReceiptStitchingShot(sectionC, dx: 20, dy: 0),
          left: 110,
          top: 56,
          right: 82,
          bottom: 76,
        ),
      ], 'dark_surface_three');

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: files.map((file) => file.path).toList(growable: false),
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs, hasLength(2));
      expect(result.overlapPixels, hasLength(2));
      expect(result.overlapPixelTotal, greaterThan(540));
      expect(result.ocrSourcePaths, [result.stitchedPath]);
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(result.stitchedPixelCount, lessThan(16000000));
      await _expectReadableStitchedArtifact(result);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'stitches dark-framed receipt photos with scale and rotation drift',
    () async {
      final sectionA = _uglySection(seed: 192, fade: .18, brightness: -6);
      final sectionB = _uglySection(seed: 193, fade: .24, brightness: 20);
      final sectionC = _uglySection(seed: 194, fade: .20, brightness: -16);
      copyReceiptStitchingOverlap(
        from: sectionA,
        to: sectionB,
        pixels: 330,
        dstX: 20,
        dstY: 48,
      );
      copyReceiptStitchingOverlap(
        from: sectionB,
        to: sectionC,
        pixels: 318,
        dstX: -18,
        dstY: 54,
      );

      final files = await _writeSections([
        frameReceiptStitchingShotOnDarkSurface(sectionA, left: 84, right: 94),
        frameReceiptStitchingShotOnDarkSurface(
          rotateReceiptStitchingShot(
            scaleReceiptStitchingShot(sectionB, scale: 1.04),
            degrees: .7,
          ),
          left: 70,
          top: 62,
          right: 112,
          bottom: 80,
        ),
        frameReceiptStitchingShotOnDarkSurface(
          rotateReceiptStitchingShot(
            scaleReceiptStitchingShot(sectionC, scale: .96),
            degrees: -.7,
          ),
          left: 104,
          top: 58,
          right: 78,
          bottom: 72,
        ),
      ], 'dark_surface_scale_rotation');

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: files.map((file) => file.path).toList(growable: false),
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs, hasLength(2));
      expect(result.overlapPixelTotal, greaterThan(520));
      expect(result.confidence, greaterThanOrEqualTo(.50));
      expect(result.ocrSourcePaths, [result.stitchedPath]);
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(result.stitchedPixelCount, lessThan(16000000));
      await _expectReadableStitchedArtifact(result);
    },
    timeout: const Timeout(Duration(minutes: 3)),
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

Future<void> _expectReadableStitchedArtifact(
  ReceiptStitchResult result, {
  int minHeight = 3600,
}) async {
  final stitchedPath = result.stitchedPath;
  expect(stitchedPath, isNotNull);
  final decoded = img.decodeImage(await File(stitchedPath!).readAsBytes());
  expect(decoded, isNotNull);
  expect(decoded!.width, result.stitchedWidth);
  expect(decoded.height, result.stitchedHeight);
  expect(decoded.height, greaterThan(minHeight));
}

img.Image _addFoldShadows(img.Image source) {
  final folded = img.copyResize(source, width: source.width);
  for (var y = 160; y < folded.height - 120; y += 420) {
    img.drawLine(
      folded,
      x1: 38,
      y1: y,
      x2: folded.width - 42,
      y2: y + 76,
      color: img.ColorRgb8(198, 198, 194),
      thickness: 5,
    );
    img.drawLine(
      folded,
      x1: 70,
      y1: y + 14,
      x2: folded.width - 76,
      y2: y + 88,
      color: img.ColorRgb8(232, 232, 228),
      thickness: 3,
    );
  }
  return folded;
}

img.Image _narrowPhoneCapture(
  img.Image source, {
  required int leftMargin,
  required int rightMargin,
}) {
  final canvas = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 3,
  );
  img.fill(canvas, color: img.ColorRgb8(238, 238, 234));
  final cropped = img.copyCrop(
    source,
    x: leftMargin,
    y: 0,
    width: source.width - leftMargin - rightMargin,
    height: source.height,
  );
  img.compositeImage(canvas, cropped, dstX: leftMargin, dstY: 0);
  return canvas;
}
