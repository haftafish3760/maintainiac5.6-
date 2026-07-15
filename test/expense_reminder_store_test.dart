import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_reminder_store.dart';

void main() {
  test('stores valid reminders and rejects an empty title', () async {
    final reminders = ExpenseReminderController.memory();
    final now = DateTime(2026, 7, 15);
    final saved = await reminders.save(
      ExpenseReminderRecord(
        id: '',
        title: 'Insurance renewal',
        category: 'Insurance',
        workProfileId: 'delivery',
        vehicleId: 'van-1',
        dueAt: now.add(const Duration(days: 8)),
        frequency: ExpenseReminderFrequency.yearly,
        channel: ExpenseReminderChannel.inApp,
        createdAt: now,
        updatedAt: now,
      ),
    );
    expect(saved.id, startsWith('REM-'));
    expect(reminders.upcoming(from: now).single.title, 'Insurance renewal');
    expect(
      reminders.upcomingForScope(
        workProfileId: 'delivery',
        vehicleId: 'van-1',
        from: now,
      ),
      hasLength(1),
    );
    expect(
      reminders.upcomingForScope(
        workProfileId: 'delivery',
        vehicleId: 'car-2',
        from: now,
      ),
      isEmpty,
    );
    await expectLater(
      reminders.save(
        ExpenseReminderRecord(
          id: '', title: ' ', category: 'Fuel', dueAt: now,
          frequency: ExpenseReminderFrequency.once,
          channel: ExpenseReminderChannel.inApp,
          createdAt: now, updatedAt: now,
        ),
      ),
      throwsArgumentError,
    );
  });

  test('recurring reminders advance for the upcoming list without mutating proof', () async {
    final reminders = ExpenseReminderController.memory();
    final now = DateTime(2026, 7, 15);
    await reminders.save(
      ExpenseReminderRecord(
        id: 'REM-monthly', title: 'Registration', category: 'Registration',
        dueAt: DateTime(2026, 6, 1), frequency: ExpenseReminderFrequency.monthly,
        channel: ExpenseReminderChannel.inApp, createdAt: now, updatedAt: now,
      ),
    );
    final upcoming = reminders.upcoming(from: now).single;
    expect(upcoming.dueAt, DateTime(2026, 8, 1));
    expect(reminders.reminders.single.dueAt, DateTime(2026, 6, 1));
  });

  test('monthly reminders preserve an end-of-month due date safely', () async {
    final reminders = ExpenseReminderController.memory();
    final now = DateTime(2026, 2, 1);
    await reminders.save(
      ExpenseReminderRecord(
        id: 'REM-month-end', title: 'Month-end bill', category: 'Utilities',
        dueAt: DateTime(2026, 1, 31), frequency: ExpenseReminderFrequency.monthly,
        channel: ExpenseReminderChannel.inApp, createdAt: now, updatedAt: now,
      ),
    );
    expect(reminders.upcoming(from: now).single.dueAt, DateTime(2026, 2, 28));
  });

  test('one-time reminders stay visible when overdue', () async {
    final reminders = ExpenseReminderController.memory();
    final now = DateTime(2026, 7, 15);
    await reminders.save(
      ExpenseReminderRecord(
        id: 'REM-overdue', title: 'Submit receipt', category: 'Tools',
        dueAt: DateTime(2026, 7, 14), frequency: ExpenseReminderFrequency.once,
        channel: ExpenseReminderChannel.inApp, createdAt: now, updatedAt: now,
      ),
    );
    final overdue = reminders.upcoming(from: now).single;
    expect(overdue.isOverdueOn(now), isTrue);
    expect(overdue.dueLabel(now), 'Overdue');
  });
}
