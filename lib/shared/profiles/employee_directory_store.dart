import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'employee_directory_models.dart';

class EmployeeDirectoryController extends ChangeNotifier {
  EmployeeDirectoryController._({
    required Box<dynamic>? box,
    required List<EmployeeDirectoryRecord> records,
  }) : _box = box,
       _records = records;

  EmployeeDirectoryController.memory({List<EmployeeDirectoryRecord>? records})
    : _box = null,
      _records = records ?? const [];

  static const boxName = 'employee_directory_v1';
  static const _recordsKey = 'records';

  final Box<dynamic>? _box;
  List<EmployeeDirectoryRecord> _records;

  List<EmployeeDirectoryRecord> get records => List.unmodifiable(_records);

  List<EmployeeDirectoryRecord> get pendingInvites {
    return _records
        .where((record) => record.status == EmployeeInviteStatus.inviteQueued)
        .toList(growable: false);
  }

  static Future<EmployeeDirectoryController> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return EmployeeDirectoryController._(
      box: box,
      records: _recordsFromBox(box.get(_recordsKey)),
    );
  }

  static Future<EmployeeDirectoryController> createOrMemory() async {
    try {
      return await create();
    } catch (_) {
      return EmployeeDirectoryController.memory();
    }
  }

  Future<void> saveRecord(EmployeeDirectoryRecord record) async {
    final next = [
      record,
      for (final existing in _records)
        if (existing.id != record.id) existing,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _records = next;
    await _persist();
  }

  Future<void> queueInvite(String employeeId) async {
    final next = [
      for (final record in _records)
        if (record.id == employeeId && record.canQueueInvite)
          record.copyWith(
            status: EmployeeInviteStatus.inviteQueued,
            updatedAt: DateTime.now(),
          )
        else
          record,
    ];
    _records = next;
    await _persist();
  }

  Future<void> _persist() async {
    await _box?.put(_recordsKey, [
      for (final record in _records) record.toMap(),
    ]);
    notifyListeners();
  }
}

List<EmployeeDirectoryRecord> _recordsFromBox(Object? value) {
  if (value is! Iterable) return const [];
  final records = value
      .whereType<Map>()
      .map(EmployeeDirectoryRecord.fromMap)
      .toList();
  records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return records;
}
