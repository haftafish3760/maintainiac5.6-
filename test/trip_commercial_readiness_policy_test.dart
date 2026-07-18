import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_commercial_readiness_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_dashboard_status_rollup_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_lifecycle_supervisor_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_location_visibility_consent_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_mapbox_request_boundary_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_profile_strategy.dart';

void main() {
  const dashboardNormal = TripDashboardStatusRollupDecision(
    severity: TripDashboardStatusRollupSeverity.normal,
    primaryReasonCode: 'trip_dashboard_normal',
    startButtonEnabled: true,
    liveTimerVisible: true,
    liveOdometerProjectionVisible: true,
    stopReviewVisible: false,
    odometerReviewVisible: false,
    backupStatusVisible: false,
    routeStorageWarningVisible: false,
  );
  const dashboardAttention = TripDashboardStatusRollupDecision(
    severity: TripDashboardStatusRollupSeverity.attention,
    primaryReasonCode: 'stop_review_available',
    startButtonEnabled: true,
    liveTimerVisible: true,
    liveOdometerProjectionVisible: true,
    stopReviewVisible: true,
    odometerReviewVisible: false,
    backupStatusVisible: false,
    routeStorageWarningVisible: false,
  );
  const lifecycleContinue = TripLifecycleSupervisorDecision(
    status: TripLifecycleSupervisorStatus.continueTracking,
    reasonCode: 'supervisor_continue_tracking',
    nextLifecycle: TripTrackingSessionLifecycleState.active,
    shouldKeepForegroundServiceAlive: true,
    shouldRequestUserAction: false,
    canReplayPendingSample: false,
    canUploadBackupMirror: true,
  );
  const lifecyclePrompt = TripLifecycleSupervisorDecision(
    status: TripLifecycleSupervisorStatus.promptUser,
    reasonCode: 'native_error_requires_user_action',
    nextLifecycle: TripTrackingSessionLifecycleState.permissionRequired,
    shouldKeepForegroundServiceAlive: false,
    shouldRequestUserAction: true,
    canReplayPendingSample: false,
    canUploadBackupMirror: false,
  );
  const privateVisible = TripLocationVisibilityConsentDecision(
    status: TripLocationVisibilityStatus.allowed,
    mode: TripLocationVisibilityMode.personalBackupOnly,
    reasonCode: 'personal_visibility_only',
    canShowLiveLocationToOrganization: false,
    canMirrorReviewedMileageToOrganization: false,
    canShowRouteHistoryToOrganization: false,
  );
  const privacyBlocked = TripLocationVisibilityConsentDecision(
    status: TripLocationVisibilityStatus.blockedNoEmployeeConsent,
    mode: TripLocationVisibilityMode.privateOnly,
    reasonCode: 'employee_location_consent_required',
    canShowLiveLocationToOrganization: false,
    canMirrorReviewedMileageToOrganization: false,
    canShowRouteHistoryToOrganization: false,
  );
  const mapsAccepted = TripMapboxRequestBoundaryDecision(
    status: TripMapboxRequestBoundaryStatus.responseAccepted,
    reasonCode: 'mapbox_visual_assist_only',
    canCallMapbox: false,
    canRenderMapAssist: true,
    shouldUseGpsOnlyFallback: false,
    shouldRetryLater: false,
    requestsRemainingInWindow: 10,
  );
  const mapsGpsOnly = TripMapboxRequestBoundaryDecision(
    status: TripMapboxRequestBoundaryStatus.fallbackGpsOnly,
    reasonCode: 'map_preview_not_enabled',
    canCallMapbox: false,
    canRenderMapAssist: false,
    shouldUseGpsOnlyFallback: true,
    shouldRetryLater: false,
    requestsRemainingInWindow: 10,
  );
  const mapsRejected = TripMapboxRequestBoundaryDecision(
    status: TripMapboxRequestBoundaryStatus.rejected,
    reasonCode: 'mapbox_malformed_response',
    canCallMapbox: false,
    canRenderMapAssist: false,
    shouldUseGpsOnlyFallback: true,
    shouldRetryLater: false,
    requestsRemainingInWindow: 0,
  );

  TripCommercialReadinessDecision evaluate({
    TripTrackingProfile profile = TripTrackingProfile.deliveryVehicle,
    TripDashboardStatusRollupDecision dashboard = dashboardNormal,
    TripLifecycleSupervisorDecision lifecycle = lifecycleContinue,
    TripLocationVisibilityConsentDecision visibility = privateVisible,
    TripMapboxRequestBoundaryDecision maps = mapsAccepted,
  }) {
    return TripCommercialReadinessPolicy.evaluate(
      profileStrategy: TripTrackingProfileStrategy.forProfile(profile),
      dashboardRollup: dashboard,
      lifecycleSupervisor: lifecycle,
      visibilityConsent: visibility,
      mapboxBoundary: maps,
    );
  }

  test('delivery mode is commercial ready when core gates are green', () {
    final decision = evaluate();

    expect(decision.status, TripCommercialReadinessStatus.readyWithReview);
    expect(decision.scenario, TripCommercialDriverScenario.delivery);
    expect(decision.canStartOrContinueTrip, isTrue);
    expect(decision.employeePrivacySafe, isTrue);
  });

  test(
    'rideshare requires stronger review even when tracking can continue',
    () {
      final decision = evaluate(profile: TripTrackingProfile.rideshareVehicle);

      expect(decision.scenario, TripCommercialDriverScenario.rideshare);
      expect(decision.manualReviewRecommended, isTrue);
      expect(decision.canStartOrContinueTrip, isTrue);
    },
  );

  test(
    'GPS-only mode remains usable when maps are disabled or unavailable',
    () {
      final decision = evaluate(maps: mapsGpsOnly);

      expect(decision.status, TripCommercialReadinessStatus.limitedGpsOnly);
      expect(decision.reasonCode, 'gps_only_commercial_mode');
      expect(decision.canStartOrContinueTrip, isTrue);
    },
  );

  test('rejected map assist still leaves GPS assisted trips available', () {
    final decision = evaluate(maps: mapsRejected);
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripCommercialReadinessStatus.limitedGpsOnly);
    expect(decision.canStartOrContinueTrip, isTrue);
    expect(decision.mapsOptionalAndSafe, isFalse);
    expect(safe['mapsRequiredForTripTracking'], isFalse);
    expect(safe['mapboxFailureCannotBlockGpsOnlyTrip'], isTrue);
    expect(safe['mapboxCanReplaceOdometer'], isFalse);
    expect(safe['mapboxCanCreateOfficialStop'], isFalse);
  });

  test(
    'dashboard attention produces ready with review instead of auto stop',
    () {
      final decision = evaluate(dashboard: dashboardAttention);

      expect(decision.status, TripCommercialReadinessStatus.readyWithReview);
      expect(decision.manualReviewRecommended, isTrue);
    },
  );

  test('permission or privacy blocks commercial trip readiness closed', () {
    final permission = evaluate(lifecycle: lifecyclePrompt);
    final privacy = evaluate(visibility: privacyBlocked);

    expect(permission.status, TripCommercialReadinessStatus.blocked);
    expect(permission.reasonCode, 'platform_permission_blocked');
    expect(privacy.status, TripCommercialReadinessStatus.blocked);
    expect(privacy.reasonCode, 'privacy_consent_blocked');
  });

  test(
    'safe summary denies maps, activity, employer, and remote authority',
    () {
      final safe = evaluate().toSafeDashboardMap();

      expect(safe['gpsAssistedTrackingAvailableWithoutMaps'], isTrue);
      expect(safe['mapsRequiredForTripTracking'], isFalse);
      expect(safe['mapboxFailureCannotBlockGpsOnlyTrip'], isTrue);
      expect(safe['mapboxAssistRequiresExplicitOptIn'], isTrue);
      expect(safe['mapboxCanReplaceOdometer'], isFalse);
      expect(safe['mapboxCanCreateOfficialStop'], isFalse);
      expect(safe['mapboxCanEndTrip'], isFalse);
      expect(safe['activityRecognitionCanCreateOfficialStop'], isFalse);
      expect(safe['employeeTrackingRequiresMutualConsent'], isTrue);
      expect(safe['employerGodModeAllowed'], isFalse);
      expect(safe['remoteDataCanOverrideLocalTrip'], isFalse);
      expect(safe['authenticatedRemoteDataStillRequiresAuthorization'], isTrue);
      expect(safe['tokensIncluded'], isFalse);
    },
  );
}
