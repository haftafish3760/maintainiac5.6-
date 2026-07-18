import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_capability_guidance.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  test('unavailable location disables every GPS dependent setting', () {
    final guidance = TripTrackingCapabilityGuidance.fromCapabilities(
      capabilities: const TripTrackingPlatformCapabilities(
        locationAvailable: false,
        backgroundTrackingAvailable: true,
        activityRecognitionAvailable: true,
        batteryStateAvailable: true,
        lowPowerModeAvailable: true,
      ),
      settings: const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        backgroundTrackingEnabled: true,
        activityRecognitionEnabled: true,
        lowBatteryGpsProtectionEnabled: true,
        lowBatteryGpsOverrideEnabled: true,
        lowBatteryGpsWarningDismissed: true,
        mapRouteHistorySavingEnabled: true,
      ),
    );

    expect(guidance.readiness, TripTrackingCapabilityReadiness.unavailable);
    expect(guidance.gpsUnavailable, isTrue);
    expect(guidance.canStartForegroundGps, isFalse);
    expect(guidance.canStartBackgroundGps, isFalse);
    expect(guidance.recommendedSettings.gpsAssistedTrackingEnabled, isFalse);
    expect(guidance.recommendedSettings.backgroundTrackingEnabled, isFalse);
    expect(guidance.recommendedSettings.activityRecognitionEnabled, isFalse);
    expect(guidance.recommendedSettings.lowBatteryGpsOverrideEnabled, isFalse);
    expect(guidance.recommendedSettings.lowBatteryGpsWarningDismissed, isFalse);
    expect(guidance.recommendedSettings.mapRouteHistorySavingEnabled, isFalse);
    expect(
      guidance.toSafeDashboardMap()['routeHistoryDisabledWhenGpsUnavailable'],
      isTrue,
    );
    expect(guidance.dashboardBadge, 'GPS unavailable');
  });

  test(
    'location-only device keeps foreground GPS but strips unavailable assists',
    () {
      final guidance = TripTrackingCapabilityGuidance.fromCapabilities(
        capabilities: const TripTrackingPlatformCapabilities(
          locationAvailable: true,
          backgroundTrackingAvailable: false,
          activityRecognitionAvailable: false,
          batteryStateAvailable: false,
        ),
        settings: const TripTrackingSettings(
          gpsAssistedTrackingEnabled: true,
          backgroundTrackingEnabled: true,
          activityRecognitionEnabled: true,
          lowBatteryGpsProtectionEnabled: true,
          lowBatteryGpsOverrideEnabled: true,
          mapRouteHistorySavingEnabled: true,
          mapPreviewEnabled: true,
          mapRouteHistoryDailyBudgetMb: 1,
        ),
      );

      expect(
        guidance.readiness,
        TripTrackingCapabilityReadiness.foregroundReady,
      );
      expect(guidance.canStartForegroundGps, isTrue);
      expect(guidance.canStartBackgroundGps, isFalse);
      expect(guidance.canUseActivityRecognition, isFalse);
      expect(guidance.canUseBatteryGuard, isFalse);
      expect(guidance.recommendedSettings.gpsAssistedTrackingEnabled, isTrue);
      expect(guidance.recommendedSettings.backgroundTrackingEnabled, isFalse);
      expect(guidance.recommendedSettings.activityRecognitionEnabled, isFalse);
      expect(
        guidance.recommendedSettings.lowBatteryGpsProtectionEnabled,
        isFalse,
      );
      expect(guidance.recommendedSettings.mapRouteHistorySavingEnabled, isTrue);
      expect(guidance.dashboardBadge, 'Foreground GPS');
    },
  );

  test('background capability is separate from motion recognition', () {
    final guidance = TripTrackingCapabilityGuidance.fromCapabilities(
      capabilities: const TripTrackingPlatformCapabilities(
        locationAvailable: true,
        backgroundTrackingAvailable: true,
        activityRecognitionAvailable: false,
        batteryStateAvailable: true,
      ),
      settings: const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        backgroundTrackingEnabled: true,
        activityRecognitionEnabled: true,
        lowBatteryGpsProtectionEnabled: true,
      ),
    );

    expect(guidance.readiness, TripTrackingCapabilityReadiness.backgroundReady);
    expect(guidance.canStartBackgroundGps, isTrue);
    expect(guidance.canUseActivityRecognition, isFalse);
    expect(guidance.recommendedSettings.backgroundTrackingEnabled, isTrue);
    expect(guidance.recommendedSettings.activityRecognitionEnabled, isFalse);
    expect(guidance.recommendedSettings.lowBatteryGpsProtectionEnabled, isTrue);
    expect(guidance.hasSafetySensors, isTrue);
  });

  test('motion and battery capable device keeps opt-in assists enabled', () {
    final guidance = TripTrackingCapabilityGuidance.fromCapabilities(
      capabilities: const TripTrackingPlatformCapabilities(
        locationAvailable: true,
        backgroundTrackingAvailable: true,
        activityRecognitionAvailable: true,
        batteryStateAvailable: true,
        lowPowerModeAvailable: true,
      ),
      settings: const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        activityRecognitionEnabled: true,
        lowBatteryGpsProtectionEnabled: true,
        lowBatteryGpsOverrideEnabled: true,
        lowBatteryGpsWarningDismissed: true,
      ),
    );

    expect(
      guidance.readiness,
      TripTrackingCapabilityReadiness.fullSafetyAssist,
    );
    expect(guidance.dashboardBadge, 'Motion + battery');
    expect(guidance.canUseActivityRecognition, isTrue);
    expect(guidance.canUseBatteryGuard, isTrue);
    expect(guidance.canUseLowPowerGuard, isTrue);
    expect(guidance.recommendedSettings.activityRecognitionEnabled, isTrue);
    expect(guidance.recommendedSettings.lowBatteryGpsOverrideEnabled, isTrue);
    expect(guidance.recommendedSettings.lowBatteryGpsWarningDismissed, isTrue);
  });

  test('motion-capable device does not auto-enable user opt-ins', () {
    final guidance = TripTrackingCapabilityGuidance.fromCapabilities(
      capabilities: const TripTrackingPlatformCapabilities(
        locationAvailable: true,
        backgroundTrackingAvailable: true,
        activityRecognitionAvailable: true,
        batteryStateAvailable: true,
      ),
      settings: const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
    );

    expect(guidance.readiness, TripTrackingCapabilityReadiness.foregroundReady);
    expect(guidance.canUseActivityRecognition, isTrue);
    expect(guidance.recommendedSettings.activityRecognitionEnabled, isFalse);
    expect(guidance.recommendedSettings.backgroundTrackingEnabled, isFalse);
    expect(guidance.recommendedSettings.lowBatteryGpsProtectionEnabled, isTrue);
  });

  test('safe statuses never expose raw native payload details', () {
    for (final readiness in TripTrackingCapabilityReadiness.values) {
      final guidance = TripTrackingCapabilityGuidance.fromCapabilities(
        capabilities: readiness == TripTrackingCapabilityReadiness.unavailable
            ? const TripTrackingPlatformCapabilities(
                locationAvailable: false,
                backgroundTrackingAvailable: false,
                activityRecognitionAvailable: false,
              )
            : const TripTrackingPlatformCapabilities(
                locationAvailable: true,
                backgroundTrackingAvailable: true,
                activityRecognitionAvailable: true,
                batteryStateAvailable: true,
                lowPowerModeAvailable: true,
              ),
        settings: const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
      );

      expect(guidance.safeStatus, isNot(contains('{')));
      expect(guidance.safeStatus, isNot(contains('latitude')));
      expect(guidance.safeStatus, isNot(contains('token')));
      final summary = guidance.toSafeDashboardMap();
      expect(summary['schemaVersion'], 1);
      expect(summary['gpsAssistRequiresOptIn'], isTrue);
      expect(summary['activityRecognitionRequiresOptIn'], isTrue);
      expect(summary['backgroundTrackingRequiresOptIn'], isTrue);
      expect(summary['deviceCapabilityCanReduceAccuracy'], isTrue);
      expect(summary['gpsTrackingCanRunWithoutMaps'], isTrue);
      expect(summary['mapsRequiredForTracking'], isFalse);
      expect(summary['routeHistoryRequiresLocationCapability'], isTrue);
      expect(summary['routeHistoryDisabledWhenGpsUnavailable'], isTrue);
      expect(summary['odometerRemainsCanonical'], isTrue);
      expect(summary['nativeCapabilitiesAreAdvisory'], isTrue);
      expect(summary['sensorAvailabilityRequiresRuntimePermission'], isTrue);
      expect(summary['capabilityReadDoesNotStartTracking'], isTrue);
      expect(summary['capabilityReadDoesNotGrantAuthorization'], isTrue);
      expect(summary['capabilityReadDoesNotGrantPlatformPermission'], isTrue);
      expect(summary['capabilityReadDoesNotGrantEmployerVisibility'], isTrue);
      expect(summary['remoteCapabilityCanEnableSensorsWithoutOptIn'], isFalse);
      expect(summary['deviceModelCanBeUsedAsSensorProof'], isFalse);
      expect(summary['lowBatteryOverrideRequiresUserChoice'], isA<bool>());
      expect(summary['rawNativePayloadIncluded'], isFalse);
      expect(summary['rawSensorPayloadIncluded'], isFalse);
      expect(summary['preciseLocationIncluded'], isFalse);
      expect(summary['tokensIncluded'], isFalse);
    }
  });

  test('battery guard capabilities expose safe low-power dashboard policy', () {
    final withBattery = TripTrackingCapabilityGuidance.fromCapabilities(
      capabilities: const TripTrackingPlatformCapabilities(
        locationAvailable: true,
        backgroundTrackingAvailable: true,
        activityRecognitionAvailable: true,
        batteryStateAvailable: true,
        lowPowerModeAvailable: true,
      ),
      settings: const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
    ).toSafeDashboardMap();
    final withoutBattery = TripTrackingCapabilityGuidance.fromCapabilities(
      capabilities: const TripTrackingPlatformCapabilities(
        locationAvailable: true,
        backgroundTrackingAvailable: true,
        activityRecognitionAvailable: true,
        batteryStateAvailable: false,
      ),
      settings: const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
    ).toSafeDashboardMap();

    expect(withBattery['batteryBelowTwentyDefaultsToGpsPause'], isTrue);
    expect(withBattery['lowBatteryOverrideRequiresUserChoice'], isTrue);
    expect(withBattery['lowBatteryWarningCanBeRestoredInSettings'], isTrue);
    expect(withoutBattery['batteryBelowTwentyDefaultsToGpsPause'], isFalse);
    expect(withoutBattery['lowBatteryOverrideRequiresUserChoice'], isFalse);
  });

  test('safe capability guidance summary validates as renderable', () {
    final validation =
        TripTrackingCapabilityGuidanceSummaryValidation.fromSummary(
          TripTrackingCapabilityGuidance.fromCapabilities(
            capabilities: const TripTrackingPlatformCapabilities(
              locationAvailable: true,
              backgroundTrackingAvailable: true,
              activityRecognitionAvailable: true,
              batteryStateAvailable: true,
              lowPowerModeAvailable: true,
            ),
            settings: const TripTrackingSettings(
              gpsAssistedTrackingEnabled: true,
              activityRecognitionEnabled: true,
              lowBatteryGpsProtectionEnabled: true,
            ),
          ).toSafeDashboardMap(),
        );

    expect(validation.isRenderable, isTrue);
    expect(
      validation.readiness,
      TripTrackingCapabilityReadiness.fullSafetyAssist,
    );
    expect(validation.reasons, isEmpty);
  });

  test('capability summary rejects tracking enable and sensitive claims', () {
    final validation =
        TripTrackingCapabilityGuidanceSummaryValidation.fromSummary(
          TripTrackingCapabilityGuidance.fromCapabilities(
            capabilities: const TripTrackingPlatformCapabilities(
              locationAvailable: true,
              backgroundTrackingAvailable: true,
              activityRecognitionAvailable: true,
              batteryStateAvailable: true,
            ),
            settings: const TripTrackingSettings(
              gpsAssistedTrackingEnabled: true,
            ),
          ).toSafeDashboardMap()..addAll({
            'gpsAssistRequiresOptIn': false,
            'backgroundTrackingRequiresOptIn': false,
            'activityRecognitionRequiresOptIn': false,
            'batteryGuardRequiresOptIn': false,
            'sensorAvailabilityRequiresRuntimePermission': false,
            'capabilityReadDoesNotGrantPlatformPermission': false,
            'capabilityReadDoesNotStartTracking': false,
            'capabilityReadDoesNotGrantAuthorization': false,
            'capabilityReadDoesNotGrantEmployerVisibility': false,
            'remoteCapabilityCanEnableSensorsWithoutOptIn': true,
            'deviceModelCanBeUsedAsSensorProof': true,
            'gpsTrackingCanRunWithoutMaps': false,
            'mapsRequiredForTracking': true,
            'odometerRemainsCanonical': false,
            'nativeCapabilitiesAreAdvisory': false,
            'deviceCapabilityCanReduceAccuracy': false,
            'rawNativePayloadIncluded': true,
            'rawSensorPayloadIncluded': true,
            'preciseLocationIncluded': true,
            'tokensIncluded': true,
            'safeStatus': 'token=pk.public lat=35.123456',
          }),
        );

    expect(validation.isRenderable, isFalse);
    expect(
      validation.reasons,
      contains('capability_permission_boundary_missing'),
    );
    expect(validation.reasons, contains('capability_can_enable_tracking'));
    expect(validation.reasons, contains('map_tracking_boundary_missing'));
    expect(validation.reasons, contains('capability_truth_boundary_missing'));
    expect(
      validation.reasons,
      contains('summary_contains_sensitive_capability_material'),
    );
    expect(validation.reasons, contains('invalid_capability_display_text'));
  });
}
