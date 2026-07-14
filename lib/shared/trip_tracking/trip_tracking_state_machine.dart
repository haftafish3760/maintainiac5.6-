import 'trip_tracking_models.dart';

/// Allowed lifecycle transitions for a locally persisted GPS session.
class TripTrackingSessionStateMachine {
  const TripTrackingSessionStateMachine._();

  static bool canTransition(
    TripTrackingSessionLifecycleState from,
    TripTrackingSessionLifecycleState to,
  ) => from == to || (_legalTransitions[from]?.contains(to) ?? false);

  static void requireTransition(
    TripTrackingSessionLifecycleState from,
    TripTrackingSessionLifecycleState to,
  ) {
    if (!canTransition(from, to)) {
      throw StateError(
        'Illegal GPS session transition: ${from.name} -> ${to.name}',
      );
    }
  }

  static const _legalTransitions =
      <
        TripTrackingSessionLifecycleState,
        Set<TripTrackingSessionLifecycleState>
      >{
        TripTrackingSessionLifecycleState.disabled: {
          TripTrackingSessionLifecycleState.permissionRequired,
          TripTrackingSessionLifecycleState.ready,
        },
        TripTrackingSessionLifecycleState.permissionRequired: {
          TripTrackingSessionLifecycleState.ready,
          TripTrackingSessionLifecycleState.failedTerminal,
        },
        TripTrackingSessionLifecycleState.ready: {
          TripTrackingSessionLifecycleState.starting,
          TripTrackingSessionLifecycleState.disabled,
        },
        TripTrackingSessionLifecycleState.starting: {
          TripTrackingSessionLifecycleState.active,
          TripTrackingSessionLifecycleState.failedRecoverable,
          TripTrackingSessionLifecycleState.permissionRequired,
        },
        TripTrackingSessionLifecycleState.active: {
          TripTrackingSessionLifecycleState.paused,
          TripTrackingSessionLifecycleState.degraded,
          TripTrackingSessionLifecycleState.interrupted,
          TripTrackingSessionLifecycleState.stopping,
          TripTrackingSessionLifecycleState.failedRecoverable,
        },
        TripTrackingSessionLifecycleState.paused: {
          TripTrackingSessionLifecycleState.starting,
          TripTrackingSessionLifecycleState.stopping,
        },
        TripTrackingSessionLifecycleState.degraded: {
          TripTrackingSessionLifecycleState.active,
          TripTrackingSessionLifecycleState.recovering,
          TripTrackingSessionLifecycleState.failedRecoverable,
          TripTrackingSessionLifecycleState.stopping,
        },
        TripTrackingSessionLifecycleState.interrupted: {
          TripTrackingSessionLifecycleState.recovering,
          TripTrackingSessionLifecycleState.starting,
          TripTrackingSessionLifecycleState.failedRecoverable,
          TripTrackingSessionLifecycleState.stopping,
        },
        TripTrackingSessionLifecycleState.recovering: {
          TripTrackingSessionLifecycleState.active,
          TripTrackingSessionLifecycleState.failedRecoverable,
          TripTrackingSessionLifecycleState.awaitingReview,
        },
        TripTrackingSessionLifecycleState.awaitingReview: {
          TripTrackingSessionLifecycleState.completed,
        },
        TripTrackingSessionLifecycleState.stopping: {
          TripTrackingSessionLifecycleState.completed,
          TripTrackingSessionLifecycleState.failedRecoverable,
        },
        TripTrackingSessionLifecycleState.completed: {
          TripTrackingSessionLifecycleState.disabled,
        },
        TripTrackingSessionLifecycleState.failedRecoverable: {
          TripTrackingSessionLifecycleState.recovering,
          TripTrackingSessionLifecycleState.starting,
          TripTrackingSessionLifecycleState.stopping,
          TripTrackingSessionLifecycleState.awaitingReview,
        },
        TripTrackingSessionLifecycleState.failedTerminal: {
          TripTrackingSessionLifecycleState.disabled,
        },
      };
}
