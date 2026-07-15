import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_backup_queue.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_upload_queue.dart';

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
