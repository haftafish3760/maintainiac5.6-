part of 'maintainiac_firestore_upload_queue.dart';

abstract class MaintainiacFirestoreDocumentSink {
  Future<void> writeDocument({
    required String path,
    required Map<String, Object?> data,
  });
}

abstract interface class MaintainiacFirestoreBatchDocumentSink {
  Future<void> writeDocuments(
    List<MaintainiacFirestoreDocumentDraft> documents,
  );
}

/// Marker for real hosted sinks that must never write without a server-issued
/// sync reservation. Test and local-only sinks remain usable without Firebase.
abstract interface class MaintainiacHostedReservationRequiredSink {}

Future<void> _firestoreUploadTail = Future<void>.value();

class MaintainiacFirestoreUploadCoordinator {
  MaintainiacFirestoreUploadCoordinator({
    required MaintainiacFirestoreUploadQueueStore queue,
    required MaintainiacFirestoreDocumentSink sink,
    bool uploadEnabled = false,
    int? freeSyncsUsedInWindow,
    int Function()? freeSyncsUsedInWindowReader,
    MaintainiacFirestoreFreeSyncAttemptRecorder? freeSyncAttemptRecorder,
    MaintainiacHostedSyncReservationProvider? hostedSyncReservationProvider,
    MaintainiacFirestoreUploadAcknowledgment? uploadAcknowledgment,
    bool Function()? uploadNetworkAllowed,
    MaintainiacCloudIdentityProvider? identityProvider,
  }) : _queue = queue,
       _sink = sink,
       _uploadEnabled = uploadEnabled,
       _uploadNetworkAllowed = uploadNetworkAllowed,
       _freeSyncAttemptRecorder = freeSyncAttemptRecorder,
       _hostedSyncReservationProvider = hostedSyncReservationProvider,
       _uploadAcknowledgment = uploadAcknowledgment,
       _identityProvider =
           identityProvider ??
           (sink is FirebaseFirestoreDocumentSink
               ? sink._identityProvider
               : null),
       _freeSyncsUsedInWindowReader =
           freeSyncsUsedInWindowReader ??
           (freeSyncsUsedInWindow == null
               ? null
               : (() => freeSyncsUsedInWindow));

  final MaintainiacFirestoreUploadQueueStore _queue;
  final MaintainiacFirestoreDocumentSink _sink;
  final bool _uploadEnabled;
  final bool Function()? _uploadNetworkAllowed;
  final MaintainiacFirestoreFreeSyncAttemptRecorder? _freeSyncAttemptRecorder;
  final MaintainiacHostedSyncReservationProvider?
  _hostedSyncReservationProvider;
  final MaintainiacFirestoreUploadAcknowledgment? _uploadAcknowledgment;
  final int Function()? _freeSyncsUsedInWindowReader;
  final MaintainiacCloudIdentityProvider? _identityProvider;

  Future<MaintainiacFirestoreUploadResult> uploadPending({
    int? limit,
    String? path,
    DateTime? nowUtc,
    String? attemptId,
  }) => _enqueue(
    () => _uploadPending(
      limit: limit,
      path: path,
      nowUtc: nowUtc,
      attemptId: attemptId,
    ),
  );

  Future<MaintainiacFirestoreUploadResult> _uploadPending({
    int? limit,
    String? path,
    DateTime? nowUtc,
    String? attemptId,
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
    String? authenticatedUid;
    final identityProvider = _identityProvider;
    if (identityProvider != null) {
      try {
        authenticatedUid = identityProvider.currentUid?.trim();
      } catch (_) {
        authenticatedUid = null;
      }
      if (authenticatedUid == null || authenticatedUid.isEmpty) {
        return const MaintainiacFirestoreUploadResult(
          status: MaintainiacFirestoreUploadStatus.disabled,
          attemptedCount: 0,
          uploadedCount: 0,
          failedCount: 0,
          reason: 'Sign in before cloud backup can continue.',
        );
      }
    }
    final batch = _queue.nextBatch(
      limit: limit,
      path: path,
      nowUtc: nowUtc,
      isEligible: authenticatedUid == null
          ? null
          : (record) => _belongsToAccount(record, authenticatedUid!),
    );
    if (batch.isEmpty) {
      return const MaintainiacFirestoreUploadResult(
        status: MaintainiacFirestoreUploadStatus.empty,
        attemptedCount: 0,
        uploadedCount: 0,
        failedCount: 0,
      );
    }
    MaintainiacHostedSyncReservation? hostedReservation;
    final hostedReservationProvider = _hostedSyncReservationProvider;
    if (_sink is MaintainiacHostedReservationRequiredSink &&
        hostedReservationProvider == null) {
      return const MaintainiacFirestoreUploadResult(
        status: MaintainiacFirestoreUploadStatus.quotaExceeded,
        attemptedCount: 0,
        uploadedCount: 0,
        failedCount: 0,
        reason: 'Hosted backup authorization is not configured.',
      );
    }
    if (hostedReservationProvider != null) {
      if (attemptId == null ||
          !RegExp(r'^[A-Za-z0-9_.-]{1,160}$').hasMatch(attemptId)) {
        return const MaintainiacFirestoreUploadResult(
          status: MaintainiacFirestoreUploadStatus.quotaExceeded,
          attemptedCount: 0,
          uploadedCount: 0,
          failedCount: 0,
          reason: 'Cloud sync needs a durable attempt identity.',
        );
      }
      try {
        hostedReservation = await hostedReservationProvider(
          attemptId,
          _batchSha256(batch),
        );
      } catch (_) {
        return const MaintainiacFirestoreUploadResult(
          status: MaintainiacFirestoreUploadStatus.quotaExceeded,
          attemptedCount: 0,
          uploadedCount: 0,
          failedCount: 0,
          reason: 'Cloud sync allowance could not be reserved.',
        );
      }
    }
    int? freeSyncsUsed;
    if (hostedReservation == null) {
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
      try {
        await _freeSyncAttemptRecorder?.call(
          (nowUtc ?? DateTime.now().toUtc()).toUtc(),
        );
      } catch (_) {
        return const MaintainiacFirestoreUploadResult(
          status: MaintainiacFirestoreUploadStatus.quotaExceeded,
          attemptedCount: 0,
          uploadedCount: 0,
          failedCount: 0,
          reason: 'Free backup sync attempt could not be recorded locally.',
        );
      }
    }

    var uploadedCount = 0;
    var failedCount = 0;
    var conflictedCount = 0;
    final uploadedIds = <String>[];
    final batchSink = _sink is MaintainiacFirestoreBatchDocumentSink
        ? _sink as MaintainiacFirestoreBatchDocumentSink
        : null;
    if (batchSink != null) {
      try {
        await batchSink.writeDocuments([
          for (final record in batch)
            MaintainiacFirestoreDocumentDraft(
              path: record.path,
              data: Map<String, Object?>.unmodifiable(record.data),
            ),
        ]);
        uploadedIds.addAll(batch.map((record) => record.id));
        uploadedCount = batch.length;
      } on MaintainiacFirestoreRevisionConflict catch (error) {
        final conflicted = batch
            .where((record) => record.path == error.path)
            .toList(growable: false);
        for (final record in conflicted) {
          conflictedCount += 1;
          await _queue.markConflicted(
            record,
            error: error.toString(),
            nowUtc: nowUtc,
          );
        }
        if (conflicted.isEmpty) {
          for (final record in batch) {
            failedCount += 1;
            await _queue.markAttempted(
              record,
              error:
                  'Cloud revision conflict identity did not match the batch.',
              nowUtc: nowUtc,
            );
          }
        }
      } catch (error) {
        for (final record in batch) {
          failedCount += 1;
          await _queue.markAttempted(
            record,
            error: error.toString(),
            nowUtc: nowUtc,
          );
        }
      }
    } else {
      for (final record in batch) {
        try {
          MaintainiacFirestoreUploadPolicy.validateDraft(
            MaintainiacFirestoreDocumentDraft(
              path: record.path,
              data: record.data,
            ),
          );
          await _sink.writeDocument(
            path: record.path,
            data: Map<String, Object?>.unmodifiable(record.data),
          );
          uploadedIds.add(record.id);
          uploadedCount += 1;
        } on MaintainiacFirestoreRevisionConflict catch (error) {
          conflictedCount += 1;
          await _queue.markConflicted(
            record,
            error: error.toString(),
            nowUtc: nowUtc,
          );
        } catch (error) {
          failedCount += 1;
          await _queue.markAttempted(
            record,
            error: error.toString(),
            nowUtc: nowUtc,
          );
        }
      }
    }
    final acknowledgedAt = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    final uploadedRecords = batch
        .where((record) => uploadedIds.contains(record.id))
        .toList(growable: false);
    final uploadAcknowledgment = _uploadAcknowledgment;
    if (uploadedRecords.isNotEmpty && uploadAcknowledgment != null) {
      try {
        await uploadAcknowledgment(uploadedRecords, acknowledgedAt);
      } catch (_) {
        for (final record in uploadedRecords) {
          await _queue.markAttempted(
            record,
            error: 'Cloud write succeeded but its local checkpoint failed.',
            nowUtc: acknowledgedAt,
          );
        }
        failedCount += uploadedRecords.length;
        uploadedCount -= uploadedRecords.length;
        uploadedIds.clear();
      }
    }
    await _queue.markUploaded(uploadedIds, nowUtc: acknowledgedAt);
    // Original local records remain authoritative. This queue copy is removed
    // only after cloud acknowledgement has itself been saved durably.
    if (uploadedIds.isNotEmpty) await _queue.clearUploaded();

    final status = conflictedCount > 0 && failedCount == 0 && uploadedCount == 0
        ? MaintainiacFirestoreUploadStatus.conflict
        : failedCount == 0 && conflictedCount == 0
        ? MaintainiacFirestoreUploadStatus.uploaded
        : uploadedCount == 0
        ? MaintainiacFirestoreUploadStatus.failed
        : MaintainiacFirestoreUploadStatus.partial;
    return MaintainiacFirestoreUploadResult(
      status: status,
      attemptedCount: batch.length,
      uploadedCount: uploadedCount,
      failedCount: failedCount,
      conflictedCount: conflictedCount,
      reason: conflictedCount > 0
          ? 'A newer cloud record needs conflict review before backup can continue.'
          : null,
      reservationId: hostedReservation?.id,
    );
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final next = _firestoreUploadTail.then((_) => operation());
    _firestoreUploadTail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  bool _belongsToAccount(
    MaintainiacFirestoreQueuedDocument record,
    String authenticatedUid,
  ) {
    try {
      MaintainiacFirestoreScopePolicy.validateWrite(
        path: record.path,
        data: record.data,
        authenticatedUid: authenticatedUid,
      );
      return true;
    } on MaintainiacFirestoreScopeMismatch {
      return false;
    }
  }

  String _batchSha256(List<MaintainiacFirestoreQueuedDocument> batch) {
    final canonical = [
      for (final record in batch)
        {'path': record.path, 'data': _canonicalSyncValue(record.data)},
    ];
    return sha256.convert(utf8.encode(jsonEncode(canonical))).toString();
  }
}

Object? _canonicalSyncValue(Object? value) {
  if (value == null || value is bool || value is String || value is int) {
    return value;
  }
  if (value is num && value.isFinite) return value;
  if (value is DateTime) return value.toUtc().toIso8601String();
  if (value is List) {
    return value.map(_canonicalSyncValue).toList(growable: false);
  }
  if (value is Map) {
    if (value.keys.any((key) => key is! String)) {
      throw const FormatException('Cloud sync batch has a non-text field.');
    }
    final keys = value.keys.cast<String>().toList()..sort();
    return {for (final key in keys) key: _canonicalSyncValue(value[key])};
  }
  throw const FormatException('Cloud sync batch contains unsupported data.');
}
