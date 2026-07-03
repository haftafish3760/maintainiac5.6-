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
      id: 'plumbing_toilet_repair',
      trade: 'Plumbing',
      tokens: ['toilet', 'wax ring', 'closet flange', 'flange repair'],
      minimumMatches: 8,
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
      id: 'electrical_conduit_support',
      trade: 'Electrical',
      tokens: ['conduit', 'connector', 'coupling', 'strap', 'raceway'],
      minimumMatches: 8,
    ),
    _FamilySpec(
      id: 'hvac_filter_airflow',
      trade: 'HVAC',
      tokens: ['filter', 'airflow', 'return air', 'grille'],
      minimumMatches: 6,
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
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final counts = <String, int>{};
    final examples = <String, List<String>>{};
    final items = _releaseOneCoreStandardItems().toList(growable: false);

    for (final family in _families) {
      final matches = items
          .where((item) => item.trade == family.trade)
          .where((item) => family.matches(_haystack(item)))
          .toList(growable: false);
      counts[family.id] = matches.length;
      examples[family.id] = [
        for (final item in matches.take(5))
          '${item.packTier.name}:${item.name}',
      ];
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
        'familyExamples': examples,
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
