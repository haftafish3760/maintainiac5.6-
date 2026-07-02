part of '../../receipts/receipt_ocr_contract.dart';

bool _hasReceiptPriceCandidate(String line) {
  return _hasExplicitReceiptPriceCandidate(line) ||
      _splitTerminalReceiptAmount(line) != null ||
      _separatorlessTerminalReceiptAmount(line) != null;
}

bool _hasExplicitReceiptPriceCandidate(String line) {
  return RegExp(r'(?<!\d)(?:\$?\s*)-?\d{1,5}[.,]\d{2}(?!\d)').hasMatch(line);
}

bool _hasSafeTerminalReceiptAmount(String line) {
  return _terminalReceiptAmount(line) != null;
}

double? _terminalReceiptAmount(String line) {
  final match = RegExp(
    r'(?<!\d)(?:\$?\s*)(-?\d{1,5}[.,]\d{2})\s*(?:[A-Z]{0,3})?\s*$',
  ).firstMatch(line.trim());
  final raw = match?.group(1)?.replaceAll(',', '.');
  final explicit = raw == null ? null : double.tryParse(raw);
  return explicit ??
      _splitTerminalReceiptAmount(line) ??
      _separatorlessTerminalReceiptAmount(line);
}

bool _hasSeparatorlessTerminalReceiptAmount(String line) {
  return !_hasExplicitReceiptPriceCandidate(line) &&
      _splitTerminalReceiptAmount(line) == null &&
      _separatorlessTerminalReceiptAmount(line) != null;
}

bool _hasSplitTerminalReceiptAmount(String line) {
  return !_hasExplicitReceiptPriceCandidate(line) &&
      _splitTerminalReceiptAmount(line) != null;
}

bool _hasReceiptSubtotalCandidate(String line) {
  final lower = _normalizeReceiptSummaryKeywordText(line);
  return _hasReceiptPriceCandidate(line) &&
      RegExp(
        r'\b(subtotal|sub total|sub-total|merch(?:andise)? total|item total|items total|pre[- ]?tax total|pre tax amount|taxable total|taxable subtotal)\b',
      ).hasMatch(lower);
}

bool _hasReceiptTotalCandidate(String line) {
  final lower = _normalizeReceiptSummaryKeywordText(line);
  return _hasReceiptPriceCandidate(line) &&
      RegExp(
        r'\b(total|grand total|order total|purchase total|amount paid|'
        r'amount due|balance due|sale total|total sale|sale amount|'
        r'fuel total|fuel sale|fuel amount|pump total|invoice total|'
        r'transaction total|transaction amount|transaction amt|'
        r'receipt total|net total)\b',
      ).hasMatch(lower) &&
      !RegExp(
        r'\b(subtotal|sub total|sub-total|merch(?:andise)? total|'
        r'item total|items total|pre[- ]?tax total|pre tax amount|'
        r'taxable total|taxable subtotal|begin bal|beginning bal|'
        r'ending bal|gift|refund|return(?:ed)?|saved|savings|'
        r'store\s+credit)\b',
      ).hasMatch(lower);
}

bool _hasReceiptTaxCandidate(String line) {
  final lower = _normalizeReceiptSummaryKeywordText(line);
  return _hasReceiptPriceCandidate(line) &&
      RegExp(
        r'\b(tax|sales tax|state tax|local tax|county tax)\b',
      ).hasMatch(lower);
}

String _normalizeReceiptSummaryKeywordText(String line) {
  return line
      .toLowerCase()
      .replaceAll(RegExp(r'\bt[0o]tal\b'), 'total')
      .replaceAll(RegExp(r'\bsubt[0o]tal\b'), 'subtotal')
      .replaceAll(RegExp(r'\bam[0o]unt\b'), 'amount')
      .replaceAll(RegExp(r'\bt[4a]x\b'), 'tax');
}

bool _hasReceiptDateCandidate(String line) {
  return _receiptDateCandidateMatch(line) != null;
}

bool _hasReceiptTimeCandidate(String line) {
  return _receiptTimeCandidateMatch(line) != null;
}

RegExpMatch? _receiptDateCandidateMatch(String line) {
  if (_looksLikeReceiptItemDateFalsePositiveLine(line)) return null;
  final normalized = _normalizeReceiptDateCandidateText(line);
  for (final match in _receiptDateCandidatePattern.allMatches(normalized)) {
    final yearFirst = match.group(1) != null;
    final year = int.tryParse(match.group(yearFirst ? 1 : 6) ?? '');
    final month = int.tryParse(match.group(yearFirst ? 2 : 4) ?? '');
    final day = int.tryParse(match.group(yearFirst ? 3 : 5) ?? '');
    if (year == null || month == null || day == null) continue;
    final fullYear = year < 100 ? 2000 + year : year;
    if (_isPlausibleReceiptDateParts(fullYear, month, day)) return match;
  }
  return null;
}

bool _looksLikeReceiptItemDateFalsePositiveLine(String line) {
  final clean = line.trim();
  if (!_hasReceiptPriceCandidate(clean)) return false;
  if (_looksLikeFuelExpenseLine(clean)) return true;
  if (_looksLikeReceiptQuantityOrUnitSignal(clean)) return true;
  if (_looksLikeReceiptAtPriceQuantitySignal(clean)) return true;
  return false;
}

String _normalizeReceiptDateCandidateText(String line) {
  return line
      .replaceAll(RegExp(r'[oO]'), '0')
      .replaceAll(RegExp(r'[iIl!|]'), '1')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool _isPlausibleReceiptDateParts(int year, int month, int day) {
  if (year < 2000 || year > 2099) return false;
  if (month < 1 || month > 12) return false;
  if (day < 1 || day > 31) return false;
  return true;
}

RegExpMatch? _receiptTimeCandidateMatch(String line) {
  if (_looksLikeReceiptMetadataOnlyTimeFalsePositiveLine(line)) return null;
  final normalized = _normalizeReceiptTimeCandidateText(
    line,
  ).replaceAll(_receiptDateCandidatePattern, ' ');
  final pattern = RegExp(
    r'(?<!\d)([0-2]?\d)([:.])(\d{2})(?::\d{2})?\s*(a\.?m\.?|p\.?m\.?)?(?!\d)',
    caseSensitive: false,
  );
  final hasDateCandidate = _hasReceiptDateCandidate(line);
  for (final match in pattern.allMatches(normalized)) {
    final hour = int.tryParse(match.group(1) ?? '');
    final separator = match.group(2);
    final minute = int.tryParse(match.group(3) ?? '');
    final marker = match.group(4);
    if (hour == null || minute == null) continue;
    if (separator == '.' && marker == null && !hasDateCandidate) continue;
    if (_isPlausibleReceiptTimeParts(hour, minute)) return match;
  }
  return null;
}

String _normalizeReceiptTimeCandidateText(String line) {
  return line
      .replaceAll(RegExp(r'[oO]'), '0')
      .replaceAll(RegExp(r'[iIl!|]'), '1')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool _isPlausibleReceiptTimeParts(int hour, int minute) {
  if (hour < 0 || hour > 23) return false;
  if (minute < 0 || minute > 59) return false;
  return true;
}

bool _looksLikeReceiptMetadataOnlyTimeFalsePositiveLine(String line) {
  final lower = line.toLowerCase();
  if (_hasReceiptDateCandidate(line)) return false;
  return RegExp(
    r'\b(auth(?:code)?|authorization|approval|batch|invoice|order|ref(?:erence)?|terminal|trace|transaction|trans#?|trans)\b',
  ).hasMatch(lower);
}

final _receiptDateCandidatePattern = RegExp(
  r'(?<!\d)(?:(\d{4})[\s./-]+(\d{1,2})[\s./-]+(\d{1,2})|(\d{1,2})[\s./-]+(\d{1,2})[\s./-]+(\d{2}|\d{4}))(?!\d)',
);

List<double> _receiptMoneyCandidates(String line) {
  final matches = RegExp(
    r'(?<!\d)(?:\$?\s*)(-?\d{1,5}[.,]\d{2})(?!\d)',
  ).allMatches(line);
  final amounts = <double>[];
  for (final match in matches) {
    final raw = match.group(1)?.replaceAll(',', '.');
    final value = raw == null ? null : double.tryParse(raw);
    if (value == null) continue;
    amounts.add(value);
  }
  if (amounts.isEmpty) {
    final inferred =
        _splitTerminalReceiptAmount(line) ??
        _separatorlessTerminalReceiptAmount(line);
    if (inferred != null) amounts.add(inferred);
  }
  return amounts;
}

double? _splitTerminalReceiptAmount(String line) {
  final clean = line.trim();
  if (clean.length < 6) return null;
  if (_hasExplicitReceiptPriceCandidate(clean)) return null;
  if (_looksLikeReceiptBarcodeOrIdLine(clean)) return null;

  final terminalMatch = RegExp(
    r'(?<!\d)(\d{1,5})\s+(\d{2})\s*(?:[A-Z]{0,2})?$',
  ).firstMatch(clean);
  final dollars = terminalMatch?.group(1);
  final cents = terminalMatch?.group(2);
  if (dollars == null || cents == null) return null;
  if (!_hasSafeInferredReceiptMoneyContext(clean)) return null;

  final value = double.tryParse('$dollars.$cents');
  return value == null ? null : _roundReceiptOcrMoney(value);
}

double? _separatorlessTerminalReceiptAmount(String line) {
  final clean = line.trim();
  if (clean.length < 5) return null;
  if (_hasExplicitReceiptPriceCandidate(clean)) return null;
  if (_looksLikeReceiptBarcodeOrIdLine(clean)) return null;

  final terminalMatch = RegExp(
    r'(?<!\d)(\d{3,4})\s*(?:[A-Z]{0,2})?$',
  ).firstMatch(clean);
  final digits = terminalMatch?.group(1);
  if (digits == null) return null;

  if (!_hasSafeInferredReceiptMoneyContext(clean)) return null;
  final cents = int.tryParse(digits);
  if (cents == null || cents <= 0) return null;
  return _roundReceiptOcrMoney(cents / 100);
}

bool _hasSafeInferredReceiptMoneyContext(String line) {
  final clean = line.trim();
  final lower = clean.toLowerCase();
  if (_looksLikeReceiptTenderReferenceLine(clean)) return false;
  final summaryLower = _normalizeReceiptSummaryKeywordText(clean);
  final hasReceiptMoneyLabel = RegExp(
    r'\b(subtotal|sub total|sub-total|tax|total|amount paid|amount due|balance due|sale total|fuel sale|transaction total|payment|paid|cash|change|visa|mastercard|amex|discover|card)\b',
  ).hasMatch(summaryLower);
  final hasExpenseFamilyItemText =
      _looksLikeMaterialExpenseLine(lower) ||
      _looksLikeFuelExpenseLine(lower) ||
      _looksLikeVehicleSupplyExpenseLine(lower) ||
      _looksLikeFoodOrGroceryExpenseLine(lower) ||
      _looksLikeBusinessSupplyExpenseLine(lower) ||
      _looksLikeServiceExpenseLine(lower);
  if (!hasExpenseFamilyItemText &&
      (_looksLikeKnownReceiptMerchantHeaderCandidate(clean) ||
          _looksLikeLocalReceiptMerchantNameSignal(clean))) {
    return false;
  }
  final hasSkuOrCodePrefix = RegExp(
    r'\b(?:barcode|qr|serial|sku|upc)\b',
  ).hasMatch(lower);
  final hasItemText =
      RegExp(r'[a-zA-Z]').allMatches(clean).length >= 3 &&
      !RegExp(
        r'\b(auth(?:code)?|business\s*lic(?:ense)?|invoice|lic(?:ense)?|terminal|trans#?|transaction)\b',
      ).hasMatch(lower) &&
      (!hasSkuOrCodePrefix || hasExpenseFamilyItemText) &&
      !RegExp(
        r'\b(?:address|ave|blvd|drive|lane|ln|road|rd|street|st)\b',
      ).hasMatch(lower);
  return hasReceiptMoneyLabel || hasItemText;
}

double _roundReceiptOcrMoney(double value) {
  return (value * 100).roundToDouble() / 100;
}
