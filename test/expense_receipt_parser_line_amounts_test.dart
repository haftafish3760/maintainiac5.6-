import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';

void main() {
  test('keeps positive balance due but ignores stored value balances', () {
    final parsed = parseExpenseReceiptText('''
SUPPLY HOUSE
06/20/2026
PVC FITTING 4.29
STORE CREDIT BALANCE 25.00
BALANCE DUE 4.29
''');

    expect(parsed.enteredTotal, 4.29);
    expect(parsed.lines, hasLength(1));
    expect(parsed.lines.single.description, 'Pvc Fitting');
    expect(parsed.diagnostics.reconciled, isTrue);
  });

  test('parses compact OCR cents and tax suffixes on item rows', () {
    final parsed = parseExpenseReceiptText('''
ACE HARDWARE
06/20/2026
SKU 123456 PVC GLUE 799T
SHOP TOWELS 897
MERCHANDISE TOTAL 16.96
STATE TAX 1.19
ORDER TOTAL 18.15
''');

    expect(parsed.merchantName, 'Ace Hardware');
    expect(parsed.enteredSubtotal, 16.96);
    expect(parsed.enteredTax, 1.19);
    expect(parsed.enteredTotal, 18.15);
    expect(parsed.lines, hasLength(2));
    expect(parsed.lines.first.category, 'Materials');
    expect(parsed.lines.first.description.toLowerCase(), contains('pvc glue'));
    expect(
      parsed.lines.first.description.toLowerCase(),
      isNot(contains('sku')),
    );
    expect(parsed.lines.first.subtotal, 7.99);
    expect(parsed.lines.last.category, 'Vehicle Supplies');
    expect(parsed.lines.last.subtotal, 8.97);
    expect(parsed.diagnostics.reconciled, isTrue);
  });

  test(
    'parses CR and trailing minus returns without treating them as payments',
    () {
      final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/20/2026
PVC PIPE 12.00
RETURN PVC PIPE 1200CR
PAINTERS TAPE 599
TOTAL 5.99
''');

      expect(parsed.lines, hasLength(3));
      expect(parsed.lines[0].subtotal, 12.00);
      expect(parsed.lines[1].subtotal, -12.00);
      expect(parsed.lines[1].category, 'Materials');
      expect(parsed.lines[1].parserNeedsReview, isFalse);
      expect(parsed.lines[2].subtotal, 5.99);
      expect(parsed.diagnostics.reconciled, isTrue);
    },
  );

  test('parses spaced OCR prices, line numbers, item ids, and quantities', () {
    final parsed = parseExpenseReceiptText('''
THE HOME DEPOT
06/20/2026
LINE 01 123456 PVC COUPLING 2 @ 3.99 7 98
25PK #8 WOOD SCREWS 6 98T
QTY: 3 SHOP TOWELS 26 91
SUBTOTAL 41 87
TAX 2 93
TOTAL 44 80
''');

    expect(parsed.enteredSubtotal, 41.87);
    expect(parsed.enteredTax, 2.93);
    expect(parsed.enteredTotal, 44.80);
    expect(parsed.lines, hasLength(3));
    expect(parsed.lines[0].category, 'Materials');
    expect(parsed.lines[0].description.toLowerCase(), contains('pvc coupling'));
    expect(
      parsed.lines[0].description.toLowerCase(),
      isNot(contains('123456')),
    );
    expect(parsed.lines[0].subtotal, 7.98);
    expect(parsed.lines[0].quantity, 2);
    expect(parsed.lines[0].unitPrice, 3.99);
    expect(parsed.lines[1].category, 'Materials');
    expect(parsed.lines[1].unitsPerPackage, 25);
    expect(parsed.lines[1].subtotal, 6.98);
    expect(parsed.lines[2].category, 'Vehicle Supplies');
    expect(parsed.lines[2].quantity, 3);
    expect(parsed.lines[2].subtotal, 26.91);
    expect(parsed.diagnostics.reconciled, isTrue);
  });

  test('parses vehicle supply quantity and unit price rows', () {
    final parsed = parseExpenseReceiptText('''
AUTO PARTS WAREHOUSE
06/30/2026
SHOP TOWELS 2 @ 8.49 16.98
MICROFIBER TOWELS QTY 3 4.50
SUBTOTAL 21.48
TAX 1.50
TOTAL 22.98
''');

    expect(parsed.merchantName, 'Auto Parts Warehouse');
    expect(parsed.enteredSubtotal, 21.48);
    expect(parsed.enteredTax, 1.50);
    expect(parsed.enteredTotal, 22.98);
    expect(parsed.lines, hasLength(2));
    expect(parsed.lines.first.category, 'Vehicle Supplies');
    expect(parsed.lines.first.quantity, 2);
    expect(parsed.lines.first.unitPrice, 8.49);
    expect(parsed.lines.first.subtotal, 16.98);
    expect(parsed.lines.last.category, 'Vehicle Supplies');
    expect(parsed.lines.last.quantity, 3);
    expect(parsed.lines.last.unitPrice, 1.50);
    expect(parsed.lines.last.subtotal, 4.50);
    expect(parsed.diagnostics.parserCategoryCount('vehicle_supplies'), 2);
    expect(parsed.diagnostics.reconciled, isTrue);
  });

  test('ignores gift card and store credit tenders but keeps item totals', () {
    final parsed = parseExpenseReceiptText('''
HOME DEPOT
06/20/2026
1/2 COPPER ELBOW 748T
GIFT CARD 3.00
STORE CREDIT 4.48
TOTAL 7.48
''');

    expect(parsed.enteredTotal, 7.48);
    expect(parsed.lines, hasLength(1));
    expect(parsed.lines.single.category, 'Materials');
    expect(parsed.lines.single.subtotal, 7.48);
    expect(parsed.diagnostics.reconciled, isTrue);
  });

  test(
    'recognizes negative receipt adjustments without lowering confidence',
    () {
      final parsed = parseExpenseReceiptText('''
CVS PHARMACY
06/20/2026
SHOP TOWELS 8.97
MFR COUPON -2.00
STORE DISCOUNT (1.50)
SUBTOTAL 5.47
TAX 0.38
TOTAL 5.85
''');

      expect(parsed.enteredSubtotal, 5.47);
      expect(parsed.enteredTotal, 5.85);
      expect(parsed.lines, hasLength(3));
      expect(parsed.lines[0].category, 'Vehicle Supplies');
      expect(parsed.lines[0].subtotal, 8.97);
      expect(parsed.lines[1].category, 'Receipt Adjustment');
      expect(parsed.lines[1].subtotal, -2.00);
      expect(parsed.lines[1].parserNeedsReview, isFalse);
      expect(parsed.lines[1].parserReviewLabel, 'Good');
      expect(parsed.lines[1].parserReviewReason, contains('coupon'));
      expect(parsed.lines[2].category, 'Receipt Adjustment');
      expect(parsed.lines[2].subtotal, -1.50);
      expect(parsed.lines[2].parserNeedsReview, isFalse);
      expect(parsed.lines[2].parserReviewLabel, 'Good');
      expect(parsed.lines[2].parserReviewReason, contains('discount'));
      expect(
        parsed.warnings.any((warning) => warning.contains('do not match')),
        isFalse,
      );
      expect(parsed.diagnostics.negativeLineCount, 2);
      expect(parsed.diagnostics.adjustmentLineCount, 2);
      expect(parsed.diagnostics.hasAdjustments, isTrue);
      expect(parsed.diagnostics.reconciled, isTrue);
    },
  );

  test('keeps returned item category when negative line names the item', () {
    final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/20/2026
PVC PIPE 12.00
RETURN PVC PIPE -12.00
PAINTERS TAPE 5.99
TOTAL 5.99
''');

    expect(parsed.lines, hasLength(3));
    expect(parsed.lines[0].category, 'Materials');
    expect(parsed.lines[0].subtotal, 12.00);
    expect(parsed.lines[1].category, 'Materials');
    expect(parsed.lines[1].subtotal, -12.00);
    expect(parsed.lines[1].parserNeedsReview, isFalse);
    expect(parsed.lines[1].parserReviewReason, contains('return/refund'));
    expect(parsed.lines[2].category, 'Materials');
    expect(parsed.lines[2].subtotal, 5.99);
    expect(
      parsed.warnings.any((warning) => warning.contains('do not match')),
      isFalse,
    );
  });

  test('flags unlabeled negative receipt lines for review', () {
    final parsed = parseExpenseReceiptText('''
WALMART
06/20/2026
SHOP TOWELS 8.97
MISC ADJ -1.00
TOTAL 7.97
''');

    expect(parsed.lines, hasLength(2));
    expect(parsed.lines.last.subtotal, -1.00);
    expect(parsed.lines.last.parserNeedsReview, isTrue);
    expect(
      parsed.lines.last.parserReviewReason,
      contains('missing an adjustment label'),
    );
  });

  test('warns when parsed line totals do not reconcile with subtotal', () {
    final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/12/2026
PVC PIPE 12.00
Subtotal 42.00
Tax 2.52
Total 44.52
''');

    expect(parsed.lines, hasLength(1));
    expect(parsed.lines.single.category, 'Materials');
    expect(
      parsed.warnings,
      contains(
        'Parsed line totals (\$12.00) do not match the receipt subtotal (\$42.00). Review missing lines, discounts, and OCR mistakes.',
      ),
    );
    expect(parsed.quality.needsReview, isTrue);
    expect(parsed.quality.reasons.join(' '), contains('do not match'));
  });

  test(
    'warns about adjacent duplicate lines from possible long receipt overlap',
    () {
      final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/20/2026
PVC GLUE 7.99
PVC GLUE 7.99
PAINTERS TAPE 5.99
SUBTOTAL 21.97
TAX 1.54
TOTAL 23.51
''');

      expect(parsed.lines, hasLength(3));
      expect(
        parsed.warnings,
        contains(
          'Possible repeated receipt line found. Check adjacent receipt overlap before saving.',
        ),
      );
      expect(parsed.diagnostics.reconciled, isTrue);
      expect(
        parsed.diagnostics.parserTaskCount('long_receipt_duplicate_text'),
        1,
      );
      expect(
        parsed.diagnostics.parserTaskCount('long_receipt_probable_overlap'),
        1,
      );
      expect(parsed.diagnostics.hasParserDuplicateOverlapReview, isTrue);
      expect(parsed.diagnostics.hasParserDuplicateOverlapSourceLabels, isTrue);
      expect(parsed.diagnostics.parserDuplicateOverlapAnchorCount, 1);
      expect(
        parsed.diagnostics.receiptSequenceReviewStatus,
        'overlap_review_needed',
      );
      expect(
        parsed.diagnostics.receiptSequenceReviewLabel,
        'Check repeated receipt overlap',
      );
      expect(parsed.diagnostics.parserDuplicateOverlapSourceLabels, [
        'Line 3 -> Line 4',
      ]);
      expect(
        parsed.diagnostics.parserDuplicateOverlapReviewLabel,
        'Check repeated overlap near Line 3 -> Line 4',
      );
      expect(
        parsed.diagnostics.parserDuplicateOverlapReviewInstruction,
        'Compare Line 3 -> Line 4 (adjacent overlap) before saving so repeated receipt overlap is not counted twice.',
      );
    },
  );
}
