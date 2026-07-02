part of 'receipt_assistance_policy.dart';

class ReceiptBrainDeploymentRecommendation {
  const ReceiptBrainDeploymentRecommendation({
    required this.modeCode,
    required this.localOcrMode,
    required this.baseCaptureAlwaysAvailable,
    required this.localReceiptReaderDefault,
    required this.optionalLocalPackAllowed,
    required this.optionalLocalPackBytes,
    required this.assistFallbackAllowed,
    required this.requiresInternetForAssist,
    required this.storageClass,
    required this.deviceTier,
    required this.userFacingSummary,
    required this.userFacingStorageWarning,
  });

  factory ReceiptBrainDeploymentRecommendation.fromCapability({
    required ReceiptDeviceCapability capability,
    required ReceiptDeviceStorageClass storageClass,
    ReceiptCloudAssistPlan? cloudAssistPlan,
  }) {
    final cloudPlan = cloudAssistPlan ?? capability.cloudAssistPlan;
    final footprint = cloudPlan.footprintPlan;
    final install = footprint.installRecommendationForStorageClass(
      storageClass,
    );
    final optionalBytes = install.optionalLocalDownloadAllowed
        ? _minInt(
            footprint.optionalLocalPackBytes,
            install.maxOptionalLocalDownloadBytes,
          )
        : 0;
    final assistAllowed =
        install.cloudFallbackSuggested || cloudPlan.hasOptionalCloudAssist;
    final modeCode = switch (storageClass) {
      ReceiptDeviceStorageClass.critical => 'base_local_reader_only',
      ReceiptDeviceStorageClass.low =>
        optionalBytes > 0
            ? 'base_local_reader_small_pack_optional'
            : 'base_local_reader_assist_optional',
      ReceiptDeviceStorageClass.comfortable =>
        optionalBytes > 0
            ? 'base_local_reader_offline_pack_optional'
            : 'base_local_reader_default',
      ReceiptDeviceStorageClass.roomy =>
        optionalBytes > 0
            ? 'full_offline_pack_optional'
            : 'full_local_reader_default',
      ReceiptDeviceStorageClass.unknown => 'base_local_reader_until_checked',
    };

    final summaryParts = <String>[
      'Receipt capture works in the base app.',
      cloudPlan.localOcrLabel,
      if (optionalBytes > 0)
        'Optional offline receipt add-ons can use about ${_formatReceiptBytes(optionalBytes)}.',
      if (assistAllowed)
        'Assisted reading can be offered later, but it must be an explicit user choice.',
      'Saved proof copies can be smaller; OCR still reads the clearest source first.',
    ];
    return ReceiptBrainDeploymentRecommendation(
      modeCode: modeCode,
      localOcrMode: cloudPlan.localOcrMode,
      baseCaptureAlwaysAvailable: true,
      localReceiptReaderDefault: cloudPlan.localOcrAvailable,
      optionalLocalPackAllowed: install.optionalLocalDownloadAllowed,
      optionalLocalPackBytes: optionalBytes,
      assistFallbackAllowed: assistAllowed,
      requiresInternetForAssist:
          assistAllowed && cloudPlan.requiresExplicitUserChoice,
      storageClass: storageClass,
      deviceTier: capability.tier,
      userFacingSummary: summaryParts.join(' '),
      userFacingStorageWarning: _storageWarningFor(
        storageClass: storageClass,
        optionalBytes: optionalBytes,
      ),
    );
  }

  final String modeCode;
  final String localOcrMode;
  final bool baseCaptureAlwaysAvailable;
  final bool localReceiptReaderDefault;
  final bool optionalLocalPackAllowed;
  final int optionalLocalPackBytes;
  final bool assistFallbackAllowed;
  final bool requiresInternetForAssist;
  final ReceiptDeviceStorageClass storageClass;
  final ReceiptCapabilityTier deviceTier;
  final String userFacingSummary;
  final String userFacingStorageWarning;

  String get optionalLocalPackSizeLabel {
    return _formatReceiptBytes(optionalLocalPackBytes);
  }

  bool get keepsBaseInstallLean {
    return baseCaptureAlwaysAvailable &&
        (!optionalLocalPackAllowed || optionalLocalPackBytes > 0);
  }

  Map<String, Object?> toPrivacySafeDiagnostics() {
    return {
      'receiptBrainMode': modeCode,
      'receiptBrainLocalOcrMode': localOcrMode,
      'receiptBrainBaseCaptureAvailable': baseCaptureAlwaysAvailable,
      'receiptBrainLocalReaderDefault': localReceiptReaderDefault,
      'receiptBrainOptionalLocalPackAllowed': optionalLocalPackAllowed,
      'receiptBrainOptionalLocalPackBytes': optionalLocalPackBytes,
      'receiptBrainAssistFallbackAllowed': assistFallbackAllowed,
      'receiptBrainRequiresInternetForAssist': requiresInternetForAssist,
      'receiptBrainStorageClass': storageClass.name,
      'receiptBrainDeviceTier': deviceTier.name,
      'receiptBrainKeepsBaseInstallLean': keepsBaseInstallLean,
    };
  }

  static String _storageWarningFor({
    required ReceiptDeviceStorageClass storageClass,
    required int optionalBytes,
  }) {
    return switch (storageClass) {
      ReceiptDeviceStorageClass.critical =>
        'Storage is very tight. Keep receipt capture, fuel receipts, and basic local reading available first. Bigger offline parser packs stay hidden until the user has room and chooses them.',
      ReceiptDeviceStorageClass.low =>
        optionalBytes > 0
            ? 'Storage is limited. Fuel receipts still use the base reader. Offer only the small offline line-item add-on, and make it optional.'
            : 'Storage is limited. Fuel receipts still use the base reader. Offer assisted reading only when the user chooses it.',
      ReceiptDeviceStorageClass.comfortable =>
        optionalBytes > 0
            ? 'This phone can choose stronger offline receipt packs, but the download must be optional.'
            : 'The base local reader is enough for this setup.',
      ReceiptDeviceStorageClass.roomy =>
        optionalBytes > 0
            ? 'This phone can choose the full offline receipt pack.'
            : 'This phone can use the full local receipt reader without extra packs.',
      ReceiptDeviceStorageClass.unknown =>
        'Check storage before offering large receipt downloads.',
    };
  }
}
