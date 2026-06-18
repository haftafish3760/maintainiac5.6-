part of 'expense_receipt_parser.dart';

final _datePattern = RegExp(
  r'\b(?:\d{4}[/-]\d{1,2}[/-]\d{1,2}|\d{1,2}[/-]\d{1,2}[/-]\d{2,4})\b',
);
final _timePattern = RegExp(
  r'\b(\d{1,2}):(\d{2})\s*(am|pm)?\b',
  caseSensitive: false,
);

class _ReceiptTotals {
  const _ReceiptTotals({this.subtotal, this.tax, this.total});

  final double? subtotal;
  final double? tax;
  final double? total;
}

class _ParsedQuantity {
  const _ParsedQuantity({
    required this.quantity,
    required this.unitsPerPackage,
    required this.unit,
  });

  final double quantity;
  final double unitsPerPackage;
  final String unit;
}

class _ParsedReceiptLine {
  const _ParsedReceiptLine({required this.record, required this.review});

  final ExpenseReceiptLineRecord record;
  final ExpenseReceiptLineReview review;
}

class _ReceiptParseContext {
  const _ReceiptParseContext({
    required this.looksLikeFuelReceipt,
    required this.looksLikeFoodReceipt,
    required this.looksLikeMaterialReceipt,
    required this.looksLikeAutoServiceReceipt,
  });

  final bool looksLikeFuelReceipt;
  final bool looksLikeFoodReceipt;
  final bool looksLikeMaterialReceipt;
  final bool looksLikeAutoServiceReceipt;

  factory _ReceiptParseContext.fromRows(List<String> rows) {
    final text = rows.join(' ').toLowerCase();
    return _ReceiptParseContext(
      looksLikeFuelReceipt: RegExp(
        r'\b(pump|island|fuel|motor fuel|diesel|dsl|ulsd|reefer|unl\b|unleaded|regular|midgrade|premium|gasoline|gallons?|gal\b|def fluid|diesel exhaust fluid|kwh|ev charge|chargepoint|supercharger|octane|grade|price per gallon|price/gal|ppu|ppg)\b',
      ).hasMatch(text),
      looksLikeFoodReceipt: RegExp(
        r'\b(combo|meal|sandwich|burger|fries|drink|coffee|breakfast|lunch|dinner|taco|biscuit|restaurant)\b',
      ).hasMatch(text),
      looksLikeMaterialReceipt: RegExp(
        r'\b(lumber|stud|pipe|pvc|cpvc|pex|copper|fitting|wire|breaker|drywall|paint|primer|fastener|screw|nail|duct|roofing|shingle|romex|conduit|valve|coupling|elbow|sealant|adhesive|plywood|osb)\b',
      ).hasMatch(text),
      looksLikeAutoServiceReceipt: RegExp(
        r'\b(oil change|tire rotation|alignment|repair order|service advisor|shop supplies|labor|diagnostic)\b',
      ).hasMatch(text),
    );
  }

  bool get hasStrongCategorySignal =>
      looksLikeFuelReceipt ||
      looksLikeFoodReceipt ||
      looksLikeMaterialReceipt ||
      looksLikeAutoServiceReceipt;
}

class _CategoryMatch {
  const _CategoryMatch({
    required this.category,
    required this.confidence,
    required this.reason,
  });

  final String category;
  final double confidence;
  final String reason;

  _CategoryMatch copyWith({
    String? category,
    double? confidence,
    String? reason,
  }) {
    return _CategoryMatch(
      category: category ?? this.category,
      confidence: confidence ?? this.confidence,
      reason: reason ?? this.reason,
    );
  }
}

class _CategoryKeywordRule {
  const _CategoryKeywordRule({
    required this.category,
    required this.pattern,
    required this.confidence,
    required this.reason,
  });

  final String category;
  final RegExp pattern;
  final double confidence;
  final String reason;

  _CategoryMatch get match {
    return _CategoryMatch(
      category: category,
      confidence: confidence,
      reason: reason,
    );
  }
}

class _MerchantProfile {
  const _MerchantProfile({
    required this.displayName,
    required this.pattern,
    this.defaultCategory,
    this.secondaryCategories = const [],
  });

  final String displayName;
  final RegExp pattern;
  final String? defaultCategory;
  final List<String> secondaryCategories;
}
