part of 'receipt_assistance_policy.dart';

extension ReceiptBrainFootprintSummaryPrivacyDiagnostics
    on ReceiptBrainFootprintSummary {
  ReceiptLocalOnlyAcceptanceGate get localOnlyAcceptanceGate =>
      ReceiptLocalOnlyAcceptanceGate.fromSummary(this);

  ReceiptInstallFootprintStrategy get installFootprintStrategy =>
      ReceiptInstallFootprintStrategy.fromSummary(this);

  Map<String, Object?> toPrivacySafeDiagnostics() {
    final releaseCheck = ReceiptRequiredBaseFootprintReleaseCheck.fromSummary(
      this,
    );
    final acceptanceGate = localOnlyAcceptanceGate;
    final installStrategy = installFootprintStrategy;
    return {
      'receiptBrainBaseBudgetBytes': baseReceiptBudgetBytes,
      'receiptBrainIncludedLocalPackBytes': includedLocalPackBytes,
      'receiptBrainOptionalLocalPackBytes': optionalLocalPackBytes,
      'receiptBrainFullOfflineBudgetBytes': fullOfflineReceiptBudgetBytes,
      'receiptBrainLocalOcrMode': localOcrMode,
      'receiptBrainParserDepth': parserDepth.name,
      'receiptBrainStorageClass': storageClass.name,
      'receiptBrainOptionalLocalPackCodes': optionalLocalPackCodes,
      'receiptBrainCloudFallbackPackCodes': cloudFallbackPackCodes,
      'receiptBrainBaseWorksWithoutOptionalPacks':
          baseCaptureWorksWithoutOptionalPacks,
      'receiptBrainOptionalPacksDetachedFromBase':
          optionalPacksDetachedFromBaseInstall,
      'receiptBrainRequiredBasePayloadCodes': requiredBasePayloadCodes,
      'receiptBrainOptionalPayloadCodes': optionalPayloadCodes,
      'receiptBrainFirstInstallBoundaryCode': firstInstallReceiptBoundaryCode,
      'receiptBrainFirstInstallBoundaryActionCode':
          firstInstallReceiptBoundaryActionCode,
      'receiptBrainFirstInstallExcludesOptionalBrain':
          firstInstallExcludesOptionalReceiptBrain,
      'receiptBrainFirstInstallRequiresOnlyBaseCapabilities':
          firstInstallRequiresOnlyBaseReceiptCapabilities,
      'receiptBrainFirstInstallCanRunOnLowStoragePhones':
          firstInstallCanRunOnLowStoragePhones,
      'receiptBrainFirstInstallBoundarySummary':
          userFacingFirstInstallReceiptBoundarySummary,
      'receiptBrainBaseCanShipWithoutFullOfflineBrain':
          baseInstallCanShipWithoutFullOfflineReceiptBrain,
      'receiptBrainBaseLocalReceiptReadingAvailable':
          baseLocalReceiptReadingAvailable,
      'receiptBrainBaseWorksWithoutCloudAssist': baseWorksWithoutCloudAssist,
      'receiptBrainLocalFirstReadinessCode': localFirstReadinessCode,
      'receiptBrainLocalFirstReadinessActionCode':
          localFirstReadinessActionCode,
      'receiptBrainUserFacingLocalFirstReadinessSummary':
          userFacingLocalFirstReadinessSummary,
      'receiptBrainOptionalParserPacksRequireUserChoice':
          optionalParserPacksRequireUserChoice,
      'receiptBrainBaseNeedsSizeReview': baseInstallNeedsSizeReview,
      'receiptBrainBaseBlocksLowStorageUsers': baseInstallBlocksLowStorageUsers,
      'receiptBrainBaseSizeDecisionCode': baseInstallSizeDecisionCode,
      'receiptBrainFullOfflineExceedsBaseGuardrail':
          fullOfflineReceiptBrainExceedsRequiredBaseGuardrail,
      'receiptBrainFullOfflineMustStayOptional':
          fullOfflineReceiptBrainMustStayOptional,
      'receiptBrainLowStorageDownloadRiskCode': lowStorageDownloadRiskCode,
      'receiptBrainShouldDeferOptionalLocalPacks':
          shouldDeferOptionalLocalPacks,
      'receiptBrainRequiresExplicitDownload': requiresExplicitDownload,
      'receiptBrainBaseInstallKeepsLean': baseInstallKeepsReceiptBrainLean,
      'receiptBrainBaseUnderRequiredBudget':
          baseInstallStaysUnderRequiredBudget,
      'receiptBrainBaseBudgetTierCode': baseInstallBudgetTierCode,
      'receiptBrainRequiredBaseReleaseActionCode':
          requiredBaseReleaseActionCode,
      'receiptBrainInstallDistributionModeCode': installDistributionModeCode,
      'receiptBrainUserFacingInstallChoiceSummary':
          userFacingInstallChoiceSummary,
      'receiptBrainUserFacingBaseVersusFullOfflineSummary':
          userFacingBaseVersusFullOfflineSummary,
      'receiptBrainRequiredBaseGuardrailSummary':
          userFacingRequiredBaseGuardrailSummary,
      'receiptBrainBaseSizeDecisionLabel': userFacingBaseSizeDecisionLabel,
      'receiptBrainUserFacingLowStorageDownloadWarning':
          userFacingLowStorageDownloadWarning,
      ...installStrategy.toPrivacySafeDiagnostics(),
      ...acceptanceGate.toPrivacySafeDiagnostics(),
      ...releaseCheck.toPrivacySafeDiagnostics(),
    };
  }
}
