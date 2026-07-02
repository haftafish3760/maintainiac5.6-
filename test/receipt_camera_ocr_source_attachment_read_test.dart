import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reviewed OCR source attachments preserve read state and cleanup safety', () async {
    final importActions =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_camera_actions.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_review_read_actions.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_native_signal_documents.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_native_signal_helpers.dart',
        ).readAsString();
    final captureFlow =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_signals.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_risks.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_native_signals.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_capture_and_review.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_review_result.dart',
        ).readAsString();

    expect(importActions, contains('ReceiptAttachmentReadState.readIntoForm'));
    expect(importActions, contains('ReceiptAttachmentReadState.unreadable'));
    expect(importActions, contains('appAssistedEnabledFor(widget.area)'));
    expect(importActions, contains('widget.onImportedText == null'));
    expect(importActions, contains('result.ocrSourcePhotoPaths.isEmpty'));
    expect(
      importActions,
      contains(
        'Receipt proof saved. App-assisted receipt filling is turned off for this area.',
      ),
    );
    expect(
      importActions,
      contains(
        r'Receipt proof saved: ${result.savedProofCountLabel}. No clear OCR source was available for app-assisted receipt filling.',
      ),
    );
    expect(importActions, contains('result.ocrSourcePhotoPaths'));
    expect(captureFlow, contains('open_filled_review_or_save_proof'));
    expect(captureFlow, isNot(contains('read_receipt_or_save_proof')));
    expect(importActions, contains('qualityForOcrSourceIndex'));
    expect(importActions, contains('_weakestPhotoQuality'));
    expect(importActions, contains('.withPhotoQuality('));
    expect(captureFlow, contains('_receiptBrainDocumentSignalsFor'));
    expect(captureFlow, contains('_receiptBrainRiskFlagsFor'));
    expect(importActions, contains('receiptBrainDocumentSignalsFor'));
    expect(importActions, contains('receiptBrainRiskFlagsFor'));
    expect(importActions, contains('receipt_brain_mode_available'));
    expect(
      importActions,
      contains('ocr_source_receipt_brain_optional_packs_deferred'),
    );
    final attachmentPanel =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_initial_state.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_publish_helpers.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_publish_signals.dart',
        ).readAsString();
    expect(attachmentPanel, contains('_photoReadStateByPath'));
    expect(attachmentPanel, contains('_photoIdByPath'));
    expect(attachmentPanel, contains('photoAttachmentIdForPath'));
    expect(attachmentPanel, contains('readState:'));
    expect(attachmentPanel, contains('attachment.readState'));
    expect(attachmentPanel, contains('onReceiptPhotoReviewAccepted'));
    expect(importActions, contains('previousPhotoIdByPath'));
    expect(importActions, contains('deleteTemporaryOcrPhotos'));
    expect(
      importActions,
      contains('required List<String> keptReceiptPhotoPaths'),
    );
    expect(
      importActions,
      contains('final keptReceiptPhotos = keptReceiptPhotoPaths'),
    );
    expect(
      importActions,
      isNot(contains('_photoPaths.map(_normalizedCleanupPath).toSet()')),
    );
    expect(
      importActions,
      contains('_shouldDeleteTemporaryOcrPhoto(sourcePath, keptReceiptPhotos)'),
    );
    expect(importActions, contains('_isProtectedReceiptStoragePath'));
    expect(importActions, contains("'/receipt_proofs/'"));
    expect(importActions, contains("'/receipt_proofs_staging/'"));
    expect(importActions, contains("'/native_capture_recovery/'"));
    expect(importActions, contains('Directory.systemTemp.path'));
    expect(
      importActions,
      contains("fileName.startsWith('maintaniac_receipt_')"),
    );
    expect(importActions, contains("fileName.endsWith('.jpg')"));
    expect(importActions, contains('reviewedPhotoReadSuccessMessage'));
    expect(
      importActions,
      contains(
        'One combined receipt image was read. Review what Maintainiac filled in below.',
      ),
    );
    expect(
      importActions,
      contains(
        'Receipt photos were read from top to bottom. Review what Maintainiac filled in below.',
      ),
    );
    expect(
      importActions,
      contains(
        'Receipt photo was read. Review what Maintainiac filled in below.',
      ),
    );
    expect(
      importActions.indexOf('_readReviewedPhotosForReceiptForm(result)'),
      lessThan(
        importActions.indexOf('keptReceiptPhotoPaths: result.photoPaths'),
      ),
    );
    expect(
      importActions,
      contains('required List<String> keptReceiptPhotoPaths'),
    );
    expect(
      importActions.indexOf(
        'widget.onReceiptPhotoReviewAccepted?.call(result)',
      ),
      lessThan(importActions.indexOf('_startReviewedPhotoReadStatus(result)')),
    );
  });
}
