import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';

void main() {
  test('parses fuel abbreviations, unit price, and odometer hints', () {
    final parsed = parseExpenseReceiptText('''
PILOT TRAVEL CENTER
06/12/2026 06:45 AM
Odometer: 298240
Pump 12
UNL 12.50 @ 3.459 43.24
TOTAL 43.24
''');

    expect(parsed.merchantName, 'Pilot Flying J');
    expect(parsed.lines.single.category, 'Fuel');
    expect(parsed.lines.single.quantity, 12.5);
    expect(parsed.lines.single.unit, 'gallon');
    expect(parsed.lines.single.unitPrice, 3.459);
    expect(parsed.lines.single.odometerReading, 298240);
    expect(parsed.lines.single.fuelType, 'Gasoline');
    expect(parsed.lines.single.fillType, 'Full fill-up');
  });

  test('parses fuel receipts with gallons before the amount', () {
    final parsed = parseExpenseReceiptText('''
EXXON
06/12/2026
Product Regular Unleaded
GAL 10.250 PRICE/GAL 3.399 AMOUNT 34.84
TOTAL 34.84
''');

    expect(parsed.merchantName, 'Exxon');
    expect(parsed.lines.single.category, 'Fuel');
    expect(parsed.lines.single.quantity, 10.25);
    expect(parsed.lines.single.unitPrice, 3.399);
    expect(parsed.lines.single.fuelType, 'Gasoline');
  });

  test('parses dispenser shorthand nozzle hose volume ppu and amount rows', () {
    final parsed = parseExpenseReceiptText('''
INDEPENDENT FUEL
06/22/2026
NOZZLE 02
HOSE 1
FUELING POINT 14
PROD UNL 87
VOL 10.250
PPU 3.459
AMT 35.45
TOTAL 35.45
ODOMETER 100250
''');

    expect(parsed.merchantName, 'Independent Fuel');
    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'Gasoline');
    expect(fuel.quantity, 10.25);
    expect(fuel.unit, 'gallon');
    expect(fuel.unitPrice, 3.459);
    expect(fuel.subtotal, 35.45);
    expect(fuel.odometerReading, 100250);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test(
    'parses liter-based fuel receipts for cross-border and import formats',
    () {
      final parsed = parseExpenseReceiptText('''
BORDER FUEL PLAZA
06/17/2026
PUMP 08
PRODUCT REGULAR UNLEADED
LITERS 42.000
PRICE/LITER 0.899
FUEL SALE 37.76
TOTAL 37.76
ODOMETER 91240
''');

      expect(parsed.merchantName, 'Border Fuel Plaza');
      expect(parsed.lines.single.category, 'Fuel');
      expect(parsed.lines.single.quantity, 42);
      expect(parsed.lines.single.unit, 'liter');
      expect(parsed.lines.single.unitPrice, .899);
      expect(parsed.lines.single.subtotal, 37.76);
      expect(parsed.lines.single.odometerReading, 91240);
      expect(parsed.lines.single.fuelType, 'Gasoline');
      expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
    },
  );

  test('marks English and Spanish partial fill-up fuel receipts', () {
    final english = parseExpenseReceiptText('''
SUNOCO
06/18/2026
PUMP 03
REG UNL
GALLONS 6.500
PRICE/GAL 3.499
FUEL SALE 22.74
TANK NOT FULL
TOTAL 22.74
ODOMETER 91840
''');

    expect(english.lines.single.category, 'Fuel');
    expect(english.lines.single.quantity, 6.5);
    expect(english.lines.single.fillType, 'Partial fill');
    expect(english.lines.single.odometerReading, 91840);

    final spanish = parseExpenseReceiptText('''
Gasolinera Del Sol
06/18/2026
Bomba 5
Gasolina Regular
Galones 7.250
Precio/Galón 3.299
Venta Combustible 23.92
Carga parcial
No lleno
Total 23.92
Odometro 82640
''');

    expect(spanish.lines.single.category, 'Fuel');
    expect(spanish.lines.single.quantity, 7.25);
    expect(spanish.lines.single.fillType, 'Partial fill');
    expect(spanish.lines.single.odometerReading, 82640);
  });

  test('parses split-row truck stop fuel receipts with rewards discounts', () {
    final parsed = parseExpenseReceiptText('''
PILOT TRVL CTR
06/23/2026 05:42 AM
PUMP 12
PRODUCT DIESEL
GALLONS 18.425
PRICE/GAL 3.699
FUEL SALE 68.15
REWARDS DISC -1.20
TOTAL 66.95
VISA FLEET CARD 66.95
AUTH 442193
TRACE 77801
ODOMETER 184220
''');

    expect(parsed.merchantName, 'Pilot Flying J');
    expect(parsed.receiptDate, DateTime(2026, 6, 23));
    expect(parsed.receiptTimeMinutes, (5 * 60) + 42);
    expect(parsed.enteredTotal, 66.95);
    expect(parsed.lines, hasLength(2));
    expect(parsed.lines.first.category, 'Fuel');
    expect(parsed.lines.first.quantity, 18.425);
    expect(parsed.lines.first.unit, 'gallon');
    expect(parsed.lines.first.unitPrice, 3.699);
    expect(parsed.lines.first.fuelType, 'Diesel');
    expect(parsed.lines.first.odometerReading, 184220);
    expect(parsed.lines.last.category, 'Receipt Adjustment');
    expect(parsed.lines.last.subtotal, -1.20);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
    expect(parsed.diagnostics.parserTaskCount('generic_fuel_receipt_ready'), 1);
    expect(parsed.diagnostics.parserTaskCount('fuel_detail_needs_review'), 0);
    expect(parsed.diagnostics.hasParserGenericFuelReceiptReady, isTrue);
    expect(
      parsed.diagnostics.downstreamReadinessSummaryLabel,
      'Fuel receipt review ready',
    );
    expect(parsed.diagnostics.reconciled, isTrue);
  });

  test('uses net unit price when fuel has a per-gallon discount', () {
    final parsed = parseExpenseReceiptText('''
CIRCLE K
06/19/2026
PUMP 04
PRODUCT REGULAR 87
GALLONS 10.000
PRICE/GAL 3.599
DISC/GAL -0.100
FUEL SALE 34.99
TOTAL 34.99
ODOMETER 92340
''');

    expect(parsed.merchantName, 'Circle K');
    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.quantity, 10);
    expect(fuel.unitPrice, closeTo(3.499, .001));
    expect(fuel.subtotal, 34.99);
    expect(fuel.fuelType, 'Gasoline');
    expect(fuel.odometerReading, 92340);
    expect(parsed.diagnostics.reconciled, isTrue);
    expect(
      parsed.diagnostics.parserTaskCount('fuel_amount_math_needs_review'),
      0,
    );
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('uses net unit price when fuel rewards apply cents off per gallon', () {
    final parsed = parseExpenseReceiptText('''
SHELL
06/19/2026
PUMP 07
PRODUCT REGULAR 87
GALLONS 10.000
PRICE/GAL 3.599
FUEL REWARDS -0.100/GAL
FUEL SALE 34.99
TOTAL 34.99
ODOMETER 92410
''');

    expect(parsed.merchantName, 'Shell');
    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.quantity, 10);
    expect(fuel.unitPrice, closeTo(3.499, .001));
    expect(fuel.subtotal, 34.99);
    expect(fuel.fuelType, 'Gasoline');
    expect(fuel.odometerReading, 92410);
    expect(parsed.diagnostics.reconciled, isTrue);
    expect(
      parsed.diagnostics.parserTaskCount('fuel_amount_math_needs_review'),
      0,
    );
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test(
    'parses grocery fuel center shopper discounts without leaking metadata',
    () {
      final parsed = parseExpenseReceiptText('''
KROGER FUEL CENTER #525
06/21/2026
PUMP 07
GRADE REGULAR 87
GALLONS 12.345
PRICE/GAL 3.699
SHOPPER DISC -0.400/GAL
FUEL SALE 40.73
ALT ID ********1234
TOTAL 40.73
ODOMETER 77120
''');

      expect(parsed.merchantName, 'Kroger');
      expect(parsed.lines, hasLength(1));
      final fuel = parsed.lines.single;
      expect(fuel.category, 'Fuel');
      expect(fuel.fuelType, 'Gasoline');
      expect(fuel.quantity, 12.345);
      expect(fuel.unit, 'gallon');
      expect(fuel.unitPrice, closeTo(3.299, .001));
      expect(fuel.subtotal, 40.73);
      expect(fuel.odometerReading, 77120);
      expect(fuel.rawReceiptText.toLowerCase(), isNot(contains('alt id')));
      expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
    },
  );

  test('parses club fuel compact gallons and savings per gallon', () {
    final parsed = parseExpenseReceiptText('''
SAMS CLUB FUEL CENTER
06/21/2026
PUMP 12
UNLEADED 87 15.432G 49.52
PRICE/G 3.259
CLUB SAVINGS -0.050/G
TOTAL 49.52
ODOMETER 88210
''');

    expect(parsed.merchantName, 'Sam\'s Club');
    expect(parsed.lines, hasLength(1));
    final fuel = parsed.lines.single;
    expect(fuel.category, 'Fuel');
    expect(fuel.fuelType, 'Gasoline');
    expect(fuel.quantity, 15.432);
    expect(fuel.unit, 'gallon');
    expect(fuel.unitPrice, closeTo(3.209, .001));
    expect(fuel.subtotal, 49.52);
    expect(fuel.odometerReading, 88210);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

  test('keeps pump car wash add-ons separate from fuel gallons', () {
    final parsed = parseExpenseReceiptText('''
SHELL
06/19/2026
PUMP 07
REG UNL 12.000 @ 3.499 41.99
CAR WASH ULTIMATE 12.00
TOTAL 53.99
VISA 53.99
ODOMETER 93420
''');

    expect(parsed.merchantName, 'Shell');
    expect(parsed.lines, hasLength(2));
    final fuel = parsed.lines.singleWhere((line) => line.category == 'Fuel');
    expect(fuel.quantity, 12);
    expect(fuel.unitPrice, closeTo(3.499, .001));
    expect(fuel.subtotal, 41.99);
    expect(fuel.odometerReading, 93420);
    final carWash = parsed.lines.singleWhere(
      (line) => line.category == 'Vehicle Supplies',
    );
    expect(carWash.subtotal, 12.00);
    expect(parsed.lineSubtotal, closeTo(53.99, .001));
    expect(parsed.businessTotal, closeTo(53.99, .001));
    expect(parsed.diagnostics.reconciled, isTrue);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
  });

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
Producto Gasolina Sin Etanol
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

  test('does not carry per gallon rewards metadata onto personal items', () {
    final parsed = parseExpenseReceiptText('''
RIVER ROAD MART 418
06/04/2026
Pump 14 B20 DIESEL 7.625 GAL 28.37
FUEL REWARDS -0.100/GAL
BEER 6PK 11.99
CIGARETTES 8.75
LOTTERY SCRATCHER 5.00
TOTAL 54.11
''');

    final fuelLines = parsed.lines.where((line) => line.category == 'Fuel');
    expect(fuelLines, hasLength(1));
    final fuel = fuelLines.single;
    expect(fuel.description, contains('B20 Diesel'));
    expect(fuel.fuelType, 'Diesel');
    expect(fuel.quantity, 7.625);
    expect(fuel.subtotal, 28.37);
    expect(fuel.unitPrice, closeTo(3.721, .001));

    final personalLines = parsed.lines.where(
      (line) => line.category == 'Personal',
    );
    expect(personalLines, hasLength(3));
    expect(
      personalLines.map((line) => line.description).join(' '),
      isNot(contains('Fuel Rewards')),
    );
    expect(parsed.personalTotal, closeTo(25.74, .001));
  });
}
