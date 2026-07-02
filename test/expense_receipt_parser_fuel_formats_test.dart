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
}
