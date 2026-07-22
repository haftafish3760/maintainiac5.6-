import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepted camera photo starts receipt details before OCR work finishes', () async {
    final entryScreen =
        await File(
          'lib/screens/expenses/entry/expense_receipt_entry_screen.dart',
        ).readAsString() +
        await File(
          'lib/screens/expenses/entry/expense_receipt_entry_read_handoff_helpers.dart',
        ).readAsString() +
        await File(
          'lib/screens/expenses/entry/expense_receipt_entry_read_handoff_metadata.dart',
        ).readAsString() +
        await File(
          'lib/screens/expenses/entry/expense_receipt_entry_read_handoff_no_line_labels.dart',
        ).readAsString();
    final stateActions =
        await File(
          'lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart',
        ).readAsString() +
        await File(
          'lib/screens/expenses/entry/expense_receipt_entry_ocr_actions.dart',
        ).readAsString() +
        await File(
          'lib/screens/expenses/entry/expense_receipt_entry_imported_text_parse_actions.dart',
        ).readAsString();
    final importActions =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_camera_actions.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_review_read_actions.dart',
        ).readAsString();
    final receiptReadActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart',
    ).readAsString();
    final reviewedReadActions = '$importActions$receiptReadActions';
    final captureModels =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_models.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_review_result_warnings.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_review_result_handoff_labels.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_review_result_completion.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_review_result_next_review.dart',
        ).readAsString();
    final attachmentPanel =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_panel_build.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_recovery_actions.dart',
        ).readAsString();

    expect(
      importActions,
      contains('if (!_notifyReviewedPhotoAccepted(result)) return false;'),
    );
    expect(importActions, contains('bool _notifyReviewedPhotoAccepted'));
    expect(
      importActions,
      contains(
        'Receipt photo saved, but the receipt details screen could not open.',
      ),
    );
    expect(importActions, contains('_startReviewedPhotoReadStatus(result);'));
    expect(
      importActions,
      contains(
        r'Photo review accepted. $processing $proofCount ready. Clear photo versions: $ocrSourceCount.',
      ),
    );
    expect(captureModels, contains('Business/Personal/Mixed choices'));
    expect(importActions, isNot(contains(r'Evidence: $evidence')));
    expect(
      importActions,
      contains('await _readReviewedPhotosForReceiptForm(result);'),
    );
    expect(reviewedReadActions, contains('_notifyReceiptReadStarted();'));
    expect(receiptReadActions, contains('void _notifyReceiptReadStarted()'));
    expect(receiptReadActions, contains('void _notifyReceiptOcrCompleted('));
    expect(receiptReadActions, contains('void _notifyReceiptReadFinished('));
    expect(receiptReadActions, contains('_notifyReceiptReadStarted();'));
    expect(receiptReadActions, contains('_notifyReceiptOcrCompleted(result);'));
    expect(receiptReadActions, contains('_notifyReceiptReadFinished(false);'));
    expect(
      importActions.indexOf(
        'if (!_notifyReviewedPhotoAccepted(result)) return false;',
      ),
      lessThan(importActions.indexOf('_startReviewedPhotoReadStatus(result);')),
    );
    expect(
      importActions.indexOf('_startReviewedPhotoReadStatus(result);'),
      lessThan(
        importActions.indexOf(
          'await _readReviewedPhotosForReceiptForm(result);',
        ),
      ),
    );
    final reviewedPhotoReadStatusBlock = reviewedReadActions.substring(
      reviewedReadActions.indexOf(
        'void _startReviewedPhotoReadStatus(ReceiptPhotoReviewResult result)',
      ),
      reviewedReadActions.indexOf(
        'String _reviewedPhotoOcrSourceQualitySummary(',
      ),
    );
    expect(
      reviewedPhotoReadStatusBlock,
      isNot(contains('widget.onReceiptReadStarted?.call();')),
    );
    expect(
      reviewedPhotoReadStatusBlock,
      contains('not receive two competing "reading" transitions'),
    );
    final takePhotoBlock = importActions.substring(
      importActions.indexOf('Future<void> takeReceiptPhoto() async'),
      importActions.indexOf('Future<_MaintainiacNativeCameraPhotoOutcome>'),
    );
    expect(
      takePhotoBlock,
      contains(
        'if (nativeOutcome == _MaintainiacNativeCameraPhotoOutcome.added) return;',
      ),
    );
    final addedReturnIndex = takePhotoBlock.indexOf(
      'if (nativeOutcome == _MaintainiacNativeCameraPhotoOutcome.added) return;',
    );
    final canceledReturnIndex = takePhotoBlock.indexOf(
      'await returnToReceiptImportOptions();',
      addedReturnIndex,
    );
    final backupCaptureIndex = takePhotoBlock.indexOf(
      '_openReceiptBackupCaptureAfterNativeUnavailable(settings)',
    );
    expect(addedReturnIndex, lessThan(canceledReturnIndex));
    expect(addedReturnIndex, lessThan(backupCaptureIndex));
    expect(
      addedReturnIndex,
      lessThan(takePhotoBlock.indexOf('_takePhoneCameraBackupPhoto();')),
    );
    expect(
      entryScreen,
      contains(
        'Maintainiac is checking the accepted photo now. Keep this screen open; receipt details will appear here when the photo is read.',
      ),
    );
    expect(
      entryScreen,
      contains('Opening receipt details from accepted photo'),
    );
    expect(entryScreen, isNot(contains('Preparing saved receipt photo')));
    expect(
      stateActions,
      contains("_receiptReadHandoffStage = 'Filling receipt details';"),
    );
    expect(
      stateActions,
      contains('parseExpenseReceiptOcrResultWithLocalMemory'),
    );
    final recoveredCaptureBlock = attachmentPanel.substring(
      attachmentPanel.indexOf('Future<void> _resumeRecoverableNativeCapture('),
      attachmentPanel.indexOf('Future<void> _dismissRecoverableNativeCapture('),
    );
    expect(
      recoveredCaptureBlock,
      contains('await _acceptReviewedPhotoResult('),
    );
    expect(recoveredCaptureBlock, contains('final accepted = await'));
    expect(
      recoveredCaptureBlock,
      contains('ReceiptNativeCaptureStaging().clearRecoveryManifestPath'),
    );
    expect(
      recoveredCaptureBlock.indexOf('final accepted = await'),
      lessThan(recoveredCaptureBlock.indexOf('clearRecoveryManifestPath')),
    );
    expect(
      '_readReviewedPhotosForReceiptForm'.allMatches(recoveredCaptureBlock),
      hasLength(0),
    );
  });
}
