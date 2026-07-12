import 'dart:convert';
import 'dart:io';

import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

part 'work_supply_plumbing_core_curation_policy.dart';

const _reportDir = 'build/parser_qa_curation/plumbing_core';

void main(List<String> args) {
  final outputDir = _argValue(args, '--output-dir') ?? _reportDir;
  final report = buildPlumbingCoreCurationAudit();
  final encoded = const JsonEncoder.withIndent('  ').convert(report);
  final directory = Directory(outputDir)..createSync(recursive: true);
  final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(
    ':',
    '',
  );
  final latest = File(
    '${directory.path}/latest_plumbing_core_curation_audit.json',
  );
  final stamped = File(
    '${directory.path}/plumbing_core_curation_audit_$timestamp.json',
  );

  latest.writeAsStringSync(encoded, flush: true);
  stamped.writeAsStringSync(encoded, flush: true);

  stdout.writeln(
    'PLUMBING_CORE_CURATION_AUDIT '
    'core=${report['coreCount']} '
    'outsideCandidates=${(report['likelyCoreOutsideCore'] as List).length} '
    'suspiciousCore=${(report['suspiciousCoreItems'] as List).length} '
    'missingFamilies=${(report['missingRequiredFamilies'] as List).length} '
    'report=${latest.path}',
  );
}

Map<String, Object?> buildPlumbingCoreCurationAudit() {
  final plumbing = workSupplyCatalogItems
      .where((item) => item.trade == 'Plumbing')
      .toList(growable: false);
  final core = plumbing.where(_isResidentialCore).toList(growable: false);
  final likelyCoreOutside =
      plumbing
          .where((item) => !_isResidentialCore(item))
          .map(_candidateOutsideCore)
          .whereType<_Candidate>()
          .toList(growable: false)
        ..sort(_candidateSort);
  final suspiciousCore =
      core
          .map(_suspiciousCoreFinding)
          .whereType<_Finding>()
          .toList(growable: false)
        ..sort(_findingSort);
  final familyCoverage = [
    for (final family in _requiredFamilies) _familyCoverage(core, family),
  ];
  final readiness = core.map(_itemReadiness).toList(growable: false);

  return {
    'schema': 'maintainiac.inventory.plumbing_core_curation_audit.v1',
    'scope': 'Plumbing / Residential / Core',
    'generatedAtUtc': DateTime.now().toUtc().toIso8601String(),
    'professionalStandard':
        'Core means common residential same-day service stock, counter-stock, '
        'or emergency repair material. It is not a random percentage of the '
        'catalog and not a warehouse/industrial/special-order bucket.',
    'rules': {
      'sourceOfTruth': 'catalog metadata + deterministic curation rules',
      'noMutation': true,
      'broadGeneratedParserWavesAllowed': false,
      'nextStep':
          'Review likelyCoreOutsideCore and suspiciousCoreItems before running '
          'large Plumbing Core parser waves.',
    },
    'totalPlumbingItems': plumbing.length,
    'coreCount': core.length,
    'tierCounts': _tierCounts(plumbing),
    'coreCategoryCounts': _countBy(core, (item) => item.category),
    'coreSystemCounts': _countBy(core, (item) => item.system),
    'requiredFamilyCoverage': [for (final entry in familyCoverage) entry.map],
    'missingRequiredFamilies': [
      for (final entry in familyCoverage)
        if (!entry.passes) entry.map,
    ],
    'likelyCoreOutsideCore': [
      for (final candidate in likelyCoreOutside.take(500)) candidate.map,
    ],
    'suspiciousCoreItems': [
      for (final finding in suspiciousCore.take(500)) finding.map,
    ],
    'coreReadinessSamples': readiness.take(250).toList(growable: false),
    'summary': {
      'likelyCoreOutsideCoreTotal': likelyCoreOutside.length,
      'suspiciousCoreTotal': suspiciousCore.length,
      'readinessFloor': _readinessFloor(readiness),
      'readinessAverage': _readinessAverage(readiness),
      'readyForMacValidation': false,
      'reason':
          'Plumbing Core catalog membership must be reviewed and locked before '
          'Mac validation or broad generated parser waves.',
    },
  };
}

bool _isResidentialCore(WorkSupplyItem item) {
  return item.packTier == WorkSupplyPackTier.core &&
      item.marketScopes.contains(WorkSupplyMarketScope.residential);
}

Map<String, int> _tierCounts(List<WorkSupplyItem> items) {
  final counts = {for (final tier in WorkSupplyPackTier.values) tier.name: 0};
  for (final item in items) {
    counts[item.packTier.name] = counts[item.packTier.name]! + 1;
  }
  return counts;
}

Map<String, int> _countBy(
  Iterable<WorkSupplyItem> items,
  String Function(WorkSupplyItem item) keyFor,
) {
  final counts = <String, int>{};
  for (final item in items) {
    counts.update(keyFor(item), (count) => count + 1, ifAbsent: () => 1);
  }
  return Map.fromEntries(
    counts.entries.toList()..sort((left, right) {
      final byCount = right.value.compareTo(left.value);
      return byCount == 0 ? left.key.compareTo(right.key) : byCount;
    }),
  );
}

_FamilyCoverage _familyCoverage(List<WorkSupplyItem> core, _Family family) {
  final matches = core.where(
    (item) => _hasAny(_directText(item), family.signals),
  );
  final sample = matches.take(16).map(_itemLabel).toList(growable: false);
  return _FamilyCoverage(family: family, count: matches.length, sample: sample);
}

_Candidate? _candidateOutsideCore(WorkSupplyItem item) {
  if (!item.marketScopes.contains(WorkSupplyMarketScope.residential)) {
    return null;
  }
  if (_isDeliberateNonCoreServiceStock(item)) return null;
  final text = _directText(item);
  final directText = text;
  final reasons = <String>[];
  for (final rule in _positiveCoreRules) {
    if (_hasAny(text, rule.signals)) reasons.add(rule.reason);
  }
  if (_commonResidentialSize(item)) reasons.add('common_residential_size');
  if (reasons.isEmpty) return null;
  if (_isOversizedForPlumbingCore(item)) return null;
  if (item.category == 'Toilet Repair' &&
      (_primaryNominalInches('${item.name} ${item.variant}') ?? 0) > 4) {
    return null;
  }
  if (_looksLegacyMaterial(directText) &&
      !_looksLegacyRepairBridge(directText)) {
    return null;
  }
  if (_looksWarehouseOrSpecialOrder(directText)) return null;
  if (_looksMajorEquipment(directText) &&
      !_looksServiceReplacementPart(directText)) {
    return null;
  }
  if (!_hasStrongCoreCandidateEvidence(item, reasons)) return null;
  return _Candidate(item, reasons.toSet().toList(growable: false));
}

_Finding? _suspiciousCoreFinding(WorkSupplyItem item) {
  final text = _directText(item);
  final reasons = <String>[];
  if (_isDeliberateNonCoreServiceStock(item)) {
    reasons.add('specialty_or_durable_service_stock_in_core');
  }
  if (_isOversizedForPlumbingCore(item)) {
    reasons.add('oversized_for_daily_residential_core');
  }
  if (_isLongTailGeneratedFitting(item, text)) {
    reasons.add('long_tail_generated_fitting_matrix_in_core');
  }
  if (_looksWarehouseOrSpecialOrder(text)) {
    reasons.add('warehouse_special_order_or_non_residential_signal');
  }
  if (_looksMajorEquipment(text) && !_looksServiceReplacementPart(text)) {
    reasons.add('major_equipment_not_service_stock');
  }
  if (_looksLegacyMaterial(text) &&
      !_looksLegacyRepairBridge(text) &&
      !_isIntentionalCommonBlackIronNipple(item)) {
    reasons.add('legacy_material_without_transition_repair_context');
  }
  if (_positiveSignals(item).isEmpty) {
    reasons.add('missing_positive_service_truck_signal');
  }
  if (reasons.isEmpty) return null;
  return _Finding(item, reasons);
}

bool _isDeliberateNonCoreServiceStock(WorkSupplyItem item) {
  if (item.category != 'Service Truck Stock') return false;
  return item.system == 'Water Treatment Service Stock' ||
      (item.system == 'Plumbing Hand Tools' &&
          !_isDeliberateEverydayCoreHandTool(item.name));
}

bool _isDeliberateEverydayCoreHandTool(String name) {
  final text = name.toLowerCase();
  return const [
    'pex crimp tool',
    'pex clamp cinch tool',
    'mini tubing cutter',
    'ratcheting pvc pipe cutter',
    'pvc deburring tool',
    'copper pipe reaming tool',
    'inside pipe cutter',
    'basin wrench',
    'strap wrench',
    'closet auger',
    'toilet auger',
    'hand drain auger',
    'small drain snake',
  ].any(text.contains);
}

Map<String, Object?> _itemReadiness(WorkSupplyItem item) {
  final signals = _positiveSignals(item);
  final hasSpanish = _hasSpanishCoverage(item);
  final hasReceiptPattern = item.intelligence.receiptPatterns.isNotEmpty;
  final hasHighImportance = item.intelligence.highImportanceTokens.isNotEmpty;
  final risk = _ambiguityRisk(item);
  final score = _readinessScore(
    signals: signals,
    hasSpanish: hasSpanish,
    hasReceiptPattern: hasReceiptPattern,
    hasHighImportance: hasHighImportance,
    ambiguityRisk: risk,
  );
  return {
    'id': item.id,
    'name': item.name,
    'tier': item.packTier.name,
    'category': item.category,
    'system': item.system,
    'itemType': item.itemType,
    'readinessPercent': score,
    'signals': signals,
    'aliasCount': item.aliases.length,
    'hasSpanishCoverage': hasSpanish,
    'hasReceiptPattern': hasReceiptPattern,
    'hasHighImportanceTokens': hasHighImportance,
    'ambiguityRisk': risk,
  };
}

int _readinessScore({
  required List<String> signals,
  required bool hasSpanish,
  required bool hasReceiptPattern,
  required bool hasHighImportance,
  required String ambiguityRisk,
}) {
  var score = 50;
  score += signals.length.clamp(0, 4) * 8;
  if (hasSpanish) score += 8;
  if (hasReceiptPattern) score += 8;
  if (hasHighImportance) score += 6;
  if (ambiguityRisk == 'medium') score -= 8;
  if (ambiguityRisk == 'high') score -= 16;
  return score.clamp(0, 99);
}

int _readinessFloor(List<Map<String, Object?>> readiness) {
  if (readiness.isEmpty) return 0;
  return readiness
      .map((item) => item['readinessPercent']! as int)
      .reduce((left, right) => left < right ? left : right);
}

double _readinessAverage(List<Map<String, Object?>> readiness) {
  if (readiness.isEmpty) return 0;
  final total = readiness
      .map((item) => item['readinessPercent']! as int)
      .reduce((left, right) => left + right);
  return double.parse((total / readiness.length).toStringAsFixed(2));
}

List<String> _positiveSignals(WorkSupplyItem item) {
  final text = _directText(item);
  final signals = <String>[];
  for (final rule in _positiveCoreRules) {
    if (_hasAny(text, rule.signals)) signals.add(rule.reason);
  }
  if (_commonResidentialSize(item)) signals.add('common_residential_size');
  if (_isIntentionalCommonBlackIronNipple(item)) {
    signals.add('common_black_iron_service_nipple');
  }
  if (_isIntentionalCoreCompressionUnion(item)) {
    signals.add('common_compression_union');
  }
  if (_isDeliberateEverydayCoreHandTool(item.name)) {
    signals.add('everyday_residential_service_hand_tool');
  }
  return signals.toSet().toList(growable: false)..sort();
}

bool _hasSpanishCoverage(WorkSupplyItem item) {
  final text = [
    item.name,
    ...item.aliases,
    ...item.intelligence.searchableTokens,
  ].join(' ').toLowerCase();
  return _hasAny(text, _spanishSignals);
}

String _ambiguityRisk(WorkSupplyItem item) {
  final text = _directText(item);
  if (_hasAny(text, ['pvc', 'cpvc', 'copper', 'pipe', 'elbow', 'tee'])) {
    return 'high';
  }
  if (_hasAny(text, ['adapter', 'coupling', 'valve', 'filter', 'pump'])) {
    return 'medium';
  }
  return 'low';
}

bool _isOversizedForPlumbingCore(WorkSupplyItem item) {
  final size = _primaryNominalInches([item.name, item.variant].join(' '));
  if (size == null) return false;
  final text = _directText(item);
  if (_hasNonPipeServiceDimension(text)) return false;
  if (_hasAny(text, ['sump pump', 'well pump', 'sump and condensate']) &&
      text.contains('check valve')) {
    return size > 1.5;
  }
  if (_hasAny(text, ['bell hanger', 'pipe j-hook', 'toilet flange'])) {
    return false;
  }
  if (_hasOversizedSupplyNominalText(text)) return true;
  if (_hasAny(text, [
    'ball valve',
    'gate valve',
    'check valve',
    'backwater valve',
  ])) {
    return size > 1;
  }
  if (_hasAny(text, ['toilet flange', 'closet flange'])) return size > 4;
  if (_hasAny(text, ['dwv', 'drain', 'sewer', 'closet flange'])) {
    return size > 4;
  }
  if (_hasAny(text, ['pex', 'copper', 'cpvc', 'push', 'sharkbite'])) {
    return size > 1;
  }
  if (_hasAny(text, ['pvc schedule 40', 'pressure pipe'])) return size > 2;
  if (_hasAny(text, ['pipe strap', 'j-hook', 'bell hanger'])) return size > 2;
  return size > 4;
}

bool _commonResidentialSize(WorkSupplyItem item) {
  final size = _primaryNominalInches([item.name, item.variant].join(' '));
  if (size == null) return false;
  final text = _directText(item);
  if (_hasAny(text, ['dwv', 'drain', 'sewer'])) return size <= 4;
  if (_hasAny(text, ['pex', 'copper', 'cpvc', 'push', 'sharkbite'])) {
    return const [0.375, 0.5, 0.625, 0.75, 1].contains(size);
  }
  return size <= 2;
}

bool _hasOversizedSupplyNominalText(String text) {
  if (!_hasAny(text, [
    'pex',
    'copper',
    'cpvc',
    'push-fit',
    'push to connect',
    'sharkbite',
  ])) {
    return false;
  }
  return RegExp(
    r'(^|\s)(1-1/4|1-1/2|2|2-1/2|3|3-1/2|4)\s*(in|inch|")\b',
  ).hasMatch(text);
}

double? _primaryNominalInches(String raw) {
  final text = raw.toLowerCase();
  final leadingBeforeBy = RegExp(
    r'^\s*(\d+(?:-\d+/\d+)?|\d+/\d+|\d+(?:\.\d+)?)\s*x\b',
  ).firstMatch(text);
  if (leadingBeforeBy != null) {
    return _parseNominalNumber(leadingBeforeBy.group(1)!);
  }
  final leading = RegExp(
    r'^\s*(\d+(?:-\d+/\d+)?|\d+/\d+|\d+(?:\.\d+)?)\s*(?:in|inch|")\b',
  ).firstMatch(text);
  if (leading != null) return _parseNominalNumber(leading.group(1)!);
  return _largestNominalInches(raw);
}

double? _largestNominalInches(String raw) {
  final text = raw.toLowerCase();
  final values = <double>[];
  final mixed = RegExp(r'(\d+)-(\d+)/(\d+)\s*(?:in|inch|")');
  for (final match in mixed.allMatches(text)) {
    values.add(
      double.parse(match.group(1)!) +
          double.parse(match.group(2)!) / double.parse(match.group(3)!),
    );
  }
  final fraction = RegExp(r'(?<!\d)(\d+)/(\d+)\s*(?:in|inch|")');
  for (final match in fraction.allMatches(text)) {
    values.add(double.parse(match.group(1)!) / double.parse(match.group(2)!));
  }
  final decimal = RegExp(r'(?<![\d/])(\d+(?:\.\d+)?)\s*(?:in|inch|")');
  for (final match in decimal.allMatches(text)) {
    values.add(double.parse(match.group(1)!));
  }
  if (values.isEmpty) return null;
  values.sort();
  return values.last;
}

double? _parseNominalNumber(String raw) {
  final mixed = RegExp(r'^(\d+)-(\d+)/(\d+)$').firstMatch(raw);
  if (mixed != null) {
    return double.parse(mixed.group(1)!) +
        double.parse(mixed.group(2)!) / double.parse(mixed.group(3)!);
  }
  final fraction = RegExp(r'^(\d+)/(\d+)$').firstMatch(raw);
  if (fraction != null) {
    return double.parse(fraction.group(1)!) / double.parse(fraction.group(2)!);
  }
  return double.tryParse(raw);
}

bool _looksWarehouseOrSpecialOrder(String text) {
  return _hasAny(text, [
    'special order',
    'industrial',
    'commercial',
    'warehouse',
    'bulk pallet',
    'case of',
    'skid',
  ]);
}

bool _looksMajorEquipment(String text) {
  if (_hasAny(text, [
    'connector',
    'supply line',
    'drain pan',
    'restraint strap',
    'install accessory',
    'element',
    'thermostat',
    't&p valve',
    'tpr valve',
    'anode',
    'drain valve',
    'expansion tank',
    'pressure tank',
    'well tank',
    'pressure gauge',
    'dielectric union',
    'dielectric nipple',
    'mixing valve',
    'water heater service fitting',
  ])) {
    return false;
  }
  return _hasAny(text, [
    'water heater',
    'tankless',
    'boiler',
    'softener system',
    'pressure tank',
  ]);
}
