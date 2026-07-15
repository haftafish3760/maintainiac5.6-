import '../../../shared/firebase/maintainiac_firestore_upload_queue.dart';
import '../../../shared/state/expense_settings_store.dart';
import 'expense_firestore_documents.dart';
import 'expense_ledger_models.dart';

class ExpenseCloudBackupIdentity {
  const ExpenseCloudBackupIdentity({
    required this.orgId,
    required this.uid,
    required this.deviceId,
  });

  final String orgId;
  final String uid;
  final String deviceId;

  bool get isComplete =>
      orgId.trim().isNotEmpty &&
      uid.trim().isNotEmpty &&
      deviceId.trim().isNotEmpty;
}

/// Local-first queueing for authenticated Expense backups.
///
/// The caller must supply an authenticated organization identity. No anonymous
/// fallback exists: without that identity, data stays safely on device.
class ExpenseCloudBackupQueue {
  ExpenseCloudBackupQueue({required MaintainiacFirestoreUploadQueueStore queue})
    : _queue = queue;

  final MaintainiacFirestoreUploadQueueStore _queue;

  Future<void> queueReceipt({
    required ExpenseCloudBackupIdentity identity,
    required ExpenseReceiptRecord receipt,
    DateTime? nowUtc,
  }) async {
    _requireIdentity(identity);
    await _queue.enqueueReplacingPendingForPath(
      ExpenseFirestoreDocumentBuilder.expenseReceiptDocument(
        orgId: identity.orgId,
        uid: identity.uid,
        deviceId: identity.deviceId,
        receipt: receipt,
        nowUtc: nowUtc,
      ),
      queuedAtUtc: nowUtc,
    );
  }

  Future<void> queueSettings({
    required ExpenseCloudBackupIdentity identity,
    required ExpenseSettingsController settings,
    DateTime? nowUtc,
  }) async {
    _requireIdentity(identity);
    await _queue.enqueueReplacingPendingForPath(
      ExpenseFirestoreDocumentBuilder.expenseSettingsDocument(
        orgId: identity.orgId,
        uid: identity.uid,
        deviceId: identity.deviceId,
        settings: settings,
        nowUtc: nowUtc,
      ),
      queuedAtUtc: nowUtc,
    );
  }

  Future<MaintainiacFirestoreUploadResult> sync({
    required MaintainiacFirestoreDocumentSink sink,
    required bool authenticated,
    required bool networkAllowed,
    int? limit,
    DateTime? nowUtc,
  }) {
    return MaintainiacFirestoreUploadCoordinator(
      queue: _queue,
      sink: sink,
      uploadEnabled: authenticated && networkAllowed,
    ).uploadPending(limit: limit, nowUtc: nowUtc);
  }

  void _requireIdentity(ExpenseCloudBackupIdentity identity) {
    if (!identity.isComplete) {
      throw ArgumentError(
        'An authenticated organization identity is required.',
      );
    }
  }
}
