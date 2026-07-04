import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/receipts/receipt_line_models.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';

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

  test('receipt line allocation normalizes unsafe split values', () {
    const paddedSplit = ReceiptLineDraft(
      kind: ReceiptLineKind.expense,
      description: '',
      businessUse: ' SPLIT ',
      businessPercent: 1.4,
      proofLineReferenceLabel: 'Line 7',
    );
    const malformedSplit = ReceiptLineDraft(
      kind: ReceiptLineKind.expense,
      description: '',
      businessUse: 'split',
      businessPercent: double.nan,
      proofLineReferenceLabel: 'Line 8',
    );
    const paddedPersonal = ReceiptLineDraft(
      kind: ReceiptLineKind.expense,
      description: '',
      businessUse: ' personal ',
      businessPercent: .9,
    );

    expect(paddedSplit.isSplitUse, isTrue);
    expect(paddedSplit.businessUseLabel, 'Split 100% business');
    expect(paddedSplit.effectiveBusinessPercent, 1);
    expect(paddedSplit.effectivePersonalPercent, 0);
    expect(malformedSplit.businessUseLabel, 'Split 50% business');
    expect(malformedSplit.effectiveBusinessPercent, .5);
    expect(malformedSplit.effectivePersonalPercent, .5);
    expect(paddedPersonal.isPersonalUse, isTrue);
    expect(paddedPersonal.effectiveBusinessPercent, 0);

    final safe = malformedSplit.privacySafeProofReference;
    expect(safe['businessUse'], 'split');
    expect(safe['businessPercent'], .5);
    expect(safe['personalPercent'], .5);
    expect(safe.toString(), isNot(contains('NaN')));

    final selected = ReceiptSelectedLineReference.fromDraft(
      receiptId: 'receipt-1',
      line: paddedSplit,
    );
    expect(selected.businessUse, 'split');
    expect(selected.businessPercent, 1);
    expect(selected.personalPercent, 0);
    expect(selected.toLocalMap()['sourceReceiptSectionLabel'], isNull);
    expect(selected.toPrivacySafeMap()['businessPercent'], 1);
    expect(selected.toPrivacySafeMap()['personalPercent'], 0);
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

  test('receipt line exposes privacy-safe client proof reference', () {
    const line = ReceiptLineDraft(
      kind: ReceiptLineKind.inventory,
      description: 'Private job material',
      receiptLineId: 'RCP-44-L3',
      subtotal: 19.99,
      businessUse: 'split',
      rawReceiptText: 'LOWES PRIVATE JOB MATERIAL 19.99',
      proofLineReferenceLabel: 'Line 3',
      clientProofDefaultVisibility:
          ReceiptLineClientProofVisibility.reviewBeforeClientShare,
      sourceReceiptSectionLabel: 'Photo receipt RCP-44',
      parserNeedsReview: true,
    );

    expect(line.proofReferenceLabel, 'Line 3');
    expect(line.needsClientProofReview, isTrue);
    expect(line.redactsFromClientProofByDefault, isFalse);
    expect(line.clientProofReviewLabel, 'Review before sharing');

    final safe = line.privacySafeProofReference;
    expect(safe['receiptLineId'], 'RCP-44-L3');
    expect(safe['proofLineReferenceLabel'], 'Line 3');
    expect(
      safe['clientProofDefaultVisibility'],
      ReceiptLineClientProofVisibility.reviewBeforeClientShare,
    );
    expect(safe['sourceReceiptSectionLabel'], 'source_section');
    expect(safe['hasAmount'], isTrue);
    expect(safe['needsParserReview'], isTrue);
    expect(safe.toString(), isNot(contains('LOWES')));
    expect(safe.toString(), isNot(contains('Private job material')));
    expect(safe.toString(), isNot(contains('19.99')));

    final map = line.toMap();
    expect(map['proofLineReferenceLabel'], 'Line 3');
    expect(
      map['clientProofDefaultVisibility'],
      ReceiptLineClientProofVisibility.reviewBeforeClientShare,
    );
    expect(map['privacySafeProofReference'], safe);
  });

  test('receipt line copy and map preserve client proof fields', () {
    const line = ReceiptLineDraft(
      kind: ReceiptLineKind.expense,
      description: 'Job lunch split',
      receiptLineId: 'RCP-55-L2',
      businessUse: 'split',
      proofLineReferenceLabel: 'Line 2',
      clientProofDefaultVisibility:
          ReceiptLineClientProofVisibility.redactByDefault,
      sourceReceiptSectionLabel: 'Photo 2 bottom',
      parserNeedsReview: true,
    );

    final copied = line.copyWith(
      description: 'Corrected job lunch split',
      clientProofDefaultVisibility:
          ReceiptLineClientProofVisibility.reviewBeforeClientShare,
    );

    expect(copied.receiptLineId, 'RCP-55-L2');
    expect(copied.proofLineReferenceLabel, 'Line 2');
    expect(
      copied.clientProofDefaultVisibility,
      ReceiptLineClientProofVisibility.reviewBeforeClientShare,
    );
    expect(copied.sourceReceiptSectionLabel, 'Photo 2 bottom');
    expect(
      copied.privacySafeProofReference['sourceReceiptSectionLabel'],
      'source_section',
    );
    expect(copied.toMap()['proofLineReferenceLabel'], 'Line 2');
    expect(
      copied.toMap()['clientProofDefaultVisibility'],
      ReceiptLineClientProofVisibility.reviewBeforeClientShare,
    );
    expect(copied.toMap()['sourceReceiptSectionLabel'], 'Photo 2 bottom');
  });

  test('multi receipt selection bundle stays privacy safe for job proof', () {
    const mondayLines = [
      ReceiptLineDraft(
        kind: ReceiptLineKind.inventory,
        description: 'Private plumbing part',
        receiptLineId: 'LOWES-MON-L1',
        subtotal: 12,
        taxRate: .08,
        rawReceiptText: 'LOWES PRIVATE PLUMBING PART 12.00',
        proofLineReferenceLabel: 'Line 1',
        clientProofDefaultVisibility:
            ReceiptLineClientProofVisibility.reviewBeforeClientShare,
        sourceReceiptSectionLabel: 'Lowe receipt Monday photo 1',
      ),
      ReceiptLineDraft(
        kind: ReceiptLineKind.expense,
        description: 'Personal soda',
        receiptLineId: 'LOWES-MON-L2',
        subtotal: 2,
        rawReceiptText: 'PERSONAL SODA 2.00',
        clientProofDefaultVisibility:
            ReceiptLineClientProofVisibility.redactByDefault,
        sourceReceiptSectionLabel: 'Lowe receipt Monday photo 1',
      ),
    ];
    const wednesdayLines = [
      ReceiptLineDraft(
        kind: ReceiptLineKind.inventory,
        description: 'Private pipe strap',
        receiptLineId: 'HD-WED-L1',
        subtotal: 8,
        taxRate: .08,
        rawReceiptText: 'HOME DEPOT PRIVATE PIPE STRAP 8.00',
        proofLineReferenceLabel: 'Line 1',
        clientProofDefaultVisibility:
            ReceiptLineClientProofVisibility.reviewBeforeClientShare,
        sourceReceiptSectionLabel: 'Home Depot receipt Wednesday photo 1',
      ),
    ];

    final mondayBundle = ReceiptLineSelectionBundle.fromDrafts(
      receiptId: 'receipt-lowes-monday',
      purpose: ReceiptLineSelectionPurpose.job,
      sourceLines: mondayLines,
      includeLine: (line) => line.isInventory,
    );
    final wednesdayBundle = ReceiptLineSelectionBundle.fromDrafts(
      receiptId: 'receipt-home-depot-wednesday',
      purpose: ReceiptLineSelectionPurpose.job,
      sourceLines: wednesdayLines,
    );
    final multiReceiptBundle = ReceiptMultiReceiptSelectionBundle(
      purpose: ReceiptLineSelectionPurpose.job,
      receiptBundles: [mondayBundle, wednesdayBundle],
    );

    expect(multiReceiptBundle.receiptCount, 2);
    expect(multiReceiptBundle.hasMultipleReceipts, isTrue);
    expect(multiReceiptBundle.selectedLineCount, 2);
    expect(multiReceiptBundle.totalSourceLineCount, 3);
    expect(multiReceiptBundle.excludedLineCount, 1);
    expect(multiReceiptBundle.reviewBeforeShareCount, 2);
    expect(multiReceiptBundle.hasHiddenClientProofLines, isTrue);
    expect(multiReceiptBundle.selectedSubtotal, 20);
    expect(multiReceiptBundle.selectedTax, 1.6);
    expect(multiReceiptBundle.selectedTotal, 21.6);

    final safe = multiReceiptBundle.toPrivacySafeMap();
    expect(safe['schema'], 'receipt_multi_receipt_selection_v1');
    expect(safe['purpose'], 'job');
    expect(safe['receiptIds'], [
      'receipt-lowes-monday',
      'receipt-home-depot-wednesday',
    ]);
    expect(safe['hasMultipleReceipts'], isTrue);
    expect(safe['selectedLineCount'], 2);
    expect(safe['excludedLineCount'], 1);
    expect(safe['needsClientProofReview'], isTrue);
    expect(safe['hasHiddenClientProofLines'], isTrue);
    expect(safe.toString(), isNot(contains('Private plumbing part')));
    expect(safe.toString(), isNot(contains('Private pipe strap')));
    expect(safe.toString(), isNot(contains('PERSONAL SODA')));
    expect(safe.toString(), isNot(contains('12.00')));
    expect(safe.toString(), contains('LOWES-MON-L1'));
    expect(safe.toString(), contains('HD-WED-L1'));

    final local = mondayBundle.toLocalMap();
    expect(local.toString(), isNot(contains('Lowe receipt Monday')));
    expect(local.toString(), contains('source_section'));
  });

  test('selected line local map bounds receipt section labels', () {
    const line = ReceiptLineDraft(
      kind: ReceiptLineKind.inventory,
      description: 'Private job part',
      receiptLineId: 'JOB-LINE-1',
      proofLineReferenceLabel: 'Line 4',
      sourceReceiptSectionLabel: 'Home Depot private job receipt Monday',
    );

    final selected = ReceiptSelectedLineReference.fromDraft(
      receiptId: 'receipt-job-1',
      line: line,
    );

    expect(
      selected.toLocalMap()['sourceReceiptSectionLabel'],
      'source_section',
    );
    expect(selected.toLocalMap().toString(), isNot(contains('Home Depot')));
    expect(
      selected.toPrivacySafeMap()['sourceReceiptSectionLabel'],
      'source_section',
    );
  });
}
