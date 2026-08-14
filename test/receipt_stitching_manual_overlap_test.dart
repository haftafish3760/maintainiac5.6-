import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_stitching_image_helpers.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

const _stitchingHeavyTimeout = Timeout(Duration(minutes: 2));

void main() {
  test(
    'manual overlap can stitch when automatic matching is uncertain',
    () async {
      final first = await writeTempReceiptStitchingImage(
        receiptStitchingSection(seed: 4, topTextOffset: 0),
        'manual_a',
      );
      final second = await writeTempReceiptStitchingImage(
        receiptStitchingSection(seed: 12, topTextOffset: 37),
        'manual_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
        manualOverlapPixels: const [260],
      );

      expect(result.didStitch, isTrue);
      expect(result.usedManualAdjustment, isTrue);
      expect(result.overlapPixels, [260]);
      expect(result.pairs.single.usedManualAdjustment, isTrue);
      expect(result.pairs.single.summaryLabel, contains('manual match'));
      expect(result.pairs.single.diagnosticCode, 'manual_overlap');
      expect(result.pairs.single.userCheckLabel, contains('manual overlap'));
      expect(result.ocrSourcePaths, hasLength(1));
      expect(result.detailLabel, contains('Manual match was used'));
    },
  );

  test('manual overlap fraction can drive stitching from review UI', () async {
    final first = await writeTempReceiptStitchingImage(
      receiptStitchingSection(seed: 7, topTextOffset: 0),
      'manual_fraction_a',
    );
    final second = await writeTempReceiptStitchingImage(
      receiptStitchingSection(seed: 9, topTextOffset: 28),
      'manual_fraction_b',
    );

    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: [first.path, second.path],
      manualOverlapFractions: const [.22],
    );

    expect(result.didStitch, isTrue);
    expect(result.usedManualAdjustment, isTrue);
    expect(result.overlapPixels.single, greaterThan(40));
    expect(result.ocrSourcePaths, hasLength(1));
  });

  test(
    'manual alignment applies size straightening and horizontal position',
    () async {
      final first = await writeTempReceiptStitchingImage(
        receiptStitchingSection(seed: 31, topTextOffset: 0),
        'manual_transform_a',
      );
      final second = await writeTempReceiptStitchingImage(
        receiptStitchingSection(seed: 32, topTextOffset: 30),
        'manual_transform_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
        manualOverlapFractions: const [.24],
        manualScaleCorrections: const [.94],
        manualRotationCorrectionsDegrees: const [1.5],
        manualHorizontalOffsetFractions: const [.04],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      final pair = result.pairs.single;
      expect(pair.usedManualAdjustment, isTrue);
      expect(pair.scaleCorrection, closeTo(.94, .001));
      expect(pair.rotationCorrectionDegrees, closeTo(1.5, .001));
      expect(pair.horizontalOffsetPixels, isNonZero);
      expect(result.stitchedPath, isNotNull);
    },
  );

  test('zero manual overlap fraction does not claim manual match', () async {
    final sectionA = receiptStitchingSection(seed: 17, topTextOffset: 0);
    final sectionB = receiptStitchingSection(seed: 18, topTextOffset: 20);
    copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 320);
    final first = await writeTempReceiptStitchingImage(
      sectionA,
      'manual_zero_a',
    );
    final second = await writeTempReceiptStitchingImage(
      sectionB,
      'manual_zero_b',
    );

    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: [first.path, second.path],
      manualOverlapFractions: const [0],
    );

    expect(result.didStitch, isTrue, reason: result.detailLabel);
    expect(result.usedManualAdjustment, isFalse);
    expect(result.pairs.single.usedManualAdjustment, isFalse);
    expect(result.matchConfidenceLabel, isNot('Manual match'));
  });

  test('zero manual overlap pixels do not block automatic stitching', () async {
    final sectionA = receiptStitchingSection(seed: 19, topTextOffset: 0);
    final sectionB = receiptStitchingSection(seed: 20, topTextOffset: 20);
    copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 320);
    final first = await writeTempReceiptStitchingImage(
      sectionA,
      'manual_zero_pixels_a',
    );
    final second = await writeTempReceiptStitchingImage(
      sectionB,
      'manual_zero_pixels_b',
    );

    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: [first.path, second.path],
      manualOverlapPixels: const [0],
    );

    expect(result.didStitch, isTrue, reason: result.detailLabel);
    expect(result.usedManualAdjustment, isFalse);
    expect(result.pairs.single.usedManualAdjustment, isFalse);
    expect(result.fallbackReasonCode, isEmpty);
    expect(result.ocrSourcePaths, hasLength(1));
  });

  test(
    'explicit no-overlap recovery preserves both ordered sections',
    () async {
      final sectionA = receiptStitchingSection(seed: 221, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 222, topTextOffset: 20);
      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'manual_no_overlap_a',
      );
      final second = await writeTempReceiptStitchingImage(
        sectionB,
        'manual_no_overlap_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
        manualZeroOverlapPairs: const [true],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.overlapPixels, [0]);
      expect(result.pairs.single.usedZeroOverlapJoin, isTrue);
      expect(result.pairs.single.matchEvidenceLabel, 'no-overlap placement');
      expect(result.pairs.single.diagnosticCode, 'manual_zero_overlap_join');
      expect(result.confidence, .30);
      expect(result.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
      expect(result.ocrSourcePaths, hasLength(1));
      expect(await File(result.ocrSourcePaths.single).exists(), isTrue);
    },
  );

  test(
    'manual overlap falls back when the requested overlap is unsafe',
    () async {
      final first = await writeTempReceiptStitchingImage(
        receiptStitchingSection(seed: 5, topTextOffset: 0),
        'manual_bad_a',
      );
      final second = await writeTempReceiptStitchingImage(
        receiptStitchingSection(seed: 6, topTextOffset: 0),
        'manual_bad_b',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
        manualOverlapPixels: const [999999],
      );

      expect(result.usedFallback, isTrue);
      expect(result.warning, contains('outside the safe range'));
      expect(result.fallbackReasonCode, 'manual_overlap_unsafe');
      expect(result.diagnosticReasonLabel, 'manual_overlap_unsafe');
      expect(result.failedPairIndex, 0);
      expect(result.ocrSourcePaths, [first.path, second.path]);
    },
  );

  test('manual overlap fraction rejects non-finite values safely', () async {
    final first = await writeTempReceiptStitchingImage(
      receiptStitchingSection(seed: 8, topTextOffset: 0),
      'manual_non_finite_a',
    );
    final second = await writeTempReceiptStitchingImage(
      receiptStitchingSection(seed: 10, topTextOffset: 0),
      'manual_non_finite_b',
    );

    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: [first.path, second.path],
      manualOverlapFractions: const [double.infinity],
    );

    expect(result.usedFallback, isTrue);
    expect(result.fallbackReasonCode, 'manual_overlap_unsafe');
    expect(result.diagnosticReasonLabel, 'manual_overlap_unsafe');
    expect(result.failedPairIndex, 0);
    expect(result.ocrSourcePaths, [first.path, second.path]);
  });

  test(
    'manual overlap supports multi-section long receipt stitching',
    () async {
      final sectionA = receiptStitchingSection(seed: 21, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 22, topTextOffset: 24);
      final sectionC = receiptStitchingSection(seed: 23, topTextOffset: 48);
      copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 240);
      copyReceiptStitchingOverlap(from: sectionB, to: sectionC, pixels: 280);

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'manual_multi_a',
      );
      final second = await writeTempReceiptStitchingImage(
        sectionB,
        'manual_multi_b',
      );
      final third = await writeTempReceiptStitchingImage(
        sectionC,
        'manual_multi_c',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path, third.path],
        manualOverlapPixels: const [240, 280],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.usedManualAdjustment, isTrue);
      expect(result.overlapPixels, [240, 280]);
      expect(result.pairs, hasLength(2));
      expect(result.pairs.every((pair) => pair.usedManualAdjustment), isTrue);
      expect(result.ocrSourcePaths, hasLength(1));
    },
  );

  test(
    'manual overlap supports exposure-shifted long receipt sections',
    () async {
      final sectionA = receiptStitchingSection(seed: 24, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 25, topTextOffset: 22);
      final sectionC = receiptStitchingSection(seed: 26, topTextOffset: 44);
      copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 255);
      copyReceiptStitchingOverlap(from: sectionB, to: sectionC, pixels: 275);

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'manual_exposure_a',
      );
      final second = await writeTempReceiptStitchingImage(
        adjustReceiptStitchingBrightness(sectionB, delta: 34),
        'manual_exposure_b',
      );
      final third = await writeTempReceiptStitchingImage(
        adjustReceiptStitchingBrightness(sectionC, delta: -30),
        'manual_exposure_c',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path, third.path],
        manualOverlapPixels: const [255, 275],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.usedManualAdjustment, isTrue);
      expect(result.overlapPixels, [255, 275]);
      expect(result.pairs, hasLength(2));
      expect(result.pairs.every((pair) => pair.usedManualAdjustment), isTrue);
      expect(result.ocrSourcePaths, [result.stitchedPath]);
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
    },
  );

  test(
    'manual overlap long receipt respects derived output size cap',
    () async {
      final tallReceipt = tallReceiptStitchingCanvas(sectionCount: 6);
      final files = <String>[];
      for (var index = 0; index < 6; index++) {
        final window = cropReceiptStitchingPhoneWindow(
          tallReceipt,
          y: index * 1120,
        );
        final file = await writeTempReceiptStitchingImage(
          window,
          'manual_overlap_size_cap_$index',
        );
        files.add(file.path);
      }

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: files,
        manualOverlapPixels: const [260, 260, 260, 260, 260],
        maxOutputPixels: 4000000,
      );

      expect(result.usedFallback, isTrue);
      expect(result.fallbackReasonCode, 'output_too_large');
      expect(result.stitchedPath, isNull);
      expect(result.ocrSourcePaths, files);
      expect(result.ocrSourceContractCode, 'fallback_ordered_sources_ready');
      expect(result.requiresOcrSourceReviewBeforeAssistedRead, isFalse);
      expect(result.pairs.length, lessThan(5));
      expect(result.failedPairIndex, result.pairs.last.pairIndex);
      expect(result.failedPairLabel, isNotEmpty);
      expect(result.pairs.every((pair) => pair.usedManualAdjustment), isTrue);
      expect(result.stitchedPixelCount, greaterThan(900000));
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'manual overlap can guide one pair while auto matching handles the next',
    () async {
      final sectionA = receiptStitchingSection(seed: 31, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 32, topTextOffset: 18);
      final sectionC = receiptStitchingSection(seed: 33, topTextOffset: 36);
      copyReceiptStitchingOverlap(from: sectionB, to: sectionC, pixels: 260);

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'manual_then_auto_a',
      );
      final second = await writeTempReceiptStitchingImage(
        sectionB,
        'manual_then_auto_b',
      );
      final third = await writeTempReceiptStitchingImage(
        sectionC,
        'manual_then_auto_c',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path, third.path],
        manualOverlapPixels: const [220],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.overlapPixels, hasLength(2));
      expect(result.overlapPixels.first, 220);
      expect(result.pairs, hasLength(2));
      expect(result.pairs.first.usedManualAdjustment, isTrue);
      expect(result.pairs.last.usedManualAdjustment, isFalse);
      expect(result.pairs.last.confidence, greaterThanOrEqualTo(.50));
      expect(result.usedManualAdjustment, isTrue);
      expect(result.ocrSourcePaths, hasLength(1));
    },
    timeout: _stitchingHeavyTimeout,
  );

  test(
    'manual overlap can rescue an unclear continuation intentionally',
    () async {
      final top = receiptStitchingSection(seed: 120, topTextOffset: 0);
      final bottom = blankDarkReceiptPhotoSection();

      final first = await writeTempReceiptStitchingImage(
        top,
        'manual_overlap_top',
      );
      final second = await writeTempReceiptStitchingImage(
        bottom,
        'manual_overlap_unclear_bottom',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path],
        manualOverlapPixels: const [180],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.usedManualAdjustment, isTrue);
      expect(result.overlapPixels, [180]);
      expect(result.pairs.single.usedManualAdjustment, isTrue);
      expect(result.pairs.single.hasTrustedOverlapEvidence, isTrue);
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(result.assistedReadinessCode, 'stitched_overlap_verified_ready');
    },
  );

  test('unsafe manual overlap keeps OCR source in review lane', () async {
    final top = receiptStitchingSection(seed: 121, topTextOffset: 0);
    final bottom = receiptStitchingSection(seed: 122, topTextOffset: 18);
    copyReceiptStitchingOverlap(from: top, to: bottom, pixels: 320);

    final first = await writeTempReceiptStitchingImage(
      top,
      'manual_overlap_unsafe_top',
    );
    final second = await writeTempReceiptStitchingImage(
      bottom,
      'manual_overlap_unsafe_bottom',
    );

    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: [first.path, second.path],
      manualOverlapFractions: const [1.25],
    );

    expect(result.usedFallback, isTrue);
    expect(result.fallbackReasonCode, 'manual_overlap_unsafe');
    expect(result.failedPairLabel, 'Photo 1 to 2');
    expect(result.ocrSourcePaths, [first.path, second.path]);
    expect(result.hasValidOcrSourceContract, isTrue);
    expect(result.ocrSourceContractCode, 'fallback_ordered_sources_ready');
    expect(result.requiresOcrSourceReviewBeforeAssistedRead, isFalse);
    expect(result.assistedReadinessCode, 'ordered_sections_ready');
  });

  test('unsafe later manual overlap preserves prior pair evidence', () async {
    final sectionA = receiptStitchingSection(seed: 123, topTextOffset: 0);
    final sectionB = receiptStitchingSection(seed: 124, topTextOffset: 18);
    final sectionC = receiptStitchingSection(seed: 125, topTextOffset: 36);
    copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 260);
    copyReceiptStitchingOverlap(from: sectionB, to: sectionC, pixels: 280);

    final first = await writeTempReceiptStitchingImage(
      sectionA,
      'manual_overlap_later_unsafe_a',
    );
    final second = await writeTempReceiptStitchingImage(
      sectionB,
      'manual_overlap_later_unsafe_b',
    );
    final third = await writeTempReceiptStitchingImage(
      sectionC,
      'manual_overlap_later_unsafe_c',
    );

    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: [first.path, second.path, third.path],
      manualOverlapPixels: const [260, 999999],
    );

    expect(result.usedFallback, isTrue);
    expect(result.fallbackReasonCode, 'manual_overlap_unsafe');
    expect(result.failedPairIndex, 1);
    expect(result.failedPairLabel, 'Photo 2 to 3');
    expect(result.pairs, hasLength(1));
    expect(result.pairs.single.usedManualAdjustment, isTrue);
    expect(result.pairs.single.overlapPixels, 260);
    expect(result.ocrSourcePaths, [first.path, second.path, third.path]);
    expect(result.requiresOcrSourceReviewBeforeAssistedRead, isFalse);
  });
}
