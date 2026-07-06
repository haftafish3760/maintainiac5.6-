import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  group('OCR source proof relationship', () {
    test('marks accepted proof reused as the same source, not fallback', () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/accepted-receipt.jpg'],
        ocrSourcePhotoPaths: const ['/tmp/accepted-receipt.jpg'],
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        stitchResult: const ReceiptStitchResult.notNeeded([
          '/tmp/accepted-receipt.jpg',
        ]),
      );

      expect(result.ocrSourceProofRelationship, 'same_accepted_source');
      expect(result.ocrSourceFirstOutcome, 'saved_source_matched_original');
      expect(result.ocrSourceReviewRiskCode, 'ocr_source_ready');
      expect(
        result.ocrSourceReviewRequirement,
        'standard_user_confirmation_required',
      );
      expect(result.ocrSourceFallbackRequiresManualReview, isFalse);
      expect(result.usedSavedProofAsOcrSourceFallback, isFalse);
      expect(result.ocrReadsClearSourceBeforeSavedProof, isTrue);
      expect(
        result.privacySafeOcrSourceFirstSummary,
        containsPair('ocrSourceProofRelationship', 'same_accepted_source'),
      );
    });

    test('marks missing OCR paths as saved proof fallback review risk', () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/saved-proof.jpg'],
        ocrSourcePhotoPaths: const [],
        dataSaverLevel: ReceiptDataSaverLevel.maximum,
        stitchResult: const ReceiptStitchResult.notNeeded([
          '/tmp/saved-proof.jpg',
        ]),
      );

      expect(result.ocrSourcePhotoPaths, ['/tmp/saved-proof.jpg']);
      expect(result.ocrSourceProofRelationship, 'saved_proof_fallback');
      expect(
        result.ocrSourceFirstDecisionCode,
        'saved_proof_fallback_review_required',
      );
      expect(
        result.ocrSourceReviewRiskCode,
        'saved_proof_ocr_fallback_review_required',
      );
      expect(
        result.ocrSourceReviewRequirement,
        'manual_review_required_before_saving_receipt',
      );
      expect(result.ocrSourceFallbackRequiresManualReview, isTrue);
      expect(
        result.receiptReaderHandoffCounts,
        containsPair(
          'ocr_source_review_risk_saved_proof_ocr_fallback_review_required',
          1,
        ),
      );
      expect(result.ocrReadsClearSourceBeforeSavedProof, isFalse);
      expect(
        result.privacySafeOcrSourceFirstSummary,
        containsPair('ocrSourceProofRelationship', 'saved_proof_fallback'),
      );
      expect(
        result.privacySafeOcrSourceFirstSummary,
        containsPair(
          'ocrSourceReviewRequirement',
          'manual_review_required_before_saving_receipt',
        ),
      );
    });

    test('marks separate OCR copies as clear source before proof', () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/saved-proof.jpg'],
        ocrSourcePhotoPaths: const ['/tmp/ocr-clear.jpg'],
        dataSaverLevel: ReceiptDataSaverLevel.strong,
        stitchResult: const ReceiptStitchResult.notNeeded([
          '/tmp/ocr-clear.jpg',
        ]),
      );

      expect(result.ocrSourceProofRelationship, 'separate_clear_source');
      expect(result.usesSeparateOcrSourceCopies, isTrue);
      expect(result.ocrSourceReviewRiskCode, 'ocr_source_ready');
      expect(result.ocrSourceFallbackRequiresManualReview, isFalse);
      expect(result.ocrReadsClearSourceBeforeSavedProof, isTrue);
      expect(
        result.privacySafeOcrSourceFirstSummary,
        containsPair('ocrSourceProofRelationship', 'separate_clear_source'),
      );
    });

    test('marks invalid stitch OCR contract as manual review risk', () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/top.jpg', '/tmp/bottom.jpg'],
        ocrSourcePhotoPaths: const ['/tmp/stitched-wrong.jpg'],
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        stitchResult: const ReceiptStitchResult(
          status: ReceiptStitchStatus.stitched,
          inputPaths: ['/tmp/top.jpg', '/tmp/bottom.jpg'],
          ocrSourcePaths: ['/tmp/stitched-wrong.jpg'],
          stitchedPath: '/tmp/stitched-ready.jpg',
        ),
      );

      expect(
        result.stitchResult.ocrSourceContractCode,
        'stitched_ocr_source_path_mismatch',
      );
      expect(result.stitchResult.hasValidOcrSourceContract, isFalse);
      expect(
        result.ocrSourceReviewRiskCode,
        'stitch_ocr_source_contract_review_required',
      );
      expect(
        result.ocrSourceReviewRequirement,
        'manual_review_required_before_saving_receipt',
      );
      expect(
        result.receiptReaderHandoffCounts,
        containsPair(
          'ocr_source_review_risk_stitch_ocr_source_contract_review_required',
          1,
        ),
      );
    });
  });
}
