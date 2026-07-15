import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'expense_ledger_models.dart';
import 'expense_ledger_scope_filter.dart';
import 'expense_receipt_item_memory_store.dart';
import '../../../shared/widgets/receipt_capture/receipt_capture_models.dart';

part 'expense_ledger_attachment_duplicates.dart';
part 'expense_ledger_duplicate_helpers.dart';

class ExpenseLedgerController extends ChangeNotifier {
  ExpenseLedgerController._(this._box);
  ExpenseLedgerController.memory() : _box = null;

  static const boxName = 'expense_ledger_receipts';

  final Box<dynamic>? _box;
  final _memoryRecords = <String, ExpenseReceiptRecord>{};

  static Future<ExpenseLedgerController> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return ExpenseLedgerController._(box);
  }

  List<ExpenseReceiptRecord> get receipts {
    final records = storedReceipts;
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
        .where((receipt) => receipt.ocrReview.needsReview)
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
      if (existing.id == receipt.id) continue;
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

  List<ExpenseReceiptRecord> receiptsForRange(
    ExpenseDateRange range, {
    ExpenseLedgerScopeFilter scope = const ExpenseLedgerScopeFilter(),
  }) {
    return receipts
        .where((receipt) => range.contains(receipt.receiptDate))
        .where(scope.matches)
        .toList(growable: false);
  }

  ExpenseLedgerSummary summaryForRange(
    ExpenseDateRange range, {
    ExpenseLedgerScopeFilter scope = const ExpenseLedgerScopeFilter(),
  }) {
    final records = receiptsForRange(range, scope: scope);
    return ExpenseLedgerSummary(
      totalCents: records.fold(0, (sum, receipt) => sum + receipt.totalCents),
      businessCents: records.fold(
        0,
        (sum, receipt) => sum + receipt.businessTotalCents,
      ),
      personalCents: records.fold(
        0,
        (sum, receipt) => sum + receipt.personalTotalCents,
      ),
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

  Future<ExpenseReceiptRecord> saveReceipt(ExpenseReceiptRecord receipt) async {
    final now = DateTime.now();
    final existing = receiptById(receipt.id);
    final audit = [
      ...receipt.auditEvents,
      '${now.toIso8601String()} ${existing == null ? 'created' : 'updated'} receipt ${receipt.id}',
    ];
    final saved = receipt.copyWith(
      createdAt: existing?.createdAt ?? receipt.createdAt ?? now,
      updatedAt: now,
      auditEvents: audit,
    );
    if (_box == null) {
      _memoryRecords[saved.id] = saved;
    } else {
      await _box.put(saved.id, saved.toMap());
      await _rememberReceiptItems(saved);
    }
    notifyListeners();
    return saved;
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
    if (receipt == null) return null;
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
    if (receipt == null) return null;
    final lines = [
      for (final current in receipt.lines)
        if (current.id != lineId) current,
    ];
    return saveReceipt(receipt.copyWith(lines: lines));
  }

  Future<void> deleteReceipt(String id) async {
    if (_box == null) {
      _memoryRecords.remove(id);
    } else {
      await _box.delete(id);
    }
    notifyListeners();
  }

  Future<void> clear() async {
    _memoryRecords.clear();
    await _box?.clear();
    notifyListeners();
  }

  Map<String, int> _ocrRecoveryCountBy(String key) {
    final counts = <String, int>{};
    for (final receipt in storedReceipts) {
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
