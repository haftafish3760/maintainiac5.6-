import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_dashboard_guidance.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_dashboard_guidance_validation.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  TripTrackingDashboardGuidance deliveryGuidance() =>
      TripTrackingDashboardGuidance.fromSettingsWithSyncContext(
        const TripTrackingSettings(
          gpsAssistedTrackingEnabled: true,
          defaultProfile: TripTrackingProfile.deliveryVehicle,
          mapPreviewEnabled: true,
        ),
        wifiAvailable: true,
        mobileDataAvailable: true,
        syncsUsedInWindow: 1,
      );

  test('valid dashboard guidance is renderable and advisory only', () {
    final validation = TripTrackingDashboardGuidanceValidation.fromGuidance(
      deliveryGuidance(),
    );

    expect(validation.isRenderable, isTrue);
    expect(validation.enabled, isTrue);
    expect(validation.modeToken, 'gig_driver');
    expect(validation.reasons, isEmpty);
  });

  test('dashboard guidance rejects map or remote mileage authority', () {
    final summary = deliveryGuidance().toSafeDashboardMap()
      ..addAll({
        'mapboxCanReplaceOdometer': true,
        'mapboxCanWriteConfirmedTripLog': true,
        'remoteTotalsCanBecomeCanonical': true,
        'odometerRemainsCanonical': false,
      });
    final validation = TripTrackingDashboardGuidanceValidation.fromSummary(
      summary,
    );

    expect(validation.isRenderable, isFalse);
    expect(validation.enabled, isFalse);
    expect(
      validation.reasons,
      contains('remote_or_map_can_mutate_mileage_truth'),
    );
  });

  test(
    'dashboard guidance rejects privacy and employee tracking violations',
    () {
      final summary = deliveryGuidance().toSafeDashboardMap()
        ..addAll({
          'locationSharingRequiresActiveOptIn': false,
          'employeeTrackingRequiresMutualConsent': false,
          'employerGodModeAllowed': true,
        });
      final validation = TripTrackingDashboardGuidanceValidation.fromSummary(
        summary,
      );

      expect(validation.isRenderable, isFalse);
      expect(
        validation.reasons,
        contains('privacy_or_employee_tracking_boundary_invalid'),
      );
    },
  );

  test(
    'dashboard guidance rejects sensitive tokens and raw route material',
    () {
      final summary = deliveryGuidance().toSafeDashboardMap()
        ..addAll({
          'primaryStatus': 'GPS ready token=sk.secret lat=35.1',
          'tokensIncluded': true,
          'preciseLocationIncluded': true,
          'rawLocationIncluded': true,
          'rawSensorPayloadIncluded': true,
          'rawModuleDataIncluded': true,
        });
      final validation = TripTrackingDashboardGuidanceValidation.fromSummary(
        summary,
      );

      expect(validation.isRenderable, isFalse);
      expect(validation.reasons, contains('invalid_primary_status'));
      expect(
        validation.reasons,
        contains('guidance_contains_sensitive_payload'),
      );
    },
  );

  test('dashboard guidance rejects map-required GPS assist', () {
    final summary = deliveryGuidance().toSafeDashboardMap()
      ..addAll({
        'gpsAssistedTrackingAvailableWithoutMaps': false,
        'mapsRequiredForTracking': true,
      });
    final validation = TripTrackingDashboardGuidanceValidation.fromSummary(
      summary,
    );

    expect(validation.isRenderable, isFalse);
    expect(validation.reasons, contains('gps_tracking_depends_on_maps'));
  });

  test('dashboard guidance rejects malformed schema and display shape', () {
    final summary = deliveryGuidance().toSafeDashboardMap()
      ..addAll({
        'schemaVersion': 99,
        'enabled': 'yes',
        'modeToken': 'admin_fleet_spy',
        'profileLabel': 'Private address',
        'dashboardBadges': ['Delivery', 42],
      });
    final validation = TripTrackingDashboardGuidanceValidation.fromSummary(
      summary,
    );

    expect(validation.isRenderable, isFalse);
    expect(
      validation.reasons,
      containsAll([
        'unsupported_schema_version',
        'enabled_not_bool',
        'invalid_mode_token',
        'invalid_profile_label',
        'invalid_dashboard_badges',
      ]),
    );
  });
}
