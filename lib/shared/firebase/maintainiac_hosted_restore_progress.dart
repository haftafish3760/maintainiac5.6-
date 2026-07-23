import '../records/maintainiac_cloud_restore_runner.dart';
import '../records/maintainiac_restore_contract.dart';
import '../records/maintainiac_restore_session_store.dart';
import 'maintainiac_restore_credential_vault.dart';
import 'maintainiac_restore_session_client.dart';

class MaintainiacHostedRestoreProgress
    implements MaintainiacRestoreProgressSink {
  MaintainiacHostedRestoreProgress({
    required MaintainiacRestoreSessionClient client,
    required MaintainiacRestoreCredentialStore credentials,
    DateTime Function()? nowUtc,
  }) : _client = client,
       _credentials = credentials,
       _nowUtc = nowUtc ?? (() => DateTime.now().toUtc());

  final MaintainiacRestoreSessionClient _client;
  final MaintainiacRestoreCredentialStore _credentials;
  final DateTime Function() _nowUtc;

  @override
  Future<void> reconcile(MaintainiacRestoreSession session) async {
    var issued = await _credentials.load(session.authorizationId);
    if (issued == null) {
      if (session.state.isTerminal) return;
      throw StateError('Restore authorization is unavailable.');
    }
    if (!_nowUtc().toUtc().isBefore(issued.expiresAtUtc)) {
      issued = await _client.refresh(issued.authorization);
      await _credentials.save(session.authorizationId, issued);
    }
    if (issued.recordCount != session.totalItems ||
        issued.structuredBytes != session.transferBytes) {
      throw StateError('Restore authorization no longer matches the plan.');
    }
    if (session.state == MaintainiacRestoreSessionState.prepared) return;

    if (session.state == MaintainiacRestoreSessionState.running ||
        session.state == MaintainiacRestoreSessionState.paused ||
        session.state == MaintainiacRestoreSessionState.failed) {
      final begun = await _client.begin(issued.authorization);
      _requireProgress(
        begun,
        session,
        expectedSessionId: issued.authorization.sessionId,
        expectedStatus: 'active',
        allowRemoteBehind: true,
      );
    }

    final action = switch (session.state) {
      MaintainiacRestoreSessionState.running =>
        MaintainiacHostedRestoreAction.progress,
      MaintainiacRestoreSessionState.paused ||
      MaintainiacRestoreSessionState.failed =>
        MaintainiacHostedRestoreAction.pause,
      MaintainiacRestoreSessionState.cancelled =>
        MaintainiacHostedRestoreAction.cancel,
      MaintainiacRestoreSessionState.completed =>
        MaintainiacHostedRestoreAction.complete,
      MaintainiacRestoreSessionState.prepared => null,
    };
    if (action == null) return;
    final hosted = await _client.update(
      authorization: issued.authorization,
      action: action,
      completedItems: session.completedItems,
      completedBytes: session.completedBytes,
    );
    _requireProgress(
      hosted,
      session,
      expectedSessionId: issued.authorization.sessionId,
      expectedStatus: switch (action) {
        MaintainiacHostedRestoreAction.progress => 'active',
        MaintainiacHostedRestoreAction.pause => 'paused',
        MaintainiacHostedRestoreAction.cancel => 'cancelled',
        MaintainiacHostedRestoreAction.complete => 'completed',
      },
    );
    if (session.state.isTerminal) {
      await _credentials.delete(session.authorizationId);
    }
  }
}

void _requireProgress(
  MaintainiacHostedRestoreSession hosted,
  MaintainiacRestoreSession local, {
  required String expectedSessionId,
  required String expectedStatus,
  bool allowRemoteBehind = false,
}) {
  final itemMismatch = allowRemoteBehind
      ? hosted.completedItems > local.completedItems
      : hosted.completedItems != local.completedItems;
  final byteMismatch = allowRemoteBehind
      ? hosted.completedBytes > local.completedBytes
      : hosted.completedBytes != local.completedBytes;
  if (hosted.sessionId != expectedSessionId ||
      hosted.status != expectedStatus ||
      itemMismatch ||
      byteMismatch) {
    throw StateError('Hosted restore progress conflicts with local recovery.');
  }
}
