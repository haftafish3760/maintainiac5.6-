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
  if (item.trade == 'Electrical') {
    if (_isElectricalLowVoltageCoreCable(text)) return WorkSupplyPackTier.core;
    if (_isElectricalResidentialDisconnect(item)) {
      return WorkSupplyPackTier.core;
    }
    if (_isElectricalCoreItem(item, text)) return WorkSupplyPackTier.core;
    if (_hasAny(text, _electricalProfessionalTierSignals)) {
      return WorkSupplyPackTier.professional;
    }
    if (_hasAny(text, _completeTierSignals)) return WorkSupplyPackTier.complete;
    return WorkSupplyPackTier.standard;
  }
  if (_hasAny(text, _completeTierSignals)) return WorkSupplyPackTier.complete;
  if (item.trade == 'HVAC') {
    if (_isHvacCoreItem(item, text)) return WorkSupplyPackTier.core;
    if (_hasAny(text, _hvacProfessionalTierSignals)) {
      return WorkSupplyPackTier.professional;
    }
    return WorkSupplyPackTier.standard;
  }
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
  if (item.trade == 'Electrical') {
    if (_isElectricalCoreItem(item, text)) {
      return WorkSupplyParserPriority.everydayCore;
    }
    if (_hasAny(text, _electricalProfessionalTierSignals)) {
      return WorkSupplyParserPriority.occasional;
    }
    return WorkSupplyParserPriority.common;
  }
  if (item.trade == 'HVAC') {
    if (_isHvacCoreItem(item, text)) {
      return WorkSupplyParserPriority.everydayCore;
    }
    if (_hasAny(text, _hvacProfessionalTierSignals)) {
      return WorkSupplyParserPriority.occasional;
    }
    return WorkSupplyParserPriority.common;
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

bool _isElectricalLowVoltageCoreCable(String text) {
  return _hasAny(text, ['low voltage cable', 'thermostat wire', 'stat wire']) &&
      _hasAny(text, ['18/2', '18/4', '18/5', '16/2', '14/2']) &&
      !text.contains('500 ft');
}

bool _isElectricalResidentialDisconnect(WorkSupplyItem item) {
  final text = '${item.name} ${item.variant} ${item.itemType} ${item.system}'
      .toLowerCase();
  return _hasAny(text, ['disconnect', 'non-fusible', 'fusible', 'pullout']) &&
      _hasAny(text, ['30 amp', '60 amp']) &&
      !_hasAny(text, ['100 amp', '200 amp', 'safety switch']);
}

bool _isEverydayNonPlumbingCore(WorkSupplyItem item, String text) {
  if (item.trade == 'HVAC' && text.contains('condensate pump')) return true;
  return false;
}

bool _isElectricalCoreItem(WorkSupplyItem item, String text) {
  final category = item.category.toLowerCase();
  final system = item.system.toLowerCase();
  if (category == 'bulk electrical catalog pack') {
    if (_hasAny(text, ['mc cable', 'armored cable']) &&
        _hasAny(text, ['14/2', '12/2', '10/2'])) {
      return true;
    }
    if (_hasAny(text, ['flexible raceway', 'flexible metal', 'fmc']) &&
        _hasAny(text, ['1/2', '3/4', '1 in'])) {
      return true;
    }
    if (text.contains('photocell')) return true;
    if (_hasAny(text, ['wall plate', 'cover plate', 'blank plate']) &&
        !_hasAny(text, ['4 gang', '5 gang', '6 gang'])) {
      return true;
    }
    return _isExpandedElectricalServiceCore(system, text);
  }
  if (category == 'expanded electrical service stock' ||
      category == 'electrical core supplemental service stock') {
    return _isExpandedElectricalServiceCore(system, text);
  }
  if (category == 'wire and cable') {
    if (system == 'nm-b cable') return _hasAny(text, _electricalCoreCableSizes);
    if (system == 'conduit wire') {
      return _hasAny(text, _electricalCoreWireSizes);
    }
  }
  if (category == 'devices') return _hasAny(text, _electricalCoreDeviceSignals);
  if (category == 'breakers') {
    return _hasAny(text, _electricalCoreBreakerSignals);
  }
  if (category == 'panels and service equipment') {
    return _hasAny(text, _electricalCoreServiceEquipmentSignals);
  }
  if (category == 'boxes and covers') {
    return _hasAny(text, _electricalCoreBoxSignals);
  }
  if (category == 'connectors and consumables') {
    return _hasAny(text, _electricalCoreConsumableSignals);
  }
  if (category == 'grounding and bonding') {
    return _hasAny(text, _electricalCoreConsumableSignals) ||
        _hasAny(text, _electricalCoreGroundingSignals);
  }
  if (category == 'lighting') {
    return _hasAny(text, _electricalCoreLightingSignals);
  }
  if (category == 'conduit and fittings') {
    return _hasAny(text, _electricalCoreRacewaySignals) &&
        _hasAny(text, _electricalCoreRacewaySizes);
  }
  return false;
}

bool _isExpandedElectricalServiceCore(String system, String text) {
  if (system == 'expanded wire and cable') {
    if (text.contains('service entrance')) return false;
    if (_hasAny(text, ['uf-b cable', 'underground feeder', 'direct burial']) &&
        _hasAny(text, ['14/2', '14/3', '12/2', '12/3', '10/2', '10/3'])) {
      return true;
    }
    if (_hasAny(text, ['mc cable', 'armored cable']) &&
        _hasAny(text, ['14/2', '12/2', '10/2'])) {
      return true;
    }
    if (_hasAny(text, ['thhn copper wire', 'thwn', 'building wire']) &&
        _hasAny(text, _electricalCoreWireSizes)) {
      return true;
    }
    return _hasAny(text, _electricalCoreCableSignals) &&
        !_hasAny(text, _electricalLargeWireSignals);
  }
  if (system == 'expanded breakers and disconnects') {
    return (_hasAny(text, _electricalCoreBreakerSignals) ||
            _hasAny(text, _electricalCoreServiceEquipmentSignals)) &&
        !text.contains('safety switch') &&
        !text.contains('100 amp') &&
        !text.contains('200 amp');
  }
  if (system == 'expanded devices and plates') {
    return _hasAny(text, _electricalCoreDeviceSignals) ||
        _hasAny(text, _electricalCoreBoxSignals) ||
        _hasAny(text, _electricalCoreFixtureSignals);
  }
  if (system == 'device box and plate service stock') {
    return _hasAny(text, _electricalCoreBoxSignals);
  }
  if (system == 'cable connector and wire termination stock') {
    return _hasAny(text, _electricalCoreConsumableSignals);
  }
  if (system == 'breaker and panel service stock') {
    return _hasAny(text, _electricalCoreBreakerSignals) ||
        _hasAny(text, _electricalCoreServiceEquipmentSignals) ||
        _hasAny(text, [
          'plug fuse',
          'cartridge fuse',
          'fuse pair',
          'surge protector',
          'ground bar kit',
          'neutral bar kit',
          'bonding screw',
          'panel screw',
          'handle tie',
        ]);
  }
  if (system == 'residential safety and control stock') {
    return _hasAny(text, _electricalCoreFixtureSignals) ||
        _hasAny(text, _electricalCoreDeviceSignals) ||
        _hasAny(text, _electricalCoreLightingSignals);
  }
  if (system == 'grounding bonding and small hardware stock') {
    return _hasAny(text, _electricalCoreGroundingSignals) ||
        _hasAny(text, ['anti oxidant', 'noalox', 'split bolt']);
  }
  if (system == 'expanded boxes and covers') {
    return _hasAny(text, _electricalCoreBoxSignals) &&
        !_hasAny(text, _electricalLargeBoxSignals);
  }
  if (system == 'expanded raceway and fittings') {
    if (_hasAny(text, _electricalCoreServiceEquipmentSignals)) return true;
    if (_hasAny(text, _electricalServiceEntranceSignals)) return false;
    return _hasAny(text, _electricalCoreRacewaySignals) &&
        _hasAny(text, _electricalCoreRacewaySizes);
  }
  if (system == 'expanded connectors grounding and consumables') {
    return _hasAny(text, _electricalCoreConsumableSignals) ||
        _hasAny(text, _electricalCoreGroundingSignals);
  }
  if (system == 'expanded lighting and lamps') {
    return _hasAny(text, _electricalCoreLightingSignals);
  }
  return false;
}

bool _isHvacCoreItem(WorkSupplyItem item, String text) {
  final category = item.category.toLowerCase();
  final system = item.system.toLowerCase();
  if (category == 'hvac core supplemental service stock') return true;
  if (category == 'air filters' || system == 'expanded air filters') {
    return _hasAny(text, _hvacCoreFilterSignals);
  }
  if (_hasAny(text, _hvacCoreCondensateSignals)) return true;
  if (_hasAny(text, _hvacCoreSealSignals)) return true;
  if (_hasAny(text, _hvacCoreIgnitionSignals)) return true;
  if (_hasAny(text, _hvacCoreControlSignals)) return true;
  if (_hasAny(text, _hvacCoreAirDistributionSignals)) return true;
  if (_hasAny(text, _hvacProfessionalTierSignals)) return false;
  if (category == 'controls and electrical') {
    return _hasAny(text, _hvacCoreControlSignals);
  }
  if (category == 'condensate') {
    return _hasAny(text, _hvacCoreCondensateSignals);
  }
  if (category == 'tape and sealants') {
    return _hasAny(text, _hvacCoreSealSignals);
  }
  if (category == 'motors and blower parts') {
    return _hasAny(text, _hvacCoreMotorSignals);
  }
  if (category == 'ignition and gas heat') {
    return _hasAny(text, _hvacCoreIgnitionSignals);
  }
  if (system.contains('service truck') || text.contains('service truck')) {
    return _hasAny(text, _hvacCoreServiceTruckSignals);
  }
  return false;
}

List<String> _resolveWorkSupplyAliases(WorkSupplyItem item) {
  final text = item.searchableText;
  final size = item.trade == 'Plumbing'
      ? _resolvePlumbingSize(item, text)
      : item.trade == 'Electrical'
      ? _resolveElectricalSize(item, text)
      : _extractSize(text);
  final material = item.trade == 'Plumbing'
      ? _resolvePlumbingMaterial(item, text)
      : item.trade == 'Electrical'
      ? _resolveElectricalMaterial(item, text)
      : _firstMatched(text, _materialSignals);
  final shape = item.trade == 'Plumbing'
      ? _resolvePlumbingShape(item, text)
      : item.trade == 'Electrical'
      ? _resolveElectricalShape(item, text)
      : _firstMatched(text, _shapeSignals);
  final compactShape = _compactAliasShape(shape);
  return _cleanList([
    ...item.aliases,
    item.name,
    ..._spanishSignalsFor(item, material, size, shape),
    ..._electricalCoreAliasTermsFor(item, material, size, shape),
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
      : item.trade == 'Electrical'
      ? _resolveElectricalMaterial(item, text)
      : _firstMatched(text, _materialSignals);
  final size = item.trade == 'Plumbing'
      ? _resolvePlumbingSize(item, text)
      : item.trade == 'Electrical'
      ? _resolveElectricalSize(item, text)
      : _extractSize(text);
  final connectionType = _firstMatched(text, _connectionSignals);
  final shape = item.trade == 'Plumbing'
      ? _resolvePlumbingShape(item, text)
      : item.trade == 'Electrical'
      ? _resolveElectricalShape(item, text)
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
  'solder',
  'flux',
  'fitting brush',
  'sand cloth',
  'emery cloth',
  'heat shield',
  'torch fuel',
  'propane',
];

const _electricalCoreCableSizes = [
  '18/2',
  '18/3',
  '18/5',
  '14/2',
  '14/3',
  '12/2',
  '12/3',
  '10/2',
];

const _electricalCoreWireSizes = ['14 awg', '12 awg', '10 awg'];

const _electricalCoreRacewaySizes = ['1/2 in', '3/4 in', '1 in'];

const _electricalCoreCableSignals = [
  ..._electricalCoreCableSizes,
  ..._electricalCoreWireSizes,
  'nm-b cable',
  'nmb',
  'romex',
  'house wire',
  'uf-b cable',
  'uf cable',
  'thhn',
  'thwn',
  'low voltage cable',
  'doorbell wire',
  'control wire',
];

const _electricalLargeWireSignals = [
  '8 awg',
  '6 awg',
  '4 awg',
  '2 awg',
  'ser',
  'seu',
  '500 ft',
];

const _electricalCoreDeviceSignals = [
  'duplex receptacle',
  'gfci',
  'outlet',
  'toggle switch',
  'single pole',
  '3-way',
  'dimmer',
  'light switch',
  '15 amp',
  '20 amp',
];

const _electricalCoreBreakerSignals = [
  'circuit breaker',
  'breaker',
  'single-pole breaker',
  'double-pole breaker',
  '15 amp single-pole',
  '20 amp single-pole',
  '15 amp',
  '20 amp',
  '25 amp',
  '30 amp',
  '40 amp',
  '50 amp',
  '60 amp',
  'gfci breaker',
  'afci breaker',
  'dual function breaker',
  'arc fault breaker',
];

const _electricalCoreServiceEquipmentSignals = [
  'ac disconnect',
  'disconnect',
  'pullout disconnect',
  'non-fusible ac disconnect',
  'fusible ac disconnect',
  'panel cover',
  'dead front',
  'panel filler',
  'filler plate',
  'neutral ground bar',
  'ground bar',
  'neutral bar',
];

const _electricalCoreBoxSignals = [
  '1 gang',
  '2 gang',
  'single gang',
  'old work',
  'new work',
  'junction box',
  'device box',
  'handy box',
  'blank cover',
  'cover plate',
  'wall plate',
  'fan box',
  'ceiling box',
  'fixture box',
  'bar hanger',
  'fan brace',
  'knockout seal',
  'ko seal',
  'reducing washer',
  'locknut',
  'plastic bushing',
  'grounding clip',
  'box extender',
  'device yoke repair clip',
  'box support clip',
  'goof ring',
  'mud ring',
  'weatherproof',
  'in-use cover',
  'gfci cover',
  'bell box',
  'outdoor cover',
  'bubble cover',
  'extra duty cover',
  'wp cover',
  'device gasket',
];

const _electricalCoreConsumableSignals = [
  'wire connector',
  'wire nut',
  'lever connector',
  'wago',
  'push-in wire connector',
  'push in connector',
  'push connector',
  'inline splice connector',
  'splice connector',
  'butt splice connector',
  'closed end splice connector',
  'grounding wire connector',
  'twister wire connector',
  'compact splicing connector',
  'waterproof wire connector',
  'electrical tape',
  'ground screw',
  'ground pigtail',
  'neutral pigtail',
  'cable staple',
  'romex connector',
  'nm connector',
  'mc connector',
  'flex connector',
  'flexible metal connector',
  'device screw',
  'plate screw',
  'outlet spacer',
  'receptacle tester',
  'gfci tester',
  'wire pulling lube',
  'putty pad',
  'anti short bushing',
  'red head bushing',
  'cable ripper',
  'circuit directory',
  'panel directory',
  'voltage detector',
  'continuity tester',
  'polarity tester',
  'wire marker',
  'panel screw',
  'yoke repair',
  'box support clip',
  'anti short',
  'no ox',
  'noalox',
  'anti-oxidant',
  'pull string',
  'fish tape',
  'plastic bushings',
  'reducing washer',
];

const _electricalCoreRacewaySignals = [
  'emt conduit',
  'emt connector',
  'emt coupling',
  'emt 90 elbow',
  'emt strap',
  'pvc electrical conduit',
  'pvc electrical 90 elbow',
  'pvc electrical coupling',
  'pvc electrical male adapter',
  'pvc electrical female adapter',
  'gray pvc conduit',
  'terminal adapter',
  'set screw',
  'compression fitting',
  'lb body',
  'll body',
  'lr body',
  'conduit body',
  'body cover',
  'mini strap',
  'one hole strap',
  'two hole strap',
  'conduit hanger',
  'fmc connector',
  'flex conduit',
  'liquidtight connector',
  'liquid tight',
  'sealtite',
  'fmc',
];

const _electricalCoreGroundingSignals = [
  'ground wire',
  'ground rod',
  'ground rod clamp',
  'grounding pigtail',
  'green ground screw',
  'bonding jumper',
  'ground clamp',
];

const _electricalCoreFixtureSignals = [
  'smoke alarm',
  'smoke detector',
  'carbon monoxide',
  'co alarm',
  'doorbell transformer',
  'doorbell chime',
  'video doorbell',
  'fan brace',
  'ceiling fan brace',
];

const _electricalCoreLightingSignals = [
  'flush mount',
  'vanity',
  'recessed trim',
  'outdoor wall',
  'flood light',
  'lampholder',
  'porcelain lampholder',
  'fixture strap',
  'fixture crossbar',
  'fixture stud',
  'canopy screw',
  'recessed trim clip',
  'remodel clip',
  'tombstone socket',
  'fluorescent starter',
  'cord grip',
  'photocell',
  'fixture gasket',
  'landscape lighting connector',
  'a19',
  'br30',
  'par38',
  'led lamp',
  'led driver',
  'led tape light',
  'shop light',
  'bulb',
];

const _electricalLargeBoxSignals = ['6 x 6', '8 x 8', 'pull box'];

const _electricalServiceEntranceSignals = [
  'service entrance',
  'weatherhead',
  'service head',
  'mast clamp',
  'meter socket',
  'main breaker kit',
  'main lug kit',
  'panel accessory',
  'surge protective device',
  'interlock kit',
  'ground bar kit',
  'neutral bar kit',
];

const _electricalProfessionalTierSignals = [
  '2-1/2 in',
  '3 in',
  '3-1/2 in',
  '4 in',
  '5 in',
  '6 in',
  'rigid metal conduit',
  'rigid pipe',
  'imc',
  'service entrance',
  'meter',
  'load center',
  'commercial',
  'bulk',
];

const _hvacCoreFilterSignals = [
  'pleated air filter',
  'furnace filter',
  'ac filter',
];

const _hvacCoreControlSignals = [
  'run capacitor',
  'dual run capacitor',
  'single run capacitor',
  'start capacitor',
  'hard start kit',
  'potential relay',
  'contactor',
  'compressor contactor',
  'thermostat',
  'thermostat wire',
  'low voltage wire',
  'fuse',
  'blade fuse',
  'cartridge fuse',
  'relay',
  'fan relay',
  'isolation relay',
  'time delay relay',
  'sequencer',
  'transformer',
  '24v transformer',
  'outdoor sensor',
  'remote indoor sensor',
  'duct temperature sensor',
  'common wire adapter',
  'wire saver',
  'terminal strip',
  'spade terminal',
  'ac disconnect',
  'pullout disconnect',
  'disconnect box',
  'equipment whip',
  'ac whip',
  'surge protector',
  'time delay fuse',
];

const _hvacCoreCondensateSignals = [
  'condensate pump',
  'condensate line',
  'condensate drain',
  'condensate safety switch',
  'condensate switch',
  'float switch',
  'wet switch',
  'overflow switch',
  'pan switch',
  'condensate pan',
  'drain pan',
  'primary drain line safety switch',
  'secondary drain pan float switch',
  'inline condensate float switch',
  'condensate cleanout',
  'condensate trap',
  'condensate tee',
  'condensate pvc fitting',
  'pvc condensate',
  'vinyl tubing',
  'clear tubing',
  'pump tubing',
  'condensate hose',
  'drain pan tablet',
  'drain pan tablets',
  'drain pan strip',
  'drain line cleaner',
  'drain gun',
  'drain cartridge',
  'drain brush',
  'trap brush',
  'pump check valve',
  'replacement tubing kit',
  'neutralizer',
  'condensate neutralizer',
];

const _hvacCoreSealSignals = [
  'foil hvac tape',
  'foil tape',
  'duct tape',
  'mastic',
  'duct sealant',
  'hvac service tape',
  'line set tape',
  'line set',
  'line set cover',
  'line set cover kit',
  'armaflex',
  'pipe insulation',
  'service valve cap',
  'ul181 tape',
  'foam gasket tape',
  'thumb gum',
];

const _hvacCoreAirDistributionSignals = [
  'register boot',
  'duct boot',
  'end boot',
  'straight boot',
  'wall stack',
  'start collar',
  'takeoff',
  'spin in',
  'spin-in',
  'sheet metal collar',
  'round pipe',
  'snap lock pipe',
  'adjustable elbow',
  'duct coupling',
  'manual damper',
  'balancing damper',
  'backdraft damper',
  'duct reducer',
  'sheet metal screw',
  'zip screw',
  'tek screw',
  'self drilling screw',
  'duct strap',
  'hanger strap',
  'duct mastic',
  'condenser pad',
  'equipment pad',
  'mastic brush',
  'flex duct',
  'insulated flex duct',
  'flex duct zip tie',
  'floor register',
  'return air grille',
  'return filter grille',
  'ceiling diffuser',
  'eggcrate return grille',
  'filter grille replacement door',
  'air distribution face',
];

const _hvacCoreMotorSignals = [
  'blower belt',
  'motor capacitor',
  'condenser fan motor',
  'blower motor',
  'fan blade',
  'blower wheel',
  'belly band',
  'motor mount',
  'hub adapter',
  'v belt',
  'motor pulley',
  'adjustable sheave',
  'isolation grommet',
];

const _hvacCoreIgnitionSignals = [
  'flame sensor',
  'hot surface ignitor',
  'ignitor',
  'thermocouple',
  'pressure switch',
  'pressure switch tubing',
  'rollout switch',
  'limit switch',
  'furnace door switch',
  'inducer gasket',
  'pilot assembly',
  'thermopile',
  'burner orifice',
  'gas leak detector',
];

const _hvacCoreServiceTruckSignals = [
  ..._hvacCoreFilterSignals,
  ..._hvacCoreControlSignals,
  ..._hvacCoreCondensateSignals,
  ..._hvacCoreSealSignals,
  ..._hvacCoreAirDistributionSignals,
  ..._hvacCoreMotorSignals,
  ..._hvacCoreIgnitionSignals,
  'coil cleaner',
  'humidifier pad',
  'water panel',
  'humidifier solenoid',
  'humidifier feed tube',
  'humidifier drain tube',
  'humidifier saddle valve',
  'humidifier bypass damper',
  'humidifier orifice',
  'media cabinet gasket',
  'filter rack door latch',
  'air scrubber cell',
  'air scrubber ballast',
  'electronic air cleaner',
  'air cleaner prefilter',
  'ionizing wire',
  'leak detector',
  'service chemical',
  'service sticker',
  'equipment tag',
  'wire marker',
  'low voltage wire nut',
  'fork terminal',
  'zip tie',
  'no ox grease',
];

const _hvacProfessionalTierSignals = [
  'heat pump',
  'condenser',
  'air handler',
  'furnace',
  'boiler',
  'package unit',
  'rooftop',
  'rtu',
  'mini split',
  'evaporator coil',
  'plenum',
  'brazing',
  'refrigerant',
  'recovery',
  'hydronic',
  'gas valve',
  'flue',
  'b vent',
  'commercial',
  'detail',
  'equipment',
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

const _consumableSignals = [
  'washer',
  'o-ring',
  'ring',
  'seal',
  'tape',
  'putty',
  'cement',
  'primer',
  'solder',
  'flux',
  'caulk',
  'sand cloth',
  'emery cloth',
  'heat shield',
  'torch fuel',
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
        ..._plumbingCoreReceiptPatternsFor(item, material, size, shape),
        ..._electricalCoreReceiptPatternsFor(item, material, size, shape),
        ..._spanishSignalsFor(item, material, size, shape),
      ])
      .take(item.trade == 'Plumbing' || item.trade == 'Electrical' ? 32 : 16)
      .toList(growable: false);
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
      : item.trade == 'Electrical'
      ? _resolveElectricalShape(item, item.searchableText)
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
    ..._plumbingCoreAttributeTokensFor(item, material, size, shape),
    ..._electricalCoreAttributeTokensFor(item, material, size, shape),
    ..._hvacCoreAttributeTokensFor(item, material, size, shape),
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
    ..._plumbingCoreNegativeMatchTokensFor(item, material, shape, text),
    ..._electricalCoreNegativeMatchTokensFor(item, material, shape, text),
    ..._hvacCoreNegativeMatchTokensFor(item, material, shape, text),
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
    ..._plumbingCoreHighImportanceTokensFor(
      item,
      material,
      size,
      connectionType,
      shape,
    ),
    ..._electricalCoreHighImportanceTokensFor(
      item,
      material,
      size,
      connectionType,
      shape,
    ),
    ..._hvacCoreHighImportanceTokensFor(
      item,
      material,
      size,
      connectionType,
      shape,
    ),
  ]);
}

List<String> _plumbingCoreReceiptPatternsFor(
  WorkSupplyItem item,
  String material,
  String size,
  String shape,
) {
  if (!_isPlumbingCoreMetadataTarget(item)) return const [];
  final family = _plumbingCoreFamilyTermsFor(item, shape);
  final compactFamily = _plumbingCompactFamilyTermsFor(item, shape);
  final spanish = _plumbingSpanishCoreFamilyTermsFor(item, shape);
  final sizeToken = size.isEmpty ? item.variant : size;
  final base = _cleanList([
    item.name,
    item.variant,
    item.itemType,
    material,
    shape,
    ...family,
  ]).join(' ');
  return _cleanList([
    base,
    '$sizeToken $base',
    '$material $sizeToken ${family.join(' ')}',
    '$sizeToken ${compactFamily.join(' ')}',
    for (final term in family) '$sizeToken $material $term',
    for (final term in compactFamily) '$sizeToken $term',
    for (final term in compactFamily) 'HD $sizeToken $term',
    for (final term in compactFamily) 'LOWES $sizeToken $term',
    for (final term in compactFamily) 'ACE $sizeToken $term',
    for (final term in compactFamily) 'SUPPLY $sizeToken $term',
    for (final term in spanish) '$sizeToken $term',
    for (final term in spanish) '$term $sizeToken',
  ]);
}

List<String> _plumbingCoreAttributeTokensFor(
  WorkSupplyItem item,
  String material,
  String size,
  String shape,
) {
  if (!_isPlumbingCoreMetadataTarget(item)) return const [];
  return _cleanList([
    'plumbing-core',
    'residential-service',
    'service-truck',
    'hardware-store-stock',
    'box-store-stock',
    'user-review-required',
    'english-us',
    'spanish-us',
    item.path,
    material,
    size,
    shape,
    ..._plumbingCoreFamilyTermsFor(item, shape),
    ..._plumbingCompactFamilyTermsFor(item, shape),
    ..._plumbingSpanishCoreFamilyTermsFor(item, shape),
  ]);
}

List<String> _plumbingCoreHighImportanceTokensFor(
  WorkSupplyItem item,
  String material,
  String size,
  String connectionType,
  String shape,
) {
  if (!_isPlumbingCoreMetadataTarget(item)) return const [];
  return _cleanList([
    'plumbing-core',
    'residential-service',
    item.system,
    item.itemType,
    item.variant,
    material,
    size,
    connectionType,
    shape,
    ..._plumbingCoreFamilyTermsFor(item, shape),
  ]);
}

List<String> _plumbingCoreNegativeMatchTokensFor(
  WorkSupplyItem item,
  String material,
  String shape,
  String text,
) {
  if (!_isPlumbingCoreMetadataTarget(item)) return const [];
  final itemText = '$text ${item.name} ${item.itemType}'.toLowerCase();
  return _cleanList([
    if (!itemText.contains('conduit')) 'electrical conduit',
    if (!itemText.contains('condensate')) 'hvac condensate drain',
    if (!itemText.contains('filter')) 'hvac air filter',
    if (!itemText.contains('paint')) 'paint supplies',
    if (!itemText.contains('irrigation')) 'irrigation sprinkler',
    if (material != 'PVC') 'pvc electrical conduit',
    if (material != 'copper') 'hvac refrigerant copper',
    if (itemText.contains('push') && !itemText.contains('electrical'))
      'electrical connector',
    if (_isWaterTreatmentCoreText(itemText)) 'pool filter',
    if (_isWaterTreatmentCoreText(itemText)) 'swimming pool chemical',
    if (_isWaterTreatmentCoreText(itemText)) 'ice melt salt',
    if (_isWaterTreatmentCoreText(itemText)) 'table salt',
    if (shape != 'valve') 'gas appliance valve',
  ]);
}

List<String> _hvacCoreAttributeTokensFor(
  WorkSupplyItem item,
  String material,
  String size,
  String shape,
) {
  if (!_isHvacCoreItem(item, item.searchableText)) return const [];
  return _cleanList([
    'hvac-core',
    'residential-service',
    'service-truck',
    'hardware-store-stock',
    'supply-house-stock',
    'user-review-required',
    'english-us',
    'spanish-us',
    item.path,
    material,
    size,
    shape,
    ..._hvacCoreFamilyTermsFor(item),
  ]);
}

List<String> _hvacCoreHighImportanceTokensFor(
  WorkSupplyItem item,
  String material,
  String size,
  String connectionType,
  String shape,
) {
  if (!_isHvacCoreItem(item, item.searchableText)) return const [];
  return _cleanList([
    'hvac-core',
    'residential-service',
    item.system,
    item.itemType,
    item.variant,
    material,
    size,
    connectionType,
    shape,
    ..._hvacCoreFamilyTermsFor(item),
  ]);
}

List<String> _hvacCoreNegativeMatchTokensFor(
  WorkSupplyItem item,
  String material,
  String shape,
  String text,
) {
  if (!_isHvacCoreItem(item, text)) return const [];
  final itemText = '$text ${item.name} ${item.itemType}'.toLowerCase();
  return _cleanList([
    if (!itemText.contains('water filter')) 'water filter',
    if (!itemText.contains('filter drier')) 'filter drier',
    if (!itemText.contains('conduit')) 'electrical conduit',
    if (!itemText.contains('plumbing')) 'plumbing pvc',
    if (!itemText.contains('irrigation')) 'irrigation tubing',
    if (!itemText.contains('appliance')) 'appliance cord',
    if (!itemText.contains('pool')) 'pool filter',
  ]);
}

List<String> _hvacCoreFamilyTermsFor(WorkSupplyItem item) {
  final text = item.searchableText;
  if (_hasAny(text, _hvacCoreFilterSignals)) {
    return const ['air filter', 'furnace filter', 'merv filter'];
  }
  if (_hasAny(text, _hvacCoreControlSignals)) {
    return const ['hvac control', 'capacitor', 'contactor', 'relay'];
  }
  if (_hasAny(text, _hvacCoreCondensateSignals)) {
    return const ['condensate', 'condensate drain', 'condensate pump'];
  }
  if (_hasAny(text, _hvacCoreSealSignals)) {
    return const ['hvac tape', 'duct mastic', 'duct sealant'];
  }
  if (_hasAny(text, _hvacCoreAirDistributionSignals)) {
    return const ['duct repair', 'flex duct', 'air distribution'];
  }
  if (_hasAny(text, _hvacCoreIgnitionSignals)) {
    return const ['ignition', 'flame sensor', 'hot surface ignitor'];
  }
  return const ['hvac service stock'];
}

bool _isWaterTreatmentCoreText(String text) {
  return text.contains('water treatment') ||
      text.contains('water filter') ||
      text.contains('filter cartridge') ||
      text.contains('reverse osmosis') ||
      text.contains('softener') ||
      text.contains('salt pellet');
}

bool _isPlumbingCoreMetadataTarget(WorkSupplyItem item) {
  return item.trade == 'Plumbing' &&
      _resolvePlumbingPackTier(item) == WorkSupplyPackTier.core &&
      item.marketScopes.contains(WorkSupplyMarketScope.residential);
}

List<String> _plumbingCoreFamilyTermsFor(WorkSupplyItem item, String shape) {
  final text =
      '${item.name} ${item.itemType} ${item.system} ${item.aliases.join(' ')}'
          .toLowerCase();
  if (text.contains('p-trap') || text.contains('p trap')) {
    return const ['p trap', 'p-trap', 'sink trap', 'lav trap'];
  }
  if (text.contains('fill valve')) {
    return const ['fill valve', 'toilet fill valve', 'ballcock'];
  }
  if (text.contains('tank lever')) {
    return const ['tank lever', 'toilet handle', 'flush lever'];
  }
  if (text.contains('aerator')) {
    return const ['aerator', 'faucet aerator', 'faucet screen'];
  }
  if (text.contains('o-ring') || text.contains('o ring')) {
    return const ['o ring', 'o-ring', 'faucet o ring', 'seal kit'];
  }
  if (text.contains('disposal drain elbow')) {
    return const [
      'disposal drain elbow',
      'disposal elbow',
      'garbage disposal elbow',
    ];
  }
  if (text.contains('disposal install kit')) {
    return const [
      'disposal install kit',
      'disposal kit',
      'garbage disposal connector',
    ];
  }
  if (text.contains('continuous waste')) {
    return const ['continuous waste', 'cont waste', 'double bowl waste'];
  }
  if (text.contains('escutcheon')) {
    return const ['escutcheon', 'esc plate', 'cover plate'];
  }
  if (text.contains('angle stop') || text.contains('supply stop')) {
    return const [
      'angle stop',
      'supply stop',
      'stop valve',
      'quarter turn stop',
    ];
  }
  if (text.contains('supply line')) {
    return const [
      'supply line',
      'toilet supply',
      'faucet supply',
      'connector line',
    ];
  }
  if (text.contains('closet flange')) {
    return const [
      'closet flange',
      'toilet flange',
      'flange repair',
      'flange spacer',
    ];
  }
  if (text.contains('cleanout')) {
    return const ['cleanout', 'clean out', 'cleanout plug', 'cleanout cover'];
  }
  if (text.contains('trap adapter')) {
    return const ['trap adapter', 'trap adpt', 'dwv adapter'];
  }
  if (text.contains('wye')) return const ['wye', 'dwv wye', 'combo wye'];
  if (text.contains('pex')) {
    return const ['pex', 'pex crimp', 'pex barb', 'pex fitting', 'poly pipe'];
  }
  if (text.contains('push-fit') ||
      text.contains('push fit') ||
      text.contains('sharkbite')) {
    return const ['push fit', 'push-fit', 'push connect', 'sharkbite'];
  }
  if (text.contains('cpvc')) return const ['cpvc', 'cpvc flowguard'];
  if (text.contains('water heater')) {
    return const ['water heater', 'wtr htr', 'heater connector', 'heater pan'];
  }
  if (text.contains('pressure tank') || text.contains('tank tee')) {
    return const ['pressure tank', 'well tank', 'tank tee', 'pressure gauge'];
  }
  if (text.contains('softener') || text.contains('filter cartridge')) {
    return const [
      'water softener',
      'softener salt',
      'filter cartridge',
      'water filter',
    ];
  }
  if (text.contains('solder')) {
    return const [
      'lead free solder',
      'plumbing solder',
      'sweat solder',
      'lf solder',
    ];
  }
  if (text.contains('flux')) {
    return const ['solder flux', 'plumbing flux', 'tinning flux', 'paste flux'];
  }
  if (text.contains('acid brush')) {
    return const ['acid brush', 'flux brush', 'solder brush'];
  }
  if (text.contains('fitting brush')) {
    return const [
      'fitting brush',
      'copper fitting brush',
      'tube brush',
      'wire brush',
    ];
  }
  if (text.contains('sand cloth') || text.contains('emery cloth')) {
    return const ['sand cloth', 'emery cloth', 'abrasive cloth'];
  }
  if (text.contains('heat shield')) {
    return const ['heat shield', 'flame protector', 'torch shield'];
  }
  if (text.contains('propane') || text.contains('map-pro')) {
    return const ['torch fuel', 'propane fuel', 'map pro fuel'];
  }
  if (text.contains('torch head')) {
    return const ['torch head', 'solder torch', 'plumbing torch'];
  }
  if (text.contains('j hook') ||
      text.contains('pipe hook') ||
      text.contains('pipe hanger') ||
      text.contains('pipe support')) {
    return const ['j hook', 'pipe hook', 'pipe hanger', 'tube strap'];
  }
  if (text.contains('sanitary tee')) {
    return const ['sanitary tee', 'san tee', 'sanitary t'];
  }
  if (text.contains('reducing coupling')) {
    return const ['reducing coupling', 'reducing cplg', 'reducer coupling'];
  }
  if (text.contains('coupling')) return const ['coupling', 'cplg', 'coupler'];
  if (text.contains('elbow') || shape == 'elbow') {
    return const ['elbow', 'elb', 'ell'];
  }
  if (text.contains('adapter') || shape == 'adapter') {
    return const ['adapter', 'adpt', 'adaptor'];
  }
  if (text.contains('tee') || shape == 'tee') return const ['tee', 't fitting'];
  if (text.contains('valve') || shape == 'valve') return const ['valve'];
  if (text.contains('pipe')) return const ['pipe', 'tube', 'tubing'];
  return _cleanList([item.itemType, shape]);
}

List<String> _plumbingCompactFamilyTermsFor(WorkSupplyItem item, String shape) {
  final terms = _plumbingCoreFamilyTermsFor(item, shape);
  return _cleanList([
    for (final term in terms) _compactPlumbingReceiptTerm(term),
    for (final term in terms)
      if (term.toLowerCase().startsWith('disposal '))
        _compactPlumbingReceiptTerm(term.replaceFirst('disposal', 'disp')),
  ]);
}

String _compactPlumbingReceiptTerm(String value) {
  return value
      .toUpperCase()
      .replaceAll(' COUPLING', ' CPLG')
      .replaceAll(' ADAPTER', ' ADPT')
      .replaceAll(' ELBOW', ' ELB')
      .replaceAll(' CONNECTOR', ' CONN')
      .replaceAll(' DISPOSAL', ' DISP')
      .replaceAll(' TOILET', ' TLT')
      .replaceAll(' FAUCET', ' FCT');
}

List<String> _plumbingSpanishCoreFamilyTermsFor(
  WorkSupplyItem item,
  String shape,
) {
  final text = '${item.name} ${item.itemType} ${item.system}'.toLowerCase();
  if (text.contains('p-trap') || text.contains('p trap')) {
    return const ['trampa p', 'trampa lavabo', 'trampa lavamanos'];
  }
  if (text.contains('fill valve')) {
    return const ['valvula llenado', 'valvula de llenado sanitario'];
  }
  if (text.contains('tank lever')) {
    return const ['palanca tanque', 'manija sanitario'];
  }
  if (text.contains('aerator')) return const ['aireador', 'aireador grifo'];
  if (text.contains('o-ring') || text.contains('o ring')) {
    return const ['o ring', 'empaque llave', 'sello llave'];
  }
  if (text.contains('disposal')) {
    return const ['triturador', 'codo triturador', 'kit triturador'];
  }
  if (text.contains('escutcheon')) return const ['chapeton', 'placa cubierta'];
  if (text.contains('angle stop') || text.contains('supply stop')) {
    return const ['llave escuadra', 'valvula cierre', 'valvula angular'];
  }
  if (text.contains('supply line')) {
    return const ['linea suministro', 'manguera suministro'];
  }
  if (text.contains('closet flange')) {
    return const ['brida sanitario', 'brida inodoro'];
  }
  if (text.contains('cleanout')) {
    return const ['registro limpieza', 'tapon limpieza'];
  }
  if (text.contains('trap adapter')) return const ['adaptador trampa'];
  if (text.contains('wye')) return const ['yee sanitaria', 'conector yee'];
  if (text.contains('pex')) return const ['pex', 'conexion pex'];
  if (text.contains('push-fit') ||
      text.contains('push fit') ||
      text.contains('sharkbite')) {
    return const ['conexion rapida', 'push fit'];
  }
  if (text.contains('cpvc')) return const ['cpvc'];
  if (text.contains('water heater')) {
    return const ['calentador agua', 'conector calentador'];
  }
  if (text.contains('pressure tank') || text.contains('tank tee')) {
    return const ['tanque presion', 'tee tanque', 'pozo'];
  }
  if (text.contains('softener') || text.contains('filter cartridge')) {
    return const ['suavizador agua', 'sal suavizador', 'filtro agua'];
  }
  if (text.contains('solder')) return const ['soldadura plomeria'];
  if (text.contains('flux')) return const ['fundente soldadura'];
  if (text.contains('acid brush') || text.contains('fitting brush')) {
    return const ['cepillo soldadura', 'cepillo cobre'];
  }
  if (text.contains('sand cloth') || text.contains('emery cloth')) {
    return const ['tela esmeril', 'lija plomero'];
  }
  if (text.contains('heat shield')) return const ['protector calor'];
  if (text.contains('propane') || text.contains('map-pro')) {
    return const ['gas soplete', 'combustible soplete'];
  }
  if (text.contains('torch head')) return const ['cabezal soplete'];
  if (text.contains('j hook') ||
      text.contains('pipe hook') ||
      text.contains('pipe hanger') ||
      text.contains('pipe support')) {
    return const ['soporte tubo', 'gancho tubo'];
  }
  if (text.contains('sanitary tee')) {
    return const ['tee sanitaria', 't sanitaria'];
  }
  if (text.contains('coupling')) return const ['cople', 'acople'];
  if (text.contains('elbow') || shape == 'elbow') return const ['codo'];
  if (text.contains('adapter') || shape == 'adapter') {
    return const ['adaptador'];
  }
  if (text.contains('valve') || shape == 'valve') return const ['valvula'];
  return const ['plomeria residencial'];
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
  if (item.trade == 'Electrical') {
    return _electricalNeedsManualReview(item, material, size, shape);
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
