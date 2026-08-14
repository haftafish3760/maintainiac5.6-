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

  test(
    'stitches adjacent receipt sections with changed brightness',
    () async {
      final sectionA = addReceiptStitchingWear(
        receiptStitchingSection(seed: 92, topTextOffset: 0),
        seed: 920,
        wrinkleCount: 8,
        smudgeCount: 4,
      );
      final sectionB = addReceiptStitchingWear(
        receiptStitchingSection(seed: 93, topTextOffset: 16),
        seed: 930,
        wrinkleCount: 8,
        smudgeCount: 4,
      );
      copyReceiptStitchingOverlap(
        from: sectionA,
        to: sectionB,
        pixels: 320,
        dstY: 48,
      );
      final shiftedAndBrighterSecond = adjustReceiptStitchingBrightness(
        shiftReceiptStitchingShot(sectionB, dx: 30, dy: 0),
        delta: 42,
      );

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'worn_brightness_a',
      );
      final second = await writeTempReceiptStitchingImage(
        shiftedAndBrighterSecond,
        'worn_brightness_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
      expect(result.pairs.single.overlapPixels, greaterThan(280));
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      await _expectStitchedImageMatchesReportedSize(result);
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'stitches adjacent receipt sections with dimmed continuation',
    () async {
      final sectionA = addReceiptStitchingWear(
        receiptStitchingSection(seed: 94, topTextOffset: 0),
        seed: 940,
        wrinkleCount: 9,
        smudgeCount: 5,
      );
      final sectionB = addReceiptStitchingWear(
        receiptStitchingSection(seed: 95, topTextOffset: 18),
        seed: 950,
        wrinkleCount: 9,
        smudgeCount: 5,
      );
      copyReceiptStitchingOverlap(
        from: sectionA,
        to: sectionB,
        pixels: 318,
        dstY: 54,
      );
      final shiftedAndDimmedSecond = adjustReceiptStitchingBrightness(
        shiftReceiptStitchingShot(sectionB, dx: -28, dy: 0),
        delta: -38,
      );

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'worn_dimmed_a',
      );
      final second = await writeTempReceiptStitchingImage(
        shiftedAndDimmedSecond,
        'worn_dimmed_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
      expect(result.pairs.single.overlapPixels, greaterThan(275));
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      await _expectStitchedImageMatchesReportedSize(result);
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'stitches wrinkled receipt sections with rippled overlap rows',
    () async {
      final sectionA = addReceiptStitchingWear(
        receiptStitchingSection(seed: 126, topTextOffset: 0),
        seed: 1260,
        wrinkleCount: 14,
        smudgeCount: 5,
      );
      final sectionB = addReceiptStitchingWear(
        receiptStitchingSection(seed: 127, topTextOffset: 18),
        seed: 1270,
        wrinkleCount: 13,
        smudgeCount: 5,
      );
      copyReceiptStitchingOverlap(
        from: sectionA,
        to: sectionB,
        pixels: 340,
        dstY: 42,
      );
      final rippledSecond = rippleReceiptStitchingRows(
        shiftReceiptStitchingShot(sectionB, dx: 18, dy: 0),
        amplitude: 9,
        period: 280,
        phase: .6,
      );

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'worn_ripple_a',
      );
      final second = await writeTempReceiptStitchingImage(
        rippledSecond,
        'worn_ripple_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
      expect(result.pairs.single.overlapPixels, greaterThan(280));
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      await _expectStitchedImageMatchesReportedSize(result);
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'stitches or preserves wrinkled receipt with alternating ripples',
    () async {
      final sectionA = addReceiptStitchingWear(
        receiptStitchingSection(seed: 128, topTextOffset: 0),
        seed: 1280,
        wrinkleCount: 13,
        smudgeCount: 5,
      );
      final sectionB = addReceiptStitchingWear(
        receiptStitchingSection(seed: 129, topTextOffset: 16),
        seed: 1290,
        wrinkleCount: 12,
        smudgeCount: 5,
      );
      final sectionC = addReceiptStitchingWear(
        receiptStitchingSection(seed: 130, topTextOffset: 32),
        seed: 1300,
        wrinkleCount: 14,
        smudgeCount: 6,
      );
      copyReceiptStitchingOverlap(
        from: sectionA,
        to: sectionB,
        pixels: 330,
        dstY: 36,
      );
      copyReceiptStitchingOverlap(
        from: sectionB,
        to: sectionC,
        pixels: 350,
        dstY: 52,
      );

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'worn_ripple_stack_a',
      );
      final second = await writeTempReceiptStitchingImage(
        rippleReceiptStitchingRows(
          shiftReceiptStitchingShot(sectionB, dx: 16, dy: 0),
          amplitude: 8,
          period: 260,
          phase: .4,
        ),
        'worn_ripple_stack_b',
      );
      final third = await writeTempReceiptStitchingImage(
        rippleReceiptStitchingRows(
          shiftReceiptStitchingShot(sectionC, dx: -14, dy: 0),
          amplitude: 10,
          period: 310,
          phase: 1.1,
        ),
        'worn_ripple_stack_c',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path, third.path],
      );

      if (result.didStitch) {
        expect(result.pairs, hasLength(2));
        expect(
          result.pairs.every((pair) => pair.confidence >= .50),
          isTrue,
          reason: result.pairDiagnosticsLabel,
        );
        expect(result.overlapPixels, hasLength(2));
        expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
        await _expectStitchedImageMatchesReportedSize(result);
      } else {
        expect(result.usedFallback, isTrue, reason: result.detailLabel);
        expect(result.ocrSourcePaths, [first.path, second.path, third.path]);
        expect(result.hasValidOcrSourceContract, isTrue);
        expect(result.ocrSourceContractCode, 'fallback_ordered_sources_ready');
        expect(result.requiresOcrSourceReviewBeforeAssistedRead, isFalse);
      }
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'stitches worn receipt when continuation overlap has a glare band',
    () async {
      final sectionA = addReceiptStitchingWear(
        receiptStitchingSection(seed: 131, topTextOffset: 0),
        seed: 1310,
        wrinkleCount: 11,
        smudgeCount: 6,
      );
      final sectionB = addReceiptStitchingWear(
        receiptStitchingSection(seed: 132, topTextOffset: 18),
        seed: 1320,
        wrinkleCount: 10,
        smudgeCount: 6,
      );
      copyReceiptStitchingOverlap(
        from: sectionA,
        to: sectionB,
        pixels: 340,
        dstY: 44,
      );
      final glaredSecond = addReceiptStitchingGlareBand(
        shiftReceiptStitchingShot(sectionB, dx: -18, dy: 0),
        y: 76,
        height: 92,
        alpha: 116,
      );

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'worn_glare_overlap_a',
      );
      final second = await writeTempReceiptStitchingImage(
        glaredSecond,
        'worn_glare_overlap_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
      expect(result.overlapPixels.single, greaterThan(280));
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      await _expectStitchedImageMatchesReportedSize(result);
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'crops delayed-overlap top strip before compositing next section',
    () async {
      final sectionA = receiptStitchingSection(seed: 96, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 97, topTextOffset: 18);
      copyReceiptStitchingOverlap(
        from: sectionA,
        to: sectionB,
        pixels: 330,
        dstY: 88,
      );
      _paintFullWidthContaminatedTopStrip(sectionB, height: 70);

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'delayed_overlap_preroll_a',
      );
      final second = await writeTempReceiptStitchingImage(
        sectionB,
        'delayed_overlap_preroll_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');

      final stitched = img.decodeImage(
        await File(result.stitchedPath!).readAsBytes(),
      );
      expect(stitched, isNotNull);
      expect(
        _containsFullWidthDarkContamination(stitched!),
        isFalse,
        reason:
            'Delayed-overlap pre-roll from the next photo must not overwrite the previous section.',
      );
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

void _paintFullWidthContaminatedTopStrip(
  img.Image image, {
  required int height,
}) {
  img.fillRect(
    image,
    x1: 0,
    y1: 0,
    x2: image.width - 1,
    y2: height.clamp(1, image.height - 1),
    color: img.ColorRgb8(4, 4, 4),
  );
}

bool _containsFullWidthDarkContamination(img.Image image) {
  final startY = (image.height * .18).round();
  final endY = (image.height * .82).round();
  var consecutiveDarkRows = 0;
  for (var y = startY; y < endY; y += 4) {
    var darkSamples = 0;
    var samples = 0;
    for (var x = image.width ~/ 20; x < image.width * 19 ~/ 20; x += 8) {
      final pixel = image.getPixel(x, y);
      final luma = (pixel.r + pixel.g + pixel.b) / 3;
      if (luma < 36) darkSamples++;
      samples++;
    }
    if (samples > 0 && darkSamples / samples > .82) {
      consecutiveDarkRows += 4;
      // Receipt rules can be dark and nearly full width. A captured table or
      // background strip persists across many rows, so only that sustained
      // band should fail this stitch regression.
      if (consecutiveDarkRows >= 40) return true;
    } else {
      consecutiveDarkRows = 0;
    }
  }
  return false;
}
