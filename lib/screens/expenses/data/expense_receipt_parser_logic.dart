part of 'expense_receipt_parser.dart';

ExpenseReceiptParseResult parseExpenseReceiptText(
  String sourceText, {
  DateTime? fallbackDate,
  ReceiptParserLearningMemory? materialCatalogMemory,
  ReceiptParserDepth parserDepth = ReceiptParserDepth.inventoryMatching,
  int maxCatalogCandidates = 80,
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
  final parsedDate = _readDate(rows);
  final date = parsedDate ?? fallbackDate;
  final time = _readTimeMinutes(rows);
  final merchantProfile = _readMerchantProfile(rows);
  final merchant = merchantProfile?.displayName ?? _readMerchant(rows);
  final context = _ReceiptParseContext.fromRows(rows);
  final parsedLines = parserDepth == ReceiptParserDepth.proofTotalsOnly
      ? const <_ParsedReceiptLine>[]
      : _readLineItems(
          rows,
          merchantProfile,
          context,
          materialCatalogMemory,
          parserDepth,
          maxCatalogCandidates,
        );
  final lineRows = parsedLines.map((line) => line.record).toList();
  final warnings = <String>[];

  if (parserDepth == ReceiptParserDepth.proofTotalsOnly) {
    warnings.add(
      'Performance mode read the receipt header and totals only. Add line items manually if you need item detail.',
    );
  } else if (lineRows.isEmpty) {
    warnings.add('No receipt line items were detected.');
  }
  if (totals.total != null &&
      lineRows.isNotEmpty &&
      totals.subtotal == null &&
      totals.tax == null) {
    warnings.add('Receipt total found, but subtotal and tax need review.');
  }
  final totalsMathWarning = _totalsMathReviewWarning(totals);
  if (totalsMathWarning != null) warnings.add(totalsMathWarning);
  final lineTotalWarning = _lineTotalReviewWarning(lineRows, totals);
  if (lineTotalWarning != null) warnings.add(lineTotalWarning);
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
    totals: totals,
    lines: lineRows,
    lineReviews: lineReviews,
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
    enteredTotal: totals.total,
    lines: lineRows,
    lineReviews: lineReviews,
    maintenanceHints: maintenanceHints,
    quality: quality,
    fieldConfidences: fieldConfidences,
    warnings: warnings,
    diagnostics: diagnostics,
  );
}

String _normalizeOcrRow(String value) {
  var output = value.trim();
  if (output.isEmpty) return '';
  output = output
      .replaceAll('\u00a0', ' ')
      .replaceAll(RegExp(r'[|]'), ' ')
      .replaceAll(RegExp(r'\bT0TAL\b', caseSensitive: false), 'TOTAL')
      .replaceAll(RegExp(r'\bSUBT0TAL\b', caseSensitive: false), 'SUBTOTAL')
      .replaceAll(RegExp(r'\bAM0UNT\b', caseSensitive: false), 'AMOUNT')
      .replaceAll(RegExp(r"\bL0VE'?S\b", caseSensitive: false), "LOVE'S")
      .replaceAll(RegExp(r'\bL0VES\b', caseSensitive: false), 'LOVES')
      .replaceAll(RegExp(r'\bFLYlNG\b', caseSensitive: false), 'FLYING')
      .replaceAll(RegExp(r'\bL0WES\b', caseSensitive: false), 'LOWES')
      .replaceAll(RegExp(r'\bH0ME\b', caseSensitive: false), 'HOME')
      .replaceAll(
        RegExp(r'\bIMPR0VEMENT\b', caseSensitive: false),
        'IMPROVEMENT',
      )
      .replaceAll(RegExp(r'\bDEP0T\b', caseSensitive: false), 'DEPOT')
      .replaceAll(RegExp(r'\bC0PPER\b', caseSensitive: false), 'COPPER')
      .replaceAll(RegExp(r'\bELB0W\b', caseSensitive: false), 'ELBOW')
      .replaceAll(RegExp(r'\bC0UPLING\b', caseSensitive: false), 'COUPLING')
      .replaceAll(RegExp(r'\bC0NDUIT\b', caseSensitive: false), 'CONDUIT')
      .replaceAll(RegExp(r'\b0IL\b', caseSensitive: false), 'OIL')
      .replaceAll(RegExp(r'\bS0\b', caseSensitive: false), '50')
      .replaceAll(RegExp(r'(?<=\d)O(?=\d)'), '0')
      .replaceAll(RegExp(r'\bO(?=\d)'), '0')
      .replaceAll(RegExp(r'(?<=\d)O\b'), '0')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  output = output.replaceAllMapped(
    RegExp(r'(\d+)\s*,\s*(\d{2})(?!\d)'),
    (match) => '${match.group(1)}.${match.group(2)}',
  );
  return output;
}

_MerchantProfile? _readMerchantProfile(List<String> rows) {
  final head = rows.take(8).join(' ').toLowerCase();
  for (final profile in _merchantProfiles) {
    if (profile.pattern.hasMatch(head)) return profile;
  }
  return null;
}

String? _readMerchant(List<String> rows) {
  for (final row in rows.take(6)) {
    final lower = row.toLowerCase();
    if (_isAdministrativeRow(lower) ||
        _datePattern.hasMatch(row) ||
        _timePattern.hasMatch(row)) {
      continue;
    }
    return _titleCase(
      row
          .replaceAll(RegExp(r'[^a-zA-Z0-9&.\- ]+'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim(),
    );
  }
  return null;
}

DateTime? _readDate(List<String> rows) {
  for (final row in rows) {
    final match = _datePattern.firstMatch(row);
    if (match == null) continue;
    final raw = match.group(0)!;
    final parts = raw.split(RegExp(r'[/-]')).map(int.parse).toList();
    if (raw.startsWith(RegExp(r'\d{4}'))) {
      return _safeDate(parts[0], parts[1], parts[2]);
    }
    final year = parts[2] < 100 ? 2000 + parts[2] : parts[2];
    return _safeDate(year, parts[0], parts[1]);
  }
  return null;
}

DateTime? _safeDate(int year, int month, int day) {
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  return DateTime(year, month, day);
}

int? _readTimeMinutes(List<String> rows) {
  for (final row in rows) {
    final match = _timePattern.firstMatch(row);
    if (match == null) continue;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final marker = match.group(3)?.toLowerCase();
    if (marker == 'pm' && hour < 12) hour += 12;
    if (marker == 'am' && hour == 12) hour = 0;
    if (hour > 23 || minute > 59) return null;
    return hour * 60 + minute;
  }
  return null;
}

_ReceiptTotals _readTotals(List<String> rows) {
  double? subtotal;
  double? tax;
  double? total;
  double? tenderTotal;
  var hasExplicitSubtotal = false;
  var hasExplicitTax = false;
  var hasExplicitTotal = false;
  for (final row in rows) {
    final lower = row.toLowerCase();
    if (_looksLikeAddressOrContactRow(lower)) continue;
    final amount = _lastMoneyAmount(
      row,
      allowCompactCents: _isTotalOrTenderLikeRow(lower),
    );
    if (amount == null) continue;
    if (_isIgnoredMoneySummaryRow(lower)) continue;
    if (_isSubtotalRow(lower)) {
      subtotal = _roundMoney(amount);
      hasExplicitSubtotal = true;
    } else if (_isTaxRow(lower)) {
      tax = _roundMoney(amount);
      hasExplicitTax = true;
    } else if (_isExplicitReceiptTotalRow(lower) &&
        !_isSubtotalRow(lower) &&
        !_isTaxRow(lower)) {
      total = _roundMoney(amount);
      hasExplicitTotal = true;
    } else if (RegExp(r'\bbalance due\b').hasMatch(lower) && amount > 0) {
      total = _roundMoney(amount);
      hasExplicitTotal = true;
    } else if (_isTenderTotalRow(lower)) {
      tenderTotal = _roundMoney(amount);
    }
  }
  if (total == null && tenderTotal != null) {
    total = tenderTotal;
    hasExplicitTotal = true;
  }
  if (subtotal == null && total != null && tax != null) {
    subtotal = _roundMoney(total - tax);
  }
  if (tax == null && total != null && subtotal != null) {
    tax = _roundMoney(total - subtotal);
  }
  return _ReceiptTotals(
    subtotal: subtotal,
    tax: tax,
    total: total,
    hasExplicitSubtotal: hasExplicitSubtotal,
    hasExplicitTax: hasExplicitTax,
    hasExplicitTotal: hasExplicitTotal,
  );
}

List<_ParsedReceiptLine> _readLineItems(
  List<String> rows,
  _MerchantProfile? merchantProfile,
  _ReceiptParseContext context,
  ReceiptParserLearningMemory? materialCatalogMemory,
  ReceiptParserDepth parserDepth,
  int maxCatalogCandidates,
) {
  final output = <_ParsedReceiptLine>[];
  String? pendingDescriptionRow;
  for (final row in rows) {
    final lower = row.toLowerCase();
    if (_isAdministrativeRow(lower) || _isIgnoredMoneySummaryRow(lower)) {
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
          use: ExpenseLineUse.business,
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
        ),
      ),
    );
  }
  return output;
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
  required _ReceiptTotals totals,
  required List<ExpenseReceiptLineRecord> lines,
  required List<ExpenseReceiptLineReview> lineReviews,
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
  );
}

Map<String, ExpenseReceiptFieldConfidence> _fieldConfidencesFor({
  required String? merchantName,
  required _MerchantProfile? merchantProfile,
  required DateTime? parsedDate,
  required DateTime? fallbackDate,
  required int? receiptTimeMinutes,
  required _ReceiptTotals totals,
  required List<ExpenseReceiptLineRecord> lines,
  required List<ExpenseReceiptLineReview> lineReviews,
  required ExpenseReceiptParseDiagnostics diagnostics,
}) {
  final output = <String, ExpenseReceiptFieldConfidence>{};
  void add(String fieldKey, double confidence, String reason) {
    output[fieldKey] = ExpenseReceiptFieldConfidence(
      fieldKey: fieldKey,
      confidence: confidence.clamp(0, 1).toDouble(),
      needsReview: confidence < .84,
      reason: reason,
    );
  }

  if (merchantProfile != null) {
    add('merchant', .94, 'Merchant matched a known receipt profile.');
  } else if ((merchantName ?? '').trim().isNotEmpty) {
    add('merchant', .72, 'Merchant came from the receipt header text.');
  } else {
    add('merchant', .12, 'Merchant was not found in the receipt text.');
  }

  if (parsedDate != null) {
    add('date', .92, 'Receipt date was found in the OCR text.');
  } else if (fallbackDate != null) {
    add('date', .62, 'Receipt date used the selected day as a fallback.');
  } else {
    add('date', .12, 'Receipt date was not found.');
  }

  if (receiptTimeMinutes != null) {
    add('time', .84, 'Receipt time was found in the OCR text.');
  } else {
    add('time', .42, 'Receipt time was not found. This is optional.');
  }

  add(
    'subtotal',
    _totalFieldConfidence(totals.subtotal, totals.hasExplicitSubtotal),
    _totalFieldReason(
      label: 'Subtotal',
      value: totals.subtotal,
      explicit: totals.hasExplicitSubtotal,
    ),
  );
  add(
    'tax',
    _totalFieldConfidence(totals.tax, totals.hasExplicitTax),
    _totalFieldReason(
      label: 'Tax',
      value: totals.tax,
      explicit: totals.hasExplicitTax,
    ),
  );
  add(
    'total',
    _totalFieldConfidence(totals.total, totals.hasExplicitTotal),
    _totalFieldReason(
      label: 'Total',
      value: totals.total,
      explicit: totals.hasExplicitTotal,
    ),
  );

  if (lines.isEmpty) {
    add('lineItems', .12, 'No receipt line items were detected.');
  } else if (lineReviews.isEmpty) {
    add('lineItems', .55, 'Receipt lines were found without review details.');
  } else {
    final averageLineConfidence =
        lineReviews.fold<double>(0, (sum, review) => sum + review.confidence) /
        lineReviews.length;
    final reviewPenalty = diagnostics.reviewRatio * .18;
    final mathBonus = diagnostics.reconciled ? .08 : 0;
    final confidence = averageLineConfidence - reviewPenalty + mathBonus;
    final reviewText = diagnostics.reviewLineCount == 0
        ? 'No parsed lines need review.'
        : '${diagnostics.reviewLineCount} parsed line${diagnostics.reviewLineCount == 1 ? '' : 's'} need review.';
    add(
      'lineItems',
      confidence,
      '$reviewText ${diagnostics.reconciliationLabel}',
    );
  }

  if (!diagnostics.hasCompleteExplicitTotals) {
    add(
      'receiptMath',
      diagnostics.reconciled ? .7 : .48,
      'Receipt math is incomplete because one or more totals were inferred or missing.',
    );
  } else if (diagnostics.taxMathReconciled && diagnostics.reconciled) {
    add(
      'receiptMath',
      .94,
      'Receipt subtotal, tax, total, and parsed line amounts reconcile.',
    );
  } else if (diagnostics.taxMathReconciled) {
    add(
      'receiptMath',
      .72,
      'Subtotal plus tax matches total, but parsed line totals need review.',
    );
  } else {
    add(
      'receiptMath',
      .36,
      'Receipt subtotal plus tax does not match the receipt total.',
    );
  }

  return Map.unmodifiable(output);
}

double _totalFieldConfidence(double? value, bool explicit) {
  if (value == null) return .12;
  return explicit ? .92 : .64;
}

String _totalFieldReason({
  required String label,
  required double? value,
  required bool explicit,
}) {
  if (value == null) return '$label was not found.';
  if (explicit) return '$label was read directly from the receipt.';
  return '$label was inferred from other receipt totals.';
}

bool _isAdministrativeRow(String lower) {
  if (RegExp(r'\bstore\s*(?:#|no\.?|number)?\s*\d{2,}\b').hasMatch(lower)) {
    return true;
  }
  return RegExp(
    r'\b(receipt|invoice|cashier|order|auth|approval|authorization|card|visa|mastercard|amex|discover|debit|cash|tender|payment|paid|change due|subtotal|sub total|sales tax|tax|total|amount paid|balance due|thank you|survey|tel|terminal|account|transaction|trans|ref(?:erence)?|trace|batch|driver id|vehicle id|fleet card|cashback|cash back|gift card|store card|ebt|snap|fsa|hsa|odometer|mileage|miles|next service due|service due|every\s+\d+)\b',
  ).hasMatch(lower);
}

bool _isSubtotalRow(String lower) {
  return RegExp(
    r'\b(subtotal|sub total|sub-total|merchandise total|merch total|item total|items total|pre[- ]?tax total)\b',
  ).hasMatch(lower);
}

bool _isTaxRow(String lower) {
  return RegExp(
    r'\b(sales tax|tax|state tax|local tax|county tax|city tax|taxable tax)\b',
  ).hasMatch(lower);
}

bool _isTotalOrTenderLikeRow(String lower) {
  return _isSubtotalRow(lower) ||
      _isTaxRow(lower) ||
      _isExplicitReceiptTotalRow(lower) ||
      _isTenderTotalRow(lower) ||
      RegExp(r'\bbalance due\b').hasMatch(lower);
}

bool _isExplicitReceiptTotalRow(String lower) {
  if (_isIgnoredMoneySummaryRow(lower)) return false;
  return RegExp(
    r'\b(total|grand total|order total|purchase total|sale total|amount paid)\b',
  ).hasMatch(lower);
}

bool _isIgnoredMoneySummaryRow(String lower) {
  if (RegExp(
    r'\b(you saved|total saved|total savings|savings today|member savings|reward savings|rewards saved|coupon savings|manufacturer savings|mfr savings|sale savings)\b',
  ).hasMatch(lower)) {
    return true;
  }
  if (RegExp(
    r'\b(cash back|cashback|change due|rounding|round up|donation|gift card balance|remaining balance|balance remaining|previous balance|new balance|available balance)\b',
  ).hasMatch(lower)) {
    return true;
  }
  if (RegExp(
    r'\b(total discount|discount total|total coupon|coupon total|total markdown|markdown total)\b',
  ).hasMatch(lower)) {
    return true;
  }
  if (RegExp(
    r'\b(card balance|store credit balance|rewards balance|points balance)\b',
  ).hasMatch(lower)) {
    return true;
  }
  return false;
}

String _combinedReceiptLineRow({
  required String? pendingDescriptionRow,
  required String pricedRow,
  required _MerchantProfile? merchantProfile,
  required _ReceiptParseContext context,
}) {
  final pending = pendingDescriptionRow?.trim();
  if (pending == null || pending.isEmpty) return pricedRow;
  if (!_looksLikePendingLineDescription(pending, merchantProfile, context)) {
    return pricedRow;
  }
  final pricedDescription = _cleanLineDescription(pricedRow);
  if (pricedDescription.length > 4 &&
      _looksLikeSpecificLineDescription(
        pricedDescription,
        merchantProfile,
        context,
      )) {
    return '$pending $pricedRow';
  }
  if (pricedDescription.length <= 4 ||
      RegExp(
        r'\b(price|amount|sale|item|sku|qty|extended)\b',
        caseSensitive: false,
      ).hasMatch(pricedDescription)) {
    return '$pending $pricedRow';
  }
  return pricedRow;
}

bool _looksLikePendingLineDescription(
  String row,
  _MerchantProfile? merchantProfile,
  _ReceiptParseContext context,
) {
  final clean = row.trim();
  if (clean.length < 4) return false;
  final lower = clean.toLowerCase();
  if (_lastMoneyAmount(clean) != null ||
      _datePattern.hasMatch(clean) ||
      _timePattern.hasMatch(clean) ||
      _isAdministrativeRow(lower) ||
      _looksLikeAddressOrContactRow(lower) ||
      _looksLikeMerchantHeaderRow(lower, merchantProfile)) {
    return false;
  }
  return _looksLikeSpecificLineDescription(clean, merchantProfile, context);
}

bool _looksLikeSpecificLineDescription(
  String value,
  _MerchantProfile? merchantProfile,
  _ReceiptParseContext context,
) {
  final text = value.toLowerCase();
  if (_categoryRules.any((rule) => rule.pattern.hasMatch(text))) return true;
  if (context.looksLikeMaterialReceipt &&
      RegExp(
        r'\b(\d+\s*x\s*\d+|sch\s*40|romex|emt|pvc|cpvc|pex|gfic?|gfi|stud|plywood|osb|drywall|caulk|sealant|adhesive|primer|paint|shingle|flashing|conduit|wire|breaker|valve|coupling|elbow|tee|nipple|fitting|screws?|nails?|capacitor|run cap|mfd|pleated filter|furnace filter|ac filter|hvac tape)\b',
      ).hasMatch(text)) {
    return true;
  }
  if (context.looksLikeFuelReceipt &&
      RegExp(
        r'\b(unleaded|regular|midgrade|premium|diesel|def|gallons?|gals?|gal\b|kwh|pump|price\s*/\s*gal|price\s*per\s*gal|ppu|ppg|ppl|fuel sale|fuel volume|fuel qty)\b',
      ).hasMatch(text)) {
    return true;
  }
  if (context.looksLikeAutoServiceReceipt &&
      RegExp(
        r'\b(oil|filter|tire|alignment|labor|diagnostic)\b',
      ).hasMatch(text)) {
    return true;
  }
  final secondary = merchantProfile?.secondaryCategories ?? const <String>[];
  if (secondary.contains('Materials') &&
      RegExp(r'\b[A-Z0-9#/-]{2,}\b').hasMatch(value) &&
      RegExp(r'\b(ea|pk|ct|ft|in|gal|qt|lb|oz|x)\b').hasMatch(text)) {
    return true;
  }
  return false;
}

bool _looksLikeAddressOrContactRow(String lower) {
  if (RegExp(r'\b[a-z]{2}\s+\d{5}(?:-\d{4})?\b').hasMatch(lower)) {
    return true;
  }
  if (RegExp(r'\(?\d{3}\)?[-\s]\d{3}[-\s]\d{4}\b').hasMatch(lower)) {
    return true;
  }
  if (RegExp(r'\b\d{3}\s+\d{2}\b').hasMatch(lower) &&
      RegExp(r'\b[a-z]{2}\b').hasMatch(lower)) {
    return true;
  }
  return RegExp(
    r'\b(street|avenue|road|blvd|boulevard|drive|lane|suite|ste|city|state|zip|www|\.com)\b',
  ).hasMatch(lower);
}

bool _looksLikeMerchantHeaderRow(
  String lower,
  _MerchantProfile? merchantProfile,
) {
  final merchant = merchantProfile?.displayName.toLowerCase();
  if (merchant != null && merchant.isNotEmpty && lower.contains(merchant)) {
    return true;
  }
  return RegExp(
    r'\b(lowes|lowe s|home depot|walmart|target|cvs|walgreens|sherwin|ferguson|supply house|store|pharmacy)\b',
  ).hasMatch(lower);
}

String _cleanLineDescription(String row) {
  return _titleCase(
    row
        .replaceAll(
          RegExp(r'^\s*(?:line|ln)\s*#?\s*\d+\s+', caseSensitive: false),
          ' ',
        )
        .replaceAll(RegExp(r'^\s*\d{5,}\s+'), ' ')
        .replaceAll(_datePattern, ' ')
        .replaceAll(_timePattern, ' ')
        .replaceAll(
          RegExp(
            r'\b(?:sku|item|upc|model|mdl|part|pn|#)\s*[:#]?\s*[a-z0-9\-]{4,}\b',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(RegExp(r'\(\s*\$?\s*\d[\d,]*\.\d{2}\s*\)'), ' ')
        .replaceAll(
          RegExp(
            r'\$?\s*-?\d[\d,]*\.\d{2}\s*(?:cr|[a-z])?\b',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(
          RegExp(
            r'\$?\s*-?\d{1,5}\s+\d{2}\s*(?:cr|[a-z])?\b',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(
          RegExp(
            r'\b(price|amount|sale|extended|ext price|item price)\b',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim(),
  );
}

double? _lineAmountForRow(String row, _ReceiptParseContext context) {
  final lower = row.toLowerCase();
  if (_isTenderTotalRow(lower) || _looksLikeAddressOrContactRow(lower)) {
    return null;
  }
  final amount = _lastMoneyAmount(
    row,
    allowCompactCents: _looksLikeCompactLineMoneyCandidate(row, context),
  );
  if (amount == null) return null;
  if (amount > 0 &&
      _negativeReceiptLineType(lower) == 'return/refund' &&
      !_isIgnoredMoneySummaryRow(lower)) {
    return -amount;
  }
  return amount;
}

double? _lastMoneyAmount(String row, {bool allowCompactCents = false}) {
  final matches = RegExp(
    r'(\()?\s*(-)?\$?\s*(\d{1,6}(?:,\d{3})*\.\d{2})(?!\d)\s*(cr|[a-z])?\s*(-)?(\))?',
    caseSensitive: false,
  ).allMatches(row).toList();
  final spaced = RegExp(
    r'(?:^|[\s:])(-)?\$?\s*(\d{1,5})\s+(\d{2})\s*(cr|[a-z]|-)?\s*$',
    caseSensitive: false,
  ).firstMatch(row);
  if (matches.isNotEmpty &&
      (spaced == null || matches.last.start > spaced.start)) {
    return _regularMoneyValue(matches.last);
  }
  if (spaced != null) {
    final dollars = int.tryParse(spaced.group(2) ?? '');
    final cents = int.tryParse(spaced.group(3) ?? '');
    if (dollars != null && cents != null && cents <= 99) {
      final suffix = spaced.group(4)?.toLowerCase();
      final negative =
          spaced.group(1) != null || suffix == 'cr' || suffix == '-';
      final value = dollars + (cents / 100);
      return negative ? -value : value;
    }
  }
  if (matches.isNotEmpty) return _regularMoneyValue(matches.last);
  if (!allowCompactCents) return null;
  final compact = RegExp(
    r'(?:^|[\s:])(-)?\$?(\d{3,6})(cr|[a-z]|-)?\s*$',
    caseSensitive: false,
  ).firstMatch(row);
  if (compact == null) return null;
  final cents = int.tryParse(compact.group(2) ?? '');
  if (cents == null || cents <= 0) return null;
  final suffix = compact.group(3)?.toLowerCase();
  final negative = compact.group(1) != null || suffix == 'cr' || suffix == '-';
  final value = cents / 100;
  return negative ? -value : value;
}

double? _regularMoneyValue(RegExpMatch match) {
  final raw = match.group(3)!.replaceAll(',', '');
  final value = double.tryParse(raw);
  if (value == null) return null;
  final suffix = match.group(4)?.toLowerCase();
  final negative =
      match.group(1) != null ||
      match.group(2) != null ||
      match.group(5) != null ||
      suffix == 'cr';
  return negative ? -value : value;
}

bool _looksLikeCompactLineMoneyCandidate(
  String row,
  _ReceiptParseContext context,
) {
  if (_lastMoneyAmount(row) != null) return false;
  final lower = row.toLowerCase();
  if (_isAdministrativeRow(lower) ||
      _isIgnoredMoneySummaryRow(lower) ||
      _looksLikeAddressOrContactRow(lower)) {
    return false;
  }
  if (!RegExp(
    r'(?:^|[\s:])-?\$?\d{3,6}(?:cr|[a-z]|-)?\s*$',
    caseSensitive: false,
  ).hasMatch(row)) {
    return false;
  }
  final description = row.replaceFirst(
    RegExp(r'(?:^|[\s:])-?\$?\d{3,6}(?:cr|[a-z]|-)?\s*$', caseSensitive: false),
    ' ',
  );
  return _looksLikeSpecificLineDescription(description, null, context) ||
      RegExp(r'[a-zA-Z]{3,}').hasMatch(description);
}

bool _isTenderTotalRow(String lower) {
  if (_isIgnoredMoneySummaryRow(lower)) return false;
  return RegExp(
    r'\b(card|visa|mastercard|amex|discover|debit|credit|cash tender|amount paid|paid|gift card|store credit|ebt|snap|fsa|hsa|fleet card|fuel card)\b',
  ).hasMatch(lower);
}

_CategoryMatch _categoryFor(
  String description,
  _MerchantProfile? merchantProfile,
  _ReceiptParseContext context, {
  double? amount,
}) {
  final text = description.toLowerCase();
  if ((amount ?? 0) < 0) {
    final adjustment = _negativeReceiptLineType(text);
    if (adjustment != null && !_hasSpecificItemCategory(text)) {
      return _CategoryMatch(
        category: 'Receipt Adjustment',
        confidence: .92,
        reason: 'Recognized negative receipt $adjustment line.',
      );
    }
  }
  for (final rule in _categoryRules) {
    if (rule.pattern.hasMatch(text)) {
      final match = _merchantAdjustedMatch(rule.match, merchantProfile);
      if ((amount ?? 0) < 0) {
        final adjustment = _negativeReceiptLineType(text);
        if (adjustment != null) {
          return match.copyWith(
            confidence: (match.confidence + .03).clamp(0, 1).toDouble(),
            reason:
                '${match.reason} Recognized negative receipt $adjustment line.',
          );
        }
      }
      return match;
    }
  }
  if ((amount ?? 0) < 0) {
    final adjustment = _negativeReceiptLineType(text);
    if (adjustment != null) {
      return _CategoryMatch(
        category: 'Receipt Adjustment',
        confidence: .92,
        reason: 'Recognized negative receipt $adjustment line.',
      );
    }
  }
  final contextDefault = _contextDefaultMatch(text, merchantProfile, context);
  if (contextDefault != null) return contextDefault;
  return const _CategoryMatch(
    category: 'Uncategorized',
    confidence: .28,
    reason: 'No category keywords matched this line.',
  );
}

String? _negativeReceiptLineType(String text) {
  if (RegExp(
    r'\b(coupon|mfr coupon|manufacturer coupon|promo|promotion)\b',
  ).hasMatch(text)) {
    return 'coupon';
  }
  if (RegExp(
    r'\b(discount|disc|markdown|price match|price adjustment|savings|saved|reward|rewards|loyalty|member savings|fuel rewards?|fuel perks?)\b',
  ).hasMatch(text)) {
    return 'discount';
  }
  if (RegExp(
    r'\b(return|returned|refund|credit|store credit)\b',
  ).hasMatch(text)) {
    return 'return/refund';
  }
  if (RegExp(r'\b(rebate|instant rebate)\b').hasMatch(text)) {
    return 'rebate';
  }
  return null;
}

bool _hasSpecificItemCategory(String text) {
  final itemText = text
      .replaceAll(
        RegExp(
          r'\b(coupon|mfr coupon|manufacturer coupon|promo|promotion|discount|disc|markdown|price match|price adjustment|savings|saved|reward|rewards|loyalty|member savings|fuel rewards?|fuel perks?|return|returned|refund|credit|store credit|rebate|instant rebate)\b',
        ),
        ' ',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (itemText.isEmpty) return false;
  return _categoryRules.any((rule) => rule.pattern.hasMatch(itemText));
}

_CategoryMatch? _contextDefaultMatch(
  String text,
  _MerchantProfile? merchantProfile,
  _ReceiptParseContext context,
) {
  if (!context.hasStrongCategorySignal) return null;
  final secondary = merchantProfile?.secondaryCategories ?? const <String>[];
  if (context.looksLikeFuelReceipt &&
      ((merchantProfile?.defaultCategory == 'Fuel' &&
              _looksLikeFuelMeasuredLine(text)) ||
          (secondary.contains('Fuel') &&
              _looksLikeGenericMerchantLine(text)))) {
    return const _CategoryMatch(
      category: 'Fuel',
      confidence: .8,
      reason: 'Receipt-level fuel signals matched this merchant.',
    );
  }
  if (context.looksLikeAutoServiceReceipt &&
      (secondary.contains('Maintenance') || secondary.contains('Repair')) &&
      _looksLikeGenericMerchantLine(text)) {
    return const _CategoryMatch(
      category: 'Maintenance',
      confidence: .78,
      reason: 'Receipt-level vehicle service signals matched this merchant.',
    );
  }
  if (context.looksLikeMaterialReceipt &&
      secondary.contains('Materials') &&
      (_looksLikeGenericMerchantLine(text) ||
          _looksLikeGenericMaterialSupplyLine(text))) {
    return const _CategoryMatch(
      category: 'Materials',
      confidence: .78,
      reason: 'Receipt-level material signals matched this merchant.',
    );
  }
  if (context.looksLikeFoodReceipt &&
      secondary.contains('Meals') &&
      _looksLikeGenericMerchantLine(text)) {
    return const _CategoryMatch(
      category: 'Meals',
      confidence: .78,
      reason: 'Receipt-level food signals matched this merchant.',
    );
  }
  return null;
}

_CategoryMatch _merchantAdjustedMatch(
  _CategoryMatch match,
  _MerchantProfile? merchantProfile,
) {
  final defaultCategory = merchantProfile?.defaultCategory;
  if (defaultCategory == null) return match;
  if (defaultCategory == match.category) {
    return match.copyWith(
      confidence: (match.confidence + .04).clamp(0, 1).toDouble(),
      reason: '${match.reason} Merchant profile agrees.',
    );
  }
  if (merchantProfile!.secondaryCategories.contains(match.category)) {
    return match.copyWith(
      confidence: (match.confidence + .02).clamp(0, 1).toDouble(),
      reason: '${match.reason} Merchant profile allows this category.',
    );
  }
  return match.copyWith(
    confidence: (match.confidence - .08).clamp(0, 1).toDouble(),
    reason: '${match.reason} Merchant profile suggests checking this category.',
  );
}

bool _looksLikeGenericMerchantLine(String text) {
  return RegExp(
    r'\b(monthly|service|payment|premium|bill|renewal|plan|account|charge)\b',
  ).hasMatch(text);
}

bool _looksLikeGenericMaterialSupplyLine(String text) {
  return RegExp(
    r'\b(?:\d+(?:/\d+)?(?:x\d+(?:x\d+)?)?|[a-z0-9#/-]{2,})\b',
  ).hasMatch(text);
}

bool _looksLikeFuelMeasuredLine(String text) {
  return RegExp(
    r'\b(gallons?|gals?|gal\b|kwh|price\s*/\s*gal|price\s*per\s*gal|ppu|ppg|amount)\b',
  ).hasMatch(text);
}

ExpenseReceiptLineReview _reviewForLine({
  required String lineId,
  required String description,
  required double amount,
  required _CategoryMatch categoryMatch,
  required _ParsedQuantity quantity,
  required bool catalogMatchingEnabled,
  ReceiptLineMatch? materialCatalogMatch,
}) {
  var confidence = categoryMatch.confidence;
  final reasons = <String>[categoryMatch.reason];
  if (materialCatalogMatch != null) {
    confidence = (confidence + (materialCatalogMatch.confidence * .16)).clamp(
      0,
      1,
    );
    reasons.add(
      'Inventory catalog suggests ${materialCatalogMatch.item.name}.',
    );
    if (materialCatalogMatch.needsReview) {
      reasons.add(materialCatalogMatch.confidenceGuidance);
    }
  } else if (categoryMatch.category == 'Materials' && catalogMatchingEnabled) {
    confidence -= .08;
    reasons.add('No inventory catalog item matched this material line.');
  } else if (categoryMatch.category == 'Materials') {
    reasons.add(
      'Inventory catalog matching was skipped for the current performance mode.',
    );
  }
  if (categoryMatch.category == 'Uncategorized') {
    confidence -= .1;
    reasons.add('Choose an expense category.');
  }
  if (description.length <= 4) {
    confidence -= .12;
    reasons.add('Description is very short.');
  }
  if (amount < 0) {
    final adjustment = _negativeReceiptLineType(description.toLowerCase());
    if (adjustment == null) {
      confidence -= .08;
      reasons.add('Negative receipt line is missing an adjustment label.');
    } else {
      confidence = (confidence + .04).clamp(0, 1).toDouble();
      reasons.add('Negative amount is a recognized receipt $adjustment line.');
    }
  } else if (amount == 0) {
    confidence -= .2;
    reasons.add('Amount needs review.');
  }
  if (quantity.quantity <= 0 || quantity.unitsPerPackage <= 0) {
    confidence -= .15;
    reasons.add('Quantity needs review.');
  }
  confidence = confidence.clamp(0, 1).toDouble();
  return ExpenseReceiptLineReview(
    lineId: lineId,
    confidence: confidence,
    needsReview: confidence < .84 || categoryMatch.category == 'Uncategorized',
    reason: reasons.join(' '),
    catalogItemName: materialCatalogMatch?.item.name,
    catalogItemPath: materialCatalogMatch?.item.path,
    catalogMatchConfidence: materialCatalogMatch?.confidence,
    catalogMatchedTerms: materialCatalogMatch?.matchedTerms ?? const [],
  );
}

_ParsedQuantity _quantityFor(String description, String category) {
  final rule = expenseReceiptRuleForCategory(category);
  if (!rule.usesQuantityFields) {
    return const _ParsedQuantity(quantity: 1, unitsPerPackage: 1, unit: 'each');
  }
  final lower = description.toLowerCase();
  if (rule.isFuel) {
    final gallons = RegExp(
      r'(\d+(?:\.\d+)?)\s*(gal|gallon|gallons)\b',
    ).firstMatch(lower);
    if (gallons != null) {
      return _ParsedQuantity(
        quantity: double.parse(gallons.group(1)!),
        unitsPerPackage: 1,
        unit: 'gallon',
      );
    }
    final kwh = RegExp(r'(\d+(?:\.\d+)?)\s*kwh\b').firstMatch(lower);
    if (kwh != null) {
      return _ParsedQuantity(
        quantity: double.parse(kwh.group(1)!),
        unitsPerPackage: 1,
        unit: 'kWh',
      );
    }
    return const _ParsedQuantity(
      quantity: 1,
      unitsPerPackage: 1,
      unit: 'gallon',
    );
  }
  final pack = RegExp(
    r'(\d+(?:\.\d+)?)\s*(pack|pk|box|case|pkg)\b',
  ).firstMatch(lower);
  if (pack != null) {
    return _ParsedQuantity(
      quantity: 1,
      unitsPerPackage: double.parse(pack.group(1)!),
      unit: defaultExpenseReceiptUnit(category),
    );
  }
  final qty = RegExp(r'\bqty\s*[:#]?\s*(\d+(?:\.\d+)?)\b').firstMatch(lower);
  if (qty != null) {
    return _ParsedQuantity(
      quantity: double.parse(qty.group(1)!),
      unitsPerPackage: 1,
      unit: defaultExpenseReceiptUnit(category),
    );
  }
  final multiplier = RegExp(
    r'(?:^|\s)(\d+(?:\.\d+)?)\s*(?:@|x)(?:\s|$)',
  ).firstMatch(lower);
  if (multiplier != null) {
    return _ParsedQuantity(
      quantity: double.parse(multiplier.group(1)!),
      unitsPerPackage: 1,
      unit: defaultExpenseReceiptUnit(category),
    );
  }
  final leadingEach = RegExp(
    r'^\s*(\d+(?:\.\d+)?)\s*(?:ea|each)\b',
  ).firstMatch(lower);
  if (leadingEach != null) {
    return _ParsedQuantity(
      quantity: double.parse(leadingEach.group(1)!),
      unitsPerPackage: 1,
      unit: defaultExpenseReceiptUnit(category),
    );
  }
  return _ParsedQuantity(
    quantity: 1,
    unitsPerPackage: 1,
    unit: defaultExpenseReceiptUnit(category),
  );
}

String _titleCase(String value) {
  return value
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) {
        if (part.length == 1) return part.toUpperCase();
        return part[0].toUpperCase() + part.substring(1).toLowerCase();
      })
      .join(' ');
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';

double _roundMoney(double value) => (value * 100).roundToDouble() / 100;
