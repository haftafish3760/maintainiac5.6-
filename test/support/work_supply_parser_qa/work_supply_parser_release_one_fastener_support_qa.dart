import 'dart:io';

import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserReleaseOneFastenerSupportSuite extends QaSuite {
  const WorkSupplyParserReleaseOneFastenerSupportSuite()
    : super('inventory.release_one_fastener_support_contract');

  static const _tradeFamilies = [
    _FastenerFamily(
      trade: 'Plumbing',
      id: 'plumbing_hangers_anchors_rod',
      tokens: [
        'pipe strap',
        'hanger',
        'threaded rod',
        'all thread',
        'tapcon',
        'concrete screw',
        'beam clamp',
      ],
      minimumMatches: 10,
    ),
    _FastenerFamily(
      trade: 'Electrical',
      id: 'electrical_conduit_straps_grounding',
      tokens: [
        'emt strap',
        'one hole strap',
        'two hole strap',
        'set screw',
        'ground clamp',
        'conduit locknut',
      ],
      minimumMatches: 8,
    ),
    _FastenerFamily(
      trade: 'HVAC',
      id: 'hvac_duct_fasteners_straps',
      tokens: [
        'sheet metal screw',
        'zip screw',
        'tek screw',
        'duct strap',
        'hanger strap',
        'drive cleat',
      ],
      minimumMatches: 8,
    ),
  ];

  static const _ambiguousFastenerTerms = {
    'screw',
    'strap',
    'hanger',
    'clamp',
    'threaded rod',
    'all thread',
    'tapcon',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final releaseItems = _releaseOneItems().toList(growable: false);
    final counts = <String, int>{};
    final examples = <String, List<String>>{};

    for (final family in _tradeFamilies) {
      final matches = releaseItems
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
        _failure(
          id: 'thin_fastener_support_family:${family.id}',
          message:
              'Release-one Core/Standard is thin for a trade fastener/support family.',
          expected:
              '${family.trade} >= ${family.minimumMatches} rows matching ${family.tokens.join(', ')}',
          actual: '${matches.length} matching rows',
          fix:
              'Add common service-truck fastener/support rows or aliases before claiming release-one readiness.',
        ),
      );
    }

    final docs = _readAmbiguityEvidence().toLowerCase();
    for (final term in _ambiguousFastenerTerms) {
      if (docs.contains(term)) continue;
      failures.add(
        _failure(
          id: 'missing_fastener_ambiguity_guard:${_safeId(term)}',
          message: 'Fastener/support QA is missing an ambiguity guard term.',
          expected: term,
          actual: 'not found in parser ambiguity/overlap sources',
          fix:
              'Shared fastener words must rank candidates and require review when trade context is weak.',
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked:
          releaseItems.length +
          _tradeFamilies.length +
          _ambiguousFastenerTerms.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'scope': 'US residential Plumbing/Electrical/HVAC Core and Standard',
        'familyCounts': counts,
        'familyExamples': examples,
        'ambiguousFastenerTerms': _ambiguousFastenerTerms.toList()..sort(),
      },
    );
  }

  Iterable<WorkSupplyItem> _releaseOneItems() sync* {
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

  String _readAmbiguityEvidence() {
    return [
      'inventory.release_one_fastener_support_contract',
      for (final path in const [
        'docs/inventory_parser_qa_progress_memory.md',
        'docs/materials_catalog_intelligence_contract.md',
        'test/support/work_supply_parser_qa/work_supply_parser_pack_overlap_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_conflict_graph_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_context_qa.dart',
      ])
        _readIfExists(path),
    ].join('\n');
  }

  String _readIfExists(String path) {
    final file = File(path);
    return file.existsSync() ? file.readAsStringSync() : path;
  }

  QaFailure _failure({
    required String id,
    required String message,
    required String expected,
    required String actual,
    required String fix,
  }) {
    return QaFailure(
      suite: name,
      id: id,
      message: message,
      severity: QaSeverity.warning,
      expected: expected,
      actual: actual,
      suggestedFix: fix,
      metadata: const {'triageCategory': QaFailureTriage.category},
    );
  }
}

class _FastenerFamily {
  const _FastenerFamily({
    required this.trade,
    required this.id,
    required this.tokens,
    required this.minimumMatches,
  });

  final String trade;
  final String id;
  final List<String> tokens;
  final int minimumMatches;

  bool matches(String haystack) {
    return tokens.any((token) => haystack.contains(token.toLowerCase()));
  }
}

String _safeId(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}
