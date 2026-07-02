import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test('pre-save allocation does not assign tax to return lines', () {
    const parsed = ExpenseReceiptParseResult(
      sourceText: 'return preview',
      enteredSubtotal: 20,
      enteredTax: 2,
      enteredTotal: 22,
      lines: [
        ExpenseReceiptLineRecord(
          id: 'business-purchase',
          description: 'Business purchase',
          category: 'Materials',
          use: ExpenseLineUse.business,
          quantity: 1,
          unitsPerPackage: 1,
          unit: 'each',
          subtotal: 30,
        ),
        ExpenseReceiptLineRecord(
          id: 'business-return',
          description: 'Business return',
          category: 'Materials',
          use: ExpenseLineUse.business,
          quantity: 1,
          unitsPerPackage: 1,
          unit: 'each',
          subtotal: -10,
        ),
        ExpenseReceiptLineRecord(
          id: 'personal-purchase',
          description: 'Personal purchase',
          category: 'Personal',
          use: ExpenseLineUse.personal,
          quantity: 1,
          unitsPerPackage: 1,
          unit: 'each',
          subtotal: 10,
        ),
      ],
    );

    expect(parsed.lineSubtotal, 30);
    expect(parsed.receiptAdjustment, -8);
    expect(parsed.businessAdjustmentBase, 30);
    expect(parsed.personalAdjustmentBase, 10);
    expect(parsed.receiptAdjustmentBase, 40);
    expect(parsed.businessTotal, closeTo(14, .001));
    expect(parsed.personalTotal, closeTo(8, .001));
    expect(parsed.businessTotalForLine(parsed.lines[0]), closeTo(24, .001));
    expect(parsed.businessTotalForLine(parsed.lines[1]), closeTo(-10, .001));
    expect(parsed.personalTotalForLine(parsed.lines[2]), closeTo(8, .001));
  });

  test('tracks parser confidence for known merchant and inferred totals', () {
    final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
PVC GLUE 7.99
Tax 0.56
Total 8.55
''', fallbackDate: DateTime(2026, 6, 12));

    expect(parsed.merchantName, "Lowe's");
    expect(parsed.receiptDate, DateTime(2026, 6, 12));
    expect(parsed.enteredSubtotal, closeTo(7.99, .001));
    expect(parsed.fieldConfidences['merchant']?.label, 'Good');
    expect(
      parsed.fieldConfidences['merchant']?.reason,
      'Merchant matched a known receipt profile.',
    );
    expect(parsed.fieldConfidences['date']?.label, 'Review');
    expect(
      parsed.fieldConfidences['date']?.reason,
      'Receipt date used the selected day as a fallback.',
    );
    expect(parsed.fieldConfidences['subtotal']?.label, 'Review');
    expect(
      parsed.fieldConfidences['subtotal']?.reason,
      'Subtotal was inferred from other receipt totals.',
    );
    expect(parsed.fieldConfidences['tax']?.label, 'Good');
    expect(parsed.fieldConfidences['total']?.label, 'Good');
    expect(parsed.fieldConfidences['receiptMath']?.label, 'Review');
    expect(
      parsed.fieldConfidences['receiptMath']?.reason,
      contains('inferred or missing'),
    );
  });

  test('light parser depth reads receipt header and totals only', () {
    final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/12/2026
1/2 IN COPPER 90 ELBOW 7.48
SAW BLADE 19.98
Subtotal 27.46
Tax 1.92
Total 29.38
''', parserDepth: ReceiptParserDepth.proofTotalsOnly);

    expect(parsed.merchantName, "Lowe's");
    expect(parsed.receiptDate, DateTime(2026, 6, 12));
    expect(parsed.enteredSubtotal, 27.46);
    expect(parsed.enteredTax, 1.92);
    expect(parsed.enteredTotal, 29.38);
    expect(parsed.lines, isEmpty);
    expect(parsed.warnings.single, contains('header and totals only'));
    expect(parsed.quality.needsReview, isTrue);
    expect(parsed.diagnostics.parserDepth, ReceiptParserDepth.proofTotalsOnly);
    expect(parsed.diagnostics.lineSummaryLabel, 'No line items parsed');
    expect(parsed.diagnostics.catalogSummaryLabel, 'Catalog matching skipped');
    expect(
      parsed.diagnostics.receiptClassificationSummaryLabel,
      'Receipt total ready to classify',
    );
    expect(
      parsed.diagnostics.localReceiptParserRoutingCode,
      'proof_totals_first',
    );
    expect(parsed.diagnostics.keepsSimpleReceiptLocal, isTrue);
    expect(parsed.diagnostics.shouldOfferDetailedParserPack, isFalse);
    expect(
      parsed.diagnostics.localReceiptParserRoutingLabel,
      contains('Use local receipt proof fields first'),
    );
    expect(
      parsed.diagnostics.localReceiptParserRoutingSummaryLabel,
      'Proof totals stayed local',
    );
    expect(
      parsed.diagnostics.localReceiptParserRoutingActionLabel,
      contains('add detailed lines only if you need them'),
    );
  });

  test('medium parser depth keeps line items but skips inventory matching', () {
    final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/12/2026
25PK #8 X 1-1/4 WOOD SCREWS 6.98
TOTAL 6.98
''', parserDepth: ReceiptParserDepth.lineItems);

    expect(parsed.lines.single.category, 'Materials');
    expect(parsed.lines.single.catalogItemId, isNull);
    expect(parsed.lineReviews.single.catalogItemName, isNull);
    expect(parsed.diagnostics.parserDepth, ReceiptParserDepth.lineItems);
    expect(parsed.diagnostics.materialLineCount, 1);
    expect(parsed.diagnostics.catalogMatchedLineCount, 0);
    expect(parsed.diagnostics.parserCategoryCount('materials'), 1);
    expect(
      parsed.diagnostics.parserCategoryHealthCount('category_materials_ready'),
      1,
    );
    expect(
      parsed.diagnostics.parserCategoryHealthCount(
        'category_materials_catalog_missing',
      ),
      1,
    );
    expect(
      parsed.diagnostics.parserCategoryHealthCount(
        'category_family_materials_ready',
      ),
      1,
    );
    expect(
      parsed.diagnostics.parserCategoryHealthCount(
        'category_materials_pack_limited',
      ),
      1,
    );
    expect(
      parsed.diagnostics.parserCategoryHealthCount(
        'category_family_materials_pack_limited',
      ),
      1,
    );
    expect(parsed.diagnostics.hasParserCategoryPackLimits, isTrue);
    expect(
      parsed.diagnostics.parserCategoryReviewActionCode,
      'optional_parser_pack_available',
    );
    expect(
      parsed.diagnostics.parserCategoryReviewActionLabel,
      contains('stronger optional parser pack'),
    );
    expect(
      parsed.diagnostics.localReceiptParserRoutingCode,
      'optional_detail_pack_available',
    );
    expect(parsed.diagnostics.keepsSimpleReceiptLocal, isFalse);
    expect(parsed.diagnostics.shouldOfferDetailedParserPack, isTrue);
    expect(
      parsed.diagnostics.localReceiptParserRoutingLabel,
      contains('optional parser pack'),
    );
    expect(
      parsed.diagnostics.localReceiptParserRoutingSummaryLabel,
      'Optional detail pack can improve categories',
    );
    expect(
      parsed.diagnostics.localReceiptParserRoutingActionLabel,
      contains('install an optional pack later'),
    );
    expect(parsed.diagnostics.catalogSummaryLabel, 'Catalog matching skipped');
    expect(
      parsed.lineReviews.single.reason,
      contains('catalog matching was skipped'),
    );
  });

  test('does not turn Lowe address ZIP text into a receipt total', () {
    final parsed = parseExpenseReceiptText('''
LOWE'S HOME CENTERS, LLC
6400 BRODIE LANE
AUSTIN, TX 78745 (512) 895-5560
SALE
SALES#: S2313USO 3644746  TRANS#: 18854480 07-09-21
23536 OATEY 14-OZ PLUMBERS PUTTY       2.99
SUBTOTAL:                              2.99
TAX:                                   0.25
INVOICE 10394  TOTAL:                  3.24
07/09/21 13:14:57
''');

    expect(parsed.merchantName, "Lowe's");
    expect(parsed.enteredSubtotal, 2.99);
    expect(parsed.enteredTax, 0.25);
    expect(parsed.enteredTotal, 3.24);
    expect(parsed.enteredTotal, isNot(787.45));
    expect(parsed.lines, hasLength(1));
    expect(parsed.lines.single.subtotal, 2.99);
  });

  test(
    'does not turn Lowe invoice identifiers into compact receipt totals',
    () {
      final parsed = parseExpenseReceiptText('''
LOWE'S HOME CENTERS, LLC
6400 BRODIE LANE
AUSTIN, TX 78745 (512) 895-5560
SALES#: S2513USO 3644746  TRANS#: 18854480 07-09-21
23536 OATEY 14-OZ PLUMBERS PUTTY       2.99
SUBTOTAL:                              2.99
TAX:                                   0.25
INVOICE TOTAL 18934
MERCH/GIFT CARD 5715 AUTHCODE 370
07/09/21 13:14:57
''');

      expect(parsed.merchantName, "Lowe's");
      expect(parsed.enteredSubtotal, 2.99);
      expect(parsed.enteredTax, 0.25);
      expect(parsed.enteredTotal, 3.24);
      expect(parsed.enteredTotal, isNot(189.34));
      expect(parsed.enteredTotal, isNot(787.45));
      expect(parsed.fieldConfidences['total']?.label, 'Review');
      expect(
        parsed.fieldConfidences['total']?.reason,
        contains('inferred from other receipt totals'),
      );
      expect(parsed.lines, hasLength(1));
      expect(parsed.lines.single.description.toUpperCase(), contains('OATEY'));
    },
  );

  test('still reads clear compact cents receipt total rows', () {
    final parsed = parseExpenseReceiptText('''
LOCAL HARDWARE
07/09/21 13:14:57
SHOP TOWELS 2 99
SUBTOTAL 299
TAX 25
TOTAL 324
''');

    expect(parsed.enteredSubtotal, 2.99);
    expect(parsed.enteredTax, 0.25);
    expect(parsed.enteredTotal, 3.24);
    expect(parsed.enteredTotal, isNot(324));
  });
}
