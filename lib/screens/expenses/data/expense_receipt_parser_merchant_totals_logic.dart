part of 'expense_receipt_parser.dart';

String _normalizeOcrRow(String value) {
  var output = value.trim();
  if (output.isEmpty) return '';
  output = output
      .replaceAll('\u00a0', ' ')
      .replaceAll(RegExp(r'[|]'), ' ')
      .replaceAll(RegExp(r'\bT0TAL\b', caseSensitive: false), 'TOTAL')
      .replaceAll(RegExp(r'\bSUBT0TAL\b', caseSensitive: false), 'SUBTOTAL')
      .replaceAll(RegExp(r'\bAM0UNT\b', caseSensitive: false), 'AMOUNT')
      .replaceAll(RegExp(r'\bPR0DUCT\b', caseSensitive: false), 'PRODUCT')
      .replaceAll(RegExp(r'\bPR[1I!|]CE\b', caseSensitive: false), 'PRICE')
      .replaceAll(RegExp(r'\bFUE[1I!|]\b', caseSensitive: false), 'FUEL')
      .replaceAll(RegExp(r'\bR0AD\b', caseSensitive: false), 'ROAD')
      .replaceAll(RegExp(r'\bD1ESEL\b', caseSensitive: false), 'DIESEL')
      .replaceAll(RegExp(r'\bDIE5EL\b', caseSensitive: false), 'DIESEL')
      .replaceAll(RegExp(r'\bGALL0NS\b', caseSensitive: false), 'GALLONS')
      .replaceAll(RegExp(r'\bGA[1l]\b', caseSensitive: false), 'GAL')
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
  output = _normalizeOcrNumericLetters(output);
  output = output.replaceAllMapped(
    RegExp(r'(\d+)\s*,\s*(\d{2})(?!\d)'),
    (match) => '${match.group(1)}.${match.group(2)}',
  );
  return output;
}

String _normalizeOcrNumericLetters(String value) {
  return value.replaceAllMapped(
    RegExp(
      r'(?<![A-Za-z])(?=[0-9Oo.,]*\d)(?=[0-9Oo.,]*[Oo])[0-9Oo]+(?:[.,][0-9Oo]+)?(?![A-Za-z])',
    ),
    (match) => match.group(0)!.replaceAll(RegExp(r'[Oo]'), '0'),
  );
}

_MerchantProfile? _readMerchantProfile(List<String> rows) {
  final head = rows.take(_merchantHeaderScanLimit).join(' ').toLowerCase();
  for (final profile in _merchantProfiles) {
    if (profile.pattern.hasMatch(head)) return profile;
  }
  return null;
}

String? _readMerchant(List<String> rows) {
  String? fallback;
  var bestScore = 0;
  String? bestMerchant;
  for (
    var index = 0;
    index < rows.length && index < _merchantHeaderScanLimit;
    index += 1
  ) {
    final row = rows[index];
    final lower = row.toLowerCase();
    if (_isAdministrativeRow(lower) ||
        _datePattern.hasMatch(row) ||
        _hasReceiptTimeCandidateRow(row) ||
        _lastMoneyAmount(row) != null) {
      continue;
    }
    final merchant = _cleanMerchantHeaderName(row);
    if (merchant.isEmpty) continue;
    if (_looksLikeGenericReceiptHeaderOnly(merchant)) continue;
    final score = _merchantHeaderScoreFor(merchant, rowIndex: index);
    if (score > 0) fallback ??= merchant;
    if (score > bestScore) {
      bestScore = score;
      bestMerchant = merchant;
    }
  }
  return bestMerchant ?? fallback;
}

const int _merchantHeaderScanLimit = 14;

String _cleanMerchantHeaderName(String row) {
  final merchant = _titleCase(
    row
        .replaceAll(RegExp(r'[^a-zA-Z0-9&.\-# ]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim(),
  ).replaceAll('#', '').replaceAll(RegExp(r'\s+'), ' ').trim();
  return merchant.replaceAll(RegExp(r'\bCvs\b'), 'CVS');
}

int _merchantHeaderScoreFor(String merchant, {required int rowIndex}) {
  final lower = merchant.toLowerCase();
  if (_looksLikeGenericReceiptHeaderOnly(merchant)) return 0;
  if (_looksLikeAddressOrContactRow(lower) &&
      !_looksLikeLocalMerchantHeaderName(lower)) {
    return 0;
  }
  if (_lastMoneyAmount(merchant) != null) return 0;
  if (_looksLikeFuelDetailHeaderOnly(lower)) return 0;
  var score = 8 - rowIndex.clamp(0, 7);
  final alphaCount = RegExp(r'[a-z]').allMatches(lower).length;
  if (alphaCount < 3) return 0;
  if (RegExp(
    r'\b(auto|automotive|building|center|centre|club|co(?:mpany)?|'
    r'corner|depot|electric|express|foods?|fuel|gas|hardware|home|'
    r'improvement|kitchen|lumber|market|mart|parts|pharmacy|station|'
    r'supply|store|stop|travel|truck|wireless)\b',
  ).hasMatch(lower)) {
    score += 16;
  }
  if (RegExp(r'\b(llc|inc|ltd|corp|co)\b').hasMatch(lower)) score += 4;
  if (RegExp(r'\b\d{1,5}\b').hasMatch(lower) && alphaCount >= 5) score += 2;
  if (lower.length >= 8) score += 2;
  return score;
}

bool _looksLikeLocalMerchantHeaderName(String lower) {
  return RegExp(
    r'\b(auto|automotive|corner|foods?|fuel|gas|hardware|lumber|market|mart|parts|station|supply|store|stop|travel|truck)\b',
  ).hasMatch(lower);
}

bool _looksLikeFuelDetailHeaderOnly(String lower) {
  return RegExp(
    r'\b(pump|product|gallons?|galns|gals?|fuel\s*vol(?:ume)?|'
    r'vol(?:ume)?|qty|qnty|quantity|price\s*/\s*g(?:al)?|'
    r'price\s*/\s*gal|price\s*per\s*gal|\$\s*/\s*gal|ppu|ppg|'
    r'ppl|cng|compressed natural gas|gge|price\s*/\s*gge|ppge|'
    r'propane|lpg|lp gas|autogas|auto gas|'
    r'hydrogen|h2 fuel|fuel cell|kg h2|price\s*/\s*kg|ppkg|'
    r'fuel sale|fuel total|fuel amount|fuel amt|card|cash|visa|'
    r'mastercard)\b',
  ).hasMatch(lower);
}

bool _looksLikeGenericReceiptHeaderOnly(String merchant) {
  final lower = merchant.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ');
  final compact = lower.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (compact.isEmpty) return true;
  if (RegExp(
    r'^(sale|sales?|receipt|invoice|tax invoice|welcome|thank you|'
    r'thanks|customer copy|merchant copy|store copy|open 24 hours|'
    r'open 24 hrs|now hiring|order|transaction|cashier|register|'
    r'terminal|returns?|refunds?|visit us|save money live better)$',
  ).hasMatch(compact)) {
    return true;
  }
  if (RegExp(r'^(open|closed)\s+\d{1,2}\s*(hours|hrs)?$').hasMatch(compact)) {
    return true;
  }
  return false;
}

_ReceiptTotals _readTotals(List<String> rows) {
  double? subtotal;
  double? tax;
  double? total;
  final paymentStyleTotalCandidates = <double>[];
  final tenderTotals = <double>[];
  var hasExplicitSubtotal = false;
  var hasExplicitTax = false;
  var hasExplicitTotal = false;
  for (final row in rows) {
    final lower = row.toLowerCase();
    if (_looksLikeAddressOrContactRow(lower)) continue;
    final allowCompactCents =
        _isTotalOrTenderLikeRow(lower) &&
        !_looksLikeIdentifierOnlyCompactMoneyRow(row);
    final amount = _lastMoneyAmount(row, allowCompactCents: allowCompactCents);
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
      final rounded = _roundMoney(amount);
      if (_isPaymentStyleReceiptTotalRow(lower)) {
        paymentStyleTotalCandidates.add(rounded);
      } else {
        total = rounded;
        hasExplicitTotal = true;
      }
    } else if (RegExp(r'\bbalance due\b').hasMatch(lower) && amount > 0) {
      total = _roundMoney(amount);
      hasExplicitTotal = true;
    } else if (_isTenderTotalRow(lower)) {
      tenderTotals.add(_roundMoney(amount));
    }
  }
  final fallbackTotal = _singleUniqueReceiptAmount(paymentStyleTotalCandidates);
  final fallbackTenderTotal = _singleUniqueReceiptAmount(tenderTotals);
  if (total == null && fallbackTotal != null) {
    total = fallbackTotal;
    hasExplicitTotal = true;
  }
  if (total == null && fallbackTenderTotal != null) {
    total = fallbackTenderTotal;
    hasExplicitTotal = true;
  }
  final splitTenderTotal = tenderTotals.length > 1
      ? _roundMoney(tenderTotals.fold<double>(0, (sum, amount) => sum + amount))
      : null;
  if (subtotal == null && total != null && tax != null) {
    subtotal = _roundMoney(total - tax);
  }
  if (tax == null && total != null && subtotal != null) {
    tax = _roundMoney(total - subtotal);
  }
  if (total == null && subtotal != null && tax != null) {
    total = _roundMoney(subtotal + tax);
  }
  return _ReceiptTotals(
    subtotal: subtotal,
    tax: tax,
    total: total,
    hasExplicitSubtotal: hasExplicitSubtotal,
    hasExplicitTax: hasExplicitTax,
    hasExplicitTotal: hasExplicitTotal,
    splitTenderTotal: splitTenderTotal,
    splitTenderCount: tenderTotals.length,
  );
}

double? _singleUniqueReceiptAmount(List<double> amounts) {
  if (amounts.isEmpty) return null;
  final unique = <double>{};
  for (final amount in amounts) {
    unique.add(_roundMoney(amount));
  }
  if (unique.length != 1) return null;
  return unique.single;
}
