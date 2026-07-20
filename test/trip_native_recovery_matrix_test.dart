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
  test('native recovery matrix preserves local trip truth', () {
    final cases = <_NativeCase>[
      _NativeCase(
        name: 'valid location feeds engine',
        current: TripTrackingSessionLifecycleState.awaitingInitialFix,
        event: _locationEvent(),
        localCheckpoint: true,
        expectedStatus: TripNativeInterruptionRecoveryStatus.feedEngine,
        expectedReason: 'native_sample_ready_for_engine',
        canFeedEngine: true,
      ),
      _NativeCase(
        name: 'background restricted prompts user',
        current: TripTrackingSessionLifecycleState.activeTracking,
        event: _statusEvent('backgroundRestricted'),
        localCheckpoint: true,
        expectedStatus: TripNativeInterruptionRecoveryStatus.promptUser,
        expectedReason: 'native_background_restriction_requires_review',
      ),
      _NativeCase(
        name: 'native stopped ignored',
        current: TripTrackingSessionLifecycleState.activeTracking,
        event: _statusEvent('stopped'),
        localCheckpoint: true,
        expectedStatus: TripNativeInterruptionRecoveryStatus.ignoreSafely,
        expectedReason: 'native_stopped_status_ignored',
      ),
      _NativeCase(
        name: 'completed session protected',
        current: TripTrackingSessionLifecycleState.completed,
        event: _locationEvent(),
        localCheckpoint: true,
        expectedStatus: TripNativeInterruptionRecoveryStatus.ignoreSafely,
        expectedReason: 'native_completed_session_ignored',
      ),
      _NativeCase(
        name: 'missing checkpoint blocks recovery',
        current: TripTrackingSessionLifecycleState.signalLost,
        event: _statusEvent('recovering'),
        localCheckpoint: false,
        expectedStatus: TripNativeInterruptionRecoveryStatus.blocked,
        expectedReason: 'native_recovery_missing_local_checkpoint',
      ),
      _NativeCase(
        name: 'permission loss prompts review',
        current: TripTrackingSessionLifecycleState.activeTracking,
        event: _authorizationEvent(TripTrackingAuthorizationState.denied),
        localCheckpoint: true,
        expectedStatus: TripNativeInterruptionRecoveryStatus.ignoreSafely,
        expectedReason: 'native_event_ignored_safely',
      ),
    ];

    for (final entry in cases) {
      final native = TripNativeEventLifecyclePolicy.evaluate(
        currentState: entry.current,
        event: entry.event,
      );
      final decision = TripNativeInterruptionRecoveryPolicy.evaluate(
        nativeDecision: native,
        supervisorDecision: _supervisorDecision(
          lifecycle: native.to,
          nativeTrackingAvailable:
              native.reason !=
              TripNativeEventLifecycleReason.backgroundRestricted,
        ),
        localCheckpointAvailable: entry.localCheckpoint,
      );
      final safe = decision.toSafeDashboardMap();
      final validation =
          TripNativeInterruptionRecoverySummaryValidation.fromSummary(safe);

      expect(decision.status, entry.expectedStatus, reason: entry.name);
      expect(decision.reasonCode, entry.expectedReason, reason: entry.name);
      expect(decision.canFeedEngine, entry.canFeedEngine, reason: entry.name);
      expect(validation.isRenderable, isTrue, reason: entry.name);
      expect(safe['nativeInterruptionCanEndTripAutomatically'], isFalse);
      expect(safe['nativeInterruptionCanDeleteLocalData'], isFalse);
      expect(safe['nativeInterruptionCanConfirmOdometer'], isFalse);
      expect(safe['nativeInterruptionCanCreateOfficialStop'], isFalse);
      expect(safe['completedSessionProtectedFromNativeResume'], isTrue);
      expect(safe['failedTerminalSessionProtectedFromNativeResume'], isTrue);
      expect(safe['nativeStoppedStatusCannotCompleteTrip'], isTrue);
      expect(safe['permissionLossCannotFeedEngine'], isTrue);
      expect(safe['hiveRemainsOperationalSourceOfTruth'], isTrue);
      expect(safe['odometerRemainsOfficialMileageTruth'], isTrue);
      expect(safe['physicalOdometerRequiredForOfficialMileage'], isTrue);
      expect(safe['confirmedOdometerOverridesExternalMileage'], isTrue);
      expect(safe['externalMileageCannotBecomeGlobalTruth'], isTrue);
      expect(safe['gpsDistanceCanOnlyAdviseMileageReview'], isTrue);
      expect(safe['mapMatchingCanOnlyAdviseMileageReview'], isTrue);
      expect(safe['optimizationCannotChangeOfficialMileage'], isTrue);
      expect(safe['mapsRequiredForRecovery'], isFalse);
      expect(safe['mapboxCanForceRecovery'], isFalse);
      expect(safe['rawNativePayloadIncluded'], isFalse);
      expect(safe['tokensIncluded'], isFalse);
    }
  });

  test(
    'native lifecycle matrix blocks remote and sensitive forged summaries',
    () {
      final safe = TripNativeEventLifecyclePolicy.evaluate(
        currentState: TripTrackingSessionLifecycleState.activeTracking,
        event: _statusEvent('recovering'),
      ).toSafeSummary();
      final validation = TripNativeEventLifecycleSummaryValidation.fromSummary({
        ...safe,
        'mapboxEventCanForceLifecycle': true,
        'firestoreEventCanForceLifecycle': true,
        'nativeEventCanForceComplete': true,
        'foregroundServiceLossRequiresRecoveryPath': false,
        'permissionLossCannotFeedEngine': false,
        'activityEventCannotFeedDistanceEngine': false,
        'debug': '35.123456,-80.123456 sk.redacted',
      });

      expect(validation.isRenderable, isFalse);
      expect(
        validation.reasons,
        contains('native_event_can_mutate_trip_truth'),
      );
      expect(validation.reasons, contains('remote_event_can_force_lifecycle'));
      expect(
        validation.reasons,
        contains('interruption_recovery_boundary_missing'),
      );
      expect(validation.reasons, contains('summary_contains_sensitive_text'));
    },
  );
}

const _normalRollup = TripDashboardStatusRollupDecision(
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

const _noRecovery = TripTrackingRecoveryDecision(
  status: TripTrackingRecoveryStatus.noRecoverableTrip,
  safeReason: 'trip_recovery_none',
  canRestore: false,
  requiresUserAction: false,
  estimatedOdometer: null,
  pendingSampleQueued: false,
);

TripLifecycleSupervisorDecision _supervisorDecision({
  required TripTrackingSessionLifecycleState lifecycle,
  required bool nativeTrackingAvailable,
}) {
  return TripLifecycleSupervisorPolicy.evaluate(
    currentLifecycle: lifecycle,
    dashboardRollup: _normalRollup,
    errorRecoveryPlan: TripTrackingErrorRecoveryPlan.forNativeError(
      null,
      failureCount: nativeTrackingAvailable ? 0 : 2,
      activeTripHasLocalCheckpoint: true,
      userCanOpenSettings: true,
    ),
    recoveryDecision: _noRecovery,
    localCheckpointAvailable: true,
    nativeTrackingAvailable: nativeTrackingAvailable,
    backupMirrorReady: false,
  );
}

TripTrackingPlatformEvent _locationEvent() {
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

TripTrackingPlatformEvent _statusEvent(String status) {
  return TripTrackingPlatformEvent.fromMap({
    'schemaVersion': 1,
    'type': 'status',
    'status': status,
    'recordedAt': DateTime.utc(2026, 7, 18, 12).toIso8601String(),
  });
}

TripTrackingPlatformEvent _authorizationEvent(
  TripTrackingAuthorizationState state,
) {
  return TripTrackingPlatformEvent.fromMap({
    'schemaVersion': 1,
    'type': 'authorization',
    'state': state.name,
    'preciseLocation': state != TripTrackingAuthorizationState.denied,
  });
}

class _NativeCase {
  const _NativeCase({
    required this.name,
    required this.current,
    required this.event,
    required this.localCheckpoint,
    required this.expectedStatus,
    required this.expectedReason,
    this.canFeedEngine = false,
  });

  final String name;
  final TripTrackingSessionLifecycleState current;
  final TripTrackingPlatformEvent event;
  final bool localCheckpoint;
  final TripNativeInterruptionRecoveryStatus expectedStatus;
  final String expectedReason;
  final bool canFeedEngine;
}
