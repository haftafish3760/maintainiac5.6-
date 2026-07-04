import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_privacy_event_store.dart';

Future<PrivacySafeReceiptEventRecord> enqueueReceiptPrivacyHealthFixture(
  PrivacySafeReceiptEventStore store,
) async {
  final parsed = parseExpenseReceiptText('''
PRIVATE SUPPLY HOUSE
06/12/2026
SECRET JOB MATERIAL 12.34
Total 99.99
''');
  await store.enqueue(
    const PrivacySafeReceiptEvent(
      type: PrivacySafeReceiptEventType.receiptOcrReview,
      featureArea: 'expenses',
      capabilityTier: 'light',
      parserDepth: 'lineItems',
      ocrSeverity: 'review',
      warningKinds: ['duplicateText', 'pdfPageLimit'],
      attachmentsRead: 2,
      rawLineCount: 10,
      parserLineCount: 8,
      ocrItemCandidateLineCount: 3,
      ocrPricedLineCount: 6,
      ocrParserReadyLineCount: 2,
      ocrParserReviewSignalCount: 3,
      ocrParserReadinessStatus: 'needs_review',
      ocrDownstreamReadinessStatus: 'inventory_material_ready',
      ocrDownstreamReadinessCounts: {
        'downstreamReadiness_inventory_material_ready': 1,
        'downstreamReadyItemLineCount': 2,
        'downstreamReviewItemLineCount': 1,
        'downstreamInventoryPrepLineCount': 2,
      },
      ocrHighConfidenceItemLineCount: 2,
      ocrReviewItemLineCount: 1,
      ocrQuantitySignalItemLineCount: 2,
      ocrSkuSignalItemLineCount: 2,
      ocrGenericItemLineCount: 1,
      ocrInventoryPrepLineIdCount: 2,
      ocrParserReadyFieldCount: 5,
      ocrParserReviewFieldCount: 1,
      ocrSummaryMathStatus: 'mismatch',
      ocrSummaryMathReconciled: false,
      ocrLineSequenceStatus: 'summary_before_items',
      ocrReceiptStructureStatus: 'line_sequence_review',
      ocrSourceSectionContinuityStatus: 'section_gap',
      ocrSourceSectionCount: 3,
      ocrSourceSectionContinuityReviewNeeded: true,
      ocrSubtotalCandidateLineCount: 1,
      ocrTaxCandidateLineCount: 1,
      ocrTotalCandidateLineCount: 1,
      ocrTenderCandidateLineCount: 2,
      ocrMetadataCandidateLineCount: 4,
      ocrParserLineRoleCounts: {'item': 3, 'summary': 3, 'metadata': 4},
      ocrDominantParserLineRole: 'metadata',
      ocrStableLineIdCount: 10,
      ocrParserReadyItemLineIdCount: 2,
      ocrReviewItemLineIdCount: 1,
      ocrParserBucketCounts: {
        'item_ready': 2,
        'item_needs_review': 1,
        'summary_ready': 3,
        'metadata_ready': 4,
      },
      ocrParserTaskCounts: {
        'vendor_candidate': 1,
        'item_price_ready': 2,
        'item_price_needs_review': 1,
        'inventory_material_candidate': 2,
      },
      clientProofRedactionStatus: 'needs_client_redaction_review',
      clientProofVisibilityCounts: {
        'review_for_client_proof': 8,
        'redact_by_default': 2,
        'review_before_client_share': 1,
      },
      selectedReceiptLinePurpose: 'clientProof',
      selectedReceiptLineCount: 6,
      excludedReceiptLineCount: 4,
      clientProofReviewLineCount: 3,
      redactedReceiptLineCount: 2,
      clientProofRedactionPlanStatus: 'review_required',
      clientProofVisibleLineCount: 1,
      clientProofHiddenLineCount: 6,
      clientProofPlanReviewLineCount: 3,
      clientProofLayoutRedactionStatus: 'ignored_unknown_lines',
      clientProofLayoutVisibleLineCount: 2,
      clientProofLayoutHiddenLineCount: 6,
      clientProofLayoutIgnoredLineCount: 1,
      clientProofLayoutProtectedTypeCount: 2,
      clientProofLayoutKeepsMerchantContext: true,
      clientProofLayoutKeepsTotalsContext: false,
      clientProofImageReviewStatus: 'manual_image_review_required',
      clientProofImageSectionCount: 3,
      clientProofImageVisibleSectionCount: 1,
      clientProofImageHiddenSectionCount: 2,
      clientProofImageReviewSectionCount: 1,
      clientProofImageUnassignedLineCount: 2,
      clientProofImageUnassignedHiddenLineCount: 1,
      clientProofImageUnassignedReviewLineCount: 1,
      ocrFieldReadinessCounts: {
        'vendor_ready': 1,
        'subtotal_ready': 1,
        'tax_ready': 1,
        'total_ready': 1,
        'item_price_ready': 2,
        'item_price_needs_review': 1,
        'inventory_material_candidate': 2,
      },
      pdfPagesRequested: 2,
      hadDuplicateOrOverlapText: true,
    ),
    queuedAtUtc: DateTime.utc(2026, 6, 23, 14),
  );
  final parseRecord = await store.enqueue(
    PrivacySafeReceiptEvent.fromParseResult(
      result: parsed,
      featureArea: 'materials_inventory',
    ),
    queuedAtUtc: DateTime.utc(2026, 6, 23, 15),
  );
  await store.markUploaded([
    parseRecord.id,
  ], nowUtc: DateTime.utc(2026, 6, 23, 16));
  return parseRecord;
}
