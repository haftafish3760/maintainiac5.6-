import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';

void main() {
  test('parses explicit business and personal receipt line allocation', () {
    final parsed = parseExpenseReceiptText('''
TARGET
07/02/2026
BUSINESS SHOP TOWELS 12.00
PERSONAL SNACKS 8.00
SUBTOTAL 20.00
TAX 1.20
TOTAL 21.20
''');

    expect(parsed.merchantName, 'Target');
    expect(parsed.receiptDate, DateTime(2026, 7, 2));
    expect(parsed.enteredSubtotal, 20.00);
    expect(parsed.enteredTax, 1.20);
    expect(parsed.enteredTotal, 21.20);
    expect(parsed.lines, hasLength(2));
    expect(parsed.lines[0].use, ExpenseLineUse.business);
    expect(parsed.lines[1].use, ExpenseLineUse.personal);
    expect(parsed.lines[0].receiptLineNumberLabel, 'Line 3');
    expect(parsed.lines[1].receiptLineNumberLabel, 'Line 4');
    expect(parsed.lines[0].receiptReviewModeCode, 'detailedLine');
    expect(parsed.lines[1].receiptReviewModeCode, 'detailedLine');
    expect(parsed.lines[0].businessUseReviewLabel, 'Business');
    expect(parsed.lines[1].businessUseReviewLabel, 'Personal');
    expect(parsed.lines[0].category, 'Vehicle Supplies');
    expect(parsed.lines[1].category, 'Meals');
    expect(parsed.lines[0].parserNeedsReview, isFalse);
    expect(parsed.lines[1].parserNeedsReview, isFalse);
    expect(parsed.businessTotal, closeTo(12.72, .001));
    expect(parsed.personalTotal, closeTo(8.48, .001));
    expect(
      parsed.diagnostics.parserDownstreamReadinessStatus,
      'expense_lines_ready',
    );
    expect(parsed.diagnostics.reviewLineCount, 0);
  });

  test('parsed lines keep numbered review contracts for price-only mode', () {
    final parsed = parseExpenseReceiptText('''
TARGET
07/02/2026
BUSINESS SHOP TOWELS 12.00
PERSONAL SNACKS 8.00
TOTAL 20.00
''');
    final allocationOnly = ExpenseReceiptLineRecord(
      id: 'allocation-price-line',
      description: '',
      category: 'Uncategorized',
      use: ExpenseLineUse.split,
      businessPercent: .5,
      quantity: 1,
      unitsPerPackage: 1,
      unit: 'each',
      subtotal: parsed.lines.fold<double>(
        0,
        (total, line) => total + line.subtotal,
      ),
      ocrSourceLineNumber: parsed.lines.first.ocrSourceLineNumber,
    );

    expect(allocationOnly.receiptLineNumberLabel, 'Line 3');
    expect(allocationOnly.receiptReviewModeCode, 'priceOnly');
    expect(
      allocationOnly.receiptLineReviewSummary,
      'Line 3: price only, Split 50% business',
    );
    expect(
      allocationOnly.privacySafeLineReviewContract['reviewMode'],
      'priceOnly',
    );
    expect(
      allocationOnly.privacySafeLineReviewContract['businessUse'],
      'split',
    );
    expect(
      allocationOnly.privacySafeLineReviewContract.toString(),
      isNot(contains('SHOP TOWELS')),
    );
    expect(
      parsed.lines.first.privacySafeLineReviewContract['reviewMode'],
      'detailedLine',
    );
  });

  test('parses non-business line marker as personal allocation', () {
    final parsed = parseExpenseReceiptText('''
TARGET
07/02/2026
NON-BUSINESS SNACKS 5.00
BUSINESS WORK GLOVES 15.00
TOTAL 20.00
''');

    expect(parsed.lines, hasLength(2));
    expect(parsed.lines.first.use, ExpenseLineUse.personal);
    expect(parsed.lines.last.use, ExpenseLineUse.business);
    expect(parsed.personalTotal, closeTo(5.00, .001));
    expect(parsed.businessTotal, closeTo(15.00, .001));
    expect(parsed.diagnostics.reviewLineCount, 0);
  });
}
