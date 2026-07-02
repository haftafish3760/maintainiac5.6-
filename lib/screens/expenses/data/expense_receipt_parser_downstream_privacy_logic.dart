part of 'expense_receipt_parser.dart';

String _parserDownstreamReadinessStatusFor({
  required String? merchantName,
  required DateTime? receiptDate,
  required _ReceiptTotals totals,
  required List<ExpenseReceiptLineRecord> lines,
  required List<ExpenseReceiptLineReview> lineReviews,
}) {
  final hasVendor = (merchantName ?? '').trim().isNotEmpty;
  final hasHeader = hasVendor || receiptDate != null;
  final hasTotal = totals.hasExplicitTotal || totals.hasExplicitSubtotal;
  final reviewByLineId = {
    for (final review in lineReviews) review.lineId: review.needsReview,
  };
  final pricedLines = lines.where((line) => line.subtotal != 0).toList();
  final reviewLines = lines
      .where(
        (line) => line.parserNeedsReview || (reviewByLineId[line.id] ?? false),
      )
      .length;
  final readyLines = pricedLines.length - reviewLines;
  final expected = totals.subtotal ?? totals.total;
  final lineSubtotal = lines.fold<double>(
    0,
    (sum, line) => sum + line.subtotal,
  );
  var receiptMathNeedsReview = false;
  if (expected != null && expected > 0 && lines.isNotEmpty) {
    var tolerance = expected.abs() * .015;
    if (tolerance < .05) tolerance = .05;
    receiptMathNeedsReview = (lineSubtotal - expected).abs() > tolerance;
  }
  if (totals.hasCompleteExplicitMath) {
    var tolerance = totals.total!.abs() * .01;
    if (tolerance < .03) tolerance = .03;
    receiptMathNeedsReview =
        receiptMathNeedsReview ||
        ((totals.subtotal! + totals.tax!) - totals.total!).abs() > tolerance;
  }
  final pricedFamilies = lines
      .where((line) => line.subtotal != 0)
      .map((line) => _parserCategoryFamilyFor(line.category))
      .toList();
  final readyPricedFamilies = lines
      .where(
        (line) =>
            line.subtotal != 0 &&
            !(line.parserNeedsReview || (reviewByLineId[line.id] ?? false)),
      )
      .map((line) => _parserCategoryFamilyFor(line.category))
      .toList();
  final materialReady = readyPricedFamilies.contains('materials');
  final vehicleReady =
      readyPricedFamilies.any(_isVehicleCostFamily) &&
      !pricedFamilies.any(_isGeneralExpenseFamily);

  if (!hasHeader && !hasTotal && lines.isEmpty) return 'proof_needs_review';
  if (lines.isEmpty) {
    return hasTotal ? 'proof_total_only' : 'proof_needs_review';
  }
  if (_hasPricedLinesMissingSummaryTotals(lines, totals)) {
    return 'expense_lines_need_review';
  }
  if (_hasPricedLinesMissingFinalTotal(lines, totals)) {
    return 'expense_lines_need_review';
  }
  if (_hasTotalOnlyLineMathReview(lines, totals)) {
    return 'expense_lines_need_review';
  }
  if (receiptMathNeedsReview) return 'expense_lines_need_review';
  if (materialReady) return 'inventory_material_ready';
  if (vehicleReady) return 'vehicle_cost_ready';
  if (readyLines > 0 && reviewLines == 0 && hasVendor && hasTotal) {
    return 'expense_lines_ready';
  }
  return 'expense_lines_need_review';
}

Map<String, int> _parserDownstreamReadinessCountsFor({
  required String readinessStatus,
  required String? merchantName,
  required DateTime? receiptDate,
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

  add('parser_downstream_$readinessStatus');
  add((merchantName ?? '').trim().isEmpty ? 'vendor_missing' : 'vendor_ready');
  add(receiptDate == null ? 'date_missing' : 'date_ready');
  add(totals.hasExplicitSubtotal ? 'subtotal_ready' : 'subtotal_missing');
  add(totals.hasExplicitTax ? 'tax_ready' : 'tax_missing');
  add(totals.hasExplicitTotal ? 'total_ready' : 'total_missing');
  final expected = totals.subtotal ?? totals.total;
  final lineSubtotal = lines.fold<double>(
    0,
    (sum, line) => sum + line.subtotal,
  );
  var receiptMathNeedsReview = false;
  if (expected != null && expected > 0 && lines.isNotEmpty) {
    var tolerance = expected.abs() * .015;
    if (tolerance < .05) tolerance = .05;
    receiptMathNeedsReview = (lineSubtotal - expected).abs() > tolerance;
  }
  if (totals.hasCompleteExplicitMath) {
    var tolerance = totals.total!.abs() * .01;
    if (tolerance < .03) tolerance = .03;
    receiptMathNeedsReview =
        receiptMathNeedsReview ||
        ((totals.subtotal! + totals.tax!) - totals.total!).abs() > tolerance;
  }
  add(
    receiptMathNeedsReview ? 'receipt_math_needs_review' : 'receipt_math_ready',
  );
  if (_hasPricedLinesMissingSummaryTotals(lines, totals)) {
    add('receipt_missing_totals_manual_review');
    add('receipt_totals_text_missing_review');
    add('receipt_possible_lower_section_missing');
  } else if (_hasPricedLinesMissingFinalTotal(lines, totals)) {
    add('receipt_partial_totals_review');
    add('receipt_final_total_missing_review');
    add('receipt_possible_lower_section_missing');
  } else if (_hasTotalOnlyLineMathReview(lines, totals)) {
    add('receipt_total_only_line_math_review');
  } else if (_hasTotalOnlyLinesReady(lines, totals)) {
    add('receipt_total_only_ready');
  }

  if (lines.isEmpty) {
    add('priced_line_missing');
    add('category_missing');
    if (totals.total != null || totals.subtotal != null) {
      add('totals_found_no_safe_lines');
    }
  }

  for (final line in lines) {
    final needsReview =
        line.parserNeedsReview || (reviewByLineId[line.id] ?? false);
    final priced = line.subtotal != 0;
    final family = _parserCategoryFamilyFor(line.category);
    add('line_${needsReview ? 'needs_review' : 'ready'}');
    add(priced ? 'priced_line_ready' : 'priced_line_missing');
    add('category_family_${family}_${needsReview ? 'needs_review' : 'ready'}');
    if (family == 'materials') {
      add(
        needsReview
            ? 'inventory_material_needs_review'
            : 'inventory_material_ready',
      );
    }
    if (family == 'vehicle') {
      add(needsReview ? 'vehicle_cost_needs_review' : 'vehicle_cost_ready');
    }
  }

  return Map.unmodifiable(counts);
}

bool _hasPricedLinesMissingSummaryTotals(
  List<ExpenseReceiptLineRecord> lines,
  _ReceiptTotals totals,
) {
  return lines.any((line) => line.subtotal != 0) &&
      !totals.hasExplicitSubtotal &&
      !totals.hasExplicitTotal;
}

bool _hasSplitTenderReconciledVisibleTotal(
  List<ExpenseReceiptLineRecord> lines,
  _ReceiptTotals totals,
) {
  if (!totals.hasSplitTenderEvidence || totals.hasExplicitTotal) return false;
  final expected =
      totals.subtotal ??
      lines.fold<double>(0, (sum, line) => sum + line.subtotal);
  if (expected <= 0) return false;
  final splitTenderTotal = totals.splitTenderTotal;
  if (splitTenderTotal == null || splitTenderTotal <= 0) return false;
  var tolerance = expected.abs() * .015;
  if (tolerance < .05) tolerance = .05;
  return (splitTenderTotal - expected).abs() <= tolerance;
}

bool _hasPricedLinesMissingFinalTotal(
  List<ExpenseReceiptLineRecord> lines,
  _ReceiptTotals totals,
) {
  return lines.any((line) => line.subtotal != 0) &&
      totals.hasExplicitSubtotal &&
      !totals.hasExplicitTotal;
}

bool _hasTotalOnlyLinesReady(
  List<ExpenseReceiptLineRecord> lines,
  _ReceiptTotals totals,
) {
  return _totalOnlyLineMathDifference(lines, totals) == _LineMathState.ready;
}

bool _hasTotalOnlyLineMathReview(
  List<ExpenseReceiptLineRecord> lines,
  _ReceiptTotals totals,
) {
  return _totalOnlyLineMathDifference(lines, totals) == _LineMathState.review;
}

_LineMathState _totalOnlyLineMathDifference(
  List<ExpenseReceiptLineRecord> lines,
  _ReceiptTotals totals,
) {
  if (!totals.hasExplicitTotal ||
      totals.hasExplicitSubtotal ||
      totals.hasExplicitTax ||
      totals.total == null) {
    return _LineMathState.notApplicable;
  }
  final pricedLines = lines.where((line) => line.subtotal != 0).toList();
  if (pricedLines.isEmpty) return _LineMathState.notApplicable;
  final lineSubtotal = pricedLines.fold<double>(
    0,
    (sum, line) => sum + line.subtotal,
  );
  var tolerance = totals.total!.abs() * .015;
  if (tolerance < .05) tolerance = .05;
  return (lineSubtotal - totals.total!).abs() <= tolerance
      ? _LineMathState.ready
      : _LineMathState.review;
}

enum _LineMathState { notApplicable, ready, review }

String _parserCategoryFamilyFor(String category) {
  final token = _safeParserToken(category);
  if (token == 'fuel') return 'fuel';
  if (token == 'materials') return 'materials';
  if (token == 'groceries' ||
      token == 'grocery' ||
      token == 'meals' ||
      token == 'food') {
    return 'food_or_grocery';
  }
  if (token == 'vehicle_supplies' ||
      token == 'vehicle_parts' ||
      token == 'vehicle_maintenance' ||
      token == 'repair' ||
      token == 'maintenance') {
    return 'vehicle';
  }
  if (token == 'receipt_adjustment') return 'adjustment';
  if (token == 'uncategorized' || token == 'unknown') return 'uncategorized';
  return 'general';
}

bool _isVehicleCostFamily(String family) {
  return family == 'vehicle' || family == 'fuel';
}

bool _isGeneralExpenseFamily(String family) {
  return family != 'vehicle' && family != 'fuel' && family != 'adjustment';
}
