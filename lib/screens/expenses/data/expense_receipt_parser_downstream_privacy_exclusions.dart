part of 'expense_receipt_parser.dart';

Map<String, int> _parserExcludedLineCountsFor(List<String> rows) {
  final counts = <String, int>{};
  void add(String key) => counts[key] = (counts[key] ?? 0) + 1;

  for (final row in rows) {
    final lower = row.toLowerCase();
    final normalized = _normalizeReceiptSummaryKeywordText(lower);
    if (_isTenderTotalRow(lower) || _isIgnoredMoneySummaryRow(lower)) {
      add('payment');
      add('private');
      _addTenderPrivacySubtypes(normalized, add);
      continue;
    }
    if (_looksLikeBarcodeOrReceiptIdMoneyRow(row)) {
      add('barcode');
      add('private');
      continue;
    }
    if (_looksLikePrivateFuelIdentityRow(normalized)) {
      add('identityDetail');
      add('private');
      continue;
    }
    if (RegExp(
      r'\b(auth|authcode|pre[- ]?auth|preauthorization|approval|'
      r'authorization|invoice|order|ref(?:erence)?|terminal|trace|'
      r'transaction|trans)\b',
    ).hasMatch(normalized)) {
      add('transaction');
      add('private');
      _addTransactionPrivacySubtypes(normalized, add);
    }
  }
  return Map.unmodifiable(counts);
}

bool _looksLikePrivateFuelIdentityRow(String normalized) {
  if (RegExp(
    r'\b(loyalty|rewards?|member|membership|club card|shopper|alt id|'
    r'account|acct|customer id|cust id|driver id|driver no|employee id|'
    r'vehicle id|vehicle no|unit no|truck no|tractor no|trailer no|'
    r'vin|license plate|plate|tag no|phone|email|e-mail)\b',
  ).hasMatch(normalized)) {
    return true;
  }
  return RegExp(
    r'\b(?:[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}|'
    r'\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4})\b',
    caseSensitive: false,
  ).hasMatch(normalized);
}

void _addTenderPrivacySubtypes(String normalized, void Function(String) add) {
  if (_isPaymentStyleReceiptTotalRow(normalized) ||
      RegExp(r'\b(payment|paid|tender)\b').hasMatch(normalized)) {
    add('paymentSummary');
  }
  if (RegExp(
    r'\b(card|cards?|visa|mastercard|amex|discover|debit|credit)\b',
  ).hasMatch(normalized)) {
    add('cardTender');
  }
  if (RegExp(r'\b(cash tender|cash)\b').hasMatch(normalized)) {
    add('cashTender');
  }
  if (RegExp(
    r'\b(gift\s*cards?|merch/gift|store credit|ebt|snap|fsa|hsa)\b',
  ).hasMatch(normalized)) {
    add('storedValueTender');
  }
  if (RegExp(
    r'\b(begin bal|beginning bal|ending bal|end bal|remaining balance|balance remaining|previous balance|new balance|available balance|card balance|store credit balance|gift card balance)\b',
  ).hasMatch(normalized)) {
    add('tenderBalanceDetail');
  }
  if (RegExp(
    r'\b(fleet card|fuel card|card flota|flota card|wex|efs|comdata|voyager|fleet one)\b',
  ).hasMatch(normalized)) {
    add('fleetTender');
  }
  _addTransactionPrivacySubtypes(normalized, add);
}

void _addTransactionPrivacySubtypes(
  String normalized,
  void Function(String) add,
) {
  if (RegExp(
    r'\b(auth|authcode|pre[- ]?auth|preauthorization|approval|authorization)\b',
  ).hasMatch(normalized)) {
    add('authDetail');
  }
  if (RegExp(
    r'\b(invoice|order|ref(?:erence)?|terminal|trace|batch)\b',
  ).hasMatch(normalized)) {
    add('referenceDetail');
  }
}
