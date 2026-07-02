part of 'expense_receipt_parser.dart';

class ExpenseReceiptFieldConfidence {
  const ExpenseReceiptFieldConfidence({
    required this.fieldKey,
    required this.confidence,
    required this.needsReview,
    required this.reason,
  });

  final String fieldKey;
  final double confidence;
  final bool needsReview;
  final String reason;

  String get label {
    if (confidence >= .84 && !needsReview) return 'Good';
    if (confidence >= .58) return 'Review';
    return 'Poor';
  }

  String get confidencePercentLabel => '${(confidence * 100).round()}%';
}

class ExpenseReceiptParseQuality {
  const ExpenseReceiptParseQuality({
    required this.confidence,
    required this.needsReview,
    required this.reasons,
  });

  final double confidence;
  final bool needsReview;
  final List<String> reasons;

  String get label {
    if (confidence >= .84 && !needsReview) return 'Good';
    if (confidence >= .58) return 'Review';
    return 'Poor';
  }

  String get confidencePercentLabel => '${(confidence * 100).round()}%';
}

class ExpenseReceiptMaintenanceHint {
  const ExpenseReceiptMaintenanceHint({
    required this.itemName,
    required this.serviceType,
    required this.confidence,
    required this.evidence,
    this.detail,
    this.oilWeight,
    this.intervalMiles,
    this.intervalMonths,
    this.serviceOdometer,
    this.dueOdometer,
  });

  final String itemName;
  final String serviceType;
  final String? detail;
  final String? oilWeight;
  final int? intervalMiles;
  final int? intervalMonths;
  final int? serviceOdometer;
  final int? dueOdometer;
  final double confidence;
  final List<String> evidence;

  bool get needsReview => confidence < .84;

  String get label {
    if (confidence >= .84) return 'Good';
    if (confidence >= .58) return 'Review';
    return 'Poor';
  }
}

class ExpenseReceiptLineReview {
  const ExpenseReceiptLineReview({
    required this.lineId,
    required this.confidence,
    required this.needsReview,
    required this.reason,
    this.catalogItemName,
    this.catalogItemPath,
    this.catalogMatchConfidence,
    this.catalogMatchedTerms = const [],
  });

  final String lineId;
  final double confidence;
  final bool needsReview;
  final String reason;
  final String? catalogItemName;
  final String? catalogItemPath;
  final double? catalogMatchConfidence;
  final List<String> catalogMatchedTerms;

  bool get hasCatalogMatch => (catalogItemName ?? '').trim().isNotEmpty;

  String get label {
    if (confidence >= .84 && !needsReview) return 'Good';
    if (confidence >= .58) return 'Review';
    return 'Poor';
  }

  String get guidance {
    return switch (label) {
      'Good' => 'Matched with strong confidence.',
      'Review' => 'Review this line before saving.',
      _ => 'Low confidence. Correct the category or receipt text.',
    };
  }
}
