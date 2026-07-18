import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_recovery_resume_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_recovery_validation.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test(
    'recoverable active session can resume through local recovering state',
    () {
      final decision = TripRecoveryResumePolicy.evaluate(
        validation: TripTrackingSessionRecoveryValidation.activeSession(
          session(),
        ),
        currentLifecycle: TripTrackingSessionLifecycleState.interrupted,
        currentVehicleId: 'vehicle_1',
        expectedVehicleId: 'vehicle_1',
        currentConfirmedOdometer: 999,
        startingOdometer: 1000,
      );

      expect(decision.isReady, isTrue);
      expect(decision.reason, TripRecoveryResumeReason.activeSessionCanResume);
      expect(
        decision.targetLifecycle,
        TripTrackingSessionLifecycleState.recovering,
      );
      expect(decision.canResumeNativeTracking, isTrue);
    },
  );

  test('recoverable review opens review instead of native tracking', () {
    final decision = TripRecoveryResumePolicy.evaluate(
      validation: TripTrackingSessionRecoveryValidation.review(review()),
      currentLifecycle: TripTrackingSessionLifecycleState.awaitingReview,
      currentVehicleId: 'vehicle_1',
      expectedVehicleId: 'vehicle_1',
      currentConfirmedOdometer: 999,
      startingOdometer: 1000,
    );

    expect(decision.isReady, isTrue);
    expect(decision.reason, TripRecoveryResumeReason.reviewCanOpen);
    expect(decision.canOpenReview, isTrue);
    expect(decision.canResumeNativeTracking, isFalse);
    expect(decision.requiresUserReview, isTrue);
  });

  test('quarantined, wrong vehicle, and rollback recovery fail closed', () {
    final quarantined = TripRecoveryResumePolicy.evaluate(
      validation: TripTrackingSessionRecoveryValidation.activeSession(
        session(id: 'bad token=sk.secret'),
      ),
      currentLifecycle: TripTrackingSessionLifecycleState.interrupted,
      currentVehicleId: 'vehicle_1',
      expectedVehicleId: 'vehicle_1',
      currentConfirmedOdometer: 999,
      startingOdometer: 1000,
    );
    final wrongVehicle = TripRecoveryResumePolicy.evaluate(
      validation: TripTrackingSessionRecoveryValidation.activeSession(
        session(),
      ),
      currentLifecycle: TripTrackingSessionLifecycleState.interrupted,
      currentVehicleId: 'vehicle_2',
      expectedVehicleId: 'vehicle_1',
      currentConfirmedOdometer: 999,
      startingOdometer: 1000,
    );
    final rollback = TripRecoveryResumePolicy.evaluate(
      validation: TripTrackingSessionRecoveryValidation.activeSession(
        session(),
      ),
      currentLifecycle: TripTrackingSessionLifecycleState.interrupted,
      currentVehicleId: 'vehicle_1',
      expectedVehicleId: 'vehicle_1',
      currentConfirmedOdometer: 1001,
      startingOdometer: 1000,
    );

    expect(quarantined.reason, TripRecoveryResumeReason.quarantinedRecord);
    expect(wrongVehicle.reason, TripRecoveryResumeReason.vehicleMismatch);
    expect(rollback.reason, TripRecoveryResumeReason.odometerRollbackRisk);
    expect(rollback.canResumeNativeTracking, isFalse);
  });

  test('completed lifecycle cannot be resurrected by recovery', () {
    final decision = TripRecoveryResumePolicy.evaluate(
      validation: TripTrackingSessionRecoveryValidation.activeSession(
        session(),
      ),
      currentLifecycle: TripTrackingSessionLifecycleState.completed,
      currentVehicleId: 'vehicle_1',
      expectedVehicleId: 'vehicle_1',
      currentConfirmedOdometer: 999,
      startingOdometer: 1000,
    );

    expect(decision.status, TripRecoveryResumeStatus.blocked);
    expect(
      decision.reason,
      TripRecoveryResumeReason.illegalLifecycleTransition,
    );
    expect(decision.canResumeNativeTracking, isFalse);
  });

  test(
    'safe recovery summary preserves local truth and privacy boundaries',
    () {
      final safe = TripRecoveryResumePolicy.evaluate(
        validation: TripTrackingSessionRecoveryValidation.activeSession(
          session(),
        ),
        currentLifecycle: TripTrackingSessionLifecycleState.interrupted,
        currentVehicleId: 'vehicle_1',
        expectedVehicleId: 'vehicle_1',
        currentConfirmedOdometer: 999,
        startingOdometer: 1000,
      ).toSafeSummary();

      expect(safe['localRecoveryValidationRequired'], isTrue);
      expect(safe['hiveRemainsOperationalSourceOfTruth'], isTrue);
      expect(safe['firestoreCanReviveQuarantinedSession'], isFalse);
      expect(safe['remoteCheckpointCanOverrideLocalRecovery'], isFalse);
      expect(safe['recoveryCanConfirmMileage'], isFalse);
      expect(safe['odometerRemainsOfficialMileageTruth'], isTrue);
      expect(safe['rawGpsIncluded'], isFalse);
      expect(safe['preciseLocationIncluded'], isFalse);
      expect(safe['tokensIncluded'], isFalse);
    },
  );
}

TripTrackingSessionRecord session({String id = 'session_1'}) {
  final startedAt = DateTime.utc(2026, 7, 18, 8);
  return TripTrackingSessionRecord(
    id: id,
    vehicleId: 'vehicle_1',
    startingOdometer: 1000,
    profile: TripTrackingProfile.deliveryVehicle,
    startedAt: startedAt,
    updatedAt: startedAt.add(const Duration(minutes: 5)),
    engineSnapshot: const TripTrackingEngineSnapshot(
      totalAcceptedMeters: 100,
      walkingReviewSuggested: false,
      vehicleMovementObserved: true,
    ),
  );
}

TripTrackingReviewRecord review() {
  final startedAt = DateTime.utc(2026, 7, 18, 8);
  return TripTrackingReviewRecord(
    id: 'review_1',
    vehicleId: 'vehicle_1',
    startingOdometer: 1000,
    estimatedEndingOdometer: 1001,
    profile: TripTrackingProfile.deliveryVehicle,
    startedAt: startedAt,
    finishedAt: startedAt.add(const Duration(hours: 1)),
    engineSnapshot: const TripTrackingEngineSnapshot(
      totalAcceptedMeters: 1609.344,
      walkingReviewSuggested: false,
      vehicleMovementObserved: true,
    ),
  );
}
