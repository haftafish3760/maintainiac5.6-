import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_state_machine.dart';

typedef State = TripTrackingSessionLifecycleState;

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
    State.failedTerminal,
    State.cancelled,
  },
  State.paused: {
    State.starting,
    State.stopping,
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
    State.failedTerminal,
    State.cancelled,
  },
  State.interrupted: {
    State.paused,
    State.recovering,
    State.starting,
    State.failedRecoverable,
    State.stopping,
    State.failedTerminal,
    State.cancelled,
  },
  State.recovering: {
    State.active,
    State.paused,
    State.stopping,
    State.failedRecoverable,
    State.awaitingReview,
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
    State.failedTerminal,
    State.cancelled,
  },
  State.failedTerminal: {State.disabled},
  State.cancelled: {State.disabled},
};
