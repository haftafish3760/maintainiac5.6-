import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';

void main() {
  test('receipt lines can be allocation-only without item descriptions', () {
    const business = ExpenseReceiptLineRecord(
      id: 'line-business',
      description: '',
      category: 'Uncategorized',
      use: ExpenseLineUse.business,
      quantity: 1,
      unitsPerPackage: 1,
      unit: 'each',
      subtotal: 42,
    );
    const personal = ExpenseReceiptLineRecord(
      id: 'line-personal',
      description: 'Receipt item',
      category: 'Uncategorized',
      use: ExpenseLineUse.personal,
      quantity: 1,
      unitsPerPackage: 1,
      unit: 'each',
      subtotal: 18,
    );
    const split = ExpenseReceiptLineRecord(
      id: 'line-split',
      description: 'Split receipt items',
      category: 'Uncategorized',
      use: ExpenseLineUse.split,
      businessPercent: .65,
      quantity: 1,
      unitsPerPackage: 1,
      unit: 'each',
      subtotal: 100,
    );

    expect(business.displayDescription, 'Business receipt items');
    expect(personal.displayDescription, 'Personal receipt items');
    expect(split.displayDescription, 'Split receipt items');
    expect(business.isAllocationOnlyLine, isTrue);
    expect(personal.isAllocationOnlyLine, isTrue);
    expect(split.businessAmount, 65);
    expect(split.personalAmount, 35);
  });

  test('receipt line catalog metadata round trips with stored maps', () {
    const line = ExpenseReceiptLineRecord(
      id: 'line-catalog',
      description: '20A GFCI RECEPTACLE',
      category: 'Materials',
      use: ExpenseLineUse.business,
      quantity: 1,
      unitsPerPackage: 1,
      unit: 'each',
      subtotal: 18.49,
      rawReceiptText: 'LOWES 20A GFCI RECEPT 18.49',
      catalogItemId: 'MI-555',
      catalogItemName: '20 Amp GFCI Outlet',
      catalogItemPath: 'Electrical / Devices / Receptacles / GFCI',
      catalogMatchConfidence: .91,
      catalogMatchedTerms: ['20', 'amp', 'gfci'],
      parserConfidence: .91,
      parserReviewLabel: 'Good',
      parserReviewReason: 'Inventory catalog match found.',
      parserNeedsReview: false,
    );

    final restored = ExpenseReceiptLineRecord.fromMap(line.toMap());

    expect(restored.hasCatalogMatch, isTrue);
    expect(restored.catalogItemId, 'MI-555');
    expect(restored.catalogItemName, '20 Amp GFCI Outlet');
    expect(restored.catalogMatchedTerms, ['20', 'amp', 'gfci']);
    expect(restored.rawReceiptText, 'LOWES 20A GFCI RECEPT 18.49');
    expect(restored.receiptEvidenceText, 'LOWES 20A GFCI RECEPT 18.49');
    expect(restored.hasParserReview, isTrue);
    expect(restored.parserReviewLabelText, 'Good');
    expect(restored.parserReviewActionText, 'Looks matched');
    expect(restored.isAllocationOnlyLine, isFalse);
  });

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
}
