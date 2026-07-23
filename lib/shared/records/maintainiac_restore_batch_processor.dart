import 'maintainiac_restore_applier.dart';
import 'maintainiac_restore_contract.dart';
import 'maintainiac_restore_session_store.dart';

class MaintainiacRestoreBatchItem {
  const MaintainiacRestoreBatchItem({
    required this.envelope,
    required this.transferBytes,
  });

  final MaintainiacRestoreEnvelope envelope;
  final int transferBytes;
}

enum MaintainiacRestoreBatchStatus { applied, blocked, stale }

class MaintainiacRestoreBatchResult {
  const MaintainiacRestoreBatchResult({
    required this.status,
    required this.session,
    required this.dispositions,
  });

  final MaintainiacRestoreBatchStatus status;
  final MaintainiacRestoreSession session;
  final List<MaintainiacRestoreDisposition> dispositions;
}

class MaintainiacRestoreBatchProcessor {
  const MaintainiacRestoreBatchProcessor({
    required MaintainiacRestoreSessionStore sessions,
    required MaintainiacRestoreApplier applier,
  }) : _sessions = sessions,
       _applier = applier;

  final MaintainiacRestoreSessionStore _sessions;
  final MaintainiacRestoreApplier _applier;
  static const int maximumBatchItems = 9;
  static const int maximumBatchBytes = 768 * 1024;

  Future<MaintainiacRestoreBatchResult> process({
    required String sessionId,
    required int expectedSessionRevision,
    required String nextCursor,
    required List<MaintainiacRestoreBatchItem> items,
    DateTime? nowUtc,
  }) async {
    final session = _sessions.sessionById(sessionId);
    final recordIdentities = items
        .map(
          (item) =>
              '${item.envelope.record.module}\u0000'
              '${item.envelope.record.id}',
        )
        .toSet();
    if (session == null ||
        session.state != MaintainiacRestoreSessionState.running ||
        session.revision != expectedSessionRevision ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(nextCursor) ||
        items.isEmpty ||
        items.length > maximumBatchItems ||
        recordIdentities.length != items.length ||
        items.any(
          (item) =>
              item.transferBytes <= 0 ||
              item.envelope.accountScopeId != session.accountScopeId,
        )) {
      throw StateError('Restore batch is invalid or no longer current.');
    }
    final pageBytes = items.fold<int>(
      0,
      (total, item) => total + item.transferBytes,
    );
    if (pageBytes > maximumBatchBytes ||
        session.completedItems + items.length > session.totalItems ||
        session.completedBytes + pageBytes > session.transferBytes) {
      throw StateError('Restore batch exceeds the authorized session plan.');
    }

    final dispositions = <MaintainiacRestoreDisposition>[];
    for (final item in items) {
      final result = await _applier.apply(item.envelope);
      dispositions.add(result.disposition);
      if (result.disposition == MaintainiacRestoreDisposition.conflict ||
          result.disposition == MaintainiacRestoreDisposition.rejectCorrupt) {
        try {
          final failed = await _sessions.fail(
            sessionId,
            'Restore stopped for record review.',
            expectedRevision: expectedSessionRevision,
            nowUtc: nowUtc,
          );
          return MaintainiacRestoreBatchResult(
            status: MaintainiacRestoreBatchStatus.blocked,
            session: failed,
            dispositions: List.unmodifiable(dispositions),
          );
        } on StateError {
          return MaintainiacRestoreBatchResult(
            status: MaintainiacRestoreBatchStatus.stale,
            session: _sessions.sessionById(sessionId)!,
            dispositions: List.unmodifiable(dispositions),
          );
        }
      }
    }

    try {
      final updated = await _sessions.updateProgress(
        id: sessionId,
        completedItems: session.completedItems + items.length,
        completedBytes: session.completedBytes + pageBytes,
        cursor: nextCursor,
        expectedRevision: expectedSessionRevision,
        nowUtc: nowUtc,
      );
      return MaintainiacRestoreBatchResult(
        status: MaintainiacRestoreBatchStatus.applied,
        session: updated,
        dispositions: List.unmodifiable(dispositions),
      );
    } on StateError {
      final current = _sessions.sessionById(sessionId)!;
      return MaintainiacRestoreBatchResult(
        status: MaintainiacRestoreBatchStatus.stale,
        session: current,
        dispositions: List.unmodifiable(dispositions),
      );
    }
  }
}
