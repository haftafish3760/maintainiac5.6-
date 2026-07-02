part of '../../receipts/receipt_ocr_contract.dart';

String _parserLineHintFor(
  ReceiptOcrParserLineKind kind,
  ReceiptOcrParserExpenseFamily family,
  List<double> amountCandidates,
) {
  final hasAmount = amountCandidates.isNotEmpty;
  if (kind == ReceiptOcrParserLineKind.itemCandidate) {
    final familyToken = _receiptExpenseFamilyToken(family);
    if (!hasAmount) return '${familyToken}_item_missing_price';
    return '${familyToken}_item_price';
  }
  if (kind == ReceiptOcrParserLineKind.vendorCandidate) {
    return 'vendor_candidate';
  }
  if (kind == ReceiptOcrParserLineKind.dateCandidate) {
    return 'date_candidate';
  }
  if (kind == ReceiptOcrParserLineKind.subtotalCandidate) {
    return 'subtotal_candidate';
  }
  if (kind == ReceiptOcrParserLineKind.taxCandidate) {
    return 'tax_candidate';
  }
  if (kind == ReceiptOcrParserLineKind.totalCandidate) {
    return 'total_candidate';
  }
  if (kind == ReceiptOcrParserLineKind.tenderCandidate) {
    return 'tender_evidence';
  }
  if (kind == ReceiptOcrParserLineKind.receiptMetadata ||
      kind == ReceiptOcrParserLineKind.barcodeOrId) {
    return 'receipt_metadata';
  }
  return hasAmount ? 'unclassified_price' : 'unclassified_text';
}

double _parserLineConfidenceFor(
  String line,
  ReceiptOcrParserLineKind kind,
  List<double> amountCandidates,
) {
  final clean = line.trim();
  final letterCount = RegExp(r'[a-zA-Z]').allMatches(clean).length;
  final wordCount = RegExp(r'[a-zA-Z0-9]+').allMatches(clean).length;
  final hasAmount = amountCandidates.isNotEmpty;
  return switch (kind) {
    ReceiptOcrParserLineKind.itemCandidate => _itemLineSignalConfidence(
      clean: clean,
      rawLine: line,
      letterCount: letterCount,
      wordCount: wordCount,
      amountCount: amountCandidates.length,
    ),
    ReceiptOcrParserLineKind.totalCandidate ||
    ReceiptOcrParserLineKind.subtotalCandidate ||
    ReceiptOcrParserLineKind.taxCandidate => hasAmount ? .92 : .56,
    ReceiptOcrParserLineKind.tenderCandidate => hasAmount ? .88 : .7,
    ReceiptOcrParserLineKind.dateCandidate => .9,
    ReceiptOcrParserLineKind.vendorCandidate =>
      letterCount >= 4 && !hasAmount ? .78 : .58,
    ReceiptOcrParserLineKind.receiptMetadata ||
    ReceiptOcrParserLineKind.barcodeOrId => .86,
    ReceiptOcrParserLineKind.other => hasAmount ? .34 : .18,
  };
}

double _itemLineSignalConfidence({
  required String clean,
  required String rawLine,
  required int letterCount,
  required int wordCount,
  required int amountCount,
}) {
  var confidence = .86;
  if (letterCount < 3) confidence -= .22;
  if (wordCount < 2) confidence -= .12;
  if (amountCount == 0) confidence -= .34;
  if (amountCount > 1) {
    confidence -=
        (_looksLikeReceiptQuantityOrUnitSignal(clean) ||
                _looksLikeReceiptAtPriceQuantitySignal(rawLine)) &&
            _hasSafeTerminalReceiptAmount(rawLine)
        ? .04
        : .12;
  }
  if (amountCount > 0 && !_hasSafeTerminalReceiptAmount(rawLine)) {
    confidence -= .22;
  }
  if (_looksLikeReceiptQuantityOrUnitSignal(clean) ||
      _looksLikeReceiptAtPriceQuantitySignal(rawLine)) {
    confidence += .05;
  }
  if (_looksLikeGenericReceiptItemText(clean)) {
    confidence -= .16;
  }
  return confidence.clamp(0, 1).toDouble();
}

String _parserLineReviewReasonFor(
  String line,
  ReceiptOcrParserLineKind kind,
  List<double> amountCandidates,
  double confidence,
) {
  final clean = line.trim();
  if (kind == ReceiptOcrParserLineKind.itemCandidate) {
    if (amountCandidates.isEmpty) {
      return 'Item-like line has no safe price candidate.';
    }
    if (!_hasSafeTerminalReceiptAmount(line)) {
      return 'Item-like line has a price that is not at the line total position; review before trusting it.';
    }
    if (amountCandidates.length > 1 &&
        !_looksLikeReceiptQuantityOrUnitSignal(clean) &&
        !_looksLikeReceiptAtPriceQuantitySignal(line)) {
      return 'Item-like line has multiple price candidates; review quantity and price.';
    }
    if (confidence >= .84) {
      return amountCandidates.length > 1
          ? 'Line has quantity/unit amounts and a terminal line total.'
          : 'Line has receipt item text and one price candidate.';
    }
    if (_looksLikeGenericReceiptItemText(clean)) {
      return 'Line is generic; review category and description.';
    }
    return 'Line item needs review before trusting the parsed expense.';
  }
  if (kind == ReceiptOcrParserLineKind.vendorCandidate) {
    return confidence >= .84
        ? 'Header line is a strong vendor candidate.'
        : 'Header line may be the vendor; review store name.';
  }
  if (kind == ReceiptOcrParserLineKind.dateCandidate) {
    return 'Line contains a receipt date candidate.';
  }
  if (kind == ReceiptOcrParserLineKind.subtotalCandidate) {
    return 'Line contains a subtotal amount candidate.';
  }
  if (kind == ReceiptOcrParserLineKind.taxCandidate) {
    return 'Line contains a tax amount candidate.';
  }
  if (kind == ReceiptOcrParserLineKind.totalCandidate) {
    return 'Line contains a total amount candidate.';
  }
  if (kind == ReceiptOcrParserLineKind.tenderCandidate) {
    return 'Payment/tender line; keep as receipt evidence, not an expense item.';
  }
  if (kind == ReceiptOcrParserLineKind.receiptMetadata ||
      kind == ReceiptOcrParserLineKind.barcodeOrId) {
    return 'Receipt metadata line; keep for context, not an expense item.';
  }
  return 'Line is not safe enough to classify automatically.';
}

String _receiptParserConfidenceBucket(double confidence) {
  if (confidence >= .92) return 'high';
  if (confidence >= .84) return 'good';
  if (confidence >= .68) return 'review';
  if (confidence > 0) return 'low';
  return 'unknown';
}
