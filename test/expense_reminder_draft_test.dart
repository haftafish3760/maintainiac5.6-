import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_reminder_draft.dart';
import 'package:maintaniac/screens/expenses/data/expense_reminder_store.dart';
import 'package:maintaniac/shared/records/maintainiac_record_lifecycle.dart';

void main() {
  test(
    'reminder form draft round-trips through shared draft storage',
    () async {
      final store = MaintainiacRecordDraftStore.memory();
      final draft = ExpenseReminderDraft(
        id: ExpenseReminderDraft.idForEditing('EXP-REM-1'),
        title: 'Renew vehicle tags',
        category: 'Tags/registration',
        channel: 'Push',
        cadence: ExpenseReminderCadence.yearly,
        dueAt: DateTime.utc(2026, 12, 1),
        details: 'Bring renewal notice',
        editingReminderId: 'EXP-REM-1',
      );

      await draft.save(store);
      final restored = ExpenseReminderDraft.load(store, draft.id);

      expect(restored?.title, 'Renew vehicle tags');
      expect(restored?.cadence, ExpenseReminderCadence.yearly);
      expect(restored?.editingReminderId, 'EXP-REM-1');
      expect(store.draftsFor(ExpenseReminderDraft.module), hasLength(1));
    },
  );

  test(
    'reminder form draft clears only after confirmed save path requests it',
    () async {
      final store = MaintainiacRecordDraftStore.memory();
      const id = ExpenseReminderDraft.newReminderId;
      await ExpenseReminderDraft(
        id: id,
        title: 'Save me',
        category: 'Fuel',
        channel: 'In-app',
        cadence: ExpenseReminderCadence.once,
        dueAt: DateTime.utc(2026, 7, 15),
        details: '',
      ).save(store);
      await ExpenseReminderDraft.clear(store, id);

      expect(ExpenseReminderDraft.load(store, id), isNull);
    },
  );
}
