part of 'expense_receipt_parser.dart';

bool _looksLikeAddressOrContactRow(String lower) {
  if (RegExp(
    r'\b(?:on|off)[-\s]?road\s+(?:clear\s+)?diesel\b',
  ).hasMatch(lower)) {
    return false;
  }
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
        .replaceAll(
          RegExp(
            r'\b\d{1,2}:\d{2}(?::\d{2})?\s*(?:a\.?m\.?|p\.?m\.?)?\b',
            caseSensitive: false,
          ),
          ' ',
        )
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
        .replaceAll(
          RegExp(
            r'\b(?:qty\s*[:#]?\s*)?\d+(?:\.\d+)?\s*(?:ea|each)\s*@\s*',
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
  if (_looksLikeFuelProductGradeOnlyRow(row)) return null;
  if (context.looksLikeFuelReceipt &&
      _looksLikeFuelQuantityOnlyDetailRow(row)) {
    return null;
  }
  if (context.looksLikeFuelReceipt &&
      _looksLikeFuelPerUnitAdjustmentMetadataRow(row)) {
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

bool _looksLikeFuelQuantityOnlyDetailRow(String row) {
  final lower = row.toLowerCase();
  if (RegExp(
    r'\b(total|sale|venta|amount|paid|due|tender|visa|mastercard|'
    r'debit|cash|precio|price|rate|ppu|ppg|ppl|@|\$)\b',
  ).hasMatch(lower)) {
    return false;
  }
  if (!RegExp(
    r'\b(kwh|gal|gals|gallon|gallons|gal[oó]n|gal[oó]nes|liter|liters|litre|litres)\b',
  ).hasMatch(lower)) {
    return false;
  }
  final numericTokens = RegExp(r'\b\d+(?:\.\d+)?\b').allMatches(lower).length;
  if (numericTokens != 1) return false;
  return RegExp(
    r'\b(kwh|energy delivered|energy|gallons?|gal[oó]nes|'
    r'fuel qty|fuel volume|combustible|volume|vol|qty|quantity)\b',
  ).hasMatch(lower);
}

bool _looksLikeFuelPerUnitAdjustmentMetadataRow(String row) {
  final lower = row.toLowerCase();
  if (!RegExp(
    r'\b(fuel rewards?|fuel perks?|reward|rewards|discount|disc|descuento|'
    r'loyalty|member savings|club savings|shopper|fuel points?|points reward)\b',
  ).hasMatch(lower)) {
    return false;
  }
  return RegExp(
    r'(?:/|\bper\s+)(?:gal|gallon|gallons|gge|kg|kwh|liter|liters|litro|litros)\b',
  ).hasMatch(lower);
}

bool _looksLikeFuelProductGradeOnlyRow(String row) {
  final lower = row.toLowerCase();
  if (lower.contains('@') || lower.contains(r'$')) return false;
  if (RegExp(
    r'\b(total|sale|venta|amount|paid|due|tender|visa|mastercard|'
    r'debit|cash|precio|price|rate|ppu|ppg|ppl|@|\$|gal|gallon|'
    r'gallons|kwh|liter|liters|litre|litres)\b',
  ).hasMatch(lower)) {
    return false;
  }
  if (!RegExp(
    r'\b(product|grade|fuel type|regular|reg|unleaded|unl|premium|'
    r'midgrade|octane|e10|e15|e85|flex fuel|gasoline|race fuel|racing fuel|'
    r'avgas|jet fuel|nitromethane|c[0o]mbustible de carrera|nitrometano|'
    r'turbosina|gasolina de aviaci[oó]n)\b',
  ).hasMatch(lower)) {
    return false;
  }
  if (RegExp(
    r'\be[-\s]?(?:10|15|20|30|50|85)\s+(?:octane\s*)?(?:8[7-9]|9\d|10\d|11\d)\b',
  ).hasMatch(lower)) {
    return true;
  }
  final numbers = RegExp(r'\b\d{1,3}\b').allMatches(lower).toList();
  if (numbers.length != 1) return false;
  final grade = int.tryParse(numbers.single.group(0) ?? '');
  const productGrades = {10, 15, 85, 87, 88, 89, 91, 93, 100, 110};
  return grade != null && productGrades.contains(grade);
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
  if (_looksLikeFuelProductGradeOnlyRow(row)) return false;
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
  // A trailing, unpunctuated number is frequently a store, terminal, loyalty,
  // or receipt identifier rather than a price.  Do not turn arbitrary words
  // plus such a number into a monetary line: fuel receipts in particular
  // contain values such as "Sheetz 754", "Term: 20754", and "Pointz: 2957".
  // Compact cents are only safe when the description itself has a recognized
  // line-item signal.
  return _looksLikeSpecificLineDescription(description, null, context);
}

bool _isTenderTotalRow(String lower) {
  if (_isIgnoredMoneySummaryRow(lower)) return false;
  final normalized = _normalizeReceiptSummaryKeywordText(lower);
  return RegExp(
    r'\b(card|cards?|visa|mastercard|amex|discover|debit|credit|'
    r'cash tender|cash|amount paid|paid|gift\s*cards?|merch/gift|'
    r'store credit|ebt|snap|fsa|hsa|fleet card|fuel card|begin bal|'
    r'beginning bal|ending bal|end bal|transaction amt)\b',
  ).hasMatch(normalized);
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
    r'\b(discount|disc|descuento|descuentos|markdown|price match|price adjustment|savings|saved|reward|rewards|loyalty|member savings|fuel rewards?|fuel perks?)\b',
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
