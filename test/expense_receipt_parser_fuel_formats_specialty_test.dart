part of 'expense_receipt_parser_fuel_formats_test.dart';

void _registerFuelFormatSpecialtyTests() {
  test('parses specialty liquid fuel labels without a gasoline fallback', () {
    final cases = [
      ('AVGAS 100LL 20.000 GAL @ 6.499 129.98', 'Aviation Gasoline'),
      ('JET A-1 30.000 GAL @ 5.999 179.97', 'Jet Fuel'),
      ('RACE FUEL 110 5.000 GAL @ 12.499 62.50', 'Racing Fuel'),
      ('NITROMETHANE 2.500 GAL @ 38.000 95.00', 'Nitromethane'),
      ('E100 ETHANOL 8.000 GAL @ 3.250 26.00', 'E100'),
    ];

    for (final entry in cases) {
      final parsed = parseExpenseReceiptText('''
SPECIALTY FUEL DEPOT
PUMP 4
${entry.$1}
FUEL SALE ${entry.$1.split(' ').last}
TOTAL ${entry.$1.split(' ').last}
ODOMETER 44120
''');

      expect(parsed.lines, hasLength(1), reason: entry.$1);
      final fuel = parsed.lines.single;
      expect(fuel.category, 'Fuel');
      expect(fuel.fuelType, entry.$2);
      expect(fuel.odometerReading, 44120);
    }
  });
}
