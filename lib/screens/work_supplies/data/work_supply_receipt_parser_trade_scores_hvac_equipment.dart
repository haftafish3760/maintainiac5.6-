part of 'work_supply_receipt_parser.dart';

int _hvacEquipmentReceiptScore(_HvacReceiptScoreContext context) {
  var score = 0;
  final text = context.text;
  final itemType = context.itemType;
  final itemName = context.itemName;
  final category = context.category;
  final system = context.system;
  final variant = context.variant;
  final item = context.item;

  if (RegExp(
    r'\b(ac condenser|condensing unit|heat pump condenser|side discharge heat pump|inverter condenser|evaporator coil|evap coil|cased coil|uncased coil|'
    r'gas furnace|air handler|electric heat kit|mini split|package unit|rooftop unit|roof curb|economizer|fresh air damper|condenser fan guard|crankcase heater|low ambient kit)\b',
  ).hasMatch(text)) {
    if (itemName.contains('equipment') ||
        itemName.contains('condenser') ||
        itemName.contains('heat pump') ||
        itemName.contains('evaporator coil') ||
        itemName.contains('gas furnace') ||
        itemName.contains('air handler') ||
        itemName.contains('heat kit') ||
        itemName.contains('mini split') ||
        itemName.contains('package unit') ||
        itemName.contains('roof curb') ||
        itemName.contains('economizer') ||
        itemName.contains('crankcase heater') ||
        itemName.contains('low ambient')) {
      score += 52;
    }
    for (final term in [
      'ac condenser',
      'heat pump condenser',
      'side discharge heat pump',
      'inverter condenser',
      'cased evaporator coil',
      'uncased evaporator coil',
      'gas furnace',
      'multi position air handler',
      'wall mount air handler',
      'electric heat kit',
      'mini split outdoor condenser',
      'mini split wall mount indoor head',
      'mini split ceiling cassette',
      'mini split floor console',
      'gas electric package unit',
      'heat pump package unit',
      'package unit roof curb',
      'economizer kit',
      'fresh air damper kit',
      'condenser fan guard',
      'evaporator coil drain pan',
      'condenser riser kit',
      'compressor sound blanket',
      'low ambient control kit',
      'crankcase heater kit',
    ]) {
      if (text.contains(term) && itemName.contains(term)) {
        score += 86;
      } else if (text.contains(term) &&
          (itemName.contains('condenser') ||
              itemName.contains('coil') ||
              itemName.contains('furnace') ||
              itemName.contains('air handler') ||
              itemName.contains('mini split') ||
              itemName.contains('package unit') ||
              itemName.contains('kit')) &&
          !itemName.contains(term)) {
        score -= 26;
      }
    }
    if (text.contains('nat gas') && itemName.contains('natural gas')) {
      score += 28;
    }
    if (text.contains('evap coil') && itemName.contains('evaporator coil')) {
      score += 70;
    }
    if (text.contains('wall mount indoor head') &&
        itemName.contains('mini split wall mount indoor head')) {
      score += 70;
    }
    for (final tons in [
      '1.5 ton',
      '2 ton',
      '2.5 ton',
      '3 ton',
      '3.5 ton',
      '4 ton',
      '5 ton',
    ]) {
      final compact = tons.replaceAll(' ', '');
      if ((text.contains(tons) || text.contains(compact)) &&
          itemName.contains(tons)) {
        score += 36;
      } else if ((text.contains(tons) || text.contains(compact)) &&
          (itemName.contains('condenser') ||
              itemName.contains('coil') ||
              itemName.contains('air handler') ||
              itemName.contains('package unit')) &&
          !itemName.contains(tons)) {
        score -= 14;
      }
    }
    for (final btu in [
      '9k btu',
      '12k btu',
      '18k btu',
      '24k btu',
      '30k btu',
      '36k btu',
      '40k btu',
      '60k btu',
      '80k btu',
      '100k btu',
      '120k btu',
    ]) {
      final compact = btu.replaceAll(' ', '');
      if ((text.contains(btu) || text.contains(compact)) &&
          itemName.contains(btu)) {
        score += 36;
      }
    }
    for (final detail in [
      '14.3 seer2',
      '15.2 seer2',
      '16 seer2',
      '17 seer2',
      '18 seer2',
      '20 seer2',
      '22 seer2',
      '80 afue',
      '92 afue',
      '96 afue',
      '97 afue',
      'r410a',
      'r454b',
      '5 kw',
      '10 kw',
      '15 kw',
      '20 kw',
      'natural gas',
      'lp convertible',
      'upflow',
      'downflow',
      'horizontal',
      'multi position',
      '208-230v',
      '120v',
    ]) {
      final compact = detail.replaceAll(' ', '');
      if ((text.contains(detail) || text.contains(compact)) &&
          itemName.contains(detail)) {
        score += 24;
      }
    }
    for (final width in ['14 in', '17.5 in', '21 in', '24.5 in']) {
      final compact = width.replaceAll(' ', '');
      if ((text.contains(width) || text.contains(compact)) &&
          itemName.contains(width)) {
        score += 24;
      }
    }
  }
  return score;
}
