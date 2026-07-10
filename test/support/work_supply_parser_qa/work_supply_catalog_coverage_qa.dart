import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyCatalogCoverageSuite extends QaSuite {
  const WorkSupplyCatalogCoverageSuite() : super('inventory.catalog_coverage');

  static const _priorityTrades = {'Plumbing', 'Electrical', 'HVAC'};

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final tradeCounts = <String, int>{};
    final scopeTierCounts = <String, int>{};
    final tradeScopeTierCounts = <String, int>{};
    final priorityCounts = <String, int>{};

    for (final item in workSupplyCatalogItems) {
      tradeCounts.update(item.trade, (count) => count + 1, ifAbsent: () => 1);
      for (final scope in item.marketScopes) {
        final scopeTierKey = '${scope.name}.${item.packTier.name}';
        final tradeScopeTierKey =
            '${item.trade}.${scope.name}.${item.packTier.name}';
        scopeTierCounts.update(
          scopeTierKey,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
        tradeScopeTierCounts.update(
          tradeScopeTierKey,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
        if (_priorityTrades.contains(item.trade)) {
          priorityCounts.update(
            tradeScopeTierKey,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
        }
      }
    }

    for (final trade in _priorityTrades) {
      _requireCoverage(
        failures,
        tradeScopeTierCounts,
        '$trade.${WorkSupplyMarketScope.residential.name}.${WorkSupplyPackTier.core.name}',
        'Priority trade is missing residential Core catalog coverage.',
      );
      _requireCoverage(
        failures,
        tradeScopeTierCounts,
        '$trade.${WorkSupplyMarketScope.residential.name}.${WorkSupplyPackTier.standard.name}',
        'Priority trade is missing residential Standard catalog coverage.',
      );
    }

    for (final scope in WorkSupplyMarketScope.values) {
      for (final tier in WorkSupplyPackTier.values) {
        final key = '${scope.name}.${tier.name}';
        if (scopeTierCounts.containsKey(key)) continue;
        failures.add(
          QaFailure(
            suite: name,
            id: 'missing_scope_tier:$key',
            message: 'Catalog has no items for a market-scope/pack-tier cell.',
            severity: QaSeverity.warning,
            expected: key,
            actual: scopeTierCounts.keys.join(', '),
            suggestedFix:
                'Add catalog rows for this cell or mark the gap as intentionally out of release scope.',
          ),
        );
      }
    }

    return timer.finish(
      suite: name,
      checked:
          workSupplyCatalogItems.length +
          (_priorityTrades.length * 2) +
          (WorkSupplyMarketScope.values.length *
              WorkSupplyPackTier.values.length),
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'itemCount': workSupplyCatalogItems.length,
        'tradeCounts': tradeCounts,
        'scopeTierCounts': scopeTierCounts,
        'priorityTradeScopeTierCounts': priorityCounts,
      },
    );
  }

  void _requireCoverage(
    List<QaFailure> failures,
    Map<String, int> counts,
    String key,
    String message,
  ) {
    if ((counts[key] ?? 0) > 0) return;
    failures.add(
      QaFailure(
        suite: name,
        id: 'missing_priority_coverage:$key',
        message: message,
        severity: QaSeverity.error,
        expected: key,
        actual: counts.keys
            .where((entry) => entry.startsWith(key.split('.').first))
            .join(', '),
        suggestedFix:
            'Release-one priority trades need residential Core and Standard coverage before accuracy claims.',
      ),
    );
  }
}
