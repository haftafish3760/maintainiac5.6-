part of 'work_supply_catalog.dart';

List<WorkSupplyMarketScope> _resolvePlumbingMarketScopes(WorkSupplyItem item) {
  final text = item.searchableText;
  final scopes = <WorkSupplyMarketScope>{WorkSupplyMarketScope.residential};
  if (_hasAny(text, _plumbingLightIndustrialSignals)) {
    scopes.add(WorkSupplyMarketScope.lightIndustrial);
  }
  if (_hasAny(text, _plumbingCommercialOverlapSignals)) {
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

WorkSupplyPackTier _resolvePlumbingPackTier(WorkSupplyItem item) {
  final text = item.searchableText;
  if (_isPlumbingCoreItem(item, text)) return WorkSupplyPackTier.core;
  if (_hasPlumbingCompleteTierSignal(text)) return WorkSupplyPackTier.complete;
  if (_hasPlumbingProfessionalSignal(text)) {
    return WorkSupplyPackTier.professional;
  }
  if (_isPlumbingStandardItem(item, text)) return WorkSupplyPackTier.standard;
  return WorkSupplyPackTier.professional;
}

bool _isPlumbingCoreItem(WorkSupplyItem item, String text) {
  final category = item.category.toLowerCase();
  final system = item.system.toLowerCase();
  final type = item.itemType.toLowerCase();
  if (category == 'valves' && _isOversizedPlumbingValveForCore(item)) {
    return false;
  }
  if (category == 'hangers and supports' &&
      _isOversizedPlumbingSupportForCore(item)) {
    return false;
  }
  if (_hasAny(text, _plumbingAlwaysCoreServiceSignals)) return true;
  if (system == 'pvc dwv' &&
      type.contains('reducing sanitary') &&
      _isCommonPlumbingVariant(item.variant)) {
    return true;
  }
  if (_hasPlumbingCommercialCoreExclusion(text)) return false;
  if (category == 'fittings' && _isOversizedPlumbingFittingForCore(item)) {
    return false;
  }
  if (category == 'fittings' && type.contains('expanded')) {
    return _isCoreExpandedPlumbingFitting(item, text);
  }
  if (type.contains('expanded')) return false;
  if (category == 'service truck stock') return true;
  if (category == 'drain and finish service stock') {
    return _hasAny(text, _plumbingCoreDrainFinishSignals);
  }
  if (category == 'seals packing and thread service') {
    return _hasAny(text, _plumbingCoreSealServiceSignals);
  }
  if (category == 'toilet repair' || category == 'sink and faucet repair') {
    return true;
  }
  if (category == 'drainage waste vent') {
    return _hasAny(text, _plumbingCoreDrainServiceSignals);
  }
  if (category == 'hangers and supports') {
    return _hasAny(text, _plumbingCoreSupportSignals);
  }
  if (category == 'water heater' || category == 'valves') {
    return _hasAny(text, _plumbingCoreValveAndWaterHeaterSignals) ||
        !_hasPlumbingProfessionalSignal(text);
  }
  if (category == 'pumps' && system == 'well service') {
    return _hasAny(text, _plumbingCoreWellServiceSignals);
  }
  if (category == 'fittings') {
    if (system == 'copper' || system == 'brass') {
      if (item.variant.toLowerCase().startsWith('2 x')) return false;
      return _hasAny(text, _plumbingCoreFittingMaterialSignals) &&
          _hasAny(text, _plumbingCoreFittingFamilySignals) &&
          (_hasAny(text, _residentialSupplySizes) || _hasAny(text, ['1 x']));
    }
    if (system == 'pex' || system == 'cpvc' || system == 'push-fit') {
      return _hasAny(text, _plumbingCoreFittingMaterialSignals) &&
          _hasAny(text, _plumbingCoreFittingFamilySignals) &&
          (_hasAny(text, _residentialSupplySizes) || _hasAny(text, ['1 x']));
    }
    return _hasAny(text, _plumbingCoreFittingMaterialSignals) &&
        _hasAny(text, _plumbingCoreFittingFamilySignals) &&
        _hasAny(text, _plumbingCoreFittingSizeSignals) &&
        _isCommonPlumbingVariant(item.variant);
  }
  if (system == 'pex' || system == 'cpvc' || system == 'push-fit') {
    return _hasAny(text, _residentialSupplySizes) &&
        _hasAny(type, _coreFittingTypes) &&
        _isCommonPlumbingVariant(item.variant);
  }
  if (system == 'pvc schedule 40' || system == 'pvc dwv') {
    return _hasAny(text, _coreDrainSizes) &&
        _hasAny(type, _coreFittingTypes) &&
        _isCommonPlumbingVariant(item.variant);
  }
  if (system == 'copper' || system == 'brass') {
    return _hasAny(text, _residentialSupplySizes) &&
        _hasAny(type, _coreFittingTypes) &&
        _isCommonPlumbingVariant(item.variant);
  }
  if (category == 'supply lines' || category == 'consumables') return true;
  return false;
}

bool _isOversizedPlumbingFittingForCore(WorkSupplyItem item) {
  final system = item.system.toLowerCase();
  final largestVariantSize = _largestPlumbingVariantSize(item.variant);
  if (largestVariantSize == null) return false;
  if (system == 'copper' ||
      system == 'brass' ||
      system == 'pex' ||
      system == 'cpvc' ||
      system == 'push-fit') {
    return largestVariantSize > 1;
  }
  if (system == 'pvc schedule 40') return largestVariantSize > 2;
  if (system == 'pvc dwv' || system == 'abs dwv') return largestVariantSize > 4;
  return false;
}

bool _isOversizedPlumbingValveForCore(WorkSupplyItem item) {
  final largestVariantSize = _largestPlumbingVariantSize(item.variant);
  if (largestVariantSize == null) return false;
  final text = item.searchableText;
  if (text.contains('ball valve') ||
      text.contains('gate valve') ||
      text.contains('check valve')) {
    return largestVariantSize > 1;
  }
  return false;
}

bool _isOversizedPlumbingSupportForCore(WorkSupplyItem item) {
  final largestVariantSize = _largestPlumbingVariantSize(item.variant);
  if (largestVariantSize == null) return false;
  return largestVariantSize > 2;
}

bool _isCoreExpandedPlumbingFitting(WorkSupplyItem item, String text) {
  final system = item.system.toLowerCase();
  final type = item.itemType.toLowerCase();
  final largestVariantSize = _largestPlumbingVariantSize(item.variant);
  if (!_isCommonPlumbingVariant(item.variant)) return false;
  if (_hasPlumbingProfessionalSignal(text)) return false;
  if (type.contains('street')) return false;
  if (type.contains('reducing') || type.contains('reducer')) return false;
  if (system == 'pex' || system == 'cpvc' || system == 'push-fit') {
    return _hasAny(text, _coreExpandedSupplySizes) &&
        _hasAny(type, _coreExpandedSupplyFittingTypes);
  }
  if (system == 'copper' || system == 'brass') {
    return _hasAny(text, _coreExpandedSupplySizes) &&
        _hasAny(type, _coreExpandedThreadedOrSweatTypes);
  }
  if (system == 'pvc schedule 40') {
    if (largestVariantSize == null || largestVariantSize > 2) return false;
    return _hasAny(text, _coreExpandedPressurePipeSizes) &&
        _hasAny(type, _coreExpandedPressurePipeTypes);
  }
  if (system == 'pvc dwv') {
    if (largestVariantSize == null || largestVariantSize > 4) return false;
    return _hasAny(text, _coreExpandedDwvSizes) &&
        _hasAny(type, _coreExpandedDwvTypes);
  }
  return false;
}

bool _isPlumbingStandardItem(WorkSupplyItem item, String text) {
  final category = item.category.toLowerCase();
  final system = item.system.toLowerCase();
  final type = item.itemType.toLowerCase();
  if (category == 'fittings') {
    if (type.contains('expanded')) {
      return _isStandardExpandedPlumbingFitting(item, text);
    }
    return _hasAny(text, _standardPlumbingSizes) &&
        _hasAny(system, _standardResidentialSystems) &&
        (_hasAny(type, _standardFittingTypes) ||
            _hasAny(type, _coreFittingTypes)) &&
        _isCommonPlumbingVariant(item.variant);
  }
  if (category == 'pipe and tubing') {
    return _hasAny(text, _standardPlumbingSizes) &&
        _hasAny(system, _standardResidentialSystems);
  }
  if (category == 'drainage waste vent' ||
      category == 'hangers and supports' ||
      category == 'pumps' ||
      category == 'shower and tub repair') {
    return true;
  }
  return !_hasPlumbingProfessionalSignal(text);
}

bool _isStandardExpandedPlumbingFitting(WorkSupplyItem item, String text) {
  final system = item.system.toLowerCase();
  final type = item.itemType.toLowerCase();
  if (!_isCommonPlumbingVariant(item.variant)) return false;
  if (_hasPlumbingProfessionalSignal(text)) return false;
  if (!_hasAny(system, _standardExpandedResidentialSystems)) return false;
  if (!_hasAny(type, _standardExpandedFittingTypes)) return false;
  return _hasAny(text, _standardExpandedResidentialSizes);
}

bool _isCommonPlumbingVariant(String variant) {
  final normalized = variant.toLowerCase().trim();
  if (!normalized.contains(' x ')) return true;
  if (_hasQuarterInchMatrixBranch(normalized)) return false;
  const commonMatrices = [
    '1/2 x 1/2',
    '3/4 x 3/4',
    '1 x 1',
    '1-1/4 x 1-1/4',
    '1-1/2 x 1-1/2',
    '2 x 2',
    '3 x 3',
    '1/2 x 1/2 x 1/2',
    '3/4 x 3/4 x 3/4',
    '1 x 1 x 1',
    '1-1/4 x 1-1/4 x 1-1/4',
    '1-1/2 x 1-1/2 x 1-1/2',
    '2 x 2 x 2',
    '3 x 3 x 3',
    '3 x 3 x 2',
    '3/4 x 1/2',
    '1 x 3/4',
    '1-1/2 x 1-1/4',
    '2 x 1-1/2',
    '3 x 2',
  ];
  return commonMatrices.any(normalized.contains);
}

double? _largestPlumbingVariantSize(String variant) {
  final values = <double>[];
  final normalized = variant.toLowerCase();
  final mixed = RegExp(r'(\d+)-(\d+)/(\d+)');
  for (final match in mixed.allMatches(normalized)) {
    values.add(
      double.parse(match.group(1)!) +
          double.parse(match.group(2)!) / double.parse(match.group(3)!),
    );
  }
  final withoutMixed = normalized.replaceAll(mixed, ' ');
  final fraction = RegExp(r'(?<!\d)(\d+)/(\d+)(?!\d)');
  for (final match in fraction.allMatches(withoutMixed)) {
    values.add(double.parse(match.group(1)!) / double.parse(match.group(2)!));
  }
  final withoutFractions = withoutMixed.replaceAll(fraction, ' ');
  final whole = RegExp(r'(?<![\d/])(\d+)(?![\d/])');
  for (final match in whole.allMatches(withoutFractions)) {
    values.add(double.parse(match.group(1)!));
  }
  if (values.isEmpty) return null;
  values.sort();
  return values.last;
}

bool _hasQuarterInchMatrixBranch(String normalizedVariant) {
  return normalizedVariant.startsWith('1/4 x ') ||
      normalizedVariant.contains(' x 1/4 x ') ||
      normalizedVariant.endsWith(' x 1/4');
}

bool _hasPlumbingCompleteTierSignal(String text) {
  return _hasAny(text, _plumbingCompleteTermSignals) ||
      _hasStandaloneInchSize(text, '8') ||
      _hasStandaloneInchSize(text, '10') ||
      _hasStandaloneInchSize(text, '12');
}

bool _hasPlumbingProfessionalSignal(String text) {
  return _hasAny(text, _plumbingProfessionalTermSignals) ||
      _hasStandaloneInchSize(text, '4') ||
      _hasStandaloneInchSize(text, '5') ||
      _hasStandaloneInchSize(text, '6') ||
      _hasStandaloneInchSize(text, '8') ||
      _hasStandaloneInchSize(text, '10') ||
      _hasStandaloneInchSize(text, '12');
}

bool _hasPlumbingCommercialCoreExclusion(String text) {
  return _hasAny(text, _plumbingCommercialOnlyCoreTermExclusions) ||
      _hasStandaloneInchSize(text, '8') ||
      _hasStandaloneInchSize(text, '10') ||
      _hasStandaloneInchSize(text, '12');
}

bool _hasStandaloneInchSize(String text, String size) {
  final pattern = RegExp('${RegExp.escape(size)}\\s+in\\b');
  for (final match in pattern.allMatches(text)) {
    if (match.start == 0) return true;
    final previous = text[match.start - 1];
    if (!'0123456789/-'.contains(previous)) return true;
  }
  return false;
}

const _plumbingCompleteTermSignals = [
  'specialty',
  'legacy',
  'roof drain',
  'interceptor',
  'mop sink',
  'industrial',
];

const _plumbingCoreWellServiceSignals = [
  'well pump',
  'pressure switch',
  'well switch',
  'pressure tank',
  'well tank',
  'tank tee',
  'pressure tank tee',
  'well pipe',
  'pitless adapter',
  'well service fitting',
  'well barb fitting',
  'poly well fitting',
  'well check valve',
  'pump check valve',
  'pressure gauge',
];

const _plumbingProfessionalTermSignals = [
  'backflow',
  'boiler',
  'hydronic',
  'cast iron',
  'no-hub',
  'grease',
  'flushometer',
  'roof drain',
  'interceptor',
  'mop sink',
  'commercial',
];

const _plumbingCommercialOnlyCoreTermExclusions = [
  'no-hub',
  'cast iron',
  'backflow',
  'boiler',
  'hydronic',
  'grease',
  'flushometer',
  'roof drain',
  'interceptor',
  'mop sink',
  '2-1/2',
  '12 in pvc',
  '12 in abs',
  '12 in cast',
];

const _plumbingAlwaysCoreServiceSignals = [
  'angle stop',
  'push angle stop',
  'supply stop',
  'shutoff',
  't&p valve',
  'tpr valve',
  'relief valve',
  'water heater connector',
  'water heater supply connector',
  'vacuum breaker',
  'hose bibb',
  'sillcock',
  'frost-free sillcock',
  'anti siphon',
  'pipe dope',
  'pipe joint compound',
  'thread sealant',
  'o-ring',
  'o ring',
  'crimp ring',
  'clamp ring',
  'cinch ring',
  'toilet seat bolt',
];

const _plumbingCoreValveAndWaterHeaterSignals = [
  'angle stop',
  'ball valve',
  'hose bibb',
  'sillcock',
  'vacuum breaker',
  't&p valve',
  'tpr valve',
  'relief valve',
  'water heater connector',
  'water heater supply connector',
  'drain valve',
];

const _plumbingCoreFittingMaterialSignals = [
  'pex',
  'push-fit',
  'cpvc',
  'copper',
  'pvc schedule 40',
  'pvc dwv',
  'brass',
];

const _plumbingCoreFittingFamilySignals = [
  '90 elbow',
  '45 elbow',
  'tee',
  'wye',
  'sanitary tee',
  'coupling',
  'adapter',
  'mip adapter',
  'fip adapter',
  'sxm adapter',
  'sxf adapter',
  'male adapter',
  'female adapter',
  'trap adapter',
  'stop',
  'angle stop',
  'drop-ear',
  'drop ear',
  'bushing',
  'cleanout',
  'test tee',
  'crimp ring',
  'clamp ring',
  'cinch ring',
];

const _plumbingCoreFittingSizeSignals = [
  '3/8',
  '1/2',
  '3/4',
  '1 in',
  '1 x',
  '1-1/4',
  '1-1/2',
  '2 in',
  '3 in',
];

const _plumbingCoreDrainServiceSignals = [
  'p-trap',
  'p trap',
  'sink trap',
  'tailpiece',
  'extension tube',
  'trap adapter',
  'slip joint',
  'trap washer',
  'disposal drain',
];

const _plumbingCoreDrainFinishSignals = [
  'dishwasher',
  'dishwasher drain',
  'dishwasher hose',
  'disposal',
  'air gap',
  'splash guard',
  'trap adapter',
  'marvel adapter',
  'desanco',
  'compression trap adapter',
  'cleanout',
  'closet flange',
  'flange repair',
  'closet bolt',
  'toilet seat bolt',
  'escutcheon',
  'tailpiece',
];

const _plumbingCoreSealServiceSignals = [
  'flush valve seal',
  'tank gasket',
  'tank to bowl',
  'tank bolt',
  'fill valve shank washer',
  'toilet supply shank washer',
  'wax ring',
  'o-ring',
  'o ring',
  'packing',
  'pipe joint compound',
  'thread sealant',
];

const _plumbingCoreSupportSignals = [
  'pipe strap',
  'pipe j-hook',
  'j-hook',
  'stud guard',
  'nail plate',
  'pipe insulation',
  'bell hanger',
  'split ring',
];

const _residentialSupplySizes = ['1/2', '3/4', '1 in', '3/8', '5/8'];

const _coreDrainSizes = ['1-1/4', '1-1/2', '2 in', '3 in'];

const _coreExpandedSupplySizes = ['1/2', '3/4', '1 in', '1 x'];

const _coreExpandedPressurePipeSizes = [
  '1/2',
  '3/4',
  '1 in',
  '1 x',
  '1-1/4',
  '1-1/2',
  '2 in',
  '3 in',
];

const _coreExpandedDwvSizes = ['1-1/4', '1-1/2', '2 in', '3 in'];

const _standardPlumbingSizes = [
  '1/4',
  '3/8',
  '1/2',
  '3/4',
  '1 in',
  '1-1/4',
  '1-1/2',
  '2 in',
  '3 in',
];

const _standardExpandedResidentialSizes = [
  '1/4',
  '3/8',
  '1/2',
  '3/4',
  '1 in',
  '1 x',
  '1-1/4',
  '1-1/2',
  '2 in',
  '3 in',
];

const _coreFittingTypes = [
  '90 elbow',
  'elbow',
  'tee',
  'coupling',
  'adapter',
  'cap',
  'plug',
  'valve',
  'stop',
  'trap',
  'washer',
  'ring',
];

const _coreExpandedSupplyFittingTypes = [
  '90 elbows',
  '45 elbows',
  'tees',
  'couplings',
  'caps',
  'male adapters',
  'female adapters',
];

const _coreExpandedThreadedOrSweatTypes = [
  '90 elbows',
  '45 elbows',
  'tees',
  'couplings',
  'caps',
  'male adapters',
  'female adapters',
];

const _coreExpandedPressurePipeTypes = [
  '90 elbows',
  '45 elbows',
  'tees',
  'couplings',
  'caps',
  'plugs',
  'male adapters',
  'female adapters',
];

const _coreExpandedDwvTypes = [
  '90 elbows',
  '45 elbows',
  'wyes',
  'sanitary tees',
  'couplings',
  'cleanouts',
];

const _standardFittingTypes = [
  'male adapter',
  'female adapter',
  'transition',
  'union',
  'bushing',
  'reducer',
  'nipple',
  'flange',
  'cleanout',
  'repair',
  'tailpiece',
];

const _standardExpandedFittingTypes = [
  '90 elbows',
  '45 elbows',
  'tees',
  'couplings',
  'reducing couplings',
  'caps',
  'male adapters',
  'female adapters',
  'reducer bushings',
  'wyes',
  'sanitary tees',
  'cleanouts',
];

const _standardResidentialSystems = [
  'brass',
  'black iron',
  'galvanized',
  'copper',
  'pvc',
  'pex',
  'cpvc',
  'dwv',
];

const _standardExpandedResidentialSystems = [
  'brass',
  'copper',
  'pvc schedule 40',
  'pvc dwv',
  'pex',
  'cpvc',
  'push-fit',
];

const _plumbingLightIndustrialSignals = [
  '2 in',
  '3 in',
  '4 in',
  'backflow',
  'boiler',
  'hydronic',
  'pump',
  'well',
  'black iron',
  'galvanized',
  'cast iron',
  'no-hub',
  'dwv',
  'commercial',
];

const _plumbingCommercialOverlapSignals = [
  '3 in',
  '4 in',
  '6 in',
  '8 in',
  'cast iron',
  'no-hub',
  'black iron',
  'galvanized',
  'dwv',
  'backflow',
  'boiler',
  'hydronic',
  'flushometer',
  'commercial',
];
