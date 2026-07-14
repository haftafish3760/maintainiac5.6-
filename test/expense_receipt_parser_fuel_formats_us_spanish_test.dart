part of 'expense_receipt_parser_fuel_formats_test.dart';

void _registerFuelFormatUsSpanishTests() {
  test('parses Mexican Spanish Magna fuel pricing', () {
    final parsed = parseExpenseReceiptText('''
ESTACION DE SERVICIO
PRODUCTO MAGNA
LITROS 25.500
PRECIO POR LITRO 1.150
VENTA COMBUSTIBLE 29.33
TOTAL 29.33
''');

    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'Gasoline');
    expect(fuel.quantity, 25.5);
    expect(fuel.unit, 'liter');
    expect(fuel.unitPrice, 1.15);
    expect(fuel.subtotal, 29.33);
  });

  test('parses Cuban Spanish gasoil as diesel', () {
    final parsed = parseExpenseReceiptText('''
SERVICENTRO
GASOIL
20.000 LITROS @ 1.050
VENTA COMBUSTIBLE 21.00
TOTAL 21.00
''');

    final fuel = parsed.lines.single;
    expect(fuel.fuelType, 'Diesel');
    expect(fuel.quantity, 20);
    expect(fuel.unit, 'liter');
    expect(fuel.unitPrice, 1.05);
    expect(fuel.subtotal, 21);
  });

  test('parses accented Spanish gas licuado de petróleo as propane', () {
    final parsed = parseExpenseReceiptText('''
SERVICENTRO
GAS LICUADO DE PETRÓLEO
10.000 LITROS @ 0.900
VENTA COMBUSTIBLE 9.00
TOTAL 9.00
''');

    final fuel = parsed.lines.single;
    expect(fuel.fuelType, 'Propane');
    expect(fuel.quantity, 10);
    expect(fuel.unit, 'liter');
    expect(fuel.unitPrice, .9);
    expect(fuel.subtotal, 9);
  });

  test('parses GNV and GLP alternative-fuel abbreviations', () {
    final cases = [
      ('GNV 12.000 GGE @ 2.500 30.00', 'CNG', 'GGE'),
      ('GLP 8.000 GAL @ 3.000 24.00', 'Propane', 'gallon'),
    ];

    for (final entry in cases) {
      final parsed = parseExpenseReceiptText('''
ESTACION DE SERVICIO
${entry.$1}
VENTA COMBUSTIBLE ${entry.$1.split(' ').last}
TOTAL ${entry.$1.split(' ').last}
''');

      final fuel = parsed.lines.single;
      expect(fuel.fuelType, entry.$2, reason: entry.$1);
      expect(fuel.unit, entry.$3, reason: entry.$1);
    }
  });

  test('parses Spanish EV precio por kWh rates', () {
    final parsed = parseExpenseReceiptText('''
ESTACION DE CARGA
CARGA ELECTRICA
20.000 KWH
PRECIO POR KWH 0.420
VENTA COMBUSTIBLE 8.40
TOTAL 8.40
''');

    final fuel = parsed.lines.single;
    expect(fuel.fuelType, 'Electric');
    expect(fuel.quantity, 20);
    expect(fuel.unit, 'kWh');
    expect(fuel.unitPrice, .42);
    expect(fuel.subtotal, 8.4);
  });
}
