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
          // Permission or location services can be restored without replacing
          // the preserved local session.
          TripTrackingSessionLifecycleState.starting,
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

  static const Map<
    TripTrackingSessionLifecycleContractState,
    Set<TripTrackingSessionLifecycleContractState>
  >
  _allowedTransitions = {
    TripTrackingSessionLifecycleContractState.IDLE: {
      TripTrackingSessionLifecycleContractState.PREPARING,
      TripTrackingSessionLifecycleContractState.AWAITING_PERMISSION,
      TripTrackingSessionLifecycleContractState.AWAITING_LOCATION_SERVICES,
      TripTrackingSessionLifecycleContractState.CANDIDATE_MOVEMENT,
    },
    TripTrackingSessionLifecycleContractState.PREPARING: {
      TripTrackingSessionLifecycleContractState.AWAITING_PERMISSION,
      TripTrackingSessionLifecycleContractState.AWAITING_LOCATION_SERVICES,
      TripTrackingSessionLifecycleContractState.AWAITING_INITIAL_FIX,
      TripTrackingSessionLifecycleContractState.IDLE,
      TripTrackingSessionLifecycleContractState.PAUSED_BY_USER,
      TripTrackingSessionLifecycleContractState.PAUSED_BY_SYSTEM,
      TripTrackingSessionLifecycleContractState.CANCELLED,
      TripTrackingSessionLifecycleContractState.FAILED_RECOVERABLE,
      TripTrackingSessionLifecycleContractState.FAILED_UNRECOVERABLE,
      TripTrackingSessionLifecycleContractState.COMPLETION_PENDING,
    },
    TripTrackingSessionLifecycleContractState.AWAITING_PERMISSION: {
      TripTrackingSessionLifecycleContractState.PREPARING,
      TripTrackingSessionLifecycleContractState.AWAITING_LOCATION_SERVICES,
      TripTrackingSessionLifecycleContractState.AWAITING_INITIAL_FIX,
      TripTrackingSessionLifecycleContractState.PAUSED_BY_USER,
      TripTrackingSessionLifecycleContractState.PAUSED_BY_SYSTEM,
      TripTrackingSessionLifecycleContractState.CANCELLED,
      TripTrackingSessionLifecycleContractState.FAILED_RECOVERABLE,
      TripTrackingSessionLifecycleContractState.FAILED_UNRECOVERABLE,
      TripTrackingSessionLifecycleContractState.COMPLETION_PENDING,
    },
    TripTrackingSessionLifecycleContractState.AWAITING_LOCATION_SERVICES: {
      TripTrackingSessionLifecycleContractState.PREPARING,
      TripTrackingSessionLifecycleContractState.AWAITING_PERMISSION,
      TripTrackingSessionLifecycleContractState.AWAITING_INITIAL_FIX,
      TripTrackingSessionLifecycleContractState.PAUSED_BY_USER,
      TripTrackingSessionLifecycleContractState.PAUSED_BY_SYSTEM,
      TripTrackingSessionLifecycleContractState.CANCELLED,
      TripTrackingSessionLifecycleContractState.FAILED_RECOVERABLE,
      TripTrackingSessionLifecycleContractState.FAILED_UNRECOVERABLE,
      TripTrackingSessionLifecycleContractState.COMPLETION_PENDING,
    },
    TripTrackingSessionLifecycleContractState.AWAITING_INITIAL_FIX: {
      TripTrackingSessionLifecycleContractState.ACTIVE_TRACKING,
      TripTrackingSessionLifecycleContractState.AWAITING_LOCATION_SERVICES,
      TripTrackingSessionLifecycleContractState.SIGNAL_DEGRADED,
      TripTrackingSessionLifecycleContractState.SIGNAL_LOST,
      TripTrackingSessionLifecycleContractState.AWAITING_PERMISSION,
      TripTrackingSessionLifecycleContractState.PAUSED_BY_USER,
      TripTrackingSessionLifecycleContractState.PAUSED_BY_SYSTEM,
      TripTrackingSessionLifecycleContractState.COMPLETION_PENDING,
      TripTrackingSessionLifecycleContractState.CANCELLED,
      TripTrackingSessionLifecycleContractState.FAILED_RECOVERABLE,
    },
    TripTrackingSessionLifecycleContractState.CANDIDATE_MOVEMENT: {
      TripTrackingSessionLifecycleContractState.IDLE,
      TripTrackingSessionLifecycleContractState.PREPARING,
      TripTrackingSessionLifecycleContractState.ACTIVE_TRACKING,
      TripTrackingSessionLifecycleContractState.CANCELLED,
      TripTrackingSessionLifecycleContractState.FAILED_RECOVERABLE,
    },
    TripTrackingSessionLifecycleContractState.ACTIVE_TRACKING: {
      TripTrackingSessionLifecycleContractState.AWAITING_INITIAL_FIX,
      TripTrackingSessionLifecycleContractState.TEMPORARILY_STOPPED,
      TripTrackingSessionLifecycleContractState.PAUSED_BY_USER,
      TripTrackingSessionLifecycleContractState.PAUSED_BY_SYSTEM,
      TripTrackingSessionLifecycleContractState.SIGNAL_DEGRADED,
      TripTrackingSessionLifecycleContractState.SIGNAL_LOST,
      TripTrackingSessionLifecycleContractState.COMPLETION_PENDING,
      TripTrackingSessionLifecycleContractState.CANCELLED,
      TripTrackingSessionLifecycleContractState.FAILED_RECOVERABLE,
      TripTrackingSessionLifecycleContractState.FAILED_UNRECOVERABLE,
    },
    TripTrackingSessionLifecycleContractState.TEMPORARILY_STOPPED: {
      TripTrackingSessionLifecycleContractState.ACTIVE_TRACKING,
      TripTrackingSessionLifecycleContractState.PAUSED_BY_USER,
      TripTrackingSessionLifecycleContractState.PAUSED_BY_SYSTEM,
      TripTrackingSessionLifecycleContractState.SIGNAL_DEGRADED,
      TripTrackingSessionLifecycleContractState.SIGNAL_LOST,
      TripTrackingSessionLifecycleContractState.COMPLETION_PENDING,
      TripTrackingSessionLifecycleContractState.CANCELLED,
      TripTrackingSessionLifecycleContractState.FAILED_RECOVERABLE,
    },
    TripTrackingSessionLifecycleContractState.PAUSED_BY_USER: {
      TripTrackingSessionLifecycleContractState.AWAITING_INITIAL_FIX,
      TripTrackingSessionLifecycleContractState.ACTIVE_TRACKING,
      TripTrackingSessionLifecycleContractState.PAUSED_BY_SYSTEM,
      TripTrackingSessionLifecycleContractState.RECOVERING,
      TripTrackingSessionLifecycleContractState.COMPLETION_PENDING,
      TripTrackingSessionLifecycleContractState.CANCELLED,
      TripTrackingSessionLifecycleContractState.FAILED_RECOVERABLE,
      TripTrackingSessionLifecycleContractState.FAILED_UNRECOVERABLE,
    },
    TripTrackingSessionLifecycleContractState.PAUSED_BY_SYSTEM: {
      TripTrackingSessionLifecycleContractState.AWAITING_INITIAL_FIX,
      TripTrackingSessionLifecycleContractState.ACTIVE_TRACKING,
      TripTrackingSessionLifecycleContractState.PAUSED_BY_USER,
      TripTrackingSessionLifecycleContractState.RECOVERING,
      TripTrackingSessionLifecycleContractState.COMPLETION_PENDING,
      TripTrackingSessionLifecycleContractState.CANCELLED,
      TripTrackingSessionLifecycleContractState.FAILED_RECOVERABLE,
      TripTrackingSessionLifecycleContractState.FAILED_UNRECOVERABLE,
    },
    TripTrackingSessionLifecycleContractState.SIGNAL_DEGRADED: {
      TripTrackingSessionLifecycleContractState.AWAITING_INITIAL_FIX,
      TripTrackingSessionLifecycleContractState.ACTIVE_TRACKING,
      TripTrackingSessionLifecycleContractState.TEMPORARILY_STOPPED,
      TripTrackingSessionLifecycleContractState.PAUSED_BY_USER,
      TripTrackingSessionLifecycleContractState.PAUSED_BY_SYSTEM,
      TripTrackingSessionLifecycleContractState.SIGNAL_LOST,
      TripTrackingSessionLifecycleContractState.RECOVERING,
      TripTrackingSessionLifecycleContractState.COMPLETION_PENDING,
      TripTrackingSessionLifecycleContractState.CANCELLED,
      TripTrackingSessionLifecycleContractState.FAILED_RECOVERABLE,
    },
    TripTrackingSessionLifecycleContractState.SIGNAL_LOST: {
      TripTrackingSessionLifecycleContractState.AWAITING_INITIAL_FIX,
      TripTrackingSessionLifecycleContractState.PAUSED_BY_USER,
      TripTrackingSessionLifecycleContractState.PAUSED_BY_SYSTEM,
      TripTrackingSessionLifecycleContractState.RECOVERING,
      TripTrackingSessionLifecycleContractState.COMPLETION_PENDING,
      TripTrackingSessionLifecycleContractState.CANCELLED,
      TripTrackingSessionLifecycleContractState.FAILED_RECOVERABLE,
      TripTrackingSessionLifecycleContractState.FAILED_UNRECOVERABLE,
    },
    TripTrackingSessionLifecycleContractState.RECOVERING: {
      TripTrackingSessionLifecycleContractState.ACTIVE_TRACKING,
      TripTrackingSessionLifecycleContractState.PAUSED_BY_USER,
      TripTrackingSessionLifecycleContractState.PAUSED_BY_SYSTEM,
      TripTrackingSessionLifecycleContractState.SIGNAL_DEGRADED,
      TripTrackingSessionLifecycleContractState.SIGNAL_LOST,
      TripTrackingSessionLifecycleContractState.COMPLETION_PENDING,
      TripTrackingSessionLifecycleContractState.CANCELLED,
      TripTrackingSessionLifecycleContractState.FAILED_RECOVERABLE,
      TripTrackingSessionLifecycleContractState.FAILED_UNRECOVERABLE,
    },
    TripTrackingSessionLifecycleContractState.COMPLETION_PENDING: {
      TripTrackingSessionLifecycleContractState.COMPLETED,
      TripTrackingSessionLifecycleContractState.CANCELLED,
      TripTrackingSessionLifecycleContractState.FAILED_RECOVERABLE,
      TripTrackingSessionLifecycleContractState.FAILED_UNRECOVERABLE,
    },
    TripTrackingSessionLifecycleContractState.COMPLETED: {
      TripTrackingSessionLifecycleContractState.IDLE,
    },
    TripTrackingSessionLifecycleContractState.CANCELLED: {
      TripTrackingSessionLifecycleContractState.IDLE,
    },
    TripTrackingSessionLifecycleContractState.FAILED_RECOVERABLE: {
      TripTrackingSessionLifecycleContractState.AWAITING_INITIAL_FIX,
      TripTrackingSessionLifecycleContractState.PAUSED_BY_SYSTEM,
      TripTrackingSessionLifecycleContractState.RECOVERING,
      TripTrackingSessionLifecycleContractState.COMPLETION_PENDING,
      TripTrackingSessionLifecycleContractState.CANCELLED,
      TripTrackingSessionLifecycleContractState.FAILED_UNRECOVERABLE,
    },
    TripTrackingSessionLifecycleContractState.FAILED_UNRECOVERABLE: {
      TripTrackingSessionLifecycleContractState.IDLE,
    },
  };

  static Set<TripTrackingSessionLifecycleContractState> allowedNextStates(
    TripTrackingSessionLifecycleContractState from,
  ) => Set.unmodifiable(_allowedTransitions[from] ?? const {});

  static bool canTransition(
    TripTrackingSessionLifecycleContractState from,
    TripTrackingSessionLifecycleContractState to,
  ) => _allowedTransitions[from]?.contains(to) ?? false;

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
    final allowed = canTransition(from, to);

    return TripTrackingLifecycleContractTransitionDecision(
      from: from,
      to: to,
      allowed: allowed,
      reasonCode: allowed
          ? 'gps_session_transition_allowed'
          : from == TripTrackingSessionLifecycleContractState.COMPLETION_PENDING
          ? 'review_required_before_transition'
          : 'illegal_gps_session_transition',
      requiresUserReview:
          !allowed ||
          to == TripTrackingSessionLifecycleContractState.COMPLETION_PENDING ||
          to == TripTrackingSessionLifecycleContractState.CANCELLED,
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
