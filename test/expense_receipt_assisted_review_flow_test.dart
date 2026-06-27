import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('assisted expense receipt review exposes whole receipt choices', () async {
    final entryScreen = await File(
      'lib/screens/expenses/entry/expense_receipt_entry_screen.dart',
    ).readAsString();
    final stateActions = await File(
      'lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart',
    ).readAsString();
    final lineModels = await File(
      'lib/screens/expenses/entry/expense_receipt_line_models.dart',
    ).readAsString();
    final attachmentPanel = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart',
    ).readAsString();
    final attachmentOcr = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart',
    ).readAsString();
    final importActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart',
    ).readAsString();
    final recap = await File(
      'lib/screens/expenses/entry/expense_receipt_recap.dart',
    ).readAsString();
    final photoControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart',
    ).readAsString();

    expect(entryScreen, contains('_ReceiptWholeUseReviewPanel'));
    expect(stateActions, contains('_markAllReceiptLines'));
    expect(recap, contains('Classify This Receipt'));
    expect(recap, contains('fieldConfidences: fieldConfidences'));
    expect(
      recap,
      contains('Choose Business, Personal, or Mixed. If it is Mixed'),
    );
    expect(recap, contains('All Business'));
    expect(recap, contains('All Personal'));
    expect(recap, contains('Mixed Receipt'));
    expect(recap, contains('What Maintainiac Found'));
    expect(
      recap,
      contains('Review the store, date, totals, and line confidence'),
    );
    expect(recap, contains('SCANNED RECEIPT REVIEW'));
    expect(recap, contains('STORE NOT FILLED YET'));
    expect(recap, contains("label: 'Subtotal'"));
    expect(recap, contains("label: 'Tax'"));
    expect(recap, contains('Split starts at 50/50'));
    expect(recap, contains('_showLineUseControls'));
    expect(recap, contains('Tap Mixed Receipt above'));
    expect(
      recap,
      contains('Mixed totals include each line share plus allocated tax'),
    );
    expect(recap, contains('Returns reduce their side'));
    expect(entryScreen, contains('_businessAdjustmentBase'));
    expect(entryScreen, contains('_personalAdjustmentBase'));
    expect(entryScreen, contains('_receiptAdjustmentBase'));
    expect(entryScreen, contains('math.max(0, line.businessAmount)'));
    expect(entryScreen, contains('math.max(0, line.personalAmount)'));
    expect(recap, contains('_ReceiptLineUseSegment'));
    expect(recap, contains('_ReceiptLineUseChip'));
    expect(recap, contains('allocationDetail'));
    expect(entryScreen, contains('onSetUse: _setReceiptLineUse'));
    expect(entryScreen, contains('String get _receiptDateLabel'));
    expect(entryScreen, contains('String get _receiptStoreAddressLabel'));
    expect(
      entryScreen.indexOf('_ReceiptClassificationReviewPanel'),
      lessThan(entryScreen.indexOf('_ReceiptWholeUseReviewPanel')),
    );
    expect(
      entryScreen.indexOf('_ReceiptWholeUseReviewPanel'),
      lessThan(entryScreen.indexOf('_ReceiptLineEvidenceReviewPanel')),
    );
    expect(
      entryScreen.indexOf('_ReceiptLineEvidenceReviewPanel'),
      lessThan(entryScreen.indexOf('_ReceiptRecapPanel')),
    );
    expect(
      entryScreen.indexOf('_ReceiptRecapPanel'),
      lessThan(entryScreen.indexOf('SharedReceiptStorePanel')),
    );
    expect(attachmentPanel, contains('_ReceiptReadReviewStatus'));
    expect(attachmentPanel, contains('this.onReceiptReadStarted'));
    expect(attachmentPanel, contains('this.onReceiptReadFinished'));
    expect(attachmentOcr, contains('_readingForReview = true'));
    expect(attachmentOcr, contains('widget.onReceiptReadStarted?.call();'));
    expect(
      attachmentOcr,
      contains('widget.onReceiptReadFinished?.call(true);'),
    );
    expect(
      attachmentOcr,
      contains('widget.onReceiptReadFinished?.call(false);'),
    );
    expect(
      attachmentOcr,
      contains(
        'Reading the clear receipt image now. If text is found, the filled receipt review appears below.',
      ),
    );
    expect(attachmentOcr, contains('_receiptReadStatusMessage = message;'));
    expect(
      stateActions,
      contains(
        'Receipt filled. Review the store, date, totals, and lines below before saving.',
      ),
    );
    expect(attachmentOcr, contains('await Future<void>.sync'));
    expect(
      attachmentOcr.indexOf('await Future<void>.sync'),
      lessThan(attachmentOcr.indexOf('_receiptReadStatusMessage = message;')),
    );
    expect(
      attachmentOcr.indexOf('widget.onReceiptReadStarted?.call();'),
      lessThan(attachmentOcr.indexOf('recognizeTextFromAttachments')),
    );
    expect(importActions, contains('_readReviewedPhotosForReceiptForm'));
    expect(importActions, contains('settings?.appAssistedEnabledFor'));
    expect(importActions, contains('result.ocrSourcePhotoPaths.isEmpty'));
    expect(
      importActions.indexOf('_publishAttachmentChange();'),
      lessThan(
        importActions.indexOf('_readReviewedPhotosForReceiptForm(result);'),
      ),
    );
    expect(
      importActions.indexOf('_readReviewedPhotosForReceiptForm(result);'),
      lessThan(
        importActions.indexOf(
          'unawaited(_deleteTemporaryOcrPhotos(result.ocrSourcePhotoPaths))',
        ),
      ),
    );
    expect(
      importActions,
      contains(
        'The matched receipt photo was read. Review the filled fields below.',
      ),
    );
    expect(
      importActions,
      contains(
        'Receipt photos were read from top to bottom. Review the filled fields below.',
      ),
    );
    expect(
      importActions,
      contains('Receipt photo was read. Review the filled fields below.'),
    );
    expect(stateActions, contains('_setReceiptLineUse'));
    expect(
      stateActions,
      contains('Future<void> _parseImportedReceiptText(String text) async'),
    );
    expect(
      stateActions,
      contains('await _parseImportedReceiptTextWithMemory(text)'),
    );
    expect(stateActions, contains('_chooseSplitBusinessPercent'));
    expect(stateActions, contains('_scrollToReceiptReview();'));
    expect(stateActions, contains('_applyUnusableParsedReceipt(parsed);'));
    expect(
      stateActions,
      contains('Receipt was read, but the app could not find usable fields.'),
    );
    expect(
      stateActions,
      contains('_lastFieldConfidences = parsed.fieldConfidences'),
    );
    expect(stateActions, contains('_lastFieldConfidences = const {};'));
    expect(
      stateActions.indexOf('_applyParsedReceipt(parsed);'),
      lessThan(stateActions.indexOf('void _applyParsedReceipt')),
    );
    expect(lineModels, contains('cameFromAppAssistedReceiptRead'));
    expect(
      lineModels,
      contains('rawReceiptText.trim().isNotEmpty || hasParserReview'),
    );
    expect(stateActions, contains('void _removeAppAssistedReceiptLines()'));
    expect(
      stateActions,
      contains(
        '_lines.removeWhere((line) => line.cameFromAppAssistedReceiptRead)',
      ),
    );
    expect(
      stateActions.indexOf('_removeAppAssistedReceiptLines();'),
      lessThan(
        stateActions.indexOf(
          'for (var index = 0; index < parsed.lines.length; index++)',
        ),
      ),
    );
    expect(
      stateActions.indexOf('_scheduleDraftSave();'),
      lessThan(stateActions.indexOf('_scrollToReceiptReview();')),
    );
    expect(stateActions, contains('Split Receipt Line'));
    expect(stateActions, contains('25% Business'));
    expect(stateActions, contains('50% Business'));
    expect(stateActions, contains('75% Business'));
    expect(stateActions, contains('Custom Business %'));
    expect(photoControls, contains('_ReceiptPreviewActionTray'));
    expect(photoControls, contains('Next'));
    expect(photoControls, contains('receipt photos ready'));
    expect(photoControls, contains('Check order and match'));
    expect(photoControls, contains('tap Next to review the filled receipt'));
    expect(
      entryScreen,
      contains(
        'Reading the receipt and preparing the filled review section below...',
      ),
    );
    expect(
      entryScreen,
      contains('onReceiptReadStarted: _markReceiptReadStarted'),
    );
    expect(
      entryScreen,
      contains('onReceiptReadFinished: _markReceiptReadFinished'),
    );
    expect(entryScreen, contains('void _markReceiptReadStarted()'));
    expect(
      entryScreen,
      contains('void _markReceiptReadFinished(bool didRead)'),
    );
    expect(
      entryScreen,
      contains('This is the filled receipt review from the photo.'),
    );
    expect(entryScreen, contains('Check the store, date, totals, and lines'));
    expect(entryScreen, contains('No Line Items Found'));
    expect(entryScreen, contains('Add Line Manually'));
    expect(entryScreen, contains('_addReceiptTotalLine'));
    expect(entryScreen, contains('Use Total As Business'));
    expect(entryScreen, contains('Use Total As Personal'));
    expect(entryScreen, contains('Split Total 50/50'));
    expect(entryScreen, contains('Receipt Total'));
    expect(entryScreen, contains('OCR Lines'));
    expect(
      entryScreen,
      contains(
        'The receipt text was read, but the app could not safely build line items. Use the receipt total if that is enough, or add line items manually.',
      ),
    );
    expect(photoControls, contains('Photo 1 starts at the top'));

    final parseReview = await File(
      'lib/screens/expenses/entry/expense_receipt_parse_review.dart',
    ).readAsString();
    expect(parseReview, contains('_ReceiptNoLineRecoveryChip'));
    expect(parseReview, contains('_ReceiptFieldConfidenceRow'));
    expect(parseReview, contains('Fields to check'));
    expect(parseReview, contains("'receiptMath' => 'Receipt math'"));
    expect(parseReview, contains("'lineItems' => 'Line items'"));

    final saveActions = await File(
      'lib/screens/expenses/entry/expense_receipt_save_actions.dart',
    ).readAsString();
    expect(saveActions, contains('_receiptSaveReadinessIssues'));
    expect(saveActions, contains('_ReceiptSaveReadinessIssue'));
    expect(saveActions, contains('unreviewed_app_filled_lines'));
    expect(saveActions, contains('receipt_ocr_no_readable_text'));
    expect(saveActions, contains('receipt_ocr_blocking_warnings'));
    expect(saveActions, contains('receipt_ocr_partial_read'));
    expect(saveActions, contains('receipt_ocr_review_warnings'));
    expect(saveActions, contains('receipt_subtotal_line_mismatch'));
    expect(saveActions, contains('Review receipt before saving?'));
    expect(saveActions, contains('Review Receipt'));
    expect(saveActions, contains('Save Anyway'));
    expect(saveActions, contains('Line subtotal is'));
    expect(saveActions, contains('Check for missing items'));
    expect(
      saveActions.indexOf('_receiptSaveReadinessIssues();'),
      lessThan(saveActions.indexOf('ledger.checkDuplicatesFor(receipt)')),
    );
  });
}
