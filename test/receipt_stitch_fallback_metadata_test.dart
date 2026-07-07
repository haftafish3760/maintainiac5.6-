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
}
