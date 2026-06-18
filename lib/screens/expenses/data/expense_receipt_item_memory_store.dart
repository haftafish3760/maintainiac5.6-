import 'package:hive_flutter/hive_flutter.dart';

import 'expense_ledger_models.dart';

class ExpenseReceiptItemMemoryStore {
  ExpenseReceiptItemMemoryStore._(this._box);

  static const boxName = 'expense_receipt_item_memory';

  final Box<dynamic> _box;

  static Future<ExpenseReceiptItemMemoryStore> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return ExpenseReceiptItemMemoryStore._(box);
  }

  Future<void> rememberReceipt(ExpenseReceiptRecord receipt) async {
    final merchantKey = normalizeExpenseMemoryKey(receipt.merchantName);
    for (final line in receipt.lines) {
      final descriptionKey = normalizeExpenseMemoryKey(line.description);
      if (descriptionKey.isEmpty) continue;
      final key = '$merchantKey|$descriptionKey';
      final existing = ExpenseReceiptItemMemory.fromStored(_box.get(key));
      final saved = ExpenseReceiptItemMemory(
        id: key,
        merchantName: receipt.merchantName.trim(),
        description: line.description.trim(),
        normalizedDescription: descriptionKey,
        category: line.category.trim().isEmpty
            ? 'Uncategorized'
            : line.category.trim(),
        useName: line.use.name,
        unit: line.unit.trim().isEmpty ? 'each' : line.unit.trim(),
        quantity: line.quantity,
        unitsPerPackage: line.unitsPerPackage,
        subtotal: line.subtotal,
        unitPrice: line.unitPrice,
        seenCount: (existing?.seenCount ?? 0) + 1,
        firstSeenAt:
            existing?.firstSeenAt ?? receipt.createdAt ?? DateTime.now(),
        lastSeenAt: DateTime.now(),
      );
      await _box.put(key, saved.toMap());
    }
  }

  ExpenseReceiptItemMemory? match({
    required String merchantName,
    required String description,
  }) {
    final merchantKey = normalizeExpenseMemoryKey(merchantName);
    final descriptionKey = normalizeExpenseMemoryKey(description);
    if (descriptionKey.isEmpty) return null;
    return ExpenseReceiptItemMemory.fromStored(
      _box.get('$merchantKey|$descriptionKey'),
    );
  }
}

class ExpenseReceiptItemMemory {
  const ExpenseReceiptItemMemory({
    required this.id,
    required this.merchantName,
    required this.description,
    required this.normalizedDescription,
    required this.category,
    required this.useName,
    required this.unit,
    required this.quantity,
    required this.unitsPerPackage,
    required this.subtotal,
    required this.seenCount,
    required this.firstSeenAt,
    required this.lastSeenAt,
    this.unitPrice,
  });

  factory ExpenseReceiptItemMemory.fromMap(Map<dynamic, dynamic> map) {
    return ExpenseReceiptItemMemory(
      id: _string(map['id']),
      merchantName: _string(map['merchantName']),
      description: _string(map['description']),
      normalizedDescription: _string(map['normalizedDescription']),
      category: _string(map['category'], fallback: 'Uncategorized'),
      useName: _string(map['useName'], fallback: ExpenseLineUse.business.name),
      unit: _string(map['unit'], fallback: 'each'),
      quantity: _double(map['quantity'], fallback: 1),
      unitsPerPackage: _double(map['unitsPerPackage'], fallback: 1),
      subtotal: _double(map['subtotal']),
      unitPrice: _nullableDouble(map['unitPrice']),
      seenCount: _int(map['seenCount'], fallback: 1),
      firstSeenAt: _date(map['firstSeenAt']) ?? DateTime.now(),
      lastSeenAt: _date(map['lastSeenAt']) ?? DateTime.now(),
    );
  }

  final String id;
  final String merchantName;
  final String description;
  final String normalizedDescription;
  final String category;
  final String useName;
  final String unit;
  final double quantity;
  final double unitsPerPackage;
  final double subtotal;
  final double? unitPrice;
  final int seenCount;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;

  static ExpenseReceiptItemMemory? fromStored(Object? value) {
    if (value is Map) return ExpenseReceiptItemMemory.fromMap(value);
    return null;
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'merchantName': merchantName,
      'description': description,
      'normalizedDescription': normalizedDescription,
      'category': category,
      'useName': useName,
      'unit': unit,
      'quantity': quantity,
      'unitsPerPackage': unitsPerPackage,
      'subtotal': subtotal,
      'unitPrice': unitPrice,
      'seenCount': seenCount,
      'firstSeenAt': firstSeenAt.toIso8601String(),
      'lastSeenAt': lastSeenAt.toIso8601String(),
    };
  }
}

String normalizeExpenseMemoryKey(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}

String _string(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

double _double(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

double? _nullableDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int _int(Object? value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
