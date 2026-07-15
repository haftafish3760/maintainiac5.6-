import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_backup_service.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_reminder_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_work_profile_store.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_upload_queue.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/expense_backup_schedule.dart';
import 'package:maintaniac/shared/state/expense_settings_store.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'expense_cloud_backup_service_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) await hiveDirectory.delete(recursive: true);
  });

  test(
    'requires an explicit organization, signed-in user, and device',
    () async {
      final service = await _service();

      final result = await service.backupLocalSnapshot();

      expect(result.queuedCount, 0);
      expect(result.reason, contains('Sign in'));
    },
  );

  test('backs up only current local receipts and member settings', () async {
    final sink = _RecordingSink();
    final service = await _service(
      sink: sink,
      organizationId: 'org-1',
      uid: 'user-1',
      deviceId: 'device-1',
    );
    await service.ledger.saveReceipt(
      ExpenseReceiptRecord(
        id: 'receipt-1',
        receiptDate: DateTime.utc(2026, 7, 15),
        merchantName: 'Local Hardware',
        enteredTotal: 19.95,
        lines: const [],
      ),
    );
    await service.reminders.save(
      ExpenseReminderRecord(
        id: '',
        title: 'Renew insurance',
        category: 'Insurance',
        channel: 'In-app',
        dueAt: DateTime.utc(2026, 8, 1),
        cadence: ExpenseReminderCadence.yearly,
        createdAt: DateTime.utc(2026, 7, 15),
        updatedAt: DateTime.utc(2026, 7, 15),
      ),
    );

    final result = await service.backupLocalSnapshot(
      nowUtc: DateTime.utc(2026, 7, 15, 12),
    );

    expect(result.completed, isTrue);
    expect(sink.documents, hasLength(5));
    expect(sink.documents.keys, contains('orgs/org-1/expenses/receipt-1'));
    expect(
      sink.documents.keys,
      contains('orgs/org-1/settings/expenses_user-1'),
    );
    expect(
      sink.documents.keys.any(
        (path) => path.startsWith('orgs/org-1/settings/expense_reminder_'),
      ),
      isTrue,
    );
    expect(
      sink.documents.keys,
      contains('orgs/org-1/settings/expense_work_profiles_user-1'),
    );
    expect(
      sink.documents.keys,
      contains('orgs/org-1/settings/expense_vehicles_user-1'),
    );
    expect(service.settings.lastBackupAttemptAt, DateTime.utc(2026, 7, 15, 12));
    expect(
      service.settings.lastSuccessfulBackupAt,
      DateTime.utc(2026, 7, 15, 12),
    );
    expect(service.settings.backupRetryPending, isFalse);
    expect(sink.documents.values.join(), isNot(contains('rawOcrText')));
  });

  test(
    'does not upload a receipt absent from the durable local ledger',
    () async {
      final sink = _RecordingSink();
      final service = await _service(
        sink: sink,
        organizationId: 'org-1',
        uid: 'user-1',
        deviceId: 'device-1',
      );

      final result = await service.backupReceipt('missing-receipt');

      expect(result.queuedCount, 0);
      expect(sink.documents, isEmpty);
    },
  );

  test(
    'refuses an oversized receipt backup without truncating local lines',
    () async {
      final sink = _RecordingSink();
      final service = await _service(
        sink: sink,
        organizationId: 'org-1',
        uid: 'user-1',
        deviceId: 'device-1',
      );
      final lines = List.generate(
        3000,
        (index) => ExpenseReceiptLineRecord(
          id: 'large-line-$index',
          description: 'x' * 240,
          category: 'Materials',
          use: ExpenseLineUse.business,
          quantity: 1,
          unitsPerPackage: 1,
          unit: 'each',
          subtotal: 1,
        ),
      );
      final saved = await service.ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'oversized-receipt',
          receiptDate: DateTime.utc(2026, 7, 15),
          lines: lines,
        ),
      );

      final result = await service.backupReceipt(saved.id);

      expect(result.completed, isFalse);
      expect(result.status, MaintainiacFirestoreUploadStatus.failed);
      expect(result.reason, contains('too large'));
      expect(sink.documents, isEmpty);
      expect(service.ledger.receiptById(saved.id)?.lines, hasLength(3000));
    },
  );

  test('queues a deleted local receipt as a durable cloud tombstone', () async {
    final sink = _RecordingSink();
    final service = await _service(
      sink: sink,
      organizationId: 'org-1',
      uid: 'user-1',
      deviceId: 'device-1',
    );
    final saved = await service.ledger.saveReceipt(
      ExpenseReceiptRecord(
        id: 'receipt-deleted',
        receiptDate: DateTime.utc(2026, 7, 15),
        lines: const [],
      ),
    );
    await service.ledger.deleteReceipt(saved.id);

    final result = await service.backupReceipt(
      saved.id,
      nowUtc: DateTime.utc(2026, 7, 15, 12),
    );
    final document = sink.documents['orgs/org-1/expenses/receipt-deleted']!;

    expect(result.completed, isTrue);
    expect(document['recordState'], 'deleted');
    expect(document['localRevision'], 2);
    expect(document['syncStatus'], 'pending_delete');
    expect(document['deletedAt'], isNotNull);
    expect(service.settings.lastBackupAttemptAt, DateTime.utc(2026, 7, 15, 12));
    expect(
      service.settings.lastSuccessfulBackupAt,
      DateTime.utc(2026, 7, 15, 12),
    );
  });

  test('includes deleted reminder tombstones in an authorized backup', () async {
    final sink = _RecordingSink();
    final reminders = ExpenseReminderController.memory();
    final reminder = await reminders.save(
      ExpenseReminderRecord(
        id: 'reminder-tombstone',
        title: 'Renew registration',
        category: 'Registration',
        channel: 'In-app',
        dueAt: DateTime.utc(2026, 8, 1),
        cadence: ExpenseReminderCadence.yearly,
        createdAt: DateTime.utc(2026, 7, 15),
        updatedAt: DateTime.utc(2026, 7, 15),
      ),
    );
    await reminders.delete(reminder.id);

    final service = await _service(
      sink: sink,
      reminders: reminders,
      organizationId: 'org-1',
      uid: 'user-1',
      deviceId: 'device-1',
    );
    final result = await service.backupLocalSnapshot();
    final document = sink
        .documents['orgs/org-1/settings/expense_reminder_reminder-tombstone']!;

    expect(result.completed, isTrue);
    expect(document['recordState'], 'deleted');
    expect(document['localRevision'], 2);
    expect(document['deletedAt'], isNotNull);
  });

  test('queues one replaceable work-profile directory locally', () async {
    final service = await _service(
      organizationId: 'org-1',
      uid: 'user-1',
      deviceId: 'device-1',
    );

    final queued = await service.queueWorkProfileDirectory(
      nowUtc: DateTime.utc(2026, 7, 15, 12),
    );

    expect(queued.wasQueued, isTrue);
    expect(
      queued.documentPath,
      'orgs/org-1/settings/expense_work_profiles_user-1',
    );
  });

  test(
    'queues an individual reminder change without a full snapshot',
    () async {
      final reminders = ExpenseReminderController.memory();
      final reminder = await reminders.save(
        ExpenseReminderRecord(
          id: 'reminder-1',
          title: 'Renew insurance',
          category: 'Insurance',
          channel: 'In-app',
          dueAt: DateTime.utc(2026, 8, 1),
          cadence: ExpenseReminderCadence.yearly,
          createdAt: DateTime.utc(2026, 7, 15),
          updatedAt: DateTime.utc(2026, 7, 15),
        ),
      );
      await reminders.delete(reminder.id);
      final service = await _service(
        reminders: reminders,
        organizationId: 'org-1',
        uid: 'user-1',
        deviceId: 'device-1',
      );

      final queued = await service.queueReminder(
        reminder.id,
        nowUtc: DateTime.utc(2026, 7, 15, 12),
      );

      expect(queued.wasQueued, isTrue);
      expect(
        queued.documentPath,
        'orgs/org-1/settings/expense_reminder_reminder-1',
      );
    },
  );

  test('app startup does not automatically flush Expense backups', () async {
    final mainSource = await File('lib/main.dart').readAsString();
    final expenseBackupBlock = mainSource.substring(
      mainSource.indexOf(
        'expenseCloudBackup = FirebaseExpenseCloudBackupMirror',
      ),
      mainSource.indexOf('final incomingReceiptShare'),
    );

    expect(expenseBackupBlock, isNot(contains('syncLocalSnapshot()')));
  });

  test('flushes each requested cloud document path only once', () async {
    final sink = _RecordingSink();
    final service = await _service(
      sink: sink,
      organizationId: 'org-1',
      uid: 'user-1',
      deviceId: 'device-1',
    );
    final saved = await service.ledger.saveReceipt(
      ExpenseReceiptRecord(
        id: 'receipt-one-write',
        receiptDate: DateTime.utc(2026, 7, 15),
        lines: const [],
      ),
    );
    final queued = await service.queueReceipt(saved.id);

    final result = await service.flushPaths([
      queued.documentPath!,
      queued.documentPath!,
      '  ',
    ], queuedCount: 3);

    expect(result.queuedCount, 1);
    expect(result.attemptedCount, 1);
    expect(result.uploadedCount, 1);
    expect(result.completed, isTrue);
    expect(sink.writeCount, 1);
  });

  test('scheduled backup honors time and transport authorization', () async {
    final sink = _RecordingSink();
    final service = await _service(
      sink: sink,
      organizationId: 'org-1',
      uid: 'user-1',
      deviceId: 'device-1',
    );
    await service.settings.setBackupSchedule(
      ExpenseBackupSchedule.normalized(
        timesMinutesAfterMidnight: [8 * 60],
        transport: ExpenseBackupTransport.wifiOnly,
      ),
    );
    await service.settings.setBackupSyncMode(
      ExpenseBackupSyncMode.scheduled,
      nowUtc: DateTime.utc(2026, 7, 15, 11),
    );

    final cellular = await service.backupScheduledSnapshot(
      network: ExpenseBackupNetworkAvailability.cellular,
      now: DateTime(2026, 7, 15, 9),
    );
    final wifi = await service.backupScheduledSnapshot(
      network: ExpenseBackupNetworkAvailability.wifi,
      now: DateTime(2026, 7, 15, 9),
    );

    expect(
      cellular.status,
      ExpenseScheduledBackupStatus.waitingForApprovedNetwork,
    );
    expect(cellular.didAttempt, isFalse);
    expect(wifi.status, ExpenseScheduledBackupStatus.attempted);
    expect(wifi.backup?.completed, isTrue);
    expect(sink.writeCount, 3);
  });

  test(
    'scheduled backup cannot leave the device without an account identity',
    () async {
      final service = await _service();
      await service.settings.setBackupSchedule(
        ExpenseBackupSchedule.normalized(
          timesMinutesAfterMidnight: [8 * 60],
          transport: ExpenseBackupTransport.wifiOnly,
        ),
      );
      await service.settings.setBackupSyncMode(
        ExpenseBackupSyncMode.scheduled,
        nowUtc: DateTime.utc(2026, 7, 15, 11),
      );

      final result = await service.backupScheduledSnapshot(
        network: ExpenseBackupNetworkAvailability.wifi,
        now: DateTime(2026, 7, 15, 9),
      );

      expect(result.status, ExpenseScheduledBackupStatus.notAuthorized);
      expect(result.didAttempt, isFalse);
      expect(service.settings.lastBackupAttemptAt, isNull);
    },
  );

  test('noop cloud mirror never schedules a transfer', () async {
    final result = await const NoopExpenseCloudBackupMirror()
        .syncScheduledSnapshot(
          network: ExpenseBackupNetworkAvailability.wifi,
          now: DateTime(2026, 7, 15, 9),
        );

    expect(result.status, ExpenseScheduledBackupStatus.notAuthorized);
    expect(result.didAttempt, isFalse);
  });

  test(
    'noop cloud mirror reports that a manual backup needs an identity',
    () async {
      final result = await const NoopExpenseCloudBackupMirror()
          .syncLocalSnapshot();

      expect(result.completed, isFalse);
      expect(result.reason, contains('Sign in'));
    },
  );
}

Future<ExpenseCloudBackupService> _service({
  _RecordingSink? sink,
  ExpenseReminderController? reminders,
  String? organizationId,
  String? uid,
  String? deviceId,
}) async {
  final queue = await MaintainiacFirestoreUploadQueueStore.create();
  return ExpenseCloudBackupService(
    ledger: ExpenseLedgerController.memory(),
    settings: await ExpenseSettingsController.create(),
    reminders: reminders ?? ExpenseReminderController.memory(),
    workProfiles: ExpenseWorkProfileController.memory(),
    appState: AppStateController(),
    queueStore: queue,
    uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
      queue: queue,
      sink: sink ?? _RecordingSink(),
      uploadEnabled: true,
    ),
    organizationId: organizationId,
    authenticatedUid: uid,
    deviceId: deviceId,
  );
}

class _RecordingSink implements MaintainiacFirestoreDocumentSink {
  final documents = <String, Map<String, Object?>>{};
  var writeCount = 0;

  @override
  Future<void> writeDocument({
    required String path,
    required Map<String, Object?> data,
  }) async {
    writeCount++;
    documents[path] = data;
  }
}
