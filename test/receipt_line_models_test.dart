import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/receipts/receipt_line_models.dart';

void main() {
  test('inventory receipt line calculates units, tax, and unit cost', () {
    const line = ReceiptLineDraft(
      kind: ReceiptLineKind.inventory,
      description: 'Fence screws',
      receiptLineId: 'RCP-44-L1',
      inventoryItemId: 'MI-123',
      inventoryPath: 'Fencing / Fasteners and Accessories / Fasteners',
      quantity: 2,
      unitsPerPackage: 50,
      purchaseType: 'box',
      unit: 'each',
      subtotal: 20,
      taxRate: .05,
      storageArea: 'Work Truck 1 inventory',
      storageDetail: 'Left drawer 2',
      businessUse: 'split',
      businessPercent: .6,
    );

    expect(line.isInventory, isTrue);
    expect(line.totalUnits, 100);
    expect(line.taxAmount, 1);
    expect(line.totalWithTax, 21);
    expect(line.unitCostWithTax, .21);
    expect(line.toMap()['inventoryPath'], contains('Fencing'));
    expect(line.toMap()['receiptLineId'], 'RCP-44-L1');
    expect(line.toMap()['storageDetail'], 'Left drawer 2');
    expect(line.toMap()['businessUse'], 'split');
    expect(line.toMap()['businessPercent'], .6);
  });

  test('expense receipt line carries expense category', () {
    const line = ReceiptLineDraft(
      kind: ReceiptLineKind.expense,
      description: 'Delivery fee',
      expenseCategory: 'Postage',
      subtotal: 9.5,
    );

    expect(line.isExpense, isTrue);
    expect(line.inventoryItemId, isEmpty);
    expect(line.toMap()['expenseCategory'], 'Postage');
  });

  test('receipt line labels separate inventory from business-only lines', () {
    const inventoryLine = ReceiptLineDraft(
      kind: ReceiptLineKind.inventory,
      description: '1/2 in copper elbow',
    );
    const businessLine = ReceiptLineDraft(
      kind: ReceiptLineKind.expense,
      description: '',
      businessUse: 'business',
    );

    expect(inventoryLine.receiptLaneLabel, 'Inventory');
    expect(inventoryLine.businessUseLabel, 'Business');
    expect(inventoryLine.displayDescription, '1/2 in copper elbow');
    expect(businessLine.receiptLaneLabel, 'Business expense only');
    expect(businessLine.displayDescription, 'Business receipt item');
  });

  test('receipt line labels make personal and split allocation clear', () {
    const personalLine = ReceiptLineDraft(
      kind: ReceiptLineKind.expense,
      description: '',
      businessUse: 'personal',
      businessPercent: 0,
    );
    const splitLine = ReceiptLineDraft(
      kind: ReceiptLineKind.expense,
      description: '',
      businessUse: 'split',
      businessPercent: .65,
    );

    expect(personalLine.receiptLaneLabel, 'Personal');
    expect(personalLine.businessUseLabel, 'Personal');
    expect(personalLine.displayDescription, 'Personal receipt item');
    expect(splitLine.receiptLaneLabel, 'Split business/personal');
    expect(splitLine.businessUseLabel, 'Split 65% business');
    expect(splitLine.displayDescription, 'Split business/personal item');
    expect(personalLine.reviewStatusLabel, 'Manual');
    expect(
      personalLine.receiptReviewSummary,
      'Saved on the receipt as personal, not inventory.',
    );
    expect(
      splitLine.receiptReviewSummary,
      'Saved on the receipt as split business/personal.',
    );
  });

  test('assisted receipt review evidence stays with receipt draft lines', () {
    const line = ReceiptLineDraft(
      kind: ReceiptLineKind.inventory,
      description: '1/2 in copper 90',
      rawReceiptText: '1/2 COP 90 ELL',
      catalogMatchConfidence: .92,
      catalogMatchedTerms: ['1/2', 'cop', '90'],
      parserConfidence: .86,
      parserReviewLabel: 'Good',
      parserReviewReason: 'Catalog match found from receipt abbreviation.',
      parserNeedsReview: false,
    );

    expect(line.hasAssistedReview, isTrue);
    expect(line.assistedReviewLabel, 'Good');
    expect(line.reviewState, ReceiptLineReviewState.parsed);
    expect(line.canConfirmAssistedReview, isTrue);
    expect(line.requiresInventoryConfirmation, isTrue);
    expect(line.reviewStatusLabel, 'Needs confirmation');
    expect(
      line.receiptReviewSummary,
      'Inventory match must be confirmed before stock updates.',
    );
    expect(
      line.assistedReviewDetail,
      'Catalog match found from receipt abbreviation.',
    );
    expect(line.catalogMatchLabel, 'Catalog 92%');
    expect(line.toMap()['rawReceiptText'], '1/2 COP 90 ELL');
    expect(line.toMap()['catalogMatchedTerms'], ['1/2', 'cop', '90']);
  });

  test('confirmed assisted review clears review state but keeps evidence', () {
    const line = ReceiptLineDraft(
      kind: ReceiptLineKind.inventory,
      description: '1/2 in copper 90',
      inventoryItemId: 'MI-003',
      rawReceiptText: 'HALF COP ELL 90',
      catalogMatchConfidence: .77,
      catalogMatchedTerms: ['half', 'cop', '90'],
      parserConfidence: .62,
      parserReviewLabel: 'Review',
      parserReviewReason: 'Review this line before saving.',
      parserNeedsReview: true,
      originalParsedDescription: '3/4 in copper 90',
      originalParsedInventoryItemId: 'MI-999',
      originalParsedInventoryPath: 'Plumbing / Fittings',
      reviewAction: 'parsed',
    );

    final confirmed = line.confirmedAssistedReview();

    expect(confirmed.canConfirmAssistedReview, isFalse);
    expect(confirmed.reviewState, ReceiptLineReviewState.confirmed);
    expect(confirmed.requiresInventoryConfirmation, isFalse);
    expect(confirmed.reviewStatusLabel, 'Confirmed');
    expect(
      confirmed.receiptReviewSummary,
      'Inventory match confirmed for stock update.',
    );
    expect(confirmed.parserNeedsReview, isFalse);
    expect(confirmed.parserReviewLabel, 'Good');
    expect(confirmed.parserConfidence, .84);
    expect(confirmed.reviewAction, 'confirmed');
    expect(confirmed.rawReceiptText, 'HALF COP ELL 90');
    expect(confirmed.catalogMatchedTerms, ['half', 'cop', '90']);
  });

  test('receipt line audit detects user correction from parser guess', () {
    const line = ReceiptLineDraft(
      kind: ReceiptLineKind.inventory,
      description: '1/2 in copper 90',
      inventoryItemId: 'MI-003',
      originalParsedDescription: '3/4 in copper 90',
      originalParsedInventoryItemId: 'MI-999',
      originalParsedInventoryPath: 'Plumbing / Fittings / Copper',
      reviewAction: 'edited',
    );

    expect(line.hasCorrectionAudit, isTrue);
    expect(line.reviewState, ReceiptLineReviewState.corrected);
    expect(line.wasChangedFromParsedGuess, isTrue);
    expect(line.reviewActionLabel, 'Corrected');
    expect(line.toMap()['originalParsedInventoryItemId'], 'MI-999');
    expect(line.toMap()['reviewAction'], 'edited');
  });
}
