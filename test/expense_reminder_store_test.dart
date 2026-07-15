import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_reminder_store.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'expense_reminder_store_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) await hiveDirectory.delete(recursive: true);
  });

  test('persists and sorts reminders by their due date', () async {
    final store = await ExpenseReminderController.create();
    final later = await store.save(_reminder('Later', DateTime(2026, 8, 1)));
    final earlier = await store.save(
      _reminder('Earlier', DateTime(2026, 7, 1)),
    );

    expect(store.records.map((record) => record.id), [earlier.id, later.id]);
    await store.setActive(earlier, false);
    expect(store.records.first.active, isFalse);
  });

  test(
    'retains the original created date when an existing reminder changes',
    () async {
      final store = ExpenseReminderController.memory();
      final original = await store.save(
        _reminder('Insurance', DateTime(2026, 7)),
      );
      final changed = await store.save(
        original.copyWith(category: 'Vehicle insurance'),
      );

      expect(changed.createdAt, original.createdAt);
      expect(changed.category, 'Vehicle insurance');
    },
  );

  test('advances recurring reminders to the next future occurrence', () {
    final reminder = _reminder('Registration', DateTime(2026, 1, 15));

    final next = reminder.nextOccurrenceAfter(DateTime(2026, 7, 15));

    expect(next, DateTime(2026, 8, 15));
  });
}

ExpenseReminderRecord _reminder(String title, DateTime dueAt) {
  return ExpenseReminderRecord(
    id: '',
    title: title,
    category: 'Fuel',
    channel: 'In-app',
    dueAt: dueAt,
    cadence: ExpenseReminderCadence.monthly,
    createdAt: DateTime(2026, 6, 1),
    updatedAt: DateTime(2026, 6, 1),
  );
}
