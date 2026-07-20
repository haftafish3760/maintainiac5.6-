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
      currentLifecycle: TripTrackingSessionLifecycleState.activeTracking,
      dashboardRollup: normalRollup,
      errorRecoveryPlan: recoveryPlan(null),
      recoveryDecision: noRecovery,
      localCheckpointAvailable: true,
      nativeTrackingAvailable: true,
      backupMirrorReady: true,
    );

    expect(decision.status, TripLifecycleSupervisorStatus.continueTracking);
    expect(
      decision.nextLifecycle,
      TripTrackingSessionLifecycleState.activeTracking,
    );
    expect(decision.shouldKeepForegroundServiceAlive, isTrue);
    expect(decision.canUploadBackupMirror, isTrue);
  });

  test(
    'dashboard blocked pauses for user review without deleting checkpoint',
    () {
      final decision = TripLifecycleSupervisorPolicy.evaluate(
        currentLifecycle: TripTrackingSessionLifecycleState.activeTracking,
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
      expect(safe['backgroundRecoveryRequiresLocalCheckpoint'], isTrue);
      expect(safe['backupMirrorBlockedWhenUserActionRequired'], isTrue);
    },
  );

  test('permission native error prompts user and blocks backup upload', () {
    final decision = TripLifecycleSupervisorPolicy.evaluate(
      currentLifecycle: TripTrackingSessionLifecycleState.activeTracking,
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
      TripTrackingSessionLifecycleState.awaitingPermission,
    );
    expect(decision.canUploadBackupMirror, isFalse);
  });

  test('recoverable session replays pending sample in background', () {
    final decision = TripLifecycleSupervisorPolicy.evaluate(
      currentLifecycle: TripTrackingSessionLifecycleState.signalLost,
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
    final safe = decision.toSafeDashboardMap();
    expect(safe['pendingReplayRequiresValidatedLocalSample'], isTrue);
    expect(safe['pendingReplayRequiresMatchingSession'], isTrue);
    expect(safe['recoveryCannotReplayMockedLocation'], isTrue);
  });

  test('malformed native payload continues offline from local checkpoint', () {
    final decision = TripLifecycleSupervisorPolicy.evaluate(
      currentLifecycle: TripTrackingSessionLifecycleState.activeTracking,
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
    expect(
      decision.toSafeDashboardMap()['malformedNativePayloadCanEndTrip'],
      isFalse,
    );
  });

  test('missing local checkpoint fails closed at supervisor boundary', () {
    final decision = TripLifecycleSupervisorPolicy.evaluate(
      currentLifecycle: TripTrackingSessionLifecycleState.activeTracking,
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
        currentLifecycle: TripTrackingSessionLifecycleState.activeTracking,
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
      expect(
        safe['foregroundServiceCanOnlyStayAliveForRecoverableLocalTrip'],
        isTrue,
      );
      expect(safe['rawNativePayloadIncluded'], isFalse);
      expect(safe['preciseLocationIncluded'], isFalse);
      expect(safe['tokensIncluded'], isFalse);
      expect(safe['permissionRequiredCannotUploadBackup'], isTrue);
      expect(safe['fleetObserverCanRecoverTrip'], isFalse);
      expect(safe['authenticationAloneAuthorizesRecovery'], isFalse);
    },
  );

  test('safe supervisor summary validates recovery truth boundary', () {
    final validation = TripLifecycleSupervisorSummaryValidation.fromSummary(
      TripLifecycleSupervisorPolicy.evaluate(
        currentLifecycle: TripTrackingSessionLifecycleState.activeTracking,
        dashboardRollup: normalRollup,
        errorRecoveryPlan: recoveryPlan(null),
        recoveryDecision: noRecovery,
        localCheckpointAvailable: true,
        nativeTrackingAvailable: true,
        backupMirrorReady: true,
      ).toSafeDashboardMap(),
    );

    expect(validation.isRenderable, isTrue);
    expect(validation.reasons, isEmpty);
  });

  test('supervisor validation rejects forged replay and upload states', () {
    final base = TripLifecycleSupervisorPolicy.evaluate(
      currentLifecycle: TripTrackingSessionLifecycleState.activeTracking,
      dashboardRollup: normalRollup,
      errorRecoveryPlan: recoveryPlan(null),
      recoveryDecision: noRecovery,
      localCheckpointAvailable: true,
      nativeTrackingAvailable: true,
      backupMirrorReady: true,
    ).toSafeDashboardMap();

    final replay = TripLifecycleSupervisorSummaryValidation.fromSummary(
      base..addAll({
        'status': 'continueTracking',
        'reasonCode': 'supervisor_continue_tracking',
        'nextLifecycle': 'active',
        'canReplayPendingSample': true,
      }),
    );
    final upload = TripLifecycleSupervisorSummaryValidation.fromSummary(
      TripLifecycleSupervisorPolicy.evaluate(
        currentLifecycle: TripTrackingSessionLifecycleState.activeTracking,
        dashboardRollup: normalRollup,
        errorRecoveryPlan: recoveryPlan(null),
        recoveryDecision: noRecovery,
        localCheckpointAvailable: true,
        nativeTrackingAvailable: true,
        backupMirrorReady: true,
      ).toSafeDashboardMap()..addAll({
        'shouldRequestUserAction': true,
        'canUploadBackupMirror': true,
      }),
    );
    final blocked = TripLifecycleSupervisorSummaryValidation.fromSummary(
      TripLifecycleSupervisorPolicy.evaluate(
        currentLifecycle: TripTrackingSessionLifecycleState.activeTracking,
        dashboardRollup: normalRollup,
        errorRecoveryPlan: recoveryPlan(null),
        recoveryDecision: noRecovery,
        localCheckpointAvailable: false,
        nativeTrackingAvailable: true,
        backupMirrorReady: true,
      ).toSafeDashboardMap()..addAll({
        'canReplayPendingSample': true,
        'canUploadBackupMirror': true,
        'shouldKeepForegroundServiceAlive': true,
      }),
    );

    expect(replay.isRenderable, isFalse);
    expect(
      replay.reasons,
      contains('pending_replay_lifecycle_boundary_missing'),
    );
    expect(upload.isRenderable, isFalse);
    expect(
      upload.reasons,
      contains('backup_upload_user_action_boundary_missing'),
    );
    expect(blocked.isRenderable, isFalse);
    expect(blocked.reasons, contains('blocked_supervisor_boundary_missing'));
  });

  test(
    'forged supervisor summaries cannot finish or remotely control trips',
    () {
      final validation = TripLifecycleSupervisorSummaryValidation.fromSummary(
        TripLifecycleSupervisorPolicy.evaluate(
          currentLifecycle: TripTrackingSessionLifecycleState.activeTracking,
          dashboardRollup: normalRollup,
          errorRecoveryPlan: recoveryPlan(null),
          recoveryDecision: noRecovery,
          localCheckpointAvailable: true,
          nativeTrackingAvailable: true,
          backupMirrorReady: true,
        ).toSafeDashboardMap()..addAll({
          'supervisorCanDeleteLocalData': true,
          'supervisorCanConfirmOdometer': true,
          'supervisorCanSetGlobalTruth': true,
          'supervisorCanChangeOfficialMileage': true,
          'supervisorCanCreateOfficialStop': true,
          'malformedNativePayloadCanEndTrip': true,
          'remoteSupervisorCanOverrideLocalTrip': true,
          'firestoreCanOverrideLifecycle': true,
          'mapboxCanOverrideLifecycle': true,
          'backgroundRecoveryCanRunWithoutMaps': false,
          'mapsRequiredForRecovery': true,
          'localCheckpointPreservedUntilReview': false,
          'backgroundRecoveryRequiresLocalCheckpoint': false,
          'foregroundServiceCanOnlyStayAliveForRecoverableLocalTrip': false,
          'backupMirrorBlockedWhenUserActionRequired': false,
          'pendingReplayRequiresValidatedLocalSample': false,
          'pendingReplayRequiresMatchingSession': false,
          'recoveryCannotReplayMockedLocation': false,
          'permissionRequiredCannotUploadBackup': false,
          'fleetObserverCanRecoverTrip': true,
          'authenticationAloneAuthorizesRecovery': true,
          'hiveRemainsOperationalSourceOfTruth': false,
          'firestoreMirrorOnly': false,
          'odometerRemainsOfficialMileageTruth': false,
          'rawNativePayloadIncluded': true,
          'rawTripRecordsIncluded': true,
          'preciseLocationIncluded': true,
          'routeGeometryIncluded': true,
          'tokensIncluded': true,
          'debug': 'sk.secret 35.123456,-80.123456',
        }),
      );

      expect(validation.isRenderable, isFalse);
      expect(validation.reasons, contains('supervisor_can_create_trip_truth'));
      expect(validation.reasons, contains('remote_can_override_lifecycle'));
      expect(
        validation.reasons,
        contains('recovery_checkpoint_boundary_missing'),
      );
      expect(
        validation.reasons,
        contains('recovery_authorization_boundary_missing'),
      );
      expect(
        validation.reasons,
        contains('recovery_source_of_truth_boundary_missing'),
      );
      expect(
        validation.reasons,
        contains('summary_contains_sensitive_recovery_material'),
      );
    },
  );

  test(
    'permission lifecycle never uploads backup or replays pending sample',
    () {
      final decision = TripLifecycleSupervisorPolicy.evaluate(
        currentLifecycle: TripTrackingSessionLifecycleState.activeTracking,
        dashboardRollup: normalRollup,
        errorRecoveryPlan: recoveryPlan(
          'trip_tracking_location_denied',
          settings: true,
        ),
        recoveryDecision: recoveryReady,
        localCheckpointAvailable: true,
        nativeTrackingAvailable: false,
        backupMirrorReady: true,
      );
      final safe = decision.toSafeDashboardMap();

      expect(decision.status, TripLifecycleSupervisorStatus.promptUser);
      expect(decision.canReplayPendingSample, isFalse);
      expect(decision.canUploadBackupMirror, isFalse);
      expect(safe['permissionRequiredCannotUploadBackup'], isTrue);
      expect(
        TripLifecycleSupervisorSummaryValidation.fromSummary(safe).isRenderable,
        isTrue,
      );
    },
  );
}
