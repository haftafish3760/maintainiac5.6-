part of 'expense_receipt_parser.dart';

class ExpenseReceiptParseResult {
  const ExpenseReceiptParseResult({
    required this.sourceText,
    required this.lines,
    this.lineReviews = const [],
    this.merchantName,
    this.receiptDate,
    this.receiptTimeMinutes,
    this.enteredSubtotal,
    this.enteredTax,
    this.enteredTotal,
    this.quality = const ExpenseReceiptParseQuality(
      confidence: 0,
      needsReview: true,
      reasons: ['Receipt text has not been parsed yet.'],
    ),
    this.maintenanceHints = const [],
    this.warnings = const [],
  });

  final String sourceText;
  final String? merchantName;
  final DateTime? receiptDate;
  final int? receiptTimeMinutes;
  final double? enteredSubtotal;
  final double? enteredTax;
  final double? enteredTotal;
  final ExpenseReceiptParseQuality quality;
  final List<ExpenseReceiptMaintenanceHint> maintenanceHints;
  final List<ExpenseReceiptLineRecord> lines;
  final List<ExpenseReceiptLineReview> lineReviews;
  final List<String> warnings;

  bool get hasUsableData {
    return merchantName != null ||
        receiptDate != null ||
        receiptTimeMinutes != null ||
        enteredSubtotal != null ||
        enteredTax != null ||
        enteredTotal != null ||
        lines.isNotEmpty;
  }
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
  });

  final String lineId;
  final double confidence;
  final bool needsReview;
  final String reason;

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
