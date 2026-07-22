import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../shared/firebase/maintainiac_cloud_identity.dart';
import '../../../shared/firebase/maintainiac_organization_bootstrap.dart';
import '../../../shared/firebase/maintainiac_firestore_documents.dart';
import '../../../shared/firebase/maintainiac_firestore_upload_queue.dart';
import '../../../shared/state/expense_settings_store.dart';
import '../../../shared/state/expense_backup_schedule.dart';
import '../../../shared/state/app_state.dart';
import 'expense_backup_draft_guard.dart';
import 'expense_cloud_proof_reference_store.dart';
import 'expense_cloud_proof_storage.dart';
import 'expense_firestore_documents.dart';
import 'expense_ledger_models.dart';
import 'expense_ledger_store.dart';
import 'expense_reminder_store.dart';
import 'expense_work_profile_store.dart';

/// Queues and uploads the authenticated user's Expense records.
///
/// Local Hive records remain the source of truth. This service never attempts
/// backup without an explicit authenticated account, organization, and device
/// identity, and it only flushes paths it created for that identity.
class ExpenseCloudBackupService {
  const ExpenseCloudBackupService({
    required this.ledger,
    required this.settings,
    required this.reminders,
    required this.workProfiles,
    required this.appState,
    required this.queueStore,
    required this.uploadCoordinator,
    required this.proofReferences,
    required this.organizationId,
    required this.authenticatedUid,
    required this.deviceId,
  });

  final ExpenseLedgerController ledger;
  final ExpenseSettingsController settings;
  final ExpenseReminderController reminders;
  final ExpenseWorkProfileController workProfiles;
  final AppStateController appState;
  final MaintainiacFirestoreUploadQueueStore queueStore;
  final MaintainiacFirestoreUploadCoordinator uploadCoordinator;
  final ExpenseCloudProofReferenceStore proofReferences;
  final String? organizationId;
  final String? authenticatedUid;
  final String? deviceId;

  bool get hasTrustedIdentity =>
      _clean(organizationId).isNotEmpty &&
      _clean(authenticatedUid).isNotEmpty &&
      _clean(deviceId).isNotEmpty;

  /// Queues one current local receipt. It never uploads a record that is no
  /// longer present in the local ledger.
  Future<ExpenseCloudBackupResult> backupReceipt(
    String receiptId, {
    DateTime? nowUtc,
  }) async {
    final queued = await queueReceipt(receiptId, nowUtc: nowUtc);
    if (!queued.wasQueued) return queued.toBackupResult();
    final timestamp = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    await settings.recordBackupAttempt(timestamp);
    final result = await flushPaths(
      [queued.documentPath!],
      queuedCount: 1,
      nowUtc: timestamp,
    );
    if (result.completed) {
      await settings.recordSuccessfulBackup(timestamp);
    } else {
      await settings.recordBackupFailure(
        result.reason ?? 'Backup is waiting to retry.',
      );
    }
    return result;
  }

  /// Writes a durable local queue entry before any network operation. This is
  /// used when the account workspace cannot be reached yet, so a later retry
  /// never depends on the original receipt-entry screen still being open.
  Future<ExpenseCloudQueueResult> queueReceipt(
    String receiptId, {
    DateTime? nowUtc,
  }) async {
    final receipt = ledger.receiptById(receiptId);
    if (receipt == null) {
      return const ExpenseCloudQueueResult.localRecordMissing();
    }
    final identity = _identityOrNull;
    if (identity == null) {
      return const ExpenseCloudQueueResult.identityRequired();
    }

    final draft = ExpenseFirestoreDocumentBuilder.expenseReceiptDocument(
      orgId: identity.organizationId,
      uid: identity.uid,
      deviceId: identity.deviceId,
      receipt: receipt,
      nowUtc: nowUtc,
      cloudProofReferences: _cloudProofReferencesFor(receipt, identity),
    );
    final rejection = ExpenseBackupDraftGuard.rejectionFor([draft]);
    if (rejection != null) {
      return ExpenseCloudQueueResult.rejected(rejection);
    }
    await queueStore.enqueueReplacingPendingForPath(
      draft,
      queuedAtUtc: (nowUtc ?? DateTime.now().toUtc()).toUtc(),
    );
    return ExpenseCloudQueueResult.queued(draft.path);
  }

  /// Queues the complete current vehicle directory as one replaceable member
  /// document. This keeps vehicle deletion recoverable without mutating any
  /// historical Expense record.
  Future<ExpenseCloudQueueResult> queueVehicleDirectory({
    DateTime? nowUtc,
  }) async {
    final identity = _identityOrNull;
    if (identity == null) {
      return const ExpenseCloudQueueResult.identityRequired();
    }
    final timestamp = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    final draft =
        ExpenseFirestoreDocumentBuilder.expenseVehicleDirectoryDocument(
          orgId: identity.organizationId,
          uid: identity.uid,
          deviceId: identity.deviceId,
          appState: appState,
          nowUtc: timestamp,
        );
    await queueStore.enqueueReplacingPendingForPath(
      draft,
      queuedAtUtc: timestamp,
    );
    return ExpenseCloudQueueResult.queued(draft.path);
  }

  Future<ExpenseCloudQueueResult> queueWorkProfileDirectory({
    DateTime? nowUtc,
  }) async {
    final identity = _identityOrNull;
    if (identity == null) {
      return const ExpenseCloudQueueResult.identityRequired();
    }
    final timestamp = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    final draft =
        ExpenseFirestoreDocumentBuilder.expenseWorkProfileDirectoryDocument(
          orgId: identity.organizationId,
          uid: identity.uid,
          deviceId: identity.deviceId,
          workProfiles: workProfiles,
          nowUtc: timestamp,
        );
    await queueStore.enqueueReplacingPendingForPath(
      draft,
      queuedAtUtc: timestamp,
    );
    return ExpenseCloudQueueResult.queued(draft.path);
  }

  /// Queues one durable reminder record, including a tombstone when the user
  /// deleted it locally.  This keeps an immediate-sync reminder change from
  /// depending on a later full backup.
  Future<ExpenseCloudQueueResult> queueReminder(
    String reminderId, {
    DateTime? nowUtc,
  }) async {
    final reminder = reminders.recordById(reminderId);
    if (reminder == null) {
      return const ExpenseCloudQueueResult.localRecordMissing();
    }
    final identity = _identityOrNull;
    if (identity == null) {
      return const ExpenseCloudQueueResult.identityRequired();
    }
    final timestamp = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    final draft = ExpenseFirestoreDocumentBuilder.expenseReminderDocument(
      orgId: identity.organizationId,
      uid: identity.uid,
      deviceId: identity.deviceId,
      reminder: reminder,
    );
    await queueStore.enqueueReplacingPendingForPath(
      draft,
      queuedAtUtc: timestamp,
    );
    return ExpenseCloudQueueResult.queued(draft.path);
  }

  /// Queues all current local Expense records plus the member-scoped settings
  /// document. It deliberately does not flush unrelated queue entries that may
  /// belong to a signed-out account or a different organization.
  Future<ExpenseCloudBackupResult> backupLocalSnapshot({
    DateTime? nowUtc,
  }) async {
    final identity = _identityOrNull;
    if (identity == null) {
      return const ExpenseCloudBackupResult.identityRequired();
    }
    final timestamp = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    final drafts = <MaintainiacFirestoreDocumentDraft>[
      ExpenseFirestoreDocumentBuilder.expenseSettingsDocument(
        orgId: identity.organizationId,
        uid: identity.uid,
        deviceId: identity.deviceId,
        settings: settings,
        nowUtc: timestamp,
      ),
      for (final reminder in reminders.storedRecords)
        ExpenseFirestoreDocumentBuilder.expenseReminderDocument(
          orgId: identity.organizationId,
          uid: identity.uid,
          deviceId: identity.deviceId,
          reminder: reminder,
        ),
      ExpenseFirestoreDocumentBuilder.expenseWorkProfileDirectoryDocument(
        orgId: identity.organizationId,
        uid: identity.uid,
        deviceId: identity.deviceId,
        workProfiles: workProfiles,
        nowUtc: timestamp,
      ),
      ExpenseFirestoreDocumentBuilder.expenseVehicleDirectoryDocument(
        orgId: identity.organizationId,
        uid: identity.uid,
        deviceId: identity.deviceId,
        appState: appState,
        nowUtc: timestamp,
      ),
      for (final receipt in ledger.storedReceipts)
        ExpenseFirestoreDocumentBuilder.expenseReceiptDocument(
          orgId: identity.organizationId,
          uid: identity.uid,
          deviceId: identity.deviceId,
          receipt: receipt,
          nowUtc: timestamp,
          cloudProofReferences: _cloudProofReferencesFor(receipt, identity),
        ),
    ];
    final rejection = ExpenseBackupDraftGuard.rejectionFor(drafts);
    if (rejection != null) {
      await settings.recordBackupAttempt(timestamp);
      await settings.recordBackupFailure(rejection);
      return ExpenseCloudBackupResult.deliveryUnavailable(rejection);
    }
    for (final draft in drafts) {
      await queueStore.enqueueReplacingPendingForPath(
        draft,
        queuedAtUtc: timestamp,
      );
    }

    await settings.recordBackupAttempt(timestamp);
    final result = await flushPaths(
      drafts.map((draft) => draft.path),
      queuedCount: drafts.length,
      nowUtc: timestamp,
    );
    if (result.completed) {
      await settings.recordSuccessfulBackup(timestamp);
    } else {
      await settings.recordBackupFailure(
        result.reason ?? 'Backup is waiting to retry.',
      );
    }
    return result;
  }

  /// Performs a snapshot only when a platform scheduler has supplied a
  /// user-approved connection and the selected local-clock time is due.
  /// Calling this never changes a manual or immediate-sync preference.
  Future<ExpenseScheduledBackupResult> backupScheduledSnapshot({
    required ExpenseBackupNetworkAvailability network,
    DateTime? now,
  }) async {
    final localNow = (now ?? DateTime.now()).toLocal();
    if (!hasTrustedIdentity) {
      return const ExpenseScheduledBackupResult.notAuthorized();
    }
    if (settings.backupSyncMode != ExpenseBackupSyncMode.scheduled) {
      return const ExpenseScheduledBackupResult.notAuthorized();
    }
    if (!network.permits(settings.backupSchedule.transport)) {
      return ExpenseScheduledBackupResult.waitingForApprovedNetwork(network);
    }
    if (!settings.isScheduledBackupDueAt(
      localNow,
      lastAttemptAt: settings.lastBackupAttemptAt,
    )) {
      return const ExpenseScheduledBackupResult.notDue();
    }
    final backup = await backupLocalSnapshot(nowUtc: localNow.toUtc());
    return ExpenseScheduledBackupResult.attempted(backup);
  }

  /// Flushes only the supplied paths. This prevents a newly signed-in account
  /// from accidentally uploading stale queue entries belonging to another
  /// account or workspace.
  Future<ExpenseCloudBackupResult> flushPaths(
    Iterable<String> paths, {
    required int queuedCount,
    DateTime? nowUtc,
  }) async {
    final identity = _identityOrNull;
    if (identity == null) {
      return const ExpenseCloudBackupResult.identityRequired();
    }
    final targetPaths = <String>{
      for (final path in paths)
        if (path.trim().isNotEmpty) path.trim(),
    };
    var attemptedCount = 0;
    var uploadedCount = 0;
    var failedCount = 0;
    MaintainiacFirestoreUploadStatus lastStatus =
        MaintainiacFirestoreUploadStatus.empty;
    String? reason;
    for (final path in targetPaths) {
      final pendingForPath = queueStore.pendingRecords.where(
        (record) => record.path == path,
      );
      if (pendingForPath.any(
        (record) => !_belongsToCurrentIdentity(record, identity),
      )) {
        failedCount += 1;
        reason ??=
            'A queued backup belongs to a different account or workspace.';
        continue;
      }
      final upload = await uploadCoordinator.uploadPending(
        limit: 1,
        path: path,
        nowUtc: nowUtc,
      );
      attemptedCount += upload.attemptedCount;
      uploadedCount += upload.uploadedCount;
      failedCount += upload.failedCount;
      lastStatus = upload.status;
      reason ??= upload.reason;
    }
    return ExpenseCloudBackupResult(
      queuedCount: targetPaths.length,
      attemptedCount: attemptedCount,
      uploadedCount: uploadedCount,
      failedCount: failedCount,
      status: failedCount > 0
          ? uploadedCount > 0
                ? MaintainiacFirestoreUploadStatus.partial
                : MaintainiacFirestoreUploadStatus.failed
          : uploadedCount > 0
          ? MaintainiacFirestoreUploadStatus.uploaded
          : lastStatus,
      reason: reason,
    );
  }

  _ExpenseCloudIdentity? get _identityOrNull {
    final orgId = _clean(organizationId);
    final uid = _clean(authenticatedUid);
    final id = _clean(deviceId);
    if (orgId.isEmpty || uid.isEmpty || id.isEmpty) return null;
    return _ExpenseCloudIdentity(orgId, uid, id);
  }

  Map<String, ExpenseCloudProofReference> _cloudProofReferencesFor(
    ExpenseReceiptRecord receipt,
    _ExpenseCloudIdentity identity,
  ) => {
    for (final reference in proofReferences.referencesForReceipt(
      organizationId: identity.organizationId,
      userId: identity.uid,
      receiptId: receipt.id,
    ))
      reference.proofId: reference,
  };

  static String _clean(String? value) => value?.trim() ?? '';

  static bool _belongsToCurrentIdentity(
    MaintainiacFirestoreQueuedDocument record,
    _ExpenseCloudIdentity identity,
  ) {
    if (!record.path.startsWith('orgs/${identity.organizationId}/')) {
      return false;
    }
    final data = record.data;
    return _clean(data['orgId']?.toString()) == identity.organizationId &&
        _clean(data['createdByUid']?.toString()) == identity.uid &&
        _clean(data['updatedByUid']?.toString()) == identity.uid;
  }
}

class ExpenseCloudBackupResult {
  const ExpenseCloudBackupResult({
    required this.queuedCount,
    required this.attemptedCount,
    required this.uploadedCount,
    required this.failedCount,
    required this.status,
    this.reason,
  });

  const ExpenseCloudBackupResult.identityRequired()
    : queuedCount = 0,
      attemptedCount = 0,
      uploadedCount = 0,
      failedCount = 0,
      status = MaintainiacFirestoreUploadStatus.disabled,
      reason = 'Sign in and an account workspace are required before backup.';

  const ExpenseCloudBackupResult.localRecordMissing()
    : queuedCount = 0,
      attemptedCount = 0,
      uploadedCount = 0,
      failedCount = 0,
      status = MaintainiacFirestoreUploadStatus.empty,
      reason = 'The local receipt no longer exists.';

  const ExpenseCloudBackupResult.deliveryUnavailable(String this.reason)
    : queuedCount = 0,
      attemptedCount = 0,
      uploadedCount = 0,
      failedCount = 1,
      status = MaintainiacFirestoreUploadStatus.failed;

  final int queuedCount;
  final int attemptedCount;
  final int uploadedCount;
  final int failedCount;
  final MaintainiacFirestoreUploadStatus status;
  final String? reason;

  bool get completed =>
      failedCount == 0 && queuedCount > 0 && uploadedCount == queuedCount;
}

class ExpenseCloudQueueResult {
  const ExpenseCloudQueueResult.queued(String this.documentPath)
    : status = MaintainiacFirestoreUploadStatus.empty,
      reason = null;

  const ExpenseCloudQueueResult.identityRequired()
    : documentPath = null,
      status = MaintainiacFirestoreUploadStatus.disabled,
      reason = 'Sign in and an account workspace are required before backup.';

  const ExpenseCloudQueueResult.localRecordMissing()
    : documentPath = null,
      status = MaintainiacFirestoreUploadStatus.empty,
      reason = 'The local receipt no longer exists.';

  const ExpenseCloudQueueResult.rejected(String this.reason)
    : documentPath = null,
      status = MaintainiacFirestoreUploadStatus.failed;

  final String? documentPath;
  final MaintainiacFirestoreUploadStatus status;
  final String? reason;

  bool get wasQueued => documentPath != null;

  ExpenseCloudBackupResult toBackupResult() {
    return ExpenseCloudBackupResult(
      queuedCount: 0,
      attemptedCount: 0,
      uploadedCount: 0,
      failedCount: 0,
      status: status,
      reason: reason,
    );
  }
}

enum ExpenseScheduledBackupStatus {
  notAuthorized,
  waitingForApprovedNetwork,
  notDue,
  attempted,
  retryPending,
}

class ExpenseScheduledBackupResult {
  const ExpenseScheduledBackupResult._(this.status, {this.backup});

  const ExpenseScheduledBackupResult.notAuthorized()
    : this._(ExpenseScheduledBackupStatus.notAuthorized);

  const ExpenseScheduledBackupResult.notDue()
    : this._(ExpenseScheduledBackupStatus.notDue);

  const ExpenseScheduledBackupResult.retryPending()
    : this._(ExpenseScheduledBackupStatus.retryPending);

  ExpenseScheduledBackupResult.waitingForApprovedNetwork(
    ExpenseBackupNetworkAvailability network,
  ) : this._(ExpenseScheduledBackupStatus.waitingForApprovedNetwork);

  const ExpenseScheduledBackupResult.attempted(ExpenseCloudBackupResult backup)
    : this._(ExpenseScheduledBackupStatus.attempted, backup: backup);

  final ExpenseScheduledBackupStatus status;
  final ExpenseCloudBackupResult? backup;

  bool get didAttempt => status == ExpenseScheduledBackupStatus.attempted;
}

class _ExpenseCloudIdentity {
  const _ExpenseCloudIdentity(this.organizationId, this.uid, this.deviceId);

  final String organizationId;
  final String uid;
  final String deviceId;
}

abstract interface class ExpenseCloudBackupMirror {
  Future<void> queueReceipt(String receiptId);

  Future<ExpenseCloudBackupResult> syncLocalSnapshot();

  Future<ExpenseScheduledBackupResult> syncScheduledSnapshot({
    required ExpenseBackupNetworkAvailability network,
    DateTime? now,
  });
}

class NoopExpenseCloudBackupMirror implements ExpenseCloudBackupMirror {
  const NoopExpenseCloudBackupMirror();

  @override
  Future<void> queueReceipt(String receiptId) async {}

  @override
  Future<ExpenseCloudBackupResult> syncLocalSnapshot() async =>
      const ExpenseCloudBackupResult.identityRequired();

  @override
  Future<ExpenseScheduledBackupResult> syncScheduledSnapshot({
    required ExpenseBackupNetworkAvailability network,
    DateTime? now,
  }) async => const ExpenseScheduledBackupResult.notAuthorized();
}

/// The live Expense backup bridge. It stays local-first: a receipt is queued
/// before workspace provisioning or network upload is attempted.
class FirebaseExpenseCloudBackupMirror implements ExpenseCloudBackupMirror {
  FirebaseExpenseCloudBackupMirror({
    required this.ledger,
    required this.settings,
    required this.reminders,
    required this.workProfiles,
    required this.appState,
    required this.queueStore,
    required this.uploadCoordinator,
    required this.proofReferences,
    required this.deviceId,
    required bool Function() backupEnabled,
    MaintainiacCloudIdentityProvider? identityProvider,
    MaintainiacOrganizationBootstrapper? workspaceBootstrapper,
  }) : _backupEnabled = backupEnabled,
       _identityProvider =
           identityProvider ?? FirebaseMaintainiacCloudIdentityProvider(),
       _workspaceBootstrapper =
           workspaceBootstrapper ??
           MaintainiacOrganizationBootstrapper(
             writer: FirebaseOrganizationBootstrapWriter(),
           ) {
    appState.addListener(_onVehicleStateChanged);
    workProfiles.addListener(_onWorkProfileStateChanged);
    _rememberReminderRevisions();
    reminders.addListener(_onReminderStateChanged);
  }

  final ExpenseLedgerController ledger;
  final ExpenseSettingsController settings;
  final ExpenseReminderController reminders;
  final ExpenseWorkProfileController workProfiles;
  final AppStateController appState;
  final MaintainiacFirestoreUploadQueueStore queueStore;
  final MaintainiacFirestoreUploadCoordinator uploadCoordinator;
  final ExpenseCloudProofReferenceStore proofReferences;
  final String deviceId;
  final bool Function() _backupEnabled;
  final MaintainiacCloudIdentityProvider _identityProvider;
  final MaintainiacOrganizationBootstrapper _workspaceBootstrapper;
  Future<void> _taskChain = Future<void>.value();
  final _knownReminderRevisions = <String, int>{};

  void _onVehicleStateChanged() {
    _scheduleBackground(_queueAndSyncVehicleDirectory);
  }

  void _onWorkProfileStateChanged() {
    _scheduleBackground(_queueAndSyncWorkProfileDirectory);
  }

  void _onReminderStateChanged() {
    final changedIds = _changedReminderIds();
    if (changedIds.isEmpty) return;
    _scheduleBackground(() => _queueAndSyncReminders(changedIds));
  }

  List<String> _changedReminderIds() {
    final current = <String, int>{
      for (final reminder in reminders.storedRecords)
        if (reminder.id.isNotEmpty)
          reminder.id: reminder.lifecycle?.revision ?? 1,
    };
    final changedIds = current.entries
        .where((entry) => _knownReminderRevisions[entry.key] != entry.value)
        .map((entry) => entry.key)
        .toList(growable: false);
    _knownReminderRevisions
      ..clear()
      ..addAll(current);
    return changedIds;
  }

  void _rememberReminderRevisions() {
    _knownReminderRevisions
      ..clear()
      ..addAll({
        for (final reminder in reminders.storedRecords)
          if (reminder.id.isNotEmpty)
            reminder.id: reminder.lifecycle?.revision ?? 1,
      });
  }

  @override
  Future<void> queueReceipt(String receiptId) async {
    try {
      await _schedule(() => _queueAndSyncReceipt(receiptId));
    } catch (_) {
      // The durable local receipt and retry queue remain available.
    }
  }

  @override
  Future<ExpenseCloudBackupResult> syncLocalSnapshot() async {
    try {
      return await _schedule(_syncSnapshot);
    } catch (_) {
      return const ExpenseCloudBackupResult.deliveryUnavailable(
        'Backup could not be completed. Your local records remain safe and can be retried.',
      );
    }
  }

  @override
  Future<ExpenseScheduledBackupResult> syncScheduledSnapshot({
    required ExpenseBackupNetworkAvailability network,
    DateTime? now,
  }) => _syncScheduledSnapshotSafely(network: network, now: now);

  Future<ExpenseScheduledBackupResult> _syncScheduledSnapshotSafely({
    required ExpenseBackupNetworkAvailability network,
    required DateTime? now,
  }) async {
    try {
      return await _schedule(
        () => _syncScheduledSnapshot(network: network, now: now),
      );
    } catch (_) {
      return const ExpenseScheduledBackupResult.retryPending();
    }
  }

  void _scheduleBackground(Future<void> Function() action) {
    unawaited(_schedule(action).catchError((_) {}));
  }

  /// Serializes background work without dropping a receipt saved while an
  /// earlier upload is still in flight. Failures remain local and never break
  /// the following queued receipt.
  Future<T> _schedule<T>(Future<T> Function() action) {
    final next = _taskChain.then((_) => action());
    _taskChain = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  Future<void> _queueAndSyncReceipt(String receiptId) async {
    final service = _serviceForCurrentUser();
    final uid = _currentUid;
    if (service == null || uid == null) return;
    final queued = await service.queueReceipt(receiptId);
    if (!queued.wasQueued) return;
    if (settings.backupSyncMode != ExpenseBackupSyncMode.immediate) {
      return;
    }
    try {
      await _workspaceBootstrapper.ensurePersonalWorkspace(
        authenticatedUid: uid,
      );
    } catch (_) {
      // The durable local queue remains intact for the next explicit sync.
      return;
    }
    await service.flushPaths([queued.documentPath!], queuedCount: 1);
  }

  Future<ExpenseCloudBackupResult> _syncSnapshot() async {
    final service = _serviceForCurrentUser();
    final uid = _currentUid;
    if (service == null || uid == null) {
      return const ExpenseCloudBackupResult.identityRequired();
    }
    try {
      await _workspaceBootstrapper.ensurePersonalWorkspace(
        authenticatedUid: uid,
      );
    } catch (_) {
      return const ExpenseCloudBackupResult.deliveryUnavailable(
        'Backup could not reach your account workspace. Your local records remain safe and can be retried.',
      );
    }
    return service.backupLocalSnapshot();
  }

  Future<ExpenseScheduledBackupResult> _syncScheduledSnapshot({
    required ExpenseBackupNetworkAvailability network,
    required DateTime? now,
  }) async {
    final service = _serviceForCurrentUser();
    final uid = _currentUid;
    if (service == null || uid == null) {
      return const ExpenseScheduledBackupResult.notAuthorized();
    }
    final localNow = (now ?? DateTime.now()).toLocal();
    if (settings.backupSyncMode != ExpenseBackupSyncMode.scheduled) {
      return const ExpenseScheduledBackupResult.notAuthorized();
    }
    if (!network.permits(settings.backupSchedule.transport)) {
      return ExpenseScheduledBackupResult.waitingForApprovedNetwork(network);
    }
    if (!settings.isScheduledBackupDueAt(
      localNow,
      lastAttemptAt: settings.lastBackupAttemptAt,
    )) {
      return const ExpenseScheduledBackupResult.notDue();
    }
    try {
      await _workspaceBootstrapper.ensurePersonalWorkspace(
        authenticatedUid: uid,
      );
    } catch (_) {
      return const ExpenseScheduledBackupResult.notAuthorized();
    }
    return service.backupScheduledSnapshot(network: network, now: localNow);
  }

  Future<void> _queueAndSyncVehicleDirectory() async {
    final service = _serviceForCurrentUser();
    final uid = _currentUid;
    if (service == null || uid == null) return;
    final queued = await service.queueVehicleDirectory();
    if (!queued.wasQueued ||
        settings.backupSyncMode != ExpenseBackupSyncMode.immediate) {
      return;
    }
    try {
      await _workspaceBootstrapper.ensurePersonalWorkspace(
        authenticatedUid: uid,
      );
    } catch (_) {
      return;
    }
    await service.flushPaths([queued.documentPath!], queuedCount: 1);
  }

  Future<void> _queueAndSyncWorkProfileDirectory() async {
    final service = _serviceForCurrentUser();
    final uid = _currentUid;
    if (service == null || uid == null) return;
    final queued = await service.queueWorkProfileDirectory();
    if (!queued.wasQueued ||
        settings.backupSyncMode != ExpenseBackupSyncMode.immediate) {
      return;
    }
    try {
      await _workspaceBootstrapper.ensurePersonalWorkspace(
        authenticatedUid: uid,
      );
    } catch (_) {
      return;
    }
    await service.flushPaths([queued.documentPath!], queuedCount: 1);
  }

  Future<void> _queueAndSyncReminders(List<String> reminderIds) async {
    final service = _serviceForCurrentUser();
    final uid = _currentUid;
    if (service == null || uid == null) return;
    for (final reminderId in reminderIds) {
      final queued = await service.queueReminder(reminderId);
      if (!queued.wasQueued ||
          settings.backupSyncMode != ExpenseBackupSyncMode.immediate) {
        continue;
      }
      try {
        await _workspaceBootstrapper.ensurePersonalWorkspace(
          authenticatedUid: uid,
        );
      } catch (_) {
        return;
      }
      await service.flushPaths([queued.documentPath!], queuedCount: 1);
    }
  }

  ExpenseCloudBackupService? _serviceForCurrentUser() {
    if (!_isBackupEnabled) return null;
    final uid = _currentUid ?? '';
    if (uid.isEmpty) return null;
    return ExpenseCloudBackupService(
      ledger: ledger,
      settings: settings,
      reminders: reminders,
      workProfiles: workProfiles,
      appState: appState,
      queueStore: queueStore,
      uploadCoordinator: uploadCoordinator,
      proofReferences: proofReferences,
      organizationId:
          MaintainiacOrganizationBootstrapper.personalOrganizationIdFor(uid),
      authenticatedUid: uid,
      deviceId: deviceId,
    );
  }

  String? get _currentUid {
    final uid = _identityProvider.currentUid?.trim() ?? '';
    return uid.isEmpty ? null : uid;
  }

  bool get _isBackupEnabled {
    try {
      return _backupEnabled();
    } catch (_) {
      return false;
    }
  }
}

class ExpenseCloudBackupScope extends InheritedWidget {
  const ExpenseCloudBackupScope({
    super.key,
    required this.mirror,
    required super.child,
  });

  final ExpenseCloudBackupMirror mirror;

  static ExpenseCloudBackupMirror of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ExpenseCloudBackupScope>();
    assert(scope != null, 'ExpenseCloudBackupScope is missing above context.');
    return scope!.mirror;
  }

  static ExpenseCloudBackupMirror? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ExpenseCloudBackupScope>()
        ?.mirror;
  }

  @override
  bool updateShouldNotify(ExpenseCloudBackupScope oldWidget) {
    return oldWidget.mirror != mirror;
  }
}
