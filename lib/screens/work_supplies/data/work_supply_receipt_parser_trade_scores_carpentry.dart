part of 'work_supply_receipt_parser.dart';

int _carpentryReceiptScore(
  String text,
  String category,
  String system,
  WorkSupplyItem item,
) {
  var score = 0;
  if (item.trade.toLowerCase() == 'carpentry' &&
      RegExp(
        r'\b(stud|lumber|kd|kiln|wood|board|treated|pt|plywood|osb|sheathing|trim|moulding|molding|joist hanger|post base|deck screw|cabinet|drawer slide|'
        r'project panel|finish board|stair tread|stair riser|handrail|lockset|door knob|deadbolt|door sweep|threshold|weatherstrip|sill pan|flashing tape|'
        r'joist tape|ledger flashing|pocket hole|wood biscuit|fluted dowel|toe kick|lazy susan|closet shelf|shelf track|door jamb repair|stair nosing|'
        r'baluster shoe|deck post cap light|deck gate|fascia screw|lvl|i joist|rim board|subfloor|underlayment|prehung|door slab|jamb kit|extension jamb|shelf pin)\b',
      ).hasMatch(text)) {
    score += 16;
  }
  if (RegExp(
    r'\b(paper tape|mesh tape|joint tape|drywall tape)\b',
  ).hasMatch(text)) {
    score -= 28;
  }
  if (RegExp(r'\b(drywall|sheetrock|gypsum)\s+screws?\b').hasMatch(text)) {
    score -= 40;
  }
  if (category == 'fasteners' &&
      RegExp(
        r'\b(screw|screws|nail|nails|fastener|fasteners)\b',
      ).hasMatch(text)) {
    score += 12;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final variant = _normalize(item.variant);
  if (RegExp(r'\b(plywood|cdx|sanded ply)\b').hasMatch(text) &&
      (variant.contains('plywood') || itemName.contains('plywood'))) {
    score += 26;
  }
  if (RegExp(r'\b(osb|sheathing)\b').hasMatch(text) &&
      (variant.contains('osb') ||
          itemName.contains('osb') ||
          variant.contains('sheathing') ||
          itemName.contains('sheathing'))) {
    score += 26;
  }
  if (RegExp(r'\b(lvl|lvl beam|engineered beam)\b').hasMatch(text) &&
      itemName.contains('lvl beam')) {
    score += 46;
  }
  if (RegExp(r'\b(i joist|i-joist|engineered joist)\b').hasMatch(text) &&
      itemName.contains('i joist')) {
    score += 46;
  }
  if (text.contains('rim board') && itemName.contains('rim board')) {
    score += 44;
  }
  if (RegExp(r'\b(subfloor|tongue and groove|t&g)\b').hasMatch(text) &&
      itemName.contains('subfloor')) {
    score += 38;
  }
  if (RegExp(r'\b(underlayment|lauan|luan)\b').hasMatch(text) &&
      (itemName.contains('underlayment') || itemName.contains('lauan'))) {
    score += 36;
  }
  if (RegExp(r'\b(baseboard|base trim)\b').hasMatch(text) &&
      (variant.contains('baseboard') || itemName.contains('baseboard'))) {
    score += 24;
  }
  if (RegExp(r'\b(casing|door casing|window casing)\b').hasMatch(text) &&
      (variant.contains('casing') || itemName.contains('casing'))) {
    score += 22;
  }
  if (RegExp(
        r'\b(crown|quarter round|shoe mould|shoe mold)\b',
      ).hasMatch(text) &&
      (variant.contains('crown') ||
          variant.contains('quarter round') ||
          variant.contains('shoe'))) {
    score += 22;
  }
  if (RegExp(r'\b(joist hanger|hanger)\b').hasMatch(text) &&
      (variant.contains('joist hanger') || itemName.contains('joist hanger'))) {
    score += 28;
  }
  if (RegExp(r'\b(hurricane tie|rafter tie)\b').hasMatch(text) &&
      (variant.contains('hurricane tie') ||
          itemName.contains('hurricane tie'))) {
    score += 26;
  }
  if (RegExp(r'\b(post base|post cap|post anchor)\b').hasMatch(text) &&
      (variant.contains('post base') ||
          variant.contains('post cap') ||
          variant.contains('post anchor'))) {
    score += 24;
  }
  if (RegExp(r'\b(cabinet pull|cabinet knob|cabinet hinge)\b').hasMatch(text) &&
      (variant.contains('cabinet') || itemName.contains('cabinet'))) {
    score += 24;
  }
  for (final hardwareTerm in [
    'cabinet pull',
    'cabinet knob',
    'handrail bracket',
    'deadbolt',
    'door knob',
    'drawer slide',
    'shelf pin',
    'shelf support clip',
  ]) {
    if (text.contains(hardwareTerm) && itemName.contains(hardwareTerm)) {
      score += 76;
    } else if (text.contains(hardwareTerm) &&
        (itemName.contains('cabinet') ||
            itemName.contains('door') ||
            itemName.contains('handrail') ||
            itemName.contains('shelf')) &&
        !itemName.contains(hardwareTerm)) {
      score -= 18;
    }
  }
  for (final finish in [
    'matte black',
    'satin nickel',
    'oil rubbed bronze',
    'brushed brass',
    'nickel',
    'white',
    'almond',
  ]) {
    if (text.contains(finish) && itemName.contains(finish)) {
      score += 24;
    }
  }
  if (RegExp(
        r'\b(cabinet filler|filler strip|toe kick|cabinet end panel|light rail|cabinet crown)\b',
      ).hasMatch(text) &&
      itemType.contains('cabinet fillers')) {
    score += 34;
  }
  if (RegExp(
        r'\b(cabinet organizer|pull out trash|wire basket|drawer organizer|lazy susan|shelf pin|shelf support clip)\b',
      ).hasMatch(text) &&
      itemType.contains('cabinet organizers')) {
    score += 34;
  }
  if (RegExp(r'\b(drawer slide|soft close slide)\b').hasMatch(text) &&
      (variant.contains('drawer slide') || itemName.contains('drawer slide'))) {
    score += 28;
  }
  if (RegExp(r'\b(shelf bracket|closet rod)\b').hasMatch(text) &&
      (variant.contains('shelf') ||
          variant.contains('closet') ||
          itemName.contains('shelving'))) {
    score += 22;
  }
  if (RegExp(
        r'\b(wire shelf|closet shelf|ventilated shelf|closet rod support|shelf track|closet tower)\b',
      ).hasMatch(text) &&
      itemType.contains('closet systems')) {
    score += 34;
  }
  if (RegExp(r'\b(project panel|craft panel|hobby board)\b').hasMatch(text) &&
      (variant.contains('project panel') || itemName.contains('project'))) {
    score += 28;
  }
  if (RegExp(r'\b(finish board|project board|craft board)\b').hasMatch(text) &&
      (variant.contains('board') || itemName.contains('finish board'))) {
    score += 24;
  }
  if (RegExp(r'\b(stair tread|oak tread|pine tread)\b').hasMatch(text) &&
      (variant.contains('stair tread') || itemName.contains('stair'))) {
    score += 30;
  }
  if (RegExp(r'\b(stair riser|riser board)\b').hasMatch(text) &&
      (variant.contains('stair riser') || itemName.contains('stair'))) {
    score += 28;
  }
  if (RegExp(
        r'\b(stair nosing|retread|landing tread|shoe rail|baluster shoe|rail bolt)\b',
      ).hasMatch(text) &&
      itemType.contains('stair baluster')) {
    score += 34;
  }
  if (RegExp(r'\b(handrail|rail bracket|handrail bracket)\b').hasMatch(text) &&
      (variant.contains('handrail') || itemName.contains('handrail'))) {
    score += 28;
  }
  if (RegExp(r'\b(lockset|door knob|door lever|deadbolt)\b').hasMatch(text) &&
      (variant.contains('door knob') ||
          variant.contains('lockset') ||
          variant.contains('deadbolt') ||
          itemName.contains('door lock'))) {
    score += 30;
  }
  if (RegExp(
        r'\b(prehung|pre hung|door slab|jamb kit|extension jamb)\b',
      ).hasMatch(text) &&
      itemName.contains('door detail')) {
    score += 38;
  }
  if (RegExp(r'\b(door sweep|threshold|door threshold)\b').hasMatch(text) &&
      (variant.contains('door sweep') || variant.contains('threshold'))) {
    score += 26;
  }
  if (RegExp(
        r'\b(door bottom|kerf weatherstrip|door jamb repair|hinge shim|strike reinforcer|security strike|pocket door roller)\b',
      ).hasMatch(text) &&
      itemType.contains('door repair')) {
    score += 34;
  }
  if (RegExp(
        r'\b(low expansion foam|window door foam|flashing tape|sill pan|weatherstrip|door install kit|prehung door bracket)\b',
      ).hasMatch(text) &&
      itemType.contains('door window install')) {
    score += 34;
  }
  if (RegExp(
        r'\b(joist tape|ledger flashing|deck plug|starter clip|deck spacer|deck drainage)\b',
      ).hasMatch(text) &&
      itemType.contains('deck flashing')) {
    score += 34;
  }
  if (RegExp(
        r'\b(deck post cap light|deck stair light|deck gate latch|deck gate hinge|deck board repair clip|fascia screw|deck plug cutter)\b',
      ).hasMatch(text) &&
      itemType.contains('deck railing lighting')) {
    score += 34;
  }
  if (RegExp(
        r'\b(wood biscuit|fluted dowel|pocket hole screw|cabinet install screw|cabinet leveler|cabinet shim|toe kick clip|cabinet filler)\b',
      ).hasMatch(text) &&
      itemType.contains('joinery')) {
    score += 34;
  }
  for (final term in [
    'low expansion',
    'flashing tape',
    'sill pan',
    'weatherstrip',
    'joist tape',
    'ledger flashing',
    'pocket hole',
    'wood biscuit',
    'fluted dowel',
    'cabinet installation',
    'cabinet shim',
  ]) {
    if (text.contains(term) && variant.contains(term)) score += 42;
  }
  if (text.contains('adjustable door sweep') &&
      variant.contains('adjustable door sweep')) {
    score += 54;
  }
  if (category != 'fasteners') return score;
  final isScrewItem = itemType.contains('screw') || system.contains('screw');
  final isNailItem = itemType.contains('nail') || system.contains('nail');
  final receiptSaysScrew = RegExp(r'\b(screw|screws)\b').hasMatch(text);
  final receiptSaysNail = RegExp(r'\b(nail|nails)\b').hasMatch(text);
  if (receiptSaysScrew && isScrewItem) score += 18;
  if (receiptSaysNail && isNailItem) score += 18;
  if (receiptSaysScrew && isNailItem) score -= 24;
  if (receiptSaysNail && isScrewItem) score -= 24;
  if (text.contains('wood') && itemType.contains('wood screw')) score += 10;
  if (text.contains('drywall') && itemType.contains('drywall')) score += 10;
  if (text.contains('deck') && itemType.contains('deck')) score += 10;
  if (text.contains('structural') && itemType.contains('structural')) {
    score += 12;
  }
  if (text.contains('timber') && itemType.contains('timber')) score += 12;
  if (text.contains('connector') && itemType.contains('connector')) {
    score += 12;
  }
  if (text.contains('framing') && itemType.contains('framing')) score += 10;
  return score;
}
