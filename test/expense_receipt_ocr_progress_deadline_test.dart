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
      expect(source, contains('Duration(seconds: 25)'));
      expect(source, contains('Duration(seconds: 30)'));
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
      expect(
        source,
        contains('_lastOcrDiagnostics = preparedDiagnostics ?? ocr.diagnostics;'),
      );
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
    expect(progressPanel, contains('class _ReceiptHandoffSteps'));
    expect(progressPanel, contains(r'Step $currentStep of ${_labels.length}'));
    expect(progressPanel, contains("'Reading receipt'"));
    expect(progressPanel, contains("'Preparing details'"));
    expect(progressPanel, contains("'Opening review'"));
    expect(progressPanel, contains('isCurrent: index + 1 == currentStep'));
    expect(progressPanel, contains('isComplete: index + 1 < currentStep'));
    expect(progressPanel, contains('required String stageLabel'));
    expect(progressPanel, contains('_progressStepFor(stage)'));
    expect(progressPanel, contains("normalized.contains('preparing')"));
    expect(progressPanel, contains("normalized.contains('filling')"));
    expect(
      progressPanel,
      isNot(contains('Step 1 of 2: extracting receipt text')),
    );
    final reviewIntro = await File(
      'lib/screens/expenses/entry/expense_receipt_parse_review_intro_panel.dart',
    ).readAsString();
    expect(reviewIntro, contains('Receipt text is ready for review'));
    expect(reviewIntro, isNot(contains('Receipt reading not measured')));
  });
}
