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
        stitchResult: const ReceiptStitchResult.notNeeded([
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
        'photo_review_ocr_source_review_required',
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
        stitchResult: const ReceiptStitchResult.notNeeded([
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
      stitchResult: const ReceiptStitchResult.notNeeded([]),
    );
    final separateOcr = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/proof.jpg', '/tmp/proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/ocr-clear.jpg', ' /tmp/ocr-clear.jpg '],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded(['/tmp/ocr-clear.jpg']),
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
        stitchResult: const ReceiptStitchResult.notNeeded(['/tmp/ocr-top.jpg']),
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

  test('kept for later review does not open receipt details input', () {
    final result = ReceiptPhotoReviewResult.keptForLater(
      photoPaths: const ['/tmp/staged-top.jpg', '/tmp/staged-bottom.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      captureDiagnosticsByPhotoPath: const {
        '/tmp/staged-top.jpg': {
          'nativeCaptureAttachmentStorageState': 'staged',
          'receiptBrainRequiredBaseReleaseActionCode':
              'ship_lean_base_and_defer_optional_receipt_packs',
          'receiptBrainInstallDistributionModeCode':
              'base_app_only_optional_cloud_assist',
          'receiptBrainStorageClass': 'critical',
          'receiptBrainLocalOcrMode': 'lean_local_ocr',
        },
        '/tmp/staged-bottom.jpg': {
          'receiptBrainRequiredBaseReleaseActionCode':
              'ship_lean_base_and_defer_optional_receipt_packs',
          'receiptBrainInstallDistributionModeCode':
              'base_app_only_optional_cloud_assist',
          'receiptBrainStorageClass': 'critical',
          'receiptBrainLocalOcrMode': 'lean_local_ocr',
        },
      },
    );

    expect(result.keptForLater, isTrue);
    expect(result.reviewExitAction, 'kept_for_later');
    expect(result.photoPaths, [
      '/tmp/staged-top.jpg',
      '/tmp/staged-bottom.jpg',
    ]);
    expect(result.ocrSourcePhotoPaths, isEmpty);
    expect(result.hasSavedBackupPhotos, isTrue);
    expect(result.hasOcrSourcePhotos, isFalse);
    expect(result.hasReceiptReaderHandoff, isFalse);
    expect(result.usedSavedProofAsOcrSourceFallback, isFalse);
    expect(result.receiptReaderHandoffCounts['saved_backup_present'], 2);
    expect(result.receiptReaderHandoffCounts['ocr_source_missing'], 1);
    expect(
      result.receiptReaderHandoffCounts['receipt_review_kept_for_later'],
      1,
    );
    expect(result.receiptReaderHandoffCounts['receipt_review_ocr_deferred'], 1);
    expect(
      result.receiptReaderHandoffCounts,
      containsPair(
        'receipt_brain_release_ship_lean_base_and_defer_optional_receipt_packs',
        2,
      ),
    );
    expect(
      result.receiptReaderHandoffCounts,
      containsPair(
        'receipt_brain_install_base_app_only_optional_cloud_assist',
        2,
      ),
    );
    expect(
      result.receiptReaderHandoffCounts,
      containsPair('receipt_brain_storage_critical', 2),
    );
    expect(
      result.receiptReaderHandoffCounts,
      containsPair('receipt_brain_local_ocr_lean_local_ocr', 2),
    );
    expect(
      result
          .receiptReaderHandoffCounts['receipt_review_receipt_details_not_accepted'],
      1,
    );
    expect(
      result.receiptReaderHandoffIntegrityLabel,
      'saved=2;ocr=0;storage=ocr_source_missing;stitch=notNeeded;coverage=coverage_ok;warnings=saved_photo_ok',
    );
    expect(
      result.acceptedPhotoHandoffOutcome,
      'not_accepted_for_receipt_details_yet',
    );
    expect(
      result.receiptPhotoReviewHandoffPath,
      'saved_without_filling_resume_required',
    );
    expect(
      result.receiptPhotoReviewHandoffPathLabel,
      'Saved without filling; resume photo review before receipt details.',
    );
    expect(
      result.acceptedPhotoHandoffActionLabel,
      'Resume photo review, then use the saved photo review to open receipt details.',
    );
    expect(
      result.acceptedPhotoHandoffRoute,
      'saved_photo_review_resume_required',
    );
    expect(
      result.acceptedPhotoHandoffNextScreen,
      'receipt_photo_review_resume',
    );
    expect(
      result.acceptedPhotoHandoffNextStepLabel,
      'Resume the saved receipt photo review, then use it to open receipt details.',
    );
    expect(result.acceptedPhotoHandoffMustOpenFilledReview, isFalse);
    expect(result.acceptedPhotoHandoffMustOpenReceiptDetails, isFalse);
    expect(result.acceptedPhotoHandoffUserAction, 'resume_saved_photo_review');
    expect(
      result.privacySafeOcrHandoffEvidenceLabel,
      contains('ocr_source_first=not_ready'),
    );
    expect(
      result
          .captureDiagnosticsByPhotoPath['/tmp/staged-top.jpg']!['receiptReviewKeptForLater'],
      isTrue,
    );
    expect(
      result
          .captureDiagnosticsByPhotoPath['/tmp/staged-bottom.jpg']!['receiptReviewNextAction'],
      'resume_saved_photo_review',
    );
    expect(
      result
          .captureDiagnosticsByPhotoPath['/tmp/staged-bottom.jpg']!['receiptReviewReaderAccepted'],
      isFalse,
    );
    expect(
      result
          .captureDiagnosticsByPhotoPath['/tmp/staged-bottom.jpg']!['receiptReviewReaderOutcome'],
      'not_accepted_for_receipt_details_yet',
    );
    expect(
      result
          .captureDiagnosticsByPhotoPath['/tmp/staged-bottom.jpg']!['receiptReviewResumeRequiredBeforeOcr'],
      isTrue,
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata,
      containsPair('receiptReviewKeptForLater', true),
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata,
      containsPair(
        'receiptReaderHandoffOutcome',
        'not_accepted_for_receipt_details_yet',
      ),
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata,
      containsPair(
        'receiptReaderHandoffRoute',
        'saved_photo_review_resume_required',
      ),
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata,
      containsPair('receiptReaderHandoffMustOpenReceiptDetails', false),
    );
  });

  test('kept for later review keeps source paths uniquely normalized', () {
    final result = ReceiptPhotoReviewResult.keptForLater(
      photoPaths: const [
        ' /tmp/staged-top.jpg ',
        '/tmp/staged-top.jpg',
        '',
        '/tmp/staged-bottom.jpg',
      ],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      captureDiagnosticsByPhotoPath: const {
        '/tmp/staged-top.jpg': {
          'nativeCaptureAttachmentStorageState': 'staged',
        },
        '/tmp/staged-bottom.jpg': {
          'nativeCaptureAttachmentStorageState': 'staged',
        },
      },
    );

    expect(result.photoPaths, [
      '/tmp/staged-top.jpg',
      '/tmp/staged-bottom.jpg',
    ]);
    expect(result.stitchResult.inputPaths, [
      '/tmp/staged-top.jpg',
      '/tmp/staged-bottom.jpg',
    ]);
    expect(
      result.captureDiagnosticsByPhotoPath['/tmp/staged-top.jpg'],
      containsPair('receiptReviewKeptPhotoCount', 2),
    );
    expect(
      result.captureDiagnosticsByPhotoPath['/tmp/staged-bottom.jpg'],
      containsPair('receiptReviewKeptPhotoCount', 2),
    );
    expect(
      result.receiptReaderHandoffCounts,
      containsPair('saved_backup_present', 2),
    );
  });
}
