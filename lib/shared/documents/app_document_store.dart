import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app_document_models.dart';

class AppDocumentStore extends ChangeNotifier {
  AppDocumentStore._(this._box);
  AppDocumentStore.memory() : _box = null;

  static const boxName = 'app_document_records';

  final Box<dynamic>? _box;
  final _memoryRecords = <String, AppDocumentRecord>{};

  static Future<AppDocumentStore> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return AppDocumentStore._(box);
  }

  List<AppDocumentRecord> get records {
    final source = _box == null ? _memoryRecords.values : _box.values;
    final records = <AppDocumentRecord>[];
    for (final value in source) {
      if (value is AppDocumentRecord) {
        records.add(value);
      } else if (value is Map) {
        records.add(AppDocumentRecord.fromMap(value));
      }
    }
    records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return records;
  }

  List<AppDocumentRecord> recordsForKind(AppDocumentKind kind) {
    return records.where((record) => record.kind == kind).toList();
  }

  AppDocumentRecord? recordById(String id) {
    final value = _box == null ? _memoryRecords[id] : _box.get(id);
    if (value is AppDocumentRecord) return value;
    if (value is Map) return AppDocumentRecord.fromMap(value);
    return null;
  }

  Future<AppDocumentRecord> saveRecord(AppDocumentRecord record) async {
    final now = DateTime.now();
    final existing = recordById(record.id);
    final saved = record.copyWith(
      createdAt: existing?.createdAt ?? record.createdAt,
      updatedAt: now,
    );
    if (_box == null) {
      _memoryRecords[saved.id] = saved;
    } else {
      await _box.put(saved.id, saved.toMap());
    }
    notifyListeners();
    return saved;
  }

  Future<void> deleteRecord(String id) async {
    if (_box == null) {
      _memoryRecords.remove(id);
    } else {
      await _box.delete(id);
    }
    notifyListeners();
  }

  Future<void> clear() async {
    _memoryRecords.clear();
    await _box?.clear();
    notifyListeners();
  }
}
