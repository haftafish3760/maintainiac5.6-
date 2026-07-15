import 'package:hive_flutter/hive_flutter.dart';

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
    return MaintainiacRecordLifecycle(
      createdAt: createdAt,
      updatedAt: now,
      revision: revision + 1,
      state: state,
      deletedAt: deletedAt,
      auditEvents: [...auditEvents, _event(now, event)],
    );
  }

  MaintainiacRecordLifecycle deleted(DateTime now, {required String event}) {
    return MaintainiacRecordLifecycle(
      createdAt: createdAt,
      updatedAt: now,
      revision: revision + 1,
      state: MaintainiacRecordState.deleted,
      deletedAt: now,
      auditEvents: [...auditEvents, _event(now, event)],
    );
  }

  MaintainiacRecordLifecycle restored(DateTime now, {required String event}) {
    return MaintainiacRecordLifecycle(
      createdAt: createdAt,
      updatedAt: now,
      revision: revision + 1,
      state: MaintainiacRecordState.active,
      auditEvents: [...auditEvents, _event(now, event)],
    );
  }

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
    final now = DateTime.now();
    return MaintainiacRecordDraft(
      module: map['module'] as String? ?? '',
      id: map['id'] as String? ?? '',
      payload: Map<String, dynamic>.from(map['payload'] as Map? ?? const {}),
      lifecycle: MaintainiacRecordLifecycle.fromMap(
        map['lifecycle'] as Map?,
        fallbackTime: now,
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

  static Future<MaintainiacRecordDraftStore> create({
    MaintainiacDraftStorageCheck? storageCheck,
  }) async => MaintainiacRecordDraftStore._(
    await Hive.openBox<dynamic>(boxName),
    storageCheck: storageCheck,
  );

  MaintainiacRecordDraft? draftFor(String module, String id) {
    final box = _box;
    final value = box == null ? _memory['$module:$id'] : box.get('$module:$id');
    if (value is MaintainiacRecordDraft) return value;
    return value is Map ? MaintainiacRecordDraft.fromMap(value) : null;
  }

  List<MaintainiacRecordDraft> draftsFor(String module) {
    final box = _box;
    final drafts = <MaintainiacRecordDraft>[];
    for (final value in box == null ? _memory.values : box.values) {
      final draft = value is MaintainiacRecordDraft
          ? value
          : value is Map
          ? MaintainiacRecordDraft.fromMap(value)
          : null;
      if (draft != null && draft.module == module) drafts.add(draft);
    }
    drafts.sort(
      (a, b) => b.lifecycle.updatedAt.compareTo(a.lifecycle.updatedAt),
    );
    return drafts;
  }

  Future<MaintainiacRecordDraft> save({
    required String module,
    required String id,
    required Map<String, dynamic> payload,
    DateTime? now,
  }) async {
    _validateDraftKey(module, id);
    await _ensureStorageForDraftSave();
    final time = now ?? DateTime.now();
    final existing = draftFor(module, id);
    final lifecycle = existing == null
        ? MaintainiacRecordLifecycle(
            createdAt: time,
            updatedAt: time,
            auditEvents: ['${time.toIso8601String()} created draft'],
          )
        : existing.lifecycle.saved(time, event: 'saved draft');
    final draft = MaintainiacRecordDraft(
      module: module,
      id: id,
      payload: Map.unmodifiable(Map<String, dynamic>.from(payload)),
      lifecycle: lifecycle,
    );
    final box = _box;
    if (box == null) {
      _memory[draft.storageKey] = draft;
    } else {
      await box.put(draft.storageKey, draft.toMap());
    }
    return draft;
  }

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
    if (module.contains(':') || id.contains(':')) {
      throw ArgumentError('Draft module and ID values cannot contain a colon.');
    }
  }

  Future<void> remove(String module, String id) async {
    final key = '$module:$id';
    final box = _box;
    if (box == null) {
      _memory.remove(key);
    } else {
      await box.delete(key);
    }
  }
}

DateTime? _date(Object? value) =>
    value is DateTime ? value : DateTime.tryParse(value?.toString() ?? '');

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
