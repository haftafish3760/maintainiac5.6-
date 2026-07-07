import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

void main() {
  test('stitch result labels explain stitched and fallback OCR handoff', () {
    final stitched = ReceiptStitchResult(
      status: ReceiptStitchStatus.stitched,
      inputPaths: ['/tmp/a.jpg', '/tmp/b.jpg', '/tmp/c.jpg'],
      ocrSourcePaths: ['/tmp/stitched.jpg'],
      stitchedPath: '/tmp/stitched.jpg',
      confidence: .86,
      overlapPixels: [240, 260],
      stitchedWidth: 1200,
      stitchedHeight: 4200,
      pairs: [
        ReceiptStitchPairResult(
          pairIndex: 0,
          overlapPixels: 240,
          confidence: .86,
        ),
        ReceiptStitchPairResult(
          pairIndex: 1,
          overlapPixels: 260,
          confidence: .9,
          rotationCorrectionDegrees: .8,
        ),
      ],
    );
    final fallback = ReceiptStitchResult.fallback(
      inputPaths: ['/tmp/a.jpg', '/tmp/b.jpg'],
      warning: 'Overlap was not clear enough.',
      confidence: .34,
      failedPairIndex: 0,
    );

    expect(stitched.summaryLabel, contains('combined'));
    expect(stitched.ocrSourceContractCode, 'stitched_ocr_source_ready');
    expect(stitched.hasValidOcrSourceContract, isTrue);
    expect(
      stitched.privacySafeOcrHandoffSafety,
      containsPair('stitchOcrSourceContractCode', 'stitched_ocr_source_ready'),
    );
    expect(
      stitched.privacySafeOcrHandoffSafety,
      containsPair('stitchOcrSourceContractReady', true),
    );
    expect(stitched.detailLabel, contains('3 photos became 1 receipt image'));
    expect(stitched.detailLabel, contains('1200 x 4200'));
    expect(stitched.detailLabel, contains('86%'));
    expect(stitched.stitchedPixelCount, 5040000);
    expect(stitched.matchedPairCount, 2);
    expect(stitched.missingPairCount, 0);
    expect(stitched.allPairsHaveOverlapEvidence, isTrue);
    expect(stitched.overlapCoverageCode, 'all_pairs_have_overlap_evidence');
    expect(
      stitched.sourcePreservationCode,
      'original_sections_preserved_derived_stitched_ocr_artifact',
    );
    expect(
      stitched.overlapCoverageLabel,
      'Every adjacent receipt section has overlap evidence.',
    );
    expect(stitched.pairs.first.summaryLabel, contains('Photo 1 to 2'));
    expect(stitched.pairs.last.summaryLabel, contains('straighten 0.8 deg'));
    expect(stitched.pairs.first.diagnosticCode, 'overlap_matched');
    expect(stitched.pairs.last.diagnosticCode, 'straighten_adjusted');
    expect(stitched.pairs.last.userCheckLabel, contains('slight tilt'));
    expect(stitched.diagnosticCodeLabel, 'overlap_matched,straighten_adjusted');
    expect(stitched.pairDiagnosticsLabel, contains('Photo 1 to 2 matched'));
    const zoomAndTilt = ReceiptStitchPairResult(
      pairIndex: 2,
      overlapPixels: 180,
      confidence: .73,
      scaleCorrection: 1.12,
      rotationCorrectionDegrees: 1.2,
    );
    expect(zoomAndTilt.diagnosticCode, 'zoom_and_straighten_adjusted');
    expect(zoomAndTilt.userCheckLabel, contains('zoom difference'));
    expect(zoomAndTilt.userCheckLabel, contains('slight tilt'));
    expect(fallback.summaryLabel, contains('reviewed separately'));
    expect(fallback.ocrSourceContractCode, 'fallback_ordered_sources_ready');
    expect(fallback.hasValidOcrSourceContract, isTrue);
    expect(fallback.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
    expect(
      fallback.assistedReadinessCode,
      'ordered_sections_stitch_fallback_review_required',
    );
    expect(
      fallback.privacySafeOcrHandoffSafety,
      containsPair(
        'stitchAssistedReadinessCode',
        'ordered_sections_stitch_fallback_review_required',
      ),
    );
    expect(
      fallback.privacySafeOcrHandoffSafety,
      containsPair('stitchRequiresOcrSourceReviewBeforeAssistedRead', true),
    );
    expect(fallback.ocrSourcePaths, ['/tmp/a.jpg', '/tmp/b.jpg']);
    expect(fallback.failedPairLabel, 'Photo 1 to 2');
    expect(fallback.matchedPairCount, 0);
    expect(fallback.missingPairCount, 1);
    expect(fallback.allPairsHaveOverlapEvidence, isFalse);
    expect(fallback.overlapCoverageCode, 'fallback_pair_1_to_2');
    expect(
      fallback.sourcePreservationCode,
      'original_sections_preserved_ordered_ocr_sources',
    );
    expect(
      fallback.overlapCoverageLabel,
      'Photo 1 to 2 did not have trusted overlap; OCR keeps sections ordered.',
    );
    expect(fallback.diagnosticReasonLabel, 'unknown');
    expect(fallback.diagnosticCodeLabel, 'unknown');
    expect(fallback.userFallbackReasonLabel, 'Stitching was not trusted');
    expect(fallback.detailLabel, 'Photo 1 to 2: Overlap was not clear enough.');
  });

  test('stitch OCR handoff contract catches mismatched source paths', () {
    final stitchedMismatch = ReceiptStitchResult(
      status: ReceiptStitchStatus.stitched,
      inputPaths: ['/tmp/top.jpg', '/tmp/bottom.jpg'],
      ocrSourcePaths: ['/tmp/different_stitch.jpg'],
      stitchedPath: '/tmp/final_stitch.jpg',
    );
    final stitchedMissing = ReceiptStitchResult(
      status: ReceiptStitchStatus.stitched,
      inputPaths: ['/tmp/top.jpg', '/tmp/bottom.jpg'],
      ocrSourcePaths: [],
    );
    final fallbackMismatch =
        ReceiptStitchResult.fallback(
          inputPaths: ['/tmp/top.jpg', '/tmp/bottom.jpg'],
          warning: 'Fallback for test.',
        ).copyForFinalOcr(
          inputPaths: const ['/tmp/top.jpg', '/tmp/bottom.jpg'],
          ocrSourcePaths: const ['/tmp/top.jpg'],
        );

    expect(
      stitchedMismatch.ocrSourceContractCode,
      'stitched_ocr_source_path_mismatch',
    );
    expect(stitchedMismatch.hasValidOcrSourceContract, isFalse);
    expect(stitchedMismatch.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
    expect(
      stitchedMismatch.assistedReadinessCode,
      'stitch_contract_review_required',
    );
    expect(
      stitchedMissing.ocrSourceContractCode,
      'stitched_ocr_source_missing',
    );
    expect(stitchedMissing.hasValidOcrSourceContract, isFalse);
    expect(stitchedMissing.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
    expect(
      fallbackMismatch.ocrSourceContractCode,
      'fallback_ordered_source_count_mismatch',
    );
    expect(fallbackMismatch.hasValidOcrSourceContract, isFalse);
    expect(fallbackMismatch.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
  });

  test('single and manual stitch overlap coverage stay explicit', () {
    final single = ReceiptStitchResult.notNeeded(['/tmp/single.jpg']);
    final manual = ReceiptStitchResult(
      status: ReceiptStitchStatus.stitched,
      inputPaths: ['/tmp/a.jpg', '/tmp/b.jpg'],
      ocrSourcePaths: ['/tmp/stitched.jpg'],
      stitchedPath: '/tmp/stitched.jpg',
      confidence: 1,
      overlapPixels: [260],
      usedManualAdjustment: true,
      pairs: [
        ReceiptStitchPairResult(
          pairIndex: 0,
          overlapPixels: 260,
          confidence: 1,
          usedManualAdjustment: true,
        ),
      ],
    );

    expect(single.pairCount, 0);
    expect(single.overlapCoverageCode, 'single_section_no_overlap_needed');
    expect(single.preservesOriginalSectionSources, isTrue);
    expect(single.requiresOcrSourceReviewBeforeAssistedRead, isFalse);
    expect(single.assistedReadinessCode, 'single_section_ready');
    expect(
      single.sourcePreservationCode,
      'original_sections_preserved_ordered_ocr_sources',
    );
    expect(manual.pairs.single.hasTrustedOverlapEvidence, isTrue);
    expect(manual.matchedPairCount, 1);
    expect(manual.requiresOcrSourceReviewBeforeAssistedRead, isFalse);
    expect(manual.assistedReadinessCode, 'stitched_overlap_verified_ready');
    expect(manual.overlapCoverageCode, 'all_pairs_have_overlap_evidence');
    expect(manual.overlapExpectationLabel, 'Manual overlap accepted');
  });

  test('stitch result handoff lists are immutable views', () {
    final inputPaths = ['/tmp/a.jpg', '/tmp/b.jpg'];
    final ocrSourcePaths = ['/tmp/stitched.jpg'];
    final overlapPixels = [240];
    final pairs = [
      const ReceiptStitchPairResult(
        pairIndex: 0,
        overlapPixels: 240,
        confidence: .86,
      ),
    ];
    final stitched = ReceiptStitchResult(
      status: ReceiptStitchStatus.stitched,
      inputPaths: inputPaths,
      ocrSourcePaths: ocrSourcePaths,
      stitchedPath: '/tmp/stitched.jpg',
      overlapPixels: overlapPixels,
      pairs: pairs,
    );

    inputPaths.add('/tmp/c.jpg');
    ocrSourcePaths.add('/tmp/late.jpg');
    overlapPixels.add(260);
    pairs.add(
      const ReceiptStitchPairResult(
        pairIndex: 1,
        overlapPixels: 260,
        confidence: .84,
      ),
    );

    expect(stitched.inputPaths, ['/tmp/a.jpg', '/tmp/b.jpg']);
    expect(stitched.ocrSourcePaths, ['/tmp/stitched.jpg']);
    expect(stitched.overlapPixels, [240]);
    expect(stitched.pairs, hasLength(1));
    expect(
      () => stitched.inputPaths.add('/tmp/nope.jpg'),
      throwsA(isA<UnsupportedError>()),
    );
    expect(
      () => stitched.ocrSourcePaths.add('/tmp/nope.jpg'),
      throwsA(isA<UnsupportedError>()),
    );
    expect(
      () => stitched.overlapPixels.add(999),
      throwsA(isA<UnsupportedError>()),
    );
    expect(
      () => stitched.pairs.add(
        const ReceiptStitchPairResult(
          pairIndex: 9,
          overlapPixels: 120,
          confidence: .5,
        ),
      ),
      throwsA(isA<UnsupportedError>()),
    );
  });

  test('stitch labels sanitize non-finite numeric evidence safely', () {
    final stitched = ReceiptStitchResult(
      status: ReceiptStitchStatus.stitched,
      inputPaths: ['/tmp/a.jpg', '/tmp/b.jpg'],
      ocrSourcePaths: ['/tmp/stitched.jpg'],
      stitchedPath: '/tmp/stitched.jpg',
      confidence: double.nan,
      overlapPixels: [140],
      pairs: [
        ReceiptStitchPairResult(
          pairIndex: 0,
          overlapPixels: 140,
          confidence: double.infinity,
          scaleCorrection: double.nan,
          rotationCorrectionDegrees: double.infinity,
        ),
      ],
    );

    expect(stitched.matchConfidenceLabel, '0% match');
    expect(stitched.detailLabel, contains('Photo match confidence 0%.'));
    expect(stitched.detailLabel, isNot(contains('NaN')));
    expect(stitched.detailLabel, isNot(contains('Infinity')));
    expect(stitched.pairs.single.hasTrustedOverlapEvidence, isFalse);
    expect(stitched.pairs.single.summaryLabel, contains('0% match'));
    expect(stitched.pairs.single.summaryLabel, isNot(contains('NaN')));
    expect(stitched.pairs.single.summaryLabel, isNot(contains('Infinity')));
    expect(stitched.pairs.single.matchEvidenceLabel, '0% overlap');
    expect(stitched.pairs.single.diagnosticCode, 'overlap_matched');
    expect(
      stitched.pairs.single.userCheckLabel,
      'Photo 1 to 2 matched repeated receipt text.',
    );
  });

  test('stitch fallback reasons have user-safe plain labels', () {
    ReceiptStitchResult fallback(String reason) => ReceiptStitchResult.fallback(
      inputPaths: const ['/tmp/a.jpg', '/tmp/b.jpg'],
      warning: 'Fallback for test.',
      fallbackReasonCode: reason,
    );

    expect(
      fallback('decode_failed').userFallbackReasonLabel,
      'One photo could not be read',
    );
    expect(
      fallback('manual_overlap_unsafe').userFallbackReasonLabel,
      'Manual overlap was outside the safe range',
    );
    expect(
      fallback('duplicate_section_image').userFallbackReasonLabel,
      'Duplicate receipt section photo',
    );
    expect(
      fallback('manual_order_review').userFallbackReasonLabel,
      'Receipt section order needs review',
    );
    expect(
      fallback('overlap_confidence_low').userFallbackReasonLabel,
      'Overlap was not clear enough',
    );
    expect(
      fallback('output_too_large').userFallbackReasonLabel,
      'Receipt is too long for this device',
    );
    expect(
      fallback('stitch_exception').userFallbackReasonLabel,
      'Stitching hit a safe fallback',
    );
  });

  test(
    'stitch rejects duplicate or alias section paths before decoding',
    () async {
      final duplicate = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: const ['/tmp/receipt/top.jpg', '/tmp/receipt/top.jpg'],
      );
      final alias = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: const [
          '/tmp/receipt/top.jpg',
          '/tmp/receipt/../receipt/top.jpg',
        ],
      );

      for (final result in [duplicate, alias]) {
        expect(result.usedFallback, isTrue);
        expect(result.diagnosticReasonLabel, 'duplicate_input_paths');
        expect(
          result.sourcePreservationCode,
          'original_sections_preserved_ordered_ocr_sources',
        );
        expect(
          result.ocrHandoffSafetyCode,
          'ordered_sections_after_duplicate_input_paths_fallback',
        );
      }
    },
  );

  test(
    'stitch fallback reason codes normalize without leaking private text',
    () {
      final noisy = ReceiptStitchResult.fallback(
        inputPaths: const ['/tmp/top.jpg', '/tmp/bottom.jpg'],
        warning: 'Fallback for test.',
        fallbackReasonCode: ' OVERLAP confidence LOW ',
      );
      final privateLooking = ReceiptStitchResult.fallback(
        inputPaths: const ['/tmp/top.jpg', '/tmp/bottom.jpg'],
        warning: 'Fallback for test.',
        fallbackReasonCode: 'merchant total 42.18 private line text',
      );
      final duplicateSection = ReceiptStitchResult.fallback(
        inputPaths: const ['/tmp/top.jpg', '/tmp/bottom.jpg'],
        warning: 'Fallback for test.',
        fallbackReasonCode: ' duplicate section image ',
      );

      expect(noisy.diagnosticReasonLabel, 'overlap_confidence_low');
      expect(
        noisy.ocrHandoffSafetyCode,
        'ordered_sections_after_overlap_confidence_low_fallback',
      );
      expect(duplicateSection.diagnosticReasonLabel, 'duplicate_section_image');
      expect(
        duplicateSection.ocrHandoffSafetyCode,
        'ordered_sections_after_duplicate_section_image_fallback',
      );
      expect(privateLooking.diagnosticReasonLabel, 'unknown');
      expect(
        privateLooking.privacySafeOcrHandoffSafety.toString(),
        isNot(contains('merchant total')),
      );
      expect(
        privateLooking.ocrHandoffSafetyCode,
        'ordered_sections_after_unknown_fallback',
      );
    },
  );

  test('stitch result can be rebound to final OCR artifact paths', () {
    final preview = ReceiptStitchResult(
      status: ReceiptStitchStatus.stitched,
      inputPaths: ['/tmp/raw_a.jpg', '/tmp/raw_b.jpg'],
      ocrSourcePaths: ['/tmp/preview_stitched.jpg'],
      stitchedPath: '/tmp/preview_stitched.jpg',
      confidence: .91,
      overlapPixels: [244],
      stitchedWidth: 900,
      stitchedHeight: 2100,
      pairs: [
        ReceiptStitchPairResult(
          pairIndex: 0,
          overlapPixels: 244,
          confidence: .91,
        ),
      ],
    );

    final finalResult = preview.copyForFinalOcr(
      inputPaths: const ['/tmp/prepared_a.jpg', '/tmp/prepared_b.jpg'],
      ocrSourcePaths: const ['/tmp/final_stitched.jpg'],
      stitchedPath: '/tmp/final_stitched.jpg',
    );

    expect(finalResult.didStitch, isTrue);
    expect(finalResult.inputPaths, [
      '/tmp/prepared_a.jpg',
      '/tmp/prepared_b.jpg',
    ]);
    expect(finalResult.ocrSourcePaths, ['/tmp/final_stitched.jpg']);
    expect(finalResult.stitchedPath, '/tmp/final_stitched.jpg');
    expect(finalResult.stitchedSizeLabel, '900 x 2100');
    expect(finalResult.pairs.single.summaryLabel, contains('91%'));
  });

  test(
    'copies a verified stitch preview into a durable OCR artifact',
    () async {
      final source = await writeTempReceiptStitchingImage(
        receiptStitchingSection(seed: 22, topTextOffset: 0),
        'copy_source',
      );

      final copy = await ReceiptImageProcessor.copyReceiptOcrArtifact(
        path: source.path,
        prefix: 'copy_test',
      );

      expect(copy, isNot(source.path));
      expect(await File(copy).exists(), isTrue);
      expect(await File(copy).length(), await source.length());
      await File(copy).delete();
    },
  );
}
