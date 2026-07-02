import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';

void main() {
  test('merchant ranking skips generic banners before gas station name', () {
    final parsed = parseExpenseReceiptText('''
WELCOME
OPEN 24 HOURS
COUNTY LINE FUEL MART #27
07/01/2026 06:45 AM
SALE
PUMP 02 UNLEADED 9.125 GAL 31.93
SUBTOTAL 31.93
TAX 0.00
TOTAL 31.93
CARD 31.93
''');

    expect(parsed.merchantName, 'County Line Fuel Mart 27');
    expect(parsed.receiptDate, DateTime(2026, 7, 1));
    expect(parsed.receiptTimeMinutes, (6 * 60) + 45);
    expect(parsed.lines.single.category, 'Fuel');
    expect(parsed.enteredTotal, 31.93);
    expect(
      parsed.diagnostics.genericReceiptSignalCount('merchantCandidate'),
      greaterThanOrEqualTo(1),
    );
  });

  test('merchant ranking skips sale header before unknown hardware store', () {
    final parsed = parseExpenseReceiptText('''
SALE
CUSTOMER COPY
OAK HILL HARDWARE & SUPPLY
07/01/2026 14:10
PVC COUPLING 1 IN 4.99
SHOP TOWELS 8.97
SUBTOTAL 13.96
SALES TAX 1.12
TOTAL 15.08
VISA 15.08
''');

    expect(parsed.merchantName, 'Oak Hill Hardware & Supply');
    expect(parsed.receiptDate, DateTime(2026, 7, 1));
    expect(parsed.receiptTimeMinutes, (14 * 60) + 10);
    expect(parsed.lines, hasLength(2));
    expect(parsed.lines.first.category, 'Materials');
    expect(parsed.enteredSubtotal, 13.96);
    expect(parsed.enteredTax, 1.12);
    expect(parsed.enteredTotal, 15.08);
  });

  test('merchant ranking survives noisy fuel register headers', () {
    final parsed = parseExpenseReceiptText('''
MERCHANT COPY
SALE
STORE #0427
REGISTER 04
CASHIER: KELLY
TERMINAL 18
TRANS#: 18854480
APPROVAL 370
RIVER ROAD STATION
07/01/2026 11:42 PM
PUMP 04
PRODUCT UNLEADED
GALLONS 10.250
PRICE/G 3.499
FUEL SALE 35.86
SUBTOTAL 35.86
TOTAL 35.86
VISA 35.86
''');

    expect(parsed.merchantName, 'River Road Station');
    expect(parsed.receiptDate, DateTime(2026, 7, 1));
    expect(parsed.receiptTimeMinutes, (23 * 60) + 42);
    expect(parsed.enteredTotal, 35.86);
    expect(parsed.lines, hasLength(1));
    expect(parsed.lines.single.category, 'Fuel');
    expect(parsed.lines.single.quantity, 10.25);
    expect(parsed.lines.single.unitPrice, 3.499);
    expect(parsed.diagnostics.parserTaskCount('generic_fuel_receipt_ready'), 1);
    expect(
      parsed.diagnostics.parserTaskCount('transaction_line_excluded'),
      greaterThanOrEqualTo(1),
    );
    expect(
      parsed.diagnostics.parserTaskCount('payment_line_excluded'),
      greaterThanOrEqualTo(1),
    );
  });

  test('known fuel profile can appear after register header noise', () {
    final parsed = parseExpenseReceiptText('''
CUSTOMER COPY
RECEIPT
STORE COPY
STORE #2513
POS REGISTER 7
CASHIER 42
TERMINAL 09
TRACE 000447
SHEETZ
07/01/2026 06:15 AM
PUMP 02 DIESEL 14.250 GAL 47.01
SUBTOTAL 47.01
TOTAL 47.01
FLEET CARD 47.01
''');

    expect(parsed.merchantName, 'Sheetz');
    expect(parsed.receiptDate, DateTime(2026, 7, 1));
    expect(parsed.receiptTimeMinutes, (6 * 60) + 15);
    expect(parsed.lines.single.category, 'Fuel');
    expect(parsed.lines.single.fuelType, 'Diesel');
    expect(parsed.enteredTotal, 47.01);
    expect(parsed.fieldConfidences['merchant']?.label, 'Good');
    expect(parsed.diagnostics.parserCategoryCount('fuel'), 1);
  });
}
