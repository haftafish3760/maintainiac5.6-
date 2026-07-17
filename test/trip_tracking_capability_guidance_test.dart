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
      ),
    );

    expect(guidance.readiness, TripTrackingCapabilityReadiness.unavailable);
    expect(guidance.gpsUnavailable, isTrue);
    expect(guidance.canStartForegroundGps, isFalse);
    expect(guidance.recommendedSettings.gpsAssistedTrackingEnabled, isFalse);
    expect(guidance.recommendedSettings.backgroundTrackingEnabled, isFalse);
    expect(guidance.recommendedSettings.activityRecognitionEnabled, isFalse);
    expect(guidance.recommendedSettings.lowBatteryGpsOverrideEnabled, isFalse);
    expect(guidance.recommendedSettings.lowBatteryGpsWarningDismissed, isFalse);
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
    }
  });
}
