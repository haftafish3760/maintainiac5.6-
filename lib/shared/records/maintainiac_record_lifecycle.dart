import 'package:hive/hive.dart';

import '../storage/app_storage_guard.dart';

/// The one lifecycle vocabulary used by durable Maintainiac records.
enum MaintainiacRecordState {
  active,
  deleted;

  static MaintainiacRecordState fromName(String? value) {
    return MaintainiacRecordState.values.firstWhere(
      (state) => state.name == value?.trim().toLowerCase(),
      orElse: () => MaintainiacRecordState.active,
    );
  }
}

enum MaintainiacStoredRecordKind { confirmed, draft }

class MaintainiacStoredRecordIntegrityIssue {
  const MaintainiacStoredRecordIntegrityIssue({
    required this.storageKey,
    required this.kind,
  });

  final String storageKey;
  final MaintainiacStoredRecordKind kind;
}

/// Immutable, local-first lifecycle metadata shared by record modules.
class MaintainiacRecordLifecycle {
  MaintainiacRecordLifecycle({
    required this.createdAt,
    required this.updatedAt,
    this.revision = 1,
    this.state = MaintainiacRecordState.active,
    this.deletedAt,
    List<String> auditEvents = const [],
  }) : auditEvents = List.unmodifiable(List<String>.from(auditEvents));

  factory MaintainiacRecordLifecycle.fromMap(
    Map<dynamic, dynamic>? map, {
    required DateTime fallbackTime,
  }) {
    final createdAt = _date(map?['createdAt']) ?? fallbackTime;
    return MaintainiacRecordLifecycle(
      createdAt: createdAt,
      updatedAt: _date(map?['updatedAt']) ?? createdAt,
      revision: _int(map?['revision']) ?? 1,
      state: MaintainiacRecordState.fromName(map?['state'] as String?),
      deletedAt: _date(map?['deletedAt']),
      auditEvents:
          (map?['auditEvents'] as List?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const [],
    );
  }

  final DateTime createdAt;
  final DateTime updatedAt;
  final int revision;
  final MaintainiacRecordState state;
  final DateTime? deletedAt;
  final List<String> auditEvents;

  bool get isActive => state == MaintainiacRecordState.active;
  bool get isDeleted => state == MaintainiacRecordState.deleted;

  MaintainiacRecordLifecycle saved(DateTime now, {required String event}) {
    final time = _nextLifecycleTime(now);
    return MaintainiacRecordLifecycle(
      createdAt: createdAt,
      updatedAt: time,
      revision: revision + 1,
      state: state,
      deletedAt: deletedAt,
      auditEvents: [...auditEvents, _event(time, event)],
    );
  }

  MaintainiacRecordLifecycle deleted(DateTime now, {required String event}) {
    final time = _nextLifecycleTime(now);
    return MaintainiacRecordLifecycle(
      createdAt: createdAt,
      updatedAt: time,
      revision: revision + 1,
      state: MaintainiacRecordState.deleted,
      deletedAt: time,
      auditEvents: [...auditEvents, _event(time, event)],
    );
  }

  MaintainiacRecordLifecycle restored(DateTime now, {required String event}) {
    final time = _nextLifecycleTime(now);
    return MaintainiacRecordLifecycle(
      createdAt: createdAt,
      updatedAt: time,
      revision: revision + 1,
      state: MaintainiacRecordState.active,
      auditEvents: [...auditEvents, _event(time, event)],
    );
  }

  // A device clock can move backward or emit the same timestamp for separate
  // edits. Keep every lifecycle mutation strictly ordered so a newer draft
  // cannot be mistaken for the checkpoint that a confirmed record may remove.
  DateTime _nextLifecycleTime(DateTime requested) =>
      requested.isAfter(updatedAt)
      ? requested
      : updatedAt.add(const Duration(microseconds: 1));

  Map<String, dynamic> toMap() => {
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'revision': revision,
    'state': state.name,
    'deletedAt': deletedAt?.toIso8601String(),
    'auditEvents': auditEvents,
  };

  static String _event(DateTime time, String event) =>
      '${time.toIso8601String()} ${event.trim()}';
}

/// A shared local checkpoint for work that is not yet a confirmed record.
/// Screens save a checkpoint on meaningful edits and remove it only after the
/// confirmed record has been written successfully.
class MaintainiacRecordDraft {
  MaintainiacRecordDraft({
    required this.module,
    required this.id,
    required Map<String, dynamic> payload,
    required this.lifecycle,
  }) : payload = _freezeDraftPayload(payload);

  factory MaintainiacRecordDraft.fromMap(Map<dynamic, dynamic> map) {
    final module = map['module'];
    final id = map['id'];
    final payload = map['payload'];
    final lifecycleMap = map['lifecycle'];
    if (module is! String ||
        id is! String ||
        !_hasValidDurableDraftKey(module, id) ||
        payload is! Map ||
        lifecycleMap is! Map) {
      throw const FormatException('Draft record is corrupt.');
    }
    final createdAt = _date(lifecycleMap['createdAt']);
    final updatedAt = _date(lifecycleMap['updatedAt']);
    final revision = _int(lifecycleMap['revision']);
    final stateName = lifecycleMap['state'];
    final deletedAt = _date(lifecycleMap['deletedAt']);
    final state = MaintainiacRecordState.values.where(
      (state) => state.name == stateName,
    );
    if (createdAt == null ||
        updatedAt == null ||
        updatedAt.isBefore(createdAt) ||
        revision == null ||
        revision < 1 ||
        state.length != 1) {
      throw const FormatException('Draft lifecycle is corrupt.');
    }
    final recordState = state.single;
    if ((recordState == MaintainiacRecordState.deleted && deletedAt == null) ||
        (recordState == MaintainiacRecordState.active && deletedAt != null) ||
        (deletedAt != null &&
            (deletedAt.isBefore(createdAt) || deletedAt.isAfter(updatedAt)))) {
      throw const FormatException('Draft lifecycle is inconsistent.');
    }
    return MaintainiacRecordDraft(
      module: module,
      id: id,
      payload: Map<String, dynamic>.from(payload),
      lifecycle: MaintainiacRecordLifecycle(
        createdAt: createdAt,
        updatedAt: updatedAt,
        revision: revision,
        state: recordState,
        deletedAt: deletedAt,
        auditEvents:
            (lifecycleMap['auditEvents'] as List?)?.whereType<String>().toList(
              growable: false,
            ) ??
            const [],
      ),
    );
  }

  final String module;
  final String id;
  final Map<String, dynamic> payload;
  final MaintainiacRecordLifecycle lifecycle;

  String get storageKey => '$module:$id';

  Map<String, dynamic> toMap() => {
    'module': module,
    'id': id,
    'payload': payload,
    'lifecycle': lifecycle.toMap(),
  };
}

typedef MaintainiacDraftStorageCheck = Future<AppStorageCheck> Function();

class MaintainiacRecordDraftStore {
  MaintainiacRecordDraftStore._(
    this._box, {
    MaintainiacDraftStorageCheck? storageCheck,
  }) : _storageCheck = storageCheck ?? _defaultStorageCheck;
  MaintainiacRecordDraftStore.memory({
    MaintainiacDraftStorageCheck? storageCheck,
  }) : _box = null,
       _storageCheck = storageCheck;

  static const boxName = 'maintainiac_record_drafts';

  final Box<dynamic>? _box;
  final MaintainiacDraftStorageCheck? _storageCheck;
  final _memory = <String, MaintainiacRecordDraft>{};
  Future<void> _writeTail = Future<void>.value();

  static Future<MaintainiacRecordDraftStore> create({
    MaintainiacDraftStorageCheck? storageCheck,
  }) async => MaintainiacRecordDraftStore._(
    await Hive.openBox<dynamic>(boxName),
    storageCheck: storageCheck,
  );

  MaintainiacRecordDraft? draftFor(
    String module,
    String id, {
    bool includeDeleted = false,
  }) {
    final draft = _storedDraftFor(module, id);
    return includeDeleted || (draft?.lifecycle.isActive ?? false)
        ? draft
        : null;
  }

  MaintainiacRecordDraft? _storedDraftFor(String module, String id) {
    if (!_hasValidDraftKey(module, id)) return null;
    final box = _box;
    final value = box == null ? _memory['$module:$id'] : box.get('$module:$id');
    if (value is MaintainiacRecordDraft) return value;
    return _decodeStoredDraft(value);
  }

  List<MaintainiacRecordDraft> draftsFor(String module) {
    if (module.trim().isEmpty || module.contains(':')) return const [];
    final box = _box;
    final drafts = <MaintainiacRecordDraft>[];
    for (final value in box == null ? _memory.values : box.values) {
      final draft = _decodeStoredDraft(value);
      if (draft != null && draft.module == module && draft.lifecycle.isActive) {
        drafts.add(draft);
      }
    }
    drafts.sort(
      (a, b) => b.lifecycle.updatedAt.compareTo(a.lifecycle.updatedAt),
    );
    return drafts;
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
      if (_decodeStoredDraft(entry.value) == null) {
        issues.add(
          MaintainiacStoredRecordIntegrityIssue(
            storageKey: key,
            kind: MaintainiacStoredRecordKind.draft,
          ),
        );
      }
    }
    return List.unmodifiable(issues);
  }

  Future<MaintainiacRecordDraft> save({
    required String module,
    required String id,
    required Map<String, dynamic> payload,
    DateTime? now,
  }) => _enqueue(() async {
    _validateDraftKey(module, id);
    await _ensureStorageForDraftSave();
    final time = now ?? DateTime.now();
    final existing = _storedDraftFor(module, id);
    if (existing == null && _containsStoredDraft(module, id)) {
      throw StateError(
        'The existing draft is unreadable and was preserved for recovery.',
      );
    }
    if (existing != null && time.isBefore(existing.lifecycle.updatedAt)) {
      return existing;
    }
    final lifecycle = existing == null
        ? MaintainiacRecordLifecycle(
            createdAt: time,
            updatedAt: time,
            auditEvents: ['${time.toIso8601String()} created draft'],
          )
        : existing.lifecycle.isDeleted
        ? existing.lifecycle.restored(time, event: 'restored and saved draft')
        : existing.lifecycle.saved(time, event: 'saved draft');
    final draft = MaintainiacRecordDraft(
      module: module,
      id: id,
      payload: Map.unmodifiable(Map<String, dynamic>.from(payload)),
      lifecycle: lifecycle,
    );
    await _putDraft(draft);
    return draft;
  });

  static Future<AppStorageCheck> _defaultStorageCheck() =>
      AppStorageGuard.check(AppStoragePurpose.smallRecordWrite);

  Future<void> _ensureStorageForDraftSave() async {
    final check = _storageCheck;
    if (check == null) return;
    final storage = await check();
    if (!storage.hasEnoughSpace) throw StateError(storage.blockingMessage());
  }

  void _validateDraftKey(String module, String id) {
    if (module.trim().isEmpty || id.trim().isEmpty) {
      throw ArgumentError('A draft needs both a module and a stable ID.');
    }
    if (module != module.trim() || id != id.trim()) {
      throw ArgumentError(
        'Draft module and ID values cannot begin or end with spaces.',
      );
    }
    if (module.contains(':') || id.contains(':')) {
      throw ArgumentError('Draft module and ID values cannot contain a colon.');
    }
  }

  bool _hasValidDraftKey(String module, String id) =>
      module.trim().isNotEmpty &&
      id.trim().isNotEmpty &&
      module == module.trim() &&
      id == id.trim() &&
      !module.contains(':') &&
      !id.contains(':');

  bool _containsStoredDraft(String module, String id) {
    final key = '$module:$id';
    return _box?.containsKey(key) ?? _memory.containsKey(key);
  }

  Future<void> remove(String module, String id, {DateTime? now}) =>
      _enqueue(() async {
        if (!_hasValidDraftKey(module, id)) return;
        final existing = _storedDraftFor(module, id);
        if (existing == null || existing.lifecycle.isDeleted) return;
        await _ensureStorageForDraftSave();
        await _putDraft(
          MaintainiacRecordDraft(
            module: existing.module,
            id: existing.id,
            payload: existing.payload,
            lifecycle: existing.lifecycle.deleted(
              now ?? DateTime.now(),
              event: 'removed draft',
            ),
          ),
        );
      });

  /// Removes a checkpoint only when it is still the version acknowledged by
  /// the confirmed-record save. A delayed completion must not erase edits that
  /// were checkpointed while that save was in flight.
  Future<bool> removeIfUnchanged({
    required String module,
    required String id,
    required DateTime expectedUpdatedAt,
  }) => _enqueue(() async {
    if (!_hasValidDraftKey(module, id)) return false;
    final existing = _storedDraftFor(module, id);
    if (existing == null ||
        existing.lifecycle.isDeleted ||
        !existing.lifecycle.updatedAt.isAtSameMomentAs(expectedUpdatedAt)) {
      return false;
    }
    await _ensureStorageForDraftSave();
    await _putDraft(
      MaintainiacRecordDraft(
        module: existing.module,
        id: existing.id,
        payload: existing.payload,
        lifecycle: existing.lifecycle.deleted(
          expectedUpdatedAt,
          event: 'acknowledged confirmed record',
        ),
      ),
    );
    return true;
  });

  Future<void> _putDraft(MaintainiacRecordDraft draft) async {
    final box = _box;
    if (box == null) {
      _memory[draft.storageKey] = draft;
    } else {
      await box.put(draft.storageKey, draft.toMap());
    }
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  MaintainiacRecordDraft? _decodeStoredDraft(Object? value) {
    if (value is MaintainiacRecordDraft) return value;
    if (value is! Map) return null;
    try {
      return MaintainiacRecordDraft.fromMap(value);
      // A malformed checkpoint cannot be allowed to prevent recovery of every
      // other draft in the same local store.
    } catch (_) {
      return null;
    }
  }
}

DateTime? _date(Object? value) =>
    value is DateTime ? value : DateTime.tryParse(value?.toString() ?? '');

bool _hasValidDurableDraftKey(String module, String id) =>
    module.trim().isNotEmpty &&
    id.trim().isNotEmpty &&
    module == module.trim() &&
    id == id.trim() &&
    !module.contains(':') &&
    !id.contains(':');

int? _int(Object? value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '');

Map<String, dynamic> _freezeDraftPayload(Map<String, dynamic> payload) {
  return Map.unmodifiable({
    for (final entry in payload.entries)
      entry.key: _freezeDraftValue(entry.value),
  });
}

Object? _freezeDraftValue(Object? value) {
  if (value is Map) {
    return Map.unmodifiable({
      for (final entry in value.entries)
        entry.key: _freezeDraftValue(entry.value),
    });
  }
  if (value is List) {
    return List.unmodifiable(value.map(_freezeDraftValue));
  }
  return value;
}
