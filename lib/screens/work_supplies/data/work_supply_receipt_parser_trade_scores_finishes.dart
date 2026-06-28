part of 'work_supply_receipt_parser.dart';

int _drywallReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'drywall') return score;
  if (RegExp(
    r'\b(drywall|sheetrock|gypsum|joint compound|mud|hot mud|easy sand|corner bead|mesh tape|spackle|access panel|access door|tear away bead|control joint|reveal bead|shadow bead|dust barrier|zip door|drywall lift|mud pan|taping knife|texture hopper|pole sander|texture repair|ceiling grid|cross tee|main runner|ceiling tile|metal stud|steel stud|metal track|hat channel|resilient channel|hanger wire|rc clip|sound isolation)\b',
  ).hasMatch(text)) {
    score += 16;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final variant = item.variant.toLowerCase();
  final receiptSaysDrywallBoard = RegExp(
    r'\b(sheetrock|gypsum|wall board|drywall board|drywall sheet|mold resist|moisture resist)\b',
  ).hasMatch(text);
  if (RegExp(r'\b(screw setter|setter bit)\b').hasMatch(text)) {
    score -= 64;
  }
  if (RegExp(r'\b(sheetrock|gypsum|drywall sheet|board)\b').hasMatch(text) &&
      category == 'panels and board') {
    score += 24;
  }
  if (receiptSaysDrywallBoard &&
      (category == 'panels and board' ||
          itemType.contains('board') ||
          itemName.contains('drywall board'))) {
    score += 34;
  }
  if (text.contains('mold resist') && variant.contains('mold resistant')) {
    score += 22;
  }
  if (text.contains('moisture resist') &&
      variant.contains('moisture resistant')) {
    score += 22;
  }
  for (final face in [
    'regular',
    'lightweight',
    'mold resistant',
    'fire rated',
    'type x',
    'abuse resistant',
  ]) {
    final receiptFace = face == 'mold resistant' ? 'mold resist' : face;
    if (text.contains(receiptFace) &&
        (variant.contains(face) || itemName.contains(face))) {
      score += 44;
    } else if (text.contains(receiptFace) &&
        itemName.contains('drywall') &&
        !(variant.contains(face) || itemName.contains(face))) {
      score -= 18;
    }
  }
  if (RegExp(r'\b(joint compound|drywall mud|mud|plus 3)\b').hasMatch(text) &&
      (itemType.contains('joint compound') ||
          itemName.contains('joint compound') ||
          itemName.contains('premixed'))) {
    score += 24;
  }
  if (text.contains('plus 3') && variant.contains('plus 3')) {
    score += 44;
  }
  if (text.contains('plus 3') &&
      itemType.contains('joint compound') &&
      !variant.contains('plus 3')) {
    score -= 12;
  }
  if (RegExp(r'\b(hot mud|easy sand|quick set|setting)\b').hasMatch(text) &&
      itemType.contains('setting')) {
    score += 24;
  }
  if (RegExp(r'\b(corner bead|j bead|edge bead)\b').hasMatch(text) &&
      itemType.contains('bead')) {
    score += 22;
  }
  if (RegExp(
        r'\b(access panel|access door|fire rated access|tear away bead|tearaway bead|control joint|no coat|shadow bead|reveal bead|expansion bead|bullnose adapter)\b',
      ).hasMatch(text) &&
      itemType.contains('access panels')) {
    score += 28;
  }
  if (RegExp(
        r'\b(reveal bead|expansion bead|bullnose adapter|splayed corner|three-way corner|outside corner cap)\b',
      ).hasMatch(text) &&
      itemType.contains('drywall reveal')) {
    score += 34;
  }
  for (final bead in [
    'shadow bead',
    'reveal bead',
    'control joint',
    'tear away bead',
    'j bead',
    'l bead',
    'bullnose corner bead',
  ]) {
    if (text.contains(bead) &&
        (variant.contains(bead) || itemName.contains(bead))) {
      score += 62;
    } else if (text.contains(bead) &&
        itemName.contains('bead') &&
        !(variant.contains(bead) || itemName.contains(bead))) {
      score -= 22;
    }
  }
  if (RegExp(r'\b(concrete|slab|masonry|zip strip)\b').hasMatch(text) &&
      text.contains('control joint') &&
      trade == 'drywall') {
    score -= 70;
  }
  if (text.contains('shadow bead')) {
    if (itemName.contains('shadow bead')) {
      score += 110;
    }
    if (itemName.contains('reveal bead') ||
        itemName.contains('control joint') ||
        itemName.contains('tear away bead')) {
      score -= 90;
    }
  }
  if (RegExp(
    r'\b(bullnose three-way corner cap|bullnose outside corner cap|bullnose adapter|reveal bead)\b',
  ).hasMatch(text)) {
    if (itemName.contains('bullnose') ||
        itemName.contains('reveal bead') ||
        itemType.contains('drywall reveal')) {
      score += 70;
    }
  }
  if (RegExp(
        r'\b(access door|fire rated access panel|flush access panel)\b',
      ).hasMatch(text) &&
      itemType.contains('access doors')) {
    score += 34;
  }
  if (RegExp(r'\b(joint tape|mesh tape|paper tape)\b').hasMatch(text) &&
      itemType.contains('tape')) {
    score += 34;
  }
  if (RegExp(r'\b(spackle|patch|wall repair)\b').hasMatch(text) &&
      itemType.contains('patch')) {
    score += 20;
  }
  if (RegExp(r'\b(drywall|sheetrock|gypsum)\s+screws?\b').hasMatch(text) &&
      (itemType.contains('screw') || itemName.contains('screw'))) {
    score += 64;
  }
  if (RegExp(
        r'\b(dust barrier|zip door|floor protection|dust collection|cleanup sponge)\b',
      ).hasMatch(text) &&
      itemType.contains('dust control')) {
    score += 26;
  }
  if (RegExp(
        r'\b(drywall lift|panel hoist|mud pan|taping knife|joint knife|texture hopper|hopper gun|drywall rasp|jab saw)\b',
      ).hasMatch(text) &&
      itemType.contains('drywall hanging')) {
    score += 28;
  }
  if (RegExp(
        r'\b(texture hopper nozzle|texture hopper nozzle kit)\b',
      ).hasMatch(text) &&
      itemName.contains('texture hopper nozzle')) {
    score += 72;
  }
  if (RegExp(
        r'\b(pole sander|hand sander|dustless sanding|sanding disc|vacuum bag|dust extractor)\b',
      ).hasMatch(text) &&
      itemType.contains('drywall sanding')) {
    score += 34;
  }
  if (RegExp(
        r'\b(texture hopper nozzle|texture nozzle|texture repair|popcorn scraper|ceiling patch|texture pattern sponge)\b',
      ).hasMatch(text) &&
      itemType.contains('texture sprayer')) {
    score += 34;
  }
  if (RegExp(r'\b(orange peel|knockdown|popcorn)\b').hasMatch(text) &&
      itemName.contains('texture')) {
    score += 24;
  }
  for (final texture in ['orange peel', 'knockdown', 'popcorn']) {
    if (text.contains(texture) && itemName.contains(texture)) {
      score += 44;
    }
  }
  for (final package in ['premixed', 'aerosol', 'powder mix']) {
    if (text.contains(package) && itemName.contains(package)) {
      score += 58;
    } else if (text.contains(package) &&
        itemName.contains('texture') &&
        !itemName.contains(package)) {
      score -= 36;
    }
  }
  if (RegExp(
        r'\b(ceiling grid|cross tee|main runner|wall angle|acoustic ceiling tile|hold down clip|grid repair clip)\b',
      ).hasMatch(text) &&
      itemType.contains('drop ceiling')) {
    score += 34;
  }
  for (final gridTerm in ['main runner', 'cross tee', 'wall angle']) {
    if (text.contains(gridTerm) && itemName.contains(gridTerm)) {
      score += 48;
    }
  }
  for (final color in ['black', 'white']) {
    if (text.contains(color) && itemName.contains(color)) {
      score += 40;
    } else if (text.contains(color) &&
        (itemName.contains('main runner') ||
            itemName.contains('cross tee') ||
            itemName.contains('wall angle')) &&
        !itemName.contains(color)) {
      score -= 36;
    }
  }
  if (RegExp(
        r'\b(metal stud|steel stud|drywall stud|metal track|steel track|hat channel|furring channel|resilient channel|rc channel|z furring)\b',
      ).hasMatch(text) &&
      itemType.contains('metal studs')) {
    score += 34;
  }
  if (RegExp(
        r'\b(ceiling wire|hanger wire|tie wire|sound isolation clip|rc clip|sound sealant|putty pad)\b',
      ).hasMatch(text) &&
      itemType.contains('ceiling grid')) {
    score += 34;
  }
  if (RegExp(
        r'\b(pan head screw|wafer head screw|metal stud screw|stud crimper|track fastener|deflection track|stud bushing)\b',
      ).hasMatch(text) &&
      itemType.contains('metal framing fasteners')) {
    score += 34;
  }
  for (final term in [
    'metal stud',
    'metal track',
    'hat channel',
    'resilient channel',
    'hanger wire',
    'sound isolation',
    'pan head',
    'wafer head',
    'stud crimper',
    'z furring',
  ]) {
    if (text.contains(term) && variant.contains(term)) score += 42;
  }
  if (text.contains('z furring')) {
    if (itemName.contains('z furring')) {
      score += 100;
    }
    if (itemName.contains('hat channel') ||
        itemName.contains('resilient channel')) {
      score -= 70;
    }
  }
  if (text.contains('paint') && trade == 'drywall') score -= 12;
  return score;
}

int _paintingReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'painting') return score;
  if (RegExp(
    r'\b(paint|primer|roller|brush|painter tape|masking tape|caulk|spackle|drop cloth|tray|stain|polyurethane|polycrylic|spray tip|paint sprayer|masking machine|paint stripper|deglosser|lead paint|color sample|paint sample|epoxy coating|concrete etcher|garage floor cleaner|rust converter|elastomeric sealant|big stretch|backer rod|sprayer filter|pre taped masking film|paint hardener)\b',
  ).hasMatch(text)) {
    score += 16;
  }
  final itemType = item.itemType.toLowerCase();
  if (RegExp(r'\b(interior paint|wall paint|latex paint)\b').hasMatch(text) &&
      itemType.contains('interior paint')) {
    score += 24;
  }
  if (RegExp(r'\b(exterior paint|outside paint)\b').hasMatch(text) &&
      itemType.contains('exterior paint')) {
    score += 24;
  }
  final itemName = item.name.toLowerCase();
  final variant = item.variant.toLowerCase();
  if (text.contains('cabinet') &&
      (variant.contains('cabinet') || itemName.contains('cabinet'))) {
    score += 36;
  }
  if (text.contains('cabinet') &&
      itemName.contains('paint') &&
      !variant.contains('cabinet') &&
      !itemName.contains('cabinet')) {
    score -= 14;
  }
  if (text.contains('ceiling') &&
      (variant.contains('ceiling') || itemName.contains('ceiling'))) {
    score += 26;
  }
  if (text.contains('trim') &&
      (variant.contains('trim') || itemName.contains('trim'))) {
    score += 26;
  }
  if (RegExp(r'\b(primer|stain blocker|bonding primer)\b').hasMatch(text) &&
      itemType.contains('primer')) {
    score += 24;
  }
  for (final primer in [
    'drywall primer',
    'stain blocking primer',
    'bonding primer',
    'masonry primer',
    'metal primer',
    'shellac primer',
    'oil based primer',
  ]) {
    if (text.contains(primer) &&
        (variant.contains(primer) || itemName.contains(primer))) {
      score += 68;
    } else if (text.contains(primer) &&
        itemName.contains('primer') &&
        !(variant.contains(primer) || itemName.contains(primer))) {
      score -= 28;
    }
  }
  if (RegExp(
        r'\b(wood stain|deck stain|fence stain|gel stain|polyurethane|polycrylic|spar urethane|shellac|lacquer|spray paint|high heat paint|appliance epoxy)\b',
      ).hasMatch(text) &&
      itemType.contains('stains clear')) {
    score += 28;
  }
  for (final term in [
    'deck stain',
    'fence stain',
    'gel stain',
    'polyurethane',
    'polycrylic',
    'spar urethane',
    'shellac',
    'lacquer',
    'high heat',
    'appliance epoxy',
  ]) {
    if (text.contains(term) && variant.contains(term)) score += 48;
  }
  if (text.contains('satin') && variant.contains('satin')) score += 18;
  if (text.contains('gloss') && variant.contains('gloss')) score += 18;
  if (RegExp(
        r'\b(floor paint|garage floor paint|epoxy coating|waterproofing paint|masonry waterproofing|rust preventive|chalkboard paint|dry erase paint)\b',
      ).hasMatch(text) &&
      itemType.contains('specialty coatings')) {
    score += 28;
  }
  if (RegExp(
        r'\b(concrete etcher|garage floor cleaner|floor degreaser|rust converter|rust reformer|anti skid additive|floor coating roller)\b',
      ).hasMatch(text) &&
      itemType.contains('concrete garage')) {
    score += 34;
  }
  for (final term in [
    'porch and patio',
    'garage floor',
    'epoxy coating',
    'waterproofing paint',
    'masonry waterproofing',
    'rust preventive',
    'chalkboard',
    'dry erase',
  ]) {
    if (text.contains(term) && variant.contains(term)) score += 44;
  }
  if (RegExp(r'\b(roller cover|roller sleeve|paint roller)\b').hasMatch(text) &&
      itemType.contains('roller')) {
    score += 22;
  }
  if (RegExp(
        r'\b(nap roller|roller\s+\d+\s*pk|3/8\s+nap|1/2\s+nap)\b',
      ).hasMatch(text) &&
      itemType.contains('roller')) {
    score += 70;
  }
  if (RegExp(
        r'\b(extension pole|paint pole|spray tip|airless tip|tip guard|paint sprayer|sprayer hose|pump armor|masking machine|hand masker)\b',
      ).hasMatch(text) &&
      itemType.contains('sprayers')) {
    score += 26;
  }
  if (RegExp(
        r'\b(airless tip|spray gun filter|gun filter|sprayer filter|tip guard|sprayer pump repair|inlet strainer|manifold filter|storage fluid)\b',
      ).hasMatch(text) &&
      itemType.contains('sprayer tips')) {
    score += 34;
  }
  for (final mesh in ['60 mesh', '100 mesh', '200 mesh']) {
    if (text.contains(mesh) && itemName.contains(mesh)) {
      score += 66;
    } else if (text.contains(mesh) &&
        itemName.contains('spray gun filter') &&
        !itemName.contains(mesh)) {
      score -= 32;
    }
  }
  if (RegExp(r'\b(painter tape|masking tape)\b').hasMatch(text) &&
      itemType.contains('tape')) {
    score += 22;
  }
  if (text.contains('delicate') &&
      (variant.contains('delicate') || itemName.contains('delicate'))) {
    score += 34;
  }
  if (text.contains('exterior') &&
      (variant.contains('exterior') || itemName.contains('exterior'))) {
    score += 18;
  }
  if (text.contains('general purpose') &&
      (variant.contains('general purpose') ||
          itemName.contains('general purpose'))) {
    score += 18;
  }
  if (RegExp(
        r'\b(paintable caulk|painter caulk|acrylic caulk)\b',
      ).hasMatch(text) &&
      itemType.contains('caulk')) {
    score += 22;
  }
  if (RegExp(
        r'\b(elastomeric sealant|big stretch|paintable silicone|backer rod|caulk finishing tool|caulk tool|caulk saver)\b',
      ).hasMatch(text) &&
      itemType.contains('specialty painter sealants')) {
    score += 34;
  }
  if (RegExp(
        r'\b(paint stripper|paint remover|adhesive remover|deglosser|lead paint test|lead test kit|deck cleaner|concrete etcher)\b',
      ).hasMatch(text) &&
      itemType.contains('paint removers')) {
    score += 26;
  }
  for (final term in [
    'paint stripper',
    'paint remover',
    'adhesive remover',
    'deglosser',
    'deck cleaner',
    'concrete etcher',
    'lead paint test',
  ]) {
    if (text.contains(term) && variant.contains(term)) score += 48;
  }
  if (RegExp(
        r'\b(paint sample|color sample|colorant|fan deck|paint suit|spray sock|paint hardener|paint disposal)\b',
      ).hasMatch(text) &&
      itemType.contains('painter safety')) {
    score += 24;
  }
  if (RegExp(
        r'\b(pre taped masking film|pre-taped masking film|canvas drop cloth|paint hardener|paint disposal|waste label|pour spout|paint can clip)\b',
      ).hasMatch(text) &&
      itemType.contains('masking film')) {
    score += 34;
  }
  if (RegExp(r'\b(angle brush|paint brush)\b').hasMatch(text) &&
      itemType.contains('brush')) {
    score += 22;
  }
  for (final term in [
    'garage floor cleaner',
    'rust converter',
    'anti-skid',
    'elastomeric',
    'big stretch',
    'paintable silicone',
    'backer rod',
    'spray gun filter',
    'pump repair',
    'pre-taped',
    'paint hardener',
    'paint disposal',
  ]) {
    if (text.contains(term) && variant.contains(term)) score += 42;
  }
  if (category == 'paint' && text.contains('drywall screw')) score -= 20;
  return score;
}

int _roofingReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'roofing') return score;
  if (RegExp(
    r'\b(roof|roofing|shingle|felt|underlayment|ice shield|drip edge|flashing|ridge vent|pipe boot|gutter|downspout|metal roof|ridge cap|rake trim|eave trim|closure strip|butyl tape|soffit|fascia|f channel|j channel|epdm|tpo|low slope|modified bitumen|roof jack|storm collar|b vent|gas vent|roof repair tape|gutter guard|heat cable|roof anchor|roof bracket|chimney cap|spark arrestor)\b',
  ).hasMatch(text)) {
    score += 16;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final variant = item.variant.toLowerCase();
  if (RegExp(
    r'\b(rafter vent baffle|soffit vent baffle|attic vent chute)\b',
  ).hasMatch(text)) {
    score -= 32;
  }
  if (RegExp(r'\b(shingle|shingles|shingle bundle)\b').hasMatch(text) &&
      itemType.contains('shingle')) {
    score += 28;
  }
  if (text.contains('starter') &&
      (variant.contains('starter') || itemName.contains('starter'))) {
    score += 38;
  }
  if (RegExp(
    r'\b(shingle repair|repair shingle|roof granule|roofing granule)\b',
  ).hasMatch(text)) {
    if (itemType.contains('shingle repair')) {
      score += 38;
    } else if (itemType.contains('shingle') ||
        itemName.contains('roof covering')) {
      score -= 10;
    }
  }
  if (text.contains('ridge') &&
      (variant.contains('ridge') || itemName.contains('ridge'))) {
    score += 30;
  }
  if ((text.contains('starter') || text.contains('ridge')) &&
      itemName.contains('shingle') &&
      !variant.contains('starter') &&
      !variant.contains('ridge')) {
    score -= 16;
  }
  if (RegExp(
        r'\b(felt|felt paper|synthetic underlayment|ice shield|ice barrier)\b',
      ).hasMatch(text) &&
      itemType.contains('underlayment')) {
    score += 26;
  }
  if (RegExp(r'\b(drip edge|edge metal|rake edge)\b').hasMatch(text) &&
      itemType.contains('drip')) {
    score += 24;
  }
  if (RegExp(
        r'\b(step flashing|valley flashing|roof flashing|flashing)\b',
      ).hasMatch(text) &&
      itemType.contains('flashing')) {
    score += 24;
  }
  if (RegExp(r'\b(pipe boot|roof boot|vent boot)\b').hasMatch(text) &&
      itemType.contains('pipe boot')) {
    score += 26;
  }
  for (final material in ['rubber', 'silicone', 'lead']) {
    if (text.contains(material) &&
        itemName.contains(material) &&
        itemName.contains('pipe boot')) {
      score += 62;
    } else if (text.contains(material) &&
        itemName.contains('pipe boot') &&
        !itemName.contains(material)) {
      score -= 28;
    }
  }
  if (RegExp(r'\b(ridge vent|box vent|roof vent)\b').hasMatch(text) &&
      itemType.contains('vent')) {
    score += 24;
  }
  if (RegExp(
        r'\b(gutter|downspout|hidden hanger|drop outlet)\b',
      ).hasMatch(text) &&
      category == 'gutters and drainage') {
    score += 22;
  }
  if (RegExp(
    r'\b(k style gutter|k-style gutter|gutter 10 ft|gutter guard|micro mesh gutter guard)\b',
  ).hasMatch(text)) {
    if (itemName.contains('gutter')) {
      score += 76;
    }
    if (itemName.contains('siding') || itemName.contains('floor')) {
      score -= 36;
    }
  }
  if (RegExp(r'\b(roof nail|roofing nail|cap nail)\b').hasMatch(text) &&
      itemType.contains('nail')) {
    score += 22;
  }
  if (RegExp(
        r'\b(roof cement|roof sealant|flashing sealant)\b',
      ).hasMatch(text) &&
      itemType.contains('sealant')) {
    score += 22;
  }
  if (RegExp(
        r'\b(roof deck|roof decking|roof sheathing|deck patch)\b',
      ).hasMatch(text) &&
      itemName.contains('roof deck')) {
    score += 28;
  }
  if (RegExp(r'\b(osb|cdx|plywood|sheathing)\b').hasMatch(text) &&
      itemName.contains('roof deck')) {
    score += 18;
  }
  if (RegExp(r'\b(h clip|h-clip|panel spacer)\b').hasMatch(text) &&
      itemName.contains('roof deck')) {
    score += 26;
  }
  if (RegExp(
    r'\b(roof h clip|roof h-clip|h clip panel spacer|h-clip panel spacer)\b',
  ).hasMatch(text)) {
    if (itemName.contains('h-clip panel spacer')) {
      score += 90;
    }
    if (itemName.contains('tile') || itemName.contains('clip spacer')) {
      score -= 40;
    }
  }
  if (RegExp(
        r'\b(metal roof|metal roofing|ridge cap|rake trim|eave trim)\b',
      ).hasMatch(text) &&
      itemName.contains('metal roofing')) {
    score += 28;
  }
  if (RegExp(r'\b(closure strip|foam closure)\b').hasMatch(text) &&
      itemName.contains('closure strip')) {
    score += 26;
  }
  if (RegExp(r'\b(butyl tape|roof butyl)\b').hasMatch(text) &&
      itemName.contains('butyl tape')) {
    score += 26;
  }
  if (RegExp(
        r'\b(roof repair tape|roof patch tape|cover tape|seam roller|flashing primer)\b',
      ).hasMatch(text) &&
      itemType.contains('roof patch')) {
    score += 34;
  }
  if (RegExp(
    r'\b(peel and stick roof repair tape|roof repair tape)\b',
  ).hasMatch(text)) {
    if (itemName.contains('roof repair tape')) {
      score += 88;
    }
    if (itemName.contains('floor') || itemName.contains('vinyl')) {
      score -= 40;
    }
  }
  if (RegExp(
        r'\b(gutter guard|micro mesh|foam gutter guard|brush gutter)\b',
      ).hasMatch(text) &&
      itemType.contains('gutter guards')) {
    score += 34;
  }
  if (RegExp(
        r'\b(heat cable|deicing cable|de-icing cable|roof clip)\b',
      ).hasMatch(text) &&
      itemType.contains('gutter guards')) {
    score += 34;
  }
  if (RegExp(
        r'\b(downspout strainer|splash block|downspout extension)\b',
      ).hasMatch(text) &&
      itemType.contains('gutter guards')) {
    score += 26;
  }
  if (RegExp(
        r'\b(roof anchor|roof bracket|toe board|walk pad|warning line|ladder roof hook|roof harness)\b',
      ).hasMatch(text) &&
      itemType.contains('roof safety')) {
    score += 36;
  }
  if (RegExp(r'\b(metal roofing screw|roofing screw)\b').hasMatch(text) &&
      itemName.contains('metal roofing screw')) {
    score += 28;
  }
  if (RegExp(
        r'\b(soffit panel|vented soffit|solid soffit|fascia cover|aluminum fascia|f channel|j channel|soffit channel)\b',
      ).hasMatch(text) &&
      itemType.contains('soffit fascia')) {
    score += 30;
  }
  if (RegExp(r'\b(soffit|fascia|f channel|j channel)\b').hasMatch(text)) {
    if (itemName.contains('soffit') ||
        itemName.contains('fascia') ||
        itemName.contains('channel')) {
      score += 26;
    } else if (itemName.contains('gutter')) {
      score -= 12;
    }
  }
  if (RegExp(r'\b(soffit panel|vented soffit|solid soffit)\b').hasMatch(text)) {
    if (itemName.contains('soffit panel')) {
      score += 60;
    } else if (itemName.contains('fascia')) {
      score -= 24;
    }
  }
  if (text.contains('vented soffit')) {
    if (itemName.contains('vented') && itemName.contains('soffit')) {
      score += 42;
    } else if (itemName.contains('solid') && itemName.contains('soffit')) {
      score -= 24;
    }
  }
  if (text.contains('solid soffit')) {
    if (itemName.contains('solid') && itemName.contains('soffit')) {
      score += 42;
    } else if (itemName.contains('vented') && itemName.contains('soffit')) {
      score -= 24;
    }
  }
  if (RegExp(
    r'\b(fascia cover|aluminum fascia|fascia trim)\b',
  ).hasMatch(text)) {
    if (itemName.contains('fascia cover')) {
      score += 60;
    } else if (itemName.contains('soffit')) {
      score -= 24;
    }
  }
  if (RegExp(
        r'\b(epdm|tpo|low slope|modified bitumen|base sheet|cold process|roof adhesive|silicone roof coating|elastomeric roof coating)\b',
      ).hasMatch(text) &&
      itemType.contains('low slope')) {
    score += 32;
  }
  if (RegExp(
    r'\b(tpo seam tape|epdm seam tape|tpo patch|epdm patch)\b',
  ).hasMatch(text)) {
    if (itemName.contains('tpo') || itemName.contains('epdm')) {
      score += 84;
    }
    if (itemName.contains('tile') || itemName.contains('membrane seam')) {
      score -= 42;
    }
  }
  if (RegExp(
    r'\b(silicone roof coating|elastomeric roof coating|roof coating)\b',
  ).hasMatch(text)) {
    if (itemName.contains('roof coating')) {
      score += 88;
    }
    if (itemName.contains('pipe boot')) {
      score -= 96;
    }
  }
  if (RegExp(r'\b(epdm patch|tpo patch|patch kit)\b').hasMatch(text)) {
    if (itemName.contains('patch kit')) {
      score += 34;
    } else if (itemName.contains('roof coating')) {
      score -= 12;
    }
  }
  if (RegExp(
        r'\b(roof jack|storm collar|b vent flashing|gas vent flashing|chimney flashing|skylight flashing|roof cricket|rain diverter)\b',
      ).hasMatch(text) &&
      itemType.contains('roof jacks')) {
    score += 32;
  }
  if (RegExp(
        r'\b(chimney flashing|counter flashing|skylight flashing|sidewall flashing|endwall flashing|kickout flashing)\b',
      ).hasMatch(text) &&
      itemType.contains('chimney skylight')) {
    score += 36;
  }
  if (RegExp(
        r'\b(chimney cap|chimney rain cap|rain cap|vent cap|spark arrestor|bird screen|vent mesh guard)\b',
      ).hasMatch(text) &&
      itemType.contains('vent cap')) {
    score += 36;
  }
  if (RegExp(
    r'\b(chimney rain cap|chimney cap|spark arrestor|bird screen|vent mesh guard)\b',
  ).hasMatch(text)) {
    if (itemName.contains('chimney') ||
        itemName.contains('spark arrestor') ||
        itemName.contains('bird screen') ||
        itemName.contains('vent mesh guard')) {
      score += 70;
    } else if (itemName.contains('wall cap') || itemName.contains('duct')) {
      score -= 18;
    }
  }
  if (RegExp(r'\b(roof jack|adjustable roof jack)\b').hasMatch(text)) {
    if (itemName.contains('roof jack')) {
      score += 70;
    } else if (itemName.contains('pipe boot')) {
      score -= 24;
    }
  }
  if (RegExp(r'\b(storm collar|vent collar)\b').hasMatch(text)) {
    if (itemName.contains('storm collar')) {
      score += 36;
    } else if (itemName.contains('pipe boot')) {
      score -= 12;
    }
  }
  if (RegExp(r'\b(thinset|grout|tile)\b').hasMatch(text)) score -= 18;
  return score;
}

int _tileReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'tile') return score;
  if (RegExp(r'\b(duct mastic|duct sealant|hvac mastic)\b').hasMatch(text)) {
    return -90;
  }
  if (RegExp(
    r'\b(tile|porcelain|ceramic|thinset|thin set|grout|mastic|membrane|backer board|cement board|spacer|leveling clip|linear drain|shower curb|shower bench|corner shelf|seam tape|backer screw|marble threshold|grout caulk|grout haze|glass tile|bullnose|cove base|pencil liner|crack isolation|anti fracture|antifracture|membrane primer|floor heat|heated floor|drain grate|tileable drain|tile-in drain)\b',
  ).hasMatch(text)) {
    score += 16;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final variant = item.variant.toLowerCase();
  if (RegExp(r'\b(ceramic|porcelain|mosaic|stone tile)\b').hasMatch(text) &&
      category == 'tile materials') {
    score += 24;
  }
  if (RegExp(
    r'\b(bathroom|shower|backsplash|kitchen|floor tile|entry tile|porcelain|ceramic|glass|quarry|stone look|subway|pickett|arabesque|herringbone|penny round|ledger panel|travertine|slate|limestone|granite|marble)\b',
  ).hasMatch(text)) {
    if (itemType.contains('bathroom') ||
        itemType.contains('kitchen') ||
        itemType.contains('floor') ||
        itemType.contains('natural stone')) {
      score += 34;
    }
  }
  for (final term in [
    'porcelain',
    'ceramic',
    'glass',
    'quarry',
    'marble',
    'travertine',
    'slate',
    'limestone',
    'granite',
  ]) {
    if (text.contains(term) && itemName.contains(term)) {
      score += 34;
    } else if (text.contains(term) &&
        (itemType.contains('bathroom') ||
            itemType.contains('kitchen') ||
            itemType.contains('floor') ||
            itemType.contains('natural stone')) &&
        !itemName.contains(term)) {
      score -= 18;
    }
  }
  for (final term in [
    'white',
    'warm white',
    'gray',
    'charcoal',
    'black',
    'blue',
    'green',
    'sage',
    'red',
    'brown',
    'tan',
    'adobe',
    'sand',
    'carrara',
    'travertine',
    'slate',
    'beige',
  ]) {
    if (text.contains(term) && itemName.contains(term)) score += 16;
  }
  for (final term in [
    'textured',
    'matte',
    'gloss',
    'polished',
    'honed',
    'tumbled',
    'split face',
    'anti slip',
  ]) {
    if (text.contains(term) && itemName.contains(term)) score += 20;
  }
  for (final term in [
    'subway',
    'pickett',
    'arabesque',
    'herringbone',
    'hex mosaic',
    'penny round',
    'basketweave',
    'lantern',
    'chevron',
    'pebble',
    'linear mosaic',
    'mosaic sheet',
    'ledger panel',
    'plank',
    'backsplash',
    'floor tile',
    'rectified',
    'stone look',
    'paver tile',
    'quarry tile',
    'saltillo',
    'terracotta',
    'tread tile',
  ]) {
    if (text.contains(term) && itemName.contains(term)) score += 24;
  }
  for (final size in [
    '3 x 6',
    '4 x 12',
    '6 x 6',
    '6 x 24',
    '8 x 36',
    '8 x 48',
    '12 x 12',
    '12 x 24',
    '16 x 16',
    '16 x 32',
    '18 x 18',
    '18 x 36',
    '24 x 24',
    '24 x 48',
    '30 x 30',
  ]) {
    final compact = size.replaceAll(' ', '');
    if ((text.contains(size) || text.contains(compact)) &&
        itemName.contains('$size in')) {
      score += 30;
    }
  }
  if (RegExp(
        r'\b(glass tile|glass mosaic|bullnose tile|bullnose trim|cove base tile|tile cove base|pencil liner|tile pencil|accent tile)\b',
      ).hasMatch(text) &&
      itemType.contains('glass decorative')) {
    score += 34;
  }
  if (RegExp(r'\b(bullnose|cove base|pencil liner)\b').hasMatch(text)) {
    if (itemName.contains('bullnose') ||
        itemName.contains('cove base') ||
        itemName.contains('pencil liner')) {
      score += 54;
    } else if (category == 'tile materials') {
      score -= 10;
    }
  }
  if (text.contains('bullnose') &&
      !RegExp(r'\b(tile|trim|schluter|ceramic|porcelain)\b').hasMatch(text) &&
      trade == 'tile') {
    score -= 36;
  }
  if (text.contains('matte') &&
      (variant.contains('matte') || itemName.contains('matte'))) {
    score += 34;
  }
  if (text.contains('polished') &&
      (variant.contains('polished') || itemName.contains('polished'))) {
    score += 30;
  }
  if (text.contains('glazed') &&
      (variant.contains('glazed') || itemName.contains('glazed'))) {
    score += 24;
  }
  if (text.contains('matte') &&
      itemName.contains('porcelain') &&
      !variant.contains('matte')) {
    score -= 12;
  }
  if (RegExp(
        r'\b(thinset|thin set|modified mortar|large format mortar|lft mortar)\b',
      ).hasMatch(text) &&
      itemType.contains('thinset')) {
    score += 28;
  }
  if (RegExp(r'\blft\b').hasMatch(text) &&
      (variant.contains('lft') || itemName.contains('lft'))) {
    score += 34;
  }
  if (RegExp(r'\blft\b').hasMatch(text) &&
      itemName.contains('mortar') &&
      !variant.contains('lft') &&
      !itemName.contains('lft')) {
    score -= 12;
  }
  if (RegExp(r'\b(mastic|tile adhesive)\b').hasMatch(text) &&
      itemType.contains('adhesive')) {
    score += 24;
  }
  if (RegExp(
        r'\b(glass tile mortar|rapid setting mortar|rapid set mortar)\b',
      ).hasMatch(text) &&
      itemType.contains('advanced mortar')) {
    score += 44;
  }
  if (RegExp(r'\b(grout|sanded grout|unsanded grout)\b').hasMatch(text) &&
      itemType.contains('grout')) {
    score += 26;
  }
  for (final unit in ['1 qt', '1 gal', '10 lb', '25 lb']) {
    final compact = unit.replaceAll(' ', '');
    if (text.contains(unit) || text.contains(compact)) {
      if (itemName.contains(unit)) {
        score += 34;
      } else if (itemName.contains('grout')) {
        score -= 10;
      }
    }
  }
  if (RegExp(
        r'\b(epoxy grout|urethane grout|high performance grout|premixed grout)\b',
      ).hasMatch(text) &&
      itemType.contains('advanced mortar')) {
    score += 44;
  }
  if (RegExp(r'\burethane grout\b').hasMatch(text)) {
    if (itemName.contains('urethane grout')) {
      score += 68;
    } else if (itemName.contains('grout')) {
      score -= 10;
    }
  }
  if (RegExp(
        r'\b(uncoupling membrane|waterproofing membrane|shower membrane|cement board|backer board)\b',
      ).hasMatch(text) &&
      category == 'waterproofing') {
    score += 26;
  }
  if (RegExp(
        r'\b(crack isolation membrane|crack isolation|anti fracture membrane|antifracture membrane|peel and stick tile membrane|membrane primer|tile primer|self leveling primer|floor heat mat|heated floor|floor heat cable|radiant floor heat|floor heat thermostat|self leveling underlayment)\b',
      ).hasMatch(text) &&
      itemType.contains('crack isolation')) {
    score += 34;
  }
  if (RegExp(
    r'\b(crack isolation membrane|crack isolation)\b',
  ).hasMatch(text)) {
    if (itemName.contains('crack isolation membrane')) {
      score += 62;
    } else if (itemName.contains('anti fracture')) {
      score -= 18;
    }
  }
  if (RegExp(
    r'\b(anti fracture membrane|antifracture membrane)\b',
  ).hasMatch(text)) {
    if (itemName.contains('anti fracture')) {
      score += 62;
    } else if (itemName.contains('crack isolation')) {
      score -= 18;
    }
  }
  if (RegExp(
    r'\b(floor heat|heated floor|radiant floor heat)\b',
  ).hasMatch(text)) {
    if (itemName.contains('floor heat') ||
        itemName.contains('heated floor') ||
        itemName.contains('radiant floor')) {
      score += 60;
    } else if (itemName.contains('membrane')) {
      score -= 10;
    }
    for (final area in [
      '10 sq ft',
      '15 sq ft',
      '20 sq ft',
      '25 sq ft',
      '30 sq ft',
      '40 sq ft',
      '50 sq ft',
      '60 sq ft',
      '80 sq ft',
      '100 sq ft',
    ]) {
      final compact = area.replaceAll(' ', '');
      if ((text.contains(area) || text.contains(compact)) &&
          itemName.contains(area)) {
        score += 44;
      } else if ((text.contains(area) || text.contains(compact)) &&
          (itemName.contains('floor heat') ||
              itemName.contains('radiant floor')) &&
          !itemName.contains(area)) {
        score -= 16;
      }
    }
  }
  if (RegExp(r'\b(shower pan|linear drain|shower niche)\b').hasMatch(text) &&
      itemType.contains('shower')) {
    score += 24;
  }
  if (RegExp(
    r'\b(shower tray|shower pan|tile ready pan|foam shower tray)\b',
  ).hasMatch(text)) {
    if (itemName.contains('shower tray') || itemName.contains('shower pan')) {
      score += 42;
    }
    for (final size in [
      '32 x 60',
      '36 x 36',
      '36 x 48',
      '36 x 60',
      '48 x 48',
      '48 x 60',
      '60 x 60',
    ]) {
      final compact = size.replaceAll(' ', '');
      if ((text.contains(size) || text.contains(compact)) &&
          itemName.contains('$size in')) {
        score += 58;
      } else if ((text.contains(size) || text.contains(compact)) &&
          (itemName.contains('shower tray') ||
              itemName.contains('shower pan')) &&
          !itemName.contains('$size in')) {
        score -= 20;
      }
    }
    for (final drain in ['left drain', 'right drain', 'center drain']) {
      if (text.contains(drain) && itemName.contains(drain)) {
        score += 36;
      } else if (text.contains(drain) &&
          (itemName.contains('shower tray') ||
              itemName.contains('shower pan')) &&
          !itemName.contains(drain)) {
        score -= 12;
      }
    }
  }
  if (RegExp(
    r'\b(linear shower drain|linear drain|shower drain)\b',
  ).hasMatch(text)) {
    if (itemName.contains('linear shower drain') ||
        itemName.contains('linear drain')) {
      score += 76;
    } else if (itemName.contains('shower pan') ||
        itemName.contains('pan extension')) {
      score -= 34;
    }
    for (final length in [
      '24 in',
      '30 in',
      '36 in',
      '42 in',
      '48 in',
      '60 in',
    ]) {
      final compact = length.replaceAll(' ', '');
      if ((text.contains(length) || text.contains(compact)) &&
          itemName.contains(length)) {
        score += 42;
      } else if ((text.contains(length) || text.contains(compact)) &&
          itemName.contains('linear') &&
          !itemName.contains(length)) {
        score -= 18;
      }
    }
    for (final finish in [
      'brushed nickel',
      'matte black',
      'chrome',
      'oil rubbed bronze',
      'satin stainless',
    ]) {
      if (text.contains(finish) && itemName.contains(finish)) {
        score += 30;
      } else if (text.contains(finish) &&
          itemName.contains('linear') &&
          !itemName.contains(finish)) {
        score -= 12;
      }
    }
    if (text.contains('channel') && itemName.contains('channel')) {
      score += 28;
    }
  }
  if (RegExp(r'\b(shower pan extension|tray extension)\b').hasMatch(text)) {
    if (itemName.contains('shower pan extension')) {
      score += 68;
    } else if (itemName.contains('linear shower drain') ||
        itemName.contains('shower pan kit')) {
      score -= 10;
    }
  }
  if (RegExp(
        r'\b(drain grate|shower drain grate|tileable drain|tile-in drain|point drain|linear drain grate|drain grate cover|waterproof shower niche|foam shower niche|foot rest|shower bench bracket|shower curb overlay)\b',
      ).hasMatch(text) &&
      itemType.contains('shower')) {
    score += 34;
  }
  if (RegExp(
    r'\b(shower niche|foam niche|tile ready shower niche|recessed shower niche|shower curb|foam curb|shower bench|corner bench|corner shelf|foot rest)\b',
  ).hasMatch(text)) {
    if (itemName.contains('shower niche') ||
        itemName.contains('shower curb') ||
        itemName.contains('shower bench') ||
        itemName.contains('corner shelf') ||
        itemName.contains('foot rest')) {
      score += 54;
    } else if (itemName.contains('membrane')) {
      score -= 30;
    }
    for (final size in [
      '12 x 12',
      '12 x 20',
      '12 x 28',
      '16 x 20',
      '16 x 28',
      '16 x 32',
      '36 in',
      '48 in',
      '60 in',
      '72 in',
    ]) {
      final compact = size.replaceAll(' ', '');
      if ((text.contains(size) || text.contains(compact)) &&
          itemName.contains(size)) {
        score += 46;
      } else if ((text.contains(size) || text.contains(compact)) &&
          (itemName.contains('shower niche') ||
              itemName.contains('shower curb') ||
              itemName.contains('shower bench')) &&
          !itemName.contains(size)) {
        score -= 14;
      }
    }
    for (final term in [
      'tile ready',
      'waterproof',
      'foam',
      'recessed',
      'triangular',
      'floating',
    ]) {
      if (text.contains(term) && itemName.contains(term)) score += 22;
    }
  }
  if (RegExp(r'\b(tileable drain|tile-in drain)\b').hasMatch(text)) {
    if (itemName.contains('tileable drain')) {
      score += 60;
    } else if (itemName.contains('linear shower drain')) {
      score -= 12;
    }
  }
  if (RegExp(
        r'\b(shower curb|foam curb|shower bench|foam bench|corner shelf|shower shelf|seam tape|waterproofing band|backer screw|backer board screw|pipe seal|mixing valve seal)\b',
      ).hasMatch(text) &&
      itemType.contains('shower curbs')) {
    score += 28;
  }
  if (RegExp(
    r'\b(waterproofing band|waterproofing seam tape|seam tape roll|uncoupling seam tape)\b',
  ).hasMatch(text)) {
    if (itemName.contains('waterproofing band') ||
        itemName.contains('seam tape')) {
      score += 48;
    }
    for (final length in ['16 ft', '33 ft', '50 ft', '98 ft']) {
      final compact = length.replaceAll(' ', '');
      if ((text.contains(length) || text.contains(compact)) &&
          itemName.contains(length)) {
        score += 42;
      } else if ((text.contains(length) || text.contains(compact)) &&
          (itemName.contains('waterproofing band') ||
              itemName.contains('seam tape')) &&
          !itemName.contains(length)) {
        score -= 14;
      }
    }
  }
  if (RegExp(
        r'\b(foam board washer|kerdi fix|waterproof sealant tube|shower pan extension|floor heat sensor|heat sensor wire|floor heat alarm)\b',
      ).hasMatch(text) &&
      itemType.contains('waterproof shower')) {
    score += 44;
  }
  if (RegExp(r'\b(foam board washer|tile board washer)\b').hasMatch(text)) {
    if (itemName.contains('foam board washer') &&
        itemType.contains('waterproof shower')) {
      score += 70;
    } else if (trade == 'tile' &&
        (itemName.contains('backer board') || itemName.contains('membrane'))) {
      score -= 8;
    }
  }
  if (RegExp(
    r'\b(schluter|tile trim|edge trim|profile|jolly|rondec|marble threshold|marble sill|tile sill|movement joint|transition strip|stair nose)\b',
  ).hasMatch(text)) {
    if (itemName.contains('profile') ||
        itemName.contains('edge trim') ||
        itemName.contains('threshold') ||
        variant.contains('profile') ||
        variant.contains('edge trim') ||
        variant.contains('threshold') ||
        variant.contains('movement joint') ||
        variant.contains('transition')) {
      score += 34;
    }
  }
  if (RegExp(
    r'\b(jolly|rondec|quadec|schiene|edge trim|inside corner profile|outside corner profile)\b',
  ).hasMatch(text)) {
    if (itemType.contains('metal tile profiles') ||
        itemName.contains('edge trim') ||
        itemName.contains('profile')) {
      score += 46;
    }
  }
  for (final term in [
    'jolly',
    'rondec',
    'quadec',
    'schiene',
    'inside corner',
    'outside corner',
  ]) {
    if (text.contains(term) && itemName.contains(term)) {
      score += 52;
    } else if (text.contains(term) &&
        itemType.contains('metal tile profiles') &&
        !itemName.contains(term)) {
      score -= 18;
    }
  }
  if (RegExp(
    r'\b(marble threshold|engineered stone threshold|shower curb cap|window sill|tile reducer|t molding|carpet transition|movement joint)\b',
  ).hasMatch(text)) {
    if (itemType.contains('thresholds') ||
        itemName.contains('threshold') ||
        itemName.contains('transition') ||
        itemName.contains('curb cap')) {
      score += 46;
    }
  }
  if (RegExp(r'\b(tile spacer|leveling clip|tile leveling)\b').hasMatch(text) &&
      itemType.contains('spacer')) {
    score += 22;
  }
  for (final term in [
    'tile spacer',
    'tile leveling clip',
    'tile leveling wedge',
    'reusable tile leveling cap',
    't spin leveling spacer',
  ]) {
    if (text.contains(term) && itemName.contains(term)) {
      score += 64;
    } else if (text.contains(term) &&
        itemType.contains('leveling') &&
        !itemName.contains(term)) {
      score -= 18;
    }
  }
  if (RegExp(
        r'\b(tile leveling cap|reusable leveling cap|porcelain diamond blade|glass tile blade|epoxy grout float|grout release|grout sealer applicator|carbide grout removal blade|tile hole saw)\b',
      ).hasMatch(text) &&
      itemType.contains('tile tools cleanup')) {
    score += 44;
  }
  if (RegExp(
    r'\b(porcelain diamond blade|glass tile blade)\b',
  ).hasMatch(text)) {
    if (itemName.contains('porcelain diamond blade') ||
        itemName.contains('glass tile blade')) {
      score += 64;
    } else if (itemName.contains('diamond blade')) {
      score -= 10;
    }
  }
  if (RegExp(
    r'\b(tile hole saw|diamond tile hole saw|porcelain hole saw|glass tile drill bit|diamond core bit|core bit)\b',
  ).hasMatch(text)) {
    if (itemName.contains('hole saw') ||
        itemName.contains('drill bit') ||
        itemName.contains('core bit')) {
      score += 70;
    } else if (itemName.contains('blade')) {
      score -= 34;
    }
    for (final toolType in [
      'diamond tile hole saw',
      'porcelain hole saw',
      'glass tile drill bit',
      'diamond core bit',
    ]) {
      if (text.contains(toolType) && itemName.contains(toolType)) {
        score += 74;
      } else if (text.contains(toolType) &&
          (itemName.contains('hole saw') ||
              itemName.contains('drill bit') ||
              itemName.contains('core bit')) &&
          !itemName.contains(toolType)) {
        score -= 28;
      }
    }
    for (final size in [
      '1/4 in',
      '5/16 in',
      '3/8 in',
      '1/2 in',
      '5/8 in',
      '3/4 in',
      '1 in',
      '1-1/4 in',
      '1-3/8 in',
      '2 in',
    ]) {
      if (_tileReceiptMentionsSize(text, size)) {
        if (itemName.contains(size)) {
          score += 46;
        } else if (itemName.contains('hole saw') ||
            itemName.contains('drill bit') ||
            itemName.contains('core bit')) {
          score -= 18;
        }
      }
    }
  }
  if (RegExp(
    r'\b(leveling clip|tile leveling clip|leveling clips)\b',
  ).hasMatch(text)) {
    if (item.name.toLowerCase().contains('leveling clip')) {
      score += 30;
    } else if (item.name.toLowerCase().contains('spacer')) {
      score -= 18;
    }
  }
  if (RegExp(
        r'\b(trowel|diamond blade|grout float|tile sponge)\b',
      ).hasMatch(text) &&
      itemType.contains('trowel')) {
    score += 18;
  }
  if (RegExp(r'\b(trowel|notched trowel|notch trowel)\b').hasMatch(text)) {
    if (itemName.contains('trowel')) {
      score += 38;
    }
    for (final notch in [
      '1/8 x 1/8 in',
      '3/16 x 5/32 in',
      '1/4 x 1/4 in',
      '1/4 x 3/8 in',
      '1/2 x 1/2 in',
      '3/4 x 9/16 in',
    ]) {
      if (_tileReceiptMentionsSize(text, notch)) {
        if (itemName.contains(notch)) {
          score += 46;
        } else if (itemName.contains('trowel')) {
          score -= 16;
        }
      }
    }
    if (text.contains('stainless') && itemName.contains('stainless')) {
      score += 24;
    }
  }
  if (RegExp(
    r'\b(cement backer board|fiber cement backer board|foam tile backer|waterproof tile board|backer board screw|mesh tape|liquid waterproofing)\b',
  ).hasMatch(text)) {
    if (itemType.contains('cement foam') ||
        itemName.contains('backer board') ||
        itemName.contains('tile board') ||
        itemName.contains('mesh tape')) {
      score += 44;
    }
  }
  for (final term in [
    'cement backer board',
    'fiber cement backer board',
    'foam tile backer board',
    'waterproof tile board',
  ]) {
    if (text.contains(term) && itemName.contains(term)) {
      score += 58;
    } else if (text.contains(term) &&
        itemType.contains('cement foam') &&
        !itemName.contains(term)) {
      score -= 18;
    }
  }
  if (RegExp(
    r'\b(self leveling underlayment|self leveling primer|tile bonding primer|porous surface primer|non porous surface primer|waterproofing primer|floor patch|feather finish|rapid set floor patch|anti fracture membrane|crack isolation membrane|uncoupling membrane|peel and stick tile membrane)\b',
  ).hasMatch(text)) {
    if (itemType.contains('self leveling') ||
        itemName.contains('self leveling') ||
        itemName.contains('primer') ||
        itemName.contains('floor patch') ||
        itemName.contains('anti fracture') ||
        itemName.contains('crack isolation') ||
        itemName.contains('uncoupling membrane')) {
      score += 48;
    }
    for (final term in [
      'tile bonding primer',
      'self leveling primer',
      'porous surface primer',
      'non porous surface primer',
      'waterproofing primer',
    ]) {
      if (text.contains(term) && itemName.contains(term)) {
        score += 64;
      } else if (text.contains(term) &&
          itemName.contains('primer') &&
          !itemName.contains(term)) {
        score -= 22;
      }
    }
    for (final size in ['1 qt', '1 gal', '2 gal', '3.5 gal', '5 gal']) {
      if (_tileReceiptMentionsSize(text, size)) {
        if (itemName.contains(size)) {
          score += 32;
        } else if (itemName.contains('primer') ||
            itemName.contains('additive')) {
          score -= 12;
        }
      }
    }
  }
  if (RegExp(
        r'\b(grout caulk|tile caulk|ceramic tile caulk|grout colorant|grout haze remover|haze remover|grout release|stone cleaner|tile sealer|stone enhancer|natural stone sealer|stone sealer)\b',
      ).hasMatch(text) &&
      itemType.contains('grout caulk')) {
    score += 28;
  }
  if (RegExp(
    r'\b(grout release|grout haze remover|heavy duty grout cleaner|stone cleaner|tile sealer|stone enhancer|natural stone sealer|stone sealer)\b',
  ).hasMatch(text)) {
    if (itemName.contains('grout release') ||
        itemName.contains('haze remover') ||
        itemName.contains('stone cleaner') ||
        itemName.contains('tile sealer') ||
        itemName.contains('stone enhancer') ||
        itemName.contains('natural stone sealer')) {
      score += 46;
    }
    for (final term in [
      'grout release',
      'grout haze remover',
      'heavy duty grout cleaner',
      'stone cleaner',
      'tile sealer',
      'stone enhancer',
      'natural stone sealer',
    ]) {
      if (text.contains(term) && itemName.contains(term)) {
        score += 64;
      } else if (text.contains(term) &&
          (itemName.contains('sealer') ||
              itemName.contains('cleaner') ||
              itemName.contains('grout')) &&
          !itemName.contains(term)) {
        score -= 18;
      }
    }
    for (final size in ['1 qt', '1 gal']) {
      if (_tileReceiptMentionsSize(text, size)) {
        if (itemName.contains(size)) {
          score += 32;
        } else if (itemName.contains('sealer') ||
            itemName.contains('cleaner')) {
          score -= 10;
        }
      }
    }
  }
  if (RegExp(r'\b(shingle|roof|gutter|drip edge)\b').hasMatch(text)) {
    score -= 18;
  }
  return score;
}

bool _tileReceiptMentionsSize(String text, String size) {
  final normalizedSize = _normalize(size);
  final compactNoSpace = normalizedSize.replaceAll(' ', '');
  final bareInch = normalizedSize.replaceFirst(RegExp(r'\s+in$'), '');
  final xCompact = normalizedSize.replaceAll(' x ', 'x');
  final xBare = bareInch.replaceAll(' x ', 'x');
  return text.contains(normalizedSize) ||
      text.contains(compactNoSpace) ||
      text.contains(bareInch) ||
      text.contains(xCompact) ||
      text.contains(xBare);
}

int _flooringReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'flooring') return score;
  if (RegExp(
    r'\b(lvp|lvt|vinyl plank|vinyl tile|luxury vinyl|rigid core|spc|wpc|laminate|hardwood|engineered hardwood|flooring|floating floor|sheet vinyl|peel stick|peel and stick|carpet|carpet tile|carpet pad|tack strip|floor underlayment|moisture barrier|vapor barrier|floor leveler|self leveler|floor patch|transition strip|t molding|reducer|end cap|threshold|quarter round|shoe molding|stair nose|floor adhesive|floor spacer|pull bar|tapping block|floor cleat|floor staple)\b',
  ).hasMatch(text)) {
    score += 18;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final variant = item.variant.toLowerCase();
  if (RegExp(r'\b(lvp|vinyl plank|luxury vinyl plank)\b').hasMatch(text)) {
    if (itemType.contains('luxury vinyl')) {
      score += 60;
    } else if (itemName.contains('sheet vinyl') ||
        itemName.contains('peel and stick')) {
      score -= 20;
    }
  }
  if (RegExp(r'\b(lvt|vinyl tile|luxury vinyl tile)\b').hasMatch(text)) {
    if (itemType.contains('luxury vinyl') && itemName.contains('tile')) {
      score += 60;
    } else if (itemName.contains('plank')) {
      score -= 12;
    }
  }
  for (final term in ['spc', 'wpc', 'rigid core', 'waterproof']) {
    if (text.contains(term) && itemName.contains(term)) score += 34;
  }
  if (RegExp(r'\b(laminate|floating floor)\b').hasMatch(text)) {
    if (itemType.contains('laminate')) {
      score += 54;
    } else if (itemName.contains('vinyl') || itemName.contains('hardwood')) {
      score -= 14;
    }
  }
  if (RegExp(
    r'\b(hardwood|engineered hardwood|wood flooring)\b',
  ).hasMatch(text)) {
    if (itemType.contains('hardwood')) {
      score += 54;
    } else if (itemName.contains('laminate') || itemName.contains('vinyl')) {
      score -= 14;
    }
  }
  for (final species in [
    'oak',
    'red oak',
    'white oak',
    'maple',
    'hickory',
    'birch',
    'bamboo',
    'walnut',
    'acacia',
  ]) {
    if (text.contains(species) && itemName.contains(species)) score += 22;
  }
  if (RegExp(r'\b(sheet vinyl|vinyl roll)\b').hasMatch(text)) {
    if (itemType.contains('sheet vinyl')) {
      score += 54;
    } else if (itemName.contains('lvp') || itemName.contains('lvt')) {
      score -= 16;
    }
  }
  if (RegExp(r'\b(peel stick|peel and stick|self stick)\b').hasMatch(text)) {
    if (itemType.contains('sheet vinyl') &&
        itemName.contains('peel and stick')) {
      score += 58;
    } else if (itemName.contains('sheet vinyl roll')) {
      score -= 18;
    }
  }
  if (RegExp(r'\b(carpet|berber|plush|frieze)\b').hasMatch(text)) {
    if (itemType.contains('carpet') && !itemName.contains('carpet pad')) {
      score += 50;
    }
  }
  if (RegExp(
    r'\b(carpet pad|tack strip|seam tape|binder bar)\b',
  ).hasMatch(text)) {
    if (itemType.contains('carpet pad')) {
      score += 56;
    } else if (itemName.contains('carpet flooring')) {
      score -= 16;
    }
  }
  if (RegExp(
        r'\b(floor underlayment|foam underlayment|cork underlayment|moisture barrier|vapor barrier|sound control underlayment|plywood underlayment)\b',
      ).hasMatch(text) &&
      itemType.contains('underlayment')) {
    score += 54;
  }
  if (RegExp(
        r'\b(self leveler|self leveling|floor leveler|floor patch|feather finish|leveler primer|floor primer|adhesive remover)\b',
      ).hasMatch(text) &&
      itemType.contains('leveler')) {
    score += 54;
  }
  if (RegExp(
    r'\b(t molding|t-molding|transition strip|reducer|end cap|threshold|quarter round|shoe molding|stair nose|metal transition)\b',
  ).hasMatch(text)) {
    if (itemType.contains('transition')) {
      score += 58;
    } else if (itemName.contains('plank') || itemName.contains('tile')) {
      score -= 14;
    }
  }
  if (RegExp(r'\bstair nose\b').hasMatch(text)) {
    if (itemName.contains('stair nose')) {
      score += 46;
    } else if (itemName.contains('threshold')) {
      score -= 18;
    }
  }
  if (RegExp(
        r'\b(floor adhesive|vinyl adhesive|wood flooring adhesive|carpet adhesive|pressure sensitive adhesive)\b',
      ).hasMatch(text) &&
      itemType.contains('adhesives')) {
    score += 54;
  }
  if (RegExp(
        r'\b(flooring installation kit|pull bar|tapping block|floor spacers|floor cleat|floor staple|floor repair|seam roller|floor cutter)\b',
      ).hasMatch(text) &&
      itemType.contains('adhesives')) {
    score += 46;
  }
  for (final size in [
    '4 mm',
    '5 mm',
    '6 mm',
    '7 mm',
    '8 mm',
    '10 mm',
    '12 mm',
    '12 x 12',
    '12 x 24',
    '18 x 18',
    '24 x 24',
    '6 x 36',
    '7 x 48',
    '72 in',
    '78 in',
    '94 in',
  ]) {
    if (_tileReceiptMentionsSize(text, size) &&
        (itemName.contains(size) || variant.contains(size))) {
      score += 26;
    }
  }
  for (final color in [
    'oak',
    'gray',
    'walnut',
    'hickory',
    'maple',
    'barnwood',
    'espresso',
    'chestnut',
    'carrara',
    'slate',
    'travertine',
    'beige',
    'taupe',
    'charcoal',
    'brown',
  ]) {
    if (text.contains(color) && itemName.contains(color)) score += 14;
  }
  if (RegExp(
    r'\b(thinset|grout|backer board|cement board|shower)\b',
  ).hasMatch(text)) {
    score -= 26;
  }
  if (RegExp(
    r'\b(floor paint|garage floor epoxy|porch paint)\b',
  ).hasMatch(text)) {
    score -= 24;
  }
  if (RegExp(
    r'\b(project panel|stair tread|handrail bracket|stair riser|baluster)\b',
  ).hasMatch(text)) {
    score -= 48;
  }
  if (RegExp(r'\b(roof|roofing|gutter|drip edge)\b').hasMatch(text)) {
    score -= 60;
  }
  if (RegExp(r'\b(thhn|awg|romex|nm-b|nmb|building wire)\b').hasMatch(text)) {
    score -= 90;
  }
  if (category == 'flooring detail stock') score += 6;
  return score;
}
