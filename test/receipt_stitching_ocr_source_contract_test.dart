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
        review.privacySafeReceiptReaderHandoffMetadata,
        containsPair('stitchFailedPairLabel', 'Photo 2 to 3'),
      );
      expect(
        review.privacySafeReceiptReaderHandoffMetadata.toString(),
        isNot(contains('/private/')),
      );
    },
  );
}
