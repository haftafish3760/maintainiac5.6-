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

  Future<MaintainiacFirestoreQueuedDocument> enqueue(
    MaintainiacFirestoreDocumentDraft draft, {
    DateTime? queuedAtUtc,
  }) => _enqueue(() => _enqueueDocument(draft, queuedAtUtc: queuedAtUtc));

  Future<MaintainiacFirestoreQueuedDocument> _enqueueDocument(
    MaintainiacFirestoreDocumentDraft draft, {
    DateTime? queuedAtUtc,
    MaintainiacFirestoreQueuedDocument? retrySource,
  }) async {
    MaintainiacFirestoreUploadPolicy.validateDraft(draft);
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
      queued.add(await _enqueueDocument(draft, queuedAtUtc: queuedAtUtc));
    }
    return List.unmodifiable(queued);
  });

  List<MaintainiacFirestoreQueuedDocument> nextBatch({
    int? limit,
    String? path,
    DateTime? nowUtc,
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
    );
    await _box.put(attempted.id, attempted.toMap());
  });

  Future<void> markUploaded(Iterable<String> recordIds, {DateTime? nowUtc}) =>
      _enqueue(() async {
        await _ensureStorageForQueueWrite();
        final uploadedAt = (nowUtc ?? DateTime.now().toUtc()).toUtc();
        for (final id in recordIds) {
          final record = MaintainiacFirestoreQueuedDocument.fromStored(
            _box.get(id),
          );
          if (record.isEmpty) continue;
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
          );
          await _box.put(uploaded.id, uploaded.toMap());
        }
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

abstract class MaintainiacFirestoreDocumentSink {
  Future<void> writeDocument({
    required String path,
    required Map<String, Object?> data,
  });
}

Future<void> _firestoreUploadTail = Future<void>.value();

class MaintainiacFirestoreUploadCoordinator {
  MaintainiacFirestoreUploadCoordinator({
    required MaintainiacFirestoreUploadQueueStore queue,
    required MaintainiacFirestoreDocumentSink sink,
    bool uploadEnabled = false,
    int? freeSyncsUsedInWindow,
    int Function()? freeSyncsUsedInWindowReader,
    bool Function()? uploadNetworkAllowed,
  }) : _queue = queue,
       _sink = sink,
       _uploadEnabled = uploadEnabled,
       _uploadNetworkAllowed = uploadNetworkAllowed,
       _freeSyncsUsedInWindowReader =
           freeSyncsUsedInWindowReader ??
           (freeSyncsUsedInWindow == null
               ? null
               : (() => freeSyncsUsedInWindow));

  final MaintainiacFirestoreUploadQueueStore _queue;
  final MaintainiacFirestoreDocumentSink _sink;
  final bool _uploadEnabled;
  final bool Function()? _uploadNetworkAllowed;
  final int Function()? _freeSyncsUsedInWindowReader;

  Future<MaintainiacFirestoreUploadResult> uploadPending({
    int? limit,
    String? path,
    DateTime? nowUtc,
  }) =>
      _enqueue(() => _uploadPending(limit: limit, path: path, nowUtc: nowUtc));

  Future<MaintainiacFirestoreUploadResult> _uploadPending({
    int? limit,
    String? path,
    DateTime? nowUtc,
  }) async {
    if (!_uploadEnabled) {
      return const MaintainiacFirestoreUploadResult(
        status: MaintainiacFirestoreUploadStatus.disabled,
        attemptedCount: 0,
        uploadedCount: 0,
        failedCount: 0,
        reason: 'Firestore uploads are disabled until hosted sync is enabled.',
      );
    }
    bool networkAllowed;
    try {
      networkAllowed = _uploadNetworkAllowed?.call() ?? true;
    } catch (_) {
      networkAllowed = false;
    }
    if (!networkAllowed) {
      return const MaintainiacFirestoreUploadResult(
        status: MaintainiacFirestoreUploadStatus.networkUnavailable,
        attemptedCount: 0,
        uploadedCount: 0,
        failedCount: 0,
        reason: 'Backup sync is waiting for the selected network.',
      );
    }
    int? freeSyncsUsed;
    try {
      freeSyncsUsed = _freeSyncsUsedInWindowReader?.call();
    } catch (_) {
      return const MaintainiacFirestoreUploadResult(
        status: MaintainiacFirestoreUploadStatus.quotaExceeded,
        attemptedCount: 0,
        uploadedCount: 0,
        failedCount: 0,
        reason: 'Free backup sync limit could not be verified.',
      );
    }
    if (freeSyncsUsed != null &&
        (freeSyncsUsed < 0 ||
            !HostedUsageLimits.canUseFreeSync(
              syncsUsedInWindow: freeSyncsUsed,
            ))) {
      return const MaintainiacFirestoreUploadResult(
        status: MaintainiacFirestoreUploadStatus.quotaExceeded,
        attemptedCount: 0,
        uploadedCount: 0,
        failedCount: 0,
        reason: 'Free backup sync limit reached for this 24-hour window.',
      );
    }

    final batch = _queue.nextBatch(limit: limit, path: path, nowUtc: nowUtc);
    if (batch.isEmpty) {
      return const MaintainiacFirestoreUploadResult(
        status: MaintainiacFirestoreUploadStatus.empty,
        attemptedCount: 0,
        uploadedCount: 0,
        failedCount: 0,
      );
    }

    var uploadedCount = 0;
    var failedCount = 0;
    final uploadedIds = <String>[];
    for (final record in batch) {
      try {
        MaintainiacFirestoreUploadPolicy.validateDraft(
          MaintainiacFirestoreDocumentDraft(
            path: record.path,
            data: record.data,
          ),
        );
        await _sink.writeDocument(path: record.path, data: record.data);
        uploadedIds.add(record.id);
        uploadedCount += 1;
      } catch (error) {
        failedCount += 1;
        await _queue.markAttempted(
          record,
          error: error.toString(),
          nowUtc: nowUtc,
        );
      }
    }
    await _queue.markUploaded(uploadedIds, nowUtc: nowUtc);
    // The original local record remains the source of truth. Once the cloud
    // acknowledgement itself is durable, retaining this queue copy only
    // consumes device space and exposes stale account metadata.
    if (uploadedIds.isNotEmpty) await _queue.clearUploaded();

    final status = failedCount == 0
        ? MaintainiacFirestoreUploadStatus.uploaded
        : uploadedCount == 0
        ? MaintainiacFirestoreUploadStatus.failed
        : MaintainiacFirestoreUploadStatus.partial;
    return MaintainiacFirestoreUploadResult(
      status: status,
      attemptedCount: batch.length,
      uploadedCount: uploadedCount,
      failedCount: failedCount,
    );
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final next = _firestoreUploadTail.then((_) => operation());
    _firestoreUploadTail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }
}
