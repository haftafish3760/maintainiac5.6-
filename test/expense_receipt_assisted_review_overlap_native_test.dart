import 'package:flutter_test/flutter_test.dart';

import 'helpers/expense_receipt_assisted_review_source_fixture.dart';

void main() {
  test('assisted receipt review exposes overlap and native diagnostics', () async {
    final source = await readAssistedReviewSourceFixture();
    final entryScreen = source.entryScreen;
    final attachmentPanel = source.attachmentPanel;
    final parseReview = source.parseReview;
    final parseModels = source.parseModels;
    final parseLogic = source.parseLogic;
    final ocrService = source.ocrService;
    expect(parseModels, contains('long_receipt_near_duplicate_text'));
    expect(parseModels, contains('parserTaskCount'));
    expect(parseLogic, contains('_DuplicateParsedLinePair'));
    expect(parseLogic, contains('_DuplicateParsedLineMatchType.near'));
    expect(parseLogic, contains('_boundedEditDistance'));
    expect(parseLogic, contains('final maxCandidateIndex = (index + 2)'));
    expect(parseModels, contains('parserDuplicateOverlapSourceLabels'));
    expect(parseModels, contains('parserDuplicateOverlapWindowLabels'));
    expect(parseModels, contains('parserDuplicateOverlapWindowSummaryLabel'));
    expect(parseModels, contains('parserDuplicateOverlapConfidenceLabels'));
    expect(
      parseModels,
      contains('parserDuplicateOverlapConfidenceSummaryLabel'),
    );
    expect(parseModels, contains('parserDuplicateOverlapEvidenceSummaryLabel'));
    expect(parseModels, contains('hasParserDuplicateOverlapSourceLabels'));
    expect(parseLogic, contains('_adjacentDuplicateParsedLineWindowLabels'));
    expect(
      parseLogic,
      contains('_adjacentDuplicateParsedLineConfidenceLabels'),
    );
    expect(parseLogic, contains('final duplicateLinePairs'));
    expect(parseLogic, contains('duplicateLinePairs: duplicateLinePairs'));
    expect(
      parseLogic,
      contains('_duplicateParsedLineReviewWarning(\n    duplicateLinePairs'),
    );
    expect(parseLogic, contains('_duplicateParsedLineWarningGuidance'));
    expect(
      parseLogic,
      contains('Compare exact and fuzzy OCR overlap before saving.'),
    );
    expect(
      parseLogic,
      contains(
        'Compare fuzzy OCR overlap around the noise line before saving.',
      ),
    );
    expect(parseLogic, contains('_hasPricedLinesMissingSummaryTotals'));
    expect(parseLogic, contains('_hasPricedLinesMissingFinalTotal'));
    expect(parseLogic, contains('_hasTotalOnlyLinesReady'));
    expect(parseLogic, contains('_hasTotalOnlyLineMathReview'));
    expect(parseLogic, contains('receipt_partial_totals_review'));
    expect(parseLogic, contains('receipt_total_only_ready'));
    expect(parseLogic, contains('receipt_total_only_line_math_review'));
    expect(parseLogic, contains('receipt_possible_lower_section_missing'));
    expect(parseLogic, contains('payment_line_excluded'));
    expect(parseLogic, contains('transaction_line_excluded'));
    expect(parseLogic, contains('private_receipt_line_protected'));
    expect(parseLogic, contains('fuel_line_ready'));
    expect(parseLogic, contains('generic_fuel_receipt_ready'));
    expect(parseLogic, contains('_fuelLineNeedsDetailReview'));
    expect(parseLogic, contains('fuel_detail_needs_review'));
    expect(parseLogic, contains('fuel_quantity_needs_review'));
    expect(parseLogic, contains('fuel_unit_price_needs_review'));
    expect(parseLogic, contains('_fuelLineHasParsedQuantityEvidence'));
    expect(parseReview, contains('_parserFuelActionLabelsFor'));
    expect(
      parseReview,
      contains("..._parserFuelActionLabelsFor(parseDiagnostics)"),
    );
    expect(parseReview, contains("tasks['fuel_detail_needs_review']"));
    expect(parseReview, contains("tasks['fuel_quantity_needs_review']"));
    expect(parseReview, contains("tasks['fuel_unit_price_needs_review']"));
    expect(parseReview, contains("tasks['fuel_detail_ready']"));
    expect(parseReview, contains('Check fuel details'));
    expect(parseReview, contains('Check fuel gallons'));
    expect(parseReview, contains('Check fuel unit price'));
    expect(parseReview, contains('Review fuel gallons/price'));
    expect(parseReview, contains('Classify fuel expense'));
    expect(
      parseReview,
      contains('fuel gallons and unit price are ready for app-assisted review'),
    );
    expect(
      parseLogic,
      contains('Subtotal and total were not found. If this is a long receipt'),
    );
    expect(
      parseLogic,
      contains('_adjacentDuplicateParsedLineSourceLabels(duplicateLinePairs)'),
    );
    expect(
      parseLogic,
      contains('_adjacentDuplicateParsedLineWindowLabels(duplicateLinePairs)'),
    );
    expect(
      parseLogic,
      contains(
        '_adjacentDuplicateParsedLineConfidenceLabels(duplicateLinePairs)',
      ),
    );
    expect(parseLogic, contains('confidenceLabel'));
    expect(parseLogic, contains('high-confidence overlap'));
    expect(parseLogic, contains('high-confidence one-line overlap'));
    expect(parseLogic, contains('review OCR overlap'));
    expect(parseLogic, contains('lineDistance: candidateIndex - index'));
    expect(parseLogic, contains('one-line gap overlap'));
    expect(parseModels, contains('parserDuplicateOverlapAnchorCount'));
    expect(parseModels, contains('parserDuplicateOverlapSourceSummaryLabel'));
    expect(parseModels, contains('parserDuplicateOverlapReviewLabel'));
    expect(parseModels, contains('parserDuplicateOverlapReviewInstruction'));
    expect(parseReview, contains('_parserDuplicateOverlapActionLabelsFor'));
    expect(parseReview, contains('Compare \$sourceLabel'));
    expect(parseReview, contains('Overlap: \$confidenceLabel'));
    expect(
      parseReview,
      contains("label.startsWith('Overlap: high-confidence')"),
    );
    expect(parseReview, contains("label.startsWith('Overlap: probable')"));
    expect(parseReview, contains("label.startsWith('Overlap: review')"));
    expect(parseReview, contains("label.startsWith('Compare ')"));
    expect(parseReview, contains('parserDuplicateOverlapReviewLabel'));
    expect(parseReview, contains('parserDuplicateOverlapReviewInstruction'));
    expect(parseReview, contains('parserDuplicateOverlapEvidenceSummaryLabel'));
    expect(parseReview, contains('Overlap evidence:'));
    expect(parseModels, contains('Check repeated overlap line'));
    expect(parseModels, contains('Check repeated overlap near'));
    expect(
      parseModels,
      contains('repeated receipt overlap is not counted twice'),
    );
    expect(parseReview, contains('duplicates are not counted twice'));
    expect(parseReview, contains("tasks['long_receipt_section_gap']"));
    expect(parseReview, contains('Add missing middle section'));
    expect(parseReview, contains('Check receipt photo order'));
    expect(parseReview, contains('Add line manually'));
    expect(parseReview, contains('Use receipt total'));
    expect(parseReview, contains('Check photo order'));
    expect(parseReview, contains('Add missing section'));
    expect(parseReview, contains('Check subtotal'));
    expect(parseReview, contains('Review line prices'));
    expect(parseReview, contains('Review low-confidence lines'));
    expect(parseReview, contains('Optional parser pack may help'));
    expect(parseReview, contains('Enter manually'));
    expect(parseReview, contains('Continue local review'));
    expect(parseReview, contains('Save proof'));
    expect(parseReview, contains('Fix base receipt flow'));
    expect(parseReview, contains('readyLineLabel'));
    expect(parseReview, contains('reviewLineLabel'));
    expect(parseReview, contains('lineMapLabel'));
    expect(parseReview, contains('parserReadyLineCount'));
    expect(parseReview, contains('parserReviewSignalCount'));
    expect(parseReview, contains('ordered'));
    expect(parseReview, contains('lineMapLabel: lineMapLabel'));
    expect(
      entryScreen,
      contains('Map<String, VoidCallback> get _ocrReviewActionCallbacks'),
    );
    expect(entryScreen, contains('_scrollToReceiptCapture'));
    expect(entryScreen, contains('_addBusinessReceiptLineFromOcrAction'));
    expect(entryScreen, contains('_useReceiptTotalAsBusinessFromOcrAction'));
    expect(
      entryScreen,
      contains('ocrActionCallbacks: _ocrReviewActionCallbacks'),
    );
    expect(attachmentPanel, contains('class _ReceiptCaptureTargetGuidance'));
    expect(
      attachmentPanel,
      contains('settings?.cameraLongReceiptTips != false'),
    );
    expect(attachmentPanel, contains('Long receipt? Scan top to bottom.'));
    expect(attachmentPanel, contains('Need another receipt section?'));
    expect(attachmentPanel, contains('Add Receipt Photo'));
    expect(attachmentPanel, contains('a little overlap'));
    expect(attachmentPanel, contains('top, middle, bottom'));
    expect(
      parseReview,
      contains('Receipt structure looks ready for app-assisted review.'),
    );
    expect(
      parseReview,
      contains('Receipt structure needs review: check the store name'),
    );
    expect(
      parseReview,
      contains(
        'Receipt structure needs review: receipt sections may be out of order or missing.',
      ),
    );
    expect(
      parseReview,
      contains(
        'Receipt structure needs review: subtotal, tax, and total do not line up.',
      ),
    );
    expect(parseReview, contains('_ocrRecoverySummaryFor'));
    expect(parseReview, contains(r'Next step: $recoverySummary'));
    expect(parseReview, contains('Scan the receipt with photos'));
    expect(parseReview, contains('Add the missing receipt section'));
    expect(parseReview, contains('Retake the photo'));
    expect(parseReview, contains('ReceiptOcrWarning.compareByPriority'));
    expect(parseReview, contains('Next checks:'));
    expect(parseReview, contains('_ocrAcceptedPhotoCueFor'));
    expect(parseReview, contains('_ocrAcceptedPhotoActionLabelsFor'));
    expect(parseReview, contains('_ocrAcceptedPhotoWarningCueStatus'));
    expect(
      parseReview,
      contains("diagnostics.ocrSourceHandoffContract['reviewCueStatus']"),
    );
    expect(parseReview, contains('ocrSourceHandoffWarningProfileCounts'));
    expect(parseReview, contains('Photo cue: saved darker than preview'));
    expect(parseReview, contains('Check totals before save'));
    expect(parseReview, contains('Check washed-out prices'));
    expect(parseReview, contains('Check bottom totals'));
    expect(parseReview, contains('more OCR'));
    expect(parseReview, contains('warnings need'));
    expect(parseReview, contains(r"'OCR read: ${diagnostics.severity.label}'"));
    expect(parseReview, contains("'warning' : 'warnings'"));
    expect(ocrService, contains('Parser signals'));
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
    expect(ocrService, contains('_parserTaskCountsWithReceiptCoverage'));
    expect(ocrService, contains('receipt_final_total_missing_review'));
    expect(ocrService, contains('receipt_possible_lower_section_missing'));
    expect(ocrService, contains('totalOnlyLineMathReconciled'));
    expect(ocrService, contains('receipt_total_only_ready'));
    expect(ocrService, contains('receipt_total_only_line_math_review'));
    expect(ocrService, contains('fuelReadyLineIds'));
    expect(ocrService, contains('fuel_line_ready'));
    expect(ocrService, contains('fuelQuantitySignalLineIds'));
    expect(ocrService, contains('fuelUnitPriceSignalLineIds'));
    expect(ocrService, contains('fuelDetailReadyLineIds'));
    expect(ocrService, contains('fuel_quantity_signal'));
    expect(ocrService, contains('fuel_unit_price_signal'));
    expect(ocrService, contains('fuel_detail_ready'));
    expect(ocrService, contains('_looksLikeFuelReceiptQuantitySignal'));
    expect(ocrService, contains('_looksLikeFuelReceiptUnitPriceSignal'));
  });
}
