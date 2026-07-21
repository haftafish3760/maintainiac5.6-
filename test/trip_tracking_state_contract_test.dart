import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
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
      TripTrackingSessionLifecycleContractState.TEMPORARILY_STOPPED,
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
      expect(contractState.toRuntimeState(), runtimeState);
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
        isFalse,
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
        isFalse,
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
