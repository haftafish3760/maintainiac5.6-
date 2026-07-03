part of 'work_supply_receipt_parser.dart';

int _hvacFinalReceiptScore(_HvacReceiptScoreContext context) {
  var score = 0;
  final text = context.text;
  final itemType = context.itemType;
  final itemName = context.itemName;
  final category = context.category;
  final system = context.system;
  final variant = context.variant;
  final item = context.item;

  if (category == 'air filters' && text.contains('mfd')) score -= 18;
  if (system == 'thermostats' && text.contains('capacitor')) score -= 18;
  if (system == 'capacitors and contactors' && text.contains('filter')) {
    score -= 18;
  }
  for (final term in [
    'filter rack',
    'return filter grille',
    'secondary drain pan',
    'clear vinyl tubing',
    'line set cover',
    'line hide',
    'equipment pad',
    'wall bracket',
    'register boot',
    'spin-in',
    'start collar',
    'b vent',
    'flue pipe',
    'wall cap',
    'rollout switch',
    'limit switch',
  ]) {
    if (text.contains(term) && variant.contains(term)) score += 42;
  }
  return score;
}
