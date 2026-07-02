part of '../../receipts/receipt_ocr_contract.dart';

ReceiptOcrParserLineKind _parserLineKindFor(
  String line,
  int index,
  List<double> amountCandidates,
) {
  if (_hasReceiptTotalCandidate(line)) {
    return ReceiptOcrParserLineKind.totalCandidate;
  }
  if (_hasReceiptTaxCandidate(line)) {
    return ReceiptOcrParserLineKind.taxCandidate;
  }
  if (_hasReceiptSubtotalCandidate(line)) {
    return ReceiptOcrParserLineKind.subtotalCandidate;
  }
  if (_looksLikeReceiptTenderLine(line)) {
    return ReceiptOcrParserLineKind.tenderCandidate;
  }
  if (_hasReceiptDateCandidate(line)) {
    return ReceiptOcrParserLineKind.dateCandidate;
  }
  if (_looksLikeReceiptBarcodeOrIdLine(line)) {
    return ReceiptOcrParserLineKind.barcodeOrId;
  }
  if (_looksLikeReceiptMetadataLine(line)) {
    return ReceiptOcrParserLineKind.receiptMetadata;
  }
  if (_looksLikeFuelExpenseLine(_normalizeReceiptParserLineText(line)) &&
      _hasFuelItemEvidence(line, amountCandidates)) {
    return ReceiptOcrParserLineKind.itemCandidate;
  }
  if (amountCandidates.isNotEmpty && _looksLikeReceiptItemCandidate(line)) {
    return ReceiptOcrParserLineKind.itemCandidate;
  }
  if (index < 8 && _looksLikeReceiptVendorCandidate(line)) {
    return ReceiptOcrParserLineKind.vendorCandidate;
  }
  return ReceiptOcrParserLineKind.other;
}

bool _hasFuelItemEvidence(String line, List<double> amountCandidates) {
  if (amountCandidates.isNotEmpty) return true;
  if (_looksLikeFuelReceiptQuantitySignal(line)) return true;
  if (_looksLikeFuelReceiptUnitPriceSignal(line)) return true;
  final clean = _normalizeFuelReceiptSignalText(line);
  return RegExp(
    r'\b(?:diesel|midgrade|premium|product|regular|unleaded)\b',
    caseSensitive: false,
  ).hasMatch(clean);
}

bool _looksLikeReceiptVendorCandidate(String line) {
  final clean = line.trim();
  if (clean.length < 2) return false;
  final lower = clean.toLowerCase();
  if (RegExp(
    r'^(?:private|sample|test|unknown)\s+(?:merchant|store|vendor)$',
  ).hasMatch(lower)) {
    return false;
  }
  if (_hasReceiptPriceCandidate(clean)) return false;
  if (_hasReceiptTotalCandidate(clean) || _hasReceiptTaxCandidate(clean)) {
    return false;
  }
  if (_looksLikeLocalReceiptMerchantNameSignal(clean)) return true;
  if (_looksLikeReceiptAddressOrContactLine(clean)) return false;
  if (_looksLikeKnownReceiptMerchantHeaderCandidate(clean)) return true;
  if (RegExp(
    r'\b(card|cashier|invoice|pump|receipt|register|terminal|trans|auth)\b',
  ).hasMatch(lower)) {
    return false;
  }
  final letters = RegExp(r'[a-zA-Z]').allMatches(clean).length;
  if (letters < 2) return false;
  final digits = RegExp(r'\d').allMatches(clean).length;
  return digits <= letters;
}

bool _looksLikeWeakReceiptHeaderCandidate(
  String line,
  ReceiptOcrParserLineKind kind,
) {
  if (kind != ReceiptOcrParserLineKind.other) return false;
  final clean = line.trim();
  if (_looksLikeKnownReceiptMerchantHeaderCandidate(clean)) return true;
  if (clean.length < 3 || clean.length > 36) return false;
  if (_hasReceiptPriceCandidate(clean) ||
      _hasReceiptDateCandidate(clean) ||
      _hasReceiptTotalCandidate(clean) ||
      _hasReceiptTaxCandidate(clean) ||
      _hasReceiptSubtotalCandidate(clean) ||
      _looksLikeReceiptTenderLine(clean) ||
      _looksLikeReceiptBarcodeOrIdLine(clean) ||
      _looksLikeReceiptMetadataLine(clean) ||
      _looksLikeReceiptAddressOrContactLine(clean)) {
    return false;
  }
  final letters = RegExp(r'[a-zA-Z]').allMatches(clean).length;
  if (letters < 2) return false;
  final digits = RegExp(r'\d').allMatches(clean).length;
  final symbolRuns = RegExp(r'[#*_=\-]{2,}').allMatches(clean).length;
  if (digits == 0 && symbolRuns == 0) return false;
  final words = clean.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
  if (words.length > 5) return false;
  return true;
}

bool _looksLikeKnownReceiptMerchantHeaderCandidate(String line) {
  final packed = _normalizeReceiptMerchantHeaderText(line);
  if (packed.length < 2) return false;
  const knownMerchantTokens = <String>[
    'lowes',
    'homedepot',
    'walmart',
    'samsclub',
    'shell',
    'exxon',
    'chevron',
    'pilot',
    'flyingj',
    'loves',
    'kroger',
    'costco',
    'acehardware',
    'napa',
    'advanceautoparts',
    'oreilly',
    'autozone',
    'menards',
    'harborfreight',
    'tractorsupply',
  ];
  return knownMerchantTokens.any(packed.contains);
}

bool _looksLikeLocalReceiptMerchantNameSignal(String line) {
  final clean = line.trim();
  final lower = clean.toLowerCase();
  if (clean.length < 6 || clean.length > 42) return false;
  if (RegExp(r'^\d+\s+\S+').hasMatch(clean)) return false;
  if (RegExp(r'\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}').hasMatch(clean)) {
    return false;
  }
  if (RegExp(r'\b\d{5}(?:-\d{4})?\b').hasMatch(clean)) return false;
  if (RegExp(
    r'\b(?:auth|cashier|customer|invoice|order|receipt|register|sale|terminal|thank|transaction|trans)\b',
  ).hasMatch(lower)) {
    return false;
  }
  if (!RegExp(
    r'\b(?:auto|automotive|corner|depot|fuel|hardware|home|lumber|market|mart|parts|road|shop|stop|store|supply|truck)\b',
  ).hasMatch(lower)) {
    return false;
  }
  final wordCount = RegExp(r'[a-zA-Z][a-zA-Z0-9&/-]*').allMatches(clean).length;
  final letters = RegExp(r'[a-zA-Z]').allMatches(clean).length;
  final digits = RegExp(r'\d').allMatches(clean).length;
  return wordCount >= 2 && wordCount <= 5 && letters >= 6 && digits <= 4;
}

bool _looksLikeUnknownReceiptMerchantHeaderCandidate(
  String line, {
  required ReceiptOcrParserLineKind kind,
}) {
  if (kind != ReceiptOcrParserLineKind.vendorCandidate) return false;
  if (_looksLikeKnownReceiptMerchantHeaderCandidate(line)) return false;
  if (_looksLikeLocalReceiptMerchantNameSignal(line)) return true;
  final clean = line.trim();
  if (clean.length < 4 || clean.length > 42) return false;
  if (_hasReceiptPriceCandidate(clean) ||
      _hasReceiptDateCandidate(clean) ||
      _hasReceiptTotalCandidate(clean) ||
      _hasReceiptTaxCandidate(clean) ||
      _hasReceiptSubtotalCandidate(clean) ||
      _looksLikeReceiptTenderLine(clean) ||
      _looksLikeReceiptBarcodeOrIdLine(clean) ||
      _looksLikeReceiptMetadataLine(clean) ||
      _looksLikeReceiptAddressOrContactLine(clean)) {
    return false;
  }
  final lower = clean.toLowerCase();
  if (RegExp(
    r'\b(?:auth|cashier|customer|invoice|order|receipt|register|sale|terminal|thank|transaction|trans)\b',
  ).hasMatch(lower)) {
    return false;
  }
  final wordMatches = RegExp(r"[a-zA-Z][a-zA-Z0-9&'/-]*").allMatches(clean);
  final wordCount = wordMatches.length;
  if (wordCount < 2 || wordCount > 5) return false;
  final letters = RegExp(r'[a-zA-Z]').allMatches(clean).length;
  if (letters < 6) return false;
  final digits = RegExp(r'\d').allMatches(clean).length;
  if (digits > 4 || digits > letters) return false;
  return true;
}
