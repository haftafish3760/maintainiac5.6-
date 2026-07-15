import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ExpenseReceiptDeletionRecord {
  const ExpenseReceiptDeletionRecord({
    required this.receiptId,
    required this.deletedAt,
  });

  factory ExpenseReceiptDeletionRecord.fromMap(Map<dynamic, dynamic> map) =>
      ExpenseReceiptDeletionRecord(
        receiptId: map['receiptId']?.toString().trim() ?? '',
        deletedAt:
            DateTime.tryParse(map['deletedAt']?.toString() ?? '') ??
            DateTime.now().toUtc(),
      );

  final String receiptId;
  final DateTime deletedAt;

  Map<String, Object?> toMap() => {
    'receiptId': receiptId,
    'deletedAt': deletedAt.toUtc().toIso8601String(),
  };
}

class ExpenseReceiptDeletionController extends ChangeNotifier {
  ExpenseReceiptDeletionController._(this._box);
  ExpenseReceiptDeletionController.memory() : _box = null;

  static const boxName = 'expense_receipt_deletions';
  final Box<dynamic>? _box;
  final Map<String, ExpenseReceiptDeletionRecord> _memory = {};

  static Future<ExpenseReceiptDeletionController> create() async =>
      ExpenseReceiptDeletionController._(await Hive.openBox<dynamic>(boxName));

  List<ExpenseReceiptDeletionRecord> get pendingTombstones {
    final values = _box == null
        ? _memory.values.toList(growable: false)
        : _box.values.toList(growable: false);
    return values
        .map(
          (value) => value is ExpenseReceiptDeletionRecord
              ? value
              : value is Map
              ? ExpenseReceiptDeletionRecord.fromMap(value)
              : null,
        )
        .whereType<ExpenseReceiptDeletionRecord>()
        .where((record) => record.receiptId.isNotEmpty)
        .toList(growable: false)
      ..sort((a, b) => a.deletedAt.compareTo(b.deletedAt));
  }

  Future<void> recordDeletion(String receiptId, {DateTime? deletedAt}) async {
    final id = receiptId.trim();
    if (id.isEmpty) return;
    final record = ExpenseReceiptDeletionRecord(
      receiptId: id,
      deletedAt: (deletedAt ?? DateTime.now()).toUtc(),
    );
    if (_box == null) {
      _memory[id] = record;
    } else {
      await _box.put(id, record.toMap());
    }
    notifyListeners();
  }

  Future<void> markUploaded(String receiptId) async {
    final id = receiptId.trim();
    if (_box == null) {
      _memory.remove(id);
    } else {
      await _box.delete(id);
    }
    notifyListeners();
  }
}

class ExpenseReceiptDeletionScope
    extends InheritedNotifier<ExpenseReceiptDeletionController> {
  const ExpenseReceiptDeletionScope({
    super.key,
    required ExpenseReceiptDeletionController controller,
    required super.child,
  }) : super(notifier: controller);

  static ExpenseReceiptDeletionController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ExpenseReceiptDeletionScope>();
    assert(scope != null, 'ExpenseReceiptDeletionScope was not found.');
    return scope!.notifier!;
  }
}
