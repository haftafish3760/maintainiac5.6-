part of 'expense_receipt_parser.dart';

ExpenseReceiptParseResult parseExpenseReceiptText(
  String sourceText, {
  DateTime? fallbackDate,
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
  final date = _readDate(rows) ?? fallbackDate;
  final time = _readTimeMinutes(rows);
  final merchantProfile = _readMerchantProfile(rows);
  final merchant = merchantProfile?.displayName ?? _readMerchant(rows);
  final context = _ReceiptParseContext.fromRows(rows);
  final parsedLines = _readLineItems(rows, merchantProfile, context);
  final lineRows = parsedLines.map((line) => line.record).toList();
  final warnings = <String>[];

  if (lineRows.isEmpty) {
    warnings.add('No receipt line items were detected.');
  }
  if (totals.total != null &&
      lineRows.isNotEmpty &&
      totals.subtotal == null &&
      totals.tax == null) {
    warnings.add('Receipt total found, but subtotal and tax need review.');
  }
  final lineTotalWarning = _lineTotalReviewWarning(lineRows, totals);
  if (lineTotalWarning != null) warnings.add(lineTotalWarning);
  final lowConfidenceCount = parsedLines
      .where((line) => line.review.needsReview)
      .length;
  if (lowConfidenceCount > 0) {
    warnings.add(
      '$lowConfidenceCount parsed receipt ${lowConfidenceCount == 1 ? 'line needs' : 'lines need'} review.',
    );
  }
  final maintenanceHints = _maintenanceHintsFor(
    rows: rows,
    lines: lineRows,
    context: context,
  );
  final quality = _parseQualityFor(
    merchantName: merchant,
    receiptDate: date,
    totals: totals,
    lines: lineRows,
    lineReviews: parsedLines.map((line) => line.review).toList(growable: false),
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
    lineReviews: parsedLines.map((line) => line.review).toList(growable: false),
    maintenanceHints: maintenanceHints,
    quality: quality,
    warnings: warnings,
  );
}

String _normalizeOcrRow(String value) {
  var output = value.trim();
  if (output.isEmpty) return '';
  output = output
      .replaceAll('\u00a0', ' ')
      .replaceAll(RegExp(r'[|]'), ' ')
      .replaceAll(RegExp(r'\bS0\b', caseSensitive: false), '50')
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
  for (final row in rows) {
    final lower = row.toLowerCase();
    final amount = _lastMoneyAmount(row);
    if (amount == null) continue;
    if (RegExp(r'\b(subtotal|sub total|sub-total)\b').hasMatch(lower)) {
      subtotal = amount;
    } else if (RegExp(r'\b(sales tax|tax)\b').hasMatch(lower)) {
      tax = amount;
    } else if (RegExp(r'\b(total|amount paid|balance due)\b').hasMatch(lower) &&
        !RegExp(r'\bsubtotal|sub total|tax\b').hasMatch(lower)) {
      total = amount;
    }
  }
  if (subtotal == null && total != null && tax != null) {
    subtotal = total - tax;
  }
  if (tax == null && total != null && subtotal != null) {
    tax = total - subtotal;
  }
  return _ReceiptTotals(subtotal: subtotal, tax: tax, total: total);
}

List<_ParsedReceiptLine> _readLineItems(
  List<String> rows,
  _MerchantProfile? merchantProfile,
  _ReceiptParseContext context,
) {
  final output = <_ParsedReceiptLine>[];
  for (final row in rows) {
    final lower = row.toLowerCase();
    if (_isAdministrativeRow(lower)) continue;
    final amount = _lastMoneyAmount(row);
    if (amount == null || amount <= 0) continue;
    final description = _cleanLineDescription(row);
    if (description.length < 2) continue;
    final categoryMatch = _categoryFor(description, merchantProfile, context);
    final category = categoryMatch.category;
    final fuelDetails = category == 'Fuel'
        ? _fuelDetailsFor(
            rawRow: row,
            description: description,
            amount: amount,
            receiptRows: rows,
          )
        : null;
    final materialQuantity = category == 'Materials'
        ? _materialQuantityFor(rawRow: row, description: description)
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

bool _isAdministrativeRow(String lower) {
  return RegExp(
    r'\b(receipt|invoice|cashier|order|auth|approval|card|visa|mastercard|amex|discover|debit|credit|cash|tender|payment|paid|change due|subtotal|sub total|sales tax|tax|total|amount paid|balance due|thank you|survey|tel|store|terminal)\b',
  ).hasMatch(lower);
}

String _cleanLineDescription(String row) {
  return _titleCase(
    row
        .replaceAll(_datePattern, ' ')
        .replaceAll(_timePattern, ' ')
        .replaceAll(RegExp(r'\$?\s*-?\d+\.\d{2}\b'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim(),
  );
}

double? _lastMoneyAmount(String row) {
  final matches = RegExp(
    r'-?\$?\s*(\d{1,6}(?:,\d{3})*\.\d{2})',
  ).allMatches(row).toList();
  if (matches.isEmpty) return null;
  final raw = matches.last.group(1)!.replaceAll(',', '');
  return double.tryParse(raw);
}

_CategoryMatch _categoryFor(
  String description,
  _MerchantProfile? merchantProfile,
  _ReceiptParseContext context,
) {
  final text = description.toLowerCase();
  for (final rule in _categoryRules) {
    if (rule.pattern.hasMatch(text)) {
      return _merchantAdjustedMatch(rule.match, merchantProfile);
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
      _looksLikeGenericMerchantLine(text)) {
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
}) {
  var confidence = categoryMatch.confidence;
  final reasons = <String>[categoryMatch.reason];
  if (categoryMatch.category == 'Uncategorized') {
    confidence -= .1;
    reasons.add('Choose an expense category.');
  }
  if (description.length <= 4) {
    confidence -= .12;
    reasons.add('Description is very short.');
  }
  if (amount <= 0) {
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
  final qty = RegExp(r'\bqty\s*(\d+(?:\.\d+)?)\b').firstMatch(lower);
  if (qty != null) {
    return _ParsedQuantity(
      quantity: double.parse(qty.group(1)!),
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
