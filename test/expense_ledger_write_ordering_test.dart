import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';

void main() {
  test('clear waits for an in-flight receipt save before removing records', () async {
    final storageCheckStarted = Completer<void>();
    final allowStorageCheck = Completer<void>();
    final ledger = ExpenseLedgerController.memory(
      storageCheck: () async {
        storageCheckStarted.complete();
        await allowStorageCheck.future;
        return const AppStorageCheck(
          availableBytes: AppStorageGuard.smallRecordWriteBytes * 2,
          operationBytes: AppStorageGuard.smallRecordWriteBytes,
          requiredBytes: AppStorageGuard.smallRecordWriteBytes,
          purpose: AppStoragePurpose.smallRecordWrite,
        );
      },
    );

    final save = ledger.saveReceipt(
      ExpenseReceiptRecord(
        id: 'write-order',
        receiptDate: DateTime(2026, 7, 15),
        lines: const [],
      ),
    );
    await storageCheckStarted.future;
    final clear = ledger.clear();
    allowStorageCheck.complete();

    await Future.wait([save, clear]);
    expect(ledger.receiptById('write-order'), isNull);
  });
}
