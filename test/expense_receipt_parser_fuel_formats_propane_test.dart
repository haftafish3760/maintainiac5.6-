part of 'expense_receipt_parser_fuel_formats_test.dart';

void _registerFuelFormatPropaneTests() {
  test('parses HD-5 propane grade without a propane word', () {
    final parsed = parseExpenseReceiptText('''
ALTERNATIVE FUEL STATION
06/30/2026
HD-5 11.500 GAL @ 2.799 32.19
TOTAL 32.19
''');

    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'Propane');
    expect(fuel.unit, 'gallon');
    expect(fuel.quantity, 11.5);
    expect(fuel.unitPrice, 2.799);
    expect(fuel.subtotal, 32.19);
  });
}
