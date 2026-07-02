import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test('normalizes unknown fuel receipt OCR swaps before parsing', () {
    final parsed = parseExpenseReceiptText('''
RIVER R0AD MART 418
O6/19/2O26 O7:15 AM
PUMP O4
PR0DUCT D1ESEL
GALL0NS 18.25O
PRICE/GA1 3.699
FUEL SALE 67.51
T0TAL 67.51
CARD 67.51
''');

    expect(parsed.merchantName, 'River Road Mart 418');
    expect(parsed.receiptDate, DateTime(2026, 6, 19));
    expect(parsed.receiptTimeMinutes, (7 * 60) + 15);
    expect(parsed.lines, hasLength(1));
    expect(parsed.lines.single.category, 'Fuel');
    expect(parsed.lines.single.quantity, 18.25);
    expect(parsed.lines.single.unitPrice, 3.699);
    expect(parsed.lines.single.fuelType, 'Diesel');
    expect(parsed.enteredTotal, 67.51);
    expect(parsed.diagnostics.parserTaskCount('generic_fuel_receipt_ready'), 1);
    expect(parsed.diagnostics.reconciled, isTrue);
  });

  test(
    'preserves split-row fuel OCR detail readiness through parser handoff',
    () {
      const ocr = ReceiptOcrResult(
        rawText: '''
COUNTY LINE MARKET
06/29/2026 08:14 PM
PUMP 04
PRODUCT D1ESEL
GALLONS 12.349
PR1CE / GA1 3.699
FUE1 SALE 45.68
TOTAL 45.68
CARD 45.68
''',
        parserText: '''
COUNTY LINE MARKET
06/29/2026 08:14 PM
PUMP 04
PRODUCT D1ESEL
GALLONS 12.349
PR1CE / GA1 3.699
FUE1 SALE 45.68
TOTAL 45.68
CARD 45.68
''',
        textByAttachmentId: {'photo-1': 'private receipt text omitted'},
        source: ReceiptProcessingSource.photo,
      );

      final parsed = parseExpenseReceiptOcrResult(ocr);

      expect(parsed.merchantName, 'County Line Market');
      expect(parsed.lines, hasLength(1));
      expect(parsed.lines.single.category, 'Fuel');
      expect(parsed.lines.single.quantity, 12.349);
      expect(parsed.lines.single.unitPrice, 3.699);
      expect(parsed.lines.single.fuelType, 'Diesel');
      expect(parsed.enteredTotal, 45.68);
      expect(
        parsed.diagnostics.ocrParserTaskCount('fuel_quantity_signal'),
        greaterThanOrEqualTo(1),
      );
      expect(
        parsed.diagnostics.ocrParserTaskCount('fuel_unit_price_signal'),
        1,
      );
      expect(
        parsed.diagnostics.ocrParserTaskCount('fuel_detail_ready'),
        greaterThanOrEqualTo(1),
      );
      expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
      expect(
        parsed.diagnostics.parserTaskCount('generic_fuel_receipt_ready'),
        1,
      );
      expect(parsed.diagnostics.reconciled, isTrue);
    },
  );

  test(
    'parses noisy neighboring fuel detail labels without merchant profile',
    () {
      final parsed = parseExpenseReceiptText('''
COUNTY LINE MARKET
06/29/2026 08:14 PM
PUMP 04
FUE1 SALE 45.68
PR1CE / GA1 3.699
V0L 12.349
PRODUCT D1ESEL
T0TAL 45.68
FLEET CARD 45.68
AUTH 883241
''');

      expect(parsed.merchantName, 'County Line Market');
      expect(parsed.lines, hasLength(1));
      expect(parsed.lines.single.category, 'Fuel');
      expect(parsed.lines.single.quantity, 12.349);
      expect(parsed.lines.single.unit, 'gallon');
      expect(parsed.lines.single.unitPrice, 3.699);
      expect(parsed.lines.single.fuelType, 'Diesel');
      expect(parsed.enteredTotal, 45.68);
      expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
      expect(parsed.diagnostics.parserTaskCount('fuel_detail_needs_review'), 0);
      expect(
        parsed.diagnostics.parserTaskCount('generic_fuel_receipt_ready'),
        1,
      );
      expect(parsed.diagnostics.reconciled, isTrue);
    },
  );

  test('parses abbreviated fuel price and quantity rows in either order', () {
    final parsed = parseExpenseReceiptText('''
RURAL STOP 12
06/30/2026 06:22 AM
PUMP 02
PRODUCT UNL
PPG 3.699
QTY 12.349
FUEL 45.68
TOTAL 45.68
VISA 45.68
''');

    expect(parsed.merchantName, 'Rural Stop 12');
    expect(parsed.lines, hasLength(1));
    expect(parsed.lines.single.category, 'Fuel');
    expect(parsed.lines.single.quantity, 12.349);
    expect(parsed.lines.single.unit, 'gallon');
    expect(parsed.lines.single.unitPrice, 3.699);
    expect(parsed.lines.single.fuelType, 'Gasoline');
    expect(parsed.enteredTotal, 45.68);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 1);
    expect(parsed.diagnostics.parserTaskCount('fuel_detail_needs_review'), 0);
    expect(parsed.diagnostics.parserTaskCount('generic_fuel_receipt_ready'), 1);
    expect(parsed.diagnostics.reconciled, isTrue);
  });

  test('parses unknown fuel receipts with noisy abbreviated fuel labels', () {
    final priceSlashG = parseExpenseReceiptText('''
COUNTY ROAD MARKET
07/01/2026 05:45 AM
PUMP 09
PRODUCT DSL
GALNS 18.250
PRICE/G 3.699
FUEL AMT 67.51
CARD 67.51
''');

    expect(priceSlashG.merchantName, 'County Road Market');
    expect(priceSlashG.lines, hasLength(1));
    expect(priceSlashG.lines.single.category, 'Fuel');
    expect(priceSlashG.lines.single.quantity, 18.25);
    expect(priceSlashG.lines.single.unit, 'gallon');
    expect(priceSlashG.lines.single.unitPrice, 3.699);
    expect(priceSlashG.lines.single.fuelType, 'Diesel');
    expect(priceSlashG.enteredTotal, 67.51);
    expect(priceSlashG.diagnostics.parserTaskCount('fuel_line_ready'), 1);
    expect(
      priceSlashG.diagnostics.parserTaskCount('generic_fuel_receipt_ready'),
      1,
    );

    final dollarPerGal = parseExpenseReceiptText('''
RIVER STOP 27
07/01/2026 06:10 AM
PUMP 03
REG UNL
VOL 12.340
\$/GAL 3.459
FUEL AMOUNT 42.69
VISA 42.69
''');

    expect(dollarPerGal.lines, hasLength(1));
    expect(dollarPerGal.lines.single.category, 'Fuel');
    expect(dollarPerGal.lines.single.quantity, 12.34);
    expect(dollarPerGal.lines.single.unitPrice, 3.459);
    expect(dollarPerGal.lines.single.fuelType, 'Gasoline');
    expect(dollarPerGal.enteredTotal, 42.69);
    expect(dollarPerGal.diagnostics.parserTaskCount('fuel_line_ready'), 1);
    expect(
      dollarPerGal.diagnostics.parserTaskCount('generic_fuel_receipt_ready'),
      1,
    );
  });

  test('flags fuel amount math mismatch for review', () {
    final parsed = parseExpenseReceiptText('''
COUNTY ROAD MARKET
07/01/2026 05:45 AM
PUMP 09
PRODUCT DSL
GALLONS 18.250
PRICE/G 3.699
FUEL AMT 60.00
CARD 60.00
''');

    expect(parsed.lines, hasLength(1));
    expect(parsed.lines.single.category, 'Fuel');
    expect(parsed.lines.single.quantity, 18.25);
    expect(parsed.lines.single.unitPrice, 3.699);
    expect(parsed.lines.single.subtotal, 60.00);
    expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 0);
    expect(parsed.diagnostics.parserTaskCount('fuel_detail_needs_review'), 1);
    expect(
      parsed.diagnostics.parserTaskCount('fuel_amount_math_needs_review'),
      1,
    );
    expect(parsed.diagnostics.parserTaskCount('generic_fuel_receipt_ready'), 0);
  });
}
