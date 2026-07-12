import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test(
    'photo review result falls back to saved proof paths if OCR paths are missing',
    () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/proof-top.jpg', '/tmp/proof-bottom.jpg'],
        ocrSourcePhotoPaths: const [],
        dataSaverLevel: ReceiptDataSaverLevel.strong,
        stitchResult: ReceiptStitchResult.notNeeded([
          '/tmp/proof-top.jpg',
          '/tmp/proof-bottom.jpg',
        ]),
      );

      expect(result.photoPaths, [
        '/tmp/proof-top.jpg',
        '/tmp/proof-bottom.jpg',
      ]);
      expect(result.ocrSourcePhotoPaths, [
        '/tmp/proof-top.jpg',
        '/tmp/proof-bottom.jpg',
      ]);
      expect(result.hasReceiptReaderHandoff, isTrue);
      expect(result.usesSeparateOcrSourceCopies, isFalse);
      expect(result.usedSavedProofAsOcrSourceFallback, isTrue);
      expect(result.ocrReadsClearSourceBeforeSavedProof, isFalse);
      expect(result.ocrUsesSavedProofOnlyAsFallback, isTrue);
      expect(
        result.ocrSourceFirstDecisionCode,
        'saved_proof_fallback_review_required',
      );
      expect(
        result.ocrSourceFirstReviewCue,
        contains('saved proof only because a clearer source was not available'),
      );
      expect(
        result.privacySafeOcrSourceFirstSummary,
        containsPair('ocrReadsClearSourceBeforeSavedProof', false),
      );
      expect(
        result.privacySafeOcrSourceFirstSummary,
        containsPair('ocrUsesSavedProofOnlyAsFallback', true),
      );
      expect(
        result.ocrSourceFirstOutcome,
        'fallback_saved_proof_review_required',
      );
      expect(
        result.ocrSourceFirstActionLabel,
        'OCR fell back to saved proof; review the filled receipt carefully',
      );
      expect(
        result.receiptReaderHandoffCounts,
        containsPair('saved_backup_present', 2),
      );
      expect(
        result.receiptReaderHandoffCounts,
        containsPair('ocr_source_present', 2),
      );
      expect(
        result.receiptReaderHandoffCounts,
        containsPair('ocr_source_matches_saved_backup', 1),
      );
      expect(
        result.receiptReaderHandoffCounts,
        containsPair('ocr_source_fallback_saved_proof', 1),
      );
      expect(
        result.receiptReaderHandoffCounts,
        containsPair('ocr_source_ordered_sections', 2),
      );
      expect(
        result.receiptReaderHandoffCounts,
        containsPair('match_readiness_ordered_sections_ready', 1),
      );
      expect(
        result.receiptReaderHandoffCounts,
        isNot(
          contains('native_camera_ui_native_capture_review_transition_ready'),
        ),
      );
      expect(result.acceptedPhotoHandoffOutcome, 'needs_review_before_ocr');
      expect(
        result.acceptedPhotoHandoffRoute,
        'photo_review_section_order_review_required',
      );
      expect(result.acceptedPhotoHandoffMustOpenReceiptDetails, isFalse);
      expect(result.acceptedPhotoHandoffMustOpenFilledReview, isFalse);
      expect(
        result.receiptPhotoReviewHandoffPath,
        'accepted_saved_proof_ocr_fallback',
      );
      expect(
        result.receiptPhotoReviewHandoffPathLabel,
        'Accepted photo review using saved proof as OCR fallback.',
      );
      expect(
        result.receiptReaderHandoffIntegrityLabel,
        contains('storage=ocr_source_fallback_saved_proof'),
      );
      expect(
        result.privacySafeOcrHandoffEvidenceLabel,
        contains('ocr_source_first=fallback_saved_proof'),
      );
    },
  );

  test(
    'separate OCR source copy is treated as clear source before saved proof',
    () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/saved-proof.jpg'],
        ocrSourcePhotoPaths: const ['/tmp/prepared-ocr-source.jpg'],
        dataSaverLevel: ReceiptDataSaverLevel.maximum,
        stitchResult: ReceiptStitchResult.notNeeded([
          '/tmp/prepared-ocr-source.jpg',
        ]),
      );

      expect(result.photoPaths, ['/tmp/saved-proof.jpg']);
      expect(result.ocrSourcePhotoPaths, ['/tmp/prepared-ocr-source.jpg']);
      expect(result.usesSeparateOcrSourceCopies, isTrue);
      expect(result.usedSavedProofAsOcrSourceFallback, isFalse);
      expect(result.ocrReadsClearSourceBeforeSavedProof, isTrue);
      expect(result.ocrUsesSavedProofOnlyAsFallback, isFalse);
      expect(
        result.ocrSourceFirstDecisionCode,
        'separate_receipt_source_before_saved_proof',
      );
      expect(
        result.ocrSourceFirstReviewCue,
        contains(
          'separate clear receipt sources before the smaller saved proof',
        ),
      );
      expect(
        result.receiptReaderHandoffCounts,
        containsPair('ocr_source_separate_from_backup', 1),
      );
      expect(
        result.receiptReaderHandoffCounts,
        containsPair(
          'receipt_proof_storage_policy_clear_ocr_source_read_before_saved_proof_copy',
          1,
        ),
      );
      expect(
        result.privacySafeOcrSourceFirstSummary,
        containsPair('ocrReadsClearSourceBeforeSavedProof', true),
      );
      expect(
        result.privacySafeOcrSourceFirstSummary,
        containsPair('ocrUsesSavedProofOnlyAsFallback', false),
      );
    },
  );

  test('photo review result removes duplicate saved and OCR source paths', () {
    final fallback = ReceiptPhotoReviewResult(
      photoPaths: const [
        ' /tmp/proof-top.jpg ',
        '/tmp/proof-top.jpg',
        '',
        '/tmp/proof-bottom.jpg',
      ],
      ocrSourcePhotoPaths: const [],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.notNeeded([]),
    );
    final separateOcr = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/proof.jpg', '/tmp/proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/ocr-clear.jpg', ' /tmp/ocr-clear.jpg '],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.notNeeded(['/tmp/ocr-clear.jpg']),
    );

    expect(fallback.photoPaths, [
      '/tmp/proof-top.jpg',
      '/tmp/proof-bottom.jpg',
    ]);
    expect(fallback.ocrSourcePhotoPaths, [
      '/tmp/proof-top.jpg',
      '/tmp/proof-bottom.jpg',
    ]);
    expect(fallback.savedBackupPhotoCount, 2);
    expect(fallback.ocrSourcePhotoCount, 2);
    expect(
      fallback.receiptReaderHandoffCounts,
      containsPair('saved_backup_present', 2),
    );
    expect(
      fallback.receiptReaderHandoffCounts,
      containsPair('ocr_source_present', 2),
    );

    expect(separateOcr.photoPaths, ['/tmp/proof.jpg']);
    expect(separateOcr.ocrSourcePhotoPaths, ['/tmp/ocr-clear.jpg']);
    expect(separateOcr.usesSeparateOcrSourceCopies, isTrue);
    expect(separateOcr.savedBackupPhotoCount, 1);
    expect(separateOcr.ocrSourcePhotoCount, 1);
  });

  test(
    'photo review result drops stale evidence for normalized-away paths',
    () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const [' /tmp/proof-top.jpg ', '/tmp/proof-bottom.jpg'],
        ocrSourcePhotoPaths: const [' /tmp/ocr-top.jpg '],
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        stitchResult: ReceiptStitchResult.notNeeded(['/tmp/ocr-top.jpg']),
        photoQualityChecksByPath: const {
          ' /tmp/proof-top.jpg ': ReceiptPhotoQualityCheck(
            width: 100,
            height: 200,
            focusScore: 2,
            brightness: 40,
            isLikelyReadable: false,
          ),
          '/tmp/proof-bottom.jpg': ReceiptPhotoQualityCheck(
            width: 100,
            height: 200,
            focusScore: 12,
            brightness: 140,
            isLikelyReadable: true,
          ),
          '/tmp/stale-proof.jpg': ReceiptPhotoQualityCheck(
            width: 1,
            height: 1,
            focusScore: 0,
            brightness: 0,
            isLikelyReadable: false,
          ),
        },
        captureDiagnosticsByPhotoPath: const {
          ' /tmp/proof-top.jpg ': {'captureFlow': 'trimmed_source'},
          '/tmp/stale-proof.jpg': {'captureFlow': 'stale_source'},
        },
        preparationDiagnosticsByOcrPath: const {
          ' /tmp/ocr-top.jpg ': {'ocrPrep': 'trimmed_source'},
          '/tmp/stale-ocr.jpg': {'ocrPrep': 'stale_source'},
        },
      );

      expect(result.photoPaths, [
        '/tmp/proof-top.jpg',
        '/tmp/proof-bottom.jpg',
      ]);
      expect(result.ocrSourcePhotoPaths, ['/tmp/ocr-top.jpg']);
      expect(result.photoQualityChecksByPath.keys, [
        '/tmp/proof-top.jpg',
        '/tmp/proof-bottom.jpg',
      ]);
      expect(result.captureDiagnosticsByPhotoPath.keys, ['/tmp/proof-top.jpg']);
      expect(result.preparationDiagnosticsByOcrPath.keys, ['/tmp/ocr-top.jpg']);
      expect(
        result.captureDiagnosticsByPhotoPath['/tmp/proof-top.jpg'],
        containsPair('captureFlow', 'trimmed_source'),
      );
      expect(
        result.preparationDiagnosticsByOcrPath['/tmp/ocr-top.jpg'],
        containsPair('ocrPrep', 'trimmed_source'),
      );
      expect(
        result.captureDiagnosticsByPhotoPath,
        isNot(contains('/tmp/stale-proof.jpg')),
      );
      expect(
        result.preparationDiagnosticsByOcrPath,
        isNot(contains('/tmp/stale-ocr.jpg')),
      );
    },
  );

  test(
    'duplicate stitched receipt sections require OCR handoff review before details',
    () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/proof-top.jpg', '/tmp/proof-dup.jpg'],
        ocrSourcePhotoPaths: const ['/tmp/ocr-top.jpg', '/tmp/ocr-dup.jpg'],
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        stitchResult: ReceiptStitchResult.fallback(
          inputPaths: const ['/tmp/ocr-top.jpg', '/tmp/ocr-dup.jpg'],
          warning: 'Duplicate section fallback for test.',
          fallbackReasonCode: 'duplicate_section_image',
          failedPairIndex: 0,
        ),
      );

      expect(
        result.receiptPhotoReviewHandoffPath,
        'accepted_stitch_ocr_source_review_required',
      );
      expect(
        result.receiptPhotoReviewHandoffPathLabel,
        'Accepted photo review, but stitch/OCR source handoff needs review.',
      );
      expect(result.nextReviewUsesOrderedSections, isTrue);
      expect(
        result.nextReviewMatchReadinessOutcome,
        'ocr_source_review_required_before_assist',
      );
      expect(
        result.nextReviewMatchReadinessLabel,
        'Photo match needs review before app-assisted receipt filling, starting with Photo 1 to 2.',
      );
      expect(
        result.stitchResult.ocrHandoffSafetyCode,
        'ordered_sections_after_duplicate_section_image_fallback',
      );
      expect(
        result.receiptReaderHandoffCounts,
        containsPair(
          'stitch_ocr_source_contract_fallback_duplicate_section_image',
          1,
        ),
      );
    },
  );

}
