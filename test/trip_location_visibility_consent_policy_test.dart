import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_location_visibility_consent_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_backup_scope_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_device_operational_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_sensor_consent_boundary.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

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

  TripTrackingSensorConsentBoundary gpsOnly() =>
      TripTrackingSensorConsentBoundary.evaluate(
        settings: const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
        devicePolicy: capablePolicy,
        platformLocationPermissionGranted: true,
        platformActivityPermissionGranted: false,
        platformBackgroundPermissionGranted: false,
      );

  TripTrackingSensorConsentBoundary backgroundGps() =>
      TripTrackingSensorConsentBoundary.evaluate(
        settings: const TripTrackingSettings(
          gpsAssistedTrackingEnabled: true,
          backgroundTrackingEnabled: true,
        ),
        devicePolicy: capablePolicy,
        platformLocationPermissionGranted: true,
        platformActivityPermissionGranted: false,
        platformBackgroundPermissionGranted: true,
      );

  TripTrackingSensorConsentBoundary gpsOff() =>
      TripTrackingSensorConsentBoundary.evaluate(
        settings: const TripTrackingSettings(),
        devicePolicy: capablePolicy,
        platformLocationPermissionGranted: true,
        platformActivityPermissionGranted: true,
        platformBackgroundPermissionGranted: true,
      );

  TripTrackingBackupScopeDecision allowedScope() =>
      TripTrackingBackupScopeDecision.allowed(_fakeReview());

  const rejectedScope = TripTrackingBackupScopeDecision.rejected(
    TripTrackingBackupScopeFailure.missingOrganization,
  );

  TripLocationVisibilityConsentDecision evaluate({
    TripTrackingSensorConsentBoundary? sensor,
    TripTrackingBackupScopeDecision? scope,
    TripTrackingCloudBackupScope requestedScope =
        TripTrackingCloudBackupScope.organization,
    bool employeeConsent = true,
    bool employerConsent = true,
    bool liveEnabled = true,
    bool routeHistory = false,
    String uid = 'owner123',
    String? owner = 'owner123',
    String? org = 'org123',
  }) {
    return TripLocationVisibilityConsentPolicy.evaluate(
      sensorConsent: sensor ?? backgroundGps(),
      backupScope: scope ?? allowedScope(),
      requestedScope: requestedScope,
      employeeConsentedToLocationSharing: employeeConsent,
      employerConsentedToLocationSharingTerms: employerConsent,
      liveLocationSharingEnabled: liveEnabled,
      routeHistorySharingEnabled: routeHistory,
      authenticatedUid: uid,
      recordOwnerUid: owner,
      organizationId: org,
    );
  }

  test('personal backup never exposes organization live location', () {
    final decision = evaluate(
      requestedScope: TripTrackingCloudBackupScope.personal,
      scope: rejectedScope,
      org: null,
    );

    expect(decision.status, TripLocationVisibilityStatus.allowed);
    expect(decision.mode, TripLocationVisibilityMode.personalBackupOnly);
    expect(decision.canShowLiveLocationToOrganization, isFalse);
  });

  test('organization live location requires employee and employer consent', () {
    final missingEmployee = evaluate(employeeConsent: false);
    final missingEmployer = evaluate(employerConsent: false);

    expect(
      missingEmployee.status,
      TripLocationVisibilityStatus.blockedNoEmployeeConsent,
    );
    expect(
      missingEmployer.status,
      TripLocationVisibilityStatus.blockedNoEmployerConsent,
    );
  });

  test('live organization location requires background GPS consent', () {
    final decision = evaluate(sensor: gpsOnly());

    expect(
      decision.status,
      TripLocationVisibilityStatus.blockedLiveSharingDisabled,
    );
    expect(decision.canShowLiveLocationToOrganization, isFalse);
  });

  test('summary organization visibility can mirror reviewed mileage only', () {
    final decision = evaluate(sensor: gpsOnly(), liveEnabled: false);

    expect(decision.status, TripLocationVisibilityStatus.allowed);
    expect(decision.mode, TripLocationVisibilityMode.organizationSummary);
    expect(decision.canMirrorReviewedMileageToOrganization, isTrue);
    expect(decision.canShowLiveLocationToOrganization, isFalse);
    expect(decision.canShowRouteHistoryToOrganization, isFalse);
  });

  test(
    'live location can include route history only after separate opt in',
    () {
      final withoutRoute = evaluate(routeHistory: false);
      final withRoute = evaluate(routeHistory: true);

      expect(withoutRoute.canShowLiveLocationToOrganization, isTrue);
      expect(withoutRoute.canShowRouteHistoryToOrganization, isFalse);
      expect(withRoute.canShowRouteHistoryToOrganization, isTrue);
    },
  );

  test('unsafe actor ids and missing organization scope fail closed', () {
    final unsafe = evaluate(uid: 'sk.secret');
    final missingScope = evaluate(scope: rejectedScope);

    expect(unsafe.status, TripLocationVisibilityStatus.blockedUnsafeActor);
    expect(
      missingScope.status,
      TripLocationVisibilityStatus.blockedNoOrganizationScope,
    );
  });

  test('GPS consent is required before any location visibility', () {
    final decision = evaluate(sensor: gpsOff());

    expect(decision.status, TripLocationVisibilityStatus.blockedNoGpsConsent);
    expect(decision.canShowLiveLocationToOrganization, isFalse);
    expect(decision.canMirrorReviewedMileageToOrganization, isFalse);
  });

  test(
    'safe summary denies god mode, remote enablement, and sensitive fields',
    () {
      final safe = evaluate(routeHistory: true).toSafeDashboardMap();

      expect(safe['employeeTrackingRequiresMutualConsent'], isTrue);
      expect(safe['employerGodModeAllowed'], isFalse);
      expect(safe['accountOwnerAloneCanEnableEmployeeTracking'], isFalse);
      expect(safe['remotePolicyCanOverrideLocalConsent'], isFalse);
      expect(safe['firestoreCanEnableLocationSharing'], isFalse);
      expect(safe['preciseLocationIncluded'], isFalse);
      expect(safe['organizationIdIncluded'], isFalse);
      expect(safe['tokensIncluded'], isFalse);
    },
  );
}

TripTrackingReviewRecord _fakeReview() {
  return TripTrackingReviewRecord(
    id: 'trip123',
    vehicleId: 'vehicle123',
    profile: TripTrackingProfile.roadVehicle,
    startedAt: DateTime.utc(2026, 7, 18, 8),
    finishedAt: DateTime.utc(2026, 7, 18, 9),
    startingOdometer: 1000,
    estimatedEndingOdometer: 1010,
    engineSnapshot: const TripTrackingEngineSnapshot(
      totalAcceptedMeters: 1609.344,
      walkingReviewSuggested: false,
    ),
    cloudBackupScope: TripTrackingCloudBackupScope.organization,
    cloudAccountUid: 'owner123',
    cloudOrganizationId: 'org123',
  );
}
