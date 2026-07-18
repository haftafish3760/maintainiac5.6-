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
    'localCheckpointPreservedUntilReview': true,
    'hiveRemainsOperationalSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'mapboxCanFillHeartbeatGap': false,
    'odometerRemainsOfficialMileageTruth': true,
    'rawLocationIncluded': false,
    'preciseTimestampIncluded': false,
    'tokensIncluded': false,
  };
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
