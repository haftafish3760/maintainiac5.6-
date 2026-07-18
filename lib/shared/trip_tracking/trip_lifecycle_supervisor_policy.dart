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
    'backgroundRecoveryRequiresLocalCheckpoint': true,
    'foregroundServiceCanOnlyStayAliveForRecoverableLocalTrip': true,
    'backupMirrorBlockedWhenUserActionRequired': true,
    'pendingReplayRequiresValidatedLocalSample': true,
    'pendingReplayRequiresMatchingSession': true,
    'recoveryCannotReplayMockedLocation': true,
    'permissionRequiredCannotUploadBackup': true,
    'fleetObserverCanRecoverTrip': false,
    'authenticationAloneAuthorizesRecovery': false,
    'hiveRemainsOperationalSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'odometerRemainsOfficialMileageTruth': true,
    'odometerIsGlobalTruth': true,
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

class TripLifecycleSupervisorSummaryValidation {
  const TripLifecycleSupervisorSummaryValidation._({
    required this.isRenderable,
    required this.reasons,
  });

  factory TripLifecycleSupervisorSummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    if (summary['schemaVersion'] != 1) {
      reasons.add('unsupported_schema_version');
    }
    final status = _safeStatus(summary['status']);
    final reasonCode = summary['reasonCode']?.toString() ?? '';
    if (status == null) {
      reasons.add('invalid_supervisor_status');
    }
    if (_safeLifecycle(summary['nextLifecycle']) == null) {
      reasons.add('invalid_next_lifecycle');
    }
    if (_safeReason(reasonCode) != summary['reasonCode']) {
      reasons.add('invalid_supervisor_reason');
    }
    for (final key in const [
      'shouldKeepForegroundServiceAlive',
      'shouldRequestUserAction',
      'canReplayPendingSample',
      'canUploadBackupMirror',
      'supervisorCanDeleteLocalData',
      'supervisorCanConfirmOdometer',
      'supervisorCanCreateOfficialStop',
      'remoteSupervisorCanOverrideLocalTrip',
      'firestoreCanOverrideLifecycle',
      'mapboxCanOverrideLifecycle',
      'malformedNativePayloadCanEndTrip',
      'backgroundRecoveryCanRunWithoutMaps',
      'mapsRequiredForRecovery',
      'localCheckpointPreservedUntilReview',
      'backgroundRecoveryRequiresLocalCheckpoint',
      'foregroundServiceCanOnlyStayAliveForRecoverableLocalTrip',
      'backupMirrorBlockedWhenUserActionRequired',
      'pendingReplayRequiresValidatedLocalSample',
      'pendingReplayRequiresMatchingSession',
      'recoveryCannotReplayMockedLocation',
      'permissionRequiredCannotUploadBackup',
      'fleetObserverCanRecoverTrip',
      'authenticationAloneAuthorizesRecovery',
      'hiveRemainsOperationalSourceOfTruth',
      'firestoreMirrorOnly',
      'odometerRemainsOfficialMileageTruth',
      'odometerIsGlobalTruth',
      'rawNativePayloadIncluded',
      'rawTripRecordsIncluded',
      'preciseLocationIncluded',
      'routeGeometryIncluded',
      'tokensIncluded',
    ]) {
      if (summary[key] is! bool) reasons.add('${key}_not_bool');
    }
    if (summary['supervisorCanDeleteLocalData'] != false ||
        summary['supervisorCanConfirmOdometer'] != false ||
        summary['supervisorCanCreateOfficialStop'] != false ||
        summary['malformedNativePayloadCanEndTrip'] != false) {
      reasons.add('supervisor_can_create_trip_truth');
    }
    if (summary['canReplayPendingSample'] == true &&
        (status != TripLifecycleSupervisorStatus.recoverInBackground ||
            reasonCode != 'replay_pending_sample_after_restore' ||
            summary['nextLifecycle'] !=
                TripTrackingSessionLifecycleState.recovering.name ||
            summary['shouldRequestUserAction'] != false)) {
      reasons.add('pending_replay_lifecycle_boundary_missing');
    }
    if (summary['canUploadBackupMirror'] == true &&
        summary['shouldRequestUserAction'] == true) {
      reasons.add('backup_upload_user_action_boundary_missing');
    }
    if (summary['status'] == TripLifecycleSupervisorStatus.blocked.name &&
        (summary['canReplayPendingSample'] != false ||
            summary['canUploadBackupMirror'] != false ||
            summary['shouldKeepForegroundServiceAlive'] != false)) {
      reasons.add('blocked_supervisor_boundary_missing');
    }
    if (summary['remoteSupervisorCanOverrideLocalTrip'] != false ||
        summary['firestoreCanOverrideLifecycle'] != false ||
        summary['mapboxCanOverrideLifecycle'] != false) {
      reasons.add('remote_can_override_lifecycle');
    }
    if (summary['backgroundRecoveryCanRunWithoutMaps'] != true ||
        summary['mapsRequiredForRecovery'] != false ||
        summary['localCheckpointPreservedUntilReview'] != true ||
        summary['backgroundRecoveryRequiresLocalCheckpoint'] != true ||
        summary['foregroundServiceCanOnlyStayAliveForRecoverableLocalTrip'] !=
            true ||
        summary['backupMirrorBlockedWhenUserActionRequired'] != true ||
        summary['pendingReplayRequiresValidatedLocalSample'] != true ||
        summary['pendingReplayRequiresMatchingSession'] != true ||
        summary['recoveryCannotReplayMockedLocation'] != true ||
        summary['permissionRequiredCannotUploadBackup'] != true) {
      reasons.add('recovery_checkpoint_boundary_missing');
    }
    if (summary['fleetObserverCanRecoverTrip'] != false ||
        summary['authenticationAloneAuthorizesRecovery'] != false) {
      reasons.add('recovery_authorization_boundary_missing');
    }
    if (summary['hiveRemainsOperationalSourceOfTruth'] != true ||
        summary['firestoreMirrorOnly'] != true ||
        summary['odometerRemainsOfficialMileageTruth'] != true ||
        summary['odometerIsGlobalTruth'] != true) {
      reasons.add('recovery_source_of_truth_boundary_missing');
    }
    if (summary['rawNativePayloadIncluded'] != false ||
        summary['rawTripRecordsIncluded'] != false ||
        summary['preciseLocationIncluded'] != false ||
        summary['routeGeometryIncluded'] != false ||
        summary['tokensIncluded'] != false ||
        summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_recovery_material');
    }

    return TripLifecycleSupervisorSummaryValidation._(
      isRenderable: reasons.isEmpty,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final List<String> reasons;
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

TripLifecycleSupervisorStatus? _safeStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripLifecycleSupervisorStatus.values) {
    if (status.name == value) return status;
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
      clean.contains(RegExp(r'-?\d{1,3}\.\d{5,}'));
}
