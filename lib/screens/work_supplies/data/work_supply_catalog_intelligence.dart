part of 'work_supply_catalog.dart';

const _catalogIntelligenceVersion = 'catalog-intelligence-2026-06-29';
const _parserRuleVersion = 'parser-rules-2026-06-29';

List<WorkSupplyMarketScope> _resolveWorkSupplyMarketScopes(
  WorkSupplyItem item,
) {
  if (item.trade == 'Plumbing') return _resolvePlumbingMarketScopes(item);
  final text = item.searchableText;
  final scopes = <WorkSupplyMarketScope>{WorkSupplyMarketScope.residential};
  if (_hasAny(text, _lightIndustrialSignals)) {
    scopes.add(WorkSupplyMarketScope.lightIndustrial);
  }
  if (_hasAny(text, _commercialSignals)) {
    scopes.addAll([
      WorkSupplyMarketScope.lightIndustrial,
      WorkSupplyMarketScope.commercial,
    ]);
  }
  if (_hasAny(text, _commercialOnlySignals)) {
    scopes
      ..remove(WorkSupplyMarketScope.residential)
      ..addAll([
        WorkSupplyMarketScope.lightIndustrial,
        WorkSupplyMarketScope.commercial,
      ]);
  }
  return List.unmodifiable(scopes);
}

WorkSupplyPackTier _resolveWorkSupplyPackTier(WorkSupplyItem item) {
  if (item.trade == 'Plumbing') return _resolvePlumbingPackTier(item);
  final text = item.searchableText;
  if (_hasAny(text, _completeTierSignals)) return WorkSupplyPackTier.complete;
  if (_isEverydayNonPlumbingCore(item, text)) return WorkSupplyPackTier.core;
  if (_hasAny(text, _professionalTierSignals)) {
    return WorkSupplyPackTier.professional;
  }
  if (_hasAny(text, _coreTierSignals)) return WorkSupplyPackTier.core;
  return WorkSupplyPackTier.standard;
}

WorkSupplyParserPriority _resolveWorkSupplyParserPriority(WorkSupplyItem item) {
  if (item.trade == 'Plumbing') {
    return switch (_resolvePlumbingPackTier(item)) {
      WorkSupplyPackTier.core => WorkSupplyParserPriority.everydayCore,
      WorkSupplyPackTier.standard => WorkSupplyParserPriority.common,
      WorkSupplyPackTier.professional => WorkSupplyParserPriority.occasional,
      WorkSupplyPackTier.complete => WorkSupplyParserPriority.specialty,
    };
  }
  final text = item.searchableText;
  if (_hasAny(text, _completeTierSignals)) {
    return WorkSupplyParserPriority.specialty;
  }
  if (_isEverydayNonPlumbingCore(item, text)) {
    return WorkSupplyParserPriority.everydayCore;
  }
  if (_hasAny(text, _professionalTierSignals)) {
    return WorkSupplyParserPriority.occasional;
  }
  if (_hasAny(text, _coreTierSignals)) {
    return WorkSupplyParserPriority.everydayCore;
  }
  return WorkSupplyParserPriority.common;
}

bool _isEverydayNonPlumbingCore(WorkSupplyItem item, String text) {
  if (item.trade == 'HVAC' && text.contains('condensate pump')) return true;
  return false;
}

List<String> _resolveWorkSupplyAliases(WorkSupplyItem item) {
  final text = item.searchableText;
  final size = item.trade == 'Plumbing'
      ? _resolvePlumbingSize(item, text)
      : _extractSize(text);
  final material = item.trade == 'Plumbing'
      ? _resolvePlumbingMaterial(item, text)
      : _firstMatched(text, _materialSignals);
  final shape = item.trade == 'Plumbing'
      ? _resolvePlumbingShape(item, text)
      : _firstMatched(text, _shapeSignals);
  final compactShape = _compactAliasShape(shape);
  return _cleanList([
    ...item.aliases,
    item.name,
    ..._spanishSignalsFor(item, material, size, shape),
    if (item.variant.isNotEmpty) '${item.variant} ${item.itemType}',
    if (size.isNotEmpty || material.isNotEmpty || compactShape.isNotEmpty)
      '$size $material $compactShape',
    if (size.isNotEmpty && compactShape.isNotEmpty) '$size $compactShape',
    if (material.isNotEmpty && compactShape.isNotEmpty)
      '$material $compactShape',
    if (size.isNotEmpty && material.isNotEmpty && item.itemType.isNotEmpty)
      '$size $material ${item.itemType}',
    if (item.itemType.isNotEmpty) item.itemType,
  ]).take(10).toList(growable: false);
}

String _compactAliasShape(String shape) {
  final value = shape.toLowerCase();
  if (value == 'elbow') return 'elb';
  if (value == 'tee') return 'tee';
  if (value == 'coupling') return 'cplg';
  if (value == 'adapter') return 'adpt';
  if (value == 'connector') return 'conn';
  return shape;
}

WorkSupplyItemIntelligence _resolveWorkSupplyItemIntelligence(
  WorkSupplyItem item,
) {
  if (_hasMeaningfulIntelligence(item.intelligence)) return item.intelligence;
  final text = item.searchableText;
  final material = item.trade == 'Plumbing'
      ? _resolvePlumbingMaterial(item, text)
      : _firstMatched(text, _materialSignals);
  final size = item.trade == 'Plumbing'
      ? _resolvePlumbingSize(item, text)
      : _extractSize(text);
  final connectionType = _firstMatched(text, _connectionSignals);
  final shape = item.trade == 'Plumbing'
      ? _resolvePlumbingShape(item, text)
      : _firstMatched(text, _shapeSignals);
  final packQuantity = _extractPackQuantity(text);
  return WorkSupplyItemIntelligence(
    material: material,
    size: size,
    connectionType: connectionType,
    shapeOrStyle: shape,
    packQuantity: packQuantity.isEmpty ? '1 each' : packQuantity,
    isConsumable: _hasAny(text, _consumableSignals),
    isDurable: !_hasAny(text, _consumableSignals),
    isBrandSpecific: _hasAny(text, _brandSignals),
    receiptPatterns: _receiptPatternsFor(item, material, size, shape),
    ocrMistakePatterns: _ocrLikeMistakePatternsFor(text),
    vendorMappings: _vendorMappingsFor(item, material, size, shape),
    attributeTokens: _attributeTokensFor(item, material, size, connectionType),
    negativeMatchTokens: _negativeMatchTokensFor(item, material, shape, text),
    highImportanceTokens: _highImportanceTokensFor(
      item,
      material,
      size,
      connectionType,
      shape,
      text,
    ),
    mediumImportanceTokens: _cleanList([
      item.category,
      item.system,
      item.itemType,
      packQuantity,
    ]),
    lowImportanceTokens: _cleanList([item.unit, item.trade]),
    ignoreTokens: const ['aisle', 'bay', 'shelf', 'dept', 'department'],
    classification: WorkSupplyItemClassification(
      inventoryCategory: item.category,
      expenseCategory: '${item.trade} materials',
      jobMaterialCategory: item.system,
      taxReportingCategory: 'materials',
      maintenanceRelevance: item.itemType,
      billableMaterial: true,
      defaultUnitCostBehavior: 'receipt-line-unit-cost',
      defaultMarkupBehavior: 'business-profile-material-markup',
    ),
    catalogVersion: _catalogIntelligenceVersion,
    parserVersion: _parserRuleVersion,
    sourceConfidence: 'auto-derived-from-catalog-fields',
    autoGenerated: true,
    needsReview: _needsManualReview(item, material, size, shape),
  );
}

List<WorkSupplyVendorMapping> _vendorMappingsFor(
  WorkSupplyItem item,
  String material,
  String size,
  String shape,
) {
  final family = _vendorFamilyCode(item, material, shape);
  final sizeCode = _vendorSafeCode(size.isEmpty ? item.variant : size);
  final itemCode = _vendorSafeCode(item.id);
  final label = _cleanList([
    item.name,
    item.trade,
    item.category,
    item.system,
    item.itemType,
    material,
    size,
    shape,
    'non-proprietary merchant-style receipt pattern',
  ]).join(' ');
  return [
    WorkSupplyVendorMapping(
      vendor: 'home depot style',
      code: 'HD-$family-$sizeCode-$itemCode',
      label: label,
    ),
    WorkSupplyVendorMapping(
      vendor: 'lowe style',
      code: 'LOWE-$family-$sizeCode-$itemCode',
      label: label,
    ),
    WorkSupplyVendorMapping(
      vendor: 'ace true value menards walmart local hardware style',
      code: 'HW-$family-$sizeCode-$itemCode',
      label: label,
    ),
    WorkSupplyVendorMapping(
      vendor: 'ferguson grainger supplyhouse tractor supply style',
      code: 'SUPPLY-$family-$sizeCode-$itemCode',
      label: label,
    ),
  ];
}

String _vendorFamilyCode(WorkSupplyItem item, String material, String shape) {
  return _vendorSafeCode(
    _cleanList([
      item.trade,
      item.system,
      item.itemType,
      material,
      shape,
    ]).join('-'),
  );
}

String _vendorSafeCode(String value) {
  final normalized = value
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  if (normalized.isEmpty) return 'GEN';
  return normalized.length <= 48 ? normalized : normalized.substring(0, 48);
}

const _coreTierSignals = [
  '1/2',
  '3/4',
  '1-1/2',
  '2 in',
  'pex',
  'pvc',
  'cpvc',
  'copper',
  'angle stop',
  'supply stop',
  'ball valve',
  'elbow',
  'tee',
  'coupling',
  'adapter',
  'trap',
  'toilet',
  'faucet',
  'water heater',
  'washer',
];

const _professionalTierSignals = [
  'backflow',
  'boiler',
  'hydronic',
  'cast iron',
  'no-hub',
  'pump',
  'well',
  'grease',
  'flushometer',
  'commercial',
  '4 in',
  '6 in',
];

const _completeTierSignals = [
  '8 in',
  '10 in',
  '12 in',
  'specialty',
  'legacy',
  'roof drain',
  'interceptor',
  'mop sink',
  'industrial',
];

const _lightIndustrialSignals = [
  'backflow',
  'boiler',
  'breaker',
  'capacitor',
  'contactor',
  'conduit',
  'condensate',
  'disconnect',
  'duct',
  'filter',
  'flex duct',
  'hydronic',
  'panel',
  'pump',
  'relay',
  'thermostat',
  'well',
  '4 in',
  '6 in',
  'commercial',
];

const _commercialSignals = [
  'cast iron',
  'no-hub',
  'grease',
  'flushometer',
  'roof drain',
  'interceptor',
  'mop sink',
  '8 in',
  '10 in',
  '12 in',
];

const _commercialOnlySignals = ['roof drain', 'grease interceptor', 'mop sink'];

const _materialSignals = {
  'cpvc': 'CPVC',
  'pvc': 'PVC',
  'pex': 'PEX',
  'aluminum': 'aluminum',
  'copper': 'copper',
  'brass': 'brass',
  'black iron': 'black iron',
  'galvanized': 'galvanized steel',
  'steel': 'steel',
  'zinc': 'zinc-plated steel',
  'cast iron': 'cast iron',
  'stainless': 'stainless steel',
  'rubber': 'rubber',
  'neoprene': 'neoprene',
  'nylon': 'nylon',
  'vinyl': 'vinyl',
  'foam': 'foam',
  'fiberglass': 'fiberglass',
  'paper': 'filter media',
  'led': 'LED lamp assembly',
  'lamp': 'lamp assembly',
  'bulb': 'lamp assembly',
  'wire': 'conductive metal',
  'cable': 'conductive metal',
  'breaker': 'electrical assembly',
  'receptacle': 'electrical device assembly',
  'outlet': 'electrical device assembly',
  'switch': 'electrical device assembly',
  'dimmer': 'electrical device assembly',
  'panel': 'electrical enclosure assembly',
  'load center': 'electrical enclosure assembly',
  'box': 'box material',
  'conduit': 'conduit material',
  'emt': 'galvanized steel',
  'fmc': 'flexible metal conduit',
  'lfmc': 'liquid-tight flexible metal conduit',
  'pvc conduit': 'PVC',
  'connector': 'connector material',
  'capacitor': 'electrical component assembly',
  'contactor': 'electrical component assembly',
  'transformer': 'electrical component assembly',
  'thermostat': 'control assembly',
  'relay': 'electrical component assembly',
  'fuse': 'electrical component assembly',
  'filter': 'filter media',
  'coil cleaner': 'service chemical',
  'cleaner': 'service chemical',
  'sealant': 'sealant',
  'mastic': 'duct sealant',
  'foil tape': 'foil tape',
  'duct': 'duct material',
  'sheet metal': 'galvanized steel',
  'furnace': 'equipment assembly',
  'blower': 'equipment component assembly',
  'motor': 'equipment component assembly',
  'ignitor': 'ignition component assembly',
  'flame sensor': 'ignition component assembly',
  'gas valve': 'gas control assembly',
  'line set': 'copper',
  'refrigerant': 'refrigerant',
  'r410a': 'refrigerant system assembly',
  'r454b': 'refrigerant system assembly',
  'r32': 'refrigerant system assembly',
  'condensate': 'condensate material',
  'condensate pipe': 'PVC',
  'condensate pump': 'pump assembly',
  'hydronic': 'hydronic system assembly',
  'boiler': 'hydronic system assembly',
  'baseboard': 'baseboard heater material',
  'radiator': 'hydronic heat material',
  'expansion tank': 'tank assembly',
  'relief valve': 'valve assembly',
  'air eliminator': 'hydronic vent assembly',
  'blower belt': 'rubber belt',
  'evaporator coil': 'coil assembly',
  'condenser': 'outdoor equipment assembly',
  'heat pump': 'outdoor equipment assembly',
  'package unit': 'packaged equipment assembly',
  'air handler': 'indoor equipment assembly',
  'b vent': 'galvanized vent material',
  'flue': 'vent material',
  'vent pipe': 'vent material',
  'garage door': 'door hardware assembly',
  'torsion spring': 'spring steel',
  'extension spring': 'spring steel',
  'roller': 'roller assembly',
  'hinge': 'steel hardware',
  'bracket': 'steel hardware',
  'track': 'galvanized steel',
  'opener': 'opener assembly',
  'photo eye': 'sensor assembly',
  'safety sensor': 'sensor assembly',
};

const _connectionSignals = {
  'push-fit': 'push-fit',
  'push fit': 'push-fit',
  'crimp': 'crimp',
  'expansion': 'expansion',
  'compression': 'compression',
  'sweat': 'sweat',
  'slip': 'slip',
  'thread': 'threaded',
  'fip': 'FIP',
  'mip': 'MIP',
  'no-hub': 'no-hub',
  'solvent': 'solvent weld',
  'barb': 'barb',
};

const _shapeSignals = {
  'air filter': 'air filter',
  'filter': 'filter',
  'run capacitor': 'capacitor',
  'capacitor': 'capacitor',
  'lamp': 'lamp',
  'bulb': 'lamp',
  'led': 'LED lamp',
  'contactor': 'contactor',
  'transformer': 'transformer',
  'thermostat': 'thermostat',
  'relay': 'relay',
  'fuse': 'fuse',
  'disconnect': 'disconnect',
  'whip': 'whip',
  'line set': 'line set',
  'flame sensor': 'flame sensor',
  'radiant manifold': 'radiant manifold part',
  'flow meter': 'flow meter',
  'actuator': 'actuator',
  'air vent': 'air vent',
  'condensate pipe': 'pipe',
  'condensate pump': 'pump',
  'condensate trap': 'trap',
  'drain treatment': 'drain treatment',
  'condensate vent tee': 'tee',
  'blower wheel': 'blower wheel',
  'brazing rod': 'brazing rod',
  'compression fitting': 'compression fitting',
  'radiant compression fitting': 'compression fitting',
  'hose adapter': 'adapter',
  'charging adapter': 'adapter',
  'charging hose set': 'hose set',
  'hose set': 'hose set',
  'service valve wrench': 'wrench',
  'wrench': 'wrench',
  'baseboard heating element': 'baseboard element',
  'baseboard enclosure': 'baseboard enclosure',
  'baseboard damper': 'baseboard damper',
  'hydronic expansion tank': 'expansion tank',
  'expansion tank': 'expansion tank',
  'relief valve': 'relief valve',
  'air eliminator': 'air eliminator',
  'blower belt': 'belt',
  'cogged blower belt': 'belt',
  'evaporator coil': 'evaporator coil',
  'condenser': 'condenser',
  'heat pump': 'heat pump',
  'side discharge': 'side discharge equipment',
  'package unit': 'package unit',
  'air handler': 'air handler',
  'furnace': 'furnace',
  'blower motor': 'blower motor',
  'fan motor': 'fan motor',
  'psc blower motor': 'blower motor',
  'ecm blower motor': 'blower motor',
  'condenser fan motor': 'fan motor',
  'b vent pipe': 'vent pipe',
  'b vent': 'b vent',
  'flue pipe': 'flue pipe',
  'vent pipe': 'vent pipe',
  'combustion air': 'combustion air',
  'duct': 'duct',
  'plenum': 'plenum',
  'register': 'register',
  'grille': 'grille',
  'diffuser': 'diffuser',
  'damper': 'damper',
  'sheet metal screw': 'sheet metal screw',
  'zip screw': 'sheet metal screw',
  'hanger strap': 'hanger strap',
  'strap': 'strap',
  'refrigerant': 'refrigerant',
  'coil cleaner': 'coil cleaner',
  'condenser coil cleaner': 'coil cleaner',
  'alkaline coil cleaner': 'coil cleaner',
  'mastic': 'mastic',
  'wire': 'wire',
  'cable': 'cable',
  'breaker': 'breaker',
  'receptacle': 'receptacle',
  'outlet': 'receptacle',
  'switch': 'switch',
  'dimmer': 'dimmer',
  'panel': 'panel',
  'load center': 'load center',
  'junction box': 'junction box',
  'ceiling fan rated': 'fan-rated box',
  'fan rated': 'fan-rated box',
  'device cover': 'device cover',
  'cover': 'cover',
  'box': 'box',
  'tape': 'tape',
  'round': 'round',
  'square': 'square',
  'conduit': 'conduit',
  'conduit body': 'conduit body',
  'set screw connector': 'connector',
  'set screw coupling': 'coupling',
  'compression connector': 'connector',
  'compression coupling': 'coupling',
  'straight connector': 'connector',
  'fmc connector': 'connector',
  'lfmc connector': 'connector',
  'wire connector': 'wire connector',
  'conduit strap screw': 'screw',
  'ground screw': 'screw',
  'machine screw': 'screw',
  'self tapping screw': 'screw',
  'plastic anchor': 'anchor',
  'toggle bolt': 'toggle bolt',
  'ground rod': 'ground rod',
  'ground clamp': 'ground clamp',
  'door section': 'door section',
  'torsion spring': 'torsion spring',
  'extension spring': 'extension spring',
  'roller': 'roller',
  'hinge': 'hinge',
  'track': 'track',
  'opener': 'opener',
  'safety sensor': 'safety sensor',
  'photo eye': 'safety sensor',
  'remote': 'remote',
  'keypad': 'keypad',
  'bottom seal': 'bottom seal',
  'weather seal': 'weather seal',
  'track bolt': 'track bolt',
  'carriage bolt': 'carriage bolt',
  'lag screw': 'lag screw',
  'drop-ear': 'drop-ear elbow',
  'drop ear': 'drop-ear elbow',
  '90': '90 elbow',
  'elbow': 'elbow',
  'tee': 'tee',
  'coupling': 'coupling',
  'adapter': 'adapter',
  'cap': 'cap',
  'plug': 'plug',
  'valve': 'valve',
  'trap': 'trap',
  'flange': 'flange',
  'nipple': 'nipple',
  'union': 'union',
  'bushing': 'bushing',
  'reducer': 'reducer',
  'washer': 'washer',
  'o-ring': 'o-ring',
  'ring': 'ring',
  'clamp': 'clamp',
};

const _consumableSignals = [
  'washer',
  'o-ring',
  'ring',
  'seal',
  'tape',
  'putty',
  'cement',
  'primer',
  'caulk',
  'screw',
  'fastener',
];

const _brandSignals = ['sharkbite', 'fernco', 'propress', 'oatey'];

bool _hasMeaningfulIntelligence(WorkSupplyItemIntelligence intelligence) {
  return intelligence.searchableTokens.any(
        (token) => token.trim().isNotEmpty,
      ) ||
      intelligence.autoGenerated ||
      intelligence.verifiedManually;
}

bool _hasAny(String text, List<String> signals) {
  return signals.any(text.contains);
}

String _firstMatched(String text, Map<String, String> signals) {
  for (final entry in signals.entries) {
    if (text.contains(entry.key)) return entry.value;
  }
  return '';
}

String _extractSize(String text) {
  final namedSize = RegExp(
    r'\b(?:small|medium|large|\d+\s*gang|new work|old work|remodel|round)\b',
  ).firstMatch(text);
  if (namedSize != null) return namedSize.group(0)!.trim();
  final hvacSize = RegExp(
    r'(?:^|\s)(?:no\s*\d+|[a-z]{1,2}\d{2,3}|\d+%|(?:\d+h/\d+c)|\d+\s*x\s*\d+(?:\s*x\s*\d+)?|\d+\s*(?:qt|quart|gal|gallon|oz|lb|pound))(?:\s|$)',
  ).firstMatch(text);
  if (hvacSize != null) return hvacSize.group(0)!.trim();
  final match = RegExp(
    r'\#\d+\b|\b\d+(?:-\d+/\d+|/\d+)?(?:\.\d+)?\s*(?:in|inch|od|awg|ft|feet|w|watt|watts|v|volt|volts|k|kelvin|mfd|uf|amp|amps|a|hp|ton|tons|cfm|btu|btu\/h)\b|\b\d+/\d+\b',
  ).firstMatch(text);
  return match?.group(0)?.trim() ?? '';
}

String _extractPackQuantity(String text) {
  final match = RegExp(r'\b(?:single|pair|\d+\s*pack)\b').firstMatch(text);
  return match?.group(0)?.trim() ?? '';
}

List<String> _receiptPatternsFor(
  WorkSupplyItem item,
  String material,
  String size,
  String shape,
) {
  final seeds = [
    item.name,
    '${item.variant} ${item.name}',
    if (size.isNotEmpty || material.isNotEmpty || shape.isNotEmpty)
      '$size $material $shape',
    ...item.aliases.take(6),
  ];
  final vendorStyleSeeds = [
    for (final seed in seeds.take(5)) ..._vendorStyleReceiptPatterns(seed),
  ];
  return _cleanList([
    for (final seed in seeds) seed,
    for (final seed in seeds) seed.toUpperCase().replaceAll(' IN ', 'IN '),
    ...vendorStyleSeeds,
    ..._spanishSignalsFor(item, material, size, shape),
  ]).take(16).toList(growable: false);
}

List<String> _vendorStyleReceiptPatterns(String value) {
  final compact = value
      .toUpperCase()
      .replaceAll(' SCHEDULE ', ' SCH ')
      .replaceAll(' WATER HEATER ', ' WTR HTR ')
      .replaceAll(' DISHWASHER ', ' DW ')
      .replaceAll(' FEMALE ', ' F ')
      .replaceAll(' MALE ', ' M ')
      .replaceAll(' ADAPTER', ' ADPT')
      .replaceAll(' COUPLING', ' CPLG')
      .replaceAll(' CONNECTOR', ' CONN')
      .replaceAll(' ELBOW', ' ELB')
      .replaceAll(' ELBOWS', ' ELBS')
      .replaceAll(' PIPE JOINT COMPOUND', ' PIPE DOPE')
      .replaceAll(' TOILET ', ' TLT ')
      .replaceAll(RegExp(r'\bIN\b'), 'IN')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return _cleanList([
    compact,
    if (compact.contains(' ')) 'HD $compact',
    if (compact.contains(' ')) 'SUPPLY $compact',
  ]);
}

List<String> _ocrLikeMistakePatternsFor(String text) {
  return _cleanList([
    if (text.contains('pex')) 'PEX->PFX',
    if (text.contains('pvc')) 'PVC->PYC',
    if (text.contains('cpvc')) 'CPVC->CPYG',
    if (text.contains('1/2')) '1/2->I/2',
    if (text.contains('elbow') || text.contains('elb')) 'ELB->E1B',
  ]);
}

List<String> _attributeTokensFor(
  WorkSupplyItem item,
  String material,
  String size,
  String connectionType,
) {
  final shape = item.trade == 'Plumbing'
      ? _resolvePlumbingShape(item, item.searchableText)
      : _firstMatched(item.searchableText, _shapeSignals);
  return _cleanList([
    item.trade,
    item.category,
    item.system,
    item.itemType,
    item.variant,
    material,
    size,
    connectionType,
    ...item.aliases,
    ..._spanishSignalsFor(item, material, size, shape),
  ]);
}

List<String> _spanishSignalsFor(
  WorkSupplyItem item,
  String material,
  String size,
  String shape,
) {
  final text = item.searchableText;
  final family = _spanishFamilyToken(item, shape, text);
  final sizeToken = _spanishSizeToken(size, item.variant);
  final materialToken = _spanishMaterialToken(material, text);
  return _cleanList([
    'es-US',
    'spanish',
    'medida 1 pulg',
    '$sizeToken $materialToken $family',
    '$family $sizeToken',
    if (item.trade == 'Plumbing') 'tubo $sizeToken',
    if (item.trade == 'Electrical') 'cable $sizeToken',
    if (item.trade == 'HVAC') 'filtro $sizeToken',
  ]);
}

String _spanishFamilyToken(WorkSupplyItem item, String shape, String text) {
  final value = '$shape ${item.itemType} $text'.toLowerCase();
  if (value.contains('adapter')) return 'adaptador';
  if (value.contains('box')) return 'caja';
  if (value.contains('tape')) return 'cinta';
  if (value.contains('elbow') || value.contains('ell')) return 'codo';
  if (value.contains('connector')) return 'conector';
  if (value.contains('conduit')) return 'conducto';
  if (value.contains('filter')) return 'filtro';
  if (value.contains('pump')) return 'bomba';
  if (value.contains('tank')) return 'tanque';
  if (value.contains('cap') || value.contains('plug')) return 'tapon';
  if (value.contains('valve')) return 'valvula';
  if (value.contains('pipe') || value.contains('tube')) return 'tubo';
  if (item.trade == 'Electrical') return 'cable';
  if (item.trade == 'HVAC') return 'filtro';
  return 'tubo';
}

String _spanishMaterialToken(String material, String text) {
  final value = '$material $text'.toLowerCase();
  if (value.contains('copper')) return 'cobre';
  if (value.contains('brass')) return 'laton';
  if (value.contains('steel')) return 'acero';
  if (value.contains('iron')) return 'hierro';
  if (value.contains('aluminum')) return 'aluminio';
  if (value.contains('pvc')) return 'pvc';
  if (value.contains('pex')) return 'pex';
  return material;
}

String _spanishSizeToken(String size, String variant) {
  final source = size.isEmpty ? variant : size;
  if (source.trim().isEmpty) return '1 pulg';
  final normalized = source
      .replaceAll(RegExp(r'\binch(?:es)?\b', caseSensitive: false), 'pulg')
      .replaceAll(RegExp(r'\bin\b', caseSensitive: false), 'pulg')
      .trim();
  if (RegExp(r'\b(?:pulg|mm|cm|metro|m)\b').hasMatch(normalized)) {
    return normalized;
  }
  if (RegExp(r'\d+\s*x\s*\d+').hasMatch(normalized.toLowerCase())) {
    return '$normalized pulg';
  }
  return '$normalized 1 pulg';
}

List<String> _negativeMatchTokensFor(
  WorkSupplyItem item,
  String material,
  String shape,
  String text,
) {
  const materials = ['PEX', 'PVC', 'CPVC', 'copper', 'brass', 'cast iron'];
  return _cleanList([
    for (final other in materials)
      if (shape.isNotEmpty &&
          material.isNotEmpty &&
          other.toLowerCase() != material.toLowerCase())
        '$other $shape',
    if (shape.isNotEmpty && !shape.contains('drop-ear')) 'drop-ear $shape',
    if (shape.isNotEmpty && material.toLowerCase() != 'pex') 'PEX crimp $shape',
    if (shape.isNotEmpty && material.toLowerCase() != 'pvc') 'PVC DWV $shape',
    ..._riskConflictNegativeMatchTokensFor(item, text),
  ]);
}

List<String> _highImportanceTokensFor(
  WorkSupplyItem item,
  String material,
  String size,
  String connectionType,
  String shape,
  String text,
) {
  return _cleanList([
    size,
    material,
    connectionType,
    shape,
    item.itemType,
    if (_containsWord(text, 'kit')) item.system,
    if (_containsWord(text, 'connector')) item.category,
    if (_containsWord(text, 'cement')) item.category,
    if (_containsWord(text, 'primer')) item.category,
    if (_containsWord(text, 'filter')) item.system,
    if (_containsWord(text, 'pvc')) item.system,
    if (_containsWord(text, 'pipe')) item.system,
  ]);
}

List<String> _riskConflictNegativeMatchTokensFor(
  WorkSupplyItem item,
  String text,
) {
  final trade = item.trade.toLowerCase();
  final riskTerms = _catalogRiskTermsFor(item, text);
  return _cleanList([
    if (riskTerms.contains('pvc') && trade != 'plumbing') 'plumbing pvc pipe',
    if (riskTerms.contains('pvc') && trade != 'electrical') 'pvc conduit',
    if (riskTerms.contains('pvc') && trade != 'hvac') 'hvac condensate pvc',
    if (riskTerms.contains('pipe') && trade != 'plumbing') 'plumbing pipe',
    if (riskTerms.contains('pipe') && trade != 'electrical') 'conduit pipe',
    if (riskTerms.contains('connector')) 'electrical connector',
    if (riskTerms.contains('connector')) 'framing connector',
    if (_containsWord(text, 'connectors')) 'electrical connector',
    if (_containsWord(text, 'connectors')) 'framing connector',
    if (riskTerms.contains('kit')) 'generic kit',
    if (riskTerms.contains('kit')) 'assortment kit',
    if (riskTerms.contains('cement')) 'pvc cement',
    if (riskTerms.contains('cement')) 'masonry cement',
    if (riskTerms.contains('primer')) 'pvc primer',
    if (riskTerms.contains('primer')) 'paint primer',
    if (riskTerms.contains('filter')) 'hvac air filter',
    if (riskTerms.contains('filter')) 'water filter',
    if (_hasFinishFilterCollisionRisk(item, text)) 'hvac air filter',
    if (_hasFinishFilterCollisionRisk(item, text)) 'water filter',
    if (riskTerms.contains('tape')) 'electrical tape',
    if (riskTerms.contains('tape')) 'drywall tape',
    if (riskTerms.contains('box')) 'electrical box',
    if (riskTerms.contains('box')) 'storage box',
    if (riskTerms.contains('gauge')) 'tire pressure gauge',
    if (riskTerms.contains('gauge')) 'air compressor gauge',
    if (riskTerms.contains('gauge')) 'fuel pressure gauge',
    if (riskTerms.contains('tank')) 'propane tank',
    if (riskTerms.contains('tank')) 'fuel tank',
    if (riskTerms.contains('tank')) 'air compressor tank',
    if (riskTerms.contains('valve')) 'plumbing valve',
    if (riskTerms.contains('valve')) 'gas valve',
  ]);
}

bool _hasFinishFilterCollisionRisk(WorkSupplyItem item, String text) {
  final haystack = [
    text,
    item.name,
    item.category,
    item.system,
    item.itemType,
    item.variant,
  ].join(' ').toLowerCase();
  return _containsWord(haystack, 'finish') ||
      _containsWord(haystack, 'blade') ||
      _containsWord(haystack, 'abrasive') ||
      _containsWord(haystack, 'underlayment') ||
      _containsWord(haystack, 'sandpaper');
}

bool _containsWord(String text, String word) {
  return RegExp(
    '(^|[^a-z0-9])${RegExp.escape(word)}([^a-z0-9]|\$)',
  ).hasMatch(text.toLowerCase());
}

Set<String> _catalogRiskTermsFor(WorkSupplyItem item, String text) {
  const risks = {
    'box',
    'cement',
    'connector',
    'filter',
    'gauge',
    'kit',
    'pipe',
    'primer',
    'pvc',
    'tank',
    'tape',
    'valve',
  };
  final tokens = _cleanList(
    [
      text,
      item.name,
      item.category,
      item.system,
      item.itemType,
      item.variant,
      ...item.aliases,
    ].join(' ').toLowerCase().split(RegExp(r'[^a-z0-9/.-]+')),
  );
  return risks
      .where(tokens.map((token) => token.toLowerCase()).contains)
      .toSet();
}

bool _needsManualReview(
  WorkSupplyItem item,
  String material,
  String size,
  String shape,
) {
  if (item.trade == 'Plumbing') {
    return _plumbingNeedsManualReview(item, material, size, shape);
  }
  final text = item.searchableText;
  return material.isEmpty ||
      (size.isEmpty &&
          _hasAny(text, _coreTierSignals) &&
          !_hasAny(text, _genericSizeOptionalSignals)) ||
      shape.isEmpty;
}

const _genericSizeOptionalSignals = [
  'kit',
  'assortment',
  'terminal',
  'compound',
  'sealant',
  'pipe dope',
  'tape',
  'spray',
  'tablet',
  'adapter',
  'wrench',
  'hose set',
  'clip',
  'latch',
  'gasket',
  'flame sensor',
  'line hide',
  'phos copper',
  'standard pack',
  'condensate trap',
  'vent condensate drain tee',
  'flow meter',
  'actuator',
  'air vent',
  'vent tee',
  'putty',
];

List<String> _cleanList(Iterable<String> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in values) {
    final cleaned = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) continue;
    final key = cleaned.toLowerCase();
    if (seen.add(key)) result.add(cleaned);
  }
  return List.unmodifiable(result);
}
