part of 'trip_sample_window_quality_policy.dart';

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
  if (acceptedSegments < 2 && rejectedSegments > 0) return false;
  if (rejectedSegments >= acceptedSegments) return false;
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
  return speed == null ||
      (speed.isFinite &&
          speed >= 0 &&
          speed <= _maximumCredibleGpsSpeedMetersPerSecond);
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
  return distanceMeters / gapSeconds > _maximumCredibleGpsSpeedMetersPerSecond;
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

const _maximumCredibleGpsSpeedMetersPerSecond = 70.0;
