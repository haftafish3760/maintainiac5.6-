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

      expect(source, contains('result.temporarySourcePhotoPaths'));
      expect(source, contains('result.ocrSourcePhotoPaths'));
      expect(source, contains('result.photoPaths'));
      expect(source, contains('keptPaths: keptReceiptPhotoPaths'));
      expect(source, contains('staging.finalizeAcceptedCapture(manifestPath)'));
      expect(
        source.indexOf('deleteAppOwnedFiles('),
        lessThan(source.indexOf('finalizeAcceptedCapture(manifestPath)')),
      );
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
