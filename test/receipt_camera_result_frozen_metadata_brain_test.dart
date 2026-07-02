import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

import 'helpers/receipt_camera_result_frozen_fixture.dart';

void main() {
  test('accepted review freezes privacy-safe receipt brain metadata', () {
    final fixture = frozenReceiptCameraDiagnosticsFixture();
    final result = fixture.result;
    final handoffMetadata = result.privacySafeReceiptReaderHandoffMetadata;

    expect(
      handoffMetadata,
      containsPair('receiptReaderHandoffOutcome', 'ready_for_receipt_review'),
    );
    expect(
      handoffMetadata,
      containsPair('receiptDetailsHandoffOutcome', 'ready_for_receipt_review'),
    );
    expect(
      handoffMetadata,
      containsPair('receiptBrainReleaseActionCounts', {
        'ship_lean_base_offer_explicit_receipt_pack_download': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair(
        'receiptBrainReleaseActionOutcome',
        'ship_lean_base_offer_explicit_receipt_pack_download',
      ),
    );
    expect(
      handoffMetadata,
      containsPair('receiptBrainInstallDistributionCounts', {
        'base_app_explicit_optional_receipt_packs': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair(
        'receiptBrainInstallDistributionOutcome',
        'base_app_explicit_optional_receipt_packs',
      ),
    );
    expect(
      handoffMetadata,
      containsPair('receiptBrainStorageClassCounts', {'comfortable': 1}),
    );
    expect(
      handoffMetadata,
      containsPair('receiptBrainLocalOcrModeCounts', {'full_local_ocr': 1}),
    );
    expect(
      handoffMetadata,
      containsPair('receiptBrainBaseSizeDecisionCounts', {
        'base_size_ready': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair('receiptBrainBaseSizeDecisionOutcome', 'base_size_ready'),
    );
    expect(
      handoffMetadata,
      containsPair('receiptBrainFirstInstallBoundaryCounts', {
        'ready_base_first_optional_local_pack_later': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair(
        'receiptBrainFirstInstallBoundaryOutcome',
        'ready_base_first_optional_local_pack_later',
      ),
    );
    expect(
      handoffMetadata,
      containsPair('receiptBrainFirstInstallBoundaryActionCounts', {
        'ship_base_then_offer_optional_local_pack': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair('receiptBrainFirstInstallCanRunLowStorageCounts', {
        'true': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair('receiptBrainBaseNeedsSizeReviewCounts', {'false': 1}),
    );
    expect(
      handoffMetadata,
      containsPair('receiptBrainBaseBlocksLowStorageCounts', {'false': 1}),
    );
    expect(
      handoffMetadata,
      containsPair('receiptBrainFullOfflineExceedsBaseGuardrailCounts', {
        'true': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair('receiptBrainFullOfflineMustStayOptionalCounts', {
        'true': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair('receiptBrainLowStorageDownloadRiskCounts', {
        'full_offline_large_optional_only': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair(
        'receiptBrainLowStorageDownloadRiskOutcome',
        'full_offline_large_optional_only',
      ),
    );
    expect(
      handoffMetadata,
      containsPair('receiptInstallRequiredSegmentCounts', {
        'required_base_lean_under_40mb': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair(
        'receiptInstallRequiredSegmentOutcome',
        'required_base_lean_under_40mb',
      ),
    );
    expect(
      handoffMetadata,
      containsPair('receiptInstallFullOfflineSegmentCounts', {
        'full_offline_100_to_250mb_optional': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair('receiptInstallLowStorageImpactCounts', {
        'low_storage_base_only_optional_pack_hidden': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair('receiptInstallRecommendedDistributionCounts', {
        'ship_base_hide_large_packs_until_storage_allows': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair('receiptInstallCameraShellParserFreeCounts', {'true': 1}),
    );
    expect(
      handoffMetadata,
      containsPair('receiptInstallBaseUsefulOnTinyPhonesCounts', {'true': 1}),
    );
    expect(
      handoffMetadata,
      containsPair('receiptInstallOptionalPacksRequireConsentCounts', {
        'true': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair('receiptBrainRequiredBasePayloadCounts', {
        'native_receipt_camera': 1,
        'receipt_proof_storage': 1,
        'basic_local_receipt_reader': 1,
        'manual_receipt_entry': 1,
        'data_saver_proof_copies': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair('receiptBrainOptionalPayloadCounts', {
        'general_expense_lines_v1': 1,
        'materials_inventory_regional_v1': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair('receiptBrainBaseShipWithoutFullOfflineCounts', {'true': 1}),
    );
    expect(
      handoffMetadata,
      containsPair('receiptBrainBaseVersusFullOfflineSummaryCounts', {
        'present': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair('receiptBrainOptionalPackUserChoiceCounts', {'true': 1}),
    );
    expect(
      handoffMetadata,
      containsPair('receiptBrainBaseLocalReadingAvailableCounts', {'true': 1}),
    );
    expect(
      handoffMetadata,
      containsPair('receiptBrainBaseWorksWithoutCloudAssistCounts', {
        'true': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair('receiptBrainLocalFirstReadinessCounts', {
        'lean_local_ready_optional_packs_deferred': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair(
        'receiptBrainLocalFirstReadinessOutcome',
        'lean_local_ready_optional_packs_deferred',
      ),
    );
  });
}
