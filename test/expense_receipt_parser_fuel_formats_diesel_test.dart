part of 'expense_receipt_parser_fuel_formats_test.dart';

void _registerFuelFormatDieselTests() {
  test('parses dyed off-road diesel for rural and equipment receipts', () {
    final rowStyle = parseExpenseReceiptText('''
RURAL CO-OP FUEL
06/26/2026
PUMP 04
OFF ROAD DIESEL 15.250 @ 3.299 50.31
TOTAL 50.31
ODOMETER 55420
''');

    expect(rowStyle.lines, hasLength(1));
    final rowFuel = rowStyle.lines.single;
    expect(rowFuel.category, 'Fuel');
    expect(rowFuel.fuelType, 'Diesel');
    expect(rowFuel.quantity, 15.25);
    expect(rowFuel.unitPrice, 3.299);
    expect(rowFuel.subtotal, 50.31);
    expect(rowFuel.odometerReading, 55420);
    expect(rowStyle.diagnostics.parserTaskCount('fuel_line_ready'), 1);

    final splitStyle = parseExpenseReceiptText('''
FARM SUPPLY FUEL
06/26/2026
PUMP 2
RED DYED DIESEL
GALLONS 22.400
PRICE/GAL 3.199
FUEL SALE 71.66
TOTAL 71.66
HUBOMETER 77840
''');

    expect(splitStyle.lines, hasLength(1));
    final splitFuel = splitStyle.lines.single;
    expect(splitFuel.category, 'Fuel');
    expect(splitFuel.fuelType, 'Diesel');
    expect(splitFuel.quantity, 22.4);
    expect(splitFuel.unitPrice, 3.199);
    expect(splitFuel.subtotal, 71.66);
    expect(splitFuel.odometerReading, 77840);
    expect(splitStyle.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('parses renewable diesel labels as diesel fuel', () {
    final rd99 = parseExpenseReceiptText('''
WEST COAST FUEL
06/27/2026
PUMP 06
RD99 RENEWABLE DIESEL 18.500 @ 4.199 77.68
TOTAL 77.68
ODOMETER 88240
''');

    expect(rd99.lines, hasLength(1));
    final rowFuel = rd99.lines.single;
    expect(rowFuel.category, 'Fuel');
    expect(rowFuel.fuelType, 'Diesel');
    expect(rowFuel.quantity, 18.5);
    expect(rowFuel.unitPrice, 4.199);
    expect(rowFuel.subtotal, 77.68);
    expect(rowFuel.odometerReading, 88240);
    expect(rd99.diagnostics.parserTaskCount('fuel_line_ready'), 1);

    final hpr = parseExpenseReceiptText('''
PACIFIC TRUCK FUEL
06/27/2026
PUMP 11
HPR DIESEL
GALLONS 31.250
PRICE/GAL 4.099
FUEL SALE 128.09
TOTAL 128.09
HUBOMETER 332840
''');

    expect(hpr.lines, hasLength(1));
    final splitFuel = hpr.lines.single;
    expect(splitFuel.category, 'Fuel');
    expect(splitFuel.fuelType, 'Diesel');
    expect(splitFuel.quantity, 31.25);
    expect(splitFuel.unitPrice, 4.099);
    expect(splitFuel.subtotal, 128.09);
    expect(splitFuel.odometerReading, 332840);
    expect(hpr.diagnostics.parserTaskCount('fuel_line_ready'), 1);

    final spanish = parseExpenseReceiptText('''
ESTACION DE COMBUSTIBLE
06/27/2026
Bomba 8
Producto Diésel Renovable RD99
Galones 13,250
Precio/Galón 4,154
Venta Combustible 55,04
Total 55,04
Odometro 88420
''');

    expect(spanish.lines, hasLength(1));
    final spanishFuel = spanish.lines.single;
    expect(spanishFuel.category, 'Fuel');
    expect(spanishFuel.fuelType, 'Diesel');
    expect(spanishFuel.quantity, 13.25);
    expect(spanishFuel.unitPrice, 4.154);
    expect(spanishFuel.subtotal, 55.04);
    expect(spanishFuel.odometerReading, 88420);
    expect(spanish.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('parses biodiesel blend labels as diesel fuel', () {
    final b99 = parseExpenseReceiptText('''
GREEN FLEET FUEL
06/29/2026
PUMP 07
B99 BIODIESEL 14.250 @ 3.899 55.56
TOTAL 55.56
ODOMETER 120440
''');

    expect(b99.lines, hasLength(1));
    final rowFuel = b99.lines.single;
    expect(rowFuel.category, 'Fuel');
    expect(rowFuel.fuelType, 'Diesel');
    expect(rowFuel.quantity, 14.25);
    expect(rowFuel.unitPrice, 3.899);
    expect(rowFuel.subtotal, 55.56);
    expect(rowFuel.odometerReading, 120440);
    expect(b99.diagnostics.parserTaskCount('fuel_line_ready'), 1);

    final b100 = parseExpenseReceiptText('''
FARM COOP FUEL
06/29/2026
PUMP 03
B100 DIESEL
GALLONS 6.750
PRICE/GAL 4.299
FUEL SALE 29.02
TOTAL 29.02
HUBOMETER 441220
''');

    expect(b100.lines, hasLength(1));
    final splitFuel = b100.lines.single;
    expect(splitFuel.category, 'Fuel');
    expect(splitFuel.fuelType, 'Diesel');
    expect(splitFuel.quantity, 6.75);
    expect(splitFuel.unitPrice, 4.299);
    expect(splitFuel.subtotal, 29.02);
    expect(splitFuel.odometerReading, 441220);
    expect(b100.diagnostics.parserTaskCount('fuel_line_ready'), 1);

    final spanish = parseExpenseReceiptText('''
ESTACION BIODIESEL
06/29/2026
Bomba 4
Biodiesel B5
Galones 8,250
Precio/Galón 3,799
Venta Combustible 31,34
Total 31,34
Odometro 120880
''');

    expect(spanish.lines, hasLength(1));
    final spanishFuel = spanish.lines.single;
    expect(spanishFuel.category, 'Fuel');
    expect(spanishFuel.fuelType, 'Diesel');
    expect(spanishFuel.quantity, 8.25);
    expect(spanishFuel.unitPrice, 3.799);
    expect(spanishFuel.subtotal, 31.34);
    expect(spanishFuel.odometerReading, 120880);
    expect(spanish.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('parses diesel grade shorthand without using grade as gallons', () {
    final ulsd = parseExpenseReceiptText('''
MIDWEST FUEL STOP
06/30/2026
PUMP 12
#2 ULSD 17.500 @ 3.799 66.48
TOTAL 66.48
ODOMETER 132440
''');

    expect(ulsd.lines, hasLength(1));
    final ulsdFuel = ulsd.lines.single;
    expect(ulsdFuel.category, 'Fuel');
    expect(ulsdFuel.fuelType, 'Diesel');
    expect(ulsdFuel.quantity, 17.5);
    expect(ulsdFuel.unitPrice, 3.799);
    expect(ulsdFuel.subtotal, 66.48);
    expect(ulsdFuel.odometerReading, 132440);
    expect(ulsd.diagnostics.parserTaskCount('fuel_line_ready'), 1);

    final winter = parseExpenseReceiptText('''
NORTHERN CO-OP FUEL
06/30/2026
PUMP 05
No. 1 Winter Diesel
GALLONS 9.250
PRICE/GAL 4.199
FUEL SALE 38.84
TOTAL 38.84
HUBOMETER 447220
''');

    expect(winter.lines, hasLength(1));
    final winterFuel = winter.lines.single;
    expect(winterFuel.category, 'Fuel');
    expect(winterFuel.fuelType, 'Diesel');
    expect(winterFuel.quantity, 9.25);
    expect(winterFuel.unitPrice, 4.199);
    expect(winterFuel.subtotal, 38.84);
    expect(winterFuel.odometerReading, 447220);
    expect(winter.diagnostics.parserTaskCount('fuel_line_ready'), 1);

    final d2 = parseExpenseReceiptText('''
COUNTRY PUMP
06/30/2026
PUMP 03
D2 12.250 GAL 45.07
PRICE/GAL 3.679
TOTAL 45.07
ODOMETER 133020
''');

    expect(d2.lines, hasLength(1));
    final d2Fuel = d2.lines.single;
    expect(d2Fuel.category, 'Fuel');
    expect(d2Fuel.fuelType, 'Diesel');
    expect(d2Fuel.quantity, 12.25);
    expect(d2Fuel.unitPrice, 3.679);
    expect(d2Fuel.subtotal, 45.07);
    expect(d2Fuel.odometerReading, 133020);
    expect(d2.diagnostics.parserTaskCount('fuel_line_ready'), 1);

    final spanishNo2 = parseExpenseReceiptText('''
ESTACION DIESEL
06/30/2026
Bomba 4
Producto Diésel No. 2
Galones 8.875
Precio/Galón 3.948
Venta Combustible 35.04
Total 35.04
Odometro 133520
''');

    expect(spanishNo2.lines, hasLength(1));
    final spanishFuel = spanishNo2.lines.single;
    expect(spanishFuel.category, 'Fuel');
    expect(spanishFuel.fuelType, 'Diesel');
    expect(spanishFuel.quantity, 8.875);
    expect(spanishFuel.unitPrice, 3.948);
    expect(spanishFuel.subtotal, 35.04);
    expect(spanishFuel.odometerReading, 133520);
    expect(spanishNo2.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('keeps federal excise tax separate from diesel fuel lines', () {
    final parsed = parseExpenseReceiptText('''
TA TRAVEL CENTER
06/24/2026
PUMP 19
PRODUCT DIESEL
GALLONS 24.000
PRICE/GAL 3.799
FUEL SALE 91.18
Federal Excise Tax 2.40
TOTAL 93.58
ODO 188920
''');

    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'Diesel');
    expect(fuel.quantity, 24);
    expect(fuel.unitPrice, 3.799);
    expect(fuel.subtotal, 91.18);
    expect(fuel.odometerReading, 188920);
    expect(parsed.enteredTax, 2.40);
    expect(parsed.enteredTotal, 93.58);
    expect(parsed.lineSubtotal + parsed.enteredTax!, closeTo(93.58, .001));
    expect(parsed.diagnostics.reconciled, isTrue);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('uses truck hubometer readings as fuel odometer evidence', () {
    final parsed = parseExpenseReceiptText('''
LOVE'S TRAVEL STOP
06/24/2026
PUMP 22
TRACTOR DIESEL
GALLONS 36.500
PRICE/GAL 3.899
FUEL SALE 142.31
HUBOMETER 231445
TOTAL 142.31
WEX FLEET CARD 142.31
''');

    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'Diesel');
    expect(fuel.quantity, 36.5);
    expect(fuel.unitPrice, 3.899);
    expect(fuel.subtotal, 142.31);
    expect(fuel.odometerReading, 231445);
    expect(parsed.enteredTotal, 142.31);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('ignores tender rows so payment lines do not become expenses', () {
    final parsed = parseExpenseReceiptText('''
Advance Auto Parts
06/12/2026
Brake Caliper 154.21
Subtotal 154.21
Tax 10.79
Debit Tender 165.00
Approval 123456
Amount Paid 165.00
''');

    expect(parsed.lines, hasLength(1));
    expect(parsed.lines.single.description, 'Brake Caliper');
    expect(parsed.lines.single.category, 'Vehicle Parts');
    expect(parsed.enteredTotal, 165.00);
    expect(
      parsed.warnings.any((warning) => warning.contains('do not match')),
      isFalse,
    );
  });

  test('ignores truck stop fleet card tender rows on diesel receipts', () {
    final parsed = parseExpenseReceiptText('''
LOVE'S TRAVEL STOP
06/19/2026
PUMP 18
TRACTOR DIESEL
GALLONS 44.250
PRICE/GAL 3.899
FUEL SALE 172.53
WEX FLEET CARD 172.53
EFS DRIVER ID 55421
COMDATA AUTH 771992
VOYAGER TRACE 202618
TOTAL 172.53
ODOMETER 226840
''');

    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'Diesel');
    expect(fuel.quantity, 44.25);
    expect(fuel.unitPrice, 3.899);
    expect(fuel.subtotal, 172.53);
    expect(fuel.odometerReading, 226840);
    expect(parsed.enteredTotal, 172.53);
    expect(parsed.businessTotal, 172.53);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
    expect(
      parsed.diagnostics.parserTaskCount('fleet_tender_line_excluded'),
      greaterThan(0),
    );
    expect(
      parsed.diagnostics.parserTaskCount('transaction_line_excluded'),
      greaterThan(0),
    );
  });

  test('parses diesel and DEF fuel lines on the same truck stop receipt', () {
    final parsed = parseExpenseReceiptText('''
PILOT TRVL CTR
06/20/2026 04:18 AM
PUMP 14
PRODUCT DIESEL
GALLONS 38.500
PRICE/GAL 3.799
FUEL SALE 146.26
DEF FLUID 3.250 GAL 13.97
TOTAL 160.23
WEX FLEET CARD 160.23
AUTH 551902
ODOMETER 229410
''');

    final fuelLines = parsed.lines.where((line) => line.category == 'Fuel');
    expect(fuelLines, hasLength(2));
    final diesel = fuelLines.singleWhere((line) => line.fuelType == 'Diesel');
    expect(diesel.quantity, 38.5);
    expect(diesel.unitPrice, 3.799);
    expect(diesel.subtotal, 146.26);
    expect(diesel.odometerReading, 229410);

    final def = fuelLines.singleWhere((line) => line.fuelType == 'DEF');
    expect(def.quantity, 3.25);
    expect(def.unitPrice, closeTo(4.298, .001));
    expect(def.subtotal, 13.97);
    expect(def.odometerReading, 229410);
    expect(parsed.enteredTotal, 160.23);
    expect(parsed.businessTotal, 160.23);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 2);
  });

  test('keeps personal convenience items separate on mixed fuel receipts', () {
    final parsed = parseExpenseReceiptText('''
SPEEDWAY
06/20/2026
PUMP 09
REG UNL 10.000 @ 3.459 34.59
COFFEE LARGE 2.49
BEER 6PK 11.99
CIGARETTES 8.75
LOTTERY SCRATCHER 5.00
ATM FEE 2.50
TOTAL 65.32
VISA 65.32
ODOMETER 93310
''');

    expect(parsed.lines, hasLength(6));
    final fuel = parsed.lines.singleWhere((line) => line.category == 'Fuel');
    expect(fuel.quantity, 10);
    expect(fuel.fuelType, 'Gasoline');
    expect(fuel.subtotal, 34.59);
    expect(fuel.odometerReading, 93310);

    final meals = parsed.lines.singleWhere((line) => line.category == 'Meals');
    expect(meals.description, contains('Coffee'));
    expect(meals.subtotal, 2.49);

    final personalLines = parsed.lines.where(
      (line) => line.category == 'Personal',
    );
    expect(personalLines, hasLength(4));
    expect(
      personalLines.map((line) => line.description).join(' '),
      contains('Beer'),
    );
    expect(personalLines.every((line) => line.use.name == 'personal'), isTrue);
    expect(parsed.businessTotal, closeTo(37.08, .001));
    expect(parsed.personalTotal, closeTo(28.24, .001));
    expect(
      parsed.diagnostics.parserTaskCount('parser_expense_family_mixed_receipt'),
      greaterThan(0),
    );
  });
}
