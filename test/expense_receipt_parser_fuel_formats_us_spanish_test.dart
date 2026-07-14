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
