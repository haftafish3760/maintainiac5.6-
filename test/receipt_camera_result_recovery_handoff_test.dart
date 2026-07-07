import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_flow.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

import 'helpers/receipt_recovery_handoff_fixture.dart';

void main() {
  test('OCR handoff attachments expose privacy-safe native recovery signals', () {
    final result = buildNativeRecoveryReviewResult();

    final attachments = ReceiptCaptureFlow.attachmentsFromReviewResult(
      result,
      ReceiptCaptureFlowModule.expenses,
    );

    expect(attachments, hasLength(1));
    final attachment = attachments.single;
    expect(attachment.linkedModule, 'expenses');
    expect(
      attachment.documentSignals,
      contains('native_recovery_resume_review_started'),
    );
    expect(
      attachment.documentSignals,
      contains('native_recovery_recovered_photos'),
    );
    expect(
      attachment.documentSignals,
      contains('native_recovery_multiple_sections'),
    );
    expect(
      attachment.documentSignals,
      contains('native_recovery_freshness_stale'),
    );
    expect(
      attachment.documentSignals,
      contains('native_recovery_storage_partial_photos_available'),
    );
    expect(
      attachment.documentSignals,
      contains('native_capture_source_native_recovery'),
    );
    expect(
      attachment.documentSignals,
      contains('native_capture_source_health_available'),
    );
    expect(
      attachment.documentSignals,
      contains('native_capture_surface_health_available'),
    );
    expect(
      attachment.documentSignals,
      contains('native_capture_surface_maintainiac_native_android'),
    );
    expect(
      attachment.documentSignals,
      contains(
        'native_capture_surface_verified_maintainiac_custom_surface_verified',
      ),
    );
    expect(
      attachment.documentSignals,
      contains('native_capture_identity_maintainiac_in_app_receipt_camera'),
    );
    expect(
      attachment.documentSignals,
      contains('receipt_review_depth_detailedlines'),
    );
    expect(
      attachment.documentSignals,
      contains(
        'receipt_proof_storage_temporary_ocr_source_saved_data_saver_proof',
      ),
    );
    expect(
      attachment.documentSignals,
      contains(
        'receipt_proof_storage_temporary_ocr_source_separate_from_saved_proof',
      ),
    );
    expect(
      attachment.documentSignals,
      contains('receipt_match_readiness_combined_receipt_image_ready'),
    );
    expect(attachment.documentSignals, contains('review_photo_edited'));
    expect(
      attachment.documentSignals,
      contains('review_photo_edit_manual_crop'),
    );
    expect(
      attachment.documentSignals,
      contains('review_photo_edit_source_selected'),
    );
    expect(
      attachment.documentSignals,
      contains('review_photo_edit_source_selected_edited_copy_selected'),
    );
    expect(
      attachment.documentSignals,
      contains('review_photo_edit_replaced_original'),
    );
    expect(
      attachment.documentSignals,
      contains('review_photo_edit_replaced_original_manual_crop'),
    );
    expect(attachment.documentSignals, contains('proof_data_saver_strong'));
    expect(
      attachment.documentSignals,
      contains('receipt_brain_mode_available'),
    );
    expect(
      attachment.documentSignals,
      contains(
        'receipt_brain_release_ship_lean_base_and_defer_optional_receipt_packs',
      ),
    );
    expect(
      attachment.documentSignals,
      contains('receipt_brain_install_base_app_only_optional_cloud_assist'),
    );
    expect(
      attachment.documentSignals,
      contains('receipt_brain_storage_critical'),
    );
    expect(
      attachment.documentSignals,
      contains('receipt_brain_local_ocr_lean_local_ocr'),
    );
    expect(
      attachment.riskFlags,
      contains('ocr_source_small_proof_copy_review_required'),
    );
    expect(
      attachment.riskFlags,
      contains('ocr_source_proof_data_saver_strong'),
    );
    expect(
      attachment.riskFlags,
      contains('ocr_source_match_readiness_combined_receipt_image_ready'),
    );
    expect(
      attachment.riskFlags,
      contains('ocr_source_native_recovery_resume_review_started'),
    );
    expect(
      attachment.riskFlags,
      contains('ocr_source_native_recovery_multiple_sections'),
    );
    expect(attachment.riskFlags, contains('ocr_source_native_recovery_stale'));
    expect(
      attachment.riskFlags,
      contains('ocr_source_native_recovery_partial_photos_available'),
    );
    expect(
      attachment.riskFlags,
      contains('ocr_source_native_capture_storage_saver'),
    );
    expect(
      attachment.riskFlags,
      contains('ocr_source_native_capture_older_phone'),
    );
    expect(attachment.riskFlags, contains('ocr_source_review_photo_edited'));
    expect(
      attachment.riskFlags,
      contains('ocr_source_review_photo_edit_manual_crop'),
    );
    expect(
      attachment.riskFlags,
      contains('ocr_source_review_photo_edit_source_selected'),
    );
    expect(
      attachment.riskFlags,
      contains(
        'ocr_source_review_photo_edit_source_selected_edited_copy_selected',
      ),
    );
    expect(
      attachment.riskFlags,
      contains('ocr_source_review_photo_edit_replaced_original'),
    );
    expect(
      attachment.riskFlags,
      contains('ocr_source_review_photo_edit_replaced_original_manual_crop'),
    );
    expect(
      attachment.riskFlags,
      contains('ocr_source_receipt_brain_optional_packs_deferred'),
    );
    expect(
      attachment.riskFlags,
      contains('ocr_source_receipt_brain_critical_storage'),
    );
    expect(
      attachment.riskFlags,
      contains('ocr_source_receipt_brain_lean_local_ocr'),
    );
    expect(attachment.documentSignals.join(' '), isNot(contains('lowe')));
    expect(attachment.riskFlags.join(' '), isNot(contains('3.24')));
  });

  test('malformed photo edit action is redacted from attachment handoff', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/edited-proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/edited-proof.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.notNeeded(['/tmp/edited-proof.jpg']),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/edited-proof.jpg': {
          'userEditedPhoto': true,
          'photoEditAction': 'PRIVATE RECEIPT TEXT CROP 12.34',
          'photoEditReplacedOriginal': true,
        },
      },
    );
    final attachment = ReceiptCaptureFlow.attachmentsFromReviewResult(
      result,
      ReceiptCaptureFlowModule.expenses,
    ).single;

    expect(
      attachment.documentSignals,
      contains('review_photo_edit_invalid_photo_edit_action'),
    );
    expect(
      attachment.documentSignals,
      contains('review_photo_edit_replaced_original_invalid_photo_edit_action'),
    );
    expect(
      attachment.riskFlags,
      contains('ocr_source_review_photo_edit_invalid_photo_edit_action'),
    );
    expect(
      attachment.riskFlags,
      contains(
        'ocr_source_review_photo_edit_replaced_original_invalid_photo_edit_action',
      ),
    );
    expect(attachment.documentSignals.join(' '), isNot(contains('PRIVATE')));
    expect(attachment.riskFlags.join(' '), isNot(contains('12.34')));
    expect(attachment.documentSignals.join(' '), isNot(contains('/tmp/')));
  });
}
