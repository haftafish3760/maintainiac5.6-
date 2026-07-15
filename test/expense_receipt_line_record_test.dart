import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';

void main() {
  test(
    'receipt evidence preserves source, display, normalization, and interpretation separately',
    () {
      const line = ExpenseReceiptLineRecord(
        id: 'faithful-line',
        description: 'Edited display label',
        displayReceiptText: 'Edited display label',
        sourceReceiptText: 'BLK NTR GLV XL',
        normalizedReceiptText: 'blk ntr glv xl',
        receiptInterpretation: 'work gloves candidate',
        category: 'Uncategorized',
        use: ExpenseLineUse.unclassified,
        quantity: 1,
        unitsPerPackage: 1,
        unit: 'each',
        subtotal: 8.49,
      );

      expect(line.receiptSourceText, 'BLK NTR GLV XL');
      expect(line.receiptEvidenceText, 'BLK NTR GLV XL');
      expect(line.receiptDisplayText, 'Edited display label');
      expect(line.displayDescription, 'Edited display label');
      expect(line.normalizedReceiptText, 'blk ntr glv xl');
      expect(line.receiptInterpretation, 'work gloves candidate');
      expect(line.use, ExpenseLineUse.unclassified);
      expect(line.businessAmount, 0);

      final restored = ExpenseReceiptLineRecord.fromMap(line.toMap());
      expect(restored.receiptSourceText, 'BLK NTR GLV XL');
      expect(restored.receiptDisplayText, 'Edited display label');
      expect(restored.normalizedReceiptText, 'blk ntr glv xl');
      expect(restored.receiptInterpretation, 'work gloves candidate');
    },
  );

  test(
    'unknown ownership is preserved as unclassified with no allocated total',
    () {
      final line = ExpenseReceiptLineRecord.fromMap({
        'id': 'line-unclassified',
        'description': 'HDWR',
        'category': 'Uncategorized',
        'use': 'unknown legacy parser signal',
        'subtotal': 42,
      });

      expect(line.use, ExpenseLineUse.unclassified);
      expect(line.displayDescription, 'HDWR');
      expect(line.businessUseReviewLabel, 'Needs classification');
      expect(line.businessAmount, 0);
      expect(line.personalAmount, 0);
      expect(line.toMap()['use'], 'unclassified');
    },
  );

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

  test('receipt line records reject non-finite numeric payloads', () {
    final restored = ExpenseReceiptLineRecord.fromMap({
      'id': 'line-nonfinite',
      'description': 'Receipt item',
      'category': 'Uncategorized',
      'use': 'split',
      'quantity': double.nan,
      'unitsPerPackage': double.infinity,
      'subtotal': double.negativeInfinity,
      'businessPercent': 'NaN',
      'odometerReading': double.infinity,
      'catalogMatchConfidence': 'Infinity',
      'parserConfidence': double.nan,
    });

    expect(restored.quantity, 1);
    expect(restored.unitsPerPackage, 1);
    expect(restored.subtotal, 0);
    expect(restored.businessPercent, isNull);
    expect(restored.effectiveBusinessPercent, .5);
    expect(restored.businessAmount, 0);
    expect(restored.personalAmount, 0);
    expect(restored.odometerReading, isNull);
    expect(restored.catalogMatchConfidence, isNull);
    expect(restored.parserConfidence, isNull);
    expect(restored.toMap().toString(), isNot(contains('NaN')));
    expect(restored.toMap().toString(), isNot(contains('Infinity')));
  });

  test('receipt line records trim stored business use names', () {
    final split = ExpenseReceiptLineRecord.fromMap({
      'id': 'line-split-padded',
      'description': 'Split receipt items',
      'category': 'Materials',
      'use': ' split ',
      'businessPercent': .25,
      'subtotal': 40,
      'ocrSourceLineNumber': 11,
    });
    final personal = ExpenseReceiptLineRecord.fromMap({
      'id': 'line-personal-padded',
      'description': 'Family snack',
      'category': 'Personal',
      'use': ' personal ',
      'subtotal': 9,
      'ocrSourceLineNumber': 12,
    });

    expect(split.use, ExpenseLineUse.split);
    expect(split.businessUseReviewLabel, 'Split 25% business');
    expect(split.businessAmount, 10);
    expect(split.personalAmount, 30);
    expect(split.receiptProofRedactionAnchorCode, endsWith('_materials_split'));
    expect(personal.use, ExpenseLineUse.personal);
    expect(personal.clientProofDefaultVisibility, 'redact_by_default');
    expect(personal.businessAmount, 0);
    expect(personal.personalAmount, 9);
  });

  test('receipt line records hydrate case-insensitive business use labels', () {
    final split = ExpenseReceiptLineRecord.fromMap({
      'id': 'line-split-label',
      'description': 'Split receipt items',
      'category': 'Materials',
      'use': ' Split ',
      'businessPercent': .75,
      'subtotal': 40,
    });
    final personal = ExpenseReceiptLineRecord.fromMap({
      'id': 'line-personal-upper',
      'description': 'Family snack',
      'category': 'Personal',
      'use': 'PERSONAL',
      'subtotal': 9,
    });
    final business = ExpenseReceiptLineRecord.fromMap({
      'id': 'line-business-label',
      'description': 'Shop towel',
      'category': 'Vehicle Supplies',
      'use': 'Business',
      'subtotal': 12,
    });

    expect(split.use, ExpenseLineUse.split);
    expect(split.businessUseReviewLabel, 'Split 75% business');
    expect(split.businessAmount, 30);
    expect(split.personalAmount, 10);
    expect(split.toMap()['use'], 'split');
    expect(personal.use, ExpenseLineUse.personal);
    expect(personal.clientProofDefaultVisibility, 'redact_by_default');
    expect(personal.businessAmount, 0);
    expect(personal.personalAmount, 9);
    expect(personal.toMap()['use'], 'personal');
    expect(business.use, ExpenseLineUse.business);
    expect(business.businessAmount, 12);
    expect(business.personalAmount, 0);
    expect(business.toMap()['use'], 'business');
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
      expect(priceOnly.privacySafeLineReviewContract['ocrSourceLineNumber'], 7);
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
        detailed.privacySafeLineReviewContract['ocrSourceSectionLineNumber'],
        4,
      );
      expect(
        detailed.privacySafeLineReviewContract.toString(),
        isNot(contains('1/2 GAL MILK')),
      );
      expect(detailed.toMap()['receiptReviewMode'], 'detailedLine');
      expect(detailed.toMap()['businessUseReviewLabel'], 'Personal');
    },
  );

  test(
    'receipt lines with raw OCR evidence stay detailed without leaking text',
    () {
      const ocrOnly = ExpenseReceiptLineRecord(
        id: 'line-ocr-only',
        description: 'Receipt item',
        category: 'Materials',
        use: ExpenseLineUse.business,
        quantity: 1,
        unitsPerPackage: 1,
        unit: 'each',
        subtotal: 18,
        rawReceiptText: 'PRIVATE HARDWARE ITEM 18.00',
        ocrSourceLineNumber: 9,
      );

      expect(ocrOnly.hasReceiptLineDetailEvidence, isTrue);
      expect(ocrOnly.isAllocationOnlyLine, isFalse);
      expect(ocrOnly.receiptReviewModeCode, 'detailedLine');
      expect(ocrOnly.privacySafeLineReviewContract['hasDetailText'], isTrue);
      expect(ocrOnly.receiptLineReviewSummary, contains('detailed line'));
      expect(
        ocrOnly.privacySafeLineReviewContract.toString(),
        isNot(contains('PRIVATE HARDWARE')),
      );
    },
  );

  test('receipt proof anchors reject malformed section numbers', () {
    const malformedSection = ExpenseReceiptLineRecord(
      id: 'line-malformed-section',
      description: 'Receipt item',
      category: 'Materials',
      use: ExpenseLineUse.business,
      quantity: 1,
      unitsPerPackage: 1,
      unit: 'each',
      subtotal: 8,
      ocrSourceSectionNumber: -3,
      ocrSourceSectionLineNumber: 4,
    );

    expect(malformedSection.receiptLineNumberLabel, 'Line 4');
    expect(
      malformedSection.receiptProofRedactionAnchorCode,
      'receipt_line_s01_l0004_materials_business',
    );
    expect(
      malformedSection.privacySafeProofReference['redactionAnchorCode'],
      'receipt_line_s01_l0004_materials_business',
    );
    expect(
      malformedSection.privacySafeLineReviewContract['ocrSourceSectionNumber'],
      1,
    );
    expect(
      malformedSection.privacySafeProofReference['ocrSourceSectionNumber'],
      1,
    );
    expect(malformedSection.toMap()['ocrSourceSectionNumber'], 1);
    expect(
      malformedSection.receiptProofRedactionAnchorCode,
      isNot(contains('-3')),
    );
    expect(malformedSection.toMap().toString(), isNot(contains('-3')));
  });

  test('receipt line maps drop malformed OCR source line numbers', () {
    const malformedLine = ExpenseReceiptLineRecord(
      id: 'line-malformed-source',
      description: 'Receipt item',
      category: 'Materials',
      use: ExpenseLineUse.business,
      quantity: 1,
      unitsPerPackage: 1,
      unit: 'each',
      subtotal: 8,
      ocrSourceLineNumber: -9,
      ocrSourceSectionNumber: 2,
      ocrSourceSectionLineNumber: 0,
    );

    expect(malformedLine.hasOcrSourceLine, isFalse);
    expect(malformedLine.receiptLineNumberLabel, 'Receipt line');
    expect(
      malformedLine.privacySafeLineReviewContract,
      isNot(containsPair('ocrSourceSectionNumber', 2)),
    );
    expect(
      malformedLine.privacySafeLineReviewContract,
      isNot(containsPair('ocrSourceSectionLineNumber', 0)),
    );
    expect(
      malformedLine.privacySafeProofReference,
      isNot(containsPair('ocrSourceLineNumber', -9)),
    );
    expect(malformedLine.toMap()['ocrSourceLineNumber'], isNull);
    expect(malformedLine.toMap()['ocrSourceSectionNumber'], isNull);
    expect(malformedLine.toMap()['ocrSourceSectionLineNumber'], isNull);
    expect(malformedLine.toMap().toString(), isNot(contains('-9')));
  });

  test('receipt line maps cap impossible OCR source row numbers', () {
    const hugeLine = ExpenseReceiptLineRecord(
      id: 'line-huge-source',
      description: 'Receipt item',
      category: 'General Expense',
      use: ExpenseLineUse.business,
      quantity: 1,
      unitsPerPackage: 1,
      unit: 'each',
      subtotal: 8,
      ocrSourceLineNumber: 1000000,
      ocrSourceSectionNumber: 2000,
      ocrSourceSectionLineNumber: 1000000,
    );

    expect(hugeLine.safeOcrSourceLineNumber, 9999);
    expect(hugeLine.safeOcrSourceSectionNumber, 999);
    expect(hugeLine.safeOcrSourceSectionLineNumber, 9999);
    expect(hugeLine.receiptLineNumberLabel, 'Section 999 line 9999');
    expect(
      hugeLine.receiptProofRedactionAnchorCode,
      'receipt_line_s999_l9999_general_expense_business',
    );
    expect(hugeLine.toMap()['ocrSourceLineNumber'], 9999);
    expect(hugeLine.toMap()['ocrSourceSectionNumber'], 999);
    expect(hugeLine.toMap()['ocrSourceSectionLineNumber'], 9999);
    expect(
      hugeLine.privacySafeLineReviewContract,
      containsPair('ocrSourceSectionLineNumber', 9999),
    );
    expect(hugeLine.toMap().toString(), isNot(contains('1000000')));
  });

  test('privacy-safe split contracts expose clamped percents', () {
    const overAllocated = ExpenseReceiptLineRecord(
      id: 'line-over-private-family',
      description: 'Private family receipt item',
      category: 'Personal',
      use: ExpenseLineUse.split,
      businessPercent: 1.8,
      quantity: 1,
      unitsPerPackage: 1,
      unit: 'each',
      subtotal: 30,
      ocrSourceLineNumber: 8,
    );

    expect(overAllocated.businessUseReviewLabel, 'Split 100% business');
    expect(overAllocated.privacySafeLineReviewContract['businessPercent'], 1);
    expect(overAllocated.privacySafeLineReviewContract['personalPercent'], 0);
    expect(overAllocated.privacySafeProofReference['businessPercent'], 1);
    expect(overAllocated.privacySafeProofReference['personalPercent'], 0);
    expect(
      overAllocated.privacySafeLineReviewContract.toString(),
      isNot(contains('Private family receipt item')),
    );
    expect(
      overAllocated.privacySafeProofReference.toString(),
      isNot(contains('Private family receipt item')),
    );
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
    expect(restored.ocrSourceLineLabel, 'Receipt section 2 line 4');
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
}
