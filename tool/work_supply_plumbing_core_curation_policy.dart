part of 'work_supply_plumbing_core_curation_audit.dart';

bool _hasNonPipeServiceDimension(String text) {
  return _hasAny(text, [
    'supply line',
    'gas appliance connector',
    'water heater connector',
    'water heater supply connector',
    'drain pan',
    'restraint strap',
    'anode rod',
    'filter cartridge',
    'water filter service part',
    'floor drain grate',
    'floor drain finish',
    'hole saw',
    'saw blade',
    'plumber sand cloth',
    'soldering heat shield',
  ]);
}

bool _looksServiceReplacementPart(String text) {
  return _hasAny(text, [
    'connector',
    'supply line',
    'drain pan',
    'restraint strap',
    'install accessory',
    'dielectric union',
    'dielectric nipple',
    'mixing valve',
    'water heater service fitting',
    'element',
    'thermostat',
    't&p valve',
    'tpr valve',
    'anode',
    'drain valve',
    'pressure switch',
    'pressure gauge',
    'pressure tank',
    'well tank',
    'tank tee',
    'relief valve',
    'filter cartridge',
    'salt',
  ]);
}

bool _hasStrongCoreCandidateEvidence(
  WorkSupplyItem item,
  List<String> reasons,
) {
  final set = reasons.toSet();
  final directText = _directText(item);
  final serviceFamilies = {
    'drain_trap_repair',
    'toilet_service',
    'faucet_sink_service',
    'valves_stops',
    'well_service',
    'well_pressure_stock',
    'service_consumables',
  };
  if (set.intersection(serviceFamilies).isNotEmpty) {
    return true;
  }
  if (_isLongTailGeneratedFitting(item, directText)) return false;
  if (set.contains('common_residential_size') &&
      set.contains('pipe_fittings') &&
      set.contains('modern_supply_material')) {
    return true;
  }
  return false;
}

bool _isLongTailGeneratedFitting(WorkSupplyItem item, String directText) {
  final type = item.itemType.toLowerCase();
  if (type.contains('expanded')) return true;
  if (_hasAny(directText, ['street 45', 'street 90', '22.5 elbow'])) {
    return true;
  }
  final dimensions = item.variant
      .toLowerCase()
      .split(RegExp(r'\s+x\s+'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (dimensions.length < 3) return false;
  return dimensions.toSet().length > 1;
}

bool _looksLegacyMaterial(String text) {
  if (_hasAny(text, ['saw blade', 'hole saw', 'cutting wheel', 'hand tool'])) {
    return false;
  }
  return _hasAny(text, ['galvanized', 'black iron', 'cast iron']);
}

bool _looksLegacyRepairBridge(String text) {
  return _hasAny(text, [
    'fernco',
    'no-hub',
    'no hub',
    'shielded',
    'transition',
    'adapter',
    'repair',
    'coupling',
  ]);
}

bool _isIntentionalCommonBlackIronNipple(WorkSupplyItem item) {
  if (item.system.toLowerCase() != 'black iron' ||
      !item.itemType.toLowerCase().contains('nipple')) {
    return false;
  }
  if ((_primaryNominalInches(item.variant) ?? 0) != .75) return false;
  return RegExp(
    r'\bx\s+(?:2|3|4|6)\s*in\b',
  ).hasMatch(item.variant.toLowerCase());
}

bool _isIntentionalCoreCompressionUnion(WorkSupplyItem item) =>
    item.system.toLowerCase() == 'brass' &&
    item.itemType.toLowerCase().contains('compression union') &&
    (_primaryNominalInches(item.variant) ?? 0) == .375;

bool _hasAny(String text, Iterable<String> signals) {
  return signals.any(text.contains);
}

String _directText(WorkSupplyItem item) {
  return [
    item.id,
    item.name,
    item.trade,
    item.category,
    item.system,
    item.itemType,
    item.variant,
    item.unit,
  ].join(' ').toLowerCase();
}

String _itemLabel(WorkSupplyItem item) => '${item.id}: ${item.name}';

String? _argValue(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index == -1 || index + 1 >= args.length) return null;
  return args[index + 1];
}

int _candidateSort(_Candidate left, _Candidate right) {
  final byReasons = right.reasons.length.compareTo(left.reasons.length);
  if (byReasons != 0) return byReasons;
  return left.item.name.compareTo(right.item.name);
}

int _findingSort(_Finding left, _Finding right) {
  final byReasons = right.reasons.length.compareTo(left.reasons.length);
  if (byReasons != 0) return byReasons;
  return left.item.name.compareTo(right.item.name);
}

const _positiveCoreRules = [
  _SignalRule('pipe_fittings', [
    'elbow',
    'tee',
    'coupling',
    'adapter',
    'wye',
    'cleanout',
    'bushing',
    'reducer',
    'union',
    'cap',
    'plug',
    'ring',
  ]),
  _SignalRule('modern_supply_material', ['pex', 'cpvc', 'copper', 'push']),
  _SignalRule('drain_trap_repair', ['p-trap', 'trap adapter', 'tailpiece']),
  _SignalRule('toilet_service', ['toilet', 'wax ring', 'closet flange']),
  _SignalRule('faucet_sink_service', ['faucet', 'sink', 'aerator']),
  _SignalRule('valves_stops', [
    'angle stop',
    'shutoff',
    'supply stop',
    'valve',
  ]),
  _SignalRule('well_service', ['well pump', 'pressure switch', 'pitless']),
  _SignalRule('well_pressure_stock', ['pressure tank', 'pressure gauge']),
  _SignalRule('service_consumables', [
    'cement',
    'primer',
    'tape',
    'putty',
    'thread seal',
    'pipe joint compound',
    'silicone',
    'pipe lubricant',
  ]),
  _SignalRule('pipe_protection', ['stud guard', 'nail plate']),
  _SignalRule('water_heater_service', [
    'water heater',
    'expansion tank',
    'drain pan',
    'restraint strap',
  ]),
  _SignalRule('pump_and_drain_service', [
    'sump pump',
    'float switch',
    'pump control',
    'drain repair',
    'floor drain',
  ]),
  _SignalRule('fixture_repair_service', [
    'shower cartridge',
    'hose bibb',
    'vacuum breaker',
    'no-hub band',
  ]),
];

const _requiredFamilies = [
  _Family('pipe fittings and adapters', 300, [
    'elbow',
    'tee',
    'coupling',
    'adapter',
    'bushing',
    'reducer',
  ]),
  _Family('modern water distribution', 120, [
    'pex',
    'copper',
    'cpvc',
    'push to connect',
    'sharkbite',
  ]),
  _Family('toilet and fixture repair', 80, [
    'toilet',
    'wax ring',
    'closet flange',
    'fill valve',
    'flapper',
    'faucet',
  ]),
  _Family('drain trap and tubular repair', 60, [
    'p-trap',
    'trap adapter',
    'tailpiece',
    'slip joint',
    'basket strainer',
  ]),
  _Family('valves and supply stops', 60, [
    'valve',
    'angle stop',
    'shutoff',
    'supply stop',
  ]),
  _Family('well pump and pressure service', 20, [
    'well pump',
    'pressure switch',
    'pressure tank',
    'pressure gauge',
    'well gauge',
    'pitless adapter',
    'tank tee',
  ]),
  _Family('same-day consumables', 20, ['cement', 'primer', 'thread seal']),
];

const _spanishSignals = [
  'codo',
  'tee',
  'acople',
  'adaptador',
  'valvula',
  'inodoro',
  'grifo',
  'fregadero',
  'trampa',
  'bomba',
  'filtro',
  'suavizador',
  'sal',
];

class _SignalRule {
  const _SignalRule(this.reason, this.signals);

  final String reason;
  final List<String> signals;
}

class _Family {
  const _Family(this.name, this.minimumRows, this.signals);

  final String name;
  final int minimumRows;
  final List<String> signals;
}

class _FamilyCoverage {
  const _FamilyCoverage({
    required this.family,
    required this.count,
    required this.sample,
  });

  final _Family family;
  final int count;
  final List<String> sample;

  bool get passes => count >= family.minimumRows;

  Map<String, Object?> get map => {
    'family': family.name,
    'minimumRows': family.minimumRows,
    'actualRows': count,
    'passes': passes,
    'sample': sample,
  };
}

class _Candidate {
  const _Candidate(this.item, this.reasons);

  final WorkSupplyItem item;
  final List<String> reasons;

  Map<String, Object?> get map => {
    'id': item.id,
    'name': item.name,
    'currentTier': item.packTier.name,
    'category': item.category,
    'system': item.system,
    'itemType': item.itemType,
    'reasons': reasons,
  };
}

class _Finding {
  const _Finding(this.item, this.reasons);

  final WorkSupplyItem item;
  final List<String> reasons;

  Map<String, Object?> get map => {
    'id': item.id,
    'name': item.name,
    'category': item.category,
    'system': item.system,
    'itemType': item.itemType,
    'reasons': reasons,
  };
}
