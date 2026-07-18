import 'trip_sample_window_quality_policy.dart';

class TripSampleWindowQualitySummaryValidation {
  const TripSampleWindowQualitySummaryValidation._({
    required this.isRenderable,
    required this.status,
    required this.reasons,
  });

  factory TripSampleWindowQualitySummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    final status = _safeStatus(summary['status']);
    final reason = summary['reasonCode'];
    if (summary['schemaVersion'] != 1) {
      reasons.add('unsupported_schema_version');
    }
    if (status == null) reasons.add('invalid_sample_window_status');
    if (reason is! String || _safeReason(reason) != reason) {
      reasons.add('invalid_sample_window_reason');
    }
    for (final key in const [
      'validSampleCount',
      'rejectedSampleCount',
      'acceptedSegmentCount',
      'rejectedGapSegmentCount',
      'rejectedJumpSegmentCount',
      'rejectedSpeedSegmentCount',
      'maximumConsecutiveRejectedSegments',
      'maximumGapSeconds',
    ]) {
      if (summary[key] is! int || (summary[key] as int) < 0) {
        reasons.add('${key}_invalid');
      }
    }
    if (summary['acceptedDistanceBucket'] is! String ||
        !const {
          'none',
          'under_100m',
          '100m_to_1km',
          '1km_to_10km',
          'over_10km',
        }.contains(summary['acceptedDistanceBucket'])) {
      reasons.add('invalid_accepted_distance_bucket');
    }
    for (final key in const [
      'canFeedLiveOdometerProjection',
      'canPersistCompactRoutePoint',
      'gpsAssistedTrackingAvailableWithoutMaps',
      'routeStorageOptional',
      'routeStorageCanPauseWithoutStoppingTrip',
      'sampleWindowRequiresTrustedGpsSignal',
      'poorGpsPausesLiveProjection',
      'interruptedGpsPausesLiveProjection',
      'missingGpsPausesLiveProjection',
      'unsafeGpsBlocksSampleWindow',
      'projectionPausesOnSparseOrBrokenWindow',
      'segmentRejectionReasonsCounted',
      'odometerRemainsOfficialMileageTruth',
      'odometerIsGlobalTruth',
      'hiveRemainsOperationalSourceOfTruth',
      'sampleTimestampsValidated',
      'duplicateOrOutOfOrderSegmentsRejected',
      'futureSamplesRejected',
      'staleSamplesRejectedWhenEvaluationClockProvided',
      'sampleWindowRequiresLocalDeviceSource',
      'sampleWindowRequiresOwnershipValidation',
      'sampleWindowRequiresIntakeGuardBeforeEvaluation',
      'sampleWindowRequiresDeviceCapabilityContext',
      'sampleWindowRequiresMonotonicSampleOrder',
      'sampleWindowRequiresMovementCorroboration',
      'sampleWindowRequiresPermissionContinuity',
      'simulatorWindowRequiresExplicitTestHarness',
      'simulatorWindowCannotWriteProductionHistory',
      'authenticationAloneAuthorizesWindowUse',
      'sampleWindowCanConfirmOdometer',
      'sampleWindowCanSetGlobalTruth',
      'sampleWindowCanChangeOfficialMileage',
      'sampleWindowCanCreateOfficialStop',
      'sampleWindowCanBypassStopDebounce',
      'sampleWindowCanAutocorrectCalibration',
      'sampleWindowCanDeleteTripData',
    ]) {
      if (summary[key] is! bool) reasons.add('${key}_not_bool');
    }
    if (summary['gpsAssistedTrackingAvailableWithoutMaps'] != true ||
        summary['mapsRequiredForGpsTracking'] != false ||
        summary['routeStorageOptional'] != true ||
        summary['routeStorageCanPauseWithoutStoppingTrip'] != true) {
      reasons.add('gps_route_storage_boundary_missing');
    }
    if (summary['sampleWindowRequiresTrustedGpsSignal'] != true ||
        summary['poorGpsPausesLiveProjection'] != true ||
        summary['interruptedGpsPausesLiveProjection'] != true ||
        summary['missingGpsPausesLiveProjection'] != true ||
        summary['unsafeGpsBlocksSampleWindow'] != true) {
      reasons.add('sample_window_gps_quality_boundary_missing');
    }
    final boundaryRisk = _sampleWindowStatusBoundaryRisk(summary, status);
    if (boundaryRisk != null) reasons.add(boundaryRisk);
    if (summary['sampleWindowRequiresLocalDeviceSource'] != true ||
        summary['sampleWindowRequiresOwnershipValidation'] != true ||
        summary['sampleWindowRequiresIntakeGuardBeforeEvaluation'] != true ||
        summary['sampleWindowRequiresDeviceCapabilityContext'] != true ||
        summary['sampleWindowRequiresMonotonicSampleOrder'] != true ||
        summary['sampleWindowRequiresMovementCorroboration'] != true ||
        summary['sampleWindowRequiresPermissionContinuity'] != true ||
        summary['simulatorWindowRequiresExplicitTestHarness'] != true ||
        summary['simulatorWindowCannotWriteProductionHistory'] != true ||
        summary['authenticationAloneAuthorizesWindowUse'] != false) {
      reasons.add('sample_window_authorization_boundary_missing');
    }
    if (summary['sampleWindowCanConfirmOdometer'] != false ||
        summary['sampleWindowCanSetGlobalTruth'] != false ||
        summary['sampleWindowCanChangeOfficialMileage'] != false ||
        summary['sampleWindowCanCreateOfficialStop'] != false ||
        summary['sampleWindowCanBypassStopDebounce'] != false ||
        summary['sampleWindowCanAutocorrectCalibration'] != false ||
        summary['sampleWindowCanDeleteTripData'] != false ||
        summary['odometerRemainsOfficialMileageTruth'] != true ||
        summary['odometerIsGlobalTruth'] != true) {
      reasons.add('sample_window_claims_trip_truth_authority');
    }
    if (summary['mapboxCanOverrideWindowQuality'] != false ||
        summary['firestoreCanOverrideWindowQuality'] != false ||
        summary['remoteWindowCanOverrideLocalTrip'] != false ||
        summary['remoteWindowCanRepairInvalidSamples'] != false ||
        summary['mapboxCanFillSampleGaps'] != false ||
        summary['cloudFunctionCanRepairSampleWindow'] != false) {
      reasons.add('remote_can_override_sample_window');
    }
    if (summary['duplicateOrOutOfOrderSegmentsRejected'] != true ||
        summary['rawSamplesIncluded'] != false ||
        summary['coordinatesIncluded'] != false ||
        summary['preciseTimestampsIncluded'] != false ||
        summary['routeGeometryIncluded'] != false ||
        summary['tokensIncluded'] != false ||
        summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_sample_material');
    }
    return TripSampleWindowQualitySummaryValidation._(
      isRenderable: reasons.isEmpty,
      status: reasons.isEmpty ? status : null,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final TripSampleWindowQualityStatus? status;
  final List<String> reasons;
}

TripSampleWindowQualityStatus? _safeStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripSampleWindowQualityStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

String _safeReason(String value) {
  return switch (value.trim()) {
    'sample_window_empty' => 'sample_window_empty',
    'sample_window_needs_more_valid_points' =>
      'sample_window_needs_more_valid_points',
    'sample_window_segments_rejected' => 'sample_window_segments_rejected',
    'sample_window_unsafe_gps_signal' => 'sample_window_unsafe_gps_signal',
    'route_storage_budget_paused' => 'route_storage_budget_paused',
    'sample_window_degraded_but_usable' => 'sample_window_degraded_but_usable',
    'sample_window_projection_paused' => 'sample_window_projection_paused',
    'sample_window_usable' => 'sample_window_usable',
    _ => 'sample_window_segments_rejected',
  };
}

String? _sampleWindowStatusBoundaryRisk(
  Map<String, Object?> summary,
  TripSampleWindowQualityStatus? status,
) {
  final project = summary['canFeedLiveOdometerProjection'];
  final persist = summary['canPersistCompactRoutePoint'];
  final validSamples = summary['validSampleCount'];
  final acceptedSegments = summary['acceptedSegmentCount'];
  final rejectedGap = summary['rejectedGapSegmentCount'];
  final rejectedJump = summary['rejectedJumpSegmentCount'];
  final rejectedSpeed = summary['rejectedSpeedSegmentCount'];
  final reason = summary['reasonCode'];
  if (status == null ||
      project is! bool ||
      persist is! bool ||
      validSamples is! int ||
      acceptedSegments is! int ||
      rejectedGap is! int ||
      rejectedJump is! int ||
      rejectedSpeed is! int) {
    return null;
  }
  final anyRejected = rejectedGap > 0 || rejectedJump > 0 || rejectedSpeed > 0;
  final invalid = switch (status) {
    TripSampleWindowQualityStatus.noSamples =>
      project || persist || validSamples != 0 || acceptedSegments != 0,
    TripSampleWindowQualityStatus.unsafeRejected => project || persist,
    TripSampleWindowQualityStatus.routeStoragePaused => !project || persist,
    TripSampleWindowQualityStatus.degradedTrackingOnly => project || persist,
    TripSampleWindowQualityStatus.usableForTracking =>
      acceptedSegments <= 0 ||
          (!project && reason != 'sample_window_projection_paused') ||
          (anyRejected && persist),
  };
  return invalid ? 'sample_window_status_conflicts_with_authority' : null;
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      RegExp(r'-?\d{1,3}\.\d{4,}\s*,\s*-?\d{1,3}\.\d{4,}').hasMatch(clean);
}
