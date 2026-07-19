import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/device_capabilities/device_capability.dart';
import 'package:maintaniac/shared/device_capabilities/device_feature_capabilities.dart';

void main() {
  const classifier = DeviceCapabilityClassifier();

  DeviceRuntimeSnapshot runtime({
    int freeStorageMb = 8000,
    int availableRamMb = 2000,
    bool powerSaving = false,
    DeviceThermalState thermalState = DeviceThermalState.nominal,
  }) => DeviceRuntimeSnapshot(
    observedAt: DateTime.utc(2026, 7, 15),
    freeStorageMb: freeStorageMb,
    availableRamMb: availableRamMb,
    powerSaving: powerSaving,
    thermalState: thermalState,
  );

  test('S9-class specifications receive a conservative balanced budget', () {
    final profile = classifier.classify(
      const DeviceHardwareSnapshot(
        platform: 'android',
        model: 'SM-G965U',
        androidSdk: 29,
        physicalRamMb: 6144,
        cpuCores: 8,
        applicationHeapMb: 192,
      ),
      runtime: runtime(),
    );

    expect(profile.tier, DevicePerformanceTier.balanced);
    expect(profile.confidence, DeviceCapabilityConfidence.high);
    expect(profile.budget.maxConcurrentHeavyTasks, 1);
    expect(profile.budget.preferredLiveAnalysisFps, 7);
    expect(profile.budget.maxPdfRasterDpi, 160);
  });

  test('media performance class can earn flagship budget', () {
    final profile = classifier.classify(
      const DeviceHardwareSnapshot(
        platform: 'android',
        model: 'modern device',
        androidMediaPerformanceClass: 35,
        physicalRamMb: 12288,
        cpuCores: 8,
        applicationHeapMb: 512,
      ),
      runtime: runtime(freeStorageMb: 32000, availableRamMb: 5000),
    );

    expect(profile.tier, DevicePerformanceTier.flagship);
    expect(profile.budget.recommendedWorkerCount, 4);
    expect(profile.budget.maxConcurrentHeavyTasks, 3);
    expect(profile.budget.maxOcrBatchImages, 12);
    expect(profile.budget.maxVideoHeight, 2160);
  });

  test(
    'verified graphics and hardware codecs can fill a missing class signal',
    () {
      final profile = classifier.classify(
        const DeviceHardwareSnapshot(
          platform: 'android',
          physicalRamMb: 11113,
          cpuCores: 8,
          applicationHeapMb: 256,
        ),
        runtime: runtime(freeStorageMb: 32000, availableRamMb: 3500),
        extended: const DeviceExtendedCapabilities(
          media: DeviceMediaCapabilities(
            hardwareDecodeTypes: {'av1', 'h264', 'hevc'},
            hardwareEncodeTypes: {'h264', 'hevc'},
          ),
          graphics: DeviceGraphicsCapabilities(
            apiName: 'vulkan+opengl_es',
            supportsCompute: true,
          ),
        ),
      );

      expect(profile.baselineTier, DevicePerformanceTier.flagship);
      expect(profile.tier, DevicePerformanceTier.flagship);
    },
  );

  test('model name and release generation never change classification', () {
    const common = DeviceHardwareSnapshot(
      platform: 'android',
      model: '2021 flagship',
      physicalRamMb: 8192,
      cpuCores: 8,
      applicationHeapMb: 256,
    );
    const newerName = DeviceHardwareSnapshot(
      platform: 'android',
      model: '2026 budget phone',
      physicalRamMb: 8192,
      cpuCores: 8,
      applicationHeapMb: 256,
    );

    expect(
      classifier.classify(common, runtime: runtime()).tier,
      classifier.classify(newerName, runtime: runtime()).tier,
    );
  });

  test('runtime pressure can lower but never raise baseline tier', () {
    const hardware = DeviceHardwareSnapshot(
      platform: 'android',
      androidMediaPerformanceClass: 35,
      physicalRamMb: 12288,
      cpuCores: 8,
      applicationHeapMb: 512,
    );

    final profile = classifier.classify(
      hardware,
      runtime: runtime(
        freeStorageMb: 900,
        availableRamMb: 700,
        powerSaving: true,
        thermalState: DeviceThermalState.serious,
      ),
    );

    expect(profile.baselineTier, DevicePerformanceTier.flagship);
    expect(profile.tier, DevicePerformanceTier.entry);
    expect(
      profile.limitingFactors,
      containsAll([
        'low_storage_yellow',
        'low_runtime_memory',
        'power_saving',
        'thermal_pressure',
      ]),
    );
  });

  test('low RAM flag overrides otherwise strong reported specifications', () {
    final profile = classifier.classify(
      const DeviceHardwareSnapshot(
        platform: 'android',
        androidMediaPerformanceClass: 35,
        physicalRamMb: 12288,
        cpuCores: 8,
        applicationHeapMb: 512,
        isLowRamDevice: true,
      ),
      runtime: runtime(),
    );

    expect(profile.tier, DevicePerformanceTier.constrained);
    expect(profile.limitingFactors, contains('system_low_ram_device'));
  });

  test(
    'low unplugged battery lowers effective work without changing baseline',
    () {
      final profile = classifier.classify(
        const DeviceHardwareSnapshot(
          platform: 'android',
          androidMediaPerformanceClass: 35,
          physicalRamMb: 12288,
          cpuCores: 8,
          applicationHeapMb: 512,
        ),
        runtime: runtime(freeStorageMb: 32000, availableRamMb: 5000),
        extended: const DeviceExtendedCapabilities(
          battery: DeviceBatteryCapabilities(levelPercent: 9),
        ),
      );

      expect(profile.baselineTier, DevicePerformanceTier.flagship);
      expect(profile.tier, DevicePerformanceTier.entry);
      expect(profile.limitingFactors, contains('critical_battery'));
    },
  );

  test('camera facts remain separate from general performance tier', () {
    final profile = classifier.classify(
      const DeviceHardwareSnapshot(
        platform: 'ios',
        physicalRamMb: 8192,
        cpuCores: 6,
        applicationHeapMb: 256,
      ),
      runtime: runtime(),
      camera: const DeviceCameraCapabilities(
        available: true,
        cameraCount: 3,
        hasRearCamera: true,
        supportsMacroSelection: true,
        maxStillWidth: 8064,
        maxStillHeight: 6048,
      ),
    );

    expect(profile.camera.cameraCount, 3);
    expect(profile.camera.supportsMacroSelection, isTrue);
    expect(profile.camera.maxStillMegapixels, 49);
  });

  test('privacy-safe diagnostics omit raw device identity and exact specs', () {
    final diagnostics = classifier
        .classify(
          const DeviceHardwareSnapshot(
            platform: 'android',
            manufacturer: 'Samsung',
            model: 'SM-S928U',
            hardwareIdentifier: 'e3q',
            physicalRamMb: 12288,
            cpuCores: 8,
          ),
          runtime: runtime(freeStorageMb: 12345),
        )
        .toPrivacySafeDiagnostics();

    expect(diagnostics, isNot(contains('model')));
    expect(diagnostics, isNot(contains('hardwareIdentifier')));
    expect(diagnostics, isNot(contains('physicalRamMb')));
    expect(diagnostics, isNot(contains('freeStorageMb')));
    expect(diagnostics['storageStatus'], 'green');
  });

  test('six tiers span prepaid-class through flagship capability', () {
    const hardwareByTier = <DevicePerformanceTier, DeviceHardwareSnapshot>{
      DevicePerformanceTier.constrained: DeviceHardwareSnapshot(
        platform: 'android', physicalRamMb: 2048, cpuCores: 4,
        applicationHeapMb: 128,
      ),
      DevicePerformanceTier.entry: DeviceHardwareSnapshot(
        platform: 'android', physicalRamMb: 4096, cpuCores: 6,
        applicationHeapMb: 192,
      ),
      DevicePerformanceTier.balanced: DeviceHardwareSnapshot(
        platform: 'android', physicalRamMb: 6144, cpuCores: 8,
        applicationHeapMb: 192,
      ),
      DevicePerformanceTier.enhanced: DeviceHardwareSnapshot(
        platform: 'android', physicalRamMb: 8192, cpuCores: 6,
        applicationHeapMb: 256,
      ),
      DevicePerformanceTier.performance: DeviceHardwareSnapshot(
        platform: 'android', androidMediaPerformanceClass: 33,
        physicalRamMb: 8192, cpuCores: 8, applicationHeapMb: 192,
      ),
      DevicePerformanceTier.flagship: DeviceHardwareSnapshot(
        platform: 'android', androidMediaPerformanceClass: 35,
        physicalRamMb: 12288, cpuCores: 8, applicationHeapMb: 512,
      ),
    };

    for (final entry in hardwareByTier.entries) {
      final profile = classifier.classify(
        entry.value,
        runtime: runtime(freeStorageMb: 32000, availableRamMb: 5000),
      );
      expect(profile.baselineTier, entry.key, reason: entry.key.name);
    }
  });
}
