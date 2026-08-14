part of 'expense_receipt_parser.dart';

ExpenseReceiptParseResult parseExpenseReceiptText(
  String sourceText, {
  DateTime? fallbackDate,
  ReceiptParserLearningMemory? materialCatalogMemory,
  ReceiptParserDepth parserDepth = ReceiptParserDepth.lineItems,
  int maxCatalogCandidates = 80,
  String? targetCategory,
}) {
  final rows = sourceText
      .split(RegExp(r'\r?\n'))
      .map(_normalizeOcrRow)
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  if (rows.isEmpty) {
    return ExpenseReceiptParseResult(
      sourceText: sourceText,
      lines: const [],
      quality: const ExpenseReceiptParseQuality(
        confidence: 0,
        needsReview: true,
        reasons: ['No readable receipt text was found.'],
      ),
      warnings: const ['No readable receipt text was found.'],
    );
  }

  final totals = _readTotals(rows);
  final layoutMap = const ReceiptLayoutAnalyzer().analyzeLines(rows);
  final parsedDate = _readDate(rows);
  final date = parsedDate ?? fallbackDate;
  final time = _readTimeMinutes(rows);
  final merchantProfile = _readMerchantProfile(rows);
  final merchant = merchantProfile?.displayName ?? _readMerchant(rows);
  final context = _ReceiptParseContext.fromRows(
    rows,
    targetCategory: targetCategory,
  );
  final parserExcludedLineCounts = _parserExcludedLineCountsFor(rows);
  final parsedLines = parserDepth == ReceiptParserDepth.proofTotalsOnly
      ? const <_ParsedReceiptLine>[]
      : _readLineItems(
          rows,
          merchantProfile,
          context,
          totals,
          materialCatalogMemory,
          parserDepth,
          maxCatalogCandidates,
        );
  final lineRows = parsedLines.map((line) => line.record).toList();
  final reviewTotal = _receiptReviewTotalFromAvailableEvidence(
    totals: totals,
    lines: lineRows,
  );
  final duplicateLinePairs = _adjacentDuplicateParsedLinePairs(lineRows);
  final warnings = <String>[];

  if (parserDepth == ReceiptParserDepth.proofTotalsOnly) {
    warnings.add(
      'Performance mode read the receipt header and totals only. Add line items manually if you need item detail.',
    );
  } else if (lineRows.isEmpty) {
    warnings.add(_noLineItemRecoveryWarningFor(totals));
  }
  if (_hasTotalOnlyLineMathReview(lineRows, totals)) {
    warnings.add(
      'Receipt total was found, but parsed line amounts do not match it. Review item lines or enter missing subtotal/tax before saving.',
    );
  } else if (_hasSplitTenderReconciledVisibleTotal(lineRows, totals)) {
    warnings.add(
      'Multiple payment rows match the visible receipt lines. Review the split payment before saving.',
    );
  } else if (_hasPricedLinesMissingSummaryTotals(lineRows, totals)) {
    if (_hasLocalFooterOrBarcodeEvidence(layoutMap.signalCounts)) {
      warnings.add(
        'The printed total was not found. A working total was calculated from the visible items; check it before saving.',
      );
    } else {
      warnings.add(
        'The printed total was not found. A working total was calculated from the visible items. If the receipt continues, add the lower section before saving.',
      );
    }
  } else if (_hasPricedLinesMissingFinalTotal(lineRows, totals)) {
    if (_hasLocalFooterOrBarcodeEvidence(layoutMap.signalCounts)) {
      warnings.add(
        'The final printed total was not found. Check the working total before saving.',
      );
    } else {
      warnings.add(
        'The final printed total was not found. Check the working total, and add the lower section if the receipt continues.',
      );
    }
  }
  final totalsMathWarning = _totalsMathReviewWarning(totals);
  if (totalsMathWarning != null) warnings.add(totalsMathWarning);
  final lineTotalWarning = _lineTotalReviewWarning(lineRows, totals);
  if (lineTotalWarning != null) warnings.add(lineTotalWarning);
  final duplicateLineWarning = _duplicateParsedLineReviewWarning(
    duplicateLinePairs,
  );
  if (duplicateLineWarning != null) warnings.add(duplicateLineWarning);
  final lowConfidenceCount = parsedLines
      .where((line) => line.review.needsReview)
      .length;
  if (lowConfidenceCount > 0) {
    warnings.add(
      '$lowConfidenceCount parsed receipt ${lowConfidenceCount == 1 ? 'line needs' : 'lines need'} review.',
    );
    if (parsedLines.length > 1 &&
        (lowConfidenceCount / parsedLines.length) > .5) {
      warnings.add(
        'Most parsed receipt lines need review before saving this receipt.',
      );
    }
  }
  final maintenanceHints = _maintenanceHintsFor(
    rows: rows,
    lines: lineRows,
    context: context,
  );
  final lineReviews = parsedLines
      .map((line) => line.review)
      .toList(growable: false);
  final baseDiagnostics = _parseDiagnosticsFor(
    parserDepth: parserDepth,
    maxCatalogCandidates: maxCatalogCandidates,
    merchantName: merchant,
    receiptDate: date,
    receiptTimeMinutes: time,
    totals: totals,
    lines: lineRows,
    lineReviews: lineReviews,
    layoutMap: layoutMap,
    duplicateLinePairs: duplicateLinePairs,
    parserExcludedLineCounts: parserExcludedLineCounts,
  );
  final fieldConfidences = _fieldConfidencesFor(
    merchantName: merchant,
    merchantProfile: merchantProfile,
    parsedDate: parsedDate,
    fallbackDate: fallbackDate,
    receiptTimeMinutes: time,
    totals: totals,
    lines: lineRows,
    lineReviews: lineReviews,
    diagnostics: baseDiagnostics,
  );
  final diagnostics = baseDiagnostics.copyWith(
    fieldConfidences: fieldConfidences,
  );
  final quality = _parseQualityFor(
    merchantName: merchant,
    receiptDate: date,
    totals: totals,
    lines: lineRows,
    lineReviews: lineReviews,
    warnings: warnings,
  );

  return ExpenseReceiptParseResult(
    sourceText: sourceText,
    merchantName: merchant,
    receiptDate: date == null
        ? null
        : DateTime(date.year, date.month, date.day),
    receiptTimeMinutes: time,
    enteredSubtotal: totals.subtotal,
    enteredTax: totals.tax,
    enteredTotal: reviewTotal,
    lines: lineRows,
    lineReviews: lineReviews,
    maintenanceHints: maintenanceHints,
    quality: quality,
    fieldConfidences: fieldConfidences,
    warnings: warnings,
    diagnostics: diagnostics,
  );
}

double? _receiptReviewTotalFromAvailableEvidence({
  required _ReceiptTotals totals,
  required List<ExpenseReceiptLineRecord> lines,
}) {
  if (totals.total != null) return totals.total;
  final pricedLines = lines.where((line) => line.subtotal != 0).toList();
  if (pricedLines.isEmpty ||
      pricedLines.any((line) => !line.subtotal.isFinite)) {
    return null;
  }
  final visibleTotal = pricedLines.fold<double>(
    0,
    (sum, line) => sum + line.subtotal,
  );
  if (!visibleTotal.isFinite || visibleTotal.abs() < .005) return null;
  return _roundMoney(visibleTotal);
}
