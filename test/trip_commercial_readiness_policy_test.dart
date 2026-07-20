import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_commercial_readiness_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_dashboard_status_rollup_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_gps_dependability_rollup_policy.dart';
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
    nextLifecycle: TripTrackingSessionLifecycleState.activeTracking,
    shouldKeepForegroundServiceAlive: true,
    shouldRequestUserAction: false,
    canReplayPendingSample: false,
    canUploadBackupMirror: true,
  );
  const lifecyclePrompt = TripLifecycleSupervisorDecision(
    status: TripLifecycleSupervisorStatus.promptUser,
    reasonCode: 'native_error_requires_user_action',
    nextLifecycle: TripTrackingSessionLifecycleState.awaitingPermission,
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
    TripGpsDependabilityRollupDecision? gpsDependabilityRollup,
  }) {
    return TripCommercialReadinessPolicy.evaluate(
      profileStrategy: TripTrackingProfileStrategy.forProfile(profile),
      dashboardRollup: dashboard,
      lifecycleSupervisor: lifecycle,
      visibilityConsent: visibility,
      mapboxBoundary: maps,
      gpsDependabilityRollup: gpsDependabilityRollup,
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

  test('weak GPS dependability rollup forces commercial manual review', () {
    final decision = evaluate(
      gpsDependabilityRollup: rollup(
        TripGpsDependabilityRollupStatus.excludedFromCalibration,
        canUseForLiveAssist: true,
        canUseForCalibrationEvidence: false,
        requiresUserReview: true,
      ),
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripCommercialReadinessStatus.readyWithReview);
    expect(decision.canStartOrContinueTrip, isTrue);
    expect(decision.manualReviewRecommended, isTrue);
    expect(safe['gpsDependabilityRollupCheckedWhenAvailable'], isTrue);
    expect(safe['weakGpsDependabilityForcesManualReview'], isTrue);
  });

  test('unsafe GPS dependability blocks commercial readiness closed', () {
    final decision = evaluate(
      gpsDependabilityRollup: rollup(
        TripGpsDependabilityRollupStatus.unsafe,
        canUseForLiveAssist: false,
        canUseForCalibrationEvidence: false,
        requiresUserReview: true,
      ),
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripCommercialReadinessStatus.blocked);
    expect(decision.reasonCode, 'gps_dependability_unsafe_blocked');
    expect(decision.canStartOrContinueTrip, isFalse);
    expect(decision.manualReviewRecommended, isTrue);
    expect(safe['unsafeGpsDependabilityBlocksCommercialReadiness'], isTrue);
    expect(
      TripCommercialReadinessSummaryValidation.fromSummary(safe).isRenderable,
      isTrue,
    );
  });

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
      expect(safe['gpsAccuracyStillRequiresFieldProof'], isTrue);
      expect(safe['commercialReadyDoesNotMeanProductionReady'], isTrue);
      expect(safe['limitedGpsOnlyCanStartWithoutMaps'], isTrue);
      expect(safe['realDeviceEvidenceRequiredForDependabilityClaim'], isTrue);
      expect(safe['odometerIsGlobalTruth'], isTrue);
      expect(safe['commercialReadinessCanSetGlobalTruth'], isFalse);
      expect(safe['commercialReadinessCanChangeOfficialMileage'], isFalse);
      expect(safe['poorGpsCalibrationProofRequired'], isTrue);
      expect(safe['calibrationRequiresTrustedGpsWindow'], isTrue);
      expect(safe['poorGpsDaysExcludedFromCalibration'], isTrue);
      expect(safe['calibrationCanCreateOfficialMileage'], isFalse);
      expect(safe['employeeTrackingRequiresMutualConsent'], isTrue);
      expect(safe['employerGodModeAllowed'], isFalse);
      expect(safe['remoteDataCanOverrideLocalTrip'], isFalse);
      expect(safe['authenticatedRemoteDataStillRequiresAuthorization'], isTrue);
      expect(safe['tokensIncluded'], isFalse);
      expect(
        TripCommercialReadinessSummaryValidation.fromSummary(safe).isRenderable,
        isTrue,
      );
    },
  );

  test(
    'commercial readiness summary rejects production and truth overclaims',
    () {
      final safe = evaluate().toSafeDashboardMap();

      final validation = TripCommercialReadinessSummaryValidation.fromSummary({
        ...safe,
        'commercialReadyDoesNotMeanProductionReady': false,
        'gpsDependabilityRollupCheckedWhenAvailable': false,
        'unsafeGpsDependabilityBlocksCommercialReadiness': false,
        'weakGpsDependabilityForcesManualReview': false,
        'realDeviceEvidenceRequiredForDependabilityClaim': false,
        'poorGpsCalibrationProofRequired': false,
        'calibrationRequiresTrustedGpsWindow': false,
        'poorGpsDaysExcludedFromCalibration': false,
        'calibrationCanCreateOfficialMileage': true,
        'mapboxCanCreateOfficialStop': true,
        'profileStrategyCanEndTripAutomatically': true,
        'odometerIsGlobalTruth': false,
        'commercialReadinessCanSetGlobalTruth': true,
        'commercialReadinessCanChangeOfficialMileage': true,
        'remoteDataCanOverrideLocalTrip': true,
        'employerGodModeAllowed': true,
        'debug': '35.123456,-80.123456 token=sk.secret',
      });

      expect(validation.isRenderable, isFalse);
      expect(
        validation.reasons,
        contains('gps_dependability_boundary_missing'),
      );
      expect(
        validation.reasons,
        contains('commercial_evidence_boundary_missing'),
      );
      expect(
        validation.reasons,
        contains('commercial_claims_trip_truth_authority'),
      );
      expect(
        validation.reasons,
        contains('commercial_remote_authority_boundary_missing'),
      );
      expect(
        validation.reasons,
        contains('commercial_privacy_boundary_missing'),
      );
      expect(
        validation.reasons,
        contains('summary_contains_sensitive_commercial_material'),
      );
    },
  );
}

TripGpsDependabilityRollupDecision rollup(
  TripGpsDependabilityRollupStatus status, {
  required bool canUseForLiveAssist,
  required bool canUseForCalibrationEvidence,
  required bool requiresUserReview,
}) {
  return TripGpsDependabilityRollupDecision(
    status: status,
    reasonCode: status == TripGpsDependabilityRollupStatus.unsafe
        ? 'gps_rollup_unsafe_window_present'
        : 'gps_rollup_projection_paused_window_present',
    windowCount: 8,
    readyWindowCount: status == TripGpsDependabilityRollupStatus.unsafe ? 7 : 6,
    reviewOnlyWindowCount: 0,
    pausedWindowCount: status == TripGpsDependabilityRollupStatus.unsafe
        ? 0
        : 2,
    unsafeWindowCount: status == TripGpsDependabilityRollupStatus.unsafe
        ? 1
        : 0,
    canUseForLiveAssist: canUseForLiveAssist,
    canUseForCalibrationEvidence: canUseForCalibrationEvidence,
    requiresUserReview: requiresUserReview,
  );
}
