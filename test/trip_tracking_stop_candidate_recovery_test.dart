import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_engine.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

void main() {
  test('vehicle-only stop candidate survives durable snapshot recovery', () {
    final startedAt = DateTime.utc(2026, 7, 21, 12);
    final detectedAt = startedAt.add(const Duration(minutes: 2));
    final persisted = TripTrackingEngineSnapshot.fromMap(
      TripTrackingEngineSnapshot(
        totalAcceptedMeters: 1200,
        walkingReviewSuggested: false,
        motionState: TripMotionState.stopCandidate,
        vehicleMovementObserved: true,
        stationaryStartedAt: startedAt,
        lastAccepted: TripLocationSample(
          latitude: 35,
          longitude: -80,
          recordedAt: startedAt,
          horizontalAccuracyMeters: 5,
          speedMetersPerSecond: 0,
        ),
        lastObservedAt: detectedAt,
      ).toMap(),
    );

    final engine = TripTrackingEngine.fromSnapshot(
      persisted,
      profile: TripTrackingProfile.roadVehicle,
    );
    final candidate = engine.currentStopCandidate;

    expect(engine.motionState, TripMotionState.stopCandidate);
    expect(candidate, isNotNull);
    expect(candidate!.startedAt, startedAt);
    expect(candidate.detectedAt, detectedAt);
    expect(candidate.confidence, TripTrackingConfidence.low);
    expect(candidate.evidence, TripStopCandidateEvidence.stationaryGps);
    expect(candidate.requiresUserReview, isTrue);
    expect(candidate.canFinalizeTrip, isFalse);
    expect(candidate.canChangeOdometer, isFalse);
  });

  test('malformed stop candidate evidence is rejected during recovery', () {
    final observedAt = DateTime.utc(2026, 7, 21, 12);
    final engine = TripTrackingEngine.fromSnapshot(
      TripTrackingEngineSnapshot(
        totalAcceptedMeters: 1200,
        walkingReviewSuggested: false,
        motionState: TripMotionState.stopCandidate,
        vehicleMovementObserved: true,
        lastObservedAt: observedAt,
      ),
      profile: TripTrackingProfile.roadVehicle,
    );

    expect(engine.motionState, TripMotionState.unknown);
    expect(engine.currentStopCandidate, isNull);
  });
}
