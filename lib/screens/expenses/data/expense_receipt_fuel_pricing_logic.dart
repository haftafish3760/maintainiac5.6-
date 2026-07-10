part of 'expense_receipt_parser.dart';

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
      text:
          '$text \${fallbackText ?? '
          '}',
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
    r'(?:cash\s+price\s*/\s*(?:gal|gallon|g|liter|liters|litre|litres|l|kwh|gge|dge|kg)|credit\s+price\s*/\s*(?:gal|gallon|g|liter|liters|litre|litres|l|kwh|gge|dge|kg)|precio\s+efectivo|precio\s+credito|precio\s+por\s+(?:gal[oó]n|gallon|gal|litro|liter|litre|l)|price\s*/\s*(?:gal|gallon|g|liter|liters|litre|litres|l|kwh|gge|dge|kg)|\$\s*/\s*(?:gal|gallon|g|liter|liters|litre|litres|l|kwh|gge|dge|kg)|price\s*per\s*(?:gal|gallon|g|liter|liters|litre|litres|l|kwh|gge|dge|kg)|unit\s*price|fuel\s*price|price|rate|unit\s*cost|ppu|ppg|ppl|ppge|ppkg|@\s*)\s*\$?(\d+(?:\.\d{2,4})?)',
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
