import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_active_day_timer_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

void main() {
  final now = DateTime.utc(2026, 7, 18, 12);
  final started = now.subtract(const Duration(hours: 2));

  test('active day timer ticks live from local active session clock', () {
    final decision = TripActiveDayTimerPolicy.evaluate(
      lifecycle: TripTrackingSessionLifecycleState.activeTracking,
      startedAtUtc: started,
      pausedAtUtc: null,
      completedAtUtc: null,
      nowUtc: now,
    );

    expect(decision.status, TripActiveDayTimerStatus.running);
    expect(decision.elapsed, const Duration(hours: 2));
    expect(decision.shouldTickLive, isTrue);
    expect(decision.toSafeDashboardMap()['timerSource'], 'local_session_clock');
  });

  test('paused, awaiting review, and completed timers stop ticking', () {
    final paused = TripActiveDayTimerPolicy.evaluate(
      lifecycle: TripTrackingSessionLifecycleState.pausedByUser,
      startedAtUtc: started,
      pausedAtUtc: started.add(const Duration(minutes: 45)),
      completedAtUtc: null,
      nowUtc: now,
    );
    final review = TripActiveDayTimerPolicy.evaluate(
      lifecycle: TripTrackingSessionLifecycleState.completionPending,
      startedAtUtc: started,
      pausedAtUtc: null,
      completedAtUtc: started.add(const Duration(hours: 1)),
      nowUtc: now,
    );
    final completed = TripActiveDayTimerPolicy.evaluate(
      lifecycle: TripTrackingSessionLifecycleState.completed,
      startedAtUtc: started,
      pausedAtUtc: null,
      completedAtUtc: started.add(const Duration(hours: 1, minutes: 15)),
      nowUtc: now,
    );

    expect(paused.status, TripActiveDayTimerStatus.paused);
    expect(paused.shouldTickLive, isFalse);
    expect(review.status, TripActiveDayTimerStatus.awaitingReview);
    expect(review.requiresUserReview, isTrue);
    expect(completed.status, TripActiveDayTimerStatus.completed);
    expect(completed.elapsed, const Duration(hours: 1, minutes: 15));
  });

  test('invalid clock data fails closed without fabricating elapsed time', () {
    final futureStart = TripActiveDayTimerPolicy.evaluate(
      lifecycle: TripTrackingSessionLifecycleState.activeTracking,
      startedAtUtc: now.add(const Duration(minutes: 1)),
      pausedAtUtc: null,
      completedAtUtc: null,
      nowUtc: now,
    );
    final pauseBeforeStart = TripActiveDayTimerPolicy.evaluate(
      lifecycle: TripTrackingSessionLifecycleState.pausedByUser,
      startedAtUtc: started,
      pausedAtUtc: started.subtract(const Duration(minutes: 1)),
      completedAtUtc: null,
      nowUtc: now,
      previouslyElapsed: const Duration(minutes: 10),
    );

    expect(futureStart.status, TripActiveDayTimerStatus.invalidClock);
    expect(futureStart.elapsed, Duration.zero);
    expect(pauseBeforeStart.status, TripActiveDayTimerStatus.invalidClock);
    expect(pauseBeforeStart.elapsed, const Duration(minutes: 10));
    expect(pauseBeforeStart.requiresUserReview, isTrue);
  });

  test('interrupted running timer keeps local clock but asks review', () {
    final decision = TripActiveDayTimerPolicy.evaluate(
      lifecycle: TripTrackingSessionLifecycleState.signalLost,
      startedAtUtc: started,
      pausedAtUtc: null,
      completedAtUtc: null,
      nowUtc: now,
    );

    expect(decision.status, TripActiveDayTimerStatus.running);
    expect(decision.shouldTickLive, isTrue);
    expect(decision.requiresUserReview, isTrue);
  });

  test('safe timer summary cannot mutate mileage, stops, maps, or data', () {
    final safe = TripActiveDayTimerPolicy.evaluate(
      lifecycle: TripTrackingSessionLifecycleState.activeTracking,
      startedAtUtc: started,
      pausedAtUtc: null,
      completedAtUtc: null,
      nowUtc: now,
    ).toSafeDashboardMap();

    expect(safe['dashboardTimerCanRunWithoutMaps'], isTrue);
    expect(safe['mapsRequiredForTimer'], isFalse);
    expect(safe['timerCanCreateMileage'], isFalse);
    expect(safe['timerCanConfirmOdometer'], isFalse);
    expect(safe['timerCanSetGlobalTruth'], isFalse);
    expect(safe['timerCanChangeOfficialMileage'], isFalse);
    expect(safe['timerCanCreateOfficialStop'], isFalse);
    expect(safe['timerCanDeleteLocalData'], isFalse);
    expect(safe['remoteTimerCanOverrideLocalSession'], isFalse);
    expect(safe['hiveRemainsOperationalSourceOfTruth'], isTrue);
    expect(safe['odometerRemainsOfficialMileageTruth'], isTrue);
    expect(safe['rawSessionIncluded'], isFalse);
    expect(safe['preciseTimestampIncluded'], isFalse);
    expect(safe['tokensIncluded'], isFalse);
  });
}
