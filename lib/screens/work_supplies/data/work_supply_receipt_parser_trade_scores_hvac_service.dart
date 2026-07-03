part of 'work_supply_receipt_parser.dart';

int _hvacServiceReceiptScore(_HvacReceiptScoreContext context) {
  var score = 0;
  final text = context.text;
  final itemType = context.itemType;
  final itemName = context.itemName;
  final category = context.category;
  final system = context.system;
  final variant = context.variant;
  final item = context.item;

  if (RegExp(r'\b(capacitor|mfd|uf|run cap|dual run)\b').hasMatch(text) &&
      itemType.contains('capacitor')) {
    score += 24;
    for (final value in [
      '25/5',
      '30/5',
      '35/5',
      '40/5',
      '45/5',
      '50/5',
      '55/5',
      '60/5',
      '70/5',
      '80/5',
    ]) {
      if (text.contains(value) && itemName.contains(value)) {
        score += 96;
      } else if (text.contains(value) && !itemName.contains(value)) {
        score -= 36;
      }
    }
    if (RegExp(r'\b(dual run|run cap)\b').hasMatch(text) &&
        itemName.contains('start kit')) {
      score -= 90;
    }
    if (text.contains('start') && itemName.contains('start capacitor')) {
      score += 42;
    }
  }
  if (RegExp(r'\b(pleated|filter)\b').hasMatch(text) &&
      itemType.contains('filter')) {
    score += 24;
  }
  if (RegExp(r'\b(filter|merv|media cabinet)\b').hasMatch(text) &&
      itemName.contains('filter')) {
    for (final size in [
      '10 x 20 x 1',
      '12 x 12 x 1',
      '12 x 20 x 1',
      '14 x 14 x 1',
      '14 x 20 x 1',
      '14 x 25 x 1',
      '16 x 16 x 1',
      '16 x 20 x 1',
      '16 x 24 x 1',
      '16 x 25 x 1',
      '18 x 20 x 1',
      '18 x 24 x 1',
      '20 x 20 x 1',
      '20 x 24 x 1',
      '20 x 25 x 1',
      '24 x 24 x 1',
      '24 x 30 x 1',
      '12 x 24 x 2',
      '16 x 20 x 2',
      '16 x 25 x 2',
      '20 x 20 x 2',
      '20 x 25 x 2',
      '24 x 24 x 2',
      '20 x 25 x 5',
      '20 x 25 x 4',
      '16 x 25 x 5',
      '16 x 25 x 4',
    ]) {
      final compact = size.replaceAll(' ', '');
      if ((text.contains(size) || text.contains(compact)) &&
          (itemName.contains('$size in') || itemName.contains(size))) {
        score += 58;
      } else if ((text.contains(size) || text.contains(compact)) &&
          !itemName.contains('$size in') &&
          !itemName.contains(size)) {
        score -= 22;
      }
    }
    for (final rating in ['merv 8', 'merv 11', 'merv 13', 'merv 16']) {
      if (text.contains(rating) && itemName.contains(rating)) {
        score += 30;
      } else if (text.contains(rating) && !itemName.contains(rating)) {
        score -= 10;
      }
    }
    if (!text.contains('merv') && itemName.contains('merv')) {
      score -= 72;
    }
    if (text.contains('media cabinet') &&
        itemName.contains('media cabinet filter')) {
      score += 40;
    }
  }
  if (RegExp(
        r'\b(filter rack|filter base|return filter grille|filter grille|return air grille)\b',
      ).hasMatch(text) &&
      itemType.contains('filter racks')) {
    score += 34;
  }
  if (RegExp(r'\b(foil tape|hvac tape|metal tape)\b').hasMatch(text) &&
      itemType.contains('tape')) {
    score += 22;
  }
  if (RegExp(r'\b(mastic|duct sealant)\b').hasMatch(text) &&
      itemType.contains('mastic')) {
    score += 22;
  }
  if (RegExp(
    r'\b(duct mastic|duct sealant|water based duct sealant)\b',
  ).hasMatch(text)) {
    if (itemName.contains('duct mastic') || itemName.contains('duct sealant')) {
      score += 84;
    } else if (itemName.contains('mastic')) {
      score -= 42;
    }
    for (final size in ['1 gal', '2 gal', '5 gal']) {
      final compact = size.replaceAll(' ', '');
      if ((text.contains(size) || text.contains(compact)) &&
          itemName.contains(size)) {
        score += 28;
      }
    }
  }
  if (RegExp(r'\b(contactor|compressor contactor)\b').hasMatch(text) &&
      itemType.contains('contactor')) {
    score += 24;
  }
  if (RegExp(r'\b(thermostat|t-stat|t stat|stat)\b').hasMatch(text) &&
      itemType.contains('thermostat')) {
    score += 20;
  }
  if (RegExp(
        r'\b(thermostat wire|stat wire|low voltage wire)\b',
      ).hasMatch(text) &&
      itemType.contains('thermostat wire')) {
    score += 24;
  }
  if (RegExp(r'\b(cond pump|condensate pump|little pump)\b').hasMatch(text) &&
      itemType.contains('condensate pump')) {
    score += 24;
  }
  if (RegExp(r'\b(pan tabs|drain tabs|condensate tablets)\b').hasMatch(text) &&
      itemType.contains('condensate drain tablets')) {
    score += 24;
  }
  if (RegExp(
        r'\b(drain pan|secondary pan|auxiliary pan|vinyl tubing|clear tubing|condensate treatment|pan switch|float switch|wet switch)\b',
      ).hasMatch(text) &&
      itemType.contains('condensate pans')) {
    score += 34;
  }
  if (RegExp(r'\b(line set|copper line|armaflex)\b').hasMatch(text) &&
      itemType.contains('line sets')) {
    score += 26;
  }
  return score;
}
