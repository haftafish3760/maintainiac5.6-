part of 'receipt_assistance_policy.dart';

class ReceiptBrainFootprintSummary {
  static const int leanBaseReceiptBudgetBytes = 40 * 1024 * 1024;
  static const int reviewRequiredBaseReceiptBudgetBytes = 50 * 1024 * 1024;
  static const int maxRequiredBaseReceiptBudgetBytes = 100 * 1024 * 1024;

  const ReceiptBrainFootprintSummary({
    required this.baseReceiptBudgetBytes,
    required this.includedLocalPackBytes,
    required this.optionalLocalPackBytes,
    required this.fullOfflineReceiptBudgetBytes,
    required this.localOcrMode,
    required this.parserDepth,
    required this.storageClass,
    required this.optionalLocalPackCodes,
    required this.cloudFallbackPackCodes,
    required this.baseCaptureWorksWithoutOptionalPacks,
    required this.optionalPacksDetachedFromBaseInstall,
    required this.shouldDeferOptionalLocalPacks,
    required this.requiresExplicitDownload,
    required this.userFacingFootprintSummary,
  });

  factory ReceiptBrainFootprintSummary.fromPlan({
    required ReceiptCloudAssistPlan plan,
    required ReceiptDeviceStorageClass storageClass,
  }) {
    final footprint = plan.footprintPlan;
    final install = footprint.installRecommendationForStorageClass(
      storageClass,
    );
    final optionalBytes = install.optionalLocalDownloadAllowed
        ? _minInt(
            footprint.optionalLocalPackBytes,
            install.maxOptionalLocalDownloadBytes,
          )
        : 0;
    final fullOfflineBytes =
        footprint.baseReceiptBudgetBytes +
        footprint.includedLocalPackBytes +
        footprint.optionalLocalPackBytes;
    final deferOptional =
        storageClass == ReceiptDeviceStorageClass.critical ||
        (storageClass == ReceiptDeviceStorageClass.low &&
            footprint.optionalLocalPackBytes > optionalBytes);
    final baseSummary =
        'Receipt camera, proof capture, and the base local reader stay in the base app budget (${footprint.baseReceiptBudgetLabel}).';
    final optionalSummary = optionalBytes > 0
        ? 'Optional offline receipt add-ons can download about ${_formatReceiptBytes(optionalBytes)} after the user chooses them.'
        : 'No optional offline receipt add-on should be offered on this storage setup.';
    final cloudSummary = footprint.cloudFallbackPackCodes.isEmpty
        ? 'Cloud fallback is not part of this setup.'
        : 'Cloud fallback remains optional and requires internet.';

    return ReceiptBrainFootprintSummary(
      baseReceiptBudgetBytes: footprint.baseReceiptBudgetBytes,
      includedLocalPackBytes: footprint.includedLocalPackBytes,
      optionalLocalPackBytes: optionalBytes,
      fullOfflineReceiptBudgetBytes: fullOfflineBytes,
      localOcrMode: plan.localOcrMode,
      parserDepth: plan.parserDepth,
      storageClass: storageClass,
      optionalLocalPackCodes: plan.optionalLocalParserPackCodes,
      cloudFallbackPackCodes: footprint.cloudFallbackPackCodes,
      baseCaptureWorksWithoutOptionalPacks: true,
      optionalPacksDetachedFromBaseInstall: true,
      shouldDeferOptionalLocalPacks: deferOptional,
      requiresExplicitDownload: optionalBytes > 0,
      userFacingFootprintSummary: '$baseSummary $optionalSummary $cloudSummary',
    );
  }

  final int baseReceiptBudgetBytes;
  final int includedLocalPackBytes;
  final int optionalLocalPackBytes;
  final int fullOfflineReceiptBudgetBytes;
  final String localOcrMode;
  final ReceiptParserDepth parserDepth;
  final ReceiptDeviceStorageClass storageClass;
  final List<String> optionalLocalPackCodes;
  final List<String> cloudFallbackPackCodes;
  final bool baseCaptureWorksWithoutOptionalPacks;
  final bool optionalPacksDetachedFromBaseInstall;
  final bool shouldDeferOptionalLocalPacks;
  final bool requiresExplicitDownload;
  final String userFacingFootprintSummary;
}
