part of 'expense_receipt_parser_fuel_formats_test.dart';

void _registerFuelFormatHydrogenTests() {
  test('parses H70 hydrogen dispenser labels without a hydrogen word', () {
    final parsed = parseExpenseReceiptText('''
ALTERNATIVE FUEL STATION
06/30/2026
H70 3.250 KG @ 16.000 52.00
TOTAL 52.00
''');

    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'Hydrogen');
    expect(fuel.unit, 'kg');
    expect(fuel.quantity, 3.25);
    expect(fuel.unitPrice, 16);
    expect(fuel.subtotal, 52);
  });

  test('parses H35 hydrogen dispenser labels without a hydrogen word', () {
    final parsed = parseExpenseReceiptText('''
ALTERNATIVE FUEL STATION
06/30/2026
H35 2.000 KG @ 14.500 29.00
TOTAL 29.00
''');

    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'Hydrogen');
    expect(fuel.unit, 'kg');
    expect(fuel.quantity, 2);
    expect(fuel.unitPrice, 14.5);
    expect(fuel.subtotal, 29);
  });
}
