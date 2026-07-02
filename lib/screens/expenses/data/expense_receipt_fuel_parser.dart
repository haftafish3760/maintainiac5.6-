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
  final combinedText = '$rawText $descriptionText $receiptText';
  final quantity = _fuelQuantityFor(
    rawText,
    amount: amount,
    fallbackText: receiptText,
  );
  final unitPrice = _fuelUnitPriceFor(
    text: '$rawText $descriptionText',
    quantity: quantity,
    amount: amount,
    fallbackText: receiptText,
  );
  return _FuelLineDetails(
    quantity: quantity,
    fuelType: _fuelTypeFor(combinedText),
    fillType: _fuelFillTypeFor(combinedText),
    unitPrice: unitPrice,
    odometerReading: _fuelOdometerFor(combinedText),
  );
}

String _normalizeFuelSignalText(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'\bpr[1i!|]ce\b'), 'price')
      .replaceAll(RegExp(r'\bv[0o]l\b'), 'vol')
      .replaceAll(RegExp(r'\bqnty\b'), 'quantity')
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

_ParsedQuantity? _fuelQuantityIn(
  String text, {
  required double amount,
  required bool allowLooseDecimal,
}) {
  final gallonAfterNumber =
      RegExp(
        r'(\d+(?:\.\d+)?)\s*(?:gal|gals|gallon|gallons|gl|g)\b',
      ).allMatches(text).where((match) {
        return !_fuelLooseQuantityCandidateIsPriceContext(text, match);
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
        r'\b(gal|gals|gallon|gallons|gl|volume|vol|qty|qnty|quantity|fuel\s+qty|fuel\s+volume)\s*[:#]?\s*(\d+(?:\.\d+)?)\b',
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
  if (kwhBeforeNumber != null) {
    return _ParsedQuantity(
      quantity: double.parse(kwhBeforeNumber.group(1)!),
      unitsPerPackage: 1,
      unit: 'kWh',
    );
  }

  final literAfterNumber = RegExp(
    r'(\d+(?:\.\d+)?)\s*(?:l|liter|liters|litre|litres)\b',
  ).firstMatch(text);
  if (literAfterNumber != null) {
    return _ParsedQuantity(
      quantity: double.parse(literAfterNumber.group(1)!),
      unitsPerPackage: 1,
      unit: 'liter',
    );
  }

  if (!allowLooseDecimal) return null;
  final decimalCandidates = RegExp(r'\b(\d{1,3}\.\d{1,4})\b').allMatches(text);
  for (final match in decimalCandidates) {
    if (_fuelLooseQuantityCandidateIsPriceContext(text, match)) continue;
    final candidate = double.parse(match.group(1)!);
    final isAmount = (candidate - amount).abs() < .01;
    final looksLikeUnitPrice = candidate > 1 && candidate < 10;
    if (!isAmount && !looksLikeUnitPrice && candidate > 0 && candidate < 300) {
      return _ParsedQuantity(
        quantity: candidate,
        unitsPerPackage: 1,
        unit: 'gallon',
      );
    }
  }

  return null;
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
        r'(price\s*/?\s*(?:gal|gallon|g)?|price\s*per|unit\s*price|fuel\s*price|rate|ppu|ppg|ppl|@\s*)$',
      ).hasMatch(nearbyBefore) ||
      RegExp(r'^\s*/\s*(?:gal|gallon|g|kwh)\b').hasMatch(nearbyAfter);
}

double? _fuelUnitPriceFor({
  required String text,
  required _ParsedQuantity quantity,
  required double amount,
  String? fallbackText,
}) {
  final direct = _fuelUnitPriceIn(text);
  if (direct != null) return direct;
  if (fallbackText != null && fallbackText.trim().isNotEmpty) {
    final fallback = _fuelUnitPriceIn(fallbackText);
    if (fallback != null) return fallback;
  }
  if (quantity.quantity > 1) return amount / quantity.quantity;
  return null;
}

double? _fuelUnitPriceIn(String text) {
  final labeledPrice = RegExp(
    r'(?:price\s*/\s*(?:gal|gallon|g|kwh)|\$\s*/\s*(?:gal|gallon|g|kwh)|price\s*per\s*(?:gal|gallon|g|kwh)|unit\s*price|fuel\s*price|price|rate|ppu|ppg|ppl|@\s*)\s*\$?(\d+(?:\.\d{2,4})?)',
  ).firstMatch(text);
  if (labeledPrice != null) return double.tryParse(labeledPrice.group(1)!);

  final slashPrice = RegExp(
    r'\$?(\d+\.\d{3,4})\s*/\s*(?:gal|gallon|g|kwh)\b',
  ).firstMatch(text);
  if (slashPrice != null) return double.tryParse(slashPrice.group(1)!);

  return null;
}

String _fuelTypeFor(String text) {
  if (RegExp(r'\b(def|diesel exhaust fluid)\b').hasMatch(text)) return 'DEF';
  if (RegExp(
    r'\b(reefer|tractor diesel|truck diesel|diesel|dsl|ulsd|b20|b10)\b',
  ).hasMatch(text)) {
    return 'Diesel';
  }
  if (RegExp(
    r'\b(ev|kwh|electric|chargepoint|supercharger|charging)\b',
  ).hasMatch(text)) {
    return 'Electric';
  }
  if (RegExp(r'\b(kerosene|kero)\b').hasMatch(text)) return 'Kerosene';
  if (RegExp(r'\b(e85|flex fuel|ethanol)\b').hasMatch(text)) return 'E85';
  return 'Gasoline';
}

String _fuelFillTypeFor(String text) {
  if (RegExp(r'\b(partial|part fill|partial fill|not full)\b').hasMatch(text)) {
    return 'Partial fill';
  }
  return 'Full fill-up';
}

int? _fuelOdometerFor(String text) {
  final match = RegExp(
    r'\b(?:odometer|odo|mileage|miles)\s*[:#]?\s*(\d{3,8})\b',
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
    r'\b(reg\s+unleaded|reg\s+unl|regular|unleaded|premium|midgrade|diesel|dsl|ulsd|def|e85|ethanol|kerosene|kero)\b',
  ).hasMatch(text);
}

bool _hasFuelMeasurementSignal(String text) {
  return RegExp(
    r'\b(pump|gals?|gallons?|volume|vol|qty|quantity|ppg|ppu|ppl|price|fuel sale|fuel amount|fuel amt|total|card|visa|driver|odometer|odo)\b',
  ).hasMatch(text);
}
