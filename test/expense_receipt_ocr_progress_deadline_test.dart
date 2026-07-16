import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'receipt OCR has a bounded recovery path before downstream handoff',
    () async {
      final source = await File(
        'lib/screens/expenses/entry/expense_receipt_entry_ocr_actions.dart',
      ).readAsString();

      expect(source, contains('ReceiptCapabilityTier.heavyweight'));
      expect(source, contains('Duration(seconds: 20)'));
      expect(
        source,
        contains('.recognizeTextFromAttachments(_receiptAttachments).timeout('),
      );
      expect(source, contains('_handleReceiptOcrDeadlineExceeded();'));
      expect(source, contains('_handleReceiptOcrReadFailure();'));
      expect(
        source,
        contains('downstream_receipt_handoff_exceeded_device_deadline'),
      );
      expect(source, contains('Preparing editable receipt details'));
      expect(
        source,
        contains('if (!ocr.hasText) _scanningReceiptPhotos = false;'),
      );
      expect(
        source,
        contains('_updateReceiptState(() => _scanningReceiptPhotos = false);'),
      );
      expect(source, contains('_pendingReceiptScanSignature = signature'));
      expect(source, contains('await _performReceiptAttachmentScan()'));
      expect(
        source,
        contains("final pendingSignature = _pendingReceiptScanSignature"),
      );
      expect(source, contains('_receiptOcrHandoffRouter('));
      expect(source, contains('receiptOcrHandoffDestination'));
    },
  );

  test('receipt review fields stay hidden until processing has ended', () async {
    final helpers = await File(
      'lib/screens/expenses/entry/expense_receipt_entry_core_helpers.dart',
    ).readAsString();
    final scaffold = await File(
      'lib/screens/expenses/entry/expense_receipt_entry_scaffold.dart',
    ).readAsString();
    final progressPanel = await File(
      'lib/screens/expenses/entry/expense_receipt_parse_review_handoff_panel.dart',
    ).readAsString();

    expect(
      helpers,
      contains('_hasAppAssistedReceiptReview && !_scanningReceiptPhotos'),
    );
    expect(scaffold, contains('if (_shouldShowReceiptReviewFields)'));
    expect(progressPanel, contains("'Receipt text extracted'"));
    expect(progressPanel, contains("'Receipt form filled'"));
    expect(
      progressPanel,
      contains(r'Step $progressStep of ${progressLabels.length}'),
    );
    expect(progressPanel, contains('required String stageLabel'));
    expect(progressPanel, contains("stage.contains('accepted')"));
    expect(progressPanel, contains("stage.contains('quality')"));
    expect(progressPanel, contains('opacity: active ? 1 : 0.5'));
    expect(
      progressPanel,
      isNot(contains('Step 1 of 2: extracting receipt text')),
    );
  });
}
