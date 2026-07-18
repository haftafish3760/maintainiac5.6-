import 'trip_tracking_models.dart';

enum TripTrackingHeartbeatWatchdogStatus {
  healthy,
  staleButRecoverable,
  interruptedNeedsRecovery,
  pausedNoop,
  terminalProtected,
  blockedInvalidClock,
}

enum TripTrackingHeartbeatWatchdogAction {
  continueTracking,
  markDegraded,
  markInterrupted,
  preservePaused,
  protectTerminal,
  ignoreInvalidClock,
}

class TripTrackingHeartbeatWatchdogDecision {
  const TripTrackingHeartbeatWatchdogDecision({
    required this.status,
    required this.action,
    required this.reasonCode,
    required this.targetLifecycle,
    required this.canBridgeDistanceGap,
    required this.shouldRetryNativeTracking,
    required this.requiresUserReview,
  });

  final TripTrackingHeartbeatWatchdogStatus status;
  final TripTrackingHeartbeatWatchdogAction action;
  final String reasonCode;
  final TripTrackingSessionLifecycleState targetLifecycle;
  final bool canBridgeDistanceGap;
  final bool shouldRetryNativeTracking;
  final bool requiresUserReview;

  Map<String, Object?> toSafeSummary() => {
    'schemaVersion': 1,
    'status': status.name,
    'action': action.name,
    'reasonCode': _safeReason(reasonCode),
    'targetLifecycle': targetLifecycle.name,
    'canBridgeDistanceGap': false,
    'shouldRetryNativeTracking': shouldRetryNativeTracking,
    'requiresUserReview': requiresUserReview,
    'backgroundHeartbeatTrustedAfterValidationOnly': true,
    'heartbeatRespectsPausedTrip': true,
    'heartbeatCannotResumeTerminalTrip': true,
    'androidSleepCanDeleteCheckpoint': false,
    'iosBackgroundPauseCanDeleteCheckpoint': false,
    'heartbeatGapCanCreateMileage': false,
    'heartbeatGapCanCreateOfficialStop': false,
    'heartbeatGapCanConfirmOdometer': false,
    'heartbeatGapCanReplayPendingSample': false,
    'heartbeatGapRequiresLifecycleSupervisor': true,
    'heartbeatGapRequiresLocalCheckpoint': true,
    'heartbeatGapCannotBypassUserConsent': true,
    'heartbeatCanUploadBackupMirror': false,
    'heartbeatCanPurgeLocalDataAfterBackup': false,
    'localCheckpointPreservedUntilReview': true,
    'hiveRemainsOperationalSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'firestoreCanMarkTripInterrupted': false,
    'mapboxCanFillHeartbeatGap': false,
    'cloudFunctionCanFillHeartbeatGap': false,
    'odometerRemainsOfficialMileageTruth': true,
    'rawLocationIncluded': false,
    'preciseTimestampIncluded': false,
    'tokensIncluded': false,
  };
}

class TripTrackingHeartbeatWatchdogSummaryValidation {
  const TripTrackingHeartbeatWatchdogSummaryValidation._({
    required this.isRenderable,
    required this.reasons,
  });

  factory TripTrackingHeartbeatWatchdogSummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    if (summary['schemaVersion'] != 1) reasons.add('unsupported_schema');
    if (_safeStatus(summary['status']) == null) {
      reasons.add('invalid_heartbeat_status');
    }
    if (_safeAction(summary['action']) == null) {
      reasons.add('invalid_heartbeat_action');
    }
    if (_safeReason(summary['reasonCode']?.toString() ?? '') !=
        summary['reasonCode']) {
      reasons.add('invalid_heartbeat_reason');
    }
    if (_safeLifecycle(summary['targetLifecycle']) == null) {
      reasons.add('invalid_target_lifecycle');
    }
    for (final key in const [
      'canBridgeDistanceGap',
      'shouldRetryNativeTracking',
      'requiresUserReview',
      'backgroundHeartbeatTrustedAfterValidationOnly',
      'heartbeatRespectsPausedTrip',
      'heartbeatCannotResumeTerminalTrip',
      'androidSleepCanDeleteCheckpoint',
      'iosBackgroundPauseCanDeleteCheckpoint',
      'heartbeatGapCanCreateMileage',
      'heartbeatGapCanCreateOfficialStop',
      'heartbeatGapCanConfirmOdometer',
      'heartbeatGapCanReplayPendingSample',
      'heartbeatGapRequiresLifecycleSupervisor',
      'heartbeatGapRequiresLocalCheckpoint',
      'heartbeatGapCannotBypassUserConsent',
      'heartbeatCanUploadBackupMirror',
      'heartbeatCanPurgeLocalDataAfterBackup',
      'localCheckpointPreservedUntilReview',
      'hiveRemainsOperationalSourceOfTruth',
      'firestoreMirrorOnly',
      'firestoreCanMarkTripInterrupted',
      'mapboxCanFillHeartbeatGap',
      'cloudFunctionCanFillHeartbeatGap',
      'odometerRemainsOfficialMileageTruth',
      'rawLocationIncluded',
      'preciseTimestampIncluded',
      'tokensIncluded',
    ]) {
      if (summary[key] is! bool) reasons.add('${key}_not_bool');
    }
    if (summary['canBridgeDistanceGap'] != false ||
        summary['heartbeatGapCanCreateMileage'] != false ||
        summary['heartbeatGapCanCreateOfficialStop'] != false ||
        summary['heartbeatGapCanConfirmOdometer'] != false ||
        summary['heartbeatGapCanReplayPendingSample'] != false ||
        summary['odometerRemainsOfficialMileageTruth'] != true) {
      reasons.add('heartbeat_claims_trip_truth');
    }
    if (summary['androidSleepCanDeleteCheckpoint'] != false ||
        summary['iosBackgroundPauseCanDeleteCheckpoint'] != false ||
        summary['heartbeatCanPurgeLocalDataAfterBackup'] != false ||
        summary['localCheckpointPreservedUntilReview'] != true) {
      reasons.add('heartbeat_can_delete_checkpoint');
    }
    if (summary['heartbeatGapRequiresLifecycleSupervisor'] != true ||
        summary['heartbeatGapRequiresLocalCheckpoint'] != true ||
        summary['heartbeatGapCannotBypassUserConsent'] != true ||
        summary['backgroundHeartbeatTrustedAfterValidationOnly'] != true ||
        summary['heartbeatCanUploadBackupMirror'] != false) {
      reasons.add('heartbeat_recovery_boundary_missing');
    }
    if (summary['hiveRemainsOperationalSourceOfTruth'] != true ||
        summary['firestoreMirrorOnly'] != true ||
        summary['firestoreCanMarkTripInterrupted'] != false ||
        summary['mapboxCanFillHeartbeatGap'] != false ||
        summary['cloudFunctionCanFillHeartbeatGap'] != false) {
      reasons.add('remote_can_control_heartbeat_gap');
    }
    if (summary['rawLocationIncluded'] != false ||
        summary['preciseTimestampIncluded'] != false ||
        summary['tokensIncluded'] != false ||
        summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_heartbeat_material');
    }
    return TripTrackingHeartbeatWatchdogSummaryValidation._(
      isRenderable: reasons.isEmpty,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final List<String> reasons;
}

class TripTrackingHeartbeatWatchdogPolicy {
  const TripTrackingHeartbeatWatchdogPolicy._();

  static TripTrackingHeartbeatWatchdogDecision evaluate({
    required TripTrackingSessionLifecycleState currentLifecycle,
    required DateTime? lastHeartbeatUtc,
    required DateTime nowUtc,
    Duration staleAfter = const Duration(minutes: 3),
    Duration interruptedAfter = const Duration(minutes: 10),
    bool nativeTrackingExpected = true,
  }) {
    if (staleAfter <= Duration.zero || interruptedAfter < staleAfter) {
      return _decision(
        TripTrackingHeartbeatWatchdogStatus.blockedInvalidClock,
        TripTrackingHeartbeatWatchdogAction.ignoreInvalidClock,
        'invalid_watchdog_thresholds',
        currentLifecycle,
        requiresUserReview: true,
      );
    }
    if (_terminalProtected(currentLifecycle)) {
      return _decision(
        TripTrackingHeartbeatWatchdogStatus.terminalProtected,
        TripTrackingHeartbeatWatchdogAction.protectTerminal,
        'heartbeat_terminal_session_protected',
        currentLifecycle,
        requiresUserReview: true,
      );
    }
    if (currentLifecycle == TripTrackingSessionLifecycleState.paused) {
      return _decision(
        TripTrackingHeartbeatWatchdogStatus.pausedNoop,
        TripTrackingHeartbeatWatchdogAction.preservePaused,
        'heartbeat_paused_trip_preserved',
        currentLifecycle,
      );
    }
    final heartbeat = lastHeartbeatUtc?.toUtc();
    final now = nowUtc.toUtc();
    if (heartbeat == null || heartbeat.isAfter(now)) {
      return _decision(
        TripTrackingHeartbeatWatchdogStatus.blockedInvalidClock,
        TripTrackingHeartbeatWatchdogAction.ignoreInvalidClock,
        'heartbeat_clock_invalid',
        currentLifecycle,
        requiresUserReview: true,
      );
    }
    final age = now.difference(heartbeat);
    if (!nativeTrackingExpected || age < staleAfter) {
      return _decision(
        TripTrackingHeartbeatWatchdogStatus.healthy,
        TripTrackingHeartbeatWatchdogAction.continueTracking,
        nativeTrackingExpected
            ? 'heartbeat_recent'
            : 'native_tracking_not_expected',
        currentLifecycle,
      );
    }
    if (age < interruptedAfter) {
      return _decision(
        TripTrackingHeartbeatWatchdogStatus.staleButRecoverable,
        TripTrackingHeartbeatWatchdogAction.markDegraded,
        'heartbeat_stale_retry_native',
        TripTrackingSessionLifecycleState.degraded,
        shouldRetryNativeTracking: true,
      );
    }
    return _decision(
      TripTrackingHeartbeatWatchdogStatus.interruptedNeedsRecovery,
      TripTrackingHeartbeatWatchdogAction.markInterrupted,
      'heartbeat_interrupted_recovery_required',
      TripTrackingSessionLifecycleState.interrupted,
      shouldRetryNativeTracking: true,
      requiresUserReview: true,
    );
  }
}

bool _terminalProtected(TripTrackingSessionLifecycleState state) {
  return state == TripTrackingSessionLifecycleState.completed ||
      state == TripTrackingSessionLifecycleState.awaitingReview ||
      state == TripTrackingSessionLifecycleState.failedTerminal ||
      state == TripTrackingSessionLifecycleState.disabled;
}

TripTrackingHeartbeatWatchdogDecision _decision(
  TripTrackingHeartbeatWatchdogStatus status,
  TripTrackingHeartbeatWatchdogAction action,
  String reasonCode,
  TripTrackingSessionLifecycleState targetLifecycle, {
  bool shouldRetryNativeTracking = false,
  bool requiresUserReview = false,
}) {
  return TripTrackingHeartbeatWatchdogDecision(
    status: status,
    action: action,
    reasonCode: reasonCode,
    targetLifecycle: targetLifecycle,
    canBridgeDistanceGap: false,
    shouldRetryNativeTracking: shouldRetryNativeTracking,
    requiresUserReview: requiresUserReview,
  );
}

String _safeReason(String value) {
  final clean = value.trim();
  return switch (clean) {
    'invalid_watchdog_thresholds' ||
    'heartbeat_clock_invalid' ||
    'heartbeat_recent' ||
    'native_tracking_not_expected' ||
    'heartbeat_stale_retry_native' ||
    'heartbeat_interrupted_recovery_required' ||
    'heartbeat_paused_trip_preserved' ||
    'heartbeat_terminal_session_protected' => clean,
    _ => 'heartbeat_clock_invalid',
  };
}

TripTrackingHeartbeatWatchdogStatus? _safeStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripTrackingHeartbeatWatchdogStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

TripTrackingHeartbeatWatchdogAction? _safeAction(Object? value) {
  if (value is! String) return null;
  for (final action in TripTrackingHeartbeatWatchdogAction.values) {
    if (action.name == value) return action;
  }
  return null;
}

TripTrackingSessionLifecycleState? _safeLifecycle(Object? value) {
  if (value is! String) return null;
  for (final lifecycle in TripTrackingSessionLifecycleState.values) {
    if (lifecycle.name == value) return lifecycle;
  }
  return null;
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      clean.contains('token=') ||
      clean.contains(RegExp(r'-?\d{1,3}\.\d{4,}\s*,\s*-?\d{1,3}\.\d{4,}'));
}
