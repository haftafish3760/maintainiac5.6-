part of 'expense_receipt_parser_fuel_formats_test.dart';

void _registerFuelFormatAlternativeFuelTests() {
  test('parses CNG sold by gasoline gallon equivalent', () {
    final parsed = parseExpenseReceiptText('''
CLEAN ENERGY
06/25/2026
PUMP 02
CNG COMPRESSED NATURAL GAS
GGE 8.420
PRICE/GGE 2.799
FUEL SALE 23.57
TOTAL 23.57
ODOMETER 95420
''');

    expect(parsed.merchantName, 'Clean Energy');
    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'CNG');
    expect(fuel.quantity, 8.42);
    expect(fuel.unit, 'GGE');
    expect(fuel.unitPrice, 2.799);
    expect(fuel.subtotal, 23.57);
    expect(fuel.odometerReading, 95420);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('parses LNG sold by diesel gallon equivalent', () {
    final parsed = parseExpenseReceiptText('''
CLEAN ENERGY
07/01/2026
PUMP 03
LNG LIQUEFIED NATURAL GAS
DGE 14.750
PRICE/DGE 3.129
FUEL SALE 46.15
TOTAL 46.15
ODOMETER 98120
''');

    expect(parsed.merchantName, 'Clean Energy');
    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'LNG');
    expect(fuel.quantity, 14.75);
    expect(fuel.unit, 'DGE');
    expect(fuel.unitPrice, 3.129);
    expect(fuel.subtotal, 46.15);
    expect(fuel.odometerReading, 98120);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);

    final inferred = parseExpenseReceiptText('''
TRILLIUM CNG
07/01/2026
LNG FUEL
RATE 3.200/DGE
FUEL SALE 40.00
TOTAL 40.00
ODOMETER 98420
''');

    expect(inferred.lines, hasLength(1));
    final inferredFuel = inferred.lines.single;
    expect(inferredFuel.category, 'Fuel');
    expect(inferredFuel.fuelType, 'LNG');
    expect(inferredFuel.quantity, closeTo(12.5, .001));
    expect(inferredFuel.unit, 'DGE');
    expect(inferredFuel.unitPrice, 3.2);
    expect(inferredFuel.subtotal, 40);
    expect(inferredFuel.odometerReading, 98420);
    expect(inferred.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('parses propane autogas sold by the gallon', () {
    final parsed = parseExpenseReceiptText('''
SUBURBAN PROPANE
06/25/2026
PUMP 01
LPG AUTOGAS
GALLONS 11.200
PRICE/GAL 2.649
FUEL SALE 29.67
TOTAL 29.67
ODOMETER 95840
''');

    expect(parsed.merchantName, 'Suburban Propane');
    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'Propane');
    expect(fuel.quantity, 11.2);
    expect(fuel.unit, 'gallon');
    expect(fuel.unitPrice, 2.649);
    expect(fuel.subtotal, 29.67);
    expect(fuel.odometerReading, 95840);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('parses hydrogen fuel sold by kilogram', () {
    final parsed = parseExpenseReceiptText('''
TRUE ZERO
06/25/2026
PUMP 04
H2 HYDROGEN FUEL
KG 4.120
PRICE/KG 15.999
FUEL SALE 65.92
TOTAL 65.92
ODOMETER 96240
''');

    expect(parsed.merchantName, 'True Zero');
    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'Hydrogen');
    expect(fuel.quantity, 4.12);
    expect(fuel.unit, 'kg');
    expect(fuel.unitPrice, 15.999);
    expect(fuel.subtotal, 65.92);
    expect(fuel.odometerReading, 96240);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('parses unknown split-row fuel receipts without a merchant profile', () {
    final parsed = parseExpenseReceiptText('''
RIVER ROAD MART 418
06/23/2026 05:42 AM
PUMP 12
PRODUCT DIESEL
GALLONS 18.425
PRICE/GAL 3.699
FUEL SALE 68.15
TOTAL 68.15
FLEET CARD 68.15
AUTH 442193
''');

    expect(parsed.merchantName, 'River Road Mart 418');
    expect(parsed.lines, hasLength(1));
    expect(parsed.lines.single.category, 'Fuel');
    expect(parsed.lines.single.quantity, 18.425);
    expect(parsed.lines.single.unit, 'gallon');
    expect(parsed.lines.single.unitPrice, 3.699);
    expect(parsed.lines.single.fuelType, 'Diesel');
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
    expect(parsed.diagnostics.parserTaskCount('generic_fuel_receipt_ready'), 1);
    expect(parsed.diagnostics.hasParserGenericFuelReceiptReady, isTrue);
    expect(
      parsed.diagnostics.downstreamReadinessSummaryLabel,
      'Fuel receipt review ready',
    );
    expect(parsed.diagnostics.reconciled, isTrue);
  });

  test('parses faded gasoline receipts with separate GALS and PPG rows', () {
    final parsed = parseExpenseReceiptText('''
SHELL OIL
O6/23/2O26 O7:O5 AM
PUMP O3
REG UNL
GALS 12.347
PPG 3.459
FUEL SALE 42.71
TOTAL 42.71
FLEET CARD 42.71
DRIVER ID 1042
''');

    expect(parsed.merchantName, 'Shell');
    expect(parsed.receiptDate, DateTime(2026, 6, 23));
    expect(parsed.receiptTimeMinutes, (7 * 60) + 5);
    expect(parsed.lines.single.category, 'Fuel');
    expect(parsed.lines.single.quantity, 12.347);
    expect(parsed.lines.single.unitPrice, 3.459);
    expect(parsed.lines.single.fuelType, 'Gasoline');
    expect(parsed.diagnostics.reconciled, isTrue);
  });

  test('parses EV charging and DEF as fuel subtypes', () {
    final ev = parseExpenseReceiptText('''
ChargePoint
06/12/2026
Energy 34.75 kWh 16.33
Total 16.33
''');

    expect(ev.merchantName, 'ChargePoint');
    expect(ev.lines.single.category, 'Fuel');
    expect(ev.lines.single.quantity, 34.75);
    expect(ev.lines.single.unit, 'kWh');
    expect(ev.lines.single.fuelType, 'Electric');

    final def = parseExpenseReceiptText('''
LOVE'S TRAVEL STOP
06/12/2026
DEF Fluid 2.500 GAL 10.00
Total 10.00
''');

    expect(def.merchantName, "Love's");
    expect(def.lines.single.category, 'Fuel');
    expect(def.lines.single.quantity, 2.5);
    expect(def.lines.single.fuelType, 'DEF');
  });

  test('keeps EV charging fees separate from kWh fuel energy', () {
    final parsed = parseExpenseReceiptText('''
EVgo Charging
06/12/2026
Charging Session 28.40 kWh @ 0.440 12.50
Session fee 1.00
Idle fee 2.50
Total 16.00
Odometer 44520
''');

    expect(parsed.lines, hasLength(3));
    final fuel = parsed.lines.singleWhere((line) => line.category == 'Fuel');
    expect(fuel.fuelType, 'Electric');
    expect(fuel.unit, 'kWh');
    expect(fuel.quantity, 28.40);
    expect(fuel.unitPrice, .440);
    expect(fuel.subtotal, 12.50);
    expect(fuel.odometerReading, 44520);
    final fees = parsed.lines.where((line) => line.category == 'Charging Fees');
    expect(fees.map((line) => line.subtotal), containsAll([1.00, 2.50]));
    expect(parsed.enteredTotal, 16.00);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('infers EV kWh when charging energy row is missing quantity', () {
    final parsed = parseExpenseReceiptText('''
EVGO
06/22/2026
EV CHARGING
Rate 0.440
Energy Sale 12.54
Total 12.54
Odometer 60220
''');

    expect(parsed.merchantName, 'EVgo');
    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'Electric');
    expect(fuel.quantity, closeTo(28.5, .01));
    expect(fuel.unit, 'kWh');
    expect(fuel.unitPrice, .44);
    expect(fuel.subtotal, 12.54);
    expect(fuel.odometerReading, 60220);
    expect(parsed.diagnostics.parserTaskCount('fuel_quantity_needs_review'), 0);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('keeps EV parking and tax separate from charging energy and fees', () {
    final parsed = parseExpenseReceiptText('''
Electrify America
06/12/2026
Charging Session 42.80 kWh @ 0.470 20.12
Session fee 1.00
Idle fee 3.50
Parking fee 4.00
Sales Tax 1.86
Total 30.48
Odometer 45840
''');

    expect(parsed.lines, hasLength(4));
    final fuel = parsed.lines.singleWhere((line) => line.category == 'Fuel');
    expect(fuel.fuelType, 'Electric');
    expect(fuel.unit, 'kWh');
    expect(fuel.quantity, 42.80);
    expect(fuel.unitPrice, .470);
    expect(fuel.subtotal, 20.12);
    expect(fuel.odometerReading, 45840);
    final fees = parsed.lines.where((line) => line.category == 'Charging Fees');
    expect(fees.map((line) => line.subtotal), containsAll([1.00, 3.50]));
    final parking = parsed.lines.singleWhere(
      (line) => line.category == 'Parking',
    );
    expect(parking.subtotal, 4.00);
    expect(parsed.enteredTax, 1.86);
    expect(parsed.enteredTotal, 30.48);
    expect(parsed.enteredSubtotal, 28.62);
    expect(parsed.lineSubtotal, closeTo(28.62, .001));
    expect(parsed.lineSubtotal + parsed.enteredTax!, closeTo(30.48, .001));
    expect(parsed.diagnostics.reconciled, isTrue);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('parses Spanish EV charging energy and fees', () {
    final parsed = parseExpenseReceiptText('''
Estacion de Carga EVgo
06/14/2026
Carga eléctrica
Energía 31.20 kWh 13.10
Tarifa/kWh 0.420
Cuota de sesión 1.25
Tarifa por inactividad 2.00
Total 16.35
Odometro 45210
''');

    expect(parsed.lines, hasLength(3));
    final fuel = parsed.lines.singleWhere((line) => line.category == 'Fuel');
    expect(fuel.fuelType, 'Electric');
    expect(fuel.unit, 'kWh');
    expect(fuel.quantity, 31.20);
    expect(fuel.unitPrice, .420);
    expect(fuel.subtotal, 13.10);
    expect(fuel.odometerReading, 45210);
    final fees = parsed.lines.where((line) => line.category == 'Charging Fees');
    expect(fees.map((line) => line.subtotal), containsAll([1.25, 2.00]));
    expect(parsed.enteredTotal, 16.35);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('parses Spanish EV session rows with kWh before the rate', () {
    final parsed = parseExpenseReceiptText('''
CHARGEPOINT
06/03/2026
Sesión de carga 21.00 kWh @ 0.549 11.53
Cuota de sesión 0.75
Estacionamiento 2.75
Impuesto 1.09
Tarjeta 16.12
Autorización 7788
Odometro 59940
''');

    final fuelLines = parsed.lines.where((line) => line.category == 'Fuel');
    expect(
      fuelLines,
      hasLength(1),
      reason: parsed.lines
          .map(
            (line) =>
                '${line.category}:${line.description}:${line.quantity}:${line.unit}:${line.subtotal}',
          )
          .join(' | '),
    );
    final fuel = fuelLines.single;
    expect(fuel.fuelType, 'Electric');
    expect(fuel.quantity, 21);
    expect(fuel.unit, 'kWh');
    expect(fuel.unitPrice, .549);
    expect(fuel.subtotal, 11.53);
    expect(fuel.odometerReading, 59940);
    expect(parsed.enteredTax, 1.09);
    expect(parsed.enteredTotal, 16.12);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('parses Spanish fuel and EV receipts with comma decimals', () {
    final liquid = parseExpenseReceiptText('''
Gasolinera Del Norte
06/15/2026
Bomba 7
Gasolina Regular
Galones 8,250
Precio/Galón 3,299
Venta Combustible 27,22
Total 27,22
Odometro 81240
''');

    expect(liquid.lines.single.category, 'Fuel');
    expect(liquid.lines.single.quantity, 8.25);
    expect(liquid.lines.single.unitPrice, 3.299);
    expect(liquid.lines.single.subtotal, 27.22);
    expect(liquid.lines.single.fuelType, 'Gasoline');

    final ev = parseExpenseReceiptText('''
Estacion de Carga
06/15/2026
Carga eléctrica
Energía 31,20 kWh 13,10
Tarifa/kWh 0,420
Cuota de sesión 1,25
Total 14,35
Odometro 45340
''');

    final fuel = ev.lines.singleWhere((line) => line.category == 'Fuel');
    expect(fuel.fuelType, 'Electric');
    expect(fuel.quantity, 31.20);
    expect(fuel.unitPrice, .420);
    expect(fuel.subtotal, 13.10);
    final fees = ev.lines.where((line) => line.category == 'Charging Fees');
    expect(fees.map((line) => line.subtotal), contains(1.25));
    expect(ev.enteredTotal, 14.35);
  });

  test('parses diesel specialty fuels and kerosene as fuel subtypes', () {
    final b20 = parseExpenseReceiptText('''
TA TRAVEL CENTER
06/13/2026
PUMP 15
B20 DIESEL 24.250 @ 3.799 92.13
TOTAL 92.13
ODOMETER 223410
''');

    expect(b20.lines.single.category, 'Fuel');
    expect(b20.lines.single.quantity, 24.25);
    expect(b20.lines.single.unitPrice, 3.799);
    expect(b20.lines.single.fuelType, 'Diesel');
    expect(b20.lines.single.odometerReading, 223410);

    final reefer = parseExpenseReceiptText('''
LOVES TRAVEL STOP
06/13/2026
REEFER FUEL
GALLONS 8.750
PRICE/GAL 3.699
FUEL SALE 32.37
TOTAL 32.37
''');

    expect(reefer.lines.single.category, 'Fuel');
    expect(reefer.lines.single.quantity, 8.75);
    expect(reefer.lines.single.unitPrice, 3.699);
    expect(reefer.lines.single.fuelType, 'Diesel');

    final kerosene = parseExpenseReceiptText('''
RURAL FUEL MART
06/13/2026
PUMP 2
KEROSENE
GALLONS 3.500
PRICE/GAL 4.899
FUEL SALE 17.15
TOTAL 17.15
''');

    expect(kerosene.lines.single.category, 'Fuel');
    expect(kerosene.lines.single.quantity, 3.5);
    expect(kerosene.lines.single.unitPrice, 4.899);
    expect(kerosene.lines.single.fuelType, 'Kerosene');
  });

  test('parses DC fast charging aliases and separates session fees', () {
    final parsed = parseExpenseReceiptText('''
PUBLIC EVSE NETWORK
06/30/2026
DCFC SESSION
ENERGY 42.500 kWh @ 0.420 17.85
SESSION FEE 1.50
TOTAL 19.35
''');

    expect(parsed.lines, hasLength(2));
    final energy = parsed.lines.firstWhere((line) => line.unit == 'kWh');
    final fee = parsed.lines.firstWhere(
      (line) => line.category == 'Charging Fees',
    );
    expect(energy.fuelType, 'Electric');
    expect(energy.quantity, 42.5);
    expect(energy.unitPrice, .42);
    expect(energy.subtotal, 17.85);
    expect(fee.subtotal, 1.5);
  });
}
