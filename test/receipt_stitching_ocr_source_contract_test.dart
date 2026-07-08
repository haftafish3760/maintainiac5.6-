import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test('final OCR handoff preserves stitch pair evidence path-free', () {
    final preview = ReceiptStitchResult(
      status: ReceiptStitchStatus.stitched,
      inputPaths: const ['/tmp/raw-top.jpg', '/tmp/raw-bottom.jpg'],
      ocrSourcePaths: const ['/tmp/preview-stitch.jpg'],
      stitchedPath: '/tmp/preview-stitch.jpg',
      confidence: .81,
      overlapPixels: const [276],
      pairs: const [
        ReceiptStitchPairResult(
          pairIndex: 0,
          overlapPixels: 276,
          confidence: .81,
          horizontalOffsetPixels: 28,
        ),
      ],
      stitchedWidth: 900,
      stitchedHeight: 2724,
    );

    final finalResult = preview.copyForFinalOcr(
      inputPaths: const [
        '/private/original-top.jpg',
        '/private/original-bottom.jpg',
      ],
      ocrSourcePaths: const ['/private/final-stitch.jpg'],
      stitchedPath: '/private/final-stitch.jpg',
    );
    final review = ReceiptPhotoReviewResult(
      photoPaths: const ['/private/proof-top.jpg', '/private/proof-bottom.jpg'],
      ocrSourcePhotoPaths: finalResult.ocrSourcePaths,
      stitchResult: finalResult,
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
    );

    expect(finalResult.ocrSourceContractCode, 'stitched_ocr_source_ready');
    expect(finalResult.sourcePreservationCode, contains('preserved'));
    expect(finalResult.pairs.single.diagnosticCode, 'drift_adjusted');
    expect(finalResult.overlapPixels, [276]);
    expect(
      review.privacySafeReceiptReaderHandoffMetadata,
      containsPair('stitchPairSafetySummaries', [
        {
          'startSectionNumber': 1,
          'endSectionNumber': 2,
          'overlapPixels': 276,
          'confidencePercent': 81,
          'usedManualAdjustment': false,
          'diagnosticCode': 'drift_adjusted',
        },
      ]),
    );
    expect(
      review.privacySafeReceiptReaderHandoffMetadata.toString(),
      isNot(contains('/private/')),
    );
  });
  test('final stitched OCR handoff uses the stitched artifact path', () {
    final preview = ReceiptStitchResult(
      status: ReceiptStitchStatus.stitched,
      inputPaths: const ['/tmp/raw-top.jpg', '/tmp/raw-bottom.jpg'],
      ocrSourcePaths: const ['/tmp/preview-stitch.jpg'],
      stitchedPath: '/tmp/preview-stitch.jpg',
      confidence: .84,
      overlapPixels: const [288],
      pairs: const [
        ReceiptStitchPairResult(
          pairIndex: 0,
          overlapPixels: 288,
          confidence: .84,
        ),
      ],
      stitchedWidth: 900,
      stitchedHeight: 2700,
    );

    final finalResult = preview.copyForFinalOcr(
      inputPaths: const [
        '/private/original-top.jpg',
        '/private/original-bottom.jpg',
      ],
      ocrSourcePaths: const ['/private/wrong-ordered-section.jpg'],
      stitchedPath: '/private/final-stitch.jpg',
    );

    expect(finalResult.ocrSourcePaths, ['/private/final-stitch.jpg']);
    expect(finalResult.stitchedPath, '/private/final-stitch.jpg');
    expect(finalResult.ocrSourceContractCode, 'stitched_ocr_source_ready');
    expect(finalResult.usesDerivedCombinedOcrArtifact, isTrue);
  });

  test('final stitched OCR handoff prefers provided OCR source path', () {
    final preview = ReceiptStitchResult(
      status: ReceiptStitchStatus.stitched,
      inputPaths: const ['/tmp/raw-top.jpg', '/tmp/raw-bottom.jpg'],
      ocrSourcePaths: const ['/tmp/disposable-preview-stitch.jpg'],
      stitchedPath: '/tmp/disposable-preview-stitch.jpg',
      confidence: .86,
      overlapPixels: const [292],
      pairs: const [
        ReceiptStitchPairResult(
          pairIndex: 0,
          overlapPixels: 292,
          confidence: .86,
        ),
      ],
      stitchedWidth: 900,
      stitchedHeight: 2660,
    );

    final finalResult = preview.copyForFinalOcr(
      inputPaths: const [
        '/private/original-top.jpg',
        '/private/original-bottom.jpg',
      ],
      ocrSourcePaths: const ['/private/final-durable-stitch.jpg'],
    );

    expect(finalResult.ocrSourcePaths, ['/private/final-durable-stitch.jpg']);
    expect(finalResult.stitchedPath, '/private/final-durable-stitch.jpg');
    expect(
      finalResult.stitchedPath,
      isNot('/tmp/disposable-preview-stitch.jpg'),
    );
    expect(finalResult.ocrSourceContractCode, 'stitched_ocr_source_ready');
  });

  test('stitched OCR source cannot reuse an original section path', () {
    final aliasedStitch = ReceiptStitchResult(
      status: ReceiptStitchStatus.stitched,
      inputPaths: const ['/tmp/top.jpg', '/tmp/bottom.jpg'],
      ocrSourcePaths: const ['/tmp/top.jpg'],
      stitchedPath: '/tmp/top.jpg',
      confidence: .88,
      overlapPixels: const [280],
      pairs: const [
        ReceiptStitchPairResult(
          pairIndex: 0,
          overlapPixels: 280,
          confidence: .88,
        ),
      ],
    );

    expect(
      aliasedStitch.ocrSourceContractCode,
      'stitched_ocr_source_reuses_input_section',
    );
    expect(aliasedStitch.hasValidOcrSourceContract, isFalse);
    expect(aliasedStitch.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
    expect(
      aliasedStitch.assistedReadinessCode,
      'stitch_contract_review_required',
    );
    expect(
      aliasedStitch.privacySafeOcrHandoffSafety,
      containsPair(
        'stitchOcrSourceContractCode',
        'stitched_ocr_source_reuses_input_section',
      ),
    );
  });

  test('stitched OCR source rejects unnormalized source paths', () {
    final invalidInput = ReceiptStitchResult(
      status: ReceiptStitchStatus.stitched,
      inputPaths: const ['/tmp/top.jpg ', '/tmp/bottom.jpg'],
      ocrSourcePaths: const ['/tmp/stitched.jpg'],
      stitchedPath: '/tmp/stitched.jpg',
      confidence: .82,
      overlapPixels: const [260],
      pairs: const [
        ReceiptStitchPairResult(
          pairIndex: 0,
          overlapPixels: 260,
          confidence: .82,
        ),
      ],
    );
    final invalidOcrSource = ReceiptStitchResult(
      status: ReceiptStitchStatus.stitched,
      inputPaths: const ['/tmp/top.jpg', '/tmp/bottom.jpg'],
      ocrSourcePaths: const ['/tmp/stitched.jpg '],
      stitchedPath: '/tmp/stitched.jpg',
      confidence: .82,
      overlapPixels: const [260],
      pairs: const [
        ReceiptStitchPairResult(
          pairIndex: 0,
          overlapPixels: 260,
          confidence: .82,
        ),
      ],
    );

    expect(invalidInput.ocrSourceContractCode, 'invalid_input_sources');
    expect(invalidInput.hasValidOcrSourceContract, isFalse);
    expect(invalidInput.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
    expect(invalidOcrSource.ocrSourceContractCode, 'invalid_ocr_sources');
    expect(invalidOcrSource.hasValidOcrSourceContract, isFalse);
    expect(
      invalidOcrSource.assistedReadinessCode,
      'stitch_contract_review_required',
    );
  });

  test(
    'final OCR fallback preserves ordered separate source paths path-free',
    () {
      final preview = ReceiptStitchResult.fallback(
        inputPaths: const [
          '/tmp/top.jpg',
          '/tmp/middle.jpg',
          '/tmp/bottom.jpg',
        ],
        warning:
            'Receipt photos did not match clearly enough to stitch safely.',
        fallbackReasonCode: 'overlap_confidence_low',
        failedPairIndex: 1,
        pairs: const [
          ReceiptStitchPairResult(
            pairIndex: 0,
            overlapPixels: 284,
            confidence: .82,
          ),
          ReceiptStitchPairResult(
            pairIndex: 1,
            overlapPixels: 96,
            confidence: .31,
          ),
        ],
      );

      final finalResult = preview.copyForFinalOcr(
        inputPaths: const [
          '/private/top.jpg',
          '/private/middle.jpg',
          '/private/bottom.jpg',
        ],
        ocrSourcePaths: const [
          '/private/ocr-top.jpg',
          '/private/ocr-middle.jpg',
          '/private/ocr-bottom.jpg',
        ],
      );
      final review = ReceiptPhotoReviewResult(
        photoPaths: const [
          '/private/proof-top.jpg',
          '/private/proof-middle.jpg',
          '/private/proof-bottom.jpg',
        ],
        ocrSourcePhotoPaths: finalResult.ocrSourcePaths,
        stitchResult: finalResult,
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
      );

      expect(finalResult.usedFallback, isTrue);
      expect(finalResult.failedPairLabel, 'Photo 2 to 3');
      expect(finalResult.ocrSourcePaths, [
        '/private/ocr-top.jpg',
        '/private/ocr-middle.jpg',
        '/private/ocr-bottom.jpg',
      ]);
      expect(
        finalResult.ocrSourceContractCode,
        'fallback_overlap_untrusted_sources',
      );
      expect(finalResult.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
      expect(review.ocrSourcePathsMatchStitchContract, isTrue);
      expect(
        review.ocrSourceReviewRiskCode,
        'stitch_ocr_source_contract_review_required',
      );
      expect(
        review.ocrSourceReviewRequirement,
        'manual_review_required_before_saving_receipt',
      );
      expect(
        review.privacySafeReceiptReaderHandoffMetadata,
        containsPair('stitchFailedPairLabel', 'Photo 2 to 3'),
      );
      expect(
        review.privacySafeReceiptReaderHandoffMetadata.toString(),
        isNot(contains('/private/')),
      );
    },
  );

  test(
    'final OCR fallback rejects reordered separate source paths path-free',
    () {
      final preview = ReceiptStitchResult.fallback(
        inputPaths: const [
          '/tmp/top.jpg',
          '/tmp/middle.jpg',
          '/tmp/bottom.jpg',
        ],
        warning:
            'Receipt photos did not match clearly enough to stitch safely.',
        fallbackReasonCode: 'manual_overlap_unsafe',
        failedPairIndex: 1,
      );

      final finalResult = preview.copyForFinalOcr(
        inputPaths: const [
          '/private/top.jpg',
          '/private/middle.jpg',
          '/private/bottom.jpg',
        ],
        ocrSourcePaths: const [
          '/private/top.jpg',
          '/private/bottom.jpg',
          '/private/middle.jpg',
        ],
      );
      final review = ReceiptPhotoReviewResult(
        photoPaths: const [
          '/private/proof-top.jpg',
          '/private/proof-middle.jpg',
          '/private/proof-bottom.jpg',
        ],
        ocrSourcePhotoPaths: finalResult.ocrSourcePaths,
        stitchResult: finalResult,
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
      );

      expect(finalResult.usedFallback, isTrue);
      expect(finalResult.failedPairLabel, 'Photo 2 to 3');
      expect(
        finalResult.ocrSourceContractCode,
        'fallback_ordered_source_path_mismatch',
      );
      expect(finalResult.hasValidOcrSourceContract, isFalse);
      expect(finalResult.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
      expect(
        finalResult.assistedReadinessCode,
        'stitch_contract_review_required',
      );
      expect(review.ocrSourcePathsMatchStitchContract, isTrue);
      expect(
        review.ocrSourceReviewRiskCode,
        'stitch_ocr_source_contract_review_required',
      );
      expect(
        review.privacySafeReceiptReaderHandoffMetadata,
        containsPair(
          'stitchOcrSourceContractCode',
          'fallback_ordered_source_path_mismatch',
        ),
      );
      expect(
        review.privacySafeReceiptReaderHandoffMetadata.toString(),
        isNot(contains('/private/')),
      );
    },
  );

  test('final unreadable fallback blocks assisted OCR path-free', () {
    final preview = ReceiptStitchResult.fallback(
      inputPaths: const ['/tmp/top.jpg', '/tmp/unreadable.jpg'],
      warning: 'One receipt photo could not be read.',
      fallbackReasonCode: 'decode_failed',
    );

    final finalResult = preview.copyForFinalOcr(
      inputPaths: const ['/private/top.jpg', '/private/unreadable.jpg'],
      ocrSourcePaths: const [
        '/private/ocr-top.jpg',
        '/private/ocr-unreadable.jpg',
      ],
    );
    final review = ReceiptPhotoReviewResult(
      photoPaths: const ['/private/proof-top.jpg', '/private/proof-bad.jpg'],
      ocrSourcePhotoPaths: finalResult.ocrSourcePaths,
      stitchResult: finalResult,
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
    );

    expect(finalResult.usedFallback, isTrue);
    expect(
      finalResult.ocrSourceContractCode,
      'fallback_unreadable_input_source',
    );
    expect(finalResult.hasValidOcrSourceContract, isFalse);
    expect(finalResult.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
    expect(review.ocrSourcePathsMatchStitchContract, isFalse);
    expect(
      review.privacySafeReceiptReaderHandoffMetadata,
      containsPair(
        'stitchOcrSourceContractCode',
        'fallback_unreadable_input_source',
      ),
    );
    expect(
      review.privacySafeReceiptReaderHandoffMetadata.toString(),
      isNot(contains('/private/')),
    );
  });
}
