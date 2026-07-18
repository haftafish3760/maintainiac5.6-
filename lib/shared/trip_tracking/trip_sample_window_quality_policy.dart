import 'dart:math' as math;

import 'trip_route_history_capture_policy.dart';
import 'trip_tracking_models.dart';
import 'trip_tracking_signal_quality.dart';

enum TripSampleWindowQualityStatus {
  noSamples,
  usableForTracking,
  degradedTrackingOnly,
  routeStoragePaused,
  unsafeRejected,
}

class TripSampleWindowQualityDecision {
  const TripSampleWindowQualityDecision({
    required this.status,
    required this.reasonCode,
    required this.validSampleCount,
    required this.rejectedSampleCount,
    required this.acceptedSegmentCount,
    required this.rejectedGapSegmentCount,
    required this.rejectedJumpSegmentCount,
    required this.rejectedSpeedSegmentCount,
    required this.maximumConsecutiveRejectedSegments,
    required this.acceptedDistanceMeters,
    required this.maximumGapSeconds,
    required this.canFeedLiveOdometerProjection,
    required this.canPersistCompactRoutePoint,
  });

  final TripSampleWindowQualityStatus status;
  final String reasonCode;
  final int validSampleCount;
  final int rejectedSampleCount;
  final int acceptedSegmentCount;
  final int rejectedGapSegmentCount;
  final int rejectedJumpSegmentCount;
  final int rejectedSpeedSegmentCount;
  final int maximumConsecutiveRejectedSegments;
  final double acceptedDistanceMeters;
  final int maximumGapSeconds;
  final bool canFeedLiveOdometerProjection;
  final bool canPersistCompactRoutePoint;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'reasonCode': _safeReason(reasonCode),
    'validSampleCount': _safeCount(validSampleCount),
    'rejectedSampleCount': _safeCount(rejectedSampleCount),
    'acceptedSegmentCount': _safeCount(acceptedSegmentCount),
    'rejectedGapSegmentCount': _safeCount(rejectedGapSegmentCount),
    'rejectedJumpSegmentCount': _safeCount(rejectedJumpSegmentCount),
    'rejectedSpeedSegmentCount': _safeCount(rejectedSpeedSegmentCount),
    'maximumConsecutiveRejectedSegments': _safeCount(
      maximumConsecutiveRejectedSegments,
    ),
    'acceptedDistanceBucket': _distanceBucket(acceptedDistanceMeters),
    'maximumGapSeconds': _safeGap(maximumGapSeconds),
    'canFeedLiveOdometerProjection': canFeedLiveOdometerProjection,
    'canPersistCompactRoutePoint': canPersistCompactRoutePoint,
    'gpsAssistedTrackingAvailableWithoutMaps': true,
    'mapsRequiredForGpsTracking': false,
    'routeStorageOptional': true,
    'routeStorageCanPauseWithoutStoppingTrip': true,
    'sampleWindowRequiresTrustedGpsSignal': true,
    'poorGpsPausesLiveProjection': true,
    'interruptedGpsPausesLiveProjection': true,
    'missingGpsPausesLiveProjection': true,
    'unsafeGpsBlocksSampleWindow': true,
    'projectionPausesOnSparseOrBrokenWindow': true,
    'segmentRejectionReasonsCounted': true,
    'sampleWindowRequiresLocalDeviceSource': true,
    'sampleWindowRequiresOwnershipValidation': true,
    'sampleWindowRequiresIntakeGuardBeforeEvaluation': true,
    'sampleWindowRequiresDeviceCapabilityContext': true,
    'sampleWindowRequiresMonotonicSampleOrder': true,
    'sampleWindowRequiresMovementCorroboration': true,
    'sampleWindowRequiresPermissionContinuity': true,
    'simulatorWindowRequiresExplicitTestHarness': true,
    'simulatorWindowCannotWriteProductionHistory': true,
    'authenticationAloneAuthorizesWindowUse': false,
    'sampleWindowCanConfirmOdometer': false,
    'sampleWindowCanSetGlobalTruth': false,
    'sampleWindowCanChangeOfficialMileage': false,
    'sampleWindowCanCreateOfficialStop': false,
    'sampleWindowCanBypassStopDebounce': false,
    'sampleWindowCanAutocorrectCalibration': false,
    'sampleWindowCanDeleteTripData': false,
    'mapboxCanOverrideWindowQuality': false,
    'firestoreCanOverrideWindowQuality': false,
    'remoteWindowCanOverrideLocalTrip': false,
    'remoteWindowCanRepairInvalidSamples': false,
    'mapboxCanFillSampleGaps': false,
    'cloudFunctionCanRepairSampleWindow': false,
    'odometerRemainsOfficialMileageTruth': true,
    'odometerIsGlobalTruth': true,
    'hiveRemainsOperationalSourceOfTruth': true,
    'sampleTimestampsValidated': true,
    'duplicateOrOutOfOrderSegmentsRejected': true,
    'futureSamplesRejected': true,
    'staleSamplesRejectedWhenEvaluationClockProvided': true,
    'rawSamplesIncluded': false,
    'coordinatesIncluded': false,
    'preciseTimestampsIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

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

class TripSampleWindowQualityPolicy {
  const TripSampleWindowQualityPolicy._();

  static TripSampleWindowQualityDecision evaluate({
    required List<TripLocationSample> samples,
    required TripRouteHistoryCaptureDecision routeHistoryDecision,
    TripTrackingSignalQuality signalQuality = TripTrackingSignalQuality.healthy,
    DateTime? evaluationNow,
    int persistedRoutePointsToday = 0,
    int maximumAcceptedGapSeconds = 180,
    double maximumAccuracyMeters = 120,
    double maximumPointJumpMeters = 2500,
    Duration maximumSampleAge = const Duration(hours: 18),
    Duration maximumFutureSkew = const Duration(minutes: 2),
  }) {
    final safeGapLimit = _safeGap(maximumAcceptedGapSeconds).clamp(30, 600);
    final safeAccuracy = _safeAccuracy(maximumAccuracyMeters);
    final safeJump = _safeJump(maximumPointJumpMeters);
    final safeNow = evaluationNow?.toUtc();
    final safeMaximumAge = _safeDuration(
      maximumSampleAge,
      fallback: const Duration(hours: 18),
      minimum: const Duration(minutes: 5),
      maximum: const Duration(days: 2),
    );
    final safeFutureSkew = _safeDuration(
      maximumFutureSkew,
      fallback: const Duration(minutes: 2),
      minimum: Duration.zero,
      maximum: const Duration(hours: 1),
    );
    if (signalQuality == TripTrackingSignalQuality.unsafe) {
      return _decision(
        status: TripSampleWindowQualityStatus.unsafeRejected,
        reasonCode: 'sample_window_unsafe_gps_signal',
        validSampleCount: 0,
        rejectedSampleCount: samples.length,
        acceptedSegmentCount: 0,
        rejectedGapSegmentCount: 0,
        rejectedJumpSegmentCount: 0,
        rejectedSpeedSegmentCount: 0,
        maximumConsecutiveRejectedSegments: 0,
        acceptedDistanceMeters: 0,
        maximumGapSeconds: 0,
        canFeedLiveOdometerProjection: false,
        canPersistCompactRoutePoint: false,
      );
    }
    final trustedSignal = _trustedSignalForProjection(signalQuality);
    final sorted = samples.where((sample) {
      return _isIndividuallySafe(
        sample,
        safeAccuracy,
        evaluationNow: safeNow,
        maximumSampleAge: safeMaximumAge,
        maximumFutureSkew: safeFutureSkew,
      );
    }).toList()..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final rejected = samples.length - sorted.length;

    if (samples.isEmpty) {
      return _decision(
        status: TripSampleWindowQualityStatus.noSamples,
        reasonCode: 'sample_window_empty',
        validSampleCount: 0,
        rejectedSampleCount: 0,
        acceptedSegmentCount: 0,
        rejectedGapSegmentCount: 0,
        rejectedJumpSegmentCount: 0,
        rejectedSpeedSegmentCount: 0,
        maximumConsecutiveRejectedSegments: 0,
        acceptedDistanceMeters: 0,
        maximumGapSeconds: 0,
        canFeedLiveOdometerProjection: false,
        canPersistCompactRoutePoint: false,
      );
    }
    if (sorted.length < 2) {
      return _decision(
        status: TripSampleWindowQualityStatus.degradedTrackingOnly,
        reasonCode: 'sample_window_needs_more_valid_points',
        validSampleCount: sorted.length,
        rejectedSampleCount: rejected,
        acceptedSegmentCount: 0,
        rejectedGapSegmentCount: 0,
        rejectedJumpSegmentCount: 0,
        rejectedSpeedSegmentCount: 0,
        maximumConsecutiveRejectedSegments: 0,
        acceptedDistanceMeters: 0,
        maximumGapSeconds: 0,
        canFeedLiveOdometerProjection: false,
        canPersistCompactRoutePoint: false,
      );
    }

    var acceptedDistance = 0.0;
    var acceptedSegments = 0;
    var rejectedSegments = 0;
    var rejectedGapSegments = 0;
    var rejectedJumpSegments = 0;
    var rejectedSpeedSegments = 0;
    var consecutiveRejectedSegments = 0;
    var maximumConsecutiveRejectedSegments = 0;
    var maximumGap = 0;
    for (var index = 1; index < sorted.length; index += 1) {
      final previous = sorted[index - 1];
      final current = sorted[index];
      final gapSeconds = current.recordedAt
          .toUtc()
          .difference(previous.recordedAt.toUtc())
          .inSeconds;
      maximumGap = math.max(maximumGap, gapSeconds);
      final distance = _distanceMeters(previous, current);
      final rejectedForGap = gapSeconds <= 0 || gapSeconds > safeGapLimit;
      final rejectedForJump = distance > safeJump;
      final rejectedForSpeed = _impossibleSegmentSpeed(distance, gapSeconds);
      if (rejectedForGap || rejectedForJump || rejectedForSpeed) {
        rejectedSegments += 1;
        if (rejectedForGap) rejectedGapSegments += 1;
        if (rejectedForJump) rejectedJumpSegments += 1;
        if (rejectedForSpeed) rejectedSpeedSegments += 1;
        consecutiveRejectedSegments += 1;
        maximumConsecutiveRejectedSegments = math.max(
          maximumConsecutiveRejectedSegments,
          consecutiveRejectedSegments,
        );
        continue;
      }
      acceptedSegments += 1;
      consecutiveRejectedSegments = 0;
      acceptedDistance += distance;
    }

    if (rejectedSegments >= sorted.length - 1) {
      return _decision(
        status: TripSampleWindowQualityStatus.unsafeRejected,
        reasonCode: 'sample_window_segments_rejected',
        validSampleCount: sorted.length,
        rejectedSampleCount: rejected + rejectedSegments,
        acceptedSegmentCount: acceptedSegments,
        rejectedGapSegmentCount: rejectedGapSegments,
        rejectedJumpSegmentCount: rejectedJumpSegments,
        rejectedSpeedSegmentCount: rejectedSpeedSegments,
        maximumConsecutiveRejectedSegments: maximumConsecutiveRejectedSegments,
        acceptedDistanceMeters: 0,
        maximumGapSeconds: maximumGap,
        canFeedLiveOdometerProjection: false,
        canPersistCompactRoutePoint: false,
      );
    }

    final routePointAllowed = _routePointAllowed(
      routeHistoryDecision,
      persistedRoutePointsToday,
    );
    final stationaryContradiction = _reportedStationaryContradictsDistance(
      sorted,
      acceptedDistance,
    );
    final projectionSafe =
        _canFeedProjection(
          acceptedSegments: acceptedSegments,
          rejectedSegments: rejectedSegments,
          maximumConsecutiveRejectedSegments:
              maximumConsecutiveRejectedSegments,
          maximumGap: maximumGap,
          safeGapLimit: safeGapLimit,
          acceptedDistanceMeters: acceptedDistance,
        ) &&
        !stationaryContradiction &&
        trustedSignal;
    if (!routePointAllowed && routeHistoryDecision.canCaptureRouteHistory) {
      return _decision(
        status: TripSampleWindowQualityStatus.routeStoragePaused,
        reasonCode: 'route_storage_budget_paused',
        validSampleCount: sorted.length,
        rejectedSampleCount: rejected + rejectedSegments,
        acceptedSegmentCount: acceptedSegments,
        rejectedGapSegmentCount: rejectedGapSegments,
        rejectedJumpSegmentCount: rejectedJumpSegments,
        rejectedSpeedSegmentCount: rejectedSpeedSegments,
        maximumConsecutiveRejectedSegments: maximumConsecutiveRejectedSegments,
        acceptedDistanceMeters: acceptedDistance,
        maximumGapSeconds: maximumGap,
        canFeedLiveOdometerProjection: projectionSafe,
        canPersistCompactRoutePoint: false,
      );
    }

    final degraded =
        maximumGap > safeGapLimit || rejectedSegments > 0 || rejected > 0;
    final sparseOrBroken = acceptedDistance > 0 && !projectionSafe;
    return _decision(
      status: degraded
          ? TripSampleWindowQualityStatus.degradedTrackingOnly
          : TripSampleWindowQualityStatus.usableForTracking,
      reasonCode: sparseOrBroken
          ? 'sample_window_projection_paused'
          : stationaryContradiction
          ? 'sample_window_projection_paused'
          : degraded
          ? 'sample_window_degraded_but_usable'
          : 'sample_window_usable',
      validSampleCount: sorted.length,
      rejectedSampleCount: rejected + rejectedSegments,
      acceptedSegmentCount: acceptedSegments,
      rejectedGapSegmentCount: rejectedGapSegments,
      rejectedJumpSegmentCount: rejectedJumpSegments,
      rejectedSpeedSegmentCount: rejectedSpeedSegments,
      maximumConsecutiveRejectedSegments: maximumConsecutiveRejectedSegments,
      acceptedDistanceMeters: acceptedDistance,
      maximumGapSeconds: maximumGap,
      canFeedLiveOdometerProjection: projectionSafe,
      canPersistCompactRoutePoint:
          routePointAllowed && trustedSignal && !stationaryContradiction,
    );
  }
}

TripSampleWindowQualityDecision _decision({
  required TripSampleWindowQualityStatus status,
  required String reasonCode,
  required int validSampleCount,
  required int rejectedSampleCount,
  required int acceptedSegmentCount,
  required int rejectedGapSegmentCount,
  required int rejectedJumpSegmentCount,
  required int rejectedSpeedSegmentCount,
  required int maximumConsecutiveRejectedSegments,
  required double acceptedDistanceMeters,
  required int maximumGapSeconds,
  required bool canFeedLiveOdometerProjection,
  required bool canPersistCompactRoutePoint,
}) {
  return TripSampleWindowQualityDecision(
    status: status,
    reasonCode: reasonCode,
    validSampleCount: _safeCount(validSampleCount),
    rejectedSampleCount: _safeCount(rejectedSampleCount),
    acceptedSegmentCount: _safeCount(acceptedSegmentCount),
    rejectedGapSegmentCount: _safeCount(rejectedGapSegmentCount),
    rejectedJumpSegmentCount: _safeCount(rejectedJumpSegmentCount),
    rejectedSpeedSegmentCount: _safeCount(rejectedSpeedSegmentCount),
    maximumConsecutiveRejectedSegments: _safeCount(
      maximumConsecutiveRejectedSegments,
    ),
    acceptedDistanceMeters: acceptedDistanceMeters.isFinite
        ? acceptedDistanceMeters.clamp(0, 1000000).toDouble()
        : 0,
    maximumGapSeconds: _safeGap(maximumGapSeconds),
    canFeedLiveOdometerProjection: canFeedLiveOdometerProjection,
    canPersistCompactRoutePoint: canPersistCompactRoutePoint,
  );
}

bool _canFeedProjection({
  required int acceptedSegments,
  required int rejectedSegments,
  required int maximumConsecutiveRejectedSegments,
  required int maximumGap,
  required int safeGapLimit,
  required double acceptedDistanceMeters,
}) {
  if (acceptedDistanceMeters <= 0 || acceptedSegments <= 0) return false;
  if (maximumGap > safeGapLimit * 3) return false;
  if (maximumConsecutiveRejectedSegments >= 3) return false;
  if (rejectedSegments > acceptedSegments * 2) return false;
  return true;
}

bool _reportedStationaryContradictsDistance(
  List<TripLocationSample> samples,
  double acceptedDistanceMeters,
) {
  if (acceptedDistanceMeters < 75 || samples.length < 2) return false;
  final reportedSpeeds = samples
      .map((sample) => sample.speedMetersPerSecond)
      .whereType<double>()
      .where((speed) => speed.isFinite)
      .toList(growable: false);
  if (reportedSpeeds.length < samples.length) return false;
  return reportedSpeeds.every((speed) => speed <= 0.5);
}

bool _isIndividuallySafe(
  TripLocationSample sample,
  double maxAccuracy, {
  required DateTime? evaluationNow,
  required Duration maximumSampleAge,
  required Duration maximumFutureSkew,
}) {
  if (!sample.hasValidCoordinate || !sample.hasValidAccuracy) return false;
  if (sample.mockedLocation == true) return false;
  if (sample.horizontalAccuracyMeters > maxAccuracy) return false;
  if (!_hasSafeTimestamp(
    sample.recordedAt,
    evaluationNow: evaluationNow,
    maximumSampleAge: maximumSampleAge,
    maximumFutureSkew: maximumFutureSkew,
  )) {
    return false;
  }
  final speed = sample.speedMetersPerSecond;
  return speed == null || (speed.isFinite && speed >= 0 && speed <= 70);
}

bool _hasSafeTimestamp(
  DateTime recordedAt, {
  required DateTime? evaluationNow,
  required Duration maximumSampleAge,
  required Duration maximumFutureSkew,
}) {
  if (recordedAt.millisecondsSinceEpoch == 0) return false;
  if (evaluationNow == null) return true;
  final age = evaluationNow.difference(recordedAt.toUtc());
  if (age < -maximumFutureSkew) return false;
  if (age > maximumSampleAge) return false;
  return true;
}

bool _routePointAllowed(
  TripRouteHistoryCaptureDecision decision,
  int persistedRoutePointsToday,
) {
  if (!decision.canCaptureRouteHistory) return false;
  if (decision.maximumRetainedPointsPerDay <= 0) return false;
  final persisted = _safeCount(persistedRoutePointsToday);
  return persisted < decision.maximumRetainedPointsPerDay;
}

bool _impossibleSegmentSpeed(double distanceMeters, int gapSeconds) {
  if (gapSeconds <= 0) return true;
  return distanceMeters / gapSeconds > 70;
}

bool _trustedSignalForProjection(TripTrackingSignalQuality quality) {
  return switch (quality) {
    TripTrackingSignalQuality.healthy ||
    TripTrackingSignalQuality.reduced => true,
    TripTrackingSignalQuality.noSamples ||
    TripTrackingSignalQuality.poor ||
    TripTrackingSignalQuality.interrupted ||
    TripTrackingSignalQuality.unsafe => false,
  };
}

double _distanceMeters(TripLocationSample a, TripLocationSample b) {
  const earthRadiusMeters = 6371000.0;
  final dLat = _radians(b.latitude - a.latitude);
  final dLon = _radians(b.longitude - a.longitude);
  final lat1 = _radians(a.latitude);
  final lat2 = _radians(b.latitude);
  final haversine =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
  return earthRadiusMeters *
      2 *
      math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
}

double _radians(double degrees) => degrees * math.pi / 180;

int _safeCount(int value) {
  if (value <= 0) return 0;
  return value > 1000000 ? 1000000 : value;
}

int _safeGap(int value) {
  if (value <= 0) return 0;
  return value > 86400 ? 86400 : value;
}

double _safeAccuracy(double value) {
  if (!value.isFinite || value <= 0) return 120;
  return value.clamp(5, 500).toDouble();
}

double _safeJump(double value) {
  if (!value.isFinite || value <= 0) return 2500;
  return value.clamp(25, 10000).toDouble();
}

Duration _safeDuration(
  Duration value, {
  required Duration fallback,
  required Duration minimum,
  required Duration maximum,
}) {
  if (value.isNegative) return fallback;
  if (value < minimum) return minimum;
  if (value > maximum) return maximum;
  return value;
}

String _distanceBucket(double meters) {
  if (!meters.isFinite || meters <= 0) return 'none';
  if (meters < 100) return 'under_100m';
  if (meters < 1000) return '100m_to_1km';
  if (meters < 10000) return '1km_to_10km';
  return 'over_10km';
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

TripSampleWindowQualityStatus? _safeStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripSampleWindowQualityStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      RegExp(r'-?\d{1,3}\.\d{4,}\s*,\s*-?\d{1,3}\.\d{4,}').hasMatch(clean);
}
