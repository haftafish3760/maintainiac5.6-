part of 'work_supply_receipt_parser.dart';

int _receiptFallbackSpecificityScore(String text, _ReceiptCatalogEntry entry) {
  final itemName = entry.item.name.toLowerCase();
  final normalizedText = entry.normalizedText;
  var score = 0;
  if (RegExp(r'\bwood\s+screws?\b').hasMatch(text)) {
    if (normalizedText.contains('wood screw')) {
      score += 1000;
    } else if (normalizedText.contains('screw')) {
      score -= 500;
    }
  }
  if (RegExp(r'\bpex\b').hasMatch(text) &&
      RegExp(r'\b(tee|red tee)\b').hasMatch(text)) {
    if (itemName.contains('pex tee') || normalizedText.contains('pex tee')) {
      score += 260;
    } else if (!normalizedText.contains('pex')) {
      score -= 80;
    }
  }
  if (RegExp(r'\bpvc\b').hasMatch(text) &&
      RegExp(r'\b(s40|sch40|schedule 40)\b').hasMatch(text) &&
      RegExp(
        r'\b(red coup|red coupl|reducing coupling|reducer)\b',
      ).hasMatch(text)) {
    if (itemName.contains('pvc schedule 40 reducing coupling') ||
        normalizedText.contains('pvc schedule 40 reducing coupling')) {
      score += 300;
    } else if (normalizedText.contains('floor') ||
        normalizedText.contains('transition') ||
        normalizedText.contains('end cap')) {
      score -= 160;
    } else if (!normalizedText.contains('pvc')) {
      score -= 80;
    }
  }
  if (RegExp(
    r'\b(thermostat wire|stat wire|low voltage wire)\b',
  ).hasMatch(text)) {
    if (itemName.contains('thermostat wire') ||
        normalizedText.contains('thermostat wire')) {
      score += 240;
    } else if (itemName.contains('water heater repair part') ||
        normalizedText.contains('anode')) {
      score -= 140;
    }
  }
  if (RegExp(r'\b(slip joint|slip nut|slip washer|s j)\b').hasMatch(text) ||
      RegExp(r'\b(nut washer|nut and washer)\b').hasMatch(text)) {
    if (itemName.contains('slip joint') ||
        normalizedText.contains('slip joint') ||
        normalizedText.contains('slip washer')) {
      score += 260;
      if (RegExp(r'\b(nut washer|nut and washer)\b').hasMatch(text) &&
          itemName.contains('slip joint nut and washer')) {
        score += 180;
      }
    } else if (normalizedText.contains('drain pan') ||
        normalizedText.contains('appliance') ||
        normalizedText.contains('washer drain')) {
      score -= 180;
    }
  }
  if (RegExp(r'\b(anode|anode rod)\b').hasMatch(text)) {
    if (itemName.contains('water heater repair part') ||
        normalizedText.contains('anode')) {
      score += 220;
    } else if (itemName.contains('water heater') ||
        normalizedText.contains('water heater')) {
      score -= 24;
    }
  }
  if (RegExp(
    r'\b(heating element|water heater element|element)\b',
  ).hasMatch(text)) {
    if (itemName.contains('water heater repair part') ||
        normalizedText.contains('element')) {
      score += 180;
    } else if (itemName.contains('water heater') ||
        normalizedText.contains('water heater')) {
      score -= 20;
    }
  }
  if (RegExp(r'\b(float switch|piggyback|pump float)\b').hasMatch(text)) {
    if (itemName.contains('pump control part') ||
        normalizedText.contains('float switch') ||
        normalizedText.contains('piggyback')) {
      score += 190;
    } else if (itemName.contains('sump pump')) {
      score -= 20;
    }
  }
  if (RegExp(r'\b(high water alarm|pump alarm)\b').hasMatch(text)) {
    if (itemName.contains('pump control part') ||
        normalizedText.contains('high water alarm') ||
        normalizedText.contains('pump alarm')) {
      score += 210;
    } else if (itemName.contains('sump pump')) {
      score -= 22;
    }
  }
  return score;
}
