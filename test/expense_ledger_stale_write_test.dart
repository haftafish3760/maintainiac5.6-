import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';

void main() {
  test('rejects a delayed receipt edit instead of losing newer changes', () async {
    final ledger = ExpenseLedgerController.memory();
    final saved = await ledger.saveReceipt(
      ExpenseReceiptRecord(
        id: 'stale-edit',
        receiptDate: DateTime(2026, 7, 15),
        merchantName: 'Original merchant',
        lines: const [],
      ),
    );
    final delayedEdit = saved.copyWith(merchantName: 'Delayed merchant');
    final newerEdit = await ledger.saveReceipt(
      saved.copyWith(merchantName: 'Newest merchant'),
    );

    await expectLater(
      ledger.saveReceipt(delayedEdit),
      throwsA(isA<StateError>()),
    );
    expect(ledger.receiptById(saved.id)?.merchantName, 'Newest merchant');
    expect(ledger.receiptById(saved.id)?.localRevision, newerEdit.localRevision);
  });
}
