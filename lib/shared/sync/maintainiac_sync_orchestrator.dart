import '../firebase/maintainiac_firestore_upload_queue.dart';
import 'maintainiac_sync_checkpoint_store.dart';
import 'maintainiac_sync_settings.dart';
import 'maintainiac_sync_settings_store.dart';

typedef MaintainiacPendingSyncUploader =
    Future<MaintainiacFirestoreUploadResult> Function({
      int? limit,
      String? path,
      DateTime? nowUtc,
    });

enum MaintainiacDurableSyncOutcome { blocked, inProgress, succeeded, failed }

class MaintainiacDurableSyncRequest {
  const MaintainiacDurableSyncRequest({
    required this.module,
    required this.attemptId,
    required this.trigger,
    required this.network,
    required this.isRoaming,
    required this.batterySaverEnabled,
    required this.immediateSyncAllowed,
    required this.localNow,
    this.limit,
    this.path,
  });

  final String module;
  final String attemptId;
  final MaintainiacSyncTrigger trigger;
  final MaintainiacSyncNetwork network;
  final bool isRoaming;
  final bool batterySaverEnabled;
  final bool immediateSyncAllowed;
  final DateTime localNow;
  final int? limit;
  final String? path;
}

class MaintainiacDurableSyncResult {
  const MaintainiacDurableSyncResult({
    required this.outcome,
    required this.decision,
    required this.checkpoint,
    this.upload,
  });

  final MaintainiacDurableSyncOutcome outcome;
  final MaintainiacSyncDecision decision;
  final MaintainiacSyncCheckpoint checkpoint;
  final MaintainiacFirestoreUploadResult? upload;
}

/// One module-neutral lifecycle for user-authorized backup attempts.
///
/// Feature modules enqueue durable documents and call this coordinator. They do
/// not own network policy, attempt recovery, hosted-plan accounting, or cloud
/// write semantics.
class MaintainiacDurableSyncOrchestrator {
  MaintainiacDurableSyncOrchestrator({
    required MaintainiacSyncSettingsStore settingsStore,
    required MaintainiacSyncCheckpointStore checkpointStore,
    required MaintainiacPendingSyncUploader uploadPending,
  }) : _settingsStore = settingsStore,
       _checkpointStore = checkpointStore,
       _uploadPending = uploadPending;

  final MaintainiacSyncSettingsStore _settingsStore;
  final MaintainiacSyncCheckpointStore _checkpointStore;
  final MaintainiacPendingSyncUploader _uploadPending;
  Future<void> _tail = Future<void>.value();

  Future<MaintainiacDurableSyncResult> run(
    MaintainiacDurableSyncRequest request,
  ) => _enqueue(() => _run(request));

  Future<MaintainiacSyncCheckpoint> recoverInterrupted(
    String module, {
    DateTime? nowUtc,
  }) => _enqueue(
    () => _checkpointStore.recoverInterrupted(module, nowUtc: nowUtc),
  );

  Future<MaintainiacDurableSyncResult> _run(
    MaintainiacDurableSyncRequest request,
  ) async {
    final snapshot = _settingsStore.snapshotFor(request.module);
    final previous = _checkpointStore.checkpointFor(request.module);
    final decision = snapshot.settings.decide(
      trigger: request.trigger,
      network: request.network,
      isRoaming: request.isRoaming,
      batterySaverEnabled: request.batterySaverEnabled,
      immediateSyncAllowed: request.immediateSyncAllowed,
      localNow: request.localNow,
      lastAttemptLocal: previous.lastAttemptAtUtc?.toLocal(),
      authorizationBeganLocal: snapshot.updatedAtUtc.toLocal(),
    );
    if (decision != MaintainiacSyncDecision.allowed) {
      return MaintainiacDurableSyncResult(
        outcome: MaintainiacDurableSyncOutcome.blocked,
        decision: decision,
        checkpoint: previous,
      );
    }
    if (previous.state == MaintainiacSyncAttemptState.running &&
        previous.activeAttemptId != request.attemptId) {
      return MaintainiacDurableSyncResult(
        outcome: MaintainiacDurableSyncOutcome.inProgress,
        decision: decision,
        checkpoint: previous,
      );
    }

    final nowUtc = request.localNow.toUtc();
    await _checkpointStore.begin(
      module: request.module,
      attemptId: request.attemptId,
      trigger: request.trigger,
      nowUtc: nowUtc,
    );
    MaintainiacFirestoreUploadResult upload;
    try {
      upload = await _uploadPending(
        limit: request.limit,
        path: request.path,
        nowUtc: nowUtc,
      );
    } catch (error) {
      upload = MaintainiacFirestoreUploadResult(
        status: MaintainiacFirestoreUploadStatus.failed,
        attemptedCount: 0,
        uploadedCount: 0,
        failedCount: 0,
        reason: _safeError(error),
      );
    }

    final succeeded =
        upload.status == MaintainiacFirestoreUploadStatus.uploaded ||
        upload.status == MaintainiacFirestoreUploadStatus.empty;
    final checkpoint = await _checkpointStore.finish(
      module: request.module,
      attemptId: request.attemptId,
      state: succeeded
          ? MaintainiacSyncAttemptState.succeeded
          : MaintainiacSyncAttemptState.failed,
      reservationId: upload.reservationId,
      error: succeeded ? null : _uploadFailure(upload),
      nowUtc: DateTime.now().toUtc(),
    );
    return MaintainiacDurableSyncResult(
      outcome: succeeded
          ? MaintainiacDurableSyncOutcome.succeeded
          : MaintainiacDurableSyncOutcome.failed,
      decision: decision,
      checkpoint: checkpoint,
      upload: upload,
    );
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final next = _tail.then((_) => operation());
    _tail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }
}

String _uploadFailure(MaintainiacFirestoreUploadResult result) {
  final reason = result.reason?.trim();
  if (reason != null && reason.isNotEmpty) return _bounded(reason);
  return _bounded('Cloud sync ended with ${result.status.name}.');
}

String _safeError(Object error) => _bounded('Cloud sync failed: $error');

String _bounded(String value) =>
    value.length <= 500 ? value : value.substring(0, 500);
