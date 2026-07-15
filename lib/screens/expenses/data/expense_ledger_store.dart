import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../shared/records/maintainiac_record_lifecycle.dart';
import '../../../shared/storage/app_storage_guard.dart';
import 'expense_ledger_models.dart';
import 'expense_receipt_item_memory_store.dart';
import '../../../shared/widgets/receipt_capture/receipt_capture_models.dart';

part 'expense_ledger_attachment_duplicates.dart';
part 'expense_ledger_duplicate_helpers.dart';

typedef ExpenseRecordStorageCheck = Future<AppStorageCheck> Function();

class ExpenseLedgerController extends ChangeNotifier {
  ExpenseLedgerController._(
    this._box, {
    ExpenseRecordStorageCheck? storageCheck,
  }) : _storageCheck = storageCheck ?? _defaultStorageCheck;
  ExpenseLedgerController.memory({ExpenseRecordStorageCheck? storageCheck})
    : _box = null,
      _storageCheck = storageCheck;

  static const boxName = 'expense_ledger_receipts';

  final Box<dynamic>? _box;
  final ExpenseRecordStorageCheck? _storageCheck;
  final _memoryRecords = <String, ExpenseReceiptRecord>{};
  Future<void> _writeTail = Future<void>.value();

  static Future<ExpenseLedgerController> create({
    ExpenseRecordStorageCheck? storageCheck,
  }) async {
    final box = await Hive.openBox<dynamic>(boxName);
    return ExpenseLedgerController._(box, storageCheck: storageCheck);
  }

  List<ExpenseReceiptRecord> get receipts {
    final records = storedReceipts
        .where((receipt) => receipt.isActive)
        .toList(growable: false);
    records.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return records;
  }

  List<ExpenseReceiptRecord> get storedReceipts {
    final source = _box == null ? _memoryRecords.values : _box.values;
    final records = <ExpenseReceiptRecord>[];
    for (final value in source) {
      try {
        if (value is ExpenseReceiptRecord) {
          records.add(value);
        } else if (value is Map) {
          records.add(ExpenseReceiptRecord.fromMap(value));
        }
      } catch (_) {
        continue;
      }
    }
    records.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return records;
  }

  List<ExpenseReceiptRecord> get receiptsNeedingOcrReview {
    return storedReceipts
        .where((receipt) => receipt.isActive && receipt.ocrReview.needsReview)
        .toList(growable: false);
  }

  Map<String, int> get ocrRecoveryActionCounts {
    return _ocrRecoveryCountBy('recoveryAction');
  }

  Map<String, int> get ocrRecoveryTargetCounts {
    return _ocrRecoveryCountBy('recoveryTarget');
  }

  String get topOcrRecoveryAction {
    return _topOcrRecoveryToken(ocrRecoveryActionCounts);
  }

  String get topOcrRecoveryTarget {
    return _topOcrRecoveryToken(ocrRecoveryTargetCounts);
  }

  ExpenseReceiptRecord? receiptById(String id) {
    final value = _box == null ? _memoryRecords[id] : _box.get(id);
    if (value is ExpenseReceiptRecord) return value;
    if (value is Map) {
      try {
        return ExpenseReceiptRecord.fromMap(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  ExpenseReceiptDuplicateCheckResult checkDuplicatesFor(
    ExpenseReceiptRecord receipt, {
    DateTime? checkedAt,
  }) {
    final checkedTime = checkedAt ?? DateTime.now();
    final candidates = <ExpenseReceiptDuplicateCandidate>[];
    final incomingHashes = _receiptHashes(receipt);
    final incomingFileHash = _primaryFileHash(receipt);

    for (final existing in storedReceipts) {
      if (existing.id == receipt.id || !existing.isActive) continue;
      final existingHashes = _receiptHashes(existing);
      final sharedHashes = incomingHashes.intersection(existingHashes);
      if (sharedHashes.isNotEmpty) {
        candidates.add(
          ExpenseReceiptDuplicateCandidate.fromReceipt(
            receipt: existing,
            confidence: ExpenseDuplicateConfidence.exactFileMatch,
            reason: 'Same receipt proof file',
            matchedFileHashSha256: sharedHashes.first,
          ),
        );
        continue;
      }

      final probableCandidate = _probableDuplicateCandidate(receipt, existing);
      if (probableCandidate != null) {
        candidates.add(probableCandidate);
      }
    }
    candidates.sort((a, b) => b.confidence.score.compareTo(a.confidence.score));
    return ExpenseReceiptDuplicateCheckResult(
      checkedAt: checkedTime,
      status: candidates.isEmpty
          ? ExpenseDuplicateCheckStatus.clear
          : ExpenseDuplicateCheckStatus.candidatesFound,
      fileHashSha256: incomingFileHash,
      candidates: List.unmodifiable(candidates),
    );
  }

  List<ExpenseReceiptDuplicateCandidate> duplicateCandidatesFor(
    ExpenseReceiptRecord receipt,
  ) {
    return checkDuplicatesFor(receipt).candidates;
  }

  List<ExpenseReceiptRecord> receiptsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    final records = receipts.where((receipt) {
      final receiptDay = DateTime(
        receipt.receiptDate.year,
        receipt.receiptDate.month,
        receipt.receiptDate.day,
      );
      return receiptDay == key;
    }).toList();
    records.sort(_compareReceiptsForCalendarDay);
    return records;
  }

  ExpenseLedgerSummary summaryForRange(ExpenseDateRange range) {
    final records = receipts
        .where((receipt) => range.contains(receipt.receiptDate))
        .toList(growable: false);
    return ExpenseLedgerSummary(
      total: records.fold(0, (sum, receipt) => sum + receipt.total),
      business: records.fold(0, (sum, receipt) => sum + receipt.businessTotal),
      personal: records.fold(0, (sum, receipt) => sum + receipt.personalTotal),
      recordCount: records.length,
    );
  }

  ExpenseLedgerSummary summaryForDay(DateTime day) {
    final range = ExpenseDateRange(
      start: DateTime(day.year, day.month, day.day),
      end: DateTime(day.year, day.month, day.day),
    );
    return summaryForRange(range);
  }

  ExpenseLedgerSummary summaryForWeek(DateTime day) {
    final start = DateTime(
      day.year,
      day.month,
      day.day - (day.weekday - DateTime.monday),
    );
    return summaryForRange(
      ExpenseDateRange(start: start, end: start.add(const Duration(days: 6))),
    );
  }

  ExpenseLedgerSummary summaryForMonth(DateTime day) {
    return summaryForRange(
      ExpenseDateRange(
        start: DateTime(day.year, day.month),
        end: DateTime(day.year, day.month + 1, 0),
      ),
    );
  }

  ExpenseLedgerSummary summaryForPayPeriod(DateTime day) {
    final anchor = DateTime(2026, 1, 5);
    final current = DateTime(day.year, day.month, day.day);
    final daysSinceAnchor = current.difference(anchor).inDays;
    final periodIndex = (daysSinceAnchor / 14).floor();
    final start = anchor.add(Duration(days: periodIndex * 14));
    return summaryForRange(
      ExpenseDateRange(start: start, end: start.add(const Duration(days: 13))),
    );
  }

  Future<ExpenseReceiptRecord> saveReceipt(ExpenseReceiptRecord receipt) =>
      _enqueue(() => _saveReceipt(receipt));

  Future<ExpenseReceiptRecord> _saveReceipt(ExpenseReceiptRecord receipt) async {
    final existing = receiptById(receipt.id);
    if (existing?.isDeleted ?? false) {
      throw StateError('Restore a removed receipt before changing it.');
    }
    if (existing != null && receipt.localRevision != existing.localRevision) {
      throw StateError(
        'This receipt changed on this device. Review the latest saved version.',
      );
    }
    await ensureStorageForLocalSave();
    final now = DateTime.now();
    final audit = [
      ...receipt.auditEvents,
      '${now.toIso8601String()} ${existing == null ? 'created' : 'updated'} receipt ${receipt.id}',
    ];
    final saved = receipt.copyWith(
      createdAt: existing?.createdAt ?? receipt.createdAt ?? now,
      updatedAt: now,
      localRevision: existing == null
          ? receipt.localRevision < 1
                ? 1
                : receipt.localRevision
          : existing.localRevision + 1,
      auditEvents: audit,
    );
    if (_box == null) {
      _memoryRecords[saved.id] = saved;
    } else {
      await _box.put(saved.id, saved.toMap());
      if (saved.isActive) await _rememberReceiptItems(saved);
    }
    notifyListeners();
    return saved;
  }

  /// Imports an explicitly authorized cloud record only while its stable ID is
  /// still absent locally. Lifecycle timestamps, revision, state, and audit
  /// history are preserved exactly; restore is not a local user edit.
  Future<ExpenseReceiptRecord?> importReceiptIfMissing(
    ExpenseReceiptRecord receipt,
  ) => _enqueue(() async {
    if (receipt.id.trim().isEmpty) {
      throw ArgumentError.value(receipt.id, 'receipt.id', 'must not be empty');
    }
    if (receiptById(receipt.id) != null) return null;
    await ensureStorageForLocalSave();
    if (receiptById(receipt.id) != null) return null;
    if (_box == null) {
      _memoryRecords[receipt.id] = receipt;
    } else {
      await _box.put(receipt.id, receipt.toMap());
      if (receipt.isActive) await _rememberReceiptItems(receipt);
    }
    notifyListeners();
    return receipt;
  });

  static Future<AppStorageCheck> _defaultStorageCheck() =>
      AppStorageGuard.check(AppStoragePurpose.smallRecordWrite);

  /// Lets an entry screen reject an unsafe save before promoting proof files.
  Future<void> ensureStorageForLocalSave() async {
    final check = _storageCheck;
    if (check == null) return;
    final storage = await check();
    if (!storage.hasEnoughSpace) throw StateError(storage.blockingMessage());
  }

  Future<void> _rememberReceiptItems(ExpenseReceiptRecord receipt) async {
    try {
      final memory = await ExpenseReceiptItemMemoryStore.create();
      await memory.rememberReceipt(receipt);
    } catch (_) {
      return;
    }
  }

  Future<ExpenseReceiptRecord?> replaceLine({
    required String receiptId,
    required ExpenseReceiptLineRecord line,
  }) async {
    final receipt = receiptById(receiptId);
    if (receipt == null || receipt.isDeleted) return null;
    final lines = [
      for (final current in receipt.lines)
        if (current.id == line.id) line else current,
    ];
    return saveReceipt(receipt.copyWith(lines: lines));
  }

  Future<ExpenseReceiptRecord?> deleteLine({
    required String receiptId,
    required String lineId,
  }) async {
    final receipt = receiptById(receiptId);
    if (receipt == null || receipt.isDeleted) return null;
    final lines = [
      for (final current in receipt.lines)
        if (current.id != lineId) current,
    ];
    return saveReceipt(receipt.copyWith(lines: lines));
  }

  Future<ExpenseReceiptRecord?> deleteReceipt(String id) => _enqueue(() async {
    final existing = receiptById(id);
    if (existing == null || existing.isDeleted) return existing;
    final now = DateTime.now();
    final deleted = existing.copyWith(
      updatedAt: now,
      localRevision: existing.localRevision + 1,
      recordState: MaintainiacRecordState.deleted,
      deletedAt: now,
      auditEvents: [
        ...existing.auditEvents,
        '${now.toIso8601String()} deleted receipt ${existing.id}',
      ],
    );
    if (_box == null) {
      _memoryRecords[deleted.id] = deleted;
    } else {
      await _box.put(deleted.id, deleted.toMap());
    }
    notifyListeners();
    return deleted;
  });

  Future<ExpenseReceiptRecord?> restoreReceipt(String id) => _enqueue(() async {
    final existing = receiptById(id);
    if (existing == null || existing.isActive) return existing;
    final now = DateTime.now();
    final restored = existing.copyWith(
      updatedAt: now,
      localRevision: existing.localRevision + 1,
      recordState: MaintainiacRecordState.active,
      deletedAt: null,
      auditEvents: [
        ...existing.auditEvents,
        '${now.toIso8601String()} restored receipt ${existing.id}',
      ],
    );
    if (_box == null) {
      _memoryRecords[restored.id] = restored;
    } else {
      await _box.put(restored.id, restored.toMap());
    }
    notifyListeners();
    return restored;
  });

  Future<void> clear() async {
    _memoryRecords.clear();
    await _box?.clear();
    notifyListeners();
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  Map<String, int> _ocrRecoveryCountBy(String key) {
    final counts = <String, int>{};
    for (final receipt in storedReceipts.where((receipt) => receipt.isActive)) {
      final token = '${receipt.ocrReview.commandCenterSummary[key] ?? ''}'
          .trim();
      if (token.isEmpty) continue;
      counts[token] = (counts[token] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }
}

class ExpenseLedgerScope extends InheritedNotifier<ExpenseLedgerController> {
  const ExpenseLedgerScope({
    super.key,
    required ExpenseLedgerController controller,
    required super.child,
  }) : super(notifier: controller);

  static ExpenseLedgerController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ExpenseLedgerScope>();
    assert(scope != null, 'ExpenseLedgerScope is missing above this context.');
    return scope!.notifier!;
  }
}
