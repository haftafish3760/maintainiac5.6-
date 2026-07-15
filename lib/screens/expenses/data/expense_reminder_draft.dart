import '../../../shared/records/maintainiac_record_lifecycle.dart';
import 'expense_reminder_store.dart';

/// The recoverable, in-progress state of the Expense reminder form.
class ExpenseReminderDraft {
  const ExpenseReminderDraft({
    required this.id,
    required this.title,
    required this.category,
    required this.channel,
    required this.cadence,
    required this.dueAt,
    required this.details,
    this.editingReminderId,
  });

  factory ExpenseReminderDraft.fromPayload(
    String id,
    Map<String, dynamic> payload,
  ) {
    return ExpenseReminderDraft(
      id: id,
      title: payload['title'] as String? ?? '',
      category: payload['category'] as String? ?? 'Fuel',
      channel: payload['channel'] as String? ?? 'In-app',
      cadence: ExpenseReminderCadence.fromName(payload['cadence'] as String?),
      dueAt:
          DateTime.tryParse(payload['dueAt'] as String? ?? '') ??
          DateTime.now(),
      details: payload['details'] as String? ?? '',
      editingReminderId: payload['editingReminderId'] as String?,
    );
  }

  static const module = 'expense_reminder_form';
  static const newReminderId = 'new';

  final String id;
  final String title;
  final String category;
  final String channel;
  final ExpenseReminderCadence cadence;
  final DateTime dueAt;
  final String details;
  final String? editingReminderId;

  static String idForEditing(String reminderId) => 'edit-$reminderId';

  Map<String, dynamic> toPayload() => {
    'title': title,
    'category': category,
    'channel': channel,
    'cadence': cadence.name,
    'dueAt': dueAt.toUtc().toIso8601String(),
    'details': details,
    'editingReminderId': editingReminderId,
  };

  Future<void> save(MaintainiacRecordDraftStore store) {
    return store
        .save(module: module, id: id, payload: toPayload())
        .then((_) {});
  }

  static ExpenseReminderDraft? load(
    MaintainiacRecordDraftStore store,
    String id,
  ) {
    final draft = store.draftFor(module, id);
    return draft == null
        ? null
        : ExpenseReminderDraft.fromPayload(id, draft.payload);
  }

  static Future<void> clear(MaintainiacRecordDraftStore store, String id) {
    return store.remove(module, id);
  }
}
