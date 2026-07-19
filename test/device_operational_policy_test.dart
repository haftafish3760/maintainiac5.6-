import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/device_capabilities/device_capabilities.dart';

void main() {
  const classifier = DeviceCapabilityClassifier();
  const hardware = DeviceHardwareSnapshot(
    platform: 'android',
    androidMediaPerformanceClass: 35,
    physicalRamMb: 12288,
    cpuCores: 8,
    applicationHeapMb: 512,
  );

  test('healthy unmetered flagship uses high quality module budgets', () {
    final profile = classifier.classify(
      hardware,
      runtime: DeviceRuntimeSnapshot(
        observedAt: DateTime.utc(2026, 7, 17),
        freeStorageMb: 32000,
        totalStorageMb: 256000,
        availableRamMb: 6000,
      ),
      camera: const DeviceCameraCapabilities(
        available: true,
        maxStillWidth: 8192,
        maxStillHeight: 6144,
      ),
      extended: const DeviceExtendedCapabilities(
        battery: DeviceBatteryCapabilities(levelPercent: 80),
        media: DeviceMediaCapabilities(hardwareEncodeTypes: {'h264', 'hevc'}),
        connectivity: DeviceConnectivityCapabilities(
          transports: {'wifi'},
          isConnected: true,
        ),
      ),
    );

    expect(profile.operationalPolicy.deferNonEssentialHeavyWork, isFalse);
    expect(profile.operationalPolicy.allowLargeNetworkTransfer, isTrue);
    expect(profile.operationalPolicy.maxOcrBatchImages, 12);
    expect(profile.operationalPolicy.preferredVideoCodec, 'hevc');
  });

  test('power pressure produces conservative cross-module guidance', () {
    final profile = classifier.classify(
      hardware,
      runtime: DeviceRuntimeSnapshot(
        observedAt: DateTime.utc(2026, 7, 17),
        freeStorageMb: 32000,
        totalStorageMb: 256000,
        availableRamMb: 6000,
        powerSaving: true,
      ),
      extended: const DeviceExtendedCapabilities(
        battery: DeviceBatteryCapabilities(levelPercent: 15),
        connectivity: DeviceConnectivityCapabilities(
          transports: {'cellular'},
          isConnected: true,
          isMetered: true,
        ),
      ),
    );

    final policy = profile.operationalPolicy;
    expect(policy.deferNonEssentialHeavyWork, isTrue);
    expect(policy.allowLargeNetworkTransfer, isFalse);
    expect(policy.liveAnalysisFps, lessThanOrEqualTo(5));
    expect(policy.maxOcrBatchImages, lessThanOrEqualTo(3));
    expect(policy.tripLocationIntervalSeconds, greaterThanOrEqualTo(10));
  });

  test('low free-storage percentage defers nonessential processing', () {
    final profile = classifier.classify(
      hardware,
      runtime: DeviceRuntimeSnapshot(
        observedAt: DateTime.utc(2026, 7, 17),
        freeStorageMb: 4000,
        totalStorageMb: 128000,
        availableRamMb: 6000,
      ),
      extended: const DeviceExtendedCapabilities(
        battery: DeviceBatteryCapabilities(levelPercent: 90),
        connectivity: DeviceConnectivityCapabilities(
          transports: {'wifi'},
          isConnected: true,
        ),
      ),
    );

    expect(profile.runtime.freeStorageFraction, closeTo(0.03125, 0.0001));
    expect(profile.operationalPolicy.deferNonEssentialHeavyWork, isTrue);
    expect(profile.operationalPolicy.allowLargeNetworkTransfer, isFalse);
  });
}
