import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  group('OCR source review risks', () {
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
      expect(
        result.acceptedPhotoHandoffActionLabel,
        'Check readability, then review receipt details and mark Business, Personal, or Mixed.',
      );
      expect(
        result.acceptedPhotoHandoffNextStepLabel,
        'Review the OCR source handoff before opening receipt details.',
      );
      expect(
        result.acceptedPhotoHandoffProcessingLabel,
        'Receipt details stay paused until the OCR source handoff is reviewed.',
      );
      expect(
        result.acceptedPhotoHandoffRouteResultLabel,
        'Receipt details can open only after the OCR source handoff is reviewed.',
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
      expect(
        result.acceptedPhotoHandoffRoute,
        'photo_review_ocr_source_missing_manual_entry_required',
      );
      expect(
        result.acceptedPhotoHandoffNextScreen,
        'receipt_photo_ocr_source_missing_manual_entry',
      );
      expect(
        result.acceptedPhotoHandoffUserAction,
        'add_clearer_photo_or_continue_manual_entry',
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
        result.acceptedPhotoHandoffActionLabel,
        'Add a clearer receipt photo, or continue by hand if app-assisted filling is not available.',
      );
      expect(
        result.acceptedPhotoHandoffNextStepLabel,
        'Add a clearer receipt photo before opening receipt details, or continue by hand without app-assisted filling.',
      );
      expect(
        result.acceptedPhotoHandoffRoute,
        'photo_review_ocr_source_missing_manual_entry_required',
      );
      expect(
        result.acceptedPhotoHandoffNextScreen,
        'receipt_photo_ocr_source_missing_manual_entry',
      );
      expect(
        result.acceptedPhotoHandoffUserAction,
        'add_clearer_photo_or_continue_manual_entry',
      );
      expect(
        result.stitchResult.privacySafeOcrHandoffSafety,
        containsPair(
          'stitchOcrHandoffSafetyCode',
          'no_receipt_photo_available',
        ),
      );
    });

    test(
      'marks duplicate receipt section fallback as OCR source review risk',
      () {
        final result = ReceiptPhotoReviewResult(
          photoPaths: const ['/tmp/proof-1.jpg', '/tmp/proof-2.jpg'],
          ocrSourcePhotoPaths: const ['/tmp/ocr-1.jpg', '/tmp/ocr-2.jpg'],
          dataSaverLevel: ReceiptDataSaverLevel.balanced,
          stitchResult: ReceiptStitchResult.fallback(
            inputPaths: ['/tmp/ocr-1.jpg', '/tmp/ocr-2.jpg'],
            warning: 'Duplicate receipt section detected.',
            fallbackReasonCode: 'duplicate_section_image',
            failedPairIndex: 0,
          ),
        );

        expect(
          result.stitchResult.ocrSourceContractCode,
          'fallback_duplicate_section_image',
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
            'stitch_ocr_source_contract_fallback_duplicate_section_image',
            1,
          ),
        );
        expect(
          result.privacySafeOcrSourceFirstSummary,
          containsPair('ocrSourcePathsMatchStitchContract', true),
        );
      },
    );
  });
}
