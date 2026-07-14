import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
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
    expect(result.nextReviewSourceLabel, 'no clear receipt photo');
    expect(
      result.nextReviewHandoffLabel,
      'No clear receipt photo is ready to fill the receipt details. Add a clearer photo or continue by hand.',
    );
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
