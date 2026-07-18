import 'trip_dashboard_status_rollup_policy.dart';
import 'trip_tracking_error_recovery_plan.dart';
import 'trip_tracking_models.dart';
import 'trip_tracking_recovery_policy.dart';

enum TripLifecycleSupervisorStatus {
  continueTracking,
  recoverInBackground,
  promptUser,
  pauseForReview,
  blocked,
}

class TripLifecycleSupervisorDecision {
  const TripLifecycleSupervisorDecision({
    required this.status,
    required this.reasonCode,
    required this.nextLifecycle,
    required this.shouldKeepForegroundServiceAlive,
    required this.shouldRequestUserAction,
    required this.canReplayPendingSample,
    required this.canUploadBackupMirror,
  });

  final TripLifecycleSupervisorStatus status;
  final String reasonCode;
  final TripTrackingSessionLifecycleState nextLifecycle;
  final bool shouldKeepForegroundServiceAlive;
  final bool shouldRequestUserAction;
  final bool canReplayPendingSample;
  final bool canUploadBackupMirror;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'reasonCode': _safeReason(reasonCode),
    'nextLifecycle': nextLifecycle.name,
    'shouldKeepForegroundServiceAlive': shouldKeepForegroundServiceAlive,
    'shouldRequestUserAction': shouldRequestUserAction,
    'canReplayPendingSample': canReplayPendingSample,
    'canUploadBackupMirror': canUploadBackupMirror,
    'supervisorCanDeleteLocalData': false,
    'supervisorCanConfirmOdometer': false,
    'supervisorCanCreateOfficialStop': false,
    'remoteSupervisorCanOverrideLocalTrip': false,
    'firestoreCanOverrideLifecycle': false,
    'mapboxCanOverrideLifecycle': false,
    'malformedNativePayloadCanEndTrip': false,
    'backgroundRecoveryCanRunWithoutMaps': true,
    'mapsRequiredForRecovery': false,
    'localCheckpointPreservedUntilReview': true,
    'hiveRemainsOperationalSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'odometerRemainsOfficialMileageTruth': true,
    'rawNativePayloadIncluded': false,
    'rawTripRecordsIncluded': false,
    'preciseLocationIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripLifecycleSupervisorPolicy {
  const TripLifecycleSupervisorPolicy._();

  static TripLifecycleSupervisorDecision evaluate({
    required TripTrackingSessionLifecycleState currentLifecycle,
    required TripDashboardStatusRollupDecision dashboardRollup,
    required TripTrackingErrorRecoveryPlan errorRecoveryPlan,
    required TripTrackingRecoveryDecision recoveryDecision,
    required bool localCheckpointAvailable,
    required bool nativeTrackingAvailable,
    required bool backupMirrorReady,
  }) {
    if (!_safeLifecycleCanBeSupervised(currentLifecycle) ||
        !localCheckpointAvailable) {
      return _decision(
        status: TripLifecycleSupervisorStatus.blocked,
        reasonCode: 'supervisor_invalid_local_boundary',
        nextLifecycle: TripTrackingSessionLifecycleState.interrupted,
        shouldKeepForegroundServiceAlive: false,
        shouldRequestUserAction: true,
        canReplayPendingSample: false,
        canUploadBackupMirror: false,
      );
    }

    if (dashboardRollup.severity == TripDashboardStatusRollupSeverity.blocked) {
      return _decision(
        status: TripLifecycleSupervisorStatus.pauseForReview,
        reasonCode: 'dashboard_blocked_requires_review',
        nextLifecycle: TripTrackingSessionLifecycleState.interrupted,
        shouldKeepForegroundServiceAlive: nativeTrackingAvailable,
        shouldRequestUserAction: true,
        canReplayPendingSample: false,
        canUploadBackupMirror: false,
      );
    }

    if (errorRecoveryPlan.action ==
        TripTrackingErrorRecoveryAction.promptUser) {
      return _decision(
        status: TripLifecycleSupervisorStatus.promptUser,
        reasonCode: 'native_error_requires_user_action',
        nextLifecycle: TripTrackingSessionLifecycleState.permissionRequired,
        shouldKeepForegroundServiceAlive: false,
        shouldRequestUserAction: true,
        canReplayPendingSample: false,
        canUploadBackupMirror: false,
      );
    }

    if (recoveryDecision.canRestore ||
        errorRecoveryPlan.action ==
            TripTrackingErrorRecoveryAction.retryNativeRegistration ||
        errorRecoveryPlan.action ==
            TripTrackingErrorRecoveryAction.continueOffline) {
      return _decision(
        status: TripLifecycleSupervisorStatus.recoverInBackground,
        reasonCode: _recoveryReason(errorRecoveryPlan, recoveryDecision),
        nextLifecycle: TripTrackingSessionLifecycleState.recovering,
        shouldKeepForegroundServiceAlive: nativeTrackingAvailable,
        shouldRequestUserAction: recoveryDecision.requiresUserAction,
        canReplayPendingSample: recoveryDecision.pendingSampleQueued,
        canUploadBackupMirror: backupMirrorReady,
      );
    }

    return _decision(
      status: TripLifecycleSupervisorStatus.continueTracking,
      reasonCode: 'supervisor_continue_tracking',
      nextLifecycle: _continueLifecycle(
        currentLifecycle,
        nativeTrackingAvailable,
      ),
      shouldKeepForegroundServiceAlive: nativeTrackingAvailable,
      shouldRequestUserAction: false,
      canReplayPendingSample: false,
      canUploadBackupMirror: backupMirrorReady,
    );
  }
}

TripLifecycleSupervisorDecision _decision({
  required TripLifecycleSupervisorStatus status,
  required String reasonCode,
  required TripTrackingSessionLifecycleState nextLifecycle,
  required bool shouldKeepForegroundServiceAlive,
  required bool shouldRequestUserAction,
  required bool canReplayPendingSample,
  required bool canUploadBackupMirror,
}) {
  return TripLifecycleSupervisorDecision(
    status: status,
    reasonCode: _safeReason(reasonCode),
    nextLifecycle: nextLifecycle,
    shouldKeepForegroundServiceAlive: shouldKeepForegroundServiceAlive,
    shouldRequestUserAction: shouldRequestUserAction,
    canReplayPendingSample: canReplayPendingSample,
    canUploadBackupMirror: canUploadBackupMirror && !shouldRequestUserAction,
  );
}

bool _safeLifecycleCanBeSupervised(TripTrackingSessionLifecycleState state) {
  return switch (state) {
    TripTrackingSessionLifecycleState.starting ||
    TripTrackingSessionLifecycleState.active ||
    TripTrackingSessionLifecycleState.paused ||
    TripTrackingSessionLifecycleState.degraded ||
    TripTrackingSessionLifecycleState.interrupted ||
    TripTrackingSessionLifecycleState.recovering ||
    TripTrackingSessionLifecycleState.stopping ||
    TripTrackingSessionLifecycleState.failedRecoverable => true,
    _ => false,
  };
}

TripTrackingSessionLifecycleState _continueLifecycle(
  TripTrackingSessionLifecycleState current,
  bool nativeTrackingAvailable,
) {
  if (!nativeTrackingAvailable) {
    return TripTrackingSessionLifecycleState.degraded;
  }
  return switch (current) {
    TripTrackingSessionLifecycleState.paused =>
      TripTrackingSessionLifecycleState.paused,
    TripTrackingSessionLifecycleState.stopping =>
      TripTrackingSessionLifecycleState.stopping,
    _ => TripTrackingSessionLifecycleState.active,
  };
}

String _recoveryReason(
  TripTrackingErrorRecoveryPlan plan,
  TripTrackingRecoveryDecision recovery,
) {
  if (recovery.pendingSampleQueued) {
    return 'replay_pending_sample_after_restore';
  }
  if (plan.action == TripTrackingErrorRecoveryAction.continueOffline) {
    return 'continue_offline_from_checkpoint';
  }
  if (plan.action == TripTrackingErrorRecoveryAction.retryNativeRegistration) {
    return 'retry_native_registration_from_checkpoint';
  }
  return 'restore_local_recoverable_session';
}

String _safeReason(String value) {
  return switch (value.trim()) {
    'supervisor_invalid_local_boundary' => 'supervisor_invalid_local_boundary',
    'dashboard_blocked_requires_review' => 'dashboard_blocked_requires_review',
    'native_error_requires_user_action' => 'native_error_requires_user_action',
    'replay_pending_sample_after_restore' =>
      'replay_pending_sample_after_restore',
    'continue_offline_from_checkpoint' => 'continue_offline_from_checkpoint',
    'retry_native_registration_from_checkpoint' =>
      'retry_native_registration_from_checkpoint',
    'restore_local_recoverable_session' => 'restore_local_recoverable_session',
    'supervisor_continue_tracking' => 'supervisor_continue_tracking',
    _ => 'supervisor_invalid_local_boundary',
  };
}
