import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/receipt_stitching_image_helpers.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test(
    'stitching rejects empty receipt photo lists before OCR handoff',
    () async {
      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: const ['', '   '],
      );

      expect(result.usedFallback, isTrue);
      expect(result.didStitch, isFalse);
      expect(result.inputPaths, isEmpty);
      expect(result.ocrSourcePaths, isEmpty);
      expect(result.fallbackReasonCode, 'no_input_paths');
      expect(result.diagnosticReasonLabel, 'no_input_paths');
      expect(result.userFallbackReasonLabel, 'No receipt photos available');
      expect(result.hasValidOcrSourceContract, isFalse);
      expect(result.ocrSourceContractCode, 'fallback_no_ocr_sources');
      expect(result.ocrHandoffSafetyCode, 'no_receipt_photo_available');
      expect(result.reviewPathLabel, 'No receipt photos to review');
      expect(result.nextStepLabel, 'Add a receipt photo before continuing.');
      expect(result.warning, contains('No receipt photos'));
    },
  );

  test('stitching falls back cleanly for unreadable photo family', () async {
    final valid = await writeTempReceiptStitchingImage(
      receiptStitchingSection(seed: 71, topTextOffset: 0),
      'unreadable_family_valid',
    );
    final dir = await Directory.systemTemp.createTemp(
      'receipt_stitch_unreadable_family_',
    );
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    final empty = File('${dir.path}/empty.jpg')..writeAsBytesSync(const []);
    final corrupt = File('${dir.path}/corrupt.jpg')
      ..writeAsBytesSync([1, 2, 3, 4, 255]);
    final wrongType = File('${dir.path}/not_an_image.txt')
      ..writeAsStringSync('TOTAL 12.34');
    final missingPath = '${dir.path}/deleted_before_stitch.jpg';

    for (final badPath in [
      missingPath,
      empty.path,
      corrupt.path,
      wrongType.path,
    ]) {
      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [valid.path, badPath],
      );

      expect(result.usedFallback, isTrue);
      expect(result.fallbackReasonCode, 'decode_failed');
      expect(result.userFallbackReasonLabel, 'One photo could not be read');
      expect(result.ocrSourcePaths, [valid.path, badPath]);
      expect(result.hasValidOcrSourceContract, isFalse);
      expect(result.ocrSourceContractCode, 'fallback_unreadable_input_source');
      expect(
        result.privacySafeOcrHandoffSafety,
        containsPair('stitchOcrSourceContractReady', false),
      );
    }
  });

  test('stitches overlapping receipt photo sections for OCR', () async {
    final sectionA = receiptStitchingSection(seed: 0, topTextOffset: 0);
    final sectionB = receiptStitchingSection(seed: 1, topTextOffset: 14);
    copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 320);

    final first = await writeTempReceiptStitchingImage(sectionA, 'a');
    final second = await writeTempReceiptStitchingImage(sectionB, 'b');

    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: [first.path, second.path],
    );

    expect(result.didStitch, isTrue, reason: 'confidence ${result.confidence}');
    expect(result.ocrSourcePaths, hasLength(1));
    expect(result.overlapPixels.single, greaterThan(100));
    expect(result.pairs.single.pairIndex, 0);
    expect(result.pairs.single.confidence, greaterThanOrEqualTo(.50));
    expect(result.stitchedWidth, greaterThan(0));
    expect(result.stitchedHeight, greaterThan(0));
    expect(result.stitchedPixelCount, greaterThan(0));
    expect(result.confidence, greaterThanOrEqualTo(.50));
    expect(await File(result.ocrSourcePaths.single).exists(), isTrue);
  });

  test(
    'stitches three ordered long-receipt sections into one OCR source',
    () async {
      final sectionA = receiptStitchingSection(seed: 10, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 11, topTextOffset: 16);
      final sectionC = receiptStitchingSection(seed: 12, topTextOffset: 32);
      copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 330);
      copyReceiptStitchingOverlap(from: sectionB, to: sectionC, pixels: 310);

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'three_part_a',
      );
      final second = await writeTempReceiptStitchingImage(
        sectionB,
        'three_part_b',
      );
      final third = await writeTempReceiptStitchingImage(
        sectionC,
        'three_part_c',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path, third.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs, hasLength(2));
      expect(result.overlapPixels, hasLength(2));
      expect(result.matchedPairCount, 2);
      expect(result.missingPairCount, 0);
      expect(result.allPairsHaveOverlapEvidence, isTrue);
      expect(result.ocrSourcePaths, hasLength(1));
      expect(result.hasValidOcrSourceContract, isTrue);
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(result.overlapPixelTotal, greaterThan(0));
      expect(result.stitchedHeight, greaterThan(sectionA.height));
      expect(result.detailLabel, contains('3 photos became 1 receipt image'));
    },
  );

  test(
    'three-section stitch falls back when a later overlap is untrusted',
    () async {
      final sectionA = receiptStitchingSection(seed: 20, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 21, topTextOffset: 18);
      copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 320);

      final first = await writeTempReceiptStitchingImage(
        sectionA,
        'three_part_fallback_a',
      );
      final second = await writeTempReceiptStitchingImage(
        sectionB,
        'three_part_fallback_b',
      );
      final third = await writeTempReceiptStitchingImage(
        blankDarkReceiptPhotoSection(),
        'three_part_fallback_c',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path, third.path],
      );

      expect(result.usedFallback, isTrue);
      expect(result.didStitch, isFalse);
      expect(result.failedPairIndex, 1);
      expect(result.fallbackReasonCode, 'overlap_confidence_low');
      expect(result.ocrSourcePaths, [first.path, second.path, third.path]);
      expect(result.hasValidOcrSourceContract, isFalse);
      expect(
        result.ocrSourceContractCode,
        'fallback_overlap_untrusted_sources',
      );
      expect(result.pairs, hasLength(2));
      expect(result.pairs.first.hasTrustedOverlapEvidence, isTrue);
      expect(result.pairs.last.hasTrustedOverlapEvidence, isFalse);
    },
  );

  test(
    'low-confidence reversed sections cannot auto-clear OCR assist',
    () async {
      final sectionA = receiptStitchingSection(seed: 80, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 81, topTextOffset: 16);
      copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 330);

      final top = await writeTempReceiptStitchingImage(
        sectionA,
        'reversed_top',
      );
      final bottom = await writeTempReceiptStitchingImage(
        sectionB,
        'reversed_bottom',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [bottom.path, top.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.hasValidOcrSourceContract, isTrue);
      expect(result.hasLowConfidenceAutomaticOverlap, isTrue);
      expect(result.assistedReadinessCode, 'stitched_overlap_review_required');
      expect(result.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
    },
  );

  test(
    'low-confidence missing middle section cannot auto-clear OCR assist',
    () async {
      final sectionA = receiptStitchingSection(seed: 82, topTextOffset: 0);
      final sectionB = receiptStitchingSection(seed: 83, topTextOffset: 18);
      final sectionC = receiptStitchingSection(seed: 84, topTextOffset: 36);
      copyReceiptStitchingOverlap(from: sectionA, to: sectionB, pixels: 320);
      copyReceiptStitchingOverlap(from: sectionB, to: sectionC, pixels: 320);

      final top = await writeTempReceiptStitchingImage(
        sectionA,
        'missing_middle_top',
      );
      final bottom = await writeTempReceiptStitchingImage(
        sectionC,
        'missing_middle_bottom',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [top.path, bottom.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs, hasLength(1));
      expect(result.pairs.single.hasTrustedOverlapEvidence, isTrue);
      expect(result.hasLowConfidenceAutomaticOverlap, isTrue);
      expect(result.assistedReadinessCode, 'stitched_overlap_review_required');
      expect(
        result.privacySafeOcrHandoffSafety,
        containsPair('stitchRequiresOcrSourceReviewBeforeAssistedRead', true),
      );
    },
  );

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
