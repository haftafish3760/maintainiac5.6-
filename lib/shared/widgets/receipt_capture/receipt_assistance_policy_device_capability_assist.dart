part of 'receipt_assistance_policy.dart';

extension ReceiptDeviceCapabilityAssist on ReceiptDeviceCapability {
  String get localPhotoLimitLabel {
    return '$maxLocalPhotoCount receipt ${maxLocalPhotoCount == 1 ? 'photo' : 'photos'}';
  }

  String get cameraCaptureLabel {
    return '${cameraResolutionTier.label} camera, $assistedCameraShotCount assisted ${assistedCameraShotCount == 1 ? 'shot' : 'shots'}';
  }

  String get localPdfLimitLabel {
    return '$maxLocalPdfPages PDF ${maxLocalPdfPages == 1 ? 'page' : 'pages'}';
  }

  String get localCatalogLimitLabel {
    return '$maxLocalCatalogMatches local catalog matches';
  }

  String get localInventoryCacheLabel {
    return '$maxLocalInventoryCacheItems inventory cache items';
  }

  bool get usesLeanLocalReceiptReading =>
      tier == ReceiptCapabilityTier.light ||
      parserDepth == ReceiptParserDepth.proofTotalsOnly ||
      maxLocalCatalogMatches <= 500;

  bool get shouldOfferCloudOcrAssist {
    return usesLeanLocalReceiptReading ||
        recommendedDataSaverLevel == ReceiptDataSaverLevel.strong ||
        recommendedDataSaverLevel == ReceiptDataSaverLevel.economy ||
        recommendedDataSaverLevel == ReceiptDataSaverLevel.maximum;
  }

  bool get shouldOfferCloudInventoryAssist {
    return maxLocalInventoryCacheItems <= 1000 ||
        maxLocalCatalogMatches <= 500 ||
        parserDepth == ReceiptParserDepth.proofTotalsOnly;
  }

  ReceiptCloudAssistPlan get cloudAssistPlan {
    return cloudAssistPlanFor(dataSaverLevel: recommendedDataSaverLevel);
  }

  ReceiptFeatureInstallRecommendation receiptInstallRecommendationFor(
    ReceiptDeviceStorageClass storageClass,
  ) {
    return cloudAssistPlan.footprintPlan.installRecommendationForStorageClass(
      storageClass,
    );
  }

  ReceiptBrainFootprintSummary receiptBrainFootprintSummaryFor(
    ReceiptDeviceStorageClass storageClass, {
    ReceiptCloudAssistPlan? cloudAssistPlan,
  }) {
    return ReceiptBrainFootprintSummary.fromPlan(
      plan: cloudAssistPlan ?? this.cloudAssistPlan,
      storageClass: storageClass,
    );
  }

  ReceiptBrainDeploymentRecommendation receiptBrainRecommendationFor(
    ReceiptDeviceStorageClass storageClass, {
    ReceiptCloudAssistPlan? cloudAssistPlan,
  }) {
    return ReceiptBrainDeploymentRecommendation.fromCapability(
      capability: this,
      storageClass: storageClass,
      cloudAssistPlan: cloudAssistPlan,
    );
  }

  ReceiptCloudAssistPlan cloudAssistPlanFor({
    required ReceiptDataSaverLevel dataSaverLevel,
  }) {
    final storageConstrained =
        dataSaverLevel == ReceiptDataSaverLevel.economy ||
        dataSaverLevel == ReceiptDataSaverLevel.maximum;
    final leanLocalReceiptReading =
        usesLeanLocalReceiptReading || storageConstrained;
    final offerCloudOcr = shouldOfferCloudOcrAssist || storageConstrained;
    final offerCloudInventory =
        shouldOfferCloudInventoryAssist || storageConstrained;
    return ReceiptCloudAssistPlan(
      localOcrAvailable: true,
      localOcrMode: leanLocalReceiptReading
          ? 'lean_local_ocr'
          : 'full_local_ocr',
      cloudOcrOptional: offerCloudOcr,
      cloudInventoryOptional: offerCloudInventory,
      requiresExplicitUserChoice: offerCloudOcr || offerCloudInventory,
      parserDepth: parserDepth,
      localCatalogMatchLimit: _localCatalogLimitFor(dataSaverLevel),
      localInventoryCacheLimit: _localInventoryCacheLimitFor(dataSaverLevel),
      dataSaverLevel: dataSaverLevel,
    );
  }

  int _localCatalogLimitFor(ReceiptDataSaverLevel dataSaverLevel) {
    final storageLimit = switch (dataSaverLevel) {
      ReceiptDataSaverLevel.maximum => 250,
      ReceiptDataSaverLevel.economy => 1000,
      ReceiptDataSaverLevel.original ||
      ReceiptDataSaverLevel.light ||
      ReceiptDataSaverLevel.balanced ||
      ReceiptDataSaverLevel.strong => maxLocalCatalogMatches,
    };
    return maxLocalCatalogMatches < storageLimit
        ? maxLocalCatalogMatches
        : storageLimit;
  }

  int _localInventoryCacheLimitFor(ReceiptDataSaverLevel dataSaverLevel) {
    final storageLimit = switch (dataSaverLevel) {
      ReceiptDataSaverLevel.maximum => 1000,
      ReceiptDataSaverLevel.economy => 3000,
      ReceiptDataSaverLevel.original ||
      ReceiptDataSaverLevel.light ||
      ReceiptDataSaverLevel.balanced ||
      ReceiptDataSaverLevel.strong => maxLocalInventoryCacheItems,
    };
    return maxLocalInventoryCacheItems < storageLimit
        ? maxLocalInventoryCacheItems
        : storageLimit;
  }

  String get localReceiptReadingPlanLabel {
    if (usesLeanLocalReceiptReading) {
      return 'Basic on-device receipt assistance stays available. Heavy catalog matching and deep line-item work are reduced for this phone.';
    }
    if (tier == ReceiptCapabilityTier.heavyweight) {
      return 'Full on-device receipt assistance is available for this phone, including deeper line-item and matching work.';
    }
    return 'Balanced on-device receipt assistance is available for this phone.';
  }

  String get optionalCloudAssistLabel {
    if (shouldOfferCloudOcrAssist) {
      return 'Optional cloud OCR can be offered for better accuracy, but it must be explicit and require internet.';
    }
    return 'Cloud OCR is optional; local receipt assistance remains the default.';
  }

  String get optionalCloudInventoryAssistLabel {
    if (shouldOfferCloudInventoryAssist) {
      return 'Optional cloud inventory matching can be offered for large catalogs, but it must be explicit, require internet, and keep local receipt capture usable.';
    }
    return 'Local inventory matching is available for this device; cloud inventory matching remains optional.';
  }

  String get optionalCloudAssistPlanLabel {
    return cloudAssistPlan.userFacingSummary;
  }

  String get recommendedSpaceSavingLabel {
    return '${recommendedDataSaverLevel.label}: ${recommendedDataSaverLevel.shortLabel}';
  }

  List<String> get enabledFeatureLabels {
    return [
      if (enableSkuDetection) 'SKU detection',
      if (enableTradeClassification) 'Trade classification',
      if (enableReturnDetection) 'Return/discount detection',
      if (enableAdvancedConfidenceScoring) 'Advanced confidence scoring',
    ];
  }

  String get enabledFeaturesLabel {
    final labels = enabledFeatureLabels;
    if (labels.isEmpty) return 'Basic receipt parsing';
    if (labels.length == 1) return labels.single;
    return '${labels.take(labels.length - 1).join(', ')} and ${labels.last}';
  }
}
