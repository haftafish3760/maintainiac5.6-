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
    expect(rowFuel.description.toLowerCase(), contains('off road'));
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
    expect(splitFuel.description.toLowerCase(), contains('red dyed diesel'));
    expect(splitFuel.quantity, 22.4);
    expect(splitFuel.unitPrice, 3.199);
    expect(splitFuel.subtotal, 71.66);
    expect(splitFuel.odometerReading, 77840);
    expect(splitStyle.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('parses red diesel shorthand as off-road diesel', () {
    final parsed = parseExpenseReceiptText('''
EQUIPMENT FUEL DEPOT
06/30/2026
RED DIESEL 12.500 @ 3.799 47.49
TOTAL 47.49
''');

    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'Diesel');
    expect(fuel.quantity, 12.5);
    expect(fuel.unitPrice, 3.799);
    expect(fuel.subtotal, 47.49);
  });

  test('keeps on-road and off-road diesel labels separate on one receipt', () {
    final parsed = parseExpenseReceiptText('''
COMMERCIAL FUEL DEPOT
07/02/2026
OFF-ROAD DIESEL 5.000 @ 3.199 16.00
ON-ROAD CLEAR DIESEL 10.000 @ 3.899 38.99
TOTAL 54.99
ODOMETER 238420
''');

    final dieselLines = parsed.lines
        .where((line) => line.fuelType == 'Diesel')
        .toList();
    expect(dieselLines, hasLength(2));
    final offRoad = dieselLines.singleWhere(
      (line) => line.description.toLowerCase().contains('off-road'),
    );
    expect(offRoad.quantity, 5);
    expect(offRoad.unitPrice, 3.199);
    expect(offRoad.subtotal, 16);
    expect(offRoad.odometerReading, 238420);

    final onRoad = dieselLines.singleWhere(
      (line) => line.description.toLowerCase().contains('on-road'),
    );
    expect(onRoad.quantity, 10);
    expect(onRoad.unitPrice, 3.899);
    expect(onRoad.subtotal, 38.99);
    expect(onRoad.odometerReading, 238420);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 2);
  });

  test('preserves Spanish on-road and off-road diesel labels', () {
    final onRoad = parseExpenseReceiptText('''
Estacion Comercial
07/02/2026
Diésel de carretera
Diésel ultra bajo azufre 14,250 @ 3,799 54,14
Total 54,14
Odometro 239180
''');

    expect(onRoad.lines, hasLength(1));
    final onRoadFuel = onRoad.lines.single;
    expect(onRoadFuel.fuelType, 'Diesel');
    expect(
      onRoadFuel.description.toLowerCase(),
      contains('diésel de carretera'),
    );
    expect(onRoadFuel.quantity, 14.25);
    expect(onRoadFuel.unitPrice, 3.799);
    expect(onRoadFuel.subtotal, 54.14);
    expect(onRoadFuel.odometerReading, 239180);

    final offRoad = parseExpenseReceiptText('''
Cooperativa Rural
07/02/2026
Diésel rojo
Diésel 7,500 @ 3,299 24,74
Total 24,74
Odometro 239260
''');

    expect(offRoad.lines, hasLength(1));
    final offRoadFuel = offRoad.lines.single;
    expect(offRoadFuel.fuelType, 'Diesel');
    expect(offRoadFuel.description.toLowerCase(), contains('diésel rojo'));
    expect(offRoadFuel.quantity, 7.5);
    expect(offRoadFuel.unitPrice, 3.299);
    expect(offRoadFuel.subtotal, 24.74);
    expect(offRoadFuel.odometerReading, 239260);
  });

  test('parses intermediate biodiesel blends such as B2 ULSD', () {
    final parsed = parseExpenseReceiptText('''
FLEET FUEL DEPOT
06/30/2026
B2 ULSD 15.250 @ 3.899 59.46
TOTAL 59.46
''');

    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'Diesel');
    expect(fuel.quantity, 15.25);
    expect(fuel.unitPrice, 3.899);
    expect(fuel.subtotal, 59.46);
  });

  test('parses B100 biodiesel without a diesel fallback label', () {
    final parsed = parseExpenseReceiptText('''
AG ENERGY CO-OP
07/01/2026
PUMP 05
B100 BIODIESEL 11.750 @ 4.129 48.52
TOTAL 48.52
ODOMETER 102640
''');

    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'Diesel');
    expect(fuel.quantity, 11.75);
    expect(fuel.unitPrice, 4.129);
    expect(fuel.subtotal, 48.52);
    expect(fuel.odometerReading, 102640);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
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
}
