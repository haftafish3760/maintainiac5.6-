import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserReleaseOnePackBalanceSuite extends QaSuite {
  const WorkSupplyParserReleaseOnePackBalanceSuite()
    : super('inventory.release_one_pack_balance');

  static const _priorityTrades = {'Plumbing', 'Electrical', 'HVAC'};

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final counts = <String, int>{};
    final tierTotalsByTrade = <String, Map<WorkSupplyPackTier, int>>{};

    for (final item in workSupplyCatalogItems) {
      if (!_priorityTrades.contains(item.trade)) continue;
      if (!item.marketScopes.contains(WorkSupplyMarketScope.residential)) {
        continue;
      }
      final tradeCounts = tierTotalsByTrade.putIfAbsent(
        item.trade,
        () => {for (final tier in WorkSupplyPackTier.values) tier: 0},
      );
      tradeCounts[item.packTier] = (tradeCounts[item.packTier] ?? 0) + 1;
      _increment(counts, '${item.trade}.${item.packTier.name}');
    }

    for (final trade in _priorityTrades) {
      final tradeCounts =
          tierTotalsByTrade[trade] ??
          {for (final tier in WorkSupplyPackTier.values) tier: 0};
      _checkTrade(failures, trade, tradeCounts);
    }

    return timer.finish(
      suite: name,
      checked: _priorityTrades.length * 8,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'releaseOneTradeTierCounts': counts,
        'contract':
            'Core should stay service-truck focused; each higher pack should expand coverage without starving Core or skipping Standard.',
        'priorityTrades': _priorityTrades.toList()..sort(),
      },
    );
  }

  void _checkTrade(
    List<QaFailure> failures,
    String trade,
    Map<WorkSupplyPackTier, int> counts,
  ) {
    final core = counts[WorkSupplyPackTier.core] ?? 0;
    final standard = counts[WorkSupplyPackTier.standard] ?? 0;
    final professional = counts[WorkSupplyPackTier.professional] ?? 0;
    final complete = counts[WorkSupplyPackTier.complete] ?? 0;
    final total = core + standard + professional + complete;
    final standardPack = core + standard;
    final professionalPack = standardPack + professional;
    final completePack = professionalPack + complete;
    if (total == 0) {
      _addFailure(
        failures,
        trade,
        'missing_trade',
        'Priority residential trade has no catalog rows.',
        'total > 0',
        'total=0',
      );
      return;
    }
    final coreRatio = core / total;
    if (coreRatio < 0.10 || coreRatio > 0.45) {
      _addFailure(
        failures,
        trade,
        'core_ratio_outside_service_truck_band',
        'Core pack does not look like a focused service-truck pack.',
        'core should be roughly 10%-45% of release-one residential catalog rows',
        'core=$core total=$total ratio=${coreRatio.toStringAsFixed(3)}',
      );
    }
    if (standardPack < core) {
      _addFailure(
        failures,
        trade,
        'standard_pack_smaller_than_core',
        'Standard download pack should include or exceed Core-level coverage.',
        'core + standard >= core',
        'core=$core standardAddOn=$standard standardPack=$standardPack',
      );
    }
    if (professionalPack < standardPack) {
      _addFailure(
        failures,
        trade,
        'professional_pack_smaller_than_standard',
        'Professional download pack should include Standard-level coverage.',
        'core + standard + professional >= core + standard',
        'standardPack=$standardPack professionalPack=$professionalPack',
      );
    }
    if (completePack < professionalPack) {
      _addFailure(
        failures,
        trade,
        'complete_pack_smaller_than_professional',
        'Complete download pack should include Professional-level coverage.',
        'core + standard + professional + complete >= core + standard + professional',
        'professionalPack=$professionalPack completePack=$completePack',
      );
    }
  }

  void _addFailure(
    List<QaFailure> failures,
    String trade,
    String id,
    String message,
    String expected,
    String actual,
  ) {
    failures.add(
      QaFailure(
        suite: name,
        id: '$id:$trade',
        message: message,
        severity: QaSeverity.warning,
        expected: expected,
        actual: actual,
        suggestedFix:
            'Rebalance residential $trade pack tiers so Core represents everyday service-truck work and later tiers expand toward long-tail coverage.',
        metadata: const {'triageCategory': QaFailureTriage.category},
      ),
    );
  }
}

void _increment(Map<String, int> counts, String key) {
  counts.update(key, (count) => count + 1, ifAbsent: () => 1);
}
