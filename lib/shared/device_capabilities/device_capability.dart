import 'device_feature_capabilities.dart';
import 'device_storage_status.dart';

enum DevicePerformanceTier {
  constrained,
  entry,
  balanced,
  enhanced,
  performance,
  flagship;

  bool get isAtLeastBalanced => index >= DevicePerformanceTier.balanced.index;
  bool get isAtLeastPerformance =>
      index >= DevicePerformanceTier.performance.index;
}

enum DeviceCapabilityConfidence { low, medium, high }

enum DeviceThermalState { unknown, nominal, fair, serious, critical }

/// Hardware facts that remain stable for the life of the running app.
/// Identity fields are local-only and never included in safe diagnostics.
class DeviceHardwareSnapshot {
  const DeviceHardwareSnapshot({
    required this.platform,
    this.platformVersion,
    this.manufacturer,
    this.model,
    this.hardwareIdentifier,
    this.androidSdk,
    this.androidMediaPerformanceClass,
    this.physicalRamMb,
    this.cpuCores,
    this.cpuArchitecture,
    this.applicationHeapMb,
    this.isLowRamDevice = false,
    this.isPhysicalDevice = true,
  });

  final String platform;
  final String? platformVersion;
  final String? manufacturer;
  final String? model;
  final String? hardwareIdentifier;
  final int? androidSdk;
  final int? androidMediaPerformanceClass;
  final int? physicalRamMb;
  final int? cpuCores;
  final String? cpuArchitecture;
  final int? applicationHeapMb;
  final bool isLowRamDevice;
  final bool isPhysicalDevice;
}

/// Conditions that can change while the app is running.
class DeviceRuntimeSnapshot {
  const DeviceRuntimeSnapshot({
    required this.observedAt,
    this.availableRamMb,
    this.freeStorageMb,
    this.totalStorageMb,
    this.powerSaving = false,
    this.thermalState = DeviceThermalState.unknown,
  });

  final DateTime observedAt;
  final int? availableRamMb;
  final int? freeStorageMb;
  final int? totalStorageMb;

  double? get freeStorageFraction {
    if (freeStorageMb == null ||
        totalStorageMb == null ||
        totalStorageMb! <= 0) {
      return null;
    }
    return freeStorageMb! / totalStorageMb!;
  }

  DeviceStorageAssessment get storageAssessment =>
      DeviceStorageAssessment.fromFreeMb(freeStorageMb);

  final bool powerSaving;
  final DeviceThermalState thermalState;

  bool get isThermallyConstrained =>
      thermalState == DeviceThermalState.serious ||
      thermalState == DeviceThermalState.critical;
}

/// Camera facts are a separate capability section because general device
/// horsepower does not guarantee a particular lens or camera control.
class DeviceCameraCapabilities {
  const DeviceCameraCapabilities({
    this.available = false,
    this.cameraCount = 0,
    this.hasRearCamera = false,
    this.hasFrontCamera = false,
    this.supportsTapFocus = false,
    this.supportsContinuousFocus = false,
    this.supportsExposureCompensation = false,
    this.supportsZoom = false,
    this.supportsMacroSelection = false,
    this.supportsTorch = false,
    this.supportsRaw = false,
    this.maxStillWidth = 0,
    this.maxStillHeight = 0,
  });

  final bool available;
  final int cameraCount;
  final bool hasRearCamera;
  final bool hasFrontCamera;
  final bool supportsTapFocus;
  final bool supportsContinuousFocus;
  final bool supportsExposureCompensation;
  final bool supportsZoom;
  final bool supportsMacroSelection;
  final bool supportsTorch;
  final bool supportsRaw;
  final int maxStillWidth;
  final int maxStillHeight;

  int get maxStillMegapixels {
    if (maxStillWidth <= 0 || maxStillHeight <= 0) return 0;
    return ((maxStillWidth * maxStillHeight) / 1000000).round();
  }
}

class DeviceWorkloadBudget {
  const DeviceWorkloadBudget({
    required this.maxConcurrentHeavyTasks,
    required this.recommendedWorkerCount,
    required this.maxInMemoryAssetMb,
    required this.maxLiveImageAnalysisPixels,
    required this.preferredLiveAnalysisFps,
    required this.maxOcrBatchImages,
    required this.maxPdfRasterDpi,
    required this.tripLocationIntervalSeconds,
    required this.maxVideoHeight,
  });

  final int maxConcurrentHeavyTasks;
  final int recommendedWorkerCount;
  final int maxInMemoryAssetMb;
  final int maxLiveImageAnalysisPixels;
  final int preferredLiveAnalysisFps;
  final int maxOcrBatchImages;
  final int maxPdfRasterDpi;
  final int tripLocationIntervalSeconds;
  final int maxVideoHeight;

  factory DeviceWorkloadBudget.forTier(DevicePerformanceTier tier) {
    return switch (tier) {
      DevicePerformanceTier.constrained => const DeviceWorkloadBudget(
        maxConcurrentHeavyTasks: 1,
        recommendedWorkerCount: 1,
        maxInMemoryAssetMb: 48,
        maxLiveImageAnalysisPixels: 900000,
        preferredLiveAnalysisFps: 4,
        maxOcrBatchImages: 2,
        maxPdfRasterDpi: 120,
        tripLocationIntervalSeconds: 12,
        maxVideoHeight: 720,
      ),
      DevicePerformanceTier.entry => const DeviceWorkloadBudget(
        maxConcurrentHeavyTasks: 1,
        recommendedWorkerCount: 1,
        maxInMemoryAssetMb: 64,
        maxLiveImageAnalysisPixels: 1100000,
        preferredLiveAnalysisFps: 5,
        maxOcrBatchImages: 3,
        maxPdfRasterDpi: 140,
        tripLocationIntervalSeconds: 10,
        maxVideoHeight: 720,
      ),
      DevicePerformanceTier.balanced => const DeviceWorkloadBudget(
        maxConcurrentHeavyTasks: 1,
        recommendedWorkerCount: 2,
        maxInMemoryAssetMb: 96,
        maxLiveImageAnalysisPixels: 1400000,
        preferredLiveAnalysisFps: 7,
        maxOcrBatchImages: 4,
        maxPdfRasterDpi: 160,
        tripLocationIntervalSeconds: 8,
        maxVideoHeight: 1080,
      ),
      DevicePerformanceTier.enhanced => const DeviceWorkloadBudget(
        maxConcurrentHeavyTasks: 2,
        recommendedWorkerCount: 2,
        maxInMemoryAssetMb: 128,
        maxLiveImageAnalysisPixels: 1800000,
        preferredLiveAnalysisFps: 9,
        maxOcrBatchImages: 6,
        maxPdfRasterDpi: 180,
        tripLocationIntervalSeconds: 7,
        maxVideoHeight: 1080,
      ),
      DevicePerformanceTier.performance => const DeviceWorkloadBudget(
        maxConcurrentHeavyTasks: 2,
        recommendedWorkerCount: 3,
        maxInMemoryAssetMb: 192,
        maxLiveImageAnalysisPixels: 2200000,
        preferredLiveAnalysisFps: 12,
        maxOcrBatchImages: 8,
        maxPdfRasterDpi: 220,
        tripLocationIntervalSeconds: 6,
        maxVideoHeight: 2160,
      ),
      DevicePerformanceTier.flagship => const DeviceWorkloadBudget(
        maxConcurrentHeavyTasks: 3,
        recommendedWorkerCount: 4,
        maxInMemoryAssetMb: 256,
        maxLiveImageAnalysisPixels: 2600000,
        preferredLiveAnalysisFps: 15,
        maxOcrBatchImages: 12,
        maxPdfRasterDpi: 240,
        tripLocationIntervalSeconds: 5,
        maxVideoHeight: 2160,
      ),
    };
  }
}

class DeviceCapabilityProfile {
  const DeviceCapabilityProfile({
    required this.hardware,
    required this.runtime,
    required this.camera,
    this.extended = DeviceExtendedCapabilities.empty,
    required this.baselineTier,
    required this.tier,
    required this.confidence,
    required this.score,
    required this.limitingFactors,
  });

  final DeviceHardwareSnapshot hardware;
  final DeviceRuntimeSnapshot runtime;
  final DeviceCameraCapabilities camera;
  final DeviceExtendedCapabilities extended;
  final DevicePerformanceTier baselineTier;
  final DevicePerformanceTier tier;
  final DeviceCapabilityConfidence confidence;
  final int score;
  final List<String> limitingFactors;

  DeviceWorkloadBudget get budget => DeviceWorkloadBudget.forTier(tier);

  /// Safe for diagnostics and future crash metadata. This intentionally omits
  /// model, hardware identifiers, exact RAM, and exact storage values.
  Map<String, Object?> toPrivacySafeDiagnostics() => {
    'platform': hardware.platform,
    'baselineTier': baselineTier.name,
    'effectiveTier': tier.name,
    'confidence': confidence.name,
    'lowRam': hardware.isLowRamDevice,
    'storagePressure': _storagePressure(runtime.freeStorageMb),
    'storageStatus': runtime.storageAssessment.status.name,
    'powerSaving': runtime.powerSaving,
    'thermalState': runtime.thermalState.name,
    'cameraClass': camera.maxStillMegapixels <= 0
        ? 'unknown'
        : camera.maxStillMegapixels < 8
        ? 'basic'
        : camera.maxStillMegapixels < 12
        ? 'standard'
        : 'highResolution',
    'cameraLensCount': extended.cameraLenses.length,
    'sensorClassCount': extended.sensors.types.length,
    'batteryLevel': _batteryLevelBucket(extended.battery.levelPercent),
    'batteryHealth': extended.battery.health.name,
    'network': extended.connectivity.transports.join('+'),
    'networkMetered': extended.connectivity.isMetered,
    'displayRefreshClass': _refreshClass(extended.display.maxRefreshRateHz),
    'graphicsApi': extended.graphics.apiName,
    'graphicsFeatureLevel': extended.graphics.featureLevel,
    'limitingFactors': List<String>.unmodifiable(limitingFactors),
  };

  static String _storagePressure(int? freeStorageMb) {
    if (freeStorageMb == null) return 'unknown';
    if (freeStorageMb < 250) return 'critical';
    if (freeStorageMb < 1024) return 'low';
    return 'normal';
  }

  static String _batteryLevelBucket(int? level) {
    if (level == null) return 'unknown';
    if (level <= 10) return 'critical';
    if (level <= 20) return 'low';
    if (level <= 50) return 'medium';
    return 'healthy';
  }

  static String _refreshClass(double hz) {
    if (hz <= 0) return 'unknown';
    if (hz < 90) return 'standard';
    if (hz < 120) return 'high';
    return 'veryHigh';
  }
}

/// Pure and deterministic. Model names and release years never contribute to
/// the score; unknown hardware earns no performance points.
class DeviceCapabilityClassifier {
  const DeviceCapabilityClassifier();

  DeviceCapabilityProfile classify(
    DeviceHardwareSnapshot hardware, {
    DeviceRuntimeSnapshot? runtime,
    DeviceCameraCapabilities camera = const DeviceCameraCapabilities(),
    DeviceExtendedCapabilities extended = DeviceExtendedCapabilities.empty,
  }) {
    final live = runtime ?? DeviceRuntimeSnapshot(observedAt: DateTime.now());
    var score = 0;
    var measuredSignals = 0;
    final limits = <String>[];

    final ram = hardware.physicalRamMb;
    if (ram != null && ram > 0) {
      measuredSignals++;
      score += switch (ram) {
        <= 3072 => -2,
        <= 4096 => 0,
        <= 6144 => 2,
        <= 8192 => 4,
        <= 12288 => 5,
        _ => 6,
      };
      if (ram <= 4096) limits.add('limited_memory');
    }

    final cores = hardware.cpuCores;
    if (cores != null && cores > 0) {
      measuredSignals++;
      score += switch (cores) {
        <= 4 => -1,
        <= 6 => 1,
        <= 8 => 2,
        _ => 3,
      };
      if (cores <= 4) limits.add('limited_cpu_parallelism');
    }

    final performanceClass = hardware.androidMediaPerformanceClass;
    if (performanceClass != null && performanceClass > 0) {
      measuredSignals++;
      score += switch (performanceClass) {
        >= 35 => 5,
        >= 34 => 4,
        >= 33 => 3,
        >= 31 => 2,
        _ => 0,
      };
    }

    final heap = hardware.applicationHeapMb;
    if (heap != null && heap > 0) {
      measuredSignals++;
      score += switch (heap) {
        < 192 => -1,
        >= 512 => 2,
        >= 256 => 1,
        _ => 0,
      };
      if (heap < 192) limits.add('limited_application_heap');
    }

    final media = extended.media;
    final graphics = extended.graphics;
    if (graphics.supportsCompute && media.hardwareDecodeTypes.isNotEmpty) {
      measuredSignals++;
      score += 1;
      if (media.canHardwareDecode('av1') && media.canHardwareEncode('hevc')) {
        score += 1;
      }
    }

    var tier = switch (score) {
      <= 0 => DevicePerformanceTier.constrained,
      <= 2 => DevicePerformanceTier.entry,
      <= 4 => DevicePerformanceTier.balanced,
      <= 6 => DevicePerformanceTier.enhanced,
      <= 9 => DevicePerformanceTier.performance,
      _ => DevicePerformanceTier.flagship,
    };

    if (hardware.isLowRamDevice) {
      tier = DevicePerformanceTier.constrained;
      limits.add('system_low_ram_device');
    }
    final baselineTier = tier;
    tier = _capForStorage(tier, live.freeStorageMb, limits);
    final availableRam = live.availableRamMb;
    if (availableRam != null && availableRam < 512) {
      tier = DevicePerformanceTier.constrained;
      limits.add('critical_runtime_memory');
    } else if (availableRam != null && availableRam < 1024) {
      tier = _cap(tier, DevicePerformanceTier.entry);
      limits.add('low_runtime_memory');
    }
    if (live.powerSaving) {
      tier = _cap(tier, DevicePerformanceTier.entry);
      limits.add('power_saving');
    }
    final battery = extended.battery;
    if (!battery.isCharging && battery.isCritical) {
      tier = _cap(tier, DevicePerformanceTier.entry);
      limits.add('critical_battery');
    } else if (!battery.isCharging && battery.isLow) {
      tier = _cap(tier, DevicePerformanceTier.balanced);
      limits.add('low_battery');
    }
    if (battery.health == DeviceBatteryHealth.overheating) {
      tier = _cap(tier, DevicePerformanceTier.balanced);
      limits.add('battery_overheating');
    }
    if (live.isThermallyConstrained) {
      tier = _cap(tier, DevicePerformanceTier.balanced);
      limits.add('thermal_pressure');
    }
    if (!hardware.isPhysicalDevice) {
      limits.add('simulator_or_emulator');
    }

    final confidence = switch (measuredSignals) {
      >= 3 => DeviceCapabilityConfidence.high,
      >= 2 => DeviceCapabilityConfidence.medium,
      _ => DeviceCapabilityConfidence.low,
    };
    if (confidence == DeviceCapabilityConfidence.low &&
        tier.index > DevicePerformanceTier.balanced.index) {
      tier = DevicePerformanceTier.balanced;
      limits.add('insufficient_hardware_evidence');
    }

    return DeviceCapabilityProfile(
      hardware: hardware,
      runtime: live,
      camera: camera,
      extended: extended,
      baselineTier: baselineTier,
      tier: tier,
      confidence: confidence,
      score: score,
      limitingFactors: List<String>.unmodifiable(limits.toSet()),
    );
  }

  static DevicePerformanceTier _capForStorage(
    DevicePerformanceTier tier,
    int? freeStorageMb,
    List<String> limits,
  ) {
    if (freeStorageMb == null) return tier;
    if (freeStorageMb < 250) {
      limits.add('critical_storage_red');
      return DevicePerformanceTier.constrained;
    }
    if (freeStorageMb < 500) {
      limits.add('very_low_storage_orange');
      return _cap(tier, DevicePerformanceTier.entry);
    }
    if (freeStorageMb < 1024) {
      limits.add('low_storage_yellow');
      return _cap(tier, DevicePerformanceTier.balanced);
    }
    return tier;
  }

  static DevicePerformanceTier _cap(
    DevicePerformanceTier value,
    DevicePerformanceTier maximum,
  ) => value.index <= maximum.index ? value : maximum;
}
