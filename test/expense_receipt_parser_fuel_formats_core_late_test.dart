part of 'expense_receipt_parser_fuel_formats_test.dart';

void _registerFuelFormatCoreLateTests() {
  test(
    'selects the paid price when cash and credit fuel prices are printed',
    () {
      final parsed = parseExpenseReceiptText('''
SUNOCO
06/20/2026
PUMP 03
REGULAR 87
GALLONS 11.000
CASH PRICE/GAL 3.299
CREDIT PRICE/GAL 3.399
FUEL SALE 37.39
VISA CREDIT 37.39
TOTAL 37.39
ODOMETER 94120
''');

      expect(parsed.merchantName, 'Sunoco');
      expect(parsed.lines, hasLength(1));
      final fuel = parsed.lines.single;
      expect(fuel.category, 'Fuel');
      expect(fuel.quantity, 11);
      expect(fuel.unitPrice, closeTo(3.399, .001));
      expect(fuel.subtotal, 37.39);
      expect(fuel.odometerReading, 94120);
      expect(parsed.diagnostics.reconciled, isTrue);
      expect(
        parsed.diagnostics.parserTaskCount('fuel_amount_math_needs_review'),
        0,
      );
      expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
    },
  );

  test('infers gallons when fuel volume row is missing', () {
    final parsed = parseExpenseReceiptText('''
MARATHON
06/20/2026
PUMP 05
PRODUCT REGULAR UNLEADED
PRICE/GAL 3.499
FUEL SALE 34.99
TOTAL 34.99
ODOMETER 94550
''');

    expect(parsed.merchantName, 'Marathon');
    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.quantity, closeTo(10.0, .01));
    expect(fuel.unit, 'gallon');
    expect(fuel.unitPrice, 3.499);
    expect(fuel.subtotal, 34.99);
    expect(fuel.odometerReading, 94550);
    expect(parsed.diagnostics.reconciled, isTrue);
    expect(parsed.diagnostics.parserTaskCount('fuel_quantity_needs_review'), 0);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('parses non-ethanol recreational and marine gas as gasoline', () {
    final parsed = parseExpenseReceiptText('''
WAWA
06/25/2026
PUMP 03
REC FUEL 90
NO ETHANOL MARINE GAS
GALLONS 6.250
PRICE/GAL 4.299
FUEL SALE 26.87
TOTAL 26.87
ODOMETER 94820
''');

    expect(parsed.merchantName, 'Wawa');
    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'Gasoline');
    expect(fuel.description, contains('90'));
    expect(fuel.quantity, 6.25);
    expect(fuel.unit, 'gallon');
    expect(fuel.unitPrice, 4.299);
    expect(fuel.subtotal, 26.87);
    expect(fuel.odometerReading, 94820);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);

    final spanish = parseExpenseReceiptText('''
Gasolinera Del Norte
06/25/2026
Bomba 1
Producto Gasolina Sin Etanol 90
Galones 5.125
Precio/Galón 3.199
Venta Combustible 16.39
Total 16.39
Odometro 95110
''');

    expect(spanish.lines, hasLength(1));
    final spanishFuel = spanish.lines.single;
    expect(spanishFuel.category, 'Fuel');
    expect(spanishFuel.fuelType, 'Gasoline');
    expect(spanishFuel.description, contains('90'));
    expect(spanishFuel.quantity, 5.125);
    expect(spanishFuel.unitPrice, 3.199);
    expect(spanishFuel.subtotal, 16.39);
    expect(spanishFuel.odometerReading, 95110);
    expect(spanish.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('parses regional ethanol blend labels as specific flex fuels', () {
    final e30 = parseExpenseReceiptText('''
MIDWEST FLEX FUEL
06/28/2026
PUMP 04
E30 FLEX FUEL 12.500 @ 2.899 36.24
TOTAL 36.24
ODOMETER 99240
''');

    expect(e30.lines, hasLength(1));
    final e30Fuel = e30.lines.single;
    expect(e30Fuel.category, 'Fuel');
    expect(e30Fuel.fuelType, 'E30');
    expect(e30Fuel.quantity, 12.5);
    expect(e30Fuel.unitPrice, 2.899);
    expect(e30Fuel.subtotal, 36.24);
    expect(e30Fuel.odometerReading, 99240);
    expect(e30.diagnostics.parserTaskCount('fuel_line_ready'), 1);

    final e50 = parseExpenseReceiptText('''
FLEX STOP
06/28/2026
PUMP 08
ETHANOL 50
GALLONS 9.750
PRICE/GAL 2.699
FUEL SALE 26.32
TOTAL 26.32
ODOMETER 99510
''');

    expect(e50.lines, hasLength(1));
    final e50Fuel = e50.lines.single;
    expect(e50Fuel.category, 'Fuel');
    expect(e50Fuel.fuelType, 'E50');
    expect(e50Fuel.quantity, 9.75);
    expect(e50Fuel.unitPrice, 2.699);
    expect(e50Fuel.subtotal, 26.32);
    expect(e50Fuel.odometerReading, 99510);
    expect(e50.diagnostics.parserTaskCount('fuel_line_ready'), 1);

    final spanish = parseExpenseReceiptText('''
Gasolinera Flex
06/28/2026
Bomba 2
Etanol 20
Galones 8,250
Precio/Galón 2,799
Venta Combustible 23,09
Total 23,09
Odometro 99720
''');

    expect(spanish.lines, hasLength(1));
    final spanishFuel = spanish.lines.single;
    expect(spanishFuel.category, 'Fuel');
    expect(spanishFuel.fuelType, 'E20');
    expect(spanishFuel.quantity, 8.25);
    expect(spanishFuel.unitPrice, 2.799);
    expect(spanishFuel.subtotal, 23.09);
    expect(spanishFuel.odometerReading, 99720);
    expect(spanish.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('parses plus mid-grade gasoline without treating octane as volume', () {
    final parsed = parseExpenseReceiptText('''
SHELL
06/30/2026
PUMP 07
PLUS 89
GALLONS 8.500
PRICE/GAL 3.659
FUEL SALE 31.10
TOTAL 31.10
ODOMETER 100120
''');

    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'Gasoline');
    expect(fuel.description, contains('89'));
    expect(fuel.quantity, 8.5);
    expect(fuel.unitPrice, 3.659);
    expect(fuel.subtotal, 31.10);
    expect(fuel.odometerReading, 100120);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test(
    'parses spaced mid grade gasoline without treating octane as volume',
    () {
      final parsed = parseExpenseReceiptText('''
EXXON
06/30/2026
PUMP 12
MID GRADE 89
GALLONS 9.250
PRICE/GAL 3.719
FUEL SALE 34.40
TOTAL 34.40
ODOMETER 100480
''');

      expect(parsed.lines, hasLength(1));
      final fuel = parsed.lines.single;
      expect(fuel.category, 'Fuel');
      expect(fuel.fuelType, 'Gasoline');
      expect(fuel.description, contains('89'));
      expect(fuel.quantity, 9.25);
      expect(fuel.unitPrice, 3.719);
      expect(fuel.subtotal, 34.40);
      expect(fuel.odometerReading, 100480);
      expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
    },
  );

  test('preserves Spanish supreme-grade octane on a gasoline receipt', () {
    final parsed = parseExpenseReceiptText('''
Gasolinera del Sol
07/01/2026
Bomba 04
Gasolina Suprema 91
Galones 7,750
Precio/Galón 3,899
Venta Combustible 30,22
Total 30,22
Odometro 101820
''');

    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'Gasoline');
    expect(fuel.description, contains('91'));
    expect(fuel.quantity, 7.75);
    expect(fuel.unitPrice, 3.899);
    expect(fuel.subtotal, 30.22);
    expect(fuel.odometerReading, 101820);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('preserves compact premium-grade octane on a gasoline receipt', () {
    final parsed = parseExpenseReceiptText('''
CHEVRON
07/01/2026
PUMP 09
PREM 93
GALLONS 10.125
PRICE/GAL 4.099
FUEL SALE 41.50
TOTAL 41.50
ODOMETER 102160
''');

    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'Gasoline');
    expect(fuel.description, contains('93'));
    expect(fuel.quantity, 10.125);
    expect(fuel.unitPrice, 4.099);
    expect(fuel.subtotal, 41.50);
    expect(fuel.odometerReading, 102160);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('preserves Unleaded 88 octane on an E15 receipt', () {
    final parsed = parseExpenseReceiptText('''
CASEY'S
07/01/2026
PUMP 02
UNLEADED 88
GALLONS 9.500
PRICE/GAL 3.099
FUEL SALE 29.44
TOTAL 29.44
ODOMETER 102590
''');

    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'E15');
    expect(fuel.description, contains('88'));
    expect(fuel.quantity, 9.5);
    expect(fuel.unitPrice, 3.099);
    expect(fuel.subtotal, 29.44);
    expect(fuel.odometerReading, 102590);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('preserves E85 octane on a flex-fuel receipt', () {
    final parsed = parseExpenseReceiptText('''
KWIK TRIP
07/02/2026
PUMP 05
E85 105
GALLONS 11.250
PRICE/GAL 2.899
FUEL SALE 32.61
TOTAL 32.61
ODOMETER 103240
''');

    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'E85');
    expect(fuel.description, contains('105'));
    expect(fuel.quantity, 11.25);
    expect(fuel.unitPrice, 2.899);
    expect(fuel.subtotal, 32.61);
    expect(fuel.odometerReading, 103240);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });
}
