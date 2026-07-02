import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test('parses expense fields from OCR parser-ready receipt signals', () {
    final sourceHandoff = ReceiptOcrSourceHandoffSummary.fromAttachments([
      ReceiptAttachmentRecord(
        id: 'receipt-photo-1',
        path: '/tmp/receipt-photo-1.jpg',
        kind: ReceiptAttachmentKind.photo,
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        createdAt: DateTime(2026, 6, 30),
        documentSignals: const [
          'receipt_coverage_bottom_edge_and_totals_missing_together',
          'receipt_coverage_evidence_bottom_edge_missing_plus_totals_text_missing',
          'receipt_coverage_rationale_edge_missing_and_totals_text_missing',
          'receipt_coverage_contract_bottom_edge_totals_missing_use_ghost_overlap',
          'receipt_continuation_missing_bottom_edge_and_totals',
          'receipt_continuation_ghost_policy_bottom_overlap_ghost_at_top_repeat_3_to_5_lines',
        ],
      ),
    ]);
    final ocr = ReceiptOcrResult(
      rawText: '''
LOWE'S HOME CENTERS, LLC
6400 BRODIE LANE
AUSTIN, TX 78745 (512) 895-5560
SALE
SALES#: S2513USO 3644746  TRANS#: 18854480 07-09-21
23536 OATEY 14-OZ PLUMBERS PUTTY       2.99
SUBTOTAL:                              2.99
TAX:                                   0.25
INVOICE 18934  TOTAL:                  3.24
MERCH/GIFT CARDS :                     3.24
MERCH/GIFT CARD 5715 AUTHCODE 370
07/09/21 13:14:57
THANK YOU FOR SHOPPING LOWE'S.
''',
      parserText: '''
LOWE'S HOME CENTERS, LLC
6400 BRODIE LANE
AUSTIN, TX 78745 (512) 895-5560
SALES#: S2513USO 3644746  TRANS#: 18854480 07-09-21
23536 OATEY 14-OZ PLUMBERS PUTTY       2.99
SUBTOTAL:                              2.99
TAX:                                   0.25
INVOICE 18934  TOTAL:                  3.24
MERCH/GIFT CARDS :                     3.24
MERCH/GIFT CARD 5715 AUTHCODE 370
07/09/21 13:14:57
''',
      textByAttachmentId: {'receipt-photo-1': 'LOWES'},
      source: ReceiptProcessingSource.photo,
      sourceHandoffSummary: sourceHandoff,
    );

    expect(ocr.vendorCandidateLines, contains("LOWE'S HOME CENTERS, LLC"));
    expect(ocr.dateCandidateLines.length, greaterThanOrEqualTo(1));
    expect(ocr.itemCandidateLines, [
      '23536 OATEY 14-OZ PLUMBERS PUTTY       2.99',
    ]);
    expect(ocr.subtotalCandidateLines, [
      'SUBTOTAL:                              2.99',
    ]);
    expect(ocr.taxCandidateLines, [
      'TAX:                                   0.25',
    ]);
    expect(ocr.totalCandidateLines, [
      'INVOICE 18934  TOTAL:                  3.24',
    ]);
    expect(
      ocr.parserLineSignals.any(
        (signal) =>
            signal.kind == ReceiptOcrParserLineKind.itemCandidate &&
            signal.amountCandidates.single == 2.99,
      ),
      isTrue,
    );

    final parsed = parseExpenseReceiptOcrResult(
      ocr,
      capability: const ReceiptDeviceCapability.highCapacity(),
    );

    expect(parsed.merchantName, "Lowe's");
    expect(parsed.receiptDate, DateTime(2021, 7, 9));
    expect(parsed.receiptTimeMinutes, (13 * 60) + 14);
    expect(parsed.enteredSubtotal, 2.99);
    expect(parsed.enteredTax, 0.25);
    expect(parsed.enteredTotal, 3.24);
    expect(parsed.lines, hasLength(1));
    expect(parsed.lines.single.description.toUpperCase(), contains('OATEY'));
    expect(parsed.lines.single.category, 'Materials');
    expect(parsed.lines.single.subtotal, 2.99);
    expect(parsed.lines.single.parserExpenseFamily, 'materials');
    expect(parsed.lines.single.parserHint, 'materials_item_price');
    expect(parsed.lines.single.parserExpenseFamilyLabel, 'Materials');
    expect(parsed.lines.single.parserHintLabel, 'Materials Item Price');
    expect(
      parsed.lines.single.parserClassificationLabel,
      'Materials | Materials Item Price',
    );
    expect(parsed.enteredTotal, isNot(787.45));
    expect(parsed.diagnostics.reconciled, isTrue);
    expect(
      parsed.diagnostics.parserDepth,
      ReceiptParserDepth.inventoryMatching,
    );
    expect(
      parsed.diagnostics.ocrParserLineCount,
      ocr.orderedParserLines.length,
    );
    expect(parsed.diagnostics.ocrItemCandidateLineCount, 1);
    expect(parsed.diagnostics.ocrPricedLineCount, greaterThanOrEqualTo(5));
    expect(parsed.diagnostics.ocrParserReadyLineCount, 1);
    expect(parsed.diagnostics.ocrParserReviewSignalCount, 0);
    expect(parsed.diagnostics.ocrParserReadinessStatus, 'inventory_ready');
    expect(parsed.diagnostics.hasOcrParserReadyStatus, isTrue);
    expect(parsed.diagnostics.hasOcrSourceCoverageSignals, isTrue);
    expect(
      parsed.diagnostics.hasOcrSourceMissingBottomCoverageEvidence,
      isTrue,
    );
    expect(
      parsed.diagnostics.missingBottomTotalsEvidenceCode,
      'bottom_edge_totals_multi_signal',
    );
    expect(
      parsed.diagnostics.missingBottomTotalsEvidenceFamilyCount,
      greaterThanOrEqualTo(2),
    );
    expect(
      parsed.diagnostics.missingBottomTotalsEvidenceLabel,
      contains('Bottom edge and totals are missing'),
    );
    expect(
      parsed.diagnostics.missingBottomTotalsLocalEvidenceReviewLabel,
      contains('Bottom edge and totals are missing'),
    );
    expect(parsed.diagnostics.ocrSourceCoverageSignalCounts, {
      'receipt_coverage_bottom_edge_and_totals_missing_together': 1,
      'receipt_coverage_evidence_bottom_edge_missing_plus_totals_text_missing':
          1,
      'receipt_coverage_rationale_edge_missing_and_totals_text_missing': 1,
      'receipt_coverage_contract_bottom_edge_totals_missing_use_ghost_overlap':
          1,
    });
    expect(parsed.diagnostics.hasOcrSourceContinuationSignals, isTrue);
    expect(
      parsed.diagnostics.hasOcrSourceBottomOverlapGhostContinuation,
      isTrue,
    );
    expect(parsed.diagnostics.ocrSourceContinuationSignalCounts, {
      'receipt_continuation_missing_bottom_edge_and_totals': 1,
      'receipt_continuation_ghost_policy_bottom_overlap_ghost_at_top_repeat_3_to_5_lines':
          1,
    });
    expect(
      parsed.diagnostics.ocrSourceContinuationReviewCode,
      'bottom_overlap_ghost_continuation',
    );
    expect(
      parsed.diagnostics.ocrSourceContinuationReviewLabel,
      'Bottom continuation uses top ghost slice',
    );
    expect(
      parsed.diagnostics.ocrSourceContinuationReviewInstruction,
      contains('bottom edge and subtotal/total evidence'),
    );
    expect(
      parsed.diagnostics.ocrSourceContinuationReviewInstruction,
      contains('repeat 3-5 readable lines in the top ghost slice'),
    );
    expect(
      parsed.diagnostics.ocrSourceContinuationReviewActionLabel,
      'Add bottom with top ghost slice',
    );
    expect(parsed.diagnostics.ocrLeanLocalReadinessStatus, 'line_items_ready');
    expect(parsed.diagnostics.hasOcrLeanLocalTotalsReady, isTrue);
    expect(parsed.diagnostics.hasOcrLeanLocalLineReview, isFalse);
    expect(
      parsed.diagnostics.ocrLeanLocalReadinessCount('parser_ready_item_lines'),
      1,
    );
    expect(
      parsed.diagnostics.ocrLeanLocalReadinessLabel,
      contains('prepare line items'),
    );
    expect(parsed.diagnostics.ocrHighConfidenceItemLineCount, 1);
    expect(parsed.diagnostics.ocrReviewItemLineCount, 0);
    expect(parsed.diagnostics.ocrQuantitySignalItemLineCount, 1);
    expect(parsed.diagnostics.ocrSkuSignalItemLineCount, 1);
    expect(parsed.diagnostics.ocrGenericItemLineCount, 0);
    expect(parsed.diagnostics.ocrInventoryPrepLineIdCount, 1);
    expect(
      parsed.diagnostics.ocrParserReadyFieldCount,
      greaterThanOrEqualTo(5),
    );
    expect(
      parsed.diagnostics.ocrParserReviewFieldCount,
      greaterThanOrEqualTo(1),
    );
    expect(parsed.diagnostics.ocrSummaryMathStatus, 'matched');
    expect(parsed.diagnostics.ocrSummaryMathReconciled, isTrue);
    expect(parsed.diagnostics.ocrLineSequenceStatus, 'expected_order');
    expect(parsed.diagnostics.ocrReceiptStructureStatus, 'ready_for_parser');
    expect(parsed.diagnostics.ocrParserLineRoleCounts['item'], 1);
    expect(parsed.diagnostics.ocrParserLineRoleCounts['summary'], 3);
    expect(parsed.diagnostics.ocrDominantParserLineRole, isNotEmpty);
    expect(
      parsed.diagnostics.ocrStableLineIdCount,
      ocr.parserHandoff.stableLineIds.length,
    );
    expect(parsed.diagnostics.hasOcrStableLineIds, isTrue);
    expect(parsed.diagnostics.ocrParserReadyItemLineIdCount, 1);
    expect(parsed.diagnostics.ocrReviewItemLineIdCount, 0);
    expect(parsed.diagnostics.hasOcrParserTaskCounts, isTrue);
    expect(
      parsed.diagnostics.ocrParserTaskCount('vendor_candidate'),
      greaterThanOrEqualTo(1),
    );
    expect(parsed.diagnostics.ocrParserTaskCount('item_price_ready'), 1);
    expect(
      parsed.diagnostics.ocrParserTaskCount('inventory_material_candidate'),
      1,
    );
    expect(parsed.diagnostics.hasOcrVendorTaskEvidence, isTrue);
    expect(parsed.diagnostics.hasOcrDateTaskEvidence, isTrue);
    expect(parsed.diagnostics.hasOcrSubtotalTaskEvidence, isTrue);
    expect(parsed.diagnostics.hasOcrTaxTaskEvidence, isTrue);
    expect(parsed.diagnostics.hasOcrTotalTaskEvidence, isTrue);
    expect(parsed.diagnostics.hasOcrItemPriceTaskEvidence, isTrue);
    expect(parsed.diagnostics.hasOcrMaterialPrepTaskEvidence, isTrue);
    expect(
      parsed.diagnostics.parserTaskSummaryLabel,
      'Add bottom receipt section first',
    );
    expect(parsed.diagnostics.hasOcrReadyItemLineIds, isTrue);
    expect(parsed.diagnostics.hasOcrReviewItemLineIds, isFalse);
    expect(
      parsed.diagnostics.ocrLineIdsForRole('item'),
      ocr.parserHandoff.parserReadyItemLineIds,
    );
    expect(parsed.diagnostics.hasOcrLineIdentityMaps, isTrue);
    expect(parsed.diagnostics.ocrRoleForLineId('ocr_line_004_item'), 'item');
    expect(
      parsed.diagnostics.ocrParserBucketForLineId('ocr_line_004_item'),
      'item_ready',
    );
    expect(
      parsed.diagnostics.ocrOrderedParserReadyLineIds,
      containsAllInOrder([
        'ocr_line_003_date',
        'ocr_line_004_item',
        'ocr_line_005_subtotal',
        'ocr_line_006_tax',
        'ocr_line_007_total',
      ]),
    );
    expect(
      parsed.diagnostics.ocrOrderedParserReviewLineIds,
      contains('ocr_line_000_vendor'),
    );
    expect(
      parsed.diagnostics.ocrLineIdentitySummaryLabel,
      contains('OCR lines mapped'),
    );
    expect(parsed.diagnostics.ocrLineIdentitySummaryLabel, contains('ready'));
    expect(
      parsed.diagnostics.ocrLineIdentitySummaryLabel,
      contains('to check'),
    );
    expect(
      parsed.diagnostics.ocrLineIdentitySummaryLabel,
      contains('material-prep'),
    );
    expect(parsed.diagnostics.ocrLineIdsForRole('summary'), [
      'ocr_line_005_subtotal',
      'ocr_line_006_tax',
      'ocr_line_007_total',
    ]);
    expect(parsed.diagnostics.hasOcrParserBucketCounts, isTrue);
    expect(parsed.diagnostics.ocrParserBucketCount('item_ready'), 1);
    expect(parsed.diagnostics.ocrParserBucketCount('summary_ready'), 3);
    expect(parsed.diagnostics.hasOcrFieldReadinessCounts, isTrue);
    expect(parsed.diagnostics.ocrFieldReadinessCount('vendor_needs_review'), 1);
    expect(parsed.diagnostics.ocrFieldReadinessCount('total_ready'), 1);
    expect(
      parsed.diagnostics.ocrFieldReadinessCount('inventory_material_candidate'),
      1,
    );
    expect(parsed.diagnostics.hasOcrRequiredFieldStatusCounts, isTrue);
    expect(
      parsed.diagnostics.ocrRequiredFieldStatusCount('required_ready_total'),
      5,
    );
    expect(
      parsed.diagnostics.ocrRequiredFieldStatusCount(
        'required_needs_review_total',
      ),
      1,
    );
    expect(
      parsed.diagnostics.ocrRequiredFieldStatusLabel,
      contains('structure=ready_for_parser'),
    );
    expect(parsed.diagnostics.ocrRequiredFieldStatusByField, {
      'vendor': 'needs_review',
      'date': 'ready',
      'subtotal': 'ready',
      'tax': 'ready',
      'total': 'ready',
      'item_price': 'ready',
    });
    expect(parsed.diagnostics.ocrRequiredFieldIssueLabels, ['check store']);
    expect(parsed.diagnostics.ocrRequiredFieldIssueSummaryLabel, 'check store');
    expect(
      parsed.diagnostics.ocrRequiredFieldReadinessSummaryLabel,
      'vendor=needs_review;date=ready;subtotal=ready;tax=ready;total=ready;item_price=ready;structure=ready_for_parser;sections=no_source_sections;readiness=inventory_ready',
    );
    expect(parsed.diagnostics.ocrParserReviewCauseCodes, isEmpty);
    expect(parsed.diagnostics.ocrSubtotalCandidateLineCount, 1);
    expect(parsed.diagnostics.ocrTaxCandidateLineCount, 1);
    expect(parsed.diagnostics.ocrTotalCandidateLineCount, 1);
    expect(
      parsed.diagnostics.ocrTenderCandidateLineCount,
      greaterThanOrEqualTo(1),
    );
    expect(parsed.diagnostics.ocrMetadataCandidateLineCount, greaterThan(0));
    expect(parsed.diagnostics.hasOcrNonItemSignals, isTrue);
    expect(parsed.diagnostics.hasOcrItemSignals, isTrue);
    expect(parsed.diagnostics.hasOcrParserReadyLines, isTrue);
    expect(parsed.diagnostics.hasOcrParserReviewSignals, isFalse);
    expect(parsed.diagnostics.hasOcrItemReviewSignals, isFalse);
    expect(parsed.diagnostics.hasOcrInventoryPrepSignals, isTrue);
    expect(parsed.diagnostics.hasOcrParserReadyFields, isTrue);
    expect(parsed.diagnostics.hasOcrParserReviewFields, isTrue);
    expect(parsed.diagnostics.hasOcrGenericItemSignals, isFalse);
    expect(parsed.diagnostics.hasOcrCompleteSummaryMath, isTrue);
    expect(parsed.diagnostics.hasOcrSummaryMathMismatch, isFalse);
    expect(parsed.diagnostics.hasOcrExpectedLineSequence, isTrue);
    expect(parsed.diagnostics.hasOcrLineSequenceReview, isFalse);
    expect(parsed.diagnostics.hasOcrReceiptStructureReview, isFalse);
    expect(parsed.diagnostics.hasOcrTotalSignals, isTrue);
    expect(parsed.fieldConfidences['total']?.label, 'Good');
  });
}
