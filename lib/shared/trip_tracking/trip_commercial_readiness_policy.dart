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
    'mapboxFailureCannotBlockGpsOnlyTrip': true,
    'mapboxAssistRequiresExplicitOptIn': true,
    'mapboxCanReplaceOdometer': false,
    'mapboxCanCreateOfficialStop': false,
    'mapboxCanEndTrip': false,
    'profileStrategyCanEndTripAutomatically': false,
    'activityRecognitionCanCreateOfficialStop': false,
    'gpsAccuracyStillRequiresFieldProof': true,
    'commercialReadyDoesNotMeanProductionReady': true,
    'limitedGpsOnlyCanStartWithoutMaps': true,
    'realDeviceEvidenceRequiredForDependabilityClaim': true,
    'stopReviewRequiredBeforeOfficialStop': true,
    'confirmedMileageRequiresUserAction': true,
    'odometerIsGlobalTruth': true,
    'odometerRemainsOfficialMileageTruth': true,
    'commercialReadinessCanSetGlobalTruth': false,
    'commercialReadinessCanChangeOfficialMileage': false,
    'poorGpsCalibrationProofRequired': true,
    'calibrationRequiresTrustedGpsWindow': true,
    'poorGpsDaysExcludedFromCalibration': true,
    'calibrationCanCreateOfficialMileage': false,
    'hiveRemainsOperationalSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'employeeTrackingRequiresMutualConsent': true,
    'employerGodModeAllowed': false,
    'remoteDataCanOverrideLocalTrip': false,
    'authenticatedRemoteDataStillRequiresAuthorization': true,
    'commercialRollupCanDeleteLocalData': false,
    'rawTripRecordsIncluded': false,
    'preciseLocationIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripCommercialReadinessSummaryValidation {
  const TripCommercialReadinessSummaryValidation._({
    required this.isRenderable,
    required this.reasons,
  });

  factory TripCommercialReadinessSummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    if (summary['schemaVersion'] != 1) reasons.add('unsupported_schema');
    if (_safeStatus(summary['status']) == null) {
      reasons.add('invalid_commercial_status');
    }
    if (_safeScenario(summary['scenario']) == null) {
      reasons.add('invalid_commercial_scenario');
    }
    if (_safeReason(summary['reasonCode']?.toString() ?? '') !=
        summary['reasonCode']) {
      reasons.add('invalid_commercial_reason');
    }
    for (final key in const [
      'canStartOrContinueTrip',
      'manualReviewRecommended',
      'mapsOptionalAndSafe',
      'employeePrivacySafe',
      'gpsAssistedTrackingAvailableWithoutMaps',
      'mapsRequiredForTripTracking',
      'mapboxFailureCannotBlockGpsOnlyTrip',
      'mapboxAssistRequiresExplicitOptIn',
      'mapboxCanReplaceOdometer',
      'mapboxCanCreateOfficialStop',
      'mapboxCanEndTrip',
      'profileStrategyCanEndTripAutomatically',
      'activityRecognitionCanCreateOfficialStop',
      'gpsAccuracyStillRequiresFieldProof',
      'commercialReadyDoesNotMeanProductionReady',
      'limitedGpsOnlyCanStartWithoutMaps',
      'realDeviceEvidenceRequiredForDependabilityClaim',
      'stopReviewRequiredBeforeOfficialStop',
      'confirmedMileageRequiresUserAction',
      'odometerIsGlobalTruth',
      'odometerRemainsOfficialMileageTruth',
      'commercialReadinessCanSetGlobalTruth',
      'commercialReadinessCanChangeOfficialMileage',
      'poorGpsCalibrationProofRequired',
      'calibrationRequiresTrustedGpsWindow',
      'poorGpsDaysExcludedFromCalibration',
      'calibrationCanCreateOfficialMileage',
      'hiveRemainsOperationalSourceOfTruth',
      'firestoreMirrorOnly',
      'employeeTrackingRequiresMutualConsent',
      'employerGodModeAllowed',
      'remoteDataCanOverrideLocalTrip',
      'authenticatedRemoteDataStillRequiresAuthorization',
      'commercialRollupCanDeleteLocalData',
      'rawTripRecordsIncluded',
      'preciseLocationIncluded',
      'routeGeometryIncluded',
      'tokensIncluded',
    ]) {
      if (summary[key] is! bool) reasons.add('${key}_not_bool');
    }
    if (summary['gpsAssistedTrackingAvailableWithoutMaps'] != true ||
        summary['mapsRequiredForTripTracking'] != false ||
        summary['mapboxFailureCannotBlockGpsOnlyTrip'] != true ||
        summary['mapboxAssistRequiresExplicitOptIn'] != true ||
        summary['limitedGpsOnlyCanStartWithoutMaps'] != true) {
      reasons.add('maps_optional_boundary_missing');
    }
    if (summary['mapboxCanReplaceOdometer'] != false ||
        summary['mapboxCanCreateOfficialStop'] != false ||
        summary['mapboxCanEndTrip'] != false ||
        summary['profileStrategyCanEndTripAutomatically'] != false ||
        summary['activityRecognitionCanCreateOfficialStop'] != false ||
        summary['stopReviewRequiredBeforeOfficialStop'] != true ||
        summary['confirmedMileageRequiresUserAction'] != true ||
        summary['odometerIsGlobalTruth'] != true ||
        summary['odometerRemainsOfficialMileageTruth'] != true ||
        summary['commercialReadinessCanSetGlobalTruth'] != false ||
        summary['commercialReadinessCanChangeOfficialMileage'] != false) {
      reasons.add('commercial_claims_trip_truth_authority');
    }
    if (summary['gpsAccuracyStillRequiresFieldProof'] != true ||
        summary['commercialReadyDoesNotMeanProductionReady'] != true ||
        summary['realDeviceEvidenceRequiredForDependabilityClaim'] != true ||
        summary['poorGpsCalibrationProofRequired'] != true ||
        summary['calibrationRequiresTrustedGpsWindow'] != true ||
        summary['poorGpsDaysExcludedFromCalibration'] != true ||
        summary['calibrationCanCreateOfficialMileage'] != false) {
      reasons.add('commercial_evidence_boundary_missing');
    }
    if (summary['hiveRemainsOperationalSourceOfTruth'] != true ||
        summary['firestoreMirrorOnly'] != true ||
        summary['remoteDataCanOverrideLocalTrip'] != false ||
        summary['authenticatedRemoteDataStillRequiresAuthorization'] != true ||
        summary['commercialRollupCanDeleteLocalData'] != false) {
      reasons.add('commercial_remote_authority_boundary_missing');
    }
    if (summary['employeeTrackingRequiresMutualConsent'] != true ||
        summary['employerGodModeAllowed'] != false) {
      reasons.add('commercial_privacy_boundary_missing');
    }
    if (summary['rawTripRecordsIncluded'] != false ||
        summary['preciseLocationIncluded'] != false ||
        summary['routeGeometryIncluded'] != false ||
        summary['tokensIncluded'] != false ||
        summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_commercial_material');
    }
    return TripCommercialReadinessSummaryValidation._(
      isRenderable: reasons.isEmpty,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final List<String> reasons;
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

TripCommercialReadinessStatus? _safeStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripCommercialReadinessStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

TripCommercialDriverScenario? _safeScenario(Object? value) {
  if (value is! String) return null;
  for (final scenario in TripCommercialDriverScenario.values) {
    if (scenario.name == value) return scenario;
  }
  return null;
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      clean.contains('token=') ||
      clean.contains(RegExp(r'-?\d{1,3}\.\d{4,}\s*,\s*-?\d{1,3}\.\d{4,}'));
}
