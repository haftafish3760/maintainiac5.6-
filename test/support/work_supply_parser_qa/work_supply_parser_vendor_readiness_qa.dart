import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserVendorReadinessSuite extends QaSuite {
  const WorkSupplyParserVendorReadinessSuite()
    : super('inventory.vendor_readiness');

  static const _priorityTrades = {'Plumbing', 'Electrical', 'HVAC'};
  static const _majorMerchantTokens = {
    'ace',
    'ferguson',
    'grainger',
    'home depot',
    'lowe',
    'menards',
    'supplyhouse',
    'tractor supply',
    'true value',
    'walmart',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final checkedByTradeTier = <String, int>{};
    final warningByTradeTier = <String, int>{};
    final missingSignalCounts = <String, int>{};
    var checkedContracts = 0;

    for (final item in _releaseOneItems()) {
      checkedContracts += 7;
      final key = '${item.trade}.${item.packTier.name}';
      _increment(checkedByTradeTier, key);
      final missing = _missingVendorSignals(item);
      for (final signal in missing) {
        _increment(missingSignalCounts, signal);
      }
      if (missing.isEmpty) continue;
      _increment(warningByTradeTier, key);
      failures.add(
        QaFailure(
          suite: name,
          id: 'vendor_readiness_gap:${item.id}',
          message:
              'Priority residential item needs stronger merchant/vendor parsing evidence.',
          severity: QaSeverity.warning,
          expected:
              'vendor mappings, merchant-style receipt patterns, brand/store hints, and review-safe fallback signals',
          actual: '${item.path} / ${item.name}; missing=${missing.join(', ')}',
          suggestedFix:
              'Add non-proprietary vendor mappings or merchant-style abbreviations, brand/private-label aliases where known, SKU/part-number pattern slots, and fallback review signals.',
          metadata: const {'triageCategory': QaFailureTriage.parserEngine},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: checkedContracts,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'releaseOneItemCount': checkedByTradeTier.values.fold<int>(
          0,
          (sum, count) => sum + count,
        ),
        'checkedByTradeTier': _topCounts(checkedByTradeTier, limit: 20),
        'warningsByTradeTier': _topCounts(warningByTradeTier, limit: 20),
        'topMissingVendorSignals': _topCounts(missingSignalCounts),
        'merchantTokensTracked': _majorMerchantTokens.toList()..sort(),
        'scope':
            'Residential Plumbing, Electrical, and HVAC catalog rows only; no live retailer scraping and no proprietary catalog copying.',
      },
    );
  }

  Iterable<WorkSupplyItem> _releaseOneItems() sync* {
    for (final item in workSupplyCatalogItems) {
      if (!_priorityTrades.contains(item.trade)) continue;
      if (!item.marketScopes.contains(WorkSupplyMarketScope.residential)) {
        continue;
      }
      yield item;
    }
  }

  List<String> _missingVendorSignals(WorkSupplyItem item) {
    final intelligence = item.intelligence;
    final haystack = [
      item.name,
      ...item.aliases,
      ...intelligence.receiptPatterns,
      ...intelligence.attributeTokens,
      for (final mapping in intelligence.vendorMappings) ...[
        mapping.vendor,
        mapping.code,
        mapping.label,
      ],
    ].join(' ').toLowerCase();
    final missing = <String>[];
    if (intelligence.vendorMappings.isEmpty) missing.add('vendorMappings');
    if (intelligence.receiptPatterns.length < 2) {
      missing.add('receiptPatterns>=2');
    }
    if (!_majorMerchantTokens.any(haystack.contains)) {
      missing.add('majorMerchantHint');
    }
    if (!_hasPartNumberShape(intelligence.vendorMappings, haystack)) {
      missing.add('skuOrPartPatternSlot');
    }
    if (item.aliases.length < 3) missing.add('aliases>=3');
    if (intelligence.negativeMatchTokens.isEmpty) {
      missing.add('negativeMatchTokens');
    }
    if (intelligence.highImportanceTokens.isEmpty) {
      missing.add('highImportanceTokens');
    }
    return missing;
  }

  bool _hasPartNumberShape(
    List<WorkSupplyVendorMapping> mappings,
    String haystack,
  ) {
    if (mappings.any((mapping) => mapping.code.trim().length >= 4)) {
      return true;
    }
    return RegExp(r'\b[a-z]{1,5}[- ]?\d{3,}\b').hasMatch(haystack) ||
        RegExp(r'\b\d{4,}[a-z]{0,4}\b').hasMatch(haystack);
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
