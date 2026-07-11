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
  if (RegExp(
    r'\b(repair|reparacion|reparación|repar)\b',
  ).hasMatch(normalized)) {
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

bool _isBareMixedSpanishValveOrSwitchReceiptLine(
  String text,
  String? tradeScope,
) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (RegExp(r'\bvalvula\b').hasMatch(normalized)) {
    final hasExplicitValveFamily = RegExp(
      r'\b(alivio|llenado|angulo|escuadra|servicio|check|bola|compuerta|'
      r'presion|vacio|manguera|condensado|heater|calentador|tapa)\b',
    ).hasMatch(normalized);
    if (!hasExplicitValveFamily && tokenCount <= 3) return true;
  }
  if (RegExp(r'\binterruptor\b').hasMatch(normalized)) {
    final hasExplicitSwitchFamily = RegExp(
      r'\b(3-way|3way|presion|limite|pared|ventilador|float|flotador|'
      r'humidificador|seguridad|toggle|dimmer)\b',
    ).hasMatch(normalized);
    if (!hasExplicitSwitchFamily && tokenCount <= 3) return true;
  }
  return false;
}

bool _isBareMixedSpanishBoxOrFilterReceiptLine(
  String text,
  String? tradeScope,
) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (RegExp(r'\bcaja\b').hasMatch(normalized)) {
    final hasExplicitBoxFamily = RegExp(
      r'\b(electrica|electrico|panel|cubierta|brace|remodelacion|old work|'
      r'octagonal|gang|junction|techo|tecla)\b',
    ).hasMatch(normalized);
    if (!hasExplicitBoxFamily && tokenCount <= 3) return true;
  }
  if (RegExp(r'\bfiltro\b').hasMatch(normalized)) {
    final hasExplicitFilterFamily = RegExp(
      r'\b(aire|agua|secador|horno|drier|hvac|ac|plegado|20x|16x|'
      r'condensado|bomba|cartucho)\b',
    ).hasMatch(normalized);
    if (!hasExplicitFilterFamily && tokenCount <= 3) return true;
  }
  return false;
}

bool _isBareMixedSpanishPumpReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bbomba\b').hasMatch(normalized)) return false;
  final hasExplicitPumpFamily = RegExp(
    r'\b(condensado|condensate|pozo|agua|sumidero|sump|well|jet|'
    r'desague|drenaje|lavadora|circulacion|recirculacion)\b',
  ).hasMatch(normalized);
  return !hasExplicitPumpFamily && tokenCount <= 3;
}

bool _isBareMixedSpanishLlaveReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bllave\b').hasMatch(normalized)) return false;
  final hasExplicitLlaveFamily = RegExp(
    r'\b(lavabo|angular|escuadra|paso|grifo|manguera|fregadero|'
    r'calentador|jardin|hose|supply|stop|faucet)\b',
  ).hasMatch(normalized);
  return !hasExplicitLlaveFamily && tokenCount <= 3;
}

bool _isBareMixedSpanishConnectorReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bconector\b').hasMatch(normalized)) return false;
  final hasExplicitConnectorFamily = RegExp(
    r'\b(romex|liquido|lavabo|grifo|supply|compresion|cable|tubo|'
    r'flex|manguera|cpvc|pex|cobre|electrico)\b',
  ).hasMatch(normalized);
  return !hasExplicitConnectorFamily && tokenCount <= 3;
}

bool _isBareMixedSpanishElbowReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bcodo\b').hasMatch(normalized)) return false;
  final hasExplicitElbowFamily = RegExp(
    r'\b(pvc|cpvc|pex|cobre|conducto|conduit|90|45|dwv|presion|'
    r'condensado|drenaje|sweat|compresion)\b',
  ).hasMatch(normalized);
  return !hasExplicitElbowFamily && tokenCount <= 3;
}

bool _isBareMixedSpanishTapeReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bcinta\b').hasMatch(normalized)) return false;
  final hasExplicitTapeFamily = RegExp(
    r'\b(aluminio|electrica|teflon|ducto|foil|hvac|rosca|aislamiento|'
    r'wire|romex|sellado)\b',
  ).hasMatch(normalized);
  return !hasExplicitTapeFamily && tokenCount <= 3;
}

bool _isBareMixedSpanishConduitReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bconducto\b').hasMatch(normalized)) return false;
  final hasExplicitConduitFamily = RegExp(
    r'\b(electrico|electrica|pvc|emt|sweep|conector|cople|codo|'
    r'ducto|aire|ventilacion|metalico)\b',
  ).hasMatch(normalized);
  return !hasExplicitConduitFamily && tokenCount <= 3;
}

bool _isBareMixedSpanishAdapterReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\badaptador\b').hasMatch(normalized)) return false;
  final hasExplicitAdapterFamily = RegExp(
    r'\b(mip|fip|mpt|fpt|male|female|trap|pvc|cpvc|pex|cobre|bronce|'
    r'laton|barb|poly|cts|ips|dwv|schedule|conduit|conducto|electrico|'
    r'electrica|compresion|sweat|rosca|reductor)\b',
  ).hasMatch(normalized);
  return !hasExplicitAdapterFamily && tokenCount <= 3;
}

bool _isBareMixedSpanishCouplingReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bacople\b').hasMatch(normalized)) return false;
  final hasExplicitCouplingFamily = RegExp(
    r'\b(pvc|cpvc|pex|cobre|copper|brass|galv|dwv|sch|schedule|'
    r'conduit|conducto|electrico|electrica|repair|reparacion|'
    r'flex|compression|compresion|sweat|slip|hub|socket|reductor)\b',
  ).hasMatch(normalized);
  return !hasExplicitCouplingFamily && tokenCount <= 3;
}

bool _isBareMixedUnionReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bunion\b').hasMatch(normalized)) return false;
  final hasExplicitUnionFamily = RegExp(
    r'\b(dielectric|water heater|wtr htr|brass|compression|comp|'
    r'condensate|drain|flare|black iron|galv|cobre|copper|cpvc|'
    r'pvc|pex|threaded|sweat|repair|service)\b',
  ).hasMatch(normalized);
  return !hasExplicitUnionFamily && tokenCount <= 3;
}

bool _isBareMixedSizedUnionReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bunion\b').hasMatch(normalized)) return false;
  if (!RegExp(
    r'\b(?:1/4|3/8|1/2|5/8|3/4|1|1-1/4|1-1/2|2|2-1/2|3|4)\b',
  ).hasMatch(normalized)) {
    return false;
  }
  final hasExplicitSizedUnionFamily = RegExp(
    r'\b(dielectric|water heater|wtr htr|brass|compression|comp|'
    r'condensate|drain|flare|black iron|galv|cobre|copper|cpvc|'
    r'pvc|pex|threaded|sweat|repair|service)\b',
  ).hasMatch(normalized);
  return !hasExplicitSizedUnionFamily && tokenCount <= 5;
}

bool _isBareMixedCompactCompressionUnionReceiptLine(
  String text,
  String? tradeScope,
) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bunion\b').hasMatch(normalized)) return false;
  if (!RegExp(r'\bcomp\b').hasMatch(normalized)) return false;
  final hasExplicitCompactCompressionUnionFamily = RegExp(
    r'\b(supply|stop|gas|faucet|icemaker|ice maker|toilet|'
    r'dishwasher|connector|hose|valve|appliance|water heater|'
    r'dielectric|flare|copper|cobre|brass|cpvc|pex|pvc)\b',
  ).hasMatch(normalized);
  return !hasExplicitCompactCompressionUnionFamily && tokenCount <= 5;
}

bool _isBareMixedBushingReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bbushing\b').hasMatch(normalized)) return false;
  final hasExplicitBushingFamily = RegExp(
    r'\b(reducing|reducer|insulated|pvc|brass|cpvc|emt|conduit|'
    r'grounding|bonding|locknut)\b',
  ).hasMatch(normalized);
  return !hasExplicitBushingFamily && tokenCount <= 3;
}

bool _isBareMixedSizedBushingReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bbushing\b').hasMatch(normalized)) return false;
  if (!RegExp(
    r'\b(?:1/4|3/8|1/2|5/8|3/4|1|1-1/4|1-1/2|2|2-1/2|3|4)\b',
  ).hasMatch(normalized)) {
    return false;
  }
  final hasExplicitSizedBushingFamily = RegExp(
    r'\b(reducing|reducer|insulated|pvc|brass|cpvc|emt|conduit|'
    r'grounding|bonding|locknut|copper|pex|dwv|threaded|mip|fip)\b',
  ).hasMatch(normalized);
  return !hasExplicitSizedBushingFamily && tokenCount <= 5;
}

bool _isBareMixedCopperReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bcopper\b').hasMatch(normalized)) return false;
  final hasExplicitCopperFamily = RegExp(
    r'\b(tub(e|ing)|coil|roll|pipe|line|fitting|elbow|tee|coupling|'
    r'adapter|mip|fip|sweat|press|type\s*[lmk]|l|m|k)\b',
  ).hasMatch(normalized);
  return !hasExplicitCopperFamily && tokenCount <= 3;
}

bool _isBareMixedPipeReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bpipe\b').hasMatch(normalized)) return false;
  final hasExplicitPipeFamily = RegExp(
    r'\b(pvc|cpvc|pex|copper|cobre|emt|conduit|rigid|flue|vent|'
    r'drain|sewer|sch|schedule|black|iron|gas|condensate|tube|'
    r'humidifier|extension|duct)\b',
  ).hasMatch(normalized);
  return !hasExplicitPipeFamily && tokenCount <= 3;
}

bool _isBareMixedSizedPipeReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bpipe\b').hasMatch(normalized)) return false;
  if (!RegExp(
    r'\b(?:1/4|3/8|1/2|5/8|3/4|1|1-1/4|1-1/2|2|2-1/2|3|4)\b',
  ).hasMatch(normalized)) {
    return false;
  }
  final hasExplicitSizedPipeFamily = RegExp(
    r'\b(pvc|cpvc|pex|copper|cobre|emt|conduit|rigid|flue|vent|'
    r'drain|sewer|sch|schedule|black|iron|gas|condensate|tube|'
    r'humidifier|extension|duct)\b',
  ).hasMatch(normalized);
  return !hasExplicitSizedPipeFamily && tokenCount <= 5;
}

bool _isBareMixedTubeReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\btube\b').hasMatch(normalized)) return false;
  final hasExplicitTubeFamily = RegExp(
    r'\b(copper|cobre|condensate|humidifier|extension|wall|led|light|'
    r'refrigerant|softener|distributor|brush|caulk|sealant|drain)\b',
  ).hasMatch(normalized);
  return !hasExplicitTubeFamily && tokenCount <= 3;
}

bool _isBareMixedSizedTubeReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\btube\b').hasMatch(normalized)) return false;
  if (!RegExp(
    r'\b(?:1/4|3/8|1/2|5/8|3/4|1|1-1/4|1-1/2|2|2-1/2|3|4)\b',
  ).hasMatch(normalized)) {
    return false;
  }
  final hasExplicitSizedTubeFamily = RegExp(
    r'\b(copper|cobre|condensate|humidifier|extension|wall|led|light|'
    r'refrigerant|softener|distributor|brush|caulk|sealant|drain)\b',
  ).hasMatch(normalized);
  return !hasExplicitSizedTubeFamily && tokenCount <= 5;
}

bool _isBareMixedCableReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bcable\b').hasMatch(normalized)) return false;
  final hasExplicitCableFamily = RegExp(
    r'\b(nm|nm-b|romex|uf|uf-b|ser|seu|mc|ac|bx|service|'
    r'communication|mini split|thermostat|low voltage|wire|'
    r'electrical|electric|hvac)\b',
  ).hasMatch(normalized);
  return !hasExplicitCableFamily && tokenCount <= 3;
}

bool _isBareMixedSizedCableReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bcable\b').hasMatch(normalized)) return false;
  if (!RegExp(
    r'\b(?:1/4|3/8|1/2|5/8|3/4|1|1-1/4|1-1/2|2|2-1/2|3|4)\b',
  ).hasMatch(normalized)) {
    return false;
  }
  final hasExplicitSizedCableFamily = RegExp(
    r'\b(nm|nm-b|romex|uf|uf-b|ser|seu|mc|ac|bx|service|'
    r'communication|mini split|thermostat|low voltage|wire|'
    r'electrical|electric|hvac)\b',
  ).hasMatch(normalized);
  return !hasExplicitSizedCableFamily && tokenCount <= 5;
}

bool _isBareMixedWireReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bwire\b').hasMatch(normalized)) return false;
  final hasExplicitWireFamily = RegExp(
    r'\b(12/2|12/3|14/2|14/3|10/2|10/3|romex|nm|mc|thhn|uf|ser|'
    r'spool|ground|grounding|solid|stranded|copper|aluminum|awg|gauge)\b',
  ).hasMatch(normalized);
  return !hasExplicitWireFamily && tokenCount <= 3;
}

bool _isBareMixedHoseReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bhose\b').hasMatch(normalized)) return false;
  final hasExplicitHoseFamily = RegExp(
    r'\b(washer|washing machine|laundry|dishwasher|drain|bibb|sillcock|'
    r'condensate|mini split|discharge|sump|garden|water|supply)\b',
  ).hasMatch(normalized);
  return !hasExplicitHoseFamily && tokenCount <= 3;
}

bool _isBareMixedSizedHoseReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bhose\b').hasMatch(normalized)) return false;
  if (!RegExp(
    r'\b(?:1/4|3/8|1/2|5/8|3/4|1|1-1/4|1-1/2|2|2-1/2|3|4)\b',
  ).hasMatch(normalized)) {
    return false;
  }
  final hasExplicitSizedHoseFamily = RegExp(
    r'\b(washer|washing machine|laundry|dishwasher|drain|bibb|sillcock|'
    r'condensate|mini split|discharge|sump|garden|water|supply)\b',
  ).hasMatch(normalized);
  return !hasExplicitSizedHoseFamily && tokenCount <= 5;
}

bool _isBareMixedStrapReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bstrap\b').hasMatch(normalized)) return false;
  final hasExplicitStrapFamily = RegExp(
    r'\b(conduit|duct|hanger|heater|water heater|fixture|pipe|vent|'
    r'seismic|earthquake|mast|one hole|two hole|mini)\b',
  ).hasMatch(normalized);
  return !hasExplicitStrapFamily && tokenCount <= 3;
}

bool _isBareMixedSizedStrapReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bstrap\b').hasMatch(normalized)) return false;
  if (!RegExp(
    r'\b(?:1/4|3/8|1/2|5/8|3/4|1|1-1/4|1-1/2|2|2-1/2|3|4)\b',
  ).hasMatch(normalized)) {
    return false;
  }
  final hasExplicitSizedStrapFamily = RegExp(
    r'\b(conduit|duct|hanger|heater|water heater|fixture|pipe|vent|'
    r'seismic|earthquake|mast|one hole|two hole|mini)\b',
  ).hasMatch(normalized);
  return !hasExplicitSizedStrapFamily && tokenCount <= 5;
}

bool _isBareMixedClampReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bclamp\b').hasMatch(normalized)) return false;
  final hasExplicitClampFamily = RegExp(
    r'\b(riser|beam|ground|bonding|acorn|mast|vent|pipe|temperature|'
    r'clamp meter|meter|duct|water pipe|ring|cinch)\b',
  ).hasMatch(normalized);
  return !hasExplicitClampFamily && tokenCount <= 3;
}

bool _isBareMixedSizedClampReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bclamp\b').hasMatch(normalized)) return false;
  if (!RegExp(
    r'\b(?:1/4|3/8|1/2|5/8|3/4|1|1-1/4|1-1/2|2|2-1/2|3|4)\b',
  ).hasMatch(normalized)) {
    return false;
  }
  final hasExplicitSizedClampFamily = RegExp(
    r'\b(riser|beam|ground|bonding|acorn|mast|vent|pipe|temperature|'
    r'clamp meter|meter|duct|water pipe|ring|cinch)\b',
  ).hasMatch(normalized);
  return !hasExplicitSizedClampFamily && tokenCount <= 5;
}

bool _isBareMixedLineReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bline\b').hasMatch(normalized)) return false;
  final hasExplicitLineFamily = RegExp(
    r'\b(supply|set|line set|water heater|heater|refrigerant|copper|'
    r'ice maker|icemaker|dishwasher|appliance|condensate|drain|'
    r'washer|laundry|gas|armaflex|mini split)\b',
  ).hasMatch(normalized);
  return !hasExplicitLineFamily && tokenCount <= 3;
}

bool _isBareMixedSizedLineReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bline\b').hasMatch(normalized)) return false;
  if (!RegExp(
    r'\b(?:1/4|3/8|1/2|5/8|3/4|1|1-1/4|1-1/2|2|2-1/2|3|4)\b',
  ).hasMatch(normalized)) {
    return false;
  }
  final hasExplicitSizedLineFamily = RegExp(
    r'\b(supply|set|line set|water heater|heater|refrigerant|copper|'
    r'ice maker|icemaker|dishwasher|appliance|condensate|drain|'
    r'washer|laundry|gas|armaflex|mini split)\b',
  ).hasMatch(normalized);
  return !hasExplicitSizedLineFamily && tokenCount <= 5;
}

bool _isBareMixedSwitchReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bswitch\b').hasMatch(normalized)) return false;
  final hasExplicitSwitchFamily = RegExp(
    r'\b(float|wet|overflow|pan|pressure|limit|rollout|door|wall|'
    r'toggle|3-way|3way|single pole|smart|motion|timer|safety|well|pump)\b',
  ).hasMatch(normalized);
  return !hasExplicitSwitchFamily && tokenCount <= 3;
}

bool _isBareMixedSizedSwitchReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bswitch\b').hasMatch(normalized)) return false;
  if (!RegExp(
    r'\b(?:1/4|3/8|1/2|5/8|3/4|1|1-1/4|1-1/2|2|2-1/2|3|4)\b',
  ).hasMatch(normalized)) {
    return false;
  }
  final hasExplicitSizedSwitchFamily = RegExp(
    r'\b(float|wet|overflow|pan|pressure|limit|rollout|door|wall|'
    r'toggle|3-way|3way|single pole|smart|motion|timer|safety|well|pump)\b',
  ).hasMatch(normalized);
  return !hasExplicitSizedSwitchFamily && tokenCount <= 5;
}

bool _isBareMixedCoverReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bcover\b').hasMatch(normalized)) return false;
  final hasExplicitCoverFamily = RegExp(
    r'\b(cleanout|access|weatherproof|wp|in use|in-use|bubble|vent|'
    r'line set|mini split|water panel|plate|device|switch|dead front|'
    r'body|lamp holder)\b',
  ).hasMatch(normalized);
  return !hasExplicitCoverFamily && tokenCount <= 3;
}

bool _isBareMixedSizedCoverReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bcover\b').hasMatch(normalized)) return false;
  if (!RegExp(
    r'\b(?:1/4|3/8|1/2|5/8|3/4|1|1-1/4|1-1/2|2|2-1/2|3|4)\b',
  ).hasMatch(normalized)) {
    return false;
  }
  final hasExplicitSizedCoverFamily = RegExp(
    r'\b(cleanout|access|weatherproof|wp|in use|in-use|bubble|vent|'
    r'line set|mini split|water panel|plate|device|switch|dead front|'
    r'body|lamp holder)\b',
  ).hasMatch(normalized);
  return !hasExplicitSizedCoverFamily && tokenCount <= 5;
}

bool _isBareMixedPanelReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bpanel\b').hasMatch(normalized)) return false;
  final hasExplicitPanelFamily = RegExp(
    r'\b(breaker|load center|sub|service|zone|control|water|humidifier|'
    r'access|cabinet|label|filler|screw|dead front)\b',
  ).hasMatch(normalized);
  return !hasExplicitPanelFamily && tokenCount <= 3;
}

bool _isBareMixedSizedPanelReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bpanel\b').hasMatch(normalized)) return false;
  if (!RegExp(
    r'\b(?:1/4|3/8|1/2|5/8|3/4|1|1-1/4|1-1/2|2|2-1/2|3|4)\b',
  ).hasMatch(normalized)) {
    return false;
  }
  final hasExplicitSizedPanelFamily = RegExp(
    r'\b(breaker|load center|sub|service|zone|control|water|humidifier|'
    r'access|cabinet|label|filler|screw|dead front)\b',
  ).hasMatch(normalized);
  return !hasExplicitSizedPanelFamily && tokenCount <= 5;
}

bool _isBareMixedTrapReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\btrap\b').hasMatch(normalized)) return false;
  final hasExplicitTrapFamily = RegExp(
    r'\b(condensate|p-trap|p trap|tubular|sediment|drip leg|trap arm|'
    r'primer|adapter|washer|lav|sink|drain)\b',
  ).hasMatch(normalized);
  return !hasExplicitTrapFamily && tokenCount <= 3;
}

bool _isBareMixedSizedTrapReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\btrap\b').hasMatch(normalized)) return false;
  if (!RegExp(
    r'\b(?:1/4|3/8|1/2|5/8|3/4|1|1-1/4|1-1/2|2|2-1/2|3|4)\b',
  ).hasMatch(normalized)) {
    return false;
  }
  final hasExplicitSizedTrapFamily = RegExp(
    r'\b(condensate|p-trap|p trap|tubular|sediment|drip leg|trap arm|'
    r'primer|adapter|washer|lav|sink|drain)\b',
  ).hasMatch(normalized);
  return !hasExplicitSizedTrapFamily && tokenCount <= 5;
}

bool _isBareMixedCleanoutReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bcleanout\b').hasMatch(normalized)) return false;
  final hasExplicitCleanoutFamily = RegExp(
    r'\b(plug|cover|access|tee|pvc|abs|dwv|brass|raised|round|square)\b',
  ).hasMatch(normalized);
  return !hasExplicitCleanoutFamily && tokenCount <= 3;
}

bool _isBareMixedSizedCleanoutReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bcleanout\b').hasMatch(normalized)) return false;
  if (!RegExp(
    r'\b(?:1/4|3/8|1/2|5/8|3/4|1|1-1/4|1-1/2|2|2-1/2|3|4)\b',
  ).hasMatch(normalized)) {
    return false;
  }
  final hasExplicitSizedCleanoutFamily = RegExp(
    r'\b(plug|cover|access|tee|pvc|abs|dwv|brass|raised|round|square)\b',
  ).hasMatch(normalized);
  return !hasExplicitSizedCleanoutFamily && tokenCount <= 5;
}

bool _isBareMixedCapReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bcap\b').hasMatch(normalized)) return false;
  final hasExplicitCapFamily = RegExp(
    r'\b(end\s*cap|service|valve|vent|roof|test|cleanout|pipe|'
    r'conduit|dust|decorative)\b',
  ).hasMatch(normalized);
  return !hasExplicitCapFamily && tokenCount <= 3;
}

bool _isBareMixedSizedCapReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bcap\b').hasMatch(normalized)) return false;
  if (!RegExp(
    r'\b(?:1/4|3/8|1/2|5/8|3/4|1|1-1/4|1-1/2|2|2-1/2|3|4)\b',
  ).hasMatch(normalized)) {
    return false;
  }
  final hasExplicitSizedCapFamily = RegExp(
    r'\b(end\s*cap|service|valve|vent|roof|test|cleanout|pipe|'
    r'conduit|dust|decorative|copper|pvc|cpvc|pex|electrical|'
    r'capacitor|hvac)\b',
  ).hasMatch(normalized);
  return !hasExplicitSizedCapFamily && tokenCount <= 5;
}

bool _isBareMixedCondensateReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bcondensate\b').hasMatch(normalized)) return false;
  final hasExplicitCondensateFamily = RegExp(
    r'\b(drain|pump|line|tub(e|ing)|trap|pan|switch|float|tablet|'
    r'gun|cartridge|hvac|furnace|air\s*handler|ac|a/c)\b',
  ).hasMatch(normalized);
  return !hasExplicitCondensateFamily && tokenCount <= 3;
}

bool _isBareMixedTeeReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\btee\b').hasMatch(normalized)) return false;
  final hasExplicitTeeFamily = RegExp(
    r'\b(sanitary|santee|reducing|reducer|pvc|cpvc|pex|copper|cobre|'
    r'dwv|sch|schedule|cts|ips|mip|fip|compression|compresion|'
    r'sweat|threaded|rosca|conduit|electrical|electrico|hvac|'
    r'condensate|drain|vent)\b',
  ).hasMatch(normalized);
  return !hasExplicitTeeFamily && tokenCount <= 3;
}

bool _isBareMixedSizedTeeReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\btee\b').hasMatch(normalized)) return false;
  if (!RegExp(
    r'\b(?:1/4|3/8|1/2|5/8|3/4|1|1-1/4|1-1/2|2|2-1/2|3|4)\b',
  ).hasMatch(normalized)) {
    return false;
  }
  final hasExplicitSizedTeeFamily = RegExp(
    r'\b(sanitary|santee|reducing|reducer|pvc|cpvc|pex|copper|cobre|'
    r'dwv|sch|schedule|cts|ips|mip|fip|compression|compresion|'
    r'sweat|threaded|rosca|conduit|electrical|electrico|hvac|'
    r'condensate|drain|vent)\b',
  ).hasMatch(normalized);
  return !hasExplicitSizedTeeFamily && tokenCount <= 5;
}

bool _isBareMixedValveReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bvalve\b').hasMatch(normalized)) return false;
  final hasExplicitValveFamily = RegExp(
    r'\b(ball|gate|check|globe|mixing|service|relief|pressure|prv|'
    r'trv|zone|gas|stop|angle|sillcock|hose|boiler|condensate|'
    r'backflow|water heater|compressor|reversing|txv|expansion)\b',
  ).hasMatch(normalized);
  return !hasExplicitValveFamily && tokenCount <= 3;
}

bool _isBareMixedSizedValveReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bvalve\b').hasMatch(normalized)) return false;
  if (!RegExp(
    r'\b(?:1/4|3/8|1/2|5/8|3/4|1|1-1/4|1-1/2|2|2-1/2|3|4)\b',
  ).hasMatch(normalized)) {
    return false;
  }
  final hasExplicitSizedValveFamily = RegExp(
    r'\b(ball|gate|check|globe|mixing|service|relief|pressure|prv|'
    r'trv|zone|gas|stop|angle|sillcock|hose|boiler|condensate|'
    r'backflow|water heater|compressor|reversing|txv|expansion)\b',
  ).hasMatch(normalized);
  return !hasExplicitSizedValveFamily && tokenCount <= 5;
}

bool _isBareMixedAdapterReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\badapter\b').hasMatch(normalized)) return false;
  final hasExplicitAdapterFamily = RegExp(
    r'\b(male|female|mip|fip|mpt|fpt|trap|closet|flange|conduit|'
    r'pvc|cpvc|pex|copper|cobre|brass|bronze|barb|poly|cts|ips|'
    r'dwv|schedule|compression|compresion|sweat|threaded|rosca|'
    r'reducer|reducing|electrical|electrico|hvac|condensate)\b',
  ).hasMatch(normalized);
  return !hasExplicitAdapterFamily && tokenCount <= 3;
}

bool _isBareMixedSizedAdapterReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\badapter\b').hasMatch(normalized)) return false;
  if (!RegExp(
    r'\b(?:1/4|3/8|1/2|5/8|3/4|1|1-1/4|1-1/2|2|2-1/2|3|4)\b',
  ).hasMatch(normalized)) {
    return false;
  }
  final hasExplicitSizedAdapterFamily = RegExp(
    r'\b(male|female|mip|fip|mpt|fpt|trap|closet|flange|conduit|'
    r'pvc|cpvc|pex|copper|cobre|brass|bronze|barb|poly|cts|ips|'
    r'dwv|schedule|compression|compresion|sweat|threaded|rosca|'
    r'reducer|reducing|electrical|electrico|hvac|condensate)\b',
  ).hasMatch(normalized);
  return !hasExplicitSizedAdapterFamily && tokenCount <= 5;
}

bool _isBareMixedCompressionThreadReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bcomp\b').hasMatch(normalized)) return false;
  if (!RegExp(r'\b(fip|mip|fpt|mpt)\b').hasMatch(normalized)) return false;
  final hasExplicitCompressionThreadFamily = RegExp(
    r'\b(supply|stop|angle|valve|connector|hose|faucet|toilet|'
    r'dishwasher|ice maker|appliance|gas|dryer|water heater|'
    r'pex|cpvc|pvc|copper|cobre|brass|bronze|barb)\b',
  ).hasMatch(normalized);
  return !hasExplicitCompressionThreadFamily && tokenCount <= 7;
}

bool _isBareMixedBlackReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bblack\b').hasMatch(normalized)) return false;
  final hasExplicitBlackFamily = RegExp(
    r'\b(pipe|iron|steel|fitting|nipple|malleable|gas|coupling|elbow|'
    r'tee|cap|plug|paint|spray|primer)\b',
  ).hasMatch(normalized);
  return !hasExplicitBlackFamily && tokenCount <= 3;
}

bool _isBareMixedElbowReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\belbow\b').hasMatch(normalized)) return false;
  final hasExplicitElbowFamily = RegExp(
    r'\b(90|45|street|sweep|long turn|lt|conduit|pvc|cpvc|pex|'
    r'copper|cobre|dwv|schedule|sch|compression|compresion|'
    r'sweat|threaded|rosca|condensate|drain|vent|electrical|'
    r'electrico|hvac)\b',
  ).hasMatch(normalized);
  return !hasExplicitElbowFamily && tokenCount <= 3;
}

bool _isBareMixedPvcElbowReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bpvc\b').hasMatch(normalized)) return false;
  if (!RegExp(r'\belbow\b').hasMatch(normalized)) return false;
  final hasExplicitPvcElbowFamily = RegExp(
    r'\b(plumbing|electrical|hvac|condensate|conduit|dwv|drain|'
    r'vent|schedule|sch|pressure|sweep|long\s*turn|street|90|45)\b',
  ).hasMatch(normalized);
  return !hasExplicitPvcElbowFamily && tokenCount <= 5;
}

bool _isBareMixedCouplingReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bcoupling\b').hasMatch(normalized)) return false;
  final hasExplicitCouplingFamily = RegExp(
    r'\b(repair|slip|stop|conduit|emt|rigid|pvc|cpvc|pex|copper|'
    r'cobre|dwv|schedule|sch|compression|compresion|sweat|'
    r'threaded|rosca|reducer|reducing|electrical|electrico|'
    r'hvac|condensate|drain|vent)\b',
  ).hasMatch(normalized);
  return !hasExplicitCouplingFamily && tokenCount <= 3;
}

bool _isBareMixedSizedCouplingReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bcoupling\b').hasMatch(normalized)) return false;
  if (!RegExp(
    r'\b(?:1/4|3/8|1/2|5/8|3/4|1|1-1/4|1-1/2|2|2-1/2|3|4)\b',
  ).hasMatch(normalized)) {
    return false;
  }
  final hasExplicitSizedCouplingFamily = RegExp(
    r'\b(repair|slip|stop|conduit|emt|rigid|pvc|cpvc|pex|copper|'
    r'cobre|dwv|schedule|sch|compression|compresion|sweat|'
    r'threaded|rosca|reducer|reducing|electrical|electrico|'
    r'hvac|condensate|drain|vent)\b',
  ).hasMatch(normalized);
  return !hasExplicitSizedCouplingFamily && tokenCount <= 5;
}

bool _isBareMixedCtsCouplingReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bcts\b').hasMatch(normalized)) return false;
  if (!RegExp(r'\b(cpl|cplg|coupling)\b').hasMatch(normalized)) return false;
  final hasExplicitCtsCouplingFamily = RegExp(
    r'\b(cpvc|pex|copper|cobre|crimp|clamp|expansion|press|'
    r'push|sharkbite|threaded|rosca|sweat)\b',
  ).hasMatch(normalized);
  return !hasExplicitCtsCouplingFamily && tokenCount <= 5;
}

bool _isBareMixedConnectorReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bconnector\b').hasMatch(normalized)) return false;
  final hasExplicitConnectorFamily = RegExp(
    r'\b(conduit|cable|flex|pvc|emt|nm|mc|lfnc|sealtite|'
    r'compression|set\s*screw)\b',
  ).hasMatch(normalized);
  return !hasExplicitConnectorFamily && tokenCount <= 3;
}

bool _isBareMixedSizedConnectorReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bconnector\b').hasMatch(normalized)) return false;
  if (!RegExp(
    r'\b(?:1/4|3/8|1/2|5/8|3/4|1|1-1/4|1-1/2|2|2-1/2|3|4)\b',
  ).hasMatch(normalized)) {
    return false;
  }
  final hasExplicitSizedConnectorFamily = RegExp(
    r'\b(conduit|cable|flex|pvc|emt|nm|mc|lfnc|sealtite|'
    r'compression|set\s*screw|wire|toilet|faucet|gas|whip|'
    r'dishwasher|dryer|appliance)\b',
  ).hasMatch(normalized);
  return !hasExplicitSizedConnectorFamily && tokenCount <= 5;
}

bool _isBareMixedWireConnectorReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bwire\b').hasMatch(normalized)) return false;
  if (!RegExp(r'\bconnector\b').hasMatch(normalized)) return false;
  final hasExplicitWireConnectorFamily = RegExp(
    r'\b(splice|grounding|ground|twister|twist|electrical|wire\s*nut|'
    r'wirenut|lever|push-in|push in|wago|romex|nm|mc|outlet|switch)\b',
  ).hasMatch(normalized);
  return !hasExplicitWireConnectorFamily && tokenCount <= 4;
}

bool _isBareMixedConnectorKitReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bconnector\b').hasMatch(normalized)) return false;
  if (!RegExp(r'\bkit\b').hasMatch(normalized)) return false;
  final hasExplicitConnectorKitFamily = RegExp(
    r'\b(dishwasher|toilet|faucet|gas|dryer|appliance|electrical|'
    r'wire|romex|nm|mc|outlet|switch|whip|conduit)\b',
  ).hasMatch(normalized);
  return !hasExplicitConnectorKitFamily && tokenCount <= 4;
}

bool _isBareMixedConduitReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bconduit\b').hasMatch(normalized)) return false;
  final hasExplicitConduitFamily = RegExp(
    r'\b(emt|rigid|imc|pvc|sch|schedule|electrical|electrico|'
    r'sweep|connector|coupling|body|lb|ll|lr|strap|bushing|'
    r'locknut|condensate|drain|hvac|vent)\b',
  ).hasMatch(normalized);
  return !hasExplicitConduitFamily && tokenCount <= 3;
}

bool _isBareMixedSizedConduitReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bconduit\b').hasMatch(normalized)) return false;
  if (!RegExp(
    r'\b(?:1/4|3/8|1/2|5/8|3/4|1|1-1/4|1-1/2|2|2-1/2|3|4)\b',
  ).hasMatch(normalized)) {
    return false;
  }
  final hasExplicitSizedConduitFamily = RegExp(
    r'\b(emt|rigid|imc|pvc|sch|schedule|electrical|electrico|'
    r'sweep|connector|coupling|body|lb|ll|lr|strap|bushing|'
    r'locknut|condensate|drain|hvac|vent)\b',
  ).hasMatch(normalized);
  return !hasExplicitSizedConduitFamily && tokenCount <= 5;
}

bool _isBareMixedBoxReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bbox\b').hasMatch(normalized)) return false;
  final hasExplicitBoxFamily = RegExp(
    r'\b(junction|device|outlet|gang|handy|square|octagon|round|'
    r'weatherproof|wp|ceiling|fan|breaker|panel|repair|filter|'
    r'air|whole house|water heater)\b',
  ).hasMatch(normalized);
  return !hasExplicitBoxFamily && tokenCount <= 3;
}

bool _isBareMixedSizedBoxReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bbox\b').hasMatch(normalized)) return false;
  if (!RegExp(
    r'\b(?:\d+\s*x\s*\d+|\d+x\d+|\d+\s+\d+)\b',
  ).hasMatch(normalized)) {
    return false;
  }
  final hasExplicitSizedBoxFamily = RegExp(
    r'\b(junction|device|outlet|gang|handy|square|octagon|round|'
    r'weatherproof|wp|ceiling|fan|breaker|panel|repair|filter|'
    r'air|whole house|water heater)\b',
  ).hasMatch(normalized);
  return !hasExplicitSizedBoxFamily && tokenCount <= 6;
}

bool _isBareMixedJBoxReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bj\s*box\b').hasMatch(normalized)) return false;
  final hasExplicitJBoxFamily = RegExp(
    r'\b(device|junction|outlet|splice|gang|square|octagon|round|'
    r'electrical|emt|conduit|wire|switch|receptacle)\b',
  ).hasMatch(normalized);
  return !hasExplicitJBoxFamily && tokenCount <= 4;
}

bool _isBareMixedFilterReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bfilter\b').hasMatch(normalized)) return false;
  final hasExplicitFilterFamily = RegExp(
    r'\b(air|return|pleated|merv|whole house|water|sediment|carbon|'
    r'refrigerant|dryer|hvac|furnace|humidifier|vacuum|pump|'
    r'cartridge|housing)\b',
  ).hasMatch(normalized);
  return !hasExplicitFilterFamily && tokenCount <= 3;
}

bool _isBareMixedSizedFilterReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bfilter\b').hasMatch(normalized)) return false;
  if (!RegExp(
    r'\b(?:\d+\s*x\s*\d+\s*x\s*\d+|\d+x\d+x\d+)\b',
  ).hasMatch(normalized)) {
    return false;
  }
  final hasExplicitSizedFilterFamily = RegExp(
    r'\b(air|return|pleated|merv|whole house|water|sediment|carbon|'
    r'refrigerant|dryer|hvac|furnace|humidifier|vacuum|pump|'
    r'cartridge|housing)\b',
  ).hasMatch(normalized);
  return !hasExplicitSizedFilterFamily && tokenCount <= 7;
}

bool _isBareMixedPumpReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bpump\b').hasMatch(normalized)) return false;
  final hasExplicitPumpFamily = RegExp(
    r'\b(condensate|well|water|jet|sump|recirculation|circulation|'
    r'booster|drain|sewage|effluent|pool|utility|transfer|washer)\b',
  ).hasMatch(normalized);
  return !hasExplicitPumpFamily && tokenCount <= 3;
}

bool _isBareMixedSaltPelletsReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bsalt\b').hasMatch(normalized)) return false;
  if (!RegExp(r'\bpellets\b').hasMatch(normalized)) return false;
  final hasExplicitSaltPelletFamily = RegExp(
    r'\b(softener|brine|resin|water\s*treatment|whole\s*house|'
    r'filtration|filter|conditioner)\b',
  ).hasMatch(normalized);
  return !hasExplicitSaltPelletFamily && tokenCount <= 4;
}

bool _isBareMixedTapeReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\btape\b').hasMatch(normalized)) return false;
  final hasExplicitTapeFamily = RegExp(
    r'\b(electrical|teflon|foil|duct|hvac|thread|seal|sealing|'
    r'insulation|wire|romex|aluminum|aluminium|butyl)\b',
  ).hasMatch(normalized);
  return !hasExplicitTapeFamily && tokenCount <= 3;
}

bool _isBareMixedFoilTapeReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bfoil\b').hasMatch(normalized)) return false;
  if (!RegExp(r'\btape\b').hasMatch(normalized)) return false;
  final hasExplicitFoilTapeFamily = RegExp(
    r'\b(hvac|duct|mastic|ul181|return|supply|plenum|air\s*handler|'
    r'furnace|vent)\b',
  ).hasMatch(normalized);
  return !hasExplicitFoilTapeFamily && tokenCount <= 4;
}

bool _isBareMixedVentReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bvent\b').hasMatch(normalized)) return false;
  final hasExplicitVentFamily = RegExp(
    r'\b(roof|dryer|bath|register|flue|vent hood|hood|termination|'
    r'cap|boot|stack|furnace|supply|return|grille|damper)\b',
  ).hasMatch(normalized);
  return !hasExplicitVentFamily && tokenCount <= 3;
}

bool _isBareMixedDrainReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bdrain\b').hasMatch(normalized)) return false;
  final hasExplicitDrainFamily = RegExp(
    r'\b(floor|tub|shower|sink|lav|condensate|storm|roof|channel|'
    r'trench|waste|dwv|cleanout|register|pan|overflow|tailpiece)\b',
  ).hasMatch(normalized);
  return !hasExplicitDrainFamily && tokenCount <= 3;
}

bool _isBareMixedCondensateDrainReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bcondensate\b').hasMatch(normalized)) return false;
  if (!RegExp(r'\bdrain\b').hasMatch(normalized)) return false;
  final hasExplicitCondensateDrainFamily = RegExp(
    r'\b(trap|pan|pump|tubing|ac|air\s*handler|furnace|hvac|'
    r'coil|mini\s*split|plenum|return|supply)\b',
  ).hasMatch(normalized);
  return !hasExplicitCondensateDrainFamily && tokenCount <= 4;
}

bool _isBareMixedFittingReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bfitting\b').hasMatch(normalized)) return false;
  final hasExplicitFittingFamily = RegExp(
    r'\b(pvc|cpvc|pex|copper|brass|emt|conduit|dwv|abs|elbow|tee|'
    r'coupling|adapter|reducer|trap|compression|flare)\b',
  ).hasMatch(normalized);
  return !hasExplicitFittingFamily && tokenCount <= 3;
}

bool _isBareMixedPlugReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bplug\b').hasMatch(normalized)) return false;
  final hasExplicitPlugFamily = RegExp(
    r'\b(cleanout|test|cord|drain|rubber|expansion|freeze|fuse|'
    r'spark|wall|reset|accessory|mip|fip|npt|brass|pvc|cpvc)\b',
  ).hasMatch(normalized);
  return !hasExplicitPlugFamily && tokenCount <= 3;
}

bool _isBareMixedSizedPlugReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bplug\b').hasMatch(normalized)) return false;
  if (!RegExp(
    r'\b(?:1/4|3/8|1/2|5/8|3/4|1|1-1/4|1-1/2|2|2-1/2|3|4)\b',
  ).hasMatch(normalized)) {
    return false;
  }
  final hasExplicitSizedPlugFamily = RegExp(
    r'\b(cleanout|test|cord|drain|rubber|expansion|freeze|fuse|'
    r'spark|wall|reset|accessory|mip|fip|npt|brass|pvc|cpvc)\b',
  ).hasMatch(normalized);
  return !hasExplicitSizedPlugFamily && tokenCount <= 5;
}

bool _isBareMixedAccessReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\baccess\b').hasMatch(normalized)) return false;
  final hasExplicitAccessFamily = RegExp(
    r'\b(panel|door|cleanout|cover|grille|attic|ceiling|wall|'
    r'cabinet|hatch|electrical|plumbing|hvac|return|service)\b',
  ).hasMatch(normalized);
  return !hasExplicitAccessFamily && tokenCount <= 3;
}

bool _isBareMixedPlateReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bplate\b').hasMatch(normalized)) return false;
  final hasExplicitPlateFamily = RegExp(
    r'\b(cover|wall|nail|stud|guard|device|switch|outlet|repair|'
    r'flange|escutcheon|filler|dead front|register|boot)\b',
  ).hasMatch(normalized);
  return !hasExplicitPlateFamily && tokenCount <= 3;
}

bool _isBareMixedWasherReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bwasher\b').hasMatch(normalized)) return false;
  final hasExplicitWasherFamily = RegExp(
    r'\b(hose|trap|seat|fender|bibb|vacuum|slip|beveled|reducing|'
    r'toilet|tank|shank|faucet|stem|drain|laundry)\b',
  ).hasMatch(normalized);
  return !hasExplicitWasherFamily && tokenCount <= 3;
}

bool _isBareMixedSizedWasherReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bwasher\b').hasMatch(normalized)) return false;
  if (!RegExp(
    r'\b(?:1/4|3/8|1/2|5/8|3/4|1|1-1/4|1-1/2|2|2-1/2|3|4)\b',
  ).hasMatch(normalized)) {
    return false;
  }
  final hasExplicitSizedWasherFamily = RegExp(
    r'\b(hose|trap|seat|fender|bibb|vacuum|slip|beveled|reducing|'
    r'toilet|tank|shank|faucet|stem|drain|laundry|rubber|lock|'
    r'flat|sealing|compression)\b',
  ).hasMatch(normalized);
  return !hasExplicitSizedWasherFamily && tokenCount <= 5;
}

bool _isBareMixedWhiteReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bwhite\b').hasMatch(normalized)) return false;
  final hasExplicitWhiteFamily = RegExp(
    r'\b(pvc|pipe|fitting|wire|switch|plate|cover|caulk|sealant|'
    r'paint|primer|trim)\b',
  ).hasMatch(normalized);
  return !hasExplicitWhiteFamily && tokenCount <= 3;
}

bool _isBareMixedPrimerReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bprimer\b').hasMatch(normalized)) return false;
  final hasExplicitPrimerFamily = RegExp(
    r'\b(pvc|cpvc|trap|purple|pipe|cement|solvent|cleaner|adhesive)\b',
  ).hasMatch(normalized);
  return !hasExplicitPrimerFamily && tokenCount <= 3;
}

bool _isBareMixedSealReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bseal\b').hasMatch(normalized)) return false;
  final hasExplicitSealFamily = RegExp(
    r'\b(toilet|wax|tank|gasket|closet|flush|flange|door|window|'
    r'weather|shaft|oil|mechanical|condensate|water heater)\b',
  ).hasMatch(normalized);
  return !hasExplicitSealFamily && tokenCount <= 3;
}

bool _isBareMixedCleanerReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\b(cleaner|clean)\b').hasMatch(normalized)) return false;
  final hasExplicitCleanerFamily = RegExp(
    r'\b(coil|condenser|evap|evaporator|hvac|air|electronic|scrubber|'
    r'pvc|cpvc|primer|cement|solvent|adhesive|degreaser)\b',
  ).hasMatch(normalized);
  return !hasExplicitCleanerFamily && tokenCount <= 3;
}

bool _isBareMixedCementReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bcement\b').hasMatch(normalized)) return false;
  final hasExplicitCementFamily = RegExp(
    r'\b(pvc|cpvc|abs|dwv|solvent|glue|adhesive|pipe|primer|cleaner)\b',
  ).hasMatch(normalized);
  return !hasExplicitCementFamily && tokenCount <= 3;
}

bool _isBareMixedPvcCementReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bpvc\s+cement\b').hasMatch(normalized)) return false;
  final hasExplicitPvcCementFamily = RegExp(
    r'\b(plumbing|electrical|electric|elec|conduit|hvac|condensate|'
    r'pressure|dwv|schedule\s*40|schedule\s*80|sch\s*40|sch\s*80)\b',
  ).hasMatch(normalized);
  return !hasExplicitPvcCementFamily && tokenCount <= 4;
}

bool _isBareMixedRegisterReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bregister\b').hasMatch(normalized)) return false;
  final hasExplicitRegisterFamily = RegExp(
    r'\b(vent|grille|boot|return|supply|floor|ceiling|wall|damper|'
    r'flue|drain|overflow|cleanout|electrical|device|cover)\b',
  ).hasMatch(normalized);
  return !hasExplicitRegisterFamily && tokenCount <= 3;
}

bool _isBareMixedDeviceReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bdevice\b').hasMatch(normalized)) return false;
  final hasExplicitDeviceFamily = RegExp(
    r'\b(switch|outlet|receptacle|cover|plate|wall|electrical|wp|'
    r'weatherproof|smart|dimmer|gfci|afci|thermostat|sensor)\b',
  ).hasMatch(normalized);
  return !hasExplicitDeviceFamily && tokenCount <= 3;
}

bool _isBareMixedFixtureReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bfixture\b').hasMatch(normalized)) return false;
  final hasExplicitFixtureFamily = RegExp(
    r'\b(faucet|lav|sink|toilet|shower|light|lighting|led|heater|'
    r'water heater|fan|ceiling|bath|kitchen|repair)\b',
  ).hasMatch(normalized);
  return !hasExplicitFixtureFamily && tokenCount <= 3;
}

bool _isBareMixedMeterReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bmeter\b').hasMatch(normalized)) return false;
  final hasExplicitMeterFamily = RegExp(
    r'\b(clamp|electrical|voltage|amp|ampere|multimeter|gas|water|'
    r'flow|pressure|utility|submeter)\b',
  ).hasMatch(normalized);
  return !hasExplicitMeterFamily && tokenCount <= 3;
}

bool _isBareMixedPvcReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bpvc\b').hasMatch(normalized)) return false;
  final hasExplicitPvcFamily = RegExp(
    r'\b(pipe|conduit|elbow|ell|elb|tee|coupling|adapter|reducer|'
    r'cement|primer|sch\s*40|sch\s*80|schedule\s*40|schedule\s*80|'
    r'dwv|drain|pressure|cond|condensate|electrical|emt)\b',
  ).hasMatch(normalized);
  return !hasExplicitPvcFamily && tokenCount <= 3;
}

bool _isBareMixedSizedPvcReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bpvc\b').hasMatch(normalized)) return false;
  if (!RegExp(
    r'\b(?:1/4|3/8|1/2|5/8|3/4|1|1-1/4|1-1/2|2|2-1/2|3|4)\b',
  ).hasMatch(normalized)) {
    return false;
  }
  final hasExplicitSizedPvcFamily = RegExp(
    r'\b(pipe|conduit|elbow|ell|elb|tee|coupling|adapter|reducer|'
    r'cement|primer|sch\s*40|sch\s*80|schedule\s*40|schedule\s*80|'
    r'dwv|drain|pressure|cond|condensate|electrical|emt)\b',
  ).hasMatch(normalized);
  return !hasExplicitSizedPvcFamily && tokenCount <= 5;
}

bool _isBareMixedHoodReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bhood\b').hasMatch(normalized)) return false;
  final hasExplicitHoodFamily = RegExp(
    r'\b(vent|range|bath|dryer|termination|flue|kitchen|exhaust|'
    r'furnace|canopy)\b',
  ).hasMatch(normalized);
  return !hasExplicitHoodFamily && tokenCount <= 3;
}

bool _isBareMixedGrilleReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bgrille\b').hasMatch(normalized)) return false;
  final hasExplicitGrilleFamily = RegExp(
    r'\b(return|supply|filter|wall|ceiling|floor|vent|register|'
    r'diffuser|eggcrate|hvac)\b',
  ).hasMatch(normalized);
  return !hasExplicitGrilleFamily && tokenCount <= 3;
}

bool _isBareMixedBootReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bboot\b').hasMatch(normalized)) return false;
  final hasExplicitBootFamily = RegExp(
    r'\b(register|vent|roof|pipe|flashing|wall|ceiling|floor|stack|'
    r'duct|grille|return|supply)\b',
  ).hasMatch(normalized);
  return !hasExplicitBootFamily && tokenCount <= 3;
}

bool _isBareMixedDamperReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bdamper\b').hasMatch(normalized)) return false;
  final hasExplicitDamperFamily = RegExp(
    r'\b(vent|furnace|return|supply|bypass|zone|flue|draft|dryer|'
    r'bath|hood|fire)\b',
  ).hasMatch(normalized);
  return !hasExplicitDamperFamily && tokenCount <= 3;
}

bool _isBareMixedDoorReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bdoor\b').hasMatch(normalized)) return false;
  final hasExplicitDoorFamily = RegExp(
    r'\b(access|attic|panel|cleanout|return|furnace|blower|dead\s*front|'
    r'electrical|cabinet|hatch)\b',
  ).hasMatch(normalized);
  return !hasExplicitDoorFamily && tokenCount <= 3;
}

bool _isBareMixedWallReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bwall\b').hasMatch(normalized)) return false;
  final hasExplicitWallFamily = RegExp(
    r'\b(plate|switch|boot|bend|tube|access|return|register|grille|'
    r'sconce|light|escutcheon|plug|device|cover)\b',
  ).hasMatch(normalized);
  return !hasExplicitWallFamily && tokenCount <= 3;
}

bool _isBareMixedFanReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bfan\b').hasMatch(normalized)) return false;
  final hasExplicitFanFamily = RegExp(
    r'\b(ceiling|bath|exhaust|blower|attic|range|condenser|air|'
    r'furnace|ventilation|inline)\b',
  ).hasMatch(normalized);
  return !hasExplicitFanFamily && tokenCount <= 3;
}

bool _isBareMixedLightReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\blight\b').hasMatch(normalized)) return false;
  final hasExplicitLightFamily = RegExp(
    r'\b(fixture|led|wall|bulb|lamp|sconce|can|recessed|strip|'
    r'emergency|exit|shop)\b',
  ).hasMatch(normalized);
  return !hasExplicitLightFamily && tokenCount <= 3;
}

bool _isBareMixedCeilingReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bceiling\b').hasMatch(normalized)) return false;
  final hasExplicitCeilingFamily = RegExp(
    r'\b(fan|register|light|box|grille|diffuser|fixture|medallion|'
    r'canopy|access)\b',
  ).hasMatch(normalized);
  return !hasExplicitCeilingFamily && tokenCount <= 3;
}

bool _isBareMixedAtticReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\battic\b').hasMatch(normalized)) return false;
  final hasExplicitAtticFamily = RegExp(
    r'\b(access|fan|ladder|stair|insulation|vent|hatch|cover|'
    r'pull\s*down|scuttle)\b',
  ).hasMatch(normalized);
  return !hasExplicitAtticFamily && tokenCount <= 3;
}

bool _isBareMixedFloorReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bfloor\b').hasMatch(normalized)) return false;
  final hasExplicitFloorFamily = RegExp(
    r'\b(drain|register|flange|sink|cleanout|vent|grille|boot|'
    r'shower|pan|channel)\b',
  ).hasMatch(normalized);
  return !hasExplicitFloorFamily && tokenCount <= 3;
}

bool _isBareMixedRoofReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\broof\b').hasMatch(normalized)) return false;
  final hasExplicitRoofFamily = RegExp(
    r'\b(vent|drain|boot|cap|flashing|jack|stack|termination|'
    r'dryer|bath|storm)\b',
  ).hasMatch(normalized);
  return !hasExplicitRoofFamily && tokenCount <= 3;
}

bool _isBareMixedWindowReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bwindow\b').hasMatch(normalized)) return false;
  final hasExplicitWindowFamily = RegExp(
    r'\b(seal|sash|screen|frame|trim|pane|glass|flange|weather|'
    r'well|opening)\b',
  ).hasMatch(normalized);
  return !hasExplicitWindowFamily && tokenCount <= 3;
}

bool _isBareMixedStackReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bstack\b').hasMatch(normalized)) return false;
  final hasExplicitStackFamily = RegExp(
    r'\b(roof|vent|soil|pipe|boot|flashing|termination|furnace|'
    r'drain|dwv)\b',
  ).hasMatch(normalized);
  return !hasExplicitStackFamily && tokenCount <= 3;
}

bool _isBareMixedBathReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bbath\b').hasMatch(normalized)) return false;
  final hasExplicitBathFamily = RegExp(
    r'\b(fan|drain|vent|exhaust|register|hood|trim|faucet|shower|'
    r'tub|sink|lav)\b',
  ).hasMatch(normalized);
  return !hasExplicitBathFamily && tokenCount <= 3;
}

bool _isBareMixedKitchenReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bkitchen\b').hasMatch(normalized)) return false;
  final hasExplicitKitchenFamily = RegExp(
    r'\b(faucet|sink|vent|range|hood|disposal|dishwasher|drain|'
    r'trim|sprayer|soap)\b',
  ).hasMatch(normalized);
  return !hasExplicitKitchenFamily && tokenCount <= 3;
}

bool _isBareMixedSinkReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bsink\b').hasMatch(normalized)) return false;
  final hasExplicitSinkFamily = RegExp(
    r'\b(drain|lav|tub|faucet|kitchen|bath|basket|strainer|tailpiece|'
    r'clip|mount|bowl)\b',
  ).hasMatch(normalized);
  return !hasExplicitSinkFamily && tokenCount <= 3;
}

bool _isBareMixedShowerReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bshower\b').hasMatch(normalized)) return false;
  final hasExplicitShowerFamily = RegExp(
    r'\b(drain|pan|valve|arm|head|trim|faucet|bath|door|base|'
    r'liner|curtain)\b',
  ).hasMatch(normalized);
  return !hasExplicitShowerFamily && tokenCount <= 3;
}

bool _isBareMixedTubReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\btub\b').hasMatch(normalized)) return false;
  final hasExplicitTubFamily = RegExp(
    r'\b(drain|shower|bath|waste|overflow|shoe|spout|faucet|trim|'
    r'pan|waste\s*and\s*overflow)\b',
  ).hasMatch(normalized);
  return !hasExplicitTubFamily && tokenCount <= 3;
}

bool _isBareMixedLavReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\blav\b').hasMatch(normalized)) return false;
  final hasExplicitLavFamily = RegExp(
    r'\b(sink|faucet|drain|bath|vanity|pop\s*up|popup|stop|supply|'
    r'trap|tailpiece)\b',
  ).hasMatch(normalized);
  return !hasExplicitLavFamily && tokenCount <= 3;
}

bool _isBareMixedFrameReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bframe\b').hasMatch(normalized)) return false;
  final hasExplicitFrameFamily = RegExp(
    r'\b(window|screen|glass|pane|door|trim|sash|mirror|grille|'
    r'register|filter)\b',
  ).hasMatch(normalized);
  return !hasExplicitFrameFamily && tokenCount <= 3;
}

bool _isBareMixedScreenReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bscreen\b').hasMatch(normalized)) return false;
  final hasExplicitScreenFamily = RegExp(
    r'\b(window|frame|mesh|filter|touch|door|insect|lint|guard|'
    r'protector)\b',
  ).hasMatch(normalized);
  return !hasExplicitScreenFamily && tokenCount <= 3;
}

bool _isBareMixedHeadReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bhead\b').hasMatch(normalized)) return false;
  final hasExplicitHeadFamily = RegExp(
    r'\b(shower|sprinkler|weatherhead|mop|pump|trim|faucet|power|'
    r'trimmer|discharge)\b',
  ).hasMatch(normalized);
  return !hasExplicitHeadFamily && tokenCount <= 3;
}

bool _isBareMixedBaseReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bbase\b').hasMatch(normalized)) return false;
  final hasExplicitBaseFamily = RegExp(
    r'\b(shower|fixture|mount|lamp|fan|flange|support|stand|'
    r'cabinet|trim)\b',
  ).hasMatch(normalized);
  return !hasExplicitBaseFamily && tokenCount <= 3;
}

bool _isBareMixedGlassReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bglass\b').hasMatch(normalized)) return false;
  final hasExplicitGlassFamily = RegExp(
    r'\b(pane|window|screen|frame|door|mirror|shade|lens|gauge|'
    r'sight|sash)\b',
  ).hasMatch(normalized);
  return !hasExplicitGlassFamily && tokenCount <= 3;
}

bool _isBareMixedPaneReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bpane\b').hasMatch(normalized)) return false;
  final hasExplicitPaneFamily = RegExp(
    r'\b(glass|window|frame|screen|storm|sash|insulated|double|'
    r'single|door)\b',
  ).hasMatch(normalized);
  return !hasExplicitPaneFamily && tokenCount <= 3;
}

bool _isBareMixedSashReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bsash\b').hasMatch(normalized)) return false;
  final hasExplicitSashFamily = RegExp(
    r'\b(window|pane|screen|frame|glass|tilt|storm|balance|'
    r'lock|weather)\b',
  ).hasMatch(normalized);
  return !hasExplicitSashFamily && tokenCount <= 3;
}

bool _isBareMixedTrimReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\btrim\b').hasMatch(normalized)) return false;
  final hasExplicitTrimFamily = RegExp(
    r'\b(shower|faucet|window|door|valve|head|base|kit|moulding|'
    r'molding|escutcheon|repair)\b',
  ).hasMatch(normalized);
  return !hasExplicitTrimFamily && tokenCount <= 3;
}

bool _isBareMixedArmReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\barm\b').hasMatch(normalized)) return false;
  final hasExplicitArmFamily = RegExp(
    r'\b(shower|support|mount|mop|extension|control|float|pitman|'
    r'bracket|spray)\b',
  ).hasMatch(normalized);
  return !hasExplicitArmFamily && tokenCount <= 3;
}

bool _isBareMixedMountReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bmount\b').hasMatch(normalized)) return false;
  final hasExplicitMountFamily = RegExp(
    r'\b(fixture|fan|bracket|ceiling|wall|surface|flush|junction|'
    r'camera|plate|support)\b',
  ).hasMatch(normalized);
  return !hasExplicitMountFamily && tokenCount <= 3;
}

bool _isBareMixedMirrorReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bmirror\b').hasMatch(normalized)) return false;
  final hasExplicitMirrorFamily = RegExp(
    r'\b(glass|frame|cabinet|bath|vanity|medicine|door|mount|'
    r'clip|bevel)\b',
  ).hasMatch(normalized);
  return !hasExplicitMirrorFamily && tokenCount <= 3;
}

bool _isBareMixedLensReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\blens\b').hasMatch(normalized)) return false;
  final hasExplicitLensFamily = RegExp(
    r'\b(light|cover|fixture|lamp|diffuser|led|canopy|camera|'
    r'safety|shade)\b',
  ).hasMatch(normalized);
  return !hasExplicitLensFamily && tokenCount <= 3;
}

bool _isBareMixedShadeReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bshade\b').hasMatch(normalized)) return false;
  final hasExplicitShadeFamily = RegExp(
    r'\b(lens|lamp|window|blind|glass|fixture|mirror|sconce|'
    r'roller|solar)\b',
  ).hasMatch(normalized);
  return !hasExplicitShadeFamily && tokenCount <= 3;
}

bool _isBareMixedSupplyReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bsupply\b').hasMatch(normalized)) return false;
  final hasExplicitSupplyFamily = RegExp(
    r'\b(line|hose|tub(e|ing)|register|vent|plenum|boot|toilet|faucet|'
    r'dishwasher|gas|water\s*heater|hvac|air|return|diffuser)\b',
  ).hasMatch(normalized);
  return !hasExplicitSupplyFamily && tokenCount <= 3;
}

bool _isBareMixedSupportReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bsupport\b').hasMatch(normalized)) return false;
  final hasExplicitSupportFamily = RegExp(
    r'\b(bracket|mount|fan|pipe|hanger|stand|camera|wall|ceiling|'
    r'flange|support\s+arm)\b',
  ).hasMatch(normalized);
  return !hasExplicitSupportFamily && tokenCount <= 3;
}

bool _isBareMixedBracketReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bbracket\b').hasMatch(normalized)) return false;
  final hasExplicitBracketFamily = RegExp(
    r'\b(shelf|support|fan|mount|wall|rail|post|hanger|angle|'
    r'joist|beam)\b',
  ).hasMatch(normalized);
  return !hasExplicitBracketFamily && tokenCount <= 3;
}

bool _isBareMixedFlangeReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bflange\b').hasMatch(normalized)) return false;
  final hasExplicitFlangeFamily = RegExp(
    r'\b(closet|toilet|hub|floor|pipe|roof|drain|cleanout|'
    r'mount|anchor)\b',
  ).hasMatch(normalized);
  return !hasExplicitFlangeFamily && tokenCount <= 3;
}

bool _isBareMixedGasketReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bgasket\b').hasMatch(normalized)) return false;
  final hasExplicitGasketFamily = RegExp(
    r'\b(toilet|flange|burner|wax|tank|seal|pump|valve|door|'
    r'blower|drain)\b',
  ).hasMatch(normalized);
  return !hasExplicitGasketFamily && tokenCount <= 3;
}

bool _isBareMixedHangerReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bhanger\b').hasMatch(normalized)) return false;
  final hasExplicitHangerFamily = RegExp(
    r'\b(pipe|strap|beam|joist|support|mount|rod|wire|duct|'
    r'conduit)\b',
  ).hasMatch(normalized);
  return !hasExplicitHangerFamily && tokenCount <= 3;
}

bool _isBareMixedSeatReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bseat\b').hasMatch(normalized)) return false;
  final hasExplicitSeatFamily = RegExp(
    r'\b(toilet|faucet|valve|repair|closet|hinge|cover|bidet|'
    r'flush|lav)\b',
  ).hasMatch(normalized);
  return !hasExplicitSeatFamily && tokenCount <= 3;
}

bool _isBareMixedStopReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bstop\b').hasMatch(normalized)) return false;
  final hasExplicitStopFamily = RegExp(
    r'\b(angle|door|compression|valve|wheel|limit|kick|'
    r'shutdown|wall|supply)\b',
  ).hasMatch(normalized);
  return !hasExplicitStopFamily && tokenCount <= 3;
}

bool _isBareMixedHandleReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bhandle\b').hasMatch(normalized)) return false;
  final hasExplicitHandleFamily = RegExp(
    r'\b(faucet|door|toilet|tank|flush|shower|trim|pull|'
    r'knob|valve)\b',
  ).hasMatch(normalized);
  return !hasExplicitHandleFamily && tokenCount <= 3;
}

bool _isBareMixedLeverReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\blever\b').hasMatch(normalized)) return false;
  final hasExplicitLeverFamily = RegExp(
    r'\b(flush|valve|door|trip|tank|stop|trim|'
    r'control|handle|faucet)\b',
  ).hasMatch(normalized);
  return !hasExplicitLeverFamily && tokenCount <= 3;
}

bool _isBareMixedHingeReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bhinge\b').hasMatch(normalized)) return false;
  final hasExplicitHingeFamily = RegExp(
    r'\b(toilet|door|seat|cover|cabinet|gate|lid|closet|'
    r'panel|shower)\b',
  ).hasMatch(normalized);
  return !hasExplicitHingeFamily && tokenCount <= 3;
}

bool _isBareMixedSpringReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bspring\b').hasMatch(normalized)) return false;
  final hasExplicitSpringFamily = RegExp(
    r'\b(faucet|door|trap|repair|valve|seat|handle|'
    r'flush|clip|closer)\b',
  ).hasMatch(normalized);
  return !hasExplicitSpringFamily && tokenCount <= 3;
}

bool _isBareMixedBodyReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bbody\b').hasMatch(normalized)) return false;
  final hasExplicitBodyFamily = RegExp(
    r'\b(valve|faucet|sprayer|pump|shower|adapter|nipple|'
    r'assembly|trim|drain)\b',
  ).hasMatch(normalized);
  return !hasExplicitBodyFamily && tokenCount <= 3;
}

bool _isBareMixedRingReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bring\b').hasMatch(normalized)) return false;
  final hasExplicitRingFamily = RegExp(
    r'\b(wax|closet|trim|seal|o-ring|oring|retaining|'
    r'lock|snap|flange)\b',
  ).hasMatch(normalized);
  return !hasExplicitRingFamily && tokenCount <= 3;
}

bool _isBareMixedClipReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bclip\b').hasMatch(normalized)) return false;
  final hasExplicitClipFamily = RegExp(
    r'\b(conduit|pipe|spring|retainer|wire|duct|cable|'
    r'mount|strap|anchor)\b',
  ).hasMatch(normalized);
  return !hasExplicitClipFamily && tokenCount <= 3;
}

bool _isBareMixedSleeveReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bsleeve\b').hasMatch(normalized)) return false;
  final hasExplicitSleeveFamily = RegExp(
    r'\b(repair|anchor|pipe|coupling|wall|pass-through|'
    r'passthrough|insulator|conduit|seal)\b',
  ).hasMatch(normalized);
  return !hasExplicitSleeveFamily && tokenCount <= 3;
}

bool _isBareMixedCollarReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bcollar\b').hasMatch(normalized)) return false;
  final hasExplicitCollarFamily = RegExp(
    r'\b(pipe|escutcheon|duct|flue|wall|roof|conduit|'
    r'clamp|support|hanger)\b',
  ).hasMatch(normalized);
  return !hasExplicitCollarFamily && tokenCount <= 3;
}

bool _isBareMixedHookReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bhook\b').hasMatch(normalized)) return false;
  final hasExplicitHookFamily = RegExp(
    r'\b(hanger|wall|tool|mount|ceiling|plant|utility|'
    r'storage|peg|bracket)\b',
  ).hasMatch(normalized);
  return !hasExplicitHookFamily && tokenCount <= 3;
}

bool _isBareMixedAnchorReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\banchor\b').hasMatch(normalized)) return false;
  final hasExplicitAnchorFamily = RegExp(
    r'\b(wall|sleeve|bolt|masonry|concrete|toggle|wedge|'
    r'pipe|clip|mount)\b',
  ).hasMatch(normalized);
  return !hasExplicitAnchorFamily && tokenCount <= 3;
}

bool _isBareMixedPostReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bpost\b').hasMatch(normalized)) return false;
  final hasExplicitPostFamily = RegExp(
    r'\b(fence|support|base|mount|bracket|rail|column|'
    r'channel|cap|guard)\b',
  ).hasMatch(normalized);
  return !hasExplicitPostFamily && tokenCount <= 3;
}

bool _isBareMixedChannelReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bchannel\b').hasMatch(normalized)) return false;
  final hasExplicitChannelFamily = RegExp(
    r'\b(strut|rail|track|support|unistrut|duct|mount|'
    r'frame|post|bracket)\b',
  ).hasMatch(normalized);
  return !hasExplicitChannelFamily && tokenCount <= 3;
}

bool _isBareMixedRailReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\brail\b').hasMatch(normalized)) return false;
  final hasExplicitRailFamily = RegExp(
    r'\b(support|track|channel|mount|guard|fence|slide|'
    r'bracket|base|system)\b',
  ).hasMatch(normalized);
  return !hasExplicitRailFamily && tokenCount <= 3;
}

bool _isBareMixedBarReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bbar\b').hasMatch(normalized)) return false;
  final hasExplicitBarFamily = RegExp(
    r'\b(support|grab|hanger|rail|mount|towel|shower|'
    r'closet|channel|brace)\b',
  ).hasMatch(normalized);
  return !hasExplicitBarFamily && tokenCount <= 3;
}

bool _isBareMixedTrayReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\btray\b').hasMatch(normalized)) return false;
  final hasExplicitTrayFamily = RegExp(
    r'\b(drain|shower|pan|overflow|condensate|catch|'
    r'utility|pump|washer|water)\b',
  ).hasMatch(normalized);
  return !hasExplicitTrayFamily && tokenCount <= 3;
}

bool _isBareMixedPanReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bpan\b').hasMatch(normalized)) return false;
  final hasExplicitPanFamily = RegExp(
    r'\b(drain|shower|heater|water|condensate|washer|'
    r'catch|overflow|utility|pump)\b',
  ).hasMatch(normalized);
  return !hasExplicitPanFamily && tokenCount <= 3;
}

bool _isBareMixedShellReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bshell\b').hasMatch(normalized)) return false;
  final hasExplicitShellFamily = RegExp(
    r'\b(housing|cover|case|body|motor|fan|'
    r'enclosure|trim|cabinet|guard)\b',
  ).hasMatch(normalized);
  return !hasExplicitShellFamily && tokenCount <= 3;
}

bool _isBareMixedJointReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bjoint\b').hasMatch(normalized)) return false;
  final hasExplicitJointFamily = RegExp(
    r'\b(expansion|slip|repair|union|flex|pipe|coupling|'
    r'gasket|sleeve|connection)\b',
  ).hasMatch(normalized);
  return !hasExplicitJointFamily && tokenCount <= 3;
}

bool _isBareMixedStubReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bstub\b').hasMatch(normalized)) return false;
  final hasExplicitStubFamily = RegExp(
    r'\b(out|nipple|pipe|copper|pex|riser|drop|'
    r'stub-out|stubout|supply)\b',
  ).hasMatch(normalized);
  return !hasExplicitStubFamily && tokenCount <= 3;
}

bool _isBareMixedBranchReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bbranch\b').hasMatch(normalized)) return false;
  final hasExplicitBranchFamily = RegExp(
    r'\b(circuit|wye|drain|line|takeoff|tee|run|'
    r'lateral|pipe|conduit)\b',
  ).hasMatch(normalized);
  return !hasExplicitBranchFamily && tokenCount <= 3;
}

bool _isBareMixedSpliceReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bsplice\b').hasMatch(normalized)) return false;
  final hasExplicitSpliceFamily = RegExp(
    r'\b(wire|kit|repair|connector|heat-shrink|heatshrink|'
    r'conduit|cable|crimp|tap)\b',
  ).hasMatch(normalized);
  return !hasExplicitSpliceFamily && tokenCount <= 3;
}

bool _isBareMixedBoltReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bbolt\b').hasMatch(normalized)) return false;
  final hasExplicitBoltFamily = RegExp(
    r'\b(anchor|carriage|lag|hex|u-bolt|ubolt|toggle|'
    r'wedge|machine|expansion)\b',
  ).hasMatch(normalized);
  return !hasExplicitBoltFamily && tokenCount <= 3;
}

bool _isBareMixedRodReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\brod\b').hasMatch(normalized)) return false;
  final hasExplicitRodFamily = RegExp(
    r'\b(threaded|hanger|anode|support|brass|weld|'
    r'ground|closet|mount|suspension)\b',
  ).hasMatch(normalized);
  return !hasExplicitRodFamily && tokenCount <= 3;
}

bool _isBareMixedCageReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bcage\b').hasMatch(normalized)) return false;
  final hasExplicitCageFamily = RegExp(
    r'\b(fan|guard|lamp|motor|blower|protector|cover|'
    r'grille|screen|housing)\b',
  ).hasMatch(normalized);
  return !hasExplicitCageFamily && tokenCount <= 3;
}

bool _isBareMixedHousingReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bhousing\b').hasMatch(normalized)) return false;
  final hasExplicitHousingFamily = RegExp(
    r'\b(motor|fan|trim|pump|lamp|switch|blower|case|'
    r'enclosure|shell)\b',
  ).hasMatch(normalized);
  return !hasExplicitHousingFamily && tokenCount <= 3;
}

bool _isBareMixedGuardReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bguard\b').hasMatch(normalized)) return false;
  final hasExplicitGuardFamily = RegExp(
    r'\b(fan|blade|wire|safety|screen|cage|grille|'
    r'cover|protector|rail)\b',
  ).hasMatch(normalized);
  return !hasExplicitGuardFamily && tokenCount <= 3;
}

bool _isBareMixedCaseReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bcase\b').hasMatch(normalized)) return false;
  final hasExplicitCaseFamily = RegExp(
    r'\b(breaker|motor|housing|cover|electrical|switch|tool|'
    r'enclosure|shell|blower)\b',
  ).hasMatch(normalized);
  return !hasExplicitCaseFamily && tokenCount <= 3;
}

bool _isBareMixedNutReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bnut\b').hasMatch(normalized)) return false;
  final hasExplicitNutFamily = RegExp(
    r'\b(lock|wire|compression|hex|flare|cap|union|'
    r'jam|wing|coupling)\b',
  ).hasMatch(normalized);
  return !hasExplicitNutFamily && tokenCount <= 3;
}

bool _isBareMixedKitReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bkit\b').hasMatch(normalized)) return false;
  final hasExplicitKitFamily = RegExp(
    r'\b(repair|toilet|faucet|trim|shower|valve|flush|'
    r'install|service|replacement)\b',
  ).hasMatch(normalized);
  return !hasExplicitKitFamily && tokenCount <= 3;
}

bool _isBareMixedMotorReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bmotor\b').hasMatch(normalized)) return false;
  final hasExplicitMotorFamily = RegExp(
    r'\b(blower|fan|pump|condenser|draft|furnace|exhaust|'
    r'shade|gear|assembly)\b',
  ).hasMatch(normalized);
  return !hasExplicitMotorFamily && tokenCount <= 3;
}

bool _isBareMixedSensorReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bsensor\b').hasMatch(normalized)) return false;
  final hasExplicitSensorFamily = RegExp(
    r'\b(flame|photo|safety|outdoor|indoor|return|discharge|'
    r'duct|defrost|floor|heat|temp|temperature|humidity|'
    r'enthalpy|leak|water|motion|door|window|gate)\b',
  ).hasMatch(normalized);
  return !hasExplicitSensorFamily && tokenCount <= 3;
}

bool _isBareMixedControlReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bcontrol\b').hasMatch(normalized)) return false;
  final hasExplicitControlFamily = RegExp(
    r'\b(zone|panel|board|wire|valve|flow|gas|fan|remote|'
    r'access|volume|joint|weed|temperature|motor|pump)\b',
  ).hasMatch(normalized);
  return !hasExplicitControlFamily && tokenCount <= 3;
}

bool _isBareMixedRelayReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\brelay\b').hasMatch(normalized)) return false;
  final hasExplicitRelayFamily = RegExp(
    r'\b(time|delay|fan|potential|isolation|start|coil|board|'
    r'compressor|pump|defrost)\b',
  ).hasMatch(normalized);
  return !hasExplicitRelayFamily && tokenCount <= 3;
}

bool _isBareMixedHeaterReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bheater\b').hasMatch(normalized)) return false;
  final hasExplicitHeaterFamily = RegExp(
    r'\b(water|crankcase|baseboard|unit|space|garage|tank|'
    r'element|block|gas|electric)\b',
  ).hasMatch(normalized);
  return !hasExplicitHeaterFamily && tokenCount <= 3;
}

bool _isBareMixedCapacitorReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bcapacitor\b').hasMatch(normalized)) return false;
  final hasExplicitCapacitorFamily = RegExp(
    r'\b(run|dual|start|mfd|uf|microfarad|motor|compressor|'
    r'hard\s*start|fan)\b',
  ).hasMatch(normalized);
  return !hasExplicitCapacitorFamily && tokenCount <= 3;
}

bool _isBareMixedContactorReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bcontactor\b').hasMatch(normalized)) return false;
  final hasExplicitContactorFamily = RegExp(
    r'\b(compressor|coil|pole|2p|1p|definite|purpose|amp|a|24v|'
    r'30a|40a|fan|unit)\b',
  ).hasMatch(normalized);
  return !hasExplicitContactorFamily && tokenCount <= 3;
}

bool _isBareMixedBoardReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bboard\b').hasMatch(normalized)) return false;
  final hasExplicitBoardFamily = RegExp(
    r'\b(control|furnace|defrost|foam|backer|cement|duct|zone|'
    r'ram|floor|protection|terminal|panel)\b',
  ).hasMatch(normalized);
  return !hasExplicitBoardFamily && tokenCount <= 3;
}

bool _isBareMixedTerminalReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bterminal\b').hasMatch(normalized)) return false;
  final hasExplicitTerminalFamily = RegExp(
    r'\b(spade|fork|ring|strip|adapter|block|lug|wire|connector|'
    r'conduit|bonding)\b',
  ).hasMatch(normalized);
  return !hasExplicitTerminalFamily && tokenCount <= 3;
}

bool _isBareMixedTransformerReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\btransformer\b').hasMatch(normalized)) return false;
  final hasExplicitTransformerFamily = RegExp(
    r'\b(24v|40va|doorbell|lighting|low\s*voltage|landscape|'
    r'control|hvac|bell)\b',
  ).hasMatch(normalized);
  return !hasExplicitTransformerFamily && tokenCount <= 3;
}

bool _isBareMixedFuseReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bfuse\b').hasMatch(normalized)) return false;
  final hasExplicitFuseFamily = RegExp(
    r'\b(blade|cartridge|plug|amp|a|3a|5a|20a|30a|time|delay|'
    r'low\s*volt|hvac|electrical)\b',
  ).hasMatch(normalized);
  return !hasExplicitFuseFamily && tokenCount <= 3;
}

bool _isBareMixedDisconnectReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bdisconnect\b').hasMatch(normalized)) return false;
  final hasExplicitDisconnectFamily = RegExp(
    r'\b(ac|pullout|fusible|non\s*fusible|box|service|safety|'
    r'air|conditioner|hvac)\b',
  ).hasMatch(normalized);
  return !hasExplicitDisconnectFamily && tokenCount <= 3;
}

bool _isBareMixedWhipReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bwhip\b').hasMatch(normalized)) return false;
  final hasExplicitWhipFamily = RegExp(
    r'\b(ac|equipment|liquidtight|disconnect|flex|conduit|seal|'
    r'3/4|1/2|6ft|whip\s*kit)\b',
  ).hasMatch(normalized);
  return !hasExplicitWhipFamily && tokenCount <= 3;
}

bool _isBareMixedThermostatReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bthermostat\b').hasMatch(normalized)) return false;
  final hasExplicitThermostatFamily = RegExp(
    r'\b(heat\s*pump|smart|wifi|programmable|digital|1h|1c|'
    r'2h|2c|tstat|wall|pro)\b',
  ).hasMatch(normalized);
  return !hasExplicitThermostatFamily && tokenCount <= 3;
}

bool _isBareMixedFloatReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bfloat\b').hasMatch(normalized)) return false;
  final hasExplicitFloatFamily = RegExp(
    r'\b(switch|pan|pump|condensate|sump|level|septic|tethered|'
    r'piggyback|wet)\b',
  ).hasMatch(normalized);
  return !hasExplicitFloatFamily && tokenCount <= 3;
}

bool _isBareMixedBreakerReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bbreaker\b').hasMatch(normalized)) return false;
  final hasExplicitBreakerFamily = RegExp(
    r'\b(1p|2p|pole|single|double|gfci|afci|arc|amp|a|20a|30a|'
    r'40a|50a|dual\s*function)\b',
  ).hasMatch(normalized);
  return !hasExplicitBreakerFamily && tokenCount <= 3;
}

bool _isBareMixedReceptacleReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\breceptacle\b').hasMatch(normalized)) return false;
  final hasExplicitReceptacleFamily = RegExp(
    r'\b(duplex|gfci|wr|outlet|tamper|20a|15a|decorator|usb|'
    r'weather|resistant)\b',
  ).hasMatch(normalized);
  return !hasExplicitReceptacleFamily && tokenCount <= 3;
}

bool _isBareMixedOutletReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\boutlet\b').hasMatch(normalized)) return false;
  final hasExplicitOutletFamily = RegExp(
    r'\b(duplex|gfci|wall|receptacle|usb|wr|tamper|weather|'
    r'resistant|spacer)\b',
  ).hasMatch(normalized);
  return !hasExplicitOutletFamily && tokenCount <= 3;
}

bool _isBareMixedJunctionReceiptLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final normalized = _normalize(text);
  final tokenCount = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .length;
  if (!RegExp(r'\bjunction\b').hasMatch(normalized)) return false;
  final hasExplicitJunctionFamily = RegExp(
    r'\b(box|splice|pull|device|wire|old\s*work|j\s*box|conduit)\b',
  ).hasMatch(normalized);
  return !hasExplicitJunctionFamily && tokenCount <= 3;
}

bool _isGenericPvcElbowReceiptLine(String text) {
  final normalized = _normalize(text);
  if (!RegExp(r'\bpvc\b').hasMatch(normalized)) return false;
  final hasElbowShape =
      RegExp(r'\b(ell|el|elb|elbow|codo)\b').hasMatch(normalized) ||
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
  if (RegExp(
    r'\b\d{2}\s+(cop|copper|cu)\s+(90|ell|elb|elbow)\b',
  ).hasMatch(normalized)) {
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
  final hasSize =
      _nominalReceiptSize(normalized) != null ||
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
