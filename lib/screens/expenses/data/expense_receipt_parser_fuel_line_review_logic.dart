part of 'expense_receipt_parser.dart';

bool _fuelLineNeedsDetailReview(ExpenseReceiptLineRecord line) {
  return _fuelLineQuantityNeedsReview(line) ||
      _fuelLineUnitPriceNeedsReview(line) ||
      _fuelLineAmountMathNeedsReview(line);
}

bool _fuelLineQuantityNeedsReview(ExpenseReceiptLineRecord line) {
  if (_parserCategoryFamilyFor(line.category) != 'fuel') return false;
  if (line.subtotal <= 0) return false;
  if (_fuelLineHasParsedQuantityEvidence(line)) return false;
  final raw = line.rawReceiptText.toLowerCase();
  final hasExplicitQuantity = RegExp(
    r'\b(\d+(?:\.\d+)?)\s*(gal|gals|gallon|gallons|gl|g|kwh|l|liter|liters|litre|litres)\b|\b(gal|gals|gallon|gallons|gl|volume|vol|qty|qnty|quantity|fuel\s+qty|fuel\s+volume|kwh)\s*[:#]?\s*(\d+(?:\.\d+)?)\b',
  ).hasMatch(raw);
  return !hasExplicitQuantity;
}

bool _fuelLineHasParsedQuantityEvidence(ExpenseReceiptLineRecord line) {
  final unit = line.unit.trim().toLowerCase();
  if (line.quantity <= 1) return false;
  return unit == 'gallon' ||
      unit == 'liter' ||
      unit == 'litre' ||
      unit == 'kwh';
}

bool _fuelLineUnitPriceNeedsReview(ExpenseReceiptLineRecord line) {
  if (_parserCategoryFamilyFor(line.category) != 'fuel') return false;
  if (line.subtotal <= 0) return false;
  return line.unitPrice == null;
}

bool _fuelLineAmountMathNeedsReview(ExpenseReceiptLineRecord line) {
  if (_parserCategoryFamilyFor(line.category) != 'fuel') return false;
  if (line.subtotal <= 0) return false;
  final unitPrice = line.unitPrice;
  if (unitPrice == null || unitPrice <= 0) return false;
  if (!_fuelLineHasParsedQuantityEvidence(line)) return false;
  final expected = line.quantity * unitPrice;
  var tolerance = line.subtotal.abs() * .02;
  if (tolerance < .05) tolerance = .05;
  return (expected - line.subtotal).abs() > tolerance;
}
