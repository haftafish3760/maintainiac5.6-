import 'dart:io';

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
    'pipe fitting',
    'toilet repair kit',
    'sink repair kit',
    'faucet repair kit',
  };

  static const _coreStandardPrioritySignals = {
    'Core and Standard are priority one',
    'common residential pipe fittings',
    'pipe fittings found in a residential home',
    'toilet repair kits',
    'sink repair kits',
    'faucet repair kits',
    'everyday service-truck reality',
    'Professional and Complete later',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final warningByTrade = <String, int>{};
    final signalCounts = <String, int>{};
    final source = _readPriorityContractSource();
    var checked = 0;

    checked += _coreStandardPrioritySignals.length;
    _requirePriorityContract(failures, source);

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
        'coreStandardPrioritySignals': _coreStandardPrioritySignals.toList()
          ..sort(),
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

  String _readPriorityContractSource() {
    final buffer = StringBuffer();
    for (final path in const [
      'docs/materials_catalog_intelligence_contract.md',
      'docs/inventory_parser_qa_progress_memory.md',
    ]) {
      final file = File(path);
      if (file.existsSync()) buffer.writeln(file.readAsStringSync());
    }
    return buffer.toString();
  }

  void _requirePriorityContract(List<QaFailure> failures, String source) {
    final lower = source.toLowerCase();
    for (final signal in _coreStandardPrioritySignals) {
      if (lower.contains(signal.toLowerCase())) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_core_standard_priority:${_safeId(signal)}',
          message:
              'Service-truck Core/Standard QA is missing release-one priority language.',
          severity: QaSeverity.warning,
          expected: signal,
          actual: 'not found',
          suggestedFix:
              'Document and enforce Core/Standard as priority-one service-truck coverage before broad Professional/Complete expansion.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }
  }
}

void _increment(Map<String, int> counts, String key) {
  counts.update(key, (count) => count + 1, ifAbsent: () => 1);
}

String _safeId(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
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
