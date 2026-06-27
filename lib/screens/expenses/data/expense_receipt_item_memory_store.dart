import 'package:hive_flutter/hive_flutter.dart';

import '../../work_supplies/data/work_supply_catalog.dart';
import '../../work_supplies/data/work_supply_models.dart';
import '../../work_supplies/data/work_supply_receipt_parser.dart';
import '../../../shared/receipts/receipt_line_models.dart';
import '../../../shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'expense_ledger_models.dart';
import 'expense_receipt_parser.dart';

Future<ExpenseReceiptParseResult> parseExpenseReceiptTextWithLocalMemory(
  String sourceText, {
  DateTime? fallbackDate,
  ReceiptParserDepth parserDepth = ReceiptParserDepth.inventoryMatching,
  int maxCatalogCandidates = 80,
}) async {
  final firstPass = parseExpenseReceiptText(
    sourceText,
    fallbackDate: fallbackDate,
    parserDepth: parserDepth,
    maxCatalogCandidates: maxCatalogCandidates,
  );
  if (parserDepth != ReceiptParserDepth.inventoryMatching) return firstPass;
  final merchantName = firstPass.merchantName?.trim();
  if (merchantName == null || merchantName.isEmpty) return firstPass;
  try {
    final store = await ExpenseReceiptItemMemoryStore.create();
    final learnedMemory = store.catalogLearningMemoryForMerchant(merchantName);
    return parseExpenseReceiptText(
      sourceText,
      fallbackDate: fallbackDate,
      materialCatalogMemory: learnedMemory,
      parserDepth: parserDepth,
      maxCatalogCandidates: maxCatalogCandidates,
    );
  } catch (_) {
    return firstPass;
  }
}

class ExpenseReceiptItemMemoryStore {
  ExpenseReceiptItemMemoryStore._(this._box);

  static const boxName = 'expense_receipt_item_memory';

  final Box<dynamic> _box;

  static Future<ExpenseReceiptItemMemoryStore> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return ExpenseReceiptItemMemoryStore._(box);
  }

  Future<void> rememberReceipt(ExpenseReceiptRecord receipt) async {
    final merchantKey = _merchantMemoryKey(receipt.merchantName);
    for (final line in receipt.lines) {
      final evidence = line.receiptEvidenceText;
      final descriptionKey = normalizeExpenseMemoryKey(evidence);
      if (descriptionKey.isEmpty) continue;
      final key = '$merchantKey|$descriptionKey';
      final existing = ExpenseReceiptItemMemory.fromStored(_box.get(key));
      final catalogItemId = _nullableString(line.catalogItemId);
      final catalogItemName = _nullableString(line.catalogItemName);
      final catalogItemPath = _nullableString(line.catalogItemPath);
      final saved = ExpenseReceiptItemMemory(
        id: key,
        merchantName: receipt.merchantName.trim(),
        description: evidence.trim(),
        normalizedDescription: descriptionKey,
        rawReceiptText: line.rawReceiptText.trim(),
        correctedDescription: line.description.trim(),
        category: line.category.trim().isEmpty
            ? 'Uncategorized'
            : line.category.trim(),
        useName: line.use.name,
        unit: line.unit.trim().isEmpty ? 'each' : line.unit.trim(),
        quantity: line.quantity,
        unitsPerPackage: line.unitsPerPackage,
        subtotal: line.subtotal,
        unitPrice: line.unitPrice,
        catalogItemId: catalogItemId ?? existing?.catalogItemId,
        catalogItemName: catalogItemName ?? existing?.catalogItemName,
        catalogItemPath: catalogItemPath ?? existing?.catalogItemPath,
        catalogMatchConfidence:
            line.catalogMatchConfidence ?? existing?.catalogMatchConfidence,
        catalogMatchedTerms: line.catalogMatchedTerms.isEmpty
            ? existing?.catalogMatchedTerms ?? const []
            : line.catalogMatchedTerms,
        parserConfidence: line.parserConfidence ?? existing?.parserConfidence,
        parserReviewLabel:
            line.parserReviewLabel ?? existing?.parserReviewLabel,
        parserReviewReason:
            line.parserReviewReason ?? existing?.parserReviewReason,
        parserNeedsReview: line.parserNeedsReview,
        reviewAction: existing?.reviewAction ?? 'saved',
        seenCount: (existing?.seenCount ?? 0) + 1,
        firstSeenAt:
            existing?.firstSeenAt ?? receipt.createdAt ?? DateTime.now(),
        lastSeenAt: DateTime.now(),
      );
      await _box.put(key, saved.toMap());
    }
  }

  Future<void> rememberMaterialsReceiptLines({
    required String merchantName,
    required Iterable<ReceiptLineDraft> lines,
  }) async {
    final merchantKey = _merchantMemoryKey(merchantName);
    if (merchantKey.isEmpty) return;
    for (final line in lines) {
      final rawText = line.rawReceiptText.trim();
      final description = rawText.isEmpty ? line.description.trim() : rawText;
      final descriptionKey = normalizeExpenseMemoryKey(description);
      if (descriptionKey.isEmpty) continue;
      final key = '$merchantKey|$descriptionKey';
      final existing = ExpenseReceiptItemMemory.fromStored(_box.get(key));
      final saved = ExpenseReceiptItemMemory(
        id: key,
        merchantName: merchantName.trim(),
        description: description,
        normalizedDescription: descriptionKey,
        rawReceiptText: rawText,
        correctedDescription: line.description.trim(),
        category: line.expenseCategory.trim().isEmpty
            ? line.receiptLaneLabel
            : line.expenseCategory.trim(),
        useName: _expenseUseNameForReceiptLine(line),
        unit: line.unit.trim().isEmpty ? 'each' : line.unit.trim(),
        quantity: line.quantity,
        unitsPerPackage: line.unitsPerPackage,
        subtotal: line.subtotal,
        unitPrice: line.unitCostWithTax,
        catalogItemId:
            _nullableString(line.inventoryItemId) ?? existing?.catalogItemId,
        catalogItemName: line.isInventory
            ? line.description.trim()
            : existing?.catalogItemName,
        catalogItemPath:
            _nullableString(line.inventoryPath) ?? existing?.catalogItemPath,
        catalogMatchConfidence:
            line.catalogMatchConfidence ?? existing?.catalogMatchConfidence,
        catalogMatchedTerms: line.catalogMatchedTerms.isEmpty
            ? existing?.catalogMatchedTerms ?? const []
            : line.catalogMatchedTerms,
        parserConfidence: line.parserConfidence ?? existing?.parserConfidence,
        parserReviewLabel:
            line.parserReviewLabel ?? existing?.parserReviewLabel,
        parserReviewReason:
            line.parserReviewReason ?? existing?.parserReviewReason,
        parserNeedsReview: line.parserNeedsReview,
        reviewAction: line.reviewAction,
        seenCount: (existing?.seenCount ?? 0) + 1,
        firstSeenAt: existing?.firstSeenAt ?? DateTime.now(),
        lastSeenAt: DateTime.now(),
      );
      await _box.put(key, saved.toMap());
    }
  }

  ExpenseReceiptItemMemory? match({
    required String merchantName,
    required String description,
  }) {
    final merchantKey = _merchantMemoryKey(merchantName);
    final descriptionKey = normalizeExpenseMemoryKey(description);
    if (descriptionKey.isEmpty) return null;
    return ExpenseReceiptItemMemory.fromStored(
      _box.get('$merchantKey|$descriptionKey'),
    );
  }

  ReceiptParserLearningMemory catalogLearningMemoryForMerchant(
    String merchantName,
  ) {
    final merchantKey = _merchantMemoryKey(merchantName);
    final memory = ReceiptParserLearningMemory();
    for (final value in _box.values) {
      final saved = ExpenseReceiptItemMemory.fromStored(value);
      if (saved == null || !saved.hasCatalogMatch) continue;
      if (!saved.isUserTaughtCatalogMatch) continue;
      if (_merchantMemoryKey(saved.merchantName) != merchantKey) {
        continue;
      }
      final item = _catalogItemById(saved.catalogItemId);
      if (item == null) continue;
      for (final phrase in saved.learningPhrases) {
        memory.confirmCorrection(receiptLine: phrase, item: item);
      }
    }
    return memory;
  }
}

Iterable<String> _receiptMemoryLearningPhrases(String description) sync* {
  final clean = description.trim();
  if (clean.isEmpty) return;
  yield clean;
  final withoutTrailingMoney = clean
      .replaceFirst(RegExp(r'\s+\$?\d+\.\d{2}$'), '')
      .trim();
  if (withoutTrailingMoney.isNotEmpty && withoutTrailingMoney != clean) {
    yield withoutTrailingMoney;
  }
}

String _expenseUseNameForReceiptLine(ReceiptLineDraft line) {
  if (line.isPersonalUse) return ExpenseLineUse.personal.name;
  if (line.isSplitUse) return ExpenseLineUse.split.name;
  return ExpenseLineUse.business.name;
}

WorkSupplyItem? _catalogItemById(String? itemId) {
  final normalizedId = itemId?.trim();
  if (normalizedId == null || normalizedId.isEmpty) return null;
  for (final item in workSupplyCatalogItems) {
    if (item.id == normalizedId) return item;
  }
  return null;
}

class ExpenseReceiptItemMemory {
  const ExpenseReceiptItemMemory({
    required this.id,
    required this.merchantName,
    required this.description,
    required this.normalizedDescription,
    this.rawReceiptText = '',
    this.correctedDescription = '',
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
    this.catalogItemId,
    this.catalogItemName,
    this.catalogItemPath,
    this.catalogMatchConfidence,
    this.catalogMatchedTerms = const [],
    this.parserConfidence,
    this.parserReviewLabel,
    this.parserReviewReason,
    this.parserNeedsReview = false,
    this.reviewAction = 'saved',
  });

  factory ExpenseReceiptItemMemory.fromMap(Map<dynamic, dynamic> map) {
    return ExpenseReceiptItemMemory(
      id: _string(map['id']),
      merchantName: _string(map['merchantName']),
      description: _string(map['description']),
      normalizedDescription: _string(map['normalizedDescription']),
      rawReceiptText: _string(map['rawReceiptText']),
      correctedDescription: _string(map['correctedDescription']),
      category: _string(map['category'], fallback: 'Uncategorized'),
      useName: _string(map['useName'], fallback: ExpenseLineUse.business.name),
      unit: _string(map['unit'], fallback: 'each'),
      quantity: _double(map['quantity'], fallback: 1),
      unitsPerPackage: _double(map['unitsPerPackage'], fallback: 1),
      subtotal: _double(map['subtotal']),
      unitPrice: _nullableDouble(map['unitPrice']),
      catalogItemId: _nullableString(map['catalogItemId']),
      catalogItemName: _nullableString(map['catalogItemName']),
      catalogItemPath: _nullableString(map['catalogItemPath']),
      catalogMatchConfidence: _nullableDouble(map['catalogMatchConfidence']),
      catalogMatchedTerms:
          (map['catalogMatchedTerms'] as List?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const [],
      parserConfidence: _nullableDouble(map['parserConfidence']),
      parserReviewLabel: _nullableString(map['parserReviewLabel']),
      parserReviewReason: _nullableString(map['parserReviewReason']),
      parserNeedsReview: map['parserNeedsReview'] as bool? ?? false,
      reviewAction: _string(map['reviewAction'], fallback: 'saved'),
      seenCount: _int(map['seenCount'], fallback: 1),
      firstSeenAt: _date(map['firstSeenAt']) ?? DateTime.now(),
      lastSeenAt: _date(map['lastSeenAt']) ?? DateTime.now(),
    );
  }

  final String id;
  final String merchantName;
  final String description;
  final String normalizedDescription;
  final String rawReceiptText;
  final String correctedDescription;
  final String category;
  final String useName;
  final String unit;
  final double quantity;
  final double unitsPerPackage;
  final double subtotal;
  final double? unitPrice;
  final String? catalogItemId;
  final String? catalogItemName;
  final String? catalogItemPath;
  final double? catalogMatchConfidence;
  final List<String> catalogMatchedTerms;
  final double? parserConfidence;
  final String? parserReviewLabel;
  final String? parserReviewReason;
  final bool parserNeedsReview;
  final String reviewAction;
  final int seenCount;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;

  bool get hasCatalogMatch => (catalogItemId ?? '').trim().isNotEmpty;
  bool get isUserTaughtCatalogMatch {
    if (!hasCatalogMatch) return false;
    return reviewAction == 'confirmed' ||
        reviewAction == 'edited' ||
        reviewAction == 'saved';
  }

  Iterable<String> get learningPhrases sync* {
    for (final source in [description, rawReceiptText, correctedDescription]) {
      yield* _receiptMemoryLearningPhrases(source);
    }
  }

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
      'rawReceiptText': rawReceiptText,
      'correctedDescription': correctedDescription,
      'category': category,
      'useName': useName,
      'unit': unit,
      'quantity': quantity,
      'unitsPerPackage': unitsPerPackage,
      'subtotal': subtotal,
      'unitPrice': unitPrice,
      'catalogItemId': catalogItemId,
      'catalogItemName': catalogItemName,
      'catalogItemPath': catalogItemPath,
      'catalogMatchConfidence': catalogMatchConfidence,
      'catalogMatchedTerms': catalogMatchedTerms,
      'parserConfidence': parserConfidence,
      'parserReviewLabel': parserReviewLabel,
      'parserReviewReason': parserReviewReason,
      'parserNeedsReview': parserNeedsReview,
      'reviewAction': reviewAction,
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

String _merchantMemoryKey(String value) {
  final aliased = normalizeMerchantName(value);
  return normalizeExpenseMemoryKey(aliased.isEmpty ? value : aliased);
}

String _string(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

String? _nullableString(Object? value) {
  final text = _string(value);
  return text.isEmpty ? null : text;
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
