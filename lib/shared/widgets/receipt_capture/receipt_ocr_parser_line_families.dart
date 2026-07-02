part of '../../receipts/receipt_ocr_contract.dart';

ReceiptOcrParserExpenseFamily _parserExpenseFamilyFor(
  String line,
  ReceiptOcrParserLineKind kind,
) {
  if (kind == ReceiptOcrParserLineKind.vendorCandidate ||
      kind == ReceiptOcrParserLineKind.dateCandidate) {
    return ReceiptOcrParserExpenseFamily.receiptHeader;
  }
  if (kind == ReceiptOcrParserLineKind.subtotalCandidate ||
      kind == ReceiptOcrParserLineKind.taxCandidate ||
      kind == ReceiptOcrParserLineKind.totalCandidate) {
    return ReceiptOcrParserExpenseFamily.receiptSummary;
  }
  if (kind == ReceiptOcrParserLineKind.tenderCandidate ||
      kind == ReceiptOcrParserLineKind.receiptMetadata ||
      kind == ReceiptOcrParserLineKind.barcodeOrId) {
    return ReceiptOcrParserExpenseFamily.tenderOrMetadata;
  }
  final clean = _normalizeReceiptParserLineText(line);
  if (_looksLikeFuelExpenseLine(clean)) {
    return ReceiptOcrParserExpenseFamily.fuel;
  }
  if (kind != ReceiptOcrParserLineKind.itemCandidate) {
    return ReceiptOcrParserExpenseFamily.unknown;
  }
  if (_looksLikeVehicleSupplyExpenseLine(clean)) {
    return ReceiptOcrParserExpenseFamily.vehicleSupplies;
  }
  if (_looksLikeMaterialExpenseLine(clean)) {
    return ReceiptOcrParserExpenseFamily.materials;
  }
  if (_looksLikeFoodOrGroceryExpenseLine(clean)) {
    return ReceiptOcrParserExpenseFamily.foodOrGrocery;
  }
  if (_looksLikeBusinessSupplyExpenseLine(clean)) {
    return ReceiptOcrParserExpenseFamily.businessSupplies;
  }
  if (_looksLikeServiceExpenseLine(clean)) {
    return ReceiptOcrParserExpenseFamily.service;
  }
  return ReceiptOcrParserExpenseFamily.generalExpense;
}

String _receiptExpenseFamilyToken(ReceiptOcrParserExpenseFamily family) {
  return switch (family) {
    ReceiptOcrParserExpenseFamily.materials => 'materials',
    ReceiptOcrParserExpenseFamily.fuel => 'fuel',
    ReceiptOcrParserExpenseFamily.vehicleSupplies => 'vehicle_supplies',
    ReceiptOcrParserExpenseFamily.foodOrGrocery => 'food_or_grocery',
    ReceiptOcrParserExpenseFamily.businessSupplies => 'business_supplies',
    ReceiptOcrParserExpenseFamily.service => 'service',
    ReceiptOcrParserExpenseFamily.generalExpense => 'general_expense',
    ReceiptOcrParserExpenseFamily.receiptSummary => 'receipt_summary',
    ReceiptOcrParserExpenseFamily.receiptHeader => 'receipt_header',
    ReceiptOcrParserExpenseFamily.tenderOrMetadata => 'tender_or_metadata',
    ReceiptOcrParserExpenseFamily.unknown => 'unknown',
  };
}

String _receiptExpenseFamilyDisplayLabel(String family) {
  return switch (family) {
    'materials' => 'materials',
    'fuel' => 'fuel',
    'vehicle_supplies' => 'vehicle supplies',
    'food_or_grocery' => 'food/grocery',
    'business_supplies' => 'business supplies',
    'service' => 'service',
    'general_expense' => 'general expense',
    'receipt_summary' => 'receipt summary',
    'receipt_header' => 'receipt header',
    'tender_or_metadata' => 'tender/metadata',
    _ => 'unknown',
  };
}
