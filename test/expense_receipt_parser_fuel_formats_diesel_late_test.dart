part of 'expense_receipt_parser_fuel_formats_test.dart';

void _registerFuelFormatDieselLateTests() {
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
