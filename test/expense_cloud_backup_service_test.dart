import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_backup_service.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_upload_queue.dart';
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

    final result = await service.backupLocalSnapshot(
      nowUtc: DateTime.utc(2026, 7, 15, 12),
    );

    expect(result.completed, isTrue);
    expect(sink.documents, hasLength(2));
    expect(sink.documents.keys, contains('orgs/org-1/expenses/receipt-1'));
    expect(
      sink.documents.keys,
      contains('orgs/org-1/settings/expenses_user-1'),
    );
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
}

Future<ExpenseCloudBackupService> _service({
  _RecordingSink? sink,
  String? organizationId,
  String? uid,
  String? deviceId,
}) async {
  final queue = await MaintainiacFirestoreUploadQueueStore.create();
  return ExpenseCloudBackupService(
    ledger: ExpenseLedgerController.memory(),
    settings: await ExpenseSettingsController.create(),
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

  @override
  Future<void> writeDocument({
    required String path,
    required Map<String, Object?> data,
  }) async {
    documents[path] = data;
  }
}
