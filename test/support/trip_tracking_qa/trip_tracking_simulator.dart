import 'package:maintaniac/shared/trip_tracking/trip_tracking_engine.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_classification.dart';

class SimulatedTripPoint {
  const SimulatedTripPoint(this.sample, {this.activity});

  final TripLocationSample sample;
  final TripActivityObservation? activity;
}

class SimulatedTripResult {
  const SimulatedTripResult({
    required this.acceptedMeters,
    required this.dispositions,
    required this.needsWalkingReview,
    required this.motionState,
  });

  final double acceptedMeters;
  final List<TripSampleDisposition> dispositions;
  final bool needsWalkingReview;
  final TripMotionState motionState;

  double get acceptedMiles => acceptedMeters / 1609.344;

  int get acceptedDistanceCount =>
      count(TripSampleDisposition.acceptedDistance);

  int get rejectedCount => dispositions
      .where(
        (value) =>
            value != TripSampleDisposition.acceptedAnchor &&
            value != TripSampleDisposition.acceptedDistance,
      )
      .length;

  int count(TripSampleDisposition disposition) =>
      dispositions.where((value) => value == disposition).length;

  Map<String, Object?> toSafeSummary() => {
    'acceptedMiles': double.parse(acceptedMiles.toStringAsFixed(3)),
    'acceptedDistanceCount': acceptedDistanceCount,
    'rejectedCount': rejectedCount,
    'needsWalkingReview': needsWalkingReview,
    'motionState': motionState.name,
    'rawSamplesIncluded': false,
    'coordinatesIncluded': false,
    'routeGeometryIncluded': false,
  };

  Map<String, Object?> toSafeDashboardSummary({
    required TripTrackingProfile profile,
  }) {
    final classification = TripStopClassifier.classify(
      profile: profile,
      motionState: motionState,
      needsWalkingReview: needsWalkingReview,
      excludedWalkingCount: count(TripSampleDisposition.excludedWalking),
      rejectedDriftCount: count(TripSampleDisposition.rejectedDrift),
      rejectedUnsafeCount:
          count(TripSampleDisposition.rejectedInvalid) +
          count(TripSampleDisposition.rejectedMockLocation) +
          count(TripSampleDisposition.rejectedAccuracy) +
          count(TripSampleDisposition.rejectedOutOfOrder),
      acceptedDistanceCount: acceptedDistanceCount,
    );
    return {
      ...toSafeSummary(),
      'profile': profile.name,
      'stopSignal': _dashboardStopSignal(classification.signal),
      'stopActionToken': classification.actionToken,
      'stopClassificationReason': classification.reasonCode,
      'stopRequiresUserReview': classification.requiresUserReview,
      'stopCanSuggestReview': classification.canSuggestStop,
    };
  }
}

String _dashboardStopSignal(TripStopSignal signal) {
  return switch (signal) {
    TripStopSignal.noStop => 'no_stop',
    TripStopSignal.stopCandidate => 'stop_candidate',
    TripStopSignal.reviewOnlyStop => 'review_only_stop',
    TripStopSignal.likelyTrafficControl => 'likely_traffic_control',
    TripStopSignal.equipmentIgnored => 'equipment_ignored',
    TripStopSignal.unsafeEvidence => 'unsafe_evidence',
  };
}

/// Deterministic replay harness for GPS QA. Scenario tests use this instead of
/// duplicating ingest loops, so each newly discovered field trace can become a
/// durable regression fixture.
SimulatedTripResult replayTrip(
  Iterable<SimulatedTripPoint> points, {
  TripTrackingProfile profile = TripTrackingProfile.roadVehicle,
}) {
  final engine = TripTrackingEngine(profile: profile);
  final dispositions = <TripSampleDisposition>[];
  for (final point in points) {
    dispositions.add(
      engine.ingest(point.sample, activity: point.activity).disposition,
    );
  }
  return SimulatedTripResult(
    acceptedMeters: engine.totalAcceptedMeters,
    dispositions: List.unmodifiable(dispositions),
    needsWalkingReview: engine.needsWalkingReview,
    motionState: engine.motionState,
  );
}
