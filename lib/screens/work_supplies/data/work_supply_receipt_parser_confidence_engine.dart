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
  if (RegExp(r'\b(c\s*wire|common\s+wire|wire\s+saver)\b').hasMatch(text) &&
      itemText.contains('common wire adapter')) {
    score += 0.10;
  }
  if (RegExp(r'\b(surge|spd)\b').hasMatch(text) &&
      itemText.contains('surge protector')) {
    score += 0.10;
  }
  if (RegExp(r'\b(foam|gasket)\b').hasMatch(text) &&
      RegExp(r'\btape\b').hasMatch(text) &&
      itemText.contains('foam gasket tape')) {
    score += 0.10;
  }
  final rawItemText = '${item.name} ${item.variant} ${item.itemType}'
      .toLowerCase();
  if (_hasPTrapReceiptPhrase(text) &&
      (rawItemText.contains('p-trap') || rawItemText.contains('p trap'))) {
    score += 0.24;
  }
  score += _plumbingCoreReceiptEvidenceScore(text, item, itemText);
  return score;
}

double _plumbingCoreReceiptEvidenceScore(
  String text,
  WorkSupplyItem item,
  String itemText,
) {
  var score = 0.0;
  if (RegExp(r'\bpvc\b').hasMatch(text) &&
      (RegExp(r'\b(ell|elb|elbow)\b').hasMatch(text) ||
          _hasReceiptNinetyDegreeEvidence(text)) &&
      itemText.contains('pvc schedule 40 90 elbow')) {
    score += 0.10;
  }
  if (RegExp(r'\bpvc\b').hasMatch(text) &&
      RegExp(r'\b(cement|solvent\s+cement|glue)\b').hasMatch(text) &&
      itemText.contains('pvc cement')) {
    score += 0.20;
    final amount = _receiptPackageAmount(text, 'oz');
    if (_itemMatchesPackageAmount(item, amount, 'oz')) {
      score += 0.12;
    }
    if (RegExp(r'\bclear\b').hasMatch(text) && itemText.contains('clear')) {
      score += 0.04;
    }
  }
  if (RegExp(r'\b(cop|cu|copper)\b').hasMatch(text) &&
      !_hasBrokenCriticalPlumbingFraction(text) &&
      (RegExp(r'\b(ell|elb|elbow)\b').hasMatch(text) ||
          _hasReceiptNinetyDegreeEvidence(text)) &&
      RegExp(
        r'\b(cxc|c\s*x\s*c|copper\s+copper|sweat|wrot)\b',
      ).hasMatch(text) &&
      itemText.contains('copper') &&
      itemText.contains('90') &&
      itemText.contains('elbow')) {
    score += 0.12;
  }
  if (RegExp(
        r'\b(reducing cplg|reducing coupling|reducer coupling)\b',
      ).hasMatch(text) &&
      itemText.contains('reducing coupling')) {
    score += 0.10;
  }
  final serviceFamilies = <RegExp, List<String>>{
    RegExp(r'\b(p trap|p-trap)\b'): ['p trap', 'p-trap'],
    RegExp(r'\b(fill valve|valvula llenado|valvula de llenado)\b'): [
      'fill valve',
    ],
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
    RegExp(r'\b(boiler drain|heater drain|drain valve)\b'): [
      'drain valve',
      'boiler drain',
      'heater drain',
    ],
    RegExp(r'\b(t and p|t p|t&p|tpr|valvula alivio|valvula t p)\b'): [
      'temperature and pressure relief valve',
      'relief valve',
      't&p valve',
      'tpr valve',
    ],
    RegExp(r'\b(fernco|rubber coupling|flexible coupling)\b'): [
      'fernco',
      'rubber coupling',
      'flexible coupling',
      'flexible drain repair coupling',
    ],
    RegExp(r'\b(sharkbite|push|push fit|push-fit)\b.*\b(coup|coupling|cplg)\b'):
        ['push-fit coupling', 'push coupling', 'push connect coupling'],
    RegExp(r'\b(cinta teflon|cinta de teflon|ptfe tape|teflon tape)\b'): [
      'ptfe thread tape',
      'ptfe tape',
      'teflon tape',
    ],
    RegExp(
      r'\b(softener salt|salt pellets|sal suavizador|sal ablandador|sal para suavizador)\b',
    ): [
      'water softener salt pellets',
      'softener salt',
    ],
    RegExp(
      r'\b(well pressure gauge|pressure gauge|well gauge|manometro presion pozo|manometro de presion)\b',
    ): [
      'pressure gauge',
      'well pressure gauge',
    ],
    RegExp(
      r'\b(well pressure switch|pump pressure switch|pressure switch|well switch)\b',
    ): [
      'pressure switch',
      'well pressure switch',
      'pump pressure switch',
      'well switch',
    ],
    RegExp(
      r'\b(well pump|jet pump|shallow well|deep well|bomba pozo|bomba de pozo|bomba agua pozo)\b',
    ): [
      'well pump',
      'jet pump',
      'shallow well pump',
      'deep well pump',
    ],
    RegExp(
      r'\b(poly|polyethylene|well pipe)\b.*\b(insert|barb|barbed|coupling|adapter)\b',
    ): [
      'poly pipe insert',
      'poly well fitting',
      'well pipe fitting',
      'barbed coupling',
      'well service fitting',
    ],
    RegExp(r'\b(tr|tamper resistant)\b.*\b(dup|duplex|recpt|recept|outlet)\b'):
        ['duplex receptacle', 'tamper resistant'],
    RegExp(r'\b(cinta electrica|cinta aislante|elec tape|electrical tape)\b'): [
      'electrical tape',
    ],
    RegExp(r'\b(liquid\s*tight|liquidtight|sealtite)\b.*\b(conn|connector)\b'):
        ['liquidtight connector', 'flexible raceway part'],
    RegExp(r'\b(wire\s*nut|wirenut)\b'): ['wire connector', 'wire nut'],
    RegExp(r'\bground\s+screw\b'): ['ground screw'],
    RegExp(r'\b(photocell|photoeye|photo eye)\b'): ['photocell'],
    RegExp(r'\b(blank\s+wall\s+plate|wall\s+plate|cover\s+plate)\b'): [
      'wall plate',
      'cover plate',
      'blank',
    ],
    RegExp(r'\b(interruptor)\b.*\b(3\s*via|tres\s+vias?)\b'): [
      '3-way toggle switch',
      'toggle switch',
    ],
    RegExp(r'\b(uf-b|ufb|uf cable|underground feeder|direct burial)\b'): [
      'uf-b cable',
      'direct burial',
    ],
    RegExp(r'\b(contactor|contctr|cntctr)\b'): ['contactor'],
    RegExp(r'\b(transformer|xfmr|transf)\b'): ['transformer'],
    RegExp(r'\b(blade\s+fuse|fuse)\b'): ['fuse'],
    RegExp(r'\b(time\s+delay\s+relay|relay)\b'): ['relay'],
    RegExp(r'\b(tstat|thermostat|termostato)\b'): ['thermostat'],
    RegExp(r'\b(cond|condensate)\b.*\b(pump|pmp|bomba)\b'): ['condensate pump'],
    RegExp(r'\b(bomba)\b.*\b(condensado|condensate)\b'): ['condensate pump'],
    RegExp(r'\b(cond|condensate)\b.*\b(float|flotador)\b.*\b(sw|switch)\b'): [
      'condensate safety switch',
      'float switch',
    ],
    RegExp(r'\bflame\s+sensor\b'): ['flame sensor'],
    RegExp(r'\b(hot\s+surface\s+ignitor|hsi|ignitor)\b'): [
      'hot surface ignitor',
      'ignitor',
    ],
    RegExp(r'\b(hard\s+start|spp6|start kit|start kt)\b'): ['hard start kit'],
    RegExp(r'\b(cinta|foil|ul181|ul 181)\b.*\b(tape|cinta|hvac)\b'): [
      'foil tape',
      'foil hvac tape',
    ],
    RegExp(r'\bduct\s+mastic\b|\bmastic\b'): ['duct mastic', 'mastic'],
    RegExp(r'\b(line\s*set|lineset|refrigerant line)\b'): [
      'line set',
      'refrigerant line',
    ],
    RegExp(r'\b(armaflex|pipe insulation|line insulation)\b'): [
      'pipe insulation',
      'line set insulation',
      'insulation',
    ],
    RegExp(r'\b(condenser pad|equipment pad)\b'): [
      'condenser pad',
      'equipment pad',
      'pad',
    ],
    RegExp(r'\b(condensate|cond)\b.*\b(pan|drain pan)\b'): [
      'condensate pan',
      'drain pan',
      'pan',
    ],
    RegExp(r'\b(condensate|cond)\b.*\b(neutralizer|neutraliser)\b'): [
      'condensate neutralizer',
      'neutralizer',
    ],
    RegExp(r'\b(service valve cap|valve cap)\b'): [
      'service valve cap',
      'valve cap',
    ],
  };
  for (final entry in serviceFamilies.entries) {
    if (entry.key.hasMatch(text) &&
        entry.value.any((phrase) => itemText.contains(phrase))) {
      score += entry.value.contains('p trap') ? 0.24 : 0.16;
      break;
    }
  }
  if (RegExp(r'\b(contactor|contctr|cntctr)\b').hasMatch(text) &&
      itemText.contains('contactor')) {
    score += 0.08;
  }
  if (RegExp(r'\b(transformer|xfmr|transf)\b').hasMatch(text) &&
      itemText.contains('transformer')) {
    score += 0.10;
  }
  if (RegExp(r'\b(blade\s+fuse|fuse)\b').hasMatch(text) &&
      itemText.contains('fuse')) {
    score += 0.10;
  }
  if (RegExp(r'\b(time\s+delay\s+relay|relay)\b').hasMatch(text) &&
      itemText.contains('relay')) {
    score += 0.10;
  }
  if (RegExp(r'\b(hard\s+start|spp6|start kit|start kt)\b').hasMatch(text) &&
      itemText.contains('hard start')) {
    score += 0.08;
  }
  if (RegExp(r'\b(line\s*set|lineset|refrigerant line)\b').hasMatch(text) &&
      itemText.contains('line set')) {
    score += 0.12;
  }
  if (RegExp(r'\b(line\s*set|lineset)\b.*\b(cover|kit)\b').hasMatch(text) &&
      itemText.contains('line set cover')) {
    score += 0.12;
  }
  if (RegExp(r'\b(condensate|cond)\b.*\b(pan|drain pan)\b').hasMatch(text) &&
      (itemText.contains('condensate pan') || itemText.contains('drain pan'))) {
    score += 0.14;
  }
  if (RegExp(
        r'\b(condensate|cond)\b.*\b(pvc|drain)\b.*\b(union|fitting)\b',
      ).hasMatch(text) &&
      itemText.contains('condensate pvc')) {
    score += 0.12;
  }
  if (RegExp(
        r'\b(condensate|cond)\b.*\b(neutralizer|neutraliser)\b',
      ).hasMatch(text) &&
      itemText.contains('neutralizer')) {
    score += 0.12;
  }
  if (RegExp(r'\b(service valve cap|valve cap)\b').hasMatch(text) &&
      itemText.contains('service valve cap')) {
    score += 0.12;
  }
  if (RegExp(
        r'\b(well pressure gauge|pressure gauge|well gauge|manometro presion pozo|manometro de presion)\b',
      ).hasMatch(text) &&
      RegExp(r'\b(well|psi|pressure|presion|pozo)\b').hasMatch(text) &&
      itemText.contains('pressure gauge')) {
    score += 0.08;
  }
  if (RegExp(
        r'\b(well pump|jet pump|shallow well|deep well|bomba pozo|bomba de pozo|bomba agua pozo)\b',
      ).hasMatch(text) &&
      itemText.contains('well pump')) {
    score += 0.10;
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
  if (_isBrokenElectricalSizeLine(text, item)) risk += 0.30;
  if (_isVaguePushFitLine(text, item)) risk += 0.28;
  if (_isVaguePressureGaugeLine(text, item)) risk += 0.24;
  if (_isVagueSoftenerSaltLine(text, item)) risk += 0.30;
  if (_isVagueHvacCapacitorLine(text, item)) risk += 0.38;
  return risk;
}

bool _isVagueHvacCapacitorLine(String text, WorkSupplyItem item) {
  if (item.trade != 'HVAC') return false;
  final itemText = _indexedReceiptTextFor(item);
  if (!itemText.contains('capacitor')) return false;
  if (!RegExp(r'\bcap\b').hasMatch(text)) return false;
  if (!RegExp(r'\b\d{2}/5\b').hasMatch(text)) return false;
  return !RegExp(
    r'\b(mfd|uf|microfarad|dual\s+run|run\s+cap|440v|370v|volt|v)\b',
  ).hasMatch(text);
}

bool _isBrokenElectricalSizeLine(String text, WorkSupplyItem item) {
  if (item.trade != 'Electrical') return false;
  final normalized = _normalize(text);
  if (!RegExp(
    r'\b(nm-b|nmb|romex|mc|armored|wire|cable)\b',
  ).hasMatch(normalized)) {
    return false;
  }
  if (RegExp(r'(^|\s)/\s*\d+\b').hasMatch(normalized)) return true;
  if (RegExp(r'\b\d+\s*/(\s|$)').hasMatch(normalized)) return true;
  if (RegExp(
    r'\b\d+\s*/\s*\b(nm-b|nmb|romex|mc|wire|cable)\b',
  ).hasMatch(normalized)) {
    return true;
  }
  return false;
}

bool _isVaguePushFitLine(String text, WorkSupplyItem item) {
  if (!RegExp(
    r'\b(push|push fit|push-fit|push connect|sharkbite)\b',
  ).hasMatch(text)) {
    return false;
  }
  if (RegExp(
    r'\b(elbow|ell|elb|tee|coupling|cplg|adapter|adpt|cap|stop|valve|'
    r'shutoff|slip|repair|reducer|reducing|mip|fip|male|female)\b',
  ).hasMatch(text)) {
    return false;
  }
  return _indexedReceiptTextFor(item).contains('push');
}

bool _isVaguePressureGaugeLine(String text, WorkSupplyItem item) {
  if (!RegExp(r'\b(pressure gauge|well gauge|manometro)\b').hasMatch(text)) {
    return false;
  }
  if (RegExp(r'\b(well|pozo|psi|pump|bomba|water|agua)\b').hasMatch(text)) {
    return false;
  }
  return _indexedReceiptTextFor(item).contains('pressure gauge');
}

bool _isVagueSoftenerSaltLine(String text, WorkSupplyItem item) {
  if (!RegExp(r'\b(salt pellets?|sal)\b').hasMatch(text)) return false;
  if (RegExp(
    r'\b(softener|suavizador|ablandador|brine|water treatment|agua)\b',
  ).hasMatch(text)) {
    return false;
  }
  final itemText = _indexedReceiptTextFor(item);
  return itemText.contains('softener') || itemText.contains('salt');
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
  final hasCompletePlumbingFittingEvidence =
      _nominalReceiptSize(text) != null &&
      RegExp(
        r'\b(90|45|ell|elb|elbow|tee|coupling|cplg|adapter|adpt)\b',
      ).hasMatch(text) &&
      RegExp(
        r'\b(cxc|c\s*x\s*c|copper\s+copper|sweat|wrot|mip|fip|male|female)\b',
      ).hasMatch(text);
  if (hasCompletePlumbingFittingEvidence && item.trade == 'Plumbing') {
    return false;
  }
  return item.trade == 'Plumbing' || item.trade == 'HVAC';
}

bool _isGenericFilterLine(
  String text,
  WorkSupplyItem item,
  String? tradeScope,
) {
  if (!RegExp(r'\b(filter|filt)\b').hasMatch(text)) return false;
  final hasSpecificFilterEvidence =
      _hasHvacAirFilterReceiptEvidence(text) ||
      RegExp(
        r'\b(return grille|return air grille|filter grille|water filter|'
        r'sediment filter|carbon filter|pleated filter|filter cartridge|'
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
  if (!RegExp(r'\b(filter|filt)\b').hasMatch(text)) return false;
  if (RegExp(
    r'\b(drier|dri|secador|liquid|liq|linea|water|oil|fuel|pool|'
    r'grille|register|rack|base|housing)\b',
  ).hasMatch(text)) {
    return false;
  }
  final hasAirFilterWords = RegExp(
    r'\b(air|furn|furnace|pleated|merv\d*|hvac|ac)\b',
  ).hasMatch(text);
  return hasAirFilterWords &&
      (_nominalReceiptSize(text) != null || _receiptSizeMatrix(text) != null);
}
