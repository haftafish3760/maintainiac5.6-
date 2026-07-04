import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';

void main() {
  test(
    'privacy-safe receipt line contracts never expose generated item ids',
    () {
      const line = ExpenseReceiptLineRecord(
        id: 'line_8_Private family medicine',
        description: 'Private family medicine',
        category: 'Personal',
        use: ExpenseLineUse.personal,
        quantity: 1,
        unitsPerPackage: 1,
        unit: 'each',
        subtotal: 12,
        ocrSourceLineNumber: 8,
      );

      expect(
        line.privacySafeLineReviewContract['lineId'],
        'receipt_line_l0008_personal_personal',
      );
      expect(
        line.privacySafeProofReference['lineId'],
        'receipt_line_l0008_personal_personal',
      );
      expect(line.toMap()['id'], 'line_8_Private family medicine');
      expect(
        line.privacySafeLineReviewContract.toString(),
        isNot(contains('Private family medicine')),
      );
      expect(
        line.privacySafeProofReference.toString(),
        isNot(contains('Private family medicine')),
      );

      const manualLine = ExpenseReceiptLineRecord(
        id: 'line_12_Private family medicine',
        description: 'Private family medicine',
        category: 'Personal',
        use: ExpenseLineUse.personal,
        quantity: 1,
        unitsPerPackage: 1,
        unit: 'each',
        subtotal: 12,
      );

      expect(
        manualLine.receiptProofRedactionAnchorCode,
        startsWith('receipt_line_manual_'),
      );
      expect(
        manualLine.privacySafeLineReviewContract.toString(),
        isNot(contains('Private family medicine')),
      );
      expect(
        manualLine.privacySafeLineReviewContract.toString(),
        isNot(contains('line_12')),
      );
    },
  );

  test('receipt line parser action labels guide review work', () {
    const reviewLine = ExpenseReceiptLineRecord(
      id: 'line-review',
      description: 'Copper thing',
      category: 'Materials',
      use: ExpenseLineUse.business,
      quantity: 1,
      unitsPerPackage: 1,
      unit: 'each',
      subtotal: 7.48,
      rawReceiptText: 'HALF COP ELL 90',
      parserReviewLabel: 'Review',
      parserReviewReason: 'Parser needs confirmation.',
      parserNeedsReview: true,
    );
    const poorLine = ExpenseReceiptLineRecord(
      id: 'line-poor',
      description: 'Receipt item',
      category: 'Uncategorized',
      use: ExpenseLineUse.business,
      quantity: 1,
      unitsPerPackage: 1,
      unit: 'each',
      subtotal: 4,
      parserConfidence: .2,
    );
    const manualLine = ExpenseReceiptLineRecord(
      id: 'line-manual',
      description: 'Manual entry',
      category: 'Supplies',
      use: ExpenseLineUse.business,
      quantity: 1,
      unitsPerPackage: 1,
      unit: 'each',
      subtotal: 4,
    );

    expect(reviewLine.receiptEvidenceText, 'HALF COP ELL 90');
    expect(reviewLine.parserReviewActionText, 'Review before saving');
    expect(poorLine.parserReviewActionText, 'Needs correction');
    expect(manualLine.parserReviewActionText, 'Manual line');
  });

  test('receipt proof visibility protects personal and review lines', () {
    const personalLine = ExpenseReceiptLineRecord(
      id: 'line-personal',
      description: 'Family snack',
      category: 'Personal',
      use: ExpenseLineUse.personal,
      quantity: 1,
      unitsPerPackage: 1,
      unit: 'each',
      subtotal: 5,
      ocrSourceLineNumber: 9,
    );
    const reviewLine = ExpenseReceiptLineRecord(
      id: 'line-review',
      description: 'Unknown item',
      category: 'Uncategorized',
      use: ExpenseLineUse.business,
      quantity: 1,
      unitsPerPackage: 1,
      unit: 'each',
      subtotal: 7,
      parserNeedsReview: true,
      ocrSourceLineId: 'ocr_line_010_item',
    );

    expect(personalLine.clientProofDefaultVisibility, 'redact_by_default');
    expect(personalLine.redactsFromClientProofByDefault, isTrue);
    expect(personalLine.clientProofReviewLabel, 'Hidden from client proof');
    expect(
      personalLine.receiptProofRedactionAnchorCode,
      'receipt_line_l0009_personal_personal',
    );
    expect(
      personalLine.privacySafeProofReference.toString(),
      isNot(contains('Family snack')),
    );

    expect(
      reviewLine.clientProofDefaultVisibility,
      'review_before_client_share',
    );
    expect(reviewLine.needsClientProofReview, isTrue);
    expect(reviewLine.clientProofReviewLabel, 'Review before sharing');
    expect(
      reviewLine.receiptProofRedactionAnchorCode,
      'receipt_line_ocr_line_010_item_uncategorized_business',
    );
  });
}
