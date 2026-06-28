part of 'work_supply_receipt_parser.dart';

int _lowVoltageDataReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'low voltage and data') return score;
  if (text.contains('landscape') &&
      RegExp(
        r'\b(path light|spot light|well light|transformer|direct burial)\b',
      ).hasMatch(text)) {
    score -= 32;
  }
  if (RegExp(
    r'\b(cat5e|cat6|cat6a|cat7|ethernet|network cable|data cable|rj45|keystone|coax|rg6|rg59|fiber|low voltage|lv bracket|tester|toner|punchdown|poe camera|video doorbell|access control|door contact|hdmi|speaker plate|speaker pair|in wall speaker|in-wall speaker|in ceiling speaker|in-ceiling speaker|cable tie|j-hook|smart lock|smart thermostat|smart switch|leak sensor|network rack|rack pdu|rack mount ups|rack ups|cage nut|rack screw|poe splitter|poe extender|fiber distribution|smurf tube|flexible raceway|bridle ring|structured media|fiber pigtail|sfp transceiver|alarm battery|electric strike|8k hdmi)\b',
  ).hasMatch(text)) {
    score += 16;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  if (RegExp(
        r'\b(cat5e|cat6|cat6a|ethernet|network cable|data cable)\b',
      ).hasMatch(text) &&
      itemType.contains('network cable')) {
    score += 28;
  }
  for (final rating in ['cat5e', 'cat6a', 'cat7', 'cat6']) {
    if (text.contains(rating)) {
      if (itemName.contains(rating.toLowerCase())) {
        score += 28;
      } else if (itemName.contains('cat')) {
        score -= 18;
      }
    }
  }
  if (RegExp(r'\b(plenum|cmp)\b').hasMatch(text)) {
    if (itemName.contains('plenum') || itemName.contains('cmp')) {
      score += 22;
    } else if (itemType.contains('network cable')) {
      score -= 16;
    }
  }
  if (RegExp(r'\b(coax|rg6|rg59|coaxial)\b').hasMatch(text) &&
      itemName.contains('coax')) {
    score += 26;
  }
  if (RegExp(r'\b(fiber|lc-lc|sc-sc|fiber jumper)\b').hasMatch(text) &&
      itemName.contains('fiber')) {
    score += 26;
  }
  if (RegExp(r'\b(rj45|ethernet plug|mod plug)\b').hasMatch(text) &&
      itemName.contains('rj45')) {
    score += 26;
  }
  if (RegExp(r'\b(keystone|data jack)\b').hasMatch(text) &&
      itemName.contains('keystone')) {
    score += 24;
  }
  if (RegExp(r'\b(patch panel)\b').hasMatch(text) &&
      itemName.contains('patch panel')) {
    score += 24;
  }
  if (RegExp(
        r'\b(low voltage bracket|lv bracket|mud ring|data plate|media enclosure)\b',
      ).hasMatch(text) &&
      category == 'boxes and plates') {
    score += 24;
  }
  if (RegExp(r'\b(low voltage bracket|lv bracket)\b').hasMatch(text) &&
      itemName.contains('low voltage mounting bracket')) {
    score += 72;
  }
  if (RegExp(
        r'\b(hdmi|usb-c|speaker plate|binding post|banana plug)\b',
      ).hasMatch(text) &&
      itemType.contains('av wall')) {
    score += 26;
  }
  for (final connector in ['usb-c', 'hdmi', 'rca']) {
    if (text.contains(connector)) {
      if (itemName.contains(connector)) {
        score += 34;
      } else if (RegExp(
        r'\b(keystone|plate|jack|insert|coupler)\b',
      ).hasMatch(itemName)) {
        score -= 18;
      }
    }
  }
  for (final color in ['white', 'ivory', 'black', 'blue', 'gray']) {
    if (text.contains(color)) {
      if (itemName.contains(color)) {
        score += 22;
      } else if (RegExp(r'\b(keystone|plate|jack|insert)\b').hasMatch(text) &&
          RegExp(r'\b(keystone|plate|jack|insert)\b').hasMatch(itemName)) {
        score -= 12;
      }
    }
  }
  if (RegExp(
        r'\b(hdmi cable|high speed hdmi|in-wall hdmi|usb-c cable|speaker selector|volume control|ir repeater|ir emitter|hdmi extender|usb extender|patch cord|ethernet patch cord|speaker pair|in wall speaker|in-wall speaker|in ceiling speaker|in-ceiling speaker)\b',
      ).hasMatch(text) &&
      itemType.contains('av cable')) {
    score += 28;
  }
  if (RegExp(
        r'\b(patch cord|ethernet patch cord|patch cable|speaker pair|in wall speaker|in-wall speaker|in ceiling speaker|in-ceiling speaker|banana plug|hdmi coupler)\b',
      ).hasMatch(text) &&
      itemType.contains('patch cable')) {
    score += 30;
  }
  if (RegExp(r'\b(patch cord|patch cable)\b').hasMatch(text)) {
    if (itemName.contains('patch cord') || itemName.contains('patch cable')) {
      score += 80;
    } else if (itemType.contains('network cable')) {
      score -= 36;
    }
  }
  if (RegExp(
    r'\b(speaker pair|in wall speaker|in-wall speaker|in ceiling speaker|in-ceiling speaker)\b',
  ).hasMatch(text)) {
    if (itemName.contains('speaker pair')) {
      score += 80;
    } else if (itemType.contains('patch cable')) {
      score -= 24;
    }
  }
  if (RegExp(
        r'\b(poe camera|security camera|ip camera|video doorbell|nvr)\b',
      ).hasMatch(text) &&
      itemType.contains('security camera')) {
    score += 30;
  }
  if (RegExp(
    r'\b(video doorbell transformer|doorbell transformer)\b',
  ).hasMatch(text)) {
    if (text.contains('video doorbell') &&
        itemName.contains('doorbell transformer')) {
      score += 76;
    }
  }
  if (RegExp(
        r'\b(camera junction box|camera mount|camera bracket|cctv power supply|doorbell chime|doorbell power kit|doorbell wedge|exit button|no touch exit|request to exit|rex button)\b',
      ).hasMatch(text) &&
      itemType.contains('camera mounts')) {
    score += 30;
  }
  if (RegExp(
        r'\b(door contact|window contact|motion detector|access control|card reader|mag lock|electric strike|no touch exit|exit button)\b',
      ).hasMatch(text) &&
      itemType.contains('access')) {
    score += 30;
  }
  if (RegExp(r'\b(no touch exit button|exit button)\b').hasMatch(text) &&
      itemName.contains('exit button')) {
    score += 70;
  }
  if (RegExp(
        r'\b(smart lock|smart thermostat|smart dimmer|smart switch|smart plug|leak sensor|c-wire adapter|garage door controller|smart hub|smart keypad)\b',
      ).hasMatch(text) &&
      itemType.contains('smart home')) {
    score += 30;
  }
  if (RegExp(
        r'\b(tester|toner|tone generator|fox and hound|certifier|vfl)\b',
      ).hasMatch(text) &&
      category == 'testers and tools') {
    score += 24;
  }
  if (RegExp(
        r'\b(punchdown|punch down|rj45 crimper|coax crimper|stripper)\b',
      ).hasMatch(text) &&
      itemType.contains('termination')) {
    score += 24;
  }
  if (RegExp(
        r'\b(cable tie|velcro tie|cable label|wire marker|j-hook|rack)\b',
      ).hasMatch(text) &&
      itemType.contains('cable management')) {
    score += 24;
  }
  if (RegExp(
        r'\b(smurf tube|flexible raceway|cable raceway|bridle ring|cable d-ring|pull string|structured media enclosure|structured media power)\b',
      ).hasMatch(text) &&
      itemType.contains('structured wiring pathway')) {
    score += 42;
  }
  if (RegExp(r'\b(smurf tube|flexible raceway)\b').hasMatch(text)) {
    if (itemName.contains('smurf tube') ||
        itemName.contains('flexible raceway')) {
      score += 56;
    } else if (itemName.contains('cable raceway')) {
      score -= 10;
    }
  }
  if (RegExp(
        r'\b(network rack|wall mount rack|rack shelf|rack pdu|rack power|poe splitter|poe extender|poe injector|fiber distribution|fiber splice tray)\b',
      ).hasMatch(text) &&
      itemType.contains('rack')) {
    score += 28;
  }
  if (RegExp(
        r'\b(slim keystone|fiber pigtail|sfp transceiver|sfp plus transceiver|fiber splice cassette|poe injector|poe splitter|poe extender)\b',
      ).hasMatch(text) &&
      itemType.contains('network fiber')) {
    score += 42;
  }
  if (RegExp(r'\b(sfp transceiver|sfp plus transceiver)\b').hasMatch(text)) {
    if (itemName.contains('sfp')) {
      score += 58;
    } else if (itemName.contains('fiber')) {
      score -= 10;
    }
  }
  if (RegExp(
        r'\b(alarm backup battery|alarm battery|gel filled alarm splice|b connector alarm splice|electric strike|electric door strike|request to exit|card reader|alarm keypad|alarm siren)\b',
      ).hasMatch(text) &&
      itemType.contains('security access')) {
    score += 42;
  }
  if (RegExp(r'\b(alarm backup battery|alarm battery)\b').hasMatch(text)) {
    if (itemName.contains('alarm backup battery')) {
      score += 58;
    }
  }
  if (RegExp(
        r'\b(8k hdmi|active hdmi|optical hdmi|pass through plate|brush pass through|speaker volume control|smart hub|doorbell wedge|doorbell angle mount)\b',
      ).hasMatch(text) &&
      itemType.contains('av smart home')) {
    score += 42;
  }
  if (RegExp(r'\b(8k hdmi|active hdmi|optical hdmi)\b').hasMatch(text)) {
    if (itemName.contains('hdmi')) {
      score += 52;
    }
  }
  if (RegExp(
        r'\b(rack drawer|brush panel|blank panel|rack fan|rack ups|rack mount ups|uninterruptible power supply|cage nut|rack screw|velcro one wrap|velcro wrap)\b',
      ).hasMatch(text) &&
      itemType.contains('rack service')) {
    score += 30;
  }
  if (RegExp(
    r'\b(rack mount ups|rack ups|uninterruptible power supply)\b',
  ).hasMatch(text)) {
    if (itemName.contains('rack mount ups')) {
      score += 80;
    } else if (itemType.contains('cable management')) {
      score -= 24;
    }
  }
  if (RegExp(r'\b(cage nut|rack screw)\b').hasMatch(text)) {
    if (itemName.contains('cage nut') || itemName.contains('rack screw')) {
      score += 80;
    } else if (itemType.contains('cable management')) {
      score -= 8;
    }
  }
  if (RegExp(
    r'\b(romex|breaker|gfci|receptacle|concrete|mulch)\b',
  ).hasMatch(text)) {
    score -= 18;
  }
  return score;
}

int _toolsSafetyReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'tools and safety') return score;
  if (RegExp(
    r'\b(wrench|pliers|screwdriver|utility knife|saw blade|drill bit|gloves|safety glasses|n95|mask|tape measure|level|chalk line|duct tape|shop towels|trash bags|extension cord|work light|ladder|drop cloth|tarp|marking paint|bar clamp|tool bag|box fan|jobsite heater|fish tape|pipe wrench|pex crimp|drain auger|pressure gauge|thermal camera|torque wrench|rivet gun|staple gun|pipe threading die|closet auger|basin wrench|emt bender|pull string|breaker finder|wire stripper|roofing shovel|safety harness|roof anchor|lifeline|hepa filter|hepa vac|vac filter|dust shroud)\b',
  ).hasMatch(text)) {
    score += 16;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  if (RegExp(
        r'\b(adjustable wrench|crescent wrench|pliers|screwdriver|utility knife|hammer|pry bar)\b',
      ).hasMatch(text) &&
      itemType.contains('hand tools')) {
    score += 26;
  }
  if (RegExp(
        r'\b(saw blade|drill bit|driver bit|oscillating|reciprocating|razor blade|knife blade)\b',
      ).hasMatch(text) &&
      itemType.contains('saw blades')) {
    score += 26;
  }
  if (RegExp(
        r'\b(sds plus masonry bit set|masonry bit set|drill bit set)\b',
      ).hasMatch(text) &&
      itemType.contains('saw blades')) {
    score += 72;
  }
  if (text.contains('sds plus') && itemName.contains('sds plus')) {
    score += 90;
  } else if (text.contains('sds plus') &&
      itemName.contains('masonry bit set')) {
    score -= 90;
  }
  if (RegExp(
        r'\b(nitrile gloves|work gloves|cut resistant glove|cut resistant gloves|safety glasses|n95|dust mask|respirator|hard hat|ear plug)\b',
      ).hasMatch(text) &&
      category == 'safety') {
    score += 28;
  }
  if (RegExp(
        r'\b(cut resistant glove|cut resistant gloves)\b',
      ).hasMatch(text) &&
      itemName.contains('cut resistant glove')) {
    score += 64;
  }
  for (final size in ['m', 'l', 'xl', '2xl']) {
    if (RegExp('\\b$size\\b').hasMatch(text) && itemName.contains('$size ')) {
      score += 12;
    }
  }
  if (RegExp(
        r'\b(tape measure|level|laser level|chalk line|snap line|marker|pencil|marking paint)\b',
      ).hasMatch(text) &&
      category == 'measuring and layout') {
    score += 26;
  }
  if (text.contains('marking paint') && itemName.contains('marking paint')) {
    score += 34;
  }
  if (RegExp(
        r'\b(duct tape|masking tape|painter tape|construction adhesive|threadlocker)\b',
      ).hasMatch(text) &&
      itemType.contains('tapes')) {
    score += 24;
  }
  if (RegExp(
        r'\b(shop towels|rags|trash bags|demo bags|bucket|broom|degreaser)\b',
      ).hasMatch(text) &&
      itemType.contains('cleaning')) {
    score += 24;
  }
  if (RegExp(
        r'\b(drop cloth|poly tarp|plastic sheeting|floor protection)\b',
      ).hasMatch(text) &&
      itemType.contains('temporary')) {
    score += 26;
  }
  if (text.contains('poly tarp') && itemName.contains('poly tarp')) {
    score += 32;
  }
  if (RegExp(
        r'\b(extension cord|cord reel|gfci cord|work light|headlamp)\b',
      ).hasMatch(text) &&
      itemType.contains('jobsite power')) {
    score += 26;
  }
  if (RegExp(
        r'\b(step ladder|extension ladder|sawhorse|work platform)\b',
      ).hasMatch(text) &&
      itemType.contains('access')) {
    score += 26;
  }
  if (RegExp(
        r'\b(bar clamp|c-clamp|quick clamp|tool bag|parts organizer)\b',
      ).hasMatch(text) &&
      itemType.contains('tool support')) {
    score += 24;
  }
  if (RegExp(
        r'\b(fish tape|pipe wrench|pex crimp|pex clamp|pex expansion tool|pex ring cutter|drain auger|pressure gauge|manifold gauge|leak detector|thermal camera|moisture meter|torque screwdriver|torque wrench|breaker finder|stud sensor|grout float|margin trowel|shingle gauge|siding removal)\b',
      ).hasMatch(text) &&
      itemType.contains('specialty trade')) {
    score += 28;
  }
  if (RegExp(
        r'\b(pipe threading die|threading die|pipe threader|closet auger|toilet auger|basin wrench|sink wrench|pex ring cutter|crimp ring cutter|pvc cutter|snap cutter|tub drain wrench)\b',
      ).hasMatch(text) &&
      itemType.contains('pipe plumbing')) {
    score += 34;
  }
  if (RegExp(r'\b(pipe threading die|threading die)\b').hasMatch(text)) {
    if (itemName.contains('pipe threading die')) {
      score += 70;
    } else if (itemName.contains('pipe wrench')) {
      score -= 18;
    }
  }
  if (RegExp(
        r'\b(emt bender|conduit bender|pull string|pull line|fish rod|glow rod|breaker finder|circuit tracer|wire stripper|cable ripper|mc cable cutter|conduit reamer|wire marker)\b',
      ).hasMatch(text) &&
      itemType.contains('electrical test')) {
    score += 34;
  }
  if (RegExp(r'\b(emt bender|conduit bender)\b').hasMatch(text)) {
    if (itemName.contains('emt bender')) {
      score += 70;
    } else if (itemName.contains('conduit')) {
      score += 20;
    }
  }
  if (RegExp(
        r'\b(concrete trowel|concrete finishing trowel|magnesium hand float|notched trowel|tile trowel|grout float|roofing shovel|tear off shovel|shingle remover|roofing hatchet)\b',
      ).hasMatch(text) &&
      itemType.contains('concrete masonry')) {
    score += 34;
  }
  if (RegExp(
    r'\b(taping knife|drywall knife|mud pan|drywall mud pan)\b',
  ).hasMatch(text)) {
    score -= 22;
  }
  if (RegExp(r'\bpex\b').hasMatch(text) &&
      RegExp(r'\b(crimp|clamp)\b').hasMatch(text) &&
      itemName.contains('pex')) {
    score += 80;
  }
  if (RegExp(r'\bpex\b').hasMatch(text) &&
      RegExp(
        r'\b(expansion tool|tool head|ring cutter|crimp|clamp)\b',
      ).hasMatch(text) &&
      itemName.contains('pex') &&
      RegExp(r'\b(tool|head|cutter)\b').hasMatch(itemName)) {
    score += 90;
  }
  for (final pexTool in ['expansion tool head', 'clamp tool', 'crimp tool']) {
    final receiptTerm = pexTool == 'expansion tool head'
        ? 'expansion tool'
        : pexTool;
    if (text.contains(receiptTerm)) {
      if (itemName.contains(pexTool)) {
        score += 70;
      } else if (itemName.contains('pex') && itemName.contains('tool')) {
        score -= 30;
      }
    }
  }
  if (RegExp(
        r'\b(screw setter|nut setter|tile bit|masonry bit|hinge bit|rivet gun|staple gun|powder actuated|powder load|concrete nail driver)\b',
      ).hasMatch(text) &&
      itemType.contains('fastener anchor')) {
    score += 28;
  }
  if (RegExp(r'\b(screw setter|setter bit)\b').hasMatch(text) &&
      itemName.contains('screw setter')) {
    score += 80;
  }
  if (text.contains('bar clamp') && itemName.contains('bar clamp')) {
    score += 36;
  }
  if (RegExp(
        r'\b(box fan|drum fan|air mover|jobsite heater|propane heater)\b',
      ).hasMatch(text) &&
      itemType.contains('temporary jobsite')) {
    score += 24;
  }
  if (RegExp(
        r'\b(spill kit|absorbent pad|oil dry|lockout|safety harness|roof anchor)\b',
      ).hasMatch(text) &&
      itemType.contains('spill')) {
    score += 24;
  }
  if (RegExp(
        r'\b(safety harness|roof anchor|fall protection|roof safety kit|lifeline|lanyard|rope grab|self retracting lifeline)\b',
      ).hasMatch(text) &&
      itemType.contains('fall protection')) {
    score += 36;
  }
  if (RegExp(r'\b(roof safety kit|fall protection kit)\b').hasMatch(text)) {
    if (itemName.contains('roof safety kit') ||
        itemName.contains('harness and lanyard')) {
      score += 50;
    }
  }
  if (RegExp(
        r'\b(hepa filter|hepa vac filter|vac filter|vacuum filter|dust bag|dust collection bag|dust shroud|shop vac hose|shop vacuum hose|dust extractor|vacuum hose)\b',
      ).hasMatch(text) &&
      itemType.contains('dust control')) {
    score += 36;
  }
  if (RegExp(
    r'\b(hepa filter|hepa vac filter|vac filter|dust extractor hepa)\b',
  ).hasMatch(text)) {
    if (itemName.contains('hepa')) {
      score += 70;
    } else if (itemName.contains('shop towels')) {
      score -= 20;
    }
  }
  if (RegExp(r'\b(n95|dust mask)\b').hasMatch(text)) {
    if (itemName.contains('n95') || itemName.contains('dust mask')) {
      score += 24;
    } else if (category == 'safety') {
      score -= 10;
    }
  }
  if (RegExp(r'\b(7-1/4|6-1/2|10 in)\b').hasMatch(text) &&
      itemName.contains('saw blade')) {
    if (_containsExactPhrase(text, item.variant)) score += 20;
  }
  if (RegExp(
    r'\b(cat6|rj45|coax|thinset|concrete mix|mulch)\b',
  ).hasMatch(text)) {
    score -= 18;
  }
  return score;
}
