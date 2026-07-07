part of 'work_supply_receipt_parser.dart';

double _directReceiptConfidence(
  String text,
  WorkSupplyItem item, {
  String? tradeScope,
  String originalText = '',
}) {
  final receiptText = _normalize(originalText.isEmpty ? text : originalText);
  final evidence = _directMatchedTerms(text, item);
  var confidence = 0.70 + (evidence.length * 0.035);
  if (_isPTrapReceiptMatch(receiptText, item)) confidence += 0.18;
  confidence += _specificityEvidenceScore(receiptText, item);
  confidence -= _receiptAmbiguityRisk(receiptText, item, tradeScope);
  return _boundedReceiptConfidence(confidence);
}

double _learnedCorrectionConfidence(String rawText, WorkSupplyItem item) {
  final normalized = _normalize(rawText);
  var confidence = 0.88;
  if (_withoutTrailingReceiptPrice(normalized) == normalized) {
    confidence += 0.03;
  }
  confidence += _specificityEvidenceScore(normalized, item);
  return _boundedReceiptConfidence(confidence);
}

double _trustedItemIdentityConfidence(String text, WorkSupplyItem item) {
  var confidence = 0.92;
  confidence += _specificityEvidenceScore(text, item);
  return _boundedReceiptConfidence(confidence);
}

double _vendorMappingConfidence(
  String text,
  WorkSupplyItem item, {
  String? tradeScope,
}) {
  var confidence = 0.88;
  confidence += _specificityEvidenceScore(text, item);
  confidence -= _receiptAmbiguityRisk(text, item, tradeScope) * 0.35;
  return _boundedReceiptConfidence(confidence);
}

double _specificityEvidenceScore(String text, WorkSupplyItem item) {
  var score = 0.0;
  if (_nominalReceiptSize(text) != null) score += 0.04;
  if (_receiptSizeMatrix(text) != null) score += 0.05;
  if (_receiptContainsVariantTokens(text, item.variant)) score += 0.06;
  if (_containsExactPhrase(text, item.itemType)) score += 0.04;
  if (_containsExactPhrase(text, item.system)) score += 0.04;
  final itemText = _indexedReceiptTextFor(item);
  if (RegExp(
    r'\b(sch|schedule|dwv|s40|emt|thhn|condensate|merv)\b',
  ).hasMatch(text)) {
    score += 0.05;
  }
  if (RegExp(
    r'\b(pex|cpvc|abs|copper|brass|galv|galvanized)\b',
  ).hasMatch(text)) {
    score += 0.04;
  }
  if (RegExp(
    r'\b(conduit|condensate|refrigerant|dwv|pressure)\b',
  ).hasMatch(itemText)) {
    score += 0.03;
  }
  final rawItemText = '${item.name} ${item.variant} ${item.itemType}'
      .toLowerCase();
  if (_hasPTrapReceiptPhrase(text) &&
      (rawItemText.contains('p-trap') || rawItemText.contains('p trap'))) {
    score += 0.24;
  }
  score += _plumbingCoreReceiptEvidenceScore(text, itemText);
  return score;
}

double _plumbingCoreReceiptEvidenceScore(String text, String itemText) {
  var score = 0.0;
  if (RegExp(r'\bpvc\b').hasMatch(text) &&
      RegExp(r'\b(90|90d|ell|elb|elbow)\b').hasMatch(text) &&
      itemText.contains('pvc schedule 40 90 elbow')) {
    score += 0.10;
  }
  if (RegExp(
        r'\b(reducing cplg|reducing coupling|reducer coupling)\b',
      ).hasMatch(text) &&
      itemText.contains('reducing coupling')) {
    score += 0.10;
  }
  final serviceFamilies = <RegExp, List<String>>{
    RegExp(r'\b(p trap|p-trap)\b'): ['p trap', 'p-trap'],
    RegExp(r'\bfill valve\b'): ['fill valve'],
    RegExp(r'\btank lever\b'): ['tank lever'],
    RegExp(r'\baerator\b'): ['aerator'],
    RegExp(r'\b(o ring|o-ring|oring)\b'): ['o ring', 'o-ring', 'oring'],
    RegExp(r'\bdisposal drain elb'): ['disposal drain elbow'],
    RegExp(r'\bcontinuous waste\b|\bcont waste\b'): ['continuous waste'],
    RegExp(r'\bdisposal install kit\b'): ['disposal install kit'],
    RegExp(r'\bdisposal elbow gasket\b|\bdisposal gasket\b'): [
      'disposal gasket',
      'disposal elbow gasket',
    ],
    RegExp(r'\bescutcheon\b|\besc plate\b'): ['escutcheon'],
    RegExp(
      r'\b(well pressure gauge|pressure gauge|well gauge|manometro presion pozo|manometro de presion)\b',
    ): [
      'pressure gauge',
      'well pressure gauge',
    ],
  };
  for (final entry in serviceFamilies.entries) {
    if (entry.key.hasMatch(text) &&
        entry.value.any((phrase) => itemText.contains(phrase))) {
      score += entry.value.contains('p trap') ? 0.24 : 0.16;
      break;
    }
  }
  if (RegExp(
        r'\b(well pressure gauge|pressure gauge|well gauge|manometro presion pozo|manometro de presion)\b',
      ).hasMatch(text) &&
      RegExp(r'\b(well|psi|pressure|presion|pozo)\b').hasMatch(text) &&
      itemText.contains('pressure gauge')) {
    score += 0.08;
  }
  return score;
}

bool _hasPTrapReceiptPhrase(String text) {
  final normalized = ' ${text.toLowerCase()} ';
  return normalized.contains(' p trap ') ||
      normalized.contains(' p-trap ') ||
      normalized.contains(' ptrap ');
}

bool _isPTrapReceiptMatch(String text, WorkSupplyItem item) {
  if (!_hasPTrapReceiptPhrase(text) && !text.toLowerCase().contains('trap')) {
    return false;
  }
  final itemText = '${item.name} ${item.variant} ${item.itemType}'
      .toLowerCase();
  return itemText.contains('p-trap') ||
      itemText.contains('p trap') ||
      (itemText.contains('tubular') && itemText.contains('trap'));
}

double _receiptAmbiguityRisk(
  String text,
  WorkSupplyItem item,
  String? tradeScope,
) {
  var risk = 0.0;
  if (_isAmbiguousPlumbingCoreLine(text, item)) risk += 0.18;
  if (_isUnscopedAmbiguousReceiptLine(text, item, tradeScope)) risk += 0.22;
  if (_isCrossTradePvcLine(text, item, tradeScope)) risk += 0.16;
  if (_isCrossTradeCopperLine(text, item, tradeScope)) risk += 0.34;
  if (_isGenericFilterLine(text, item, tradeScope)) risk += 0.38;
  return risk;
}

bool _isCrossTradePvcLine(
  String text,
  WorkSupplyItem item,
  String? tradeScope,
) {
  if (!RegExp(r'\bpvc\b').hasMatch(text)) return false;
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final hasTradeSpecificEvidence = RegExp(
    r'\b(dwv|sch|schedule|s40|cond|conduit|electrical|elec|emt|condensate|hvac)\b',
  ).hasMatch(text);
  if (hasTradeSpecificEvidence) return false;
  final canCrossTrades =
      item.trade == 'Plumbing' ||
      item.trade == 'Electrical' ||
      item.trade == 'HVAC';
  return canCrossTrades &&
      RegExp(r'\b(90|45|ell|el|elb|elbow|cplg|coupling|pipe)\b').hasMatch(text);
}

bool _isCrossTradeCopperLine(
  String text,
  WorkSupplyItem item,
  String? tradeScope,
) {
  if (!RegExp(r'\bcopper\b').hasMatch(text)) return false;
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  if (RegExp(
    r'\b(refrigerant|acr|hvac|water|dwv|type l|type m)\b',
  ).hasMatch(text)) {
    return false;
  }
  return item.trade == 'Plumbing' || item.trade == 'HVAC';
}

bool _isGenericFilterLine(
  String text,
  WorkSupplyItem item,
  String? tradeScope,
) {
  if (!RegExp(r'\bfilter\b').hasMatch(text)) return false;
  final hasSpecificFilterEvidence =
      _hasHvacAirFilterReceiptEvidence(text) ||
      RegExp(
        r'\b(return grille|return air grille|filter grille|water filter|'
        r'oil filter|fuel filter|pool filter|filter drier|secador)\b',
      ).hasMatch(text);
  if (hasSpecificFilterEvidence) return false;
  final itemText = _indexedReceiptTextFor(item);
  return RegExp(
    r'\b(filter|air filter|filter drier|filter grille|water filter|'
    r'oil filter|fuel filter|pool filter)\b',
  ).hasMatch(itemText);
}

double _boundedReceiptConfidence(double confidence) {
  if (confidence < 0.15) return 0.15;
  if (confidence > 0.95) return 0.95;
  return confidence;
}

bool _hasHvacAirFilterReceiptEvidence(String text) {
  if (!RegExp(r'\bfilter\b').hasMatch(text)) return false;
  if (RegExp(
    r'\b(drier|dri|secador|liquid|liq|linea|water|oil|fuel|pool|'
    r'grille|register|rack|base|housing)\b',
  ).hasMatch(text)) {
    return false;
  }
  final hasAirFilterWords = RegExp(
    r'\b(air|furnace|pleated|merv|hvac|ac)\b',
  ).hasMatch(text);
  return hasAirFilterWords && _nominalReceiptSize(text) != null;
}
