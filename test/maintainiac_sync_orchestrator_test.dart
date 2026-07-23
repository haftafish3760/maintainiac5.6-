import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  late MaintainiacSyncSettingsStore settings;
  late MaintainiacSyncCheckpointStore checkpoints;

  setUp(() {
    settings = MaintainiacSyncSettingsStore.memory();
    checkpoints = MaintainiacSyncCheckpointStore.memory();
  });

  test(
    'disabled backup never starts an attempt or calls the uploader',
    () async {
      var uploads = 0;
      final orchestrator = MaintainiacDurableSyncOrchestrator(
        settingsStore: settings,
        checkpointStore: checkpoints,
        uploadPending: ({limit, path, nowUtc, attemptId}) async {
          uploads += 1;
          return _upload(MaintainiacFirestoreUploadStatus.uploaded);
        },
      );
      final result = await orchestrator.run(_request('attempt-1'));
      expect(result.outcome, MaintainiacDurableSyncOutcome.blocked);
      expect(result.decision, MaintainiacSyncDecision.disabled);
      expect(result.checkpoint.revision, 0);
      expect(uploads, 0);
    },
  );

  test(
    'successful upload is enclosed by durable attempt checkpoints',
    () async {
      await _enable(settings);
      MaintainiacSyncCheckpoint? checkpointDuringUpload;
      String? uploadAttemptId;
      final orchestrator = MaintainiacDurableSyncOrchestrator(
        settingsStore: settings,
        checkpointStore: checkpoints,
        uploadPending: ({limit, path, nowUtc, attemptId}) async {
          checkpointDuringUpload = checkpoints.checkpointFor('expenses');
          uploadAttemptId = attemptId;
          return _upload(
            MaintainiacFirestoreUploadStatus.uploaded,
            reservationId: 'reservation-1',
          );
        },
      );
      final result = await orchestrator.run(_request('attempt-1'));
      expect(
        checkpointDuringUpload?.state,
        MaintainiacSyncAttemptState.running,
      );
      expect(uploadAttemptId, 'attempt-1');
      expect(result.outcome, MaintainiacDurableSyncOutcome.succeeded);
      expect(result.checkpoint.state, MaintainiacSyncAttemptState.succeeded);
      expect(result.checkpoint.reservationId, 'reservation-1');
      expect(result.checkpoint.lastSuccessfulAtUtc, isNotNull);
    },
  );

  test('uploader exception becomes durable failure without escaping', () async {
    await _enable(settings);
    final orchestrator = MaintainiacDurableSyncOrchestrator(
      settingsStore: settings,
      checkpointStore: checkpoints,
      uploadPending: ({limit, path, nowUtc, attemptId}) async {
        throw StateError('offline');
      },
    );
    final result = await orchestrator.run(_request('attempt-1'));
    expect(result.outcome, MaintainiacDurableSyncOutcome.failed);
    expect(result.upload?.status, MaintainiacFirestoreUploadStatus.failed);
    expect(result.checkpoint.state, MaintainiacSyncAttemptState.failed);
    expect(result.checkpoint.lastError, contains('offline'));
  });

  test('a different active attempt is reported without overlapping', () async {
    await _enable(settings);
    await checkpoints.begin(
      module: 'expenses',
      attemptId: 'interrupted-attempt',
      trigger: MaintainiacSyncTrigger.background,
    );
    var uploads = 0;
    final orchestrator = MaintainiacDurableSyncOrchestrator(
      settingsStore: settings,
      checkpointStore: checkpoints,
      uploadPending: ({limit, path, nowUtc, attemptId}) async {
        uploads += 1;
        return _upload(MaintainiacFirestoreUploadStatus.uploaded);
      },
    );
    final result = await orchestrator.run(_request('new-attempt'));
    expect(result.outcome, MaintainiacDurableSyncOutcome.inProgress);
    expect(result.checkpoint.activeAttemptId, 'interrupted-attempt');
    expect(uploads, 0);
  });

  test('partial upload is failed and keeps its reservation evidence', () async {
    await _enable(settings);
    final orchestrator = MaintainiacDurableSyncOrchestrator(
      settingsStore: settings,
      checkpointStore: checkpoints,
      uploadPending: ({limit, path, nowUtc, attemptId}) async =>
          MaintainiacFirestoreUploadResult(
            status: MaintainiacFirestoreUploadStatus.partial,
            attemptedCount: 2,
            uploadedCount: 1,
            failedCount: 1,
            reason: 'One record remains queued.',
            reservationId: 'reservation-2',
          ),
    );
    final result = await orchestrator.run(_request('attempt-1'));
    expect(result.outcome, MaintainiacDurableSyncOutcome.failed);
    expect(result.checkpoint.reservationId, 'reservation-2');
    expect(result.checkpoint.lastError, 'One record remains queued.');
  });

  test('one authorized attempt drains bounded batches with one id', () async {
    await _enable(settings);
    final attemptIds = <String?>[];
    var remaining = 3;
    final orchestrator = MaintainiacDurableSyncOrchestrator(
      settingsStore: settings,
      checkpointStore: checkpoints,
      uploadPending: ({limit, path, nowUtc, attemptId}) async {
        attemptIds.add(attemptId);
        remaining -= 1;
        return MaintainiacFirestoreUploadResult(
          status: MaintainiacFirestoreUploadStatus.uploaded,
          attemptedCount: 1,
          uploadedCount: 1,
          failedCount: 0,
          remainingPendingCount: remaining,
          hasMoreEligible: remaining > 0,
          reservationId: 'reservation-1',
        );
      },
    );
    final result = await orchestrator.run(_request('attempt-1'));
    expect(attemptIds, ['attempt-1', 'attempt-1', 'attempt-1']);
    expect(result.outcome, MaintainiacDurableSyncOutcome.succeeded);
    expect(result.upload?.attemptedCount, 3);
    expect(result.upload?.uploadedCount, 3);
    expect(result.upload?.remainingPendingCount, 0);
    expect(result.checkpoint.revision, 2);
  });

  test(
    'delayed queued work is preserved without a futile upload loop',
    () async {
      await _enable(settings);
      var uploads = 0;
      final orchestrator = MaintainiacDurableSyncOrchestrator(
        settingsStore: settings,
        checkpointStore: checkpoints,
        uploadPending: ({limit, path, nowUtc, attemptId}) async {
          uploads += 1;
          return const MaintainiacFirestoreUploadResult(
            status: MaintainiacFirestoreUploadStatus.uploaded,
            attemptedCount: 1,
            uploadedCount: 1,
            failedCount: 0,
            remainingPendingCount: 1,
            hasMoreEligible: false,
          );
        },
      );

      final result = await orchestrator.run(_request('attempt-1'));

      expect(uploads, 1);
      expect(result.outcome, MaintainiacDurableSyncOutcome.succeeded);
      expect(result.upload?.remainingPendingCount, 1);
      expect(result.upload?.hasMoreEligible, isFalse);
    },
  );

  test('safe batch bound leaves remaining work durably failed', () async {
    await _enable(settings);
    var uploads = 0;
    final orchestrator = MaintainiacDurableSyncOrchestrator(
      settingsStore: settings,
      checkpointStore: checkpoints,
      uploadPending: ({limit, path, nowUtc, attemptId}) async {
        uploads += 1;
        return const MaintainiacFirestoreUploadResult(
          status: MaintainiacFirestoreUploadStatus.uploaded,
          attemptedCount: 1,
          uploadedCount: 1,
          failedCount: 0,
          remainingPendingCount: 1,
          hasMoreEligible: true,
        );
      },
    );
    final result = await orchestrator.run(
      MaintainiacDurableSyncRequest(
        module: 'expenses',
        attemptId: 'attempt-1',
        trigger: MaintainiacSyncTrigger.manual,
        network: MaintainiacSyncNetwork.wifi,
        isRoaming: false,
        batterySaverEnabled: false,
        immediateSyncAllowed: true,
        localNow: DateTime(2026, 7, 22, 12),
        maximumBatches: 2,
      ),
    );
    expect(uploads, 2);
    expect(result.outcome, MaintainiacDurableSyncOutcome.failed);
    expect(result.upload?.status, MaintainiacFirestoreUploadStatus.partial);
    expect(result.upload?.uploadedCount, 2);
    expect(
      result.checkpoint.lastError,
      contains('safe per-attempt batch limit'),
    );
  });

  test('serialized runs cannot overlap upload attempts', () async {
    await _enable(settings);
    var active = 0;
    var maximumActive = 0;
    final orchestrator = MaintainiacDurableSyncOrchestrator(
      settingsStore: settings,
      checkpointStore: checkpoints,
      uploadPending: ({limit, path, nowUtc, attemptId}) async {
        active += 1;
        if (active > maximumActive) maximumActive = active;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        active -= 1;
        return _upload(MaintainiacFirestoreUploadStatus.uploaded);
      },
    );
    await Future.wait([
      orchestrator.run(_request('attempt-1')),
      orchestrator.run(_request('attempt-2')),
    ]);
    expect(maximumActive, 1);
    expect(checkpoints.checkpointFor('expenses').revision, 4);
  });
}

Future<void> _enable(MaintainiacSyncSettingsStore store) => store.save(
  'expenses',
  MaintainiacSyncSettings(
    mode: MaintainiacSyncMode.automaticProtection,
    transport: MaintainiacSyncTransport.wifiAndCellular,
    localTimesMinutesAfterMidnight: const [],
    allowRoaming: false,
    pauseOnBatterySaver: true,
  ),
);

MaintainiacDurableSyncRequest _request(String attemptId) =>
    MaintainiacDurableSyncRequest(
      module: 'expenses',
      attemptId: attemptId,
      trigger: MaintainiacSyncTrigger.manual,
      network: MaintainiacSyncNetwork.wifi,
      isRoaming: false,
      batterySaverEnabled: false,
      immediateSyncAllowed: true,
      localNow: DateTime(2026, 7, 22, 12),
    );

MaintainiacFirestoreUploadResult _upload(
  MaintainiacFirestoreUploadStatus status, {
  String? reservationId,
}) => MaintainiacFirestoreUploadResult(
  status: status,
  attemptedCount: status == MaintainiacFirestoreUploadStatus.empty ? 0 : 1,
  uploadedCount: status == MaintainiacFirestoreUploadStatus.uploaded ? 1 : 0,
  failedCount: 0,
  reservationId: reservationId,
);
