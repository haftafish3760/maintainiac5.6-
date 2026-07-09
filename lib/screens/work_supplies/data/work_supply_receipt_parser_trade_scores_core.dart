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
        r'\b(stud|lumber|kd|kiln|wood|board|treated|pt|plywood|osb|sheathing|trim|moulding|molding|joist hanger|post base|deck screw|cabinet|drawer slide|project panel|finish board|stair tread|stair riser|handrail|lockset|door knob|deadbolt|door sweep|threshold|weatherstrip|sill pan|flashing tape|joist tape|ledger flashing|pocket hole|wood biscuit|fluted dowel|toe kick|lazy susan|closet shelf|shelf track|door jamb repair|stair nosing|baluster shoe|deck post cap light|deck gate|fascia screw|lvl|i joist|rim board|subfloor|underlayment|prehung|door slab|jamb kit|extension jamb|shelf pin)\b',
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

int _windowsDoorsReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'windows and doors') return score;
  if (RegExp(
    r'\b(window|windows|single hung|double hung|sliding window|glass block|hopper window|window screen|sash balance|tilt latch|window crank|entry door|prehung door|door slab|interior door|storm door|patio door|bifold|closet door|barn door|lockset|door knob|door lever|deadbolt|handleset|door hinge|strike plate|pocket door|jamb kit|threshold|door sweep|door bottom|weatherstrip|window door foam|flashing tape|sill pan|door install|screen spline)\b',
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
    r'\b(low expansion window door foam|window door foam|window door flashing tape|butyl flashing tape|stretch flashing tape|cedar shims|composite shims|sill pan|door install bracket|window installation screw|door frame anchor)\b',
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

int _cabinetsCountertopsReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'cabinets and countertops') return score;
  if (RegExp(
    r'\b(base cabinet|wall cabinet|sink base|drawer base|pantry cabinet|utility cabinet|kitchen cabinet|cabinet filler|toe kick|end panel|vanity|vanity cabinet|vanity top|medicine cabinet|countertop|counter top|laminate top|butcher block|solid surface|quartz top|granite top|side splash|countertop end cap|miter bolt|backsplash panel|range backsplash|countertop support|undermount sink clip|dishwasher bracket)\b',
  ).hasMatch(text)) {
    score += 18;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final variant = item.variant.toLowerCase();
  if (RegExp(
    r'\b(base cabinet|wall cabinet|sink base|drawer base|pantry cabinet|utility cabinet|kitchen cabinet)\b',
  ).hasMatch(text)) {
    if (itemType.contains('base wall')) {
      score += 60;
    } else if (itemName.contains('vanity')) {
      score -= 16;
    }
  }
  if (RegExp(
    r'\b(cabinet filler|filler strip|end panel|toe kick|light rail|cabinet crown|scribe molding)\b',
  ).hasMatch(text)) {
    if (itemType.contains('cabinet panels')) {
      score += 54;
    }
  }
  if (RegExp(
    r'\b(cabinet filler strip|toe kick board|cabinet end panel)\b',
  ).hasMatch(text)) {
    score -= 34;
  }
  if (RegExp(
    r'\b(vanity|vanity cabinet|vanity top|cultured marble top|quartz vanity|granite vanity|ceramic vanity)\b',
  ).hasMatch(text)) {
    if (itemType.contains('vanity')) {
      score += 58;
    } else if (itemName.contains('kitchen cabinet')) {
      score -= 16;
    }
  }
  if (RegExp(
    r'\b(medicine cabinet|bath storage|linen tower|over toilet cabinet)\b',
  ).hasMatch(text)) {
    if (itemType.contains('medicine')) score += 54;
  }
  if (RegExp(
    r'\b(laminate countertop|countertop|counter top|butcher block|solid surface|worktop|finished edge)\b',
  ).hasMatch(text)) {
    if (itemType.contains('laminate butcher')) {
      score += 58;
    } else if (itemName.contains('backsplash')) {
      score -= 14;
    }
  }
  if (RegExp(
    r'\b(quartz countertop|quartz top|granite top|side splash|end cap kit|miter bolt|seam filler)\b',
  ).hasMatch(text)) {
    if (itemType.contains('stone quartz')) score += 56;
  }
  if (RegExp(
    r'\b(laminate backsplash|peel and stick backsplash|range backsplash|backsplash panel)\b',
  ).hasMatch(text)) {
    if (itemType.contains('backsplash')) {
      score += 54;
    } else if (itemName.contains('tile')) {
      score -= 16;
    }
  }
  if (RegExp(
    r'\b(countertop support|countertop bracket|countertop adhesive|countertop sealant|undermount sink clip|sink rail|dishwasher bracket)\b',
  ).hasMatch(text)) {
    if (itemType.contains('cabinet countertop install')) score += 54;
  }
  for (final size in [
    '3 in',
    '6 in',
    '9 in',
    '12 in',
    '18 in',
    '24 in',
    '30 in',
    '36 in',
    '48 in',
    '4 ft',
    '6 ft',
    '8 ft',
    '10 ft',
    '12 ft',
  ]) {
    final compact = size.replaceAll(' ', '');
    if ((text.contains(size) || text.contains(compact)) &&
        (itemName.contains(size) || variant.contains(size))) {
      score += 22;
    }
  }
  for (final finish in [
    'white shaker',
    'gray shaker',
    'espresso',
    'natural oak',
    'hickory',
    'unfinished',
    'navy shaker',
    'maple',
    'carrara',
    'calacatta',
    'black granite',
    'concrete gray',
    'walnut',
  ]) {
    if (text.contains(finish) && itemName.contains(finish)) score += 18;
  }
  for (final material in [
    'quartz',
    'ceramic',
    'cultured marble',
    'granite',
    'laminate',
    'butcher block',
    'solid surface',
  ]) {
    if (text.contains(material) && itemName.contains(material)) {
      score += 20;
    } else if (text.contains(material) && itemName.contains(' with ')) {
      score -= 10;
    }
  }
  if (RegExp(
    r'\b(cabinet pull|cabinet knob|cabinet hinge|cabinet shim pack|cabinet install screw|drawer slide|lazy susan hardware)\b',
  ).hasMatch(text)) {
    score -= 80;
  }
  if (RegExp(
    r'\b(cabinet paint|paint|roller|nap roller|roller cover|tile|grout|thinset)\b',
  ).hasMatch(text)) {
    score -= 90;
  }
  if (category == 'cabinets countertops detail stock') score += 6;
  return score;
}

int _electricalReceiptScore(
  String text,
  String trade,
  String category,
  String system,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'electrical') return score;
  if (RegExp(
    r'\b(gfci|gfi|receptacle|recept|outlet|romex|nm-b|nmb|mc|armored|emt|conduit|raceway|awg|wire|breaker|lb body|smart switch|smart dimmer|smoke alarm|smoke detector|co alarm|fan box|fan brace|weatherhead|ground bar|panel filler)\b',
  ).hasMatch(text)) {
    score += 16;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final variant = _normalize(item.variant);
  final ampRating = RegExp(r'\b(\d{1,3})\s*amp\b').firstMatch(text);
  if (ampRating != null) {
    final rating = '${ampRating.group(1)} amp';
    if (variant == rating) {
      score += 24;
    } else if (variant.endsWith('amp')) {
      score -= 18;
    }
  }
  final receiptSaysNmCable = RegExp(
    r'\b(nm-b|nmb|romex|house wire)\b',
  ).hasMatch(text);
  final receiptSaysThhn = RegExp(r'\b(thhn|building wire)\b').hasMatch(text);
  final receiptLength = RegExp(r'\b(\d{2,4})\s*ft\b').firstMatch(text);
  final receiptSaysBreaker = RegExp(
    r'\b(breaker|brkr|circuit breaker)\b',
  ).hasMatch(text);
  final receiptSaysSinglePole = RegExp(
    r'\b(single pole|single-pole|1p)\b',
  ).hasMatch(text);
  final receiptSaysDoublePole = RegExp(
    r'\b(double pole|double-pole|2p)\b',
  ).hasMatch(text);
  final receiptSaysGfci = RegExp(
    r'\b(gfci|gfc1|gfi|ground fault)\b',
  ).hasMatch(text);
  final receiptSaysAfci = RegExp(r'\b(afci|arc fault)\b').hasMatch(text);
  final receiptSaysDualFunction = RegExp(
    r'\b(dual function|dual-function)\b',
  ).hasMatch(text);
  final receiptPackCount = RegExp(r'\b(\d+)\s*pack\b').firstMatch(text);
  final receiptSaysOutlet = RegExp(
    r'\b(receptacle|recept|outlet|wall socket|plug)\b',
  ).hasMatch(text);
  final receiptSaysMcCable = RegExp(
    r'\b(mc|armored cable|metal clad|bx)\b',
  ).hasMatch(text);
  final receiptSaysFlexibleRaceway = RegExp(
    r'\b(flex|flexible|fmc|liquid\s*tight|liquidtight|sealtite)\b',
  ).hasMatch(text);
  final receiptSaysPhotocell = RegExp(
    r'\b(photocell|photoeye|photo eye)\b',
  ).hasMatch(text);
  final receiptSaysEmt = RegExp(r'\b(emt|thinwall)\b').hasMatch(text);
  final receiptSaysConduit = RegExp(r'\b(conduit|pipe)\b').hasMatch(text);
  final receiptSaysRacewayBody = RegExp(
    r'\b(lb body|ll body|lr body|conduit body)\b',
  ).hasMatch(text);
  final receiptSaysConnector = RegExp(
    r'\b(connector|conn|set screw conn)\b',
  ).hasMatch(text);
  final receiptSaysCoupling = RegExp(
    r'\b(coupling|cplg|coup)\b',
  ).hasMatch(text);
  final receiptSaysWireNut = RegExp(r'\b(wire nut|wirenut)\b').hasMatch(text);
  final receiptSaysWinged = RegExp(r'\bwing(ed)?\b').hasMatch(text);
  final receiptSaysSmartControl = RegExp(
    r'\b(smart switch|smart dimmer|wifi switch|wi-fi switch|motion switch|occupancy sensor|vacancy sensor|timer switch|countdown timer)\b',
  ).hasMatch(text);
  final receiptSaysAlarm = RegExp(
    r'\b(smoke alarm|smoke detector|co alarm|carbon monoxide|heat alarm)\b',
  ).hasMatch(text);
  final receiptSaysLedLighting = RegExp(
    r'\b(led shop light|shop light|led lamp|led bulb|led driver|tape light)\b',
  ).hasMatch(text);
  final receiptSaysDoorbell = RegExp(
    r'\b(doorbell transformer|bell transformer|doorbell chime|video doorbell)\b',
  ).hasMatch(text);
  final receiptSaysFanSupport = RegExp(
    r'\b(fan box|fan brace|ceiling fan box|fixture box|ceiling box|bar hanger)\b',
  ).hasMatch(text);
  final receiptSaysBoxAccessory = RegExp(
    r'\b(mud ring|box extender|extension ring|knockout seal|ko seal|locknut|bushing|reducing washer)\b',
  ).hasMatch(text);
  final receiptSaysDeviceBox = RegExp(
    r'\b(device box|outlet box|switch box|single gang box|gang device box)\b',
  ).hasMatch(text);
  final receiptSaysJunctionBox = RegExp(
    r'\b(junction box|j box|square box)\b',
  ).hasMatch(text);
  final receiptSaysWeatherproofCover = RegExp(
    r'\b(weatherproof|extra duty|in use|in-use|bubble cover|outdoor cover)\b',
  ).hasMatch(text);
  final receiptSaysWallPlate = RegExp(
    r'\b(wall plate|cover plate|switch plate|device plate|blank plate|placa|placa electrica|placa decora|placa decorador|cubierta electrica)\b',
  ).hasMatch(text);
  final receiptSaysPanelAccessory = RegExp(
    r'\b(ground bar|neutral bar|breaker filler|panel filler|panel label|circuit directory|panel schedule|interlock kit|surge protective)\b',
  ).hasMatch(text);
  final receiptSaysServiceAccessory = RegExp(
    r'\b(weatherhead|service head|service entrance head|mast clamp|service mast|ground bridge|bonding terminal)\b',
  ).hasMatch(text);
  final receiptSaysRacewaySupport = RegExp(
    r'\b(one hole strap|two hole strap|mini strap|conduit strap|conduit hanger|minerallac|beam clamp|strut clamp)\b',
  ).hasMatch(text);
  if (receiptSaysNmCable && system == 'nm-b cable') score += 24;
  if (receiptSaysThhn && system == 'conduit wire') score += 24;
  if (receiptSaysThhn && itemName.contains('thhn')) score += 72;
  if (receiptSaysThhn && receiptLength != null) {
    final length = '${receiptLength.group(1)} ft';
    if (variant.contains(length) || itemName.contains(length)) {
      score += 34;
    } else if (system == 'conduit wire' && itemName.contains('thhn')) {
      score -= 12;
    }
  }
  if (receiptSaysMcCable && itemType.contains('armored cable')) score += 28;
  if (receiptSaysMcCable && itemType.contains('nm-b')) score -= 16;
  if (receiptSaysFlexibleRaceway &&
      (itemType.contains('flexible raceway') ||
          itemName.contains('flexible raceway') ||
          variant.contains('flexible metal') ||
          variant.contains('fmc') ||
          variant.contains('liquidtight'))) {
    score += 54;
  }
  if (receiptSaysFlexibleRaceway && variant.contains('1/2 in')) score += 26;
  if (receiptSaysFlexibleRaceway && variant.contains('1-1/2 in')) score -= 28;
  if (receiptSaysFlexibleRaceway && system == 'emt') score -= 26;
  if (receiptSaysNmCable && system == 'conduit wire') score -= 20;
  if (receiptSaysThhn && system == 'nm-b cable') score -= 20;
  if (text.contains('with ground') && system == 'nm-b cable') score += 10;
  if (receiptSaysBreaker && category == 'breakers') score += 22;
  if (receiptSaysSinglePole && itemType.contains('single-pole')) score += 22;
  if (receiptSaysDoublePole && itemType.contains('double-pole')) score += 22;
  if (receiptSaysSinglePole && itemType.contains('double-pole')) score -= 22;
  if (receiptSaysDoublePole && itemType.contains('single-pole')) score -= 22;
  if (receiptSaysOutlet && system == 'receptacles') score += 22;
  if (receiptSaysOutlet &&
      (itemType.contains('wiring device') ||
          itemName.contains('wiring device'))) {
    score += 20;
  }
  if (receiptPackCount != null) {
    final pack = '${receiptPackCount.group(1)} pack';
    if (variant.contains(pack)) {
      score += 24;
    } else if (itemType.contains('receptacle') || itemType.contains('outlet')) {
      score -= 10;
    }
  }
  if (receiptSaysGfci && itemType.contains('gfci')) score += 36;
  if (receiptSaysGfci && !itemType.contains('gfci')) score -= 12;
  if (receiptSaysAfci && itemType.contains('afci')) score += 20;
  if (receiptSaysAfci && !itemType.contains('afci')) score -= 12;
  if (receiptSaysDualFunction && itemName.contains('dual function')) {
    score += 92;
  } else if (receiptSaysDualFunction && category == 'breakers') {
    score -= 32;
  }
  if (receiptSaysEmt && system == 'emt') score += 20;
  if (receiptSaysConduit && itemType.contains('conduit')) score += 18;
  if (receiptSaysRacewayBody && itemType.contains('raceway')) score += 24;
  if (receiptSaysRacewayBody && itemType.contains('conduit bodies')) {
    score += 38;
  }
  if (receiptSaysRacewaySupport && itemType.contains('raceway hangers')) {
    score += 34;
  }
  if (receiptSaysConnector && itemType.contains('connector')) score += 18;
  if (receiptSaysCoupling && itemType.contains('coupling')) score += 18;
  if (receiptSaysConnector && itemType.contains('coupling')) score -= 16;
  if (receiptSaysCoupling && itemType.contains('connector')) score -= 16;
  if (receiptSaysWireNut &&
      (itemType.contains('wire connector') ||
          itemType.contains('wire nut') ||
          itemName.contains('wire connector'))) {
    score += 24;
  }
  if (receiptSaysWinged && variant.contains('winged')) score += 28;
  if (receiptSaysWinged &&
      (itemType.contains('wire connector') ||
          itemType.contains('wire nut') ||
          itemName.contains('wire connector')) &&
      !variant.contains('winged')) {
    score -= 14;
  }
  if (receiptSaysSmartControl && itemType.contains('smart controls')) {
    score += 34;
  }
  if (receiptSaysAlarm && itemType.contains('safety and alarm')) score += 36;
  if (receiptSaysDoorbell && itemType.contains('safety and alarm')) {
    score += 32;
  }
  if (receiptSaysLedLighting &&
      (itemType.contains('lamp') ||
          itemType.contains('lighting') ||
          itemName.contains('led'))) {
    score += 44;
  }
  if (receiptSaysPhotocell && variant.contains('photocell')) score += 110;
  if (receiptSaysPhotocell && !variant.contains('photocell')) score -= 36;
  if (text.contains('shop light') && itemName.contains('shop light')) {
    score += 36;
  }
  if (text.contains('video doorbell') &&
      itemName.contains('doorbell transformer')) {
    score -= 28;
  }
  if (receiptSaysFanSupport && itemType.contains('fan and fixture')) {
    score += 38;
  }
  if (receiptSaysDeviceBox && itemName.contains('electrical box')) {
    score += 40;
    if (text.contains('old work') && itemName.contains('old work')) {
      score += 28;
    }
    if (text.contains('new work') && itemName.contains('new work')) {
      score += 28;
    }
  }
  if (receiptSaysJunctionBox && itemName.contains('junction box')) {
    score += 44;
  }
  if (receiptSaysWeatherproofCover) {
    if (itemName.contains('weatherproof')) {
      score += 72;
    } else if (itemName.contains('cover')) {
      score -= 30;
    }
    if ((text.contains('bubble cover') ||
            text.contains('extra duty') ||
            text.contains('in use') ||
            text.contains('in-use')) &&
        itemName.contains('in-use cover')) {
      score += 82;
    }
  }
  if (receiptSaysWallPlate && itemName.contains('cover plate')) {
    score += 48;
    if (text.contains('blank') && variant.contains('blank')) score += 32;
    if (!text.contains('blank') && variant.contains('blank')) score -= 36;
    if (RegExp(r'\b(1g|1 gang|single gang)\b').hasMatch(text) &&
        variant.contains('1 gang')) {
      score += 28;
    }
    if (RegExp(r'\b(wht|white)\b').hasMatch(text)) {
      if (variant.contains('white')) {
        score += 42;
      } else if (variant.contains('black') || variant.contains('brown')) {
        score -= 42;
      }
    }
  }
  if (receiptSaysWallPlate && itemName.contains('wall plate')) {
    score += 54;
    if (RegExp(r'\b(decora|decorator|decorador)\b').hasMatch(text)) {
      if (variant.contains('decorator')) {
        score += 58;
      } else if (variant.contains('blank') ||
          variant.contains('toggle') ||
          variant.contains('duplex')) {
        score -= 52;
      }
    }
    if (text.contains('blank')) {
      if (variant.contains('blank')) {
        score += 36;
      } else {
        score -= 26;
      }
    } else if (variant.contains('blank')) {
      score -= 32;
    }
  }
  if (receiptSaysBoxAccessory && itemType.contains('box accessories')) {
    score += 34;
  }
  if (RegExp(r'\b(low voltage bracket|lv bracket)\b').hasMatch(text) &&
      itemType.contains('box accessories')) {
    score += 42;
    if (itemName.contains('mud ring') || itemName.contains('box extender')) {
      score += 24;
    }
  }
  if (receiptSaysPanelAccessory && itemType.contains('panel accessories')) {
    score += 38;
  }
  if (receiptSaysServiceAccessory &&
      itemType.contains('service entrance accessories')) {
    score += 38;
  }
  for (final term in [
    'smart dimmer',
    'smart switch',
    'motion sensor',
    'occupancy sensor',
    'timer switch',
    'smoke alarm',
    'carbon monoxide',
    'doorbell transformer',
    'fan brace',
    'ceiling fan',
    'mud ring',
    'box extender',
    'ground bar',
    'neutral bar',
    'breaker filler',
    'panel schedule',
    'weatherhead',
    'service entrance',
    'bonding terminal',
  ]) {
    if (text.contains(term) && variant.contains(term)) score += 42;
  }
  return score;
}

int _plumbingReceiptScore(
  String text,
  String trade,
  String category,
  String system,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'plumbing') return score;
  if (RegExp(
    r'\b(copper|pvc|cpvc|pex|dwv|pipe|fitting|coupling|elbow|tee|valve|brass)\b',
  ).hasMatch(text)) {
    score += 12;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final receiptSaysTee = RegExp(r'\b(tee|t)\b').hasMatch(text);
  final receiptSaysCoupling = RegExp(
    r'\b(coupling|coup|cplg|coupler)\b',
  ).hasMatch(text);
  final receiptSaysPipe = RegExp(r'\b(pipe|stick)\b').hasMatch(text);
  final receiptSaysNipple = RegExp(r'\b(nipple|npt nipple)\b').hasMatch(text);
  final receiptSaysSupplyStop = RegExp(
    r'\b(supply stop|angle stop|straight stop|stop valve|shutoff|shut off)\b',
  ).hasMatch(text);
  final receiptSaysPvc = RegExp(r'\b(pvc|sch40|schedule 40)\b').hasMatch(text);
  final receiptSaysToiletRepair = RegExp(
    r'\b(toilet wax|wax ring|fill valve|flush valve|flapper|tank lever|tank bolt|toilet flange|flange repair)\b',
  ).hasMatch(text);
  final receiptSaysWaterHeaterPart = RegExp(
    r'\b(water heater|wtr htr|heater strap|restraint strap|seismic strap|earthquake strap|relief valve|t p valve|t and p valve|temperature pressure|drain valve|dielectric nipple|anode|anode rod|heating element|water heater element|thermostat)\b',
  ).hasMatch(text);
  final receiptSaysSupplyLine = RegExp(
    r'\b(supply line|faucet connector|toilet connector|closet line|lav supply|braided line|dishwasher line|icemaker line|washer hose)\b',
  ).hasMatch(text);
  final receiptSaysFaucetRepair = RegExp(
    r'\b(faucet cartridge|faucet stem|faucet repair|o ring|seat washer|aerator|pop up drain|pop-up drain|basket strainer|sink strainer)\b',
  ).hasMatch(text);
  final receiptSaysShowerTubRepair = RegExp(
    r'\b(shower cartridge|mixing valve cartridge|shower trim|tub spout|diverter spout|shower head|shower arm|tub waste|tub drain|tub stopper)\b',
  ).hasMatch(text);
  final receiptSaysPumpPart = RegExp(
    r'\b(sump pump|condensate pump|pump check valve|discharge hose|pump tubing|pump float|float switch|piggyback|high water alarm|pump alarm)\b',
  ).hasMatch(text);
  final receiptSaysDrainFinishPart = RegExp(
    r'\b(basket strainer|sink strainer|air gap|dishwasher branch|dishwasher hose|disposal flange|disposal connector|splash guard|trap adapter|marvel adapter|desanco|wall bend|trap arm|slip nut|slip washer|escutcheon|cleanout|clean out|floor drain|drain grate|closet flange repair|flange repair ring|flange spacer|closet bolt cap)\b',
  ).hasMatch(text);
  final receiptSaysSealServicePart = RegExp(
    r'\b(faucet washer|bib washer|seat washer|o ring|o-ring|oring|stem packing|valve packing|bonnet packing|packing nut|flush valve seal|tank gasket|tank to bowl|closet seal|toilet seal|hose washer|hose bibb washer|vacuum breaker|anti siphon|anti-siphon|pipe dope|thread sealant|ptfe tape|teflon tape|gas tape)\b',
  ).hasMatch(text);
  final receiptSaysSolderingConsumable = RegExp(
    r'\b(lead free solder|lf solder|plumbing solder|sweat solder|silver bearing solder|tin antimony|solder flux|plumbing flux|tinning flux|paste flux|water soluble flux|acid brush|flux brush|solder brush|fitting brush|fit brush|tube brush|sand cloth|emery cloth|abrasive cloth|heat shield|flame protector|torch shield|propane cylinder|propane bottle|propane fuel|mapp gas|map gas|map-pro|torch fuel|torch head|solder torch|plumbing torch)\b',
  ).hasMatch(text);
  if (RegExp(r'\b(cond pump|condensate pump|little pump)\b').hasMatch(text)) {
    score -= 80;
  }
  if (receiptSaysTee && itemType.contains('tee')) score += 18;
  if (receiptSaysTee && !text.contains(' x ') && item.variant.contains(' x ')) {
    score -= 24;
  }
  if (receiptSaysCoupling && itemType.contains('coupling')) score += 18;
  if (receiptSaysPipe && category == 'pipe and tubing') score += 24;
  if (receiptSaysNipple && itemType.contains('nipple')) score += 26;
  if (RegExp(r'\b(bi|black iron|black pipe)\b').hasMatch(text) &&
      receiptSaysNipple &&
      itemName.contains('black iron') &&
      itemName.contains('nipple')) {
    score += 92;
  }
  if (receiptSaysPipe && category == 'fittings') score -= 24;
  if (receiptSaysTee && itemType.contains('coupling')) score -= 22;
  if (receiptSaysCoupling && itemType.contains('tee')) score -= 22;
  if (receiptSaysNipple && itemType.contains('elbow')) score -= 18;
  if (receiptSaysPvc && text.contains('ball valve')) {
    if (itemName.contains('pvc ball valve')) {
      score += 58;
    } else if (itemName.contains('ball valve') && !itemName.contains('pvc')) {
      score -= 24;
    }
  }
  if (receiptSaysSupplyStop) {
    if (itemType.contains('supply stop') ||
        itemType.contains('stop valve') ||
        itemName.contains('supply stop') ||
        itemName.contains('stop valve')) {
      score += 64;
      if (text.contains('escutcheon') &&
          item.aliases.any(
            (alias) => _normalize(alias).contains('escutcheon'),
          )) {
        score += 86;
      }
    } else if (itemType.contains('elbow') || itemName.contains('elbow')) {
      score -= 40;
    }
  }
  if (receiptSaysToiletRepair && category == 'toilet repair') {
    score += 36;
    for (final term in [
      'wax ring',
      'fill valve',
      'flush valve',
      'flapper',
      'tank lever',
      'tank bolt',
      'toilet flange',
      'flange repair',
    ]) {
      if (text.contains(term) && itemName.contains(term)) score += 48;
    }
  }
  if (receiptSaysSupplyLine && category == 'supply lines') {
    score += 42;
    for (final term in [
      'faucet supply line',
      'toilet supply line',
      'appliance supply line',
      'gas appliance connector',
    ]) {
      if (itemName.contains(term)) score += 18;
    }
    for (final term in [
      'faucet connector',
      'toilet connector',
      'closet line',
      'lav supply',
      'dishwasher line',
      'icemaker line',
      'washer hose',
      'gas connector',
    ]) {
      if (text.contains(term) &&
          item.aliases.any((alias) => _normalize(alias).contains(term))) {
        score += 42;
      }
    }
  }
  if (receiptSaysFaucetRepair && category == 'sink and faucet repair') {
    score += 42;
    for (final term in [
      'faucet cartridge',
      'faucet stem',
      'faucet o-ring',
      'faucet aerator',
      'lavatory pop-up assembly',
      'kitchen sink basket strainer',
    ]) {
      if (itemName.contains(term)) score += 24;
    }
    for (final term in [
      'pop up drain',
      'pop-up drain',
      'basket strainer',
      'sink strainer',
      'aerator',
      'faucet stem',
      'faucet cartridge',
    ]) {
      if (text.contains(term) &&
          (itemName.contains(term.replaceAll('pop-up', 'pop-up')) ||
              item.aliases.any((alias) => _normalize(alias).contains(term)))) {
        score += 46;
      }
    }
  }
  if (receiptSaysShowerTubRepair && category == 'shower and tub repair') {
    score += 42;
    for (final term in [
      'shower cartridge',
      'shower valve trim kit',
      'tub spout',
      'shower head',
      'shower arm',
      'tub waste and overflow kit',
      'tub drain stopper',
    ]) {
      if (itemName.contains(term)) score += 28;
    }
    for (final term in [
      'mixing valve cartridge',
      'diverter spout',
      'showerhead',
      'tub drain kit',
      'tub stopper',
    ]) {
      if (text.contains(term) &&
          item.aliases.any((alias) => _normalize(alias).contains(term))) {
        score += 46;
      }
    }
  }
  if (receiptSaysDrainFinishPart &&
      category == 'drain and finish service stock') {
    score += 46;
    if (receiptSaysSupplyStop) score -= 68;
    for (final term in [
      'basket strainer',
      'sink strainer',
      'air gap',
      'dishwasher branch',
      'dishwasher hose',
      'disposal connector',
      'disposal flange',
      'splash guard',
      'trap adapter',
      'marvel adapter',
      'desanco',
      'wall bend',
      'trap arm',
      'slip nut',
      'slip washer',
      'escutcheon',
      'cleanout',
      'clean out',
      'floor drain',
      'drain grate',
      'flange repair',
      'flange spacer',
      'closet bolt',
    ]) {
      if (text.contains(term) &&
          (itemName.contains(term) ||
              item.aliases.any((alias) => _normalize(alias).contains(term)))) {
        score += 56;
      }
    }
    if (text.contains('clean out') && itemName.contains('cleanout')) {
      score += 44;
    }
    if (text.contains('closet flange repair') &&
        itemName.contains('closet flange repair')) {
      score += 58;
    }
    if (text.contains('dishwasher branch') &&
        itemName.contains('dishwasher branch')) {
      score += 58;
    }
    if (text.contains('floor drain') && itemName.contains('floor drain')) {
      score += 50;
    }
  }
  if (receiptSaysSealServicePart &&
      category == 'seals packing and thread service') {
    score += 48;
    for (final term in [
      'faucet washer',
      'bib washer',
      'seat washer',
      'o ring',
      'o-ring',
      'stem packing',
      'valve packing',
      'bonnet packing',
      'packing nut',
      'flush valve seal',
      'tank gasket',
      'tank to bowl',
      'closet seal',
      'toilet seal',
      'hose washer',
      'hose bibb washer',
      'vacuum breaker',
      'anti siphon',
      'anti-siphon',
      'pipe dope',
      'thread sealant',
      'ptfe tape',
      'teflon tape',
      'gas tape',
    ]) {
      if (text.contains(term) &&
          (itemName.contains(term.replaceAll('o ring', 'o-ring')) ||
              itemName.contains(term.replaceAll('teflon', 'ptfe')) ||
              item.aliases.any((alias) => _normalize(alias).contains(term)))) {
        score += 58;
      }
    }
    if (text.contains('pipe dope') &&
        itemName.contains('pipe joint compound')) {
      score += 66;
    }
    if (text.contains('teflon tape') && itemName.contains('ptfe tape')) {
      score += 66;
    }
    if (text.contains('vacuum breaker') &&
        itemName.contains('vacuum breaker')) {
      score += 62;
    }
    if (text.contains('hose bibb') && itemName.contains('hose bibb')) {
      score += 52;
    }
  }
  if (receiptSaysSolderingConsumable &&
      system == 'copper soldering consumables') {
    score += 72;
    for (final term in [
      'lead-free plumbing solder',
      'water soluble flux',
      'acid brush',
      'copper fitting brush',
      'plumber sand cloth',
      'soldering heat shield',
      'propane torch fuel',
      'map-pro torch fuel',
      'soldering torch head',
    ]) {
      if (itemName.contains(term)) score += 18;
    }
    for (final term in [
      'lead free solder',
      'lf solder',
      'plumbing solder',
      'sweat solder',
      'silver bearing solder',
      'tin antimony',
      'solder flux',
      'plumbing flux',
      'tinning flux',
      'paste flux',
      'water soluble flux',
      'acid brush',
      'flux brush',
      'solder brush',
      'fitting brush',
      'fit brush',
      'tube brush',
      'sand cloth',
      'emery cloth',
      'abrasive cloth',
      'heat shield',
      'flame protector',
      'torch shield',
      'propane cylinder',
      'propane bottle',
      'propane fuel',
      'mapp gas',
      'map gas',
      'map-pro',
      'torch head',
      'solder torch',
      'plumbing torch',
    ]) {
      if (text.contains(term) &&
          (itemName.contains(term.replaceAll('lead free', 'lead-free')) ||
              item.aliases.any((alias) => _normalize(alias).contains(term)))) {
        score += 64;
      }
    }
    if (RegExp(r'\b(paint|electrical|hvac|refrigerant)\b').hasMatch(text)) {
      score -= 42;
    }
    if (RegExp(
      r'\b(ma[pb]{1,2}[-\s]*pro|ma[pb]{1,2}\s+gas|map\s+gas)\b',
    ).hasMatch(text)) {
      if (itemName.contains('map-pro torch fuel')) {
        score += 120;
      } else if (itemName.contains('propane torch fuel')) {
        score -= 90;
      }
    }
    if (RegExp(r'\b(propane|lp\s+fuel|propane\s+cylinder)\b').hasMatch(text)) {
      if (itemName.contains('propane torch fuel')) {
        score += 90;
      } else if (itemName.contains('map-pro torch fuel')) {
        score -= 70;
      }
    }
  } else if (receiptSaysSolderingConsumable &&
      category != 'consumables' &&
      !itemName.contains('solder') &&
      !itemName.contains('flux')) {
    score -= 18;
  }
  final isWaterHeaterItem =
      category == 'water heater' || itemName.contains('water heater');
  final isPumpItem = category == 'pumps' || itemName.contains('pump');
  if (receiptSaysWaterHeaterPart && isWaterHeaterItem) {
    score += 38;
    if (RegExp(r'\b(anode|anode rod)\b').hasMatch(text)) {
      if (itemName.contains('water heater repair part') ||
          item.aliases.any((alias) => _normalize(alias).contains('anode'))) {
        score += 180;
      } else if (itemName.contains('relief valve') ||
          itemName.contains('drain valve') ||
          itemName.contains('dielectric')) {
        score -= 54;
      }
    }
    if (RegExp(
      r'\b(heating element|water heater element|element)\b',
    ).hasMatch(text)) {
      if (itemName.contains('water heater repair part') ||
          item.aliases.any((alias) => _normalize(alias).contains('element'))) {
        score += 160;
      } else if (itemName.contains('relief valve') ||
          itemName.contains('drain valve') ||
          itemName.contains('dielectric')) {
        score -= 42;
      }
    }
    if (text.contains('thermostat') &&
        (itemName.contains('water heater repair part') ||
            item.aliases.any(
              (alias) => _normalize(alias).contains('thermostat'),
            ))) {
      score += 72;
    }
    if (RegExp(
          r'\b(relief valve|t p valve|t and p valve|temperature pressure)\b',
        ).hasMatch(text) &&
        itemName.contains('relief valve')) {
      score += 72;
    }
    if (text.contains('drain valve') && itemName.contains('drain valve')) {
      score += 48;
    }
    if (text.contains('dielectric') && itemName.contains('dielectric')) {
      score += 48;
    }
    if (RegExp(
          r'\b(heater strap|restraint strap|seismic strap|earthquake strap|wtr htr strap)\b',
        ).hasMatch(text)) {
      if (itemName.contains('water heater restraint strap') ||
          item.aliases.any(
            (alias) => _normalize(alias).contains('heater strap'),
          ) ||
          item.aliases.any(
            (alias) => _normalize(alias).contains('restraint strap'),
          )) {
        score += 140;
      } else if (itemName.contains('pipe strap')) {
        score -= 72;
      }
    }
  }
  if (receiptSaysPumpPart && isPumpItem) {
    score += 36;
    if (text.contains('pump check valve')) {
      if (itemName.contains('pump check valve')) {
        score += 140;
      } else if (!itemName.contains('check valve')) {
        score -= 44;
      }
    }
    if (RegExp(r'\b(float switch|piggyback|pump float)\b').hasMatch(text)) {
      if (itemName.contains('pump control part') ||
          item.aliases.any((alias) => _normalize(alias).contains('float'))) {
        score += 92;
      } else if (itemName.contains('sump pump')) {
        score -= 40;
      }
    }
    if (RegExp(r'\b(high water alarm|pump alarm)\b').hasMatch(text)) {
      if (itemName.contains('pump control part') ||
          item.aliases.any((alias) => _normalize(alias).contains('alarm'))) {
        score += 96;
      } else if (itemName.contains('sump pump')) {
        score -= 42;
      }
    }
    for (final term in [
      'sump pump',
      'condensate pump',
      'pump check valve',
      'discharge hose',
      'pump tubing',
      'float switch',
    ]) {
      if (text.contains(term) && itemName.contains(term)) score += 48;
    }
  }
  if (system == 'brass') {
    if (text.contains('compression') && itemType.contains('compression')) {
      score += 18;
    }
    if (text.contains('flare') && itemType.contains('flare')) score += 18;
    if (text.contains('barb') && itemType.contains('barb')) score += 18;
    if (text.contains('union') && itemType.contains('union')) score += 18;
  }
  if (RegExp(
    r'\b(stud|lumber|kd|wood|romex|gfci|emt|conduit)\b',
  ).hasMatch(text)) {
    score -= 18;
  }
  return score;
}

int _hvacReceiptScore(String text, String trade, WorkSupplyItem item) {
  var score = 0;
  if (trade != 'hvac') return score;
  if (text.contains('retaining wall')) {
    score -= 40;
  }
  if (RegExp(
    r'\b(capacitor|mfd|uf|run cap|pleated|filter|furnace filter|ac filter|filter rack|return grille|foil tape|hvac tape|mastic|duct|condensate|drain pan|thermostat|contactor|line set|line hide|mini split|register|grille|boot|takeoff|b vent|flue|ignitor|flame sensor|coil cleaner|zone damper|duct board|plenum|dryer vent|vacuum pump|manifold gauge|micron gauge|ac disconnect|ac whip|equipment pad|limit switch|rollout switch|condenser|heat pump|evaporator coil|evap coil|gas furnace|air handler|heat kit|package unit|rooftop unit|economizer|crankcase heater)\b',
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
  if (RegExp(
    r'\b(ac condenser|condensing unit|heat pump condenser|side discharge heat pump|inverter condenser|evaporator coil|evap coil|cased coil|uncased coil|gas furnace|air handler|electric heat kit|mini split|package unit|rooftop unit|roof curb|economizer|fresh air damper|condenser fan guard|crankcase heater|low ambient kit)\b',
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
    if (!RegExp(r'\b(12\s*pack|pack|case|carton|ct)\b').hasMatch(text) &&
        RegExp(r'\b(12\s*pack|case stock|filter case)\b').hasMatch(itemName)) {
      score -= 84;
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
  if (RegExp(r'\b(flex duct|insulated flex)\b').hasMatch(text)) {
    if (itemName.contains('flex duct')) {
      score += 90;
    } else if (itemName.contains('duct elbow') ||
        itemName.contains('duct coupling') ||
        itemName.contains('round duct')) {
      score -= 42;
    }
    for (final size in ['4 in', '5 in', '6 in', '7 in', '8 in', '10 in']) {
      final compact = size.replaceAll(' ', '');
      if ((text.contains(size) || text.contains(compact)) &&
          itemName.contains(size)) {
        score += 34;
      }
    }
    for (final rating in ['r6', 'r8']) {
      if (text.contains(rating) && itemName.contains(rating)) {
        score += 46;
      } else if (text.contains(rating) &&
          itemName.contains('flex duct') &&
          !itemName.contains(rating)) {
        score -= 22;
      }
    }
  }
  if (RegExp(r'\b(spin in|spin-in|takeoff)\b').hasMatch(text)) {
    if (itemName.contains('takeoff')) {
      score += 54;
    }
    if (text.contains('with damper') &&
        itemName.contains('takeoff with damper')) {
      score += 86;
    } else if (text.contains('with damper') &&
        itemName.contains('takeoff') &&
        !itemName.contains('with damper')) {
      score -= 34;
    }
  }
  if (RegExp(r'\b(galvanized sheet metal|sheet metal)\b').hasMatch(text)) {
    if (itemName.contains('galvanized sheet metal')) {
      score += 112;
    } else if (itemName.contains('elbow') ||
        itemName.contains('round duct') ||
        itemName.contains('takeoff')) {
      score -= 50;
    }
    for (final size in ['12 x 24', '24 x 24', '24 x 36', '36 x 48']) {
      final compact = size.replaceAll(' ', '');
      if ((text.contains(size) || text.contains(compact)) &&
          itemName.contains(size)) {
        score += 52;
      }
    }
  }
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
  if (RegExp(
        r'\b(register|grille|vent cover|wall stack boot)\b',
      ).hasMatch(text) &&
      itemType.contains('boots')) {
    score += 24;
  }
  if (text.contains('register boot')) {
    if (itemName.contains('register boot')) {
      score += 70;
    }
    for (final style in ['straight', 'end']) {
      if (text.contains(style) && itemName.contains(style)) {
        score += 54;
      } else if (text.contains(style) &&
          itemName.contains('register boot') &&
          !itemName.contains(style)) {
        score -= 20;
      }
    }
  }
  if (text.contains('manual balancing damper')) {
    if (itemName.contains('manual balancing damper')) {
      score += 110;
    } else if (itemName.contains('duct reducer') ||
        itemName.contains('round duct')) {
      score -= 48;
    }
  }
  if (text.contains('ul181') && text.contains('foil tape')) {
    if (itemName.contains('ul181 foil tape')) {
      score += 110;
    } else if (itemName.contains('foil hvac tape')) {
      score -= 46;
    }
  }
  if (RegExp(r'\b(sediment trap|drip leg)\b').hasMatch(text)) {
    if (itemName.contains('sediment trap') || itemName.contains('drip leg')) {
      score += 116;
    }
    if (itemName.contains('black iron') && !itemName.contains('sediment')) {
      score -= 36;
    }
  }
  if (text.contains('gas appliance connector') ||
      text.contains('gas flex connector')) {
    if (itemName.contains('gas appliance connector')) {
      score += 118;
    } else if (itemName.contains('gas connector') ||
        itemName.contains('gas range connector')) {
      score += 32;
    } else if (itemName.contains('connector')) {
      score -= 20;
    }
    for (final size in ['1/2 in', '3/4 in']) {
      final compact = size.replaceAll(' ', '');
      if ((text.contains(size) || text.contains(compact)) &&
          itemName.contains(size)) {
        score += 38;
      } else if ((text.contains(size) || text.contains(compact)) &&
          itemName.contains('gas appliance connector') &&
          !itemName.contains(size)) {
        score -= 18;
      }
    }
    for (final length in ['24 in', '36 in', '48 in', '60 in']) {
      final compact = length.replaceAll(' ', '');
      if ((text.contains(length) || text.contains(compact)) &&
          itemName.contains(length)) {
        score += 46;
      } else if ((text.contains(length) || text.contains(compact)) &&
          itemName.contains('gas appliance connector') &&
          !itemName.contains(length)) {
        score -= 20;
      }
    }
  }
  if (RegExp(r'\b(bath fan wall cap|bath fan roof jack)\b').hasMatch(text)) {
    if (itemName.contains('bath fan wall cap') ||
        itemName.contains('bath fan roof jack')) {
      score += 116;
    } else if (itemName.contains('wall cap') || itemName.contains('roof cap')) {
      score -= 38;
    }
  }
  if (RegExp(
        r'\b(register boot|duct boot|spin in|spin-in|takeoff|start collar|round reducer|round wye)\b',
      ).hasMatch(text) &&
      itemType.contains('duct boots')) {
    score += 34;
  }
  if (RegExp(
    r'\b(round duct|duct pipe|sheet metal|manual damper|backdraft damper|start collar|takeoff collar|spin in|spin-in|round reducer|round wye|round tee)\b',
  ).hasMatch(text)) {
    if (itemName.contains('round duct') ||
        itemName.contains('duct pipe') ||
        itemName.contains('manual damper') ||
        itemName.contains('backdraft damper') ||
        itemName.contains('start collar') ||
        itemName.contains('takeoff') ||
        itemName.contains('round reducer') ||
        itemName.contains('round wye') ||
        itemName.contains('round tee')) {
      score += 44;
    }
    for (final item in [
      'manual damper',
      'backdraft damper',
      'start collar',
      'takeoff collar',
      'spin in takeoff',
      'round reducer',
      'round wye',
      'round tee',
      'adjustable elbow',
    ]) {
      if (text.contains(item) && itemName.contains(item)) {
        score += 70;
      } else if (text.contains(item) &&
          (itemName.contains('duct') ||
              itemName.contains('damper') ||
              itemName.contains('elbow') ||
              itemName.contains('collar')) &&
          !itemName.contains(item)) {
        score -= 28;
      }
    }
    for (final size in [
      '3 in',
      '4 in',
      '5 in',
      '6 in',
      '7 in',
      '8 in',
      '9 in',
      '10 in',
      '12 in',
      '14 in',
      '16 in',
      '18 in',
    ]) {
      final compact = size.replaceAll(' ', '');
      if ((text.contains(size) || text.contains(compact)) &&
          itemName.contains(size)) {
        score += 28;
      }
    }
    for (final gauge in ['26 gauge', '28 gauge', '30 gauge']) {
      final compact = gauge.replaceAll('uge', '').replaceAll(' ', '');
      if ((text.contains(gauge) || text.contains(compact)) &&
          itemName.contains(gauge)) {
        score += 30;
      }
    }
  }
  if (RegExp(
        r'\b(b vent|b-vent|gas vent|flue pipe|draft hood|wall cap|roof cap|backdraft damper|galvanized pipe)\b',
      ).hasMatch(text) &&
      itemType.contains('duct pipe')) {
    score += 34;
  }
  if (text.contains('dryer vent hood')) {
    if (itemName.contains('dryer vent hood')) {
      score += 90;
    } else if (itemName.contains('dryer')) {
      score += 20;
    }
  }
  if (RegExp(
    r'\b(b vent|b-vent|gas vent|flue pipe|draft hood|storm collar|wall thimble)\b',
  ).hasMatch(text)) {
    if (itemName.contains('b vent') ||
        itemName.contains('gas vent') ||
        itemName.contains('flue pipe') ||
        itemName.contains('draft hood')) {
      score += 38;
    }
    for (final part in [
      'b vent adjustable elbow',
      'b vent 90 elbow',
      'b vent pipe',
      'b vent tee',
      'b vent cap',
      'b vent storm collar',
      'b vent wall thimble',
      'draft hood connector',
      'single wall flue pipe',
    ]) {
      if (text.contains(part) && itemName.contains(part)) {
        score += 82;
      } else if (text.contains(part) &&
          (itemName.contains('b vent') ||
              itemName.contains('flue pipe') ||
              itemName.contains('draft hood')) &&
          !itemName.contains(part)) {
        score -= 32;
      }
    }
  }
  if (RegExp(
        r'\b(zone damper|zoning panel|humidifier pad|uv lamp|air cleaner)\b',
      ).hasMatch(text) &&
      itemType.contains('zoning')) {
    score += 26;
  }
  if (RegExp(
    r'\b(zone damper|round zone damper|bypass damper|motorized round damper|zone control panel|zone panel|damper motor)\b',
  ).hasMatch(text)) {
    if (itemName.contains('zone damper') ||
        itemName.contains('bypass damper') ||
        itemName.contains('motorized round damper') ||
        itemName.contains('zone control panel') ||
        itemName.contains('damper motor')) {
      score += 64;
    } else if (itemName.contains('duct') || itemName.contains('elbow')) {
      score -= 38;
    }
    for (final part in [
      'round zone damper',
      'bypass damper',
      'motorized round damper',
      'zone control panel',
      'zone damper motor',
    ]) {
      if (text.contains(part) && itemName.contains(part)) {
        score += 84;
      } else if (text.contains(part) &&
          (itemName.contains('damper') || itemName.contains('zone')) &&
          !itemName.contains(part)) {
        score -= 24;
      }
    }
    for (final size in ['6 in', '8 in', '10 in', '12 in', '14 in', '16 in']) {
      final compact = size.replaceAll(' ', '');
      if ((text.contains(size) || text.contains(compact)) &&
          itemName.contains(size)) {
        score += 30;
      }
    }
    for (final voltage in ['24v', '120v']) {
      if (text.contains(voltage) && itemName.contains(voltage)) {
        score += 28;
      }
    }
  }
  if (RegExp(
        r'\b(duct board|supply plenum|return plenum|return box|duct transition|takeoff damper)\b',
      ).hasMatch(text) &&
      itemType.contains('duct board')) {
    score += 26;
  }
  if (RegExp(
    r'\b(supply plenum|return plenum|return air box|filter box|duct transition|square to round transition)\b',
  ).hasMatch(text)) {
    if (itemName.contains('plenum') ||
        itemName.contains('return air box') ||
        itemName.contains('filter box') ||
        itemName.contains('transition')) {
      score += 38;
    }
    for (final term in [
      'supply plenum',
      'return plenum',
      'return air box',
      'filter box',
      'duct transition',
      'square to round transition',
    ]) {
      if (text.contains(term) && itemName.contains(term)) {
        score += 76;
      } else if (text.contains(term) &&
          (itemName.contains('plenum') ||
              itemName.contains('box') ||
              itemName.contains('transition')) &&
          !itemName.contains(term)) {
        score -= 36;
      }
    }
    for (final size in [
      '16 x 16 x 24',
      '16 x 20 x 24',
      '18 x 18 x 24',
      '20 x 20 x 24',
      '20 x 25 x 24',
      '24 x 24 x 24',
      '16 x 16 x 30',
      '16 x 20 x 30',
      '18 x 18 x 30',
      '20 x 20 x 30',
      '20 x 25 x 30',
      '24 x 24 x 30',
      '16 x 16 x 36',
      '16 x 20 x 36',
      '18 x 18 x 36',
      '20 x 20 x 36',
      '20 x 25 x 36',
      '24 x 24 x 36',
      '16 x 16 x 48',
      '16 x 20 x 48',
      '18 x 18 x 48',
      '20 x 20 x 48',
      '20 x 25 x 48',
      '24 x 24 x 48',
    ]) {
      final compact = size.replaceAll(' ', '');
      if ((text.contains(size) || text.contains(compact)) &&
          itemName.contains(size)) {
        score += 46;
      }
    }
  }
  if (RegExp(
        r'\b(dryer vent|dryer duct|vent hood|bath fan|exhaust duct)\b',
      ).hasMatch(text) &&
      itemType.contains('dryer vent')) {
    score += 26;
  }
  if (RegExp(
        r'\b(manifold gauge|gauge set|refrigerant scale|charging scale|vacuum pump|micron gauge|core removal|flaring tool|tubing cutter|recovery tank)\b',
      ).hasMatch(text) &&
      itemType.contains('vacuum')) {
    score += 26;
  }
  if (RegExp(
    r'\b(clamp meter|multimeter|manometer|psychrometer|temperature clamp|pipe clamp thermometer|infrared thermometer|static pressure|combustion analyzer|carbon monoxide|co meter)\b',
  ).hasMatch(text)) {
    if (itemType.contains('meters') ||
        itemName.contains('meter') ||
        itemName.contains('manometer') ||
        itemName.contains('psychrometer') ||
        itemName.contains('thermometer') ||
        itemName.contains('test instrument')) {
      score += 64;
    } else if (itemName.contains('gauge') || itemName.contains('tool')) {
      score += 12;
    }
    for (final tool in [
      'clamp meter',
      'true rms multimeter',
      'dual port manometer',
      'digital psychrometer',
      'temperature clamp probe',
      'pipe clamp thermometer',
      'infrared thermometer',
      'static pressure tip',
      'combustion analyzer',
      'carbon monoxide meter',
    ]) {
      if (text.contains(tool) && itemName.contains(tool)) {
        score += 86;
      } else if (text.contains(tool) &&
          itemName.contains('hvac test instrument') &&
          !itemName.contains(tool)) {
        score -= 24;
      }
    }
  }
  if (RegExp(
    r'\b(leak detector|refrigerant leak detector|uv dye|dye injector|bubble leak|nylog|schrader core|service cap)\b',
  ).hasMatch(text)) {
    if (itemName.contains('leak detector') ||
        itemName.contains('uv leak') ||
        itemName.contains('uv dye') ||
        itemName.contains('nylog') ||
        itemName.contains('schrader') ||
        itemName.contains('service cap')) {
      score += 70;
    } else if (itemName.contains('hvac leak detection')) {
      score += 24;
    }
    for (final item in [
      'electronic refrigerant leak detector',
      'uv leak detection dye cartridge',
      'uv dye injector hose',
      'bubble leak detector spray',
      'nylog blue thread sealant',
      'schrader core assortment',
      'low side service cap',
      'high side service cap',
    ]) {
      if (text.contains(item) && itemName.contains(item)) {
        score += 88;
      } else if (text.contains(item) &&
          itemName.contains('hvac leak detection') &&
          !itemName.contains(item)) {
        score -= 22;
      }
    }
  }
  if (RegExp(
    r'\b(boiler|hydronic|circulator|circ pump|zone valve|aquastat|low water cutoff|expansion tank|air vent|coin vent|backflow preventer|pressure reducing|fill valve|air separator)\b',
  ).hasMatch(text)) {
    if (itemName.contains('hydronic') ||
        itemName.contains('boiler') ||
        itemName.contains('circulator') ||
        itemName.contains('zone valve') ||
        itemName.contains('aquastat') ||
        itemName.contains('expansion tank') ||
        itemName.contains('air vent') ||
        itemName.contains('backflow preventer') ||
        itemName.contains('pressure reducing')) {
      score += 62;
    } else if (item.trade == 'Plumbing' && text.contains('boiler')) {
      score -= 18;
    }
    for (final item in [
      'universal circulator pump',
      'zone valve power head',
      'aquastat temperature control',
      'low water cutoff control',
      'hydronic expansion tank',
      'automatic air vent',
      'pressure relief valve 30 psi',
      'pressure reducing fill valve',
      'microbubble air separator',
    ]) {
      if (text.contains(item) && itemName.contains(item)) {
        score += 88;
      } else if (text.contains(item) &&
          (itemName.contains('hydronic') || itemName.contains('boiler')) &&
          !itemName.contains(item)) {
        score -= 24;
      }
    }
  }
  if (RegExp(
    r'\b(baseboard heat|baseboard element|baseboard cover|baseboard end cap|radiator air vent|radiator valve|radiant heat|radiant manifold|oxygen barrier pex)\b',
  ).hasMatch(text)) {
    if (itemName.contains('baseboard') ||
        itemName.contains('radiator') ||
        itemName.contains('radiant')) {
      score += 64;
    }
    for (final item in [
      'baseboard heating element',
      'baseboard enclosure front cover',
      'baseboard end cap',
      'radiator air vent',
      'radiant manifold flow meter',
      'radiant manifold actuator',
      'oxygen barrier pex coupling',
    ]) {
      if (text.contains(item) && itemName.contains(item)) {
        score += 82;
      } else if (text.contains(item) &&
          (itemName.contains('baseboard') ||
              itemName.contains('radiator') ||
              itemName.contains('radiant')) &&
          !itemName.contains(item)) {
        score -= 22;
      }
    }
  }
  if (RegExp(
    r'\b(rooftop unit|rtu|package unit|blower belt|cogged belt|hail guard|panel screw|door latch|crankcase heater|phase monitor)\b',
  ).hasMatch(text)) {
    if (itemName.contains('rooftop unit') ||
        itemName.contains('package unit') ||
        itemName.contains('blower belt') ||
        itemName.contains('crankcase heater') ||
        itemName.contains('phase monitor') ||
        itemName.contains('hail guard')) {
      score += 62;
    }
    for (final belt in [
      'a28',
      'a30',
      'a32',
      'a34',
      'a36',
      'a38',
      'a40',
      'a42',
      'b34',
      'b36',
      'b38',
      'b40',
      'b42',
      'b44',
      'bx38',
      'bx40',
      'bx42',
      'bx44',
    ]) {
      if (text.contains(belt) &&
          itemName.contains('$belt cogged blower belt')) {
        score += 94;
      } else if (text.contains(belt) &&
          itemName.contains('blower belt') &&
          !itemName.contains(belt)) {
        score -= 24;
      }
    }
    for (final item in [
      'rooftop unit hail guard panel',
      'rtu condensate drain trap kit',
      'package unit fan relay',
      'rtu time delay relay',
      'crankcase heater',
      'rtu phase monitor',
      'compressor terminal repair kit',
    ]) {
      if (text.contains(item) && itemName.contains(item)) {
        score += 84;
      } else if (text.contains(item) &&
          (itemName.contains('rooftop unit') ||
              itemName.contains('package unit') ||
              itemName.contains('rtu')) &&
          !itemName.contains(item)) {
        score -= 22;
      }
    }
  }
  if (RegExp(
    r'\b(economizer|enthalpy sensor|mixed air sensor|outdoor air sensor|return air sensor|damper actuator|damper linkage|minimum position|barometric relief|fresh air hood)\b',
  ).hasMatch(text)) {
    if (itemName.contains('economizer') ||
        itemName.contains('enthalpy sensor') ||
        itemName.contains('mixed air sensor') ||
        itemName.contains('outdoor air sensor') ||
        itemName.contains('return air sensor') ||
        itemName.contains('damper actuator') ||
        itemName.contains('barometric relief') ||
        itemName.contains('fresh air hood')) {
      score += 68;
    }
    for (final item in [
      'economizer logic module',
      'economizer enthalpy sensor',
      'economizer mixed air sensor',
      'economizer outdoor air sensor',
      'economizer damper linkage kit',
      'barometric relief damper',
      'fresh air hood filter',
    ]) {
      if (text.contains(item) && itemName.contains(item)) {
        score += 88;
      } else if (text.contains(item) &&
          itemName.contains('economizer') &&
          !itemName.contains(item)) {
        score -= 24;
      }
    }
  }
  if (RegExp(
        r'\b(ac disconnect|disconnect box|ac whip|liquid tight|surge protector)\b',
      ).hasMatch(text) &&
      itemType.contains('electrical install')) {
    score += 26;
  }
  if (RegExp(
        r'\b(ignitor|hsi|flame sensor|flame rod|pressure switch)\b',
      ).hasMatch(text) &&
      itemType.contains('ignition')) {
    score += 26;
  }
  if (RegExp(
        r'\b(pressure switch tubing|door switch|rollout switch|limit switch|inducer gasket|ignitor wire harness)\b',
      ).hasMatch(text) &&
      itemType.contains('furnace service switches')) {
    score += 34;
  }
  if (RegExp(
    r'\b(coil cleaner|evap cleaner|evaporator cleaner|condenser cleaner|no rinse cleaner|pan tablets|pan strips|drain line cleaner|uv dye|fin comb|coil brush)\b',
  ).hasMatch(text)) {
    if (itemType.contains('coil cleaners') ||
        itemName.contains('coil cleaner') ||
        itemName.contains('evaporator cleaner') ||
        itemName.contains('condenser cleaner') ||
        itemName.contains('drain line cleaner') ||
        itemName.contains('pan tablet') ||
        itemName.contains('fin comb') ||
        itemName.contains('coil brush')) {
      score += 42;
    }
    for (final item in [
      'foaming evaporator coil cleaner',
      'condenser coil cleaner',
      'no rinse evaporator cleaner',
      'drain line cleaner',
      'condensate pan tablet',
      'fin comb',
      'coil brush',
    ]) {
      if (text.contains(item) && itemName.contains(item)) {
        score += 78;
      } else if (text.contains(item) &&
          itemName.contains('hvac cleaning supply') &&
          !itemName.contains(item)) {
        score -= 18;
      }
    }
  }
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
