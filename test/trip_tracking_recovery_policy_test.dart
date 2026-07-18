import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_recovery_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  final startedAt = DateTime.utc(2026, 7, 17, 8);

  TripTrackingSessionRecord session({
    String vehicleId = 'vehicle_1',
    bool valid = true,
    double acceptedMeters = 1609.344,
  }) => TripTrackingSessionRecord(
    id: 'trip_recovery_1',
    vehicleId: vehicleId,
    startingOdometer: 1000,
    profile: TripTrackingProfile.deliveryVehicle,
    startedAt: startedAt,
    updatedAt: startedAt.add(const Duration(minutes: 5)),
    hasValidTimeline: valid,
    engineSnapshot: TripTrackingEngineSnapshot(
      totalAcceptedMeters: acceptedMeters,
      walkingReviewSuggested: false,
    ),
  );

  TripTrackingReviewRecord review({bool valid = true}) =>
      TripTrackingReviewRecord(
        id: 'trip_recovery_1',
        vehicleId: 'vehicle_1',
        startingOdometer: 1000,
        estimatedEndingOdometer: 1001,
        profile: TripTrackingProfile.deliveryVehicle,
        startedAt: startedAt,
        finishedAt: startedAt.add(const Duration(minutes: 10)),
        hasValidTimeline: valid,
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 1609.344,
          walkingReviewSuggested: false,
        ),
      );

  test('ready recovery estimates odometer without exposing raw location', () {
    final decision = TripTrackingRecoveryPolicy.evaluate(
      session: session(),
      currentVehicleId: 'vehicle_1',
      currentConfirmedOdometer: 1000,
    );
    final summary = decision.toSafeSummary();

    expect(decision.status, TripTrackingRecoveryStatus.ready);
    expect(decision.canRestore, isTrue);
    expect(decision.estimatedOdometer, 1001);
    expect(summary['schemaVersion'], 1);
    expect(summary['localRecoveryAuthoritative'], isTrue);
    expect(summary['firestoreCanOverrideLocalRecovery'], isFalse);
    expect(summary['odometerRemainsCanonical'], isTrue);
    expect(summary['mapboxCanRestoreTrip'], isFalse);
    expect(summary['requiresSameVehicle'], isTrue);
    expect(summary['requiresSameConfirmedOdometer'], isTrue);
    expect(summary['rawLocationIncluded'], isFalse);
    expect(summary['routeGeometryIncluded'], isFalse);
    expect(summary['pendingSampleIncluded'], isFalse);
    expect(summary['rawSessionIncluded'], isFalse);
    expect(summary['rawReviewIncluded'], isFalse);
  });

  test('pending sample can be replayed but is never included in summary', () {
    final pending = TripTrackingPendingSample(
      sessionId: 'trip_recovery_1',
      sample: TripLocationSample(
        latitude: 35,
        longitude: -80,
        recordedAt: startedAt.add(const Duration(minutes: 1)),
        horizontalAccuracyMeters: 5,
      ),
    );

    final decision = TripTrackingRecoveryPolicy.evaluate(
      session: session(),
      currentVehicleId: 'vehicle_1',
      currentConfirmedOdometer: 1000,
      pendingSample: pending,
    );

    expect(decision.status, TripTrackingRecoveryStatus.pendingReplayReady);
    expect(decision.canRestore, isTrue);
    expect(decision.pendingSampleQueued, isTrue);
    expect(decision.toSafeSummary().toString(), isNot(contains('-80')));
    expect(decision.toSafeSummary()['pendingSampleIncluded'], isFalse);
  });

  test('unsafe pending sample evidence is ignored during recovery', () {
    final impossibleCoordinate = TripTrackingPendingSample(
      sessionId: 'trip_recovery_1',
      sample: TripLocationSample(
        latitude: 999,
        longitude: -80,
        recordedAt: startedAt.add(const Duration(minutes: 1)),
        horizontalAccuracyMeters: 5,
      ),
    );
    final staleSensorEvidence = TripTrackingPendingSample(
      sessionId: 'trip_recovery_1',
      sample: TripLocationSample(
        latitude: 35,
        longitude: -80,
        recordedAt: startedAt.add(const Duration(minutes: 5)),
        horizontalAccuracyMeters: 5,
      ),
      activity: TripActivityObservation(
        activity: TripActivity.walking,
        confidence: 95,
        recordedAt: startedAt,
      ),
    );
    final futureReplay = TripTrackingPendingSample(
      sessionId: 'trip_recovery_1',
      sample: TripLocationSample(
        latitude: 35,
        longitude: -80,
        recordedAt: startedAt.add(const Duration(hours: 2)),
        horizontalAccuracyMeters: 5,
      ),
    );

    for (final pending in [
      impossibleCoordinate,
      staleSensorEvidence,
      futureReplay,
    ]) {
      final decision = TripTrackingRecoveryPolicy.evaluate(
        session: session(),
        currentVehicleId: 'vehicle_1',
        currentConfirmedOdometer: 1000,
        pendingSample: pending,
      );

      expect(decision.status, TripTrackingRecoveryStatus.ready);
      expect(decision.canRestore, isTrue);
      expect(decision.pendingSampleQueued, isFalse);
      expect(decision.toSafeSummary()['pendingSampleQueued'], isFalse);
      expect(decision.toSafeSummary()['pendingSampleIncluded'], isFalse);
    }
  });

  test('invalid or already-reviewed recovery records fail closed', () {
    final invalidSession = TripTrackingRecoveryPolicy.evaluate(
      session: session(valid: false),
      currentVehicleId: 'vehicle_1',
      currentConfirmedOdometer: 1000,
    );
    final completed = TripTrackingRecoveryPolicy.evaluate(
      session: session(),
      currentVehicleId: 'vehicle_1',
      currentConfirmedOdometer: 1000,
      review: review(),
    );
    final invalidReview = TripTrackingRecoveryPolicy.evaluate(
      session: session(),
      currentVehicleId: 'vehicle_1',
      currentConfirmedOdometer: 1000,
      review: review(valid: false),
    );

    expect(invalidSession.status, TripTrackingRecoveryStatus.invalidSession);
    expect(invalidSession.requiresUserAction, isTrue);
    expect(completed.status, TripTrackingRecoveryStatus.completedReviewPresent);
    expect(completed.canRestore, isFalse);
    expect(completed.toSafeSummary()['rawReviewIncluded'], isFalse);
    expect(
      invalidReview.status,
      TripTrackingRecoveryStatus.invalidReviewPresent,
    );
    expect(invalidReview.requiresUserAction, isTrue);
  });

  test('vehicle or odometer mismatch requires user action', () {
    final vehicleMismatch = TripTrackingRecoveryPolicy.evaluate(
      session: session(vehicleId: 'vehicle_2'),
      currentVehicleId: 'vehicle_1',
      currentConfirmedOdometer: 1000,
    );
    final odometerMismatch = TripTrackingRecoveryPolicy.evaluate(
      session: session(),
      currentVehicleId: 'vehicle_1',
      currentConfirmedOdometer: 1005,
    );

    expect(vehicleMismatch.status, TripTrackingRecoveryStatus.vehicleMismatch);
    expect(vehicleMismatch.requiresUserAction, isTrue);
    expect(vehicleMismatch.toSafeSummary()['canRestore'], isFalse);
    expect(
      odometerMismatch.status,
      TripTrackingRecoveryStatus.odometerMismatch,
    );
    expect(odometerMismatch.requiresUserAction, isTrue);
    expect(odometerMismatch.toSafeSummary()['canRestore'], isFalse);
    expect(
      odometerMismatch.toSafeSummary()['odometerRemainsCanonical'],
      isTrue,
    );
  });
}
