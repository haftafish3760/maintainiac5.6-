import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_state_machine.dart';

typedef State = TripTrackingSessionLifecycleState;
typedef ContractState = TripTrackingSessionLifecycleContractState;

void main() {
  test('every lifecycle pair has an explicit approved disposition', () {
    expect(_approved.keys.toSet(), State.values.toSet());
    for (final from in State.values) {
      for (final to in State.values) {
        final expected = from == to || (_approved[from]?.contains(to) ?? false);
        expect(
          TripTrackingSessionStateMachine.canTransition(from, to),
          expected,
          reason: '${from.name} -> ${to.name}',
        );
        final decision = TripTrackingSessionStateMachine.evaluateTransition(
          from,
          to,
        );
        expect(decision.allowed, expected);
        expect(
          decision.reasonCode,
          _expectedRuntimeReason(from: from, to: to, allowed: expected),
          reason: '${from.name} -> ${to.name}',
        );
        if (expected) {
          expect(
            () => TripTrackingSessionStateMachine.requireTransition(from, to),
            returnsNormally,
            reason: '${from.name} -> ${to.name}',
          );
        } else {
          expect(
            () => TripTrackingSessionStateMachine.requireTransition(from, to),
            throwsStateError,
            reason: '${from.name} -> ${to.name}',
          );
        }
      }
    }
  });

  test('every contract lifecycle pair has an explicit disposition', () {
    expect(_approvedContract.keys.toSet(), ContractState.values.toSet());
    for (final from in ContractState.values) {
      final allowedNext =
          TripTrackingSessionContractStateMachine.allowedNextStates(from);
      expect(allowedNext, _approvedContract[from], reason: from.name);
      expect(
        () => allowedNext.add(ContractState.IDLE),
        throwsUnsupportedError,
        reason: '${from.name} next states must be immutable',
      );

      for (final to in ContractState.values) {
        final expected = _approvedContract[from]!.contains(to);
        expect(
          TripTrackingSessionContractStateMachine.canTransition(from, to),
          expected,
          reason: '${from.name} -> ${to.name}',
        );
        expect(
          () => TripTrackingSessionContractStateMachine.requireTransition(
            from,
            to,
          ),
          expected ? returnsNormally : throwsStateError,
          reason: '${from.name} -> ${to.name}',
        );
        final decision =
            TripTrackingSessionContractStateMachine.evaluateTransition(
              from,
              to,
            );
        expect(decision.allowed, expected);
        expect(
          decision.reasonCode,
          expected
              ? 'gps_session_transition_allowed'
              : from == ContractState.COMPLETION_PENDING
              ? 'review_required_before_transition'
              : 'illegal_gps_session_transition',
          reason: '${from.name} -> ${to.name}',
        );
        expect(decision.toSafeSummary()['allowed'], expected);
      }
    }
  });
}

String _expectedRuntimeReason({
  required State from,
  required State to,
  required bool allowed,
}) {
  if (allowed) return 'gps_session_transition_allowed';
  if (from == State.completed) return 'completed_session_cannot_resume';
  if (from == State.awaitingReview && to != State.completed) {
    return 'review_required_before_transition';
  }
  if (from == State.failedTerminal && to != State.disabled) {
    return 'terminal_failure_requires_fresh_opt_in';
  }
  return 'illegal_gps_session_transition';
}

const Map<State, Set<State>> _approved = {
  State.disabled: {State.permissionRequired, State.ready},
  State.permissionRequired: {
    State.starting,
    State.ready,
    State.stopping,
    State.failedTerminal,
    State.cancelled,
  },
  State.ready: {
    State.starting,
    State.paused,
    State.stopping,
    State.permissionRequired,
    State.disabled,
    State.cancelled,
  },
  State.starting: {
    State.active,
    State.paused,
    State.stopping,
    State.failedRecoverable,
    State.permissionRequired,
    State.cancelled,
  },
  State.active: {
    State.starting,
    State.paused,
    State.degraded,
    State.interrupted,
    State.stopping,
    State.failedRecoverable,
    State.permissionRequired,
    State.failedTerminal,
    State.cancelled,
  },
  State.paused: {
    State.starting,
    State.stopping,
    State.permissionRequired,
    State.failedTerminal,
    State.cancelled,
  },
  State.degraded: {
    State.starting,
    State.active,
    State.paused,
    State.recovering,
    State.interrupted,
    State.failedRecoverable,
    State.stopping,
    State.permissionRequired,
    State.failedTerminal,
    State.cancelled,
  },
  State.interrupted: {
    State.paused,
    State.recovering,
    State.starting,
    State.failedRecoverable,
    State.stopping,
    State.permissionRequired,
    State.failedTerminal,
    State.cancelled,
  },
  State.recovering: {
    State.active,
    State.paused,
    State.stopping,
    State.failedRecoverable,
    State.awaitingReview,
    State.permissionRequired,
    State.failedTerminal,
    State.cancelled,
  },
  State.awaitingReview: {State.completed, State.cancelled},
  State.stopping: {
    State.completed,
    State.failedRecoverable,
    State.failedTerminal,
    State.cancelled,
  },
  State.completed: {},
  State.failedRecoverable: {
    State.recovering,
    State.starting,
    State.stopping,
    State.awaitingReview,
    State.permissionRequired,
    State.failedTerminal,
    State.cancelled,
  },
  State.failedTerminal: {State.disabled},
  State.cancelled: {State.disabled},
};

const Map<ContractState, Set<ContractState>> _approvedContract = {
  ContractState.IDLE: {
    ContractState.PREPARING,
    ContractState.AWAITING_PERMISSION,
    ContractState.AWAITING_LOCATION_SERVICES,
    ContractState.CANDIDATE_MOVEMENT,
  },
  ContractState.PREPARING: {
    ContractState.AWAITING_PERMISSION,
    ContractState.AWAITING_LOCATION_SERVICES,
    ContractState.AWAITING_INITIAL_FIX,
    ContractState.IDLE,
    ContractState.PAUSED_BY_USER,
    ContractState.PAUSED_BY_SYSTEM,
    ContractState.CANCELLED,
    ContractState.FAILED_RECOVERABLE,
    ContractState.FAILED_UNRECOVERABLE,
    ContractState.COMPLETION_PENDING,
  },
  ContractState.AWAITING_PERMISSION: {
    ContractState.PREPARING,
    ContractState.AWAITING_LOCATION_SERVICES,
    ContractState.AWAITING_INITIAL_FIX,
    ContractState.PAUSED_BY_USER,
    ContractState.PAUSED_BY_SYSTEM,
    ContractState.CANCELLED,
    ContractState.FAILED_RECOVERABLE,
    ContractState.FAILED_UNRECOVERABLE,
    ContractState.COMPLETION_PENDING,
  },
  ContractState.AWAITING_LOCATION_SERVICES: {
    ContractState.PREPARING,
    ContractState.AWAITING_PERMISSION,
    ContractState.AWAITING_INITIAL_FIX,
    ContractState.PAUSED_BY_USER,
    ContractState.PAUSED_BY_SYSTEM,
    ContractState.CANCELLED,
    ContractState.FAILED_RECOVERABLE,
    ContractState.FAILED_UNRECOVERABLE,
    ContractState.COMPLETION_PENDING,
  },
  ContractState.AWAITING_INITIAL_FIX: {
    ContractState.ACTIVE_TRACKING,
    ContractState.AWAITING_LOCATION_SERVICES,
    ContractState.SIGNAL_DEGRADED,
    ContractState.SIGNAL_LOST,
    ContractState.AWAITING_PERMISSION,
    ContractState.PAUSED_BY_USER,
    ContractState.PAUSED_BY_SYSTEM,
    ContractState.COMPLETION_PENDING,
    ContractState.CANCELLED,
    ContractState.FAILED_RECOVERABLE,
  },
  ContractState.CANDIDATE_MOVEMENT: {
    ContractState.IDLE,
    ContractState.PREPARING,
    ContractState.ACTIVE_TRACKING,
    ContractState.CANCELLED,
    ContractState.FAILED_RECOVERABLE,
  },
  ContractState.ACTIVE_TRACKING: {
    ContractState.AWAITING_INITIAL_FIX,
    ContractState.TEMPORARILY_STOPPED,
    ContractState.PAUSED_BY_USER,
    ContractState.PAUSED_BY_SYSTEM,
    ContractState.SIGNAL_DEGRADED,
    ContractState.SIGNAL_LOST,
    ContractState.COMPLETION_PENDING,
    ContractState.CANCELLED,
    ContractState.FAILED_RECOVERABLE,
    ContractState.FAILED_UNRECOVERABLE,
  },
  ContractState.TEMPORARILY_STOPPED: {
    ContractState.ACTIVE_TRACKING,
    ContractState.PAUSED_BY_USER,
    ContractState.PAUSED_BY_SYSTEM,
    ContractState.SIGNAL_DEGRADED,
    ContractState.SIGNAL_LOST,
    ContractState.COMPLETION_PENDING,
    ContractState.CANCELLED,
    ContractState.FAILED_RECOVERABLE,
  },
  ContractState.PAUSED_BY_USER: {
    ContractState.AWAITING_INITIAL_FIX,
    ContractState.ACTIVE_TRACKING,
    ContractState.PAUSED_BY_SYSTEM,
    ContractState.RECOVERING,
    ContractState.COMPLETION_PENDING,
    ContractState.CANCELLED,
    ContractState.FAILED_RECOVERABLE,
    ContractState.FAILED_UNRECOVERABLE,
  },
  ContractState.PAUSED_BY_SYSTEM: {
    ContractState.AWAITING_INITIAL_FIX,
    ContractState.ACTIVE_TRACKING,
    ContractState.PAUSED_BY_USER,
    ContractState.RECOVERING,
    ContractState.COMPLETION_PENDING,
    ContractState.CANCELLED,
    ContractState.FAILED_RECOVERABLE,
    ContractState.FAILED_UNRECOVERABLE,
  },
  ContractState.SIGNAL_DEGRADED: {
    ContractState.AWAITING_INITIAL_FIX,
    ContractState.ACTIVE_TRACKING,
    ContractState.TEMPORARILY_STOPPED,
    ContractState.PAUSED_BY_USER,
    ContractState.PAUSED_BY_SYSTEM,
    ContractState.SIGNAL_LOST,
    ContractState.RECOVERING,
    ContractState.COMPLETION_PENDING,
    ContractState.CANCELLED,
    ContractState.FAILED_RECOVERABLE,
  },
  ContractState.SIGNAL_LOST: {
    ContractState.AWAITING_INITIAL_FIX,
    ContractState.PAUSED_BY_USER,
    ContractState.PAUSED_BY_SYSTEM,
    ContractState.RECOVERING,
    ContractState.COMPLETION_PENDING,
    ContractState.CANCELLED,
    ContractState.FAILED_RECOVERABLE,
    ContractState.FAILED_UNRECOVERABLE,
  },
  ContractState.RECOVERING: {
    ContractState.ACTIVE_TRACKING,
    ContractState.PAUSED_BY_USER,
    ContractState.PAUSED_BY_SYSTEM,
    ContractState.SIGNAL_DEGRADED,
    ContractState.SIGNAL_LOST,
    ContractState.COMPLETION_PENDING,
    ContractState.CANCELLED,
    ContractState.FAILED_RECOVERABLE,
    ContractState.FAILED_UNRECOVERABLE,
  },
  ContractState.COMPLETION_PENDING: {
    ContractState.COMPLETED,
    ContractState.CANCELLED,
    ContractState.FAILED_RECOVERABLE,
    ContractState.FAILED_UNRECOVERABLE,
  },
  ContractState.COMPLETED: {ContractState.IDLE},
  ContractState.CANCELLED: {ContractState.IDLE},
  ContractState.FAILED_RECOVERABLE: {
    ContractState.AWAITING_INITIAL_FIX,
    ContractState.PAUSED_BY_SYSTEM,
    ContractState.RECOVERING,
    ContractState.COMPLETION_PENDING,
    ContractState.CANCELLED,
    ContractState.FAILED_UNRECOVERABLE,
  },
  ContractState.FAILED_UNRECOVERABLE: {ContractState.IDLE},
};
