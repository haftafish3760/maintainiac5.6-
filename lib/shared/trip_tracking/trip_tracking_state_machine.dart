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
          !allowed || to == TripTrackingSessionLifecycleState.completionPending,
    );
  }

  static const _legalTransitions =
      <
        TripTrackingSessionLifecycleState,
        Set<TripTrackingSessionLifecycleState>
      >{
        TripTrackingSessionLifecycleState.idle: {
          TripTrackingSessionLifecycleState.preparing,
          TripTrackingSessionLifecycleState.candidateMovement,
        },
        TripTrackingSessionLifecycleState.preparing: {
          TripTrackingSessionLifecycleState.awaitingPermission,
          TripTrackingSessionLifecycleState.awaitingLocationServices,
          TripTrackingSessionLifecycleState.awaitingInitialFix,
          TripTrackingSessionLifecycleState.pausedByUser,
          TripTrackingSessionLifecycleState.pausedBySystem,
          TripTrackingSessionLifecycleState.stopping,
          TripTrackingSessionLifecycleState.cancelled,
          TripTrackingSessionLifecycleState.failedRecoverable,
          TripTrackingSessionLifecycleState.failedUnrecoverable,
        },
        TripTrackingSessionLifecycleState.awaitingPermission: {
          TripTrackingSessionLifecycleState.preparing,
          TripTrackingSessionLifecycleState.awaitingLocationServices,
          TripTrackingSessionLifecycleState.awaitingInitialFix,
          TripTrackingSessionLifecycleState.pausedBySystem,
          TripTrackingSessionLifecycleState.stopping,
          TripTrackingSessionLifecycleState.cancelled,
          TripTrackingSessionLifecycleState.failedRecoverable,
          TripTrackingSessionLifecycleState.failedUnrecoverable,
        },
        TripTrackingSessionLifecycleState.awaitingLocationServices: {
          TripTrackingSessionLifecycleState.awaitingPermission,
          TripTrackingSessionLifecycleState.awaitingInitialFix,
          TripTrackingSessionLifecycleState.pausedBySystem,
          TripTrackingSessionLifecycleState.stopping,
          TripTrackingSessionLifecycleState.cancelled,
          TripTrackingSessionLifecycleState.failedRecoverable,
          TripTrackingSessionLifecycleState.failedUnrecoverable,
        },
        TripTrackingSessionLifecycleState.awaitingInitialFix: {
          TripTrackingSessionLifecycleState.awaitingPermission,
          TripTrackingSessionLifecycleState.awaitingLocationServices,
          TripTrackingSessionLifecycleState.candidateMovement,
          TripTrackingSessionLifecycleState.activeTracking,
          TripTrackingSessionLifecycleState.signalDegraded,
          TripTrackingSessionLifecycleState.signalLost,
          TripTrackingSessionLifecycleState.pausedByUser,
          TripTrackingSessionLifecycleState.pausedBySystem,
          TripTrackingSessionLifecycleState.stopping,
          TripTrackingSessionLifecycleState.cancelled,
          TripTrackingSessionLifecycleState.failedRecoverable,
          TripTrackingSessionLifecycleState.failedUnrecoverable,
        },
        TripTrackingSessionLifecycleState.candidateMovement: {
          TripTrackingSessionLifecycleState.awaitingInitialFix,
          TripTrackingSessionLifecycleState.activeTracking,
          TripTrackingSessionLifecycleState.temporarilyStopped,
          TripTrackingSessionLifecycleState.pausedByUser,
          TripTrackingSessionLifecycleState.pausedBySystem,
          TripTrackingSessionLifecycleState.signalDegraded,
          TripTrackingSessionLifecycleState.signalLost,
          TripTrackingSessionLifecycleState.stopping,
          TripTrackingSessionLifecycleState.cancelled,
          TripTrackingSessionLifecycleState.failedRecoverable,
        },
        TripTrackingSessionLifecycleState.activeTracking: {
          TripTrackingSessionLifecycleState.awaitingInitialFix,
          TripTrackingSessionLifecycleState.temporarilyStopped,
          TripTrackingSessionLifecycleState.pausedByUser,
          TripTrackingSessionLifecycleState.pausedBySystem,
          TripTrackingSessionLifecycleState.signalDegraded,
          TripTrackingSessionLifecycleState.signalLost,
          TripTrackingSessionLifecycleState.stopping,
          TripTrackingSessionLifecycleState.failedRecoverable,
          TripTrackingSessionLifecycleState.failedUnrecoverable,
        },
        TripTrackingSessionLifecycleState.temporarilyStopped: {
          TripTrackingSessionLifecycleState.candidateMovement,
          TripTrackingSessionLifecycleState.activeTracking,
          TripTrackingSessionLifecycleState.pausedByUser,
          TripTrackingSessionLifecycleState.pausedBySystem,
          TripTrackingSessionLifecycleState.signalDegraded,
          TripTrackingSessionLifecycleState.signalLost,
          TripTrackingSessionLifecycleState.stopping,
          TripTrackingSessionLifecycleState.failedRecoverable,
        },
        TripTrackingSessionLifecycleState.pausedByUser: {
          TripTrackingSessionLifecycleState.preparing,
          TripTrackingSessionLifecycleState.awaitingInitialFix,
          TripTrackingSessionLifecycleState.stopping,
          TripTrackingSessionLifecycleState.cancelled,
        },
        TripTrackingSessionLifecycleState.pausedBySystem: {
          TripTrackingSessionLifecycleState.preparing,
          TripTrackingSessionLifecycleState.awaitingPermission,
          TripTrackingSessionLifecycleState.awaitingLocationServices,
          TripTrackingSessionLifecycleState.awaitingInitialFix,
          TripTrackingSessionLifecycleState.recovering,
          TripTrackingSessionLifecycleState.stopping,
          TripTrackingSessionLifecycleState.cancelled,
          TripTrackingSessionLifecycleState.failedRecoverable,
          TripTrackingSessionLifecycleState.failedUnrecoverable,
        },
        TripTrackingSessionLifecycleState.signalDegraded: {
          TripTrackingSessionLifecycleState.activeTracking,
          TripTrackingSessionLifecycleState.temporarilyStopped,
          TripTrackingSessionLifecycleState.signalLost,
          TripTrackingSessionLifecycleState.recovering,
          TripTrackingSessionLifecycleState.pausedByUser,
          TripTrackingSessionLifecycleState.pausedBySystem,
          TripTrackingSessionLifecycleState.stopping,
          TripTrackingSessionLifecycleState.failedRecoverable,
          TripTrackingSessionLifecycleState.failedUnrecoverable,
        },
        TripTrackingSessionLifecycleState.signalLost: {
          TripTrackingSessionLifecycleState.awaitingInitialFix,
          TripTrackingSessionLifecycleState.recovering,
          TripTrackingSessionLifecycleState.pausedBySystem,
          TripTrackingSessionLifecycleState.stopping,
          TripTrackingSessionLifecycleState.failedRecoverable,
          TripTrackingSessionLifecycleState.failedUnrecoverable,
        },
        TripTrackingSessionLifecycleState.recovering: {
          TripTrackingSessionLifecycleState.awaitingPermission,
          TripTrackingSessionLifecycleState.awaitingLocationServices,
          TripTrackingSessionLifecycleState.awaitingInitialFix,
          TripTrackingSessionLifecycleState.activeTracking,
          TripTrackingSessionLifecycleState.signalDegraded,
          TripTrackingSessionLifecycleState.signalLost,
          TripTrackingSessionLifecycleState.pausedBySystem,
          TripTrackingSessionLifecycleState.stopping,
          TripTrackingSessionLifecycleState.completionPending,
          TripTrackingSessionLifecycleState.failedRecoverable,
          TripTrackingSessionLifecycleState.failedUnrecoverable,
        },
        TripTrackingSessionLifecycleState.stopping: {
          TripTrackingSessionLifecycleState.completionPending,
          TripTrackingSessionLifecycleState.failedRecoverable,
          TripTrackingSessionLifecycleState.failedUnrecoverable,
        },
        TripTrackingSessionLifecycleState.completionPending: {
          TripTrackingSessionLifecycleState.completed,
          TripTrackingSessionLifecycleState.cancelled,
          TripTrackingSessionLifecycleState.failedRecoverable,
        },
        TripTrackingSessionLifecycleState.completed: {},
        TripTrackingSessionLifecycleState.cancelled: {},
        TripTrackingSessionLifecycleState.failedRecoverable: {
          TripTrackingSessionLifecycleState.preparing,
          TripTrackingSessionLifecycleState.awaitingInitialFix,
          TripTrackingSessionLifecycleState.recovering,
          TripTrackingSessionLifecycleState.stopping,
          TripTrackingSessionLifecycleState.completionPending,
          TripTrackingSessionLifecycleState.cancelled,
          TripTrackingSessionLifecycleState.failedUnrecoverable,
        },
        TripTrackingSessionLifecycleState.failedUnrecoverable: {},
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
  if (from == TripTrackingSessionLifecycleState.completionPending &&
      to != TripTrackingSessionLifecycleState.completed) {
    return 'review_required_before_transition';
  }
  if (from == TripTrackingSessionLifecycleState.failedUnrecoverable &&
      to != TripTrackingSessionLifecycleState.idle) {
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
        to == TripTrackingSessionLifecycleState.completionPending;
  }
  return true;
}
