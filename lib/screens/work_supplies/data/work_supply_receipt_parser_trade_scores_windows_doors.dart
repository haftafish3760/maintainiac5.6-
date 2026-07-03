part of 'work_supply_receipt_parser.dart';

int _windowsDoorsReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'windows and doors') return score;
  if (RegExp(
    r'\b(window|windows|single hung|double hung|sliding window|glass block|hopper window|window screen|sash balance|tilt latch|window crank|entry door|'
    r'prehung door|door slab|interior door|storm door|patio door|bifold|closet door|barn door|lockset|door knob|door lever|deadbolt|handleset|door hinge|'
    r'strike plate|pocket door|jamb kit|threshold|door sweep|door bottom|weatherstrip|window door foam|flashing tape|sill pan|door install|screen spline)\b',
  ).hasMatch(text)) {
    score += 18;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final variant = item.variant.toLowerCase();
  if (RegExp(
    r'\b(single hung|double hung|sliding window|replacement window|glass block|hopper window)\b',
  ).hasMatch(text)) {
    if (itemType.contains('vinyl') || itemName.contains('window unit')) {
      score += 58;
    } else if (itemName.contains('screen')) {
      score -= 18;
    }
  }
  if (RegExp(
    r'\b(window screen|sash balance|tilt latch|window lock|window crank|casement handle|screen spline|screen repair)\b',
  ).hasMatch(text)) {
    if (itemType.contains('window screens')) {
      score += 58;
    } else if (itemName.contains('window unit')) {
      score -= 18;
    }
  }
  if (RegExp(
    r'\b(entry door|prehung entry|steel prehung|fiberglass prehung|patio door|sliding patio|storm door)\b',
  ).hasMatch(text)) {
    if (itemType.contains('exterior entry')) {
      score += 58;
    } else if (itemName.contains('interior door')) {
      score -= 16;
    }
  }
  if (RegExp(
    r'\b(interior door|hollow core|solid core|door slab|bifold|closet door|barn door)\b',
  ).hasMatch(text)) {
    if (itemType.contains('interior doors')) {
      score += 58;
    } else if (itemName.contains('entry door') ||
        itemName.contains('patio door')) {
      score -= 16;
    }
  }
  if (RegExp(
    r'\b(keypad deadbolt|front door handleset|single cylinder deadbolt|double cylinder deadbolt|privacy door lever|passage door lever|entry door lever)\b',
  ).hasMatch(text)) {
    if (itemType.contains('locksets')) score += 56;
  }
  if (RegExp(r'\bentry door knob\b').hasMatch(text)) {
    score -= 140;
  }
  if (RegExp(r'\bsingle cyl(inder)? deadbolt\b').hasMatch(text)) {
    score -= 110;
  }
  if (text.contains('adjustable door sweep')) {
    score -= 180;
  }
  if (text.contains('low expansion window door foam')) {
    score -= 180;
  }
  if (text.contains('exterior door sill pan')) {
    score -= 180;
  }
  if (text.contains('door jamb repair kit')) {
    score -= 180;
  }
  if (RegExp(
    r'\b(door hinge|strike plate|security strike|hinge shim|pocket door roller|sliding door roller|barn door track|bifold door repair)\b',
  ).hasMatch(text)) {
    if (itemType.contains('hinges')) score += 54;
  }
  if (RegExp(
    r'\b(adjustable door threshold|door threshold|door sweep|door bottom|kerf door weatherstrip|magnetic door weatherstrip|door jamb|jamb kit|extension jamb)\b',
  ).hasMatch(text)) {
    if (itemType.contains('jambs')) score += 56;
  }
  if (RegExp(
    r'\b(low expansion window door foam|window door foam|window door flashing tape|butyl flashing tape|stretch flashing tape|cedar shims|composite shims|'
    r'sill pan|door install bracket|window installation screw|door frame anchor)\b',
  ).hasMatch(text)) {
    if (itemType.contains('opening flashing')) score += 56;
  }
  for (final size in [
    '24 in',
    '28 in',
    '30 in',
    '32 in',
    '36 in',
    '48 in',
    '60 in',
    '72 in',
    '4-9/16 in',
    '6-9/16 in',
  ]) {
    final compact = size.replaceAll(' ', '');
    if ((text.contains(size) || text.contains(compact)) &&
        (itemName.contains(size) || variant.contains(size))) {
      score += 24;
    }
  }
  for (final finish in [
    'satin nickel',
    'matte black',
    'oil rubbed bronze',
    'polished brass',
    'antique brass',
    'chrome',
    'white',
    'black',
    'bronze',
  ]) {
    if (text.contains(finish) && itemName.contains(finish)) score += 18;
  }
  if (RegExp(r'\b(cabinet|drawer|shelf|tile|grout|drywall)\b').hasMatch(text)) {
    score -= 22;
  }
  if (category == 'windows doors detail stock') score += 6;
  return score;
}
