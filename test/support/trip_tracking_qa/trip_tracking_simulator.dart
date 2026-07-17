import 'package:maintaniac/shared/trip_tracking/trip_tracking_engine.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

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

  int count(TripSampleDisposition disposition) =>
      dispositions.where((value) => value == disposition).length;
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
