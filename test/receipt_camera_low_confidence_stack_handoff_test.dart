import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_flow.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test(
    'multi-pair low-confidence stitch stays blocked before receipt assist',
    () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const [
          '/tmp/section-1-proof.jpg',
          '/tmp/section-2-proof.jpg',
          '/tmp/section-3-proof.jpg',
        ],
        ocrSourcePhotoPaths: const ['/tmp/stitched-review-required.jpg'],
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        stitchResult: ReceiptStitchResult(
          status: ReceiptStitchStatus.stitched,
          inputPaths: const [
            '/tmp/section-1-ocr.jpg',
            '/tmp/section-2-ocr.jpg',
            '/tmp/section-3-ocr.jpg',
          ],
          ocrSourcePaths: const ['/tmp/stitched-review-required.jpg'],
          stitchedPath: '/tmp/stitched-review-required.jpg',
          confidence: .56,
          overlapPixels: const [328, 352],
          pairs: const [
            ReceiptStitchPairResult(
              pairIndex: 0,
              overlapPixels: 328,
              confidence: .82,
            ),
            ReceiptStitchPairResult(
              pairIndex: 1,
              overlapPixels: 352,
              confidence: .56,
            ),
          ],
        ),
      );

      expect(result.nextReviewUsesOrderedSections, isFalse);
      expect(
        result.nextReviewMatchReadinessOutcome,
        'ocr_source_review_required_before_assist',
      );
      expect(
        result.stitchResult.assistedReadinessCode,
        'stitched_overlap_review_required',
      );
      expect(result.stitchResult.reviewFocusPairLabel, 'Photo 2 to 3');
      expect(
        result.receiptPhotoReviewHandoffPath,
        'accepted_stitch_ocr_source_review_required',
      );
      expect(
        result.privacySafeReceiptReaderHandoffMetadata,
        containsPair('stitchReviewFocusPairLabel', 'Photo 2 to 3'),
      );

      final attachment = ReceiptCaptureFlow.attachmentsFromReviewResult(
        result,
        ReceiptCaptureFlowModule.expenses,
      ).single;
      expect(
        attachment.documentSignals,
        contains('stitch_review_focus_pair_photo_2_to_3'),
      );
      expect(
        attachment.riskFlags,
        contains('ocr_source_stitch_review_focus_pair_photo_2_to_3'),
      );
    },
  );
}
