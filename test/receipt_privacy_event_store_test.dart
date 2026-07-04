import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_privacy_event_store.dart';

import 'helpers/receipt_privacy_health_fixture.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'receipt_privacy_event_store_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test(
    'builds command center health snapshot without raw event details',
    () async {
      final store = await PrivacySafeReceiptEventStore.create();
      final parseRecord = await enqueueReceiptPrivacyHealthFixture(store);

      final snapshot = store.buildHealthSnapshot(
        nowUtc: DateTime.utc(2026, 6, 23, 17),
      );
      final map = snapshot.toCommandCenterMap();

      expect(map['schema'], 'receipt_privacy_health_v1');
      expect(map['totalEventCount'], 2);
      expect(map['pendingUploadCount'], 1);
      expect(map['uploadedEventCount'], 1);
      expect(map['healthLabel'], isNot('healthy'));
      expect(snapshot.needsAttention, isTrue);
      expect(snapshot.duplicateOrOverlapCount, 1);
      expect(snapshot.ocrItemCandidateLineCount, 3);
      expect(snapshot.ocrPricedLineCount, 6);
      expect(snapshot.ocrParserReadyLineCount, 2);
      expect(snapshot.ocrParserReviewSignalCount, 3);
      expect(snapshot.ocrParserReadinessStatusCounts['needs_review'], 1);
      expect(
        snapshot.ocrDownstreamReadinessStatusCounts['inventory_material_ready'],
        1,
      );
      expect(
        snapshot.ocrDownstreamReadinessCounts['downstreamReadyItemLineCount'],
        2,
      );
      expect(
        snapshot.ocrDownstreamReadinessCounts['downstreamReviewItemLineCount'],
        1,
      );
      expect(
        snapshot
            .ocrDownstreamReadinessCounts['downstreamInventoryPrepLineCount'],
        2,
      );
      expect(snapshot.ocrParserLineRoleCounts['item'], greaterThanOrEqualTo(3));
      expect(
        snapshot.ocrParserLineRoleCounts['summary'],
        greaterThanOrEqualTo(3),
      );
      expect(snapshot.ocrDominantParserLineRoleCounts['metadata'], 1);
      expect(snapshot.ocrStableLineIdCount, 10);
      expect(snapshot.ocrParserReadyItemLineIdCount, 2);
      expect(snapshot.ocrReviewItemLineIdCount, 1);
      expect(snapshot.ocrParserBucketCounts['item_ready'], 2);
      expect(snapshot.ocrParserBucketCounts['item_needs_review'], 1);
      expect(snapshot.ocrParserBucketCounts['summary_ready'], 3);
      expect(snapshot.ocrParserTaskCounts['vendor_candidate'], 1);
      expect(snapshot.ocrParserTaskCounts['item_price_ready'], 2);
      expect(snapshot.ocrParserTaskCounts['item_price_needs_review'], 1);
      expect(snapshot.ocrParserTaskCounts['inventory_material_candidate'], 2);
      expect(
        snapshot
            .clientProofRedactionStatusCounts['needs_client_redaction_review'],
        1,
      );
      expect(
        snapshot.clientProofVisibilityCounts['review_for_client_proof'],
        8,
      );
      expect(snapshot.clientProofVisibilityCounts['redact_by_default'], 2);
      expect(
        snapshot.clientProofVisibilityCounts['review_before_client_share'],
        1,
      );
      expect(snapshot.selectedReceiptLinePurposeCounts['clientProof'], 1);
      expect(snapshot.selectedReceiptLineCount, 6);
      expect(snapshot.excludedReceiptLineCount, 4);
      expect(snapshot.clientProofReviewLineCount, 3);
      expect(snapshot.redactedReceiptLineCount, 2);
      expect(
        snapshot.clientProofRedactionPlanStatusCounts['review_required'],
        1,
      );
      expect(snapshot.clientProofVisibleLineCount, 1);
      expect(snapshot.clientProofHiddenLineCount, 6);
      expect(snapshot.clientProofPlanReviewLineCount, 3);
      expect(
        snapshot
            .clientProofLayoutRedactionStatusCounts['ignored_unknown_lines'],
        1,
      );
      expect(snapshot.clientProofLayoutVisibleLineCount, 2);
      expect(snapshot.clientProofLayoutHiddenLineCount, 6);
      expect(snapshot.clientProofLayoutIgnoredLineCount, 1);
      expect(snapshot.clientProofLayoutProtectedTypeCount, 2);
      expect(snapshot.clientProofLayoutMerchantContextCount, 1);
      expect(snapshot.clientProofLayoutTotalsContextCount, 0);
      expect(
        snapshot
            .clientProofImageReviewStatusCounts['manual_image_review_required'],
        1,
      );
      expect(snapshot.clientProofImageSectionCount, 3);
      expect(snapshot.clientProofImageVisibleSectionCount, 1);
      expect(snapshot.clientProofImageHiddenSectionCount, 2);
      expect(snapshot.clientProofImageReviewSectionCount, 1);
      expect(snapshot.clientProofImageUnassignedLineCount, 2);
      expect(snapshot.clientProofImageUnassignedHiddenLineCount, 1);
      expect(snapshot.clientProofImageUnassignedReviewLineCount, 1);
      expect(snapshot.ocrHighConfidenceItemLineCount, 2);
      expect(snapshot.ocrReviewItemLineCount, 1);
      expect(snapshot.ocrQuantitySignalItemLineCount, 2);
      expect(snapshot.ocrSkuSignalItemLineCount, 2);
      expect(snapshot.ocrGenericItemLineCount, 1);
      expect(snapshot.ocrInventoryPrepLineIdCount, 2);
      expect(snapshot.ocrParserReadyFieldCount, 5);
      expect(snapshot.ocrParserReviewFieldCount, 1);
      expect(snapshot.ocrFieldReadinessCounts['vendor_ready'], 1);
      expect(snapshot.ocrFieldReadinessCounts['item_price_ready'], 2);
      expect(
        snapshot.ocrFieldReadinessCounts['inventory_material_candidate'],
        2,
      );
      expect(snapshot.ocrSummaryMathStatusCounts['mismatch'], 1);
      expect(snapshot.ocrSummaryMathMismatchCount, 1);
      expect(snapshot.ocrLineSequenceStatusCounts['summary_before_items'], 1);
      expect(snapshot.ocrLineSequenceStatusCounts['unknown'], 1);
      expect(snapshot.ocrLineSequenceReviewCount, 1);
      expect(
        snapshot.ocrReceiptStructureStatusCounts['line_sequence_review'],
        1,
      );
      expect(snapshot.ocrReceiptStructureStatusCounts['unknown'], 1);
      expect(snapshot.ocrReceiptStructureReviewCount, 1);
      expect(snapshot.ocrSourceSectionContinuityStatusCounts['section_gap'], 1);
      expect(snapshot.ocrSourceSectionContinuityStatusCounts['unknown'], 1);
      expect(snapshot.ocrSourceSectionReviewCount, 1);
      expect(snapshot.ocrSourceSectionCount, 3);
      expect(snapshot.ocrSubtotalCandidateLineCount, 1);
      expect(snapshot.ocrTaxCandidateLineCount, 1);
      expect(snapshot.ocrTotalCandidateLineCount, 1);
      expect(snapshot.ocrTenderCandidateLineCount, 2);
      expect(snapshot.ocrMetadataCandidateLineCount, 4);
      expect(snapshot.pdfPagesRequested, 2);
      expect(snapshot.heavyReviewCount, 1);
      expect(snapshot.taxMathMismatchCount, 0);
      expect(
        snapshot.eventCounts[PrivacySafeReceiptEventType.receiptOcrReview.name],
        1,
      );
      expect(snapshot.featureAreaCounts['materials_inventory'], 1);
      expect(snapshot.warningKindCounts['duplicateText'], 1);
      expect(snapshot.parserTrustCounts, isNotEmpty);
      expect(snapshot.totalsMathStatusCounts, isNotEmpty);
      expect(snapshot.parserReviewCauseCounts, isNotEmpty);
      expect(snapshot.fieldReviewKeyCounts, isNotEmpty);
      expect(snapshot.parserCategoryCounts, isNotEmpty);
      expect(snapshot.parserCategoryHealthCounts, isNotEmpty);
      expect(
        snapshot.parserCategoryReviewActionCounts,
        containsPair('review_low_confidence_lines', 1),
      );
      expect(snapshot.parserRequiredFieldStatusCounts, isNotEmpty);
      expect(
        snapshot.parserDownstreamReadinessStatusCounts,
        containsPair('expense_lines_need_review', 1),
      );
      expect(
        snapshot.parserDownstreamReadinessCounts,
        containsPair('parser_downstream_expense_lines_need_review', 1),
      );
      expect(
        snapshot.parserDownstreamReadinessCounts,
        containsPair('vendor_ready', 1),
      );
      expect(snapshot.localReceiptParserRoutingCounts, isNotEmpty);
      expect(
        map['localReceiptParserRoutingCounts'],
        snapshot.localReceiptParserRoutingCounts,
      );
      expect(
        map['localReceiptParserKeptLocalCount'],
        snapshot.localReceiptParserKeptLocalCount,
      );
      expect(
        map['localReceiptParserOptionalPackOfferCount'],
        snapshot.localReceiptParserOptionalPackOfferCount,
      );
      expect(snapshot.ocrAttemptCount, 1);
      expect(snapshot.ocrReadableRate, 1);
      expect(snapshot.ocrFailRate, 0);
      expect(snapshot.parserAttemptCount, 1);
      expect(snapshot.parserSuccessRate, 0);
      expect(snapshot.parserProblemRate, 1);
      expect(map['heavyReviewCount'], 1);
      expect(map['taxMathMismatchCount'], 0);
      expect(map['ocrReadableRate'], 1);
      expect(map['parserProblemRate'], 1);
      expect(map['ocrItemCandidateLineCount'], 3);
      expect(map['ocrPricedLineCount'], 6);
      expect(map['ocrParserReadyLineCount'], 2);
      expect(map['ocrParserReviewSignalCount'], 3);
      expect(map['ocrStableLineIdCount'], 10);
      expect(map['ocrParserReadyItemLineIdCount'], 2);
      expect(map['ocrReviewItemLineIdCount'], 1);
      expect(map['ocrInventoryPrepLineIdCount'], 2);
      expect(map['ocrParserReadyFieldCount'], 5);
      expect(map['ocrParserReviewFieldCount'], 1);
      expect(
        map['ocrParserBucketCounts'],
        containsPair('item_needs_review', 1),
      );
      expect(
        map['ocrParserTaskCounts'],
        containsPair('inventory_material_candidate', 2),
      );
      expect(
        map['clientProofRedactionStatusCounts'],
        containsPair('needs_client_redaction_review', 1),
      );
      expect(
        map['clientProofVisibilityCounts'],
        containsPair('review_for_client_proof', 8),
      );
      expect(
        map['clientProofVisibilityCounts'],
        containsPair('redact_by_default', 2),
      );
      expect(
        map['clientProofRedactionPlanStatusCounts'],
        containsPair('review_required', 1),
      );
      expect(map['clientProofVisibleLineCount'], 1);
      expect(map['clientProofHiddenLineCount'], 6);
      expect(map['clientProofPlanReviewLineCount'], 3);
      expect(
        map['clientProofLayoutRedactionStatusCounts'],
        containsPair('ignored_unknown_lines', 1),
      );
      expect(map['clientProofLayoutVisibleLineCount'], 2);
      expect(map['clientProofLayoutHiddenLineCount'], 6);
      expect(map['clientProofLayoutIgnoredLineCount'], 1);
      expect(map['clientProofLayoutProtectedTypeCount'], 2);
      expect(map['clientProofLayoutMerchantContextCount'], 1);
      expect(map['clientProofLayoutTotalsContextCount'], 0);
      expect(
        map['clientProofImageReviewStatusCounts'],
        containsPair('manual_image_review_required', 1),
      );
      expect(map['clientProofImageSectionCount'], 3);
      expect(map['clientProofImageVisibleSectionCount'], 1);
      expect(map['clientProofImageHiddenSectionCount'], 2);
      expect(map['clientProofImageReviewSectionCount'], 1);
      expect(map['clientProofImageUnassignedLineCount'], 2);
      expect(map['clientProofImageUnassignedHiddenLineCount'], 1);
      expect(map['clientProofImageUnassignedReviewLineCount'], 1);
      expect(
        map['ocrFieldReadinessCounts'],
        containsPair('inventory_material_candidate', 2),
      );
      expect(
        map['ocrParserReadinessStatusCounts'],
        containsPair('needs_review', 1),
      );
      expect(
        map['ocrDownstreamReadinessStatusCounts'],
        containsPair('inventory_material_ready', 1),
      );
      expect(
        map['ocrDownstreamReadinessCounts'],
        containsPair('downstreamReadyItemLineCount', 2),
      );
      final parserRoleCounts =
          map['parserLineRoleCounts'] as Map<String, Object?>;
      expect(parserRoleCounts['item'], greaterThanOrEqualTo(1));
      expect(parserRoleCounts['vendor'], 1);
      final parserTaskCounts = map['parserTaskCounts'] as Map<String, Object?>;
      expect(parserTaskCounts['vendor_detected'], 1);
      expect(parserTaskCounts['total_detected'], 1);
      final parserCategoryCounts =
          map['parserCategoryCounts'] as Map<String, Object?>;
      expect(parserCategoryCounts, isNotEmpty);
      final parserCategoryHealthCounts =
          map['parserCategoryHealthCounts'] as Map<String, Object?>;
      expect(parserCategoryHealthCounts, isNotEmpty);
      final parserRequiredCounts =
          map['parserRequiredFieldStatusCounts'] as Map<String, Object?>;
      expect(parserRequiredCounts['vendor_ready'], 1);
      expect(parserRequiredCounts['date_ready'], 1);
      expect(parserRequiredCounts['total_ready'], 1);
      expect(
        map['parserDownstreamReadinessStatusCounts'],
        containsPair('expense_lines_need_review', 1),
      );
      expect(
        map['parserDownstreamReadinessCounts'],
        containsPair('parser_downstream_expense_lines_need_review', 1),
      );
      final snapshotRoleCounts =
          map['ocrParserLineRoleCounts'] as Map<String, Object?>;
      expect(snapshotRoleCounts['item'], greaterThanOrEqualTo(3));
      expect(snapshotRoleCounts['summary'], greaterThanOrEqualTo(3));
      expect(map['ocrDominantParserLineRoleCounts'], {'metadata': 1});
      expect(map['ocrHighConfidenceItemLineCount'], 2);
      expect(map['ocrReviewItemLineCount'], 1);
      expect(map['ocrQuantitySignalItemLineCount'], 2);
      expect(map['ocrSkuSignalItemLineCount'], 2);
      expect(map['ocrGenericItemLineCount'], 1);
      expect(map['ocrSummaryMathStatusCounts'], {
        'mismatch': 1,
        'incomplete': 1,
      });
      expect(map['ocrLineSequenceStatusCounts'], {
        'summary_before_items': 1,
        'unknown': 1,
      });
      expect(map['ocrReceiptStructureStatusCounts'], {
        'line_sequence_review': 1,
        'unknown': 1,
      });
      expect(map['ocrSourceSectionContinuityStatusCounts'], {
        'section_gap': 1,
        'unknown': 1,
      });
      expect(map['ocrSummaryMathMismatchCount'], 1);
      expect(map['ocrLineSequenceReviewCount'], 1);
      expect(map['ocrReceiptStructureReviewCount'], 1);
      expect(map['ocrSourceSectionReviewCount'], 1);
      expect(map['ocrSourceSectionCount'], 3);
      expect(map['ocrSubtotalCandidateLineCount'], 1);
      expect(map['ocrTaxCandidateLineCount'], 1);
      expect(map['ocrTotalCandidateLineCount'], 1);
      expect(map['ocrTenderCandidateLineCount'], 2);
      expect(map['ocrMetadataCandidateLineCount'], 4);
      expect(map['parserReviewCauseCounts'], isNotEmpty);
      expect(map['parserCategoryReviewActionCounts'], isNotEmpty);
      expect(map['fieldReviewKeyCounts'], isNotEmpty);

      final encoded = map.toString().toLowerCase();
      expect(encoded, isNot(contains(parseRecord.id.toLowerCase())));
      expect(encoded, isNot(contains('private supply')));
      expect(encoded, isNot(contains('secret job')));
      expect(encoded, isNot(contains('12.34')));
      expect(encoded, isNot(contains('99.99')));
      expect(encoded, isNot(contains('customer')));
    },
  );
}
