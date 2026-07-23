import '../firebase/maintainiac_durable_cloud_restore_gateway.dart';
import 'maintainiac_restore_batch_processor.dart';
import 'maintainiac_restore_contract.dart';
import 'maintainiac_restore_session_store.dart';

class MaintainiacCloudRestoreStep {
  const MaintainiacCloudRestoreStep({
    required this.session,
    required this.batchStatus,
    required this.completed,
  });

  final MaintainiacRestoreSession session;
  final MaintainiacRestoreBatchStatus batchStatus;
  final bool completed;
}

abstract interface class MaintainiacRestoreProgressSink {
  Future<void> reconcile(MaintainiacRestoreSession session);
}

class MaintainiacCloudRestoreRunner {
  const MaintainiacCloudRestoreRunner({
    required MaintainiacDurableCloudRestoreGateway gateway,
    required MaintainiacRestoreBatchProcessor batches,
    required MaintainiacRestoreSessionStore sessions,
    MaintainiacRestoreProgressSink? progressSink,
  }) : _gateway = gateway,
       _batches = batches,
       _sessions = sessions,
       _progressSink = progressSink;

  final MaintainiacDurableCloudRestoreGateway _gateway;
  final MaintainiacRestoreBatchProcessor _batches;
  final MaintainiacRestoreSessionStore _sessions;
  final MaintainiacRestoreProgressSink? _progressSink;

  Future<MaintainiacCloudRestoreStep> processNextPage({
    required String organizationId,
    required String sessionId,
    int pageSize = MaintainiacDurableCloudRestoreGateway.defaultPageSize,
    DateTime? nowUtc,
  }) async {
    final session = _sessions.sessionById(sessionId);
    if (session == null) {
      throw StateError('Restore session is not ready to continue.');
    }
    await _progressSink?.reconcile(session);
    if (session.state == MaintainiacRestoreSessionState.completed) {
      return MaintainiacCloudRestoreStep(
        session: session,
        batchStatus: MaintainiacRestoreBatchStatus.applied,
        completed: true,
      );
    }
    if (session.state != MaintainiacRestoreSessionState.running) {
      throw StateError('Restore session is not ready to continue.');
    }
    final page = await _gateway.fetchPage(
      organizationId: organizationId,
      pageSize: pageSize,
      afterRecordKey: session.cursor,
    );
    if (page.items.isEmpty || page.lastRecordKey == null) {
      final failed = await _sessions.fail(
        session.id,
        'Cloud restore ended before the authorized plan was complete.',
        expectedRevision: session.revision,
        nowUtc: nowUtc,
      );
      return MaintainiacCloudRestoreStep(
        session: failed,
        batchStatus: MaintainiacRestoreBatchStatus.blocked,
        completed: false,
      );
    }
    final batch = await _batches.process(
      sessionId: session.id,
      expectedSessionRevision: session.revision,
      nextCursor: page.lastRecordKey!,
      items: [
        for (final item in page.items)
          MaintainiacRestoreBatchItem(
            envelope: item.envelope,
            transferBytes: item.transferBytes,
          ),
      ],
      nowUtc: nowUtc,
    );
    if (batch.status != MaintainiacRestoreBatchStatus.applied) {
      return MaintainiacCloudRestoreStep(
        session: batch.session,
        batchStatus: batch.status,
        completed: false,
      );
    }
    final shouldComplete =
        !page.hasMore &&
        batch.session.completedItems == batch.session.totalItems &&
        batch.session.completedBytes == batch.session.transferBytes;
    final result = shouldComplete
        ? await _sessions.complete(batch.session.id, nowUtc: nowUtc)
        : batch.session;
    await _progressSink?.reconcile(result);
    return MaintainiacCloudRestoreStep(
      session: result,
      batchStatus: batch.status,
      completed: shouldComplete,
    );
  }
}
