part of 'expense_receipt_item_memory_store.dart';

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
