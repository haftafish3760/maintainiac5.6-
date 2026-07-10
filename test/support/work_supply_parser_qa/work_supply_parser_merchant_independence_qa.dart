import 'dart:convert';
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
  static const _goldenFixturePath =
      'test/fixtures/work_supply_parser/golden_fixtures.json';

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

  static const _requiredFixtureMerchants = {
    'Local Hardware',
    'Regional Supplier',
    'Counter Sale',
    'unknown',
  };

  static const _requiredFixtureTags = {
    'local_hardware',
    'regional_supplier',
    'counter_sale',
    'merchant_independence',
    'bad_spacing',
    'generic_unknown_merchant',
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

    final fixtures = _loadGoldenFixtures(failures);
    final merchantCounts = _fixtureMerchantCounts(fixtures);
    final fixtureTags = _fixtureTags(fixtures);

    checked += _requiredFixtureMerchants.length;
    for (final merchant in _requiredFixtureMerchants) {
      if ((merchantCounts[merchant] ?? 0) > 0) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_merchant_independence_fixture:${_safeId(merchant)}',
          message:
              'Golden fixtures are missing a merchant-independent receipt family.',
          expected: merchant,
          actual: merchantCounts.keys.join(', '),
          suggestedFix:
              'Add synthetic local/regional/counter-sale/unknown receipt fixtures that stay review-safe without a known major merchant.',
          metadata: const {'triageCategory': QaFailureTriage.fixture},
        ),
      );
    }

    checked += _requiredFixtureTags.length;
    for (final tag in _requiredFixtureTags) {
      if (fixtureTags.contains(tag)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_merchant_independence_tag:${_safeId(tag)}',
          message:
              'Golden fixtures are missing a merchant-independence risk tag.',
          expected: tag,
          actual: fixtureTags.join(', '),
          suggestedFix:
              'Tag merchant-independent fixtures so reports can prove local, regional, counter-sale, generic, and bad-spacing coverage.',
          metadata: const {'triageCategory': QaFailureTriage.fixture},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: checked + _sourcePaths.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'fixtureMerchants': merchantCounts,
        'fixtureTags': fixtureTags,
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

  List<_MerchantIndependenceFixture> _loadGoldenFixtures(
    List<QaFailure> failures,
  ) {
    final file = File(_goldenFixturePath);
    if (!file.existsSync()) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_merchant_independence_fixture_corpus',
          message: 'Golden fixture corpus is missing.',
          expected: _goldenFixturePath,
          actual: 'not found',
          suggestedFix:
              'Restore golden fixtures before claiming merchant-independent receipt coverage.',
          metadata: const {'triageCategory': QaFailureTriage.fixture},
        ),
      );
      return const [];
    }
    final decoded = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    return [
      for (final entry in decoded)
        _MerchantIndependenceFixture.fromJson(
          (entry as Map).cast<String, Object?>(),
        ),
    ];
  }
}

class _MerchantIndependenceFixture {
  const _MerchantIndependenceFixture({
    required this.merchant,
    required this.trade,
    required this.marketScope,
    required this.tier,
    required this.riskTags,
  });

  final String merchant;
  final String trade;
  final String marketScope;
  final String tier;
  final List<String> riskTags;

  bool get isPriorityReleaseOne {
    return const {'plumbing', 'electrical', 'hvac'}.contains(trade) &&
        const {'core', 'standard'}.contains(tier) &&
        marketScope == 'residential';
  }

  static _MerchantIndependenceFixture fromJson(Map<String, Object?> json) {
    return _MerchantIndependenceFixture(
      merchant: json['merchant'] as String? ?? 'unknown',
      trade: (json['trade'] as String? ?? '').toLowerCase(),
      marketScope: (json['marketScope'] as String? ?? '').toLowerCase(),
      tier: (json['tier'] as String? ?? '').toLowerCase(),
      riskTags: [
        for (final tag in json['riskTags'] as List<dynamic>? ?? const [])
          tag.toString(),
      ],
    );
  }
}

Map<String, int> _fixtureMerchantCounts(
  List<_MerchantIndependenceFixture> fixtures,
) {
  final counts = <String, int>{};
  for (final fixture in fixtures.where(
    (fixture) => fixture.isPriorityReleaseOne,
  )) {
    counts.update(fixture.merchant, (count) => count + 1, ifAbsent: () => 1);
  }
  return counts;
}

List<String> _fixtureTags(List<_MerchantIndependenceFixture> fixtures) {
  final tags = <String>{};
  for (final fixture in fixtures.where(
    (fixture) => fixture.isPriorityReleaseOne,
  )) {
    tags.addAll(fixture.riskTags);
  }
  return tags.toList()..sort();
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
