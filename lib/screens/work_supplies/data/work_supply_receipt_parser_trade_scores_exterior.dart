part of 'work_supply_receipt_parser.dart';

int _insulationReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'insulation') return score;
  if (RegExp(
    r'\b(insulation|batt|fiberglass|mineral wool|rock wool|foam board|spray foam|loose fill|vapor barrier|house wrap|r-\d{2}|pipe insulation|weatherstrip|radiant barrier|water heater blanket|garage door insulation|acoustic sealant|sound panel|mass loaded vinyl|crawlspace liner|crawl space liner|crawlspace seam tape|termination bar|drainage mat|firestop collar|fire stop collar|firestop sealant|draft stop|putty pad|sound control batt|acoustic board|sound isolation clip|rafter vent|soffit baffle|attic vent chute|can light cover|foam gasket|insulation netting|cap nail|impaling clip|firestop wrap|sound isolation track)\b',
  ).hasMatch(text)) {
    score += 16;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final variant = item.variant.toLowerCase();
  if (RegExp(r'\b(r-\d{2}|batt|fiberglass batt|attic batt)\b').hasMatch(text) &&
      itemType.contains('batt')) {
    score += 28;
  }
  if (text.contains('kraft') && variant.contains('kraft')) score += 24;
  if (text.contains('unfaced') && variant.contains('unfaced')) score += 24;
  if (text.contains('foil') && variant.contains('foil')) score += 22;
  if (RegExp(
        r'\b(mineral wool|rock wool|sound batt|fire batt)\b',
      ).hasMatch(text) &&
      itemType.contains('mineral')) {
    score += 26;
  }
  if (RegExp(r'\b(foam board|rigid insulation|xps|polyiso)\b').hasMatch(text) &&
      itemType.contains('foam board')) {
    score += 26;
  }
  if (text.contains('polyiso') &&
      (variant.contains('polyiso') || itemName.contains('polyiso'))) {
    score += 34;
  }
  if (text.contains('xps') &&
      (variant.contains('xps') || itemName.contains('xps'))) {
    score += 28;
  }
  if (text.contains('r tech') &&
      (variant.contains('r-tech') || itemName.contains('r-tech'))) {
    score += 28;
  }
  if (RegExp(
        r'\b(spray foam|expanding foam|foam sealant|fire block foam)\b',
      ).hasMatch(text) &&
      itemType.contains('spray foam')) {
    score += 26;
  }
  if (RegExp(r'\b(fireblock|fire block)\b').hasMatch(text) &&
      (variant.contains('fire block') ||
          variant.contains('fireblock') ||
          itemName.contains('fire block') ||
          itemName.contains('fireblock'))) {
    score += 40;
  }
  if (RegExp(r'\b(fireblock|fire block)\b').hasMatch(text) &&
      itemName.contains('spray foam') &&
      !variant.contains('fire block') &&
      !variant.contains('fireblock')) {
    score -= 14;
  }
  if (RegExp(r'\b(blown insulation|loose fill|cellulose)\b').hasMatch(text) &&
      itemType.contains('loose fill')) {
    score += 24;
  }
  if (text.contains('cellulose')) {
    if (item.name.toLowerCase().contains('cellulose')) {
      score += 26;
    } else if (item.name.toLowerCase().contains('fiberglass')) {
      score -= 18;
    }
  }
  if (text.contains('fiberglass')) {
    if (item.name.toLowerCase().contains('fiberglass')) {
      score += 20;
    } else if (item.name.toLowerCase().contains('cellulose')) {
      score -= 14;
    }
  }
  if (RegExp(
        r'\b(vapor barrier|poly barrier|plastic sheeting|house wrap)\b',
      ).hasMatch(text) &&
      category == 'vapor barriers and accessories') {
    score += 24;
  }
  if (RegExp(
        r'\b(crawlspace liner|crawl space liner|crawlspace seam tape|crawl space tape|vapor barrier sealant|termination bar|drainage mat|foundation air sealant|crawlspace sealant)\b',
      ).hasMatch(text) &&
      itemType.contains('crawlspace')) {
    score += 34;
  }
  if (RegExp(r'\b(crawlspace seam tape|crawl space tape)\b').hasMatch(text)) {
    if (itemName.contains('crawlspace seam tape')) {
      score += 60;
    } else if (itemName.contains('house wrap tape') ||
        itemName.contains('seam tape')) {
      score -= 14;
    }
  }
  if (RegExp(r'\b(crawlspace liner|crawl space liner)\b').hasMatch(text)) {
    if (itemName.contains('crawlspace liner')) {
      score += 60;
    } else if (itemName.contains('vapor barrier')) {
      score -= 10;
    }
  }
  for (final mil in ['4 mil', '6 mil', '10 mil', '12 mil', '20 mil']) {
    final compact = mil.replaceAll(' ', '');
    if ((text.contains(mil) || text.contains(compact)) &&
        itemName.contains(mil)) {
      score += 44;
    } else if ((text.contains(mil) || text.contains(compact)) &&
        (itemName.contains('crawlspace liner') ||
            itemName.contains('vapor barrier')) &&
        !itemName.contains(mil)) {
      score -= 24;
    }
  }
  if (RegExp(
        r'\b(seam tape|house wrap tape|support wire|insulation hanger)\b',
      ).hasMatch(text) &&
      itemType.contains('tape')) {
    score += 20;
  }
  if (RegExp(
        r'\b(rafter vent|soffit baffle|attic vent chute|wind wash barrier|can light cover|recessed light cover|foam gasket|outlet gasket|switch gasket|air sealant)\b',
      ).hasMatch(text) &&
      itemType.contains('attic venting')) {
    score += 42;
  }
  if (RegExp(
    r'\b(rafter vent baffle|soffit vent baffle|attic vent chute)\b',
  ).hasMatch(text)) {
    if (itemName.contains('rafter vent baffle') ||
        itemName.contains('soffit vent baffle') ||
        itemName.contains('attic vent chute')) {
      score += 68;
    }
  }
  if (RegExp(r'\b(can light cover|recessed light cover)\b').hasMatch(text)) {
    if (itemName.contains('can light cover') ||
        itemName.contains('light cover')) {
      score += 52;
    } else if (itemName.contains('vapor barrier') ||
        itemName.contains('seam tape')) {
      score -= 16;
    }
  }
  if (RegExp(
        r'\b(insulation netting|blown in mesh|cap nail|house wrap cap|vapor barrier cap nail|foam board washer|impaling clip|stick pin|termination bar)\b',
      ).hasMatch(text) &&
      itemType.contains('fasteners')) {
    score += 42;
  }
  if (RegExp(r'\b(impaling clip|stick pin)\b').hasMatch(text)) {
    if (itemName.contains('impaling clip') || itemName.contains('stick pin')) {
      score += 56;
    } else if (itemName.contains('retainer clip')) {
      score -= 12;
    }
  }
  if (RegExp(
        r'\b(firestop collar|fire stop collar|firestop sleeve|firestop sealant|fire stop sealant|fireblock sealant|draft stop|intumescent|putty pad|fire pad|firestop wrap|pipe firestop boot|smoke seal)\b',
      ).hasMatch(text) &&
      itemType.contains('firestop')) {
    score += 36;
  }
  if (RegExp(
    r'\b(firestop wrap|pipe firestop boot|wrap strip)\b',
  ).hasMatch(text)) {
    if (itemName.contains('firestop wrap') ||
        itemName.contains('firestop boot')) {
      score += 58;
    } else if (itemName.contains('firestop collar')) {
      score -= 12;
    }
  }
  if (RegExp(r'\b(firestop collar|fire stop collar)\b').hasMatch(text)) {
    if (itemName.contains('firestop collar')) {
      score += 64;
    } else if (itemName.contains('pipe insulation')) {
      score -= 18;
    }
  }
  if (RegExp(
        r'\b(pipe insulation|foam pipe insulation|rubber pipe insulation|weatherstrip|door sweep|window insulation|foam gasket)\b',
      ).hasMatch(text) &&
      itemType.contains('weatherization')) {
    score += 28;
  }
  if (RegExp(
        r'\b(radiant barrier|reflective insulation|water heater blanket|garage door insulation|vent cover)\b',
      ).hasMatch(text) &&
      itemType.contains('weatherization')) {
    score += 28;
  }
  if (RegExp(
        r'\b(acoustic sealant|sound panel|acoustic panel|mass loaded vinyl|resilient channel|sound isolation)\b',
      ).hasMatch(text) &&
      itemType.contains('acoustic')) {
    score += 28;
  }
  if (RegExp(
        r'\b(sound control batt|sound batt|acoustic board|sound board|sound isolation clip|sound isolation track|hat channel|sound deadening|door sound seal)\b',
      ).hasMatch(text) &&
      itemType.contains('sound isolation')) {
    score += 34;
  }
  if (RegExp(r'\b(sound isolation clip|resilient channel)\b').hasMatch(text)) {
    if (itemName.contains('sound isolation clip') ||
        itemName.contains('resilient channel')) {
      score += 54;
    }
  }
  if (RegExp(
    r'\b(sound isolation track|sound isolation bracket)\b',
  ).hasMatch(text)) {
    if (itemName.contains('sound isolation track') ||
        itemName.contains('sound isolation bracket')) {
      score += 58;
    } else if (itemName.contains('sound isolation clip')) {
      score -= 12;
    }
  }
  if (RegExp(r'\b(fence|shingle|tile|thinset)\b').hasMatch(text)) score -= 16;
  return score;
}

int _fencingReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'fencing') return score;
  if (RegExp(
    r'\b(fence|fencing|picket|chain link|chainlink|vinyl fence|gate|barbed wire|welded wire|field fence|t-post|post concrete|ornamental fence|aluminum fence|post cap|post repair|electric fence|fence charger|poly wire|privacy slat|fence screen|silt fence|post anchor|pool fence|pet fence)\b',
  ).hasMatch(text)) {
    score += 16;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final variant = item.variant.toLowerCase();
  if (RegExp(r'\b(picket|privacy fence board|wood fence)\b').hasMatch(text) &&
      itemType.contains('wood fence')) {
    score += 26;
  }
  for (final style in ['dog ear picket', 'flat top picket', 'privacy board']) {
    if (text.contains(style) && itemName.contains(style)) {
      score += 64;
    } else if (text.contains(style) &&
        itemName.contains('wood fence') &&
        !itemName.contains(style)) {
      score -= 26;
    }
  }
  if (RegExp(r'\b(vinyl fence|privacy panel|vinyl rail)\b').hasMatch(text) &&
      itemType.contains('vinyl')) {
    score += 26;
  }
  if (RegExp(
        r'\b(chain link|chainlink|top rail|terminal post|line post)\b',
      ).hasMatch(text) &&
      itemType.contains('chain link')) {
    score += 26;
  }
  if (RegExp(
    r'\b(chain link|chainlink)\s+fabric\b|\bfabric\b',
  ).hasMatch(text)) {
    if (variant.contains('fabric') || itemName.contains('fabric')) {
      score += 42;
    } else if (variant.contains('post') ||
        itemName.contains('post') ||
        itemName.contains('rail')) {
      score -= 18;
    }
  }
  final chainGauge = RegExp(
    r'\b(9|11|11\.5)\s*(?:ga|gauge)\b',
  ).firstMatch(text);
  if (chainGauge != null && itemName.contains('chain link')) {
    final gauge = '${chainGauge.group(1)} gauge';
    if (itemName.contains(gauge)) {
      score += 46;
    } else if (itemName.contains('gauge')) {
      score -= 24;
    }
  }
  if (RegExp(
    r'\b(landscape fabric|weed barrier|landscaping fabric)\b',
  ).hasMatch(text)) {
    score -= 36;
  }
  if (RegExp(
        r'\b(welded wire|barbed wire|barb wire|field fence|farm fence)\b',
      ).hasMatch(text) &&
      itemType.contains('wire')) {
    score += 24;
  }
  if (RegExp(
        r'\b(t post|t-post|green t post|treated post|wood fence post)\b',
      ).hasMatch(text) &&
      itemType.contains('post')) {
    score += 24;
  }
  if (RegExp(r'\b(gate hinge|gate latch|gate kit|anti-sag)\b').hasMatch(text) &&
      itemType.contains('gate')) {
    score += 24;
  }
  if (text.contains('gate kit')) {
    if (itemName.contains('gate kit')) {
      score += 72;
    } else if (itemName.contains('walk gate') ||
        itemName.contains('farm gate')) {
      score -= 28;
    }
  }
  for (final width in ['4 ft', '5 ft', '6 ft', '8 ft', '10 ft', '12 ft']) {
    final compact = width.replaceAll(' ', '');
    if ((text.contains(width) || text.contains(compact)) &&
        itemName.contains(width)) {
      score += 32;
    }
  }
  if (RegExp(
        r'\b(walk gate|farm gate|driveway gate|gate opener|gate operator|gate wheel|drop rod)\b',
      ).hasMatch(text) &&
      itemType.contains('driveway')) {
    score += 28;
  }
  if (RegExp(
        r'\b(ornamental fence|aluminum fence|steel fence|fence finial)\b',
      ).hasMatch(text) &&
      itemType.contains('ornamental')) {
    score += 28;
  }
  if (RegExp(
        r'\b(post cap|post repair sleeve|mending plate|rail repair bracket|fence tie|hog ring|wire stretcher)\b',
      ).hasMatch(text) &&
      itemType.contains('repair')) {
    score += 28;
  }
  if (RegExp(
        r'\b(electric fence|fence charger|poly wire|poly tape|fence insulator|gate handle|voltage tester)\b',
      ).hasMatch(text) &&
      itemType.contains('electric')) {
    score += 30;
  }
  if (RegExp(
        r'\b(privacy slat|fence screen|privacy screen|windscreen|reed fence|bamboo fence|willow fence|screen clip)\b',
      ).hasMatch(text) &&
      itemType.contains('privacy')) {
    score += 30;
  }
  if (RegExp(r'\b(fence screen|privacy screen|windscreen)\b').hasMatch(text)) {
    if (variant.contains('fence privacy screen') ||
        itemName.contains('fence privacy screen')) {
      score += 36;
    } else if (variant.contains('privacy fence roll') ||
        itemName.contains('privacy fence roll')) {
      score -= 18;
    }
  }
  if (RegExp(r'\b(reed fence|bamboo fence|willow fence)\b').hasMatch(text)) {
    if (variant.contains('privacy fence roll') ||
        itemName.contains('privacy fence roll')) {
      score += 36;
    }
  }
  if (RegExp(
        r'\b(orange safety fence|temporary fence|silt fence|silt fence fabric|fence stake|temporary fence panel)\b',
      ).hasMatch(text) &&
      itemType.contains('temporary')) {
    score += 30;
  }
  if (RegExp(
        r'\b(post anchor|post base anchor|post anchor spike|adjustable post base|rail bracket|fence flange)\b',
      ).hasMatch(text) &&
      itemType.contains('anchor')) {
    score += 30;
  }
  if (RegExp(
        r'\b(pool fence|pool gate latch|pool gate hinge|pet fence|child safety fence)\b',
      ).hasMatch(text) &&
      itemType.contains('pool')) {
    score += 30;
  }
  if (RegExp(
        r'\b(gate keypad|gate opener keypad|photo eye sensor|gate opener solar|control board|exit wand)\b',
      ).hasMatch(text) &&
      itemType.contains('gate opener')) {
    score += 30;
  }
  if (RegExp(
        r'\b(fence screw|fence staple|tension band|brace band)\b',
      ).hasMatch(text) &&
      itemType.contains('fastener')) {
    score += 22;
  }
  if (text.contains('tension band') &&
      (variant.contains('tension band') || itemName.contains('tension band'))) {
    score += 34;
  }
  if (text.contains('brace band') &&
      (variant.contains('brace band') || itemName.contains('brace band'))) {
    score += 34;
  }
  if (text.contains('tension band') && itemName.contains('brace band')) {
    score -= 18;
  }
  if (text.contains('brace band') && itemName.contains('tension band')) {
    score -= 18;
  }
  if (RegExp(
        r'\b(post concrete|fence post concrete|post foam)\b',
      ).hasMatch(text) &&
      itemType.contains('concrete')) {
    score += 22;
  }
  if (RegExp(r'\b(insulation|batt|thinset|shingle)\b').hasMatch(text)) {
    score -= 16;
  }
  return score;
}

int _masonryConcreteReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'masonry and concrete') return score;
  if (RegExp(
    r'\b(concrete|mortar|cement|block|brick|cmu|rebar|remesh|anchor|tapcon|form board|sonotube|paver|patio stone|control joint|backer rod|acid stain|weep screed|metal lath|flue liner|refractory mortar|paver restraint|masonry bit|diamond blade)\b',
  ).hasMatch(text)) {
    score += 16;
  }
  final itemType = item.itemType.toLowerCase();
  final normalizedVariant = _normalize(item.variant);
  if (RegExp(
        r'\b(concrete mix|high strength concrete|fast setting concrete|ready mix|quikrete|sakrete)\b',
      ).hasMatch(text) &&
      itemType.contains('concrete')) {
    score += 28;
  }
  if (RegExp(r'\b5000\s*psi\b').hasMatch(text) &&
      normalizedVariant.contains('5000 psi')) {
    score += 42;
  }
  if (RegExp(
        r'\b(fiber reinforced|crack resistant|countertop)\b',
      ).hasMatch(text) &&
      RegExp(
        r'\b(fiber reinforced|crack resistant|countertop)\b',
      ).hasMatch(normalizedVariant)) {
    score += 36;
  }
  if (RegExp(r'\b(integral concrete color|concrete color)\b').hasMatch(text) &&
      itemType.contains('additive')) {
    score += 34;
  }
  if (RegExp(r'\b(charcoal|buff|red|brown|terra cotta)\b').hasMatch(text) &&
      RegExp(
        r'\b(charcoal|buff|red|brown|terra cotta)\b',
      ).hasMatch(normalizedVariant)) {
    score += 24;
  }
  if (RegExp(
        r'\b(mortar|type n|type s|type m|masonry mortar)\b',
      ).hasMatch(text) &&
      itemType.contains('mortar')) {
    score += 26;
  }
  if (RegExp(r'\btype\s*n\b').hasMatch(text) &&
      normalizedVariant.contains('type n')) {
    score += 34;
  }
  if (RegExp(r'\btype\s*s\b').hasMatch(text) &&
      normalizedVariant.contains('type s')) {
    score += 34;
  }
  if (RegExp(r'\btype\s*m\b').hasMatch(text) &&
      normalizedVariant.contains('type m')) {
    score += 34;
  }
  if (RegExp(
        r'\b(portland cement|masonry cement|hydraulic cement|cement)\b',
      ).hasMatch(text) &&
      item.name.toLowerCase().contains('cement')) {
    score += 24;
  }
  if (RegExp(r'\b(block|cinder block|cmu|brick|fire brick)\b').hasMatch(text) &&
      category == 'masonry materials') {
    score += 26;
  }
  final masonrySize = RegExp(
    r'\b(\d{1,2}\s*x\s*\d{1,2}\s*x\s*\d{1,2})\b',
  ).firstMatch(text);
  if (masonrySize != null &&
      RegExp(r'\b(block|cmu|brick|paver|patio stone)\b').hasMatch(text)) {
    final receiptSize = masonrySize.group(1)!.replaceAll(RegExp(r'\s+'), ' ');
    if (normalizedVariant.contains(receiptSize)) {
      score += 34;
    } else if (category == 'masonry materials') {
      score -= 18;
    }
  }
  if (RegExp(
        r'\b(rebar|reinforcing bar|remesh|wire mesh|tie wire|rebar chair|dobie)\b',
      ).hasMatch(text) &&
      category == 'reinforcement and forms') {
    score += 26;
  }
  if (RegExp(
        r'\b(form board|form lumber|form stake|expansion joint|sonotube|form tube)\b',
      ).hasMatch(text) &&
      itemType.contains('forming')) {
    score += 24;
  }
  if (RegExp(
        r'\b(wedge anchor|tapcon|concrete screw|masonry screw|sleeve anchor|drop-in anchor)\b',
      ).hasMatch(text) &&
      itemType.contains('anchor')) {
    score += 26;
  }
  if (text.contains('tapcon') &&
      (normalizedVariant.contains('tapcon') ||
          normalizedVariant.contains('concrete screw anchor'))) {
    score += 42;
  }
  if (RegExp(
        r'\b(concrete patch|crack repair|resurfacer|paver sealer|masonry sealer|foundation coating)\b',
      ).hasMatch(text) &&
      itemType.contains('repair')) {
    score += 24;
  }
  if (RegExp(
        r'\b(expansion joint|control joint|zip strip|backer rod|isolation joint)\b',
      ).hasMatch(text) &&
      itemType.contains('concrete joint')) {
    score += 32;
  }
  if (RegExp(r'\b(zip strip|control joint)\b').hasMatch(text) &&
      (normalizedVariant.contains('control joint') ||
          normalizedVariant.contains('zip strip'))) {
    score += 44;
  }
  if (RegExp(
        r'\b(concrete stain|acid stain|concrete dye|concrete color|integral color|stamped concrete release|densifier|wet look sealer)\b',
      ).hasMatch(text) &&
      itemType.contains('concrete stain')) {
    score += 32;
  }
  if (RegExp(
        r'\b(weep screed|stucco bead|corner bead|metal lath|wire lath|stucco netting)\b',
      ).hasMatch(text) &&
      itemType.contains('stucco')) {
    score += 32;
  }
  if (RegExp(
        r'\b(fire brick|flue liner|flue tile|refractory mortar|fireplace mortar|chimney crown|smoke chamber)\b',
      ).hasMatch(text) &&
      itemType.contains('fire brick')) {
    score += 32;
  }
  if (RegExp(
        r'\b(paver|patio stone|wall block|stepping stone|fire pit block)\b',
      ).hasMatch(text) &&
      itemType.contains('pavers')) {
    score += 22;
  }
  if (RegExp(r'\b(holland paver|rectangle paver|wall cap)\b').hasMatch(text) &&
      normalizedVariant.contains(
        RegExp(
              r'\b(holland paver|rectangle paver|wall cap)\b',
            ).firstMatch(text)?.group(1) ??
            '',
      )) {
    score += 32;
  }
  if (RegExp(r'\b(form tube|sonotube)\b').hasMatch(text) &&
      normalizedVariant.contains('form tube')) {
    score += 34;
  }
  final formTubeSize = RegExp(
    r'\b(\d{1,2})\s*in\s*x\s*(\d{2,3})\s*in\b',
  ).firstMatch(text);
  if (formTubeSize != null && normalizedVariant.contains('form tube')) {
    final diameter = '${formTubeSize.group(1)} in';
    final height = '${formTubeSize.group(2)} in';
    if (normalizedVariant.contains(diameter) &&
        normalizedVariant.contains(height)) {
      score += 42;
    } else if (normalizedVariant.contains(diameter)) {
      score += 12;
    }
  }
  if (RegExp(r'\bblue concrete screw\b').hasMatch(text) &&
      normalizedVariant.contains('blue concrete screw')) {
    score += 38;
  }
  if (RegExp(
        r'\b(paver edge|paver restraint|edge restraint|paver spike|permeable paver grid|paver joint|joint stabilizer)\b',
      ).hasMatch(text) &&
      itemType.contains('paver edge')) {
    score += 32;
  }
  if (RegExp(
        r'\b(masonry bit|sds masonry bit|concrete diamond blade|masonry blade|brick chisel|mason line)\b',
      ).hasMatch(text) &&
      itemType.contains('masonry blades')) {
    score += 32;
  }
  if (text.contains('bit set') && itemType.contains('masonry blades')) {
    score -= 28;
  }
  if (RegExp(r'\bsds\s*plus\s*masonry\s*bit\b').hasMatch(text) &&
      normalizedVariant.contains('sds plus masonry bit')) {
    score += 44;
  }
  final masonryBitSize = RegExp(
    r'\b(\d/\d)\s*in\s*(?:sds\s*plus\s*)?masonry\s*bit\b',
  ).firstMatch(text);
  if (masonryBitSize != null &&
      normalizedVariant.contains('${masonryBitSize.group(1)} in') &&
      normalizedVariant.contains('masonry bit')) {
    score += 28;
  }
  if (RegExp(
        r'\b(block adhesive|masonry adhesive|epoxy anchor)\b',
      ).hasMatch(text) &&
      itemType.contains('adhesive')) {
    score += 34;
  }
  if (RegExp(r'\b(mulch|topsoil|sprinkler|drip|irrigation)\b').hasMatch(text)) {
    score -= 18;
  }
  return score;
}

int _landscapingReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'landscaping') return score;
  if (RegExp(
    r'\b(landscape|landscaping|irrigation|drip|sprinkler|corrugated drain|catch basin|wattle|paver base|mulch|topsoil|fabric|weed barrier|grass seed|fertilizer|sod|pine straw|weed killer|herbicide|pump sprayer|trimmer line|mower blade|path light|paver sealer|geogrid|tree tie|plant stake|root stimulator|two cycle oil|mower spark plug)\b',
  ).hasMatch(text)) {
    score += 16;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final variant = item.variant.toLowerCase();
  if (RegExp(
        r'\b(irrigation pipe|poly pipe|funny pipe|drip tubing|drip line|drip emitter)\b',
      ).hasMatch(text) &&
      itemType.contains('irrigation')) {
    score += 28;
  }
  if (RegExp(r'\bblu-?lock\b').hasMatch(text)) {
    if (itemName.contains('blu-lock')) {
      score += 58;
    } else if (itemType.contains('irrigation')) {
      score -= 16;
    }
  }
  for (final fitting in ['coupling', 'elbow', 'tee', 'adapter']) {
    if (RegExp('\\b$fitting\\b').hasMatch(text) && itemName.contains(fitting)) {
      score += 24;
    }
  }
  if (RegExp(
        r'\b(pressure compensating drip emitter|pc drip emitter|drip manifold|drip pressure regulator|drip filter|drip flush valve|valve box lid|valve box extension|valve diaphragm|irrigation valve solenoid)\b',
      ).hasMatch(text) &&
      itemType.contains('drip emitters')) {
    score += 42;
  }
  if (RegExp(r'\b(pressure compensating|pc)\b').hasMatch(text) &&
      text.contains('emitter')) {
    if (itemName.contains('pressure compensating')) {
      score += 62;
    } else if (itemName.contains('drip emitter')) {
      score -= 10;
    }
  }
  if (text.contains('funny pipe') &&
      (itemName.contains('funny pipe') || variant.contains('funny pipe'))) {
    score += 36;
  }
  if (RegExp(
        r'\b(sprinkler head|rotor|pop-up|irrigation valve|timer|solenoid)\b',
      ).hasMatch(text) &&
      itemType.contains('irrigation control')) {
    score += 26;
  }
  if (RegExp(
        r'\b(sprinkler wire|irrigation wire|waterproof wire connector|grease cap|valve repair|diaphragm)\b',
      ).hasMatch(text) &&
      itemType.contains('irrigation repair')) {
    score += 28;
  }
  if (text.contains('sprinkler wire')) {
    if (itemName.contains('sprinkler wire')) {
      score += 82;
    } else if (itemName.contains('landscape wire')) {
      score -= 40;
    }
  }
  if (RegExp(
        r'\b(sprinkler nozzle|spray nozzle|cut off riser|cut-off riser|riser extension|rotor tool|sprinkler head cap|filter screen)\b',
      ).hasMatch(text) &&
      itemType.contains('sprinkler nozzles')) {
    score += 34;
  }
  if (RegExp(r'\b(irrigation|sprinkler)\b').hasMatch(text) &&
      RegExp(
        r'\b(grease cap|waterproof connector|waterproof wire connector)\b',
      ).hasMatch(text) &&
      (itemName.contains('grease cap') ||
          itemName.contains('waterproof wire connector'))) {
    score += 80;
  }
  if (RegExp(
        r'\b(corrugated drain|french drain|ez drain|catch basin|drain box|drain grate|pop-up drainage)\b',
      ).hasMatch(text) &&
      category == 'drainage and erosion') {
    score += 28;
  }
  if (RegExp(
        r'\b(ez drain|catch basin|drain grate|channel drain)\b',
      ).hasMatch(text) &&
      itemType.contains('drainage')) {
    score += 34;
  }
  if (RegExp(r'\bcatch basin\b').hasMatch(text)) {
    if (RegExp(
      r'\b(catch basin grate|catch basin riser|catch basin outlet)\b',
    ).hasMatch(text)) {
      if (itemName.contains('catch basin grate') ||
          itemName.contains('catch basin riser') ||
          itemName.contains('catch basin outlet')) {
        score += 58;
      }
    } else if (itemName.contains('catch basin') &&
        !itemName.contains('atrium grate')) {
      score += 72;
    } else if (itemName.contains('atrium grate')) {
      score -= 24;
    }
  }
  if (RegExp(
        r'\b(channel drain grate|channel drain end cap|channel drain outlet|channel drain coupler|catch basin grate|catch basin riser|atrium grate|pop up emitter|pop-up emitter|downspout adapter|french drain sock)\b',
      ).hasMatch(text) &&
      itemType.contains('drainage channel')) {
    score += 42;
  }
  if (RegExp(r'\bchannel drain grate\b').hasMatch(text)) {
    if (itemName.contains('channel drain grate')) {
      score += 72;
    } else if (itemName.contains('catch basin grate')) {
      score -= 24;
    }
  }
  if (RegExp(r'\b(atrium grate|yard drain grate)\b').hasMatch(text)) {
    if (itemName.contains('atrium grate')) score += 58;
  }
  if (text.contains('ez drain') &&
      (itemName.contains('ez drain') || variant.contains('ez drain'))) {
    score += 80;
  }
  if (RegExp(
        r'\b(straw wattle|erosion wattle|silt fence|erosion blanket)\b',
      ).hasMatch(text) &&
      itemType.contains('erosion')) {
    score += 26;
  }
  if (RegExp(
        r'\b(paver base|leveling sand|polymeric sand|landscape edging|plastic landscape edging|steel landscape edging|aluminum landscape edging)\b',
      ).hasMatch(text) &&
      itemType.contains('hardscape')) {
    score += 26;
  }
  if (text.contains('paver base')) {
    if (itemName.contains('paver base')) {
      score += 72;
    } else if (itemName.contains('polymeric sand')) {
      score -= 24;
    }
  }
  if (text.contains('landscape edging') &&
      variant.contains('landscape edging')) {
    score += 54;
  }
  if (RegExp(
        r'\b(no dig edging|no-dig edging|edging spike|paver edge spike|artificial turf|putting green turf|turf seam tape|artificial turf adhesive|retaining wall cap|retaining wall pin|paver sand base panel)\b',
      ).hasMatch(text) &&
      itemType.contains('edging turf')) {
    score += 42;
  }
  if (RegExp(r'\bretaining wall cap\b').hasMatch(text)) {
    if (itemName.contains('retaining wall cap')) {
      score += 76;
    } else if (itemName.contains('wall cap')) {
      score += 20;
    }
  }
  if (RegExp(r'\b(artificial turf|putting green turf)\b').hasMatch(text)) {
    if (itemName.contains('artificial turf') ||
        itemName.contains('putting green turf')) {
      score += 58;
    }
  }
  if (RegExp(
        r'\b(paver sealer|paver cleaner|geogrid|edge restraint|paver spacer|paver joint)\b',
      ).hasMatch(text) &&
      itemType.contains('hardscape adhesives')) {
    score += 34;
  }
  if (RegExp(r'\b(landscape block adhesive|block adhesive)\b').hasMatch(text) &&
      itemType.contains('hardscape adhesives')) {
    score -= 44;
  }
  if (RegExp(
        r'\b(paver stone|patio paver|patio stone|retaining wall|river rock|pea gravel)\b',
      ).hasMatch(text) &&
      category == 'hardscape') {
    score += 24;
  }
  if (RegExp(
        r'\b(mulch|topsoil|garden soil|compost|fertilizer|lime|soil conditioner)\b',
      ).hasMatch(text) &&
      itemType.contains('ground')) {
    score += 26;
  }
  if (RegExp(
        r'\b(grass seed|fescue|bermuda|ryegrass|weed and feed|grub control)\b',
      ).hasMatch(text) &&
      itemType.contains('lawn care')) {
    score += 28;
  }
  if (RegExp(
        r'\b(weed killer|herbicide|brush killer|pre-emergent|insect control|sod roll|sod patch|pine straw|wheat straw|pump sprayer|backpack sprayer)\b',
      ).hasMatch(text) &&
      itemType.contains('lawn and landscape treatment')) {
    score += 28;
  }
  if (text.contains('weed killer') &&
      (itemName.contains('weed killer') || variant.contains('weed killer'))) {
    score += 64;
  }
  if (RegExp(
        r'\b(tree tie|plant stake|plant support|root stimulator|tree watering bag|tree fertilizer spike|burlap|guying kit|bird netting|deer netting)\b',
      ).hasMatch(text) &&
      itemType.contains('planting and tree support')) {
    score += 34;
  }
  if (RegExp(
        r'\b(landscape fabric|weed barrier|fabric staple|tree stake)\b',
      ).hasMatch(text) &&
      itemType.contains('accessory')) {
    score += 24;
  }
  if (RegExp(
        r'\b(shovel|rake|tamper|post hole digger|trimmer line|mower blade|edger blade|yard waste bag|garden hose)\b',
      ).hasMatch(text) &&
      itemType.contains('landscape tool')) {
    score += 26;
  }
  if (RegExp(
        r'\b(trimmer line|weed eater string|mower blade|mulching blade|high lift blade|edger blade|two cycle oil|2 cycle oil|mower spark plug|primer bulb|trimmer head|brush cutter)\b',
      ).hasMatch(text) &&
      itemType.contains('power equipment consumables')) {
    score += 34;
  }
  if (RegExp(
        r'\b(landscape light|path light|spot light|well light|low voltage landscape wire|low voltage transformer|photocell)\b',
      ).hasMatch(text) &&
      itemType.contains('landscape lighting')) {
    score += 26;
  }
  if (RegExp(
        r'\b(direct burial landscape wire|smart landscape transformer|hardscape wall light|deck step light|waterproof landscape wire nut|pierce point wire connector|landscape lighting wire connector|astronomical landscape timer|smart outdoor plug)\b',
      ).hasMatch(text) &&
      itemType.contains('lighting timer')) {
    score += 42;
  }
  if (text.contains('low voltage') &&
      text.contains('landscape') &&
      itemType.contains('lighting timer')) {
    score += 34;
  }
  if (RegExp(r'\b\d{2}/2\b').hasMatch(text) &&
      text.contains('landscape wire')) {
    if (itemName.contains('landscape wire')) {
      score += 72;
    } else if (itemName.contains('transformer')) {
      score -= 30;
    }
  }
  if (text.contains('low voltage landscape wire')) {
    if (itemName.contains('low voltage landscape wire')) {
      score += 54;
    } else if (itemName.contains('direct burial landscape wire')) {
      score -= 20;
    }
  }
  final landscapeWireLength = RegExp(r'\b(50|100|250)\s*ft\b').firstMatch(text);
  if (landscapeWireLength != null &&
      itemName.contains('${landscapeWireLength.group(1)} ft') &&
      itemName.contains('landscape wire')) {
    score += 34;
  }
  if (text.contains('weed barrier') &&
      (itemName.contains('weed barrier') || variant.contains('weed barrier'))) {
    score += 28;
  }
  if (text.contains('landscape fabric') &&
      (itemName.contains('landscape fabric') ||
          variant.contains('landscape fabric'))) {
    score += 28;
  }
  for (final term in [
    'spray nozzle',
    'cut-off riser',
    'paver sealer',
    'geogrid',
    'tree tie',
    'plant stake',
    'root stimulator',
    'tree watering bag',
    'two cycle',
    'mower spark plug',
  ]) {
    if (text.contains(term) && variant.contains(term)) score += 42;
  }
  if (RegExp(r'\b(rebar|tapcon|cmu|mortar|concrete anchor)\b').hasMatch(text)) {
    score -= 18;
  }
  return score;
}

int _sidingExteriorReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'siding and exterior') return score;
  if (RegExp(
    r'\b(siding|vinyl siding|dutch lap|lap siding|fiber cement|engineered siding|t1-11|shake siding|shingle siding|starter strip|j channel|f channel|undersill|outside corner|inside corner|corner post|trim coil|pvc trim|mounting block|housewrap|house wrap|flashing tape|rain screen|drainage mat|siding caulk|siding sealant|zip tool|gable vent|foundation vent|dryer vent hood|vinyl shutter|siding nail|fiber cement screw)\b',
  ).hasMatch(text)) {
    score += 18;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final variant = item.variant.toLowerCase();
  if (RegExp(
    r'\b(vinyl siding|dutch lap|d4|d5|board batten)\b',
  ).hasMatch(text)) {
    if (itemType.contains('vinyl siding')) {
      score += 60;
    } else if (itemName.contains('fiber cement')) {
      score -= 18;
    }
  }
  if (RegExp(r'\bd4\b').hasMatch(text)) {
    if (itemName.contains('double 4 in')) {
      score += 74;
    } else if (itemName.contains('double 5 in') || itemName.contains('4 x 8')) {
      score -= 36;
    }
  }
  if (RegExp(r'\bd5\b').hasMatch(text)) {
    if (itemName.contains('double 5 in')) {
      score += 74;
    } else if (itemName.contains('double 4 in') || itemName.contains('4 x 8')) {
      score -= 36;
    }
  }
  if (RegExp(
    r'\b(fiber cement|cement siding|engineered siding|lap siding|t1-11)\b',
  ).hasMatch(text)) {
    if (itemType.contains('fiber cement')) {
      score += 58;
    } else if (itemName.contains('vinyl siding')) {
      score -= 18;
    }
  }
  if (RegExp(r'\bfiber cement\b').hasMatch(text)) {
    if (itemName.contains('fiber cement')) {
      score += 68;
    } else if (itemName.contains('engineered wood') ||
        itemName.contains('cedar texture')) {
      score -= 28;
    }
  }
  if (RegExp(r'\bengineered (wood )?siding\b').hasMatch(text)) {
    if (itemName.contains('engineered wood')) {
      score += 58;
    } else if (itemName.contains('fiber cement')) {
      score -= 24;
    }
  }
  if (RegExp(
    r'\b(shake siding|shingle siding|scallop siding)\b',
  ).hasMatch(text)) {
    if (itemType.contains('shake')) {
      score += 56;
    } else if (itemName.contains('lap siding')) {
      score -= 14;
    }
  }
  if (RegExp(
    r'\b(starter strip|j channel|j-channel|f channel|undersill|finish trim|utility trim|corner post|outside corner|inside corner)\b',
  ).hasMatch(text)) {
    if (itemType.contains('starter')) {
      score += 58;
    } else if (itemName.contains('siding panel')) {
      score -= 16;
    }
  }
  if (RegExp(
    r'\b(pvc trim|trim board|trim coil|aluminum coil|mounting block|siding block)\b',
  ).hasMatch(text)) {
    if (itemType.contains('trim boards')) {
      score += 56;
    } else if (itemName.contains('siding trim')) {
      score -= 12;
    }
  }
  if (RegExp(
    r'\b(housewrap|house wrap|flashing tape|seam tape|rain screen|drainage mat|sill pan|window flashing|door sill pan)\b',
  ).hasMatch(text)) {
    if (itemType.contains('housewrap')) {
      score += 56;
    } else if (category == 'vapor barriers and accessories') {
      score -= 20;
    }
  }
  if (text.contains('exterior door sill pan')) {
    score -= 180;
  }
  if (text.contains('dryer vent hood')) {
    score -= 120;
  }
  if (RegExp(r'\bhousewrap roll\b').hasMatch(text)) {
    if (itemName.contains('housewrap roll') &&
        !itemName.contains('drainage') &&
        !itemName.contains('commercial')) {
      score += 62;
    } else if (itemName.contains('commercial') ||
        itemName.contains('drainage')) {
      score -= 18;
    }
  }
  if (RegExp(
    r'\b(siding caulk|siding sealant|polyurethane sealant|siding repair|fiber cement patch|zip tool)\b',
  ).hasMatch(text)) {
    if (itemType.contains('sealant')) {
      score += 54;
    } else if (itemName.contains('siding panel')) {
      score -= 14;
    }
  }
  if (RegExp(
    r'\b(gable vent|foundation vent|dryer vent hood|louver vent|vinyl shutter|shutter pair)\b',
  ).hasMatch(text)) {
    if (itemType.contains('vents')) {
      score += 54;
    }
  }
  if (RegExp(
    r'\b(siding nail|ring shank siding nail|trim nail|fiber cement screw|siding screw)\b',
  ).hasMatch(text)) {
    if (itemType.contains('fasteners')) {
      score += 54;
    } else if (itemName.contains('shutter') || itemName.contains('vent')) {
      score -= 12;
    }
  }
  for (final length in ['10 ft', '12 ft', '1-1/4 in', '1-1/2 in', '2 in']) {
    final compact = length.replaceAll(' ', '');
    if ((text.contains(length) || text.contains(compact)) &&
        (itemName.contains(length) || variant.contains(length))) {
      score += 26;
    }
  }
  for (final color in [
    'white',
    'almond',
    'clay',
    'sandstone',
    'gray',
    'charcoal',
    'brown',
    'black',
    'blue',
    'sage',
    'cedar',
    'tan',
  ]) {
    if (text.contains(color) && itemName.contains(color)) score += 14;
  }
  if (RegExp(
    r'\b(shingle bundle|roofing nail|roof cement|ridge cap|k style gutter|gutter guard|micro mesh gutter guard)\b',
  ).hasMatch(text)) {
    score -= 54;
  }
  if (RegExp(
    r'\b(thhn|awg|romex|nm-b|nmb|bi nipple|black iron nipple|galv stl tee|pvc dwv|san tee)\b',
  ).hasMatch(text)) {
    score -= 80;
  }
  if (RegExp(r'\b(batt|fiberglass|foam board|r-\d{2})\b').hasMatch(text)) {
    score -= 18;
  }
  if (category == 'siding exterior detail stock') score += 6;
  return score;
}
