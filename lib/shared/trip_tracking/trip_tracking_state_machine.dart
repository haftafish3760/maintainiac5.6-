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

  static TripTrackingLifecycleTransitionDecision evaluateTransition(
    TripTrackingSessionLifecycleState from,
    TripTrackingSessionLifecycleState to,
  ) {
    final allowed = canTransition(from, to);
    return TripTrackingLifecycleTransitionDecision(
      from: from,
      to: to,
      allowed: allowed,
      reasonCode: allowed
          ? 'gps_session_transition_allowed'
          : _rejectedReason(from, to),
      requiresUserReview:
          !allowed || to == TripTrackingSessionLifecycleState.awaitingReview,
    );
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
          // Native collection may have stopped while a local checkpoint was
          // temporarily unavailable. A later retry can safely re-enter the
          // start handshake for this still-recoverable trip.
          TripTrackingSessionLifecycleState.starting,
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
          TripTrackingSessionLifecycleState.starting,
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
        TripTrackingSessionLifecycleState.completed: {},
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

class TripTrackingLifecycleTransitionDecision {
  const TripTrackingLifecycleTransitionDecision({
    required this.from,
    required this.to,
    required this.allowed,
    required this.reasonCode,
    required this.requiresUserReview,
  });

  final TripTrackingSessionLifecycleState from;
  final TripTrackingSessionLifecycleState to;
  final bool allowed;
  final String reasonCode;
  final bool requiresUserReview;

  Map<String, Object?> toSafeSummary() => {
    'schemaVersion': 1,
    'from': from.name,
    'to': to.name,
    'allowed': _safeTransitionAllowed(
      from: from,
      to: to,
      allowed: allowed,
      reasonCode: reasonCode,
    ),
    'reasonCode': _safeTransitionReason(reasonCode),
    'requiresUserReview': _safeRequiresTransitionReview(
      from: from,
      to: to,
      allowed: allowed,
      reasonCode: reasonCode,
      requiresUserReview: requiresUserReview,
    ),
    'localLifecycleAuthoritative': true,
    'transitionTrustedAfterValidationOnly': true,
    'remoteLifecycleCanOverrideLocalCheckpoint': false,
    'firestoreCanForceLifecycleTransition': false,
    'cloudFunctionCanForceLifecycleTransition': false,
    'nativeEventCanForceComplete': false,
    'mapboxEventCanForceComplete': false,
    'remoteEventCanForceComplete': false,
    'backgroundPauseCanDeleteCheckpoint': false,
    'backgroundInterruptionRequiresRecovery': true,
    'permissionLossRequiresUserReview': true,
    'localCheckpointPreservedAcrossInterruption': true,
    'completedSessionCanResume': false,
    'failedTerminalRequiresFreshOptIn': true,
    'recoveryRequiresLocalCheckpoint': true,
    'odometerRemainsCanonical': true,
    'odometerIsGlobalTruth': true,
    'rawNativePayloadIncluded': false,
    'rawLocationIncluded': false,
    'rawMapboxPayloadIncluded': false,
  };
}

String _rejectedReason(
  TripTrackingSessionLifecycleState from,
  TripTrackingSessionLifecycleState to,
) {
  if (from == TripTrackingSessionLifecycleState.completed) {
    return 'completed_session_cannot_resume';
  }
  if (from == TripTrackingSessionLifecycleState.awaitingReview &&
      to != TripTrackingSessionLifecycleState.completed) {
    return 'review_required_before_transition';
  }
  if (from == TripTrackingSessionLifecycleState.failedTerminal &&
      to != TripTrackingSessionLifecycleState.disabled) {
    return 'terminal_failure_requires_fresh_opt_in';
  }
  return 'illegal_gps_session_transition';
}

String _safeTransitionReason(String value) {
  return switch (value) {
    'gps_session_transition_allowed' => value,
    'completed_session_cannot_resume' => value,
    'review_required_before_transition' => value,
    'terminal_failure_requires_fresh_opt_in' => value,
    'illegal_gps_session_transition' => value,
    _ => 'illegal_gps_session_transition',
  };
}

bool _safeTransitionAllowed({
  required TripTrackingSessionLifecycleState from,
  required TripTrackingSessionLifecycleState to,
  required bool allowed,
  required String reasonCode,
}) =>
    allowed &&
    _safeTransitionReason(reasonCode) == 'gps_session_transition_allowed' &&
    TripTrackingSessionStateMachine.canTransition(from, to);

bool _safeRequiresTransitionReview({
  required TripTrackingSessionLifecycleState from,
  required TripTrackingSessionLifecycleState to,
  required bool allowed,
  required String reasonCode,
  required bool requiresUserReview,
}) {
  if (_safeTransitionAllowed(
    from: from,
    to: to,
    allowed: allowed,
    reasonCode: reasonCode,
  )) {
    return requiresUserReview ||
        to == TripTrackingSessionLifecycleState.awaitingReview;
  }
  return true;
}
