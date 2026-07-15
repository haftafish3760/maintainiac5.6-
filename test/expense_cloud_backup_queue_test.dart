import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_backup_queue.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_job_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_reminder_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_work_profile_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_vehicle_profile_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_deletion_store.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_upload_queue.dart';
import 'package:maintaniac/shared/state/expense_settings_store.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'expense_cloud_backup_queue_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test(
    'queues only authenticated expense snapshots and replaces stale work',
    () async {
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final backup = ExpenseCloudBackupQueue(queue: queue);
      final identity = const ExpenseCloudBackupIdentity(
        orgId: 'ORG-1',
        uid: 'USER-1',
        deviceId: 'DEVICE-1',
      );
      final receipt = ExpenseReceiptRecord(
        id: 'EXP-1',
        receiptDate: DateTime.utc(2026, 7, 15),
        lines: const [],
      );

      await backup.queueReceipt(
        identity: identity,
        receipt: receipt,
        nowUtc: DateTime.utc(2026, 7, 15, 1),
      );
      await backup.queueReceipt(
        identity: identity,
        receipt: receipt,
        nowUtc: DateTime.utc(2026, 7, 15, 2),
      );

      expect(queue.pendingRecords, hasLength(1));
      expect(queue.pendingRecords.single.data['rawOcrStored'], isFalse);
      await expectLater(
        backup.queueReceipt(
          identity: const ExpenseCloudBackupIdentity(
            orgId: '',
            uid: 'USER-1',
            deviceId: 'DEVICE-1',
          ),
          receipt: receipt,
        ),
        throwsArgumentError,
      );

      final reminders = ExpenseReminderController.memory();
      await reminders.save(
        ExpenseReminderRecord(
          id: 'REM-1',
          title: 'Registration',
          category: 'Registration',
          dueAt: DateTime.utc(2026, 8, 1),
          frequency: ExpenseReminderFrequency.yearly,
          channel: ExpenseReminderChannel.inApp,
          createdAt: DateTime.utc(2026, 7, 15),
          updatedAt: DateTime.utc(2026, 7, 15),
        ),
      );
      await backup.queueReminders(identity: identity, reminders: reminders);
      final jobs = ExpenseJobController.memory();
      final profiles = ExpenseWorkProfileController.memory();
      final vehicles = ExpenseVehicleProfileController.memory();
      await backup.queueJobs(identity: identity, jobs: jobs);
      await backup.queueWorkProfiles(identity: identity, profiles: profiles);
      await backup.queueVehicleProfiles(identity: identity, profiles: vehicles);
      expect(queue.pendingRecords, hasLength(5));
    },
  );

  test(
    'does not send the queue before authentication and network approval',
    () async {
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final backup = ExpenseCloudBackupQueue(queue: queue);
      final sink = _Sink();
      await queue.enqueue(
        const MaintainiacFirestoreDocumentDraft(
          path: 'parserHealth/expense_sync_test',
          data: {'schema': 'safe'},
        ),
      );

      final result = await backup.sync(
        sink: sink,
        authenticated: false,
        networkAllowed: true,
      );

      expect(result.status, MaintainiacFirestoreUploadStatus.disabled);
      expect(sink.writes, isEmpty);
    },
  );

  test(
    'authenticated local snapshot includes records and profile documents',
    () async {
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final backup = ExpenseCloudBackupQueue(queue: queue);
      final identity = const ExpenseCloudBackupIdentity(
        orgId: 'ORG-1',
        uid: 'USER-1',
        deviceId: 'DEVICE-1',
      );
      final ledger = ExpenseLedgerController.memory();
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-1',
          receiptDate: DateTime.utc(2026, 7, 15),
          lines: const [],
        ),
      );
      final settings = await ExpenseSettingsController.create();
      await backup.queueLocalSnapshot(
        identity: identity,
        ledger: ledger,
        settings: settings,
        reminders: ExpenseReminderController.memory(),
        jobs: ExpenseJobController.memory(),
        workProfiles: ExpenseWorkProfileController.memory(),
        vehicleProfiles: ExpenseVehicleProfileController.memory(),
        deletions: ExpenseReceiptDeletionController.memory(),
        nowUtc: DateTime.utc(2026, 7, 15, 2),
      );
      expect(queue.pendingRecords, hasLength(6));
      expect(
        queue.pendingRecords.map((record) => record.path),
        containsAll([
          'orgs/ORG-1/expenses/EXP-1',
          'orgs/ORG-1/settings/expenses_USER-1',
          'orgs/ORG-1/settings/expense_reminders_USER-1',
          'orgs/ORG-1/settings/expense_jobs_USER-1',
          'orgs/ORG-1/settings/expense_work_profiles_USER-1',
          'orgs/ORG-1/settings/expense_vehicle_profiles_USER-1',
        ]),
      );
    },
  );

  test(
    'receipt deletion queues a tombstone instead of a forbidden delete',
    () async {
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final backup = ExpenseCloudBackupQueue(queue: queue);
      await backup.queueReceiptDeletion(
        identity: const ExpenseCloudBackupIdentity(
          orgId: 'ORG-1',
          uid: 'USER-1',
          deviceId: 'DEVICE-1',
        ),
        deletion: ExpenseReceiptDeletionRecord(
          receiptId: 'EXP-1',
          deletedAt: DateTime.utc(2026, 7, 15, 3),
        ),
      );
      final data = queue.pendingRecords.single.data;
      expect(data['tombstone'], isTrue);
      expect(data['deletedAt'], '2026-07-15T03:00:00.000Z');
    },
  );

  test(
    'snapshot ignores a tombstone while its receipt still exists locally',
    () async {
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final ledger = ExpenseLedgerController.memory();
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-1',
          receiptDate: DateTime.utc(2026, 7, 15),
          lines: const [],
        ),
      );
      final deletions = ExpenseReceiptDeletionController.memory();
      await deletions.recordDeletion('EXP-1');
      await ExpenseCloudBackupQueue(queue: queue).queueLocalSnapshot(
        identity: const ExpenseCloudBackupIdentity(
          orgId: 'ORG-1',
          uid: 'USER-1',
          deviceId: 'DEVICE-1',
        ),
        ledger: ledger,
        settings: await ExpenseSettingsController.create(),
        reminders: ExpenseReminderController.memory(),
        jobs: ExpenseJobController.memory(),
        workProfiles: ExpenseWorkProfileController.memory(),
        vehicleProfiles: ExpenseVehicleProfileController.memory(),
        deletions: deletions,
      );
      final receiptRecord = queue.pendingRecords.singleWhere(
        (record) => record.path.endsWith('EXP-1'),
      );
      expect(receiptRecord.data['tombstone'], isNull);
    },
  );
}

class _Sink implements MaintainiacFirestoreDocumentSink {
  final writes = <String>[];

  @override
  Future<void> writeDocument({
    required String path,
    required Map<String, Object?> data,
  }) async {
    writes.add(path);
  }
}
