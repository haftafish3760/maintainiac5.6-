import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';

void main() {
  test(
    'does not change receipt lifecycle when storage becomes unavailable',
    () async {
      var hasSpace = true;
      final ledger = ExpenseLedgerController.memory(
        storageCheck: () async => AppStorageCheck(
          availableBytes: hasSpace
              ? AppStorageGuard.smallRecordWriteBytes * 2
              : 0,
          operationBytes: AppStorageGuard.smallRecordWriteBytes,
          requiredBytes: AppStorageGuard.smallRecordWriteBytes,
          purpose: AppStoragePurpose.smallRecordWrite,
        ),
      );
      final saved = await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'lifecycle-storage',
          receiptDate: DateTime(2026, 7, 15),
          lines: const [],
        ),
      );
      hasSpace = false;

      await expectLater(
        ledger.deleteReceipt(saved.id),
        throwsA(isA<StateError>()),
      );
      expect(ledger.receiptById(saved.id)?.isActive, isTrue);

      hasSpace = true;
      final deleted = await ledger.deleteReceipt(saved.id);
      expect(deleted?.isDeleted, isTrue);
      hasSpace = false;

      await expectLater(
        ledger.restoreReceipt(saved.id),
        throwsA(isA<StateError>()),
      );
      expect(ledger.receiptById(saved.id)?.isDeleted, isTrue);
    },
  );

  test('receipt lifecycle timestamps never move backward', () async {
    final ledger = ExpenseLedgerController.memory();
    final futureCreatedAt = DateTime.utc(2099, 1, 1);
    final saved = await ledger.saveReceipt(
      ExpenseReceiptRecord(
        id: 'lifecycle-monotonic',
        receiptDate: DateTime(2026, 7, 15),
        createdAt: futureCreatedAt,
        lines: const [],
      ),
    );

    expect(saved.updatedAt, futureCreatedAt);
    final deleted = await ledger.deleteReceipt(saved.id);
    expect(deleted?.updatedAt, futureCreatedAt);
    expect(deleted?.deletedAt, futureCreatedAt);
  });
}
