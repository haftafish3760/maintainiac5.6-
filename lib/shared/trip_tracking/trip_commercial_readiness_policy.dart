import 'trip_dashboard_status_rollup_policy.dart';
import 'trip_lifecycle_supervisor_policy.dart';
import 'trip_location_visibility_consent_policy.dart';
import 'trip_mapbox_request_boundary_policy.dart';
import 'trip_tracking_profile_strategy.dart';

enum TripCommercialReadinessStatus {
  ready,
  readyWithReview,
  limitedGpsOnly,
  blocked,
}

enum TripCommercialDriverScenario {
  general,
  rideshare,
  delivery,
  contractor,
  equipment,
}

class TripCommercialReadinessDecision {
  const TripCommercialReadinessDecision({
    required this.status,
    required this.scenario,
    required this.reasonCode,
    required this.canStartOrContinueTrip,
    required this.manualReviewRecommended,
    required this.mapsOptionalAndSafe,
    required this.employeePrivacySafe,
  });

  final TripCommercialReadinessStatus status;
  final TripCommercialDriverScenario scenario;
  final String reasonCode;
  final bool canStartOrContinueTrip;
  final bool manualReviewRecommended;
  final bool mapsOptionalAndSafe;
  final bool employeePrivacySafe;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'scenario': scenario.name,
    'reasonCode': _safeReason(reasonCode),
    'canStartOrContinueTrip': canStartOrContinueTrip,
    'manualReviewRecommended': manualReviewRecommended,
    'mapsOptionalAndSafe': mapsOptionalAndSafe,
    'employeePrivacySafe': employeePrivacySafe,
    'gpsAssistedTrackingAvailableWithoutMaps': true,
    'mapsRequiredForTripTracking': false,
    'mapboxCanReplaceOdometer': false,
    'mapboxCanCreateOfficialStop': false,
    'profileStrategyCanEndTripAutomatically': false,
    'activityRecognitionCanCreateOfficialStop': false,
    'stopReviewRequiredBeforeOfficialStop': true,
    'confirmedMileageRequiresUserAction': true,
    'odometerRemainsOfficialMileageTruth': true,
    'hiveRemainsOperationalSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'employeeTrackingRequiresMutualConsent': true,
    'employerGodModeAllowed': false,
    'remoteDataCanOverrideLocalTrip': false,
    'commercialRollupCanDeleteLocalData': false,
    'rawTripRecordsIncluded': false,
    'preciseLocationIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripCommercialReadinessPolicy {
  const TripCommercialReadinessPolicy._();

  static TripCommercialReadinessDecision evaluate({
    required TripTrackingProfileStrategy profileStrategy,
    required TripDashboardStatusRollupDecision dashboardRollup,
    required TripLifecycleSupervisorDecision lifecycleSupervisor,
    required TripLocationVisibilityConsentDecision visibilityConsent,
    required TripMapboxRequestBoundaryDecision mapboxBoundary,
  }) {
    final scenario = _scenarioFor(profileStrategy.workStyle);
    final privacySafe = _privacySafe(visibilityConsent);
    final mapsSafe = _mapsSafe(mapboxBoundary);

    if (!privacySafe) {
      return _decision(
        status: TripCommercialReadinessStatus.blocked,
        scenario: scenario,
        reasonCode: 'privacy_consent_blocked',
        canStartOrContinueTrip: false,
        manualReviewRecommended: true,
        mapsOptionalAndSafe: mapsSafe,
        employeePrivacySafe: false,
      );
    }

    if (dashboardRollup.severity == TripDashboardStatusRollupSeverity.blocked ||
        lifecycleSupervisor.status == TripLifecycleSupervisorStatus.blocked ||
        lifecycleSupervisor.status ==
            TripLifecycleSupervisorStatus.promptUser) {
      return _decision(
        status: TripCommercialReadinessStatus.blocked,
        scenario: scenario,
        reasonCode: _blockedReason(dashboardRollup, lifecycleSupervisor),
        canStartOrContinueTrip: false,
        manualReviewRecommended: true,
        mapsOptionalAndSafe: mapsSafe,
        employeePrivacySafe: true,
      );
    }

    if (!mapsSafe || !mapboxBoundary.canRenderMapAssist) {
      return _decision(
        status: TripCommercialReadinessStatus.limitedGpsOnly,
        scenario: scenario,
        reasonCode: 'gps_only_commercial_mode',
        canStartOrContinueTrip: true,
        manualReviewRecommended: _manualReviewNeeded(
          dashboardRollup,
          lifecycleSupervisor,
          profileStrategy,
        ),
        mapsOptionalAndSafe: mapsSafe,
        employeePrivacySafe: true,
      );
    }

    final reviewNeeded = _manualReviewNeeded(
      dashboardRollup,
      lifecycleSupervisor,
      profileStrategy,
    );
    return _decision(
      status: reviewNeeded
          ? TripCommercialReadinessStatus.readyWithReview
          : TripCommercialReadinessStatus.ready,
      scenario: scenario,
      reasonCode: reviewNeeded
          ? 'commercial_ready_with_review'
          : 'commercial_ready',
      canStartOrContinueTrip: true,
      manualReviewRecommended: reviewNeeded,
      mapsOptionalAndSafe: true,
      employeePrivacySafe: true,
    );
  }
}

TripCommercialReadinessDecision _decision({
  required TripCommercialReadinessStatus status,
  required TripCommercialDriverScenario scenario,
  required String reasonCode,
  required bool canStartOrContinueTrip,
  required bool manualReviewRecommended,
  required bool mapsOptionalAndSafe,
  required bool employeePrivacySafe,
}) {
  return TripCommercialReadinessDecision(
    status: status,
    scenario: scenario,
    reasonCode: _safeReason(reasonCode),
    canStartOrContinueTrip: canStartOrContinueTrip,
    manualReviewRecommended: manualReviewRecommended,
    mapsOptionalAndSafe: mapsOptionalAndSafe,
    employeePrivacySafe: employeePrivacySafe,
  );
}

TripCommercialDriverScenario _scenarioFor(TripTrackingWorkStyle workStyle) {
  return switch (workStyle) {
    TripTrackingWorkStyle.rideshare => TripCommercialDriverScenario.rideshare,
    TripTrackingWorkStyle.delivery => TripCommercialDriverScenario.delivery,
    TripTrackingWorkStyle.contractor => TripCommercialDriverScenario.contractor,
    TripTrackingWorkStyle.equipment => TripCommercialDriverScenario.equipment,
    TripTrackingWorkStyle.generalRoad => TripCommercialDriverScenario.general,
  };
}

bool _privacySafe(TripLocationVisibilityConsentDecision value) {
  return value.status == TripLocationVisibilityStatus.allowed;
}

bool _mapsSafe(TripMapboxRequestBoundaryDecision value) {
  return value.status != TripMapboxRequestBoundaryStatus.rejected &&
      value.reasonCode != 'mapbox_http_failure';
}

bool _manualReviewNeeded(
  TripDashboardStatusRollupDecision dashboard,
  TripLifecycleSupervisorDecision lifecycle,
  TripTrackingProfileStrategy profile,
) {
  if (dashboard.severity == TripDashboardStatusRollupSeverity.attention) {
    return true;
  }
  if (lifecycle.shouldRequestUserAction || lifecycle.canReplayPendingSample) {
    return true;
  }
  return profile.vehicleOnlyStopsNeedManualFallback ||
      profile.requiresStrongerStopDebounce;
}

String _blockedReason(
  TripDashboardStatusRollupDecision dashboard,
  TripLifecycleSupervisorDecision lifecycle,
) {
  if (lifecycle.status == TripLifecycleSupervisorStatus.promptUser) {
    return 'platform_permission_blocked';
  }
  if (lifecycle.status == TripLifecycleSupervisorStatus.blocked) {
    return 'local_lifecycle_blocked';
  }
  if (dashboard.severity == TripDashboardStatusRollupSeverity.blocked) {
    return 'dashboard_status_blocked';
  }
  return 'commercial_tracking_blocked';
}

String _safeReason(String value) {
  return switch (value.trim()) {
    'privacy_consent_blocked' => 'privacy_consent_blocked',
    'platform_permission_blocked' => 'platform_permission_blocked',
    'local_lifecycle_blocked' => 'local_lifecycle_blocked',
    'dashboard_status_blocked' => 'dashboard_status_blocked',
    'commercial_tracking_blocked' => 'commercial_tracking_blocked',
    'gps_only_commercial_mode' => 'gps_only_commercial_mode',
    'commercial_ready_with_review' => 'commercial_ready_with_review',
    'commercial_ready' => 'commercial_ready',
    _ => 'commercial_tracking_blocked',
  };
}
