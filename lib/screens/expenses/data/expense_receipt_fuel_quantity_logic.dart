part of 'expense_receipt_parser.dart';

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
  return const _ParsedQuantity(quantity: 1, unitsPerPackage: 1, unit: 'each');
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
            !_fuelQuantityCandidateIsMethanolBlendGradeContext(text, match) &&
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
    r'\b(?:reg\s+unleaded|reg\s+unl|regular|unleaded|premium|midgrade|diesel|dsl|d1|d2|ulsd|ultra\s+low\s+sulfur\s+diesel|clear\s+diesel|highway\s+diesel|on\s*road\s+diesel|b(?:[1-9]|[1-9]\d|100)|biodiesel|off\s*road\s+diesel|dyed\s+diesel|red(?:\s+dyed?)?\s+diesel|farm\s+diesel|ag\s+diesel|renewable\s+diesel|rd20|rd99|r20|r99|hvo|hvo100|hydrotreated\s+vegetable\s+oil|hpr\s+diesel|hpr\s+fuel|def|diesel\s+exhaust\s+fluid|kerosene|kero|k[-\s]?1|propane|lpg|l\.?p\.?\s+gas|gas\s+l\.?p\.?|autogas|auto\s+gas|hd[-\s]?5|methanol|m85|m100|hydrogen|h2|h35|h70|e[-\s]*(?:85|50|30|20|15|10)|ethanol\s+(?:10|15|20|30|50|85)|flex\s+fuel)\b.*?\b(\d{1,3}\.\d{2,4})\s*@\s*\d',
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

bool _fuelQuantityCandidateIsMethanolBlendGradeContext(
  String text,
  RegExpMatch match,
) {
  final candidate = double.tryParse(match.group(1) ?? '');
  if (candidate == null || candidate % 1 != 0) return false;
  if (candidate != 85 && candidate != 100) return false;
  final before = text.substring(0, match.start);
  return RegExp(r'\bm\s*$').hasMatch(before);
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
  const productGradeValues = {10, 15, 85, 87, 88, 89, 91, 93, 100, 110};
  if (!productGradeValues.contains(candidate.toInt())) return false;
  final before = text.substring(0, match.start);
  final nearbyBefore = before.substring(
    before.length > 28 ? before.length - 28 : 0,
  );
  return RegExp(
    r'\b(product|regular|reg|unleaded|unl|premium|midgrade|super|supreme|suprema|ethanol|e10|e15|octane|grade|race fuel|racing fuel|avgas|jet fuel|nitromethane)\s*$',
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
