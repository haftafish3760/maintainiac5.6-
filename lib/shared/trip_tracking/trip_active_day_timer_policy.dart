import 'trip_tracking_models.dart';

enum TripActiveDayTimerStatus {
  notStarted,
  running,
  paused,
  awaitingReview,
  completed,
  invalidClock,
}

class TripActiveDayTimerDecision {
  const TripActiveDayTimerDecision({
    required this.status,
    required this.elapsed,
    required this.reasonCode,
    required this.shouldTickLive,
    required this.requiresUserReview,
  });

  final TripActiveDayTimerStatus status;
  final Duration elapsed;
  final String reasonCode;
  final bool shouldTickLive;
  final bool requiresUserReview;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'elapsedSeconds': _safeElapsedSeconds(elapsed),
    'elapsedBucket': _elapsedBucket(elapsed),
    'reasonCode': _safeReason(reasonCode),
    'shouldTickLive': shouldTickLive,
    'requiresUserReview': requiresUserReview,
    'timerSource': 'local_session_clock',
    'dashboardTimerCanRunWithoutMaps': true,
    'mapsRequiredForTimer': false,
    'timerCanCreateMileage': false,
    'timerCanConfirmOdometer': false,
    'timerCanCreateOfficialStop': false,
    'timerCanDeleteLocalData': false,
    'remoteTimerCanOverrideLocalSession': false,
    'firestoreMirrorOnly': true,
    'hiveRemainsOperationalSourceOfTruth': true,
    'odometerRemainsOfficialMileageTruth': true,
    'odometerIsGlobalTruth': true,
    'rawSessionIncluded': false,
    'preciseTimestampIncluded': false,
    'preciseLocationIncluded': false,
    'tokensIncluded': false,
  };
}

class TripActiveDayTimerPolicy {
  const TripActiveDayTimerPolicy._();

  static TripActiveDayTimerDecision evaluate({
    required TripTrackingSessionLifecycleState lifecycle,
    required DateTime? startedAtUtc,
    required DateTime? pausedAtUtc,
    required DateTime? completedAtUtc,
    required DateTime nowUtc,
    Duration previouslyElapsed = Duration.zero,
  }) {
    final previous = _safePreviousElapsed(previouslyElapsed);
    final now = nowUtc.toUtc();
    final started = startedAtUtc?.toUtc();
    final paused = pausedAtUtc?.toUtc();
    final completed = completedAtUtc?.toUtc();

    if (started == null) {
      return _decision(
        TripActiveDayTimerStatus.notStarted,
        previous,
        'timer_waiting_for_start',
        shouldTickLive: false,
      );
    }
    if (started.isAfter(now) ||
        (paused != null && paused.isBefore(started)) ||
        (completed != null && completed.isBefore(started))) {
      return _decision(
        TripActiveDayTimerStatus.invalidClock,
        previous,
        'timer_clock_invalid',
        shouldTickLive: false,
        requiresUserReview: true,
      );
    }

    return switch (lifecycle) {
      TripTrackingSessionLifecycleState.paused => _decision(
        TripActiveDayTimerStatus.paused,
        previous + ((paused ?? now).difference(started)),
        'timer_paused_from_local_checkpoint',
        shouldTickLive: false,
      ),
      TripTrackingSessionLifecycleState.awaitingReview => _decision(
        TripActiveDayTimerStatus.awaitingReview,
        previous + ((completed ?? now).difference(started)),
        'timer_awaiting_odometer_review',
        shouldTickLive: false,
        requiresUserReview: true,
      ),
      TripTrackingSessionLifecycleState.completed => _decision(
        TripActiveDayTimerStatus.completed,
        previous + ((completed ?? now).difference(started)),
        'timer_completed',
        shouldTickLive: false,
      ),
      TripTrackingSessionLifecycleState.active ||
      TripTrackingSessionLifecycleState.starting ||
      TripTrackingSessionLifecycleState.degraded ||
      TripTrackingSessionLifecycleState.interrupted ||
      TripTrackingSessionLifecycleState.recovering ||
      TripTrackingSessionLifecycleState.stopping ||
      TripTrackingSessionLifecycleState.failedRecoverable => _decision(
        TripActiveDayTimerStatus.running,
        previous + now.difference(started),
        'timer_running_from_local_checkpoint',
        shouldTickLive: true,
        requiresUserReview:
            lifecycle == TripTrackingSessionLifecycleState.interrupted ||
            lifecycle == TripTrackingSessionLifecycleState.stopping,
      ),
      TripTrackingSessionLifecycleState.disabled ||
      TripTrackingSessionLifecycleState.permissionRequired ||
      TripTrackingSessionLifecycleState.ready ||
      TripTrackingSessionLifecycleState.failedTerminal => _decision(
        TripActiveDayTimerStatus.notStarted,
        previous,
        'timer_not_tracking',
        shouldTickLive: false,
        requiresUserReview:
            lifecycle == TripTrackingSessionLifecycleState.permissionRequired,
      ),
    };
  }
}

TripActiveDayTimerDecision _decision(
  TripActiveDayTimerStatus status,
  Duration elapsed,
  String reasonCode, {
  required bool shouldTickLive,
  bool requiresUserReview = false,
}) {
  return TripActiveDayTimerDecision(
    status: status,
    elapsed: elapsed.isNegative ? Duration.zero : elapsed,
    reasonCode: reasonCode,
    shouldTickLive: shouldTickLive,
    requiresUserReview: requiresUserReview,
  );
}

Duration _safePreviousElapsed(Duration value) {
  if (value.isNegative) return Duration.zero;
  if (value > const Duration(days: 7)) return const Duration(days: 7);
  return value;
}

int _safeElapsedSeconds(Duration value) {
  if (value.isNegative) return 0;
  final seconds = value.inSeconds;
  return seconds > 604800 ? 604800 : seconds;
}

String _elapsedBucket(Duration value) {
  final seconds = _safeElapsedSeconds(value);
  if (seconds == 0) return 'none';
  if (seconds < 3600) return 'under_1_hour';
  if (seconds < 14400) return '1_to_4_hours';
  if (seconds < 43200) return '4_to_12_hours';
  return 'over_12_hours';
}

String _safeReason(String value) {
  final clean = value.trim();
  return switch (clean) {
    'timer_waiting_for_start' ||
    'timer_clock_invalid' ||
    'timer_paused_from_local_checkpoint' ||
    'timer_awaiting_odometer_review' ||
    'timer_completed' ||
    'timer_running_from_local_checkpoint' ||
    'timer_not_tracking' => clean,
    _ => 'timer_clock_invalid',
  };
}
