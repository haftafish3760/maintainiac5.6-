part of 'work_supply_receipt_parser.dart';

WorkSupplyItem? _directPlumbingFastMatch(String text) {
  return _directPlumbingAbsDwvMatch(text) ??
      _directPlumbingPvcDwvMatch(text) ??
      _directPlumbingPexServiceFittingMatch(text) ??
      _directPlumbingWaterTreatmentMatch(text) ??
      _directPlumbingRepairKitMatch(text) ??
      _directPlumbingHoseBibbRepairPartMatch(text) ??
      _directPlumbingSolderingConsumableMatch(text) ??
      _directPlumbingHandToolMatch(text);
}

WorkSupplyItem? _directPlumbingAbsDwvMatch(String text) {
  if (!RegExp(r'\b(abs|black\s+dwv|black\s+drain)\b').hasMatch(text)) {
    return null;
  }
  final targetName = switch (text) {
    final value
        when RegExp(
          r'\b(trap\s+adapter|trap\s+adpt|marvel\s+adapter)\b',
        ).hasMatch(value) =>
      'abs dwv trap adapter',
    final value
        when RegExp(
          r'\b(san\s+tee|sanitary\s+tee|sanitary\s+t|santee)\b',
        ).hasMatch(value) =>
      'abs dwv sanitary tee',
    final value
        when RegExp(r'\b(wye|y\s+fitting|why\s+fitting)\b').hasMatch(value) =>
      'abs dwv wye',
    final value when RegExp(r'\b(cleanout|clean\s*out|co)\b').hasMatch(value) =>
      'abs dwv cleanout',
    final value when RegExp(r'\b45\b').hasMatch(value) => 'abs dwv 45 elbow',
    final value
        when RegExp(r'\b(ell|elb|elbow)\b').hasMatch(value) ||
            _hasReceiptNinetyDegreeEvidence(value) =>
      'abs dwv 90 elbow',
    final value
        when RegExp(r'\b(cpl|cplg|coupling|coupler)\b').hasMatch(value) =>
      'abs dwv coupling',
    _ => null,
  };
  if (targetName == null) return null;
  final size = _nominalReceiptSize(text);
  for (final item in workSupplyCatalogItems) {
    final name = item.name.toLowerCase();
    if (item.trade != 'Plumbing' || !name.contains(targetName)) continue;
    if (_nameMatchesReceiptMatrix(name, text) ||
        _receiptMatchesVariant(text, item.variant) ||
        _nameMatchesReceiptSize(name, size)) {
      return item;
    }
  }
  return null;
}

WorkSupplyItem? _directPlumbingHoseBibbRepairPartMatch(String text) {
  final wantedName = switch (text) {
    final value when RegExp(r'\bhose\s+bibb\s+washer\b').hasMatch(value) =>
      'hose bibb washer',
    final value when RegExp(r'\bhose\s+washer\b').hasMatch(value) =>
      'hose washer',
    final value when RegExp(r'\bsillcock\s+stem\s+packing\b').hasMatch(value) =>
      'sillcock stem packing',
    final value when RegExp(r'\bsillcock\s+handle\s+screw\b').hasMatch(value) =>
      'sillcock handle screw',
    final value when RegExp(r'\bsillcock\s+packing\s+nut\b').hasMatch(value) =>
      'sillcock packing nut',
    final value
        when RegExp(r'\bfrost\s+free\s+stem\s+washer\b').hasMatch(value) =>
      'frost free stem washer',
    final value
        when RegExp(
          r'\bfrost\s+free\s+vacuum\s+breaker\s+kit\b',
        ).hasMatch(value) =>
      'frost free vacuum breaker kit',
    final value
        when RegExp(
          r'\banti[-\s]*siphon\s+vacuum\s+breaker\s+kit\b',
        ).hasMatch(value) =>
      'anti-siphon vacuum breaker kit',
    final value when RegExp(r'\bvacuum\s+breaker\s+cap\b').hasMatch(value) =>
      'vacuum breaker cap',
    final value when RegExp(r'\bvacuum\s+breaker\s+washer\b').hasMatch(value) =>
      'vacuum breaker washer',
    _ => null,
  };
  if (wantedName == null) return null;
  return _firstPlumbingItemNamed(wantedName, ['hose bibb repair part']);
}

WorkSupplyItem? _directPlumbingPvcDwvMatch(String text) {
  if (!RegExp(r'\b(pvc|dwv)\b').hasMatch(text)) return null;
  if (RegExp(r'\b(abs|black\s+dwv|black\s+drain)\b').hasMatch(text)) {
    return null;
  }
  final targetName = switch (text) {
    final value
        when RegExp(
          r'\b(reducing\s+san\s+tee|reducing\s+sanitary|reducing\s+sanitary\s+tee)\b',
        ).hasMatch(value) =>
      'pvc dwv reducing sanitary tee',
    final value
        when RegExp(
          r'\b(reducing\s+cplg|reducing\s+coupling|reducer\s+coupling|dwv\s+reducer)\b',
        ).hasMatch(value) =>
      'pvc dwv reducing coupling',
    final value
        when RegExp(r'\b(test\s+tee|cleanout\s+tee)\b').hasMatch(value) =>
      'pvc dwv test tee',
    final value
        when RegExp(
          r'\b(trap\s+adapter|trap\s+adpt|marvel\s+adapter)\b',
        ).hasMatch(value) =>
      'pvc dwv trap adapter',
    final value
        when RegExp(
          r'\b(san\s+tee|sanitary\s+tee|sanitary\s+t|santee)\b',
        ).hasMatch(value) =>
      'pvc dwv sanitary tee',
    final value
        when RegExp(r'\b(wye|y\s+fitting|why\s+fitting)\b').hasMatch(value) =>
      'pvc dwv wye',
    final value when RegExp(r'\b(cleanout|clean\s*out|co)\b').hasMatch(value) =>
      'pvc dwv cleanout',
    final value when RegExp(r'\b45\b').hasMatch(value) => 'pvc dwv 45 elbow',
    final value
        when RegExp(r'\b(ell|elb|elbow)\b').hasMatch(value) ||
            _hasReceiptNinetyDegreeEvidence(value) =>
      'pvc dwv 90 elbow',
    final value when RegExp(r'\b(cplg|coupling|coupler)\b').hasMatch(value) =>
      'pvc dwv coupling',
    _ => null,
  };
  if (targetName == null) return null;
  final size = _nominalReceiptSize(text);
  for (final item in workSupplyCatalogItems) {
    final name = item.name.toLowerCase();
    if (item.trade != 'Plumbing' || !name.contains(targetName)) continue;
    if (_nameMatchesReceiptMatrix(name, text) ||
        _receiptMatchesVariant(text, item.variant) ||
        _nameMatchesReceiptSize(name, size)) {
      return item;
    }
  }
  return null;
}

WorkSupplyItem? _directPlumbingPexServiceFittingMatch(String text) {
  if (!RegExp(r'\bpex\b').hasMatch(text)) return null;
  final size = _nominalReceiptSize(text);
  final wantedItemType = switch (text) {
    final value
        when RegExp(
          r'\b(drop\s*ear|drop-ear|shower\s+elbow|stub\s*out\s+elbow)\b',
        ).hasMatch(value) =>
      'drop-ear elbows',
    final value
        when RegExp(
          r'\b(mip|male\s+adapter|m\s+adapter|m\s+adpt|crimp\s+male)\b',
        ).hasMatch(value) =>
      'male adapters',
    final value
        when RegExp(
          r'\b(fip|female\s+adapter|f\s+adapter|f\s+adpt|crimp\s+female)\b',
        ).hasMatch(value) =>
      'female adapters',
    final value
        when RegExp(
          r'\b(crimp\s+ring|crmp\s+ring|pex\s+ring)\b',
        ).hasMatch(value) =>
      'crimp rings',
    final value
        when RegExp(
          r'\b(clamp\s+ring|cinch\s+ring|cinch\s+clamp)\b',
        ).hasMatch(value) =>
      'clamp rings',
    final value when RegExp(r'\b(tee|t)\b').hasMatch(value) => 'tees',
    final value when RegExp(r'\b(cplg|coupling|coupler)\b').hasMatch(value) =>
      RegExp(r'\b(transition|trans)\b').hasMatch(value)
          ? 'transition couplings'
          : 'couplings',
    final value
        when RegExp(r'\b(ell|elb|elbow|codo)\b').hasMatch(value) ||
            _hasReceiptNinetyDegreeEvidence(value) =>
      '90 elbows',
    _ => null,
  };
  if (wantedItemType == null) return null;
  for (final item in workSupplyCatalogItems) {
    final itemType = _normalize(item.itemType);
    final system = _normalize(item.system);
    final variant = _normalize(item.variant);
    if (item.trade == 'Plumbing' &&
        system == 'pex' &&
        itemType == wantedItemType &&
        (size == null || variant == '$size in')) {
      return item;
    }
  }
  return null;
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

WorkSupplyItem? _directPlumbingSolderingConsumableMatch(String text) {
  final wantedName = switch (text) {
    final value
        when RegExp(
          r'\b(lead\s*free\s+solder|lf\s+solder|plumbing\s+solder|sweat\s+solder|silver\s+bearing\s+solder|tin\s+antimony)\b',
        ).hasMatch(value) =>
      'lead-free plumbing solder',
    final value
        when RegExp(
          r'\b(solder\s+flux|plumbing\s+flux|tinning\s+flux|paste\s+flux|water\s+soluble\s+flux)\b',
        ).hasMatch(value) =>
      'water soluble flux',
    final value
        when RegExp(
          r'\b(acid\s+brush|flux\s+brush|solder\s+brush)\b',
        ).hasMatch(value) =>
      'acid brush',
    final value
        when RegExp(
          r'\b(fitting\s+brush|fit\s+brush|copper\s+brush|tube\s+brush|wire\s+fitting\s+brush)\b',
        ).hasMatch(value) =>
      'copper fitting brush',
    final value
        when RegExp(
          r'\b(sand\s+cloth|emery\s+cloth|abrasive\s+cloth)\b',
        ).hasMatch(value) =>
      'plumber sand cloth',
    final value
        when RegExp(
          r'\b(heat\s+shield|flame\s+protector|torch\s+shield|flame\s+shield)\b',
        ).hasMatch(value) =>
      'soldering heat shield',
    final value
        when RegExp(
          r'\b(ma[pb]{1,2}[-\s]*pro|ma[pb]{1,2}\s+gas|map\s+gas)\b',
        ).hasMatch(value) =>
      'map-pro torch fuel',
    final value
        when RegExp(
              r'\b(propane|lp\s+fuel|propane\s+cylinder)\b',
            ).hasMatch(value) &&
            RegExp(r'\b(torch|fuel|cyl|cylinder|bottle)\b').hasMatch(value) =>
      'propane torch fuel',
    final value
        when RegExp(
          r'\b(torch\s+head|solder\s+torch|plumbing\s+torch|trigger\s+start\s+torch|self\s+lighting\s+torch)\b',
        ).hasMatch(value) =>
      'soldering torch head',
    _ => null,
  };
  if (wantedName == null) return null;
  return _firstPlumbingItemNamed(wantedName);
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
  'coupling': ['cpl', 'cplg', 'coup', 'coupler', 'coupling'],
  'reducing coupling': ['red cpl', 'red coup', 'red cplg', 'reducer coupling'],
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
  'compression union': ['comp un', 'comp union', 'compression union'],
  'nipple': ['nipple', 'pipe nipple', 'npt nipple', 'nip', 'nipl'],
  'ball valve': [
    'ball valve',
    'ball valv',
    'bl valve',
    'bv',
    'full port valve',
  ],
  'check valve': ['check valve', 'check valv', 'chk valve', 'one way valve'],
  'gate valve': ['gate valve', 'gate valv', 'water valve'],
  'vacuum relief valve': [
    'vacuum relief valve',
    'vac relief valve',
    'vac relief',
    'water heater vacuum relief',
    'wh vacuum relief',
  ],
  'vacuum breaker': ['vacuum breaker', 'vac breaker', 'vac brkr'],
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
  'faucet': ['faucet', 'fct'],
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
  'lead-free plumbing solder': [
    'lead free solder',
    'lf solder',
    'plumbing solder',
    'sweat solder',
    'tin antimony solder',
    'silver bearing solder',
  ],
  'water soluble flux': [
    'solder flux',
    'plumbing flux',
    'tinning flux',
    'paste flux',
    'water soluble flux',
  ],
  'acid brush': ['acid brush', 'flux brush', 'solder brush'],
  'copper fitting brush': [
    'fitting brush',
    'fit brush',
    'copper brush',
    'tube brush',
    'wire fitting brush',
  ],
  'plumber sand cloth': ['sand cloth', 'emery cloth', 'abrasive cloth'],
  'soldering heat shield': [
    'heat shield',
    'flame protector',
    'torch shield',
    'flame shield',
  ],
  'propane torch fuel': [
    'propane bottle',
    'propane cylinder',
    'propane fuel',
    'lp fuel',
    'torch fuel',
  ],
  'map-pro torch fuel': [
    'mapp gas',
    'map gas',
    'map-pro',
    'map pro fuel',
    'torch fuel',
  ],
  'soldering torch head': [
    'torch head',
    'solder torch',
    'plumbing torch',
    'trigger start torch',
  ],
  'crimp ring': ['crimp ring', 'pex ring'],
  'clamp ring': ['clamp ring', 'cinch ring'],
};
