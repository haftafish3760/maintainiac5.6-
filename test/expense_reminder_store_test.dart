import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_reminder_store.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';

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

  test('reminder deletion is recoverable local record history', () async {
    final store = ExpenseReminderController.memory();
    final saved = await store.save(_reminder('Recover me', DateTime(2026, 7)));

    await store.delete(saved.id);
    expect(store.records, isEmpty);
    expect(store.recordById(saved.id)?.isDeleted, isTrue);

    await store.restore(saved.id);
    expect(store.records.single.id, saved.id);
    expect(store.recordById(saved.id)?.lifecycle?.revision, 3);
  });

  test(
    'does not claim a reminder is saved when device storage is full',
    () async {
      final store = ExpenseReminderController.memory(
        storageCheck: () async => const AppStorageCheck(
          availableBytes: 0,
          operationBytes: AppStorageGuard.smallRecordWriteBytes,
          requiredBytes: AppStorageGuard.smallRecordWriteBytes + 1,
          purpose: AppStoragePurpose.smallRecordWrite,
        ),
      );

      await expectLater(
        () => store.save(_reminder('Blocked storage', DateTime(2026, 7))),
        throwsA(isA<StateError>()),
      );
      expect(store.records, isEmpty);
    },
  );

  test('reminder screen offers immediate restore after removal', () async {
    final source = await File(
      'lib/screens/expenses/reminders/expense_reminder_screen.dart',
    ).readAsString();

    expect(
      source,
      contains("const Text('Reminder removed. It can be restored.')"),
    );
    expect(source, contains('controller.restore(reminder.id)'));
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
