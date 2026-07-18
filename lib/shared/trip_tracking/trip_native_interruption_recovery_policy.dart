import 'trip_lifecycle_supervisor_policy.dart';
import 'trip_native_event_lifecycle_policy.dart';
import 'trip_tracking_models.dart';

enum TripNativeInterruptionRecoveryStatus {
  feedEngine,
  recoverInBackground,
  promptUser,
  pauseForReview,
  ignoreSafely,
  blocked,
}

class TripNativeInterruptionRecoveryDecision {
  const TripNativeInterruptionRecoveryDecision({
    required this.status,
    required this.reasonCode,
    required this.nextLifecycle,
    required this.canFeedEngine,
    required this.shouldKeepForegroundServiceAlive,
    required this.shouldRequestUserAction,
    required this.canReplayPendingSample,
    required this.canUploadBackupMirror,
  });

  final TripNativeInterruptionRecoveryStatus status;
  final String reasonCode;
  final TripTrackingSessionLifecycleState nextLifecycle;
  final bool canFeedEngine;
  final bool shouldKeepForegroundServiceAlive;
  final bool shouldRequestUserAction;
  final bool canReplayPendingSample;
  final bool canUploadBackupMirror;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'reasonCode': _safeReason(reasonCode),
    'nextLifecycle': nextLifecycle.name,
    'canFeedEngine': canFeedEngine,
    'shouldKeepForegroundServiceAlive': shouldKeepForegroundServiceAlive,
    'shouldRequestUserAction': shouldRequestUserAction,
    'canReplayPendingSample': canReplayPendingSample,
    'canUploadBackupMirror': canUploadBackupMirror,
    'localCheckpointRequiredForRecovery': true,
    'nativeInterruptionCanEndTripAutomatically': false,
    'nativeInterruptionCanDeleteLocalData': false,
    'nativeInterruptionCanConfirmOdometer': false,
    'nativeInterruptionCanSetGlobalTruth': false,
    'nativeInterruptionCanChangeOfficialMileage': false,
    'nativeInterruptionCanCreateOfficialStop': false,
    'nativeInterruptionCanPurgeLocalDataAfterBackup': false,
    'nativeInterruptionCanBypassLocalCheckpoint': false,
    'nativeInterruptionCanBypassUserConsent': false,
    'completedSessionProtectedFromNativeResume': true,
    'failedTerminalSessionProtectedFromNativeResume': true,
    'nativeStoppedStatusCannotCompleteTrip': true,
    'permissionLossCannotFeedEngine': true,
    'backgroundRestrictionRequiresRecoverableInterruption': true,
    'foregroundServiceLossRequiresCheckpointRecovery': true,
    'recoveryCanDegradeToUserReviewWithoutDataLoss': true,
    'pendingReplayRequiresValidatedLocalSample': true,
    'pendingReplayRequiresMatchingSession': true,
    'pendingReplayCannotUseMockedLocation': true,
    'backupMirrorBlockedWhenUserActionRequired': true,
    'backupMirrorCannotConfirmTripTruth': true,
    'backupMirrorCannotSetGlobalTruth': true,
    'backupMirrorCannotChangeOfficialMileage': true,
    'authenticationAloneAuthorizesNativeRecovery': false,
    'fleetObserverCanForceNativeRecovery': false,
    'backgroundRecoveryCanRunWithoutMaps': true,
    'mapsRequiredForRecovery': false,
    'firestoreCanForceRecovery': false,
    'cloudFunctionCanForceRecovery': false,
    'mapboxCanForceRecovery': false,
    'hiveRemainsOperationalSourceOfTruth': true,
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
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripNativeInterruptionRecoverySummaryValidation {
  const TripNativeInterruptionRecoverySummaryValidation._({
    required this.isRenderable,
    required this.status,
    required this.reasons,
  });

  factory TripNativeInterruptionRecoverySummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    final status = _safeStatus(summary['status']);
    if (summary['schemaVersion'] != 1) {
      reasons.add('unsupported_schema_version');
    }
    if (status == null) reasons.add('invalid_recovery_status');
    if (_safeReasonObject(summary['reasonCode']) == null) {
      reasons.add('invalid_recovery_reason');
    }
    if (_safeLifecycleState(summary['nextLifecycle']) == null) {
      reasons.add('invalid_next_lifecycle');
    }
    if (summary['canFeedEngine'] == true &&
        (status != TripNativeInterruptionRecoveryStatus.feedEngine ||
            summary['shouldRequestUserAction'] == true)) {
      reasons.add('unsafe_engine_feed_claim');
    }
    if (summary['canReplayPendingSample'] == true &&
        (summary['localCheckpointRequiredForRecovery'] != true ||
            summary['shouldRequestUserAction'] == true)) {
      reasons.add('unsafe_pending_sample_replay_claim');
    }
    if (summary['localCheckpointRequiredForRecovery'] != true ||
        summary['hiveRemainsOperationalSourceOfTruth'] != true ||
        summary['odometerRemainsOfficialMileageTruth'] != true ||
        summary['odometerIsGlobalTruth'] != true ||
        summary['physicalOdometerRequiredForOfficialMileage'] != true ||
        summary['confirmedOdometerOverridesExternalMileage'] != true ||
        summary['externalMileageCannotBecomeGlobalTruth'] != true ||
        summary['gpsDistanceCanOnlyAdviseMileageReview'] != true ||
        summary['mapMatchingCanOnlyAdviseMileageReview'] != true ||
        summary['optimizationCannotChangeOfficialMileage'] != true) {
      reasons.add('local_recovery_truth_boundary_missing');
    }
    if (summary['nativeInterruptionCanEndTripAutomatically'] != false ||
        summary['nativeInterruptionCanDeleteLocalData'] != false ||
        summary['nativeInterruptionCanConfirmOdometer'] != false ||
        summary['nativeInterruptionCanSetGlobalTruth'] != false ||
        summary['nativeInterruptionCanChangeOfficialMileage'] != false ||
        summary['nativeInterruptionCanCreateOfficialStop'] != false ||
        summary['nativeInterruptionCanPurgeLocalDataAfterBackup'] != false ||
        summary['nativeInterruptionCanBypassLocalCheckpoint'] != false) {
      reasons.add('native_recovery_can_mutate_trip_truth');
    }
    if (summary['nativeInterruptionCanBypassUserConsent'] != false) {
      reasons.add('consent_boundary_missing');
    }
    if (summary['completedSessionProtectedFromNativeResume'] != true ||
        summary['failedTerminalSessionProtectedFromNativeResume'] != true ||
        summary['nativeStoppedStatusCannotCompleteTrip'] != true ||
        summary['permissionLossCannotFeedEngine'] != true ||
        summary['backgroundRestrictionRequiresRecoverableInterruption'] !=
            true ||
        summary['foregroundServiceLossRequiresCheckpointRecovery'] != true ||
        summary['recoveryCanDegradeToUserReviewWithoutDataLoss'] != true ||
        summary['pendingReplayRequiresValidatedLocalSample'] != true ||
        summary['pendingReplayRequiresMatchingSession'] != true ||
        summary['pendingReplayCannotUseMockedLocation'] != true ||
        summary['backupMirrorBlockedWhenUserActionRequired'] != true ||
        summary['backupMirrorCannotConfirmTripTruth'] != true ||
        summary['backupMirrorCannotSetGlobalTruth'] != true ||
        summary['backupMirrorCannotChangeOfficialMileage'] != true) {
      reasons.add('completed_session_resume_boundary_missing');
    }
    if (summary['authenticationAloneAuthorizesNativeRecovery'] != false ||
        summary['fleetObserverCanForceNativeRecovery'] != false) {
      reasons.add('native_recovery_authorization_boundary_missing');
    }
    if (summary['backgroundRecoveryCanRunWithoutMaps'] != true ||
        summary['mapsRequiredForRecovery'] != false ||
        summary['firestoreCanForceRecovery'] != false ||
        summary['cloudFunctionCanForceRecovery'] != false ||
        summary['mapboxCanForceRecovery'] != false) {
      reasons.add('remote_or_map_can_force_recovery');
    }
    if (summary['rawNativePayloadIncluded'] != false ||
        summary['rawLocationIncluded'] != false ||
        summary['routeGeometryIncluded'] != false ||
        summary['tokensIncluded'] != false) {
      reasons.add('summary_contains_sensitive_recovery_material');
    }
    if (summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_text');
    }

    return TripNativeInterruptionRecoverySummaryValidation._(
      isRenderable: reasons.isEmpty,
      status: reasons.isEmpty ? status : null,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final TripNativeInterruptionRecoveryStatus? status;
  final List<String> reasons;
}

class TripNativeInterruptionRecoveryPolicy {
  const TripNativeInterruptionRecoveryPolicy._();

  static TripNativeInterruptionRecoveryDecision evaluate({
    required TripNativeEventLifecycleDecision nativeDecision,
    required TripLifecycleSupervisorDecision supervisorDecision,
    required bool localCheckpointAvailable,
  }) {
    if (nativeDecision.action == TripNativeEventLifecycleAction.ignoreEvent) {
      return _decision(
        status: TripNativeInterruptionRecoveryStatus.ignoreSafely,
        reasonCode: _nativeReason(nativeDecision),
        nextLifecycle: nativeDecision.to,
        canFeedEngine: false,
        shouldKeepForegroundServiceAlive: false,
        shouldRequestUserAction: nativeDecision.requiresUserReview,
        canReplayPendingSample: false,
        canUploadBackupMirror: false,
      );
    }

    if (!nativeDecision.transitionAllowed || !localCheckpointAvailable) {
      return _decision(
        status: TripNativeInterruptionRecoveryStatus.blocked,
        reasonCode: !localCheckpointAvailable
            ? 'native_recovery_missing_local_checkpoint'
            : 'native_recovery_illegal_transition',
        nextLifecycle: nativeDecision.from,
        canFeedEngine: false,
        shouldKeepForegroundServiceAlive: false,
        shouldRequestUserAction: true,
        canReplayPendingSample: false,
        canUploadBackupMirror: false,
      );
    }

    if (nativeDecision.requiresUserReview ||
        supervisorDecision.shouldRequestUserAction) {
      final prompt =
          supervisorDecision.status ==
          TripLifecycleSupervisorStatus.pauseForReview;
      return _decision(
        status: prompt
            ? TripNativeInterruptionRecoveryStatus.pauseForReview
            : TripNativeInterruptionRecoveryStatus.promptUser,
        reasonCode: _reviewReason(nativeDecision, supervisorDecision),
        nextLifecycle: supervisorDecision.nextLifecycle,
        canFeedEngine: false,
        shouldKeepForegroundServiceAlive:
            supervisorDecision.shouldKeepForegroundServiceAlive,
        shouldRequestUserAction: true,
        canReplayPendingSample: false,
        canUploadBackupMirror: false,
      );
    }

    if (supervisorDecision.status ==
            TripLifecycleSupervisorStatus.recoverInBackground ||
        nativeDecision.action ==
            TripNativeEventLifecycleAction.recoverLocally ||
        nativeDecision.action ==
            TripNativeEventLifecycleAction.markInterrupted ||
        nativeDecision.action == TripNativeEventLifecycleAction.markDegraded) {
      return _decision(
        status: TripNativeInterruptionRecoveryStatus.recoverInBackground,
        reasonCode: _supervisorReason(supervisorDecision),
        nextLifecycle: supervisorDecision.nextLifecycle,
        canFeedEngine: false,
        shouldKeepForegroundServiceAlive:
            supervisorDecision.shouldKeepForegroundServiceAlive,
        shouldRequestUserAction: false,
        canReplayPendingSample: supervisorDecision.canReplayPendingSample,
        canUploadBackupMirror: supervisorDecision.canUploadBackupMirror,
      );
    }

    return _decision(
      status: nativeDecision.canFeedEngine
          ? TripNativeInterruptionRecoveryStatus.feedEngine
          : TripNativeInterruptionRecoveryStatus.recoverInBackground,
      reasonCode: nativeDecision.canFeedEngine
          ? 'native_sample_ready_for_engine'
          : _supervisorReason(supervisorDecision),
      nextLifecycle: nativeDecision.to,
      canFeedEngine: nativeDecision.canFeedEngine,
      shouldKeepForegroundServiceAlive:
          supervisorDecision.shouldKeepForegroundServiceAlive,
      shouldRequestUserAction: false,
      canReplayPendingSample: false,
      canUploadBackupMirror: supervisorDecision.canUploadBackupMirror,
    );
  }
}

TripNativeInterruptionRecoveryDecision _decision({
  required TripNativeInterruptionRecoveryStatus status,
  required String reasonCode,
  required TripTrackingSessionLifecycleState nextLifecycle,
  required bool canFeedEngine,
  required bool shouldKeepForegroundServiceAlive,
  required bool shouldRequestUserAction,
  required bool canReplayPendingSample,
  required bool canUploadBackupMirror,
}) {
  return TripNativeInterruptionRecoveryDecision(
    status: status,
    reasonCode: _safeReason(reasonCode),
    nextLifecycle: nextLifecycle,
    canFeedEngine: canFeedEngine && !shouldRequestUserAction,
    shouldKeepForegroundServiceAlive: shouldKeepForegroundServiceAlive,
    shouldRequestUserAction: shouldRequestUserAction,
    canReplayPendingSample: canReplayPendingSample && !shouldRequestUserAction,
    canUploadBackupMirror: canUploadBackupMirror && !shouldRequestUserAction,
  );
}

String _nativeReason(TripNativeEventLifecycleDecision decision) {
  return switch (decision.reason) {
    TripNativeEventLifecycleReason.completedSessionProtected =>
      'native_completed_session_ignored',
    TripNativeEventLifecycleReason.nativeStoppedStatusIgnored =>
      'native_stopped_status_ignored',
    _ => 'native_event_ignored_safely',
  };
}

String _reviewReason(
  TripNativeEventLifecycleDecision nativeDecision,
  TripLifecycleSupervisorDecision supervisorDecision,
) {
  if (nativeDecision.reason ==
      TripNativeEventLifecycleReason.permissionRequired) {
    return 'native_permission_requires_user_review';
  }
  if (nativeDecision.reason ==
      TripNativeEventLifecycleReason.backgroundRestricted) {
    return 'native_background_restriction_requires_review';
  }
  if (supervisorDecision.status ==
      TripLifecycleSupervisorStatus.pauseForReview) {
    return 'supervisor_pause_requires_user_review';
  }
  return 'native_recovery_requires_user_review';
}

String _supervisorReason(TripLifecycleSupervisorDecision decision) {
  return switch (decision.reasonCode) {
    'replay_pending_sample_after_restore' =>
      'replay_pending_sample_after_restore',
    'continue_offline_from_checkpoint' => 'continue_offline_from_checkpoint',
    'retry_native_registration_from_checkpoint' =>
      'retry_native_registration_from_checkpoint',
    'restore_local_recoverable_session' => 'restore_local_recoverable_session',
    _ => 'native_background_recovery_ready',
  };
}

String _safeReason(String value) {
  return switch (value.trim()) {
    'native_recovery_missing_local_checkpoint' =>
      'native_recovery_missing_local_checkpoint',
    'native_recovery_illegal_transition' =>
      'native_recovery_illegal_transition',
    'native_completed_session_ignored' => 'native_completed_session_ignored',
    'native_stopped_status_ignored' => 'native_stopped_status_ignored',
    'native_event_ignored_safely' => 'native_event_ignored_safely',
    'native_permission_requires_user_review' =>
      'native_permission_requires_user_review',
    'native_background_restriction_requires_review' =>
      'native_background_restriction_requires_review',
    'supervisor_pause_requires_user_review' =>
      'supervisor_pause_requires_user_review',
    'native_recovery_requires_user_review' =>
      'native_recovery_requires_user_review',
    'replay_pending_sample_after_restore' =>
      'replay_pending_sample_after_restore',
    'continue_offline_from_checkpoint' => 'continue_offline_from_checkpoint',
    'retry_native_registration_from_checkpoint' =>
      'retry_native_registration_from_checkpoint',
    'restore_local_recoverable_session' => 'restore_local_recoverable_session',
    'native_background_recovery_ready' => 'native_background_recovery_ready',
    'native_sample_ready_for_engine' => 'native_sample_ready_for_engine',
    _ => 'native_recovery_illegal_transition',
  };
}

TripNativeInterruptionRecoveryStatus? _safeStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripNativeInterruptionRecoveryStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

String? _safeReasonObject(Object? value) {
  if (value is! String) return null;
  return _safeReason(value);
}

TripTrackingSessionLifecycleState? _safeLifecycleState(Object? value) {
  if (value is! String) return null;
  for (final state in TripTrackingSessionLifecycleState.values) {
    if (state.name == value) return state;
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
