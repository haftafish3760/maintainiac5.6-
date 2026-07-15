part of 'maintainiac_firestore_upload_queue.dart';

class MaintainiacFirestoreUploadQueueStore {
  MaintainiacFirestoreUploadQueueStore._(this._box);

  static const boxName = 'maintainiac_firestore_upload_queue';

  final Box<dynamic> _box;
  Future<void> _writeTail = Future<void>.value();

  static Future<MaintainiacFirestoreUploadQueueStore> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return MaintainiacFirestoreUploadQueueStore._(box);
  }

  List<MaintainiacFirestoreQueuedDocument> get records {
    final loaded = <MaintainiacFirestoreQueuedDocument>[];
    for (final value in _box.values) {
      final record = MaintainiacFirestoreQueuedDocument.fromStored(value);
      if (!record.isEmpty) loaded.add(record);
    }
    loaded.sort((a, b) => a.queuedAtUtc.compareTo(b.queuedAtUtc));
    return List.unmodifiable(loaded);
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
  }) async {
    MaintainiacFirestoreUploadPolicy.validateDraft(draft);
    final queuedAt = (queuedAtUtc ?? DateTime.now().toUtc()).toUtc();
    final record = MaintainiacFirestoreQueuedDocument(
      id: _recordIdFor(draft.path, queuedAt),
      path: draft.path,
      data: Map<String, Object?>.unmodifiable(draft.data),
      queuedAtUtc: queuedAt,
    );
    await _box.put(record.id, record.toMap());
    await _trimOldestIfNeeded();
    return record;
  }

  Future<MaintainiacFirestoreQueuedDocument> enqueueReplacingPendingForPath(
    MaintainiacFirestoreDocumentDraft draft, {
    DateTime? queuedAtUtc,
  }) => _enqueue(() async {
    MaintainiacFirestoreUploadPolicy.validateDraft(draft);
    for (final record in pendingRecords) {
      if (record.path == draft.path) {
        await _box.delete(record.id);
      }
    }
    return _enqueueDocument(draft, queuedAtUtc: queuedAtUtc);
  });

  Future<List<MaintainiacFirestoreQueuedDocument>> enqueueAll(
    Iterable<MaintainiacFirestoreDocumentDraft> drafts, {
    DateTime? queuedAtUtc,
  }) => _enqueue(() async {
    final queued = <MaintainiacFirestoreQueuedDocument>[];
    for (final draft in drafts) {
      queued.add(await _enqueueDocument(draft, queuedAtUtc: queuedAtUtc));
    }
    return List.unmodifiable(queued);
  });

  List<MaintainiacFirestoreQueuedDocument> nextBatch({
    int? limit,
    String? path,
  }) {
    final cappedLimit = (limit ?? MaintainiacFirestoreUploadPolicy.maxBatchSize)
        .clamp(0, MaintainiacFirestoreUploadPolicy.maxBatchSize)
        .toInt();
    final candidates = path == null
        ? pendingRecords
        : pendingRecords.where((record) => record.path == path);
    return List.unmodifiable(candidates.take(cappedLimit));
  }

  Future<void> markAttempted(
    MaintainiacFirestoreQueuedDocument record, {
    required String error,
    DateTime? nowUtc,
  }) => _enqueue(() async {
    if (record.isEmpty) return;
    final attempted = MaintainiacFirestoreQueuedDocument(
      id: record.id,
      path: record.path,
      data: record.data,
      queuedAtUtc: record.queuedAtUtc,
      attemptCount: record.attemptCount + 1,
      lastAttemptAtUtc: (nowUtc ?? DateTime.now().toUtc()).toUtc(),
      lastError: error,
      uploadedAtUtc: record.uploadedAtUtc,
    );
    await _box.put(attempted.id, attempted.toMap());
  });

  Future<void> markUploaded(Iterable<String> recordIds, {DateTime? nowUtc}) =>
      _enqueue(() async {
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
}

abstract class MaintainiacFirestoreDocumentSink {
  Future<void> writeDocument({
    required String path,
    required Map<String, Object?> data,
  });
}

Future<void> _firestoreUploadTail = Future<void>.value();

class MaintainiacFirestoreUploadCoordinator {
  const MaintainiacFirestoreUploadCoordinator({
    required MaintainiacFirestoreUploadQueueStore queue,
    required MaintainiacFirestoreDocumentSink sink,
    bool uploadEnabled = false,
  }) : _queue = queue,
       _sink = sink,
       _uploadEnabled = uploadEnabled;

  final MaintainiacFirestoreUploadQueueStore _queue;
  final MaintainiacFirestoreDocumentSink _sink;
  final bool _uploadEnabled;

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

    final batch = _queue.nextBatch(limit: limit, path: path);
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
