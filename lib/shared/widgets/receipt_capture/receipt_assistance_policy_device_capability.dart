part of 'receipt_assistance_policy.dart';

class ReceiptDeviceCapability {
  const ReceiptDeviceCapability({
    required this.profileName,
    required this.tier,
    required this.parserDepth,
    required this.maxLocalPdfBytes,
    required this.maxLocalPdfPages,
    required this.maxLocalPhotoBytes,
    required this.maxLocalPhotoCount,
    required this.cameraResolutionTier,
    required this.assistedCameraShotCount,
    required this.bestShotCandidateCount,
    required this.liveAnalysisGapMs,
    required this.readyHoldMs,
    required this.maxLocalCatalogMatches,
    required this.maxLocalInventoryCacheItems,
    required this.enableSkuDetection,
    required this.enableTradeClassification,
    required this.enableReturnDetection,
    required this.enableAdvancedConfidenceScoring,
    required this.recommendedDataSaverLevel,
  });

  const ReceiptDeviceCapability.standard()
    : this(
        profileName: 'Standard device',
        tier: ReceiptCapabilityTier.medium,
        parserDepth: ReceiptParserDepth.lineItems,
        maxLocalPdfBytes: ReceiptPdfLimits.localAssistedReadBytes,
        maxLocalPdfPages: ReceiptPdfLimits.maxPdfPagesForReceiptOcrLater,
        maxLocalPhotoBytes: 12 * 1024 * 1024,
        maxLocalPhotoCount: 8,
        cameraResolutionTier: ReceiptCameraResolutionTier.high,
        assistedCameraShotCount: 4,
        bestShotCandidateCount: 3,
        liveAnalysisGapMs: 480,
        readyHoldMs: 700,
        maxLocalCatalogMatches: 1500,
        maxLocalInventoryCacheItems: 5000,
        enableSkuDetection: false,
        enableTradeClassification: true,
        enableReturnDetection: true,
        enableAdvancedConfidenceScoring: true,
        recommendedDataSaverLevel: ReceiptDataSaverLevel.balanced,
      );

  const ReceiptDeviceCapability.olderPhone()
    : this(
        profileName: 'Older phone',
        tier: ReceiptCapabilityTier.light,
        parserDepth: ReceiptParserDepth.proofTotalsOnly,
        maxLocalPdfBytes: 8 * 1024 * 1024,
        maxLocalPdfPages: 12,
        maxLocalPhotoBytes: 6 * 1024 * 1024,
        maxLocalPhotoCount: 4,
        cameraResolutionTier: ReceiptCameraResolutionTier.medium,
        assistedCameraShotCount: 2,
        bestShotCandidateCount: 1,
        liveAnalysisGapMs: 760,
        readyHoldMs: 900,
        maxLocalCatalogMatches: 250,
        maxLocalInventoryCacheItems: 1000,
        enableSkuDetection: false,
        enableTradeClassification: false,
        enableReturnDetection: true,
        enableAdvancedConfidenceScoring: false,
        recommendedDataSaverLevel: ReceiptDataSaverLevel.strong,
      );

  const ReceiptDeviceCapability.highCapacity()
    : this(
        profileName: 'High-capacity device',
        tier: ReceiptCapabilityTier.heavyweight,
        parserDepth: ReceiptParserDepth.inventoryMatching,
        maxLocalPdfBytes: ReceiptPdfLimits.localAssistedReadBytes,
        maxLocalPdfPages: ReceiptPdfLimits.maxPdfPagesForReceiptOcrLater,
        maxLocalPhotoBytes: 20 * 1024 * 1024,
        maxLocalPhotoCount: 12,
        cameraResolutionTier: ReceiptCameraResolutionTier.max,
        assistedCameraShotCount: 5,
        bestShotCandidateCount: 5,
        liveAnalysisGapMs: 380,
        readyHoldMs: 600,
        maxLocalCatalogMatches: 8000,
        maxLocalInventoryCacheItems: 25000,
        enableSkuDetection: true,
        enableTradeClassification: true,
        enableReturnDetection: true,
        enableAdvancedConfidenceScoring: true,
        recommendedDataSaverLevel: ReceiptDataSaverLevel.balanced,
      );

  factory ReceiptDeviceCapability.fromHardware({
    ReceiptHardwareProfile hardware = const ReceiptHardwareProfile(),
    ReceiptPerformanceMode mode = ReceiptPerformanceMode.automatic,
  }) {
    final tier = hardware.tierFor(mode);
    final base = switch (tier) {
      ReceiptCapabilityTier.light => const ReceiptDeviceCapability.olderPhone(),
      ReceiptCapabilityTier.medium => const ReceiptDeviceCapability.standard(),
      ReceiptCapabilityTier.heavyweight =>
        const ReceiptDeviceCapability.highCapacity(),
    };
    return base.withStoragePressure(hardware.storageClass);
  }

  final String profileName;
  final ReceiptCapabilityTier tier;
  final ReceiptParserDepth parserDepth;
  final int maxLocalPdfBytes;
  final int maxLocalPdfPages;
  final int maxLocalPhotoBytes;
  final int maxLocalPhotoCount;
  final ReceiptCameraResolutionTier cameraResolutionTier;
  final int assistedCameraShotCount;
  final int bestShotCandidateCount;
  final int liveAnalysisGapMs;
  final int readyHoldMs;
  final int maxLocalCatalogMatches;
  final int maxLocalInventoryCacheItems;
  final bool enableSkuDetection;
  final bool enableTradeClassification;
  final bool enableReturnDetection;
  final bool enableAdvancedConfidenceScoring;
  final ReceiptDataSaverLevel recommendedDataSaverLevel;

  ReceiptDeviceCapability withStoragePressure(
    ReceiptDeviceStorageClass storageClass,
  ) {
    if (storageClass == ReceiptDeviceStorageClass.critical) {
      return ReceiptDeviceCapability(
        profileName: '$profileName - critical storage',
        tier: ReceiptCapabilityTier.light,
        parserDepth: ReceiptParserDepth.proofTotalsOnly,
        maxLocalPdfBytes: _minInt(maxLocalPdfBytes, 4 * 1024 * 1024),
        maxLocalPdfPages: _minInt(maxLocalPdfPages, 6),
        maxLocalPhotoBytes: _minInt(maxLocalPhotoBytes, 4 * 1024 * 1024),
        maxLocalPhotoCount: _minInt(maxLocalPhotoCount, 4),
        cameraResolutionTier: ReceiptCameraResolutionTier.medium,
        assistedCameraShotCount: _minInt(assistedCameraShotCount, 1),
        bestShotCandidateCount: _minInt(bestShotCandidateCount, 1),
        liveAnalysisGapMs: _maxInt(liveAnalysisGapMs, 1100),
        readyHoldMs: _maxInt(readyHoldMs, 1100),
        maxLocalCatalogMatches: _minInt(maxLocalCatalogMatches, 150),
        maxLocalInventoryCacheItems: _minInt(maxLocalInventoryCacheItems, 400),
        enableSkuDetection: false,
        enableTradeClassification: false,
        enableReturnDetection: enableReturnDetection,
        enableAdvancedConfidenceScoring: false,
        recommendedDataSaverLevel: ReceiptDataSaverLevel.maximum,
      );
    }
    if (storageClass == ReceiptDeviceStorageClass.low) {
      final leanDepth = parserDepth == ReceiptParserDepth.inventoryMatching
          ? ReceiptParserDepth.lineItems
          : parserDepth;
      return ReceiptDeviceCapability(
        profileName: '$profileName - low storage',
        tier: ReceiptCapabilityTier.light,
        parserDepth: leanDepth,
        maxLocalPdfBytes: _minInt(maxLocalPdfBytes, 6 * 1024 * 1024),
        maxLocalPdfPages: _minInt(maxLocalPdfPages, 10),
        maxLocalPhotoBytes: _minInt(maxLocalPhotoBytes, 6 * 1024 * 1024),
        maxLocalPhotoCount: _minInt(maxLocalPhotoCount, 5),
        cameraResolutionTier: ReceiptCameraResolutionTier.medium,
        assistedCameraShotCount: _minInt(assistedCameraShotCount, 2),
        bestShotCandidateCount: _minInt(bestShotCandidateCount, 1),
        liveAnalysisGapMs: _maxInt(liveAnalysisGapMs, 850),
        readyHoldMs: _maxInt(readyHoldMs, 950),
        maxLocalCatalogMatches: _minInt(maxLocalCatalogMatches, 500),
        maxLocalInventoryCacheItems: _minInt(maxLocalInventoryCacheItems, 1500),
        enableSkuDetection: false,
        enableTradeClassification:
            leanDepth != ReceiptParserDepth.proofTotalsOnly &&
            enableTradeClassification,
        enableReturnDetection: enableReturnDetection,
        enableAdvancedConfidenceScoring: false,
        recommendedDataSaverLevel: ReceiptDataSaverLevel.strong,
      );
    }
    final recommended = recommendedDataSaverLevel;
    return ReceiptDeviceCapability(
      profileName: profileName,
      tier: tier,
      parserDepth: parserDepth,
      maxLocalPdfBytes: maxLocalPdfBytes,
      maxLocalPdfPages: maxLocalPdfPages,
      maxLocalPhotoBytes: maxLocalPhotoBytes,
      maxLocalPhotoCount: maxLocalPhotoCount,
      cameraResolutionTier: cameraResolutionTier,
      assistedCameraShotCount: assistedCameraShotCount,
      bestShotCandidateCount: bestShotCandidateCount,
      liveAnalysisGapMs: liveAnalysisGapMs,
      readyHoldMs: readyHoldMs,
      maxLocalCatalogMatches: maxLocalCatalogMatches,
      maxLocalInventoryCacheItems: maxLocalInventoryCacheItems,
      enableSkuDetection: enableSkuDetection,
      enableTradeClassification: enableTradeClassification,
      enableReturnDetection: enableReturnDetection,
      enableAdvancedConfidenceScoring: enableAdvancedConfidenceScoring,
      recommendedDataSaverLevel: recommended,
    );
  }
}
