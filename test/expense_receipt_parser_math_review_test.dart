import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';

void main() {
  test('warns when explicit subtotal tax and total do not reconcile', () {
    final parsed = parseExpenseReceiptText('''
THE HOME DEPOT
06/12/2026
PVC GLUE 7.99
PIPE STRAP 2.01
Subtotal 10.00
Tax 0.80
Total 12.80
''');

    expect(parsed.lines, hasLength(2));
    expect(parsed.diagnostics.hasCompleteExplicitTotals, isTrue);
    expect(parsed.diagnostics.taxMathReconciled, isFalse);
    expect(parsed.diagnostics.taxMathDifference, closeTo(-2.00, .001));
    expect(
      parsed.diagnostics.totalsMathLabel,
      'Subtotal plus tax differs by \$2.00',
    );
    expect(parsed.diagnostics.trustLabel, 'Needs receipt math review');
    expect(
      parsed.warnings,
      contains(
        'Receipt subtotal plus tax (\$10.80) does not match the receipt total (\$12.80). Review receipt math and OCR mistakes.',
      ),
    );
  });

  test('calculates visible line math independently of an OCR total', () {
    final parsed = parseExpenseReceiptText('''
LOCAL HARDWARE
06/12/2026
PIPE STRAP 8.00
COUPON -1.00
TOTAL 12.00
''');

    expect(parsed.lineSubtotal, 7.00);
    expect(parsed.enteredTotal, 12.00);
    expect(parsed.diagnostics.reconciled, isFalse);
    expect(parsed.diagnostics.reconciliationDifference, closeTo(-5.00, .001));
    expect(parsed.diagnostics.lineSubtotal, 7.00);
    expect(parsed.diagnostics.expectedSubtotalOrTotal, 12.00);
    expect(
      parsed.warnings.singleWhere(
        (warning) => warning.contains('Parsed line totals'),
      ),
      contains('discounts, and OCR mistakes'),
    );
  });

  test(
    'marks inferred receipt math as incomplete instead of overconfident',
    () {
      final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/12/2026
PVC GLUE 7.99
Tax 0.56
Total 8.55
''');

      expect(parsed.enteredSubtotal, closeTo(7.99, .001));
      expect(parsed.diagnostics.hasExplicitSubtotal, isFalse);
      expect(parsed.diagnostics.hasExplicitTax, isTrue);
      expect(parsed.diagnostics.hasExplicitTotal, isTrue);
      expect(parsed.diagnostics.hasCompleteExplicitTotals, isFalse);
      expect(parsed.diagnostics.taxMathReconciled, isFalse);
      expect(
        parsed.diagnostics.totalsMathLabel,
        'Receipt total math incomplete',
      );
      expect(
        parsed.warnings.any((warning) => warning.contains('subtotal plus tax')),
        isFalse,
      );
    },
  );

  test('flags receipts where most parsed lines need review', () {
    final parsed = parseExpenseReceiptText('''
CORNER STORE
06/12/2026
AA 1.00
BB 2.00
PVC GLUE 7.99
Total 10.99
''');

    expect(parsed.lines, hasLength(3));
    expect(parsed.diagnostics.reviewLineCount, greaterThanOrEqualTo(2));
    expect(parsed.diagnostics.reviewRatio, greaterThanOrEqualTo(.5));
    expect(parsed.diagnostics.needsHeavyReview, isTrue);
    expect(parsed.diagnostics.hasParserCategoryWeakConfidence, isTrue);
    expect(
      parsed.diagnostics.parserCategoryReviewActionCode,
      'review_low_confidence_lines',
    );
    expect(
      parsed.diagnostics.parserCategoryReviewActionLabel,
      'Review the low-confidence receipt lines before saving.',
    );
    expect(parsed.diagnostics.trustLabel, 'Needs line review');
    expect(
      parsed.warnings,
      contains(
        'Most parsed receipt lines need review before saving this receipt.',
      ),
    );
  });

  test('normalizes common OCR letter and number swaps before parsing', () {
    final homeCenter = parseExpenseReceiptText('''
H0ME DEP0T
O6/19/2O26
1/2  IN   C0PPER  9O  ELB0W   7.48
PVC  GLUE  7,99
T0TAL 15.47
''');

    expect(homeCenter.merchantName, 'The Home Depot');
    expect(homeCenter.receiptDate, DateTime(2026, 6, 19));
    expect(homeCenter.enteredTotal, 15.47);
    expect(homeCenter.lines, hasLength(2));
    expect(
      homeCenter.lines.first.description.toLowerCase(),
      contains('copper'),
    );
    expect(homeCenter.lines.first.description.toLowerCase(), contains('elbow'));
    expect(homeCenter.lines.first.category, 'Materials');
    expect(homeCenter.lines.first.subtotal, 7.48);
    expect(homeCenter.lines.last.category, 'Materials');
    expect(homeCenter.lines.last.subtotal, 7.99);

    final fuel = parseExpenseReceiptText('''
SHEETZ
O6/19/2O26 O7:15 AM
PUMP O4 UNLEADED 14.25O GAL 47.O1
T0TAL 47.O1
''');

    expect(fuel.merchantName, 'Sheetz');
    expect(fuel.receiptDate, DateTime(2026, 6, 19));
    expect(fuel.receiptTimeMinutes, (7 * 60) + 15);
    expect(fuel.enteredTotal, 47.01);
    expect(fuel.lines.single.category, 'Fuel');
    expect(fuel.lines.single.quantity, 14.25);
    expect(fuel.lines.single.unit, 'gallon');
    expect(fuel.lines.single.subtotal, 47.01);

    final decimalFuel = parseExpenseReceiptText('''
SHELL
O7/O1/2O26 O6:45 AM
PUMP O2 DIESEL 1O.OOO GAL 35.OO
SUBT0TAL 35.OO
T4X 2.1O
T0TAL 37.1O
''');

    expect(decimalFuel.merchantName, 'Shell');
    expect(decimalFuel.lines.single.category, 'Fuel');
    expect(decimalFuel.lines.single.quantity, 10);
    expect(decimalFuel.lines.single.unitPrice, 3.5);
    expect(decimalFuel.lines.single.fuelType, 'Diesel');
    expect(decimalFuel.enteredTotal, 37.10);
  });

  test('normalizes damaged Lowe OCR merchant text before matching profile', () {
    final parsed = parseExpenseReceiptText('''
L0WES H0ME IMPR0VEMENT
O6/2O/2O26
PVC C0UPLING 2.49
PVC GLUE 7,99
AM0UNT PAID 10.48
''');

    expect(parsed.merchantName, "Lowe's");
    expect(parsed.receiptDate, DateTime(2026, 6, 20));
    expect(parsed.enteredTotal, 10.48);
    expect(parsed.lines, hasLength(2));
    expect(parsed.lines.map((line) => line.category), [
      'Materials',
      'Materials',
    ]);
  });
}
