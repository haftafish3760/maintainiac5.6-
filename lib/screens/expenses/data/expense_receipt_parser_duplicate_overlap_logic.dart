part of 'expense_receipt_parser.dart';

String _duplicateParsedLineWarningGuidance(
  List<_DuplicateParsedLinePair> duplicateLinePairs,
) {
  final hasExact = duplicateLinePairs.any((pair) => pair.isExact);
  final hasNear = duplicateLinePairs.any((pair) => !pair.isExact);
  final hasOneLineGap = duplicateLinePairs.any((pair) => pair.lineDistance > 1);
  final hasAdjacent = duplicateLinePairs.any((pair) => pair.lineDistance <= 1);
  if (hasExact && hasNear) {
    return 'Compare exact and fuzzy OCR overlap before saving.';
  }
  if (hasExact && hasOneLineGap) {
    return 'Compare the repeated line around the OCR noise before saving.';
  }
  if (hasExact && hasAdjacent) {
    return 'Check adjacent receipt overlap before saving.';
  }
  if (hasNear && hasOneLineGap) {
    return 'Compare fuzzy OCR overlap around the noise line before saving.';
  }
  return 'Compare fuzzy OCR overlap before saving.';
}

String? _totalsMathReviewWarning(_ReceiptTotals totals) {
  if (!totals.hasCompleteExplicitMath) return null;
  final subtotal = totals.subtotal!;
  final tax = totals.tax!;
  final total = totals.total!;
  final difference = (subtotal + tax) - total;
  var tolerance = total.abs() * .01;
  if (tolerance < .03) tolerance = .03;
  if (difference.abs() <= tolerance) return null;
  return 'Receipt subtotal plus tax (${_money(subtotal + tax)}) does not match the receipt total (${_money(total)}). Review receipt math and OCR mistakes.';
}

ExpenseReceiptParseDiagnostics _parseDiagnosticsFor({
  required ReceiptParserDepth parserDepth,
  required int maxCatalogCandidates,
  required String? merchantName,
  required DateTime? receiptDate,
  required int? receiptTimeMinutes,
  required _ReceiptTotals totals,
  required List<ExpenseReceiptLineRecord> lines,
  required List<ExpenseReceiptLineReview> lineReviews,
  required ReceiptLayoutMap layoutMap,
  required List<_DuplicateParsedLinePair> duplicateLinePairs,
  required Map<String, int> parserExcludedLineCounts,
}) {
  final expected = totals.subtotal ?? totals.total;
  final lineSubtotal = lines.fold<double>(
    0,
    (sum, line) => sum + line.subtotal,
  );
  double? difference;
  var reconciled = false;
  if (expected != null && expected > 0 && lines.isNotEmpty) {
    difference = lineSubtotal - expected;
    var tolerance = expected.abs() * .015;
    if (tolerance < .05) tolerance = .05;
    reconciled = difference.abs() <= tolerance;
  }
  double? taxMathDifference;
  var taxMathReconciled = false;
  if (totals.hasCompleteExplicitMath) {
    taxMathDifference = (totals.subtotal! + totals.tax!) - totals.total!;
    var tolerance = totals.total!.abs() * .01;
    if (tolerance < .03) tolerance = .03;
    taxMathReconciled = taxMathDifference.abs() <= tolerance;
  }
  final materialLines = lines
      .where((line) => line.category == 'Materials')
      .toList(growable: false);
  final parserLineRoleCounts = _parserLineRoleCountsFor(
    merchantName: merchantName,
    receiptDate: receiptDate,
    receiptTimeMinutes: receiptTimeMinutes,
    totals: totals,
    lines: lines,
    lineReviews: lineReviews,
  );
  final parserTaskCounts = _parserTaskCountsFor(
    merchantName: merchantName,
    receiptDate: receiptDate,
    receiptTimeMinutes: receiptTimeMinutes,
    totals: totals,
    lines: lines,
    lineReviews: lineReviews,
    duplicateLinePairs: duplicateLinePairs,
    layoutSignalCounts: layoutMap.signalCounts,
    parserExcludedLineCounts: parserExcludedLineCounts,
  );
  final parserCategoryCounts = _parserCategoryCountsFor(lines);
  final parserCategoryHealthCounts = _parserCategoryHealthCountsFor(
    lines: lines,
    lineReviews: lineReviews,
    parserDepth: parserDepth,
  );
  final parserItemExpenseFamilyCounts = _parserItemExpenseFamilyCountsFor(
    lines,
  );
  final parserRequiredFieldStatusCounts = _parserRequiredFieldStatusCountsFor(
    merchantName: merchantName,
    receiptDate: receiptDate,
    receiptTimeMinutes: receiptTimeMinutes,
    totals: totals,
    lines: lines,
    lineReviews: lineReviews,
  );
  final parserDownstreamReadinessStatus = _parserDownstreamReadinessStatusFor(
    merchantName: merchantName,
    receiptDate: receiptDate,
    totals: totals,
    lines: lines,
    lineReviews: lineReviews,
  );
  final parserDownstreamReadinessCounts = _parserDownstreamReadinessCountsFor(
    readinessStatus: parserDownstreamReadinessStatus,
    merchantName: merchantName,
    receiptDate: receiptDate,
    totals: totals,
    lines: lines,
    lineReviews: lineReviews,
  );
  final localCoverageEvidence = _localMissingBottomTotalsEvidenceFor(
    totals: totals,
    lines: lines,
    layoutSignalCounts: layoutMap.signalCounts,
  );
  return ExpenseReceiptParseDiagnostics(
    parserDepth: parserDepth,
    maxCatalogCandidates: maxCatalogCandidates,
    detectedLineCount: lines.length,
    reviewLineCount: lineReviews.where((review) => review.needsReview).length,
    catalogMatchedLineCount: lines
        .where((line) => (line.catalogItemId ?? '').trim().isNotEmpty)
        .length,
    materialLineCount: materialLines.length,
    unmatchedMaterialLineCount: materialLines
        .where((line) => (line.catalogItemId ?? '').trim().isEmpty)
        .length,
    negativeLineCount: lines.where((line) => line.subtotal < 0).length,
    adjustmentLineCount: lines
        .where((line) => line.category == 'Receipt Adjustment')
        .length,
    lineSubtotal: lineSubtotal,
    expectedSubtotalOrTotal: expected,
    reconciliationDifference: difference,
    taxMathDifference: taxMathDifference,
    reconciled: reconciled,
    taxMathReconciled: taxMathReconciled,
    hasExplicitSubtotal: totals.hasExplicitSubtotal,
    hasExplicitTax: totals.hasExplicitTax,
    hasExplicitTotal: totals.hasExplicitTotal,
    parserLineRoleCounts: parserLineRoleCounts,
    parserTaskCounts: parserTaskCounts,
    parserDuplicateOverlapSourceLabels:
        _adjacentDuplicateParsedLineSourceLabels(duplicateLinePairs),
    parserDuplicateOverlapWindowLabels:
        _adjacentDuplicateParsedLineWindowLabels(duplicateLinePairs),
    parserDuplicateOverlapConfidenceLabels:
        _adjacentDuplicateParsedLineConfidenceLabels(duplicateLinePairs),
    parserCategoryCounts: parserCategoryCounts,
    parserCategoryHealthCounts: parserCategoryHealthCounts,
    parserItemExpenseFamilyStatus: _parserItemExpenseFamilyStatusFor(
      parserItemExpenseFamilyCounts,
    ),
    parserItemExpenseFamilySummaryLabel:
        _parserItemExpenseFamilySummaryLabelFor(parserItemExpenseFamilyCounts),
    parserItemExpenseFamilyCounts: parserItemExpenseFamilyCounts,
    parserRequiredFieldStatusCounts: parserRequiredFieldStatusCounts,
    parserRequiredFieldStatusLabel: _parserRequiredFieldStatusLabelFor(
      parserRequiredFieldStatusCounts,
    ),
    parserDownstreamReadinessStatus: parserDownstreamReadinessStatus,
    parserDownstreamReadinessCounts: parserDownstreamReadinessCounts,
    genericReceiptStructureStatus: layoutMap.structureStatus,
    genericReceiptStructureSummary: layoutMap.structureSummary,
    genericReceiptZoneCounts: layoutMap.zoneCounts,
    genericReceiptSignalCounts: layoutMap.signalCounts,
    genericReceiptParserLineNumbers: layoutMap.parserLineNumbers,
    genericReceiptClientProofLineNumbers:
        layoutMap.clientProofDefaultVisibleLineNumbers,
    genericReceiptRedactionAnchorCount: layoutMap.lines.length,
    missingBottomTotalsEvidenceCode: localCoverageEvidence.code,
    missingBottomTotalsEvidenceLabel: localCoverageEvidence.label,
    missingBottomTotalsEvidenceFamilyCount: localCoverageEvidence.familyCount,
  );
}

({String code, String label, int familyCount})
_localMissingBottomTotalsEvidenceFor({
  required _ReceiptTotals totals,
  required List<ExpenseReceiptLineRecord> lines,
  required Map<String, int> layoutSignalCounts,
}) {
  final hasPricedLines = lines.any((line) => line.subtotal != 0);
  if (!hasPricedLines) {
    return (code: '', label: '', familyCount: 0);
  }
  final hasFooterOrBarcode = _hasLocalFooterOrBarcodeEvidence(
    layoutSignalCounts,
  );
  if (_hasPricedLinesMissingSummaryTotals(lines, totals)) {
    if (_hasSplitTenderReconciledVisibleTotal(lines, totals)) {
      return (
        code: 'local_text_split_tender_matches_visible_lines',
        label:
            'Local parser found multiple payment rows that match the visible receipt lines. Review split payment instead of adding another photo.',
        familyCount: 1,
      );
    }
    if (hasFooterOrBarcode) {
      return (
        code: 'local_text_footer_seen_totals_missing',
        label:
            'Local parser found receipt footer evidence, but subtotal and total are still missing. Review OCR/crop or enter total manually.',
        familyCount: 1,
      );
    }
    return (
      code: 'local_text_items_without_summary_totals',
      label:
          'Local parser found priced lines but no subtotal or total. The bottom receipt section may be missing.',
      familyCount: 1,
    );
  }
  if (_hasPricedLinesMissingFinalTotal(lines, totals)) {
    if (hasFooterOrBarcode) {
      return (
        code: 'local_text_footer_seen_final_total_missing',
        label:
            'Local parser found receipt footer evidence, but the final total is still missing. Review OCR/crop or confirm the inferred total.',
        familyCount: 1,
      );
    }
    return (
      code: 'local_text_summary_without_final_total',
      label:
          'Local parser found subtotal or tax lines but no final total. The bottom receipt section may be lower down.',
      familyCount: 1,
    );
  }
  return (code: '', label: '', familyCount: 0);
}
