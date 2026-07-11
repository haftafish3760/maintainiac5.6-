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

bool _isBareMixedSpanishConnectorReceiptLine(
  String text,
  String? tradeScope,
) {
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

bool _isBareMixedSpanishConduitReceiptLine(
  String text,
  String? tradeScope,
) {
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
