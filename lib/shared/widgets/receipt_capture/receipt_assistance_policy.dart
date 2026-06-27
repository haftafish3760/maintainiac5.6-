import 'receipt_capture_models.dart';
import 'receipt_pdf_inspector.dart';
import 'receipt_pdf_limits.dart';

enum ReceiptAssistanceMode {
  localRead('Read on this device'),
  localReadWithReview('Read on this device, then review'),
  proofOnly('Save proof only'),
  cloudCandidate('Can offer cloud-assisted reading later');

  const ReceiptAssistanceMode(this.label);

  final String label;
}

enum ReceiptPerformanceMode {
  automatic('Automatic', 'Let Maintainiac choose the right receipt workload.'),
  batterySaver('Battery Saver', 'Use the lightest local receipt reading path.'),
  balanced('Balanced', 'Use a steady receipt reading path for most phones.'),
  maximumPerformance(
    'Maximum Performance',
    'Use the heaviest local receipt reading path this phone can handle.',
  );

  const ReceiptPerformanceMode(this.label, this.description);

  final String label;
  final String description;

  static ReceiptPerformanceMode fromName(String? name) {
    return ReceiptPerformanceMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => ReceiptPerformanceMode.automatic,
    );
  }
}

enum ReceiptCapabilityTier {
  light('Light'),
  medium('Medium'),
  heavyweight('Heavyweight');

  const ReceiptCapabilityTier(this.label);

  final String label;
}

enum ReceiptParserDepth {
  proofTotalsOnly('Vendor, date, subtotal, tax, and total'),
  lineItems('Line items, business/personal/split, and categories'),
  inventoryMatching(
    'Line items, inventory matching, SKU checks, trade terms, and review scoring',
  );

  const ReceiptParserDepth(this.label);

  final String label;
}

enum ReceiptCameraResolutionTier {
  medium('Medium'),
  high('High'),
  max('Receipt High');

  const ReceiptCameraResolutionTier(this.label);

  final String label;
}

enum ReceiptDeviceStorageClass {
  unknown('Unknown'),
  critical('Critical'),
  low('Low'),
  comfortable('Comfortable'),
  roomy('Roomy');

  const ReceiptDeviceStorageClass(this.label);

  final String label;
}

class ReceiptHardwareProfile {
  const ReceiptHardwareProfile({
    this.platformName,
    this.platformVersion,
    this.deviceModel,
    this.deviceManufacturer,
    this.deviceName,
    this.appVersion,
    this.appBuildNumber,
    this.availableRamMb,
    this.cpuCores,
    this.androidSdk,
    this.androidPerformanceClass,
    this.freeStorageMb,
    this.lowPowerMode = false,
    this.hasOnDeviceAcceleration = false,
    this.cameraPermissionGranted = false,
    this.cameraCount = 0,
    this.hasRearCamera = false,
    this.hasFrontCamera = false,
    this.rearCameraName,
  });

  final String? platformName;
  final String? platformVersion;
  final String? deviceModel;
  final String? deviceManufacturer;
  final String? deviceName;
  final String? appVersion;
  final String? appBuildNumber;
  final int? availableRamMb;
  final int? cpuCores;
  final int? androidSdk;
  final int? androidPerformanceClass;
  final int? freeStorageMb;
  final bool lowPowerMode;
  final bool hasOnDeviceAcceleration;
  final bool cameraPermissionGranted;
  final int cameraCount;
  final bool hasRearCamera;
  final bool hasFrontCamera;
  final String? rearCameraName;

  ReceiptCapabilityTier tierFor(ReceiptPerformanceMode mode) {
    return switch (mode) {
      ReceiptPerformanceMode.batterySaver => ReceiptCapabilityTier.light,
      ReceiptPerformanceMode.balanced => ReceiptCapabilityTier.medium,
      ReceiptPerformanceMode.maximumPerformance => _automaticTier(
        allowHeavy: true,
      ),
      ReceiptPerformanceMode.automatic => _automaticTier(allowHeavy: true),
    };
  }

  ReceiptCapabilityTier _automaticTier({required bool allowHeavy}) {
    if (lowPowerMode || _isConstrained) return ReceiptCapabilityTier.light;
    final score = _score;
    if (allowHeavy && score >= 8) return ReceiptCapabilityTier.heavyweight;
    if (score >= 4) return ReceiptCapabilityTier.medium;
    return ReceiptCapabilityTier.light;
  }

  bool get _isConstrained {
    final ram = availableRamMb;
    final storage = freeStorageMb;
    return (cameraCount > 0 && !hasRearCamera) ||
        (ram != null && ram <= 4096) ||
        (storage != null && storage < 1200) ||
        (cpuCores != null && cpuCores! <= 4);
  }

  int get _score {
    var score = 0;
    final ram = availableRamMb;
    if (ram != null) {
      if (ram >= 8192) {
        score += 4;
      } else if (ram >= 6144) {
        score += 3;
      } else if (ram >= 4096) {
        score += 1;
      }
    } else if ((cpuCores ?? 0) >= 6) {
      score += 2;
    }
    final cores = cpuCores;
    if (cores != null) {
      if (cores >= 8) {
        score += 2;
      } else if (cores >= 6) {
        score += 1;
      }
    }
    final performanceClass = androidPerformanceClass;
    if (performanceClass != null) {
      if (performanceClass >= 33) {
        score += 3;
      } else if (performanceClass >= 30) {
        score += 2;
      }
    } else {
      final sdk = androidSdk;
      if (sdk != null && sdk >= 33) score += 1;
    }
    if (hasOnDeviceAcceleration) score += 2;
    if (cameraPermissionGranted && hasRearCamera) score += 1;
    final storage = freeStorageMb;
    if (storage != null && storage >= 4096) score += 1;
    return score;
  }

  String get platformLabel {
    final name = platformName?.trim();
    if (name == null || name.isEmpty) return 'Unknown';
    return name;
  }

  String get platformVersionLabel {
    final value = platformVersion?.trim();
    if (value == null || value.isEmpty) return 'Unknown';
    return value;
  }

  String get availableRamLabel {
    final mb = availableRamMb;
    if (mb == null || mb <= 0) return 'Unknown';
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(1)} GB';
    return '$mb MB';
  }

  String get cpuCoresLabel {
    final cores = cpuCores;
    if (cores == null || cores <= 0) return 'Unknown';
    return '$cores ${cores == 1 ? 'core' : 'cores'}';
  }

  String get androidSdkLabel {
    final sdk = androidSdk;
    if (sdk == null || sdk <= 0) return 'Unavailable';
    return 'Android SDK $sdk';
  }

  String get androidPerformanceClassLabel {
    final value = androidPerformanceClass;
    if (value == null || value <= 0) return 'Unavailable';
    return '$value';
  }

  String get freeStorageLabel {
    final mb = freeStorageMb;
    if (mb == null || mb <= 0) return 'Unknown';
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(1)} GB';
    return '$mb MB';
  }

  ReceiptDeviceStorageClass get storageClass {
    final mb = freeStorageMb;
    if (mb == null || mb <= 0) return ReceiptDeviceStorageClass.unknown;
    if (mb < 500) return ReceiptDeviceStorageClass.critical;
    if (mb < 1500) return ReceiptDeviceStorageClass.low;
    if (mb < 8192) return ReceiptDeviceStorageClass.comfortable;
    return ReceiptDeviceStorageClass.roomy;
  }

  bool get isStorageConstrained {
    return storageClass == ReceiptDeviceStorageClass.critical ||
        storageClass == ReceiptDeviceStorageClass.low;
  }

  String get storageClassLabel {
    return switch (storageClass) {
      ReceiptDeviceStorageClass.unknown => 'Unknown',
      ReceiptDeviceStorageClass.critical => 'Critical - strongest space saving',
      ReceiptDeviceStorageClass.low => 'Low - stronger space saving',
      ReceiptDeviceStorageClass.comfortable => 'Comfortable',
      ReceiptDeviceStorageClass.roomy => 'Roomy',
    };
  }

  String get lowPowerModeLabel => lowPowerMode ? 'On' : 'Off';

  String get accelerationLabel {
    return hasOnDeviceAcceleration ? 'Detected' : 'Not detected';
  }

  String get deviceLabel {
    final maker = deviceManufacturer?.trim();
    final model = deviceModel?.trim();
    if ((maker == null || maker.isEmpty) && (model == null || model.isEmpty)) {
      return 'Unknown device';
    }
    if (maker == null || maker.isEmpty) return model!;
    if (model == null || model.isEmpty) return maker;
    return '$maker $model';
  }

  String get appVersionLabel {
    final version = appVersion?.trim();
    final build = appBuildNumber?.trim();
    if (version == null || version.isEmpty) return 'Unknown';
    if (build == null || build.isEmpty) return version;
    return '$version+$build';
  }

  String get cameraLabel {
    if (!cameraPermissionGranted) return 'Camera permission not granted';
    if (!hasRearCamera) return 'No rear camera detected';
    return '$cameraCount camera${cameraCount == 1 ? '' : 's'} detected';
  }
}

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
    final recommended = switch (storageClass) {
      ReceiptDeviceStorageClass.critical => ReceiptDataSaverLevel.maximum,
      ReceiptDeviceStorageClass.low => ReceiptDataSaverLevel.strong,
      ReceiptDeviceStorageClass.unknown => recommendedDataSaverLevel,
      ReceiptDeviceStorageClass.comfortable => recommendedDataSaverLevel,
      ReceiptDeviceStorageClass.roomy => recommendedDataSaverLevel,
    };
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

  String get recommendedSpaceSavingLabel {
    return '${recommendedDataSaverLevel.label}: ${recommendedDataSaverLevel.shortLabel}';
  }

  ReceiptStitchDeviceLimits get stitchLimits {
    return switch (tier) {
      ReceiptCapabilityTier.light => const ReceiptStitchDeviceLimits(
        maxOutputPixels: 9000000,
        maxOutputHeight: 14000,
      ),
      ReceiptCapabilityTier.medium => const ReceiptStitchDeviceLimits(
        maxOutputPixels: 14000000,
        maxOutputHeight: 18000,
      ),
      ReceiptCapabilityTier.heavyweight => const ReceiptStitchDeviceLimits(
        maxOutputPixels: 18000000,
        maxOutputHeight: 24000,
      ),
    };
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

  ReceiptCameraRuntimeProfile cameraRuntimeProfileFor({
    required bool guidanceRequested,
    required bool startAssistedRequested,
    required bool autoCaptureRequested,
    required bool longReceiptTipsRequested,
  }) {
    final supportsGuidance = guidanceRequested;
    final supportsAssisted = switch (tier) {
      ReceiptCapabilityTier.light => false,
      ReceiptCapabilityTier.medium => startAssistedRequested,
      ReceiptCapabilityTier.heavyweight => startAssistedRequested,
    };
    final supportsAutoCapture = switch (tier) {
      ReceiptCapabilityTier.light => false,
      ReceiptCapabilityTier.medium => false,
      ReceiptCapabilityTier.heavyweight => autoCaptureRequested,
    };
    final effectiveStartAssisted = supportsGuidance && supportsAssisted;
    final effectiveAutoCapture = effectiveStartAssisted && supportsAutoCapture;
    final notes = <String>[
      if (!guidanceRequested) 'Live receipt guidance is off.',
      if (tier == ReceiptCapabilityTier.light && startAssistedRequested)
        'This device uses manual capture first to keep the camera responsive.',
      if (tier != ReceiptCapabilityTier.heavyweight && autoCaptureRequested)
        'Auto capture is held back on this device; tap the shutter when ready.',
      if (recommendedDataSaverLevel == ReceiptDataSaverLevel.maximum)
        'Storage is tight, so saved receipt proof copies use stronger space saving.',
    ];
    return ReceiptCameraRuntimeProfile(
      tier: tier,
      liveGuidanceEnabled: supportsGuidance,
      startAssistedEnabled: effectiveStartAssisted,
      autoCaptureEnabled: effectiveAutoCapture,
      longReceiptTipsEnabled: longReceiptTipsRequested,
      resolutionTier: cameraResolutionTier,
      assistedShotCount: assistedCameraShotCount,
      liveAnalysisGapMs: liveAnalysisGapMs,
      readyHoldMs: readyHoldMs,
      dataSaverLevel: recommendedDataSaverLevel,
      notes: notes,
    );
  }
}

class ReceiptCameraRuntimeProfile {
  const ReceiptCameraRuntimeProfile({
    required this.tier,
    required this.liveGuidanceEnabled,
    required this.startAssistedEnabled,
    required this.autoCaptureEnabled,
    required this.longReceiptTipsEnabled,
    required this.resolutionTier,
    required this.assistedShotCount,
    required this.liveAnalysisGapMs,
    required this.readyHoldMs,
    required this.dataSaverLevel,
    this.notes = const [],
  });

  final ReceiptCapabilityTier tier;
  final bool liveGuidanceEnabled;
  final bool startAssistedEnabled;
  final bool autoCaptureEnabled;
  final bool longReceiptTipsEnabled;
  final ReceiptCameraResolutionTier resolutionTier;
  final int assistedShotCount;
  final int liveAnalysisGapMs;
  final int readyHoldMs;
  final ReceiptDataSaverLevel dataSaverLevel;
  final List<String> notes;

  String get modeLabel {
    if (autoCaptureEnabled) return 'Guided auto capture';
    if (startAssistedEnabled) return 'Guided manual capture';
    if (liveGuidanceEnabled) return 'Manual capture with guidance';
    return 'Manual capture';
  }

  String get summaryLabel {
    return '$modeLabel, ${resolutionTier.label.toLowerCase()} receipt camera, ${dataSaverLevel.shortLabel.toLowerCase()} saved proof.';
  }

  String get notesLabel {
    if (notes.isEmpty) {
      return 'Maintainiac is using the safest receipt camera behavior for this phone.';
    }
    return notes.join(' ');
  }
}

class ReceiptStitchDeviceLimits {
  const ReceiptStitchDeviceLimits({
    required this.maxOutputPixels,
    required this.maxOutputHeight,
  });

  final int maxOutputPixels;
  final int maxOutputHeight;

  String get label {
    return '${(maxOutputPixels / 1000000).toStringAsFixed(1)} MP, max height $maxOutputHeight px';
  }
}

class ReceiptAssistanceDecision {
  const ReceiptAssistanceDecision({
    required this.mode,
    required this.reason,
    this.warnings = const [],
  });

  final ReceiptAssistanceMode mode;
  final String reason;
  final List<String> warnings;

  bool get shouldReadLocally =>
      mode == ReceiptAssistanceMode.localRead ||
      mode == ReceiptAssistanceMode.localReadWithReview;

  bool get needsReview => mode != ReceiptAssistanceMode.localRead;
}

class ReceiptAssistancePolicy {
  const ReceiptAssistancePolicy({
    this.device = const ReceiptDeviceCapability.standard(),
    this.cloudAssistedAvailable = false,
  });

  final ReceiptDeviceCapability device;
  final bool cloudAssistedAvailable;

  ReceiptAssistanceDecision decideForAttachment(
    ReceiptAttachmentRecord attachment,
  ) {
    if (attachment.isImportedText) {
      final text = attachment.importedText.trim();
      if (text.isEmpty) {
        return const ReceiptAssistanceDecision(
          mode: ReceiptAssistanceMode.proofOnly,
          reason: 'No receipt text was available to read.',
        );
      }
      return const ReceiptAssistanceDecision(
        mode: ReceiptAssistanceMode.localRead,
        reason: 'Imported receipt text can be read directly on this device.',
      );
    }
    if (attachment.isPdf) return _decideForPdf(attachment);
    if (attachment.isPhoto) return _decideForPhoto(attachment);
    return const ReceiptAssistanceDecision(
      mode: ReceiptAssistanceMode.proofOnly,
      reason: 'This attachment type can be saved as proof.',
    );
  }

  ReceiptAssistanceDecision decideForAttachments(
    List<ReceiptAttachmentRecord> attachments,
  ) {
    if (attachments.isEmpty) {
      return const ReceiptAssistanceDecision(
        mode: ReceiptAssistanceMode.proofOnly,
        reason: 'No receipt proof was attached.',
      );
    }
    final decisions = attachments.map(decideForAttachment).toList();
    final photoCount = attachments
        .where((attachment) => attachment.isPhoto)
        .length;
    final countWarnings = <String>[
      if (photoCount > device.maxLocalPhotoCount)
        'This receipt has $photoCount photos. ${device.profileName} is tuned for ${device.maxLocalPhotoCount}; review the result before saving.',
    ];
    if (decisions.any((decision) => decision.shouldReadLocally)) {
      final warnings = [
        ...countWarnings,
        for (final decision in decisions) ...decision.warnings,
      ];
      return ReceiptAssistanceDecision(
        mode: warnings.isEmpty
            ? ReceiptAssistanceMode.localRead
            : ReceiptAssistanceMode.localReadWithReview,
        reason: 'At least one receipt attachment can be read on this device.',
        warnings: warnings,
      );
    }
    if (decisions.any(
      (decision) => decision.mode == ReceiptAssistanceMode.cloudCandidate,
    )) {
      return const ReceiptAssistanceDecision(
        mode: ReceiptAssistanceMode.cloudCandidate,
        reason:
            'Receipt proof can be saved now and offered for cloud-assisted reading later.',
      );
    }
    return ReceiptAssistanceDecision(
      mode: ReceiptAssistanceMode.proofOnly,
      reason: decisions.first.reason,
      warnings: [
        ...countWarnings,
        for (final decision in decisions) ...decision.warnings,
      ],
    );
  }

  ReceiptAssistanceDecision _decideForPdf(ReceiptAttachmentRecord attachment) {
    final validation = attachment.validationStatus;
    if (validation == ReceiptPdfValidationStatus.missing ||
        validation == ReceiptPdfValidationStatus.empty ||
        validation == ReceiptPdfValidationStatus.invalidHeader ||
        validation == ReceiptPdfValidationStatus.tooLarge ||
        validation == ReceiptPdfValidationStatus.failed) {
      return ReceiptAssistanceDecision(
        mode: ReceiptAssistanceMode.proofOnly,
        reason: 'This PDF cannot be read safely on this device.',
        warnings: [validation.label],
      );
    }
    if (attachment.riskFlags.contains(ReceiptPdfInspector.encryptionRiskFlag) ||
        attachment.riskFlags.any(
          ReceiptPdfInspector.activeContentRiskFlags.contains,
        )) {
      return ReceiptAssistanceDecision(
        mode: ReceiptAssistanceMode.proofOnly,
        reason:
            'This PDF can be saved as proof, but app-assisted reading will not open protected or active PDF content.',
        warnings: attachment.riskFlags,
      );
    }
    final byteSize = attachment.byteSize ?? 0;
    final pageCount = attachment.pageCount ?? 1;
    final tooLargeForDevice =
        byteSize > device.maxLocalPdfBytes ||
        pageCount > device.maxLocalPdfPages;
    if (tooLargeForDevice) {
      if (cloudAssistedAvailable &&
          byteSize <= ReceiptPdfLimits.cloudAssistedReadBytes &&
          pageCount <= ReceiptPdfLimits.cloudAssistedReadPageLimit) {
        return ReceiptAssistanceDecision(
          mode: ReceiptAssistanceMode.cloudCandidate,
          reason:
              'This PDF is too heavy for ${device.profileName}, but it fits the future cloud-assisted reading limits.',
          warnings: ['Save as proof first; cloud reading must be explicit.'],
        );
      }
      return ReceiptAssistanceDecision(
        mode: ReceiptAssistanceMode.proofOnly,
        reason:
            'This PDF is too heavy for ${device.profileName}. Save it as proof and enter the totals/allocation manually.',
      );
    }
    final warnings = <String>[];
    if (attachment.pageCountStatus == ReceiptPdfPageCountStatus.unknown) {
      warnings.add('PDF page count is unknown.');
    }
    if (pageCount > ReceiptPdfLimits.softPdfPageWarning) {
      warnings.add('Long receipt PDF; review parsed lines before saving.');
    }
    if (attachment.documentSignals.contains(
      ReceiptPdfInspector.imageContentSignal,
    )) {
      warnings.add('Image-based PDF; reading quality depends on page clarity.');
    }
    return ReceiptAssistanceDecision(
      mode: warnings.isEmpty
          ? ReceiptAssistanceMode.localRead
          : ReceiptAssistanceMode.localReadWithReview,
      reason:
          'This PDF fits ${device.profileName} local app-assisted reading limits.',
      warnings: warnings,
    );
  }

  ReceiptAssistanceDecision _decideForPhoto(
    ReceiptAttachmentRecord attachment,
  ) {
    final byteSize = attachment.byteSize ?? 0;
    final qualityWarnings = <String>[
      if (attachment.photoQualityNeedsReview)
        attachment.photoQualityLabel.trim().isEmpty
            ? 'Receipt photo quality needs review.'
            : attachment.photoQualityLabel,
      ...attachment.photoQualityWarnings,
    ];
    if (byteSize > device.maxLocalPhotoBytes) {
      return ReceiptAssistanceDecision(
        mode: ReceiptAssistanceMode.localReadWithReview,
        reason:
            'This receipt photo is large for ${device.profileName}; read locally, then review carefully.',
        warnings: [
          'Large receipt photo may be slower on older phones.',
          ...qualityWarnings,
        ],
      );
    }
    if (qualityWarnings.isNotEmpty) {
      return ReceiptAssistanceDecision(
        mode: ReceiptAssistanceMode.localReadWithReview,
        reason:
            'This receipt photo can be read on ${device.profileName}, but the photo quality needs review.',
        warnings: qualityWarnings,
      );
    }
    return ReceiptAssistanceDecision(
      mode: ReceiptAssistanceMode.localRead,
      reason: 'Receipt photos can be read on ${device.profileName}.',
    );
  }
}
