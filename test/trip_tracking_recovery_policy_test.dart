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
    TripTrackingSessionLifecycleState lifecycleState =
        TripTrackingSessionLifecycleState.ready,
  }) => TripTrackingSessionRecord(
    id: 'trip_recovery_1',
    vehicleId: vehicleId,
    startingOdometer: 1000,
    profile: TripTrackingProfile.deliveryVehicle,
    startedAt: startedAt,
    updatedAt: startedAt.add(const Duration(minutes: 5)),
    lifecycleState: lifecycleState,
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

  TripTrackingReviewRecord reviewVariant({
    String vehicleId = 'vehicle_1',
    TripTrackingProfile profile = TripTrackingProfile.deliveryVehicle,
    DateTime? startedAtOverride,
  }) => TripTrackingReviewRecord(
    id: 'trip_recovery_1',
    vehicleId: vehicleId,
    startingOdometer: 1000,
    estimatedEndingOdometer: 1001,
    profile: profile,
    startedAt: startedAtOverride ?? startedAt,
    finishedAt: startedAt.add(const Duration(minutes: 10)),
    hasValidTimeline: true,
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
    expect(summary['cloudMirrorCanDeleteLocalRecovery'], isFalse);
    expect(summary['recoveryNeverDeletesTripData'], isTrue);
    expect(summary['backgroundInterruptionCanDeleteCheckpoint'], isFalse);
    expect(summary['permissionLossCanDeleteCheckpoint'], isFalse);
    expect(summary['localCheckpointPreservedUntilReview'], isTrue);
    expect(summary['odometerRemainsCanonical'], isTrue);
    expect(summary['mapboxCanRestoreTrip'], isFalse);
    expect(summary['mapboxCanModifyRecoveredOdometer'], isFalse);
    expect(summary['manualReviewRequiredBeforeConfirmation'], isFalse);
    expect(summary['requiresSameVehicle'], isTrue);
    expect(summary['requiresSameConfirmedOdometer'], isTrue);
    expect(summary['estimatedOdometerTrustedAfterValidationOnly'], isTrue);
    expect(summary['invalidEstimatedOdometerCanRestore'], isFalse);
    expect(summary['remotePendingSampleCanReplayWithoutValidation'], isFalse);
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
    final mockedReplay = TripTrackingPendingSample(
      sessionId: 'trip_recovery_1',
      sample: TripLocationSample(
        latitude: 35,
        longitude: -80,
        recordedAt: startedAt.add(const Duration(minutes: 1)),
        horizontalAccuracyMeters: 5,
        mockedLocation: true,
      ),
    );

    for (final pending in [
      impossibleCoordinate,
      staleSensorEvidence,
      futureReplay,
      mockedReplay,
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

  test('recovery rejects completed reviews that do not own the session', () {
    for (final badReview in [
      reviewVariant(vehicleId: 'vehicle_2'),
      reviewVariant(profile: TripTrackingProfile.rideshareVehicle),
      reviewVariant(
        startedAtOverride: startedAt.add(const Duration(seconds: 1)),
      ),
    ]) {
      final decision = TripTrackingRecoveryPolicy.evaluate(
        session: session(),
        currentVehicleId: 'vehicle_1',
        currentConfirmedOdometer: 1000,
        review: badReview,
      );

      expect(decision.status, TripTrackingRecoveryStatus.invalidReviewPresent);
      expect(decision.canRestore, isFalse);
      expect(decision.requiresUserAction, isTrue);
      expect(decision.toSafeSummary()['rawReviewIncluded'], isFalse);
      expect(
        decision.toSafeSummary()['firestoreCanOverrideLocalRecovery'],
        isFalse,
      );
    }
  });

  test(
    'terminal lifecycle checkpoints cannot be restored from summary path',
    () {
      for (final lifecycleState in [
        TripTrackingSessionLifecycleState.disabled,
        TripTrackingSessionLifecycleState.permissionRequired,
        TripTrackingSessionLifecycleState.awaitingReview,
        TripTrackingSessionLifecycleState.completed,
        TripTrackingSessionLifecycleState.failedTerminal,
      ]) {
        final decision = TripTrackingRecoveryPolicy.evaluate(
          session: session(lifecycleState: lifecycleState),
          currentVehicleId: 'vehicle_1',
          currentConfirmedOdometer: 1000,
        );

        expect(decision.status, TripTrackingRecoveryStatus.invalidSession);
        expect(decision.canRestore, isFalse);
        expect(decision.requiresUserAction, isTrue);
        expect(
          decision.toSafeSummary()['safeReason'],
          'trip_recovery_invalid_session',
        );
        expect(decision.toSafeSummary()['localRecoveryAuthoritative'], isTrue);
        expect(
          decision.toSafeSummary()['localCheckpointPreservedUntilReview'],
          isTrue,
        );
        expect(decision.toSafeSummary()['rawSessionIncluded'], isFalse);
      }
    },
  );

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
      vehicleMismatch.toSafeSummary()['manualReviewRequiredBeforeConfirmation'],
      isTrue,
    );
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

  test('legacy padded vehicle ids recover without widening ownership', () {
    final padded = TripTrackingRecoveryPolicy.evaluate(
      session: session(vehicleId: ' vehicle_1 '),
      currentVehicleId: 'vehicle_1',
      currentConfirmedOdometer: 1000,
    );
    final unsafe = TripTrackingRecoveryPolicy.evaluate(
      session: session(vehicleId: 'vehicle_1\nvehicle_2'),
      currentVehicleId: 'vehicle_1',
      currentConfirmedOdometer: 1000,
    );

    expect(padded.status, TripTrackingRecoveryStatus.ready);
    expect(padded.canRestore, isTrue);
    expect(unsafe.status, TripTrackingRecoveryStatus.vehicleMismatch);
    expect(unsafe.canRestore, isFalse);
    expect(unsafe.requiresUserAction, isTrue);
    expect(unsafe.toSafeSummary()['rawSessionIncluded'], isFalse);
  });

  test('safe recovery summaries sanitize direct malformed public fields', () {
    const decision = TripTrackingRecoveryDecision(
      status: TripTrackingRecoveryStatus.ready,
      safeReason: 'lat=35.1 token=sk.secret',
      canRestore: true,
      requiresUserAction: false,
      estimatedOdometer: 1001,
      pendingSampleQueued: false,
    );
    final summary = decision.toSafeSummary();

    expect(summary['safeReason'], 'trip_recovery_invalid_session');
    expect(summary['canRestore'], isFalse);
    expect(summary['requiresUserAction'], isTrue);
    expect(summary['manualReviewRequiredBeforeConfirmation'], isTrue);
    expect(summary['cloudMirrorCanDeleteLocalRecovery'], isFalse);
    expect(summary['recoveryNeverDeletesTripData'], isTrue);
    expect(summary['backgroundInterruptionCanDeleteCheckpoint'], isFalse);
    expect(summary['mapboxCanModifyRecoveredOdometer'], isFalse);
    expect(summary.toString(), isNot(contains('35.1')));
    expect(summary.toString(), isNot(contains('sk.secret')));
  });

  test('safe recovery summaries drop impossible direct odometer estimates', () {
    const negative = TripTrackingRecoveryDecision(
      status: TripTrackingRecoveryStatus.ready,
      safeReason: 'trip_recovery_ready',
      canRestore: true,
      requiresUserAction: false,
      estimatedOdometer: -1,
      pendingSampleQueued: false,
    );
    const overrange = TripTrackingRecoveryDecision(
      status: TripTrackingRecoveryStatus.ready,
      safeReason: 'trip_recovery_ready',
      canRestore: true,
      requiresUserAction: false,
      estimatedOdometer: 10000000,
      pendingSampleQueued: false,
    );

    expect(negative.toSafeSummary().keys, isNot(contains('estimatedOdometer')));
    expect(negative.toSafeSummary()['canRestore'], isFalse);
    expect(negative.toSafeSummary()['requiresUserAction'], isTrue);
    expect(
      overrange.toSafeSummary().keys,
      isNot(contains('estimatedOdometer')),
    );
    expect(overrange.toSafeSummary()['canRestore'], isFalse);
    expect(
      overrange.toSafeSummary()['estimatedOdometerTrustedAfterValidationOnly'],
      isTrue,
    );
    expect(
      overrange.toSafeSummary()['invalidEstimatedOdometerCanRestore'],
      isFalse,
    );
  });

  test('direct recovery summaries cannot forge pending replay readiness', () {
    const forged = TripTrackingRecoveryDecision(
      status: TripTrackingRecoveryStatus.ready,
      safeReason: 'trip_recovery_pending_replay_ready',
      canRestore: true,
      requiresUserAction: false,
      estimatedOdometer: 1001,
      pendingSampleQueued: true,
    );
    final summary = forged.toSafeSummary();

    expect(summary['canRestore'], isFalse);
    expect(summary['requiresUserAction'], isTrue);
    expect(summary['pendingSampleQueued'], isFalse);
    expect(summary['remotePendingSampleCanReplayWithoutValidation'], isFalse);
    expect(summary['pendingSampleIncluded'], isFalse);
  });

  test('interrupted and degraded checkpoints remain recoverable locally', () {
    for (final lifecycleState in [
      TripTrackingSessionLifecycleState.interrupted,
      TripTrackingSessionLifecycleState.degraded,
      TripTrackingSessionLifecycleState.failedRecoverable,
    ]) {
      final decision = TripTrackingRecoveryPolicy.evaluate(
        session: session(lifecycleState: lifecycleState),
        currentVehicleId: 'vehicle_1',
        currentConfirmedOdometer: 1000,
      );
      final summary = decision.toSafeSummary();

      expect(decision.canRestore, isTrue, reason: lifecycleState.name);
      expect(summary['canRestore'], isTrue, reason: lifecycleState.name);
      expect(summary['localRecoveryAuthoritative'], isTrue);
      expect(summary['backgroundInterruptionCanDeleteCheckpoint'], isFalse);
      expect(summary['permissionLossCanDeleteCheckpoint'], isFalse);
      expect(summary['localCheckpointPreservedUntilReview'], isTrue);
      expect(summary['manualReviewRequiredBeforeConfirmation'], isFalse);
      expect(summary['odometerRemainsCanonical'], isTrue);
      expect(summary['rawSessionIncluded'], isFalse);
    }
  });
}
