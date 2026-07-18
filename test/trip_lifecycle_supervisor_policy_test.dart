import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_dashboard_status_rollup_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_lifecycle_supervisor_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_error_recovery_plan.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_recovery_policy.dart';

void main() {
  const normalRollup = TripDashboardStatusRollupDecision(
    severity: TripDashboardStatusRollupSeverity.normal,
    primaryReasonCode: 'trip_dashboard_normal',
    startButtonEnabled: true,
    liveTimerVisible: true,
    liveOdometerProjectionVisible: true,
    stopReviewVisible: false,
    odometerReviewVisible: false,
    backupStatusVisible: false,
    routeStorageWarningVisible: false,
  );
  const blockedRollup = TripDashboardStatusRollupDecision(
    severity: TripDashboardStatusRollupSeverity.blocked,
    primaryReasonCode: 'odometer_review_blocked',
    startButtonEnabled: false,
    liveTimerVisible: true,
    liveOdometerProjectionVisible: false,
    stopReviewVisible: false,
    odometerReviewVisible: true,
    backupStatusVisible: true,
    routeStorageWarningVisible: false,
  );
  const noRecovery = TripTrackingRecoveryDecision(
    status: TripTrackingRecoveryStatus.noRecoverableTrip,
    safeReason: 'trip_recovery_none',
    canRestore: false,
    requiresUserAction: false,
    estimatedOdometer: null,
    pendingSampleQueued: false,
  );
  const recoveryReady = TripTrackingRecoveryDecision(
    status: TripTrackingRecoveryStatus.pendingReplayReady,
    safeReason: 'trip_recovery_pending_replay_ready',
    canRestore: true,
    requiresUserAction: false,
    estimatedOdometer: 1120,
    pendingSampleQueued: true,
  );

  TripTrackingErrorRecoveryPlan recoveryPlan(
    String? code, {
    int failureCount = 0,
    bool checkpoint = true,
    bool settings = false,
  }) {
    return TripTrackingErrorRecoveryPlan.forNativeError(
      code,
      failureCount: failureCount,
      activeTripHasLocalCheckpoint: checkpoint,
      userCanOpenSettings: settings,
    );
  }

  test('normal active session continues tracking and may upload backup', () {
    final decision = TripLifecycleSupervisorPolicy.evaluate(
      currentLifecycle: TripTrackingSessionLifecycleState.active,
      dashboardRollup: normalRollup,
      errorRecoveryPlan: recoveryPlan(null),
      recoveryDecision: noRecovery,
      localCheckpointAvailable: true,
      nativeTrackingAvailable: true,
      backupMirrorReady: true,
    );

    expect(decision.status, TripLifecycleSupervisorStatus.continueTracking);
    expect(decision.nextLifecycle, TripTrackingSessionLifecycleState.active);
    expect(decision.shouldKeepForegroundServiceAlive, isTrue);
    expect(decision.canUploadBackupMirror, isTrue);
  });

  test(
    'dashboard blocked pauses for user review without deleting checkpoint',
    () {
      final decision = TripLifecycleSupervisorPolicy.evaluate(
        currentLifecycle: TripTrackingSessionLifecycleState.active,
        dashboardRollup: blockedRollup,
        errorRecoveryPlan: recoveryPlan(null),
        recoveryDecision: noRecovery,
        localCheckpointAvailable: true,
        nativeTrackingAvailable: true,
        backupMirrorReady: true,
      );
      final safe = decision.toSafeDashboardMap();

      expect(decision.status, TripLifecycleSupervisorStatus.pauseForReview);
      expect(decision.shouldRequestUserAction, isTrue);
      expect(decision.canUploadBackupMirror, isFalse);
      expect(safe['localCheckpointPreservedUntilReview'], isTrue);
    },
  );

  test('permission native error prompts user and blocks backup upload', () {
    final decision = TripLifecycleSupervisorPolicy.evaluate(
      currentLifecycle: TripTrackingSessionLifecycleState.active,
      dashboardRollup: normalRollup,
      errorRecoveryPlan: recoveryPlan(
        'trip_tracking_location_denied',
        settings: true,
      ),
      recoveryDecision: noRecovery,
      localCheckpointAvailable: true,
      nativeTrackingAvailable: false,
      backupMirrorReady: true,
    );

    expect(decision.status, TripLifecycleSupervisorStatus.promptUser);
    expect(
      decision.nextLifecycle,
      TripTrackingSessionLifecycleState.permissionRequired,
    );
    expect(decision.canUploadBackupMirror, isFalse);
  });

  test('recoverable session replays pending sample in background', () {
    final decision = TripLifecycleSupervisorPolicy.evaluate(
      currentLifecycle: TripTrackingSessionLifecycleState.interrupted,
      dashboardRollup: normalRollup,
      errorRecoveryPlan: recoveryPlan(null),
      recoveryDecision: recoveryReady,
      localCheckpointAvailable: true,
      nativeTrackingAvailable: true,
      backupMirrorReady: true,
    );

    expect(decision.status, TripLifecycleSupervisorStatus.recoverInBackground);
    expect(decision.reasonCode, 'replay_pending_sample_after_restore');
    expect(
      decision.nextLifecycle,
      TripTrackingSessionLifecycleState.recovering,
    );
    expect(decision.canReplayPendingSample, isTrue);
    expect(decision.canUploadBackupMirror, isTrue);
  });

  test('malformed native payload continues offline from local checkpoint', () {
    final decision = TripLifecycleSupervisorPolicy.evaluate(
      currentLifecycle: TripTrackingSessionLifecycleState.active,
      dashboardRollup: normalRollup,
      errorRecoveryPlan: recoveryPlan('invalidLocationPayload'),
      recoveryDecision: noRecovery,
      localCheckpointAvailable: true,
      nativeTrackingAvailable: false,
      backupMirrorReady: false,
    );

    expect(decision.status, TripLifecycleSupervisorStatus.recoverInBackground);
    expect(decision.reasonCode, 'continue_offline_from_checkpoint');
    expect(decision.shouldRequestUserAction, isFalse);
  });

  test('missing local checkpoint fails closed at supervisor boundary', () {
    final decision = TripLifecycleSupervisorPolicy.evaluate(
      currentLifecycle: TripTrackingSessionLifecycleState.active,
      dashboardRollup: normalRollup,
      errorRecoveryPlan: recoveryPlan(null),
      recoveryDecision: noRecovery,
      localCheckpointAvailable: false,
      nativeTrackingAvailable: true,
      backupMirrorReady: true,
    );

    expect(decision.status, TripLifecycleSupervisorStatus.blocked);
    expect(decision.reasonCode, 'supervisor_invalid_local_boundary');
    expect(decision.canUploadBackupMirror, isFalse);
  });

  test(
    'safe summary denies remote, mapbox, raw location, and token authority',
    () {
      final safe = TripLifecycleSupervisorPolicy.evaluate(
        currentLifecycle: TripTrackingSessionLifecycleState.active,
        dashboardRollup: normalRollup,
        errorRecoveryPlan: recoveryPlan(null),
        recoveryDecision: noRecovery,
        localCheckpointAvailable: true,
        nativeTrackingAvailable: true,
        backupMirrorReady: true,
      ).toSafeDashboardMap();

      expect(safe['supervisorCanDeleteLocalData'], isFalse);
      expect(safe['remoteSupervisorCanOverrideLocalTrip'], isFalse);
      expect(safe['firestoreCanOverrideLifecycle'], isFalse);
      expect(safe['mapboxCanOverrideLifecycle'], isFalse);
      expect(safe['rawNativePayloadIncluded'], isFalse);
      expect(safe['preciseLocationIncluded'], isFalse);
      expect(safe['tokensIncluded'], isFalse);
    },
  );
}
