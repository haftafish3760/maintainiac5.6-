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
    // A fuel receipt commonly begins with a store header plus a location or
    // store number (for example, "Market 418"). OCR can make that number look
    // like compact cents, so never treat an unpriced first header as fuel.
    final unpricedFuelHeader =
        context.looksLikeFuelReceipt &&
        rowIndex == 0 &&
        !RegExp(
          r'(?:\$?\d+[\.,]\d{2,4}|\b(?:gal(?:lon)?s?|lit(?:er|re)s?|kwh|kg|gge|dge)\b|@)',
        ).hasMatch(lower);
    // Ignore a visual section divider without discarding preceding dispenser
    // detail. The next fuel-sale amount needs that context for quantity and
    // price, but the heading itself must never become part of its description.
    if (context.looksLikeFuelReceipt && _isFuelReceiptSectionHeading(lower)) {
      continue;
    }
    if (unpricedFuelHeader ||
        _isAdministrativeRow(lower) ||
        (context.looksLikeFuelReceipt && _isFuelReceiptMetadataRow(lower)) ||
        _datePattern.hasMatch(row) ||
        (_hasReceiptTimeCandidateRow(row) &&
            !_looksLikeFuelMeasuredLine(lower) &&
            !_looksLikeStrongFuelReceiptLine(lower)) ||
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
    if (_isFuelSaleLineItemRow(
          lower: lower,
          amount: amount,
          context: context,
          totals: totals,
        ) &&
        output.any(
          (line) =>
              line.record.category == 'Fuel' &&
              (line.record.subtotal - amount).abs() < .005,
        )) {
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
    final lineDescription = fuelDetails == null
        ? description
        : _fuelDescriptionWithRoadClassification(
            description: _fuelDescriptionWithOctane(
              description: description,
              details: fuelDetails,
              receiptRows: rows,
            ),
            details: fuelDetails,
            receiptRows: rows,
          );
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
      description: lineDescription,
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
          description: lineDescription,
          category: category,
          use: _lineUseFor(rawRow: parseRow, description: lineDescription),
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
  final hasFuelLine = output.any((line) => line.record.category == 'Fuel');
  if (!hasFuelLine && context.looksLikeFuelReceipt) {
    final fallbackAmount =
        _measuredFuelSaleAmountFromRows(rows, context) ?? totals.total;
    if (fallbackAmount == null) return output;
    final fallback = _fallbackFuelLineFromReceiptRows(
      rows: rows,
      amount: fallbackAmount,
      parserDepth: parserDepth,
      allowIncompleteFuel: context.targetFuelSelected,
    );
    if (fallback != null) output.add(fallback);
  }
  return output;
}

double? _measuredFuelSaleAmountFromRows(
  List<String> rows,
  _ReceiptParseContext context,
) {
  for (final row in rows) {
    final lower = row.toLowerCase();
    if (!_looksLikeFuelMeasuredLine(lower) &&
        !_looksLikeStrongFuelReceiptLine(lower)) {
      continue;
    }
    if (_isAdministrativeRow(lower) ||
        _isTenderTotalRow(lower) ||
        _isTaxRow(lower) ||
        _isIgnoredMoneySummaryRow(lower)) {
      continue;
    }
    if (RegExp(
      r'\b(session fee|idle fee|parking fee|charging fee|cuota de sesi[oó]n|tarifa por inactividad|estacionamiento)\b',
    ).hasMatch(lower)) {
      continue;
    }
    final amount = _lastMoneyAmount(row) ?? _lineAmountForRow(row, context);
    if (amount != null && amount > 0) return amount;
  }
  return null;
}

ExpenseLineUse _lineUseFor({
  required String rawRow,
  required String description,
}) {
  final text = '$rawRow $description'.toLowerCase();
  if (RegExp(
    r'\b(personal|personal use|non[- ]?business|cig(?:arette)?s?|cigar|'
    r'tobacco|nicotine|vape|beer|wine|alcohol|liquor|lottery|lotto|'
    r'scratch(?:er|off)?|atm fee|atm surcharge|cash advance|cerveza|'
    r'cigarrillos?|loter[ií]a)\b',
  ).hasMatch(text)) {
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
  return true;
}

_ParsedReceiptLine? _fallbackFuelLineFromReceiptRows({
  required List<String> rows,
  required double amount,
  required ReceiptParserDepth parserDepth,
  bool allowIncompleteFuel = false,
}) {
  if (amount <= 0) return null;
  final receiptText = rows.join(' ');
  if (!allowIncompleteFuel &&
      !_looksLikeStrongFuelReceiptLine(receiptText.toLowerCase())) {
    return null;
  }
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
      !allowIncompleteFuel &&
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
