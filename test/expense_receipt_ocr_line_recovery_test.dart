import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/shared/receipts/receipt_ocr_contract.dart';

void main() {
  test('recovers safe OCR item drafts omitted by generic text parsing', () {
    const existing = ExpenseReceiptLineRecord(
      id: 'PARSED-1',
      description: 'Bread',
      category: 'Uncategorized',
      use: ExpenseLineUse.unclassified,
      quantity: 1,
      unitsPerPackage: 1,
      unit: 'each',
      subtotal: 1.99,
      unitPrice: 1.99,
      rawReceiptText: 'BREAD 1.99',
      ocrSourceLineId: 'ocr_line_001_item',
      ocrSourceLineNumber: 2,
    );
    const parsed = ExpenseReceiptParseResult(
      sourceText: 'BREAD 1.99\nMILK 2.49\nTOTAL 4.48',
      lines: [existing],
      enteredTotal: 4.48,
    );
    const drafts = [
      ReceiptOcrParserLineDraft(
        stableLineId: 'ocr_line_001_item',
        lineNumber: 2,
        text: 'BREAD 1.99',
        role: 'item',
        parserBucket: 'item_ready',
        amount: 1.99,
        confidence: .95,
        needsReview: false,
        reviewReason: 'Strong priced item line.',
        traits: ['safe_terminal_line_amount'],
      ),
      ReceiptOcrParserLineDraft(
        stableLineId: 'ocr_line_002_item',
        lineNumber: 3,
        text: 'MILK 2.49',
        role: 'item',
        parserBucket: 'item_ready',
        amount: 2.49,
        confidence: .91,
        needsReview: false,
        reviewReason: 'Strong priced item line.',
        traits: ['safe_terminal_line_amount'],
        sourceLocation: ReceiptOcrParserLineLocation(
          sectionNumber: 1,
          sectionLineNumber: 3,
        ),
        expenseFamily: ReceiptOcrParserExpenseFamily.foodOrGrocery,
        parserHint: 'food_or_grocery_item_price',
      ),
      ReceiptOcrParserLineDraft(
        stableLineId: 'ocr_line_003_item',
        lineNumber: 4,
        text: 'UNSAFE EMBEDDED 8.75 EACH',
        role: 'item',
        parserBucket: 'item_needs_review',
        amount: 8.75,
        confidence: .42,
        needsReview: true,
        reviewReason: 'Amount is not safely positioned.',
        traits: [],
      ),
      ReceiptOcrParserLineDraft(
        stableLineId: 'ocr_line_004_total',
        lineNumber: 5,
        text: 'TOTAL 4.48',
        role: 'total',
        parserBucket: 'total_ready',
        amount: 4.48,
        confidence: .99,
        needsReview: false,
        reviewReason: 'Receipt total.',
        traits: ['safe_terminal_line_amount'],
      ),
      ReceiptOcrParserLineDraft(
        stableLineId: 'ocr_line_008_item',
        lineNumber: 9,
        text: 'BREAD 1.99',
        role: 'item',
        parserBucket: 'item_ready',
        amount: 1.99,
        confidence: .94,
        needsReview: false,
        reviewReason: 'Repeated OCR candidate.',
        traits: ['safe_terminal_line_amount'],
      ),
    ];

    final recovered = recoverMissingOcrItemDrafts(parsed, drafts);

    expect(recovered.lines, hasLength(2));
    expect(recovered.lines.map((line) => line.description), ['Bread', 'Milk']);
    final milk = recovered.lines.last;
    expect(milk.subtotal, 2.49);
    expect(milk.category, 'Uncategorized');
    expect(milk.use, ExpenseLineUse.unclassified);
    expect(milk.parserNeedsReview, isTrue);
    expect(milk.parserReviewLabel, 'Review');
    expect(milk.ocrSourceLineId, 'ocr_line_002_item');
    expect(milk.ocrSourceSectionLineNumber, 3);
    expect(milk.parserExpenseFamily, 'food_or_grocery');
    expect(recovered.lineReviews, hasLength(1));
    expect(recovered.lineReviews.single.lineId, milk.id);
    expect(recovered.lineReviews.single.needsReview, isTrue);
    expect(recovered.warnings.single, contains('one additional priced line'));
  });

  test(
    'returns the original result when no safe item candidate is missing',
    () {
      const parsed = ExpenseReceiptParseResult(
        sourceText: 'TOTAL 5.00',
        lines: [],
        enteredTotal: 5,
      );
      const drafts = [
        ReceiptOcrParserLineDraft(
          stableLineId: 'ocr_line_000_total',
          lineNumber: 1,
          text: 'TOTAL 5.00',
          role: 'total',
          parserBucket: 'total_ready',
          amount: 5,
          confidence: .99,
          needsReview: false,
          reviewReason: 'Receipt total.',
          traits: ['safe_terminal_line_amount'],
        ),
      ];

      expect(recoverMissingOcrItemDrafts(parsed, drafts), same(parsed));
    },
  );
}
