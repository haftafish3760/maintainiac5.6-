import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_backup_draft_guard.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';

void main() {
  test('accepts a normal guarded backup draft', () {
    final rejection = ExpenseBackupDraftGuard.rejectionFor([
      const MaintainiacFirestoreDocumentDraft(
        path: 'orgs/org-1/expenses/receipt-1',
        data: {'schema': 'expense_receipt_backup_v1'},
      ),
    ]);

    expect(rejection, isNull);
  });

  test('rejects an oversized draft before it can be partially backed up', () {
    final rejection = ExpenseBackupDraftGuard.rejectionFor([
      MaintainiacFirestoreDocumentDraft(
        path: 'orgs/org-1/expenses/large-receipt',
        data: {'schema': 'expense_receipt_backup_v1', 'notes': 'x' * 800000},
      ),
    ]);

    expect(rejection, contains('too large'));
    expect(rejection, contains('safely stored on this device'));
  });
}
