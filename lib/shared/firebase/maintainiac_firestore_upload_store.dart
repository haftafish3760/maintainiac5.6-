part of 'maintainiac_firestore_upload_queue.dart';

class MaintainiacFirestoreUploadQueueStore {
  MaintainiacFirestoreUploadQueueStore._(this._box, {this.storageCheck});

  static const boxName = 'maintainiac_firestore_upload_queue';

  final Box<dynamic> _box;
  final MaintainiacFirestoreQueueStorageCheck? storageCheck;
  Future<void> _writeTail = Future<void>.value();

  static Future<MaintainiacFirestoreUploadQueueStore> create({
    MaintainiacFirestoreQueueStorageCheck? storageCheck,
  }) async {
    final box = await Hive.openBox<dynamic>(boxName);
    return MaintainiacFirestoreUploadQueueStore._(
      box,
      storageCheck: storageCheck ?? _defaultStorageCheck,
    );
  }

  List<MaintainiacFirestoreQueuedDocument> get records {
    final loaded = <MaintainiacFirestoreQueuedDocument>[];
    for (final value in _box.values) {
      final record = MaintainiacFirestoreQueuedDocument.fromStored(value);
      if (_isRecoverableQueuedDocument(record)) loaded.add(record);
    }
    loaded.sort((a, b) => a.queuedAtUtc.compareTo(b.queuedAtUtc));
    return List.unmodifiable(loaded);
  }

  bool _isRecoverableQueuedDocument(MaintainiacFirestoreQueuedDocument record) {
    if (record.isEmpty) return false;
    try {
      MaintainiacFirestoreUploadPolicy.validateDraft(
        MaintainiacFirestoreDocumentDraft(path: record.path, data: record.data),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  List<MaintainiacFirestoreQueuedDocument> get pendingRecords {
    return List.unmodifiable(records.where((record) => record.isPendingUpload));
  }

  List<MaintainiacFirestoreQueueIntegrityIssue> get integrityIssues {
    final issues = <MaintainiacFirestoreQueueIntegrityIssue>[];
    for (final entry in _box.toMap().entries) {
      final record = MaintainiacFirestoreQueuedDocument.fromStored(entry.value);
      if (record.isEmpty) {
        issues.add(
          MaintainiacFirestoreQueueIntegrityIssue(
            entryId: entry.key.toString(),
            reason: 'Unreadable queued backup evidence was preserved.',
          ),
        );
      } else if (!_isRecoverableQueuedDocument(record)) {
        issues.add(
          MaintainiacFirestoreQueueIntegrityIssue(
            entryId: entry.key.toString(),
            reason: 'Unsafe queued backup evidence was preserved.',
          ),
        );
      }
    }
    return List.unmodifiable(issues);
  }

  Future<MaintainiacFirestoreQueuedDocument> enqueue(
    MaintainiacFirestoreDocumentDraft draft, {
    DateTime? queuedAtUtc,
  }) => _enqueue(
    () => _enqueueDocument(draft, queuedAtUtc: queuedAtUtc, deduplicate: true),
  );

  Future<MaintainiacFirestoreQueuedDocument> _enqueueDocument(
    MaintainiacFirestoreDocumentDraft draft, {
    DateTime? queuedAtUtc,
    MaintainiacFirestoreQueuedDocument? retrySource,
    bool deduplicate = false,
  }) async {
    MaintainiacFirestoreUploadPolicy.validateDraft(draft);
    if (deduplicate) {
      final duplicate = _latestMatchingPending(draft);
      if (duplicate != null) return duplicate;
    }
    await _ensureStorageForQueueWrite();
    final queuedAt = (queuedAtUtc ?? DateTime.now().toUtc()).toUtc();
    final record = MaintainiacFirestoreQueuedDocument(
      id: _recordIdFor(draft.path, queuedAt),
      path: draft.path,
      data: Map<String, Object?>.unmodifiable(draft.data),
      queuedAtUtc: queuedAt,
      attemptCount: retrySource?.attemptCount ?? 0,
      lastAttemptAtUtc: retrySource?.lastAttemptAtUtc,
      nextAttemptAtUtc: retrySource?.nextAttemptAtUtc,
      lastError: retrySource?.lastError,
      conflictedAtUtc: null,
    );
    await _box.put(record.id, record.toMap());
    await _trimOldestIfNeeded();
    return record;
  }

  Future<MaintainiacFirestoreQueuedDocument> enqueueReplacingPendingForPath(
    MaintainiacFirestoreDocumentDraft draft, {
    DateTime? queuedAtUtc,
    bool preserveAttemptMetadata = false,
  }) => _enqueue(() async {
    MaintainiacFirestoreUploadPolicy.validateDraft(draft);
    await _ensureStorageForQueueWrite();
    final replaced = [
      for (final record in pendingRecords)
        if (record.path == draft.path) record,
    ];
    // Write the replacement before removing any retry evidence. If an I/O
    // failure interrupts this operation, the older pending record remains
    // recoverable rather than silently losing a user-authorized backup.
    final queued = await _enqueueDocument(
      draft,
      queuedAtUtc: queuedAtUtc,
      retrySource: preserveAttemptMetadata ? _latestAttempt(replaced) : null,
    );
    for (final record in replaced) {
      await _box.delete(record.id);
    }
    return queued;
  });

  Future<List<MaintainiacFirestoreQueuedDocument>> enqueueAll(
    Iterable<MaintainiacFirestoreDocumentDraft> drafts, {
    DateTime? queuedAtUtc,
  }) => _enqueue(() async {
    await _ensureStorageForQueueWrite();
    final queued = <MaintainiacFirestoreQueuedDocument>[];
    for (final draft in drafts) {
      queued.add(
        await _enqueueDocument(
          draft,
          queuedAtUtc: queuedAtUtc,
          deduplicate: true,
        ),
      );
    }
    return List.unmodifiable(queued);
  });

  List<MaintainiacFirestoreQueuedDocument> nextBatch({
    int? limit,
    String? path,
    DateTime? nowUtc,
    bool Function(MaintainiacFirestoreQueuedDocument record)? isEligible,
  }) {
    final cappedLimit = (limit ?? MaintainiacFirestoreUploadPolicy.maxBatchSize)
        .clamp(0, MaintainiacFirestoreUploadPolicy.maxBatchSize)
        .toInt();
    final candidates = path == null
        ? pendingRecords
        : pendingRecords.where((record) => record.path == path);
    final now = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    return List.unmodifiable(
      candidates
          .where((record) => record.isReadyForAttemptAt(now))
          .where((record) => isEligible?.call(record) ?? true)
          .take(cappedLimit),
    );
  }

  Future<void> markAttempted(
    MaintainiacFirestoreQueuedDocument record, {
    required String error,
    DateTime? nowUtc,
  }) => _enqueue(() async {
    if (record.isEmpty) return;
    // A newer replacement may have removed this exact queue entry while an
    // upload was in flight. Never resurrect that stale payload after a failed
    // network attempt.
    final current = MaintainiacFirestoreQueuedDocument.fromStored(
      _box.get(record.id),
    );
    if (current.isEmpty || !current.isPendingUpload) return;
    await _ensureStorageForQueueWrite();
    final requestedAttemptAt = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    final attemptAt = current.lastAttemptAtUtc == null
        ? requestedAttemptAt
        : _nextQueueTimestamp(
            current.lastAttemptAtUtc!,
            requested: requestedAttemptAt,
          );
    final attemptCount = current.attemptCount + 1;
    final attempted = MaintainiacFirestoreQueuedDocument(
      id: current.id,
      path: current.path,
      data: current.data,
      queuedAtUtc: current.queuedAtUtc,
      attemptCount: attemptCount,
      lastAttemptAtUtc: attemptAt,
      nextAttemptAtUtc: attemptAt.add(
        MaintainiacFirestoreUploadPolicy.retryDelayForAttempt(attemptCount),
      ),
      lastError: error,
      uploadedAtUtc: current.uploadedAtUtc,
      conflictedAtUtc: current.conflictedAtUtc,
    );
    await _box.put(attempted.id, attempted.toMap());
  });

  Future<void> markUploaded(Iterable<String> recordIds, {DateTime? nowUtc}) =>
      _enqueue(() async {
        await _ensureStorageForQueueWrite();
        final requestedUploadedAt = (nowUtc ?? DateTime.now().toUtc()).toUtc();
        for (final id in recordIds) {
          final record = MaintainiacFirestoreQueuedDocument.fromStored(
            _box.get(id),
          );
          if (record.isEmpty) continue;
          final notBefore = record.lastAttemptAtUtc ?? record.queuedAtUtc;
          final uploadedAt = requestedUploadedAt.isBefore(notBefore)
              ? notBefore
              : requestedUploadedAt;
          final uploaded = MaintainiacFirestoreQueuedDocument(
            id: record.id,
            path: record.path,
            data: record.data,
            queuedAtUtc: record.queuedAtUtc,
            attemptCount: record.attemptCount,
            lastAttemptAtUtc: record.lastAttemptAtUtc,
            nextAttemptAtUtc: null,
            lastError: record.lastError,
            uploadedAtUtc: uploadedAt,
            conflictedAtUtc: record.conflictedAtUtc,
          );
          await _box.put(uploaded.id, uploaded.toMap());
        }
      });

  Future<void> markConflicted(
    MaintainiacFirestoreQueuedDocument record, {
    required String error,
    DateTime? nowUtc,
  }) => _enqueue(() async {
    if (record.isEmpty) return;
    final current = MaintainiacFirestoreQueuedDocument.fromStored(
      _box.get(record.id),
    );
    if (current.isEmpty || !current.isPendingUpload) return;
    await _ensureStorageForQueueWrite();
    final conflictedAt = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    await _box.put(
      current.id,
      MaintainiacFirestoreQueuedDocument(
        id: current.id,
        path: current.path,
        data: current.data,
        queuedAtUtc: current.queuedAtUtc,
        attemptCount: current.attemptCount + 1,
        lastAttemptAtUtc: conflictedAt,
        lastError: error,
        uploadedAtUtc: current.uploadedAtUtc,
        conflictedAtUtc: conflictedAt,
      ).toMap(),
    );
  });

  Future<void> clearUploaded() => _enqueue(() async {
    for (final record in records) {
      if (record.uploadedAtUtc != null) {
        await _box.delete(record.id);
      }
    }
  });

  Future<void> discardPendingForPath(String path) => _enqueue(() async {
    for (final record in pendingRecords) {
      if (record.path == path) await _box.delete(record.id);
    }
  });

  Future<void> clearAll() => _enqueue(() => _box.clear());

  static Future<AppStorageCheck> _defaultStorageCheck() =>
      AppStorageGuard.check(AppStoragePurpose.smallRecordWrite);

  Future<void> _ensureStorageForQueueWrite() async {
    final check = storageCheck;
    if (check == null) return;
    final storage = await check();
    if (!storage.hasEnoughSpace) throw StateError(storage.blockingMessage());
  }

  Future<void> _trimOldestIfNeeded() async {
    final extraCount =
        records.length - MaintainiacFirestoreUploadPolicy.maxQueuedRecords;
    if (extraCount <= 0) return;
    // Pending records are the durable retry ledger. A size cap must never
    // silently discard unsynced local changes; only already-uploaded
    // acknowledgments may be trimmed here.
    final uploaded = records.where((record) => record.uploadedAtUtc != null);
    for (final record in uploaded.take(extraCount)) {
      await _box.delete(record.id);
    }
  }

  MaintainiacFirestoreQueuedDocument? _latestAttempt(
    List<MaintainiacFirestoreQueuedDocument> records,
  ) {
    if (records.isEmpty) return null;
    final sorted = [...records]
      ..sort((a, b) {
        final left = a.lastAttemptAtUtc ?? a.queuedAtUtc;
        final right = b.lastAttemptAtUtc ?? b.queuedAtUtc;
        return right.compareTo(left);
      });
    return sorted.first;
  }

  MaintainiacFirestoreQueuedDocument? _latestMatchingPending(
    MaintainiacFirestoreDocumentDraft draft,
  ) {
    final expected = jsonEncode(_canonicalSyncValue(draft.data));
    final matching = pendingRecords.where(
      (record) =>
          record.path == draft.path &&
          jsonEncode(_canonicalSyncValue(record.data)) == expected,
    );
    return matching.isEmpty ? null : matching.last;
  }

  String _recordIdFor(String path, DateTime queuedAtUtc) {
    final basePath = path
        .replaceAll(RegExp(r'[^A-Za-z0-9_.-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final base = '${queuedAtUtc.microsecondsSinceEpoch}_$basePath';
    var id = base;
    var suffix = 1;
    while (_box.containsKey(id)) {
      id = '$base-$suffix';
      suffix += 1;
    }
    return id;
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  DateTime _nextQueueTimestamp(DateTime current, {DateTime? requested}) {
    final next = (requested ?? DateTime.now().toUtc()).toUtc();
    return next.isAfter(current)
        ? next
        : current.add(const Duration(microseconds: 1));
  }
}
