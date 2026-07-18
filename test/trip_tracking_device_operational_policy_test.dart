import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/device_capabilities/device_capabilities.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_device_operational_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';
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
    expect(summary['mapUsageRequiresSeparateUserOptIn'], isTrue);
    expect(summary['paidMapServicesCanBeDisabled'], isTrue);
    expect(summary['mapRouteHistoryIsOptional'], isTrue);
    expect(summary['deviceCapabilityTrustedAfterValidationOnly'], isTrue);
    expect(
      summary['validatedCapabilityDoesNotReplacePlatformPermission'],
      isTrue,
    );
    expect(summary['deviceCapabilityCanOnlyRecommendSettings'], isTrue);
    expect(summary['deviceCapabilityCanDeleteLocalData'], isFalse);
    expect(summary['deviceCapabilityCanSilentlyStartTracking'], isFalse);
    expect(summary['remoteCapabilityCanEnableSensorsWithoutOptIn'], isFalse);
    expect(summary['firebaseDeviceProfileCanOverrideUserConsent'], isFalse);
    expect(summary['mapboxCanOverrideDevicePolicy'], isFalse);
    expect(summary['malformedCapabilityPayloadFailsSafe'], isTrue);
    expect(summary['activityRecognitionRequiresOptIn'], isTrue);
    expect(summary['activityRecognitionCanCreateOfficialStop'], isFalse);
    expect(summary['activityRecognitionCanOnlySuggestReview'], isTrue);
    expect(summary['backgroundTrackingRequiresPlatformPermission'], isTrue);
    expect(summary['backgroundTrackingRequiresUserConsent'], isTrue);
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
      expect(summary['gpsTextTripLogCanContinueAtTwentyFiveMb'], isTrue);
      expect(summary['mapRouteHistoryIsOptional'], isTrue);
      expect(summary['mapRouteHistoryDeferBelowDeviceBudget'], isTrue);
      expect(summary['deviceCapabilityCanDeleteLocalData'], isFalse);
      expect(policy.deferMapRouteHistory, isTrue);
      expect(summary['preciseLocationIncluded'], isFalse);
    },
  );

  test('storage decision keeps text trip logs and defers map history', () {
    final decision = TripTrackingStorageDecision.evaluate(
      freeStorageMb: 25,
      mapRouteHistoryRequested: true,
    );
    final summary = decision.toSafeSummary();

    expect(
      decision.status,
      TripTrackingStorageDecisionStatus.deferMapRouteHistory,
    );
    expect(decision.textTripLogAllowed, isTrue);
    expect(decision.mapRouteHistoryAllowed, isFalse);
    expect(summary['freeStorageBucket'], '25_to_499_mb');
    expect(summary['minimumTextTripLogStorageMb'], 25);
    expect(summary['gpsTextTripLogCanContinueAtTwentyFiveMb'], isTrue);
    expect(summary['mapRouteHistoryCanBeDeferredWithoutStoppingTrip'], isTrue);
    expect(summary['storageDecisionCanDeleteTripData'], isFalse);
    expect(summary['firebaseBackupCanPurgeLocalRecordsSilently'], isFalse);
    expect(summary['preciseFreeStorageIncluded'], isFalse);
  });

  test('storage decision never blocks text TripLog at critical storage', () {
    final decision = TripTrackingStorageDecision.evaluate(
      freeStorageMb: 10,
      mapRouteHistoryRequested: true,
    );
    final summary = decision.toSafeSummary();

    expect(decision.status, TripTrackingStorageDecisionStatus.reviewStorage);
    expect(decision.shouldPromptUser, isTrue);
    expect(decision.textTripLogAllowed, isTrue);
    expect(decision.mapRouteHistoryAllowed, isFalse);
    expect(summary['reasonCode'], 'critically_low_storage_review');
    expect(summary['freeStorageBucket'], 'below_25_mb');
    expect(summary['storageDecisionCanPurgeLocalRecords'], isFalse);
    expect(summary['rawStoragePayloadIncluded'], isFalse);
  });

  test('storage decision allows optional map history only with budget', () {
    final noMaps = TripTrackingStorageDecision.evaluate(
      freeStorageMb: 5000,
      mapRouteHistoryRequested: false,
    );
    final maps = TripTrackingStorageDecision.evaluate(
      freeStorageMb: 5000,
      mapRouteHistoryRequested: true,
    );
    final malformed = TripTrackingStorageDecision.evaluate(
      freeStorageMb: 5000,
      mapRouteHistoryRequested: true,
      minimumTextTripLogStorageMb: 1000,
      minimumMapRouteHistoryStorageMb: 100,
    );

    expect(noMaps.mapRouteHistoryAllowed, isFalse);
    expect(noMaps.reasonCode, 'storage_allows_text_log');
    expect(maps.mapRouteHistoryAllowed, isTrue);
    expect(maps.reasonCode, 'storage_allows_text_log_and_map_history');
    expect(malformed.status, TripTrackingStorageDecisionStatus.reviewStorage);
    expect(malformed.reasonCode, 'invalid_storage_policy');
  });

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

  test('direct device policy summaries clamp malformed sample intervals', () {
    const policy = TripTrackingDeviceOperationalPolicy(
      platformCapabilities: TripTrackingPlatformCapabilities(
        locationAvailable: true,
        backgroundTrackingAvailable: true,
        activityRecognitionAvailable: true,
      ),
      recommendedSampleIntervalSeconds: -999,
      lowBatteryGuardRecommended: true,
      activityRecognitionRecommended: true,
      backgroundTrackingAllowed: true,
      deferMapRouteHistory: false,
    );

    final summary = policy.toSafeSummary();

    expect(summary['recommendedSampleIntervalSeconds'], 5);
    expect(summary['deviceCapabilityTrustedAfterValidationOnly'], isTrue);
    expect(
      summary['validatedCapabilityDoesNotReplacePlatformPermission'],
      isTrue,
    );
    expect(summary['remoteCapabilityCanEnableSensorsWithoutOptIn'], isFalse);
    expect(summary['firebaseDeviceProfileCanOverrideUserConsent'], isFalse);
    expect(summary['mapboxCanOverrideDevicePolicy'], isFalse);
    expect(summary['malformedCapabilityPayloadFailsSafe'], isTrue);
    expect(summary['deviceModelIncluded'], isFalse);
    expect(summary['rawSensorPayloadIncluded'], isFalse);
  });

  test('device consent policy enables GPS without requiring maps', () {
    final decision = TripTrackingDeviceConsentPolicy.evaluate(
      settings: const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        backgroundTrackingEnabled: true,
        activityRecognitionEnabled: true,
        lowBatteryGpsProtectionEnabled: true,
        mapRouteHistorySavingEnabled: false,
      ),
      capabilities: const TripTrackingPlatformCapabilities(
        locationAvailable: true,
        backgroundTrackingAvailable: true,
        activityRecognitionAvailable: true,
        batteryStateAvailable: true,
      ),
      userConsentedToGps: true,
      userConsentedToBackground: true,
      userConsentedToActivityRecognition: true,
    );
    final summary = decision.toSafeSummary();

    expect(decision.status, TripTrackingDeviceConsentStatus.ready);
    expect(
      decision.assistLevel,
      TripTrackingDeviceAssistLevel.motionAndBatteryAssist,
    );
    expect(decision.canStartGpsTracking, isTrue);
    expect(decision.canUseMotionStopAssist, isTrue);
    expect(decision.backgroundEnabled, isTrue);
    expect(decision.activityRecognitionEnabled, isTrue);
    expect(decision.batteryGuardEnabled, isTrue);
    expect(decision.mapHistoryEnabled, isFalse);
    expect(summary['gpsTrackingCanRunWithoutMaps'], isTrue);
    expect(summary['mapsRequiredForTracking'], isFalse);
    expect(summary['mapboxCanEnableGpsTracking'], isFalse);
    expect(summary['activityRecognitionCanCreateOfficialStop'], isFalse);
    expect(summary['activityRecognitionCanOnlySuggestReview'], isTrue);
    expect(summary['odometerRemainsOfficialMileageTruth'], isTrue);
  });

  test('activity sensors require explicit consent and capability', () {
    for (final entry in [
      (
        consent: false,
        capability: true,
        reason: 'activity_recognition_not_authorized_or_available',
      ),
      (
        consent: true,
        capability: false,
        reason: 'activity_recognition_not_authorized_or_available',
      ),
    ]) {
      final decision = TripTrackingDeviceConsentPolicy.evaluate(
        settings: const TripTrackingSettings(
          gpsAssistedTrackingEnabled: true,
          activityRecognitionEnabled: true,
        ),
        capabilities: TripTrackingPlatformCapabilities(
          locationAvailable: true,
          backgroundTrackingAvailable: true,
          activityRecognitionAvailable: entry.capability,
          batteryStateAvailable: true,
        ),
        userConsentedToGps: true,
        userConsentedToBackground: false,
        userConsentedToActivityRecognition: entry.consent,
      );

      expect(
        decision.status,
        TripTrackingDeviceConsentStatus.motionNeedsConsentOrCapability,
      );
      expect(decision.locationEnabled, isTrue);
      expect(decision.canStartGpsTracking, isTrue);
      expect(decision.activityRecognitionEnabled, isFalse);
      expect(decision.canUseMotionStopAssist, isFalse);
      expect(decision.reasonCodes, contains(entry.reason));
      expect(decision.toSafeSummary()['canDegradeToLocationOnly'], isTrue);
      expect(
        decision.toSafeSummary()['missingAssistBlocksGpsTracking'],
        isFalse,
      );
      expect(
        decision.toSafeSummary()['motionAssistCanDegradeWithoutStoppingTrip'],
        isTrue,
      );
      expect(
        decision.toSafeSummary()['firebaseCanEnableSensorsWithoutUserConsent'],
        isFalse,
      );
    }
  });

  test('background tracking requires user consent and native capability', () {
    final decision = TripTrackingDeviceConsentPolicy.evaluate(
      settings: const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        backgroundTrackingEnabled: true,
      ),
      capabilities: const TripTrackingPlatformCapabilities(
        locationAvailable: true,
        backgroundTrackingAvailable: false,
        activityRecognitionAvailable: false,
        batteryStateAvailable: false,
      ),
      userConsentedToGps: true,
      userConsentedToBackground: true,
      userConsentedToActivityRecognition: false,
    );

    expect(
      decision.status,
      TripTrackingDeviceConsentStatus.backgroundNeedsConsentOrCapability,
    );
    expect(decision.locationEnabled, isTrue);
    expect(decision.canStartGpsTracking, isTrue);
    expect(decision.backgroundEnabled, isFalse);
    expect(decision.recommendedSettings.backgroundTrackingEnabled, isFalse);
    expect(decision.toSafeSummary()['missingAssistBlocksGpsTracking'], isFalse);
    expect(
      decision.toSafeSummary()['backgroundAssistCanDegradeWithoutStoppingTrip'],
      isTrue,
    );
    expect(
      decision.toSafeSummary()['backgroundTrackingRequiresPlatformCapability'],
      isTrue,
    );
  });

  test(
    'GPS disabled or unavailable fails closed without sensor side effects',
    () {
      final disabled = TripTrackingDeviceConsentPolicy.evaluate(
        settings: const TripTrackingSettings(
          gpsAssistedTrackingEnabled: false,
          backgroundTrackingEnabled: true,
          activityRecognitionEnabled: true,
        ),
        capabilities: const TripTrackingPlatformCapabilities(
          locationAvailable: true,
          backgroundTrackingAvailable: true,
          activityRecognitionAvailable: true,
          batteryStateAvailable: true,
        ),
        userConsentedToGps: false,
        userConsentedToBackground: true,
        userConsentedToActivityRecognition: true,
      );
      final unavailable = TripTrackingDeviceConsentPolicy.evaluate(
        settings: const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
        capabilities: const TripTrackingPlatformCapabilities(
          locationAvailable: false,
          backgroundTrackingAvailable: true,
          activityRecognitionAvailable: true,
        ),
        userConsentedToGps: true,
        userConsentedToBackground: true,
        userConsentedToActivityRecognition: true,
      );

      expect(
        disabled.status,
        TripTrackingDeviceConsentStatus.gpsDisabledByUser,
      );
      expect(disabled.canStartGpsTracking, isFalse);
      expect(disabled.activityRecognitionEnabled, isFalse);
      expect(
        unavailable.status,
        TripTrackingDeviceConsentStatus.locationUnavailable,
      );
      expect(unavailable.canStartGpsTracking, isFalse);
      expect(
        unavailable.assistLevel,
        TripTrackingDeviceAssistLevel.unavailable,
      );
    },
  );

  test('device consent summary is safe for logs and employers', () {
    final summary = TripTrackingDeviceConsentPolicy.evaluate(
      settings: const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        activityRecognitionEnabled: true,
        mapRouteHistorySavingEnabled: true,
        mapRouteHistoryDailyBudgetMb: 1,
      ),
      capabilities: const TripTrackingPlatformCapabilities(
        locationAvailable: true,
        backgroundTrackingAvailable: true,
        activityRecognitionAvailable: true,
        batteryStateAvailable: true,
      ),
      userConsentedToGps: true,
      userConsentedToBackground: false,
      userConsentedToActivityRecognition: true,
    ).toSafeSummary();

    expect(summary['employerCanEnableTrackingWithoutUserConsent'], isFalse);
    expect(summary['deviceCapabilityCanOnlyRecommendSettings'], isTrue);
    expect(summary['deviceCapabilityCannotInferConsentFromModel'], isTrue);
    expect(summary['deviceCapabilityCanSilentlyStartTracking'], isFalse);
    expect(summary['activityEvidenceRequiresCurrentDeviceSession'], isTrue);
    expect(summary['importedSensorEvidenceCannotEnableAssist'], isTrue);
    expect(summary['batteryGuardCanStopTripAutomatically'], isFalse);
    expect(summary['batteryGuardCanDeleteTripRecords'], isFalse);
    expect(summary['physicalOdometerRequiredForOfficialMileage'], isTrue);
    expect(summary['confirmedOdometerOverridesExternalMileage'], isTrue);
    expect(summary['externalMileageCannotBecomeGlobalTruth'], isTrue);
    expect(summary['gpsDistanceCanOnlyAdviseMileageReview'], isTrue);
    expect(summary['mapMatchingCanOnlyAdviseMileageReview'], isTrue);
    expect(summary['optimizationCannotChangeOfficialMileage'], isTrue);
    expect(summary['rawSensorPayloadIncluded'], isFalse);
    expect(summary['preciseLocationIncluded'], isFalse);
    expect(summary['deviceModelIncluded'], isFalse);
    expect(summary['tokensIncluded'], isFalse);
    expect(summary.toString(), isNot(contains('pk.')));
    expect(summary.toString(), isNot(contains('sk.')));
  });
}
