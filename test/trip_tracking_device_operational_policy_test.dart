import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/device_capabilities/device_capabilities.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_device_operational_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  test('shared device capabilities shape GPS sampling without maps', () {
    final policy = TripTrackingDeviceOperationalPolicy.fromDeviceProfile(
      DeviceCapabilityProfile(
        hardware: const DeviceHardwareSnapshot(platform: 'android'),
        runtime: DeviceRuntimeSnapshot(
          observedAt: DateTime.utc(2026, 7, 18),
          freeStorageMb: 32000,
          totalStorageMb: 64000,
        ),
        camera: const DeviceCameraCapabilities(),
        extended: const DeviceExtendedCapabilities(
          sensors: DeviceSensorCapabilities(
            types: {'accelerometer', 'gyroscope'},
          ),
          battery: DeviceBatteryCapabilities(levelPercent: 75),
          connectivity: DeviceConnectivityCapabilities(isConnected: true),
        ),
        baselineTier: DevicePerformanceTier.performance,
        tier: DevicePerformanceTier.performance,
        confidence: DeviceCapabilityConfidence.high,
        score: 80,
        limitingFactors: const [],
      ),
    );
    final summary = policy.toSafeSummary();

    expect(policy.activityRecognitionRecommended, isTrue);
    expect(policy.backgroundTrackingAllowed, isTrue);
    expect(policy.deferMapRouteHistory, isFalse);
    expect(summary['usesSharedDeviceCapabilityProfile'], isTrue);
    expect(summary['gpsTrackingCanRunWithoutMaps'], isTrue);
    expect(summary['mapsRequiredForTracking'], isFalse);
    expect(summary['mapRouteHistoryIsOptional'], isTrue);
    expect(summary['activityRecognitionRequiresOptIn'], isTrue);
    expect(summary['backgroundTrackingRequiresPlatformPermission'], isTrue);
    expect(summary['deviceModelIncluded'], isFalse);
    expect(summary['rawSensorPayloadIncluded'], isFalse);
  });

  test('constrained devices defer map history and keep battery guard', () {
    final policy = TripTrackingDeviceOperationalPolicy.fromDeviceProfile(
      DeviceCapabilityProfile(
        hardware: const DeviceHardwareSnapshot(platform: 'android'),
        runtime: DeviceRuntimeSnapshot(
          observedAt: DateTime.utc(2026, 7, 18),
          freeStorageMb: 500,
          totalStorageMb: 64000,
          powerSaving: true,
        ),
        camera: const DeviceCameraCapabilities(),
        extended: const DeviceExtendedCapabilities(
          battery: DeviceBatteryCapabilities(levelPercent: 12),
        ),
        baselineTier: DevicePerformanceTier.entry,
        tier: DevicePerformanceTier.constrained,
        confidence: DeviceCapabilityConfidence.medium,
        score: 20,
        limitingFactors: const ['low_storage', 'critical_battery'],
      ),
    );
    final guidance = policy.guidanceFor(
      const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        activityRecognitionEnabled: true,
        backgroundTrackingEnabled: true,
        mapPreviewEnabled: true,
        mapRouteHistorySavingEnabled: true,
        mapRouteHistoryDailyBudgetMb: 1,
      ),
    );

    expect(policy.lowBatteryGuardRecommended, isTrue);
    expect(policy.backgroundTrackingAllowed, isFalse);
    expect(policy.activityRecognitionRecommended, isFalse);
    expect(policy.deferMapRouteHistory, isTrue);
    expect(guidance.recommendedSettings.backgroundTrackingEnabled, isFalse);
    expect(guidance.recommendedSettings.activityRecognitionEnabled, isFalse);
    expect(guidance.recommendedSettings.mapRouteHistorySavingEnabled, isFalse);
    expect(guidance.recommendedSettings.lowBatteryGpsProtectionEnabled, isTrue);
  });

  test(
    'low-storage devices keep GPS text logs while deferring map history',
    () {
      final policy = TripTrackingDeviceOperationalPolicy.fromDeviceProfile(
        DeviceCapabilityProfile(
          hardware: const DeviceHardwareSnapshot(platform: 'android'),
          runtime: DeviceRuntimeSnapshot(
            observedAt: DateTime.utc(2026, 7, 18),
            freeStorageMb: 25,
            totalStorageMb: 64000,
          ),
          camera: const DeviceCameraCapabilities(),
          extended: const DeviceExtendedCapabilities(
            sensors: DeviceSensorCapabilities(types: {'accelerometer'}),
            battery: DeviceBatteryCapabilities(levelPercent: 35),
            connectivity: DeviceConnectivityCapabilities(isConnected: true),
          ),
          baselineTier: DevicePerformanceTier.entry,
          tier: DevicePerformanceTier.constrained,
          confidence: DeviceCapabilityConfidence.medium,
          score: 25,
          limitingFactors: const ['low_storage'],
        ),
      );
      final summary = policy.toSafeSummary();

      expect(summary['gpsTextTripLogCanContinueWithLowStorage'], isTrue);
      expect(summary['mapRouteHistoryIsOptional'], isTrue);
      expect(summary['mapRouteHistoryDeferBelowDeviceBudget'], isTrue);
      expect(policy.deferMapRouteHistory, isTrue);
      expect(summary['preciseLocationIncluded'], isFalse);
    },
  );

  test('battery guard defaults are user-controlled and token-safe', () {
    final policy = TripTrackingDeviceOperationalPolicy.fromDeviceProfile(
      DeviceCapabilityProfile(
        hardware: const DeviceHardwareSnapshot(platform: 'ios'),
        runtime: DeviceRuntimeSnapshot(
          observedAt: DateTime.utc(2026, 7, 18),
          freeStorageMb: 64000,
          totalStorageMb: 128000,
          powerSaving: true,
        ),
        camera: const DeviceCameraCapabilities(),
        extended: const DeviceExtendedCapabilities(
          battery: DeviceBatteryCapabilities(levelPercent: 18),
        ),
        baselineTier: DevicePerformanceTier.performance,
        tier: DevicePerformanceTier.performance,
        confidence: DeviceCapabilityConfidence.high,
        score: 70,
        limitingFactors: const ['low_battery'],
      ),
    );
    final summary = policy.toSafeSummary();

    expect(summary['lowBatteryDefaultGpsPausePercent'], 20);
    expect(summary['lowBatteryPauseCanBeOverriddenByUser'], isTrue);
    expect(summary['tokensIncluded'], isFalse);
  });
}
