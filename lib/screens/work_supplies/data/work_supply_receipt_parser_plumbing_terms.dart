part of 'work_supply_receipt_parser.dart';

WorkSupplyItem? _directPlumbingFastMatch(String text) {
  return _directPlumbingWaterTreatmentMatch(text) ??
      _directPlumbingRepairKitMatch(text) ??
      _directPlumbingHandToolMatch(text);
}

WorkSupplyItem? _directPlumbingWaterTreatmentMatch(String text) {
  final wantedName = switch (text) {
    final value
        when RegExp(
          r'\b(brine\s+valve|brine\s+pickup|brine\s+pick\s*up)\b',
        ).hasMatch(value) =>
      'water softener brine valve',
    final value
        when RegExp(
          r'\b(brine\s+line|flow\s+control|flow\s+restrictor)\b',
        ).hasMatch(value) =>
      'water softener brine line flow control',
    final value when RegExp(r'\b(bypass\s+valve|bypass)\b').hasMatch(value) =>
      'water softener bypass valve',
    final value when RegExp(r'\b(resin|resina)\b').hasMatch(value) =>
      'softener resin bag',
    final value
        when RegExp(r'\b(ro|reverse\s+osmosis)\b').hasMatch(value) &&
            RegExp(r'\b(membrane|membrana)\b').hasMatch(value) =>
      'reverse osmosis membrane',
    final value
        when RegExp(r'\b(uv|ultraviolet)\b').hasMatch(value) &&
            RegExp(r'\b(quartz\s+sleeve|sleeve|manga)\b').hasMatch(value) =>
      'uv quartz sleeve',
    final value
        when RegExp(r'\b(uv|ultraviolet)\b').hasMatch(value) &&
            RegExp(r'\b(lamp|bulb|lampara)\b').hasMatch(value) =>
      'uv water treatment lamp',
    final value
        when RegExp(
          r'\b(softener\s+salt|salt\s+pellets|solar\s+salt|potassium\s+chloride)\b',
        ).hasMatch(value) =>
      RegExp(r'\b(solar)\b').hasMatch(value)
          ? 'solar salt crystals'
          : RegExp(r'\b(potassium)\b').hasMatch(value)
          ? 'potassium chloride softener pellets'
          : 'water softener salt pellets',
    final value
        when RegExp(
          r'\b(sal\s+suavizador|sal\s+ablandador|sal\s+para\s+suavizador)\b',
        ).hasMatch(value) =>
      'water softener salt pellets',
    final value
        when RegExp(
          r'\b(osmosis\s+inversa|osmosis inversa|membrana\s+osmosis)\b',
        ).hasMatch(value) =>
      'reverse osmosis membrane',
    _ => null,
  };
  if (wantedName == null) return null;
  return _firstPlumbingItemNamed(wantedName);
}

WorkSupplyItem? _directPlumbingRepairKitMatch(String text) {
  if (RegExp(
    r'\b(toilet repair kit|kit reparacion sanitario|'
    r'kit reparacion inodoro)\b',
  ).hasMatch(text)) {
    return _firstPlumbingItemNamed('toilet', ['fill valve']);
  }
  if (RegExp(
    r'\b(sink repair kit|lavatory repair kit|basin repair kit|'
    r'kit reparacion lavabo|kit reparacion fregadero)\b',
  ).hasMatch(text)) {
    return _firstPlumbingItemNamed('sink repair kit');
  }
  if (RegExp(
    r'\b(faucet repair kit|o-ring and seat kit|o ring and seat kit|'
    r'kit reparacion llave|kit reparacion grifo)\b',
  ).hasMatch(text)) {
    return _firstPlumbingItemNamed('faucet o-ring and seat kit');
  }
  return null;
}

WorkSupplyItem? _firstPlumbingItemNamed(
  String requiredName, [
  List<String> additionalNameTokens = const [],
]) {
  for (final item in workSupplyCatalogItems) {
    final name = item.name.toLowerCase();
    if (item.trade != 'Plumbing' || !name.contains(requiredName)) continue;
    if (additionalNameTokens.every(name.contains)) return item;
  }
  return null;
}

const plumbingReceiptTermAliases = {
  '90 elbow': ['90', '90d', 'el', 'ell', 'elbow'],
  '45 elbow': ['45', '45d', 'forty five', 'forty-five'],
  'tee': ['tee', 't fitting', 't'],
  'coupling': ['cplg', 'coup', 'coupler', 'coupling'],
  'reducing coupling': ['red coup', 'red cplg', 'reducer coupling'],
  'reducer': ['red', 'reducer'],
  'bushing': ['bush', 'bushing'],
  'street': ['street', 'st 90', 'st ell'],
  'wye': ['wye', 'y fitting', 'why fitting'],
  'sanitary tee': ['san tee', 'sanitary t', 'sanitary tee'],
  'trap adapter': [
    'trap adapter',
    'trap adaptor',
    'trap adpt',
    'trap adapt',
    'marvel adapter',
    'desanco adapter',
    'desanco',
  ],
  'copper': ['cop', 'cpr', 'cu', 'sweat', 'copper', 'c x c', 'cxc'],
  'copper pipe': [
    'copper pipe',
    'hard copper',
    'type l copper',
    'type m copper',
  ],
  'soft copper tubing': ['soft copper', 'copper roll', 'refrig copper'],
  'pvc schedule 40': [
    'sch40',
    'sch 40',
    's40',
    'sched40',
    'sched 40',
    'schedule 40',
    's x s',
    'sxs',
  ],
  'pvc schedule 40 pipe': ['pvc pipe', 'pvc stick', 'pressure pipe'],
  'pvc dwv': ['dwv', 'drain waste vent'],
  'pvc dwv pipe': ['dwv pipe', 'drain pipe', 'sewer pipe'],
  'abs dwv': ['abs', 'abs dwv', 'black drain', 'black dwv'],
  'abs dwv pipe': ['abs pipe', 'black drain pipe'],
  'cpvc': ['cpvc', 'cpv', 'cpv c'],
  'cpvc pipe': ['cpvc pipe', 'cpvc stick'],
  'pex': ['pex', 'crimp'],
  'pex tubing': ['pex tubing', 'pex pipe', 'pex roll'],
  'pex 90 elbow': ['pex elb', 'pex ell', 'pex l', 'pex 90d'],
  'pex tee': ['pex t', 'pex tee', 'pex red tee'],
  'pex coupling': ['pex coup', 'pex cplg'],
  'black iron': ['black iron', 'blk iron', 'black pipe', 'blk pipe', 'bi'],
  'galvanized': ['galv', 'galvanized', 'galv steel', 'galv stl'],
  'cast iron': ['cast iron', 'ci'],
  'no-hub': ['no hub', 'no-hub', 'nh'],
  'no-hub coupling': ['no hub cplg', 'nh cplg', 'shielded coupling'],
  'brass': ['brass', 'brs'],
  'compression': ['compression', 'comp'],
  'flare': ['flare', 'flr'],
  'barbed': ['barbed', 'barb', 'hose barb'],
  'compression gasket': ['compression gasket', 'service weight gasket'],
  'cleanout': ['cleanout', 'clean out', 'co', 'co plug', 'c/o plug'],
  'cleanout plug': [
    'cleanout plug',
    'clean out plug',
    'co plug',
    'c/o plug',
    'countersunk plug',
  ],
  'push-fit': [
    'push fit',
    'push-fit',
    'push-to-connect',
    'push connect',
    'push conn',
    'sharkbite',
  ],
  'male adapter': [
    'male adapter',
    'mip adapter',
    'mpt adapter',
    'male adapt',
    'sxm',
    's x m',
    'slip male',
  ],
  'female adapter': [
    'female adapter',
    'fip adapter',
    'fpt adapter',
    'female adapt',
    'sxf',
    's x f',
    'slip female',
  ],
  'slip joint': ['slip joint', 's/j', 'sj'],
  'union': ['union'],
  'nipple': ['nipple', 'pipe nipple', 'npt nipple', 'nip', 'nipl'],
  'ball valve': ['ball valve', 'bl valve', 'full port valve'],
  'vacuum relief valve': [
    'vacuum relief valve',
    'vac relief valve',
    'vac relief',
    'water heater vacuum relief',
    'wh vacuum relief',
  ],
  'angle stop': ['angle stop', 'angle valve', 'ang stop', 'shutoff'],
  'straight stop': ['straight stop', 'str stop', 'fixture stop'],
  'pressure reducing valve': [
    'pressure reducing valve',
    'prv',
    'press red valve',
  ],
  'water heater': ['water heater', 'wtr htr', 'wh', 'htr'],
  'temperature and pressure relief valve': [
    't p relief',
    't&p relief',
    'tp relief',
    'tpr valve',
    't and p valve',
  ],
  'drain valve': ['drain valve', 'boiler drain', 'heater drain'],
  'anode rod': ['anode', 'anode rod'],
  'sillcock': ['sillcock', 'sill cock', 'hose bibb', 'hose bib', 'frost free'],
  'closet bolt': ['closet bolt', 'johnny bolt', 'toilet bolt'],
  'wax ring': ['wax ring', 'closet wax', 'toilet wax'],
  'fill valve': ['fill valve', 'ballcock', 'toilet fill'],
  'flush valve': ['flush valve', 'toilet flush'],
  'flapper': ['flapper', 'toilet flapper'],
  'tailpiece': ['tailpiece', 'tail piece', 'sink tailpiece'],
  'tub drain': ['tub drain', 'waste and overflow', 'waste overflow'],
  'closet flange': ['closet flange', 'toilet flange', 'clst flange'],
  'air gap': ['air gap', 'dishwasher air gap'],
  'disposal splash guard': ['splash guard', 'disposal splash guard'],
  'primer': [
    'primer',
    'purple primer',
    'paint primer',
    'stain blocker',
    'bonding primer',
  ],
  'cement': ['cement', 'glue'],
  'crimp ring': ['crimp ring', 'pex ring'],
  'clamp ring': ['clamp ring', 'cinch ring'],
};
