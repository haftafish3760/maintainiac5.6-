import 'package:hive_flutter/hive_flutter.dart';

import 'maintainiac_hive_write_serialization.dart';
import 'maintainiac_record_audit_archive.dart';
import 'maintainiac_record_lifecycle.dart';

/// Local append-only audit evidence for every durable record lifecycle.
///
/// Archive writes occur before the compact record snapshot advances. A crash
/// may therefore leave a harmless replayable archive entry, but never removes
/// historical evidence that was already accepted locally.
class MaintainiacRecordAuditArchiveStore {
  MaintainiacRecordAuditArchiveStore._(this._box);

  MaintainiacRecordAuditArchiveStore.memory() : _box = null;

  final Box<dynamic>? _box;
  final Map<String, Map<String, Object>> _memory = {};

  static Future<MaintainiacRecordAuditArchiveStore> create(
    String boxName,
  ) async => MaintainiacRecordAuditArchiveStore._(
    await Hive.openBox<dynamic>(boxName),
  );

  Future<void> preserveLifecycle({
    required String module,
    required String id,
    required MaintainiacRecordLifecycle lifecycle,
  }) => _enqueue(() async {
    final entries = MaintainiacRecordAuditArchive.entriesFor(
      recordModule: module,
      recordId: id,
      auditEvents: lifecycle.auditEvents,
    );
    for (final entry in entries) {
      final key = entry.archiveId;
      final existing = _read(key);
      if (existing != null) {
        if (existing.entrySha256 != entry.entrySha256) {
          throw StateError('Audit archive evidence conflicts with local data.');
        }
        continue;
      }
      final map = entry.toMap();
      if (_box == null) {
        _memory[key] = map;
      } else {
        await _box.put(key, map);
      }
    }
  });

  List<MaintainiacRecordAuditArchiveEntry> entriesFor(
    String module,
    String id,
  ) {
    final key = MaintainiacRecordAuditArchiveEntry.recordKeyFor(module, id);
    final values = _box?.values ?? _memory.values;
    final entries = <MaintainiacRecordAuditArchiveEntry>[];
    for (final value in values) {
      if (value is! Map) continue;
      try {
        final entry = MaintainiacRecordAuditArchiveEntry.fromMap(value);
        if (entry.recordKey == key) entries.add(entry);
      } on FormatException {
        // Corrupt evidence is intentionally retained for recovery review.
      }
    }
    entries.sort((left, right) => left.ordinal.compareTo(right.ordinal));
    return List.unmodifiable(entries);
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final box = _box;
    return box == null
        ? operation()
        : MaintainiacHiveWriteSerialization.enqueue(box.name, operation);
  }

  MaintainiacRecordAuditArchiveEntry? _read(String key) {
    final value = _box?.get(key) ?? _memory[key];
    if (value is! Map) return null;
    try {
      return MaintainiacRecordAuditArchiveEntry.fromMap(value);
    } on FormatException {
      throw StateError(
        'Audit archive evidence is unreadable and was preserved.',
      );
    }
  }
}
