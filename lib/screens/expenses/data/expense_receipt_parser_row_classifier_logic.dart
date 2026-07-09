part of 'expense_receipt_parser.dart';

bool _isAdministrativeRow(String lower) {
  if (RegExp(r'\bstore\s*(?:#|no\.?|number)?\s*\d{2,}\b').hasMatch(lower)) {
    return true;
  }
  return RegExp(
    r'\b(receipt|invoice|cashier|order|auth|authcode|pre[- ]?auth|'
    r'preauthorization|approval|authorization|authorization hold|'
    r'card|visa|mastercard|amex|discover|debit|cash|'
    r'tarjeta|efectivo|cambio|autorizaci[oó]n|tender|payment|paid|'
    r'change due|subtotal|sub total|sales tax|tax|impuesto|'
    r'total|amount paid|balance due|begin bal|beginning bal|ending bal|'
    r'end bal|thank you|survey|tel|terminal|account|transaction|'
    r'transaction amt|trans|ref(?:erence)?|trace|batch|driver id|'
    r'vehicle id|vehicle no|unit no|truck no|tractor no|trailer no|'
    r'vin|license plate|plate|tag no|club card|alt id|customer id|cust id|'
    r'fleet card|cashback|cash back|gift card|store card|'
    r'ebt|snap|fsa|hsa|odometer|odo|hubometer|hub\s*miles|'
    r'od[oó]metro|mileage|miles|next service due|'
    r'service due|every\s+\d+)\b',
  ).hasMatch(lower);
}

bool _looksLikeBarcodeOrReceiptIdMoneyRow(String row) {
  final lower = row.toLowerCase();
  if (_lastMoneyAmount(row) == null) return false;
  if (!RegExp(
    r'\b(bar\s*code|barcode|upc|ean|gtin|qr\s*code|serial(?:\s*(?:no|number|#))?)\b',
  ).hasMatch(lower)) {
    return false;
  }
  final withoutMoney = row
      .replaceAll(
        RegExp(
          r'(\()?\s*(-)?\$?\s*(\d{1,6}(?:,\d{3})*\.\d{2})(?!\d)\s*(cr|[a-z])?\s*(-)?(\))?',
          caseSensitive: false,
        ),
        ' ',
      )
      .replaceAll(
        RegExp(
          r'(?:^|[\s:])(-)?\$?\s*(\d{1,5})\s+(\d{2})\s*(cr|[a-z]|-)?\s*$',
          caseSensitive: false,
        ),
        ' ',
      );
  final longDigitCount = RegExp(r'\d').allMatches(withoutMoney).length;
  final hasLettersBeyondMetadata = withoutMoney
      .replaceAll(
        RegExp(
          r'\b(bar\s*code|barcode|upc|ean|gtin|qr\s*code|serial|no|number)\b',
          caseSensitive: false,
        ),
        ' ',
      )
      .replaceAll(RegExp(r'[#:\-\s\d]+'), ' ')
      .trim()
      .isNotEmpty;
  return longDigitCount >= 6 && !hasLettersBeyondMetadata;
}

bool _isSubtotalRow(String lower) {
  final normalized = _normalizeReceiptSummaryKeywordText(lower);
  return RegExp(
    r'\b(subtotal|sub total|sub-total|merchandise total|merchandise subtotal|merch total|merch subtotal|item total|items total|taxable total|taxable subtotal|pre[- ]?tax total|pre[- ]?tax amount)\b',
  ).hasMatch(normalized);
}

bool _isTaxRow(String lower) {
  final normalized = _normalizeReceiptSummaryKeywordText(lower);
  return RegExp(
    r'\b(sales tax|tax|state tax|local tax|county tax|city tax|taxable tax)\b',
  ).hasMatch(normalized);
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
  final normalized = _normalizeReceiptSummaryKeywordText(lower);
  return RegExp(
    r'\b(total|grand total|order total|purchase total|sale total|'
    r'total sale|sale amount|receipt total|net total|invoice total|'
    r'amount due|total due|amount paid|fuel total|fuel sale|fuel amount|'
    r'pump total|transaction total|transaction amount|transaction amt)\b',
  ).hasMatch(normalized);
}

bool _isPaymentStyleReceiptTotalRow(String lower) {
  final normalized = _normalizeReceiptSummaryKeywordText(lower);
  return RegExp(
    r'\b(amount paid|transaction amount|transaction amt)\b',
  ).hasMatch(normalized);
}

bool _isIgnoredMoneySummaryRow(String lower) {
  final normalized = _normalizeReceiptSummaryKeywordText(lower);
  if (RegExp(
    r'\b(you saved|total saved|total savings|savings today|member savings|reward savings|rewards saved|coupon savings|manufacturer savings|mfr savings|sale savings)\b',
  ).hasMatch(normalized)) {
    return true;
  }
  if (RegExp(
    r'\b(cash back|cashback|change due|refund due|prepay refund|'
    r'unused prepay refund|remaining prepay|prepay balance|rounding|'
    r'round up|donation|gift card balance|begin bal|beginning bal|'
    r'ending bal|end bal|remaining balance|balance remaining|'
    r'previous balance|new balance|available balance)\b',
  ).hasMatch(normalized)) {
    return true;
  }
  if (RegExp(
    r'\b(total discount|discount total|total coupon|coupon total|total markdown|markdown total)\b',
  ).hasMatch(normalized)) {
    return true;
  }
  if (RegExp(
    r'\b(card balance|store credit balance|rewards balance|points balance)\b',
  ).hasMatch(normalized)) {
    return true;
  }
  return false;
}

String _normalizeReceiptSummaryKeywordText(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'\btarjeta\b'), 'card')
      .replaceAll(RegExp(r'\befectivo\b'), 'cash')
      .replaceAll(RegExp(r'\bcambio\b'), 'change due')
      .replaceAll(RegExp(r'\bautorizaci[oó]n\b'), 'authorization')
      .replaceAll(RegExp(r'\bimpuesto\b'), 'tax')
      .replaceAll(RegExp(r'\bventa\s+(?:de\s+)?combustible\b'), 'fuel sale')
      .replaceAll(RegExp(r'\bcombustible\b'), 'fuel')
      .replaceAll(RegExp(r'\bt[0o]tal\b'), 'total')
      .replaceAll(RegExp(r'\bsubt[0o]tal\b'), 'subtotal')
      .replaceAll(RegExp(r'\bam[0o]unt\b'), 'amount')
      .replaceAll(RegExp(r'\bt[4a]x\b'), 'tax');
}

bool _looksLikeIdentifierOnlyCompactMoneyRow(String row) {
  if (_lastMoneyAmount(row) != null) return false;
  final lower = row.toLowerCase();
  if (!_isTotalOrTenderLikeRow(lower)) return false;
  if (!RegExp(
    r'\b(invoice|inv|auth(?:code)?|authorization|approval|transaction|trans|terminal|store|ref(?:erence)?|trace|batch|sales[#:\s]|order)\b',
  ).hasMatch(lower)) {
    return false;
  }
  final compact = RegExp(
    r'(?:^|[\s:])(-)?\$?(\d{3,6})(cr|[a-z]|-)?\s*$',
    caseSensitive: false,
  ).firstMatch(row);
  if (compact == null) return false;
  final prefix = row.substring(0, compact.start).toLowerCase();
  final hasClearAmountCue = RegExp(
    r'(\$|amount|paid|balance\s+due|total\s*[:=]\s*$)',
  ).hasMatch(prefix);
  return !hasClearAmountCue;
}
