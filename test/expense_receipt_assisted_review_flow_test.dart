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
    final lineEditorActions = await File(
      'lib/screens/expenses/entry/expense_receipt_line_editor_actions.dart',
    ).readAsString();
    final lineFields = await File(
      'lib/screens/expenses/entry/expense_receipt_line_fields.dart',
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
    final parseReview = await File(
      'lib/screens/expenses/entry/expense_receipt_parse_review.dart',
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
      contains('Mixed totals include each line share plus allocated sales tax'),
    );
    expect(recap, contains('_ReceiptMixedAllocationReview'));
    expect(recap, contains('MIXED ALLOCATION REVIEW'));
    expect(recap, contains('Business subtotal'));
    expect(recap, contains('Business tax/adjustment'));
    expect(recap, contains('Business final'));
    expect(recap, contains('Personal subtotal'));
    expect(recap, contains('Personal tax/adjustment'));
    expect(recap, contains('Personal final'));
    expect(recap, contains('sales tax, fees, discounts'));
    expect(recap, contains('Returns reduce their side'));
    expect(recap, contains('math.max(0, line.businessAmount)'));
    expect(recap, contains('math.max(0, line.personalAmount)'));
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
        r'Preparing $sourceSummary for app assistance. When text is found, Maintainiac shows the receipt details so you can check the store, date, total, and item lines.',
      ),
    );
    expect(attachmentOcr, contains('_receiptReadSourceSummary(readable)'));
    expect(attachmentOcr, contains('_receiptReadRecoveryAdvice(readable)'));
    expect(
      attachmentOcr,
      contains(r'Receipt reading failed for $sourceSummary'),
    );
    expect(attachmentOcr, contains('class _ReceiptReadRecoveryAdvice'));
    expect(
      attachmentOcr,
      contains('Receipt photo text was not readable enough.'),
    );
    expect(attachmentOcr, contains('recoveryAdvice.primaryAction'));
    expect(attachmentOcr, contains('recoveryAdvice.shortAction'));
    expect(attachmentOcr, contains('_receiptReadStatusMessage = message;'));
    expect(
      stateActions,
      contains(
        'Receipt filled. Review the store, date, totals, and lines below before saving.',
      ),
    );
    expect(stateActions, contains('ocr.strongestActionMessage'));
    expect(stateActions, contains('_primaryParsedReceiptWarning(parsed)'));
    expect(
      stateActions,
      contains(
        'Receipt fields filled. Classify it as Business, Personal, or Mixed, then review the lines before saving.',
      ),
    );
    expect(
      stateActions,
      contains(
        'Classify the receipt and review every filled line before saving.',
      ),
    );
    expect(parseReview, contains('warning.reviewInstruction'));
    expect(parseReview, contains('class _ReceiptReadHandoffPanel'));
    expect(parseReview, contains('Reading Receipt Details'));
    expect(
      parseReview,
      contains('next it opens the filled receipt details review'),
    );
    expect(parseReview, contains('Saved Proof'));
    expect(parseReview, contains('Receipt Reader'));
    expect(parseReview, contains('warning.reviewTargetLabel'));
    expect(parseReview, contains('warning.reviewTargetInstruction'));
    expect(parseReview, contains('_ocrRecoverySummaryFor'));
    expect(parseReview, contains(r'Next step: $recoverySummary'));
    expect(parseReview, contains('Scan the receipt with photos'));
    expect(parseReview, contains('Add the missing receipt section'));
    expect(parseReview, contains('Retake the photo'));
    expect(parseReview, contains('ReceiptOcrWarning.compareByPriority'));
    expect(parseReview, contains('Next checks:'));
    expect(parseReview, contains('more OCR'));
    expect(parseReview, contains('warnings need'));
    expect(parseReview, contains(r"'OCR read: ${diagnostics.severity.label}'"));
    expect(parseReview, contains("'warning' : 'warnings'"));

    final ocrService = await File(
      'lib/shared/widgets/receipt_capture/receipt_ocr_service.dart',
    ).readAsString();
    expect(ocrService, contains('String get reviewTargetLabel'));
    expect(ocrService, contains('String get reviewTargetInstruction'));
    expect(
      ocrService,
      contains('List<ReceiptOcrWarning> get prioritizedWarnings'),
    );
    expect(ocrService, contains('int get priorityRank'));
    expect(ocrService, contains('static int compareByPriority'));
    expect(ocrService, contains('Check long receipt overlap'));
    expect(ocrService, contains('Check missing receipt section'));
    expect(ocrService, contains('Check photo proof'));
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
    expect(stateActions, contains('_parserCategoryBuckets(result)'));
    expect(stateActions, contains('_parserReviewCategoryBuckets(result)'));
    expect(stateActions, contains('_parserFieldConfidenceBuckets(result)'));
    expect(stateActions, contains("'parsedCategoryBuckets': categoryBuckets"));
    expect(
      stateActions,
      contains("'reviewCategoryBuckets': reviewCategoryBuckets"),
    );
    expect(
      stateActions,
      contains("'parserFieldConfidenceBuckets': fieldConfidenceBuckets"),
    );
    expect(
      stateActions.indexOf('_applyParsedReceipt(parsed);'),
      lessThan(stateActions.indexOf('void _applyParsedReceipt')),
    );
    expect(lineModels, contains('cameFromAppAssistedReceiptRead'));
    expect(lineEditorActions, contains('_parserReviewLabelForSavedLine'));
    expect(lineEditorActions, contains('_parserReviewReasonForSavedLine'));
    expect(lineEditorActions, contains("'Corrected'"));
    expect(lineEditorActions, contains("'Confirmed'"));
    expect(lineEditorActions, contains('parserNeedsReview: false'));
    expect(
      lineEditorActions,
      contains('User reviewed and corrected this app-filled receipt line.'),
    );
    expect(
      lineEditorActions,
      contains('User reviewed and confirmed this app-filled receipt line.'),
    );
    expect(lineFields, contains('Saving this line marks it reviewed.'));
    expect(stateActions, contains('void _recordAppFilledLineReviewTelemetry'));
    expect(
      stateActions,
      contains('ExpenseTelemetryEventType.appFilledReceiptLineCorrected'),
    );
    expect(
      stateActions,
      contains('ExpenseTelemetryEventType.appFilledReceiptLineConfirmed'),
    );
    expect(stateActions, contains("'lineUse': reviewed.use.name"));
    expect(stateActions, contains("'parserConfidenceBucket'"));
    expect(stateActions, contains('String _confidenceBucket'));

    final telemetry = await File(
      'lib/screens/expenses/data/expense_screen_telemetry.dart',
    ).readAsString();
    expect(telemetry, contains('appFilledReceiptLineConfirmed'));
    expect(telemetry, contains('appFilledReceiptLineCorrected'));
    expect(telemetry, contains('appFilledReceiptLineConfirmedCount'));
    expect(telemetry, contains('appFilledReceiptLineCorrectedCount'));
    expect(telemetry, contains('appFilledReceiptLineCorrectionRate'));
    expect(
      lineModels,
      contains('rawReceiptText.trim().isNotEmpty || hasParserReview'),
    );
    expect(stateActions, contains('void _removeAppAssistedReceiptLines()'));
    expect(stateActions, contains('String? _primaryParsedReceiptWarning'));
    expect(stateActions, contains("lower.contains('missing')"));
    expect(stateActions, contains("lower.contains('could not')"));
    expect(stateActions, contains("lower.contains('low confidence')"));
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
    expect(photoControls, contains('Check Match'));
    expect(photoControls, contains('tap Next to review item prices'));
    expect(entryScreen, contains("'tapFocusSuppressedAfterZoomTotal'"));
    expect(entryScreen, contains("'closeRetryTotal'"));
    expect(entryScreen, contains('_ReceiptReadHandoffPanel('));
    expect(entryScreen, contains('_receiptReadHandoffProofCount'));
    expect(entryScreen, contains('_receiptReadHandoffOcrSourceCount'));
    expect(entryScreen, contains('_receiptReadHandoffDecision'));
    expect(
      entryScreen,
      contains(
        '_receiptReadHandoffDecision = result.stitchResult.reviewDecisionLabel',
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
    expect(entryScreen, contains('bool get _hasAppAssistedReceiptReview'));
    expect(entryScreen, contains('_rawReceiptText.trim().isNotEmpty'));
    expect(entryScreen, contains('_receiptReadAttemptedWithoutText'));
    expect(entryScreen, contains('_lastOcrDiagnostics != null'));
    expect(entryScreen, contains('if (_hasAppAssistedReceiptReview)'));
    expect(
      entryScreen,
      contains('final _receiptReadHandoffKey = GlobalKey();'),
    );
    expect(entryScreen, contains('key: _receiptReadHandoffKey'));
    expect(
      entryScreen,
      contains('void _scrollToReceiptReview({int attempt = 0})'),
    );
    expect(
      entryScreen,
      contains('void _scrollToReceiptReadHandoff({int attempt = 0})'),
    );
    expect(
      entryScreen,
      contains(
        'void _scrollToReceiptFlowKey(GlobalKey key, {int attempt = 0})',
      ),
    );
    expect(
      entryScreen,
      contains(
        'if (mounted) _scrollToReceiptFlowKey(key, attempt: attempt + 1);',
      ),
    );
    expect(entryScreen, contains('if (didRead)'));
    expect(entryScreen, contains('_scrollToReceiptReadHandoff();'));
    expect(
      entryScreen,
      contains(
        'Maintainiac could not read usable receipt text from that photo.',
      ),
    );
    expect(entryScreen, contains('_receiptReadAttemptedWithoutText = true;'));
    expect(
      entryScreen.indexOf(
        '_updateReceiptState(() => _scanningReceiptPhotos = false);',
      ),
      lessThan(entryScreen.indexOf('_scrollToReceiptReview();')),
    );
    expect(entryScreen, contains('void _markReceiptReadStarted()'));
    expect(
      entryScreen,
      contains('void _markReceiptReadFinished(bool didRead)'),
    );
    expect(entryScreen, contains('_ReceiptAppAssistedReviewIntroPanel'));
    expect(
      parseReview,
      contains(
        'Your receipt photo is saved. Maintainiac is reading the clearest image now; next it opens the filled receipt details review.',
      ),
    );
    expect(
      parseReview,
      contains('Do not go back unless you want to keep checking the photo.'),
    );
    expect(parseReview, contains('Review What The App Filled In'));
    expect(
      parseReview,
      contains('Check the store, date, total, tax, and item prices.'),
    );
    expect(parseReview, contains('Simple price review'));
    expect(parseReview, contains('Detailed item review'));
    expect(parseReview, contains('Check highlighted lines'));
    expect(parseReview, contains('No line warnings'));
    expect(parseReview, contains('OCR looked good'));
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
    expect(saveActions, contains('mixed_receipt_split_percent_missing'));
    expect(saveActions, contains('_splitLinesMissingBusinessPercentCount'));
    expect(saveActions, contains('_primaryOcrWarningMessage'));
    expect(saveActions, contains('ReceiptOcrWarning.compareByPriority'));
    expect(saveActions, contains('warning.reviewTargetLabel'));
    expect(saveActions, contains('warning.reviewTargetInstruction'));
    expect(saveActions, contains('warnings also need'));
    expect(saveActions, isNot(contains('if (warning.isBlocking) return')));
    expect(saveActions, isNot(contains('if (warning.isPartial) return')));
    expect(saveActions, isNot(contains('if (warning.needsReview) return')));
    expect(
      saveActions,
      contains(
        'Review the filled receipt lines, then save when everything looks right.',
      ),
    );
    expect(saveActions, contains('Review receipt before saving?'));
    expect(saveActions, contains('Review Receipt'));
    expect(saveActions, contains('Save Anyway'));
    expect(saveActions, contains('Line subtotal is'));
    expect(saveActions, contains('Check for missing items'));
    expect(
      saveActions.indexOf('_receiptSaveReadinessIssues();'),
      lessThan(saveActions.indexOf('ledger.checkDuplicatesFor(receipt)')),
    );

    final totals = await File(
      'lib/screens/expenses/entry/expense_receipt_totals.dart',
    ).readAsString();
    expect(totals, contains('splitPercentIssueCount'));
    expect(totals, contains('One mixed line needs a business percent.'));
    expect(totals, contains('mixed lines need business percents.'));

    expect(entryScreen, contains('splitPercentIssueCount'));
    expect(entryScreen, contains('_splitLinesMissingBusinessPercentCount'));
  });
}
