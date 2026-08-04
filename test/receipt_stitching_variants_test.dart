import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_artifact_expectations.dart';
import 'helpers/receipt_stitching_image_helpers.dart';
import 'helpers/receipt_stitching_result_reason.dart';

const _stitchingHeavyTimeout = Timeout(Duration(minutes: 2));

void main() {
  test(
    'stitches receipt sections when overlap starts below the next photo top',
    () async {
      final sectionA = receiptStitchingSection(seed: 67, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 68, topTextOffset: 18);
      copyReceiptStitchingOverlap(
        from: sectionA,
        to: sectionB,
        pixels: 340,
        dstY: 48,
      );

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'delayed_overlap_a',
      );
      final second = await writeTempReceiptStitchingImage(
        sectionB,
        'delayed_overlap_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
      expect(
        result.pairs.single.rotationCorrectionDegrees,
        0,
        reason: receiptStitchingResultReason(result),
      );
      expect(result.overlapPixels.single, greaterThan(340));
      expect(
        result.overlapPixels.single,
        result.pairs.single.overlapPixels +
            result.pairs.single.verticalOffsetPixels,
      );
      expect(
        result.stitchedHeight,
        expectedStitchedHeightForUniformSections(
          sectionWidth: sectionA.width,
          sectionHeight: sectionA.height,
          result: result,
        ),
      );
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');

      final boundedResult =
          await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
            paths: [first.path, second.path],
            maxOutputPixels: result.stitchedPixelCount + 500,
          );

      expect(
        boundedResult.didStitch,
        isTrue,
        reason: boundedResult.detailLabel,
      );
      expect(boundedResult.ocrSourceContractCode, 'stitched_ocr_source_ready');

      final boundedFallback =
          await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
            paths: [first.path, second.path],
            maxOutputPixels: result.stitchedPixelCount - 500,
          );

      expect(boundedFallback.usedFallback, isTrue);
      expect(boundedFallback.fallbackReasonCode, 'output_too_large');
      expect(boundedFallback.stitchedPath, isNull);
      expect(boundedFallback.ocrSourcePaths, [first.path, second.path]);
      expect(
        boundedFallback.ocrSourceContractCode,
        'fallback_derived_stitch_too_large',
      );
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'stitches three receipt sections with delayed overlap in each continuation',
    () async {
      final sectionA = receiptStitchingSection(seed: 69, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 70, topTextOffset: 12);
      final sectionC = receiptStitchingSection(seed: 71, topTextOffset: 24);
      copyReceiptStitchingOverlap(
        from: sectionA,
        to: sectionB,
        pixels: 320,
        dstY: 36,
      );
      copyReceiptStitchingOverlap(
        from: sectionB,
        to: sectionC,
        pixels: 360,
        dstY: 60,
      );

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'delayed_overlap_stack_a',
      );
      final second = await writeTempReceiptStitchingImage(
        sectionB,
        'delayed_overlap_stack_b',
      );
      final third = await writeTempReceiptStitchingImage(
        sectionC,
        'delayed_overlap_stack_c',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path, third.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs, hasLength(2));
      expect(result.overlapPixels, hasLength(2));
      expect(result.overlapPixels.first, greaterThan(320));
      expect(result.overlapPixels.last, greaterThan(360));
      expect(
        result.stitchedHeight,
        expectedStitchedHeightForUniformSections(
          sectionWidth: sectionA.width,
          sectionHeight: sectionA.height,
          result: result,
        ),
      );
      expect(result.ocrSourcePaths, [result.stitchedPath]);
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'stitches receipt sections with delayed overlap and handheld drift',
    () async {
      final sectionA = receiptStitchingSection(seed: 72, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 73, topTextOffset: 30);
      copyReceiptStitchingOverlap(
        from: sectionA,
        to: sectionB,
        pixels: 330,
        dstY: 48,
      );
      final shiftedSecond = shiftReceiptStitchingShot(sectionB, dx: 24, dy: 0);

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'delayed_drift_overlap_a',
      );
      final second = await writeTempReceiptStitchingImage(
        shiftedSecond,
        'delayed_drift_overlap_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(
        result.didStitch,
        isTrue,
        reason: receiptStitchingResultReason(result),
      );
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
      expect(result.overlapPixels.single, greaterThan(330));
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'stitches faded thermal receipt sections with delayed overlap',
    () async {
      final sectionA = fadeReceiptStitchingInk(
        receiptStitchingSection(seed: 72, topTextOffset: 0),
        amount: .58,
      );
      final sectionB = fadeReceiptStitchingInk(
        receiptStitchingSection(seed: 73, topTextOffset: 18),
        amount: .54,
      );
      copyReceiptStitchingOverlap(
        from: sectionA,
        to: sectionB,
        pixels: 330,
        dstY: 36,
      );

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'faded_delayed_overlap_a',
      );
      final second = await writeTempReceiptStitchingImage(
        sectionB,
        'faded_delayed_overlap_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
      expect(result.overlapPixels.single, greaterThan(330));
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'stitches receipt sections with only a few repeated guide lines',
    () async {
      final sectionA = addReceiptStitchingWear(
        receiptStitchingSection(seed: 81, topTextOffset: 0),
        seed: 810,
        wrinkleCount: 7,
        smudgeCount: 4,
      );
      final sectionB = addReceiptStitchingWear(
        receiptStitchingSection(seed: 82, topTextOffset: 18),
        seed: 820,
        wrinkleCount: 8,
        smudgeCount: 4,
      );
      copyReceiptStitchingOverlap(
        from: sectionA,
        to: sectionB,
        pixels: 210,
        dstY: 24,
      );
      final shiftedSecond = shiftReceiptStitchingShot(
        adjustReceiptStitchingBrightness(sectionB, delta: 16),
        dx: -18,
        dy: 0,
      );

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'few_repeated_lines_a',
      );
      final second = await writeTempReceiptStitchingImage(
        shiftedSecond,
        'few_repeated_lines_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(
        result.didStitch,
        isTrue,
        reason: receiptStitchingResultReason(result),
      );
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
      expect(result.overlapPixels.single, greaterThanOrEqualTo(190));
      expect(result.ocrSourcePaths, [result.stitchedPath]);
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'keeps severe horizontal drift in weak-overlap review lane',
    () async {
      final sectionA = receiptStitchingSection(seed: 66, topTextOffset: 0);
      final shiftedSecond = shiftReceiptStitchingShot(
        blankDarkReceiptPhotoSection(),
        dx: 520,
        dy: 0,
      );

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'shift_bad_a',
      );
      final second = await writeTempReceiptStitchingImage(
        shiftedSecond,
        'shift_bad_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(result.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
      expect(result.reviewFocusPairLabel, 'Photo 1 to 2');
      expect(
        result.privacySafeOcrHandoffSafety,
        containsPair('stitchReviewFocusPairLabel', 'Photo 1 to 2'),
      );
      if (result.didStitch) {
        expect(result.pairs.single.confidence, inInclusiveRange(.50, .69));
        expect(result.hasLowConfidenceAutomaticOverlap, isTrue);
        expect(
          result.assistedReadinessCode,
          'stitched_overlap_review_required',
        );
      } else {
        expect(result.usedFallback, isTrue, reason: result.detailLabel);
        expect(result.fallbackReasonCode, 'overlap_confidence_low');
        expect(
          result.ocrSourceContractCode,
          'fallback_overlap_untrusted_sources',
        );
      }
    },
    timeout: _stitchingHeavyTimeout,
  );

  test('stitches receipt sections with mild wrinkles and smudges', () async {
    final sectionA = addReceiptStitchingWear(
      receiptStitchingSection(seed: 62, topTextOffset: 0),
      seed: 620,
    );
    final sectionB = addReceiptStitchingWear(
      receiptStitchingSection(seed: 63, topTextOffset: 18),
      seed: 630,
    );
    copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 340);

    final first = await writeTempReceiptStitchingImage(sectionA, 'worn_a');
    final second = await writeTempReceiptStitchingImage(sectionB, 'worn_b');

    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: [first.path, second.path],
    );

    expect(result.didStitch, isTrue, reason: result.detailLabel);
    expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
    expect(result.overlapPixels.single, greaterThan(120));
    expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
  });

  test('stitches receipt sections when continuation edge is clipped', () async {
    final sectionA = receiptStitchingSection(seed: 76, topTextOffset: 0);
    final sectionB = receiptStitchingSection(seed: 77, topTextOffset: 18);
    copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 330);
    final clippedSecond = clipReceiptStitchingSide(
      sectionB,
      left: 72,
      right: 36,
    );

    final first = await writeTempReceiptStitchingImage(
      sectionA,
      'clipped_overlap_a',
    );
    final second = await writeTempReceiptStitchingImage(
      clippedSecond,
      'clipped_overlap_b',
    );

    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: [first.path, second.path],
    );

    expect(result.didStitch, isTrue, reason: result.detailLabel);
    expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
    expect(result.overlapPixels.single, greaterThan(120));
    expect(result.hasValidOcrSourceContract, isTrue);
  });

  test(
    'stitches faded receipt sections when continuation edge is clipped',
    () async {
      final sectionA = fadeReceiptStitchingInk(
        receiptStitchingSection(seed: 78, topTextOffset: 0),
        amount: .52,
      );
      final sectionB = fadeReceiptStitchingInk(
        receiptStitchingSection(seed: 79, topTextOffset: 18),
        amount: .50,
      );
      copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 330);
      final clippedSecond = clipReceiptStitchingSide(sectionB, right: 84);

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'faded_clipped_overlap_a',
      );
      final second = await writeTempReceiptStitchingImage(
        clippedSecond,
        'faded_clipped_overlap_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
      expect(result.overlapPixels.single, greaterThan(120));
      expect(result.hasValidOcrSourceContract, isTrue);
    },
  );

  test(
    'falls back to separate OCR photos when overlap confidence is low',
    () async {
      final first = await writeTempReceiptStitchingImage(
        receiptStitchingSection(seed: 4, topTextOffset: 0),
        'fallback_a',
      );
      final second = await writeTempReceiptStitchingImage(
        blankDarkReceiptPhotoSection(),
        'fallback_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(
        result.usedFallback,
        isTrue,
        reason: 'confidence ${result.confidence}',
      );
      expect(result.ocrSourcePaths, [first.path, second.path]);
      expect(result.failedPairIndex, 0);
      expect(result.fallbackReasonCode, 'overlap_confidence_low');
      expect(result.diagnosticReasonLabel, 'overlap_confidence_low');
      expect(result.warning, isNotEmpty);
      expect(result.pairs, hasLength(1));
      expect(result.pairs.single.confidence, lessThan(.50));
      expect(result.pairs.single.summaryLabel, contains('Photo 1 to 2'));
      expect(result.hasValidOcrSourceContract, isFalse);
      expect(
        result.ocrSourceContractCode,
        'fallback_overlap_untrusted_sources',
      );
      expect(
        result.privacySafeOcrHandoffSafety,
        containsPair('stitchOcrSourceContractReady', false),
      );
    },
  );

  test(
    'does not combine an unrelated app screen with a receipt photo',
    () async {
      final appScreen = receiptStitchingSection(seed: 201, topTextOffset: 0);
      for (var y = 0; y < appScreen.height; y += 210) {
        img.fillRect(
          appScreen,
          x1: 28,
          y1: y + 24,
          x2: appScreen.width - 28,
          y2: (y + 178).clamp(0, appScreen.height - 1),
          color: img.ColorRgb8(38 + (y ~/ 210) * 8, 52, 64),
        );
        for (var x = 52; x < appScreen.width - 80; x += 220) {
          img.fillRect(
            appScreen,
            x1: x,
            y1: y + 48,
            x2: (x + 170).clamp(0, appScreen.width - 1),
            y2: (y + 142).clamp(0, appScreen.height - 1),
            color: img.ColorRgb8(68, 82 + (x ~/ 220) * 8, 92),
          );
        }
      }
      final receipt = receiptStitchingSection(seed: 319, topTextOffset: 7);
      final first = await writeTempReceiptStitchingImage(
        appScreen,
        'unrelated_app_screen',
      );
      final second = await writeTempReceiptStitchingImage(
        receipt,
        'unrelated_receipt',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(result.usedFallback, isTrue, reason: result.detailLabel);
      expect(result.fallbackReasonCode, 'overlap_confidence_low');
      expect(result.ocrSourcePaths, [first.path, second.path]);
      expect(result.failedPairIndex, 0);
    },
    timeout: _stitchingHeavyTimeout,
  );
}
