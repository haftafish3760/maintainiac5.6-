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

  test('infers dirty M100 methanol gallons when the volume row is missing', () {
    final parsed = parseExpenseReceiptText('''
SHELL
07/01/2026
PUMP 18
PRODUCT M100 METHAN0L
PR1CE/GAL 2.529
FUE1 SALE 20.86
TOTAL 20.86
ODO 51863
''');

    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'Methanol');
    expect(fuel.unit, 'gallon');
    expect(fuel.quantity, closeTo(8.25, .01));
    expect(fuel.unitPrice, 2.529);
    expect(fuel.subtotal, 20.86);
    expect(fuel.odometerReading, 51863);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('does not treat M100 as gallons before a printed volume row', () {
    final parsed = parseExpenseReceiptText('''
ALTERNATIVE FUEL STATION
07/02/2026
PRODUCT METANOL M100
GAL0NES 5.750
PR1CE/GAL 2.628
FUE1 SALE 15.11
TOTAL 15.11
''');

    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'Methanol');
    expect(fuel.unit, 'gallon');
    expect(fuel.quantity, 5.75);
    expect(fuel.unitPrice, 2.628);
    expect(fuel.subtotal, 15.11);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });
}
