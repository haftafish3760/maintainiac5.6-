import 'dart:math' as math;

import 'trip_tracking_models.dart';

enum TripInitialFixClassification {
  freshPrecise,
  freshModerate,
  freshLowQuality,
  staleCached,
  approximateOnly,
  unavailable,
  rejected,
}

class TripInitialFixDecision {
  const TripInitialFixDecision({
    required this.classification,
    required this.confidence,
    required this.reasonCode,
    required this.canAnchorSession,
    required this.provisional,
  });

  final TripInitialFixClassification classification;
  final TripTrackingConfidence confidence;
  final String reasonCode;
  final bool canAnchorSession;
  final bool provisional;

  Map<String, Object?> toSafeSummary() => {
    'schemaVersion': 1,
    'classification': classification.name,
    'confidence': confidence.name,
    'reasonCode': reasonCode,
    'canAnchorSession': canAnchorSession,
    'provisional': provisional,
    'odometerIsGlobalTruth': true,
    'gpsCanMoveTripStartTime': false,
    'gpsCanFabricateMissingRoute': false,
    'rawLocationIncluded': false,
    'coordinatesIncluded': false,
  };
}

class TripInitialFixClassifier {
  const TripInitialFixClassifier._();

  static TripInitialFixDecision evaluate({
    required TripLocationSample? sample,
    required DateTime sessionStartedAt,
    required DateTime receivedAt,
    required bool preciseLocationAuthorized,
    TripLocationSample? recentKnownLocation,
    TripMotionState motionState = TripMotionState.unknown,
    Duration maximumFreshAge = const Duration(seconds: 30),
    double preciseAccuracyMeters = 15,
    double moderateAccuracyMeters = 40,
    double maximumUsableAccuracyMeters = 65,
  }) {
    if (sample == null) {
      return _decision(
        TripInitialFixClassification.unavailable,
        TripTrackingConfidence.unknown,
        'initial_fix_unavailable',
        false,
        true,
      );
    }
    if (!preciseLocationAuthorized) {
      return _decision(
        TripInitialFixClassification.approximateOnly,
        TripTrackingConfidence.low,
        'initial_fix_approximate_only',
        false,
        true,
      );
    }
    if (!sample.hasValidCoordinate ||
        !sample.hasValidAccuracy ||
        !sample.hasValidReportedSpeed ||
        !sample.hasValidReportedSpeedAccuracy ||
        !sample.hasValidReportedBearing ||
        !sample.hasValidMonotonicElapsedNanos ||
        sample.mockedLocation == true) {
      return _decision(
        TripInitialFixClassification.rejected,
        TripTrackingConfidence.low,
        'initial_fix_rejected_invalid',
        false,
        true,
      );
    }

    final started = sessionStartedAt.toUtc();
    final received = receivedAt.toUtc();
    final observed = sample.recordedAt.toUtc();
    final freshAge = maximumFreshAge > Duration.zero
        ? maximumFreshAge
        : const Duration(seconds: 30);
    if (observed.isBefore(started) ||
        observed.isBefore(received.subtract(freshAge))) {
      return _decision(
        TripInitialFixClassification.staleCached,
        TripTrackingConfidence.low,
        'initial_fix_stale_cached',
        false,
        true,
      );
    }
    if (observed.isAfter(received.add(const Duration(minutes: 2)))) {
      return _decision(
        TripInitialFixClassification.rejected,
        TripTrackingConfidence.low,
        'initial_fix_rejected_future',
        false,
        true,
      );
    }
    if (_implausibleRelationship(sample, recentKnownLocation, motionState)) {
      return _decision(
        TripInitialFixClassification.rejected,
        TripTrackingConfidence.low,
        'initial_fix_rejected_relationship',
        false,
        true,
      );
    }

    final precise = _safeThreshold(preciseAccuracyMeters, 15);
    final moderate = math.max(
      precise,
      _safeThreshold(moderateAccuracyMeters, 40),
    );
    final usable = math.max(
      moderate,
      _safeThreshold(maximumUsableAccuracyMeters, 65),
    );
    if (sample.horizontalAccuracyMeters <= precise) {
      return _decision(
        TripInitialFixClassification.freshPrecise,
        TripTrackingConfidence.high,
        'initial_fix_fresh_precise',
        true,
        false,
      );
    }
    if (sample.horizontalAccuracyMeters <= moderate) {
      return _decision(
        TripInitialFixClassification.freshModerate,
        TripTrackingConfidence.medium,
        'initial_fix_fresh_moderate',
        true,
        true,
      );
    }
    if (sample.horizontalAccuracyMeters <= usable) {
      return _decision(
        TripInitialFixClassification.freshLowQuality,
        TripTrackingConfidence.low,
        'initial_fix_fresh_low_quality',
        true,
        true,
      );
    }
    return _decision(
      TripInitialFixClassification.rejected,
      TripTrackingConfidence.low,
      'initial_fix_rejected_accuracy',
      false,
      true,
    );
  }
}

TripInitialFixDecision _decision(
  TripInitialFixClassification classification,
  TripTrackingConfidence confidence,
  String reasonCode,
  bool canAnchorSession,
  bool provisional,
) => TripInitialFixDecision(
  classification: classification,
  confidence: confidence,
  reasonCode: reasonCode,
  canAnchorSession: canAnchorSession,
  provisional: provisional,
);

double _safeThreshold(double value, double fallback) =>
    value.isFinite && value > 0 ? value : fallback;

bool _implausibleRelationship(
  TripLocationSample candidate,
  TripLocationSample? recent,
  TripMotionState motionState,
) {
  if (recent == null || !recent.hasValidCoordinate) return false;
  final elapsed = candidate.recordedAt.difference(recent.recordedAt);
  if (elapsed.isNegative || elapsed > const Duration(minutes: 10)) return false;
  if (motionState == TripMotionState.moving) return false;
  return _distanceMeters(recent, candidate) > 5000;
}

double _distanceMeters(TripLocationSample a, TripLocationSample b) {
  const earthRadiusMeters = 6371008.8;
  final lat1 = a.latitude * math.pi / 180;
  final lat2 = b.latitude * math.pi / 180;
  final latDelta = lat2 - lat1;
  final lonDelta = (b.longitude - a.longitude) * math.pi / 180;
  final haversine =
      math.sin(latDelta / 2) * math.sin(latDelta / 2) +
      math.cos(lat1) *
          math.cos(lat2) *
          math.sin(lonDelta / 2) *
          math.sin(lonDelta / 2);
  return earthRadiusMeters * 2 * math.asin(math.sqrt(haversine.clamp(0, 1)));
}
