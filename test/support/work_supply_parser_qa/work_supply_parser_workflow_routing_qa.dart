import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserWorkflowRoutingSuite extends QaSuite {
  const WorkSupplyParserWorkflowRoutingSuite()
    : super('inventory.workflow_routing');

  static const _priorityTrades = {'Plumbing', 'Electrical', 'HVAC'};

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final warningByTradeTier = <String, int>{};
    final missingSignalCounts = <String, int>{};
    var checked = 0;

    for (final item in _releaseOneCoreAndStandardItems()) {
      checked += 9;
      final missing = _missingWorkflowSignals(item);
      for (final signal in missing) {
        _increment(missingSignalCounts, signal);
      }
      if (missing.isEmpty) continue;
      _increment(warningByTradeTier, '${item.trade}.${item.packTier.name}');
      failures.add(
        QaFailure(
          suite: name,
          id: 'workflow_routing_gap:${item.id}',
          message:
              'Release-one item is not fully ready for parser-to-workflow routing.',
          severity: QaSeverity.warning,
          expected:
              'inventory, expense, job, estimate/invoice cost behavior, tax reporting, markup, and billable routing hints',
          actual: '${item.path} / ${item.name}; missing=${missing.join(', ')}',
          suggestedFix:
              'Fill parser classification/routing metadata so a receipt line can become a reviewable inventory/job/estimate/invoice candidate without UI coupling.',
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
        'contract': 'inventory/job/estimate/invoice routing',
        'scope':
            'Residential Plumbing, Electrical, and HVAC Core/Standard rows only.',
        'warningsByTradeTier': _topCounts(warningByTradeTier, limit: 12),
        'topMissingWorkflowSignals': _topCounts(missingSignalCounts),
      },
    );
  }

  Iterable<WorkSupplyItem> _releaseOneCoreAndStandardItems() sync* {
    for (final item in workSupplyCatalogItems) {
      if (!_priorityTrades.contains(item.trade)) continue;
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

  List<String> _missingWorkflowSignals(WorkSupplyItem item) {
    final classification = item.intelligence.classification;
    final missing = <String>[];
    if (classification.inventoryCategory.trim().isEmpty) {
      missing.add('inventoryCategory');
    }
    if (classification.expenseCategory.trim().isEmpty) {
      missing.add('expenseCategory');
    }
    if (classification.jobMaterialCategory.trim().isEmpty) {
      missing.add('jobMaterialCategory');
    }
    if (classification.taxReportingCategory.trim().isEmpty) {
      missing.add('taxReportingCategory');
    }
    if (classification.defaultUnitCostBehavior.trim().isEmpty) {
      missing.add('defaultUnitCostBehavior');
    }
    if (classification.defaultMarkupBehavior.trim().isEmpty) {
      missing.add('defaultMarkupBehavior');
    }
    if (item.unit.trim().isEmpty) missing.add('unit');
    if (item.intelligence.packQuantity.trim().isEmpty) {
      missing.add('packQuantity');
    }
    if (!classification.billableMaterial && item.trade != 'Tools and Safety') {
      missing.add('billableMaterialReview');
    }
    return missing;
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
