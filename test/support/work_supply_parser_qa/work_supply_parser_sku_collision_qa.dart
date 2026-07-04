import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserSkuCollisionSuite extends QaSuite {
  const WorkSupplyParserSkuCollisionSuite()
    : super('inventory.sku_collision_contract');

  static const _sourcePaths = {
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_vendor_sku_matrix_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_conflict_graph_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_ranked_candidate_qa.dart',
    'test/work_supply_parser_sku_collision_behavior_test.dart',
  };

  static const _collisionAxes = {
    'same sku different merchant',
    'same part number different brand',
    'same upc different pack count',
    'same short name different trade',
    'same brand different material',
    'same size different connection type',
    'same alias different canonical item',
    'private label remap',
    'regional item number',
    'legacy sku',
  };

  static const _requiredOutcomes = {
    'ranked candidates',
    'needs review',
    'confidence reasons',
    'conflict rule',
    'negative match',
    'merchant evidence',
    'brand evidence',
    'size evidence',
    'pack count evidence',
    'not enough evidence',
  };

  static const _doNotAllow = {
    'sku only final answer',
    'part number only final answer',
    'brand only final answer',
    'merchant only final answer',
    'generic alias final answer',
    'cross-trade auto-save',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _collisionAxes.length;
    _requireTokens(
      failures,
      source,
      _collisionAxes,
      idPrefix: 'missing_collision_axis',
      message: 'SKU collision QA is missing a collision axis.',
      fix:
          'Add SKU/UPC/part-number collision fixtures across merchants, brands, pack counts, trades, sizes, aliases, and legacy/regional codes.',
      triage: QaFailureTriage.conflict,
    );

    checked += _requiredOutcomes.length;
    _requireTokens(
      failures,
      source,
      _requiredOutcomes,
      idPrefix: 'missing_collision_outcome',
      message: 'SKU collision QA is missing conservative parser outcomes.',
      fix:
          'Collisions must return ranked candidates with conflict evidence and review status instead of one confident answer.',
      triage: QaFailureTriage.reviewSafety,
    );

    checked += _doNotAllow.length;
    _requireForbiddenOutcomeText(failures, source);

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'contract':
            'SKU/UPC/part-number evidence is strong only when corroborated by merchant, brand, size, material, pack count, and trade context.',
      },
    );
  }

  void _requireForbiddenOutcomeText(
    List<QaFailure> failures,
    String source,
  ) {
    final lower = _normalizeContractText(source);
    for (final rule in _doNotAllow) {
      if (lower.contains(_normalizeContractText(rule))) continue;
      failures.add(
        _failure(
          id: 'missing_collision_forbidden_rule:${_safeId(rule)}',
          message: 'SKU collision QA is missing a forbidden shortcut rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Document and test that identifiers alone do not bypass ambiguity, review, or conflict handling.',
          triage: QaFailureTriage.security,
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
