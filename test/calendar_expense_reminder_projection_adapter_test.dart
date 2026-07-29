import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_reminder_store.dart';
import 'package:maintaniac/shared/calendar/calendar_expense_reminder_projection_adapter.dart';
import 'package:maintaniac/shared/calendar/calendar_projection_contract.dart';

void main() {
  test(
    'monthly reminder preserves scheduled occurrence and owner deep link',
    () {
      final reminder = ExpenseReminderRecord(
        id: 'fuel-reminder',
        title: 'Log fuel receipt',
        category: 'Fuel',
        channel: 'All',
        dueAt: DateTime(2026, 1, 31, 8),
        cadence: ExpenseReminderCadence.monthly,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final events = CalendarExpenseReminderProjectionAdapter.eventsForDay(
        [reminder],
        DateTime(2026, 2, 28),
        now: DateTime(2026, 2, 1),
      ).toList();

      expect(events, hasLength(1));
      expect(events.single.timing.timeSource, CalendarTimeSource.scheduled);
      expect(events.single.timing.scheduledAt, DateTime(2026, 2, 28, 8));
      expect(
        events.single.deepLink.target,
        CalendarDeepLinkTarget.reminderDetail,
      );
    },
  );

  test('quarterly reminder preserves its source cadence and review state', () {
    final reminder = ExpenseReminderRecord(
      id: 'insurance-reminder',
      title: 'Review commercial insurance',
      category: 'Insurance',
      channel: 'In-app',
      dueAt: DateTime(2026, 1, 31, 8),
      cadence: ExpenseReminderCadence.quarterly,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
    final events = CalendarExpenseReminderProjectionAdapter.eventsForDay(
      [reminder],
      DateTime(2026, 4, 30),
      now: DateTime(2026, 5, 1),
    ).toList();

    expect(events, hasLength(1));
    expect(events.single.timing.scheduledAt, DateTime(2026, 4, 30, 8));
    expect(events.single.state, CalendarProjectionState.needsReview);
    expect(events.single.evidence.explanation, 'Delivery preference: In-app.');
  });
}
