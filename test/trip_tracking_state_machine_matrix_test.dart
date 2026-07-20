import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_state_machine.dart';

typedef State = TripTrackingSessionLifecycleState;

void main() {
  test('every lifecycle pair has the explicitly approved disposition', () {
    for (final from in State.values) {
      for (final to in State.values) {
        final expected = from == to || (_approved[from]?.contains(to) ?? false);
        expect(
          TripTrackingSessionStateMachine.canTransition(from, to),
          expected,
          reason: '${from.name} -> ${to.name}',
        );
      }
    }
  });

  test('every legal transition is accepted and every illegal one rejects', () {
    for (final from in State.values) {
      for (final to in State.values) {
        final expected = from == to || (_approved[from]?.contains(to) ?? false);
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

  test(
    'the approved matrix covers every state and terminal states stay terminal',
    () {
      expect(_approved.keys.toSet(), State.values.toSet());
      expect(_approved[State.completed], isEmpty);
      expect(_approved[State.cancelled], isEmpty);
      expect(_approved[State.failedUnrecoverable], isEmpty);
    },
  );
}

const Map<State, Set<State>> _approved = {
  State.idle: {State.preparing, State.candidateMovement},
  State.preparing: {
    State.awaitingPermission,
    State.awaitingLocationServices,
    State.awaitingInitialFix,
    State.candidateMovement,
    State.pausedByUser,
    State.pausedBySystem,
    State.stopping,
    State.cancelled,
    State.failedRecoverable,
    State.failedUnrecoverable,
  },
  State.awaitingPermission: {
    State.preparing,
    State.awaitingLocationServices,
    State.awaitingInitialFix,
    State.pausedBySystem,
    State.stopping,
    State.cancelled,
    State.failedRecoverable,
    State.failedUnrecoverable,
  },
  State.awaitingLocationServices: {
    State.awaitingPermission,
    State.awaitingInitialFix,
    State.pausedBySystem,
    State.stopping,
    State.cancelled,
    State.failedRecoverable,
    State.failedUnrecoverable,
  },
  State.awaitingInitialFix: {
    State.awaitingPermission,
    State.awaitingLocationServices,
    State.candidateMovement,
    State.activeTracking,
    State.signalDegraded,
    State.signalLost,
    State.pausedByUser,
    State.pausedBySystem,
    State.stopping,
    State.cancelled,
    State.failedRecoverable,
    State.failedUnrecoverable,
  },
  State.candidateMovement: {
    State.awaitingInitialFix,
    State.activeTracking,
    State.temporarilyStopped,
    State.pausedByUser,
    State.pausedBySystem,
    State.signalDegraded,
    State.signalLost,
    State.stopping,
    State.cancelled,
    State.failedRecoverable,
  },
  State.activeTracking: {
    State.awaitingInitialFix,
    State.temporarilyStopped,
    State.pausedByUser,
    State.pausedBySystem,
    State.signalDegraded,
    State.signalLost,
    State.stopping,
    State.cancelled,
    State.failedRecoverable,
    State.failedUnrecoverable,
  },
  State.temporarilyStopped: {
    State.candidateMovement,
    State.activeTracking,
    State.pausedByUser,
    State.pausedBySystem,
    State.signalDegraded,
    State.signalLost,
    State.stopping,
    State.cancelled,
    State.failedRecoverable,
  },
  State.pausedByUser: {
    State.preparing,
    State.awaitingInitialFix,
    State.stopping,
    State.cancelled,
  },
  State.pausedBySystem: {
    State.preparing,
    State.awaitingPermission,
    State.awaitingLocationServices,
    State.awaitingInitialFix,
    State.recovering,
    State.stopping,
    State.cancelled,
    State.failedRecoverable,
    State.failedUnrecoverable,
  },
  State.signalDegraded: {
    State.activeTracking,
    State.temporarilyStopped,
    State.signalLost,
    State.recovering,
    State.pausedByUser,
    State.pausedBySystem,
    State.stopping,
    State.cancelled,
    State.failedRecoverable,
    State.failedUnrecoverable,
  },
  State.signalLost: {
    State.awaitingInitialFix,
    State.recovering,
    State.pausedBySystem,
    State.stopping,
    State.cancelled,
    State.failedRecoverable,
    State.failedUnrecoverable,
  },
  State.recovering: {
    State.awaitingPermission,
    State.awaitingLocationServices,
    State.awaitingInitialFix,
    State.activeTracking,
    State.signalDegraded,
    State.signalLost,
    State.pausedBySystem,
    State.stopping,
    State.completionPending,
    State.cancelled,
    State.failedRecoverable,
    State.failedUnrecoverable,
  },
  State.stopping: {
    State.completionPending,
    State.cancelled,
    State.failedRecoverable,
    State.failedUnrecoverable,
  },
  State.completionPending: {
    State.completed,
    State.cancelled,
    State.failedRecoverable,
  },
  State.completed: {},
  State.cancelled: {},
  State.failedRecoverable: {
    State.preparing,
    State.awaitingInitialFix,
    State.recovering,
    State.stopping,
    State.completionPending,
    State.cancelled,
    State.failedUnrecoverable,
  },
  State.failedUnrecoverable: {},
};
