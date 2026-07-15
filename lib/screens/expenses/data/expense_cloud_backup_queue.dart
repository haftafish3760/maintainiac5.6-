import '../../../shared/firebase/maintainiac_firestore_upload_queue.dart';
import '../../../shared/state/expense_settings_store.dart';
import 'expense_firestore_documents.dart';
import 'expense_ledger_models.dart';
import 'expense_ledger_store.dart';
import 'expense_job_store.dart';
import 'expense_reminder_store.dart';
import 'expense_work_profile_store.dart';
import 'expense_vehicle_profile_store.dart';
import 'expense_receipt_deletion_store.dart';

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

  Future<void> queueReceiptDeletion({
    required ExpenseCloudBackupIdentity identity,
    required ExpenseReceiptDeletionRecord deletion,
  }) async {
    _requireIdentity(identity);
    await _queue.enqueueReplacingPendingForPath(
      ExpenseFirestoreDocumentBuilder.expenseReceiptTombstoneDocument(
        orgId: identity.orgId,
        uid: identity.uid,
        deviceId: identity.deviceId,
        deletion: deletion,
      ),
      queuedAtUtc: deletion.deletedAt,
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

  Future<void> queueReminders({
    required ExpenseCloudBackupIdentity identity,
    required ExpenseReminderController reminders,
    DateTime? nowUtc,
  }) async {
    _requireIdentity(identity);
    await _queue.enqueueReplacingPendingForPath(
      ExpenseFirestoreDocumentBuilder.expenseRemindersDocument(
        orgId: identity.orgId,
        uid: identity.uid,
        deviceId: identity.deviceId,
        reminders: reminders,
        nowUtc: nowUtc,
      ),
      queuedAtUtc: nowUtc,
    );
  }

  Future<void> queueJobs({
    required ExpenseCloudBackupIdentity identity,
    required ExpenseJobController jobs,
    DateTime? nowUtc,
  }) async {
    _requireIdentity(identity);
    await _queue.enqueueReplacingPendingForPath(
      ExpenseFirestoreDocumentBuilder.expenseJobsDocument(
        orgId: identity.orgId,
        uid: identity.uid,
        deviceId: identity.deviceId,
        jobs: jobs,
        nowUtc: nowUtc,
      ),
      queuedAtUtc: nowUtc,
    );
  }

  Future<void> queueWorkProfiles({
    required ExpenseCloudBackupIdentity identity,
    required ExpenseWorkProfileController profiles,
    DateTime? nowUtc,
  }) async {
    _requireIdentity(identity);
    await _queue.enqueueReplacingPendingForPath(
      ExpenseFirestoreDocumentBuilder.expenseWorkProfilesDocument(
        orgId: identity.orgId,
        uid: identity.uid,
        deviceId: identity.deviceId,
        profiles: profiles,
        nowUtc: nowUtc,
      ),
      queuedAtUtc: nowUtc,
    );
  }

  Future<void> queueVehicleProfiles({
    required ExpenseCloudBackupIdentity identity,
    required ExpenseVehicleProfileController profiles,
    DateTime? nowUtc,
  }) async {
    _requireIdentity(identity);
    await _queue.enqueueReplacingPendingForPath(
      ExpenseFirestoreDocumentBuilder.expenseVehicleProfilesDocument(
        orgId: identity.orgId,
        uid: identity.uid,
        deviceId: identity.deviceId,
        profiles: profiles,
        nowUtc: nowUtc,
      ),
      queuedAtUtc: nowUtc,
    );
  }

  /// Queues a complete, local-first Expense snapshot after account identity is
  /// available. The caller still chooses when transport is allowed.
  Future<void> queueLocalSnapshot({
    required ExpenseCloudBackupIdentity identity,
    required ExpenseLedgerController ledger,
    required ExpenseSettingsController settings,
    required ExpenseReminderController reminders,
    required ExpenseJobController jobs,
    required ExpenseWorkProfileController workProfiles,
    required ExpenseVehicleProfileController vehicleProfiles,
    required ExpenseReceiptDeletionController deletions,
    DateTime? nowUtc,
  }) async {
    _requireIdentity(identity);
    for (final receipt in ledger.storedReceipts) {
      await queueReceipt(identity: identity, receipt: receipt, nowUtc: nowUtc);
    }
    final localReceiptIds = ledger.storedReceipts
        .map((receipt) => receipt.id)
        .toSet();
    for (final deletion in deletions.pendingTombstones) {
      if (localReceiptIds.contains(deletion.receiptId)) continue;
      await queueReceiptDeletion(identity: identity, deletion: deletion);
    }
    await queueSettings(identity: identity, settings: settings, nowUtc: nowUtc);
    await queueReminders(
      identity: identity,
      reminders: reminders,
      nowUtc: nowUtc,
    );
    await queueJobs(identity: identity, jobs: jobs, nowUtc: nowUtc);
    await queueWorkProfiles(
      identity: identity,
      profiles: workProfiles,
      nowUtc: nowUtc,
    );
    await queueVehicleProfiles(
      identity: identity,
      profiles: vehicleProfiles,
      nowUtc: nowUtc,
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
