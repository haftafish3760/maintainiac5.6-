import 'package:hive_flutter/hive_flutter.dart';

import '../../work_supplies/data/work_supply_catalog.dart';
import '../../work_supplies/data/work_supply_models.dart';
import '../../work_supplies/data/work_supply_receipt_parser.dart';
import '../../../shared/receipts/receipt_ocr_contract.dart';
import '../../../shared/receipts/receipt_line_models.dart';
import '../../../shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'expense_ledger_models.dart';
import 'expense_receipt_parser.dart';

part 'expense_receipt_item_memory.dart';

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

Future<ExpenseReceiptParseResult> parseExpenseReceiptOcrResultWithLocalMemory(
  ReceiptOcrResult ocr, {
  DateTime? fallbackDate,
  ReceiptDeviceCapability? capability,
  ReceiptParserDepth? parserDepth,
  int? maxCatalogCandidates,
}) async {
  final effectiveDepth =
      parserDepth ?? capability?.parserDepth ?? ReceiptParserDepth.lineItems;
  final effectiveMaxCatalogCandidates =
      maxCatalogCandidates ??
      capability?.cloudAssistPlan.localCatalogMatchLimit ??
      80;
  final firstPass = parseExpenseReceiptOcrResult(
    ocr,
    fallbackDate: fallbackDate,
    capability: capability,
    parserDepth: effectiveDepth,
    maxCatalogCandidates: effectiveMaxCatalogCandidates,
  );
  if (effectiveDepth != ReceiptParserDepth.inventoryMatching) {
    return firstPass;
  }
  final merchantName = firstPass.merchantName?.trim();
  if (merchantName == null || merchantName.isEmpty) return firstPass;
  try {
    final store = await ExpenseReceiptItemMemoryStore.create();
    final learnedMemory = store.catalogLearningMemoryForMerchant(merchantName);
    return parseExpenseReceiptOcrResult(
      ocr,
      fallbackDate: fallbackDate,
      capability: capability,
      materialCatalogMemory: learnedMemory,
      parserDepth: effectiveDepth,
      maxCatalogCandidates: effectiveMaxCatalogCandidates,
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
