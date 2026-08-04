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
  automaticEvidenceRequiresSeparateReview,
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
    'nativeEventCanSetGlobalTruth': false,
    'nativeEventCanChangeOfficialMileage': false,
    'nativeEventCanCreateOfficialStop': false,
    'mapboxEventCanForceLifecycle': false,
    'firestoreEventCanForceLifecycle': false,
    'cloudFunctionCanForceLifecycle': false,
    'remoteLifecycleCanOverrideLocalCheckpoint': false,
    'nativeEventCanPurgeLocalDataAfterBackup': false,
    'nativeEventCanBypassLocalCheckpoint': false,
    'nativeEventCanBypassAuthorization': false,
    'nativeEventCanBypassUserConsent': false,
    'backgroundPauseRequiresRecoveryPath': true,
    'backgroundRestrictionCanOnlyInterruptRecoverably': true,
    'foregroundServiceLossRequiresRecoveryPath': true,
    'permissionLossCannotFeedEngine': true,
    'activityEventCannotFeedDistanceEngine': true,
    'lateNativeStoppedStatusCannotEndTrip': true,
    'nativeStatusRequiresLocalStateMachineTransition': true,
    'permissionLossRequiresUserReview': true,
    'completedSessionCanResume': false,
    'odometerRemainsOfficialMileageTruth': true,
    'odometerIsGlobalTruth': true,
    'physicalOdometerRequiredForOfficialMileage': true,
    'confirmedOdometerOverridesExternalMileage': true,
    'externalMileageCannotBecomeGlobalTruth': true,
    'gpsDistanceCanOnlyAdviseMileageReview': true,
    'mapMatchingCanOnlyAdviseMileageReview': true,
    'optimizationCannotChangeOfficialMileage': true,
    'rawNativePayloadIncluded': false,
    'rawLocationIncluded': false,
    'preciseTimestampIncluded': false,
    'tokensIncluded': false,
  };
}

class TripNativeEventLifecycleSummaryValidation {
  const TripNativeEventLifecycleSummaryValidation._({
    required this.isRenderable,
    required this.action,
    required this.reasons,
  });

  factory TripNativeEventLifecycleSummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    final action = _safeAction(summary['action']);
    if (summary['schemaVersion'] != 1) {
      reasons.add('unsupported_schema_version');
    }
    if (action == null) reasons.add('invalid_native_action');
    if (_safeLifecycleReason(summary['reason']) == null) {
      reasons.add('invalid_native_reason');
    }
    if (_safeLifecycleState(summary['from']) == null ||
        _safeLifecycleState(summary['to']) == null) {
      reasons.add('invalid_lifecycle_state');
    }
    if (summary['canFeedEngine'] == true &&
        (summary['transitionAllowed'] != true ||
            action != TripNativeEventLifecycleAction.ingestLocation)) {
      reasons.add('unsafe_engine_feed_claim');
    }
    if (summary['nativeEventTrustedAfterValidationOnly'] != true ||
        summary['localLifecycleAuthoritative'] != true ||
        summary['nativeStatusRequiresLocalStateMachineTransition'] != true) {
      reasons.add('native_lifecycle_boundary_missing');
    }
    if (summary['nativeEventCanForceComplete'] != false ||
        summary['nativeEventCanDeleteCheckpoint'] != false ||
        summary['nativeEventCanConfirmOdometer'] != false ||
        summary['nativeEventCanSetGlobalTruth'] != false ||
        summary['nativeEventCanChangeOfficialMileage'] != false ||
        summary['nativeEventCanCreateOfficialStop'] != false ||
        summary['nativeEventCanPurgeLocalDataAfterBackup'] != false ||
        summary['nativeEventCanBypassLocalCheckpoint'] != false) {
      reasons.add('native_event_can_mutate_trip_truth');
    }
    if (summary['mapboxEventCanForceLifecycle'] != false ||
        summary['firestoreEventCanForceLifecycle'] != false ||
        summary['cloudFunctionCanForceLifecycle'] != false ||
        summary['remoteLifecycleCanOverrideLocalCheckpoint'] != false) {
      reasons.add('remote_event_can_force_lifecycle');
    }
    if (summary['nativeEventCanBypassAuthorization'] != false ||
        summary['nativeEventCanBypassUserConsent'] != false ||
        summary['permissionLossRequiresUserReview'] != true) {
      reasons.add('permission_boundary_missing');
    }
    if (summary['backgroundPauseRequiresRecoveryPath'] != true ||
        summary['backgroundRestrictionCanOnlyInterruptRecoverably'] != true ||
        summary['foregroundServiceLossRequiresRecoveryPath'] != true ||
        summary['permissionLossCannotFeedEngine'] != true ||
        summary['activityEventCannotFeedDistanceEngine'] != true ||
        summary['lateNativeStoppedStatusCannotEndTrip'] != true ||
        summary['completedSessionCanResume'] != false) {
      reasons.add('interruption_recovery_boundary_missing');
    }
    if (summary['odometerRemainsOfficialMileageTruth'] != true ||
        summary['odometerIsGlobalTruth'] != true ||
        summary['physicalOdometerRequiredForOfficialMileage'] != true ||
        summary['confirmedOdometerOverridesExternalMileage'] != true ||
        summary['externalMileageCannotBecomeGlobalTruth'] != true ||
        summary['gpsDistanceCanOnlyAdviseMileageReview'] != true ||
        summary['mapMatchingCanOnlyAdviseMileageReview'] != true ||
        summary['optimizationCannotChangeOfficialMileage'] != true) {
      reasons.add('odometer_truth_boundary_missing');
    }
    if (summary['rawNativePayloadIncluded'] != false ||
        summary['rawLocationIncluded'] != false ||
        summary['preciseTimestampIncluded'] != false ||
        summary['tokensIncluded'] != false) {
      reasons.add('summary_contains_sensitive_native_material');
    }
    final boundaryRisk = _nativeLifecycleBoundaryRisk(summary, action);
    if (boundaryRisk != null) reasons.add(boundaryRisk);
    if (summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_text');
    }

    return TripNativeEventLifecycleSummaryValidation._(
      isRenderable: reasons.isEmpty,
      action: reasons.isEmpty ? action : null,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final TripNativeEventLifecycleAction? action;
  final List<String> reasons;
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
    // App Assistant observations use their own review-only runtime path.
    // They must never mutate an active trip lifecycle or feed its distance
    // engine, even though both collectors share the native event channel.
    TripTrackingPlatformEventType.automaticEvidenceLocation ||
    TripTrackingPlatformEventType.automaticEvidenceActivity => _NativeTarget(
      state: currentState,
      action: TripNativeEventLifecycleAction.ignoreEvent,
      reason: TripNativeEventLifecycleReason
          .automaticEvidenceRequiresSeparateReview,
      canFeedEngine: false,
      requiresUserReview: true,
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
    TripTrackingSessionLifecycleState.paused ||
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

TripNativeEventLifecycleAction? _safeAction(Object? value) {
  if (value is! String) return null;
  for (final action in TripNativeEventLifecycleAction.values) {
    if (action.name == value) return action;
  }
  return null;
}

TripNativeEventLifecycleReason? _safeLifecycleReason(Object? value) {
  if (value is! String) return null;
  for (final reason in TripNativeEventLifecycleReason.values) {
    if (reason.name == value) return reason;
  }
  return null;
}

TripTrackingSessionLifecycleState? _safeLifecycleState(Object? value) {
  if (value is! String) return null;
  for (final state in TripTrackingSessionLifecycleState.values) {
    if (state.name == value) return state;
  }
  return null;
}

String? _nativeLifecycleBoundaryRisk(
  Map<String, Object?> summary,
  TripNativeEventLifecycleAction? action,
) {
  final transition = summary['transitionAllowed'];
  final canFeed = summary['canFeedEngine'];
  final review = summary['requiresUserReview'];
  final reason = _safeLifecycleReason(summary['reason']);
  final from = _safeLifecycleState(summary['from']);
  final to = _safeLifecycleState(summary['to']);
  if (action == null ||
      transition is! bool ||
      canFeed is! bool ||
      review is! bool ||
      from == null ||
      to == null) {
    return null;
  }
  if (canFeed &&
      (action != TripNativeEventLifecycleAction.ingestLocation ||
          !transition ||
          from == TripTrackingSessionLifecycleState.paused ||
          from == TripTrackingSessionLifecycleState.permissionRequired)) {
    return 'native_lifecycle_status_conflicts_with_authority';
  }
  if (!transition && to != from) {
    return 'native_lifecycle_status_conflicts_with_authority';
  }
  if (action == TripNativeEventLifecycleAction.requestUserPermissionReview &&
      (!review || canFeed)) {
    return 'native_lifecycle_status_conflicts_with_authority';
  }
  if (reason == TripNativeEventLifecycleReason.permissionRequired &&
      (!review || canFeed)) {
    return 'native_lifecycle_status_conflicts_with_authority';
  }
  return null;
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      RegExp(r'-?\d{1,3}\.\d{4,}\s*,\s*-?\d{1,3}\.\d{4,}').hasMatch(clean);
}
