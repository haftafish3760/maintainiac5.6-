import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

const _stitchingHeavyTimeout = Timeout(Duration(minutes: 2));

void main() {
  test('stitching rejects duplicate receipt section paths', () async {
    final section = receiptStitchingSection(seed: 90, topTextOffset: 0);
    final source = await writeTempReceiptStitchingImage(
      section,
      'duplicate_input',
    );

    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: [source.path, ' ${source.path} '],
    );

    expect(result.usedFallback, isTrue);
    expect(result.fallbackReasonCode, 'duplicate_input_paths');
    expect(result.userFallbackReasonLabel, 'Duplicate receipt section photo');
    expect(result.didStitch, isFalse);
    expect(result.ocrSourcePaths, [source.path, source.path]);
    expect(result.hasValidOcrSourceContract, isFalse);
    expect(result.ocrSourceContractCode, 'fallback_duplicate_input_sources');
    expect(
      result.privacySafeOcrHandoffSafety,
      containsPair('stitchOcrSourceContractReady', false),
    );
  });

  test('stitching rejects duplicate receipt section images', () async {
    final section = receiptStitchingSection(seed: 91, topTextOffset: 0);
    final first = await writeTempReceiptStitchingImage(
      section,
      'duplicate_section_a',
    );
    final second = await writeTempReceiptStitchingImage(
      section,
      'duplicate_section_b',
    );

    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: [first.path, second.path],
    );

    expect(result.usedFallback, isTrue);
    expect(result.didStitch, isFalse);
    expect(result.fallbackReasonCode, 'duplicate_section_image');
    expect(result.userFallbackReasonLabel, 'Duplicate receipt section photo');
    expect(result.failedPairLabel, 'Photo 1 to 2');
    expect(result.ocrSourcePaths, [first.path, second.path]);
    expect(result.hasValidOcrSourceContract, isFalse);
    expect(result.ocrSourceContractCode, 'fallback_duplicate_section_image');
    expect(
      result.privacySafeOcrHandoffSafety,
      containsPair('stitchRequiresOcrSourceReviewBeforeAssistedRead', true),
    );
  });

  test(
    'stitching rejects duplicate receipt section images saved at different quality',
    () async {
      final section = receiptStitchingSection(seed: 94, topTextOffset: 0);
      final first = await writeTempReceiptStitchingImageWithQuality(
        section,
        'duplicate_quality_a',
        quality: 94,
      );
      final second = await writeTempReceiptStitchingImageWithQuality(
        section,
        'duplicate_quality_b',
        quality: 72,
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(result.usedFallback, isTrue, reason: result.detailLabel);
      expect(result.didStitch, isFalse);
      expect(result.fallbackReasonCode, 'duplicate_section_image');
      expect(result.failedPairLabel, 'Photo 1 to 2');
      expect(result.ocrSourceContractCode, 'fallback_duplicate_section_image');
    },
  );

  test(
    'stitching rejects duplicate receipt section images with exposure changes',
    () async {
      final section = receiptStitchingSection(seed: 97, topTextOffset: 0);
      final darkerCopy = adjustReceiptStitchingBrightness(section, delta: -22);
      final first = await writeTempReceiptStitchingImage(
        section,
        'duplicate_exposure_a',
      );
      final second = await writeTempReceiptStitchingImage(
        darkerCopy,
        'duplicate_exposure_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(result.usedFallback, isTrue, reason: result.detailLabel);
      expect(result.didStitch, isFalse);
      expect(result.fallbackReasonCode, 'duplicate_section_image');
      expect(result.failedPairLabel, 'Photo 1 to 2');
      expect(result.ocrSourceContractCode, 'fallback_duplicate_section_image');
    },
  );

  test(
    'stitching rejects duplicate receipt section images even when repeated later in the stack',
    () async {
      final top = receiptStitchingSection(seed: 92, topTextOffset: 0);
      final middle = receiptStitchingSection(seed: 93, topTextOffset: 18);
      copyReceiptStitchingOverlap(from: top, to: middle, pixels: 330);

      final first = await writeTempReceiptStitchingImage(
        top,
        'duplicate_non_neighbor_a',
      );
      final second = await writeTempReceiptStitchingImage(
        middle,
        'duplicate_non_neighbor_b',
      );
      final third = await writeTempReceiptStitchingImage(
        top,
        'duplicate_non_neighbor_c',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path, third.path],
      );

      expect(result.usedFallback, isTrue);
      expect(result.didStitch, isFalse);
      expect(result.fallbackReasonCode, 'duplicate_section_image');
      expect(result.failedPairIndex, 1);
      expect(result.failedPairLabel, 'Photo 2 to 3');
      expect(result.ocrSourcePaths, [first.path, second.path, third.path]);
      expect(result.hasValidOcrSourceContract, isFalse);
      expect(result.ocrSourceContractCode, 'fallback_duplicate_section_image');
      expect(result.warning, contains('same section'));
    },
  );

  test(
    'stitching rejects recompressed duplicate receipt section repeated later in the stack',
    () async {
      final top = receiptStitchingSection(seed: 95, topTextOffset: 0);
      final middle = receiptStitchingSection(seed: 96, topTextOffset: 18);
      copyReceiptStitchingOverlap(from: top, to: middle, pixels: 330);

      final first = await writeTempReceiptStitchingImageWithQuality(
        top,
        'duplicate_quality_non_neighbor_a',
        quality: 94,
      );
      final second = await writeTempReceiptStitchingImage(
        middle,
        'duplicate_quality_non_neighbor_b',
      );
      final third = await writeTempReceiptStitchingImageWithQuality(
        top,
        'duplicate_quality_non_neighbor_c',
        quality: 70,
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path, third.path],
      );

      expect(result.usedFallback, isTrue, reason: result.detailLabel);
      expect(result.fallbackReasonCode, 'duplicate_section_image');
      expect(result.failedPairIndex, 1);
      expect(result.failedPairLabel, 'Photo 2 to 3');
      expect(result.ocrSourcePaths, [first.path, second.path, third.path]);
      expect(result.ocrSourceContractCode, 'fallback_duplicate_section_image');
    },
  );

  test('stitches receipt sections when the next photo is closer', () async {
    final sectionA = receiptStitchingSection(seed: 40, topTextOffset: 0);
    final sectionB = receiptStitchingSection(seed: 41, topTextOffset: 18);
    copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 340);
    final closerSecond = scaleReceiptStitchingShot(sectionB, scale: 1.12);

    final first = await writeTempReceiptStitchingImage(
      sectionA,
      'scale_close_a',
    );
    final second = await writeTempReceiptStitchingImage(
      closerSecond,
      'scale_close_b',
    );

    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: [first.path, second.path],
    );

    expect(result.didStitch, isTrue, reason: result.detailLabel);
    expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
    expect(result.pairs.single.diagnosticCode, isNotEmpty);
    expect(result.pairs.single.userCheckLabel, contains('Photo 1 to 2'));
    expect(result.ocrSourcePaths, hasLength(1));
  });

  test(
    'stitches receipt sections when the next photo is farther away',
    () async {
      final sectionA = receiptStitchingSection(seed: 50, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 51, topTextOffset: 18);
      copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 340);
      final fartherSecond = scaleReceiptStitchingShot(sectionB, scale: .90);

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'scale_far_a',
      );
      final second = await writeTempReceiptStitchingImage(
        fartherSecond,
        'scale_far_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
      expect(result.pairs.single.diagnosticCode, isNotEmpty);
      expect(result.ocrSourcePaths, hasLength(1));
    },
  );

  test('stitches receipt sections with slight handheld rotation', () async {
    final sectionA = receiptStitchingSection(seed: 60, topTextOffset: 0);
    final sectionB = receiptStitchingSection(seed: 61, topTextOffset: 18);
    copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 340);
    final rotatedSecond = rotateReceiptStitchingShot(sectionB, degrees: 1.2);

    final first = await writeTempReceiptStitchingImage(sectionA, 'rotate_a');
    final second = await writeTempReceiptStitchingImage(
      rotatedSecond,
      'rotate_b',
    );

    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: [first.path, second.path],
    );

    expect(result.didStitch, isTrue, reason: result.detailLabel);
    expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
    expect(result.pairs.single.summaryLabel, contains('%'));
    expect(result.pairs.single.diagnosticCode, isNotEmpty);
    expect(result.ocrSourcePaths, hasLength(1));
  });

  test(
    'stitches receipt sections with modest horizontal handheld drift',
    () async {
      for (final drift in const [18, -18]) {
        final sectionA = receiptStitchingSection(
          seed: 64 + drift.abs(),
          topTextOffset: 0,
        );
        final sectionB = receiptStitchingSection(
          seed: 65 + drift.abs(),
          topTextOffset: 18,
        );
        copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 340);
        final shiftedSecond = shiftReceiptStitchingShot(
          sectionB,
          dx: drift,
          dy: 0,
        );

        final first = await writeTempReceiptStitchingImage(
          sectionA,
          'shift_${drift}_a',
        );
        final second = await writeTempReceiptStitchingImage(
          shiftedSecond,
          'shift_${drift}_b',
        );

        final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
          paths: [first.path, second.path],
        );

        expect(
          result.didStitch,
          isTrue,
          reason: 'drift=$drift ${result.detailLabel}',
        );
        expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
        expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      }
    },
    timeout: _stitchingHeavyTimeout,
  );

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
