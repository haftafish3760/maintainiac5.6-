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

  test(
    'sensor consent matrix degrades safely without stopping GPS tracking',
    () {
      final cases = <_ConsentCase>[
        const _ConsentCase(
          name: 'gps disabled',
          settings: TripTrackingSettings(
            gpsAssistedTrackingEnabled: false,
            activityRecognitionEnabled: true,
            backgroundTrackingEnabled: true,
          ),
          locationGrant: true,
          activityGrant: true,
          backgroundGrant: true,
          expectedStatus: TripTrackingSensorConsentStatus.gpsOff,
          gpsAllowed: false,
          activityAllowed: false,
          backgroundAllowed: false,
          reason: 'gps_assist_user_disabled',
        ),
        const _ConsentCase(
          name: 'gps only',
          settings: TripTrackingSettings(gpsAssistedTrackingEnabled: true),
          locationGrant: true,
          activityGrant: false,
          backgroundGrant: false,
          expectedStatus: TripTrackingSensorConsentStatus.gpsOnly,
          gpsAllowed: true,
          activityAllowed: false,
          backgroundAllowed: false,
          reason: 'gps_assist_allowed',
        ),
        const _ConsentCase(
          name: 'motion opt in but permission denied',
          settings: TripTrackingSettings(
            gpsAssistedTrackingEnabled: true,
            activityRecognitionEnabled: true,
          ),
          locationGrant: true,
          activityGrant: false,
          backgroundGrant: true,
          expectedStatus: TripTrackingSensorConsentStatus.gpsOnly,
          gpsAllowed: true,
          activityAllowed: false,
          backgroundAllowed: false,
          reason: 'activity_recognition_not_available_or_not_permitted',
        ),
        const _ConsentCase(
          name: 'background opt in but permission denied',
          settings: TripTrackingSettings(
            gpsAssistedTrackingEnabled: true,
            backgroundTrackingEnabled: true,
          ),
          locationGrant: true,
          activityGrant: false,
          backgroundGrant: false,
          expectedStatus: TripTrackingSensorConsentStatus.gpsOnly,
          gpsAllowed: true,
          activityAllowed: false,
          backgroundAllowed: false,
          reason: 'background_tracking_not_available_or_not_permitted',
        ),
        const _ConsentCase(
          name: 'motion assist allowed',
          settings: TripTrackingSettings(
            gpsAssistedTrackingEnabled: true,
            activityRecognitionEnabled: true,
          ),
          locationGrant: true,
          activityGrant: true,
          backgroundGrant: false,
          expectedStatus: TripTrackingSensorConsentStatus.motionAssistAllowed,
          gpsAllowed: true,
          activityAllowed: true,
          backgroundAllowed: false,
          reason: 'gps_assist_allowed',
        ),
        const _ConsentCase(
          name: 'full assist allowed',
          settings: TripTrackingSettings(
            gpsAssistedTrackingEnabled: true,
            activityRecognitionEnabled: true,
            backgroundTrackingEnabled: true,
          ),
          locationGrant: true,
          activityGrant: true,
          backgroundGrant: true,
          expectedStatus: TripTrackingSensorConsentStatus.fullAssistAllowed,
          gpsAllowed: true,
          activityAllowed: true,
          backgroundAllowed: true,
          reason: 'gps_assist_allowed',
        ),
      ];

      for (final entry in cases) {
        final boundary = TripTrackingSensorConsentBoundary.evaluate(
          settings: entry.settings,
          devicePolicy: capablePolicy,
          platformLocationPermissionGranted: entry.locationGrant,
          platformActivityPermissionGranted: entry.activityGrant,
          platformBackgroundPermissionGranted: entry.backgroundGrant,
        );
        final safe = boundary.toSafeDashboardMap();
        final validation =
            TripTrackingSensorConsentSummaryValidation.fromSummary(safe);

        expect(boundary.status, entry.expectedStatus, reason: entry.name);
        expect(boundary.gpsAllowed, entry.gpsAllowed, reason: entry.name);
        expect(
          boundary.activityRecognitionAllowed,
          entry.activityAllowed,
          reason: entry.name,
        );
        expect(
          boundary.backgroundTrackingAllowed,
          entry.backgroundAllowed,
          reason: entry.name,
        );
        expect(
          boundary.reasonCodes,
          contains(entry.reason),
          reason: entry.name,
        );
        expect(validation.isRenderable, isTrue, reason: entry.name);
        expect(safe['activityRecognitionCanCreateOfficialStop'], isFalse);
        expect(safe['activityRecognitionCanOnlySuggestReview'], isTrue);
        expect(safe['activityEvidenceRequiresCurrentDeviceSession'], isTrue);
        expect(safe['importedSensorEvidenceCannotEnableAssist'], isTrue);
        expect(safe['gpsOnlyModeRemainsAvailableWithoutMotionAssist'], isTrue);
        expect(safe['motionAssistCanDegradeWithoutStoppingTrip'], isTrue);
        expect(safe['backgroundAssistCanDegradeWithoutStoppingTrip'], isTrue);
        expect(
          safe['employerCanEnableTrackingWithoutEmployeeConsent'],
          isFalse,
        );
        expect(
          safe['fleetAdminCanEnableTrackingWithoutEmployeeConsent'],
          isFalse,
        );
        expect(safe['mapboxCanEnableTrackingWithoutConsent'], isFalse);
        expect(safe['odometerRemainsOfficialMileageTruth'], isTrue);
        expect(safe['physicalOdometerRequiredForOfficialMileage'], isTrue);
        expect(safe['localTripLogProtected'], isTrue);
        expect(safe.toString(), isNot(contains('pk.')));
        expect(safe.toString(), isNot(contains('sk.')));
      }
    },
  );

  test('sensor consent validation rejects forged assist without GPS', () {
    final safe = TripTrackingSensorConsentBoundary.evaluate(
      settings: const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
      devicePolicy: capablePolicy,
      platformLocationPermissionGranted: true,
      platformActivityPermissionGranted: false,
      platformBackgroundPermissionGranted: false,
    ).toSafeDashboardMap();

    final validation = TripTrackingSensorConsentSummaryValidation.fromSummary({
      ...safe,
      'gpsAllowed': false,
      'activityRecognitionAllowed': true,
      'backgroundTrackingAllowed': true,
      'debug': '35.123456,-80.123456 sk.redacted',
    });

    expect(validation.isRenderable, isFalse);
    expect(validation.reasons, contains('assist_enabled_without_gps'));
    expect(validation.reasons, contains('summary_contains_sensitive_text'));
  });
}

class _ConsentCase {
  const _ConsentCase({
    required this.name,
    required this.settings,
    required this.locationGrant,
    required this.activityGrant,
    required this.backgroundGrant,
    required this.expectedStatus,
    required this.gpsAllowed,
    required this.activityAllowed,
    required this.backgroundAllowed,
    required this.reason,
  });

  final String name;
  final TripTrackingSettings settings;
  final bool locationGrant;
  final bool activityGrant;
  final bool backgroundGrant;
  final TripTrackingSensorConsentStatus expectedStatus;
  final bool gpsAllowed;
  final bool activityAllowed;
  final bool backgroundAllowed;
  final String reason;
}
