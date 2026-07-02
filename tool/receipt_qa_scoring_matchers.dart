part of 'receipt_qa_runner.dart';

bool _matchesMerchant(String? actual, String expectedNeedle) {
  final normalizedActual = (actual ?? '').toLowerCase();
  final normalizedExpected = expectedNeedle.toLowerCase();
  return normalizedActual.contains(normalizedExpected) ||
      normalizedExpected.contains(normalizedActual);
}

bool _isParsedFuelLine(ExpenseReceiptLineRecord line) {
  return line.category.toLowerCase() == 'fuel' ||
      (line.parserExpenseFamily ?? '').toLowerCase() == 'fuel' ||
      line.fuelType != null;
}

bool _lineAllocationReconciles(ExpenseReceiptParseResult parsed) {
  for (final line in parsed.lines) {
    final allocated = line.businessAmount + line.personalAmount;
    if ((allocated - line.subtotal).abs() > 0.01) return false;
  }
  return (parsed.businessTotal + parsed.personalTotal - parsed.receiptTotal)
          .abs() <=
      0.02;
}

bool _lineSubtotalsMatch(
  List<ExpenseReceiptLineRecord> lines,
  List<double> expectedSubtotals,
) {
  if (lines.length != expectedSubtotals.length) return false;
  for (var index = 0; index < expectedSubtotals.length; index += 1) {
    if (!_nearMoney(lines[index].subtotal, expectedSubtotals[index])) {
      return false;
    }
  }
  return true;
}

bool _lineFamiliesMatch(
  List<ExpenseReceiptLineRecord> lines,
  List<String> expectedFamilies,
) {
  if (lines.length != expectedFamilies.length) return false;
  for (var index = 0; index < expectedFamilies.length; index += 1) {
    final actual = (lines[index].parserExpenseFamily ?? '').toLowerCase();
    final expected = expectedFamilies[index].toLowerCase();
    if (actual != expected) return false;
  }
  return true;
}

bool _lineCategoriesMatch(
  List<ExpenseReceiptLineRecord> lines,
  List<String> expectedCategories,
) {
  if (lines.length != expectedCategories.length) return false;
  for (var index = 0; index < expectedCategories.length; index += 1) {
    final actual = lines[index].category.toLowerCase();
    final expected = expectedCategories[index].toLowerCase();
    if (actual != expected) return false;
  }
  return true;
}

bool _lineDescriptionNeedlesMatch(
  List<ExpenseReceiptLineRecord> lines,
  List<String> expectedNeedles,
) {
  if (lines.length != expectedNeedles.length) return false;
  for (var index = 0; index < expectedNeedles.length; index += 1) {
    final actual = lines[index].description.toLowerCase();
    final expected = expectedNeedles[index].toLowerCase();
    if (!actual.contains(expected)) return false;
  }
  return true;
}

String _lineDescriptionNeedlesDebugSummary(
  List<ExpenseReceiptLineRecord> lines,
  List<String> expectedNeedles,
) {
  return _expectedActualLineSummary(
    expected: expectedNeedles,
    actual: lines.map((line) => line.description).toList(),
  );
}

String _lineCategoriesDebugSummary(
  List<ExpenseReceiptLineRecord> lines,
  List<String> expectedCategories,
) {
  return _expectedActualLineSummary(
    expected: expectedCategories,
    actual: lines.map((line) => line.category).toList(),
  );
}

String _lineFamiliesDebugSummary(
  List<ExpenseReceiptLineRecord> lines,
  List<String> expectedFamilies,
) {
  return _expectedActualLineSummary(
    expected: expectedFamilies,
    actual: lines.map((line) => line.parserExpenseFamily ?? '').toList(),
  );
}

bool _lineUsesMatch(
  List<ExpenseReceiptLineRecord> lines,
  List<String> expectedUses,
) {
  if (lines.length != expectedUses.length) return false;
  for (var index = 0; index < expectedUses.length; index += 1) {
    if (lines[index].use.name != expectedUses[index]) return false;
  }
  return true;
}

String _lineUsesDebugSummary(
  List<ExpenseReceiptLineRecord> lines,
  List<String> expectedUses,
) {
  return _expectedActualLineSummary(
    expected: expectedUses,
    actual: lines.map((line) => line.use.name).toList(),
  );
}

String _expectedActualLineSummary({
  required List<String> expected,
  required List<String> actual,
}) {
  return 'expected=[${expected.join('|')}], actual=[${actual.join('|')}]';
}

String? _dateIso(DateTime? date) {
  if (date == null) return null;
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

bool _nearMoney(double? actual, double expected) {
  return actual != null && (actual - expected).abs() <= 0.01;
}
