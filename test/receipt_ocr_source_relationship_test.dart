import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  group('OCR source proof relationship', () {
    test('marks accepted proof reused as the same source, not fallback', () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/accepted-receipt.jpg'],
        ocrSourcePhotoPaths: const ['/tmp/accepted-receipt.jpg'],
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        stitchResult: ReceiptStitchResult.notNeeded([
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
        stitchResult: ReceiptStitchResult.notNeeded(['/tmp/saved-proof.jpg']),
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
        stitchResult: ReceiptStitchResult.notNeeded(['/tmp/ocr-clear.jpg']),
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

    test('keeps compressed saved proof separate from clear OCR source', () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/saved-proof-750kb.jpg'],
        ocrSourcePhotoPaths: const ['/tmp/ocr-full-quality-source.jpg'],
        dataSaverLevel: ReceiptDataSaverLevel.maximum,
        stitchResult: ReceiptStitchResult.notNeeded([
          '/tmp/ocr-full-quality-source.jpg',
        ]),
        preparationDiagnosticsByOcrPath: const {
          '/tmp/ocr-full-quality-source.jpg': {
            'ocrStoragePolicyCode': 'ocr_clear_source_before_saved_proof_copy',
            'ocrUsesPreparedSourceBeforeSavedProof': true,
            'ocrUsesSavedProofFallback': false,
          },
        },
      );

      expect(result.ocrSourceProofRelationship, 'separate_clear_source');
      expect(result.usesSeparateOcrSourceCopies, isTrue);
      expect(result.ocrReadsClearSourceBeforeSavedProof, isTrue);
      expect(result.ocrUsesSavedProofOnlyAsFallback, isFalse);
      expect(
        result.ocrStoragePolicyOutcome,
        'ocr_clear_source_before_saved_proof_copy',
      );
      expect(
        result.receiptProofStoragePolicyOutcome,
        'temporary_ocr_source_saved_data_saver_proof',
      );
      expect(
        result.ocrSourceReviewRequirement,
        'standard_user_confirmation_required',
      );
      expect(
        result.receiptProofStoragePolicyCounts,
        containsPair('saved_proof_kept_for_receipt_record', 1),
      );
      expect(
        result.receiptProofStoragePolicyCounts,
        containsPair('ocr_source_used_for_reading_before_saved_proof', 1),
      );
      expect(
        result.receiptProofStoragePolicyCounts,
        containsPair('temporary_ocr_source_separate_from_saved_proof', 1),
      );
      expect(
        result.receiptProofStoragePolicyCounts,
        containsPair('clear_ocr_source_read_before_saved_proof_copy', 1),
      );
      expect(
        result.receiptProofStoragePolicyCounts,
        containsPair('normal_record_uses_data_saver_proof', 1),
      );
      expect(
        result.receiptProofStoragePolicyCounts,
        containsPair('accepted_review_allows_temporary_ocr_cleanup', 1),
      );
      expect(
        result.privacySafeReceiptReaderHandoffMetadata,
        isNot(containsValue(contains('/tmp/'))),
      );
    });

    test('kept-for-later reviews do not create OCR source cleanup', () {
      final result = ReceiptPhotoReviewResult.keptForLater(
        photoPaths: const ['/tmp/saved-proof-750kb.jpg'],
        dataSaverLevel: ReceiptDataSaverLevel.maximum,
      );

      expect(result.keptForLater, isTrue);
      expect(result.ocrSourcePhotoPaths, isEmpty);
      expect(result.hasOcrSourcePhotos, isFalse);
      expect(result.ocrSourceProofRelationship, 'missing_ocr_source');
      expect(
        result.ocrSourceFirstDecisionCode,
        'ocr_source_missing_block_review',
      );
      expect(result.ocrReadsClearSourceBeforeSavedProof, isFalse);
      expect(result.ocrUsesSavedProofOnlyAsFallback, isFalse);
      expect(
        result.receiptProofStoragePolicyCounts,
        containsPair('saved_proof_kept_for_receipt_record', 1),
      );
      expect(
        result.receiptProofStoragePolicyCounts,
        containsPair('normal_record_uses_data_saver_proof', 1),
      );
      expect(
        result.receiptProofStoragePolicyCounts,
        containsPair('review_kept_for_later_no_cleanup_yet', 1),
      );
      expect(
        result.receiptProofStoragePolicyCounts,
        isNot(contains('accepted_review_allows_temporary_ocr_cleanup')),
      );
      expect(
        result.privacySafeReceiptReaderHandoffMetadata,
        containsPair('receiptReviewKeptForLater', true),
      );
    });

    test('marks invalid stitch OCR contract as manual review risk', () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/top.jpg', '/tmp/bottom.jpg'],
        ocrSourcePhotoPaths: const ['/tmp/stitched-wrong.jpg'],
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        stitchResult: ReceiptStitchResult(
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

    test('marks result and stitch OCR source disagreement for review', () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/top.jpg', '/tmp/bottom.jpg'],
        ocrSourcePhotoPaths: const ['/tmp/review-result-source.jpg'],
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        stitchResult: ReceiptStitchResult(
          status: ReceiptStitchStatus.stitched,
          inputPaths: ['/tmp/top.jpg', '/tmp/bottom.jpg'],
          ocrSourcePaths: ['/tmp/stitched-ready.jpg'],
          stitchedPath: '/tmp/stitched-ready.jpg',
        ),
      );

      expect(result.stitchResult.hasValidOcrSourceContract, isTrue);
      expect(result.ocrSourcePathsMatchStitchContract, isFalse);
      expect(
        result.ocrSourceReviewRiskCode,
        'stitch_ocr_source_contract_review_required',
      );
      expect(
        result.privacySafeOcrSourceFirstSummary,
        containsPair('ocrSourcePathsMatchStitchContract', false),
      );
      expect(result.acceptedPhotoHandoffOutcome, 'needs_review_before_ocr');
      expect(
        result.receiptPhotoReviewHandoffPath,
        'accepted_stitch_ocr_source_review_required',
      );
      expect(
        result.receiptPhotoReviewHandoffPathLabel,
        'Accepted photo review, but stitch/OCR source handoff needs review.',
      );
      expect(
        result.acceptedPhotoHandoffRoute,
        'photo_review_ocr_source_review_required',
      );
      expect(
        result.acceptedPhotoHandoffNextScreen,
        'receipt_photo_ocr_source_review',
      );
      expect(result.acceptedPhotoHandoffMustOpenReceiptDetails, isFalse);
      expect(result.acceptedPhotoHandoffMustOpenFilledReview, isFalse);
      expect(
        result.acceptedPhotoHandoffUserAction,
        'review_ocr_source_handoff',
      );
      expect(
        result.receiptReaderHandoffCounts,
        containsPair(
          'ocr_source_review_requirement_manual_review_required_before_saving_receipt',
          1,
        ),
      );
    });

    test('marks sanitized OCR source input as review risk', () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/top.jpg', '/tmp/bottom.jpg'],
        ocrSourcePhotoPaths: const [
          '/tmp/top.jpg',
          '/tmp/top.jpg',
          '/tmp/bottom.jpg',
        ],
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        stitchResult: ReceiptStitchResult.notNeeded([
          '/tmp/top.jpg',
          '/tmp/bottom.jpg',
        ]),
      );

      expect(result.ocrSourcePhotoPaths, ['/tmp/top.jpg', '/tmp/bottom.jpg']);
      expect(result.photoPathInputWasSanitized, isFalse);
      expect(result.ocrSourcePathInputWasSanitized, isTrue);
      expect(result.ocrSourcePathsMatchStitchContract, isTrue);
      expect(
        result.ocrSourceReviewRiskCode,
        'receipt_source_path_input_sanitized_review_required',
      );
      expect(
        result.ocrSourceReviewRequirement,
        'manual_review_required_before_saving_receipt',
      );
      expect(
        result.privacySafeOcrSourceFirstSummary,
        containsPair('ocrSourcePathInputWasSanitized', true),
      );
      expect(
        result.receiptReaderHandoffCounts,
        containsPair(
          'ocr_source_review_risk_receipt_source_path_input_sanitized_review_required',
          1,
        ),
      );
    });

    test('marks sanitized saved proof input as review risk', () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/top.jpg', '/tmp/top.jpg'],
        ocrSourcePhotoPaths: const ['/tmp/top.jpg'],
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        stitchResult: ReceiptStitchResult.notNeeded(['/tmp/top.jpg']),
      );

      expect(result.photoPaths, ['/tmp/top.jpg']);
      expect(result.photoPathInputWasSanitized, isTrue);
      expect(result.ocrSourcePathInputWasSanitized, isFalse);
      expect(
        result.ocrSourceReviewRiskCode,
        'receipt_source_path_input_sanitized_review_required',
      );
      expect(
        result.privacySafeOcrSourceFirstSummary,
        containsPair('photoPathInputWasSanitized', true),
      );
    });

    test('marks fallback-disabled missing OCR source as not ready', () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/proof-only.jpg'],
        ocrSourcePhotoPaths: const [],
        dataSaverLevel: ReceiptDataSaverLevel.maximum,
        stitchResult: ReceiptStitchResult.notNeeded(['/tmp/proof-only.jpg']),
        allowSavedProofOcrFallback: false,
      );

      expect(result.hasOcrSourcePhotos, isFalse);
      expect(result.ocrSourcePathsMatchStitchContract, isFalse);
      expect(
        result.ocrSourceReviewRiskCode,
        'ocr_source_missing_manual_entry_required',
      );
      expect(
        result.ocrSourceReviewRequirement,
        'manual_review_required_before_saving_receipt',
      );
      expect(
        result.privacySafeOcrSourceFirstSummary,
        containsPair('ocrSourcePathsMatchStitchContract', false),
      );
    });

    test('marks no receipt photos as blocked before OCR source handoff', () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const [],
        ocrSourcePhotoPaths: const [],
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        stitchResult: ReceiptStitchResult.fallback(
          inputPaths: [],
          warning: 'No receipt photos available.',
          fallbackReasonCode: 'no_input_paths',
        ),
      );

      expect(result.hasOcrSourcePhotos, isFalse);
      expect(result.stitchResult.hasNoInputPaths, isTrue);
      expect(
        result.stitchResult.ocrSourceContractCode,
        'fallback_no_ocr_sources',
      );
      expect(result.stitchResult.hasValidOcrSourceContract, isFalse);
      expect(result.ocrSourcePathsMatchStitchContract, isFalse);
      expect(
        result.ocrSourceReviewRiskCode,
        'ocr_source_missing_manual_entry_required',
      );
      expect(
        result.ocrSourceReviewRequirement,
        'manual_review_required_before_saving_receipt',
      );
      expect(
        result.ocrSourceFirstDecisionCode,
        'ocr_source_missing_block_review',
      );
      expect(result.ocrSourceProofRelationship, 'missing_ocr_source');
      expect(
        result.privacySafeOcrSourceFirstSummary,
        containsPair('ocrSourceCount', 0),
      );
      expect(
        result.receiptReaderHandoffCounts,
        containsPair('ocr_source_missing', 1),
      );
      expect(
        result.receiptReaderHandoffCounts,
        containsPair('stitch_ocr_source_contract_fallback_no_ocr_sources', 1),
      );
      expect(
        result.stitchResult.privacySafeOcrHandoffSafety,
        containsPair(
          'stitchOcrHandoffSafetyCode',
          'no_receipt_photo_available',
        ),
      );
    });
  });
}
