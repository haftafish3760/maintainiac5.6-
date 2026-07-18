import 'trip_tracking_models.dart';
import 'trip_tracking_platform.dart';
import 'trip_tracking_state_machine.dart';

enum TripNativeEventLifecycleAction {
  ingestLocation,
  ingestActivity,
  requestUserPermissionReview,
  markDegraded,
  markInterrupted,
  recoverLocally,
  ignoreEvent,
}

enum TripNativeEventLifecycleReason {
  activeLocationSample,
  activeActivitySample,
  permissionRequired,
  providerUnavailable,
  backgroundRestricted,
  nativeTrackingStatus,
  nativePausedStatus,
  nativeRecoveringStatus,
  nativeStoppedStatusIgnored,
  malformedNativeEvent,
  completedSessionProtected,
  illegalTransitionRejected,
}

class TripNativeEventLifecycleDecision {
  const TripNativeEventLifecycleDecision({
    required this.action,
    required this.reason,
    required this.from,
    required this.to,
    required this.transitionAllowed,
    required this.canFeedEngine,
    required this.requiresUserReview,
  });

  final TripNativeEventLifecycleAction action;
  final TripNativeEventLifecycleReason reason;
  final TripTrackingSessionLifecycleState from;
  final TripTrackingSessionLifecycleState to;
  final bool transitionAllowed;
  final bool canFeedEngine;
  final bool requiresUserReview;

  Map<String, Object?> toSafeSummary() => {
    'schemaVersion': 1,
    'action': action.name,
    'reason': reason.name,
    'from': from.name,
    'to': to.name,
    'transitionAllowed': transitionAllowed,
    'canFeedEngine': canFeedEngine && transitionAllowed,
    'requiresUserReview': requiresUserReview,
    'nativeEventTrustedAfterValidationOnly': true,
    'localLifecycleAuthoritative': true,
    'nativeEventCanForceComplete': false,
    'nativeEventCanDeleteCheckpoint': false,
    'nativeEventCanConfirmOdometer': false,
    'nativeEventCanCreateOfficialStop': false,
    'mapboxEventCanForceLifecycle': false,
    'firestoreEventCanForceLifecycle': false,
    'cloudFunctionCanForceLifecycle': false,
    'remoteLifecycleCanOverrideLocalCheckpoint': false,
    'backgroundPauseRequiresRecoveryPath': true,
    'permissionLossRequiresUserReview': true,
    'completedSessionCanResume': false,
    'odometerRemainsOfficialMileageTruth': true,
    'rawNativePayloadIncluded': false,
    'rawLocationIncluded': false,
    'preciseTimestampIncluded': false,
    'tokensIncluded': false,
  };
}

class TripNativeEventLifecyclePolicy {
  const TripNativeEventLifecyclePolicy._();

  static TripNativeEventLifecycleDecision evaluate({
    required TripTrackingSessionLifecycleState currentState,
    required TripTrackingPlatformEvent event,
  }) {
    if (currentState == TripTrackingSessionLifecycleState.completed) {
      return _decision(
        action: TripNativeEventLifecycleAction.ignoreEvent,
        reason: TripNativeEventLifecycleReason.completedSessionProtected,
        from: currentState,
        to: currentState,
        canFeedEngine: false,
        requiresUserReview: true,
      );
    }
    if (currentState == TripTrackingSessionLifecycleState.failedTerminal) {
      return _decision(
        action: TripNativeEventLifecycleAction.ignoreEvent,
        reason: TripNativeEventLifecycleReason.illegalTransitionRejected,
        from: currentState,
        to: currentState,
        canFeedEngine: false,
        requiresUserReview: true,
      );
    }
    final target = _targetState(currentState, event);
    final transition = TripTrackingSessionStateMachine.evaluateTransition(
      currentState,
      target.state,
    );
    if (!transition.allowed) {
      return _decision(
        action: TripNativeEventLifecycleAction.ignoreEvent,
        reason: TripNativeEventLifecycleReason.illegalTransitionRejected,
        from: currentState,
        to: currentState,
        canFeedEngine: false,
        requiresUserReview: true,
      );
    }
    return _decision(
      action: target.action,
      reason: target.reason,
      from: currentState,
      to: target.state,
      canFeedEngine: target.canFeedEngine,
      requiresUserReview:
          target.requiresUserReview || transition.requiresUserReview,
    );
  }
}

_NativeTarget _targetState(
  TripTrackingSessionLifecycleState currentState,
  TripTrackingPlatformEvent event,
) {
  return switch (event.type) {
    TripTrackingPlatformEventType.location => _NativeTarget(
      state: _activeCompatibleState(currentState),
      action: TripNativeEventLifecycleAction.ingestLocation,
      reason: TripNativeEventLifecycleReason.activeLocationSample,
      canFeedEngine: _locationCanFeedEngine(currentState),
      requiresUserReview: !_locationCanFeedEngine(currentState),
    ),
    TripTrackingPlatformEventType.activity => _NativeTarget(
      state: _activeCompatibleState(currentState),
      action: TripNativeEventLifecycleAction.ingestActivity,
      reason: TripNativeEventLifecycleReason.activeActivitySample,
      canFeedEngine: false,
    ),
    TripTrackingPlatformEventType.authorization => _authorizationTarget(
      event.authorization,
    ),
    TripTrackingPlatformEventType.status => _statusTarget(
      currentState,
      event.status,
    ),
    TripTrackingPlatformEventType.error => _NativeTarget(
      state: TripTrackingSessionLifecycleState.failedRecoverable,
      action: TripNativeEventLifecycleAction.markInterrupted,
      reason: TripNativeEventLifecycleReason.malformedNativeEvent,
      canFeedEngine: false,
      requiresUserReview: true,
    ),
  };
}

bool _locationCanFeedEngine(TripTrackingSessionLifecycleState currentState) {
  return switch (currentState) {
    TripTrackingSessionLifecycleState.disabled ||
    TripTrackingSessionLifecycleState.permissionRequired ||
    TripTrackingSessionLifecycleState.awaitingReview ||
    TripTrackingSessionLifecycleState.completed ||
    TripTrackingSessionLifecycleState.failedTerminal => false,
    _ => true,
  };
}

TripTrackingSessionLifecycleState _activeCompatibleState(
  TripTrackingSessionLifecycleState currentState,
) {
  return switch (currentState) {
    TripTrackingSessionLifecycleState.starting ||
    TripTrackingSessionLifecycleState.degraded ||
    TripTrackingSessionLifecycleState.recovering ||
    TripTrackingSessionLifecycleState.failedRecoverable =>
      TripTrackingSessionLifecycleState.active,
    _ => currentState,
  };
}

_NativeTarget _authorizationTarget(TripTrackingAuthorization? authorization) {
  final state = authorization?.state;
  if (state == TripTrackingAuthorizationState.denied ||
      state == TripTrackingAuthorizationState.restricted ||
      state == TripTrackingAuthorizationState.notDetermined) {
    return _NativeTarget(
      state: TripTrackingSessionLifecycleState.permissionRequired,
      action: TripNativeEventLifecycleAction.requestUserPermissionReview,
      reason: TripNativeEventLifecycleReason.permissionRequired,
      canFeedEngine: false,
      requiresUserReview: true,
    );
  }
  return const _NativeTarget(
    state: TripTrackingSessionLifecycleState.active,
    action: TripNativeEventLifecycleAction.recoverLocally,
    reason: TripNativeEventLifecycleReason.nativeTrackingStatus,
    canFeedEngine: false,
  );
}

_NativeTarget _statusTarget(
  TripTrackingSessionLifecycleState currentState,
  String? status,
) {
  return switch (status) {
    'tracking' => _NativeTarget(
      state: _activeCompatibleState(currentState),
      action: TripNativeEventLifecycleAction.recoverLocally,
      reason: TripNativeEventLifecycleReason.nativeTrackingStatus,
      canFeedEngine: false,
    ),
    'paused' => const _NativeTarget(
      state: TripTrackingSessionLifecycleState.paused,
      action: TripNativeEventLifecycleAction.markInterrupted,
      reason: TripNativeEventLifecycleReason.nativePausedStatus,
      canFeedEngine: false,
    ),
    'recovering' => const _NativeTarget(
      state: TripTrackingSessionLifecycleState.recovering,
      action: TripNativeEventLifecycleAction.recoverLocally,
      reason: TripNativeEventLifecycleReason.nativeRecoveringStatus,
      canFeedEngine: false,
    ),
    'degraded' || 'providerUnavailable' => const _NativeTarget(
      state: TripTrackingSessionLifecycleState.degraded,
      action: TripNativeEventLifecycleAction.markDegraded,
      reason: TripNativeEventLifecycleReason.providerUnavailable,
      canFeedEngine: false,
    ),
    'backgroundRestricted' => const _NativeTarget(
      state: TripTrackingSessionLifecycleState.interrupted,
      action: TripNativeEventLifecycleAction.markInterrupted,
      reason: TripNativeEventLifecycleReason.backgroundRestricted,
      canFeedEngine: false,
      requiresUserReview: true,
    ),
    'permissionRequired' => const _NativeTarget(
      state: TripTrackingSessionLifecycleState.permissionRequired,
      action: TripNativeEventLifecycleAction.requestUserPermissionReview,
      reason: TripNativeEventLifecycleReason.permissionRequired,
      canFeedEngine: false,
      requiresUserReview: true,
    ),
    'stopped' => _NativeTarget(
      state: currentState,
      action: TripNativeEventLifecycleAction.ignoreEvent,
      reason: TripNativeEventLifecycleReason.nativeStoppedStatusIgnored,
      canFeedEngine: false,
      requiresUserReview: true,
    ),
    _ => const _NativeTarget(
      state: TripTrackingSessionLifecycleState.failedRecoverable,
      action: TripNativeEventLifecycleAction.markInterrupted,
      reason: TripNativeEventLifecycleReason.malformedNativeEvent,
      canFeedEngine: false,
      requiresUserReview: true,
    ),
  };
}

TripNativeEventLifecycleDecision _decision({
  required TripNativeEventLifecycleAction action,
  required TripNativeEventLifecycleReason reason,
  required TripTrackingSessionLifecycleState from,
  required TripTrackingSessionLifecycleState to,
  required bool canFeedEngine,
  required bool requiresUserReview,
}) {
  final transitionAllowed = TripTrackingSessionStateMachine.canTransition(
    from,
    to,
  );
  return TripNativeEventLifecycleDecision(
    action: action,
    reason: reason,
    from: from,
    to: transitionAllowed ? to : from,
    transitionAllowed: transitionAllowed,
    canFeedEngine: canFeedEngine && transitionAllowed,
    requiresUserReview: requiresUserReview || !transitionAllowed,
  );
}

class _NativeTarget {
  const _NativeTarget({
    required this.state,
    required this.action,
    required this.reason,
    required this.canFeedEngine,
    this.requiresUserReview = false,
  });

  final TripTrackingSessionLifecycleState state;
  final TripNativeEventLifecycleAction action;
  final TripNativeEventLifecycleReason reason;
  final bool canFeedEngine;
  final bool requiresUserReview;
}
