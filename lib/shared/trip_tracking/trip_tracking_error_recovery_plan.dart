import 'trip_tracking_native_error_policy.dart';

enum TripTrackingErrorRecoveryAction {
  continueOffline,
  promptUser,
  retryNativeRegistration,
  keepTracking,
}

class TripTrackingErrorRecoveryPlan {
  const TripTrackingErrorRecoveryPlan._({
    required this.action,
    required this.nativeErrorCode,
    required this.retryAfter,
    required this.reasonCode,
  });

  factory TripTrackingErrorRecoveryPlan.forNativeError(
    String? errorCode, {
    required int failureCount,
    required bool activeTripHasLocalCheckpoint,
    required bool userCanOpenSettings,
  }) {
    final safeFailureCount = failureCount < 0
        ? 0
        : failureCount > 20
        ? 20
        : failureCount;
    final summary = TripTrackingNativeErrorPolicy.toSafeSummary(errorCode);
    final safeCode = summary['nativeErrorCode'] as String;

    if (summary['ignorableMalformedPayload'] == true) {
      return TripTrackingErrorRecoveryPlan._(
        action: TripTrackingErrorRecoveryAction.continueOffline,
        nativeErrorCode: safeCode,
        retryAfter: _retryBackoff(safeFailureCount),
        reasonCode: activeTripHasLocalCheckpoint
            ? 'malformed_payload_checkpoint_preserved'
            : 'malformed_payload_waiting_for_local_checkpoint',
      );
    }

    if (summary['recoverable'] == true && userCanOpenSettings) {
      return TripTrackingErrorRecoveryPlan._(
        action: TripTrackingErrorRecoveryAction.promptUser,
        nativeErrorCode: safeCode,
        retryAfter: Duration.zero,
        reasonCode: 'user_permission_or_device_action_required',
      );
    }

    if (summary['recoverable'] == true) {
      return TripTrackingErrorRecoveryPlan._(
        action: TripTrackingErrorRecoveryAction.retryNativeRegistration,
        nativeErrorCode: safeCode,
        retryAfter: _retryBackoff(safeFailureCount),
        reasonCode: activeTripHasLocalCheckpoint
            ? 'retry_without_losing_local_trip'
            : 'retry_before_tracking_starts',
      );
    }

    return TripTrackingErrorRecoveryPlan._(
      action: TripTrackingErrorRecoveryAction.keepTracking,
      nativeErrorCode: safeCode,
      retryAfter: Duration.zero,
      reasonCode: 'unknown_error_does_not_mutate_trip',
    );
  }

  final TripTrackingErrorRecoveryAction action;
  final String nativeErrorCode;
  final Duration retryAfter;
  final String reasonCode;

  Map<String, Object?> toSafeSummary() => {
    'schemaVersion': 1,
    'action': action.name,
    'nativeErrorCode': nativeErrorCode,
    'retryAfterSeconds': retryAfter.inSeconds,
    'reasonCode': reasonCode,
    'nonBlockingRecovery': action != TripTrackingErrorRecoveryAction.promptUser,
    'localCheckpointPreserved': true,
    'tripDataDeletionAllowed': false,
    'activeTripCanContinueWithoutMapbox': true,
    'firestoreErrorCanOverrideRecovery': false,
    'mapboxErrorCanOverrideRecovery': false,
    'nativeErrorCanOverrideOdometer': false,
    'confirmedOdometerRemainsCanonical': true,
    'rawNativePayloadIncluded': false,
    'preciseLocationIncluded': false,
    'tokensIncluded': false,
  };
}

Duration _retryBackoff(int failureCount) {
  if (failureCount <= 0) return const Duration(seconds: 2);
  final seconds = 2 << (failureCount > 4 ? 4 : failureCount);
  return Duration(seconds: seconds > 60 ? 60 : seconds);
}
