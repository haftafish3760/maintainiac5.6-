import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_heartbeat_watchdog_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

void main() {
  final now = DateTime.utc(2026, 7, 18, 12);

  test('recent heartbeat keeps active tracking healthy', () {
    final decision = evaluate(now, lastHeartbeatUtc: now);

    expect(decision.status, TripTrackingHeartbeatWatchdogStatus.healthy);
    expect(
      decision.action,
      TripTrackingHeartbeatWatchdogAction.continueTracking,
    );
    expect(
      decision.targetLifecycle,
      TripTrackingSessionLifecycleState.activeTracking,
    );
    expect(decision.canBridgeDistanceGap, isFalse);
  });

  test('stale heartbeat marks degraded and retries native tracking', () {
    final decision = evaluate(
      now,
      lastHeartbeatUtc: now.subtract(const Duration(minutes: 4)),
    );

    expect(
      decision.status,
      TripTrackingHeartbeatWatchdogStatus.staleButRecoverable,
    );
    expect(decision.action, TripTrackingHeartbeatWatchdogAction.markDegraded);
    expect(
      decision.targetLifecycle,
      TripTrackingSessionLifecycleState.signalDegraded,
    );
    expect(decision.shouldRetryNativeTracking, isTrue);
    expect(decision.requiresUserReview, isFalse);
  });

  test('long heartbeat gap interrupts and requires recovery review', () {
    final decision = evaluate(
      now,
      lastHeartbeatUtc: now.subtract(const Duration(minutes: 12)),
    );
    final safe = decision.toSafeSummary();

    expect(
      decision.status,
      TripTrackingHeartbeatWatchdogStatus.interruptedNeedsRecovery,
    );
    expect(
      decision.targetLifecycle,
      TripTrackingSessionLifecycleState.signalLost,
    );
    expect(decision.requiresUserReview, isTrue);
    expect(safe['heartbeatGapCanCreateMileage'], isFalse);
    expect(safe['heartbeatGapCanReplayPendingSample'], isFalse);
    expect(safe['heartbeatGapRequiresLifecycleSupervisor'], isTrue);
    expect(safe['heartbeatGapRequiresLocalCheckpoint'], isTrue);
    expect(safe['localCheckpointPreservedUntilReview'], isTrue);
  });

  test('paused trips are preserved instead of restarted by heartbeat', () {
    final decision = TripTrackingHeartbeatWatchdogPolicy.evaluate(
      currentLifecycle: TripTrackingSessionLifecycleState.pausedByUser,
      lastHeartbeatUtc: now.subtract(const Duration(minutes: 20)),
      nowUtc: now,
    );
    final safe = decision.toSafeSummary();

    expect(decision.status, TripTrackingHeartbeatWatchdogStatus.pausedNoop);
    expect(decision.action, TripTrackingHeartbeatWatchdogAction.preservePaused);
    expect(
      decision.targetLifecycle,
      TripTrackingSessionLifecycleState.pausedByUser,
    );
    expect(decision.shouldRetryNativeTracking, isFalse);
    expect(safe['heartbeatRespectsPausedTrip'], isTrue);
  });

  test('missing heartbeat is no-op when native tracking is not expected', () {
    final decision = TripTrackingHeartbeatWatchdogPolicy.evaluate(
      currentLifecycle: TripTrackingSessionLifecycleState.activeTracking,
      lastHeartbeatUtc: null,
      nowUtc: now,
      nativeTrackingExpected: false,
    );
    final safe = decision.toSafeSummary();

    expect(decision.status, TripTrackingHeartbeatWatchdogStatus.healthy);
    expect(
      decision.action,
      TripTrackingHeartbeatWatchdogAction.continueTracking,
    );
    expect(decision.reasonCode, 'native_tracking_not_expected');
    expect(decision.shouldRetryNativeTracking, isFalse);
    expect(decision.requiresUserReview, isFalse);
    expect(safe['heartbeatGapCanCreateMileage'], isFalse);
    expect(safe['heartbeatCanPurgeLocalDataAfterBackup'], isFalse);
    expect(
      TripTrackingHeartbeatWatchdogSummaryValidation.fromSummary(
        safe,
      ).isRenderable,
      isTrue,
    );
  });

  test('terminal sessions cannot be resumed by stale heartbeat recovery', () {
    for (final state in [
      TripTrackingSessionLifecycleState.completed,
      TripTrackingSessionLifecycleState.completionPending,
      TripTrackingSessionLifecycleState.failedUnrecoverable,
      TripTrackingSessionLifecycleState.idle,
    ]) {
      final decision = TripTrackingHeartbeatWatchdogPolicy.evaluate(
        currentLifecycle: state,
        lastHeartbeatUtc: now.subtract(const Duration(minutes: 20)),
        nowUtc: now,
      );

      expect(
        decision.status,
        TripTrackingHeartbeatWatchdogStatus.terminalProtected,
        reason: state.name,
      );
      expect(decision.targetLifecycle, state);
      expect(decision.shouldRetryNativeTracking, isFalse);
      expect(
        decision.toSafeSummary()['heartbeatCannotResumeTerminalTrip'],
        isTrue,
      );
    }
  });

  test(
    'invalid clocks fail closed without changing mileage or checkpoints',
    () {
      final missing = evaluate(now, lastHeartbeatUtc: null);
      final future = evaluate(
        now,
        lastHeartbeatUtc: now.add(const Duration(minutes: 1)),
      );
      final malformedThresholds = TripTrackingHeartbeatWatchdogPolicy.evaluate(
        currentLifecycle: TripTrackingSessionLifecycleState.activeTracking,
        lastHeartbeatUtc: now,
        nowUtc: now,
        staleAfter: const Duration(minutes: 5),
        interruptedAfter: const Duration(minutes: 2),
      );

      expect(
        missing.status,
        TripTrackingHeartbeatWatchdogStatus.blockedInvalidClock,
      );
      expect(
        future.status,
        TripTrackingHeartbeatWatchdogStatus.blockedInvalidClock,
      );
      expect(
        malformedThresholds.status,
        TripTrackingHeartbeatWatchdogStatus.blockedInvalidClock,
      );
      expect(future.canBridgeDistanceGap, isFalse);
    },
  );

  test('safe summary protects location, odometer, and remote boundaries', () {
    final safe = evaluate(
      now,
      lastHeartbeatUtc: now.subtract(const Duration(minutes: 12)),
    ).toSafeSummary();

    expect(safe['androidSleepCanDeleteCheckpoint'], isFalse);
    expect(safe['iosBackgroundPauseCanDeleteCheckpoint'], isFalse);
    expect(safe['heartbeatGapCanConfirmOdometer'], isFalse);
    expect(safe['heartbeatGapCanSetGlobalTruth'], isFalse);
    expect(safe['heartbeatGapCanChangeOfficialMileage'], isFalse);
    expect(safe['heartbeatGapCanCreateOfficialStop'], isFalse);
    expect(safe['hiveRemainsOperationalSourceOfTruth'], isTrue);
    expect(safe['firestoreMirrorOnly'], isTrue);
    expect(safe['firestoreCanMarkTripInterrupted'], isFalse);
    expect(safe['mapboxCanFillHeartbeatGap'], isFalse);
    expect(safe['cloudFunctionCanFillHeartbeatGap'], isFalse);
    expect(safe['odometerRemainsOfficialMileageTruth'], isTrue);
    expect(safe['heartbeatCanUploadBackupMirror'], isFalse);
    expect(safe['heartbeatCanPurgeLocalDataAfterBackup'], isFalse);
    expect(safe['rawLocationIncluded'], isFalse);
    expect(safe['preciseTimestampIncluded'], isFalse);
    expect(safe['tokensIncluded'], isFalse);
    expect(
      TripTrackingHeartbeatWatchdogSummaryValidation.fromSummary(
        safe,
      ).isRenderable,
      isTrue,
    );
  });

  test('heartbeat summary validation rejects forged trip truth authority', () {
    final safe = evaluate(
      now,
      lastHeartbeatUtc: now.subtract(const Duration(minutes: 12)),
    ).toSafeSummary();

    expect(
      TripTrackingHeartbeatWatchdogSummaryValidation.fromSummary({
        ...safe,
        'heartbeatGapCanCreateMileage': true,
      }).reasons,
      contains('heartbeat_claims_trip_truth'),
    );
    expect(
      TripTrackingHeartbeatWatchdogSummaryValidation.fromSummary({
        ...safe,
        'androidSleepCanDeleteCheckpoint': true,
      }).reasons,
      contains('heartbeat_can_delete_checkpoint'),
    );
    expect(
      TripTrackingHeartbeatWatchdogSummaryValidation.fromSummary({
        ...safe,
        'firestoreCanMarkTripInterrupted': true,
      }).reasons,
      contains('remote_can_control_heartbeat_gap'),
    );
    expect(
      TripTrackingHeartbeatWatchdogSummaryValidation.fromSummary({
        ...safe,
        'debug': '35.123456,-80.123456 token=sk.secret',
      }).reasons,
      contains('summary_contains_sensitive_heartbeat_material'),
    );
  });

  test('heartbeat summary validation rejects status action mismatch', () {
    final stale = evaluate(
      now,
      lastHeartbeatUtc: now.subtract(const Duration(minutes: 4)),
    ).toSafeSummary();
    final interrupted = evaluate(
      now,
      lastHeartbeatUtc: now.subtract(const Duration(minutes: 12)),
    ).toSafeSummary();

    final forgedStale =
        TripTrackingHeartbeatWatchdogSummaryValidation.fromSummary({
          ...stale,
          'action': TripTrackingHeartbeatWatchdogAction.continueTracking.name,
          'shouldRetryNativeTracking': false,
        });
    final forgedInterrupted =
        TripTrackingHeartbeatWatchdogSummaryValidation.fromSummary({
          ...interrupted,
          'requiresUserReview': false,
          'targetLifecycle':
              TripTrackingSessionLifecycleState.activeTracking.name,
        });

    expect(forgedStale.isRenderable, isFalse);
    expect(forgedInterrupted.isRenderable, isFalse);
    expect(
      forgedStale.reasons,
      contains('heartbeat_status_conflicts_with_action'),
    );
    expect(
      forgedInterrupted.reasons,
      contains('heartbeat_status_conflicts_with_action'),
    );
  });
}

TripTrackingHeartbeatWatchdogDecision evaluate(
  DateTime now, {
  required DateTime? lastHeartbeatUtc,
}) {
  return TripTrackingHeartbeatWatchdogPolicy.evaluate(
    currentLifecycle: TripTrackingSessionLifecycleState.activeTracking,
    lastHeartbeatUtc: lastHeartbeatUtc,
    nowUtc: now,
  );
}
