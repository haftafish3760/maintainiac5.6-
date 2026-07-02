import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/shared/receipts/receipt_line_models.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  test(
    'OCR privacy event keeps warning categories but no receipt text',
    () async {
      final result = await const ReceiptOcrService()
          .recognizeTextFromAttachments([
            _textAttachment(
              id: 'top',
              text: 'LOWES HOME IMPROVEMENT\nPVC GLUE 7.99',
            ),
            _textAttachment(id: 'bottom', text: 'PVC GLUE 7.99\nTOTAL 7.99'),
          ]);

      final event = PrivacySafeReceiptEvent.fromOcrResult(
        result: result,
        featureArea: 'materials inventory',
        capability: const ReceiptDeviceCapability.highCapacity(),
      );
      final map = event.toMap();
      final encoded = map.toString().toLowerCase();

      expect(map['event'], PrivacySafeReceiptEventType.receiptOcrReview.name);
      expect(map['featureArea'], 'materials_inventory');
      expect(map['capabilityTier'], ReceiptCapabilityTier.heavyweight.name);
      expect(map['warningKinds'], [ReceiptOcrWarningKind.duplicateText.name]);
      expect(map['rawLineCount'], 4);
      expect(map['parserLineCount'], 3);
      expect(map['ocrItemCandidateLineCount'], 1);
      expect(map['ocrPricedLineCount'], greaterThanOrEqualTo(1));
      expect(map['ocrParserReadyLineCount'], 1);
      expect(map['ocrParserReviewSignalCount'], 0);
      expect(map['ocrParserReadinessStatus'], 'receipt_ready');
      expect(map['ocrDownstreamReadinessStatus'], 'inventory_material_ready');
      final downstreamCounts =
          map['ocrDownstreamReadinessCounts'] as Map<String, int>;
      expect(
        downstreamCounts,
        containsPair('downstreamReadiness_inventory_material_ready', 1),
      );
      expect(downstreamCounts, containsPair('downstreamReadyItemLineCount', 1));
      expect(map['ocrStableLineIdCount'], 3);
      expect(map['ocrParserReadyItemLineIdCount'], 1);
      expect(map['ocrReviewItemLineIdCount'], 0);
      expect(map['ocrInventoryPrepLineIdCount'], 1);
      expect(map['ocrParserReadyFieldCount'], greaterThanOrEqualTo(2));
      expect(map['ocrParserReviewFieldCount'], greaterThanOrEqualTo(1));
      final bucketCounts = map['ocrParserBucketCounts'] as Map<String, int>;
      expect(bucketCounts, containsPair('item_ready', 1));
      expect(bucketCounts, containsPair('summary_ready', 1));
      final taskCounts = map['ocrParserTaskCounts'] as Map<String, int>;
      expect(taskCounts, containsPair('vendor_candidate', 1));
      expect(taskCounts, containsPair('item_price_ready', 1));
      expect(taskCounts, containsPair('long_receipt_duplicate_text', 1));
      final readinessCounts =
          map['ocrFieldReadinessCounts'] as Map<String, int>;
      expect(readinessCounts, containsPair('vendor_needs_review', 1));
      expect(readinessCounts, containsPair('total_ready', 1));
      expect(readinessCounts, containsPair('item_price_ready', 1));
      final requiredCounts =
          map['ocrRequiredFieldStatusCounts'] as Map<String, int>;
      expect(requiredCounts, containsPair('vendor_needs_review', 1));
      expect(requiredCounts, containsPair('total_ready', 1));
      expect(requiredCounts, containsPair('item_price_ready', 1));
      expect(requiredCounts, containsPair('required_ready_total', 2));
      expect(requiredCounts, containsPair('required_needs_review_total', 1));
      expect(requiredCounts, containsPair('required_missing_total', 1));
      expect(
        map['ocrRequiredFieldStatusLabel'],
        contains('structure=ready_for_parser'),
      );
      final roleCounts = map['ocrParserLineRoleCounts'] as Map<String, int>;
      expect(roleCounts, containsPair('item', 1));
      expect(roleCounts, containsPair('vendor', 1));
      expect(roleCounts, containsPair('summary', 1));
      expect(map['ocrDominantParserLineRole'], isNotEmpty);
      expect(map['ocrHighConfidenceItemLineCount'], 1);
      expect(map['ocrReviewItemLineCount'], 0);
      expect(map['ocrQuantitySignalItemLineCount'], 0);
      expect(map['ocrSkuSignalItemLineCount'], 0);
      expect(map['ocrGenericItemLineCount'], 0);
      expect(map['ocrSummaryMathStatus'], 'incomplete');
      expect(map['ocrSummaryMathReconciled'], isFalse);
      expect(map['ocrLineSequenceStatus'], 'expected_order');
      expect(map['ocrReceiptStructureStatus'], 'ready_for_parser');
      expect(map['clientProofRedactionStatus'], 'ready_for_client_proof');
      final clientProofCounts =
          map['clientProofVisibilityCounts'] as Map<String, int>;
      expect(clientProofCounts, containsPair('review_for_client_proof', 3));
      expect(clientProofCounts.containsKey('redact_by_default'), isFalse);
      expect(map['ocrSubtotalCandidateLineCount'], 0);
      expect(map['ocrTaxCandidateLineCount'], 0);
      expect(map['ocrTotalCandidateLineCount'], 1);
      expect(map['ocrTenderCandidateLineCount'], 0);
      expect(map['ocrMetadataCandidateLineCount'], 0);
      expect(map['hadDuplicateOrOverlapText'], isTrue);
      expect(encoded, isNot(contains('lowes')));
      expect(encoded, isNot(contains('pvc')));
      expect(encoded, isNot(contains('7.99')));
      expect(encoded, isNot(contains('ocr_line_')));
      expect(encoded, isNot(contains('customer')));
    },
  );

  test(
    'line selection privacy event reports counts without receipt content',
    () {
      const businessLine = ReceiptLineDraft(
        kind: ReceiptLineKind.inventory,
        description: 'Private copper elbow',
        receiptLineId: 'RCP-77-L1',
        subtotal: 12,
        rawReceiptText: 'LOWES PRIVATE COPPER ELBOW 12.00',
        proofLineReferenceLabel: 'Line 1',
      );
      const personalLine = ReceiptLineDraft(
        kind: ReceiptLineKind.expense,
        description: 'Personal snack',
        receiptLineId: 'RCP-77-L2',
        subtotal: 4,
        businessUse: 'personal',
        rawReceiptText: 'LOWES PERSONAL SNACK 4.00',
        proofLineReferenceLabel: 'Line 2',
        clientProofDefaultVisibility:
            ReceiptLineClientProofVisibility.redactByDefault,
      );
      final bundle = ReceiptLineSelectionBundle.fromDrafts(
        receiptId: 'RCP-77',
        purpose: ReceiptLineSelectionPurpose.clientProof,
        sourceLines: const [businessLine, personalLine],
      );

      final event = PrivacySafeReceiptEvent.fromLineSelectionBundle(
        bundle: bundle,
        featureArea: 'job invoice',
      );
      final map = event.toMap();
      final encoded = map.toString().toLowerCase();

      expect(
        map['event'],
        PrivacySafeReceiptEventType.receiptParserReview.name,
      );
      expect(map['featureArea'], 'job_invoice');
      expect(map['selectedReceiptLinePurpose'], 'clientProof');
      expect(map['selectedReceiptLineCount'], 1);
      expect(map['excludedReceiptLineCount'], 1);
      expect(map['clientProofReviewLineCount'], 1);
      expect(map['redactedReceiptLineCount'], 0);
      expect(map['clientProofRedactionPlanStatus'], 'review_required');
      expect(map['clientProofVisibleLineCount'], 0);
      expect(map['clientProofHiddenLineCount'], 1);
      expect(map['clientProofPlanReviewLineCount'], 1);
      expect(encoded, isNot(contains('lowes')));
      expect(encoded, isNot(contains('copper')));
      expect(encoded, isNot(contains('snack')));
      expect(encoded, isNot(contains('12.00')));
      expect(encoded, isNot(contains('4.00')));
    },
  );

  test(
    'client proof image review privacy event reports section counts only',
    () {
      const reviewLine = ReceiptLineDraft(
        kind: ReceiptLineKind.inventory,
        description: 'Private repair part',
        receiptLineId: 'RCP-88-L1',
        subtotal: 18,
        rawReceiptText: 'LOWES PRIVATE REPAIR PART 18.00',
        proofLineReferenceLabel: 'Line 1',
        sourceReceiptSectionLabel: 'Photo 1',
        clientProofDefaultVisibility:
            ReceiptLineClientProofVisibility.reviewBeforeClientShare,
      );
      const hiddenLine = ReceiptLineDraft(
        kind: ReceiptLineKind.expense,
        description: 'Personal drink',
        receiptLineId: 'RCP-88-L2',
        subtotal: 2,
        businessUse: 'personal',
        rawReceiptText: 'LOWES PERSONAL DRINK 2.00',
        proofLineReferenceLabel: 'Line 2',
        sourceReceiptSectionLabel: 'Photo 2',
        clientProofDefaultVisibility:
            ReceiptLineClientProofVisibility.redactByDefault,
      );
      final bundle = ReceiptLineSelectionBundle.fromDrafts(
        receiptId: 'RCP-88',
        purpose: ReceiptLineSelectionPurpose.clientProof,
        sourceLines: const [reviewLine, hiddenLine],
        includeLine: (_) => true,
      );
      final plan = ReceiptClientProofImageReviewPlan.fromRedactionPlan(
        ReceiptClientProofRedactionPlan.fromBundle(bundle),
      );

      final event = PrivacySafeReceiptEvent.fromClientProofImageReviewPlan(
        plan: plan,
        featureArea: 'job invoice',
      );
      final map = event.toMap();
      final encoded = map.toString().toLowerCase();

      expect(
        map['event'],
        PrivacySafeReceiptEventType.receiptParserReview.name,
      );
      expect(map['featureArea'], 'job_invoice');
      expect(map['selectedReceiptLinePurpose'], 'clientProof');
      expect(
        map['clientProofImageReviewStatus'],
        'manual_image_review_required',
      );
      expect(map['clientProofImageSectionCount'], 2);
      expect(map['clientProofImageVisibleSectionCount'], 0);
      expect(map['clientProofImageHiddenSectionCount'], 1);
      expect(map['clientProofImageReviewSectionCount'], 1);
      expect(map['clientProofImageUnassignedLineCount'], 0);
      expect(map['clientProofImageUnassignedHiddenLineCount'], 0);
      expect(map['clientProofImageUnassignedReviewLineCount'], 0);
      expect(encoded, isNot(contains('lowes')));
      expect(encoded, isNot(contains('repair')));
      expect(encoded, isNot(contains('drink')));
      expect(encoded, isNot(contains('18.00')));
      expect(encoded, isNot(contains('2.00')));
    },
  );
}

ReceiptAttachmentRecord _textAttachment({
  required String id,
  required String text,
  List<String> documentSignals = const [],
  List<String> riskFlags = const [],
}) {
  return ReceiptAttachmentRecord(
    id: id,
    path: '',
    kind: ReceiptAttachmentKind.emailText,
    dataSaverLevel: ReceiptDataSaverLevel.balanced,
    createdAt: DateTime(2026, 6, 23),
    importedText: text,
    documentSignals: documentSignals,
    riskFlags: riskFlags,
  );
}
