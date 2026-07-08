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

  test(
    'shifted duplicate repeated later in the stack requires review before assist',
    () async {
      final top = receiptStitchingSection(seed: 98, topTextOffset: 0);
      final middle = receiptStitchingSection(seed: 99, topTextOffset: 18);
      copyReceiptStitchingOverlap(from: top, to: middle, pixels: 330);
      final shiftedDuplicate = shiftReceiptStitchingShot(top, dx: 28, dy: 0);

      final first = await writeTempReceiptStitchingImage(
        top,
        'duplicate_shifted_non_neighbor_a',
      );
      final second = await writeTempReceiptStitchingImage(
        middle,
        'duplicate_shifted_non_neighbor_b',
      );
      final third = await writeTempReceiptStitchingImage(
        shiftedDuplicate,
        'duplicate_shifted_non_neighbor_c',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [first.path, second.path, third.path],
      );

      expect(
        result.requiresOcrSourceReviewBeforeAssistedRead,
        isTrue,
        reason: result.detailLabel,
      );
      if (result.didStitch) {
        expect(result.hasLowConfidenceAutomaticOverlap, isTrue);
        expect(
          result.assistedReadinessCode,
          'stitched_overlap_review_required',
        );
        expect(result.reviewFocusPairLabel, isNotEmpty);
        expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      } else {
        expect(result.usedFallback, isTrue, reason: result.detailLabel);
        expect(result.fallbackReasonCode, 'duplicate_section_image');
        expect(result.failedPairIndex, anyOf(0, 1));
        expect(result.failedPairLabel, isNotEmpty);
        expect(result.ocrSourcePaths, [first.path, second.path, third.path]);
        expect(
          result.ocrSourceContractCode,
          'fallback_duplicate_section_image',
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
