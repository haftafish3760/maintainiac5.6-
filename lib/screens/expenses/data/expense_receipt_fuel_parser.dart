part of 'expense_receipt_parser.dart';

class _FuelLineDetails {
  const _FuelLineDetails({
    required this.quantity,
    required this.fuelType,
    required this.fillType,
    this.unitPrice,
    this.odometerReading,
  });

  final _ParsedQuantity quantity;
  final String fuelType;
  final String fillType;
  final double? unitPrice;
  final int? odometerReading;
}

_FuelLineDetails _fuelDetailsFor({
  required String rawRow,
  required String description,
  required double amount,
  required List<String> receiptRows,
}) {
  final rawText = _normalizeFuelSignalText(rawRow);
  final descriptionText = _normalizeFuelSignalText(description);
  final receiptText = _normalizeFuelSignalText(receiptRows.join(' '));
  final lineText = '$rawText $descriptionText';
  final combinedText = '$rawText $descriptionText $receiptText';
  final fuelType = _fuelTypeForLine(
    lineText: lineText,
    receiptText: receiptText,
  );
  final parsedQuantity =
      _fuelExplicitLabeledQuantityIn(descriptionText) ??
      (_receiptHasOnlyFuelType(receiptRows, fuelType)
          ? _fuelExplicitLabeledQuantityIn(receiptText)
          : null) ??
      _fuelQuantityFor(rawText, amount: amount, fallbackText: receiptText);
  final unitPrice = _fuelUnitPriceFor(
    text: '$rawText $descriptionText',
    quantity: parsedQuantity,
    amount: amount,
    fallbackText: receiptText,
    fuelType: fuelType,
  );
  final quantity = _fuelQuantityWithUnitPriceFallback(
    quantity: parsedQuantity,
    unitPrice: unitPrice,
    amount: amount,
    text: combinedText,
    fuelType: fuelType,
  );
  return _FuelLineDetails(
    quantity: quantity,
    fuelType: fuelType,
    fillType: _fuelFillTypeFor(combinedText),
    unitPrice: unitPrice,
    odometerReading: _fuelOdometerFor(combinedText),
  );
}

bool _receiptHasOnlyFuelType(List<String> receiptRows, String fuelType) {
  final signals = receiptRows
      .map(_normalizeFuelSignalText)
      .map(_fuelTypeSignalFor)
      .whereType<String>()
      .toSet();
  return signals.isEmpty || (signals.length == 1 && signals.single == fuelType);
}

_ParsedQuantity _fuelQuantityWithUnitPriceFallback({
  required _ParsedQuantity quantity,
  required double? unitPrice,
  required double amount,
  required String text,
  required String fuelType,
}) {
  if (unitPrice == null || unitPrice <= 0 || amount <= 0) return quantity;
  if (quantity.quantity != 1 || quantity.unit != 'gallon') return quantity;
  var tolerance = amount.abs() * .02;
  if (tolerance < .05) tolerance = .05;
  if ((unitPrice - amount).abs() <= tolerance) return quantity;
  final inferred = amount / unitPrice;
  if (inferred <= 0 || inferred > 300) return quantity;
  return _ParsedQuantity(
    quantity: inferred,
    unitsPerPackage: 1,
    unit: _fuelUnitFromUnitPriceText(text) ?? _fuelUnitForType(fuelType),
  );
}

String _fuelUnitForType(String fuelType) {
  if (fuelType == 'CNG') return 'GGE';
  if (fuelType == 'LNG') return 'DGE';
  if (fuelType == 'Hydrogen') return 'kg';
  return fuelType == 'Electric' ? 'kWh' : 'gallon';
}

String? _fuelUnitFromUnitPriceText(String text) {
  if (RegExp(r'\b(?:kwh|price\s*/\s*kwh|price\s+per\s+kwh)\b').hasMatch(text)) {
    return 'kWh';
  }
  if (RegExp(
    r'\b(?:price\s*/\s*(?:kg|kilogram|kilograms)|'
    r'price\s+per\s+(?:kg|kilogram|kilograms)|ppkg)\b',
  ).hasMatch(text)) {
    return 'kg';
  }
  if (RegExp(
    r'\b(?:price\s*/\s*(?:gge|dge|gasoline\s+gallon\s+equivalent|diesel\s+gallon\s+equivalent)|'
    r'price\s+per\s+(?:gge|dge|gasoline\s+gallon\s+equivalent|diesel\s+gallon\s+equivalent)|ppge)\b',
  ).hasMatch(text)) {
    return RegExp(r'\b(?:dge|diesel\s+gallon\s+equivalent)\b').hasMatch(text)
        ? 'DGE'
        : 'GGE';
  }
  if (RegExp(
    r'\b(?:price\s*/\s*(?:liter|liters|litre|litres|l)|'
    r'price\s+per\s+(?:liter|liters|litre|litres|l)|ppl)\b',
  ).hasMatch(text)) {
    return 'liter';
  }
  if (RegExp(
    r'\b(?:price\s*/\s*(?:gal|gallon|g)|'
    r'price\s+per\s+(?:gal|gallon|g)|ppg)\b',
  ).hasMatch(text)) {
    return 'gallon';
  }
  return null;
}

String _normalizeFuelSignalText(String value) {
  return value
      .toLowerCase()
      .replaceAllMapped(RegExp(r'\b(\d{1,4}),(\d{2,4})\b'), (match) {
        return '${match.group(1)}.${match.group(2)}';
      })
      .replaceAll(RegExp(r'\bpr[1i!|]ce\b'), 'price')
      .replaceAll(RegExp(r'\bv[0o]l\b'), 'vol')
      .replaceAll(RegExp(r'\bqnty\b'), 'quantity')
      .replaceAll(RegExp(r'\bgal[oó]nes\b'), 'gallons')
      .replaceAll(RegExp(r'\bgal[0o]nes\b'), 'gallons')
      .replaceAll(RegExp(r'\bgal[oó]n\b'), 'gallon')
      .replaceAll(RegExp(r'\blitros\b'), 'liters')
      .replaceAll(RegExp(r'\blitro\b'), 'liter')
      .replaceAll(RegExp(r'\bventa\s+(?:de\s+)?c[0o]mbustible\b'), 'fuel sale')
      .replaceAll(RegExp(r'\bcombustible\b'), 'fuel')
      .replaceAll(RegExp(r'\bc[0o]mbustible\b'), 'fuel')
      .replaceAll(RegExp(r'\bgasolina\b'), 'gasoline')
      .replaceAll(RegExp(r'\betanol\b'), 'ethanol')
      .replaceAll(RegExp(r'\bdi[eé]sel\b'), 'diesel')
      .replaceAll(RegExp(r'\bd[1i][eé]sel\b'), 'diesel')
      .replaceAll(RegExp(r'\bpr[e3]c1[o0]\b'), 'price')
      .replaceAll(RegExp(r'\b(?:precio|price)\s+efectivo\b'), 'cash price')
      .replaceAll(RegExp(r'\b(?:precio|price)\s+cr[eé]dito\b'), 'credit price')
      .replaceAll(RegExp(r'\bqueroseno\b'), 'kerosene')
      .replaceAll(RegExp(r'\bgas\s+natural\s+comprimido\b'), 'cng')
      .replaceAll(RegExp(r'\benerg[ií]a\b'), 'energy')
      .replaceAll(RegExp(r'\bcarga\s+parcial\b'), 'partial')
      .replaceAll(RegExp(r'\bcarga\s+el[eé]ctrica\b'), 'charging')
      .replaceAll(RegExp(r'\bcarga\b'), 'charging')
      .replaceAll(RegExp(r'\blleno\b'), 'full')
      .replaceAll(RegExp(r'\bparcial\b'), 'partial')
      .replaceAll(RegExp(r'\btanque\b'), 'tank')
      .replaceAll(RegExp(r'\bel[eé]ctrico\b'), 'electric')
      .replaceAll(RegExp(r'\bel[eé]ctrica\b'), 'electric')
      .replaceAll(
        RegExp(r'\bprecio\s*/?\s*(?:gal[oó]n|gallon|gal)\b'),
        'price/gal',
      )
      .replaceAll(
        RegExp(r'\bprecio\s+por\s+(?:gal[oó]n|gallon|gal)\b'),
        'price per gal',
      )
      .replaceAll(
        RegExp(r'\bprecio\s*/?\s*(?:litro|liter|litre|l)\b'),
        'price/liter',
      )
      .replaceAll(
        RegExp(r'\bprecio\s+por\s+(?:litro|liter|litre|l)\b'),
        'price per liter',
      )
      .replaceAll(RegExp(r'\bprecio\s*/?\s*kwh\b'), 'price/kwh')
      .replaceAll(RegExp(r'\btarifa\s*/?\s*kwh\b'), 'price/kwh')
      .replaceAll(RegExp(r'\btarifa\b'), 'rate')
      .replaceAll(RegExp(r'\bventa\s+(?:de\s+)?combustible\b'), 'fuel sale')
      .replaceAll(RegExp(r'\bod[oó]metro\b'), 'odometer')
      .replaceAll(RegExp(r'\bgall[0o]ns\b'), 'gallons')
      .replaceAll(RegExp(r'\bga[1il|!]\b'), 'gal')
      .replaceAll(RegExp(r'\bgalns\b'), 'gallons')
      .replaceAll(RegExp(r'\bpp[6g]\b'), 'ppg')
      .replaceAll(RegExp(r'\bd[1i!|]esel\b'), 'diesel')
      .replaceAll(RegExp(r'\bunl(?:eaded)?\b'), 'unleaded')
      .replaceAll(RegExp(r'\bfue[1i!|]\b'), 'fuel');
}

String _fuelTypeForLine({
  required String lineText,
  required String receiptText,
}) {
  return _fuelTypeSignalFor(lineText) ??
      _receiptPrimaryFuelTypeSignalFor(receiptText) ??
      'Gasoline';
}

String? _fuelTypeSignalFor(String text) {
  if (RegExp(r'\b(def|diesel exhaust fluid)\b').hasMatch(text)) return 'DEF';
  if (RegExp(
    r'\b(lng|liquefied natural gas|dge|diesel gallon equivalent)\b',
  ).hasMatch(text)) {
    return 'LNG';
  }
  if (RegExp(
    r'\b(cng|compressed natural gas|natural gas fuel|gge|gasoline gallon equivalent)\b',
  ).hasMatch(text)) {
    return 'CNG';
  }
  if (RegExp(r'\b(rng|renewable natural gas)\b').hasMatch(text)) {
    return 'CNG';
  }
  if (RegExp(
    r'\b(propane|lpg|l\.?p\.?\s+gas|gas\s+l\.?p\.?|autogas|auto\s+gas|hd[-\s]?5)\b',
  ).hasMatch(text)) {
    return 'Propane';
  }
  if (RegExp(r'\b(methanol|m85|m100)\b').hasMatch(text)) {
    return 'Methanol';
  }
  if (RegExp(
    r'\b(hydrogen|h2 fuel|fuel cell|kg h2|h2|h35|h70)\b',
  ).hasMatch(text)) {
    return 'Hydrogen';
  }
  if (RegExp(
    r'\b(reefer|tractor diesel|truck diesel|on\s*road\s+diesel|highway\s+diesel|clear\s+diesel|ultra\s+low\s+sulfur\s+diesel|off\s*road diesel|off\s*road\s+diesel|dyed\s+diesel|red(?:\s+dyed?)?\s+diesel|farm\s+diesel|ag\s+diesel|renewable\s+diesel|rd20|rd99|r20|r99|hvo|hvo100|hydrotreated\s+vegetable\s+oil|hpr\s+diesel|hpr\s+fuel|biodiesel|diesel|dsl|d2|d1|ulsd|b(?:[1-9]|[1-9]\d|100))\b',
  ).hasMatch(text)) {
    return 'Diesel';
  }
  if (RegExp(
    r'\b(ev|kwh|electric|chargepoint|supercharger|charging|dcfc|dc\s+fast|evse|level\s*2|l2\s+charg(?:e|ing)|carga|el[eé]ctrica|el[eé]ctrico)\b',
  ).hasMatch(text)) {
    return 'Electric';
  }
  if (RegExp(r'\b(kerosene|kero|k[-\s]?1)\b').hasMatch(text)) {
    return 'Kerosene';
  }
  if (RegExp(
    r'\b(no ethanol|non ethanol|ethanol free|sin ethanol|sin etanol|rec fuel|recreational fuel|marine gas|marine fuel|e[-\s]*0)\b',
  ).hasMatch(text)) {
    return 'Gasoline';
  }
  final ethanolBlend = _ethanolBlendFuelTypeFor(text);
  if (ethanolBlend != null) return ethanolBlend;
  if (RegExp(r'\b(flex\s*fuel)\b').hasMatch(text)) return 'E85';
  if (RegExp(r'\bethanol\b').hasMatch(text)) return 'Ethanol';
  if (RegExp(
    r'\b(gasoline|gasohol|unleaded|regular|midgrade|premium)\b',
  ).hasMatch(text)) {
    return 'Gasoline';
  }
  return null;
}

String? _ethanolBlendFuelTypeFor(String text) {
  final compact = RegExp(r'\be[-\s]*(10|15|20|30|50|85)\b').firstMatch(text);
  if (compact != null) return 'E${compact.group(1)}';
  final labeled = RegExp(
    r'\bethanol\s*(?:blend|fuel)?\s*(10|15|20|30|50|85)\b',
  ).firstMatch(text);
  if (labeled != null) return 'E${labeled.group(1)}';
  if (RegExp(r'\b(unleaded 88|unl 88)\b').hasMatch(text)) return 'E15';
  return null;
}

String? _receiptPrimaryFuelTypeSignalFor(String text) {
  final withoutDefLongName = text.replaceAll(
    RegExp(r'\bdiesel\s+exhaust\s+fluid\b'),
    'def',
  );
  if (_dieselFuelTypeSignalPattern.hasMatch(withoutDefLongName)) {
    return 'Diesel';
  }
  return _fuelTypeSignalFor(text);
}

final _dieselFuelTypeSignalPattern = RegExp(
  r'\b(reefer|tractor diesel|truck diesel|on\s*road\s+diesel|'
  r'highway\s+diesel|clear\s+diesel|ultra\s+low\s+sulfur\s+diesel|off\s*road diesel|'
  r'off\s*road\s+diesel|dyed\s+diesel|red(?:\s+dyed?)?\s+diesel|'
  r'farm\s+diesel|ag\s+diesel|renewable\s+diesel|rd20|rd99|r20|r99|'
  r'hvo|hvo100|hydrotreated\s+vegetable\s+oil|hpr\s+diesel|hpr\s+fuel|'
  r'biodiesel|diesel|dsl|d2|d1|ulsd|'
  r'b(?:[1-9]|[1-9]\d|100))\b',
);

String _fuelFillTypeFor(String text) {
  if (RegExp(
    r'\b(partial|part fill|partial fill|partial fill-up|not full|'
    r'tank not full|no full|not filled|did not fill|no lleno|'
    r'tank no full|tanque no full)\b',
  ).hasMatch(text)) {
    return 'Partial fill';
  }
  return 'Full fill-up';
}

int? _fuelOdometerFor(String text) {
  final match = RegExp(
    r'\b(?:odometer|odo|hubometer|hub\s*miles|mileage|miles|od[oó]metro)\s*[:#]?\s*(\d{3,8})\b',
  ).firstMatch(text);
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

String _fallbackFuelDescriptionFor({
  required List<String> receiptRows,
  required _FuelLineDetails details,
}) {
  final productLabel = _fuelProductLabelFor(receiptRows);
  if (productLabel != null) return '$productLabel Fuel';
  return '${details.fuelType} Fuel';
}

String? _fuelProductLabelFor(List<String> receiptRows) {
  for (final row in receiptRows) {
    final raw = row.trim();
    if (raw.isEmpty) continue;
    final normalized = _normalizeFuelSignalText(raw);
    if (!_hasFuelProductSignal(normalized)) continue;
    if (_hasFuelMeasurementSignal(normalized)) continue;
    final cleaned = raw
        .replaceFirst(
          RegExp(r'^\s*(product|fuel\s*type|grade)\s+', caseSensitive: false),
          '',
        )
        .trim();
    if (cleaned.length < 2) continue;
    return cleaned;
  }
  return null;
}

bool _hasFuelProductSignal(String text) {
  return RegExp(
    r'\b(prod|product|grade|reg\s+unleaded|reg\s+unl|regular|unleaded|unl|premium|midgrade|diesel|dsl|d2|d1|ulsd|def|e85|ethanol|kerosene|kero|k[-\s]?1|propane|lpg|l\.?p\.?\s+gas|gas\s+l\.?p\.?)\b',
  ).hasMatch(text);
}

bool _hasFuelMeasurementSignal(String text) {
  return RegExp(
    r'\b(pump|nozzle|hose|fueling point|fueling position|gals?|gallons?|volume|vol|qty|quantity|amt|ppg|ppu|ppl|price|fuel sale|fuel amount|fuel amt|total|card|visa|driver|odometer|odo)\b',
  ).hasMatch(text);
}
