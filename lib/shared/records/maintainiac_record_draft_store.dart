part of 'maintainiac_record_lifecycle.dart';

typedef MaintainiacDraftStorageCheck = Future<AppStorageCheck> Function();
typedef MaintainiacDraftSizedStorageCheck =
    Future<AppStorageCheck> Function(int operationBytes);

class MaintainiacRecordDraftStore {
  MaintainiacRecordDraftStore._(
    this._box, {
    MaintainiacDraftStorageCheck? storageCheck,
    MaintainiacDraftSizedStorageCheck? sizedStorageCheck,
  }) : _storageCheck = storageCheck,
       _sizedStorageCheck = storageCheck == null
           ? (sizedStorageCheck ?? _defaultSizedStorageCheck)
           : null;
  MaintainiacRecordDraftStore.memory({
    MaintainiacDraftStorageCheck? storageCheck,
    MaintainiacDraftSizedStorageCheck? sizedStorageCheck,
  }) : _box = null,
       _storageCheck = storageCheck,
       _sizedStorageCheck = storageCheck == null ? sizedStorageCheck : null;

  static const boxName = 'maintainiac_record_drafts';

  final Box<dynamic>? _box;
  final MaintainiacDraftStorageCheck? _storageCheck;
  final MaintainiacDraftSizedStorageCheck? _sizedStorageCheck;
  final _memory = <String, MaintainiacRecordDraft>{};
  Future<void> _writeTail = Future<void>.value();

  static Future<MaintainiacRecordDraftStore> create({
    MaintainiacDraftStorageCheck? storageCheck,
    MaintainiacDraftSizedStorageCheck? sizedStorageCheck,
  }) async => MaintainiacRecordDraftStore._(
    await Hive.openBox<dynamic>(boxName),
    storageCheck: storageCheck,
    sizedStorageCheck: sizedStorageCheck,
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
      (a, b) => compareMaintainiacRecordsNewestFirst(
        leftUpdatedAt: a.lifecycle.updatedAt,
        leftRevision: a.lifecycle.revision,
        leftId: a.id,
        rightUpdatedAt: b.lifecycle.updatedAt,
        rightRevision: b.lifecycle.revision,
        rightId: b.id,
      ),
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
        : existing.lifecycle.checkpointed(time);
    final draft = MaintainiacRecordDraft(
      module: module,
      id: id,
      payload: Map.unmodifiable(Map<String, dynamic>.from(payload)),
      lifecycle: lifecycle,
    );
    await _ensureStorageForDraftSave(
      MaintainiacDurablePayload.encodedByteEstimate(draft.toMap()),
    );
    await _putDraft(draft);
    return draft;
  });

  static Future<AppStorageCheck> _defaultSizedStorageCheck(
    int operationBytes,
  ) => AppStorageGuard.checkForBytes(
    operationBytes: operationBytes < AppStorageGuard.smallRecordWriteBytes
        ? AppStorageGuard.smallRecordWriteBytes
        : operationBytes,
    purpose: AppStoragePurpose.smallRecordWrite,
  );

  Future<void> _ensureStorageForDraftSave(int operationBytes) async {
    final check = _storageCheck;
    final sizedCheck = _sizedStorageCheck;
    if (check == null && sizedCheck == null) return;
    final storage = check != null
        ? await check()
        : await sizedCheck!(operationBytes);
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
        final removed = MaintainiacRecordDraft(
          module: existing.module,
          id: existing.id,
          payload: existing.payload,
          lifecycle: existing.lifecycle.deleted(
            now ?? DateTime.now(),
            event: 'removed draft',
          ),
        );
        await _ensureStorageForDraftSave(
          MaintainiacDurablePayload.encodedByteEstimate(removed.toMap()),
        );
        await _putDraft(removed);
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
    final acknowledged = MaintainiacRecordDraft(
      module: existing.module,
      id: existing.id,
      payload: existing.payload,
      lifecycle: existing.lifecycle.deleted(
        expectedUpdatedAt,
        event: 'acknowledged confirmed record',
      ),
    );
    await _ensureStorageForDraftSave(
      MaintainiacDurablePayload.encodedByteEstimate(acknowledged.toMap()),
    );
    await _putDraft(acknowledged);
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
