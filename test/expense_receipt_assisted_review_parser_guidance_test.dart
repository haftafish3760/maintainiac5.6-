import 'package:flutter_test/flutter_test.dart';

import 'helpers/expense_receipt_assisted_review_source_fixture.dart';

void main() {
  test('assisted receipt review exposes parser guidance actions', () async {
    final source = await readAssistedReviewSourceFixture();
    final entryScreen = source.entryScreen;
    final attachmentPanel = source.attachmentPanel;
    final importActions = source.importActions;
    final parseReview = source.parseReview;
    final parseModels = source.parseModels;
    expect(parseReview, contains('warning.reviewInstruction'));
    expect(parseReview, contains('fieldStatusChips'));
    expect(parseReview, contains('class _ReceiptFieldStatusChipData'));
    expect(
      parseReview,
      contains('ExpenseReceiptParseDiagnostics? parseDiagnostics'),
    );
    expect(parseReview, contains('parserTaskSummaryLabel'));
    expect(parseReview, contains('parseDiagnostics.parserTaskSummaryLabel'));
    expect(parseReview, contains('parserReviewRootCauseCode'));
    expect(parseReview, contains('parserReviewRootCauseLabel'));
    expect(parseReview, contains('parserReviewRootCauseInstruction'));
    expect(parseReview, contains('parserMathReviewLabel'));
    expect(parseReview, contains('_parserMathActionLabelsFor'));
    expect(parseReview, contains('_parserCategoryActionLabelsFor'));
    expect(parseReview, contains('_receiptFootprintReviewCueFor'));
    expect(parseReview, contains('_receiptFootprintActionLabelsFor'));
    expect(parseReview, contains('defaultDataSaverFootprintSummary'));
    expect(parseReview, contains('defaultDataSaverLocalOnlyAcceptanceGate'));
    expect(parseReview, contains('baseFlowCanRunLocallyNow'));
    expect(parseReview, contains('blocksLowStorageUsers'));
    expect(
      parseReview,
      contains('defaultDataSaverShouldOfferOptionalLocalParserPacks'),
    );
    expect(
      parseReview,
      contains(
        'Receipt capture, receipt reading, and manual line review still work',
      ),
    );
    expect(parseReview, contains('without downloading them.'));
    expect(
      parseReview,
      contains('receipt capture, proof save, and basic local review'),
    );
    expect(parseReview, contains('cannot depend on heavy offline packs'));
    expect(parseReview, contains('optionalLocalDownloadSizeLabel'));
    expect(parseReview, contains('Use assisted help later'));
    expect(parseReview, contains('Continue without add-on'));
    expect(parseReview, contains('Optional add-on later'));
    expect(parseReview, contains('_orderedUniqueActionLabels'));
    expect(parseReview, contains('_actionPriority'));
    expect(
      parseReview,
      contains('..._parserMathActionLabelsFor(parseDiagnostics)'),
    );
    expect(
      parseReview,
      contains('..._parserCategoryActionLabelsFor(parseDiagnostics)'),
    );
    expect(parseReview, contains('Check missing lines'));
    expect(parseReview, contains('Check duplicate lines'));
    expect(parseReview, contains('Use receipt total only'));
    expect(
      parseModels,
      contains(
        'Check missing, duplicate, return, discount, fee, or skipped long-receipt lines',
      ),
    );
    expect(
      parseModels,
      contains('Check subtotal, tax, fees, discounts, and receipt total math'),
    );
    expect(parseReview, contains('downstreamReadinessLabel'));
    expect(parseReview, contains('downstreamReadinessSummaryLabel'));
    expect(parseModels, contains('hasParserGenericFuelReceiptReady'));
    expect(parseModels, contains('Fuel receipt review ready'));
    expect(parseModels, contains('fuel ready'));
    expect(parseReview, contains('hasOcrDownstreamReadyStatus'));
    expect(parseReview, contains('hasParserDownstreamReadyStatus'));
    expect(parseReview, contains('parserDownstreamReadinessStatus'));
    expect(
      parseReview,
      contains("parserDownstreamReadinessCount('priced_line_ready')"),
    );
    expect(
      parseReview,
      contains("parserDownstreamReadinessCount('line_needs_review')"),
    );
    expect(parseReview, contains('inventory_material_ready'));
    expect(parseReview, contains('Icons.rule_folder_rounded'));
    expect(parseReview, contains('classificationReadinessLabel'));
    expect(
      parseReview,
      contains('parseDiagnostics?.receiptClassificationSummaryLabel'),
    );
    expect(parseReview, contains('mixedClassificationEvidenceLabel'));
    expect(parseReview, contains('mixedClassificationReadinessStatus'));
    expect(parseReview, contains('Icons.call_split_rounded'));
    expect(parseReview, contains('itemFamilyReviewLabel'));
    expect(parseReview, contains('ocrItemExpenseFamilySummaryLabel'));
    expect(parseReview, contains('parserItemExpenseFamilySummaryLabel'));
    expect(parseReview, contains('hasAnyMixedItemExpenseFamilies'));
    expect(parseReview, contains('mixedItemFamilyNextStepLabel'));
    expect(parseReview, contains('mixedItemFamilyReviewActionLabel'));
    expect(parseReview, contains('Icons.category_rounded'));
    expect(parseReview, contains('lineIdentityLabel'));
    expect(
      parseReview,
      contains('parseDiagnostics.ocrLineIdentitySummaryLabel'),
    );
    expect(parseReview, contains('Icons.format_list_numbered_rtl_rounded'));
    expect(parseReview, contains('diagnostics.parserTaskCounts'));
    expect(parseReview, contains('_diagnosticCount'));
    expect(parseReview, contains('_readyCount'));
    expect(parseReview, contains('Store needs review'));
    expect(parseReview, contains('Store missing'));
    expect(parseReview, contains('Date needs review'));
    expect(parseReview, contains('Date missing'));
    expect(parseReview, contains('Total missing'));
    expect(parseReview, contains('Tax missing'));
    expect(parseReview, contains('Item prices missing'));
    expect(parseReview, contains('Totals section missing'));
    expect(parseReview, contains('Color(0xFFFF8FA3)'));
    expect(parseReview, contains('Subtotal needs review'));
    expect(parseReview, contains('subtotal_candidate'));
    expect(parseReview, contains('Total needs review'));
    expect(parseReview, contains('total_candidate'));
    expect(parseReview, contains('Tax needs review'));
    expect(parseReview, contains('tax_candidate'));
    expect(parseReview, contains('vendor_candidate'));
    expect(parseReview, contains('date_candidate'));
    expect(parseReview, contains('item_price_ready'));
    expect(parseReview, contains('item_price_needs_review'));
    expect(parseReview, contains('inventory_material_candidate'));
    expect(parseReview, contains('materialCandidates'));
    expect(parseReview, contains('candidates'));
    expect(parseReview, contains('class _ReceiptReadHandoffPanel'));
    expect(parseReview, contains('required this.onReviewDetails'));
    expect(parseReview, contains('required this.routeResultLabel'));
    expect(parseReview, contains('final VoidCallback onReviewDetails;'));
    expect(parseReview, contains('final String routeResultLabel;'));
    expect(
      parseReview,
      contains('onPressed: processingInFlight ? null : onReviewDetails'),
    );
    expect(parseReview, contains("'Review Details'"));
    expect(parseReview, contains("'Show Filled Review'"));
    expect(parseReview, contains("'Open Manual Review'"));
    expect(parseReview, isNot(contains("'Go To Review'")));
    expect(parseReview, contains('Receipt text extracted'));
    expect(
      parseReview,
      contains(
        'Receipt capture, receipt reading, and manual line review still work',
      ),
    );
    expect(parseReview, contains('used the clearest original photo'));
    expect(parseReview, contains('defaultDataSaverFootprintSummary'));
    expect(parseReview, contains('ReceiptReviewStepMetric'));
    expect(parseReview, contains("'Retake / Add Photo'"));
    expect(parseReview, contains("'Add Bottom Section'"));
    expect(parseReview, contains('Saved Proof'));
    expect(parseReview, contains('Clear Original Photo'));
    expect(parseReview, contains('warning.reviewTargetLabel'));
    expect(parseReview, contains('warning.reviewTargetInstruction'));
    expect(parseReview, contains('diagnostics.parserSignalSummaryLabel'));
    expect(parseReview, contains('receiptMayNeedBottomSection'));
    expect(parseReview, contains('receiptMissingBottomEdgeAndTotals'));
    expect(parseReview, contains('shouldSuggestLowerReceiptSection'));
    expect(parseReview, contains('lowerReceiptSectionReviewLabel'));
    expect(parseReview, contains('lowerReceiptSectionReviewInstruction'));
    expect(parseReview, contains('lowerSectionReviewLabel'));
    expect(parseModels, contains('hasParserPossibleLowerSectionMissing'));
    expect(parseReview, contains('Add Lower Section'));
    expect(entryScreen, contains('shouldSuggestLowerReceiptSection'));
    expect(entryScreen, contains('Add the lower receipt section'));
    expect(parseReview, contains('Check for missing bottom'));
    expect(parseReview, contains('Add bottom receipt section'));
    expect(parseReview, contains('Use top ghost slice'));
    expect(parseReview, contains('hasOcrSourceGhostSliceContinuation'));
    expect(parseReview, contains('ocrSourceGhostSliceReviewInstruction'));
    expect(parseReview, contains('Bottom continuation uses top ghost slice'));
    expect(parseReview, contains('Repeat 3-5 lines in top ghost slice'));
    expect(
      parseReview,
      contains('repeat 3-5 readable lines in the top ghost slice'),
    );
    expect(parseReview, contains('receipt_bottom_section_continuation_needed'));
    expect(parseReview, contains('receipt_missing_bottom_edge_and_totals'));
    expect(parseReview, contains('receipt_missing_totals_manual_review'));
    expect(parseReview, contains('receipt_totals_text_missing_review'));
    expect(parseReview, contains('receipt_possible_lower_section_missing'));
    expect(parseReview, contains('receipt_final_total_missing_review'));
    expect(parseReview, contains('Check final receipt total'));
    expect(parseReview, contains('receipt_total_only_ready'));
    expect(parseReview, contains('receipt_total_only_line_math_review'));
    expect(parseReview, contains('Review total-only math'));
    expect(parseReview, contains('receipt_user_confirmed_complete_review'));
    expect(
      parseReview,
      contains('receipt_user_confirmed_missing_bottom_review'),
    );
    expect(parseReview, contains('Review user-confirmed receipt'));
    expect(parseReview, contains('Check lower receipt lines'));
    expect(parseReview, contains('Check lower receipt section'));
    expect(parseReview, contains('Receipt completeness needs confirmation'));
    expect(
      parseReview,
      contains('the user marked this as the full receipt'),
    );
    expect(parseReview, contains('Enter total manually'));
    expect(
      parseReview,
      contains('The next receipt section is needed'),
    );
    expect(parseReview, contains('Receipt details need totals review'));
    expect(parseReview, contains('Bottom section may be missing'));
    expect(parseReview, contains('Bottom edge and totals may be missing'));
    expect(parseReview, contains('ocrSourceSectionReviewLabel'));
    expect(parseReview, contains('ocrSourceSectionReviewInstruction'));
    expect(parseModels, contains('OCR section order looks continuous'));
    expect(parseModels, contains('Only one OCR section reached review'));
    expect(parseModels, contains('OCR sections appear out of order'));
    expect(parseReview, contains('Icons.account_tree_rounded'));
    expect(parseReview, contains('_joinReceiptReviewSentences'));
    expect(parseReview, contains('required this.onAddMissingBottomSection'));
    expect(
      parseReview,
      contains('final VoidCallback onAddMissingBottomSection'),
    );
    expect(parseReview, contains('onPressed: onAddMissingBottomSection'));
    expect(
      parseReview,
      contains(
        'Receipt text was found, but subtotal or total lines were not found.',
      ),
    );
    expect(
      parseReview,
      contains(
        'Receipt text was found, but the bottom edge and subtotal/total lines were not found together.',
      ),
    );
    expect(
      parseReview,
      contains('Add the bottom receipt section and repeat 3-5 readable lines'),
    );
    expect(parseReview, contains('Add Next Receipt Section'));
    expect(parseReview, contains('required this.missingBottomSection'));
    expect(parseReview, contains('Add bottom receipt section'));
    expect(parseReview, contains('required this.missingBottomEdgeAndTotals'));
    expect(
      parseReview,
      contains('repeat 3-5 readable lines in the top ghost slice'),
    );
    expect(
      parseReview,
      contains(
        'Bottom edge and subtotal/total lines were not found together. Add the bottom receipt section and repeat 3-5 readable lines in the top ghost slice so subtotal, total, and final lines can be matched.',
      ),
    );
    expect(
      parseReview,
      contains('Subtotal/total lines were not found. Add the lower section'),
    );
    expect(attachmentPanel, contains('receiptContinuationReasonCode'));
    expect(attachmentPanel, contains('receiptContinuationGuidance'));
    expect(
      importActions,
      contains('ReceiptCaptureContinuationGuide.fromPreviousPhotos'),
    );
    expect(
      importActions,
      contains('reasonCode: _nextReceiptContinuationReasonCode()'),
    );
    expect(
      importActions,
      contains(
        "if (_needsBottomReceiptSection) return 'missing_bottom_edge_and_totals';",
      ),
    );
    expect(
      importActions,
      contains('guidance: _nextReceiptContinuationGuidance()'),
    );
    expect(
      importActions,
      contains(
        'Add the bottom receipt section and repeat 3-5 readable lines in the top ghost slice so subtotal, total, and final lines can be matched.',
      ),
    );
    expect(importActions, contains('options: continuationGuide.applyTo'));
    expect(parseReview, contains('_ocrStructureSummaryFor'));
    expect(parseReview, contains('_ocrStructureActionLabelsFor'));
    expect(parseReview, contains('_ocrParserReadinessSummaryFor'));
    expect(parseReview, contains('_ocrParserReadinessActionLabelsFor'));
    expect(parseReview, contains('diagnostics.parserReadinessStatus'));
    expect(parseReview, contains('Receipt lines are ready for review'));
    expect(parseReview, contains('no_parser_ready_items'));
    expect(parseReview, contains('Check material matches'));
    expect(parseReview, contains('class _ReceiptParseReviewActionChip'));
    expect(parseReview, contains('actionLabels: actionLabels'));
    expect(parseReview, contains('actionCallbacks: actionCallbacks'));
    expect(parseReview, contains('actionCallbacks[action]'));
    expect(parseReview, contains('OutlinedButton.icon'));
    expect(parseReview, contains('Review filled fields'));
    expect(parseReview, contains('Classify Business/Personal/Mixed'));
    expect(parseReview, contains('_ocrParserTaskActionLabelsFor'));
    expect(parseReview, contains("tasks['vendor_missing']"));
    expect(parseReview, contains('Check receipt date'));
    expect(parseReview, contains('Check totals section'));
    expect(parseReview, contains('Check tax line'));
    expect(parseReview, contains("tasks['long_receipt_duplicate_text']"));
    expect(parseReview, contains("tasks['long_receipt_near_duplicate_text']"));
    expect(parseReview, contains('Check removed overlap'));
    expect(parseReview, contains('Confirm no duplicate charges'));
    expect(parseReview, contains("tasks['long_receipt_probable_overlap']"));
    expect(parseReview, contains('Review overlap area'));
    expect(parseReview, contains('Check missing or repeated charges'));
    expect(parseModels, contains('hasParserDuplicateOverlapReview'));
  });
}
