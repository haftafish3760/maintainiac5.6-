part of 'receipt_assistance_policy.dart';

class ReceiptFeatureFootprintPlan {
  const ReceiptFeatureFootprintPlan({
    required this.baseReceiptBudgetBytes,
    required this.includedLocalPackBytes,
    required this.optionalLocalPackBytes,
    required this.cloudFallbackPackCodes,
    required this.lowStorageSafe,
    required this.requiresExplicitDownloadForHeavyPacks,
  });

  factory ReceiptFeatureFootprintPlan.fromCloudAssistPlan(
    ReceiptCloudAssistPlan plan,
  ) {
    final disclosures = plan.parserPackDisclosures;
    final includedBytes = disclosures
        .where(
          (pack) =>
              pack.availability == ReceiptParserPackAvailability.includedLocal,
        )
        .fold<int>(0, (sum, pack) => sum + pack.estimatedBytes);
    final optionalBytes = disclosures
        .where(
          (pack) =>
              pack.availability ==
              ReceiptParserPackAvailability.optionalLocalDownload,
        )
        .fold<int>(0, (sum, pack) => sum + pack.estimatedBytes);
    final cloudFallback = disclosures
        .where((pack) => pack.isCloudFallback)
        .map((pack) => pack.code)
        .toList(growable: false);
    final lowStorageSafe =
        plan.parserDepth == ReceiptParserDepth.proofTotalsOnly &&
        optionalBytes == 0 &&
        plan.localCatalogMatchLimit <= 250 &&
        plan.localInventoryCacheLimit <= 1000;

    return ReceiptFeatureFootprintPlan(
      baseReceiptBudgetBytes:
          ReceiptBrainFootprintSummary.leanBaseReceiptBudgetBytes,
      includedLocalPackBytes: includedBytes,
      optionalLocalPackBytes: optionalBytes,
      cloudFallbackPackCodes: List.unmodifiable(cloudFallback),
      lowStorageSafe: lowStorageSafe,
      requiresExplicitDownloadForHeavyPacks: optionalBytes > 0,
    );
  }

  final int baseReceiptBudgetBytes;
  final int includedLocalPackBytes;
  final int optionalLocalPackBytes;
  final List<String> cloudFallbackPackCodes;
  final bool lowStorageSafe;
  final bool requiresExplicitDownloadForHeavyPacks;

  bool get baseIncludesHeavyParserPacks => includedLocalPackBytes > 0;

  String get baseReceiptBudgetLabel =>
      _formatReceiptBytes(baseReceiptBudgetBytes);

  String get optionalLocalPackSizeLabel =>
      _formatReceiptBytes(optionalLocalPackBytes);

  String get userFacingFootprintLabel {
    final base =
        'The core receipt camera and basic local receipt reading stay in the base app budget.';
    final optional = optionalLocalPackBytes > 0
        ? 'Stronger offline receipt packs can add about $optionalLocalPackSizeLabel only after the user chooses to download them.'
        : 'No extra local receipt pack download is needed for this setup.';
    final cloud = cloudFallbackPackCodes.isEmpty
        ? 'Cloud fallback is not part of this setup.'
        : 'Cloud fallback is optional and requires internet.';
    return '$base $optional $cloud';
  }

  ReceiptFeatureInstallRecommendation installRecommendationForStorageClass(
    ReceiptDeviceStorageClass storageClass,
  ) {
    return ReceiptFeatureInstallRecommendation.fromFootprintPlan(
      this,
      storageClass: storageClass,
    );
  }

  Map<String, Object?> toPrivacySafeDiagnostics() {
    return {
      'baseReceiptBudgetBytes': baseReceiptBudgetBytes,
      'includedLocalPackBytes': includedLocalPackBytes,
      'optionalLocalPackBytes': optionalLocalPackBytes,
      'baseIncludesHeavyParserPacks': baseIncludesHeavyParserPacks,
      'footprintCloudFallbackPackCodes': cloudFallbackPackCodes,
      'lowStorageSafe': lowStorageSafe,
      'requiresExplicitDownloadForHeavyPacks':
          requiresExplicitDownloadForHeavyPacks,
    };
  }
}

class ReceiptFeatureInstallRecommendation {
  const ReceiptFeatureInstallRecommendation({
    required this.modeCode,
    required this.userFacingLabel,
    required this.optionalLocalDownloadAllowed,
    required this.cloudFallbackSuggested,
    required this.maxOptionalLocalDownloadBytes,
    required this.reasonCode,
  });

  factory ReceiptFeatureInstallRecommendation.fromFootprintPlan(
    ReceiptFeatureFootprintPlan plan, {
    required ReceiptDeviceStorageClass storageClass,
  }) {
    final hasHeavyOptionalPack = plan.optionalLocalPackBytes > 0;
    final hasCloudFallback = plan.cloudFallbackPackCodes.isNotEmpty;
    switch (storageClass) {
      case ReceiptDeviceStorageClass.critical:
        return ReceiptFeatureInstallRecommendation(
          modeCode: 'base_receipt_only',
          userFacingLabel:
              'Keep the receipt camera lean on this phone. Use the base receipt reader now; bigger offline packs can wait.',
          optionalLocalDownloadAllowed: false,
          cloudFallbackSuggested: hasCloudFallback || hasHeavyOptionalPack,
          maxOptionalLocalDownloadBytes: 0,
          reasonCode: 'critical_storage_protect_base_capture',
        );
      case ReceiptDeviceStorageClass.low:
        final smallPackAllowed =
            hasHeavyOptionalPack &&
            plan.optionalLocalPackBytes <= 24 * 1024 * 1024;
        return ReceiptFeatureInstallRecommendation(
          modeCode: smallPackAllowed
              ? 'small_optional_pack_allowed'
              : 'base_receipt_cloud_assist_preferred',
          userFacingLabel: smallPackAllowed
              ? 'A small offline receipt add-on can be offered, but the base receipt camera still works without it.'
              : 'Keep the base receipt camera installed and offer cloud assist or later downloads for heavier receipt intelligence.',
          optionalLocalDownloadAllowed: smallPackAllowed,
          cloudFallbackSuggested: hasCloudFallback || !smallPackAllowed,
          maxOptionalLocalDownloadBytes: 24 * 1024 * 1024,
          reasonCode: 'low_storage_limit_optional_downloads',
        );
      case ReceiptDeviceStorageClass.comfortable:
        final allowed =
            hasHeavyOptionalPack &&
            plan.optionalLocalPackBytes <= 100 * 1024 * 1024;
        return ReceiptFeatureInstallRecommendation(
          modeCode: allowed
              ? 'optional_receipt_packs_allowed'
              : 'base_receipt_first',
          userFacingLabel: allowed
              ? 'Offer stronger offline receipt packs as an explicit download; keep the base receipt camera separate.'
              : 'Use the base receipt camera first and keep large receipt packs optional.',
          optionalLocalDownloadAllowed: allowed,
          cloudFallbackSuggested: hasCloudFallback,
          maxOptionalLocalDownloadBytes: 100 * 1024 * 1024,
          reasonCode: 'comfortable_storage_explicit_optional_packs',
        );
      case ReceiptDeviceStorageClass.roomy:
        return ReceiptFeatureInstallRecommendation(
          modeCode: hasHeavyOptionalPack
              ? 'full_offline_receipt_packs_allowed'
              : 'base_receipt_sufficient',
          userFacingLabel: hasHeavyOptionalPack
              ? 'This phone can be offered the full offline receipt pack, but it still must be a clear user choice.'
              : 'The base receipt install is enough for this receipt setup.',
          optionalLocalDownloadAllowed: hasHeavyOptionalPack,
          cloudFallbackSuggested: hasCloudFallback,
          maxOptionalLocalDownloadBytes: plan.optionalLocalPackBytes,
          reasonCode: 'roomy_storage_full_offline_optional',
        );
      case ReceiptDeviceStorageClass.unknown:
        return ReceiptFeatureInstallRecommendation(
          modeCode: 'base_receipt_until_storage_known',
          userFacingLabel:
              'Use the base receipt camera first. Offer larger receipt packs only after storage can be checked.',
          optionalLocalDownloadAllowed: false,
          cloudFallbackSuggested: hasCloudFallback || hasHeavyOptionalPack,
          maxOptionalLocalDownloadBytes: 0,
          reasonCode: 'unknown_storage_conservative_default',
        );
    }
  }

  final String modeCode;
  final String userFacingLabel;
  final bool optionalLocalDownloadAllowed;
  final bool cloudFallbackSuggested;
  final int maxOptionalLocalDownloadBytes;
  final String reasonCode;

  String get maxOptionalLocalDownloadLabel {
    return _formatReceiptBytes(maxOptionalLocalDownloadBytes);
  }

  Map<String, Object?> toPrivacySafeDiagnostics() {
    return {
      'receiptInstallMode': modeCode,
      'receiptInstallOptionalLocalDownloadAllowed':
          optionalLocalDownloadAllowed,
      'receiptInstallCloudFallbackSuggested': cloudFallbackSuggested,
      'receiptInstallMaxOptionalLocalBytes': maxOptionalLocalDownloadBytes,
      'receiptInstallReason': reasonCode,
      'receiptInstallLabel': userFacingLabel,
    };
  }
}
