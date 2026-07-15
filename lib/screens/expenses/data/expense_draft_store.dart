import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../shared/records/maintainiac_record_lifecycle.dart';
import '../../../shared/widgets/receipt_capture/receipt_capture_models.dart';
import '../../../shared/widgets/receipt_capture/receipt_proof_storage.dart';
import 'expense_ledger_models.dart';

class ExpenseDraftController extends ChangeNotifier {
  ExpenseDraftController._(this._legacyBox, this._drafts);
  ExpenseDraftController.memory()
    : _legacyBox = null,
      _drafts = MaintainiacRecordDraftStore.memory();

  /// Legacy box used only to migrate drafts safely into the shared store.
  static const boxName = 'expense_receipt_drafts';
  static const _module = 'expenses';

  final Box<dynamic>? _legacyBox;
  final MaintainiacRecordDraftStore _drafts;
  Future<void> _writeTail = Future<void>.value();

  static Future<ExpenseDraftController> create() async {
    final controller = ExpenseDraftController._(
      await Hive.openBox<dynamic>(boxName),
      await MaintainiacRecordDraftStore.create(),
    );
    await controller._migrateLegacyDrafts();
    return controller;
  }

  List<ExpenseReceiptDraftRecord> get drafts {
    final records = _drafts
        .draftsFor(_module)
        .map((draft) => ExpenseReceiptDraftRecord.fromMap(draft.payload))
        .toList(growable: false);
    records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return records;
  }

  ExpenseReceiptDraftRecord? draftById(String id) {
    final draft = _drafts.draftFor(_module, id);
    return draft == null
        ? null
        : ExpenseReceiptDraftRecord.fromMap(draft.payload);
  }

  List<ReceiptAttachmentRecord> missingAttachmentsForDraft(String id) {
    final draft = draftById(id);
    if (draft == null) return const [];
    return [
      for (final attachment in draft.attachments)
        if (!attachment.isImportedText &&
            attachment.path.trim().isNotEmpty &&
            !File(attachment.path).existsSync())
          attachment,
    ];
  }

  bool draftHasMissingProof(String id) {
    return missingAttachmentsForDraft(id).isNotEmpty;
  }

  ExpenseDraftRecoverySnapshot recoverySnapshot() {
    final records = drafts;
    final missingByDraft = <String, List<ReceiptAttachmentRecord>>{};
    final retainedStagedPaths = <String>{};
    for (final draft in records) {
      final missing = missingAttachmentsForDraft(draft.id);
      if (missing.isNotEmpty) missingByDraft[draft.id] = missing;
      for (final attachment in draft.attachments) {
        if (attachment.storageState != ReceiptAttachmentStorageState.staged) {
          continue;
        }
        final proofPath = attachment.path.trim();
        if (proofPath.isNotEmpty) retainedStagedPaths.add(proofPath);
      }
    }
    return ExpenseDraftRecoverySnapshot(
      drafts: records,
      missingAttachmentsByDraftId: missingByDraft,
      retainedStagedProofPaths: retainedStagedPaths.toList(growable: false),
    );
  }

  Future<ExpenseDraftRecoverySnapshot> cleanAbandonedStagedProofs({
    Iterable<String> additionalRetainedPaths = const [],
    Duration olderThan = const Duration(days: 7),
    DateTime? now,
  }) async {
    final snapshot = recoverySnapshot();
    await ReceiptProofStorage.instance.cleanOldStagedFiles(
      retainedPaths: [
        ...snapshot.retainedStagedProofPaths,
        ...additionalRetainedPaths,
      ],
      olderThan: olderThan,
      now: now,
    );
    return snapshot;
  }

  Future<void> saveDraft(ExpenseReceiptDraftRecord draft) => _enqueue(() async {
    final existing = draftById(draft.id);
    // An older entry screen or delayed lifecycle callback must never erase a
    // newer checkpoint that has already reached this device.
    if (existing != null && existing.updatedAt.isAfter(draft.updatedAt)) {
      return;
    }
    if (!draft.hasUserContent) {
      await _deleteDraft(draft.id, notify: false);
      notifyListeners();
      return;
    }
    await _drafts.save(
      module: _module,
      id: draft.id,
      payload: draft.toMap(),
      now: draft.updatedAt,
    );
    notifyListeners();
  });

  Future<void> deleteDraft(String id, {bool notify = true}) =>
      _enqueue(() => _deleteDraft(id, notify: notify));

  Future<void> _deleteDraft(String id, {bool notify = true}) async {
    await _deleteStagedProofsForDraft(id);
    await _drafts.remove(_module, id);
    if (notify) notifyListeners();
  }

  Future<void> clear() => _enqueue(() async {
    final attachments = [for (final draft in drafts) ...draft.attachments];
    await ReceiptProofStorage.instance.deleteStagedAttachments(attachments);
    for (final draft in drafts) {
      await _drafts.remove(_module, draft.id);
    }
    notifyListeners();
  });

  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _writeTail.then((_) => operation());
    _writeTail = next.catchError((_) {});
    return next;
  }

  Future<void> _migrateLegacyDrafts() async {
    final box = _legacyBox;
    if (box == null) return;
    for (final key in box.keys.toList(growable: false)) {
      final value = box.get(key);
      if (value is! Map) continue;
      try {
        final draft = ExpenseReceiptDraftRecord.fromMap(value);
        if (draft.id.trim().isEmpty) continue;
        if (_drafts.draftFor(_module, draft.id) == null) {
          await _drafts.save(
            module: _module,
            id: draft.id,
            payload: draft.toMap(),
            now: draft.updatedAt,
          );
        }
        await box.delete(key);
      } catch (_) {
        // Preserve malformed legacy data rather than discarding it.
      }
    }
  }

  Future<void> _deleteStagedProofsForDraft(String id) async {
    final draft = draftById(id);
    if (draft == null) return;
    await ReceiptProofStorage.instance.deleteStagedAttachments(
      draft.attachments,
    );
  }
}

class ExpenseDraftRecoverySnapshot {
  const ExpenseDraftRecoverySnapshot({
    required this.drafts,
    required this.missingAttachmentsByDraftId,
    required this.retainedStagedProofPaths,
  });

  final List<ExpenseReceiptDraftRecord> drafts;
  final Map<String, List<ReceiptAttachmentRecord>> missingAttachmentsByDraftId;
  final List<String> retainedStagedProofPaths;

  int get draftCount => drafts.length;
  int get missingProofDraftCount => missingAttachmentsByDraftId.length;
  int get missingProofCount => missingAttachmentsByDraftId.values.fold(
    0,
    (sum, attachments) => sum + attachments.length,
  );
  bool get hasRecoverableWork => drafts.isNotEmpty;
  bool get hasMissingProof => missingProofCount > 0;
  List<String> get recoverableDraftIds => [
    for (final draft in drafts) draft.id,
  ];
}

class ExpenseDraftScope extends InheritedNotifier<ExpenseDraftController> {
  const ExpenseDraftScope({
    super.key,
    required ExpenseDraftController controller,
    required super.child,
  }) : super(notifier: controller);

  static ExpenseDraftController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(
      controller != null,
      'ExpenseDraftScope is missing above this context.',
    );
    return controller!;
  }

  static ExpenseDraftController? maybeOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ExpenseDraftScope>();
    return scope?.notifier;
  }
}
