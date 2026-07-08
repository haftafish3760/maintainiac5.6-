import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test('stitch fallback metadata includes privacy-safe failed pair details', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const [
        '/private/top-proof.jpg',
        '/private/middle-proof.jpg',
        '/private/bottom-proof.jpg',
      ],
      ocrSourcePhotoPaths: const [
        '/private/top-ocr.jpg',
        '/private/middle-ocr.jpg',
        '/private/bottom-ocr.jpg',
      ],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.fallback(
        inputPaths: [
          '/private/top-ocr.jpg',
          '/private/middle-ocr.jpg',
          '/private/bottom-ocr.jpg',
        ],
        warning: 'Middle overlap was not trusted.',
        fallbackReasonCode: 'overlap_confidence_low',
        failedPairIndex: 1,
      ),
    );

    final metadata = result.privacySafeReceiptReaderHandoffMetadata;

    expect(metadata['stitchFallbackReasonCode'], 'overlap_confidence_low');
    expect(
      metadata['stitchFallbackReasonLabel'],
      'Overlap was not clear enough',
    );
    expect(metadata['stitchFailedPairLabel'], 'Photo 2 to 3');
    expect(metadata['stitchFailedPairStartSectionNumber'], 2);
    expect(metadata['stitchFailedPairEndSectionNumber'], 3);
    expect(
      metadata['nextReviewMatchReadinessLabel'],
      'Photo match needs review before app-assisted receipt filling, starting with Photo 2 to 3.',
    );
    expect(
      metadata['nextReviewMatchReadinessOutcome'],
      'ocr_source_review_required_before_assist',
    );
    expect(metadata['nextReviewRequiresOcrSourceReviewBeforeAssist'], true);
    expect(
      result
          .receiptReaderHandoffCounts['stitch_requires_ocr_source_review_before_assist'],
      1,
    );
    expect(metadata['stitchOverlapCoverageCode'], 'fallback_pair_2_to_3');
    expect(metadata['stitchSourcePreservationCode'], contains('preserved'));
    expect(metadata['stitchInputSourceCount'], 3);
    expect(metadata['stitchOcrSourceCount'], 3);
    expect(metadata.toString(), isNot(contains('/private/')));
    expect(metadata.toString(), isNot(contains('top-ocr')));
    expect(metadata.toString(), isNot(contains('bottom-proof')));
  });

  test('stitch fallback metadata keeps pair summaries path-free', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/private/top-proof.jpg', '/private/bottom-proof.jpg'],
      ocrSourcePhotoPaths: const [
        '/private/top-ocr.jpg',
        '/private/bottom-ocr.jpg',
      ],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.fallback(
        inputPaths: ['/private/top-ocr.jpg', '/private/bottom-ocr.jpg'],
        warning: 'Overlap was not trusted.',
        fallbackReasonCode: 'overlap_confidence_low',
        failedPairIndex: 0,
        pairs: const [
          ReceiptStitchPairResult(
            pairIndex: 0,
            overlapPixels: 214,
            confidence: .46,
          ),
        ],
      ),
    );

    final metadata = result.privacySafeReceiptReaderHandoffMetadata;

    expect(
      metadata,
      containsPair('stitchPairSafetySummaries', [
        {
          'startSectionNumber': 1,
          'endSectionNumber': 2,
          'overlapPixels': 214,
          'confidencePercent': 46,
          'usedManualAdjustment': false,
          'diagnosticCode': 'overlap_matched',
        },
      ]),
    );
    expect(metadata['stitchFallbackReasonCode'], 'overlap_confidence_low');
    expect(metadata.toString(), isNot(contains('/private/')));
    expect(metadata.toString(), isNot(contains('top-proof')));
    expect(metadata.toString(), isNot(contains('bottom-ocr')));
  });

  test('oversized stitch fallback keeps failed pair metadata path-free', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const [
        '/private/proof-top.jpg',
        '/private/proof-middle.jpg',
        '/private/proof-bottom.jpg',
      ],
      ocrSourcePhotoPaths: const [
        '/private/ocr-top.jpg',
        '/private/ocr-middle.jpg',
        '/private/ocr-bottom.jpg',
      ],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.fallback(
        inputPaths: [
          '/private/ocr-top.jpg',
          '/private/ocr-middle.jpg',
          '/private/ocr-bottom.jpg',
        ],
        warning: 'Receipt is too long to stitch safely on this device.',
        fallbackReasonCode: 'output_too_large',
        failedPairIndex: 1,
        stitchedWidth: 1200,
        stitchedHeight: 22000,
        pairs: const [
          ReceiptStitchPairResult(
            pairIndex: 0,
            overlapPixels: 280,
            confidence: .82,
          ),
          ReceiptStitchPairResult(
            pairIndex: 1,
            overlapPixels: 260,
            confidence: .78,
          ),
        ],
      ),
    );

    final metadata = result.privacySafeReceiptReaderHandoffMetadata;

    expect(metadata['stitchFallbackReasonCode'], 'output_too_large');
    expect(metadata['stitchFailedPairLabel'], 'Photo 2 to 3');
    expect(metadata['stitchFailedPairStartSectionNumber'], 2);
    expect(metadata['stitchFailedPairEndSectionNumber'], 3);
    expect(metadata['stitchCandidateWidth'], 1200);
    expect(metadata['stitchCandidateHeight'], 22000);
    expect(metadata['stitchCandidatePixelCount'], 26400000);
    expect(
      metadata['nextReviewMatchReadinessOutcome'],
      'ocr_source_review_required_before_assist',
    );
    expect(
      result.receiptReaderHandoffCounts,
      containsPair('stitch_fallback_output_too_large', 1),
    );
    expect(
      result.receiptSectionOrderReviewActionCode,
      'review_multi_section_order',
    );
    expect(
      result.receiptReaderHandoffCounts,
      containsPair(
        'receipt_section_order_action_review_multi_section_order',
        1,
      ),
    );
    expect(
      result.receiptReaderHandoffCounts,
      containsPair('receipt_section_order_review_required', 1),
    );
    expect(metadata['receiptSectionOrderNeedsReview'], true);
    expect(result.acceptedPhotoHandoffOutcome, 'needs_review_before_ocr');
    expect(
      result.acceptedPhotoHandoffUserAction,
      'review_receipt_section_order',
    );
    expect(
      result.receiptReaderHandoffCounts,
      isNot(contains('receipt_section_order_action_review_single_section')),
    );
    expect(
      result.receiptReaderHandoffCounts,
      containsPair('stitch_requires_ocr_source_review_before_assist', 1),
    );
    expect(metadata.toString(), isNot(contains('/private/')));
    expect(metadata.toString(), isNot(contains('ocr-middle')));
    expect(metadata.toString(), isNot(contains('proof-bottom')));
  });

  test('stitch fallback reason count uses privacy-safe normalized code', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/private/proof-top.jpg', '/private/proof-bottom.jpg'],
      ocrSourcePhotoPaths: const [
        '/private/ocr-top.jpg',
        '/private/ocr-bottom.jpg',
      ],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.fallback(
        inputPaths: ['/private/ocr-top.jpg', '/private/ocr-bottom.jpg'],
        warning: 'Overlap was not trusted.',
        fallbackReasonCode: ' OVERLAP confidence LOW ',
        failedPairIndex: 0,
      ),
    );

    final counts = result.receiptReaderHandoffCounts;

    expect(counts, containsPair('stitch_fallback_overlap_confidence_low', 1));
    expect(
      counts.keys,
      isNot(contains('stitch_fallback_ OVERLAP confidence LOW ')),
    );
    expect(counts.keys.join('|'), isNot(contains('/private/')));
    expect(counts.keys.join('|'), isNot(contains('ocr-bottom')));
  });
}
