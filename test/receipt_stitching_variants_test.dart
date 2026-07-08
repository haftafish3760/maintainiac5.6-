import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

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
      expect(result.overlapPixels.single, greaterThan(340));
      final normalizedSectionHeight =
          (sectionA.height * result.stitchedWidth / sectionA.width).round();
      expect(
        result.stitchedHeight,
        normalizedSectionHeight * 2 - result.overlapPixels.single,
      );
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
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
      final normalizedSectionHeight =
          (sectionA.height * result.stitchedWidth / sectionA.width).round();
      expect(
        result.stitchedHeight,
        normalizedSectionHeight * 3 -
            result.overlapPixels.reduce((total, pixels) => total + pixels),
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

      expect(result.didStitch, isTrue, reason: result.detailLabel);
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
    'falls back with output dimensions when receipt would be too large',
    () async {
      final sectionA = receiptStitchingSection(seed: 30, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 31, topTextOffset: 14);
      copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 320);

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'too_large_a',
      );
      final second = await writeTempReceiptStitchingImage(
        sectionB,
        'too_large_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
        maxOutputHeight: 100,
      );

      expect(result.usedFallback, isTrue);
      expect(result.warning, contains('too long'));
      expect(result.fallbackReasonCode, 'output_too_large');
      expect(result.diagnosticReasonLabel, 'output_too_large');
      expect(result.stitchedWidth, greaterThan(0));
      expect(result.stitchedHeight, greaterThan(100));
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
      expect(result.hasValidOcrSourceContract, isFalse);
      expect(result.ocrSourceContractCode, 'fallback_derived_stitch_too_large');
      expect(
        result.privacySafeOcrHandoffSafety,
        containsPair('stitchOcrSourceContractReady', false),
      );
    },
  );

  test(
    'falls back before stitching when output pixel cap would be exceeded',
    () async {
      final sectionA = receiptStitchingSection(seed: 70, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 71, topTextOffset: 14);
      copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 320);

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'pixel_cap_a',
      );
      final second = await writeTempReceiptStitchingImage(
        sectionB,
        'pixel_cap_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
        maxOutputPixels: 500000,
      );

      expect(result.usedFallback, isTrue);
      expect(result.fallbackReasonCode, 'output_too_large');
      expect(result.ocrSourcePaths, [first.path, second.path]);
      expect(result.stitchedWidth, greaterThan(0));
      expect(result.stitchedHeight, greaterThan(0));
      expect(result.stitchedPixelCount, greaterThan(500000));
      expect(result.stitchedPath, isNull);
      expect(result.warning, contains('too long'));
      expect(result.hasValidOcrSourceContract, isFalse);
      expect(result.ocrSourceContractCode, 'fallback_derived_stitch_too_large');
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
}
