import 'dart:math' as math;

import 'trip_route_history_capture_policy.dart';
import 'trip_tracking_models.dart';

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
    'projectionPausesOnSparseOrBrokenWindow': true,
    'segmentRejectionReasonsCounted': true,
    'sampleWindowCanConfirmOdometer': false,
    'sampleWindowCanCreateOfficialStop': false,
    'sampleWindowCanDeleteTripData': false,
    'mapboxCanOverrideWindowQuality': false,
    'firestoreCanOverrideWindowQuality': false,
    'remoteWindowCanOverrideLocalTrip': false,
    'remoteWindowCanRepairInvalidSamples': false,
    'odometerRemainsOfficialMileageTruth': true,
    'hiveRemainsOperationalSourceOfTruth': true,
    'sampleTimestampsValidated': true,
    'futureSamplesRejected': true,
    'staleSamplesRejectedWhenEvaluationClockProvided': true,
    'rawSamplesIncluded': false,
    'coordinatesIncluded': false,
    'preciseTimestampsIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripSampleWindowQualityPolicy {
  const TripSampleWindowQualityPolicy._();

  static TripSampleWindowQualityDecision evaluate({
    required List<TripLocationSample> samples,
    required TripRouteHistoryCaptureDecision routeHistoryDecision,
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
    final projectionSafe = _canFeedProjection(
      acceptedSegments: acceptedSegments,
      rejectedSegments: rejectedSegments,
      maximumConsecutiveRejectedSegments: maximumConsecutiveRejectedSegments,
      maximumGap: maximumGap,
      safeGapLimit: safeGapLimit,
      acceptedDistanceMeters: acceptedDistance,
    );
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
      canPersistCompactRoutePoint: routePointAllowed,
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
    'route_storage_budget_paused' => 'route_storage_budget_paused',
    'sample_window_degraded_but_usable' => 'sample_window_degraded_but_usable',
    'sample_window_projection_paused' => 'sample_window_projection_paused',
    'sample_window_usable' => 'sample_window_usable',
    _ => 'sample_window_segments_rejected',
  };
}
