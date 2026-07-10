import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserMerchantAliasNormalizationSuite extends QaSuite {
  const WorkSupplyParserMerchantAliasNormalizationSuite()
    : super('inventory.merchant_alias_normalization_contract');

  static const _sourcePaths = {
    'test/support/work_supply_parser_qa/work_supply_parser_merchant_alias_normalization_qa.dart',
    'docs/inventory_parser_qa_master_coverage_matrix.md',
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_merchant_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_merchant_matrix_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_vendor_sku_matrix_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_product_normalization_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_sku_collision_qa.dart',
  };

  static const _merchantAliasInputs = {
    'Home Depot',
    'Lowe',
    'Ace',
    'Ferguson',
    'Grainger',
    'Menards',
    'Walmart',
    'True Value',
    'SupplyHouse',
    'local hardware store',
    'unknown merchant',
  };

  static const _aliasEvidenceTypes = {
    'store-specific short name',
    'merchant abbreviation',
    'receipt abbreviation',
    'private-label name',
    'manufacturer part number',
    'store item number',
    'SKU',
    'UPC',
    'GTIN',
    'brand',
    'department code',
    'aisle/bin text',
  };

  static const _aliasRules = {
    'merchant_alias_normalization_preserves_raw_receipt_text',
    'merchant_alias_normalization_is_merchant_scoped',
    'merchant_alias_normalization_is_locale_scoped',
    'merchant_alias_normalization_does_not_cross_pollinate_merchants',
    'merchant_alias_normalization_does_not_force_confidence',
    'merchant_alias_collision_requires_review',
    'private_label_alias_maps_to_canonical_item_with_evidence',
    'store_short_name_maps_to_candidate_evidence',
    'department_code_boosts_but_does_not_finalize',
    'missing_merchant_keeps_generic_rules_conservative',
    'unknown_merchant_alias_does_not_create_official_rule',
    'new_merchant_alias_requires_regression_fixture',
  };

  static const _collisionCases = {
    'same alias different merchant',
    'same SKU different merchant',
    'same short name different trade',
    'same brand different material',
    'same department code different category',
    'same private label different pack count',
    'same manufacturer part number different size',
    'generic alias without size',
    'generic alias without material',
    'generic alias without connection type',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _merchantAliasInputs.length;
    _requireTokens(
      failures,
      source,
      _merchantAliasInputs,
      idPrefix: 'missing_merchant_alias_input',
      message: 'Merchant alias normalization QA is missing a merchant input.',
      fix:
          'Merchant alias QA must cover major big-box, supply-house, local, and unknown merchant contexts.',
      triage: QaFailureTriage.merchantRule,
    );

    checked += _aliasEvidenceTypes.length;
    _requireTokens(
      failures,
      source,
      _aliasEvidenceTypes,
      idPrefix: 'missing_alias_evidence_type',
      message: 'Merchant alias normalization QA is missing an evidence type.',
      fix:
          'Merchant alias QA must include short names, abbreviations, private labels, part numbers, SKUs, UPC/GTIN, brand, department, and aisle/bin text.',
      triage: QaFailureTriage.alias,
    );

    checked += _aliasRules.length;
    _requireRules(failures, source, _aliasRules);

    checked += _collisionCases.length;
    _requireTokens(
      failures,
      source,
      _collisionCases,
      idPrefix: 'missing_merchant_alias_collision',
      message: 'Merchant alias normalization QA is missing a collision case.',
      fix:
          'Merchant alias QA must prove collisions stay review-only across merchants, trades, materials, sizes, brands, departments, and pack counts.',
      triage: QaFailureTriage.conflict,
    );

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'contract':
            'Merchant aliases are scoped evidence, not global truth; collisions require ranked review candidates and regression fixtures.',
      },
    );
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
          id: 'missing_merchant_alias_rule:${_safeId(rule)}',
          message: 'Merchant alias normalization QA is missing a named rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Add explicit scoped merchant alias rules before aliases can influence parser ranking.',
          triage: QaFailureTriage.merchantRule,
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
