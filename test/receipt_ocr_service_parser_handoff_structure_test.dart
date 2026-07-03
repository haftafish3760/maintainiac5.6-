import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

import 'helpers/receipt_ocr_parser_ready_fixture.dart';

void main() {
  test('parser line drafts expose source-first receipt line labels', () {
    const sourceLocation = ReceiptOcrParserLineLocation(
      sectionNumber: 2,
      sectionLineNumber: 4,
    );
    final draft = ReceiptOcrParserLineDraft.fromSignal(
      const ReceiptOcrParserLineSignal(
        index: 12,
        text: '1/2 GAL MILK 4.25',
        kind: ReceiptOcrParserLineKind.itemCandidate,
        amountCandidates: [4.25],
        confidence: .88,
        sourceLocation: sourceLocation,
      ),
    );
    final noSourceDraft = ReceiptOcrParserLineDraft.fromSignal(
      const ReceiptOcrParserLineSignal(
        index: 3,
        text: 'BREAD 2.50',
        kind: ReceiptOcrParserLineKind.itemCandidate,
        amountCandidates: [2.50],
        confidence: .86,
      ),
    );

    expect(draft.lineLabel, 'Line 13');
    expect(draft.sourceFirstLineLabel, 'section 2 line 4');
    expect(draft.proofLineReferenceLabel, 'Line 13, section 2 line 4');
    expect(
      draft.toLocalReviewMap()['sourceFirstLineLabel'],
      'section 2 line 4',
    );
    expect(
      draft.toPrivacySafeSummaryMap()['sourceFirstLineLabel'],
      'section 2 line 4',
    );
    expect(noSourceDraft.sourceFirstLineLabel, 'Line 4');
  });

  test('parser line source locations clamp unusable line numbers', () {
    const badLocation = ReceiptOcrParserLineLocation(
      sectionNumber: -3,
      sectionLineNumber: 0,
    );
    final draft = ReceiptOcrParserLineDraft.fromSignal(
      const ReceiptOcrParserLineSignal(
        index: 0,
        text: 'MILK 4.25',
        kind: ReceiptOcrParserLineKind.itemCandidate,
        amountCandidates: [4.25],
        confidence: .88,
        sourceLocation: badLocation,
      ),
    );

    expect(badLocation.safeSectionNumber, 1);
    expect(badLocation.safeSectionLineNumber, 1);
    expect(badLocation.label, 'source line 1');
    expect(badLocation.toMap(), {
      'sectionNumber': 1,
      'sectionLineNumber': 1,
      'label': 'source line 1',
    });
    expect(draft.sourceFirstLineLabel, 'source line 1');
    expect(draft.proofLineReferenceLabel, 'Line 1, source line 1');
    expect(draft.toLocalReviewMap()['sourceFirstLineLabel'], 'source line 1');
  });

  test('parser handoff line id maps preserve first duplicate line id', () {
    const firstLocation = ReceiptOcrParserLineLocation(
      sectionNumber: 1,
      sectionLineNumber: 3,
    );
    const secondLocation = ReceiptOcrParserLineLocation(
      sectionNumber: 2,
      sectionLineNumber: 1,
    );
    const first = ReceiptOcrParserLineSignal(
      index: 2,
      text: 'FIRST ITEM 2.99',
      kind: ReceiptOcrParserLineKind.itemCandidate,
      amountCandidates: [2.99],
      confidence: .9,
      traits: ['safe_terminal_line_amount'],
      sourceLocation: firstLocation,
      expenseFamily: ReceiptOcrParserExpenseFamily.materials,
      parserHint: 'first_material_hint',
    );
    const second = ReceiptOcrParserLineSignal(
      index: 2,
      text: 'SECOND ITEM 9.99',
      kind: ReceiptOcrParserLineKind.itemCandidate,
      amountCandidates: [9.99],
      confidence: .9,
      traits: ['safe_terminal_line_amount'],
      sourceLocation: secondLocation,
      expenseFamily: ReceiptOcrParserExpenseFamily.fuel,
      parserHint: 'second_fuel_hint',
    );
    const handoff = ReceiptOcrParserHandoff(
      lines: [first, second],
      vendorLines: [],
      dateLines: [],
      itemLines: [first, second],
      summaryLines: [],
      tenderLines: [],
      metadataLines: [],
    );
    final lineId = first.stableLineId;

    expect(second.stableLineId, lineId);
    expect(handoff.stableLineIds, [lineId, lineId]);
    expect(handoff.parserReadyItemLineIds, [lineId]);
    expect(handoff.materialCandidateLineIds, [lineId]);
    expect(handoff.inventoryPrepLineIds, [lineId]);
    expect(handoff.parserTaskLineIds['item_price_ready'], [lineId]);
    expect(handoff.parserTaskLineIds['material_line_candidate'], [lineId]);
    expect(handoff.lineNumberByLineId[lineId], 3);
    expect(
      handoff.proofLineReferenceLabelByLineId[lineId],
      'Line 3, source line 3',
    );
    expect(handoff.lineDraftsById[lineId]?.text, 'FIRST ITEM 2.99');
    expect(handoff.itemAmountsByLineId[lineId], 2.99);
    expect(handoff.itemTextByLineId[lineId], 'FIRST ITEM 2.99');
    expect(handoff.roleByLineId[lineId], 'item');
    expect(handoff.parserBucketByLineId[lineId], 'item_ready');
    expect(handoff.expenseFamilyByLineId[lineId], 'materials');
    expect(handoff.parserHintByLineId[lineId], 'first_material_hint');
    expect(
      handoff.customerProofDefaultVisibilityByLineId[lineId],
      'review_for_customer_proof',
    );
    expect(handoff.customerProofReviewLineIds, [lineId]);
    expect(
      handoff.privacySafeCustomerProofContract['customerProofReviewLineIds'],
      [lineId],
    );
    expect(
      handoff.customerProofVisibilityCounts['review_for_customer_proof'],
      2,
    );
  });

  test('ocr parser handoff exposes ready item and summary structure', () {
    final result = parserReadyLowesReceiptResult();

    final itemSignal = result.parserLineSignals.singleWhere(
      (signal) => signal.text == '23536 OATEY 14-OZ PLUMBERS PUTT        2.99',
    );
    final tenderSignal = result.parserLineSignals.singleWhere(
      (signal) => signal.text == 'MERCH/GIFT CARDS :                     3.24',
    );
    expect(tenderSignal.kind, ReceiptOcrParserLineKind.tenderCandidate);
    expect(tenderSignal.isLikelyTender, isTrue);
    expect(tenderSignal.primaryAmount, 3.24);
    expect(tenderSignal.roleLabel, 'tender');
    expect(tenderSignal.stableLineId, 'ocr_line_008_tender');
    expect(tenderSignal.parserBucketId, 'tender_ready');
    final authCodeTenderSignal = result.parserLineSignals.singleWhere(
      (signal) => signal.text == 'MERCH/GIFT CARD 5715 AUTHCODE 370',
    );
    expect(authCodeTenderSignal.kind, ReceiptOcrParserLineKind.tenderCandidate);
    expect(authCodeTenderSignal.isLikelyTender, isTrue);
    expect(authCodeTenderSignal.primaryAmount, isNull);
    expect(authCodeTenderSignal.roleLabel, 'tender');
    final handoff = result.parserHandoff;
    expect(handoff.primaryVendorLine?.text, "LOWE'S HOME CENTERS, LLC");
    expect(handoff.primaryDateLine?.text, '07/09/21 13:14:57');
    expect(
      handoff.primarySubtotalLine?.text,
      'SUBTOTAL:                              2.99',
    );
    expect(
      handoff.primaryTaxLine?.text,
      'TAX:                                   0.25',
    );
    expect(
      handoff.primaryTotalLine?.text,
      'INVOICE 18934 TOTAL:                   3.24',
    );
    expect(handoff.primarySubtotalAmount, 2.99);
    expect(handoff.primaryTaxAmount, 0.25);
    expect(handoff.primaryTotalAmount, 3.24);
    expect(handoff.itemAmountSubtotal, 2.99);
    expect(handoff.hasCompleteSummaryAmounts, isTrue);
    expect(handoff.summaryMathReconciled, isTrue);
    expect(handoff.summaryMathStatus, 'matched');
    expect(handoff.firstHeaderLineIndex, 0);
    expect(handoff.firstItemLineIndex, 4);
    expect(handoff.lastItemLineIndex, 4);
    expect(handoff.firstSummaryLineIndex, 5);
    expect(handoff.lastSummaryLineIndex, 7);
    expect(handoff.firstTenderLineIndex, 8);
    expect(handoff.lineSequenceStatus, 'expected_order');
    expect(handoff.hasExpectedLineSequence, isTrue);
    expect(handoff.needsLineSequenceReview, isFalse);
    expect(handoff.itemLines.single.text, itemSignal.text);
    expect(handoff.summaryLines, hasLength(3));
    expect(
      handoff.tenderLines.map((line) => line.text),
      contains(tenderSignal.text),
    );
    expect(
      handoff.tenderLines.map((line) => line.text),
      contains(authCodeTenderSignal.text),
    );
    expect(handoff.metadataLines, hasLength(3));
    expect(handoff.hasLineItemEvidence, isTrue);
    expect(handoff.pricedLineCount, greaterThanOrEqualTo(5));
    expect(handoff.parserReadyLineCount, 1);
    expect(handoff.parserReviewSignalCount, 0);
    expect(handoff.receiptStructureStatus, 'ready_for_parser');
    expect(handoff.mixedClassificationReadinessStatus, 'ready');
    expect(handoff.mixedClassificationReady, isTrue);
    expect(
      handoff.mixedClassificationEvidenceLabel,
      contains('mixed_classification_ready'),
    );
    expect(
      handoff.mixedClassificationEvidenceDiagnostics['readyItemLineCount'],
      1,
    );
    expect(handoff.downstreamReadinessStatus, 'inventory_material_ready');
    expect(
      handoff.downstreamReadinessLabel,
      'Material-style item lines are ready for inventory review.',
    );
    expect(handoff.highConfidenceItemLineCount, 1);
    expect(handoff.reviewItemLineCount, 0);
    expect(handoff.quantitySignalItemLineCount, 1);
    expect(handoff.skuSignalItemLineCount, 1);
    expect(handoff.genericItemLineCount, 0);
    expect(handoff.inventoryPrepLineCount, 1);
    expect(handoff.materialCandidateLineCount, 1);
    expect(handoff.fuelCandidateLineCount, 0);
    expect(handoff.vehicleSupplyCandidateLineCount, 0);
    expect(handoff.parserReadyFieldCount, greaterThanOrEqualTo(5));
    expect(handoff.parserReviewFieldCount, greaterThanOrEqualTo(1));
    expect(handoff.lineRoleCounts['item'], 1);
    expect(handoff.lineRoleCounts['summary'], 3);
    expect(handoff.dominantLineRole, isNotEmpty);
    expect(handoff.hasSummaryEvidence, isTrue);
    expect(handoff.hasTenderOrMetadataNoise, isTrue);
    expect(handoff.stableLineIds, contains('ocr_line_004_item'));
    expect(handoff.parserReadyItemLineIds, ['ocr_line_004_item']);
    expect(handoff.reviewItemLineIds, isEmpty);
    expect(handoff.inventoryPrepLineIds, ['ocr_line_004_item']);
    expect(handoff.materialCandidateLineIds, ['ocr_line_004_item']);
    expect(handoff.fuelCandidateLineIds, isEmpty);
    expect(handoff.vehicleSupplyCandidateLineIds, isEmpty);
    expect(handoff.primaryFieldLineIds['vendor'], 'ocr_line_000_vendor');
    expect(handoff.primaryFieldLineIds['date'], 'ocr_line_003_date');
    expect(handoff.primaryFieldLineIds['subtotal'], 'ocr_line_005_subtotal');
    expect(handoff.primaryFieldLineIds['tax'], 'ocr_line_006_tax');
    expect(handoff.primaryFieldLineIds['total'], 'ocr_line_007_total');
    expect(handoff.lineIdsByRole['item'], ['ocr_line_004_item']);
    expect(handoff.lineIdsByRole['summary'], [
      'ocr_line_005_subtotal',
      'ocr_line_006_tax',
      'ocr_line_007_total',
    ]);
    expect(handoff.roleByLineId['ocr_line_004_item'], 'item');
    expect(handoff.roleByLineId['ocr_line_007_total'], 'total');
    expect(handoff.parserBucketByLineId['ocr_line_004_item'], 'item_ready');
    expect(handoff.expenseFamilyByLineId['ocr_line_004_item'], 'materials');
    expect(
      handoff.parserHintByLineId['ocr_line_004_item'],
      'materials_item_price',
    );
    expect(
      handoff.parserBucketByLineId['ocr_line_000_vendor'],
      'vendor_needs_review',
    );
    expect(
      handoff.orderedParserReadyLineIds,
      containsAllInOrder([
        'ocr_line_003_date',
        'ocr_line_004_item',
        'ocr_line_005_subtotal',
        'ocr_line_006_tax',
        'ocr_line_007_total',
      ]),
    );
    expect(handoff.orderedParserReviewLineIds, contains('ocr_line_000_vendor'));
    expect(
      handoff.parserTaskLineIds['vendor_candidate'],
      contains('ocr_line_000_vendor'),
    );
    expect(handoff.parserTaskLineIds['date_candidate'], ['ocr_line_003_date']);
    expect(handoff.parserTaskLineIds['subtotal_candidate'], [
      'ocr_line_005_subtotal',
    ]);
    expect(handoff.parserTaskLineIds['tax_candidate'], ['ocr_line_006_tax']);
    expect(handoff.parserTaskLineIds['total_candidate'], [
      'ocr_line_007_total',
    ]);
    expect(handoff.parserTaskLineIds['item_price_ready'], [
      'ocr_line_004_item',
    ]);
    expect(handoff.parserTaskLineIds['inventory_material_candidate'], [
      'ocr_line_004_item',
    ]);
    expect(handoff.parserTaskLineIds['material_line_candidate'], [
      'ocr_line_004_item',
    ]);
    expect(
      handoff.parserTaskLineIds['parser_ready_field'],
      containsAll([
        'ocr_line_003_date',
        'ocr_line_004_item',
        'ocr_line_005_subtotal',
        'ocr_line_006_tax',
        'ocr_line_007_total',
      ]),
    );
    expect(
      handoff.parserTaskLineIds['parser_review_field'],
      contains('ocr_line_000_vendor'),
    );
    expect(
      handoff.parserTaskCounts['vendor_candidate'],
      greaterThanOrEqualTo(1),
    );
    expect(handoff.parserTaskCounts['item_price_ready'], 1);
    expect(handoff.parserTaskCounts['inventory_material_candidate'], 1);
    expect(handoff.parserTaskCounts['material_line_candidate'], 1);
    expect(handoff.parserMissingFieldCounts, isEmpty);
    expect(handoff.parserReviewTaskCounts['vendor_candidate_needs_review'], 1);
  });
}
