import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_restore_codec.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_restore_receipt_coordinator.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_restore_session.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_restore_storage_plan.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('restore-runner-');
    Hive.init(hiveDirectory.path);
  });

  setUp(() async {
    if (Hive.isBoxOpen(ExpenseCloudRestoreSessionStore.boxName)) {
      await Hive.box<dynamic>(ExpenseCloudRestoreSessionStore.boxName).close();
    }
    await Hive.deleteBoxFromDisk(ExpenseCloudRestoreSessionStore.boxName);
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test(
    'checkpoints each created receipt and completes a safe restore',
    () async {
      final sessions = await ExpenseCloudRestoreSessionStore.create();
      await _prepare(sessions, totalRecords: 1);
      await sessions.updateProgress(
        id: 'restore-1',
        completedDownloadBytes: 1,
        completedRecords: 0,
      );
      final ledger = ExpenseLedgerController.memory();
      final result = await ExpenseCloudRestoreReceiptCoordinator(
        ledger: ledger,
        sessions: sessions,
      ).restoreMissing(sessionId: 'restore-1', cloudRecords: [_cloudReceipt()]);

      expect(result.createdCount, 1);
      expect(result.needsReview, isFalse);
      expect(ledger.receiptById('cloud-receipt'), isNotNull);
      expect(
        sessions.sessionById('restore-1')?.state,
        ExpenseCloudRestoreSessionState.completed,
      );
    },
  );

  test('pauses instead of overwriting a conflicting local receipt', () async {
    final sessions = await ExpenseCloudRestoreSessionStore.create();
    await _prepare(sessions, totalRecords: 1);
    final ledger = ExpenseLedgerController.memory();
    await ledger.saveReceipt(_cloudReceipt().receipt);

    final result = await ExpenseCloudRestoreReceiptCoordinator(
      ledger: ledger,
      sessions: sessions,
    ).restoreMissing(sessionId: 'restore-1', cloudRecords: [_cloudReceipt()]);

    expect(result.createdCount, 0);
    expect(result.needsReview, isTrue);
    expect(
      sessions.sessionById('restore-1')?.state,
      ExpenseCloudRestoreSessionState.paused,
    );
  });
}

Future<void> _prepare(
  ExpenseCloudRestoreSessionStore sessions, {
  required int totalRecords,
}) => sessions.savePrepared(
  id: 'restore-1',
  requestId: 'server-request-1',
  plan: ExpenseCloudRestoreStoragePlan.forMode(
    mode: ExpenseCloudRestoreMode.recordsOnly,
    estimate: const ExpenseCloudRestoreEstimate(
      recordCount: 1,
      proofCount: 0,
      cloudProofCount: 0,
      metadataOnlyProofCount: 0,
      knownProofBytes: 0,
      proofsWithUnknownSize: 0,
    ),
    structuredRecordBytes: 1,
    availableBytes: 100,
  ),
  totalRecords: totalRecords,
);

ExpenseCloudRestoredReceipt _cloudReceipt() => ExpenseCloudRestoredReceipt(
  receipt: ExpenseReceiptRecord(
    id: 'cloud-receipt',
    receiptDate: DateTime.utc(2026, 7, 15),
    createdAt: DateTime.utc(2026, 7, 15),
    updatedAt: DateTime.utc(2026, 7, 15),
    localRevision: 1,
    lines: const [],
  ),
  proofPointers: const [],
);
