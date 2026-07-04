import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';

void main() {
  test(
    'receipt brain footprint separates base camera from optional parser packs',
    () {
      const crampedHardware = ReceiptHardwareProfile(
        availableRamMb: 3900,
        cpuCores: 4,
        freeStorageMb: 190,
        cameraCount: 1,
        hasRearCamera: true,
        supportsTapFocus: true,
        supportsZoom: true,
      );
      const roomyHardware = ReceiptHardwareProfile(
        availableRamMb: 12288,
        cpuCores: 8,
        androidPerformanceClass: 34,
        freeStorageMb: 16000,
        hasOnDeviceAcceleration: true,
        cameraCount: 1,
        hasRearCamera: true,
        supportsTapFocus: true,
        supportsContinuousFocus: true,
        supportsZoom: true,
        supportsExposureCompensation: true,
        maxStillWidth: 4000,
        maxStillHeight: 3000,
      );

      final cramped = crampedHardware.receiptBrainFootprintSummaryFor();
      final roomy = roomyHardware.receiptBrainFootprintSummaryFor();

      expect(cramped.baseCaptureWorksWithoutOptionalPacks, isTrue);
      expect(cramped.optionalPacksDetachedFromBaseInstall, isTrue);
      expect(cramped.shouldDeferOptionalLocalPacks, isTrue);
      expect(cramped.requiresExplicitDownload, isFalse);
      expect(cramped.optionalLocalPackBytes, 0);
      expect(cramped.baseReceiptBudgetLabel, '40 MB');
      expect(cramped.fullOfflineReceiptBudgetLabel, '40 MB');
      expect(cramped.baseInstallStaysUnderRequiredBudget, isTrue);
      expect(cramped.baseInstallNeedsSizeReview, isFalse);
      expect(cramped.baseInstallBlocksLowStorageUsers, isFalse);
      expect(cramped.baseInstallSizeDecisionCode, 'base_size_ready');
      expect(
        cramped.fullOfflineReceiptBrainExceedsRequiredBaseGuardrail,
        isFalse,
      );
      expect(cramped.fullOfflineReceiptBrainMustStayOptional, isTrue);
      expect(
        cramped.lowStorageDownloadRiskCode,
        'base_safe_optional_brain_deferred_for_low_storage',
      );
      expect(cramped.baseInstallBudgetTierCode, 'lean_base_under_40mb');
      expect(
        cramped.baseInstallBudgetLabel,
        'Lean required receipt base: 40 MB.',
      );
      expect(cramped.baseInstallKeepsReceiptBrainLean, isTrue);
      expect(cramped.baseLocalReceiptReadingAvailable, isTrue);
      expect(cramped.baseWorksWithoutCloudAssist, isTrue);
      expect(
        cramped.localFirstReadinessCode,
        'lean_local_ready_optional_packs_deferred',
      );
      expect(
        cramped.localFirstReadinessActionCode,
        'keep_capture_and_basic_reader_available',
      );
      expect(
        cramped.userFacingLocalFirstReadinessSummary,
        contains('basic local reading work from the base app'),
      );
      expect(
        cramped.userFacingLocalFirstReadinessSummary,
        contains('must not block local capture'),
      );
      final crampedAcceptance = cramped.localOnlyAcceptanceGate;
      expect(crampedAcceptance.baseFlowCanRunLocallyNow, isTrue);
      expect(crampedAcceptance.blocksLowStorageUsers, isFalse);
      expect(
        crampedAcceptance.statusCode,
        'ready_local_first_optional_packs_deferred',
      );
      expect(
        crampedAcceptance.actionCode,
        'ship_base_capture_save_review_before_optional_packs',
      );
      expect(
        crampedAcceptance.evidenceCodes,
        containsAll([
          'capture_available_in_base',
          'proof_save_available_in_base',
          'basic_local_review_available_in_base',
          'optional_packs_not_required_before_capture',
          'cloud_assist_optional_after_local_flow',
        ]),
      );
      expect(
        crampedAcceptance.userFacingSummary,
        contains('capture, save proof, and open basic local review'),
      );
      final crampedReleaseCheck =
          ReceiptRequiredBaseFootprintReleaseCheck.fromSummary(cramped);
      final crampedInstallStrategy = cramped.installFootprintStrategy;
      expect(crampedReleaseCheck.requiredBaseCanShip, isTrue);
      expect(crampedReleaseCheck.requiresReview, isFalse);
      expect(crampedReleaseCheck.statusCode, 'ready');
      expect(crampedReleaseCheck.blockingReasonCodes, isEmpty);
      expect(crampedReleaseCheck.reviewReasonCodes, isEmpty);
      expect(
        crampedReleaseCheck.releaseActionCode,
        'ship_required_receipt_base',
      );
      expect(
        cramped.userFacingFootprintSummary,
        contains('base local reader stay in the base app budget'),
      );
      expect(
        crampedInstallStrategy.requiredInstallSegmentCode,
        'required_base_lean_under_40mb',
      );
      expect(
        crampedInstallStrategy.fullOfflineSegmentCode,
        'full_offline_same_as_base',
      );
      expect(
        crampedInstallStrategy.lowStorageUserImpactCode,
        'low_storage_base_flow_ready',
      );
      expect(
        crampedInstallStrategy.recommendedDistributionCode,
        'ship_base_receipt_flow_only',
      );
      expect(crampedInstallStrategy.cameraShellMustStayParserFree, isTrue);
      expect(
        crampedInstallStrategy.baseDownloadStillUsefulOnTinyPhones,
        isTrue,
      );
      expect(crampedInstallStrategy.optionalOfflinePacksRequireConsent, isTrue);
      expect(
        crampedInstallStrategy.userFacingSummary,
        contains('Low-storage users can capture and review basic receipts now'),
      );
      expect(cramped.toPrivacySafeDiagnostics(), {
        'receiptBrainBaseBudgetBytes': 40 * 1024 * 1024,
        'receiptBrainIncludedLocalPackBytes': 0,
        'receiptBrainOptionalLocalPackBytes': 0,
        'receiptBrainFullOfflineBudgetBytes': 40 * 1024 * 1024,
        'receiptBrainLocalOcrMode': 'lean_local_ocr',
        'receiptBrainParserDepth': 'proofTotalsOnly',
        'receiptBrainStorageClass': 'critical',
        'receiptBrainOptionalLocalPackCodes': <String>[],
        'receiptBrainCloudFallbackPackCodes': ['cloud_ocr_assist_v1'],
        'receiptBrainBaseWorksWithoutOptionalPacks': true,
        'receiptBrainOptionalPacksDetachedFromBase': true,
        'receiptBrainRequiredBasePayloadCodes': [
          'native_receipt_camera',
          'receipt_proof_storage',
          'basic_local_receipt_reader',
          'manual_receipt_entry',
          'data_saver_proof_copies',
        ],
        'receiptBrainOptionalPayloadCodes': ['cloud_ocr_assist_v1'],
        'receiptBrainFirstInstallBoundaryCode':
            'ready_base_first_cloud_assist_optional_later',
        'receiptBrainFirstInstallBoundaryActionCode':
            'ship_base_then_offer_optional_cloud_assist',
        'receiptBrainFirstInstallExcludesOptionalBrain': true,
        'receiptBrainFirstInstallRequiresOnlyBaseCapabilities': true,
        'receiptBrainFirstInstallCanRunOnLowStoragePhones': true,
        'receiptBrainFirstInstallBoundarySummary':
            cramped.userFacingFirstInstallReceiptBoundarySummary,
        'receiptBrainBaseCanShipWithoutFullOfflineBrain': true,
        'receiptBrainBaseLocalReceiptReadingAvailable': true,
        'receiptBrainBaseWorksWithoutCloudAssist': true,
        'receiptBrainLocalFirstReadinessCode':
            'lean_local_ready_optional_packs_deferred',
        'receiptBrainLocalFirstReadinessActionCode':
            'keep_capture_and_basic_reader_available',
        'receiptBrainUserFacingLocalFirstReadinessSummary':
            cramped.userFacingLocalFirstReadinessSummary,
        'receiptBrainOptionalParserPacksRequireUserChoice': true,
        'receiptBrainBaseNeedsSizeReview': false,
        'receiptBrainBaseBlocksLowStorageUsers': false,
        'receiptBrainBaseSizeDecisionCode': 'base_size_ready',
        'receiptBrainFullOfflineExceedsBaseGuardrail': false,
        'receiptBrainFullOfflineMustStayOptional': true,
        'receiptBrainLowStorageDownloadRiskCode':
            'base_safe_optional_brain_deferred_for_low_storage',
        'receiptBrainShouldDeferOptionalLocalPacks': true,
        'receiptBrainRequiresExplicitDownload': false,
        'receiptBrainBaseInstallKeepsLean': true,
        'receiptBrainBaseUnderRequiredBudget': true,
        'receiptBrainBaseBudgetTierCode': 'lean_base_under_40mb',
        'receiptBrainRequiredBaseReleaseActionCode':
            'ship_lean_base_and_defer_optional_receipt_packs',
        'receiptBrainInstallDistributionModeCode':
            'base_app_only_optional_cloud_assist',
        'receiptBrainUserFacingInstallChoiceSummary':
            cramped.userFacingInstallChoiceSummary,
        'receiptBrainUserFacingBaseVersusFullOfflineSummary':
            cramped.userFacingBaseVersusFullOfflineSummary,
        'receiptBrainRequiredBaseGuardrailSummary':
            cramped.userFacingRequiredBaseGuardrailSummary,
        'receiptBrainBaseSizeDecisionLabel':
            cramped.userFacingBaseSizeDecisionLabel,
        'receiptBrainUserFacingLowStorageDownloadWarning':
            cramped.userFacingLowStorageDownloadWarning,
        'receiptInstallRequiredBaseBytes': 40 * 1024 * 1024,
        'receiptInstallOptionalOfflineBytes': 0,
        'receiptInstallFullOfflineBytes': 40 * 1024 * 1024,
        'receiptInstallStorageClass': 'critical',
        'receiptInstallRequiredSegmentCode': 'required_base_lean_under_40mb',
        'receiptInstallFullOfflineSegmentCode': 'full_offline_same_as_base',
        'receiptInstallLowStorageUserImpactCode': 'low_storage_base_flow_ready',
        'receiptInstallRecommendedDistributionCode':
            'ship_base_receipt_flow_only',
        'receiptInstallCameraShellParserFree': true,
        'receiptInstallBaseUsefulOnTinyPhones': true,
        'receiptInstallOptionalPacksRequireConsent': true,
        'receiptInstallUserFacingSummary':
            crampedInstallStrategy.userFacingSummary,
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
        'receiptLocalOnlyEvidenceCodes': crampedAcceptance.evidenceCodes,
        'receiptLocalOnlyUserFacingSummary':
            crampedAcceptance.userFacingSummary,
        'receiptRequiredBaseFootprintStatusCode': 'ready',
        'receiptRequiredBaseFootprintCanShip': true,
        'receiptRequiredBaseFootprintRequiresReview': false,
        'receiptRequiredBaseFootprintFullOfflineOptional': true,
        'receiptRequiredBaseFootprintBlockingReasonCodes': <String>[],
        'receiptRequiredBaseFootprintReviewReasonCodes': <String>[],
        'receiptRequiredBaseFootprintReleaseActionCode':
            'ship_required_receipt_base',
        'receiptRequiredBaseFootprintRequiredBytes': 40 * 1024 * 1024,
        'receiptRequiredBaseFootprintOptionalBytes': 0,
        'receiptRequiredBaseFootprintFullOfflineBytes': 40 * 1024 * 1024,
        'receiptRequiredBaseFootprintRequiredPayloadCodes': [
          'native_receipt_camera',
          'receipt_proof_storage',
          'basic_local_receipt_reader',
          'manual_receipt_entry',
          'data_saver_proof_copies',
        ],
        'receiptRequiredBaseFootprintOptionalPayloadCodes': [
          'cloud_ocr_assist_v1',
        ],
        'receiptRequiredBaseFootprintSummary':
            crampedReleaseCheck.userFacingSummary,
      });

      expect(roomy.baseCaptureWorksWithoutOptionalPacks, isTrue);
      expect(roomy.optionalPacksDetachedFromBaseInstall, isTrue);
      expect(roomy.baseInstallStaysUnderRequiredBudget, isTrue);
      expect(roomy.baseInstallNeedsSizeReview, isFalse);
      expect(roomy.baseInstallBlocksLowStorageUsers, isFalse);
      expect(roomy.baseInstallSizeDecisionCode, 'base_size_ready');
      expect(roomy.baseInstallBudgetTierCode, 'lean_base_under_40mb');
      expect(roomy.shouldDeferOptionalLocalPacks, isFalse);
      expect(roomy.requiresExplicitDownload, isTrue);
      expect(roomy.optionalLocalPackSizeLabel, '124 MB');
      expect(roomy.fullOfflineReceiptBudgetLabel, '164 MB');
      expect(roomy.optionalLocalPackCodes, [
        'general_expense_lines_v1',
        'materials_inventory_regional_v1',
      ]);
      expect(roomy.cloudFallbackPackCodes, isEmpty);
      expect(
        roomy.userFacingFootprintSummary,
        contains('after the user chooses them'),
      );
      expect(roomy.requiredBasePayloadCodes, [
        'native_receipt_camera',
        'receipt_proof_storage',
        'basic_local_receipt_reader',
        'manual_receipt_entry',
        'data_saver_proof_copies',
      ]);
      expect(roomy.optionalPayloadCodes, [
        'general_expense_lines_v1',
        'materials_inventory_regional_v1',
      ]);
      expect(roomy.firstInstallExcludesOptionalReceiptBrain, isTrue);
      expect(roomy.firstInstallRequiresOnlyBaseReceiptCapabilities, isTrue);
      expect(roomy.firstInstallCanRunOnLowStoragePhones, isTrue);
      expect(
        roomy.firstInstallReceiptBoundaryCode,
        'ready_base_first_optional_local_pack_later',
      );
      expect(
        roomy.firstInstallReceiptBoundaryActionCode,
        'ship_base_then_offer_optional_local_pack',
      );
      expect(
        roomy.userFacingFirstInstallReceiptBoundarySummary,
        contains('Extra offline receipt intelligence is a later choice'),
      );
      expect(roomy.baseInstallCanShipWithoutFullOfflineReceiptBrain, isTrue);
      expect(roomy.optionalParserPacksRequireUserChoice, isTrue);
      expect(roomy.fullOfflineReceiptBrainExceedsRequiredBaseGuardrail, isTrue);
      expect(roomy.fullOfflineReceiptBrainMustStayOptional, isTrue);
      final roomyAcceptance = roomy.localOnlyAcceptanceGate;
      expect(roomyAcceptance.baseFlowCanRunLocallyNow, isTrue);
      expect(
        roomyAcceptance.statusCode,
        'ready_local_first_optional_packs_deferred',
      );
      expect(
        roomyAcceptance.actionCode,
        'ship_base_capture_save_review_before_optional_packs',
      );
      final roomyReleaseCheck =
          ReceiptRequiredBaseFootprintReleaseCheck.fromSummary(roomy);
      final roomyInstallStrategy = roomy.installFootprintStrategy;
      expect(roomyReleaseCheck.requiredBaseCanShip, isTrue);
      expect(roomyReleaseCheck.requiresReview, isTrue);
      expect(roomyReleaseCheck.statusCode, 'review');
      expect(
        roomyReleaseCheck.reviewReasonCodes,
        contains('full_offline_brain_over_100mb_optional_only'),
      );
      expect(roomyReleaseCheck.blockingReasonCodes, isEmpty);
      expect(roomyReleaseCheck.requiredBaseLabel, '40 MB');
      expect(roomyReleaseCheck.optionalLabel, '124 MB');
      expect(roomyReleaseCheck.fullOfflineLabel, '164 MB');
      expect(
        roomyReleaseCheck.releaseActionCode,
        'review_receipt_base_before_adding_weight',
      );
      expect(
        roomyReleaseCheck.userFacingSummary,
        contains('full offline receipt intelligence remains optional'),
      );
      expect(
        roomy.lowStorageDownloadRiskCode,
        'full_offline_large_optional_only',
      );
      expect(
        roomy.requiredBaseReleaseActionCode,
        'ship_lean_base_offer_explicit_receipt_pack_download',
      );
      expect(
        roomy.installDistributionModeCode,
        'base_app_full_offline_optional',
      );
      expect(
        roomy.userFacingRequiredBaseGuardrailSummary,
        contains('not part of the first install'),
      );
      expect(
        roomyInstallStrategy.fullOfflineSegmentCode,
        'full_offline_100_to_250mb_optional',
      );
      expect(
        roomyInstallStrategy.lowStorageUserImpactCode,
        'larger_storage_can_choose_optional_offline',
      );
      expect(
        roomyInstallStrategy.recommendedDistributionCode,
        'ship_base_offer_optional_offline_receipt_packs',
      );
      expect(roomyInstallStrategy.cameraShellMustStayParserFree, isTrue);
      expect(roomyInstallStrategy.baseDownloadStillUsefulOnTinyPhones, isTrue);
      expect(roomyInstallStrategy.optionalOfflinePacksRequireConsent, isTrue);
      expect(
        roomy.toPrivacySafeDiagnostics(),
        containsPair('receiptRequiredBaseFootprintStatusCode', 'review'),
      );
      expect(
        roomy.toPrivacySafeDiagnostics(),
        containsPair(
          'receiptInstallRecommendedDistributionCode',
          'ship_base_offer_optional_offline_receipt_packs',
        ),
      );
      expect(
        roomy.toPrivacySafeDiagnostics(),
        containsPair(
          'receiptInstallFullOfflineSegmentCode',
          'full_offline_100_to_250mb_optional',
        ),
      );
      expect(
        roomy.toPrivacySafeDiagnostics(),
        containsPair('receiptRequiredBaseFootprintCanShip', true),
      );
      expect(
        roomy.toPrivacySafeDiagnostics(),
        containsPair(
          'receiptRequiredBaseFootprintReleaseActionCode',
          'review_receipt_base_before_adding_weight',
        ),
      );
    },
  );
}
