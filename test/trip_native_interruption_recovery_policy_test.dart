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

  test('permission event wins a race with stale active supervision', () {
    final decision = TripNativeInterruptionRecoveryPolicy.evaluate(
      nativeDecision: nativeDecision(event: statusEvent('permissionRequired')),
      supervisorDecision: supervisorDecision(),
      localCheckpointAvailable: true,
    );

    expect(decision.status, TripNativeInterruptionRecoveryStatus.promptUser);
    expect(decision.reasonCode, 'native_permission_requires_user_review');
    expect(
      decision.nextLifecycle,
      TripTrackingSessionLifecycleState.permissionRequired,
    );
    expect(decision.shouldKeepForegroundServiceAlive, isFalse);
    expect(decision.canFeedEngine, isFalse);
    expect(
      TripNativeInterruptionRecoverySummaryValidation.fromSummary(
        decision.toSafeDashboardMap(),
      ).isRenderable,
      isTrue,
    );
  });

  test('background restriction wins a race with stale active supervision', () {
    final decision = TripNativeInterruptionRecoveryPolicy.evaluate(
      nativeDecision: nativeDecision(
        event: statusEvent('backgroundRestricted'),
      ),
      supervisorDecision: supervisorDecision(),
      localCheckpointAvailable: true,
    );

    expect(decision.status, TripNativeInterruptionRecoveryStatus.promptUser);
    expect(
      decision.nextLifecycle,
      TripTrackingSessionLifecycleState.interrupted,
    );
    expect(decision.shouldKeepForegroundServiceAlive, isFalse);
    expect(decision.canFeedEngine, isFalse);

    final forged = TripNativeInterruptionRecoverySummaryValidation.fromSummary({
      ...decision.toSafeDashboardMap(),
      'nextLifecycle': TripTrackingSessionLifecycleState.active.name,
    });
    expect(forged.isRenderable, isFalse);
    expect(
      forged.reasons,
      contains('native_review_lifecycle_boundary_missing'),
    );
  });

  test('provider degradation wins a race with stale active supervision', () {
    final decision = TripNativeInterruptionRecoveryPolicy.evaluate(
      nativeDecision: nativeDecision(event: statusEvent('providerUnavailable')),
      supervisorDecision: supervisorDecision(),
      localCheckpointAvailable: true,
    );

    expect(
      decision.status,
      TripNativeInterruptionRecoveryStatus.recoverInBackground,
    );
    expect(decision.nextLifecycle, TripTrackingSessionLifecycleState.degraded);
    expect(decision.canFeedEngine, isFalse);
    expect(decision.shouldRequestUserAction, isFalse);
  });

  test('native pause wins a race with stale active supervision', () {
    final decision = TripNativeInterruptionRecoveryPolicy.evaluate(
      nativeDecision: nativeDecision(event: statusEvent('paused')),
      supervisorDecision: supervisorDecision(),
      localCheckpointAvailable: true,
    );

    expect(
      decision.status,
      TripNativeInterruptionRecoveryStatus.recoverInBackground,
    );
    expect(decision.nextLifecycle, TripTrackingSessionLifecycleState.paused);
    expect(decision.canFeedEngine, isFalse);
  });

  test(
    'explicit supervisor recovery remains authoritative over native noise',
    () {
      final decision = TripNativeInterruptionRecoveryPolicy.evaluate(
        nativeDecision: nativeDecision(event: statusEvent('paused')),
        supervisorDecision: supervisorDecision(
          recovery: const TripTrackingRecoveryDecision(
            status: TripTrackingRecoveryStatus.pendingReplayReady,
            safeReason: 'trip_recovery_pending_replay_ready',
            canRestore: true,
            requiresUserAction: false,
            estimatedOdometer: 1120,
            pendingSampleQueued: true,
          ),
        ),
        localCheckpointAvailable: true,
      );

      expect(
        decision.nextLifecycle,
        TripTrackingSessionLifecycleState.recovering,
      );
      expect(decision.canReplayPendingSample, isTrue);
    },
  );

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
      final safe = decision.toSafeDashboardMap();
      expect(safe['pendingReplayRequiresValidatedLocalSample'], isTrue);
      expect(safe['pendingReplayRequiresMatchingSession'], isTrue);
      expect(safe['pendingReplayCannotUseMockedLocation'], isTrue);
      expect(safe['backupMirrorCannotConfirmTripTruth'], isTrue);
      expect(safe['backupMirrorCannotSetGlobalTruth'], isTrue);
      expect(safe['backupMirrorCannotChangeOfficialMileage'], isTrue);
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

  test('ignored native noise does not require local checkpoint recovery', () {
    for (final ignored in [
      nativeDecision(
        current: TripTrackingSessionLifecycleState.completed,
        event: locationEvent(),
      ),
      nativeDecision(event: statusEvent('stopped')),
    ]) {
      final decision = TripNativeInterruptionRecoveryPolicy.evaluate(
        nativeDecision: ignored,
        supervisorDecision: supervisorDecision(),
        localCheckpointAvailable: false,
      );
      final safe = decision.toSafeDashboardMap();

      expect(
        decision.status,
        TripNativeInterruptionRecoveryStatus.ignoreSafely,
      );
      expect(decision.canFeedEngine, isFalse);
      expect(decision.canReplayPendingSample, isFalse);
      expect(decision.canUploadBackupMirror, isFalse);
      expect(safe['nativeInterruptionCanDeleteLocalData'], isFalse);
      expect(safe['nativeStoppedStatusCannotCompleteTrip'], isTrue);
      expect(
        TripNativeInterruptionRecoverySummaryValidation.fromSummary(
          safe,
        ).isRenderable,
        isTrue,
      );
    }
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
      expect(safe['physicalOdometerRequiredForOfficialMileage'], isTrue);
      expect(safe['confirmedOdometerOverridesExternalMileage'], isTrue);
      expect(safe['externalMileageCannotBecomeGlobalTruth'], isTrue);
      expect(safe['gpsDistanceCanOnlyAdviseMileageReview'], isTrue);
      expect(safe['mapMatchingCanOnlyAdviseMileageReview'], isTrue);
      expect(safe['optimizationCannotChangeOfficialMileage'], isTrue);
      expect(safe['nativeInterruptionCanSetGlobalTruth'], isFalse);
      expect(safe['nativeInterruptionCanChangeOfficialMileage'], isFalse);
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
      expect(safe['backupMirrorBlockedWhenUserActionRequired'], isTrue);
      expect(safe['authenticationAloneAuthorizesNativeRecovery'], isFalse);
      expect(safe['fleetObserverCanForceNativeRecovery'], isFalse);
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
            'nativeInterruptionCanSetGlobalTruth': true,
            'nativeInterruptionCanChangeOfficialMileage': true,
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
            'pendingReplayRequiresValidatedLocalSample': false,
            'pendingReplayRequiresMatchingSession': false,
            'pendingReplayCannotUseMockedLocation': false,
            'backupMirrorBlockedWhenUserActionRequired': false,
            'backupMirrorCannotConfirmTripTruth': false,
            'backupMirrorCannotSetGlobalTruth': false,
            'backupMirrorCannotChangeOfficialMileage': false,
            'authenticationAloneAuthorizesNativeRecovery': true,
            'fleetObserverCanForceNativeRecovery': true,
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
    expect(
      validation.reasons,
      contains('native_recovery_authorization_boundary_missing'),
    );
    expect(validation.reasons, contains('remote_or_map_can_force_recovery'));
    expect(
      validation.reasons,
      contains('summary_contains_sensitive_recovery_material'),
    );
    expect(validation.reasons, contains('summary_contains_sensitive_text'));
  });

  test('user-action recovery blocks replay and backup mirror', () {
    final decision = TripNativeInterruptionRecoveryPolicy.evaluate(
      nativeDecision: nativeDecision(event: statusEvent('permissionRequired')),
      supervisorDecision: supervisorDecision(
        lifecycle: TripTrackingSessionLifecycleState.permissionRequired,
        nativeTrackingAvailable: false,
        backupMirrorReady: true,
        recovery: const TripTrackingRecoveryDecision(
          status: TripTrackingRecoveryStatus.pendingReplayReady,
          safeReason: 'trip_recovery_pending_replay_ready',
          canRestore: true,
          requiresUserAction: true,
          estimatedOdometer: 1120,
          pendingSampleQueued: true,
        ),
      ),
      localCheckpointAvailable: true,
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.shouldRequestUserAction, isTrue);
    expect(decision.canReplayPendingSample, isFalse);
    expect(decision.canUploadBackupMirror, isFalse);
    expect(safe['backupMirrorBlockedWhenUserActionRequired'], isTrue);
    expect(
      TripNativeInterruptionRecoverySummaryValidation.fromSummary(
        safe,
      ).isRenderable,
      isTrue,
    );
  });

  test('native recovery summary rejects status authority mismatch', () {
    final feed = TripNativeInterruptionRecoveryPolicy.evaluate(
      nativeDecision: nativeDecision(
        current: TripTrackingSessionLifecycleState.starting,
        event: locationEvent(),
      ),
      supervisorDecision: supervisorDecision(
        lifecycle: TripTrackingSessionLifecycleState.starting,
      ),
      localCheckpointAvailable: true,
    ).toSafeDashboardMap();
    final prompt = TripNativeInterruptionRecoveryPolicy.evaluate(
      nativeDecision: nativeDecision(event: statusEvent('permissionRequired')),
      supervisorDecision: supervisorDecision(
        lifecycle: TripTrackingSessionLifecycleState.permissionRequired,
        nativeTrackingAvailable: false,
      ),
      localCheckpointAvailable: true,
    ).toSafeDashboardMap();

    final forgedFeed =
        TripNativeInterruptionRecoverySummaryValidation.fromSummary({
          ...feed,
          'canFeedEngine': false,
          'shouldRequestUserAction': true,
        });
    final forgedPrompt =
        TripNativeInterruptionRecoverySummaryValidation.fromSummary({
          ...prompt,
          'canUploadBackupMirror': true,
          'canReplayPendingSample': true,
        });

    expect(forgedFeed.isRenderable, isFalse);
    expect(forgedPrompt.isRenderable, isFalse);
    expect(
      forgedFeed.reasons,
      contains('native_recovery_status_conflicts_with_authority'),
    );
    expect(
      forgedPrompt.reasons,
      contains('native_recovery_status_conflicts_with_authority'),
    );
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
