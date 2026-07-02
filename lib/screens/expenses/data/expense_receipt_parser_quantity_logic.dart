part of 'expense_receipt_parser.dart';

_ParsedQuantity _quantityFor(String description, String category) {
  final rule = expenseReceiptRuleForCategory(category);
  if (!rule.usesQuantityFields) {
    return const _ParsedQuantity(quantity: 1, unitsPerPackage: 1, unit: 'each');
  }
  final lower = description.toLowerCase();
  if (rule.isFuel) {
    final gallons = RegExp(
      r'(\d+(?:\.\d+)?)\s*(gal|gallon|gallons)\b',
    ).firstMatch(lower);
    if (gallons != null) {
      return _ParsedQuantity(
        quantity: double.parse(gallons.group(1)!),
        unitsPerPackage: 1,
        unit: 'gallon',
      );
    }
    final kwh = RegExp(r'(\d+(?:\.\d+)?)\s*kwh\b').firstMatch(lower);
    if (kwh != null) {
      return _ParsedQuantity(
        quantity: double.parse(kwh.group(1)!),
        unitsPerPackage: 1,
        unit: 'kWh',
      );
    }
    return const _ParsedQuantity(
      quantity: 1,
      unitsPerPackage: 1,
      unit: 'gallon',
    );
  }
  final pack = RegExp(
    r'(\d+(?:\.\d+)?)\s*(pack|pk|box|case|pkg)\b',
  ).firstMatch(lower);
  if (pack != null) {
    return _ParsedQuantity(
      quantity: 1,
      unitsPerPackage: double.parse(pack.group(1)!),
      unit: defaultExpenseReceiptUnit(category),
    );
  }
  final qty = RegExp(r'\bqty\s*[:#]?\s*(\d+(?:\.\d+)?)\b').firstMatch(lower);
  if (qty != null) {
    return _ParsedQuantity(
      quantity: double.parse(qty.group(1)!),
      unitsPerPackage: 1,
      unit: defaultExpenseReceiptUnit(category),
    );
  }
  final multiplier = RegExp(
    r'(?:^|\s)(\d+(?:\.\d+)?)\s*(?:@|x)(?:\s|$)',
  ).firstMatch(lower);
  if (multiplier != null) {
    return _ParsedQuantity(
      quantity: double.parse(multiplier.group(1)!),
      unitsPerPackage: 1,
      unit: defaultExpenseReceiptUnit(category),
    );
  }
  final leadingEach = RegExp(
    r'^\s*(\d+(?:\.\d+)?)\s*(?:ea|each)\b',
  ).firstMatch(lower);
  if (leadingEach != null) {
    return _ParsedQuantity(
      quantity: double.parse(leadingEach.group(1)!),
      unitsPerPackage: 1,
      unit: defaultExpenseReceiptUnit(category),
    );
  }
  return _ParsedQuantity(
    quantity: 1,
    unitsPerPackage: 1,
    unit: defaultExpenseReceiptUnit(category),
  );
}
