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
        result.receiptProofStoragePolicyCounts,
        containsPair('saved_proof_kept_for_receipt_record', 1),
      );
      expect(
        result.receiptProofStoragePolicyCounts,
        containsPair('ocr_source_used_for_reading_before_saved_proof', 1),
      );
      expect(
        result.receiptProofStoragePolicyCounts,
        isNot(contains('temporary_ocr_source_separate_from_saved_proof')),
      );
      expect(
        result.receiptProofStoragePolicyCounts,
        isNot(contains('accepted_review_allows_temporary_ocr_cleanup')),
      );
      expect(result.receiptProofStoragePolicyOutcome, 'saved_proof_storage_ready');
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

    test('marks imported receipt photos as imported clear source before proof', () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/imported-proof-top.jpg'],
        ocrSourcePhotoPaths: const ['/tmp/imported-proof-top.jpg'],
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        stitchResult: ReceiptStitchResult.notNeeded([
          '/tmp/imported-proof-top.jpg',
        ]),
        captureDiagnosticsByPhotoPath: const {
          '/tmp/imported-proof-top.jpg': {
            'captureFlow': 'existing_receipt_photo_import',
            'existingPhotoImportUsed': true,
            'existingPhotoImportRole': 'user_selected_receipt_photo',
          },
        },
      );

      expect(
        result.ocrSourceFirstDecisionCode,
        'imported_receipt_source_before_saved_proof',
      );
      expect(result.ocrSourceProofRelationship, 'imported_clear_source');
      expect(result.usesImportedReceiptPhotoSource, isTrue);
      expect(result.ocrReadsClearSourceBeforeSavedProof, isTrue);
      expect(
        result.ocrSourceFirstReviewCue,
        contains('imported receipt photo source before the smaller saved proof copy'),
      );
      expect(
        result.privacySafeOcrSourceFirstSummary,
        containsPair(
          'ocrSourceFirstDecisionCode',
          'imported_receipt_source_before_saved_proof',
        ),
      );
      expect(result.ocrSourceFirstOutcome, 'imported_source_ready');
      expect(
        result.ocrSourceFirstActionLabel,
        'OCR reads the imported receipt photo source before saved proof',
      );
      expect(
        result.privacySafeOcrSourceFirstSummary,
        containsPair('ocrSourceProofRelationship', 'imported_clear_source'),
      );
      expect(
        result.privacySafeOcrSourceFirstSummary,
        containsPair('ocrSourceFirstOutcome', 'imported_source_ready'),
      );
    });

    test('marks stitched combined OCR source separately from generic copies', () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/proof-top.jpg', '/tmp/proof-bottom.jpg'],
        ocrSourcePhotoPaths: const ['/tmp/receipt-stitched.jpg'],
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        stitchResult: ReceiptStitchResult(
          status: ReceiptStitchStatus.stitched,
          inputPaths: ['/tmp/ocr-top.jpg', '/tmp/ocr-bottom.jpg'],
          ocrSourcePaths: ['/tmp/receipt-stitched.jpg'],
          stitchedPath: '/tmp/receipt-stitched.jpg',
        ),
      );

      expect(
        result.ocrSourceFirstDecisionCode,
        'combined_receipt_source_before_saved_proof',
      );
      expect(result.ocrSourceFirstOutcome, 'combined_source_ready');
      expect(
        result.ocrSourceFirstReviewCue,
        contains('one combined stitched receipt source before the smaller saved proof copy'),
      );
      expect(
        result.ocrSourceFirstActionLabel,
        'OCR reads one combined stitched source before saved proof',
      );
      expect(result.ocrSourceProofRelationship, 'combined_clear_source');
      expect(result.usesSeparateOcrSourceCopies, isTrue);
      expect(result.ocrReadsClearSourceBeforeSavedProof, isTrue);
      expect(
        result.privacySafeOcrSourceFirstSummary,
        containsPair(
          'ocrSourceProofRelationship',
          'combined_clear_source',
        ),
      );
      expect(
        result.privacySafeOcrSourceFirstSummary,
        containsPair(
          'ocrSourceFirstDecisionCode',
          'combined_receipt_source_before_saved_proof',
        ),
      );
      expect(
        result.privacySafeOcrSourceFirstSummary,
        containsPair('ocrSourceFirstOutcome', 'combined_source_ready'),
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

    test('keeps original proof while tracking separate OCR source cleanup', () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/original-proof.jpg'],
        ocrSourcePhotoPaths: const ['/tmp/ocr-cleanup-copy.jpg'],
        dataSaverLevel: ReceiptDataSaverLevel.original,
        stitchResult: ReceiptStitchResult.notNeeded([
          '/tmp/ocr-cleanup-copy.jpg',
        ]),
        preparationDiagnosticsByOcrPath: const {
          '/tmp/ocr-cleanup-copy.jpg': {
            'ocrStoragePolicyCode': 'ocr_clear_source_before_saved_proof_copy',
            'ocrUsesPreparedSourceBeforeSavedProof': true,
            'ocrUsesSavedProofFallback': false,
          },
        },
      );

      expect(result.ocrSourceProofRelationship, 'separate_clear_source');
      expect(result.usesSeparateOcrSourceCopies, isTrue);
      expect(result.ocrReadsClearSourceBeforeSavedProof, isTrue);
      expect(
        result.receiptProofStoragePolicyCounts,
        containsPair('saved_proof_kept_for_receipt_record', 1),
      );
      expect(
        result.receiptProofStoragePolicyCounts,
        containsPair('temporary_ocr_source_separate_from_saved_proof', 1),
      );
      expect(
        result.receiptProofStoragePolicyCounts,
        containsPair('normal_record_keeps_original_quality_proof', 1),
      );
      expect(
        result.receiptProofStoragePolicyCounts,
        containsPair('accepted_review_allows_temporary_ocr_cleanup', 1),
      );
      expect(
        result.receiptProofStoragePolicyOutcome,
        'temporary_ocr_source_original_quality_proof',
      );
      expect(
        result.privacySafeReceiptReaderHandoffMetadata,
        containsPair(
          'receiptProofStoragePolicyOutcome',
          'temporary_ocr_source_original_quality_proof',
        ),
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

  });
}
