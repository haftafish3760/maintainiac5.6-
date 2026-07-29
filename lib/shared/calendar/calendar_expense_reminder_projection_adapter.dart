// Expense reminder projection. Expense Reminders retain scheduling ownership;
// Calendar only displays occurrences and routes back to that owner.

import '../../screens/expenses/data/expense_reminder_store.dart';
import 'calendar_projection_contract.dart';
import 'calendar_schedule_recurrence_contract.dart';

class CalendarExpenseReminderProjectionAdapter {
  const CalendarExpenseReminderProjectionAdapter._();

  static Iterable<CalendarProjectionEvent> eventsForDay(
    Iterable<ExpenseReminderRecord> reminders,
    DateTime day, {
    DateTime? now,
  }) sync* {
    final referenceNow = now ?? DateTime.now();
    for (final reminder in reminders) {
      if (!reminder.active || reminder.isDeleted) continue;
      final occurrence = _occurrenceOnDay(reminder, day);
      if (occurrence == null) continue;
      yield CalendarProjectionEvent(
        eventId:
            'expense-reminder:${reminder.id}:${occurrence.toIso8601String()}',
        source: CalendarProjectionSource.reminder,
        sourceRecordId: reminder.id,
        timing: CalendarProjectionTiming(
          eventDate: occurrence,
          recordedAt: reminder.updatedAt,
          scheduledAt: occurrence,
          timeSource: CalendarTimeSource.scheduled,
        ),
        title: reminder.title,
        conciseDetail:
            '${reminder.category} expense reminder · ${reminder.cadence.label}',
        state: _dateOnly(occurrence).isBefore(_dateOnly(referenceNow))
            ? CalendarProjectionState.needsReview
            : CalendarProjectionState.proposed,
        sourceRecordStatus: reminder.active ? 'active' : 'inactive',
        revision:
            reminder.lifecycle?.revision ??
            reminder.updatedAt.millisecondsSinceEpoch,
        evidence: CalendarProjectionEvidence(
          summary: reminder.details.trim().isEmpty
              ? null
              : reminder.details.trim(),
          explanation: 'Delivery preference: ${reminder.channel}.',
        ),
        deepLink: CalendarProjectionDeepLink(
          target: CalendarDeepLinkTarget.reminderDetail,
          sourceRecordId: reminder.id,
        ),
      );
    }
  }

  static DateTime? _occurrenceOnDay(
    ExpenseReminderRecord reminder,
    DateTime day,
  ) {
    final occurrences = CalendarScheduleRecurrence.occurrencesForRange(
      sourceRecordId: reminder.id,
      start: reminder.dueAt,
      rule: _ruleFor(reminder.cadence),
      rangeStart: day,
      rangeEnd: day,
    );
    return occurrences.isEmpty ? null : occurrences.single.start;
  }
}

CalendarScheduleRule _ruleFor(ExpenseReminderCadence cadence) =>
    CalendarScheduleRule(
      frequency: switch (cadence) {
        ExpenseReminderCadence.once => CalendarScheduleFrequency.once,
        _ => CalendarScheduleFrequency.monthly,
      },
      interval: switch (cadence) {
        ExpenseReminderCadence.once || ExpenseReminderCadence.monthly => 1,
        ExpenseReminderCadence.quarterly => 3,
        ExpenseReminderCadence.yearly => 12,
      },
    );

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
