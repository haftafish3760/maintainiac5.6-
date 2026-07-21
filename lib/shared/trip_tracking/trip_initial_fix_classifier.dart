import 'dart:math' as math;

import 'trip_tracking_models.dart';

class TripInitialFixClassifier {
  const TripInitialFixClassifier({
    this.maximumFreshAge = const Duration(seconds: 30),
    this.maximumFutureSkew = const Duration(minutes: 2),
    this.preciseAccuracyMeters = 10,
    this.moderateAccuracyMeters = 35,
    this.maximumUsableAccuracyMeters = 100,
    this.maximumRelationshipSpeedMetersPerSecond = 90,
  });

  final Duration maximumFreshAge;
  final Duration maximumFutureSkew;
  final double preciseAccuracyMeters;
  final double moderateAccuracyMeters;
  final double maximumUsableAccuracyMeters;
  final double maximumRelationshipSpeedMetersPerSecond;

  TripInitialFixAssessment classify({
    required TripLocationSample? sample,
    required DateTime receivedAt,
    required bool locationServicesAvailable,
    required bool preciseLocationAuthorized,
    TripLocationSample? recentKnownLocation,
  }) {
    final assessedAt = receivedAt.toUtc();
    if (!locationServicesAvailable || sample == null) {
      return _result(TripInitialFixQuality.unavailable, assessedAt: assessedAt);
    }
    if (!preciseLocationAuthorized) {
      return _result(
        TripInitialFixQuality.approximateOnly,
        assessedAt: assessedAt,
        sample: sample,
      );
    }
    if (!sample.hasValidCoordinate ||
        !sample.hasValidAccuracy ||
        !sample.hasValidReportedSpeed ||
        !sample.hasValidReportedSpeedAccuracy) {
      return _result(
        TripInitialFixQuality.rejected,
        assessedAt: assessedAt,
        sample: sample,
      );
    }
    final age = assessedAt.difference(sample.recordedAt.toUtc());
    if (age < -maximumFutureSkew ||
        sample.horizontalAccuracyMeters > maximumUsableAccuracyMeters ||
        _relationshipIsImplausible(sample, recentKnownLocation)) {
      return _result(
        TripInitialFixQuality.rejected,
        assessedAt: assessedAt,
        sample: sample,
        age: age.isNegative ? Duration.zero : age,
      );
    }
    if (age > maximumFreshAge) {
      return _result(
        TripInitialFixQuality.staleCached,
        assessedAt: assessedAt,
        sample: sample,
        age: age,
      );
    }
    if (sample.horizontalAccuracyMeters <= preciseAccuracyMeters) {
      return _result(
        TripInitialFixQuality.freshPrecise,
        assessedAt: assessedAt,
        sample: sample,
        age: age.isNegative ? Duration.zero : age,
      );
    }
    if (sample.horizontalAccuracyMeters <= moderateAccuracyMeters) {
      return _result(
        TripInitialFixQuality.freshModerate,
        assessedAt: assessedAt,
        sample: sample,
        age: age.isNegative ? Duration.zero : age,
      );
    }
    return _result(
      TripInitialFixQuality.freshLowQuality,
      assessedAt: assessedAt,
      sample: sample,
      age: age.isNegative ? Duration.zero : age,
    );
  }

  TripInitialFixAssessment _result(
    TripInitialFixQuality quality, {
    required DateTime assessedAt,
    TripLocationSample? sample,
    Duration? age,
  }) {
    final usable =
        quality == TripInitialFixQuality.freshPrecise ||
        quality == TripInitialFixQuality.freshModerate ||
        quality == TripInitialFixQuality.freshLowQuality;
    final confidence = switch (quality) {
      TripInitialFixQuality.freshPrecise => TripTrackingConfidence.high,
      TripInitialFixQuality.freshModerate => TripTrackingConfidence.medium,
      TripInitialFixQuality.freshLowQuality => TripTrackingConfidence.low,
      _ => TripTrackingConfidence.unknown,
    };
    return TripInitialFixAssessment(
      quality: quality,
      assessedAt: assessedAt,
      sampleRecordedAt: sample?.recordedAt.toUtc(),
      sampleAge: age,
      horizontalAccuracyMeters: sample?.horizontalAccuracyMeters,
      confidence: confidence,
      mayUseProvisionally: usable,
    );
  }

  bool _relationshipIsImplausible(
    TripLocationSample sample,
    TripLocationSample? recent,
  ) {
    if (recent == null || !recent.hasValidCoordinate) return false;
    final elapsedSeconds =
        sample.recordedAt
            .toUtc()
            .difference(recent.recordedAt.toUtc())
            .inMilliseconds /
        1000;
    if (elapsedSeconds < 0) return true;
    final distance = _distanceMeters(recent, sample);
    if (elapsedSeconds == 0) return distance > 1000;
    return distance / elapsedSeconds > maximumRelationshipSpeedMetersPerSecond;
  }

  double _distanceMeters(TripLocationSample a, TripLocationSample b) {
    const earthRadiusMeters = 6371008.8;
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final deltaLat = (b.latitude - a.latitude) * math.pi / 180;
    final deltaLon = (b.longitude - a.longitude) * math.pi / 180;
    final haversine =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    return earthRadiusMeters *
        2 *
        math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
  }
}
