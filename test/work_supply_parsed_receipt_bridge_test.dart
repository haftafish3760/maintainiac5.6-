import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_parsed_receipt_bridge.dart';
import 'package:maintaniac/shared/receipts/receipt_line_models.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';

void main() {
  test('mixed PEH quantities packages and tax preserve unit costs', () {
    final plumbing = workSupplyCatalogItems.firstWhere(
      (item) =>
          item.trade == 'Plumbing' && item.name.contains('Copper 90 Elbow'),
    );
    final electrical = workSupplyCatalogItems.firstWhere(
      (item) =>
          item.trade == 'Electrical' &&
          item.name.toLowerCase().contains('pvc electrical coupling'),
    );
    final hvac = workSupplyCatalogItems.firstWhere(
      (item) => item.trade == 'HVAC' && item.name.contains('Thermostat Wire'),
    );
    final parsed = ExpenseReceiptParseResult(
      sourceText: 'mixed PEH receipt',
      enteredSubtotal: 200,
      enteredTax: 16,
      lines: [
        _inventoryExpenseLine(
          'P1',
          plumbing.id,
          plumbing.name,
          plumbing.path,
          2,
          5,
          100,
        ),
        _inventoryExpenseLine(
          'E1',
          electrical.id,
          electrical.name,
          electrical.path,
          4,
          1,
          40,
        ),
        _inventoryExpenseLine('H1', hvac.id, hvac.name, hvac.path, 3, 2, 60),
      ],
    );

    final draft = buildWorkSupplyParsedReceiptDraft(
      parsed: parsed,
      receiptId: 'RCP-PEH-MATH',
      loggedAt: DateTime(2026, 7, 12),
      storageArea: 'Service vehicle',
      merchantName: 'Mixed Supply House',
    );

    expect(draft.inventoryRecords, hasLength(3));
    expect(draft.inventoryRecords.map((record) => record.item.trade), [
      'Plumbing',
      'Electrical',
      'HVAC',
    ]);
    expect(draft.inventoryRecords.map((record) => record.totalUnitsPurchased), [
      10,
      4,
      6,
    ]);
    for (final record in draft.inventoryRecords) {
      expect(record.taxRate, .08);
      expect(record.unitCostWithTax, closeTo(10.8, .000001));
      expect(record.sourceMerchantName, 'Mixed Supply House');
    }
  });

  test('catalog matched material receipt lines become inventory drafts', () {
    final copperElbow = workSupplyCatalogItems.firstWhere(
      (item) =>
          item.name.contains('Copper 90 Elbow') && item.variant.contains('1/2'),
    );
    final parsed = ExpenseReceiptParseResult(
      sourceText: 'LOWES 1/2 COPPER 90 12.00 SHOP TOWELS 4.00',
      merchantName: 'LOWES',
      enteredSubtotal: 16,
      enteredTax: 1.28,
      lineReviews: const [
        ExpenseReceiptLineReview(
          lineId: 'L1',
          confidence: .88,
          needsReview: false,
          reason: 'Catalog match found from receipt text.',
          catalogItemName: '1/2 in Copper 90 Elbow',
          catalogItemPath: 'Plumbing / Fittings / Copper / 90 Elbows',
          catalogMatchConfidence: .91,
          catalogMatchedTerms: ['1/2', 'copper', '90'],
        ),
        ExpenseReceiptLineReview(
          lineId: 'L2',
          confidence: .67,
          needsReview: true,
          reason: 'No inventory catalog match was found.',
        ),
      ],
      lines: [
        ExpenseReceiptLineRecord(
          id: 'L1',
          description: '1/2 COPPER 90',
          category: 'Materials',
          use: ExpenseLineUse.business,
          quantity: 2,
          unitsPerPackage: 1,
          unit: 'each',
          subtotal: 12,
          catalogItemId: copperElbow.id,
          catalogItemName: copperElbow.name,
          catalogItemPath: copperElbow.path,
          catalogMatchConfidence: .91,
        ),
        const ExpenseReceiptLineRecord(
          id: 'L2',
          description: 'SHOP TOWELS',
          category: 'Supplies',
          use: ExpenseLineUse.business,
          quantity: 1,
          unitsPerPackage: 1,
          unit: 'each',
          subtotal: 4,
        ),
      ],
    );

    final draft = buildWorkSupplyParsedReceiptDraft(
      parsed: parsed,
      receiptId: 'RCP-1',
      loggedAt: DateTime(2026, 6, 23),
      storageArea: 'Company inventory',
      merchantName: 'LOWES',
      source: ReceiptProcessingSource.photo,
    );

    expect(draft.lines, hasLength(2));
    expect(draft.inventoryRecords, hasLength(1));
    expect(draft.processingSnapshot.source, ReceiptProcessingSource.photo);
    expect(
      draft.processingSnapshot.stage,
      ReceiptProcessingStage.stagedForReview,
    );
    expect(
      draft.processingSnapshot.destination,
      ReceiptSaveDestination.inventoryReview,
    );
    expect(draft.canCommitInventory, isFalse);
    expect(draft.inventoryLineCount, 1);
    expect(draft.businessOnlyLineCount, 1);
    expect(draft.hasInventorySelection, isTrue);
    expect(
      draft.inventorySelectionBundle.purpose,
      ReceiptLineSelectionPurpose.inventory,
    );
    expect(draft.inventorySelectionBundle.selectedLineCount, 1);
    expect(draft.inventorySelectionBundle.totalSourceLineCount, 2);
    expect(
      draft.inventorySelectionBundle.selectedLines.single.receiptLineId,
      'RCP-1-L1',
    );
    expect(draft.hasClientProofSelection, isTrue);
    expect(
      draft.clientProofSelectionBundle.purpose,
      ReceiptLineSelectionPurpose.clientProof,
    );
    expect(draft.clientProofSelectionBundle.selectedLineCount, 2);
    expect(draft.clientProofSelectionBundle.excludedLineCount, 0);
    expect(draft.clientProofSelectionBundle.reviewBeforeShareCount, 2);
    expect(
      draft.clientProofSelectionBundle.toPrivacySafeMap().toString(),
      isNot(contains('LOWES')),
    );
    final inventoryEvent = draft.inventorySelectionPrivacyEvent();
    expect(inventoryEvent.selectedReceiptLinePurpose, 'inventory');
    expect(inventoryEvent.selectedReceiptLineCount, 1);
    expect(inventoryEvent.excludedReceiptLineCount, 1);
    final clientProofEvent = draft.clientProofSelectionPrivacyEvent(
      featureArea: 'job invoice',
    );
    expect(clientProofEvent.featureArea, 'job_invoice');
    expect(clientProofEvent.selectedReceiptLinePurpose, 'clientProof');
    expect(clientProofEvent.selectedReceiptLineCount, 2);
    expect(clientProofEvent.excludedReceiptLineCount, 0);
    expect(clientProofEvent.toMap().toString(), isNot(contains('LOWES')));
    expect(clientProofEvent.toMap().toString(), isNot(contains('COPPER')));
    expect(draft.lines.first.kind, ReceiptLineKind.inventory);
    expect(draft.lines.first.receiptLineId, 'RCP-1-L1');
    expect(draft.lines.first.inventoryItemId, copperElbow.id);
    expect(draft.lines.first.taxRate, closeTo(.08, .001));
    expect(draft.lines.first.receiptLaneLabel, 'Inventory');
    expect(draft.lines.first.rawReceiptText, '1/2 COPPER 90');
    expect(draft.lines.first.proofLineReferenceLabel, 'Line 1');
    expect(
      draft.lines.first.clientProofDefaultVisibility,
      ReceiptLineClientProofVisibility.reviewForClientProof,
    );
    expect(draft.lines.first.sourceReceiptSectionLabel, 'Photo receipt RCP-1');
    expect(
      draft.lines.first.privacySafeProofReference.toString(),
      isNot(contains('LOWES')),
    );
    expect(
      draft.lines.first.privacySafeProofReference.toString(),
      isNot(contains('COPPER')),
    );
    expect(
      draft.lines.first.privacySafeProofReference.toString(),
      isNot(contains('12')),
    );
    expect(draft.lines.first.catalogMatchConfidence, .91);
    expect(draft.lines.first.catalogMatchedTerms, ['1/2', 'copper', '90']);
    expect(draft.lines.first.parserReviewLabel, 'Good');
    expect(
      draft.lines.first.parserReviewReason,
      'Catalog match found from receipt text.',
    );
    expect(draft.lines.last.kind, ReceiptLineKind.expense);
    expect(draft.lines.last.receiptLaneLabel, 'Business expense only');
    expect(draft.lines.last.parserNeedsReview, isTrue);
    expect(draft.inventoryRecords.single.sourceReceiptLineId, 'RCP-1-L1');
  });

  test('personal and split parsed lines stay out of inventory', () {
    final copperElbow = workSupplyCatalogItems.firstWhere(
      (item) =>
          item.name.contains('Copper 90 Elbow') && item.variant.contains('1/2'),
    );
    final parsed = ExpenseReceiptParseResult(
      sourceText: 'mixed receipt',
      lines: [
        ExpenseReceiptLineRecord(
          id: 'L1',
          description: 'PERSONAL COPPER 90',
          category: 'Materials',
          use: ExpenseLineUse.personal,
          quantity: 1,
          unitsPerPackage: 1,
          unit: 'each',
          subtotal: 8,
          catalogItemId: copperElbow.id,
          catalogItemName: copperElbow.name,
          catalogItemPath: copperElbow.path,
        ),
        const ExpenseReceiptLineRecord(
          id: 'L2',
          description: 'SHARED CLEANER',
          category: 'Supplies',
          use: ExpenseLineUse.split,
          businessPercent: .4,
          quantity: 1,
          unitsPerPackage: 1,
          unit: 'each',
          subtotal: 5,
        ),
      ],
    );

    final draft = buildWorkSupplyParsedReceiptDraft(
      parsed: parsed,
      receiptId: 'RCP-2',
      loggedAt: DateTime(2026, 6, 23),
      storageArea: 'Company inventory',
      merchantName: 'Home Depot',
      startingLineNumber: 4,
    );

    expect(draft.inventoryRecords, isEmpty);
    expect(draft.personalLineCount, 1);
    expect(draft.splitLineCount, 1);
    expect(draft.hasInventorySelection, isFalse);
    expect(draft.inventorySelectionBundle.selectedLineCount, 0);
    expect(draft.clientProofSelectionBundle.selectedLineCount, 1);
    expect(draft.clientProofSelectionBundle.excludedLineCount, 1);
    expect(
      draft.clientProofSelectionPrivacyEvent().selectedReceiptLineCount,
      1,
    );
    expect(
      draft.clientProofSelectionPrivacyEvent().excludedReceiptLineCount,
      1,
    );
    expect(draft.clientProofRedactionPlan.reviewLineCount, 1);
    expect(draft.clientProofRedactionPlan.hiddenLineCount, 1);
    expect(draft.clientProofRedactionPlan.needsReviewBeforeShare, isTrue);
    expect(draft.clientProofReviewSummary.status, 'review_required');
    expect(draft.clientProofReviewSummary.hiddenLineCount, 1);
    expect(draft.clientProofReviewSummary.reviewLineCount, 1);
    expect(
      draft.clientProofReviewSummary.recommendedNextAction,
      'review_lines_before_client_share',
    );
    expect(draft.clientProofImageReviewPlan.sectionCount, 1);
    expect(draft.clientProofImageReviewPlan.reviewSectionCount, 1);
    expect(draft.clientProofImageReviewPlan.unassignedHiddenLineCount, 1);
    expect(
      draft.clientProofRedactionPlan.toPrivacySafeMap().toString(),
      isNot(contains('PERSONAL COPPER')),
    );
    expect(
      draft.clientProofRedactionPlan.toPrivacySafeMap().toString(),
      isNot(contains('SHARED CLEANER')),
    );
    expect(
      draft.clientProofSelectionBundle.selectedLines.single.receiptLineId,
      'RCP-2-L5',
    );
    expect(draft.lines.first.receiptLaneLabel, 'Personal');
    expect(draft.lines.first.proofLineReferenceLabel, 'Line 4');
    expect(
      draft.lines.first.clientProofDefaultVisibility,
      ReceiptLineClientProofVisibility.redactByDefault,
    );
    expect(draft.lines.first.redactsFromClientProofByDefault, isTrue);
    expect(draft.lines.last.receiptLaneLabel, 'Split business/personal');
    expect(draft.lines.last.proofLineReferenceLabel, 'Line 5');
    expect(
      draft.lines.last.clientProofDefaultVisibility,
      ReceiptLineClientProofVisibility.reviewBeforeClientShare,
    );
    expect(draft.lines.last.needsClientProofReview, isTrue);
    expect(draft.lines.last.businessUseLabel, 'Split 40% business');
  });
}

ExpenseReceiptLineRecord _inventoryExpenseLine(
  String id,
  String catalogItemId,
  String catalogItemName,
  String catalogItemPath,
  double quantity,
  double unitsPerPackage,
  double subtotal,
) {
  return ExpenseReceiptLineRecord(
    id: id,
    description: catalogItemName,
    category: 'Materials',
    use: ExpenseLineUse.business,
    quantity: quantity,
    unitsPerPackage: unitsPerPackage,
    unit: 'each',
    subtotal: subtotal,
    catalogItemId: catalogItemId,
    catalogItemName: catalogItemName,
    catalogItemPath: catalogItemPath,
  );
}
