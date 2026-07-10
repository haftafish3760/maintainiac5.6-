part of 'expense_receipt_parser.dart';

String _safeParserToken(String value) {
  final token = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return token.isEmpty ? 'unknown' : token;
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
    final hasReceiptTotal = totals.hasExplicitTotal || totals.total != null;
    final hasReceiptSubtotal =
        totals.hasExplicitSubtotal || totals.subtotal != null;
    add(
      'lineItems',
      hasReceiptTotal || hasReceiptSubtotal ? .22 : .12,
      _noLineItemRecoveryWarningFor(totals),
    );
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

  if (_hasTotalOnlyLinesReady(lines, totals)) {
    add(
      'receiptMath',
      .82,
      'Receipt total matches parsed line amounts; subtotal and tax were not printed separately.',
    );
  } else if (!diagnostics.hasCompleteExplicitTotals) {
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

String _noLineItemRecoveryWarningFor(_ReceiptTotals totals) {
  final hasReceiptTotal = totals.hasExplicitTotal || totals.total != null;
  final hasReceiptSubtotal =
      totals.hasExplicitSubtotal || totals.subtotal != null;
  final hasAnyReceiptTotal = hasReceiptTotal || hasReceiptSubtotal;
  if (!hasAnyReceiptTotal) return 'No receipt line items were detected.';
  return 'Receipt totals were found, but no safe item-price lines were detected. Continue with the receipt total or add item lines manually.';
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
  if (_looksLikeFuelPendingDetailRow(pending) &&
      !_looksLikeFuelMeasuredLine(pricedRow.toLowerCase()) &&
      !_looksLikeStrongFuelReceiptLine(pricedRow.toLowerCase())) {
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

bool _looksLikeFuelPendingDetailRow(String row) {
  final lower = row.toLowerCase();
  return RegExp(
    r'\b(fuel\s+qty|fuel\s+volume|gallons?|galns|gals?|price\s*/\s*gal|'
    r'ppg|ppu|ppl|price\s*/\s*kwh|kwh|gge|ppge|kg|ppkg)\b',
  ).hasMatch(lower);
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
      _hasReceiptTimeCandidateRow(clean) ||
      _isAdministrativeRow(lower) ||
      _looksLikePrivateFuelIdentityRow(
        _normalizeReceiptSummaryKeywordText(lower),
      ) ||
      (context.looksLikeFuelReceipt &&
          _looksLikeFuelPerUnitAdjustmentMetadataRow(clean)) ||
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
        r'\b(\d+\s*x\s*\d+|sch\s*40|romex|emt|pvc|cpvc|pex|gfic?|'
        r'gfi|stud|plywood|osb|drywall|caulk|sealant|adhesive|primer|'
        r'paint|shingle|flashing|conduit|wire|breaker|valve|coupling|'
        r'elbow|tee|nipple|fitting|screws?|nails?|capacitor|run cap|'
        r'mfd|pleated filter|furnace filter|ac filter|hvac tape)\b',
      ).hasMatch(text)) {
    return true;
  }
  if (context.looksLikeFuelReceipt &&
      RegExp(
        r'\b(unleaded|regular|midgrade|premium|diesel|def|fuel|'
        r'gasoline|propane|lpg|l\.?p\.? gas|gas l\.?p\.?|kerosene|kero|queroseno|k[- ]?1|gallons?|galns|gals?|gal\b|kwh|pump|'
        r'price\s*/\s*g(?:al)?|price\s*per\s*gal|\$\s*/\s*gal|'
        r'ppu|ppg|ppl|fuel sale|fuel amount|fuel amt|fuel volume|'
        r'fuel vol|fuel qty|vol(?:ume)?|qty|qnty|quantity)\b',
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
