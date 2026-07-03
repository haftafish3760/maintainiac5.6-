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
    expect(business.receiptReviewModeCode, 'priceOnly');
    expect(personal.receiptReviewModeLabel, 'Price only');
    expect(split.businessUseReviewLabel, 'Split 65% business');
    expect(split.businessAmount, 65);
    expect(split.personalAmount, 35);
  });

  test('split receipt lines bound malformed business percentages', () {
    const overAllocated = ExpenseReceiptLineRecord(
      id: 'line-over',
      description: 'Split receipt items',
      category: 'Uncategorized',
      use: ExpenseLineUse.split,
      businessPercent: 1.4,
      quantity: 1,
      unitsPerPackage: 1,
      unit: 'each',
      subtotal: 100,
    );
    const underAllocated = ExpenseReceiptLineRecord(
      id: 'line-under',
      description: 'Split receipt items',
      category: 'Uncategorized',
      use: ExpenseLineUse.split,
      businessPercent: -.2,
      quantity: 1,
      unitsPerPackage: 1,
      unit: 'each',
      subtotal: 100,
    );

    expect(overAllocated.businessUseReviewLabel, 'Split 100% business');
    expect(overAllocated.businessAmount, 100);
    expect(overAllocated.personalAmount, 0);
    expect(overAllocated.toMap()['businessPercent'], 1);
    expect(underAllocated.businessUseReviewLabel, 'Split 0% business');
    expect(underAllocated.businessAmount, 0);
    expect(underAllocated.personalAmount, 100);
    expect(underAllocated.toMap()['businessPercent'], 0);
  });

  test(
    'receipt lines expose numbered price-only and detailed review contracts',
    () {
      const priceOnly = ExpenseReceiptLineRecord(
        id: 'line-price-only',
        description: '',
        category: 'Uncategorized',
        use: ExpenseLineUse.split,
        businessPercent: .4,
        quantity: 1,
        unitsPerPackage: 1,
        unit: 'each',
        subtotal: 30,
        ocrSourceLineNumber: 7,
      );
      const detailed = ExpenseReceiptLineRecord(
        id: 'line-detailed',
        description: '1/2 GAL MILK',
        category: 'Meals',
        use: ExpenseLineUse.personal,
        quantity: 1,
        unitsPerPackage: 1,
        unit: 'each',
        subtotal: 4.25,
        rawReceiptText: '1/2 GAL MILK 4.25',
        ocrSourceSectionNumber: 2,
        ocrSourceSectionLineNumber: 4,
      );

      expect(priceOnly.receiptLineNumberLabel, 'Line 7');
      expect(priceOnly.receiptReviewModeCode, 'priceOnly');
      expect(
        priceOnly.receiptLineReviewSummary,
        'Line 7: price only, Split 40% business',
      );
      expect(priceOnly.privacySafeLineReviewContract['hasDetailText'], isFalse);
      expect(
        priceOnly.privacySafeLineReviewContract.toString(),
        isNot(contains('GAL MILK')),
      );

      expect(detailed.receiptLineNumberLabel, 'Section 2 line 4');
      expect(detailed.receiptReviewModeCode, 'detailedLine');
      expect(
        detailed.receiptLineReviewSummary,
        'Section 2 line 4: detailed line, Personal',
      );
      expect(detailed.privacySafeLineReviewContract['hasDetailText'], isTrue);
      expect(
        detailed.privacySafeLineReviewContract.toString(),
        isNot(contains('1/2 GAL MILK')),
      );
      expect(detailed.toMap()['receiptReviewMode'], 'detailedLine');
      expect(detailed.toMap()['businessUseReviewLabel'], 'Personal');
    },
  );

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
      ocrSourceLineId: 'ocr_line_002_item',
      ocrSourceLineNumber: 3,
      ocrSourceSectionNumber: 2,
      ocrSourceSectionLineNumber: 4,
      parserExpenseFamily: 'materials',
      parserHint: 'materials_item_price',
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
    expect(restored.hasOcrSourceLine, isTrue);
    expect(restored.ocrSourceLineId, 'ocr_line_002_item');
    expect(restored.ocrSourceLineNumber, 3);
    expect(restored.ocrSourceSectionNumber, 2);
    expect(restored.ocrSourceSectionLineNumber, 4);
    expect(restored.ocrSourceLineLabel, 'OCR section 2 line 4');
    expect(restored.receiptLineNumberLabel, 'Section 2 line 4');
    expect(restored.receiptReviewModeCode, 'detailedLine');
    expect(restored.businessUseReviewLabel, 'Business');
    expect(restored.receiptProofLineReferenceLabel, 'Section 2 line 4');
    expect(
      restored.receiptProofRedactionAnchorCode,
      'receipt_line_s02_l0004_materials_business',
    );
    expect(restored.clientProofDefaultVisibility, 'review_for_client_proof');
    expect(restored.clientProofReviewLabel, 'Review for client proof');
    expect(
      restored.privacySafeProofReference['lineId'],
      'receipt_line_s02_l0004_materials_business',
    );
    expect(
      restored.privacySafeProofReference['redactionAnchorCode'],
      'receipt_line_s02_l0004_materials_business',
    );
    expect(restored.privacySafeProofReference['ocrSourceLineNumber'], 3);
    expect(restored.privacySafeProofReference['ocrSourceSectionNumber'], 2);
    expect(restored.privacySafeProofReference['ocrSourceSectionLineNumber'], 4);
    expect(restored.privacySafeProofReference['hasOcrSourceLine'], isTrue);
    expect(
      restored.privacySafeProofReference.toString(),
      isNot(contains('LOWES')),
    );
    expect(
      restored.toMap()['receiptProofRedactionAnchorCode'],
      'receipt_line_s02_l0004_materials_business',
    );
    expect(
      restored.toMap()['receiptLineReviewSummary'],
      contains('detailed line'),
    );
    expect(restored.hasParserClassification, isTrue);
    expect(restored.parserExpenseFamily, 'materials');
    expect(restored.parserHint, 'materials_item_price');
    expect(restored.parserExpenseFamilyLabel, 'Materials');
    expect(restored.parserHintLabel, 'Materials Item Price');
    expect(
      restored.parserClassificationLabel,
      'Materials | Materials Item Price',
    );
    expect(restored.isAllocationOnlyLine, isFalse);
  });

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
