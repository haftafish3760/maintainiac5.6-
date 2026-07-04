import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserMerchantIndependenceSuite extends QaSuite {
  const WorkSupplyParserMerchantIndependenceSuite()
    : super('inventory.merchant_independence_contract');

  static const _sourcePaths = {
    'docs/inventory_parser_release1_acceptance_scorecard.md',
    'docs/inventory_parser_qa_harness_plan.md',
    'docs/materials_catalog_intelligence_contract.md',
    'tool/work_supply_parser_qa_fixture_recipes.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_merchant_matrix_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_vendor_sku_matrix_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_real_receipt_validation_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_standard_fixture_seed_qa.dart',
  };

  static const _merchantFamilies = {
    'Home Depot',
    'Lowe',
    'Ace',
    'True Value',
    'Menards',
    'Walmart',
    'Ferguson',
    'Grainger',
    'SupplyHouse',
    'HVAC supply house',
    'Electrical supply house',
    'Plumbing supply house',
    'local hardware',
    'regional',
    'small counter-sale',
    'unknown merchant',
    'generic unknown merchant',
  };

  static const _storeIndependenceRules = {
    'merchant_specific_rules_boost_but_do_not_force_truth',
    'unknown_merchant_uses_generic_parser_pipeline',
    'misspelled_merchant_keeps_review_safe_fallback',
    'local_hardware_receipts_require_generic_coverage',
    'regional_supplier_receipts_require_generic_coverage',
    'counter_sale_receipts_require_generic_coverage',
    'merchant_absent_receipts_do_not_fail_parser',
    'named_store_fixtures_are_not_the_only_release_gate',
    'store_independence_proof_required',
    'receipt_wording_not_store_name_is_primary_evidence',
    'merchant_department_hint_is_supporting_evidence',
    'merchant_pack_missing_does_not_block_review_candidate',
  };

  static const _receiptStyles = {
    'all-caps receipt text',
    'store-counter shorthand',
    'abbreviations',
    'bad spacing',
    'PDF/email receipt text',
    'Spanish receipt wording',
    'nearby receipt words',
    'receipt short name',
    'department hints',
    'merchant type',
  };

  static const _safetyTokens = {
    'do not copy proprietary',
    'scrape retailer databases',
    'private receipt text',
    'review required',
    'matched',
    'unknown',
    'ambiguous',
    'false-confident',
    'no auto-save',
    'user approval',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources(failures);
    var checked = 0;

    checked += _merchantFamilies.length;
    _requireTokens(
      failures,
      source,
      _merchantFamilies,
      idPrefix: 'missing_merchant_family',
      message: 'Merchant-independence QA is missing a merchant family.',
      fix:
          'Release-one fixtures must cover named stores, regional/local stores, supply houses, counter-sale receipts, and generic unknown merchants.',
      triage: QaFailureTriage.fixture,
    );

    checked += _storeIndependenceRules.length;
    _requireTokens(
      failures,
      source,
      _storeIndependenceRules,
      idPrefix: 'missing_store_independence_rule',
      message: 'Merchant-independence QA is missing a named safety rule.',
      fix:
          'Add store-independence rules so merchant recognition improves ranking without making the parser dependent on one retailer.',
      triage: QaFailureTriage.merchantRule,
      normalizeUnderscores: true,
    );

    checked += _receiptStyles.length;
    _requireTokens(
      failures,
      source,
      _receiptStyles,
      idPrefix: 'missing_receipt_style',
      message: 'Merchant-independence QA is missing a receipt style.',
      fix:
          'Synthetic receipt fixtures must cover text styles from big-box, supply-house, counter-sale, PDF/email, Spanish, and unknown merchant inputs.',
      triage: QaFailureTriage.fixture,
    );

    checked += _safetyTokens.length;
    _requireTokens(
      failures,
      source,
      _safetyTokens,
      idPrefix: 'missing_merchant_safety_token',
      message: 'Merchant-independence QA is missing a safety token.',
      fix:
          'Merchant fallback must stay review-only, privacy-safe, legal, and resistant to false-confident auto-save behavior.',
      triage: QaFailureTriage.reviewSafety,
    );

    return timer.finish(
      suite: name,
      checked: checked + _sourcePaths.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'contract':
            'Inventory parser release readiness must prove store-independent receipt understanding, not only named big-box merchant tuning.',
      },
    );
  }

  void _requireTokens(
    List<QaFailure> failures,
    String source,
    Set<String> tokens, {
    required String idPrefix,
    required String message,
    required String fix,
    required String triage,
    bool normalizeUnderscores = false,
  }) {
    final haystack = _normal(source);
    for (final token in tokens) {
      final needle = normalizeUnderscores
          ? _normal(token.replaceAll('_', ' '))
          : _normal(token);
      if (haystack.contains(needle)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: '$idPrefix:${_safeId(token)}',
          message: message,
          expected: token,
          actual: 'not found',
          suggestedFix: fix,
          metadata: {'triageCategory': triage},
        ),
      );
    }
  }

  String _readSources(List<QaFailure> failures) {
    final buffer = StringBuffer();
    for (final path in _sourcePaths) {
      final file = File(path);
      if (!file.existsSync()) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'missing_merchant_independence_source:$path',
            message: 'Merchant-independence source file is missing.',
            expected: path,
            actual: 'not found',
            suggestedFix:
                'Update this suite if merchant fixture docs or QA contracts move.',
            metadata: const {'triageCategory': QaFailureTriage.schema},
          ),
        );
        continue;
      }
      buffer.writeln(file.readAsStringSync());
    }
    return buffer.toString();
  }
}

String _normal(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _safeId(String value) {
  return _normal(value).replaceAll(' ', '_');
}
