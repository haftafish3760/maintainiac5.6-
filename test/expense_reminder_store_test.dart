import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_reminder_store.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';

void main() {
  test('rejects corrupt persisted reminder lifecycle metadata', () {
    expect(
      () => ExpenseReminderRecord.fromMap({
        'id': 'corrupt-reminder',
        'title': 'Broken reminder',
        'dueAt': '2026-07-15T12:00:00.000Z',
        'createdAt': '2026-07-15T12:00:00.000Z',
        'updatedAt': '2026-07-15T12:00:00.000Z',
        'lifecycle': {
          'createdAt': '2026-07-15T12:00:00.000Z',
          'updatedAt': '2026-07-15T12:00:00.000Z',
          'revision': 2,
          'state': 'deleted',
        },
      }),
      throwsFormatException,
    );
  });

  test('queued reminder save and delete preserve lifecycle order', () async {
    final reminders = ExpenseReminderController.memory();
    final record = ExpenseReminderRecord(
      id: 'queued-reminder',
      title: 'Queued reminder',
      category: 'Tools',
      channel: 'In-app',
      dueAt: DateTime.utc(2026, 7, 15),
      cadence: ExpenseReminderCadence.once,
      createdAt: DateTime.utc(2026, 7, 15),
      updatedAt: DateTime.utc(2026, 7, 15),
    );

    await Future.wait([reminders.save(record), reminders.delete(record.id)]);

    expect(reminders.recordById(record.id)?.isDeleted, isTrue);
  });

  test('an older reminder edit cannot overwrite a newer local edit', () async {
    final reminders = ExpenseReminderController.memory();
    final original = await reminders.save(
      _reminder('Insurance', DateTime.utc(2026, 7, 15)),
    );
    final newer = await reminders.save(
      original.copyWith(category: 'Vehicle insurance'),
    );

    await expectLater(
      () => reminders.save(original.copyWith(category: 'Old category')),
      throwsA(isA<StateError>()),
    );

    expect(reminders.recordById(original.id)?.category, newer.category);
  });
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

  test('keeps recurring reminders on their intended month-end day', () {
    final monthly = _reminder('Month end', DateTime(2026, 1, 31));
    final leapDay = _reminder(
      'Leap day',
      DateTime(2024, 2, 29),
    ).copyWith(cadence: ExpenseReminderCadence.yearly);

    expect(
      monthly.nextOccurrenceAfter(DateTime(2026, 2, 1)),
      DateTime(2026, 2, 28),
    );
    expect(
      monthly.nextOccurrenceAfter(DateTime(2026, 2, 28)),
      DateTime(2026, 3, 31),
    );
    expect(
      leapDay.nextOccurrenceAfter(DateTime(2025, 1, 1)),
      DateTime(2025, 2, 28),
    );
    expect(
      leapDay.nextOccurrenceAfter(DateTime(2027, 2, 28)),
      DateTime(2028, 2, 29),
    );
  });

  test(
    'finds a far-future recurring reminder without replaying every month',
    () {
      final monthly = _reminder('Old monthly', DateTime(2000, 1, 31));
      final quarterly = _reminder(
        'Old quarterly',
        DateTime(2000, 1, 31),
      ).copyWith(cadence: ExpenseReminderCadence.quarterly);

      expect(
        monthly.nextOccurrenceAfter(DateTime(2026, 7, 31)),
        DateTime(2026, 8, 31),
      );
      expect(
        quarterly.nextOccurrenceAfter(DateTime(2026, 7, 31)),
        DateTime(2026, 10, 31),
      );
    },
  );

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
    expect(source, contains('_restoreReminder(controller, reminder.id)'));
  });

  test(
    'does not delete a reminder when device storage becomes unavailable',
    () async {
      var storageAvailable = true;
      final store = ExpenseReminderController.memory(
        storageCheck: () async => AppStorageCheck(
          availableBytes: storageAvailable
              ? AppStorageGuard.smallRecordWriteBytes * 2
              : 0,
          operationBytes: AppStorageGuard.smallRecordWriteBytes,
          requiredBytes: AppStorageGuard.smallRecordWriteBytes,
          purpose: AppStoragePurpose.smallRecordWrite,
        ),
      );
      final saved = await store.save(_reminder('Existing', DateTime(2026, 7)));
      storageAvailable = false;

      await expectLater(
        () => store.delete(saved.id),
        throwsA(isA<StateError>()),
      );

      expect(store.recordById(saved.id)?.isDeleted, isFalse);
    },
  );
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
