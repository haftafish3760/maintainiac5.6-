import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserReleaseOneServiceFamilySuite extends QaSuite {
  const WorkSupplyParserReleaseOneServiceFamilySuite()
    : super('inventory.release_one_service_family_contract');

  static const _families = [
    _FamilySpec(
      id: 'plumbing_common_pipe_fittings',
      trade: 'Plumbing',
      tokens: ['elbow', 'tee', 'coupling', 'adapter', 'pipe fitting'],
      minimumMatches: 20,
    ),
    _FamilySpec(
      id: 'plumbing_water_distribution_materials',
      trade: 'Plumbing',
      tokens: ['pex', 'copper', 'cpvc', 'push to connect', 'sharkbite'],
      minimumMatches: 20,
    ),
    _FamilySpec(
      id: 'plumbing_toilet_repair',
      trade: 'Plumbing',
      tokens: ['toilet', 'wax ring', 'closet flange', 'flange repair'],
      minimumMatches: 8,
    ),
    _FamilySpec(
      id: 'plumbing_toilet_tank_rebuild',
      trade: 'Plumbing',
      tokens: [
        'fill valve',
        'flush valve',
        'flapper',
        'tank lever',
        'toilet bolt',
      ],
      minimumMatches: 6,
    ),
    _FamilySpec(
      id: 'plumbing_sink_faucet_repair',
      trade: 'Plumbing',
      tokens: [
        'faucet repair',
        'sink',
        'p-trap',
        'trap adapter',
        'supply line',
      ],
      minimumMatches: 8,
    ),
    _FamilySpec(
      id: 'plumbing_drain_trap_repair',
      trade: 'Plumbing',
      tokens: [
        'p-trap',
        'trap adapter',
        'tailpiece',
        'slip joint',
        'basket strainer',
      ],
      minimumMatches: 8,
    ),
    _FamilySpec(
      id: 'plumbing_valves_supply_stops',
      trade: 'Plumbing',
      tokens: ['valve', 'shutoff', 'stop valve', 'angle stop', 'supply stop'],
      minimumMatches: 12,
    ),
    _FamilySpec(
      id: 'plumbing_water_heater_service',
      trade: 'Plumbing',
      tokens: [
        'water heater',
        'dielectric',
        't&p valve',
        'tpr valve',
        'expansion tank',
      ],
      minimumMatches: 6,
    ),
    _FamilySpec(
      id: 'plumbing_well_service',
      trade: 'Plumbing',
      tokens: [
        'well pump',
        'well pressure tank',
        'pressure switch',
        'well pipe',
        'pitless adapter',
      ],
      minimumMatches: 8,
    ),
    _FamilySpec(
      id: 'electrical_wire_cable',
      trade: 'Electrical',
      tokens: ['wire', 'cable', 'nm-b', 'thhn', 'uf-b'],
      minimumMatches: 8,
    ),
    _FamilySpec(
      id: 'electrical_boxes_devices',
      trade: 'Electrical',
      tokens: ['box', 'switch', 'outlet', 'receptacle', 'gfci'],
      minimumMatches: 8,
    ),
    _FamilySpec(
      id: 'electrical_switch_outlet_repair',
      trade: 'Electrical',
      tokens: ['switch', 'outlet', 'receptacle', 'gfci', 'wall plate'],
      minimumMatches: 8,
    ),
    _FamilySpec(
      id: 'electrical_conduit_support',
      trade: 'Electrical',
      tokens: ['conduit', 'connector', 'coupling', 'strap', 'raceway'],
      minimumMatches: 8,
    ),
    _FamilySpec(
      id: 'electrical_breaker_service',
      trade: 'Electrical',
      tokens: ['breaker', 'afci', 'gfci breaker', 'disconnect', 'panel'],
      minimumMatches: 6,
    ),
    _FamilySpec(
      id: 'electrical_grounding_bonding',
      trade: 'Electrical',
      tokens: ['ground', 'grounding', 'ground rod', 'ground clamp'],
      minimumMatches: 5,
    ),
    _FamilySpec(
      id: 'hvac_filter_airflow',
      trade: 'HVAC',
      tokens: ['filter', 'airflow', 'return air', 'grille'],
      minimumMatches: 6,
    ),
    _FamilySpec(
      id: 'hvac_filter_common_sizes',
      trade: 'HVAC',
      tokens: ['air filter', 'furnace filter', 'return filter', 'merv'],
      minimumMatches: 8,
    ),
    _FamilySpec(
      id: 'hvac_controls_service',
      trade: 'HVAC',
      tokens: [
        'capacitor',
        'contactor',
        'relay',
        'thermostat wire',
        'transformer',
      ],
      minimumMatches: 8,
    ),
    _FamilySpec(
      id: 'hvac_condensate_drain',
      trade: 'HVAC',
      tokens: ['condensate', 'drain', 'trap', 'pump'],
      minimumMatches: 6,
    ),
    _FamilySpec(
      id: 'hvac_service_fasteners_sealants',
      trade: 'HVAC',
      tokens: [
        'sheet metal screw',
        'zip screw',
        'foil tape',
        'mastic',
        'strap',
      ],
      minimumMatches: 6,
    ),
    _FamilySpec(
      id: 'hvac_duct_repair_seal',
      trade: 'HVAC',
      tokens: [
        'foil tape',
        'mastic',
        'duct sealant',
        'duct strap',
        'sheet metal screw',
      ],
      minimumMatches: 8,
    ),
  ];

  static const _requiredSignalsByFamily = {
    'plumbing_common_pipe_fittings': {
      'elbow',
      'tee',
      'coupling',
      'adapter',
      'reducer',
      'bushing',
    },
    'plumbing_water_distribution_materials': {
      'pex',
      'copper',
      'cpvc',
      'push to connect',
    },
    'plumbing_toilet_repair': {
      'wax ring',
      'closet flange',
      'flange repair',
      'closet bolt',
    },
    'plumbing_toilet_tank_rebuild': {
      'fill valve',
      'flush valve',
      'flapper',
      'tank lever',
      'tank bolt',
    },
    'plumbing_sink_faucet_repair': {
      'faucet cartridge',
      'faucet repair kit',
      'aerator',
      'pop up drain',
      'basket strainer',
      'supply line',
    },
    'plumbing_drain_trap_repair': {
      'p-trap',
      'trap adapter',
      'tailpiece',
      'slip joint',
      'basket strainer',
    },
    'plumbing_valves_supply_stops': {
      'shutoff',
      'angle stop',
      'supply stop',
      'ball valve',
    },
    'plumbing_water_heater_service': {
      'water heater',
      'dielectric',
      't&p valve',
      'expansion tank',
    },
    'plumbing_well_service': {
      'well pump',
      'pressure switch',
      'well pipe',
      'pitless adapter',
    },
    'electrical_wire_cable': {'nm-b', 'thhn', 'uf-b'},
    'electrical_boxes_devices': {'switch', 'outlet', 'receptacle', 'gfci'},
    'electrical_conduit_support': {'conduit', 'connector', 'coupling', 'strap'},
    'electrical_breaker_service': {'breaker', 'afci', 'disconnect', 'panel'},
    'electrical_grounding_bonding': {'ground rod', 'ground clamp'},
    'hvac_filter_common_sizes': {'air filter', 'furnace filter', 'merv'},
    'hvac_controls_service': {'capacitor', 'contactor', 'relay'},
    'hvac_condensate_drain': {'condensate', 'trap', 'pump'},
    'hvac_duct_repair_seal': {
      'foil tape',
      'mastic',
      'duct sealant',
      'sheet metal screw',
    },
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final counts = <String, int>{};
    final tierCounts = <String, Map<String, int>>{};
    final examples = <String, List<String>>{};
    final requiredSignalHits = <String, Map<String, int>>{};
    final items = _releaseOneCoreStandardItems().toList(growable: false);

    for (final family in _families) {
      final matches = items
          .where((item) => item.trade == family.trade)
          .where((item) => family.matches(_haystack(item)))
          .toList(growable: false);
      counts[family.id] = matches.length;
      tierCounts[family.id] = _tierCounts(matches);
      examples[family.id] = [
        for (final item in matches.take(5))
          '${item.packTier.name}:${item.name}',
      ];
      final signalHits = _requiredSignalHits(family.id, matches);
      requiredSignalHits[family.id] = signalHits;
      _requireSignals(failures, family, signalHits);
      if (matches.length >= family.minimumMatches) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_release_one_service_family:${family.id}',
          message:
              'Release-one Core/Standard catalog is thin for an everyday service family.',
          severity: QaSeverity.warning,
          expected:
              '${family.trade} Core/Standard >= ${family.minimumMatches} rows matching ${family.tokens.join(', ')}',
          actual: '${matches.length} matching rows',
          suggestedFix:
              'Add or retier common residential service items before expanding Professional/Complete long-tail catalog rows.',
          metadata: const {'triageCategory': QaFailureTriage.category},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: _families.length + items.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'scope': 'Residential Plumbing/Electrical/HVAC Core and Standard',
        'familyCounts': counts,
        'familyTierCounts': tierCounts,
        'familyExamples': examples,
        'requiredSignalHits': requiredSignalHits,
      },
    );
  }

  Iterable<WorkSupplyItem> _releaseOneCoreStandardItems() sync* {
    for (final item in workSupplyCatalogItems) {
      if (item.trade != 'Plumbing' &&
          item.trade != 'Electrical' &&
          item.trade != 'HVAC') {
        continue;
      }
      if (!item.marketScopes.contains(WorkSupplyMarketScope.residential)) {
        continue;
      }
      if (item.packTier != WorkSupplyPackTier.core &&
          item.packTier != WorkSupplyPackTier.standard) {
        continue;
      }
      yield item;
    }
  }

  String _haystack(WorkSupplyItem item) {
    return [
      item.name,
      item.category,
      item.system,
      item.itemType,
      item.variant,
      ...item.aliases,
      ...item.intelligence.attributeTokens,
      ...item.intelligence.receiptPatterns,
      ...item.intelligence.negativeMatchTokens,
      ...item.intelligence.highImportanceTokens,
    ].join(' ').toLowerCase();
  }

  Map<String, int> _requiredSignalHits(
    String familyId,
    Iterable<WorkSupplyItem> matches,
  ) {
    final signals = _requiredSignalsByFamily[familyId];
    if (signals == null) return const {};
    final hits = {for (final signal in signals) signal: 0};
    for (final item in matches) {
      final haystack = _haystack(item);
      for (final signal in signals) {
        if (!haystack.contains(signal)) continue;
        hits.update(signal, (count) => count + 1);
      }
    }
    return hits;
  }

  void _requireSignals(
    List<QaFailure> failures,
    _FamilySpec family,
    Map<String, int> signalHits,
  ) {
    for (final entry in signalHits.entries) {
      if (entry.value > 0) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_release_one_service_signal:${family.id}:${_safeId(entry.key)}',
          message:
              'Release-one Core/Standard service family is missing an everyday required signal.',
          severity: QaSeverity.warning,
          expected:
              '${family.trade} ${family.id} includes ${entry.key} evidence',
          actual: '0 matching Core/Standard rows',
          suggestedFix:
              'Add the missing everyday residential service item, alias, or receipt signal before treating this family as release-one ready.',
          metadata: const {'triageCategory': QaFailureTriage.category},
        ),
      );
    }
  }
}

Map<String, int> _tierCounts(Iterable<WorkSupplyItem> items) {
  final counts = <String, int>{};
  for (final item in items) {
    counts.update(item.packTier.name, (count) => count + 1, ifAbsent: () => 1);
  }
  return counts;
}

String _safeId(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}

class _FamilySpec {
  const _FamilySpec({
    required this.id,
    required this.trade,
    required this.tokens,
    required this.minimumMatches,
  });

  final String id;
  final String trade;
  final List<String> tokens;
  final int minimumMatches;

  bool matches(String haystack) {
    return tokens.any((token) => haystack.contains(token.toLowerCase()));
  }
}
