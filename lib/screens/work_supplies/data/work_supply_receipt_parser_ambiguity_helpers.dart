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
        r'\b(90|ell|elb|elbow|cement|cond|conduit|cplg|coupling|coup)\b',
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

bool _isGenericPvcElbowReceiptLine(String text) {
  final normalized = _normalize(text);
  if (!RegExp(r'\bpvc\b').hasMatch(normalized)) return false;
  final hasElbowShape = RegExp(
    r'\b(90|45|ell|el|elb|elbow|codo)\b',
  ).hasMatch(normalized);
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
