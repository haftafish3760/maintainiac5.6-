part of 'expense_receipt_parser.dart';

bool _hasLocalFooterOrBarcodeEvidence(Map<String, int> layoutSignalCounts) {
  return (layoutSignalCounts['footerCandidate'] ?? 0) > 0 ||
      (layoutSignalCounts['barcodeCandidate'] ?? 0) > 0;
}

bool _hasReceiptSummaryTotalsReady(_ReceiptTotals totals) {
  if (!totals.hasExplicitTotal || totals.total == null) return false;
  return totals.hasExplicitSubtotal ||
      totals.hasExplicitTax ||
      totals.hasCompleteExplicitMath;
}

bool _hasLocalBottomCompletionEvidence(
  List<ExpenseReceiptLineRecord> lines,
  _ReceiptTotals totals,
  Map<String, int> layoutSignalCounts,
) {
  final hasPricedLines = lines.any((line) => line.subtotal != 0);
  if (!hasPricedLines || !totals.hasExplicitTotal) return false;
  if (_hasLocalFooterOrBarcodeEvidence(layoutSignalCounts)) return true;
  return totals.hasCompleteExplicitMath;
}

Map<String, int> _parserLineRoleCountsFor({
  required String? merchantName,
  required DateTime? receiptDate,
  required int? receiptTimeMinutes,
  required _ReceiptTotals totals,
  required List<ExpenseReceiptLineRecord> lines,
  required List<ExpenseReceiptLineReview> lineReviews,
}) {
  final counts = <String, int>{};
  void add(String role, [int count = 1]) {
    if (count <= 0) return;
    counts[role] = (counts[role] ?? 0) + count;
  }

  if ((merchantName ?? '').trim().isNotEmpty) add('vendor');
  if (receiptDate != null) add('date');
  if (receiptTimeMinutes != null) add('time');
  if (totals.hasExplicitSubtotal) add('subtotal');
  if (totals.hasExplicitTax) add('tax');
  if (totals.hasExplicitTotal) add('total');
  if (lines.isNotEmpty) add('item', lines.length);
  add('item_price', lines.where((line) => line.subtotal != 0).length);
  add('review_item', lineReviews.where((review) => review.needsReview).length);
  for (final entry in _categoryCounts(lines).entries) {
    add('category_${_safeParserToken(entry.key)}', entry.value);
  }
  return Map.unmodifiable(counts);
}

Map<String, int> _parserTaskCountsFor({
  required String? merchantName,
  required DateTime? receiptDate,
  required int? receiptTimeMinutes,
  required _ReceiptTotals totals,
  required List<ExpenseReceiptLineRecord> lines,
  required List<ExpenseReceiptLineReview> lineReviews,
  required List<_DuplicateParsedLinePair> duplicateLinePairs,
  required Map<String, int> layoutSignalCounts,
  required Map<String, int> parserExcludedLineCounts,
}) {
  final counts = <String, int>{};
  void add(String role, [int count = 1]) {
    if (count <= 0) return;
    counts[role] = (counts[role] ?? 0) + count;
  }

  add(
    (merchantName ?? '').trim().isEmpty ? 'vendor_missing' : 'vendor_detected',
  );
  add(receiptDate == null ? 'date_missing' : 'date_detected');
  add(receiptTimeMinutes == null ? 'time_missing' : 'time_detected');
  add(totals.hasExplicitSubtotal ? 'subtotal_detected' : 'subtotal_missing');
  add(totals.hasExplicitTax ? 'tax_detected' : 'tax_missing');
  add(totals.hasExplicitTotal ? 'total_detected' : 'total_missing');
  int strongerCount(String layoutKey, String parserKey) {
    final layoutCount = layoutSignalCounts[layoutKey] ?? 0;
    final parserCount = parserExcludedLineCounts[parserKey] ?? 0;
    return layoutCount >= parserCount ? layoutCount : parserCount;
  }

  add('payment_line_excluded', strongerCount('paymentCandidate', 'payment'));
  add(
    'payment_summary_line_excluded',
    parserExcludedLineCounts['paymentSummary'] ?? 0,
  );
  add('card_tender_line_excluded', parserExcludedLineCounts['cardTender'] ?? 0);
  add('cash_tender_line_excluded', parserExcludedLineCounts['cashTender'] ?? 0);
  add(
    'stored_value_tender_line_excluded',
    parserExcludedLineCounts['storedValueTender'] ?? 0,
  );
  add(
    'tender_balance_detail_line_excluded',
    parserExcludedLineCounts['tenderBalanceDetail'] ?? 0,
  );
  add(
    'fleet_tender_line_excluded',
    parserExcludedLineCounts['fleetTender'] ?? 0,
  );
  add(
    'transaction_line_excluded',
    strongerCount('transactionCandidate', 'transaction'),
  );
  add('auth_detail_line_excluded', parserExcludedLineCounts['authDetail'] ?? 0);
  add(
    'reference_detail_line_excluded',
    parserExcludedLineCounts['referenceDetail'] ?? 0,
  );
  add(
    'identity_detail_line_excluded',
    parserExcludedLineCounts['identityDetail'] ?? 0,
  );
  add('barcode_line_excluded', strongerCount('barcodeCandidate', 'barcode'));
  add('footer_line_excluded', layoutSignalCounts['footerCandidate'] ?? 0);
  add(
    'private_receipt_line_protected',
    strongerCount('personalInfoCandidate', 'private'),
  );
  if (_hasPricedLinesMissingSummaryTotals(lines, totals)) {
    add('receipt_missing_totals_manual_review');
    add('receipt_totals_text_missing_review');
    if (_hasSplitTenderReconciledVisibleTotal(lines, totals)) {
      add('receipt_split_tender_matches_visible_lines_review');
    } else if (_hasLocalFooterOrBarcodeEvidence(layoutSignalCounts)) {
      add('receipt_footer_seen_totals_missing_review');
    } else {
      add('receipt_possible_lower_section_missing');
    }
  } else if (_hasPricedLinesMissingFinalTotal(lines, totals)) {
    add('receipt_partial_totals_review');
    add('receipt_final_total_missing_review');
    if (_hasLocalFooterOrBarcodeEvidence(layoutSignalCounts)) {
      add('receipt_footer_seen_final_total_missing_review');
    } else {
      add('receipt_possible_lower_section_missing');
    }
  } else if (_hasTotalOnlyLineMathReview(lines, totals)) {
    add('receipt_total_only_line_math_review');
  } else if (_hasTotalOnlyLinesReady(lines, totals)) {
    add('receipt_total_only_ready');
  }
  if (_hasReceiptSummaryTotalsReady(totals)) {
    add('receipt_summary_totals_ready');
  }
  if (_hasLocalFooterOrBarcodeEvidence(layoutSignalCounts)) {
    add('receipt_footer_or_barcode_seen');
  }
  if (_hasLocalBottomCompletionEvidence(lines, totals, layoutSignalCounts)) {
    add('receipt_bottom_complete_ready');
  }
  add(
    'item_price_ready',
    lines.length - lineReviews.where((r) => r.needsReview).length,
  );
  add(
    'item_price_needs_review',
    lineReviews.where((r) => r.needsReview).length,
  );
  final reviewByLineId = {
    for (final review in lineReviews) review.lineId: review.needsReview,
  };
  final readyFuelLineCount = lines
      .where(
        (line) =>
            _parserCategoryFamilyFor(line.category) == 'fuel' &&
            line.subtotal != 0 &&
            !_fuelLineNeedsDetailReview(line) &&
            !(line.parserNeedsReview || (reviewByLineId[line.id] ?? false)),
      )
      .length;
  final fuelDetailReviewLines = lines.where(_fuelLineNeedsDetailReview).length;
  add('fuel_line_ready', readyFuelLineCount);
  add('fuel_detail_needs_review', fuelDetailReviewLines);
  add(
    'fuel_quantity_needs_review',
    lines.where(_fuelLineQuantityNeedsReview).length,
  );
  add(
    'fuel_unit_price_needs_review',
    lines.where(_fuelLineUnitPriceNeedsReview).length,
  );
  add(
    'fuel_amount_math_needs_review',
    lines.where(_fuelLineAmountMathNeedsReview).length,
  );
  if (readyFuelLineCount > 0 && totals.hasExplicitTotal) {
    add('generic_fuel_receipt_ready');
  }
  final familyCounts = _parserItemExpenseFamilyCountsFor(lines);
  for (final entry in familyCounts.entries) {
    add('parser_expense_family_${entry.key}_item', entry.value);
  }
  if (familyCounts.length > 1) {
    add('parser_expense_family_mixed_receipt', lines.length);
  } else if (familyCounts.length == 1) {
    add('parser_expense_family_single_receipt');
  }
  final duplicateLineCount = duplicateLinePairs
      .where((pair) => pair.isExact)
      .length;
  final nearDuplicateLineCount = duplicateLinePairs
      .where((pair) => !pair.isExact)
      .length;
  final probableOverlapCount = duplicateLineCount + nearDuplicateLineCount;
  if (duplicateLineCount > 0) {
    add('long_receipt_duplicate_text', duplicateLineCount);
  }
  if (nearDuplicateLineCount > 0) {
    add('long_receipt_near_duplicate_text', nearDuplicateLineCount);
  }
  if (probableOverlapCount > 0) {
    add('long_receipt_probable_overlap', probableOverlapCount);
  }
  for (final entry in _categoryCounts(lines).entries) {
    add('category_${_safeParserToken(entry.key)}', entry.value);
  }
  return Map.unmodifiable(counts);
}

Map<String, int> _parserRequiredFieldStatusCountsFor({
  required String? merchantName,
  required DateTime? receiptDate,
  required int? receiptTimeMinutes,
  required _ReceiptTotals totals,
  required List<ExpenseReceiptLineRecord> lines,
  required List<ExpenseReceiptLineReview> lineReviews,
}) {
  final counts = <String, int>{};
  final reviewByLineId = {
    for (final review in lineReviews) review.lineId: review.needsReview,
  };

  void add(String key, [int count = 1]) {
    if (count <= 0) return;
    counts[key] = (counts[key] ?? 0) + count;
  }

  void addFieldStatus(String field, String status, [int count = 1]) {
    add('${field}_$status', count);
    add('parser_required_${status}_total', count);
  }

  addFieldStatus(
    'vendor',
    (merchantName ?? '').trim().isEmpty ? 'missing' : 'ready',
  );
  addFieldStatus('date', receiptDate == null ? 'missing' : 'ready');
  addFieldStatus('time', receiptTimeMinutes == null ? 'missing' : 'ready');
  addFieldStatus('subtotal', totals.hasExplicitSubtotal ? 'ready' : 'missing');
  addFieldStatus('tax', totals.hasExplicitTax ? 'ready' : 'missing');
  addFieldStatus('total', totals.hasExplicitTotal ? 'ready' : 'missing');

  if (lines.isEmpty) {
    addFieldStatus('item_price', 'missing');
    addFieldStatus('category', 'missing');
  } else {
    final pricedLines = lines.where((line) => line.subtotal != 0).length;
    final zeroPriceLines = lines.length - pricedLines;
    final reviewLines = lines
        .where(
          (line) =>
              line.parserNeedsReview || (reviewByLineId[line.id] ?? false),
        )
        .length;
    final readyPricedLines = pricedLines - reviewLines;
    if (readyPricedLines > 0) {
      addFieldStatus('item_price', 'ready', readyPricedLines);
    }
    if (reviewLines > 0) {
      addFieldStatus('item_price', 'needs_review', reviewLines);
    }
    if (zeroPriceLines > 0) {
      addFieldStatus('item_price', 'missing', zeroPriceLines);
    }

    final categoryReady = lines
        .where(
          (line) =>
              _safeParserToken(line.category) != 'uncategorized' &&
              !(line.parserNeedsReview || (reviewByLineId[line.id] ?? false)),
        )
        .length;
    final categoryReview = lines.length - categoryReady;
    if (categoryReady > 0) {
      addFieldStatus('category', 'ready', categoryReady);
    }
    if (categoryReview > 0) {
      addFieldStatus('category', 'needs_review', categoryReview);
    }
  }

  return Map.unmodifiable(counts);
}

String _parserRequiredFieldStatusLabelFor(Map<String, int> counts) {
  final ready = counts['parser_required_ready_total'] ?? 0;
  final review = counts['parser_required_needs_review_total'] ?? 0;
  final missing = counts['parser_required_missing_total'] ?? 0;
  return 'parser_required_receipt_fields:ready=$ready;review=$review;missing=$missing';
}
