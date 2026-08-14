import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expense receipt cleanup runs only after durable ledger save', () async {
    final source = await File(
      'lib/screens/expenses/entry/expense_receipt_save_actions.dart',
    ).readAsString();
    final ledgerSave = source.indexOf(
      'final saved = await _saveReceiptToLedger(ledger, receipt);',
    );
    final stagedCleanup = source.indexOf(
      'await ReceiptProofStorage.instance.deleteStagedAttachments(',
      ledgerSave,
    );
    final temporaryCleanup = source.indexOf(
      'await _manualReceiptAttachmentController.finalizeSuccessfulReceiptSave(',
      ledgerSave,
    );

    expect(ledgerSave, greaterThanOrEqualTo(0));
    expect(stagedCleanup, greaterThan(ledgerSave));
    expect(temporaryCleanup, greaterThan(stagedCleanup));
    expect(
      source.substring(ledgerSave, stagedCleanup),
      contains('if (saved == null) return;'),
    );
    expect(
      source.substring(temporaryCleanup),
      contains('saved.attachments.map('),
    );
  });

  test(
    'controller retains accepted sources and finalizes recovery manifests',
    () async {
      final source = await File(
        'lib/shared/widgets/receipt_capture/receipt_attachment_panel_controller.dart',
      ).readAsString();
      final tracker = await File(
        'lib/shared/widgets/receipt_capture/receipt_session_artifact_tracker.dart',
      ).readAsString();

      expect(source, contains('_artifactTracker.retainReviewSources(result)'));
      expect(tracker, contains('result.temporarySourcePhotoPaths'));
      expect(tracker, contains('result.ocrSourcePhotoPaths'));
      expect(tracker, contains('result.photoPaths'));
      expect(tracker, contains('keptPaths: keptReceiptPhotoPaths'));
      expect(tracker, contains('_nativeStaging.finalizeAcceptedCapture('));
      expect(
        tracker.indexOf('_temporaryCleanup.deleteAppOwnedFiles('),
        lessThan(tracker.indexOf('_finalizeTrackedManifests()')),
      );
    },
  );

  test(
    'failed prep cleanup is restricted to app-owned temporary files',
    () async {
      final source = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_exit_actions.dart',
      ).readAsString();
      final start = source.indexOf(
        'Future<void> _cleanupFailedReceiptPrepArtifacts',
      );
      final end = source.indexOf(
        'void _forgetAcceptedReceiptPrepArtifacts',
        start,
      );
      final cleanupBlock = source.substring(start, end);

      expect(cleanupBlock, contains('ReceiptTemporaryArtifactCleanup'));
      expect(cleanupBlock, contains('keptPaths: _photoPaths'));
      expect(cleanupBlock, isNot(contains('file.delete()')));
    },
  );

  test(
    'controller-based expense flow does not delete OCR sources after read',
    () async {
      final source = await File(
        'lib/shared/widgets/receipt_capture/receipt_attachment_review_read_actions.dart',
      ).readAsString();
      final readBlock = source.substring(
        source.indexOf(
          'Future<_ReceiptAttachmentReadResult?> _readAcceptedPhotosForReceiptForm(',
        ),
        source.indexOf('void _startReviewedPhotoReadStatus('),
      );

      expect(readBlock, contains('if (widget.controller == null)'));
      expect(readBlock, contains('deleteTemporaryOcrPhotos('));
    },
  );
}
