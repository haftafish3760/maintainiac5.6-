part of 'expense_receipt_parser.dart';

final _datePattern = RegExp(
  r'\b(?:\d{4}[./-]\d{1,2}[./-]\d{1,2}|\d{1,2}[./-]\d{1,2}[./-]\d{2,4})\b',
);
final _timePattern = RegExp(
  r'\b([0-2]?\d)([:.])(\d{2})(?::\d{2})?\s*(a\.?m\.?|p\.?m\.?)?\b',
  caseSensitive: false,
);

class _ReceiptTotals {
  const _ReceiptTotals({
    this.subtotal,
    this.tax,
    this.total,
    this.hasExplicitSubtotal = false,
    this.hasExplicitTax = false,
    this.hasExplicitTotal = false,
    this.splitTenderTotal,
    this.splitTenderCount = 0,
  });

  final double? subtotal;
  final double? tax;
  final double? total;
  final bool hasExplicitSubtotal;
  final bool hasExplicitTax;
  final bool hasExplicitTotal;
  final double? splitTenderTotal;
  final int splitTenderCount;

  bool get hasSplitTenderEvidence =>
      splitTenderCount > 1 && splitTenderTotal != null;

  bool get hasCompleteExplicitMath {
    return hasExplicitSubtotal &&
        hasExplicitTax &&
        hasExplicitTotal &&
        subtotal != null &&
        tax != null &&
        total != null;
  }
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
    required this.targetFuelSelected,
    required this.looksLikeFoodReceipt,
    required this.looksLikeMaterialReceipt,
    required this.looksLikeAutoServiceReceipt,
  });

  final bool looksLikeFuelReceipt;
  final bool targetFuelSelected;
  final bool looksLikeFoodReceipt;
  final bool looksLikeMaterialReceipt;
  final bool looksLikeAutoServiceReceipt;

  factory _ReceiptParseContext.fromRows(
    List<String> rows, {
    String? targetCategory,
  }) {
    final text = rows.join(' ').toLowerCase();
    final selectedFuel = targetCategory?.trim().toLowerCase() == 'fuel';
    return _ReceiptParseContext(
      looksLikeFuelReceipt:
          RegExp(
            r'\b(pump|island|nozzle|hose|fueling point|fueling position|fuel|motor fuel|combustible|gasolina|'
            r'diesel|di[eé]sel|dsl|ulsd|reefer|bomba|surtidor|'
            r'unl\b|unleaded|regular|midgrade|premium|gasoline|gallons?|'
            r'avgas|aviation gasoline|jet[-\s]?a(?:[-\s]?1)?|jet fuel|turbine fuel|turbosina|race fuel|racing fuel|combustible de carrera|nitromethane|nitrometano|e[-\s]?100|'
            r'gal\b|gal[oó]n|gal[oó]nes|def fluid|diesel exhaust fluid|'
            r'cng|compressed natural gas|gas natural comprimido|gge|'
            r'propane|lpg|l\.?p\.? gas|gas l\.?p\.?|autogas|auto gas|hd[-\s]?5|methanol|m85|m100|'
            r'kerosene|kero|queroseno|k[- ]?1|'
            r'hydrogen|h2 fuel|fuel cell|kg h2|h35|h70|'
            r'kwh|ev charge|ev charging|energy sale|energy delivered|'
            r'chargepoint|supercharger|octane|grade|'
            r'price per gallon|price/gal|precio\s*/?\s*gal[oó]n|'
            r'precio\s+por\s+gal[oó]n|ppu|ppg|amt\b|vol\b)\b',
          ).hasMatch(text) ||
          selectedFuel,
      targetFuelSelected: selectedFuel,
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
