import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_state_machine.dart';

void main() {
  test('contract lifecycle exposes required canonical states', () {
    const required = TripTrackingSessionLifecycleContractState.values;
    expect(required.isNotEmpty, isTrue);
    expect(required.length, 18);
    expect(required, contains(TripTrackingSessionLifecycleContractState.IDLE));
    expect(
      required,
      contains(TripTrackingSessionLifecycleContractState.FAILED_UNRECOVERABLE),
    );
  });

  test('runtime lifecycle states map to contract states', () {
    expect(
      TripTrackingSessionLifecycleState.disabled.toContractState(),
      TripTrackingSessionLifecycleContractState.IDLE,
    );
    expect(
      TripTrackingSessionLifecycleState.ready.toContractState(),
      TripTrackingSessionLifecycleContractState.PREPARING,
    );
    expect(
      TripTrackingSessionLifecycleState.permissionRequired.toContractState(),
      TripTrackingSessionLifecycleContractState.AWAITING_PERMISSION,
    );
    expect(
      TripTrackingSessionLifecycleState.starting.toContractState(),
      TripTrackingSessionLifecycleContractState.AWAITING_INITIAL_FIX,
    );
    expect(
      TripTrackingSessionLifecycleState.active.toContractState(),
      TripTrackingSessionLifecycleContractState.ACTIVE_TRACKING,
    );
    expect(
      TripTrackingSessionLifecycleState.paused.toContractState(),
      TripTrackingSessionLifecycleContractState.PAUSED_BY_USER,
    );
    expect(
      TripTrackingSessionLifecycleState.degraded.toContractState(),
      TripTrackingSessionLifecycleContractState.SIGNAL_DEGRADED,
    );
    expect(
      TripTrackingSessionLifecycleState.interrupted.toContractState(),
      TripTrackingSessionLifecycleContractState.SIGNAL_LOST,
    );
    expect(
      TripTrackingSessionLifecycleState.recovering.toContractState(),
      TripTrackingSessionLifecycleContractState.RECOVERING,
    );
    expect(
      TripTrackingSessionLifecycleState.stopping.toContractState(),
      TripTrackingSessionLifecycleContractState.COMPLETION_PENDING,
    );
    expect(
      TripTrackingSessionLifecycleState.awaitingReview.toContractState(),
      TripTrackingSessionLifecycleContractState.COMPLETION_PENDING,
    );
    expect(
      TripTrackingSessionLifecycleState.completed.toContractState(),
      TripTrackingSessionLifecycleContractState.COMPLETED,
    );
    expect(
      TripTrackingSessionLifecycleState.failedRecoverable.toContractState(),
      TripTrackingSessionLifecycleContractState.FAILED_RECOVERABLE,
    );
    expect(
      TripTrackingSessionLifecycleState.failedTerminal.toContractState(),
      TripTrackingSessionLifecycleContractState.FAILED_UNRECOVERABLE,
    );
    expect(
      TripTrackingSessionLifecycleState.cancelled.toContractState(),
      TripTrackingSessionLifecycleContractState.CANCELLED,
    );
  });

  test('runtime lifecycle mapping to contract is stable and reversible', () {
    for (final runtimeState in TripTrackingSessionLifecycleState.values) {
      final contractState = runtimeState.toContractState();
      if (runtimeState == TripTrackingSessionLifecycleState.stopping) {
        expect(
          contractState.toRuntimeState(),
          TripTrackingSessionLifecycleState.awaitingReview,
        );
      } else {
        expect(contractState.toRuntimeState(), runtimeState);
      }
    }
  });

  test('contract aliases map intentionally to runtime counterparts', () {
    expect(
      TripTrackingSessionLifecycleContractState.AWAITING_PERMISSION
          .toRuntimeState(),
      TripTrackingSessionLifecycleState.permissionRequired,
    );
    expect(
      TripTrackingSessionLifecycleContractState.AWAITING_LOCATION_SERVICES
          .toRuntimeState(),
      TripTrackingSessionLifecycleState.permissionRequired,
    );
    expect(
      TripTrackingSessionLifecycleContractState.CANDIDATE_MOVEMENT
          .toRuntimeState(),
      TripTrackingSessionLifecycleState.active,
    );
    expect(
      TripTrackingSessionLifecycleContractState.TEMPORARILY_STOPPED
          .toRuntimeState(),
      TripTrackingSessionLifecycleState.active,
    );
    expect(
      TripTrackingSessionLifecycleContractState.PAUSED_BY_SYSTEM
          .toRuntimeState(),
      TripTrackingSessionLifecycleState.paused,
    );
    expect(
      TripTrackingSessionLifecycleContractState.CANCELLED.toRuntimeState(),
      TripTrackingSessionLifecycleState.cancelled,
    );
  });

  test(
    'contract state machine follows runtime transition contract boundary',
    () {
      expect(
        TripTrackingSessionContractStateMachine.canTransition(
          TripTrackingSessionLifecycleContractState.IDLE,
          TripTrackingSessionLifecycleContractState.PREPARING,
        ),
        isTrue,
      );
      expect(
        TripTrackingSessionContractStateMachine.canTransition(
          TripTrackingSessionLifecycleContractState.PREPARING,
          TripTrackingSessionLifecycleContractState.AWAITING_PERMISSION,
        ),
        isTrue,
      );
      expect(
        TripTrackingSessionContractStateMachine.canTransition(
          TripTrackingSessionLifecycleContractState.AWAITING_INITIAL_FIX,
          TripTrackingSessionLifecycleContractState.ACTIVE_TRACKING,
        ),
        isTrue,
      );
      expect(
        TripTrackingSessionContractStateMachine.canTransition(
          TripTrackingSessionLifecycleContractState.ACTIVE_TRACKING,
          TripTrackingSessionLifecycleContractState.COMPLETION_PENDING,
        ),
        isTrue,
      );
      expect(
        TripTrackingSessionContractStateMachine.evaluateTransition(
          TripTrackingSessionLifecycleContractState.FAILED_RECOVERABLE,
          TripTrackingSessionLifecycleContractState.RECOVERING,
        ).allowed,
        isTrue,
      );
      expect(
        TripTrackingSessionContractStateMachine.canTransition(
          TripTrackingSessionLifecycleContractState.CANDIDATE_MOVEMENT,
          TripTrackingSessionLifecycleContractState.ACTIVE_TRACKING,
        ),
        isTrue,
      );
      expect(
        TripTrackingSessionContractStateMachine.canTransition(
          TripTrackingSessionLifecycleContractState.PAUSED_BY_SYSTEM,
          TripTrackingSessionLifecycleContractState.PAUSED_BY_USER,
        ),
        isTrue,
      );
      expect(
        TripTrackingSessionContractStateMachine.canTransition(
          TripTrackingSessionLifecycleContractState.CANCELLED,
          TripTrackingSessionLifecycleContractState.IDLE,
        ),
        isTrue,
      );
      expect(
        TripTrackingSessionContractStateMachine.canTransition(
          TripTrackingSessionLifecycleContractState.ACTIVE_TRACKING,
          TripTrackingSessionLifecycleContractState.CANCELLED,
        ),
        isTrue,
      );
    },
  );

  test('contract transitions do not inherit lossy runtime alias decisions', () {
    expect(
      TripTrackingSessionContractStateMachine.canTransition(
        TripTrackingSessionLifecycleContractState.AWAITING_PERMISSION,
        TripTrackingSessionLifecycleContractState.AWAITING_LOCATION_SERVICES,
      ),
      isTrue,
    );
    expect(
      TripTrackingSessionContractStateMachine.canTransition(
        TripTrackingSessionLifecycleContractState.CANDIDATE_MOVEMENT,
        TripTrackingSessionLifecycleContractState.TEMPORARILY_STOPPED,
      ),
      isFalse,
    );
    expect(
      TripTrackingSessionContractStateMachine.canTransition(
        TripTrackingSessionLifecycleContractState.SIGNAL_LOST,
        TripTrackingSessionLifecycleContractState.ACTIVE_TRACKING,
      ),
      isFalse,
    );
    expect(
      TripTrackingSessionContractStateMachine.canTransition(
        TripTrackingSessionLifecycleContractState.COMPLETION_PENDING,
        TripTrackingSessionLifecycleContractState.ACTIVE_TRACKING,
      ),
      isFalse,
    );
    expect(
      TripTrackingSessionContractStateMachine.canTransition(
        TripTrackingSessionLifecycleContractState.COMPLETED,
        TripTrackingSessionLifecycleContractState.PREPARING,
      ),
      isFalse,
    );
  });

  test('every contract state pair returns one deterministic decision', () {
    for (final from in TripTrackingSessionLifecycleContractState.values) {
      final allowed = TripTrackingSessionContractStateMachine.allowedNextStates(
        from,
      );
      expect(allowed, isNot(contains(from)));
      for (final to in TripTrackingSessionLifecycleContractState.values) {
        final decision =
            TripTrackingSessionContractStateMachine.evaluateTransition(
              from,
              to,
            );
        expect(decision.from, from);
        expect(decision.to, to);
        expect(decision.allowed, allowed.contains(to));
        expect(
          TripTrackingSessionContractStateMachine.canTransition(from, to),
          decision.allowed,
        );
      }
    }
  });

  test('every exact contract state survives local session serialization', () {
    final at = DateTime.utc(2026, 7, 22, 22);
    for (final state in TripTrackingSessionLifecycleContractState.values) {
      final session = TripTrackingSessionRecord(
        id: 'state-${state.name}',
        vehicleId: 'vehicle-1',
        startingOdometer: 1000,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: at,
        updatedAt: at,
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 0,
          walkingReviewSuggested: false,
        ),
        lifecycleState: state.toRuntimeState(),
        persistedContractState: state,
      );
      final restored = TripTrackingSessionRecord.fromMap(session.toMap());
      expect(restored.hasValidTimeline, isTrue, reason: state.name);
      expect(restored.effectiveContractState, state, reason: state.name);
      expect(restored.toMap()['contractState'], state.name);
    }
  });

  test('mismatched persisted contract state fails the recovery boundary', () {
    final at = DateTime.utc(2026, 7, 22, 22);
    final session = TripTrackingSessionRecord(
      id: 'state-mismatch',
      vehicleId: 'vehicle-1',
      startingOdometer: 1000,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: at,
      updatedAt: at,
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 0,
        walkingReviewSuggested: false,
      ),
      lifecycleState: TripTrackingSessionLifecycleState.active,
    );
    final restored = TripTrackingSessionRecord.fromMap({
      ...session.toMap(),
      'contractState':
          TripTrackingSessionLifecycleContractState.AWAITING_PERMISSION.name,
    });
    expect(restored.hasValidTimeline, isFalse);
    expect(
      restored.effectiveContractState,
      TripTrackingSessionLifecycleContractState.ACTIVE_TRACKING,
    );
  });

  test('contract transition decision safe summary remains redacted', () {
    final summary = TripTrackingSessionContractStateMachine.evaluateTransition(
      TripTrackingSessionLifecycleContractState.ACTIVE_TRACKING,
      TripTrackingSessionLifecycleContractState.PAUSED_BY_USER,
    ).toSafeSummary();

    expect(
      summary['from'],
      TripTrackingSessionLifecycleContractState.ACTIVE_TRACKING.name,
    );
    expect(
      summary['to'],
      TripTrackingSessionLifecycleContractState.PAUSED_BY_USER.name,
    );
    expect(summary['allowed'], isTrue);
    expect(summary['reasonCode'], 'gps_session_transition_allowed');
  });
}
