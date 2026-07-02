import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

class FrozenReceiptCameraDiagnosticsFixture {
  const FrozenReceiptCameraDiagnosticsFixture({
    required this.result,
    required this.quality,
  });

  final ReceiptPhotoReviewResult result;
  final ReceiptPhotoQualityCheck quality;
}

FrozenReceiptCameraDiagnosticsFixture frozenReceiptCameraDiagnosticsFixture() {
  const quality = ReceiptPhotoQualityCheck(
    width: 1200,
    height: 1800,
    focusScore: 12,
    isLikelyReadable: true,
  );
  final photoPaths = ['/tmp/proof.jpg'];
  final ocrPaths = ['/tmp/ocr.jpg'];
  final qualityByPath = {'/tmp/proof.jpg': quality};
  final prepDiagnostics = {
    '/tmp/ocr.jpg': {
      'usedEnhancedOcrSource': true,
      'cleanupActions': ['grayscale'],
      'scannerDecisionCodes': [
        'cleanup_applied_dark_receipt',
        'ocr_source_enhanced_selected',
      ],
      'ocrStoragePolicyCode': 'ocr_clear_source_before_saved_proof_copy',
      'ocrUsesPreparedSourceBeforeSavedProof': true,
      'ocrUsesSavedProofFallback': false,
    },
  };
  final captureDiagnostics = {
    '/tmp/proof.jpg': {
      'latestBrightnessBucket': 'good',
      'pinchZoomEnabled': true,
      'reviewDepth': 'detailedLines',
      'photoCoverageStatus': ReceiptPhotoCoverageStatus.likelyComplete.name,
      'photoCoverageReason': 'framing_ok_readable',
      'photoCoverageNeedsMorePhotos': false,
      'receiptBrainRequiredBaseReleaseActionCode':
          'ship_lean_base_offer_explicit_receipt_pack_download',
      'receiptBrainInstallDistributionModeCode':
          'base_app_explicit_optional_receipt_packs',
      'receiptBrainStorageClass': 'comfortable',
      'receiptBrainLocalOcrMode': 'full_local_ocr',
      'receiptBrainBaseSizeDecisionCode': 'base_size_ready',
      'receiptBrainBaseNeedsSizeReview': false,
      'receiptBrainBaseBlocksLowStorageUsers': false,
      'receiptBrainFullOfflineExceedsBaseGuardrail': true,
      'receiptBrainFullOfflineMustStayOptional': true,
      'receiptBrainLowStorageDownloadRiskCode':
          'full_offline_large_optional_only',
      'receiptInstallRequiredSegmentCode': 'required_base_lean_under_40mb',
      'receiptInstallFullOfflineSegmentCode':
          'full_offline_100_to_250mb_optional',
      'receiptInstallLowStorageUserImpactCode':
          'low_storage_base_only_optional_pack_hidden',
      'receiptInstallRecommendedDistributionCode':
          'ship_base_hide_large_packs_until_storage_allows',
      'receiptInstallCameraShellParserFree': true,
      'receiptInstallBaseUsefulOnTinyPhones': true,
      'receiptInstallOptionalPacksRequireConsent': true,
      'receiptBrainRequiredBasePayloadCodes': [
        'native_receipt_camera',
        'receipt_proof_storage',
        'basic_local_receipt_reader',
        'manual_receipt_entry',
        'data_saver_proof_copies',
      ],
      'receiptBrainOptionalPayloadCodes': [
        'general_expense_lines_v1',
        'materials_inventory_regional_v1',
      ],
      'receiptBrainFirstInstallBoundaryCode':
          'ready_base_first_optional_local_pack_later',
      'receiptBrainFirstInstallBoundaryActionCode':
          'ship_base_then_offer_optional_local_pack',
      'receiptBrainFirstInstallExcludesOptionalBrain': true,
      'receiptBrainFirstInstallRequiresOnlyBaseCapabilities': true,
      'receiptBrainFirstInstallCanRunOnLowStoragePhones': true,
      'receiptBrainFirstInstallBoundarySummary':
          'Required receipt install stays lean. Extra offline receipt intelligence is a later choice.',
      'receiptBrainBaseCanShipWithoutFullOfflineBrain': true,
      'receiptBrainOptionalParserPacksRequireUserChoice': true,
      'receiptBrainBaseLocalReceiptReadingAvailable': true,
      'receiptBrainBaseWorksWithoutCloudAssist': true,
      'receiptBrainLocalFirstReadinessCode':
          'lean_local_ready_optional_packs_deferred',
      'receiptBrainLocalFirstReadinessActionCode':
          'keep_capture_and_basic_reader_available',
      'receiptBrainUserFacingLocalFirstReadinessSummary':
          'Receipt capture and basic local reading work from the base app. Optional offline packs can be added later, and assist fallback must not block local capture.',
      'receiptLocalOnlyAcceptanceStatusCode':
          'ready_local_first_optional_packs_deferred',
      'receiptLocalOnlyAcceptanceActionCode':
          'ship_base_capture_save_review_before_optional_packs',
      'receiptLocalOnlyBaseFlowCanRunNow': true,
      'receiptLocalOnlyCanCaptureReceipt': true,
      'receiptLocalOnlyCanSaveReceiptProof': true,
      'receiptLocalOnlyCanOpenBasicReview': true,
      'receiptLocalOnlyRequiresHeavyPackBeforeCapture': false,
      'receiptLocalOnlyRequiresCloudBeforeCapture': false,
      'receiptLocalOnlyOptionalPacksDeferredBeforeCapture': true,
      'receiptLocalOnlyBlocksLowStorageUsers': false,
      'receiptLocalOnlyEvidenceCodes': [
        'capture_available_in_base',
        'proof_save_available_in_base',
        'basic_local_review_available_in_base',
      ],
      'localOnlyCapturePolicy':
          'capture_save_basic_review_now_optional_packs_later',
      'localOnlyBaseFlowCanRunNow': true,
      'localOnlyHeavyPacksMayBlockCapture': false,
      'localOnlyCloudAssistMayBlockCapture': false,
      'receiptBrainUserFacingBaseVersusFullOfflineSummary':
          'First install needs the receipt camera and basic local reading only. Full offline receipt intelligence can be added later. Do not block receipt capture behind optional OCR/parser packs.',
      'receiptRequiredBaseFootprintStatusCode': 'review',
      'receiptRequiredBaseFootprintCanShip': true,
      'receiptRequiredBaseFootprintRequiresReview': true,
      'receiptRequiredBaseFootprintBlockingReasonCodes': <String>[],
      'receiptRequiredBaseFootprintReviewReasonCodes': [
        'full_offline_brain_over_100mb_optional_only',
      ],
    },
  };

  final result = ReceiptPhotoReviewResult(
    photoPaths: photoPaths,
    ocrSourcePhotoPaths: ocrPaths,
    dataSaverLevel: ReceiptDataSaverLevel.balanced,
    stitchResult: ReceiptStitchResult.notNeeded(ocrPaths),
    photoQualityChecksByPath: qualityByPath,
    preparationDiagnosticsByOcrPath: prepDiagnostics,
    captureDiagnosticsByPhotoPath: captureDiagnostics,
  );

  photoPaths.add('/tmp/late-proof.jpg');
  ocrPaths.add('/tmp/late-ocr.jpg');
  qualityByPath.clear();
  prepDiagnostics['/tmp/ocr.jpg']!['usedEnhancedOcrSource'] = false;
  captureDiagnostics['/tmp/proof.jpg']!['latestBrightnessBucket'] = 'dark';

  return FrozenReceiptCameraDiagnosticsFixture(
    result: result,
    quality: quality,
  );
}
