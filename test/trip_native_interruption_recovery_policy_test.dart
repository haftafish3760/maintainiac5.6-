import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_dashboard_status_rollup_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_lifecycle_supervisor_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_native_event_lifecycle_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_native_interruption_recovery_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_error_recovery_plan.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_recovery_policy.dart';

void main() {
  test(
    'valid location event feeds engine while preserving backup boundary',
    () {
      final native = nativeDecision(
        current: TripTrackingSessionLifecycleState.starting,
        event: locationEvent(),
      );
      final supervisor = supervisorDecision(
        lifecycle: TripTrackingSessionLifecycleState.starting,
        backupMirrorReady: true,
      );
      final decision = TripNativeInterruptionRecoveryPolicy.evaluate(
        nativeDecision: native,
        supervisorDecision: supervisor,
        localCheckpointAvailable: true,
      );

      expect(decision.status, TripNativeInterruptionRecoveryStatus.feedEngine);
      expect(decision.canFeedEngine, isTrue);
      expect(decision.nextLifecycle, TripTrackingSessionLifecycleState.active);
      expect(decision.canUploadBackupMirror, isTrue);
    },
  );

  test('background restriction prompts review and cannot upload backup', () {
    final decision = TripNativeInterruptionRecoveryPolicy.evaluate(
      nativeDecision: nativeDecision(
        event: statusEvent('backgroundRestricted'),
      ),
      supervisorDecision: supervisorDecision(
        lifecycle: TripTrackingSessionLifecycleState.interrupted,
        nativeTrackingAvailable: false,
      ),
      localCheckpointAvailable: true,
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripNativeInterruptionRecoveryStatus.promptUser);
    expect(
      decision.reasonCode,
      'native_background_restriction_requires_review',
    );
    expect(decision.canFeedEngine, isFalse);
    expect(decision.shouldRequestUserAction, isTrue);
    expect(decision.canUploadBackupMirror, isFalse);
    expect(safe['nativeInterruptionCanEndTripAutomatically'], isFalse);
    expect(safe['nativeInterruptionCanDeleteLocalData'], isFalse);
  });

  test(
    'pending recoverable sample can replay in background from checkpoint',
    () {
      final decision = TripNativeInterruptionRecoveryPolicy.evaluate(
        nativeDecision: nativeDecision(
          current: TripTrackingSessionLifecycleState.interrupted,
          event: statusEvent('recovering'),
        ),
        supervisorDecision: supervisorDecision(
          lifecycle: TripTrackingSessionLifecycleState.interrupted,
          recovery: const TripTrackingRecoveryDecision(
            status: TripTrackingRecoveryStatus.pendingReplayReady,
            safeReason: 'trip_recovery_pending_replay_ready',
            canRestore: true,
            requiresUserAction: false,
            estimatedOdometer: 1120,
            pendingSampleQueued: true,
          ),
          backupMirrorReady: true,
        ),
        localCheckpointAvailable: true,
      );

      expect(
        decision.status,
        TripNativeInterruptionRecoveryStatus.recoverInBackground,
      );
      expect(decision.reasonCode, 'replay_pending_sample_after_restore');
      expect(decision.canReplayPendingSample, isTrue);
      expect(decision.canUploadBackupMirror, isTrue);
    },
  );

  test('native stopped status is ignored and never completes local trip', () {
    final decision = TripNativeInterruptionRecoveryPolicy.evaluate(
      nativeDecision: nativeDecision(event: statusEvent('stopped')),
      supervisorDecision: supervisorDecision(),
      localCheckpointAvailable: true,
    );

    expect(decision.status, TripNativeInterruptionRecoveryStatus.ignoreSafely);
    expect(decision.reasonCode, 'native_stopped_status_ignored');
    expect(decision.canFeedEngine, isFalse);
    expect(decision.canUploadBackupMirror, isFalse);
  });

  test('missing local checkpoint blocks recovery from native events', () {
    final decision = TripNativeInterruptionRecoveryPolicy.evaluate(
      nativeDecision: nativeDecision(
        current: TripTrackingSessionLifecycleState.interrupted,
        event: statusEvent('recovering'),
      ),
      supervisorDecision: supervisorDecision(),
      localCheckpointAvailable: false,
    );

    expect(decision.status, TripNativeInterruptionRecoveryStatus.blocked);
    expect(decision.reasonCode, 'native_recovery_missing_local_checkpoint');
    expect(decision.canReplayPendingSample, isFalse);
    expect(decision.canUploadBackupMirror, isFalse);
  });

  test(
    'safe summary denies remote, mapbox, raw payload, and token authority',
    () {
      final safe = TripNativeInterruptionRecoveryPolicy.evaluate(
        nativeDecision: nativeDecision(event: statusEvent('recovering')),
        supervisorDecision: supervisorDecision(),
        localCheckpointAvailable: true,
      ).toSafeDashboardMap();

      expect(safe['backgroundRecoveryCanRunWithoutMaps'], isTrue);
      expect(safe['mapsRequiredForRecovery'], isFalse);
      expect(safe['firestoreCanForceRecovery'], isFalse);
      expect(safe['cloudFunctionCanForceRecovery'], isFalse);
      expect(safe['mapboxCanForceRecovery'], isFalse);
      expect(safe['rawNativePayloadIncluded'], isFalse);
      expect(safe['rawLocationIncluded'], isFalse);
      expect(safe['tokensIncluded'], isFalse);
      expect(safe['failedTerminalSessionProtectedFromNativeResume'], isTrue);
      expect(safe['nativeStoppedStatusCannotCompleteTrip'], isTrue);
      expect(safe['permissionLossCannotFeedEngine'], isTrue);
      expect(
        safe['backgroundRestrictionRequiresRecoverableInterruption'],
        isTrue,
      );
      expect(safe['foregroundServiceLossRequiresCheckpointRecovery'], isTrue);
      expect(safe['recoveryCanDegradeToUserReviewWithoutDataLoss'], isTrue);
      expect(safe.toString(), isNot(contains('pk.')));
      expect(safe.toString(), isNot(contains('sk.')));
    },
  );

  test('safe native recovery summary validates as renderable', () {
    final validation =
        TripNativeInterruptionRecoverySummaryValidation.fromSummary(
          TripNativeInterruptionRecoveryPolicy.evaluate(
            nativeDecision: nativeDecision(event: statusEvent('recovering')),
            supervisorDecision: supervisorDecision(),
            localCheckpointAvailable: true,
          ).toSafeDashboardMap(),
        );

    expect(validation.isRenderable, isTrue);
    expect(
      validation.status,
      TripNativeInterruptionRecoveryStatus.ignoreSafely,
    );
    expect(validation.reasons, isEmpty);
  });

  test('native recovery summary rejects mutation and remote force claims', () {
    final validation =
        TripNativeInterruptionRecoverySummaryValidation.fromSummary(
          TripNativeInterruptionRecoveryPolicy.evaluate(
            nativeDecision: nativeDecision(event: statusEvent('recovering')),
            supervisorDecision: supervisorDecision(),
            localCheckpointAvailable: true,
          ).toSafeDashboardMap()..addAll({
            'nativeInterruptionCanEndTripAutomatically': true,
            'nativeInterruptionCanDeleteLocalData': true,
            'nativeInterruptionCanConfirmOdometer': true,
            'nativeInterruptionCanCreateOfficialStop': true,
            'nativeInterruptionCanPurgeLocalDataAfterBackup': true,
            'nativeInterruptionCanBypassLocalCheckpoint': true,
            'nativeInterruptionCanBypassUserConsent': true,
            'completedSessionProtectedFromNativeResume': false,
            'failedTerminalSessionProtectedFromNativeResume': false,
            'nativeStoppedStatusCannotCompleteTrip': false,
            'permissionLossCannotFeedEngine': false,
            'backgroundRestrictionRequiresRecoverableInterruption': false,
            'foregroundServiceLossRequiresCheckpointRecovery': false,
            'recoveryCanDegradeToUserReviewWithoutDataLoss': false,
            'backgroundRecoveryCanRunWithoutMaps': false,
            'mapsRequiredForRecovery': true,
            'firestoreCanForceRecovery': true,
            'cloudFunctionCanForceRecovery': true,
            'mapboxCanForceRecovery': true,
            'rawNativePayloadIncluded': true,
            'rawLocationIncluded': true,
            'routeGeometryIncluded': true,
            'tokensIncluded': true,
            'debug': 'pk.public 35.123456,-80.123456',
          }),
        );

    expect(validation.isRenderable, isFalse);
    expect(
      validation.reasons,
      contains('native_recovery_can_mutate_trip_truth'),
    );
    expect(validation.reasons, contains('consent_boundary_missing'));
    expect(
      validation.reasons,
      contains('completed_session_resume_boundary_missing'),
    );
    expect(validation.reasons, contains('remote_or_map_can_force_recovery'));
    expect(
      validation.reasons,
      contains('summary_contains_sensitive_recovery_material'),
    );
    expect(validation.reasons, contains('summary_contains_sensitive_text'));
  });
}

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

const noRecovery = TripTrackingRecoveryDecision(
  status: TripTrackingRecoveryStatus.noRecoverableTrip,
  safeReason: 'trip_recovery_none',
  canRestore: false,
  requiresUserAction: false,
  estimatedOdometer: null,
  pendingSampleQueued: false,
);

TripNativeEventLifecycleDecision nativeDecision({
  TripTrackingSessionLifecycleState current =
      TripTrackingSessionLifecycleState.active,
  TripTrackingPlatformEvent? event,
}) {
  return TripNativeEventLifecyclePolicy.evaluate(
    currentState: current,
    event: event ?? locationEvent(),
  );
}

TripLifecycleSupervisorDecision supervisorDecision({
  TripTrackingSessionLifecycleState lifecycle =
      TripTrackingSessionLifecycleState.active,
  bool nativeTrackingAvailable = true,
  bool backupMirrorReady = false,
  TripTrackingRecoveryDecision recovery = noRecovery,
}) {
  return TripLifecycleSupervisorPolicy.evaluate(
    currentLifecycle: lifecycle,
    dashboardRollup: normalRollup,
    errorRecoveryPlan: TripTrackingErrorRecoveryPlan.forNativeError(
      null,
      failureCount: 0,
      activeTripHasLocalCheckpoint: true,
      userCanOpenSettings: false,
    ),
    recoveryDecision: recovery,
    localCheckpointAvailable: true,
    nativeTrackingAvailable: nativeTrackingAvailable,
    backupMirrorReady: backupMirrorReady,
  );
}

TripTrackingPlatformEvent locationEvent() {
  return TripTrackingPlatformEvent.fromMap({
    'schemaVersion': 1,
    'type': 'location',
    'latitude': 35.0,
    'longitude': -80.0,
    'horizontalAccuracyMeters': 8,
    'recordedAt': DateTime.utc(2026, 7, 18, 12).toIso8601String(),
    'speedMetersPerSecond': 12,
  });
}

TripTrackingPlatformEvent statusEvent(String status) {
  return TripTrackingPlatformEvent.fromMap({
    'schemaVersion': 1,
    'type': 'status',
    'status': status,
  });
}
