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
    expect(decision.targetLifecycle, TripTrackingSessionLifecycleState.active);
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
      TripTrackingSessionLifecycleState.degraded,
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
      TripTrackingSessionLifecycleState.interrupted,
    );
    expect(decision.requiresUserReview, isTrue);
    expect(safe['heartbeatGapCanCreateMileage'], isFalse);
    expect(safe['localCheckpointPreservedUntilReview'], isTrue);
  });

  test('paused trips are preserved instead of restarted by heartbeat', () {
    final decision = TripTrackingHeartbeatWatchdogPolicy.evaluate(
      currentLifecycle: TripTrackingSessionLifecycleState.paused,
      lastHeartbeatUtc: now.subtract(const Duration(minutes: 20)),
      nowUtc: now,
    );
    final safe = decision.toSafeSummary();

    expect(decision.status, TripTrackingHeartbeatWatchdogStatus.pausedNoop);
    expect(decision.action, TripTrackingHeartbeatWatchdogAction.preservePaused);
    expect(decision.targetLifecycle, TripTrackingSessionLifecycleState.paused);
    expect(decision.shouldRetryNativeTracking, isFalse);
    expect(safe['heartbeatRespectsPausedTrip'], isTrue);
  });

  test('terminal sessions cannot be resumed by stale heartbeat recovery', () {
    for (final state in [
      TripTrackingSessionLifecycleState.completed,
      TripTrackingSessionLifecycleState.awaitingReview,
      TripTrackingSessionLifecycleState.failedTerminal,
      TripTrackingSessionLifecycleState.disabled,
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
        currentLifecycle: TripTrackingSessionLifecycleState.active,
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
    expect(safe['heartbeatGapCanCreateOfficialStop'], isFalse);
    expect(safe['hiveRemainsOperationalSourceOfTruth'], isTrue);
    expect(safe['firestoreMirrorOnly'], isTrue);
    expect(safe['mapboxCanFillHeartbeatGap'], isFalse);
    expect(safe['odometerRemainsOfficialMileageTruth'], isTrue);
    expect(safe['rawLocationIncluded'], isFalse);
    expect(safe['preciseTimestampIncluded'], isFalse);
    expect(safe['tokensIncluded'], isFalse);
  });
}

TripTrackingHeartbeatWatchdogDecision evaluate(
  DateTime now, {
  required DateTime? lastHeartbeatUtc,
}) {
  return TripTrackingHeartbeatWatchdogPolicy.evaluate(
    currentLifecycle: TripTrackingSessionLifecycleState.active,
    lastHeartbeatUtc: lastHeartbeatUtc,
    nowUtc: now,
  );
}
