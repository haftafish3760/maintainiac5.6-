import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';

void expectExpenseParserCategorySummaryTelemetry(
  ExpenseTelemetryHealthSnapshot snapshot,
  Map<String, Object?> map,
  String encoded,
) {
  expect(snapshot.parserCategoryCounts, {
    'fuel': 3,
    'materials': 1,
    'groceries': 3,
  });
  expect(snapshot.parserNeedsReviewCategoryCounts, {'groceries': 2});
  expect(snapshot.parserFailedCategoryCounts, {'maintenance': 1});
  expect(snapshot.parserFieldConfidenceCounts, {
    'merchant_good': 1,
    'total_good': 1,
    'tax_review': 1,
    'total_review': 1,
  });
  expect(snapshot.parserCategoryHealthCounts, {
    'category_fuel_ready': 3,
    'category_materials_ready': 1,
    'category_ready_total': 3,
    'category_groceries_needs_review': 2,
    'category_needs_review_total': 2,
    'category_maintenance_failed': 1,
    'category_failed_total': 1,
  });
  expect(snapshot.parserCategoryReviewActionCounts, {
    'optional_parser_pack_available': 1,
  });
  expect(snapshot.parserPackPressureStatusCounts, {
    'optional_pack_would_help': 1,
  });
  expect(snapshot.receiptBrainParserLimitOutcomeCounts, {
    'optional_parser_pack_deferred_for_storage': 1,
  });
  expect(snapshot.receiptBrainLowStorageDownloadRiskCounts, {
    'base_safe_optional_brain_deferred_for_low_storage': 1,
  });
  expect(snapshot.receiptBrainFullOfflineMustStayOptionalCounts, {'true': 1});
  expect(snapshot.receiptBrainBaseLocalReadingAvailableCounts, {'true': 1});
  expect(snapshot.receiptBrainBaseWorksWithoutCloudAssistCounts, {'true': 1});
  expect(snapshot.receiptBrainLocalFirstReadinessCounts, {
    'lean_local_ready_optional_packs_deferred': 1,
  });
  expect(snapshot.receiptBrainLocalFirstReadinessActionCounts, {
    'keep_capture_and_basic_reader_available': 1,
  });
  expect(snapshot.receiptBrainLocalFirstReadinessSummaryCounts, {'present': 1});
  expect(snapshot.receiptBrainFirstInstallBoundaryCounts, {
    'ready_base_first_optional_local_pack_later': 1,
  });
  expect(snapshot.receiptBrainFirstInstallBoundaryActionCounts, {
    'ship_base_then_offer_optional_local_pack': 1,
  });
  expect(snapshot.receiptBrainFirstInstallCanRunLowStorageCounts, {'true': 1});
  expect(snapshot.receiptBrainFirstInstallRequiresBaseCapabilityCounts, {
    'true': 1,
  });
  expect(snapshot.receiptBrainFirstInstallBoundarySummaryCounts, {
    'present': 1,
  });
  expect(snapshot.receiptInstallRequiredSegmentCounts, {
    'required_base_lean_under_40mb': 1,
  });
  expect(snapshot.receiptInstallFullOfflineSegmentCounts, {
    'full_offline_100_to_250mb_optional': 1,
  });
  expect(snapshot.receiptInstallLowStorageImpactCounts, {
    'low_storage_base_only_optional_pack_hidden': 1,
  });
  expect(snapshot.receiptInstallRecommendedDistributionCounts, {
    'ship_base_hide_large_packs_until_storage_allows': 1,
  });
  expect(snapshot.receiptInstallCameraShellParserFreeCounts, {'true': 1});
  expect(snapshot.receiptInstallBaseUsefulOnTinyPhonesCounts, {'true': 1});
  expect(snapshot.receiptInstallOptionalPacksRequireConsentCounts, {'true': 1});
  expect(snapshot.receiptLocalOnlyAcceptanceStatusCounts, {
    'ready_local_first_optional_packs_deferred': 1,
  });
  expect(snapshot.receiptLocalOnlyAcceptanceActionCounts, {
    'ship_base_capture_save_review_before_optional_packs': 1,
  });
  expect(snapshot.receiptLocalOnlyBaseFlowCanRunCounts, {'true': 1});
  expect(snapshot.receiptLocalOnlyBlocksLowStorageCounts, {'false': 1});
  expect(snapshot.receiptLocalOnlyEvidenceCounts, {
    'capture_available_in_base': 1,
    'proof_save_available_in_base': 1,
    'basic_local_review_available_in_base': 1,
  });
  expect(snapshot.nativeLocalOnlyCapturePolicyCounts, {
    'capture_save_basic_review_now_optional_packs_later': 1,
  });
  expect(snapshot.nativeLocalOnlyBaseFlowCanRunCounts, {'true': 1});
  expect(snapshot.nativeLocalOnlyHeavyPacksMayBlockCaptureCounts, {'false': 1});
  expect(snapshot.nativeLocalOnlyCloudAssistMayBlockCaptureCounts, {
    'false': 1,
  });
  expect(snapshot.parserRequiredFieldStatusCounts, {
    'vendor_ready': 2,
    'date_ready': 2,
    'total_ready': 1,
    'parser_required_ready_total': 3,
    'tax_needs_review': 1,
    'total_needs_review': 1,
    'parser_required_needs_review_total': 2,
    'vendor_missing': 1,
    'date_missing': 1,
    'total_missing': 1,
    'parser_required_missing_total': 3,
  });
  expect(snapshot.parserDownstreamReadinessStatusCounts, {
    'expense_lines_ready': 1,
    'expense_lines_need_review': 1,
    'proof_needs_review': 1,
  });
  expect(snapshot.parserDownstreamReadinessCounts, {
    'parser_downstream_expense_lines_ready': 1,
    'parser_downstream_expense_lines_need_review': 1,
    'parser_downstream_proof_needs_review': 1,
    'vendor_ready': 2,
    'priced_line_ready': 4,
    'total_ready': 1,
    'line_needs_review': 2,
    'vendor_missing': 1,
    'priced_line_missing': 1,
    'total_missing': 1,
  });
  expect(snapshot.localReceiptParserRoutingCounts, {
    'fuel_simple_local': 1,
    'optional_detail_pack_available': 1,
    'manual_receipt_entry': 1,
  });
  expect(snapshot.localParserEvidenceOutcomeCounts, {
    'local_parser_ready': 1,
    'receipt_brain_storage_limited': 1,
    'ocr_readability_limited': 1,
  });
  expect(snapshot.ocrStoragePolicyCounts, {
    'ocr_clear_source_before_saved_proof_copy': 2,
    'ocr_saved_proof_fallback_review_required': 1,
  });
  expect(snapshot.ocrUsesPreparedSourceBeforeSavedProofCounts, {
    'true': 2,
    'false': 1,
  });
  expect(snapshot.ocrUsesSavedProofFallbackCounts, {'false': 2, 'true': 1});
  expect(snapshot.localReceiptParserKeptLocalCount, 1);
  expect(snapshot.localReceiptParserOptionalPackOfferCount, 1);
  expect(snapshot.ocrParserTaskCounts, {
    'vendor_candidate': 1,
    'item_price_ready': 2,
    'total_candidate': 1,
    'tax_missing': 1,
    'item_price_review_required': 2,
    'vendor_missing': 1,
    'item_price_missing': 1,
    'total_missing': 1,
  });
  expect(snapshot.ocrFieldReadinessCounts, {
    'vendor_ready': 1,
    'item_price_ready': 2,
    'total_ready': 1,
    'tax_missing': 1,
    'item_price_needs_review': 2,
    'vendor_missing': 1,
    'item_price_missing': 1,
    'total_missing': 1,
  });
  expect(map['parserCategoryCounts'], snapshot.parserCategoryCounts);
  expect(
    map['parserNeedsReviewCategoryCounts'],
    snapshot.parserNeedsReviewCategoryCounts,
  );
  expect(map['parserFailedCategoryCounts'], {'maintenance': 1});
  expect(
    map['parserCategoryHealthCounts'],
    snapshot.parserCategoryHealthCounts,
  );
  expect(
    map['parserCategoryReviewActionCounts'],
    snapshot.parserCategoryReviewActionCounts,
  );
  expect(
    map['parserPackPressureStatusCounts'],
    snapshot.parserPackPressureStatusCounts,
  );
  expect(
    map['receiptBrainParserLimitOutcomeCounts'],
    snapshot.receiptBrainParserLimitOutcomeCounts,
  );
  expect(
    map['receiptBrainLowStorageDownloadRiskCounts'],
    snapshot.receiptBrainLowStorageDownloadRiskCounts,
  );
  expect(
    map['receiptBrainFullOfflineMustStayOptionalCounts'],
    snapshot.receiptBrainFullOfflineMustStayOptionalCounts,
  );
  expect(
    map['receiptBrainBaseLocalReadingAvailableCounts'],
    snapshot.receiptBrainBaseLocalReadingAvailableCounts,
  );
  expect(
    map['receiptBrainBaseWorksWithoutCloudAssistCounts'],
    snapshot.receiptBrainBaseWorksWithoutCloudAssistCounts,
  );
  expect(
    map['receiptBrainLocalFirstReadinessCounts'],
    snapshot.receiptBrainLocalFirstReadinessCounts,
  );
  expect(
    map['receiptBrainLocalFirstReadinessActionCounts'],
    snapshot.receiptBrainLocalFirstReadinessActionCounts,
  );
  expect(
    map['receiptBrainLocalFirstReadinessSummaryCounts'],
    snapshot.receiptBrainLocalFirstReadinessSummaryCounts,
  );
  expect(
    map['receiptBrainFirstInstallBoundaryCounts'],
    snapshot.receiptBrainFirstInstallBoundaryCounts,
  );
  expect(
    map['receiptBrainFirstInstallBoundaryActionCounts'],
    snapshot.receiptBrainFirstInstallBoundaryActionCounts,
  );
  expect(
    map['receiptBrainFirstInstallCanRunLowStorageCounts'],
    snapshot.receiptBrainFirstInstallCanRunLowStorageCounts,
  );
  expect(
    map['receiptInstallRequiredSegmentCounts'],
    snapshot.receiptInstallRequiredSegmentCounts,
  );
  expect(
    map['receiptInstallFullOfflineSegmentCounts'],
    snapshot.receiptInstallFullOfflineSegmentCounts,
  );
  expect(
    map['receiptInstallLowStorageImpactCounts'],
    snapshot.receiptInstallLowStorageImpactCounts,
  );
  expect(
    map['receiptInstallRecommendedDistributionCounts'],
    snapshot.receiptInstallRecommendedDistributionCounts,
  );
  expect(
    map['receiptInstallBaseUsefulOnTinyPhonesCounts'],
    snapshot.receiptInstallBaseUsefulOnTinyPhonesCounts,
  );
  expect(
    map['receiptLocalOnlyAcceptanceStatusCounts'],
    snapshot.receiptLocalOnlyAcceptanceStatusCounts,
  );
  expect(
    map['receiptLocalOnlyAcceptanceActionCounts'],
    snapshot.receiptLocalOnlyAcceptanceActionCounts,
  );
  expect(
    map['receiptLocalOnlyBaseFlowCanRunCounts'],
    snapshot.receiptLocalOnlyBaseFlowCanRunCounts,
  );
  expect(
    map['receiptLocalOnlyBlocksLowStorageCounts'],
    snapshot.receiptLocalOnlyBlocksLowStorageCounts,
  );
  expect(
    map['receiptLocalOnlyEvidenceCounts'],
    snapshot.receiptLocalOnlyEvidenceCounts,
  );
  expect(
    map['nativeLocalOnlyCapturePolicyCounts'],
    snapshot.nativeLocalOnlyCapturePolicyCounts,
  );
  expect(
    map['nativeLocalOnlyBaseFlowCanRunCounts'],
    snapshot.nativeLocalOnlyBaseFlowCanRunCounts,
  );
  expect(
    map['nativeLocalOnlyHeavyPacksMayBlockCaptureCounts'],
    snapshot.nativeLocalOnlyHeavyPacksMayBlockCaptureCounts,
  );
  expect(
    map['nativeLocalOnlyCloudAssistMayBlockCaptureCounts'],
    snapshot.nativeLocalOnlyCloudAssistMayBlockCaptureCounts,
  );
  expect(
    map['parserRequiredFieldStatusCounts'],
    snapshot.parserRequiredFieldStatusCounts,
  );
  expect(
    map['parserDownstreamReadinessStatusCounts'],
    snapshot.parserDownstreamReadinessStatusCounts,
  );
  expect(
    map['parserDownstreamReadinessCounts'],
    snapshot.parserDownstreamReadinessCounts,
  );
  expect(
    map['localReceiptParserRoutingCounts'],
    snapshot.localReceiptParserRoutingCounts,
  );
  expect(
    map['localParserEvidenceOutcomeCounts'],
    snapshot.localParserEvidenceOutcomeCounts,
  );
  expect(map['ocrStoragePolicyCounts'], snapshot.ocrStoragePolicyCounts);
  expect(
    map['ocrUsesPreparedSourceBeforeSavedProofCounts'],
    snapshot.ocrUsesPreparedSourceBeforeSavedProofCounts,
  );
  expect(
    map['ocrUsesSavedProofFallbackCounts'],
    snapshot.ocrUsesSavedProofFallbackCounts,
  );
  expect(map['localReceiptParserKeptLocalCount'], 1);
  expect(map['localReceiptParserOptionalPackOfferCount'], 1);
  expect(map['ocrParserTaskCounts'], snapshot.ocrParserTaskCounts);
  expect(map['ocrFieldReadinessCounts'], snapshot.ocrFieldReadinessCounts);
  expect(snapshot.topOcrParserTask, 'item_price_ready');
  expect(snapshot.topOcrFieldReadiness, 'item_price_needs_review');
  expect(snapshot.topParserCategoryHealth, 'category_fuel_ready');
  expect(
    snapshot.topParserCategoryReviewAction,
    'optional_parser_pack_available',
  );
  expect(snapshot.topParserPackPressureStatus, 'optional_pack_would_help');
  expect(
    snapshot.topReceiptBrainParserLimitOutcome,
    'optional_parser_pack_deferred_for_storage',
  );
  expect(
    snapshot.topReceiptBrainLowStorageDownloadRisk,
    'base_safe_optional_brain_deferred_for_low_storage',
  );
  expect(
    snapshot.topReceiptBrainLocalFirstReadiness,
    'lean_local_ready_optional_packs_deferred',
  );
  expect(
    snapshot.topReceiptBrainLocalFirstReadinessAction,
    'keep_capture_and_basic_reader_available',
  );
  expect(
    snapshot.topReceiptBrainFirstInstallBoundary,
    'ready_base_first_optional_local_pack_later',
  );
  expect(
    snapshot.topReceiptBrainFirstInstallBoundaryAction,
    'ship_base_then_offer_optional_local_pack',
  );
  expect(
    snapshot.topReceiptLocalOnlyAcceptanceStatus,
    'ready_local_first_optional_packs_deferred',
  );
  expect(
    snapshot.topReceiptLocalOnlyAcceptanceAction,
    'ship_base_capture_save_review_before_optional_packs',
  );
  expect(
    snapshot.topNativeLocalOnlyCapturePolicy,
    'capture_save_basic_review_now_optional_packs_later',
  );
  expect(
    snapshot.topParserRequiredFieldStatus,
    'parser_required_missing_total',
  );
  expect(
    snapshot.topParserDownstreamReadinessStatus,
    'expense_lines_need_review',
  );
  expect(snapshot.topParserDownstreamReadiness, 'priced_line_ready');
  expect(snapshot.topLocalReceiptParserRouting, 'fuel_simple_local');
  expect(snapshot.topLocalParserEvidenceOutcome, 'local_parser_ready');
  expect(
    snapshot.topOcrStoragePolicy,
    'ocr_clear_source_before_saved_proof_copy',
  );
  expect(snapshot.topOcrUsesPreparedSourceBeforeSavedProof, 'true');
  expect(snapshot.topOcrUsesSavedProofFallback, 'false');
  expect(map['topOcrParserTask'], 'item_price_ready');
  expect(map['topOcrFieldReadiness'], 'item_price_needs_review');
  expect(map['topParserCategoryHealth'], 'category_fuel_ready');
  expect(
    map['topParserCategoryReviewAction'],
    'optional_parser_pack_available',
  );
  expect(map['topParserPackPressureStatus'], 'optional_pack_would_help');
  expect(
    map['topReceiptBrainParserLimitOutcome'],
    'optional_parser_pack_deferred_for_storage',
  );
  expect(
    map['topReceiptBrainLowStorageDownloadRisk'],
    'base_safe_optional_brain_deferred_for_low_storage',
  );
  expect(
    map['topReceiptBrainLocalFirstReadiness'],
    'lean_local_ready_optional_packs_deferred',
  );
  expect(
    map['topReceiptBrainLocalFirstReadinessAction'],
    'keep_capture_and_basic_reader_available',
  );
  expect(
    map['topReceiptBrainFirstInstallBoundary'],
    'ready_base_first_optional_local_pack_later',
  );
  expect(
    map['topReceiptBrainFirstInstallBoundaryAction'],
    'ship_base_then_offer_optional_local_pack',
  );
  expect(
    map['topReceiptInstallRecommendedDistribution'],
    'ship_base_hide_large_packs_until_storage_allows',
  );
  expect(
    map['topReceiptInstallLowStorageImpact'],
    'low_storage_base_only_optional_pack_hidden',
  );
  expect(
    map['topReceiptLocalOnlyAcceptanceStatus'],
    'ready_local_first_optional_packs_deferred',
  );
  expect(
    map['topReceiptLocalOnlyAcceptanceAction'],
    'ship_base_capture_save_review_before_optional_packs',
  );
  expect(
    map['topNativeLocalOnlyCapturePolicy'],
    'capture_save_basic_review_now_optional_packs_later',
  );
  expect(map['topParserRequiredFieldStatus'], 'parser_required_missing_total');
  expect(map['topLocalReceiptParserRouting'], 'fuel_simple_local');
  expect(map['topLocalParserEvidenceOutcome'], 'local_parser_ready');
  expect(
    map['topOcrStoragePolicy'],
    'ocr_clear_source_before_saved_proof_copy',
  );
  expect(map['topOcrUsesPreparedSourceBeforeSavedProof'], 'true');
  expect(map['topOcrUsesSavedProofFallback'], 'false');
  expect(
    map['topParserDownstreamReadinessStatus'],
    'expense_lines_need_review',
  );
  expect(map['topParserDownstreamReadiness'], 'priced_line_ready');
  expect(map['topParserCategory'], 'fuel');
  expect(map['topParserNeedsReviewCategory'], 'groceries');
  expect(map['topParserFailedCategory'], 'maintenance');
  expect(encoded, isNot(contains('lowes')));
  expect(encoded, isNot(contains('receipttext')));
  expect(encoded, isNot(contains('merchantname')));
}
