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
    required this.acceptedDistanceMeters,
    required this.maximumGapSeconds,
    required this.canFeedLiveOdometerProjection,
    required this.canPersistCompactRoutePoint,
  });

  final TripSampleWindowQualityStatus status;
  final String reasonCode;
  final int validSampleCount;
  final int rejectedSampleCount;
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
    'acceptedDistanceBucket': _distanceBucket(acceptedDistanceMeters),
    'maximumGapSeconds': _safeGap(maximumGapSeconds),
    'canFeedLiveOdometerProjection': canFeedLiveOdometerProjection,
    'canPersistCompactRoutePoint': canPersistCompactRoutePoint,
    'gpsAssistedTrackingAvailableWithoutMaps': true,
    'mapsRequiredForGpsTracking': false,
    'routeStorageOptional': true,
    'routeStorageCanPauseWithoutStoppingTrip': true,
    'sampleWindowCanConfirmOdometer': false,
    'sampleWindowCanCreateOfficialStop': false,
    'sampleWindowCanDeleteTripData': false,
    'mapboxCanOverrideWindowQuality': false,
    'firestoreCanOverrideWindowQuality': false,
    'remoteWindowCanOverrideLocalTrip': false,
    'odometerRemainsOfficialMileageTruth': true,
    'hiveRemainsOperationalSourceOfTruth': true,
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
    int persistedRoutePointsToday = 0,
    int maximumAcceptedGapSeconds = 180,
    double maximumAccuracyMeters = 120,
    double maximumPointJumpMeters = 2500,
  }) {
    final safeGapLimit = _safeGap(maximumAcceptedGapSeconds).clamp(30, 600);
    final safeAccuracy = _safeAccuracy(maximumAccuracyMeters);
    final safeJump = _safeJump(maximumPointJumpMeters);
    final sorted =
        samples
            .where((sample) => _isIndividuallySafe(sample, safeAccuracy))
            .toList()
          ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final rejected = samples.length - sorted.length;

    if (samples.isEmpty) {
      return _decision(
        status: TripSampleWindowQualityStatus.noSamples,
        reasonCode: 'sample_window_empty',
        validSampleCount: 0,
        rejectedSampleCount: 0,
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
        acceptedDistanceMeters: 0,
        maximumGapSeconds: 0,
        canFeedLiveOdometerProjection: false,
        canPersistCompactRoutePoint: false,
      );
    }

    var acceptedDistance = 0.0;
    var rejectedSegments = 0;
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
      if (gapSeconds <= 0 ||
          gapSeconds > safeGapLimit ||
          distance > safeJump ||
          _impossibleSegmentSpeed(distance, gapSeconds)) {
        rejectedSegments += 1;
        continue;
      }
      acceptedDistance += distance;
    }

    if (rejectedSegments >= sorted.length - 1) {
      return _decision(
        status: TripSampleWindowQualityStatus.unsafeRejected,
        reasonCode: 'sample_window_segments_rejected',
        validSampleCount: sorted.length,
        rejectedSampleCount: rejected + rejectedSegments,
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
    if (!routePointAllowed && routeHistoryDecision.canCaptureRouteHistory) {
      return _decision(
        status: TripSampleWindowQualityStatus.routeStoragePaused,
        reasonCode: 'route_storage_budget_paused',
        validSampleCount: sorted.length,
        rejectedSampleCount: rejected + rejectedSegments,
        acceptedDistanceMeters: acceptedDistance,
        maximumGapSeconds: maximumGap,
        canFeedLiveOdometerProjection: acceptedDistance > 0,
        canPersistCompactRoutePoint: false,
      );
    }

    final degraded = maximumGap > safeGapLimit || rejectedSegments > 0;
    return _decision(
      status: degraded
          ? TripSampleWindowQualityStatus.degradedTrackingOnly
          : TripSampleWindowQualityStatus.usableForTracking,
      reasonCode: degraded
          ? 'sample_window_degraded_but_usable'
          : 'sample_window_usable',
      validSampleCount: sorted.length,
      rejectedSampleCount: rejected + rejectedSegments,
      acceptedDistanceMeters: acceptedDistance,
      maximumGapSeconds: maximumGap,
      canFeedLiveOdometerProjection: acceptedDistance > 0,
      canPersistCompactRoutePoint: routePointAllowed,
    );
  }
}

TripSampleWindowQualityDecision _decision({
  required TripSampleWindowQualityStatus status,
  required String reasonCode,
  required int validSampleCount,
  required int rejectedSampleCount,
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
    acceptedDistanceMeters: acceptedDistanceMeters.isFinite
        ? acceptedDistanceMeters.clamp(0, 1000000).toDouble()
        : 0,
    maximumGapSeconds: _safeGap(maximumGapSeconds),
    canFeedLiveOdometerProjection: canFeedLiveOdometerProjection,
    canPersistCompactRoutePoint: canPersistCompactRoutePoint,
  );
}

bool _isIndividuallySafe(TripLocationSample sample, double maxAccuracy) {
  if (!sample.hasValidCoordinate || !sample.hasValidAccuracy) return false;
  if (sample.mockedLocation == true) return false;
  if (sample.horizontalAccuracyMeters > maxAccuracy) return false;
  final speed = sample.speedMetersPerSecond;
  return speed == null || (speed.isFinite && speed >= 0 && speed <= 70);
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
    'sample_window_usable' => 'sample_window_usable',
    _ => 'sample_window_segments_rejected',
  };
}
