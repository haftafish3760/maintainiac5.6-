part of 'receipt_assistance_policy.dart';

class ReceiptInstallFootprintStrategy {
  const ReceiptInstallFootprintStrategy({
    required this.requiredBaseBytes,
    required this.optionalOfflineBytes,
    required this.fullOfflineBytes,
    required this.storageClass,
    required this.requiredInstallSegmentCode,
    required this.fullOfflineSegmentCode,
    required this.lowStorageUserImpactCode,
    required this.recommendedDistributionCode,
    required this.cameraShellMustStayParserFree,
    required this.baseDownloadStillUsefulOnTinyPhones,
    required this.optionalOfflinePacksRequireConsent,
    required this.userFacingSummary,
  });

  factory ReceiptInstallFootprintStrategy.fromSummary(
    ReceiptBrainFootprintSummary summary,
  ) {
    final requiredSegment = _requiredInstallSegmentCode(
      summary.baseReceiptBudgetBytes,
    );
    final fullSegment = _fullOfflineSegmentCode(
      summary.fullOfflineReceiptBudgetBytes,
      summary.baseReceiptBudgetBytes,
    );
    final cameraShellParserFree =
        summary.includedLocalPackBytes == 0 &&
        summary.optionalPacksDetachedFromBaseInstall &&
        summary.baseCaptureWorksWithoutOptionalPacks;
    final baseUsefulOnTinyPhones =
        summary.baseInstallStaysUnderRequiredBudget &&
        summary.baseLocalReceiptReadingAvailable &&
        cameraShellParserFree;
    final optionalConsent =
        summary.optionalLocalPackBytes == 0 || summary.requiresExplicitDownload;
    final lowStorageImpact = _lowStorageImpactCode(
      summary: summary,
      baseUsefulOnTinyPhones: baseUsefulOnTinyPhones,
      optionalConsent: optionalConsent,
    );
    final distribution = _recommendedInstallDistributionCode(
      summary: summary,
      baseUsefulOnTinyPhones: baseUsefulOnTinyPhones,
      optionalConsent: optionalConsent,
    );

    return ReceiptInstallFootprintStrategy(
      requiredBaseBytes: summary.baseReceiptBudgetBytes,
      optionalOfflineBytes: summary.optionalLocalPackBytes,
      fullOfflineBytes: summary.fullOfflineReceiptBudgetBytes,
      storageClass: summary.storageClass,
      requiredInstallSegmentCode: requiredSegment,
      fullOfflineSegmentCode: fullSegment,
      lowStorageUserImpactCode: lowStorageImpact,
      recommendedDistributionCode: distribution,
      cameraShellMustStayParserFree: cameraShellParserFree,
      baseDownloadStillUsefulOnTinyPhones: baseUsefulOnTinyPhones,
      optionalOfflinePacksRequireConsent: optionalConsent,
      userFacingSummary: _installFootprintUserSummary(
        summary: summary,
        distribution: distribution,
        lowStorageImpact: lowStorageImpact,
      ),
    );
  }

  final int requiredBaseBytes;
  final int optionalOfflineBytes;
  final int fullOfflineBytes;
  final ReceiptDeviceStorageClass storageClass;
  final String requiredInstallSegmentCode;
  final String fullOfflineSegmentCode;
  final String lowStorageUserImpactCode;
  final String recommendedDistributionCode;
  final bool cameraShellMustStayParserFree;
  final bool baseDownloadStillUsefulOnTinyPhones;
  final bool optionalOfflinePacksRequireConsent;
  final String userFacingSummary;

  String get requiredBaseLabel => _formatReceiptBytes(requiredBaseBytes);
  String get optionalOfflineLabel => _formatReceiptBytes(optionalOfflineBytes);
  String get fullOfflineLabel => _formatReceiptBytes(fullOfflineBytes);

  Map<String, Object?> toPrivacySafeDiagnostics() {
    return {
      'receiptInstallRequiredBaseBytes': requiredBaseBytes,
      'receiptInstallOptionalOfflineBytes': optionalOfflineBytes,
      'receiptInstallFullOfflineBytes': fullOfflineBytes,
      'receiptInstallStorageClass': storageClass.name,
      'receiptInstallRequiredSegmentCode': requiredInstallSegmentCode,
      'receiptInstallFullOfflineSegmentCode': fullOfflineSegmentCode,
      'receiptInstallLowStorageUserImpactCode': lowStorageUserImpactCode,
      'receiptInstallRecommendedDistributionCode': recommendedDistributionCode,
      'receiptInstallCameraShellParserFree': cameraShellMustStayParserFree,
      'receiptInstallBaseUsefulOnTinyPhones':
          baseDownloadStillUsefulOnTinyPhones,
      'receiptInstallOptionalPacksRequireConsent':
          optionalOfflinePacksRequireConsent,
      'receiptInstallUserFacingSummary': userFacingSummary,
    };
  }
}

String _requiredInstallSegmentCode(int requiredBaseBytes) {
  if (requiredBaseBytes <=
      ReceiptBrainFootprintSummary.leanBaseReceiptBudgetBytes) {
    return 'required_base_lean_under_40mb';
  }
  if (requiredBaseBytes <=
      ReceiptBrainFootprintSummary.reviewRequiredBaseReceiptBudgetBytes) {
    return 'required_base_watch_40_to_50mb';
  }
  if (requiredBaseBytes <=
      ReceiptBrainFootprintSummary.maxRequiredBaseReceiptBudgetBytes) {
    return 'required_base_review_50_to_100mb';
  }
  return 'required_base_block_over_100mb';
}

String _fullOfflineSegmentCode(int fullOfflineBytes, int requiredBaseBytes) {
  if (fullOfflineBytes <= requiredBaseBytes) {
    return 'full_offline_same_as_base';
  }
  if (fullOfflineBytes <=
      ReceiptBrainFootprintSummary.maxRequiredBaseReceiptBudgetBytes) {
    return 'full_offline_under_100mb_optional';
  }
  if (fullOfflineBytes <= 250 * 1024 * 1024) {
    return 'full_offline_100_to_250mb_optional';
  }
  return 'full_offline_over_250mb_optional_or_assist';
}

String _lowStorageImpactCode({
  required ReceiptBrainFootprintSummary summary,
  required bool baseUsefulOnTinyPhones,
  required bool optionalConsent,
}) {
  if (!baseUsefulOnTinyPhones) {
    return 'blocks_low_storage_users_until_base_trimmed';
  }
  if (summary.storageClass == ReceiptDeviceStorageClass.critical ||
      summary.storageClass == ReceiptDeviceStorageClass.low) {
    if (summary.optionalLocalPackBytes > 0) {
      return optionalConsent
          ? 'low_storage_base_only_optional_pack_hidden'
          : 'low_storage_optional_pack_consent_missing';
    }
    return 'low_storage_base_flow_ready';
  }
  if (summary.optionalLocalPackBytes > 0) {
    return 'larger_storage_can_choose_optional_offline';
  }
  return 'base_flow_enough_for_this_device';
}

String _recommendedInstallDistributionCode({
  required ReceiptBrainFootprintSummary summary,
  required bool baseUsefulOnTinyPhones,
  required bool optionalConsent,
}) {
  if (!baseUsefulOnTinyPhones) {
    return 'split_heavy_receipt_work_before_release';
  }
  if (!optionalConsent) {
    return 'require_explicit_pack_consent_before_release';
  }
  if (summary.storageClass == ReceiptDeviceStorageClass.critical ||
      summary.storageClass == ReceiptDeviceStorageClass.low) {
    return summary.optionalLocalPackBytes > 0
        ? 'ship_base_hide_large_packs_until_storage_allows'
        : 'ship_base_receipt_flow_only';
  }
  if (summary.optionalLocalPackBytes > 0) {
    return 'ship_base_offer_optional_offline_receipt_packs';
  }
  if (summary.cloudFallbackPackCodes.isNotEmpty) {
    return 'ship_base_offer_optional_assist_only';
  }
  return 'ship_base_no_extra_receipt_download';
}

String _installFootprintUserSummary({
  required ReceiptBrainFootprintSummary summary,
  required String distribution,
  required String lowStorageImpact,
}) {
  final base =
      'The required receipt camera, proof save, manual entry, and basic local reading stay at ${summary.baseReceiptBudgetLabel}.';
  final full = summary.optionalLocalPackBytes > 0
      ? 'The stronger offline receipt brain is ${summary.optionalLocalPackSizeLabel} and must be a later choice.'
      : 'No stronger offline receipt pack is required for this setup.';
  final lowStorage = switch (lowStorageImpact) {
    'blocks_low_storage_users_until_base_trimmed' =>
      'Low-storage users are blocked until the required base is trimmed.',
    'low_storage_base_only_optional_pack_hidden' =>
      'Low-storage users get the base flow first; large packs stay hidden until there is room.',
    'low_storage_optional_pack_consent_missing' =>
      'Low-storage users need explicit consent before any optional receipt pack is offered.',
    'low_storage_base_flow_ready' =>
      'Low-storage users can capture and review basic receipts now.',
    _ =>
      'Users with more storage can choose stronger offline receipt help later.',
  };
  final action = switch (distribution) {
    'split_heavy_receipt_work_before_release' =>
      'Move heavy OCR/parser work out of the first install.',
    'require_explicit_pack_consent_before_release' =>
      'Require a clear user choice before any pack download.',
    'ship_base_hide_large_packs_until_storage_allows' =>
      'Ship the base app and wait before showing large pack downloads.',
    'ship_base_offer_optional_offline_receipt_packs' =>
      'Ship the base app and offer offline packs only as an explicit upgrade.',
    _ => 'Ship the base receipt flow.',
  };
  return '$base $full $lowStorage $action';
}
