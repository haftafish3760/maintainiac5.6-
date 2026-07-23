part of 'maintainiac_firestore_upload_queue.dart';

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
    MaintainiacFirestoreFreeSyncAttemptRecorder? freeSyncAttemptRecorder,
    MaintainiacHostedSyncReservationProvider? hostedSyncReservationProvider,
    bool Function()? uploadNetworkAllowed,
    MaintainiacCloudIdentityProvider? identityProvider,
  }) : _queue = queue,
       _sink = sink,
       _uploadEnabled = uploadEnabled,
       _uploadNetworkAllowed = uploadNetworkAllowed,
       _freeSyncAttemptRecorder = freeSyncAttemptRecorder,
       _hostedSyncReservationProvider = hostedSyncReservationProvider,
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
  final int Function()? _freeSyncsUsedInWindowReader;
  final MaintainiacCloudIdentityProvider? _identityProvider;

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
    if (hostedReservationProvider != null) {
      try {
        hostedReservation = await hostedReservationProvider();
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
    await _queue.markUploaded(uploadedIds, nowUtc: nowUtc);
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
}
