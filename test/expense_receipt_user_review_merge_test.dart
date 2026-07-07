import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_user_review_merge.dart';

void main() {
  test('preserves corrected reviewed app-assisted line on reparse', () {
    final existing = ExpenseReceiptLineRecord(
      id: 'existing-line',
      description: 'Corrected PVC Glue',
      category: 'Materials',
      use: ExpenseLineUse.business,
      quantity: 1,
      unitsPerPackage: 1,
      unit: 'each',
      subtotal: 8.49,
      rawReceiptText: 'PVC GLUE',
      parserReviewLabel: 'Corrected',
      parserReviewReason:
          'User reviewed and corrected this app-filled receipt line.',
      parserNeedsReview: false,
      ocrSourceLineId: 'ocr_line_0007_materials',
      ocrSourceLineNumber: 7,
    );
    final parsed = ExpenseReceiptLineRecord(
      id: 'parsed-line',
      description: 'PVC Glue',
      category: 'Supplies',
      use: ExpenseLineUse.personal,
      quantity: 1,
      unitsPerPackage: 1,
      unit: 'each',
      subtotal: 7.99,
      rawReceiptText: 'PVC GLUE',
      parserConfidence: .93,
      parserReviewLabel: 'Review',
      parserReviewReason: 'Parser suggested this line.',
      parserNeedsReview: true,
      ocrSourceLineId: 'ocr_line_0007_materials',
      ocrSourceLineNumber: 7,
    );

    final merged = mergeParsedReceiptLinesWithReviewedLines(
      parsedLines: [parsed],
      existingLines: [existing],
    );

    expect(merged.single.description, 'Corrected PVC Glue');
    expect(merged.single.category, 'Materials');
    expect(merged.single.use, ExpenseLineUse.business);
    expect(merged.single.subtotal, 8.49);
    expect(merged.single.parserReviewLabel, 'Corrected');
  });

  test('preserves confirmed line matched by section and line numbers', () {
    final existing = ExpenseReceiptLineRecord(
      id: 'existing-line',
      description: 'Fuel',
      category: 'Fuel',
      use: ExpenseLineUse.split,
      quantity: 1,
      unitsPerPackage: 1,
      unit: 'gal',
      subtotal: 40,
      businessPercent: .75,
      rawReceiptText: 'FUEL 40.00',
      parserReviewLabel: 'Good',
      parserReviewReason: 'User confirmed this parsed receipt line.',
      parserNeedsReview: false,
      ocrSourceSectionNumber: 2,
      ocrSourceSectionLineNumber: 4,
    );
    final parsed = ExpenseReceiptLineRecord(
      id: 'parsed-line',
      description: 'Fuel purchase',
      category: 'Fuel',
      use: ExpenseLineUse.business,
      quantity: 1,
      unitsPerPackage: 1,
      unit: 'gal',
      subtotal: 39.12,
      rawReceiptText: 'FUEL 39.12',
      parserConfidence: .9,
      parserNeedsReview: true,
      ocrSourceSectionNumber: 2,
      ocrSourceSectionLineNumber: 4,
    );

    final merged = mergeParsedReceiptLinesWithReviewedLines(
      parsedLines: [parsed],
      existingLines: [existing],
    );

    expect(merged.single.use, ExpenseLineUse.split);
    expect(merged.single.businessPercent, .75);
    expect(
      merged.single.parserReviewReason,
      'User confirmed this parsed receipt line.',
    );
  });

  test(
    'keeps fresh parsed line when existing app-assisted line was not reviewed',
    () {
      final existing = ExpenseReceiptLineRecord(
        id: 'existing-line',
        description: 'Old guess',
        category: 'Supplies',
        use: ExpenseLineUse.business,
        quantity: 1,
        unitsPerPackage: 1,
        unit: 'each',
        subtotal: 9.99,
        rawReceiptText: 'OLD GUESS',
        parserConfidence: .91,
        parserReviewLabel: 'Review',
        parserReviewReason: 'Parser suggested this line.',
        parserNeedsReview: true,
        ocrSourceLineId: 'ocr_line_0009_supplies',
        ocrSourceLineNumber: 9,
      );
      final parsed = ExpenseReceiptLineRecord(
        id: 'parsed-line',
        description: 'New parser line',
        category: 'Materials',
        use: ExpenseLineUse.business,
        quantity: 1,
        unitsPerPackage: 1,
        unit: 'each',
        subtotal: 10.49,
        rawReceiptText: 'NEW PARSER LINE',
        parserConfidence: .94,
        parserReviewLabel: 'Review',
        parserReviewReason: 'Parser suggested this line.',
        parserNeedsReview: true,
        ocrSourceLineId: 'ocr_line_0009_supplies',
        ocrSourceLineNumber: 9,
      );

      final merged = mergeParsedReceiptLinesWithReviewedLines(
        parsedLines: [parsed],
        existingLines: [existing],
      );

      expect(merged.single.description, 'New parser line');
      expect(merged.single.category, 'Materials');
      expect(merged.single.subtotal, 10.49);
    },
  );
}
