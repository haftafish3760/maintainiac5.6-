part of 'expense_receipt_parser_fuel_formats_test.dart';

void _registerFuelFormatCoreTests() {
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
}
