part of 'expense_receipt_parser.dart';

bool _hasSpecificItemCategory(String text) {
  final itemText = text
      .replaceAll(
        RegExp(
          r'\b(coupon|mfr coupon|manufacturer coupon|promo|promotion|'
          r'discount|disc|descuento|descuentos|markdown|price match|price adjustment|savings|'
          r'saved|reward|rewards|loyalty|member savings|fuel rewards?|'
          r'fuel perks?|return|returned|refund|credit|store credit|rebate|'
          r'instant rebate)\b',
        ),
        ' ',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (itemText.isEmpty) return false;
  return _categoryRules.any((rule) => rule.pattern.hasMatch(itemText));
}

_CategoryMatch? _contextDefaultMatch(
  String text,
  _MerchantProfile? merchantProfile,
  _ReceiptParseContext context,
) {
  if (!context.hasStrongCategorySignal) return null;
  final secondary = merchantProfile?.secondaryCategories ?? const <String>[];
  if (context.looksLikeFuelReceipt &&
      ((merchantProfile?.defaultCategory == 'Fuel' &&
              _looksLikeFuelMeasuredLine(text)) ||
          _looksLikeStrongFuelReceiptLine(text) ||
          _looksLikeEvEnergyReceiptLine(text) ||
          (secondary.contains('Fuel') &&
              _looksLikeGenericMerchantLine(text)))) {
    return const _CategoryMatch(
      category: 'Fuel',
      confidence: .86,
      reason: 'Receipt-level fuel signals matched this merchant.',
    );
  }
  if (context.looksLikeAutoServiceReceipt &&
      (secondary.contains('Maintenance') || secondary.contains('Repair')) &&
      _looksLikeGenericMerchantLine(text)) {
    return const _CategoryMatch(
      category: 'Maintenance',
      confidence: .78,
      reason: 'Receipt-level vehicle service signals matched this merchant.',
    );
  }
  if (context.looksLikeMaterialReceipt &&
      secondary.contains('Materials') &&
      (_looksLikeGenericMerchantLine(text) ||
          _looksLikeGenericMaterialSupplyLine(text))) {
    return const _CategoryMatch(
      category: 'Materials',
      confidence: .78,
      reason: 'Receipt-level material signals matched this merchant.',
    );
  }
  if (context.looksLikeFoodReceipt &&
      secondary.contains('Meals') &&
      _looksLikeGenericMerchantLine(text)) {
    return const _CategoryMatch(
      category: 'Meals',
      confidence: .78,
      reason: 'Receipt-level food signals matched this merchant.',
    );
  }
  return null;
}

_CategoryMatch _merchantAdjustedMatch(
  _CategoryMatch match,
  _MerchantProfile? merchantProfile,
) {
  final defaultCategory = merchantProfile?.defaultCategory;
  if (defaultCategory == null) return match;
  if (defaultCategory == match.category) {
    return match.copyWith(
      confidence: (match.confidence + .04).clamp(0, 1).toDouble(),
      reason: '${match.reason} Merchant profile agrees.',
    );
  }
  if (merchantProfile!.secondaryCategories.contains(match.category)) {
    return match.copyWith(
      confidence: (match.confidence + .02).clamp(0, 1).toDouble(),
      reason: '${match.reason} Merchant profile allows this category.',
    );
  }
  return match.copyWith(
    confidence: (match.confidence - .08).clamp(0, 1).toDouble(),
    reason: '${match.reason} Merchant profile suggests checking this category.',
  );
}

bool _looksLikeGenericMerchantLine(String text) {
  return RegExp(
    r'\b(monthly|service|payment|premium|bill|renewal|plan|account|charge)\b',
  ).hasMatch(text);
}

bool _looksLikeGenericMaterialSupplyLine(String text) {
  return RegExp(
    r'\b(?:\d+(?:/\d+)?(?:x\d+(?:x\d+)?)?|[a-z0-9#/-]{2,})\b',
  ).hasMatch(text);
}

bool _looksLikeEvEnergyReceiptLine(String text) {
  return RegExp(
    r'\b(?:energy|energia|energ[ií]a|sesi[oó]n de carga|carga el[eé]ctrica|carga ev)\b',
  ).hasMatch(text);
}

bool _looksLikeFuelMeasuredLine(String text) {
  return RegExp(
    r'\b(gallons?|galns|gals?|gal\b|liters?|litres?|litros?|vol(?:ume)?|amt\b|kwh|kg|gge|cng|compressed natural gas|e[-\s]?(?:10|15|20|30|50|85)|ethanol|flex\s*fuel|gasohol|propane|lpg|l\.?p\.? gas|gas l\.?p\.?|autogas|hd[- ]?5|methanol|m85|m100|kerosene|kero|queroseno|k[- ]?1|hydrogen|h2 fuel|fuel cell|h35|h70|price\s*/\s*g(?:al)?|price\s*/\s*gge|price\s*/\s*kg|price\s*per\s*gal|\$\s*/\s*gal|ppu|ppg|ppl|ppge|ppkg|fuel amount|fuel amt|amount|fuel sale|fuel total)\b',
  ).hasMatch(text);
}

bool _looksLikeStrongFuelReceiptLine(String text) {
  return RegExp(
    r'\b(unleaded|regular|midgrade|premium|diesel|di[eé]sel|def|'
    r'gasoline|gasolina|c[0o]mbustible|e[-\s]?(?:10|15|20|30|50|85)|ethanol|flex\s*fuel|gasohol|propane|lpg|l\.?p\.? gas|gas l\.?p\.?|autogas|auto gas|hd[- ]?5|methanol|m85|m100|kerosene|kero|queroseno|k[- ]?1|hydrogen|h2 fuel|fuel cell|h35|h70|'
    r'avgas|aviation gasoline|jet[-\s]?a(?:[-\s]?1)?|jet fuel|turbine fuel|turbosina|race fuel|racing fuel|combustible de carrera|nitromethane|nitrometano|e[-\s]?100|'
    r'electric|charging|chargepoint|supercharger|sesi[oó]n de carga|'
    r'fuel sale|fuel total|'
    r'energy sale|energy delivered|'
    r'fuel amount|fuel amt|gallons?|galns|gals?|gal\b|liters?|litres?|litros?|vol(?:ume)?|amt\b|kwh|kg|gge|cng|e[-\s]?(?:10|15|20|30|50|85)|ethanol|flex\s*fuel|gasohol|propane|lpg|l\.?p\.? gas|gas l\.?p\.?|hd[- ]?5|methanol|m85|m100|kerosene|kero|queroseno|k[- ]?1|hydrogen|h35|h70|'
    r'price\s*/\s*g(?:al)?|price\s*/\s*kwh|price\s*per\s*gal|'
    r'price\s*per\s*kwh|\$\s*/\s*gal|\$\s*/\s*kwh|ppu|ppg|ppl)\b',
  ).hasMatch(text);
}

ExpenseReceiptLineReview _reviewForLine({
  required String lineId,
  required String description,
  required double amount,
  required _CategoryMatch categoryMatch,
  required _ParsedQuantity quantity,
  required bool catalogMatchingEnabled,
  ReceiptLineMatch? materialCatalogMatch,
}) {
  var confidence = categoryMatch.confidence;
  final reasons = <String>[categoryMatch.reason];
  if (materialCatalogMatch != null) {
    confidence = (confidence + (materialCatalogMatch.confidence * .16)).clamp(
      0,
      1,
    );
    reasons.add(
      'Inventory catalog suggests ${materialCatalogMatch.item.name}.',
    );
    if (materialCatalogMatch.needsReview) {
      reasons.add(materialCatalogMatch.confidenceGuidance);
    }
  } else if (categoryMatch.category == 'Materials' && catalogMatchingEnabled) {
    confidence -= .08;
    reasons.add('No inventory catalog item matched this material line.');
  } else if (categoryMatch.category == 'Materials') {
    reasons.add(
      'Inventory catalog matching was skipped for the current performance mode.',
    );
  }
  if (categoryMatch.category == 'Uncategorized') {
    confidence -= .1;
    reasons.add('Choose an expense category.');
  }
  if (description.length <= 4) {
    confidence -= .12;
    reasons.add('Description is very short.');
  }
  if (amount < 0) {
    final adjustment = _negativeReceiptLineType(description.toLowerCase());
    if (adjustment == null) {
      confidence -= .08;
      reasons.add('Negative receipt line is missing an adjustment label.');
    } else {
      confidence = (confidence + .04).clamp(0, 1).toDouble();
      reasons.add('Negative amount is a recognized receipt $adjustment line.');
    }
  } else if (amount == 0) {
    confidence -= .2;
    reasons.add('Amount needs review.');
  }
  if (quantity.quantity <= 0 || quantity.unitsPerPackage <= 0) {
    confidence -= .15;
    reasons.add('Quantity needs review.');
  }
  confidence = confidence.clamp(0, 1).toDouble();
  return ExpenseReceiptLineReview(
    lineId: lineId,
    confidence: confidence,
    needsReview: confidence < .84 || categoryMatch.category == 'Uncategorized',
    reason: reasons.join(' '),
    catalogItemName: materialCatalogMatch?.item.name,
    catalogItemPath: materialCatalogMatch?.item.path,
    catalogMatchConfidence: materialCatalogMatch?.confidence,
    catalogMatchedTerms: materialCatalogMatch?.matchedTerms ?? const [],
  );
}

String _titleCase(String value) {
  return value
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) {
        if (part.length == 1) return part.toUpperCase();
        return part[0].toUpperCase() + part.substring(1).toLowerCase();
      })
      .join(' ');
}

String _parserExpenseFamilyForCategory({
  required String category,
  required String rawRow,
  required String description,
}) {
  final categoryToken = category.trim().toLowerCase();
  if (categoryToken == 'materials') return 'materials';
  if (categoryToken == 'fuel') return 'fuel';
  if (categoryToken == 'receipt adjustment') return 'receipt_adjustment';
  if (categoryToken == 'uncategorized') return 'uncategorized';
  if (categoryToken == 'supplies') return 'business_supplies';
  if (categoryToken == 'meals' ||
      categoryToken == 'food' ||
      categoryToken == 'groceries' ||
      categoryToken == 'grocery') {
    return 'food_or_grocery';
  }
  if (categoryToken == 'vehicle' || categoryToken == 'vehicle supplies') {
    return 'vehicle_supplies';
  }
  final clean = '$rawRow $description'.toLowerCase();
  if (RegExp(
    r'\b(?:pvc|pipe|coupling|fitting|oatey|plumber|putt|putty|wire|'
    r'lumber|screw|scrw|bolt|valve|glue)\b',
  ).hasMatch(clean)) {
    return 'materials';
  }
  if (RegExp(
    r'\b(?:fuel|diesel|gasoline|unleaded|pump|gallon|cng|gge|propane|lpg|autogas|hydrogen|h2)\b',
  ).hasMatch(clean)) {
    return 'fuel';
  }
  if (RegExp(
    r'\b(?:oil|filter|tire|brake|coolant|wiper|battery)\b',
  ).hasMatch(clean)) {
    return 'vehicle_supplies';
  }
  return 'general_expense';
}

String _parserHintForCategory({
  required String expenseFamily,
  required double amount,
}) {
  final family = expenseFamily.trim().isEmpty
      ? 'general_expense'
      : expenseFamily.trim();
  return amount > 0 ? '${family}_item_price' : '${family}_item_missing_price';
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';

double _roundMoney(double value) => (value * 100).roundToDouble() / 100;
