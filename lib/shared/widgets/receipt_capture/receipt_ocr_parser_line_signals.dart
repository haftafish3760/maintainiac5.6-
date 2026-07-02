part of '../../receipts/receipt_ocr_contract.dart';

List<String> _receiptOcrLines(String text) {
  return List.unmodifiable(
    text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty),
  );
}

String _normalizeReceiptParserLineText(String line) {
  return line
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9.,/&$#:\-\s]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

ReceiptOcrParserLineSignal _parserLineSignalFor(
  String line,
  int index, {
  ReceiptOcrParserLineLocation? sourceLocation,
}) {
  final amounts = _receiptMoneyCandidates(line);
  final kind = _parserLineKindFor(line, index, amounts);
  final expenseFamily = _parserExpenseFamilyFor(line, kind);
  final parserHint = _parserLineHintFor(kind, expenseFamily, amounts);
  final traits = _parserLineTraitsFor(line, kind, amounts, expenseFamily);
  final confidence = _parserLineConfidenceFor(line, kind, amounts);
  return ReceiptOcrParserLineSignal(
    index: index,
    text: line,
    kind: kind,
    amountCandidates: List.unmodifiable(amounts),
    traits: traits,
    confidence: confidence,
    reviewReason: _parserLineReviewReasonFor(line, kind, amounts, confidence),
    sourceLocation: sourceLocation,
    expenseFamily: expenseFamily,
    parserHint: parserHint,
  );
}

List<String> _parserLineTraitsFor(
  String line,
  ReceiptOcrParserLineKind kind,
  List<double> amountCandidates,
  ReceiptOcrParserExpenseFamily expenseFamily,
) {
  final clean = _normalizeReceiptParserLineText(line);
  final traits = <String>{};
  if (amountCandidates.isNotEmpty) traits.add('price_present');
  if (_hasSeparatorlessTerminalReceiptAmount(line)) {
    traits.add('separatorless_money_inferred');
  }
  if (_hasSplitTerminalReceiptAmount(line)) {
    traits.add('split_cents_money_inferred');
  }
  if (kind == ReceiptOcrParserLineKind.itemCandidate) {
    if (_hasSafeTerminalReceiptAmount(line)) {
      traits.add('safe_terminal_line_amount');
      traits.add('terminal_line_amount_selected');
    } else if (amountCandidates.isNotEmpty) {
      traits.add('embedded_amount_review');
    }
    if (amountCandidates.length > 1) {
      if ((_looksLikeReceiptQuantityOrUnitSignal(clean) ||
              _looksLikeReceiptAtPriceQuantitySignal(line)) &&
          _hasSafeTerminalReceiptAmount(line)) {
        traits.add('unit_or_quantity_amounts_present');
      } else {
        traits.add('multiple_amounts_review');
      }
    }
  }
  if (_hasReceiptDateCandidate(line)) traits.add('date_present');
  if (_hasReceiptTimeCandidate(line)) traits.add('time_present');
  if (_looksLikeReceiptAddressOrContactLine(clean)) {
    traits.add('address_or_contact_metadata');
  }
  if (_looksLikeKnownReceiptMerchantHeaderCandidate(line)) {
    traits.add('known_merchant_header_candidate');
  }
  if (_looksLikeUnknownReceiptMerchantHeaderCandidate(line, kind: kind)) {
    traits.add('unknown_merchant_header_candidate');
  }
  if (_looksLikeWeakReceiptHeaderCandidate(clean, kind)) {
    traits.add('weak_header_candidate');
  }
  if (_looksLikeReceiptSkuOrCodeSignal(clean)) traits.add('sku_like');
  if (_looksLikeReceiptQuantityOrUnitSignal(clean) ||
      _looksLikeReceiptAtPriceQuantitySignal(line)) {
    traits.add('quantity_or_unit');
  }
  if (expenseFamily == ReceiptOcrParserExpenseFamily.fuel) {
    if (_looksLikeFuelReceiptQuantitySignal(clean)) {
      traits.add('fuel_quantity_signal');
    }
    if (_looksLikeFuelReceiptUnitPriceSignal(clean)) {
      traits.add('fuel_unit_price_signal');
    }
  }
  if (_looksLikeGenericReceiptItemText(clean)) {
    traits.add('generic_description');
  }
  final familyToken = _receiptExpenseFamilyToken(expenseFamily);
  if (familyToken != 'unknown') {
    traits.add('expense_family_$familyToken');
  }
  if (kind == ReceiptOcrParserLineKind.itemCandidate &&
      amountCandidates.isNotEmpty &&
      _hasSafeTerminalReceiptAmount(line) &&
      !_looksLikeGenericReceiptItemText(clean) &&
      (_looksLikeReceiptQuantityOrUnitSignal(clean) ||
          _looksLikeReceiptAtPriceQuantitySignal(line) ||
          _looksLikeReceiptSkuOrCodeSignal(clean) ||
          expenseFamily == ReceiptOcrParserExpenseFamily.materials)) {
    traits.add('candidate_inventory_prep');
  }
  if (kind == ReceiptOcrParserLineKind.itemCandidate) {
    traits.add('candidate_expense_item');
  } else if (kind == ReceiptOcrParserLineKind.vendorCandidate) {
    traits.add('candidate_vendor');
  } else if (kind == ReceiptOcrParserLineKind.totalCandidate ||
      kind == ReceiptOcrParserLineKind.subtotalCandidate ||
      kind == ReceiptOcrParserLineKind.taxCandidate) {
    traits.add('candidate_receipt_total');
  } else if (kind == ReceiptOcrParserLineKind.tenderCandidate) {
    traits.add('candidate_tender');
  } else if (kind == ReceiptOcrParserLineKind.receiptMetadata ||
      kind == ReceiptOcrParserLineKind.barcodeOrId) {
    traits.add('candidate_metadata');
  }
  return List.unmodifiable(traits);
}
