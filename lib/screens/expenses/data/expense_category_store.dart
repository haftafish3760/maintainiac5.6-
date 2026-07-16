import '../../../shared/records/maintainiac_durable_record_store.dart';

class ExpenseCategoryStore {
  ExpenseCategoryStore._(this._records);

  static const _module = 'expense_categories';
  final MaintainiacDurableRecordStore _records;

  static Future<ExpenseCategoryStore> create() async =>
      ExpenseCategoryStore._(
        await MaintainiacDurableRecordStore.create('expense_category_settings'),
      );
  ExpenseCategoryStore.memory()
    : _records = MaintainiacDurableRecordStore.memory();

  Future<void> rename({required String id, required String name, DateTime? now}) async {
    final cleanId = id.trim();
    final cleanName = name.trim();
    if (cleanId.isEmpty || cleanName.isEmpty || cleanId.contains(':')) {
      throw ArgumentError('A category needs a stable ID and a name.');
    }
    await _records.save(
      module: _module,
      id: cleanId,
      payload: {'id': cleanId, 'displayName': cleanName},
      now: now,
    );
  }

  String displayNameFor(String id, {required String fallback}) {
    final value = _records.recordFor(_module, id)?.payload['displayName'];
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
