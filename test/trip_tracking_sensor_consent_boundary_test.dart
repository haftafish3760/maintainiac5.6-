import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_device_operational_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_sensor_consent_boundary.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  const capablePolicy = TripTrackingDeviceOperationalPolicy(
    platformCapabilities: TripTrackingPlatformCapabilities(
      locationAvailable: true,
      backgroundTrackingAvailable: true,
      activityRecognitionAvailable: true,
      batteryStateAvailable: true,
    ),
    recommendedSampleIntervalSeconds: 5,
    lowBatteryGuardRecommended: true,
    activityRecognitionRecommended: true,
    backgroundTrackingAllowed: true,
    deferMapRouteHistory: false,
  );

  test('GPS off disables every sensor path regardless of permissions', () {
    final boundary = TripTrackingSensorConsentBoundary.evaluate(
      settings: const TripTrackingSettings(
        activityRecognitionEnabled: true,
        backgroundTrackingEnabled: true,
      ),
      devicePolicy: capablePolicy,
      platformLocationPermissionGranted: true,
      platformActivityPermissionGranted: true,
      platformBackgroundPermissionGranted: true,
    );

    expect(boundary.status, TripTrackingSensorConsentStatus.gpsOff);
    expect(boundary.gpsAllowed, isFalse);
    expect(boundary.activityRecognitionAllowed, isFalse);
    expect(boundary.backgroundTrackingAllowed, isFalse);
    expect(boundary.reasonCodes, contains('gps_assist_user_disabled'));
  });

  test(
    'full assist requires user opt-in, device support, and platform grants',
    () {
      final boundary = TripTrackingSensorConsentBoundary.evaluate(
        settings: const TripTrackingSettings(
          gpsAssistedTrackingEnabled: true,
          activityRecognitionEnabled: true,
          backgroundTrackingEnabled: true,
        ),
        devicePolicy: capablePolicy,
        platformLocationPermissionGranted: true,
        platformActivityPermissionGranted: true,
        platformBackgroundPermissionGranted: true,
      );
      final safe = boundary.toSafeDashboardMap();

      expect(
        boundary.status,
        TripTrackingSensorConsentStatus.fullAssistAllowed,
      );
      expect(boundary.gpsAllowed, isTrue);
      expect(boundary.activityRecognitionAllowed, isTrue);
      expect(boundary.backgroundTrackingAllowed, isTrue);
      expect(safe['gpsAssistedTrackingRequiresUserOptIn'], isTrue);
      expect(safe['activityRecognitionRequiresUserOptIn'], isTrue);
      expect(safe['backgroundTrackingRequiresUserOptIn'], isTrue);
      expect(safe['activityRecognitionCanCreateOfficialStop'], isFalse);
    },
  );

  test(
    'missing motion permission keeps GPS while disabling walking assist',
    () {
      final boundary = TripTrackingSensorConsentBoundary.evaluate(
        settings: const TripTrackingSettings(
          gpsAssistedTrackingEnabled: true,
          activityRecognitionEnabled: true,
        ),
        devicePolicy: capablePolicy,
        platformLocationPermissionGranted: true,
        platformActivityPermissionGranted: false,
        platformBackgroundPermissionGranted: true,
      );

      expect(boundary.status, TripTrackingSensorConsentStatus.gpsOnly);
      expect(boundary.gpsAllowed, isTrue);
      expect(boundary.activityRecognitionAllowed, isFalse);
      expect(
        boundary.reasonCodes,
        contains('activity_recognition_not_available_or_not_permitted'),
      );
    },
  );

  test('missing background permission keeps foreground GPS available', () {
    final boundary = TripTrackingSensorConsentBoundary.evaluate(
      settings: const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        backgroundTrackingEnabled: true,
      ),
      devicePolicy: capablePolicy,
      platformLocationPermissionGranted: true,
      platformActivityPermissionGranted: false,
      platformBackgroundPermissionGranted: false,
    );

    expect(boundary.status, TripTrackingSensorConsentStatus.gpsOnly);
    expect(boundary.gpsAllowed, isTrue);
    expect(boundary.backgroundTrackingAllowed, isFalse);
    expect(
      boundary.reasonCodes,
      contains('background_tracking_not_available_or_not_permitted'),
    );
  });

  test(
    'location permission denial blocks GPS but cannot delete local records',
    () {
      final boundary = TripTrackingSensorConsentBoundary.evaluate(
        settings: const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
        devicePolicy: capablePolicy,
        platformLocationPermissionGranted: false,
        platformActivityPermissionGranted: true,
        platformBackgroundPermissionGranted: true,
      );
      final safe = boundary.toSafeDashboardMap();

      expect(boundary.gpsAllowed, isFalse);
      expect(
        boundary.reasonCodes,
        contains('location_permission_or_capability_required'),
      );
      expect(safe['localTripLogProtected'], isTrue);
      expect(safe['firebaseCanEnableTrackingWithoutConsent'], isFalse);
      expect(safe['mapboxCanEnableTrackingWithoutConsent'], isFalse);
    },
  );

  test('remote, employer, and map services cannot enable sensors', () {
    final safe = TripTrackingSensorConsentBoundary.evaluate(
      settings: const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
      devicePolicy: capablePolicy,
      platformLocationPermissionGranted: true,
      platformActivityPermissionGranted: true,
      platformBackgroundPermissionGranted: true,
    ).toSafeDashboardMap();

    expect(safe['remoteCapabilityCanEnableSensorsWithoutOptIn'], isFalse);
    expect(safe['firebaseCanEnableTrackingWithoutConsent'], isFalse);
    expect(safe['mapboxCanEnableTrackingWithoutConsent'], isFalse);
    expect(safe['employerCanEnableTrackingWithoutEmployeeConsent'], isFalse);
    expect(safe['gpsCanReplaceOdometer'], isFalse);
    expect(safe['mapboxCanReplaceOdometer'], isFalse);
    expect(safe['deviceModelIncluded'], isFalse);
    expect(safe['rawSensorPayloadIncluded'], isFalse);
    expect(safe['preciseLocationIncluded'], isFalse);
    expect(safe['tokensIncluded'], isFalse);
  });
}
