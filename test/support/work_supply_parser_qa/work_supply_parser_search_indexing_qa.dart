import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserSearchIndexingSuite extends QaSuite {
  const WorkSupplyParserSearchIndexingSuite()
    : super('inventory.search_indexing_contract');

  static const _sourcePaths = {
    'test/support/work_supply_parser_qa/work_supply_parser_search_indexing_qa.dart',
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_scalability_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_runtime_profile_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_security_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_product_normalization_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_vendor_sku_matrix_qa.dart',
  };

  static const _indexSignals = {
    'search index',
    'token index',
    'alias index',
    'merchant index',
    'SKU index',
    'UPC index',
    'GTIN index',
    'trade index',
    'pack index',
    'locale index',
    'negative index',
    'conflict graph',
  };

  static const _searchSecurityCases = {
    'SQL injection',
    'NoSQL injection',
    'path traversal',
    'script tag',
    'command-looking text',
    'regex backtracking',
    'huge input',
    'repeated tokens',
    'control characters',
    'unicode override',
    'pasted JSON',
    'pasted CSV',
    'malicious SKU',
    'malicious barcode',
  };

  static const _indexRules = {
    'search_index_uses_normalized_tokens',
    'search_index_keeps_raw_evidence_out_of_logs',
    'search_index_is_bounded_for_huge_input',
    'search_index_is_locale_scoped',
    'search_index_is_pack_scoped',
    'search_index_is_trade_aware',
    'search_index_handles_alias_collisions',
    'search_index_handles_sku_collisions',
    'search_index_handles_negative_rules',
    'search_index_rebuilds_after_pack_update',
    'search_index_rolls_back_with_pack_rollback',
    'search_index_never_auto_saves_results',
  };

  static const _performanceSignals = {
    'cold start',
    'warm run',
    'indexing time',
    'memory growth',
    'slowest rule',
    'checks per second',
    'older phone',
    'modern flagship',
    'low storage',
    'pack size',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _indexSignals.length;
    _requireTokens(
      failures,
      source,
      _indexSignals,
      idPrefix: 'missing_index_signal',
      message: 'Search/indexing QA is missing an index dimension.',
      fix:
          'Search/index QA must cover token, alias, merchant, SKU, UPC, GTIN, trade, pack, locale, negative, and conflict indexes.',
      triage: QaFailureTriage.performance,
    );

    checked += _searchSecurityCases.length;
    _requireTokens(
      failures,
      source,
      _searchSecurityCases,
      idPrefix: 'missing_search_security_case',
      message: 'Search/indexing QA is missing hostile input coverage.',
      fix:
          'Search QA must fuzz injection-like strings, path/script/command text, regex traps, huge/repeated input, Unicode controls, pasted data, SKUs, and barcodes.',
      triage: QaFailureTriage.security,
    );

    checked += _indexRules.length;
    _requireRules(failures, source, _indexRules);

    checked += _performanceSignals.length;
    _requireTokens(
      failures,
      source,
      _performanceSignals,
      idPrefix: 'missing_index_performance_signal',
      message: 'Search/indexing QA is missing performance/device coverage.',
      fix:
          'Index QA must track cold/warm runs, indexing time, memory growth, slowest rules, checks/sec, older phones, flagship phones, storage, and pack size.',
      triage: QaFailureTriage.performance,
    );

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'contract':
            'Search/indexing must be tokenized, scoped, collision-safe, hostile-input safe, bounded, and review-only.',
      },
    );
  }

  void _requireRules(
    List<QaFailure> failures,
    String source,
    Set<String> rules,
  ) {
    final lower = source.toLowerCase();
    for (final rule in rules) {
      if (lower.contains(rule.toLowerCase())) continue;
      failures.add(
        _failure(
          id: 'missing_search_indexing_rule:${_safeId(rule)}',
          message: 'Search/indexing QA is missing a named rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Add explicit index safety, scoping, collision, rebuild, rollback, hostile-input, and review-only rules.',
          triage: QaFailureTriage.performance,
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
    final lower = source.toLowerCase();
    for (final token in tokens) {
      if (lower.contains(token.toLowerCase())) continue;
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
