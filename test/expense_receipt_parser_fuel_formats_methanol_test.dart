part of 'expense_receipt_parser_fuel_formats_test.dart';

void _registerFuelFormatMethanolTests() {
  test('parses M85 methanol fuel without a gasoline fallback', () {
    final parsed = parseExpenseReceiptText('''
ALTERNATIVE FUEL STATION
06/30/2026
M85 9.750 GAL @ 2.499 24.37
TOTAL 24.37
''');

    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'Methanol');
    expect(fuel.unit, 'gallon');
    expect(fuel.quantity, 9.75);
    expect(fuel.unitPrice, 2.499);
    expect(fuel.subtotal, 24.37);
  });
}
