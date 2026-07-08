import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

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
      expect(
        result.warning,
        contains('same section'),
      );
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
