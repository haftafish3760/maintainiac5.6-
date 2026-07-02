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
