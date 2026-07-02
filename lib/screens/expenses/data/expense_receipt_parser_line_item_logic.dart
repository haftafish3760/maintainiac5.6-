part of 'expense_receipt_parser.dart';

List<_ParsedReceiptLine> _readLineItems(
  List<String> rows,
  _MerchantProfile? merchantProfile,
  _ReceiptParseContext context,
  _ReceiptTotals totals,
  ReceiptParserLearningMemory? materialCatalogMemory,
  ReceiptParserDepth parserDepth,
  int maxCatalogCandidates,
) {
  final output = <_ParsedReceiptLine>[];
  String? pendingDescriptionRow;
  for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
    final row = rows[rowIndex];
    final lower = row.toLowerCase();
    if (_isAdministrativeRow(lower) ||
        _datePattern.hasMatch(row) ||
        _hasReceiptTimeCandidateRow(row) ||
        _isIgnoredMoneySummaryRow(lower)) {
      pendingDescriptionRow = null;
      continue;
    }
    if (_looksLikeBarcodeOrReceiptIdMoneyRow(row)) {
      pendingDescriptionRow = null;
      continue;
    }
    final amount = _lineAmountForRow(row, context);
    if (amount == null || amount == 0) {
      if (_looksLikePendingLineDescription(row, merchantProfile, context)) {
        pendingDescriptionRow = pendingDescriptionRow == null
            ? row
            : '$pendingDescriptionRow $row';
      }
      continue;
    }
    if (_isTenderTotalRow(lower) && _negativeReceiptLineType(lower) == null) {
      pendingDescriptionRow = null;
      continue;
    }
    if (_shouldSkipSummaryLineItemRow(
      lower: lower,
      amount: amount,
      context: context,
      totals: totals,
    )) {
      pendingDescriptionRow = null;
      continue;
    }
    final parseRow = _combinedReceiptLineRow(
      pendingDescriptionRow: pendingDescriptionRow,
      pricedRow: row,
      merchantProfile: merchantProfile,
      context: context,
    );
    pendingDescriptionRow = null;
    final description = _cleanLineDescription(parseRow);
    if (description.length < 2) continue;
    final categoryMatch = _categoryFor(
      description,
      merchantProfile,
      context,
      amount: amount,
    );
    final category = categoryMatch.category;
    final parserExpenseFamily = _parserExpenseFamilyForCategory(
      category: category,
      rawRow: parseRow,
      description: description,
    );
    final parserHint = _parserHintForCategory(
      expenseFamily: parserExpenseFamily,
      amount: amount,
    );
    final fuelDetails = category == 'Fuel'
        ? _fuelDetailsFor(
            rawRow: parseRow,
            description: description,
            amount: amount,
            receiptRows: rows,
          )
        : null;
    final materialQuantity = category == 'Materials'
        ? _materialQuantityFor(rawRow: parseRow, description: description)
        : null;
    final materialCatalogMatch =
        category == 'Materials' &&
            parserDepth == ReceiptParserDepth.inventoryMatching
        ? matchReceiptLineToCatalog(
                '$parseRow $description',
                memory: materialCatalogMemory,
                maxCandidates: maxCatalogCandidates,
              ) ??
              matchReceiptLineToCatalog(
                description,
                memory: materialCatalogMemory,
                maxCandidates: maxCatalogCandidates,
              )
        : null;
    final quantity =
        fuelDetails?.quantity ??
        materialQuantity ??
        _quantityFor(description, category);
    final lineId = 'PARSED-${output.length + 1}';
    final ocrSourceLineId =
        'ocr_line_${rowIndex.toString().padLeft(3, '0')}_item';
    final review = _reviewForLine(
      lineId: lineId,
      description: description,
      amount: amount,
      categoryMatch: categoryMatch,
      quantity: quantity,
      materialCatalogMatch: materialCatalogMatch,
      catalogMatchingEnabled:
          parserDepth == ReceiptParserDepth.inventoryMatching,
    );
    output.add(
      _ParsedReceiptLine(
        review: review,
        record: ExpenseReceiptLineRecord(
          id: lineId,
          description: description,
          category: category,
          use: _lineUseFor(rawRow: parseRow, description: description),
          quantity: quantity.quantity,
          unitsPerPackage: quantity.unitsPerPackage,
          unit: quantity.unit,
          subtotal: amount,
          odometerReading: fuelDetails?.odometerReading,
          fuelType: fuelDetails?.fuelType,
          fillType: fuelDetails?.fillType,
          unitPrice:
              fuelDetails?.unitPrice ??
              (quantity.quantity <= 0 ? null : amount / quantity.quantity),
          rawReceiptText: parseRow,
          catalogItemId: materialCatalogMatch?.item.id,
          catalogItemName: materialCatalogMatch?.item.name,
          catalogItemPath: materialCatalogMatch?.item.path,
          catalogMatchConfidence: materialCatalogMatch?.confidence,
          catalogMatchedTerms: materialCatalogMatch?.matchedTerms ?? const [],
          parserConfidence: review.confidence,
          parserReviewLabel: review.label,
          parserReviewReason: review.reason,
          parserNeedsReview: review.needsReview,
          ocrSourceLineId: ocrSourceLineId,
          ocrSourceLineNumber: rowIndex + 1,
          parserExpenseFamily: parserExpenseFamily,
          parserHint: parserHint,
        ),
      ),
    );
  }
  if (output.isEmpty && context.looksLikeFuelReceipt && totals.total != null) {
    final fallback = _fallbackFuelLineFromReceiptRows(
      rows: rows,
      amount: totals.total!,
      parserDepth: parserDepth,
    );
    if (fallback != null) output.add(fallback);
  }
  return output;
}

ExpenseLineUse _lineUseFor({
  required String rawRow,
  required String description,
}) {
  final text = '$rawRow $description'.toLowerCase();
  if (RegExp(r'\b(personal|personal use|non[- ]?business)\b').hasMatch(text)) {
    return ExpenseLineUse.personal;
  }
  return ExpenseLineUse.business;
}

bool _shouldSkipSummaryLineItemRow({
  required String lower,
  required double amount,
  required _ReceiptParseContext context,
  required _ReceiptTotals totals,
}) {
  if (_isSubtotalRow(lower) || _isTaxRow(lower)) return true;
  if (!_isExplicitReceiptTotalRow(lower)) return false;
  return !_isFuelSaleLineItemRow(
    lower: lower,
    amount: amount,
    context: context,
    totals: totals,
  );
}

bool _isFuelSaleLineItemRow({
  required String lower,
  required double amount,
  required _ReceiptParseContext context,
  required _ReceiptTotals totals,
}) {
  if (!context.looksLikeFuelReceipt || amount <= 0) return false;
  final normalized = _normalizeReceiptSummaryKeywordText(lower);
  if (!RegExp(
    r'\b(fuel sale|fuel amount|fuel amt|pump total)\b',
  ).hasMatch(normalized)) {
    return false;
  }
  final receiptTotal = totals.total;
  if (receiptTotal != null && (amount - receiptTotal).abs() < .01) {
    return false;
  }
  return true;
}

_ParsedReceiptLine? _fallbackFuelLineFromReceiptRows({
  required List<String> rows,
  required double amount,
  required ReceiptParserDepth parserDepth,
}) {
  if (amount <= 0) return null;
  final receiptText = rows.join(' ');
  if (!_looksLikeStrongFuelReceiptLine(receiptText.toLowerCase())) return null;
  final details = _fuelDetailsFor(
    rawRow: receiptText,
    description: 'Fuel',
    amount: amount,
    receiptRows: rows,
  );
  if (_fuelLineQuantityNeedsReview(
        ExpenseReceiptLineRecord(
          id: 'PARSED-FUEL-FALLBACK-CHECK',
          description: 'Fuel',
          category: 'Fuel',
          use: ExpenseLineUse.business,
          quantity: details.quantity.quantity,
          unitsPerPackage: details.quantity.unitsPerPackage,
          unit: details.quantity.unit,
          subtotal: amount,
          fuelType: details.fuelType,
          fillType: details.fillType,
          unitPrice: details.unitPrice,
          rawReceiptText: receiptText,
        ),
      ) &&
      details.unitPrice == null) {
    return null;
  }
  const categoryMatch = _CategoryMatch(
    category: 'Fuel',
    confidence: .88,
    reason:
        'Receipt-level fuel rows and total were combined into one fuel line.',
  );
  const lineId = 'PARSED-1';
  final description = _fallbackFuelDescriptionFor(
    receiptRows: rows,
    details: details,
  );
  final review = _reviewForLine(
    lineId: lineId,
    description: description,
    amount: amount,
    categoryMatch: categoryMatch,
    quantity: details.quantity,
    catalogMatchingEnabled: parserDepth == ReceiptParserDepth.inventoryMatching,
  );
  return _ParsedReceiptLine(
    review: review,
    record: ExpenseReceiptLineRecord(
      id: lineId,
      description: description,
      category: 'Fuel',
      use: ExpenseLineUse.business,
      quantity: details.quantity.quantity,
      unitsPerPackage: details.quantity.unitsPerPackage,
      unit: details.quantity.unit,
      subtotal: amount,
      odometerReading: details.odometerReading,
      fuelType: details.fuelType,
      fillType: details.fillType,
      unitPrice:
          details.unitPrice ??
          (details.quantity.quantity <= 0
              ? null
              : amount / details.quantity.quantity),
      rawReceiptText: receiptText,
      parserConfidence: review.confidence,
      parserReviewLabel: review.label,
      parserReviewReason: review.reason,
      parserNeedsReview: review.needsReview,
      ocrSourceLineId: 'ocr_line_fuel_fallback_item',
      ocrSourceLineNumber: 0,
      parserExpenseFamily: 'fuel',
      parserHint: _parserHintForCategory(expenseFamily: 'fuel', amount: amount),
    ),
  );
}

String? _lineTotalReviewWarning(
  List<ExpenseReceiptLineRecord> lines,
  _ReceiptTotals totals,
) {
  if (lines.isEmpty) return null;
  final expected = totals.subtotal ?? totals.total;
  if (expected == null || expected <= 0) return null;
  final lineTotal = lines.fold<double>(0, (sum, line) => sum + line.subtotal);
  final difference = (lineTotal - expected).abs();
  var tolerance = expected.abs() * .015;
  if (tolerance < .05) tolerance = .05;
  if (difference <= tolerance) return null;
  return 'Parsed line totals (${_money(lineTotal)}) do not match the receipt ${totals.subtotal == null ? 'total' : 'subtotal'} (${_money(expected)}). Review missing lines, discounts, and OCR mistakes.';
}

String? _duplicateParsedLineReviewWarning(
  List<_DuplicateParsedLinePair> duplicateLinePairs,
) {
  final duplicateCount = duplicateLinePairs.length;
  if (duplicateCount == 0) return null;
  final guidance = _duplicateParsedLineWarningGuidance(duplicateLinePairs);
  return duplicateCount == 1
      ? 'Possible repeated receipt line found. $guidance'
      : '$duplicateCount possible repeated receipt lines found. $guidance';
}
