import 'dart:io';

import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserPackOverlapSuite extends QaSuite {
  const WorkSupplyParserPackOverlapSuite()
    : super('inventory.pack_overlap_contract');

  static const _sourcePaths = {
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_pack_scope_gate_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_category_reuse_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_conflict_graph_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_context_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_service_truck_core_qa.dart',
  };

  static const _scopeTokens = {
    'residential',
    'light industrial',
    'commercial',
    'core',
    'standard',
    'professional',
    'complete',
    'downloadable pack',
    'pack size',
    'megabytes',
  };

  static const _overlapRules = {
    'same_item_can_belong_to_multiple_pack_scopes',
    'canonical_identity_is_not_duplicated',
    'pack_membership_is_separate_from_item_identity',
    'residential_core_is_service_truck_first',
    'standard_extends_core',
    'professional_extends_standard',
    'complete_extends_professional',
    'commercial_only_does_not_pollute_residential_core',
    'light_industrial_overlap_is_explicit',
    'fasteners_can_cross_trade_with_context',
  };

  static const _crossTradeExamples = {
    'PVC',
    'conduit',
    'condensate',
    'threaded rod',
    'all thread',
    'tapcon',
    'sheet metal screw',
    'foil tape',
    'filter',
    'box',
    'coupling',
    'elbow',
  };

  static const _packSafetyTokens = {
    'active plumbing estimate section',
    'active electrical estimate section',
    'active HVAC estimate section',
    'selected job type',
    'enabled trade packs',
    'vehicle inventory',
    'previous corrections',
    'context boost',
    'does not erase ambiguity',
    'requires review',
  };

  static const _priorityTrades = {'Plumbing', 'Electrical', 'HVAC'};

  static const _crossTradeEvidenceTerms = {
    'PVC': 'pvc',
    'conduit': 'conduit',
    'condensate': 'condensate',
    'threaded rod': 'threaded rod',
    'all thread': 'all thread',
    'tapcon': 'tapcon',
    'sheet metal screw': 'sheet metal screw',
    'foil tape': 'foil tape',
    'filter': 'filter',
    'box': 'box',
    'coupling': 'coupling',
    'elbow': 'elbow',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    final overlapCounts = <String, int>{};
    final ambiguityCounts = <String, int>{};
    var checked = 0;

    checked += _scopeTokens.length;
    _requireTokens(
      failures,
      source,
      _scopeTokens,
      idPrefix: 'missing_scope_token',
      message: 'Pack overlap QA is missing scope/tier vocabulary.',
      fix:
          'Pack QA must model residential, light-industrial, commercial, and all four downloadable tiers.',
      triage: QaFailureTriage.governance,
    );

    checked += _overlapRules.length;
    _requireRules(failures, source, _overlapRules);

    checked += _crossTradeExamples.length;
    _requireTokens(
      failures,
      source,
      _crossTradeExamples,
      idPrefix: 'missing_cross_trade_example',
      message: 'Pack overlap QA is missing cross-trade ambiguity examples.',
      fix:
          'Add overlap fixtures for PVC, conduit, condensate, fasteners, filters, boxes, couplings, elbows, and tape.',
      triage: QaFailureTriage.conflict,
    );

    checked += _packSafetyTokens.length;
    _requireTokens(
      failures,
      source,
      _packSafetyTokens,
      idPrefix: 'missing_context_safety',
      message: 'Pack overlap QA is missing context safety coverage.',
      fix:
          'Context may boost ranking, but it must not hide realistic meanings or auto-save a candidate.',
      triage: QaFailureTriage.reviewSafety,
    );

    checked += 4;
    _requireLayering(source, failures);

    final executable = _checkExecutablePackOverlap(
      failures,
      overlapCounts,
      ambiguityCounts,
    );
    checked += executable;

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'multiScopePriorityCounts': overlapCounts,
        'crossTradeEvidenceCounts': ambiguityCounts,
        'contract':
            'Pack membership is a versioned routing layer over canonical items, not duplicated data or a reason to force certainty.',
      },
    );
  }

  int _checkExecutablePackOverlap(
    List<QaFailure> failures,
    Map<String, int> overlapCounts,
    Map<String, int> ambiguityCounts,
  ) {
    var checked = 0;
    for (final item in workSupplyCatalogItems) {
      if (!_priorityTrades.contains(item.trade)) continue;
      if (item.packTier != WorkSupplyPackTier.core &&
          item.packTier != WorkSupplyPackTier.standard) {
        continue;
      }
      checked++;
      if (item.marketScopes.length > 1) {
        overlapCounts.update(
          item.trade,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
      final haystack = [
        item.name,
        item.category,
        item.system,
        item.itemType,
        item.variant,
        ...item.aliases,
        ...item.intelligence.negativeMatchTokens,
        ...item.intelligence.highImportanceTokens,
      ].join(' ').toLowerCase();
      for (final entry in _crossTradeEvidenceTerms.entries) {
        if (!haystack.contains(entry.value)) continue;
        ambiguityCounts.update(
          entry.key,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
    }

    for (final trade in _priorityTrades) {
      if ((overlapCounts[trade] ?? 0) >= 10) continue;
      failures.add(
        _failure(
          id: 'thin_executable_scope_overlap:${_safeId(trade)}',
          message:
              'Priority release-one trade has too little executable multi-scope overlap evidence.',
          expected:
              '$trade Core/Standard has at least 10 rows that can belong to more than one market scope',
          actual: '${overlapCounts[trade] ?? 0} rows',
          fix:
              'Add explicit market-scope membership for service-truck rows that legitimately appear in residential plus light-industrial/commercial work.',
          triage: QaFailureTriage.governance,
        ),
      );
    }

    for (final term in _crossTradeEvidenceTerms.keys) {
      if ((ambiguityCounts[term] ?? 0) > 0) continue;
      failures.add(
        _failure(
          id: 'missing_executable_cross_trade_term:${_safeId(term)}',
          message:
              'Cross-trade ambiguity term is documented but not visible in executable catalog evidence.',
          expected: term,
          actual: '0 matching priority Core/Standard rows',
          fix:
              'Add catalog aliases, negative-match tokens, or item rows that keep this overlap visible to parser QA.',
          triage: QaFailureTriage.conflict,
        ),
      );
    }
    return checked + _priorityTrades.length + _crossTradeEvidenceTerms.length;
  }

  void _requireRules(
    List<QaFailure> failures,
    String source,
    Set<String> rules,
  ) {
    final lower = _normalizeContractText(source);
    for (final rule in rules) {
      if (lower.contains(_normalizeContractText(rule))) continue;
      failures.add(
        _failure(
          id: 'missing_overlap_rule:${_safeId(rule)}',
          message: 'Pack overlap QA is missing a named pack-routing rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Add explicit pack-overlap rules before growing residential, light-industrial, or commercial catalogs.',
          triage: QaFailureTriage.governance,
        ),
      );
    }
  }

  void _requireLayering(String source, List<QaFailure> failures) {
    const layeredTokens = {'canonical', 'membership', 'trade', 'tier'};
    final lower = _normalizeContractText(source);
    for (final token in layeredTokens) {
      if (lower.contains(token)) continue;
      failures.add(
        _failure(
          id: 'missing_pack_layer:${_safeId(token)}',
          message: 'Pack overlap QA does not prove layered pack design.',
          expected: token,
          actual: 'not found',
          fix:
              'Keep canonical item identity separate from pack membership, trade routing, and tier download shape.',
          triage: QaFailureTriage.schema,
        ),
      );
    }
  }

  void _requireTokens(
    List<QaFailure> failures,
    String source,
    Set<String> tokens, {
    required String idPrefix,
    required String message,
    required String fix,
    required String triage,
  }) {
    final lower = _normalizeContractText(source);
    for (final token in tokens) {
      if (lower.contains(_normalizeContractText(token))) continue;
      failures.add(
        _failure(
          id: '$idPrefix:${_safeId(token)}',
          message: message,
          expected: token,
          actual: 'not found',
          fix: fix,
          triage: triage,
        ),
      );
    }
  }

  String _readSources() {
    final buffer = StringBuffer();
    for (final path in _sourcePaths) {
      final file = File(path);
      if (!file.existsSync()) continue;
      buffer.writeln(file.readAsStringSync());
    }
    return buffer.toString();
  }

  QaFailure _failure({
    required String id,
    required String message,
    required String expected,
    required String actual,
    required String fix,
    required String triage,
  }) {
    return QaFailure(
      suite: name,
      id: id,
      message: message,
      severity: QaSeverity.warning,
      expected: expected,
      actual: actual,
      suggestedFix: fix,
      metadata: {'triageCategory': triage},
    );
  }
}

String _safeId(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}

String _normalizeContractText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
