import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/jobs/maintainiac_job_store.dart';
import 'package:maintaniac/shared/jobs/maintainiac_job_schedule_exception.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'maintainiac_job_store_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('persists and archives jobs without deleting their history', () async {
    final controller = await MaintainiacJobController.create(
      storageCheck: _availableStorageCheck,
    );
    final now = DateTime.utc(2026, 7, 22, 12);
    final saved = await controller.save(
      MaintainiacJobRecord(
        id: '',
        name: 'Kitchen repair',
        customerReference: 'Smith residence',
        workProfileId: 'business',
        vehicleIds: const ['truck-1'],
        createdAt: now,
        updatedAt: now,
      ),
    );

    expect(saved.id, startsWith('JOB-'));
    expect(controller.activeJobs.single.id, saved.id);
    expect(controller.backupPayloads().single['name'], 'Kitchen repair');

    await controller.archive(saved.id);

    expect(controller.activeJobs, isEmpty);
    expect(controller.jobs.single.archived, isTrue);
    expect(
      Hive.box<dynamic>(MaintainiacJobController.boxName).containsKey(saved.id),
      isTrue,
    );
  });

  test('copies legacy Expense jobs without removing legacy records', () async {
    final legacy = await Hive.openBox<dynamic>(
      MaintainiacJobController.legacyExpenseBoxName,
    );
    await legacy.put('JOB-legacy', {
      'id': 'JOB-legacy',
      'name': 'Legacy service call',
      'workProfileId': 'business',
      'vehicleId': 'truck-7',
      'customerReference': 'Customer 7',
      'archived': false,
      'createdAt': DateTime.utc(2026, 7, 1).toIso8601String(),
      'updatedAt': DateTime.utc(2026, 7, 2).toIso8601String(),
    });

    final controller = await MaintainiacJobController.create(
      storageCheck: _availableStorageCheck,
    );

    expect(controller.jobs.single.vehicleIds, ['truck-7']);
    expect(
      Hive.box<dynamic>(
        MaintainiacJobController.boxName,
      ).containsKey('JOB-legacy'),
      isTrue,
    );
    expect(legacy.containsKey('JOB-legacy'), isTrue);
  });

  test('keeps legacy jobs readable when storage blocks migration', () async {
    final legacy = await Hive.openBox<dynamic>(
      MaintainiacJobController.legacyExpenseBoxName,
    );
    await legacy.put('JOB-preserved', {
      'id': 'JOB-preserved',
      'name': 'Preserved job',
      'createdAt': DateTime.utc(2026, 7, 1).toIso8601String(),
      'updatedAt': DateTime.utc(2026, 7, 1).toIso8601String(),
    });

    final controller = await MaintainiacJobController.create(
      storageCheck: _fullStorageCheck,
    );

    expect(controller.jobs.single.id, 'JOB-preserved');
    expect(
      Hive.box<dynamic>(
        MaintainiacJobController.boxName,
      ).containsKey('JOB-preserved'),
      isFalse,
    );
    await expectLater(
      controller.save(controller.jobs.single.copyWith(name: 'Changed')),
      throwsA(isA<StateError>()),
    );
    expect(controller.jobs.single.name, 'Preserved job');
  });

  test('serializes concurrent job writes', () async {
    final controller = await MaintainiacJobController.create(
      storageCheck: _availableStorageCheck,
    );
    final now = DateTime.utc(2026, 7, 22);

    await Future.wait([
      controller.save(
        MaintainiacJobRecord(
          id: 'JOB-1',
          name: 'First job',
          createdAt: now,
          updatedAt: now,
        ),
      ),
      controller.save(
        MaintainiacJobRecord(
          id: 'JOB-2',
          name: 'Second job',
          createdAt: now,
          updatedAt: now,
        ),
      ),
    ]);

    expect(
      controller.jobs.map((job) => job.id),
      containsAll(['JOB-1', 'JOB-2']),
    );
  });

  test(
    'round-trips client, schedule, recurrence, and reminder preferences',
    () async {
      final controller = MaintainiacJobController.memory();
      final start = DateTime(2026, 7, 27, 8, 30);
      final saved = await controller.save(
        MaintainiacJobRecord(
          id: 'JOB-scheduled',
          name: 'Service call',
          customerReference: 'Jordan Smith',
          customerPhone: '555-0100',
          customerEmail: 'jordan@example.com',
          address: '12 Main Street',
          notes: 'Call before arrival.',
          scheduledStart: start,
          scheduledEnd: start.add(const Duration(hours: 2)),
          repeatRule: 'weekly',
          inAppReminder: true,
          pushReminder: true,
          soundReminder: true,
          reminderLeadMinutes: 30,
          createdAt: start,
          updatedAt: start,
        ),
      );

      final restored = MaintainiacJobRecord.fromMap(saved.toMap());
      expect(restored.customerReference, 'Jordan Smith');
      expect(restored.customerPhone, '555-0100');
      expect(restored.customerEmail, 'jordan@example.com');
      expect(restored.address, '12 Main Street');
      expect(restored.notes, 'Call before arrival.');
      expect(restored.scheduledStart, start);
      expect(restored.repeatRule, 'weekly');
      expect(restored.inAppReminder, isTrue);
      expect(restored.pushReminder, isTrue);
      expect(restored.soundReminder, isTrue);
      expect(restored.reminderLeadMinutes, 30);
    },
  );

  test('round-trips bounded selected-weekday schedules', () async {
    final controller = MaintainiacJobController.memory();
    final start = DateTime(2026, 7, 27, 8, 30);
    final saved = await controller.save(
      MaintainiacJobRecord(
        id: 'JOB-weekdays',
        name: 'Route service',
        scheduledStart: start,
        repeatRule: 'selectedWeekdays',
        repeatWeekdays: const [DateTime.wednesday, DateTime.monday],
        repeatUntil: DateTime(2026, 8, 31),
        createdAt: start,
        updatedAt: start,
      ),
    );

    final restored = MaintainiacJobRecord.fromMap(saved.toMap());
    expect(restored.repeatWeekdays, [DateTime.monday, DateTime.wednesday]);
    expect(restored.repeatUntil, DateTime(2026, 8, 31));
  });

  test('allows an audible job reminder without push delivery', () async {
    final controller = MaintainiacJobController.memory();
    addTearDown(controller.dispose);
    final now = DateTime(2026, 7, 29, 8);

    await controller.save(
      MaintainiacJobRecord(
        id: 'JOB-audio-only',
        name: 'Audio-only reminder visit',
        scheduledStart: now,
        soundReminder: true,
        reminderLeadMinutes: 30,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final saved = controller.jobs.singleWhere(
      (candidate) => candidate.id == 'JOB-audio-only',
    );
    expect(saved.soundReminder, isTrue);
    expect(saved.pushReminder, isFalse);
  });

  test(
    'round-trips source-owned skipped and rescheduled occurrences',
    () async {
      final controller = MaintainiacJobController.memory();
      final start = DateTime(2026, 7, 27, 8);
      final saved = await controller.save(
        MaintainiacJobRecord(
          id: 'JOB-exceptions',
          name: 'Recurring service',
          scheduledStart: start,
          scheduledEnd: start.add(const Duration(hours: 2)),
          repeatRule: 'weekly',
          scheduleExceptions: [
            MaintainiacJobScheduleException(
              day: DateTime(2026, 8, 3),
              startOverride: DateTime(2026, 8, 3, 9),
              endOverride: DateTime(2026, 8, 3, 11),
            ),
            MaintainiacJobScheduleException(
              day: DateTime(2026, 8, 10),
              cancelled: true,
            ),
          ],
          createdAt: start,
          updatedAt: start,
        ),
      );

      final restored = MaintainiacJobRecord.fromMap(saved.toMap());
      expect(restored.scheduleExceptions, hasLength(2));
      expect(
        restored.scheduleExceptions.first.startOverride,
        DateTime(2026, 8, 3, 9),
      );
      expect(restored.scheduleExceptions.last.cancelled, isTrue);
    },
  );

  test('rejects unsafe references and invalid schedule windows', () async {
    final controller = MaintainiacJobController.memory();
    final now = DateTime.utc(2026, 7, 22);

    await expectLater(
      controller.save(
        MaintainiacJobRecord(
          id: 'JOB/unsafe',
          name: 'Unsafe job',
          createdAt: now,
          updatedAt: now,
        ),
      ),
      throwsArgumentError,
    );
    await expectLater(
      controller.save(
        MaintainiacJobRecord(
          id: 'JOB-off-schedule',
          name: 'Off schedule exception',
          scheduledStart: DateTime(2026, 7, 27, 8),
          repeatRule: 'weekly',
          scheduleExceptions: [
            MaintainiacJobScheduleException(day: DateTime(2026, 7, 28)),
          ],
          createdAt: now,
          updatedAt: now,
        ),
      ),
      throwsArgumentError,
    );
    await expectLater(
      controller.save(
        MaintainiacJobRecord(
          id: 'JOB-duplicate-exception',
          name: 'Duplicate exception',
          scheduledStart: now,
          scheduleExceptions: [
            MaintainiacJobScheduleException(day: now),
            MaintainiacJobScheduleException(day: now),
          ],
          createdAt: now,
          updatedAt: now,
        ),
      ),
      throwsArgumentError,
    );
    await expectLater(
      controller.save(
        MaintainiacJobRecord(
          id: 'JOB-no-days',
          name: 'No weekdays',
          scheduledStart: now,
          repeatRule: 'selectedWeekdays',
          createdAt: now,
          updatedAt: now,
        ),
      ),
      throwsArgumentError,
    );
    await expectLater(
      controller.save(
        MaintainiacJobRecord(
          id: 'JOB-safe',
          name: 'Bad schedule',
          scheduledStart: now.add(const Duration(hours: 2)),
          scheduledEnd: now,
          createdAt: now,
          updatedAt: now,
        ),
      ),
      throwsArgumentError,
    );
  });
}

Future<AppStorageCheck> _availableStorageCheck() async => const AppStorageCheck(
  availableBytes: 1024 * 1024 * 1024,
  operationBytes: AppStorageGuard.smallRecordWriteBytes,
  requiredBytes:
      AppStorageGuard.minimumDeviceReserveBytes +
      AppStorageGuard.smallRecordWriteBytes,
  purpose: AppStoragePurpose.smallRecordWrite,
);

Future<AppStorageCheck> _fullStorageCheck() async => const AppStorageCheck(
  availableBytes: 0,
  operationBytes: AppStorageGuard.smallRecordWriteBytes,
  requiredBytes:
      AppStorageGuard.minimumDeviceReserveBytes +
      AppStorageGuard.smallRecordWriteBytes,
  purpose: AppStoragePurpose.smallRecordWrite,
);
