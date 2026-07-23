import 'package:hive_flutter/hive_flutter.dart';

import '../storage/app_storage_guard.dart';
import 'maintainiac_durable_payload.dart';
import 'maintainiac_hive_write_serialization.dart';
import 'maintainiac_record_lifecycle.dart';
import 'maintainiac_record_ordering.dart';

typedef MaintainiacDurableStorageCheck = Future<AppStorageCheck> Function();
typedef MaintainiacDurableSizedStorageCheck =
    Future<AppStorageCheck> Function(int operationBytes);

/// Shared local-first store for confirmed records owned by a Maintainiac
/// module. Modules keep their own payload schema while lifecycle, ordering,
/// storage safety, and conflict behavior remain identical across the app.
class MaintainiacDurableRecordStore {
  static const int maximumModuleLength = maintainiacMaximumRecordModuleLength;
  static const int maximumRecordIdLength = maintainiacMaximumRecordIdLength;

  MaintainiacDurableRecordStore._(
    this._box, {
    MaintainiacDurableStorageCheck? storageCheck,
    MaintainiacDurableSizedStorageCheck? sizedStorageCheck,
  }) : _storageCheck = storageCheck,
       _sizedStorageCheck = storageCheck == null
           ? (sizedStorageCheck ?? _defaultSizedStorageCheck)
           : null;

  MaintainiacDurableRecordStore.memory({
    MaintainiacDurableStorageCheck? storageCheck,
    MaintainiacDurableSizedStorageCheck? sizedStorageCheck,
  }) : _box = null,
       _storageCheck = storageCheck,
       _sizedStorageCheck = storageCheck == null ? sizedStorageCheck : null;

  final Box<dynamic>? _box;
  final MaintainiacDurableStorageCheck? _storageCheck;
  final MaintainiacDurableSizedStorageCheck? _sizedStorageCheck;
  final _memory = <String, Map<String, dynamic>>{};
  Future<void> _writeTail = Future<void>.value();

  static Future<MaintainiacDurableRecordStore> create(
    String boxName, {
    MaintainiacDurableStorageCheck? storageCheck,
    MaintainiacDurableSizedStorageCheck? sizedStorageCheck,
  }) async => MaintainiacDurableRecordStore._(
    await Hive.openBox<dynamic>(boxName),
    storageCheck: storageCheck,
    sizedStorageCheck: sizedStorageCheck,
  );

  MaintainiacDurableRecord? recordFor(String module, String id) {
    if (!_validKey(module, id)) return null;
    final value = _box?.get(_key(module, id)) ?? _memory[_key(module, id)];
    return value is Map ? _decode(value) : null;
  }

  List<MaintainiacDurableRecord> recordsFor(
    String module, {
    bool includeDeleted = false,
  }) {
    if (module.trim().isEmpty || module.contains(':')) return const [];
    final values = _box?.values ?? _memory.values;
    final records = <MaintainiacDurableRecord>[];
    for (final value in values) {
      if (value is! Map) {
        continue;
      }
      final record = _decode(value);
      if (record != null &&
          record.module == module &&
          (includeDeleted || record.lifecycle.isActive)) {
        records.add(record);
      }
    }
    records.sort(
      (a, b) => compareMaintainiacRecordsNewestFirst(
        leftUpdatedAt: a.lifecycle.updatedAt,
        leftRevision: a.lifecycle.revision,
        leftId: a.id,
        rightUpdatedAt: b.lifecycle.updatedAt,
        rightRevision: b.lifecycle.revision,
        rightId: b.id,
      ),
    );
    return List.unmodifiable(records);
  }

  List<MaintainiacStoredRecordIntegrityIssue> integrityIssues({
    String? module,
  }) {
    final box = _box;
    final entries = box == null ? _memory.entries : box.toMap().entries;
    final issues = <MaintainiacStoredRecordIntegrityIssue>[];
    for (final entry in entries) {
      final key = entry.key.toString();
      if (module != null && !key.startsWith('$module:')) continue;
      final value = entry.value;
      if (value is! Map || _decode(value) == null) {
        issues.add(
          MaintainiacStoredRecordIntegrityIssue(
            storageKey: key,
            kind: MaintainiacStoredRecordKind.confirmed,
          ),
        );
      }
    }
    return List.unmodifiable(issues);
  }

  Future<MaintainiacDurableRecord> save({
    required String module,
    required String id,
    required Map<String, dynamic> payload,
    int? expectedRevision,
    DateTime? now,
  }) => _enqueue(() async {
    _validateKey(module, id);
    final existing = recordFor(module, id);
    if (existing == null && _containsStoredValue(module, id)) {
      throw StateError(
        'The existing record is unreadable and was preserved for recovery.',
      );
    }
    if (existing?.lifecycle.isDeleted ?? false) {
      throw StateError('Restore a removed record before changing it.');
    }
    if (expectedRevision != null &&
        existing?.lifecycle.revision != expectedRevision) {
      throw StateError(
        'This record changed locally. Review the latest saved version.',
      );
    }
    final requested = now ?? DateTime.now();
    final lifecycle = existing == null
        ? MaintainiacRecordLifecycle(
            createdAt: requested,
            updatedAt: requested,
            auditEvents: ['${requested.toIso8601String()} created record'],
          )
        : existing.lifecycle.saved(requested, event: 'saved record');
    final record = MaintainiacDurableRecord(
      module: module,
      id: id,
      payload: payload,
      lifecycle: lifecycle,
    );
    await _ensureSpace(
      MaintainiacDurablePayload.encodedByteEstimate(record.toMap()),
    );
    await _put(record);
    return record;
  });

  /// Confirms a record locally before acknowledging its draft checkpoint.
  /// A newer draft is intentionally retained for recovery rather than lost.
  Future<MaintainiacDurableRecord> saveAndAcknowledgeDraft({
    required String module,
    required String id,
    required Map<String, dynamic> payload,
    required MaintainiacRecordDraftStore draftStore,
    required DateTime expectedDraftUpdatedAt,
    int? expectedRevision,
    DateTime? now,
  }) async {
    final existing = recordFor(module, id);
    final draft = draftStore.draftFor(module, id);
    final matchesDraft =
        draft != null &&
        draft.lifecycle.updatedAt.isAtSameMomentAs(expectedDraftUpdatedAt);
    final isAcknowledgmentRetry =
        existing != null &&
        matchesDraft &&
        !existing.lifecycle.updatedAt.isBefore(expectedDraftUpdatedAt) &&
        MaintainiacDurablePayload.equivalent(existing.payload, payload) &&
        (expectedRevision == null ||
            existing.lifecycle.revision == expectedRevision + 1);
    final record = isAcknowledgmentRetry
        ? existing
        : await save(
            module: module,
            id: id,
            payload: payload,
            expectedRevision: expectedRevision,
            now: now,
          );
    await draftStore.removeIfUnchanged(
      module: module,
      id: id,
      expectedUpdatedAt: expectedDraftUpdatedAt,
    );
    return record;
  }

  Future<MaintainiacDurableRecord?> delete(
    String module,
    String id, {
    DateTime? now,
  }) => _enqueue(() async {
    final existing = recordFor(module, id);
    if (existing == null || existing.lifecycle.isDeleted) return existing;
    final record = existing.withLifecycle(
      existing.lifecycle.deleted(
        now ?? DateTime.now(),
        event: 'deleted record',
      ),
    );
    await _ensureSpace(
      MaintainiacDurablePayload.encodedByteEstimate(record.toMap()),
    );
    await _put(record);
    return record;
  });

  Future<MaintainiacDurableRecord?> restore(
    String module,
    String id, {
    DateTime? now,
  }) => _enqueue(() async {
    final existing = recordFor(module, id);
    if (existing == null || existing.lifecycle.isActive) return existing;
    final record = existing.withLifecycle(
      existing.lifecycle.restored(
        now ?? DateTime.now(),
        event: 'restored record',
      ),
    );
    await _ensureSpace(
      MaintainiacDurablePayload.encodedByteEstimate(record.toMap()),
    );
    await _put(record);
    return record;
  });

  /// Applies a verified cloud version without rewriting its original
  /// lifecycle. The expected revision closes the race between restore conflict
  /// evaluation and the local write.
  Future<MaintainiacDurableRecord> applyRestoredRecord(
    MaintainiacDurableRecord remote, {
    required int? expectedLocalRevision,
  }) => _enqueue(() async {
    _validateKey(remote.module, remote.id);
    final verified = MaintainiacDurableRecord.fromMap(remote.toMap());
    final local = recordFor(remote.module, remote.id);
    if (local == null && _containsStoredValue(remote.module, remote.id)) {
      throw StateError(
        'The local record is unreadable and was preserved for recovery.',
      );
    }
    if (local?.lifecycle.revision != expectedLocalRevision) {
      throw StateError('The local record changed during restore.');
    }
    if (local != null &&
        verified.lifecycle.revision <= local.lifecycle.revision) {
      throw StateError(
        'Restore cannot replace an equal or newer local record.',
      );
    }
    await _ensureSpace(
      MaintainiacDurablePayload.encodedByteEstimate(verified.toMap()),
    );
    await _put(verified);
    return verified;
  });

  Future<MaintainiacDurableRecord> preserveLocalAfterConflict({
    required String module,
    required String id,
    required int expectedRevision,
    DateTime? now,
  }) => _enqueue(() async {
    final local = recordFor(module, id);
    if (local == null || local.lifecycle.revision != expectedRevision) {
      throw StateError('The local record changed during conflict review.');
    }
    final preserved = local.withLifecycle(
      local.lifecycle.saved(
        now ?? DateTime.now(),
        event: 'resolved cloud conflict by keeping local record',
      ),
    );
    await _ensureSpace(
      MaintainiacDurablePayload.encodedByteEstimate(preserved.toMap()),
    );
    await _put(preserved);
    return preserved;
  });

  Future<MaintainiacDurableRecord> applyRemoteAfterConflict(
    MaintainiacDurableRecord remote, {
    required int expectedLocalRevision,
  }) => _enqueue(() async {
    final verified = MaintainiacDurableRecord.fromMap(remote.toMap());
    final local = recordFor(verified.module, verified.id);
    if (local == null ||
        local.lifecycle.revision != expectedLocalRevision ||
        verified.lifecycle.revision != expectedLocalRevision) {
      throw StateError('The conflict record changed before resolution.');
    }
    await _ensureSpace(
      MaintainiacDurablePayload.encodedByteEstimate(verified.toMap()),
    );
    await _put(verified);
    return verified;
  });

  Future<void> _put(MaintainiacDurableRecord record) async {
    final map = record.toMap();
    if (_box == null) {
      _memory[record.storageKey] = map;
    } else {
      await _box.put(record.storageKey, map);
    }
  }

  Future<void> _ensureSpace(int operationBytes) async {
    final check = _storageCheck;
    final sizedCheck = _sizedStorageCheck;
    if (check == null && sizedCheck == null) return;
    final result = check != null
        ? await check()
        : await sizedCheck!(operationBytes);
    if (!result.hasEnoughSpace) throw StateError(result.blockingMessage());
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final box = _box;
    if (box != null) {
      return MaintainiacHiveWriteSerialization.enqueue(box.name, operation);
    }
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>((_) {}, onError: (_) {});
    return next;
  }

  static Future<AppStorageCheck> _defaultSizedStorageCheck(
    int operationBytes,
  ) => AppStorageGuard.checkForBytes(
    operationBytes: operationBytes < AppStorageGuard.smallRecordWriteBytes
        ? AppStorageGuard.smallRecordWriteBytes
        : operationBytes,
    purpose: AppStoragePurpose.smallRecordWrite,
  );

  static String _key(String module, String id) => '$module:$id';
  bool _containsStoredValue(String module, String id) {
    final key = _key(module, id);
    return _box?.containsKey(key) ?? _memory.containsKey(key);
  }

  static bool _validKey(String module, String id) =>
      module.trim().isNotEmpty &&
      id.trim().isNotEmpty &&
      module.length <= maximumModuleLength &&
      id.length <= maximumRecordIdLength &&
      module == module.trim() &&
      id == id.trim() &&
      !module.contains(':') &&
      !id.contains(':');
  static void _validateKey(String module, String id) {
    if (!_validKey(module, id)) {
      throw ArgumentError('A record needs a safe module and stable ID.');
    }
  }

  static MaintainiacDurableRecord? _decode(Map<dynamic, dynamic> map) {
    try {
      return MaintainiacDurableRecord.fromMap(map);
      // Device storage is untrusted at recovery time. A partially written or
      // legacy-corrupt value must be skipped rather than crashing the module
      // that is attempting to recover its other valid records.
    } catch (_) {
      return null;
    }
  }
}

class MaintainiacDurableRecord {
  MaintainiacDurableRecord({
    required this.module,
    required this.id,
    required Map<String, dynamic> payload,
    required this.lifecycle,
  }) : payload = _freezePayload(payload);

  factory MaintainiacDurableRecord.fromMap(Map<dynamic, dynamic> map) {
    final module = map['module'];
    final id = map['id'];
    final payload = map['payload'];
    final lifecycle = map['lifecycle'];
    if (module is! String ||
        id is! String ||
        payload is! Map ||
        lifecycle is! Map ||
        !_hasValidLifecycleDates(lifecycle) ||
        !MaintainiacDurableRecordStore._validKey(module, id)) {
      throw const FormatException('Durable record is corrupt.');
    }
    try {
      final metadata = MaintainiacRecordLifecycle.fromMap(lifecycle);
      return MaintainiacDurableRecord(
        module: module,
        id: id,
        payload: Map<String, dynamic>.from(payload),
        lifecycle: metadata,
      );
    } catch (_) {
      throw const FormatException('Durable record is corrupt.');
    }
  }

  final String module;
  final String id;
  final Map<String, dynamic> payload;
  final MaintainiacRecordLifecycle lifecycle;
  String get storageKey => '$module:$id';
  MaintainiacDurableRecord withLifecycle(MaintainiacRecordLifecycle value) =>
      MaintainiacDurableRecord(
        module: module,
        id: id,
        payload: payload,
        lifecycle: value,
      );
  Map<String, dynamic> toMap() => {
    'module': module,
    'id': id,
    'payload': payload,
    'lifecycle': lifecycle.toMap(),
  };

  static bool _hasValidLifecycleDates(Map<dynamic, dynamic> lifecycle) =>
      _isValidDate(lifecycle['createdAt']) &&
      _isValidDate(lifecycle['updatedAt']);

  static bool _isValidDate(Object? value) =>
      value is DateTime ||
      (value is String && DateTime.tryParse(value) != null);

  static Map<String, dynamic> _freezePayload(Map<String, dynamic> value) =>
      MaintainiacDurablePayload.freeze(value);
}
