part of 'work_supply_receipt_parser.dart';

int _hvacInstallSupportReceiptScore(_HvacReceiptScoreContext context) {
  var score = 0;
  final text = context.text;
  final itemType = context.itemType;
  final itemName = context.itemName;
  final variant = context.variant;

  if (RegExp(
        r'\b(line set cover|line hide|equipment pad|condenser pad|wall bracket|ground stand|tie down kit|hurricane strap)\b',
      ).hasMatch(text) &&
      itemType.contains('line set covers')) {
    score += 34;
  }
  if (text.contains('line hide') && itemName.contains('line hide')) {
    score += 72;
  } else if (text.contains('line hide') &&
      itemName.contains('line set cover')) {
    score -= 28;
  }
  if (text.contains('line hide')) {
    for (final part in ['elbow', 'coupling', 'end cap', 'wall cap']) {
      if (text.contains(part) && itemName.contains('line hide $part')) {
        score += 82;
      } else if (text.contains(part) &&
          itemName.contains('line hide') &&
          !itemName.contains(part)) {
        score -= 36;
      }
    }
    for (final size in ['3 in', '4 in', '5 in']) {
      final compact = size.replaceAll(' ', '');
      if ((text.contains(size) || text.contains(compact)) &&
          itemName.contains(size)) {
        score += 64;
      } else if ((text.contains(size) || text.contains(compact)) &&
          itemName.contains('line hide') &&
          !itemName.contains(size)) {
        score -= 26;
      }
    }
    for (final color in ['white', 'black', 'brown']) {
      if (text.contains(color) && itemName.contains(color)) {
        score += 30;
      } else if (text.contains(color) &&
          itemName.contains('line hide') &&
          !itemName.contains(color)) {
        score -= 16;
      }
    }
  }
  if (RegExp(
    r'\b(equipment pad|condenser pad|hurricane pad|wall bracket|ground stand|snow stand|tie down strap|vibration pad)\b',
  ).hasMatch(text)) {
    if (itemName.contains('equipment pad') ||
        itemName.contains('condenser pad') ||
        itemName.contains('hurricane pad') ||
        itemName.contains('wall bracket') ||
        itemName.contains('ground stand') ||
        itemName.contains('tie down') ||
        itemName.contains('vibration pad')) {
      score += 48;
    }
    for (final part in [
      'equipment pad',
      'condenser pad',
      'hurricane pad',
      'wall bracket',
      'ground stand',
      'snow stand',
      'condenser tie down strap kit',
      'hurricane pad strap kit',
      'anti vibration pad',
    ]) {
      if (text.contains(part) && itemName.contains(part)) {
        score += 72;
      } else if (text.contains(part) &&
          (itemName.contains('pad') ||
              itemName.contains('bracket') ||
              itemName.contains('stand')) &&
          !itemName.contains(part)) {
        score -= 24;
      }
    }
    for (final size in [
      '18 x 38',
      '24 x 24',
      '24 x 36',
      '30 x 30',
      '32 x 32',
      '36 x 36',
      '40 x 40',
    ]) {
      final compact = size.replaceAll(' ', '');
      if ((text.contains(size) || text.contains(compact)) &&
          itemName.contains(size)) {
        score += 44;
      } else if ((text.contains(size) || text.contains(compact)) &&
          (itemName.contains('equipment pad') ||
              itemName.contains('condenser pad') ||
              itemName.contains('hurricane pad')) &&
          !itemName.contains(size)) {
        score -= 20;
      }
    }
  }
  if (RegExp(
        r'\b(mini split|mini-split|line hide|communication cable)\b',
      ).hasMatch(text) &&
      itemType.contains('mini split')) {
    score += 28;
  }
  if (text.contains('mini split') &&
      text.contains('line hide') &&
      itemType.contains('mini split')) {
    score += 30;
  }
  if (text.contains('mini split') &&
      itemType.contains('line set covers') &&
      !variant.contains('mini split')) {
    score -= 16;
  }
  if (text.contains('communication cable')) {
    if (itemName.contains('communication cable')) {
      score += 80;
    } else if (itemType.contains('mini split')) {
      score -= 28;
    }
    for (final cable in ['14/4 x 50 ft', '14/4 x 100 ft', '16/4 x 50 ft']) {
      final compact = cable
          .replaceAll(' x ', ' ')
          .replaceAll(' ', '')
          .replaceAll('ft', 'ft');
      final receiptCompact = text.replaceAll(' ', '');
      if ((text.contains(cable) || receiptCompact.contains(compact)) &&
          itemName.contains(cable)) {
        score += 86;
      } else if ((text.contains(cable) || receiptCompact.contains(compact)) &&
          itemName.contains('communication cable') &&
          !itemName.contains(cable)) {
        score -= 28;
      }
    }
  }
  return score;
}
