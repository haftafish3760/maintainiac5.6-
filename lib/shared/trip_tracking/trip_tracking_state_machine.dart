import 'trip_tracking_models.dart';

/// Allowed lifecycle transitions for a locally persisted GPS session.
class TripTrackingSessionStateMachine {
  const TripTrackingSessionStateMachine._();

  static bool canTransition(
    TripTrackingSessionLifecycleState from,
    TripTrackingSessionLifecycleState to,
  ) =>
      from == to ||
      _isCancellationTransition(from, to) ||
      (_legalTransitions[from]?.contains(to) ?? false);

  static bool _isCancellationTransition(
    TripTrackingSessionLifecycleState from,
    TripTrackingSessionLifecycleState to,
  ) =>
      to == TripTrackingSessionLifecycleState.cancelled &&
      from != TripTrackingSessionLifecycleState.disabled &&
      from != TripTrackingSessionLifecycleState.completed &&
      from != TripTrackingSessionLifecycleState.cancelled &&
      from != TripTrackingSessionLifecycleState.failedTerminal;

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
          TripTrackingSessionLifecycleState.stopping,
          TripTrackingSessionLifecycleState.failedTerminal,
        },
        TripTrackingSessionLifecycleState.ready: {
          TripTrackingSessionLifecycleState.starting,
          TripTrackingSessionLifecycleState.stopping,
          TripTrackingSessionLifecycleState.disabled,
        },
        TripTrackingSessionLifecycleState.starting: {
          TripTrackingSessionLifecycleState.active,
          TripTrackingSessionLifecycleState.paused,
          TripTrackingSessionLifecycleState.stopping,
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
          TripTrackingSessionLifecycleState.failedTerminal,
        },
        TripTrackingSessionLifecycleState.paused: {
          TripTrackingSessionLifecycleState.starting,
          TripTrackingSessionLifecycleState.stopping,
          TripTrackingSessionLifecycleState.failedTerminal,
        },
        TripTrackingSessionLifecycleState.degraded: {
          TripTrackingSessionLifecycleState.starting,
          TripTrackingSessionLifecycleState.active,
          TripTrackingSessionLifecycleState.recovering,
          TripTrackingSessionLifecycleState.interrupted,
          TripTrackingSessionLifecycleState.failedRecoverable,
          TripTrackingSessionLifecycleState.stopping,
          TripTrackingSessionLifecycleState.failedTerminal,
        },
        TripTrackingSessionLifecycleState.interrupted: {
          TripTrackingSessionLifecycleState.recovering,
          TripTrackingSessionLifecycleState.starting,
          TripTrackingSessionLifecycleState.failedRecoverable,
          TripTrackingSessionLifecycleState.stopping,
          TripTrackingSessionLifecycleState.failedTerminal,
        },
        TripTrackingSessionLifecycleState.recovering: {
          TripTrackingSessionLifecycleState.active,
          TripTrackingSessionLifecycleState.stopping,
          TripTrackingSessionLifecycleState.failedRecoverable,
          TripTrackingSessionLifecycleState.awaitingReview,
          TripTrackingSessionLifecycleState.failedTerminal,
        },
        TripTrackingSessionLifecycleState.awaitingReview: {
          TripTrackingSessionLifecycleState.completed,
        },
        TripTrackingSessionLifecycleState.stopping: {
          TripTrackingSessionLifecycleState.completed,
          TripTrackingSessionLifecycleState.failedRecoverable,
          TripTrackingSessionLifecycleState.failedTerminal,
        },
        TripTrackingSessionLifecycleState.completed: {},
        TripTrackingSessionLifecycleState.failedRecoverable: {
          TripTrackingSessionLifecycleState.recovering,
          TripTrackingSessionLifecycleState.starting,
          TripTrackingSessionLifecycleState.stopping,
          TripTrackingSessionLifecycleState.awaitingReview,
          TripTrackingSessionLifecycleState.failedTerminal,
        },
        TripTrackingSessionLifecycleState.failedTerminal: {
          TripTrackingSessionLifecycleState.disabled,
        },
        TripTrackingSessionLifecycleState.cancelled: {
          TripTrackingSessionLifecycleState.disabled,
        },
      };
}

class TripTrackingSessionContractStateMachine {
  const TripTrackingSessionContractStateMachine._();

  static bool canTransition(
    TripTrackingSessionLifecycleContractState from,
    TripTrackingSessionLifecycleContractState to,
  ) => TripTrackingSessionStateMachine.canTransition(
    from.toRuntimeState(),
    to.toRuntimeState(),
  );

  static void requireTransition(
    TripTrackingSessionLifecycleContractState from,
    TripTrackingSessionLifecycleContractState to,
  ) {
    if (!canTransition(from, to)) {
      throw StateError(
        'Illegal contract lifecycle transition: ${from.name} -> ${to.name}',
      );
    }
  }

  static TripTrackingLifecycleContractTransitionDecision evaluateTransition(
    TripTrackingSessionLifecycleContractState from,
    TripTrackingSessionLifecycleContractState to,
  ) {
    final runtimeDecision = TripTrackingSessionStateMachine.evaluateTransition(
      from.toRuntimeState(),
      to.toRuntimeState(),
    );

    return TripTrackingLifecycleContractTransitionDecision(
      from: from,
      to: to,
      allowed: runtimeDecision.allowed,
      reasonCode: runtimeDecision.reasonCode,
      requiresUserReview: runtimeDecision.requiresUserReview,
    );
  }
}

class TripTrackingLifecycleContractTransitionDecision {
  const TripTrackingLifecycleContractTransitionDecision({
    required this.from,
    required this.to,
    required this.allowed,
    required this.reasonCode,
    required this.requiresUserReview,
  });

  final TripTrackingSessionLifecycleContractState from;
  final TripTrackingSessionLifecycleContractState to;
  final bool allowed;
  final String reasonCode;
  final bool requiresUserReview;

  Map<String, Object?> toSafeSummary() => {
    'schemaVersion': 1,
    'from': from.name,
    'to': to.name,
    'allowed': allowed,
    'reasonCode': _safeTransitionReason(reasonCode),
    'requiresUserReview': requiresUserReview,
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
