import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  test('parser handoff line id maps flag duplicate line ids', () {
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
    expect(handoff.hasDuplicateLineIds, isTrue);
    expect(handoff.duplicateLineIds, [lineId]);
    expect(handoff.duplicateLineIdCounts, {lineId: 2});
    expect(handoff.lineIdentityStatus, 'duplicate_line_ids_need_review');
    expect(handoff.parserReadinessStatus, 'needs_review');
    expect(handoff.downstreamReadinessStatus, 'expense_lines_need_review');
    expect(handoff.receiptStructureStatus, 'line_identity_review');
    expect(handoff.mixedClassificationReadinessStatus, 'needs_receipt_total');
    expect(handoff.leanLocalOcrReadinessStatus, 'proof_fields_need_review');
    expect(handoff.parserReviewTaskCounts['duplicate_line_ids_need_review'], 1);
    expect(
      handoff.privacySafeParserHandoffContract['lineIdentityStatus'],
      'duplicate_line_ids_need_review',
    );
    expect(handoff.privacySafeParserHandoffContract['duplicateLineIdCounts'], {
      lineId: 2,
    });
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

    const vendor = ReceiptOcrParserLineSignal(
      index: 0,
      text: 'STORE HEADER',
      kind: ReceiptOcrParserLineKind.vendorCandidate,
      confidence: .9,
    );
    const date = ReceiptOcrParserLineSignal(
      index: 1,
      text: '07/04/26',
      kind: ReceiptOcrParserLineKind.dateCandidate,
      confidence: .9,
    );
    const total = ReceiptOcrParserLineSignal(
      index: 4,
      text: 'TOTAL 12.98',
      kind: ReceiptOcrParserLineKind.totalCandidate,
      amountCandidates: [12.98],
      confidence: .92,
    );
    const readyExceptDuplicateHandoff = ReceiptOcrParserHandoff(
      lines: [vendor, date, first, second, total],
      vendorLines: [vendor],
      dateLines: [date],
      itemLines: [first, second],
      summaryLines: [total],
      tenderLines: [],
      metadataLines: [],
    );

    expect(
      readyExceptDuplicateHandoff.lineIdentityStatus,
      'duplicate_line_ids_need_review',
    );
    expect(readyExceptDuplicateHandoff.parserReadinessStatus, 'needs_review');
    expect(
      readyExceptDuplicateHandoff.downstreamReadinessStatus,
      'expense_lines_need_review',
    );
    expect(
      readyExceptDuplicateHandoff.receiptStructureStatus,
      'line_identity_review',
    );
    expect(
      readyExceptDuplicateHandoff.merchantIndependentStructureStatus,
      'needs_line_identity_review',
    );
    expect(
      readyExceptDuplicateHandoff.mixedClassificationReadinessStatus,
      'needs_line_identity_review',
    );
    expect(
      readyExceptDuplicateHandoff.leanLocalOcrReadinessStatus,
      'proof_totals_ready_lines_need_review',
    );
  });
}
