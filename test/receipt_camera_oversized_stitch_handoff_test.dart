import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test(
    'oversized stitch fallback keeps long receipt ordered and review blocked',
    () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const [
          '/tmp/section-1-proof.jpg',
          '/tmp/section-2-proof.jpg',
          '/tmp/section-3-proof.jpg',
          '/tmp/section-4-proof.jpg',
          '/tmp/section-5-proof.jpg',
        ],
        ocrSourcePhotoPaths: const [
          '/tmp/section-1-ocr.jpg',
          '/tmp/section-2-ocr.jpg',
          '/tmp/section-3-ocr.jpg',
          '/tmp/section-4-ocr.jpg',
          '/tmp/section-5-ocr.jpg',
        ],
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        stitchResult: ReceiptStitchResult.fallback(
          inputPaths: [
            '/tmp/section-1-ocr.jpg',
            '/tmp/section-2-ocr.jpg',
            '/tmp/section-3-ocr.jpg',
            '/tmp/section-4-ocr.jpg',
            '/tmp/section-5-ocr.jpg',
          ],
          warning: 'Receipt is too long to stitch safely on this device.',
          fallbackReasonCode: 'output_too_large',
          stitchedWidth: 1200,
          stitchedHeight: 21000,
        ),
      );

      expect(
        result.receiptPhotoReviewHandoffPath,
        'accepted_stitch_ocr_source_review_required',
      );
      expect(result.nextReviewUsesOrderedSections, isTrue);
      expect(
        result.nextReviewMatchReadinessOutcome,
        'ocr_source_review_required_before_assist',
      );
      expect(
        result.stitchResult.reviewPathLabel,
        '5 receipt sections top to bottom',
      );
      expect(
        result.stitchResult.ocrSourceContractCode,
        'fallback_derived_stitch_too_large',
      );
      expect(
        result.receiptReaderHandoffCounts,
        containsPair(
          'stitch_ocr_source_contract_fallback_derived_stitch_too_large',
          1,
        ),
      );
      expect(
        result.privacySafeReceiptReaderHandoffMetadata,
        containsPair('stitchFallbackReasonCode', 'output_too_large'),
      );
    },
  );
}
