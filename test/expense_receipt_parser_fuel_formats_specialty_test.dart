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

  test(
    'keeps an avgas grade with an at-sign price as a measured fuel line',
    () {
      final parsed = parseExpenseReceiptText('''
AIRFIELD
AVGAS 100LL 23.000 L @ 1.728 39.75
CARD SALE 39.75
''');

      final fuel = parsed.lines.single;
      expect(fuel.fuelType, 'Aviation Gasoline');
      expect(fuel.quantity, 23);
      expect(fuel.unit, 'liter');
      expect(fuel.unitPrice, 1.728);
      expect(fuel.subtotal, 39.75);
    },
  );

  test('parses dirty Spanish racing fuel labels as one fuel line', () {
    final parsed = parseExpenseReceiptText('''
RACEWAY
Producto C0mbustible de Carrera 110
Gal0nes 5,750
Prec1o/Galón 12,598
Venta C0mbustible 72,44
Total 72,44
''');

    final fuel = parsed.lines.single;
    expect(fuel.fuelType, 'Racing Fuel');
    expect(fuel.quantity, 5.75);
    expect(fuel.unitPrice, 12.598);
    expect(fuel.subtotal, 72.44);
  });

  test('recognizes the AdBlue DEF product alias', () {
    final parsed = parseExpenseReceiptText('''
TRUCK STOP
AdBlue
2.500 GAL @ 7.996
FUEL SALE 19.99
TOTAL 19.99
''');

    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'DEF');
    expect(fuel.quantity, 2.5);
    expect(fuel.unitPrice, 7.996);
    expect(fuel.subtotal, 19.99);
  });

  test('recognizes BlueDEF and punctuated DEF product aliases', () {
    for (final product in ['BlueDEF', 'D.E.F.']) {
      final parsed = parseExpenseReceiptText('''
TRUCK STOP
$product 2.500 GAL @ 7.996 19.99
TOTAL 19.99
''');

      final fuel = parsed.lines.single;
      expect(fuel.fuelType, 'DEF', reason: product);
      expect(fuel.quantity, 2.5, reason: product);
      expect(fuel.subtotal, 19.99, reason: product);
    }
  });
}
