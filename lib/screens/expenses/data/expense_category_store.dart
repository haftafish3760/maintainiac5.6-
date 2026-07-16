import '../../../shared/records/maintainiac_record_lifecycle.dart';

class ExpenseCategoryStore {
  ExpenseCategoryStore._(this._drafts);

  static const _module = 'expense_categories';
  final MaintainiacRecordDraftStore _drafts;

  static Future<ExpenseCategoryStore> create() async =>
      ExpenseCategoryStore._(await MaintainiacRecordDraftStore.create());
  ExpenseCategoryStore.memory() : _drafts = MaintainiacRecordDraftStore.memory();

  Future<void> rename({required String id, required String name, DateTime? now}) async {
    final cleanId = id.trim();
    final cleanName = name.trim();
    if (cleanId.isEmpty || cleanName.isEmpty || cleanId.contains(':')) {
      throw ArgumentError('A category needs a stable ID and a name.');
    }
    await _drafts.save(
      module: _module,
      id: cleanId,
      payload: {'id': cleanId, 'displayName': cleanName},
      now: now,
    );
  }

  String displayNameFor(String id, {required String fallback}) {
    final value = _drafts.draftFor(_module, id)?.payload['displayName'];
    return value is String && value.trim().isNotEmpty ? value : fallback;
  }

  Map<String, Object?> backupPayloadFor(String id, {required String fallback}) {
    final cleanId = id.trim();
    if (cleanId.isEmpty || cleanId.contains(':')) {
      throw ArgumentError.value(id, 'id', 'requires a stable category ID');
    }
    return {
      'schema': 'expense_category_backup_v1',
      'categoryId': cleanId,
      'displayName': displayNameFor(cleanId, fallback: fallback),
    };
  }
}
