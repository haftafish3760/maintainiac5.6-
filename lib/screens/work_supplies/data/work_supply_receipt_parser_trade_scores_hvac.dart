part of 'work_supply_receipt_parser.dart';

int _hvacReceiptScore(String text, String trade, WorkSupplyItem item) {
  var score = 0;
  if (trade != 'hvac') return score;
  if (text.contains('retaining wall')) {
    score -= 40;
  }
  if (RegExp(
    r'\b(capacitor|mfd|uf|run cap|pleated|filter|furnace filter|ac filter|filter rack|return grille|foil tape|hvac tape|mastic|duct|condensate|drain pan|'
    r'thermostat|contactor|line set|line hide|mini split|register|grille|boot|takeoff|b vent|flue|ignitor|flame sensor|coil cleaner|zone damper|duct board|'
    r'plenum|dryer vent|vacuum pump|manifold gauge|micron gauge|ac disconnect|ac whip|equipment pad|limit switch|rollout switch|condenser|heat pump|'
    r'evaporator coil|evap coil|gas furnace|air handler|heat kit|package unit|rooftop unit|economizer|crankcase heater)\b',
  ).hasMatch(text)) {
    score += 16;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final category = item.category.toLowerCase();
  final system = item.system.toLowerCase();
  final variant = _normalize(item.variant);
  if (RegExp(r'\b\d{2,3}v\b').hasMatch(variant) &&
      !RegExp(r'\b\d{2,3}v\b').hasMatch(text)) {
    score -= 20;
  }
  final context = _HvacReceiptScoreContext(
    text: text,
    itemType: itemType,
    itemName: itemName,
    category: category,
    system: system,
    variant: variant,
    item: item,
  );
  score += _hvacEquipmentReceiptScore(context);
  score += _hvacServiceReceiptScore(context);
  score += _hvacDuctReceiptScore(context);
  score += _hvacToolsHydronicReceiptScore(context);
  score += _hvacFinalReceiptScore(context);
  return score;
}

class _HvacReceiptScoreContext {
  const _HvacReceiptScoreContext({
    required this.text,
    required this.itemType,
    required this.itemName,
    required this.category,
    required this.system,
    required this.variant,
    required this.item,
  });

  final String text;
  final String itemType;
  final String itemName;
  final String category;
  final String system;
  final String variant;
  final WorkSupplyItem item;
}
