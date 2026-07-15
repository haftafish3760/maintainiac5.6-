import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_deletion_store.dart';

void main() {
  test(
    'keeps a local tombstone until an authenticated backup confirms it',
    () async {
      final deletions = ExpenseReceiptDeletionController.memory();
      await deletions.recordDeletion(
        'EXP-1',
        deletedAt: DateTime.utc(2026, 7, 15, 3),
      );
      expect(deletions.pendingTombstones.single.receiptId, 'EXP-1');
      await deletions.markUploaded('EXP-1');
      expect(deletions.pendingTombstones, isEmpty);
    },
  );
}
