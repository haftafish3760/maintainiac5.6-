import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/data/active_workday_elapsed_clock.dart';
import 'package:maintaniac/screens/dashboard/data/active_workday_store.dart';

void main() {
  test('wall-clock rollback cannot move an active workday timer backward', () {
    var monotonic = Duration.zero;
    final clock = ActiveWorkdayElapsedClock(monotonicNow: () => monotonic);
    final session = _session();

    expect(
      clock.elapsedFor(session, wallNow: DateTime.utc(2026, 7, 24, 9)),
      const Duration(hours: 1),
    );

    monotonic = const Duration(minutes: 5);
    expect(
      clock.elapsedFor(session, wallNow: DateTime.utc(2026, 7, 24, 8, 30)),
      const Duration(hours: 1, minutes: 5),
    );
  });

  test('pause and resume retain one monotonic elapsed boundary', () {
    var monotonic = Duration.zero;
    final clock = ActiveWorkdayElapsedClock(monotonicNow: () => monotonic);
    final active = _session();

    expect(
      clock.elapsedFor(active, wallNow: DateTime.utc(2026, 7, 24, 9)),
      const Duration(hours: 1),
    );

    monotonic = const Duration(minutes: 10);
    final paused = active.copyWith(status: ActiveWorkdayStatus.paused);
    expect(
      clock.elapsedFor(paused, wallNow: DateTime.utc(2026, 7, 24, 9, 10)),
      const Duration(hours: 1, minutes: 10),
    );

    monotonic = const Duration(minutes: 20);
    expect(
      clock.elapsedFor(paused, wallNow: DateTime.utc(2026, 7, 24, 9, 20)),
      const Duration(hours: 1, minutes: 10),
    );

    final resumed = paused.copyWith(status: ActiveWorkdayStatus.active);
    expect(
      clock.elapsedFor(resumed, wallNow: DateTime.utc(2026, 7, 24, 9, 20)),
      const Duration(hours: 1, minutes: 10),
    );

    monotonic = const Duration(minutes: 25);
    expect(
      clock.elapsedFor(resumed, wallNow: DateTime.utc(2026, 7, 24, 7)),
      const Duration(hours: 1, minutes: 15),
    );
  });

  test('a recovered workday establishes its baseline from durable time', () {
    var monotonic = const Duration(hours: 4);
    final clock = ActiveWorkdayElapsedClock(monotonicNow: () => monotonic);
    final recovered = _session(id: 'recovered');

    expect(
      clock.elapsedFor(recovered, wallNow: DateTime.utc(2026, 7, 24, 10)),
      const Duration(hours: 2),
    );

    monotonic += const Duration(minutes: 1);
    expect(
      clock.elapsedFor(recovered, wallNow: DateTime.utc(2026, 7, 25)),
      const Duration(hours: 2, minutes: 1),
    );
  });
}

ActiveWorkdaySessionRecord _session({String id = 'workday_1'}) =>
    ActiveWorkdaySessionRecord(
      id: id,
      vehicleId: 'vehicle_1',
      vehicleLabel: 'Work truck',
      workProfileId: 'profile_1',
      startedAt: DateTime.utc(2026, 7, 24, 8),
      startOdometer: 1000,
      status: ActiveWorkdayStatus.active,
      events: const [],
    );
