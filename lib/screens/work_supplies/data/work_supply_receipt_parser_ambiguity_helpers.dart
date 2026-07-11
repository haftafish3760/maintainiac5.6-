part of 'work_supply_receipt_parser.dart';

bool _isUnscopedAmbiguousReceiptLine(
  String text,
  WorkSupplyItem item,
  String? tradeScope, {
  String originalText = '',
}) {
  final receiptText = _normalize(originalText.isEmpty ? text : originalText);
  if (_isGenericPvcElbowReceiptLine(receiptText)) {
    return true;
  }
  if (_isBareElectricalPvcConduitShorthandLine(receiptText, item)) {
    return true;
  }
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final itemText = _indexedReceiptTextFor(item);
  if (RegExp(r'\bpvc\b').hasMatch(normalized) &&
      RegExp(
        r'\b(90|ell|elb|elbow|cement|cond|conduit|cplg|coupling|coup|'
        r'union|pipe)\b',
      ).hasMatch(normalized)) {
    return true;
  }
  if (RegExp(r'\btape\b').hasMatch(normalized)) return true;
  if (RegExp(r'\bfilter\b').hasMatch(normalized)) return true;
  if (RegExp(r'\bcement\b').hasMatch(normalized) &&
      !itemText.contains('pvc cement')) {
    return true;
  }
  return false;
}

bool _isBareMixedRepairOrServiceReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (RegExp(r'\b(repair|reparacion|reparación|repar)\b').hasMatch(normalized)) {
    final hasExplicitRepairFamily = RegExp(
      r'\b(drain|faucet|sink|lav|tub|shower|hose|sillcock|heater|'
      r'water heater|vacuum breaker|pop up|pop-up|o ring|o-ring|'
      r'washer|stem|cartridge|service|flange|coupling|pump|trap|'
      r'condensate|toilet|stop|valve|kit|part)\b',
    ).hasMatch(normalized);
    if (!hasExplicitRepairFamily && tokenCount <= 3) return true;
  }
  if (RegExp(r'\b(service|serv|servicio)\b').hasMatch(normalized)) {
    final hasExplicitServiceFamily = RegExp(
      r'\b(valve|valvula|head|weatherhead|filter|fitting|water heater|'
      r'heater|water|electrical|hvac|cap|truck|panel|kit|part|'
      r'condensate|pump|refrigerant)\b',
    ).hasMatch(normalized);
    if (!hasExplicitServiceFamily && tokenCount <= 3) return true;
  }
  return false;
}

bool _isGenericPvcElbowReceiptLine(String text) {
  final normalized = _normalize(text);
  if (!RegExp(r'\bpvc\b').hasMatch(normalized)) return false;
  final hasElbowShape = RegExp(r'\b(ell|el|elb|elbow|codo)\b')
          .hasMatch(normalized) ||
      _hasReceiptNinetyDegreeEvidence(normalized) ||
      RegExp(r'(?<![\d.])45(?![\d.a-z])').hasMatch(normalized);
  if (!hasElbowShape) return false;
  final hasPlumbingSpecificEvidence = RegExp(
    r'\b(sch|schedule|s40|sch40|ced|cedula|dwv|drain|presion|pressure|'
    r'slip|sxs|hub|spigot|socket|solvent)\b',
  ).hasMatch(normalized);
  final hasOtherTradeSpecificEvidence = RegExp(
    r'\b(cond|conduit|electrical|elec|emt|condensate|hvac|irrigation)\b',
  ).hasMatch(normalized);
  return !hasPlumbingSpecificEvidence && !hasOtherTradeSpecificEvidence;
}

bool _isBareElectricalPvcConduitShorthandLine(
  String text,
  WorkSupplyItem item,
) {
  if (item.trade != 'Electrical') return false;
  final itemName = item.name.toLowerCase();
  final itemType = item.itemType.toLowerCase();
  if (!itemName.contains('pvc electrical conduit') &&
      !itemType.contains('conduit')) {
    return false;
  }
  final normalized = _normalize(text);
  final saysPvc = RegExp(r'\bpvc\b').hasMatch(normalized);
  final saysCondAbbreviation = RegExp(r'\bcond\b').hasMatch(normalized);
  if (!saysPvc || !saysCondAbbreviation) return false;
  final hasStrongRacewayEvidence = RegExp(
    r'\b(conduit|electrical|elec|emt|sch\s*40|schedule\s*40|s40|'
    r'cplg|cplgs|coupling|coup|connector|conn|body|lb|ll|lr|strap|'
    r'bushing|locknut|sweep|elbow|ell|elb|adapter|adpt|ft)\b',
  ).hasMatch(normalized);
  return !hasStrongRacewayEvidence;
}

bool _isAmbiguousPlumbingCoreLine(String text, WorkSupplyItem item) {
  if (item.trade != 'Plumbing') return false;
  if (_hasBrokenCriticalPlumbingFraction(text)) return true;
  if (_isDirtyMaterialShapeOnlyPlumbingLine(text, item)) return true;
  if (RegExp(r'\bcopper\s+copper\b').hasMatch(text) &&
      !RegExp(
        r'\b(90|45|elbow|ell|tee|wye|coupling|cpl|cplg|adapter|adpt|'
        r'male|female|cap|plug|union|repair|street|stub|tube|pipe)\b',
      ).hasMatch(text)) {
    return true;
  }
  if (RegExp(r'\badapter\b').hasMatch(text) &&
      !RegExp(
        r'\b(mip|fip|mpt|fpt|male|female|trap|pvc|cpvc|pex|copper|brass|'
        r'barb|poly|cts|ips|dwv|schedule)\b',
      ).hasMatch(text)) {
    return true;
  }
  if (RegExp(r'\brepair\s+kit\b').hasMatch(text) &&
      !RegExp(
        r'\b(faucet|toilet|sink|lav|tub|shower|hose|sillcock|water heater|'
        r'vacuum breaker|pop up|o ring|o-ring|washer|stem|cartridge)\b',
      ).hasMatch(text)) {
    return true;
  }
  if (RegExp(r'\bfaucet\s+repair\s+kit\b').hasMatch(text) &&
      !RegExp(
        r'\b(stem|cartridge|cart|washer|seat|aerator|o ring|o-ring|oring|'
        r'handle|sprayer|diverter|pop up|pop-up)\b',
      ).hasMatch(text)) {
    return true;
  }
  final hasAmbiguousShape = RegExp(
    r'\b(elbow|ell|elb|adapter|adpt|valve|coupling|cplg|coup)\b',
  ).hasMatch(text);
  if (!hasAmbiguousShape) return false;
  final hasMaterial = RegExp(
    r'\b(pex|pvc|cpvc|abs|dwv|copper|brass|black iron|blk iron|galv|galvanized|cast iron|no hub|push fit|sharkbite)\b',
  ).hasMatch(text);
  final hasConnection = RegExp(
    r'\b(crimp|slip|mip|fip|compression|sweat|thread|push|solvent|cts|dwv|schedule 40|s40)\b',
  ).hasMatch(text);
  final hasSpecificValve = RegExp(
    r'\b(angle|stop|ball|gate|check|prv|pressure|relief|vacuum|hose bibb|sillcock|fill|flush|toilet)\b',
  ).hasMatch(text);
  return !hasMaterial && !hasConnection && !hasSpecificValve;
}

bool _hasBrokenCriticalPlumbingFraction(String text) {
  final normalized = _normalize(text);
  if (RegExp(r'(^|\s)/\s*\d+\b').hasMatch(normalized)) return true;
  if (RegExp(r'\b\d+\s*/(\s|$)').hasMatch(normalized)) return true;
  if (RegExp(
    r'\b\d+\s*/\s*\b(cop|copper|cu|pex|pvc|cpvc|abs|brass|cplg|coupling|'
    r'ell|elb|elbow|tee|adpt|adapter|valv|valve)\b',
  ).hasMatch(normalized)) {
    return true;
  }
  if (RegExp(r'\b\d{2}\s+(cop|copper|cu)\s+(90|ell|elb|elbow)\b')
      .hasMatch(normalized)) {
    return true;
  }
  return false;
}

bool _isDirtyMaterialShapeOnlyPlumbingLine(String text, WorkSupplyItem item) {
  final normalized = _normalize(text);
  final itemText = _indexedReceiptTextFor(item);
  final hasMaterial = RegExp(
    r'\b(cop|copper|cu|pex|pvc|cpvc|abs|brass|galv|blk iron|black iron)\b',
  ).hasMatch(normalized);
  final hasShape = RegExp(
    r'\b(90|45|ell|elb|elbow|tee|cplg|coupling|adpt|adapter|valv|valve)\b',
  ).hasMatch(normalized);
  if (!hasMaterial || !hasShape) return false;
  final hasSize = _nominalReceiptSize(normalized) != null ||
      _receiptSizeMatrix(normalized) != null;
  final hasConnection = RegExp(
    r'\b(cxc|c\s*x\s*c|mip|fip|male|female|sweat|wrot|press|propress|'
    r'crimp|clamp|expansion|slip|solvent|sch|schedule|s40|dwv|cts|ips|'
    r'push|sharkbite|compression)\b',
  ).hasMatch(normalized);
  final hasBrand = RegExp(
    r'\b(nibco|mueller|viega|apollo|sharkbite|oatey|watts|fernco|zurn)\b',
  ).hasMatch(normalized);
  if (hasSize || hasConnection || hasBrand) return false;
  return RegExp(
    r'\b(copper|pex|pvc|cpvc|abs|brass|galvanized|black iron)\b',
  ).hasMatch(itemText);
}
