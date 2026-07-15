import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_draft_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';

void main() {
  test('an older delayed checkpoint cannot overwrite a newer draft', () async {
    final drafts = ExpenseDraftController.memory();
    final time = DateTime.utc(2026, 7, 15, 12);
    final newest = ExpenseReceiptDraftRecord(
      id: 'draft-order',
      receiptDate: time,
      updatedAt: time.add(const Duration(seconds: 1)),
      merchantName: 'Newest merchant',
    );
    final stale = ExpenseReceiptDraftRecord(
      id: newest.id,
      receiptDate: time,
      updatedAt: time,
      merchantName: 'Stale merchant',
    );

    await Future.wait([drafts.saveDraft(newest), drafts.saveDraft(stale)]);

    expect(drafts.draftById(newest.id)?.merchantName, 'Newest merchant');
  });

  test('an older empty checkpoint cannot delete a newer draft', () async {
    final drafts = ExpenseDraftController.memory();
    final time = DateTime.utc(2026, 7, 15, 12);
    final newest = ExpenseReceiptDraftRecord(
      id: 'draft-order-delete',
      receiptDate: time,
      updatedAt: time.add(const Duration(seconds: 1)),
      merchantName: 'Keep this draft',
    );
    final staleEmpty = ExpenseReceiptDraftRecord(
      id: newest.id,
      receiptDate: time,
      updatedAt: time,
    );

    await drafts.saveDraft(newest);
    await drafts.saveDraft(staleEmpty);

    expect(drafts.draftById(newest.id)?.merchantName, 'Keep this draft');
  });
}
