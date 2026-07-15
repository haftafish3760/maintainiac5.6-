import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/expense_backup_schedule.dart';

void main() {
  test('next backup uses the user-selected local clock time', () {
    final schedule = ExpenseBackupSchedule.normalized(
      timesMinutesAfterMidnight: [17 * 60 + 30, 8 * 60],
      transport: ExpenseBackupTransport.wifiOnly,
    );

    expect(
      schedule.nextRunAtOrAfter(DateTime(2026, 7, 15, 7, 59)),
      DateTime(2026, 7, 15, 8),
    );
    expect(
      schedule.nextRunAtOrAfter(DateTime(2026, 7, 15, 18)),
      DateTime(2026, 7, 16, 8),
    );
  });

  test('an empty schedule never creates a backup time', () {
    final schedule = ExpenseBackupSchedule.normalized(
      timesMinutesAfterMidnight: const [],
      transport: ExpenseBackupTransport.wifiOnly,
    );

    expect(schedule.nextRunAtOrAfter(DateTime(2026, 7, 15)), isNull);
  });

  test(
    'a completed backup is not repeatedly due at the same selected time',
    () {
      final schedule = ExpenseBackupSchedule.normalized(
        timesMinutesAfterMidnight: [8 * 60, 17 * 60 + 30],
        transport: ExpenseBackupTransport.wifiOnly,
      );

      expect(
        schedule.isDueAt(
          DateTime(2026, 7, 15, 9),
          lastAttemptAt: DateTime(2026, 7, 15, 8),
        ),
        isFalse,
      );
      expect(
        schedule.isDueAt(
          DateTime(2026, 7, 15, 18),
          lastAttemptAt: DateTime(2026, 7, 15, 8),
        ),
        isTrue,
      );
    },
  );

  test('first scheduled run starts only after user authorization', () {
    final schedule = ExpenseBackupSchedule.normalized(
      timesMinutesAfterMidnight: [8 * 60],
      transport: ExpenseBackupTransport.wifiOnly,
    );

    expect(schedule.isDueAt(DateTime(2026, 7, 15, 9)), isFalse);
    expect(
      schedule.isDueAt(
        DateTime(2026, 7, 15, 9),
        authorizationBeganAt: DateTime(2026, 7, 15, 7),
      ),
      isTrue,
    );
  });

  test('scheduled backup transport never uses an unapproved connection', () {
    expect(
      ExpenseBackupNetworkAvailability.wifi.permits(
        ExpenseBackupTransport.wifiOnly,
      ),
      isTrue,
    );
    expect(
      ExpenseBackupNetworkAvailability.cellular.permits(
        ExpenseBackupTransport.wifiOnly,
      ),
      isFalse,
    );
    expect(
      ExpenseBackupNetworkAvailability.cellular.permits(
        ExpenseBackupTransport.wifiAndCellular,
      ),
      isTrue,
    );
    expect(
      ExpenseBackupNetworkAvailability.unknown.permits(
        ExpenseBackupTransport.wifiAndCellular,
      ),
      isFalse,
    );
  });
}
