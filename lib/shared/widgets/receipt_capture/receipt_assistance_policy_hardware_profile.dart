part of 'receipt_assistance_policy.dart';

enum ReceiptCameraWorkloadTier {
  light(
    'Light receipt workload',
    'Older-phone safe',
    maxLiveAnalysisPixels: 900000,
    maxCleanupPixels: 6000000,
  ),
  entry(
    'Entry receipt workload',
    'Responsive capture first',
    maxLiveAnalysisPixels: 1100000,
    maxCleanupPixels: 8000000,
  ),
  balanced(
    'Balanced receipt workload',
    'Most phones',
    maxLiveAnalysisPixels: 1400000,
    maxCleanupPixels: 10000000,
  ),
  enhanced(
    'Enhanced receipt workload',
    'More live receipt assistance',
    maxLiveAnalysisPixels: 1800000,
    maxCleanupPixels: 12000000,
  ),
  performance(
    'Performance receipt workload',
    'Fast modern hardware',
    maxLiveAnalysisPixels: 2200000,
    maxCleanupPixels: 14000000,
  ),
  flagship(
    'Flagship receipt workload',
    'High-capacity phones',
    maxLiveAnalysisPixels: 2600000,
    maxCleanupPixels: 16000000,
  );

  const ReceiptCameraWorkloadTier(
    this.label,
    this.shortLabel, {
    required this.maxLiveAnalysisPixels,
    required this.maxCleanupPixels,
  });

  final String label;
  final String shortLabel;
  final int maxLiveAnalysisPixels;
  final int maxCleanupPixels;
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
    this.isLowRamDevice = false,
    this.freeStorageMb,
    this.lowPowerMode = false,
    this.hasOnDeviceAcceleration = false,
    this.cameraPermissionGranted = false,
    this.cameraCount = 0,
    this.hasRearCamera = false,
    this.hasFrontCamera = false,
    this.supportsTapFocus = false,
    this.supportsContinuousFocus = false,
    this.supportsExposureCompensation = false,
    this.supportsZoom = false,
    this.supportsYuvLiveFrames = false,
    this.supportsNativeEdgeSignals = false,
    this.maxStillWidth = 0,
    this.maxStillHeight = 0,
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
  final bool isLowRamDevice;
  final int? freeStorageMb;
  final bool lowPowerMode;
  final bool hasOnDeviceAcceleration;
  final bool cameraPermissionGranted;
  final int cameraCount;
  final bool hasRearCamera;
  final bool hasFrontCamera;
  final bool supportsTapFocus;
  final bool supportsContinuousFocus;
  final bool supportsExposureCompensation;
  final bool supportsZoom;
  final bool supportsYuvLiveFrames;
  final bool supportsNativeEdgeSignals;
  final int maxStillWidth;
  final int maxStillHeight;
  final String? rearCameraName;

  int get maxStillMegapixels {
    if (maxStillWidth <= 0 || maxStillHeight <= 0) return 0;
    return ((maxStillWidth * maxStillHeight) / 1000000).round();
  }

  String privacySafeCapabilityLabel({
    ReceiptPerformanceMode mode = ReceiptPerformanceMode.automatic,
  }) {
    final tier = tierFor(mode);
    final camera = hasRearCamera
        ? 'rear camera available'
        : 'rear camera unavailable';
    final controls = [
      if (supportsContinuousFocus) 'continuous focus',
      if (supportsZoom) 'pinch zoom',
      if (supportsExposureCompensation) 'brightness control',
      if (supportsNativeEdgeSignals) 'edge guidance',
    ];
    final controlLabel = controls.isEmpty
        ? 'basic controls'
        : controls.join(', ');
    return '${tier.name} capability, ${storageClass.name} storage, $camera, $controlLabel.';
  }

  Map<String, Object?> privacySafeCapabilityDiagnostics({
    ReceiptPerformanceMode mode = ReceiptPerformanceMode.automatic,
  }) {
    return {
      'capabilityTier': tierFor(mode).name,
      'storageClass': storageClass.name,
      'cameraPermissionGranted': cameraPermissionGranted,
      'cameraCount': cameraCount,
      'hasRearCamera': hasRearCamera,
      'hasFrontCamera': hasFrontCamera,
      'supportsContinuousFocus': supportsContinuousFocus,
      'legacyTapFocusSupported': supportsTapFocus,
      'supportsExposureCompensation': supportsExposureCompensation,
      'supportsZoom': supportsZoom,
      'supportsYuvLiveFrames': supportsYuvLiveFrames,
      'supportsNativeEdgeSignals': supportsNativeEdgeSignals,
      'maxStillMegapixels': maxStillMegapixels,
      'isLowRamDevice': isLowRamDevice,
    };
  }

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

  ReceiptCameraWorkloadTier cameraWorkloadTierFor(ReceiptPerformanceMode mode) {
    if (mode == ReceiptPerformanceMode.batterySaver ||
        lowPowerMode ||
        _isConstrained) {
      return ReceiptCameraWorkloadTier.light;
    }
    if (mode == ReceiptPerformanceMode.balanced) {
      return ReceiptCameraWorkloadTier.balanced;
    }
    final score = _score;
    final measured = switch (score) {
      <= 1 => ReceiptCameraWorkloadTier.light,
      <= 3 => ReceiptCameraWorkloadTier.entry,
      <= 5 => ReceiptCameraWorkloadTier.balanced,
      <= 7 => ReceiptCameraWorkloadTier.enhanced,
      <= 9 => ReceiptCameraWorkloadTier.performance,
      _ => ReceiptCameraWorkloadTier.flagship,
    };
    final generationCap = _androidGenerationWorkloadCap;
    if (generationCap == null || measured.index <= generationCap.index) {
      return measured;
    }
    return generationCap;
  }

  ReceiptCapabilityTier _automaticTier({required bool allowHeavy}) {
    if (lowPowerMode || _isConstrained) return ReceiptCapabilityTier.light;
    final score = _score;
    final androidSdkValue = androidSdk;
    final heavyAllowedByGeneration =
        androidSdkValue == null || androidSdkValue >= 33;
    if (allowHeavy && heavyAllowedByGeneration && score >= 8) {
      return ReceiptCapabilityTier.heavyweight;
    }
    if (score >= 4) return ReceiptCapabilityTier.medium;
    return ReceiptCapabilityTier.light;
  }

  bool get _isConstrained {
    final ram = availableRamMb;
    final storage = freeStorageMb;
    return isLowRamDevice ||
        (cameraCount > 0 && !hasRearCamera) ||
        (ram != null && ram <= 4096) ||
        (storage != null && storage < 1200) ||
        (cpuCores != null && cpuCores! <= 4);
  }

  ReceiptCameraWorkloadTier? get _androidGenerationWorkloadCap {
    final sdk = androidSdk;
    if (sdk == null) return null;
    if (sdk <= 28) return ReceiptCameraWorkloadTier.light;
    if (sdk <= 30) return ReceiptCameraWorkloadTier.entry;
    if (sdk <= 32) return ReceiptCameraWorkloadTier.enhanced;
    return null;
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
    if (supportsContinuousFocus &&
        supportsZoom &&
        supportsExposureCompensation) {
      score += 1;
    }
    if (supportsYuvLiveFrames && supportsNativeEdgeSignals) score += 1;
    if (maxStillMegapixels >= 12) score += 1;
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
}
