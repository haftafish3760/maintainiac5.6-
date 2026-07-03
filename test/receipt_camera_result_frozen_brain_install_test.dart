import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

import 'helpers/receipt_camera_result_frozen_fixture.dart';

void main() {
  test(
    'native review depth does not downgrade detailed multi-photo intent',
    () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/section-1.jpg', '/tmp/section-2.jpg'],
        ocrSourcePhotoPaths: const ['/tmp/section-1.jpg', '/tmp/section-2.jpg'],
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        stitchResult: const ReceiptStitchResult.notNeeded([
          '/tmp/section-1.jpg',
          '/tmp/section-2.jpg',
        ]),
        captureDiagnosticsByPhotoPath: const {
          '/tmp/section-1.jpg': {'reviewDepth': 'pricesOnly'},
          '/tmp/section-2.jpg': {'reviewDepth': 'detailedLines'},
        },
      );

      expect(result.nativeReceiptReviewDepth, 'detailedLines');
      expect(result.nativeReceiptReviewDepthCounts, {
        'pricesOnly': 1,
        'detailedLines': 1,
      });
      expect(
        result.privacySafeReceiptReaderHandoffMetadata,
        containsPair('nativeReceiptReviewDepth', 'detailedLines'),
      );
      expect(
        result.privacySafeReceiptReaderHandoffMetadata,
        containsPair('nativeReceiptReviewDepthCounts', {
          'pricesOnly': 1,
          'detailedLines': 1,
        }),
      );
    },
  );

  test('malformed native review depth is visible in safe metadata', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/section-1.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/section-1.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded(['/tmp/section-1.jpg']),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/section-1.jpg': {'reviewDepth': 'full receipt text please'},
      },
    );

    expect(result.nativeReceiptReviewDepth, 'pricesOnly');
    expect(result.nativeReceiptReviewDepthCounts, {
      'invalid_full_receipt_text_please': 1,
    });
    expect(
      result.privacySafeReceiptReaderHandoffMetadata,
      containsPair('nativeReceiptReviewDepthCounts', {
        'invalid_full_receipt_text_please': 1,
      }),
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata.toString(),
      isNot(contains('/tmp/section-1.jpg')),
    );
  });

  test('accepted review freezes receipt brain install and local-only counts', () {
    final fixture = frozenReceiptCameraDiagnosticsFixture();
    final result = fixture.result;

    expect(result.nativeReceiptReviewDepth, 'detailedLines');
    expect(result.receiptBrainReleaseActionCounts, {
      'ship_lean_base_offer_explicit_receipt_pack_download': 1,
    });
    expect(
      result.receiptBrainReleaseActionOutcome,
      'ship_lean_base_offer_explicit_receipt_pack_download',
    );
    expect(result.receiptBrainInstallDistributionCounts, {
      'base_app_explicit_optional_receipt_packs': 1,
    });
    expect(
      result.receiptBrainInstallDistributionOutcome,
      'base_app_explicit_optional_receipt_packs',
    );
    expect(result.receiptBrainStorageClassCounts, {'comfortable': 1});
    expect(result.receiptBrainLocalOcrModeCounts, {'full_local_ocr': 1});
    expect(result.receiptBrainBaseSizeDecisionCounts, {'base_size_ready': 1});
    expect(result.receiptBrainFirstInstallBoundaryCounts, {
      'ready_base_first_optional_local_pack_later': 1,
    });
    expect(
      result.receiptBrainFirstInstallBoundaryOutcome,
      'ready_base_first_optional_local_pack_later',
    );
    expect(result.receiptBrainFirstInstallBoundaryActionCounts, {
      'ship_base_then_offer_optional_local_pack': 1,
    });
    expect(result.receiptBrainFirstInstallCanRunLowStorageCounts, {'true': 1});
    expect(result.receiptBrainFirstInstallRequiresBaseCapabilityCounts, {
      'true': 1,
    });
    expect(result.receiptBrainFirstInstallBoundarySummaryCounts, {
      'present': 1,
    });
    expect(result.receiptBrainBaseNeedsSizeReviewCounts, {'false': 1});
    expect(result.receiptBrainBaseBlocksLowStorageCounts, {'false': 1});
    expect(result.receiptBrainFullOfflineExceedsBaseGuardrailCounts, {
      'true': 1,
    });
    expect(result.receiptBrainFullOfflineMustStayOptionalCounts, {'true': 1});
    expect(result.receiptBrainLowStorageDownloadRiskCounts, {
      'full_offline_large_optional_only': 1,
    });
    expect(
      result.receiptBrainLowStorageDownloadRiskOutcome,
      'full_offline_large_optional_only',
    );
    expect(result.receiptInstallRequiredSegmentCounts, {
      'required_base_lean_under_40mb': 1,
    });
    expect(
      result.receiptInstallRequiredSegmentOutcome,
      'required_base_lean_under_40mb',
    );
    expect(result.receiptInstallFullOfflineSegmentCounts, {
      'full_offline_100_to_250mb_optional': 1,
    });
    expect(
      result.receiptInstallFullOfflineSegmentOutcome,
      'full_offline_100_to_250mb_optional',
    );
    expect(result.receiptInstallLowStorageImpactCounts, {
      'low_storage_base_only_optional_pack_hidden': 1,
    });
    expect(
      result.receiptInstallLowStorageImpactOutcome,
      'low_storage_base_only_optional_pack_hidden',
    );
    expect(result.receiptInstallRecommendedDistributionCounts, {
      'ship_base_hide_large_packs_until_storage_allows': 1,
    });
    expect(
      result.receiptInstallRecommendedDistributionOutcome,
      'ship_base_hide_large_packs_until_storage_allows',
    );
    expect(result.receiptInstallCameraShellParserFreeCounts, {'true': 1});
    expect(result.receiptInstallBaseUsefulOnTinyPhonesCounts, {'true': 1});
    expect(result.receiptInstallOptionalPacksRequireConsentCounts, {'true': 1});
    expect(result.receiptBrainBaseSizeDecisionOutcome, 'base_size_ready');
    expect(result.receiptBrainRequiredBasePayloadCounts, {
      'native_receipt_camera': 1,
      'receipt_proof_storage': 1,
      'basic_local_receipt_reader': 1,
      'manual_receipt_entry': 1,
      'data_saver_proof_copies': 1,
    });
    expect(result.receiptBrainOptionalPayloadCounts, {
      'general_expense_lines_v1': 1,
      'materials_inventory_regional_v1': 1,
    });
    expect(result.receiptBrainBaseShipWithoutFullOfflineCounts, {'true': 1});
    expect(result.receiptBrainBaseVersusFullOfflineSummaryCounts, {
      'present': 1,
    });
    expect(result.receiptBrainOptionalPackUserChoiceCounts, {'true': 1});
    expect(result.receiptBrainBaseLocalReadingAvailableCounts, {'true': 1});
    expect(result.receiptBrainBaseWorksWithoutCloudAssistCounts, {'true': 1});
    expect(result.receiptBrainLocalFirstReadinessCounts, {
      'lean_local_ready_optional_packs_deferred': 1,
    });
    expect(
      result.receiptBrainLocalFirstReadinessOutcome,
      'lean_local_ready_optional_packs_deferred',
    );
    expect(result.receiptBrainLocalFirstReadinessActionCounts, {
      'keep_capture_and_basic_reader_available': 1,
    });
    expect(
      result.receiptBrainLocalFirstReadinessActionOutcome,
      'keep_capture_and_basic_reader_available',
    );
    expect(result.receiptBrainLocalFirstReadinessSummaryCounts, {'present': 1});
    expect(result.receiptLocalOnlyAcceptanceStatusCounts, {
      'ready_local_first_optional_packs_deferred': 1,
    });
    expect(
      result.receiptLocalOnlyAcceptanceStatusOutcome,
      'ready_local_first_optional_packs_deferred',
    );
    expect(result.receiptLocalOnlyAcceptanceActionCounts, {
      'ship_base_capture_save_review_before_optional_packs': 1,
    });
    expect(
      result.receiptLocalOnlyAcceptanceActionOutcome,
      'ship_base_capture_save_review_before_optional_packs',
    );
    expect(result.receiptLocalOnlyBaseFlowCanRunCounts, {'true': 1});
    expect(result.receiptLocalOnlyBlocksLowStorageCounts, {'false': 1});
    expect(result.receiptLocalOnlyEvidenceCounts, {
      'capture_available_in_base': 1,
      'proof_save_available_in_base': 1,
      'basic_local_review_available_in_base': 1,
    });
    expect(result.nativeLocalOnlyCapturePolicyCounts, {
      'capture_save_basic_review_now_optional_packs_later': 1,
    });
    expect(
      result.nativeLocalOnlyCapturePolicyOutcome,
      'capture_save_basic_review_now_optional_packs_later',
    );
    expect(result.nativeLocalOnlyBaseFlowCanRunCounts, {'true': 1});
    expect(result.nativeLocalOnlyHeavyPacksMayBlockCaptureCounts, {'false': 1});
    expect(result.nativeLocalOnlyCloudAssistMayBlockCaptureCounts, {
      'false': 1,
    });
    expect(result.receiptRequiredBaseFootprintStatusCounts, {'review': 1});
    expect(result.receiptRequiredBaseFootprintStatusOutcome, 'review');
    expect(result.receiptRequiredBaseFootprintCanShipCounts, {'true': 1});
    expect(result.receiptRequiredBaseFootprintReviewCounts, {'true': 1});
    expect(result.receiptRequiredBaseFootprintBlockingReasonCounts, isEmpty);
    expect(result.receiptRequiredBaseFootprintReviewReasonCounts, {
      'full_offline_brain_over_100mb_optional_only': 1,
    });
    expect(
      result.receiptBrainBasePayloadGuardrailOutcome,
      'base_payload_optional_packs_ok',
    );
    expect(
      result.acceptedPhotoHandoffRoute,
      'photo_review_accepted_to_receipt_details',
    );
    expect(
      result.receiptPhotoReviewHandoffPath,
      'accepted_single_prepared_source',
    );
    expect(
      result.receiptPhotoReviewHandoffPathLabel,
      'Accepted single receipt with prepared OCR source.',
    );
    expect(
      result.acceptedPhotoHandoffNextScreen,
      'receipt_details_store_date_total_tax_items',
    );
    expect(
      result.acceptedPhotoHandoffNextStepLabel,
      'Next opens receipt details with store, date, total, tax, item prices, and Business/Personal/Mixed choices.',
    );
    expect(
      result.acceptedPhotoHandoffRouteResultLabel,
      'Accepted photo review must open receipt details next, not the previous expense screen.',
    );
    expect(result.acceptedPhotoHandoffMustOpenFilledReview, isTrue);
    expect(result.acceptedPhotoHandoffMustOpenReceiptDetails, isTrue);
    expect(
      result.acceptedPhotoHandoffUserAction,
      'tap_next_after_photo_review',
    );
    expect(
      result.privacySafeOcrHandoffEvidenceLabel,
      'quality=ready_for_receipt_review;stitch=notNeeded;reason=notNeeded;sources=1;ocr_source_first=true;scanner=enhanced_ocr_source;saved=saved_warning_none;coverage=coverage_ok;ui=native_ui_signal_missing',
    );
  });
}
