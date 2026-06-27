import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'expense_ledger_models.dart';
import 'expense_receipt_item_memory_store.dart';
import '../../../shared/widgets/receipt_capture/receipt_capture_models.dart';

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

  List<ExpenseAttachmentDuplicateCandidate> duplicateAttachmentCandidatesFor({
    required String fileHashSha256,
    ExpenseDuplicateAttachmentScope scope =
        ExpenseDuplicateAttachmentScope.expenses,
    List<ReceiptAttachmentRecord> currentFormAttachments = const [],
  }) {
    final hash = fileHashSha256.trim();
    if (hash.isEmpty) return const [];
    final candidates = <ExpenseAttachmentDuplicateCandidate>[];

    void addCurrentFormCandidates() {
      for (final attachment in currentFormAttachments) {
        if (attachment.fileHash.trim() == hash) {
          candidates.add(
            ExpenseAttachmentDuplicateCandidate.fromAttachment(
              attachment: attachment,
              reason: 'Already attached to this receipt form',
            ),
          );
        }
      }
    }

    void addExpenseCandidates() {
      final seenReceiptHashes = <String>{};
      for (final receipt in storedReceipts) {
        for (final attachment in receipt.attachments) {
          if (attachment.fileHash.trim() == hash) {
            seenReceiptHashes.add('${receipt.id}:$hash');
            candidates.add(
              ExpenseAttachmentDuplicateCandidate.fromAttachment(
                attachment: attachment,
                receiptId: receipt.id,
                reason: 'Already saved on an expense receipt',
              ),
            );
          }
        }
        if (receipt.fileHashSha256.trim() == hash) {
          if (seenReceiptHashes.contains('${receipt.id}:$hash')) continue;
          candidates.add(
            ExpenseAttachmentDuplicateCandidate(
              attachmentId: '',
              receiptId: receipt.id,
              linkedModule: 'expenses',
              fileHashSha256: hash,
              originalFileName: receipt.title,
              reason: 'Already saved on an expense receipt',
            ),
          );
        }
      }
    }

    switch (scope) {
      case ExpenseDuplicateAttachmentScope.currentForm:
        addCurrentFormCandidates();
      case ExpenseDuplicateAttachmentScope.expenses:
        addExpenseCandidates();
      case ExpenseDuplicateAttachmentScope.allModulesFuture:
        addCurrentFormCandidates();
        addExpenseCandidates();
    }
    return List.unmodifiable(candidates);
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
}

int _compareReceiptsForCalendarDay(
  ExpenseReceiptRecord left,
  ExpenseReceiptRecord right,
) {
  final leftMinutes = left.receiptTimeMinutes;
  final rightMinutes = right.receiptTimeMinutes;
  if (leftMinutes != null && rightMinutes != null) {
    final byEnteredTime = leftMinutes.compareTo(rightMinutes);
    if (byEnteredTime != 0) return byEnteredTime;
    return _compareCreatedOrder(left, right);
  }
  if (leftMinutes != null) return -1;
  if (rightMinutes != null) return 1;
  return _compareCreatedOrder(left, right);
}

int _compareCreatedOrder(
  ExpenseReceiptRecord left,
  ExpenseReceiptRecord right,
) {
  final leftCreated = left.createdAt;
  final rightCreated = right.createdAt;
  if (leftCreated != null && rightCreated != null) {
    final byCreated = leftCreated.compareTo(rightCreated);
    if (byCreated != 0) return byCreated;
  } else if (leftCreated != null) {
    return -1;
  } else if (rightCreated != null) {
    return 1;
  }
  return left.id.compareTo(right.id);
}

String _normalizeReceiptFingerprintText(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}

ExpenseReceiptDuplicateCandidate? _probableDuplicateCandidate(
  ExpenseReceiptRecord incoming,
  ExpenseReceiptRecord existing,
) {
  final incomingMerchant = _normalizeReceiptFingerprintText(
    incoming.merchantName,
  );
  final existingMerchant = _normalizeReceiptFingerprintText(
    existing.merchantName,
  );
  if (incomingMerchant.isEmpty || incomingMerchant != existingMerchant) {
    return null;
  }

  final sameDate = _sameReceiptDay(incoming.receiptDate, existing.receiptDate);
  final closeDate = _closeReceiptDay(
    incoming.receiptDate,
    existing.receiptDate,
  );
  final sameAmount = _sameMoney(incoming.total, existing.total);
  final similarAmount = _similarMoney(incoming.total, existing.total);
  final sameReceiptNumber = _sameRequiredText(
    incoming.receiptNumber,
    existing.receiptNumber,
  );
  final sameTax = _sameOptionalMoney(incoming.receiptTax, existing.receiptTax);
  final compatibleCategory = _compatibleOptionalText(
    incoming.primaryCategoryLabel,
    existing.primaryCategoryLabel,
  );
  final compatibleVehicle = _compatibleOptionalText(
    incoming.vehicleId ?? '',
    existing.vehicleId ?? '',
  );
  final samePaymentMethod = _sameOptionalText(
    incoming.paymentMethod,
    existing.paymentMethod,
  );

  if (sameDate && sameAmount && sameReceiptNumber) {
    return ExpenseReceiptDuplicateCandidate.fromReceipt(
      receipt: existing,
      confidence: ExpenseDuplicateConfidence.veryHigh,
      reason: 'Same store, date, total, and receipt number',
    );
  }
  if (sameDate &&
      sameAmount &&
      sameTax &&
      compatibleCategory &&
      compatibleVehicle &&
      samePaymentMethod) {
    return ExpenseReceiptDuplicateCandidate.fromReceipt(
      receipt: existing,
      confidence: ExpenseDuplicateConfidence.high,
      reason: 'Same store, date, amount, category, and vehicle',
    );
  }
  if (closeDate && (sameAmount || similarAmount)) {
    return ExpenseReceiptDuplicateCandidate.fromReceipt(
      receipt: existing,
      confidence: ExpenseDuplicateConfidence.possible,
      reason: 'Same store with a similar amount near this date',
    );
  }
  return null;
}

Set<String> _receiptHashes(ExpenseReceiptRecord receipt) {
  return {
    if (receipt.fileHashSha256.trim().isNotEmpty) receipt.fileHashSha256.trim(),
    for (final attachment in receipt.attachments)
      if (attachment.fileHash.trim().isNotEmpty) attachment.fileHash.trim(),
  };
}

String _primaryFileHash(ExpenseReceiptRecord receipt) {
  final hashes = _receiptHashes(receipt);
  return hashes.isEmpty ? '' : hashes.first;
}

bool _sameReceiptDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

bool _closeReceiptDay(DateTime first, DateTime second) {
  return first.difference(second).inDays.abs() <= 3;
}

bool _sameMoney(double first, double second) {
  return ((first * 100).round() - (second * 100).round()).abs() <= 1;
}

bool _similarMoney(double first, double second) {
  final delta = (first - second).abs();
  if (delta <= 1) return true;
  final larger = first.abs() > second.abs() ? first.abs() : second.abs();
  if (larger <= 0) return false;
  return delta / larger <= .02;
}

bool _sameOptionalMoney(double first, double second) {
  if (first == 0 || second == 0) return true;
  return _sameMoney(first, second);
}

bool _sameOptionalText(String first, String second) {
  final left = _normalizeReceiptFingerprintText(first);
  final right = _normalizeReceiptFingerprintText(second);
  if (left.isEmpty || right.isEmpty) return true;
  return left == right;
}

bool _sameRequiredText(String first, String second) {
  final left = _normalizeReceiptFingerprintText(first);
  final right = _normalizeReceiptFingerprintText(second);
  if (left.isEmpty || right.isEmpty) return false;
  return left == right;
}

bool _compatibleOptionalText(String first, String second) {
  final left = _normalizeReceiptFingerprintText(first);
  final right = _normalizeReceiptFingerprintText(second);
  if (left.isEmpty || right.isEmpty) return true;
  if (left == 'mixed' || right == 'mixed') return true;
  return left == right;
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
