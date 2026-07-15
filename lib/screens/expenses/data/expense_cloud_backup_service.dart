import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../../../shared/firebase/maintainiac_organization_bootstrap.dart';
import '../../../shared/firebase/maintainiac_firestore_documents.dart';
import '../../../shared/firebase/maintainiac_firestore_upload_queue.dart';
import '../../../shared/state/expense_settings_store.dart';
import '../../../shared/state/app_state.dart';
import 'expense_firestore_documents.dart';
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
    return flushPaths([queued.documentPath!], queuedCount: 1, nowUtc: nowUtc);
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
    );
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
        ),
    ];
    for (final draft in drafts) {
      await queueStore.enqueueReplacingPendingForPath(
        draft,
        queuedAtUtc: timestamp,
      );
    }

    return flushPaths(
      drafts.map((draft) => draft.path),
      queuedCount: drafts.length,
      nowUtc: timestamp,
    );
  }

  /// Flushes only the supplied paths. This prevents a newly signed-in account
  /// from accidentally uploading stale queue entries belonging to another
  /// account or workspace.
  Future<ExpenseCloudBackupResult> flushPaths(
    Iterable<String> paths, {
    required int queuedCount,
    DateTime? nowUtc,
  }) async {
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

  static String _clean(String? value) => value?.trim() ?? '';
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
    : reason = null;

  const ExpenseCloudQueueResult.identityRequired()
    : documentPath = null,
      reason = 'Sign in and an account workspace are required before backup.';

  const ExpenseCloudQueueResult.localRecordMissing()
    : documentPath = null,
      reason = 'The local receipt no longer exists.';

  final String? documentPath;
  final String? reason;

  bool get wasQueued => documentPath != null;

  ExpenseCloudBackupResult toBackupResult() {
    return ExpenseCloudBackupResult(
      queuedCount: 0,
      attemptedCount: 0,
      uploadedCount: 0,
      failedCount: 0,
      status: reason?.contains('Sign in') == true
          ? MaintainiacFirestoreUploadStatus.disabled
          : MaintainiacFirestoreUploadStatus.empty,
      reason: reason,
    );
  }
}

class _ExpenseCloudIdentity {
  const _ExpenseCloudIdentity(this.organizationId, this.uid, this.deviceId);

  final String organizationId;
  final String uid;
  final String deviceId;
}

abstract interface class ExpenseCloudBackupMirror {
  Future<void> queueReceipt(String receiptId);

  Future<void> syncLocalSnapshot();
}

class NoopExpenseCloudBackupMirror implements ExpenseCloudBackupMirror {
  const NoopExpenseCloudBackupMirror();

  @override
  Future<void> queueReceipt(String receiptId) async {}

  @override
  Future<void> syncLocalSnapshot() async {}
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
    required this.deviceId,
    required bool Function() backupEnabled,
    FirebaseAuth? firebaseAuth,
    MaintainiacOrganizationBootstrapper? workspaceBootstrapper,
  }) : _backupEnabled = backupEnabled,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
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
  final String deviceId;
  final bool Function() _backupEnabled;
  final FirebaseAuth _firebaseAuth;
  final MaintainiacOrganizationBootstrapper _workspaceBootstrapper;
  Future<void> _taskChain = Future<void>.value();
  final _knownReminderRevisions = <String, int>{};

  void _onVehicleStateChanged() {
    unawaited(_schedule(_queueAndSyncVehicleDirectory));
  }

  void _onWorkProfileStateChanged() {
    unawaited(_schedule(_queueAndSyncWorkProfileDirectory));
  }

  void _onReminderStateChanged() {
    final changedIds = _changedReminderIds();
    if (changedIds.isEmpty) return;
    unawaited(_schedule(() => _queueAndSyncReminders(changedIds)));
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
  Future<void> queueReceipt(String receiptId) {
    return _schedule(() => _queueAndSyncReceipt(receiptId));
  }

  @override
  Future<void> syncLocalSnapshot() {
    return _schedule(_syncSnapshot);
  }

  /// Serializes background work without dropping a receipt saved while an
  /// earlier upload is still in flight. Failures remain local and never break
  /// the following queued receipt.
  Future<void> _schedule(Future<void> Function() action) {
    final next = _taskChain.then((_) => action()).catchError((_) {});
    _taskChain = next;
    return next;
  }

  Future<void> _queueAndSyncReceipt(String receiptId) async {
    final service = _serviceForCurrentUser();
    final user = _firebaseAuth.currentUser;
    if (service == null || user == null) return;
    final queued = await service.queueReceipt(receiptId);
    if (!queued.wasQueued) return;
    if (settings.backupSyncMode != ExpenseBackupSyncMode.immediate) {
      return;
    }
    try {
      await _workspaceBootstrapper.ensurePersonalWorkspace(
        authenticatedUid: user.uid,
      );
    } catch (_) {
      // The durable local queue remains intact for the next explicit sync.
      return;
    }
    await service.flushPaths([queued.documentPath!], queuedCount: 1);
  }

  Future<void> _syncSnapshot() async {
    final service = _serviceForCurrentUser();
    final user = _firebaseAuth.currentUser;
    if (service == null || user == null) return;
    try {
      await _workspaceBootstrapper.ensurePersonalWorkspace(
        authenticatedUid: user.uid,
      );
    } catch (_) {
      return;
    }
    await service.backupLocalSnapshot();
  }

  Future<void> _queueAndSyncVehicleDirectory() async {
    final service = _serviceForCurrentUser();
    final user = _firebaseAuth.currentUser;
    if (service == null || user == null) return;
    final queued = await service.queueVehicleDirectory();
    if (!queued.wasQueued ||
        settings.backupSyncMode != ExpenseBackupSyncMode.immediate) {
      return;
    }
    try {
      await _workspaceBootstrapper.ensurePersonalWorkspace(
        authenticatedUid: user.uid,
      );
    } catch (_) {
      return;
    }
    await service.flushPaths([queued.documentPath!], queuedCount: 1);
  }

  Future<void> _queueAndSyncWorkProfileDirectory() async {
    final service = _serviceForCurrentUser();
    final user = _firebaseAuth.currentUser;
    if (service == null || user == null) return;
    final queued = await service.queueWorkProfileDirectory();
    if (!queued.wasQueued ||
        settings.backupSyncMode != ExpenseBackupSyncMode.immediate) {
      return;
    }
    try {
      await _workspaceBootstrapper.ensurePersonalWorkspace(
        authenticatedUid: user.uid,
      );
    } catch (_) {
      return;
    }
    await service.flushPaths([queued.documentPath!], queuedCount: 1);
  }

  Future<void> _queueAndSyncReminders(List<String> reminderIds) async {
    final service = _serviceForCurrentUser();
    final user = _firebaseAuth.currentUser;
    if (service == null || user == null) return;
    for (final reminderId in reminderIds) {
      final queued = await service.queueReminder(reminderId);
      if (!queued.wasQueued ||
          settings.backupSyncMode != ExpenseBackupSyncMode.immediate) {
        continue;
      }
      try {
        await _workspaceBootstrapper.ensurePersonalWorkspace(
          authenticatedUid: user.uid,
        );
      } catch (_) {
        return;
      }
      await service.flushPaths([queued.documentPath!], queuedCount: 1);
    }
  }

  ExpenseCloudBackupService? _serviceForCurrentUser() {
    if (!_isBackupEnabled) return null;
    final uid = _firebaseAuth.currentUser?.uid.trim() ?? '';
    if (uid.isEmpty) return null;
    return ExpenseCloudBackupService(
      ledger: ledger,
      settings: settings,
      reminders: reminders,
      workProfiles: workProfiles,
      appState: appState,
      queueStore: queueStore,
      uploadCoordinator: uploadCoordinator,
      organizationId:
          MaintainiacOrganizationBootstrapper.personalOrganizationIdFor(uid),
      authenticatedUid: uid,
      deviceId: deviceId,
    );
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
