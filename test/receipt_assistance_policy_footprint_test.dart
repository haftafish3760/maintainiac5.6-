import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';


void main() {
  test(
    'receipt brain footprint blocks oversized required camera and OCR base',
    () {
      const oversized = ReceiptBrainFootprintSummary(
        baseReceiptBudgetBytes: 132 * 1024 * 1024,
        includedLocalPackBytes: 18 * 1024 * 1024,
        optionalLocalPackBytes: 210 * 1024 * 1024,
        fullOfflineReceiptBudgetBytes: 360 * 1024 * 1024,
        localOcrMode: 'full_local_ocr',
        parserDepth: ReceiptParserDepth.inventoryMatching,
        storageClass: ReceiptDeviceStorageClass.low,
        optionalLocalPackCodes: [
          'general_expense_lines_v1',
          'materials_inventory_regional_v1',
        ],
        cloudFallbackPackCodes: ['receipt_cloud_assist_v1'],
        baseCaptureWorksWithoutOptionalPacks: true,
        optionalPacksDetachedFromBaseInstall: true,
        shouldDeferOptionalLocalPacks: true,
        requiresExplicitDownload: true,
        userFacingFootprintSummary:
            'Required base is intentionally oversized for release guard testing.',
      );

      expect(oversized.baseReceiptBudgetLabel, '132 MB');
      expect(oversized.fullOfflineReceiptBudgetLabel, '360 MB');
      final oversizedReleaseCheck =
          ReceiptRequiredBaseFootprintReleaseCheck.fromSummary(oversized);
      final oversizedInstallStrategy = oversized.installFootprintStrategy;
      expect(oversizedReleaseCheck.requiredBaseCanShip, isFalse);
      expect(oversizedReleaseCheck.requiresReview, isTrue);
      expect(oversizedReleaseCheck.statusCode, 'blocked');
      expect(
        oversizedReleaseCheck.blockingReasonCodes,
        containsAll([
          'required_base_over_100mb',
          'parser_pack_in_required_base',
        ]),
      );
      expect(
        oversizedReleaseCheck.reviewReasonCodes,
        contains('full_offline_brain_over_100mb_optional_only'),
      );
      expect(
        oversizedReleaseCheck.releaseActionCode,
        'fix_required_receipt_base_before_release',
      );
      expect(oversized.baseInstallStaysUnderRequiredBudget, isFalse);
      expect(oversized.baseInstallKeepsReceiptBrainLean, isFalse);
      expect(oversized.baseInstallNeedsSizeReview, isTrue);
      expect(oversized.baseInstallBlocksLowStorageUsers, isTrue);
      final oversizedAcceptance = oversized.localOnlyAcceptanceGate;
      expect(oversizedAcceptance.baseFlowCanRunLocallyNow, isFalse);
      expect(oversizedAcceptance.blocksLowStorageUsers, isTrue);
      expect(
        oversizedAcceptance.statusCode,
        'blocked_heavy_pack_required_before_capture',
      );
      expect(
        oversizedAcceptance.actionCode,
        'move_heavy_receipt_pack_out_of_required_capture_flow',
      );
      expect(oversized.baseInstallSizeDecisionCode, 'block_base_over_100mb');
      expect(
        oversized.fullOfflineReceiptBrainExceedsRequiredBaseGuardrail,
        isTrue,
      );
      expect(oversized.fullOfflineReceiptBrainMustStayOptional, isTrue);
      expect(
        oversized.lowStorageDownloadRiskCode,
        'base_install_blocks_low_storage_users',
      );
      expect(
        oversized.baseInstallBudgetTierCode,
        'base_over_100mb_block_required_install',
      );
      expect(
        oversized.requiredBaseReleaseActionCode,
        'move_heavy_receipt_work_to_optional_packs_before_release',
      );
      expect(oversized.firstInstallExcludesOptionalReceiptBrain, isFalse);
      expect(
        oversized.firstInstallRequiresOnlyBaseReceiptCapabilities,
        isFalse,
      );
      expect(oversized.firstInstallCanRunOnLowStoragePhones, isFalse);
      expect(
        oversized.firstInstallReceiptBoundaryCode,
        'blocked_heavy_pack_in_first_install',
      );
      expect(
        oversized.firstInstallReceiptBoundaryActionCode,
        'move_heavy_ocr_parser_pack_to_optional_download',
      );
      expect(
        oversized.userFacingFirstInstallReceiptBoundarySummary,
        contains('Move heavy OCR/parser weight out of the first install'),
      );
      expect(
        oversized.installDistributionModeCode,
        'required_base_blocked_until_optionalized',
      );
      expect(
        oversized.baseInstallBudgetLabel,
        contains('over the 100 MB guardrail'),
      );
      expect(
        oversized.userFacingRequiredBaseGuardrailSummary,
        contains('cannot ship as a required download'),
      );
      expect(
        oversized.toPrivacySafeDiagnostics(),
        containsPair(
          'receiptBrainRequiredBaseReleaseActionCode',
          'move_heavy_receipt_work_to_optional_packs_before_release',
        ),
      );
      expect(
        oversized.toPrivacySafeDiagnostics(),
        containsPair(
          'receiptBrainBaseBudgetTierCode',
          'base_over_100mb_block_required_install',
        ),
      );
      expect(
        oversized.toPrivacySafeDiagnostics(),
        containsPair('receiptBrainBaseNeedsSizeReview', true),
      );
      expect(
        oversized.toPrivacySafeDiagnostics(),
        containsPair('receiptBrainBaseBlocksLowStorageUsers', true),
      );
      expect(
        oversized.toPrivacySafeDiagnostics(),
        containsPair(
          'receiptLocalOnlyAcceptanceStatusCode',
          'blocked_heavy_pack_required_before_capture',
        ),
      );
      expect(
        oversized.toPrivacySafeDiagnostics(),
        containsPair('receiptLocalOnlyBaseFlowCanRunNow', false),
      );
      expect(
        oversized.toPrivacySafeDiagnostics(),
        containsPair('receiptLocalOnlyBlocksLowStorageUsers', true),
      );
      expect(
        oversized.toPrivacySafeDiagnostics(),
        containsPair(
          'receiptBrainBaseSizeDecisionCode',
          'block_base_over_100mb',
        ),
      );
      expect(
        oversized.toPrivacySafeDiagnostics(),
        containsPair(
          'receiptBrainFirstInstallBoundaryCode',
          'blocked_heavy_pack_in_first_install',
        ),
      );
      expect(
        oversized.toPrivacySafeDiagnostics(),
        containsPair(
          'receiptBrainFirstInstallBoundaryActionCode',
          'move_heavy_ocr_parser_pack_to_optional_download',
        ),
      );
      expect(
        oversized.toPrivacySafeDiagnostics(),
        containsPair('receiptBrainFirstInstallCanRunOnLowStoragePhones', false),
      );
      expect(
        oversized.toPrivacySafeDiagnostics(),
        containsPair('receiptBrainFullOfflineExceedsBaseGuardrail', true),
      );
      expect(
        oversized.toPrivacySafeDiagnostics(),
        containsPair('receiptBrainFullOfflineMustStayOptional', true),
      );
      expect(
        oversized.toPrivacySafeDiagnostics(),
        containsPair(
          'receiptBrainLowStorageDownloadRiskCode',
          'base_install_blocks_low_storage_users',
        ),
      );
      expect(
        oversized.toPrivacySafeDiagnostics(),
        containsPair('receiptRequiredBaseFootprintStatusCode', 'blocked'),
      );
      expect(
        oversized.toPrivacySafeDiagnostics(),
        containsPair('receiptRequiredBaseFootprintCanShip', false),
      );
      expect(
        oversized.toPrivacySafeDiagnostics(),
        containsPair(
          'receiptRequiredBaseFootprintBlockingReasonCodes',
          contains('required_base_over_100mb'),
        ),
      );
      expect(
        oversized.userFacingBaseSizeDecisionLabel,
        contains('too large for release'),
      );
      expect(
        oversized.userFacingLowStorageDownloadWarning,
        contains('Move receipt OCR/parser weight into optional packs'),
      );
      expect(
        oversizedInstallStrategy.requiredInstallSegmentCode,
        'required_base_block_over_100mb',
      );
      expect(
        oversizedInstallStrategy.fullOfflineSegmentCode,
        'full_offline_over_250mb_optional_or_assist',
      );
      expect(
        oversizedInstallStrategy.lowStorageUserImpactCode,
        'blocks_low_storage_users_until_base_trimmed',
      );
      expect(
        oversizedInstallStrategy.recommendedDistributionCode,
        'split_heavy_receipt_work_before_release',
      );
      expect(oversizedInstallStrategy.cameraShellMustStayParserFree, isFalse);
      expect(
        oversizedInstallStrategy.baseDownloadStillUsefulOnTinyPhones,
        isFalse,
      );
      expect(
        oversizedInstallStrategy.userFacingSummary,
        contains('Low-storage users are blocked'),
      );
      expect(
        oversized.toPrivacySafeDiagnostics(),
        containsPair(
          'receiptInstallRecommendedDistributionCode',
          'split_heavy_receipt_work_before_release',
        ),
      );
      expect(
        oversized.toPrivacySafeDiagnostics(),
        containsPair('receiptInstallBaseUsefulOnTinyPhones', false),
      );
    },
  );
}
