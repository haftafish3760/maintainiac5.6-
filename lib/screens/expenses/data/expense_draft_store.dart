import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../shared/widgets/receipt_capture/receipt_capture_models.dart';
import '../../../shared/widgets/receipt_capture/receipt_proof_storage.dart';
import 'expense_ledger_models.dart';

class ExpenseDraftController extends ChangeNotifier {
  ExpenseDraftController._(this._box);
  ExpenseDraftController.memory() : _box = null;

  static const boxName = 'expense_receipt_drafts';

  final Box<dynamic>? _box;
  final _memoryRecords = <String, ExpenseReceiptDraftRecord>{};

  static Future<ExpenseDraftController> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return ExpenseDraftController._(box);
  }

  List<ExpenseReceiptDraftRecord> get drafts {
    final source = _box == null ? _memoryRecords.values : _box.values;
    final records = <ExpenseReceiptDraftRecord>[];
    for (final value in source) {
      if (value is ExpenseReceiptDraftRecord) {
        records.add(value);
      } else if (value is Map) {
        records.add(ExpenseReceiptDraftRecord.fromMap(value));
      }
    }
    records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return records;
  }

  ExpenseReceiptDraftRecord? draftById(String id) {
    final value = _box == null ? _memoryRecords[id] : _box.get(id);
    if (value is ExpenseReceiptDraftRecord) return value;
    if (value is Map) return ExpenseReceiptDraftRecord.fromMap(value);
    return null;
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

  Future<void> saveDraft(ExpenseReceiptDraftRecord draft) async {
    if (!draft.hasUserContent) {
      await deleteDraft(draft.id, notify: false);
      notifyListeners();
      return;
    }
    if (_box == null) {
      _memoryRecords[draft.id] = draft;
    } else {
      await _box.put(draft.id, draft.toMap());
    }
    notifyListeners();
  }

  Future<void> deleteDraft(String id, {bool notify = true}) async {
    await _deleteStagedProofsForDraft(id);
    if (_box == null) {
      _memoryRecords.remove(id);
    } else {
      await _box.delete(id);
    }
    if (notify) notifyListeners();
  }

  Future<void> clear() async {
    final attachments = [for (final draft in drafts) ...draft.attachments];
    await ReceiptProofStorage.instance.deleteStagedAttachments(attachments);
    _memoryRecords.clear();
    await _box?.clear();
    notifyListeners();
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
