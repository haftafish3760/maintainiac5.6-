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
      _fuelQuantityFor(
        rawText,
        amount: amount,
        fallbackText: receiptText,
      );
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
      .replaceAll(RegExp(r'\bgal[oó]n\b'), 'gallon')
      .replaceAll(RegExp(r'\blitros\b'), 'liters')
      .replaceAll(RegExp(r'\blitro\b'), 'liter')
      .replaceAll(RegExp(r'\bcombustible\b'), 'fuel')
      .replaceAll(RegExp(r'\bgasolina\b'), 'gasoline')
      .replaceAll(RegExp(r'\betanol\b'), 'ethanol')
      .replaceAll(RegExp(r'\bdi[eé]sel\b'), 'diesel')
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

_ParsedQuantity _fuelQuantityFor(
  String text, {
  required double amount,
  String? fallbackText,
}) {
  final direct = _fuelQuantityIn(text, amount: amount, allowLooseDecimal: true);
  if (direct != null) return direct;
  if (fallbackText != null && fallbackText.trim().isNotEmpty) {
    final fallback = _fuelQuantityIn(
      fallbackText,
      amount: amount,
      allowLooseDecimal: false,
    );
    if (fallback != null) return fallback;
  }
  return const _ParsedQuantity(quantity: 1, unitsPerPackage: 1, unit: 'gallon');
}

_ParsedQuantity? _fuelExplicitLabeledQuantityIn(String text) {
  final match = RegExp(
    r'\b(gallons|gal[oó]nes|volume|vol|qty|qnty|quantity|fuel\s+qty|fuel\s+volume)\s*[:#]?\s*(\d+(?:\.\d+)?)\b',
  ).firstMatch(text);
  if (match == null || _fuelVolumeLabelIsPriceContext(text, match)) return null;
  final quantity = double.tryParse(match.group(2)!);
  if (quantity == null || quantity <= 0) return null;
  return _ParsedQuantity(
    quantity: quantity,
    unitsPerPackage: 1,
    unit: 'gallon',
  );
}

_ParsedQuantity? _fuelQuantityIn(
  String text, {
  required double amount,
  required bool allowLooseDecimal,
}) {
  final gallonAfterNumber =
      RegExp(
        r'(\d+(?:\.\d+)?)\s*(?:gal|gals|gallon|gallons|gal[oó]n|gal[oó]nes|gl|g)\b',
      ).allMatches(text).where((match) {
        return !_fuelLooseQuantityCandidateIsPriceContext(text, match) &&
            !_fuelQuantityCandidateIsDispenserContext(text, match) &&
            !_fuelLooseDecimalCandidateIsRenewableDieselGradeContext(
              text,
              match,
            ) &&
            !_fuelQuantityCandidateIsDieselNumberGradeContext(text, match) &&
            !_fuelQuantityCandidateIsBiodieselBlendGradeContext(text, match) &&
            !_fuelQuantityCandidateIsEthanolBlendGradeContext(text, match) &&
            !_fuelQuantityCandidateIsProductGradeContext(text, match);
      }).firstOrNull;
  if (gallonAfterNumber != null) {
    return _ParsedQuantity(
      quantity: double.parse(gallonAfterNumber.group(1)!),
      unitsPerPackage: 1,
      unit: 'gallon',
    );
  }

  final gallonBeforeNumber =
      RegExp(
        r'\b(gal|gals|gallon|gallons|gal[oó]n|gal[oó]nes|gl|volume|vol|qty|qnty|quantity|fuel\s+qty|fuel\s+volume)\s*[:#]?\s*(\d+(?:\.\d+)?)\b',
      ).allMatches(text).where((match) {
        final label = match.group(1) ?? '';
        if (label == 'gal' || label == 'gallon' || label == 'gl') {
          return !_fuelVolumeLabelIsPriceContext(text, match);
        }
        return true;
      }).firstOrNull;
  if (gallonBeforeNumber != null) {
    return _ParsedQuantity(
      quantity: double.parse(gallonBeforeNumber.group(2)!),
      unitsPerPackage: 1,
      unit: 'gallon',
    );
  }

  final kwhAfterNumber = RegExp(r'(\d+(?:\.\d+)?)\s*kwh\b').firstMatch(text);
  if (kwhAfterNumber != null) {
    return _ParsedQuantity(
      quantity: double.parse(kwhAfterNumber.group(1)!),
      unitsPerPackage: 1,
      unit: 'kWh',
    );
  }

  final kwhBeforeNumber = RegExp(
    r'\bkwh\s*[:#]?\s*(\d+(?:\.\d+)?)\b',
  ).firstMatch(text);
  if (kwhBeforeNumber != null &&
      !_fuelVolumeLabelIsPriceContext(text, kwhBeforeNumber)) {
    return _ParsedQuantity(
      quantity: double.parse(kwhBeforeNumber.group(1)!),
      unitsPerPackage: 1,
      unit: 'kWh',
    );
  }

  final gallonEquivalentAfterNumber = RegExp(
    r'(\d+(?:\.\d+)?)\s*(gge|dge|gasoline\s+gallon\s+equivalent|diesel\s+gallon\s+equivalent)\b',
  ).firstMatch(text);
  if (gallonEquivalentAfterNumber != null) {
    return _ParsedQuantity(
      quantity: double.parse(gallonEquivalentAfterNumber.group(1)!),
      unitsPerPackage: 1,
      unit: _gallonEquivalentUnitFor(gallonEquivalentAfterNumber.group(2)!),
    );
  }

  final gallonEquivalentBeforeNumber = RegExp(
    r'\b(gge|dge|gasoline\s+gallon\s+equivalent|diesel\s+gallon\s+equivalent)\s*[:#]?\s*(\d+(?:\.\d+)?)\b',
  ).firstMatch(text);
  if (gallonEquivalentBeforeNumber != null &&
      !_fuelVolumeLabelIsPriceContext(text, gallonEquivalentBeforeNumber)) {
    return _ParsedQuantity(
      quantity: double.parse(gallonEquivalentBeforeNumber.group(2)!),
      unitsPerPackage: 1,
      unit: _gallonEquivalentUnitFor(gallonEquivalentBeforeNumber.group(1)!),
    );
  }

  final kilogramAfterNumber =
      RegExp(
        r'(\d+(?:\.\d+)?)\s*(?:kg|kilogram|kilograms)\b',
      ).allMatches(text).where((match) {
        return !_fuelQuantityCandidateIsHydrogenFormulaContext(text, match);
      }).firstOrNull;
  if (kilogramAfterNumber != null) {
    return _ParsedQuantity(
      quantity: double.parse(kilogramAfterNumber.group(1)!),
      unitsPerPackage: 1,
      unit: 'kg',
    );
  }

  final kilogramBeforeNumber = RegExp(
    r'\b(?:kg|kilogram|kilograms)\s*[:#]?\s*(\d+(?:\.\d+)?)\b',
  ).firstMatch(text);
  if (kilogramBeforeNumber != null &&
      !_fuelVolumeLabelIsPriceContext(text, kilogramBeforeNumber)) {
    return _ParsedQuantity(
      quantity: double.parse(kilogramBeforeNumber.group(1)!),
      unitsPerPackage: 1,
      unit: 'kg',
    );
  }

  final literBeforeNumber = RegExp(
    r'\b(liter|liters|litre|litres|litro|litros)\s*[:#]?\s*(\d+(?:\.\d+)?)\b',
  ).firstMatch(text);
  if (literBeforeNumber != null) {
    return _ParsedQuantity(
      quantity: double.parse(literBeforeNumber.group(2)!),
      unitsPerPackage: 1,
      unit: 'liter',
    );
  }

  final literAfterNumber =
      RegExp(
        r'(\d+(?:\.\d+)?)\s*(?:l|liter|liters|litre|litres|litro|litros)\b',
      ).allMatches(text).where((match) {
        return !_fuelQuantityCandidateIsProductGradeContext(text, match) &&
            !_fuelQuantityCandidateIsLpGasContext(text, match);
      }).firstOrNull;
  if (literAfterNumber != null) {
    return _ParsedQuantity(
      quantity: double.parse(literAfterNumber.group(1)!),
      unitsPerPackage: 1,
      unit: 'liter',
    );
  }

  final productQuantityBeforeAtPrice = RegExp(
    r'\b(?:reg\s+unleaded|reg\s+unl|regular|unleaded|premium|midgrade|diesel|dsl|d1|d2|ulsd|ultra\s+low\s+sulfur\s+diesel|clear\s+diesel|highway\s+diesel|on\s*road\s+diesel|b5|b10|b20|b99|b100|biodiesel|off\s*road\s+diesel|dyed\s+diesel|red\s+dyed?\s+diesel|farm\s+diesel|ag\s+diesel|renewable\s+diesel|rd20|rd99|r20|r99|hvo|hvo100|hydrotreated\s+vegetable\s+oil|hpr\s+diesel|hpr\s+fuel|def|diesel\s+exhaust\s+fluid|kerosene|kero|k[-\s]?1|propane|lpg|l\.?p\.?\s+gas|gas\s+l\.?p\.?|autogas|auto\s+gas|e[-\s]*(?:85|50|30|20|15|10)|ethanol\s+(?:10|15|20|30|50|85)|flex\s*fuel)\b.*?\b(\d{1,3}\.\d{2,4})\s*@\s*\d',
  ).firstMatch(text);
  if (productQuantityBeforeAtPrice != null) {
    return _ParsedQuantity(
      quantity: double.parse(productQuantityBeforeAtPrice.group(1)!),
      unitsPerPackage: 1,
      unit: 'gallon',
    );
  }

  if (!allowLooseDecimal) return null;
  final decimalCandidates = RegExp(r'\b(\d{1,3}\.\d{1,4})\b').allMatches(text);
  for (final match in decimalCandidates) {
    if (_fuelLooseQuantityCandidateIsPriceContext(text, match)) continue;
    final candidate = double.parse(match.group(1)!);
    final isAmount = (candidate - amount).abs() < .01;
    final looksLikeUnitPrice = candidate > 1 && candidate < 10;
    if (!isAmount &&
        !looksLikeUnitPrice &&
        !_fuelLooseDecimalCandidateIsRenewableDieselGradeContext(text, match) &&
        !_fuelQuantityCandidateIsDieselNumberGradeContext(text, match) &&
        !_fuelQuantityCandidateIsBiodieselBlendGradeContext(text, match) &&
        !_fuelQuantityCandidateIsEthanolBlendGradeContext(text, match) &&
        candidate > 0 &&
        candidate < 300) {
      return _ParsedQuantity(
        quantity: candidate,
        unitsPerPackage: 1,
        unit: 'gallon',
      );
    }
  }

  return null;
}

bool _fuelLooseDecimalCandidateIsRenewableDieselGradeContext(
  String text,
  RegExpMatch match,
) {
  final before = text.substring(0, match.start);
  final after = text.substring(match.end);
  final nearbyBefore = before.substring(
    before.length > 8 ? before.length - 8 : 0,
  );
  final nearbyAfter = after.substring(0, after.length > 24 ? 24 : after.length);
  return RegExp(r'(?:\brd?|\bhpr|\bhvo)\s*$').hasMatch(nearbyBefore) ||
      RegExp(r'^\s*(?:renewable\s+)?diesel\b').hasMatch(nearbyAfter);
}

bool _fuelQuantityCandidateIsEthanolBlendGradeContext(
  String text,
  RegExpMatch match,
) {
  final candidate = double.tryParse(match.group(1) ?? '');
  if (candidate == null || candidate % 1 != 0) return false;
  const blendValues = {10, 15, 20, 30, 50, 85};
  if (!blendValues.contains(candidate.toInt())) return false;
  final before = text.substring(0, match.start);
  final after = text.substring(match.end);
  final nearbyBefore = before.substring(
    before.length > 18 ? before.length - 18 : 0,
  );
  final nearbyAfter = after.substring(0, after.length > 18 ? 18 : after.length);
  return RegExp(r'\b(?:ethanol|etanol|e)\s*$').hasMatch(nearbyBefore) ||
      RegExp(r'^\s*(?:ethanol|etanol|flex\s+fuel)\b').hasMatch(nearbyAfter);
}

bool _fuelQuantityCandidateIsBiodieselBlendGradeContext(
  String text,
  RegExpMatch match,
) {
  final candidate = double.tryParse(match.group(1) ?? '');
  if (candidate == null || candidate % 1 != 0) return false;
  const blendValues = {5, 10, 20, 99, 100};
  if (!blendValues.contains(candidate.toInt())) return false;
  final before = text.substring(0, match.start);
  final after = text.substring(match.end);
  final nearbyBefore = before.substring(
    before.length > 14 ? before.length - 14 : 0,
  );
  final nearbyAfter = after.substring(0, after.length > 24 ? 24 : after.length);
  return RegExp(r'\b(?:b|bio\s?diesel|biodiesel)\s*$').hasMatch(nearbyBefore) ||
      RegExp(r'^\s*(?:bio\s?diesel|biodiesel|diesel)\b').hasMatch(nearbyAfter);
}

bool _fuelQuantityCandidateIsDieselNumberGradeContext(
  String text,
  RegExpMatch match,
) {
  final candidate = double.tryParse(match.group(1) ?? '');
  if (candidate == null || candidate % 1 != 0) return false;
  if (!{1, 2}.contains(candidate.toInt())) return false;
  final before = text.substring(0, match.start);
  final nearbyBefore = before.substring(
    before.length > 28 ? before.length - 28 : 0,
  );
  return RegExp(
    r'\b(?:no\.?|number|diesel\s+no\.?)\s*$',
  ).hasMatch(nearbyBefore);
}

String _gallonEquivalentUnitFor(String text) {
  return RegExp(r'\b(?:dge|diesel\s+gallon\s+equivalent)\b').hasMatch(text)
      ? 'DGE'
      : 'GGE';
}

bool _fuelVolumeLabelIsPriceContext(String text, RegExpMatch match) {
  final before = text.substring(0, match.start);
  final nearbyBefore = before.substring(
    before.length > 18 ? before.length - 18 : 0,
  );
  return RegExp(r'(price\s*/?\s*|price\s*per\s*)$').hasMatch(nearbyBefore);
}

bool _fuelLooseQuantityCandidateIsPriceContext(String text, RegExpMatch match) {
  final before = text.substring(0, match.start);
  final after = text.substring(match.end);
  final nearbyBefore = before.substring(
    before.length > 24 ? before.length - 24 : 0,
  );
  final nearbyAfter = after.substring(0, after.length > 16 ? 16 : after.length);
  return RegExp(
        r'(price\s*/?\s*(?:gal|gallon|g|kwh|gge|dge|kg)?|price\s*per|unit\s*price|fuel\s*price|rate|ppu|ppg|ppl|ppge|ppkg|@)\s*$',
      ).hasMatch(nearbyBefore) ||
      RegExp(
        r'^\s*/\s*(?:gal|gallon|g|kwh|gge|dge|kg)\b',
      ).hasMatch(nearbyAfter);
}

bool _fuelQuantityCandidateIsProductGradeContext(
  String text,
  RegExpMatch match,
) {
  final candidate = double.tryParse(match.group(1) ?? '');
  if (candidate == null || candidate % 1 != 0) return false;
  const productGradeValues = {10, 15, 85, 87, 88, 89, 91, 93};
  if (!productGradeValues.contains(candidate.toInt())) return false;
  final before = text.substring(0, match.start);
  final nearbyBefore = before.substring(
    before.length > 28 ? before.length - 28 : 0,
  );
  return RegExp(
    r'\b(product|regular|reg|unleaded|unl|premium|midgrade|ethanol|e10|e15|octane|grade)\s*$',
  ).hasMatch(nearbyBefore);
}

bool _fuelQuantityCandidateIsLpGasContext(String text, RegExpMatch match) {
  final after = text.substring(match.end);
  final nearbyAfter = after.substring(0, after.length > 16 ? 16 : after.length);
  return RegExp(r'^\s*\.?\s*p\.?\s*gas\b').hasMatch(nearbyAfter);
}

bool _fuelQuantityCandidateIsDispenserContext(String text, RegExpMatch match) {
  final before = text.substring(0, match.start);
  final nearbyBefore = before.substring(
    before.length > 28 ? before.length - 28 : 0,
  );
  return RegExp(
    r'\b(pump|nozzle|hose|fueling\s+point|disp(?:enser)?)\s*[:#]?\s*$',
  ).hasMatch(nearbyBefore);
}

bool _fuelQuantityCandidateIsHydrogenFormulaContext(
  String text,
  RegExpMatch match,
) {
  final before = text.substring(0, match.start);
  return before.endsWith('h');
}

double? _fuelUnitPriceFor({
  required String text,
  required _ParsedQuantity quantity,
  required double amount,
  required String fuelType,
  String? fallbackText,
}) {
  final direct = _fuelUnitPriceIn(text, quantity: quantity, amount: amount);
  if (direct != null) {
    final directEffective = _effectiveFuelUnitPriceFor(
      text: '$text ${fallbackText ?? ''}',
      unitPrice: direct,
      quantity: quantity,
      amount: amount,
    );
    if (fallbackText != null && fallbackText.trim().isNotEmpty) {
      final fallback = _fuelUnitPriceIn(
        fallbackText,
        quantity: quantity,
        amount: amount,
      );
      if (fallback != null) {
        final fallbackEffective = _effectiveFuelUnitPriceFor(
          text: fallbackText,
          unitPrice: fallback,
          quantity: quantity,
          amount: amount,
        );
        final directDifference =
            ((directEffective * quantity.quantity) - amount).abs();
        final fallbackDifference =
            ((fallbackEffective * quantity.quantity) - amount).abs();
        if (fallbackDifference < directDifference) return fallbackEffective;
      }
    }
    return directEffective;
  }
  final lineQuantity = _fuelQuantityIn(
    text,
    amount: amount,
    allowLooseDecimal: false,
  );
  if (lineQuantity != null &&
      lineQuantity.quantity > 1 &&
      _shouldPreferLineComputedUnitPrice(fuelType)) {
    return amount / lineQuantity.quantity;
  }
  if (fallbackText != null && fallbackText.trim().isNotEmpty) {
    final fallback = _fuelUnitPriceIn(
      fallbackText,
      quantity: quantity,
      amount: amount,
    );
    if (fallback != null) {
      return _effectiveFuelUnitPriceFor(
        text: fallbackText,
        unitPrice: fallback,
        quantity: quantity,
        amount: amount,
      );
    }
  }
  if (quantity.quantity > 1) return amount / quantity.quantity;
  return null;
}

bool _shouldPreferLineComputedUnitPrice(String fuelType) {
  return fuelType == 'DEF';
}

double _effectiveFuelUnitPriceFor({
  required String text,
  required double unitPrice,
  required _ParsedQuantity quantity,
  required double amount,
}) {
  final perUnitDiscount = _fuelPerUnitDiscountIn(text);
  if (perUnitDiscount == null || quantity.quantity <= 0) return unitPrice;
  final discounted = unitPrice + perUnitDiscount;
  if (discounted <= 0) return unitPrice;
  final expected = discounted * quantity.quantity;
  var tolerance = amount.abs() * .02;
  if (tolerance < .05) tolerance = .05;
  return (expected - amount).abs() <= tolerance ? discounted : unitPrice;
}

double? _fuelPerUnitDiscountIn(String text) {
  final match = RegExp(
    r'\b(?:disc(?:ount)?|descuento|fuel\s+rewards?|rewards?|loyalty|'
    r'member\s+savings?|club\s+savings?|shopper|fuel\s+points?|points\s+reward)\s*/?'
    r'\s*(?:gal|gallon|g|liter|liters|litre|litres|l|kwh)?\s*(-?\d+(?:\.\d{2,4})?)'
    r'\s*(?:/|per)?\s*(?:gal|gallon|g|liter|liters|litre|litres|l|kwh)?\b',
  ).firstMatch(text);
  if (match == null) return null;
  final value = double.tryParse(match.group(1)!);
  if (value == null || value == 0) return null;
  return value > 0 ? -value : value;
}

double? _fuelUnitPriceIn(
  String text, {
  required _ParsedQuantity quantity,
  required double amount,
}) {
  final prices = <double>[];
  final labeledPrice = RegExp(
    r'(?:cash\s+price\s*/\s*(?:gal|gallon|g|liter|liters|litre|litres|l|kwh|gge|dge|kg)|credit\s+price\s*/\s*(?:gal|gallon|g|liter|liters|litre|litres|l|kwh|gge|dge|kg)|precio\s+efectivo|precio\s+credito|price\s*/\s*(?:gal|gallon|g|liter|liters|litre|litres|l|kwh|gge|dge|kg)|\$\s*/\s*(?:gal|gallon|g|liter|liters|litre|litres|l|kwh|gge|dge|kg)|price\s*per\s*(?:gal|gallon|g|liter|liters|litre|litres|l|kwh|gge|dge|kg)|unit\s*price|fuel\s*price|price|rate|unit\s*cost|ppu|ppg|ppl|ppge|ppkg|@\s*)\s*\$?(\d+(?:\.\d{2,4})?)',
  );
  for (final match in labeledPrice.allMatches(text)) {
    final value = double.tryParse(match.group(1)!);
    if (value != null) prices.add(value);
  }

  final slashPrice = RegExp(
    r'\$?(\d+\.\d{3,4})\s*/\s*(?:gal|gallon|g|liter|liters|litre|litres|l|kwh|gge|dge|kg)\b',
  );
  for (final match in slashPrice.allMatches(text)) {
    if (_fuelSlashPriceCandidateIsAdjustment(text, match)) continue;
    final value = double.tryParse(match.group(1)!);
    if (value != null) prices.add(value);
  }
  if (prices.isEmpty) return null;
  return _fuelUnitPriceClosestToAmount(
    prices,
    quantity: quantity,
    amount: amount,
  );
}

bool _fuelSlashPriceCandidateIsAdjustment(String text, RegExpMatch match) {
  final before = text.substring(0, match.start).trimRight();
  return before.endsWith('-') ||
      RegExp(
        r'\b(?:disc(?:ount)?|descuento|fuel\s+rewards?|rewards?|loyalty|member\s+savings?)\s*$',
      ).hasMatch(before) ||
      RegExp(
        r'\b(?:gal|gals|gallon|gallons|gal[oó]n|gal[oó]nes|volume|vol|qty|qnty|quantity)\s*$',
      ).hasMatch(before);
}

double _fuelUnitPriceClosestToAmount(
  List<double> prices, {
  required _ParsedQuantity quantity,
  required double amount,
}) {
  if (prices.length == 1 || quantity.quantity <= 0) return prices.first;
  var best = prices.first;
  var bestDifference = ((best * quantity.quantity) - amount).abs();
  for (final price in prices.skip(1)) {
    final difference = ((price * quantity.quantity) - amount).abs();
    if (difference < bestDifference) {
      best = price;
      bestDifference = difference;
    }
  }
  return best;
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
    r'\b(propane|lpg|l\.?p\.?\s+gas|gas\s+l\.?p\.?|autogas|auto\s+gas)\b',
  ).hasMatch(text)) {
    return 'Propane';
  }
  if (RegExp(r'\b(hydrogen|h2 fuel|fuel cell|kg h2|h2)\b').hasMatch(text)) {
    return 'Hydrogen';
  }
  if (RegExp(
    r'\b(reefer|tractor diesel|truck diesel|on\s*road\s+diesel|highway\s+diesel|clear\s+diesel|ultra\s+low\s+sulfur\s+diesel|off\s*road diesel|off\s*road\s+diesel|dyed\s+diesel|red\s+dyed?\s+diesel|farm\s+diesel|ag\s+diesel|renewable\s+diesel|rd20|rd99|r20|r99|hvo|hvo100|hydrotreated\s+vegetable\s+oil|hpr\s+diesel|hpr\s+fuel|biodiesel|diesel|dsl|d2|d1|ulsd|b100|b99|b20|b10|b5)\b',
  ).hasMatch(text)) {
    return 'Diesel';
  }
  if (RegExp(
    r'\b(ev|kwh|electric|chargepoint|supercharger|charging|carga|el[eé]ctrica|el[eé]ctrico)\b',
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
  r'off\s*road\s+diesel|dyed\s+diesel|red\s+dyed?\s+diesel|'
  r'farm\s+diesel|ag\s+diesel|renewable\s+diesel|rd20|rd99|r20|r99|'
  r'hvo|hvo100|hydrotreated\s+vegetable\s+oil|hpr\s+diesel|hpr\s+fuel|'
  r'biodiesel|diesel|dsl|d2|d1|ulsd|'
  r'b100|b99|b20|b10|b5)\b',
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
