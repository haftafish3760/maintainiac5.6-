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
  return score;
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
  if (_isGenericFilterLine(text, item, tradeScope)) risk += 0.14;
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
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final hasSpecificEvidence = RegExp(
    r'\b(merv|air|furnace|return|water|oil|fuel|pool|hvac)\b',
  ).hasMatch(text);
  return !hasSpecificEvidence && item.trade != 'HVAC';
}

double _boundedReceiptConfidence(double confidence) {
  if (confidence < 0.15) return 0.15;
  if (confidence > 0.95) return 0.95;
  return confidence;
}
