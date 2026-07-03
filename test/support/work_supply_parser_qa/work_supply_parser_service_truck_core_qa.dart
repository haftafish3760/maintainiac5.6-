import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserServiceTruckCoreSuite extends QaSuite {
  const WorkSupplyParserServiceTruckCoreSuite()
    : super('inventory.service_truck_core_contract');

  static const _priorityTrades = {'Plumbing', 'Electrical', 'HVAC'};
  static const _serviceTruckSignals = {
    'repair',
    'service',
    'replacement',
    'connector',
    'fitting',
    'valve',
    'line',
    'wire',
    'filter',
    'fastener',
    'screw',
    'strap',
    'hanger',
    'ground',
    'clamp',
    'adapter',
    'coupling',
    'drain',
    'elbow',
    'trap',
    'tailpiece',
    'tube',
    'nut',
    'washer',
    'water heater',
    'dielectric',
    'expansion',
    'compound',
    'tape',
    'cement',
    'primer',
    'putty',
    'silicone',
    'sealant',
    'motor',
    'blower',
    'fan blade',
    'condenser',
    'tee',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final warningByTrade = <String, int>{};
    final signalCounts = <String, int>{};
    var checked = 0;

    for (final item in _coreItems()) {
      checked += 4;
      final signals = _signalsFor(item);
      for (final signal in signals) {
        _increment(signalCounts, signal);
      }
      if (signals.isNotEmpty &&
          item.parserPriority == WorkSupplyParserPriority.everydayCore) {
        continue;
      }
      _increment(warningByTrade, item.trade);
      failures.add(
        QaFailure(
          suite: name,
          id: 'core_service_truck_intent_gap:${item.id}',
          message:
              'Residential Core item needs clearer everyday service-truck intent.',
          severity: QaSeverity.warning,
          expected:
              'everydayCore priority plus service-truck/repair/fastener/fitting signal',
          actual:
              '${item.path} / ${item.name}; priority=${item.parserPriority.name}; signals=${signals.join(', ')}',
          suggestedFix:
              'Mark true everyday stock as everydayCore and add service-truck intent tokens; move long-tail rows to later tiers.',
          metadata: const {'triageCategory': QaFailureTriage.category},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'scope': 'Residential Plumbing, Electrical, and HVAC Core rows only.',
        'warningsByTrade': _topCounts(warningByTrade),
        'serviceTruckSignalCounts': _topCounts(signalCounts),
        'requiredSignals': _serviceTruckSignals.toList()..sort(),
      },
    );
  }

  Iterable<WorkSupplyItem> _coreItems() sync* {
    for (final item in workSupplyCatalogItems) {
      if (!_priorityTrades.contains(item.trade)) continue;
      if (item.packTier != WorkSupplyPackTier.core) continue;
      if (!item.marketScopes.contains(WorkSupplyMarketScope.residential)) {
        continue;
      }
      yield item;
    }
  }

  List<String> _signalsFor(WorkSupplyItem item) {
    final haystack = [
      item.name,
      item.category,
      item.system,
      item.itemType,
      item.variant,
      ...item.aliases,
      ...item.intelligence.attributeTokens,
      ...item.intelligence.receiptPatterns,
    ].join(' ').toLowerCase();
    return [
      for (final signal in _serviceTruckSignals)
        if (haystack.contains(signal)) signal,
    ];
  }
}

void _increment(Map<String, int> counts, String key) {
  counts.update(key, (count) => count + 1, ifAbsent: () => 1);
}

List<Map<String, Object?>> _topCounts(
  Map<String, int> counts, {
  int limit = 12,
}) {
  final entries = counts.entries.toList()
    ..sort((left, right) => right.value.compareTo(left.value));
  return [
    for (final entry in entries.take(limit))
      {'name': entry.key, 'count': entry.value},
  ];
}
