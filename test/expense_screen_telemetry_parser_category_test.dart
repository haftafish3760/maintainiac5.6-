import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';

import 'helpers/expense_parser_category_summary_expectations.dart';
import 'helpers/expense_screen_telemetry_harness.dart';

void main() {
  installExpenseTelemetryHiveLifecycle('expense_screen_telemetry_test_');

  test(
    'summarizes parser category health for Command 1 without receipt content',
    () async {
      final store = await ExpenseTelemetryStore.create();
      final context = expenseTelemetryContextFixture();

      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.parserCompleted,
          context: context,
          categoryGroup: 'fuel',
          metadata: const {
            'source': 'expenses',
            'parserDepth': 'inventoryMatching',
            'lineCount': 3,
            'parsedCategoryBuckets': {'fuel': 2, 'materials': 1},
            'parserFieldConfidenceBuckets': {
              'merchant_good': 1,
              'total_good': 1,
            },
            'parserCategoryHealthCounts': {
              'category_fuel_ready': 2,
              'category_materials_ready': 1,
              'category_ready_total': 3,
            },
            'parserRequiredFieldStatusCounts': {
              'vendor_ready': 1,
              'date_ready': 1,
              'total_ready': 1,
              'parser_required_ready_total': 3,
            },
            'parserDownstreamReadinessStatus': 'expense_lines_ready',
            'parserDownstreamReadinessCounts': {
              'parser_downstream_expense_lines_ready': 1,
              'vendor_ready': 1,
              'priced_line_ready': 2,
              'total_ready': 1,
            },
            'localReceiptParserRoutingCode': 'fuel_simple_local',
            'localReceiptParserRoutingCounts': {'fuel_simple_local': 1},
            'localParserEvidenceOutcome': 'local_parser_ready',
            'ocrStoragePolicyCounts': {
              'ocr_clear_source_before_saved_proof_copy': 1,
            },
            'ocrUsesPreparedSourceBeforeSavedProofCounts': {'true': 1},
            'ocrUsesSavedProofFallbackCounts': {'false': 1},
            'localReceiptParserKeptLocalCount': 1,
            'localReceiptParserOptionalPackOfferCount': 0,
            'ocrParserTaskCounts': {
              'vendor_candidate': 1,
              'item_price_ready': 2,
              'total_candidate': 1,
            },
            'ocrFieldReadinessCounts': {
              'vendor_ready': 1,
              'item_price_ready': 2,
              'total_ready': 1,
            },
            'parseQualityBucket': 'high',
            'parserLineReviewCount': 0,
            'subtotalReconciliationStatus': 'matched',
            'taxMathStatus': 'matched',
          },
        ),
      );
      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.parserNeedsReview,
          context: context,
          categoryGroup: 'groceries',
          metadata: const {
            'source': 'expenses',
            'parserDepth': 'inventoryMatching',
            'lineCount': 4,
            'parsedCategoryBuckets': {'groceries': 3, 'fuel': 1},
            'reviewCategoryBuckets': {'groceries': 2},
            'parserFieldConfidenceBuckets': {
              'tax_review': 1,
              'total_review': 1,
            },
            'parserCategoryHealthCounts': {
              'category_groceries_needs_review': 2,
              'category_fuel_ready': 1,
              'category_needs_review_total': 2,
            },
            'parserCategoryReviewActionCode': 'optional_parser_pack_available',
            'parserPackPressureStatus': 'optional_pack_would_help',
            'receiptBrainParserLimitOutcome':
                'optional_parser_pack_deferred_for_storage',
            'receiptBrainLowStorageDownloadRiskCounts': {
              'base_safe_optional_brain_deferred_for_low_storage': 1,
            },
            'receiptBrainFullOfflineMustStayOptionalCounts': {'true': 1},
            'receiptBrainBaseLocalReadingAvailableCounts': {'true': 1},
            'receiptBrainBaseWorksWithoutCloudAssistCounts': {'true': 1},
            'receiptBrainLocalFirstReadinessCounts': {
              'lean_local_ready_optional_packs_deferred': 1,
            },
            'receiptBrainLocalFirstReadinessActionCounts': {
              'keep_capture_and_basic_reader_available': 1,
            },
            'receiptBrainLocalFirstReadinessSummaryCounts': {'present': 1},
            'receiptBrainFirstInstallBoundaryCounts': {
              'ready_base_first_optional_local_pack_later': 1,
            },
            'receiptBrainFirstInstallBoundaryActionCounts': {
              'ship_base_then_offer_optional_local_pack': 1,
            },
            'receiptBrainFirstInstallCanRunLowStorageCounts': {'true': 1},
            'receiptBrainFirstInstallRequiresBaseCapabilityCounts': {'true': 1},
            'receiptBrainFirstInstallBoundarySummaryCounts': {'present': 1},
            'receiptInstallRequiredSegmentCounts': {
              'required_base_lean_under_40mb': 1,
            },
            'receiptInstallFullOfflineSegmentCounts': {
              'full_offline_100_to_250mb_optional': 1,
            },
            'receiptInstallLowStorageImpactCounts': {
              'low_storage_base_only_optional_pack_hidden': 1,
            },
            'receiptInstallRecommendedDistributionCounts': {
              'ship_base_hide_large_packs_until_storage_allows': 1,
            },
            'receiptInstallCameraShellParserFreeCounts': {'true': 1},
            'receiptInstallBaseUsefulOnTinyPhonesCounts': {'true': 1},
            'receiptInstallOptionalPacksRequireConsentCounts': {'true': 1},
            'receiptLocalOnlyAcceptanceStatusCounts': {
              'ready_local_first_optional_packs_deferred': 1,
            },
            'receiptLocalOnlyAcceptanceActionCounts': {
              'ship_base_capture_save_review_before_optional_packs': 1,
            },
            'receiptLocalOnlyBaseFlowCanRunCounts': {'true': 1},
            'receiptLocalOnlyBlocksLowStorageCounts': {'false': 1},
            'receiptLocalOnlyEvidenceCounts': {
              'capture_available_in_base': 1,
              'proof_save_available_in_base': 1,
              'basic_local_review_available_in_base': 1,
            },
            'nativeLocalOnlyCapturePolicyCounts': {
              'capture_save_basic_review_now_optional_packs_later': 1,
            },
            'nativeLocalOnlyBaseFlowCanRunCounts': {'true': 1},
            'nativeLocalOnlyHeavyPacksMayBlockCaptureCounts': {'false': 1},
            'nativeLocalOnlyCloudAssistMayBlockCaptureCounts': {'false': 1},
            'parserRequiredFieldStatusCounts': {
              'vendor_ready': 1,
              'date_ready': 1,
              'tax_needs_review': 1,
              'total_needs_review': 1,
              'parser_required_needs_review_total': 2,
            },
            'parserDownstreamReadinessStatus': 'expense_lines_need_review',
            'parserDownstreamReadinessCounts': {
              'parser_downstream_expense_lines_need_review': 1,
              'vendor_ready': 1,
              'priced_line_ready': 2,
              'line_needs_review': 2,
            },
            'localReceiptParserRoutingCode': 'optional_detail_pack_available',
            'localReceiptParserRoutingCounts': {
              'optional_detail_pack_available': 1,
            },
            'localParserEvidenceOutcome': 'receipt_brain_storage_limited',
            'ocrStoragePolicyCounts': {
              'ocr_clear_source_before_saved_proof_copy': 1,
            },
            'ocrUsesPreparedSourceBeforeSavedProofCounts': {'true': 1},
            'ocrUsesSavedProofFallbackCounts': {'false': 1},
            'localReceiptParserKeptLocalCount': 0,
            'localReceiptParserOptionalPackOfferCount': 1,
            'ocrParserTaskCounts': {
              'tax_missing': 1,
              'item_price_review_required': 2,
            },
            'ocrFieldReadinessCounts': {
              'tax_missing': 1,
              'item_price_needs_review': 2,
            },
            'parseQualityBucket': 'medium',
            'parserLineReviewCount': 2,
            'subtotalReconciliationStatus': 'needs_review',
            'taxMathStatus': 'needs_review',
          },
        ),
      );
      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.parserFailed,
          context: context,
          categoryGroup: 'maintenance',
          failureKind: 'receipt_parser_no_usable_fields',
          diagnostic: const ExpenseFailureDiagnostic(
            workflowStep: ExpenseWorkflowStep.receiptParser,
            failedAt: 'parser_after_ocr',
            confirmedCause: 'receipt_parser_no_usable_fields',
            causeStatus: ExpenseFailureCauseStatus.confirmed,
            evidence: 'no_fields_detected',
          ),
          metadata: const {
            'source': 'expenses',
            'parserDepth': 'inventoryMatching',
            'lineCount': 0,
            'parsedCategoryBuckets': {'maintenance': 1},
            'parserCategoryHealthCounts': {
              'category_maintenance_failed': 1,
              'category_failed_total': 1,
            },
            'parserRequiredFieldStatusCounts': {
              'vendor_missing': 1,
              'date_missing': 1,
              'total_missing': 1,
              'parser_required_missing_total': 3,
            },
            'parserDownstreamReadinessStatus': 'proof_needs_review',
            'parserDownstreamReadinessCounts': {
              'parser_downstream_proof_needs_review': 1,
              'vendor_missing': 1,
              'priced_line_missing': 1,
              'total_missing': 1,
            },
            'localReceiptParserRoutingCode': 'manual_receipt_entry',
            'localReceiptParserRoutingCounts': {'manual_receipt_entry': 1},
            'localParserEvidenceOutcome': 'ocr_readability_limited',
            'ocrStoragePolicyOutcome':
                'ocr_saved_proof_fallback_review_required',
            'ocrUsesPreparedSourceBeforeSavedProofCounts': {'false': 1},
            'ocrUsesSavedProofFallbackCounts': {'true': 1},
            'localReceiptParserKeptLocalCount': 0,
            'localReceiptParserOptionalPackOfferCount': 0,
            'ocrParserTaskCounts': {
              'vendor_missing': 1,
              'item_price_missing': 1,
              'total_missing': 1,
            },
            'ocrFieldReadinessCounts': {
              'vendor_missing': 1,
              'item_price_missing': 1,
              'total_missing': 1,
            },
            'parseQualityBucket': 'very_low',
          },
        ),
      );
      final snapshot = store.buildHealthSnapshot(
        nowUtc: DateTime.utc(2026, 6, 24, 13),
      );
      final map = snapshot.toCommandCenterMap();
      final encoded = map.toString().toLowerCase();

      expectExpenseParserCategorySummaryTelemetry(snapshot, map, encoded);
    },
  );
}
