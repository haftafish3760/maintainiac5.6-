import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserItemMetadataDepthSuite extends QaSuite {
  const WorkSupplyParserItemMetadataDepthSuite()
    : super('inventory.item_metadata_depth');

  static const _highRiskFamilies = {
    'adapter',
    'box',
    'cap',
    'cement',
    'connector',
    'conduit',
    'coupling',
    'elbow',
    'filter',
    'fitting',
    'kit',
    'pipe',
    'plug',
    'primer',
    'tape',
    'tee',
    'valve',
    'wire',
  };

  static const _majorMerchantHints = {
    'ace',
    'ferguson',
    'grainger',
    'home depot',
    'lowe',
    'menards',
    'supplyhouse',
    'true value',
    'walmart',
  };

  static const _priorityTrades = {'Plumbing', 'Electrical', 'HVAC'};

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final items = _orderedForQa(
      context.isFullProfile
          ? workSupplyCatalogItems
          : _sampledItems(
              workSupplyCatalogItems,
              limit: context.catalogSchemaSampleLimit,
            ),
    );
    final scoreBuckets = <String, int>{};
    final missingSignalCounts = <String, int>{};
    final riskTermCounts = <String, int>{};
    final warningCountsByTrade = <String, int>{};
    final warningCountsByTier = <String, int>{};
    final warningCountsByPriorityScope = <String, int>{};
    final checkedCountsByPriorityScope = <String, int>{};
    var checkedContracts = 0;

    for (final item in items) {
      final score = _scoreItem(item);
      final riskTerms = _riskTermsFor(item);
      final priorityScope = _priorityScope(item);
      _increment(checkedCountsByPriorityScope, priorityScope);
      scoreBuckets.update(score.label, (count) => count + 1, ifAbsent: () => 1);
      for (final missing in score.missing) {
        _increment(missingSignalCounts, missing);
      }
      for (final risk in riskTerms) {
        _increment(riskTermCounts, risk);
      }
      final failuresBefore = failures.length;
      checkedContracts += 12;
      _checkMinimumDepth(failures, item, score);
      _checkRiskGuards(failures, item, riskTerms);
      _checkClassification(failures, item);
      _checkVersioning(failures, item);
      if (failures.length != failuresBefore) {
        _increment(warningCountsByTrade, item.trade);
        _increment(warningCountsByTier, item.packTier.name);
        _increment(warningCountsByPriorityScope, priorityScope);
      }
    }

    return timer.finish(
      suite: name,
      checked: checkedContracts,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'catalogItemCount': workSupplyCatalogItems.length,
        'profileItemCount': items.length,
        'scoreBuckets': scoreBuckets,
        'topMissingSignals': _topCounts(missingSignalCounts),
        'topRiskTerms': _topCounts(riskTermCounts),
        'warningsByTrade': _topCounts(warningCountsByTrade, limit: 20),
        'warningsByTier': _topCounts(warningCountsByTier, limit: 8),
        'warningsByPriorityScope': _topCounts(
          warningCountsByPriorityScope,
          limit: 8,
        ),
        'checkedByPriorityScope': _topCounts(
          checkedCountsByPriorityScope,
          limit: 8,
        ),
        'failurePriority':
            'Plumbing, Electrical, and HVAC residential items are scanned first so capped reports show release-one trade gaps before lower-priority trades.',
        'sampleLimit': context.isFullProfile
            ? 'all'
            : context.catalogSchemaSampleLimit,
      },
    );
  }

  List<WorkSupplyItem> _orderedForQa(List<WorkSupplyItem> items) {
    final copy = [...items];
    copy.sort((left, right) {
      final priority = _priorityRank(left).compareTo(_priorityRank(right));
      if (priority != 0) return priority;
      final tier = left.packTier.index.compareTo(right.packTier.index);
      if (tier != 0) return tier;
      final trade = left.trade.compareTo(right.trade);
      if (trade != 0) return trade;
      return left.id.compareTo(right.id);
    });
    return copy;
  }

  int _priorityRank(WorkSupplyItem item) {
    if (_priorityTrades.contains(item.trade) &&
        item.marketScopes.contains(WorkSupplyMarketScope.residential)) {
      return 0;
    }
    if (_priorityTrades.contains(item.trade)) return 1;
    if (item.marketScopes.contains(WorkSupplyMarketScope.residential)) return 2;
    return 3;
  }

  String _priorityScope(WorkSupplyItem item) {
    if (_priorityTrades.contains(item.trade) &&
        item.marketScopes.contains(WorkSupplyMarketScope.residential)) {
      return 'release_one_residential_priority_trades';
    }
    if (_priorityTrades.contains(item.trade)) {
      return 'release_one_priority_trades_other_scope';
    }
    if (item.marketScopes.contains(WorkSupplyMarketScope.residential)) {
      return 'other_residential_trades';
    }
    return 'other_trades_other_scope';
  }

  void _checkMinimumDepth(
    List<QaFailure> failures,
    WorkSupplyItem item,
    _ItemMetadataScore score,
  ) {
    final coreOrStandard =
        item.packTier == WorkSupplyPackTier.core ||
        item.packTier == WorkSupplyPackTier.standard;
    final residential = item.marketScopes.contains(
      WorkSupplyMarketScope.residential,
    );
    final expectedScore = coreOrStandard && residential ? 9 : 7;
    if (score.points >= expectedScore) return;
    failures.add(
      _failure(
        item,
        id: 'thin_parser_metadata:${item.id}',
        message: 'Catalog item does not yet have world-class parser metadata.',
        expected: 'score >= $expectedScore for ${item.packTier.name}',
        actual: 'score=${score.points}; missing=${score.missing.join(', ')}',
        fix:
            'Add aliases, receipt patterns, attribute tokens, negative-match guards, confidence tokens, and classification before release.',
      ),
    );
  }

  void _checkRiskGuards(
    List<QaFailure> failures,
    WorkSupplyItem item,
    List<String> riskTerms,
  ) {
    if (riskTerms.isEmpty) return;
    final intelligence = item.intelligence;
    if (intelligence.negativeMatchTokens.length >= 2 &&
        intelligence.highImportanceTokens.isNotEmpty) {
      return;
    }
    failures.add(
      _failure(
        item,
        id: 'missing_conflict_guards:${item.id}',
        message: 'High-risk item family needs conflict/negative-match guards.',
        expected: 'negativeMatchTokens >= 2 and highImportanceTokens present',
        actual:
            'risk=${riskTerms.take(4).join(', ')}; negative=${intelligence.negativeMatchTokens.length}; high=${intelligence.highImportanceTokens.length}',
        fix:
            'Guard ambiguous families such as PVC, conduit, tape, filter, box, coupling, elbow, tee, pipe, wire, connector, and valve.',
        category: QaFailureTriage.conflict,
      ),
    );
  }

  void _checkClassification(List<QaFailure> failures, WorkSupplyItem item) {
    final classification = item.intelligence.classification;
    final missing = [
      if (classification.inventoryCategory.trim().isEmpty) 'inventoryCategory',
      if (classification.expenseCategory.trim().isEmpty) 'expenseCategory',
      if (classification.jobMaterialCategory.trim().isEmpty)
        'jobMaterialCategory',
      if (classification.defaultUnitCostBehavior.trim().isEmpty)
        'defaultUnitCostBehavior',
    ];
    if (missing.isEmpty) return;
    failures.add(
      _failure(
        item,
        id: 'missing_parser_output_classification:${item.id}',
        message: 'Item cannot fully feed inventory/job/estimate workflows yet.',
        expected: 'inventory, expense, job material, and cost behavior fields',
        actual: 'missing=${missing.join(', ')}',
        fix:
            'Add parser output classification so receipt matches can flow into inventory, jobs, estimates, and invoices without UI coupling.',
        category: QaFailureTriage.category,
      ),
    );
  }

  void _checkVersioning(List<QaFailure> failures, WorkSupplyItem item) {
    final intelligence = item.intelligence;
    final missing = [
      if (intelligence.catalogVersion.trim().isEmpty) 'catalogVersion',
      if (intelligence.parserVersion.trim().isEmpty) 'parserVersion',
      if (intelligence.sourceConfidence.trim().isEmpty) 'sourceConfidence',
    ];
    if (missing.isEmpty) return;
    failures.add(
      _failure(
        item,
        id: 'missing_metadata_versioning:${item.id}',
        message: 'Item parser metadata is not safely versioned.',
        expected: 'catalogVersion, parserVersion, sourceConfidence',
        actual: 'missing=${missing.join(', ')}',
        fix:
            'Version every generated/manual item so bad data can be rolled forward or back by pack version.',
        category: QaFailureTriage.governance,
      ),
    );
  }

  QaFailure _failure(
    WorkSupplyItem item, {
    required String id,
    required String message,
    required String expected,
    required String actual,
    required String fix,
    String category = QaFailureTriage.parserEngine,
  }) {
    return QaFailure(
      suite: name,
      id: id,
      message: message,
      severity: QaSeverity.warning,
      expected: expected,
      actual: '${item.path} / ${item.name}; $actual',
      suggestedFix: fix,
      metadata: {'triageCategory': category},
    );
  }

  _ItemMetadataScore _scoreItem(WorkSupplyItem item) {
    final intelligence = item.intelligence;
    final missing = <String>[];
    var points = 0;
    void mark(bool condition, String label) {
      if (condition) {
        points++;
      } else {
        missing.add(label);
      }
    }

    mark(item.aliases.length >= 3, 'aliases>=3');
    mark(intelligence.receiptPatterns.length >= 2, 'receiptPatterns>=2');
    mark(intelligence.attributeTokens.length >= 3, 'attributeTokens>=3');
    mark(intelligence.negativeMatchTokens.isNotEmpty, 'negativeMatchTokens');
    mark(intelligence.highImportanceTokens.isNotEmpty, 'highImportanceTokens');
    mark(
      intelligence.mediumImportanceTokens.isNotEmpty ||
          intelligence.lowImportanceTokens.isNotEmpty,
      'confidenceWeightTokens',
    );
    mark(item.marketScopes.isNotEmpty, 'marketScopes');
    mark(item.packTier.name.isNotEmpty, 'packTier');
    mark(item.parserPriority.name.isNotEmpty, 'parserPriority');
    mark(_hasMerchantHint(item), 'merchantOrVendorHint');
    mark(intelligence.classification.inventoryCategory.isNotEmpty, 'classify');
    mark(intelligence.catalogVersion.isNotEmpty, 'versioning');
    final label = points >= 10
        ? 'strong'
        : points >= 7
        ? 'needs_enrichment'
        : 'thin';
    return _ItemMetadataScore(points, label, missing);
  }

  bool _hasMerchantHint(WorkSupplyItem item) {
    final intelligence = item.intelligence;
    if (intelligence.vendorMappings.isNotEmpty) return true;
    final haystack = [
      ...item.aliases,
      ...intelligence.receiptPatterns,
      ...intelligence.attributeTokens,
    ].join(' ').toLowerCase();
    return _majorMerchantHints.any(haystack.contains);
  }

  List<String> _riskTermsFor(WorkSupplyItem item) {
    final tokens = _normalizedTokens([
      item.name,
      item.category,
      item.system,
      item.itemType,
      item.variant,
      ...item.aliases,
      ...item.intelligence.receiptPatterns,
      ...item.intelligence.attributeTokens,
    ]);
    final risks = _highRiskFamilies.where(tokens.contains).toList();
    if (tokens.contains('pvc')) risks.add('pvc');
    return risks.toSet().toList(growable: false)..sort();
  }
}

class _ItemMetadataScore {
  const _ItemMetadataScore(this.points, this.label, this.missing);

  final int points;
  final String label;
  final List<String> missing;
}

List<WorkSupplyItem> _sampledItems(
  List<WorkSupplyItem> items, {
  required int limit,
}) {
  if (items.length <= limit) return items;
  final sampled = <WorkSupplyItem>[];
  final step = (items.length / limit).ceil();
  for (
    var index = 0;
    index < items.length && sampled.length < limit;
    index += step
  ) {
    sampled.add(items[index]);
  }
  return sampled;
}

Set<String> _normalizedTokens(Iterable<String> values) {
  return values
      .join(' ')
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9/.-]+'), ' ')
      .split(RegExp(r'\s+'))
      .where((token) => token.length >= 2)
      .toSet();
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
