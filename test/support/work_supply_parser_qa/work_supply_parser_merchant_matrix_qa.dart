import 'dart:convert';
import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserMerchantMatrixSuite extends QaSuite {
  const WorkSupplyParserMerchantMatrixSuite()
    : super('inventory.merchant_matrix_contract');

  static const _progressPath = 'docs/inventory_parser_qa_progress_memory.md';
  static const _fixtureCoveragePath =
      'test/support/work_supply_parser_qa/work_supply_parser_fixture_coverage_qa.dart';
  static const _merchantPath =
      'test/support/work_supply_parser_qa/work_supply_parser_merchant_qa.dart';
  static const _vendorPath =
      'test/support/work_supply_parser_qa/work_supply_parser_vendor_readiness_qa.dart';
  static const _generatedFixturePath =
      'test/support/work_supply_parser_qa/work_supply_parser_generated_fixture_cell_qa.dart';
  static const _catalogContractPath =
      'docs/materials_catalog_intelligence_contract.md';
  static const _behaviorPath =
      'test/work_supply_parser_merchant_matrix_behavior_test.dart';
  static const _goldenFixturePath =
      'test/fixtures/work_supply_parser/golden_fixtures.json';

  static const _requiredMerchants = {
    'Home Depot',
    'Lowes',
    'Ace',
    'Ferguson',
    'Grainger',
    'Menards',
    'True Value',
    'Walmart',
    'Tractor Supply',
    'Northern Tool',
    'Local Hardware',
    'Regional Supplier',
    'Electrical Supply',
    'HVAC Supply',
    'Supply House',
    'unknown',
  };

  static const _merchantStyleTokens = {
    'merchant_abbreviation',
    'home_depot_style',
    'lowes_style',
    'ace_style',
    'supply_house',
    'store-specific short name',
    'major merchant alias normalization',
    'merchant context',
  };

  static const _tradeTokens = {'plumbing', 'electrical', 'hvac'};

  static const _localeTokens = {'en-US', 'es-US', 'spanish', 'locale_pack'};

  static const _receiptBehaviorTokens = {
    'compressed sizes',
    'missing punctuation',
    'missing spaces',
    'all-caps receipt text',
    'store-counter shorthand',
    'abbreviations',
    'SKU/part-number pattern slots',
    'vendor mappings',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final progress = _read(_progressPath);
    final fixtures = _loadFixtures();
    final fixtureMerchants = _priorityFixtureMerchantCounts(fixtures);
    final sources = [
      progress,
      _read(_fixtureCoveragePath),
      _read(_merchantPath),
      _read(_vendorPath),
      _read(_generatedFixturePath),
      _read(_catalogContractPath),
      _read(_behaviorPath),
    ].join('\n');
    var checked = 0;

    checked += _requiredMerchants.length;
    for (final merchant in _requiredMerchants) {
      if (sources.contains(merchant)) continue;
      failures.add(
        _failure(
          id: 'missing_merchant_matrix_coverage:${_safeId(merchant)}',
          message: 'Merchant matrix is missing required merchant coverage.',
          expected: merchant,
          actual: 'not found in merchant/vendor/fixture/progress sources',
          fix:
              'Add non-proprietary synthetic receipt coverage for this merchant style across priority residential trades.',
          category: QaFailureTriage.merchantRule,
        ),
      );
    }

    checked += _merchantStyleTokens.length;
    for (final token in _merchantStyleTokens) {
      if (sources.toLowerCase().contains(token.toLowerCase())) continue;
      failures.add(
        _failure(
          id: 'missing_merchant_style_token:${_safeId(token)}',
          message: 'Merchant matrix is missing a receipt-style behavior token.',
          expected: token,
          actual: 'not found in merchant/vendor/fixture/progress sources',
          fix:
              'Merchant QA must cover abbreviation styles, supply-house wording, and store-specific short names.',
          category: QaFailureTriage.merchantRule,
        ),
      );
    }

    checked += _tradeTokens.length;
    for (final trade in _tradeTokens) {
      if (sources.contains(trade)) continue;
      failures.add(
        _failure(
          id: 'missing_merchant_trade_axis:$trade',
          message: 'Merchant matrix is missing a priority trade axis.',
          expected: trade,
          actual: 'not found',
          fix:
              'Merchant receipt coverage must be traceable across plumbing, electrical, and HVAC.',
          category: QaFailureTriage.category,
        ),
      );
    }

    checked += _localeTokens.length;
    for (final locale in _localeTokens) {
      if (sources.contains(locale)) continue;
      failures.add(
        _failure(
          id: 'missing_merchant_locale_axis:${_safeId(locale)}',
          message: 'Merchant matrix is missing a required locale axis.',
          expected: locale,
          actual: 'not found',
          fix:
              'Merchant receipt coverage must preserve English and US Spanish pack separation.',
          category: QaFailureTriage.locale,
        ),
      );
    }

    checked += _receiptBehaviorTokens.length;
    for (final token in _receiptBehaviorTokens) {
      if (sources.toLowerCase().contains(token.toLowerCase())) continue;
      failures.add(
        _failure(
          id: 'missing_merchant_receipt_behavior:${_safeId(token)}',
          message:
              'Merchant matrix is missing real-world receipt behavior coverage.',
          expected: token,
          actual: 'not found',
          fix:
              'Merchant QA must cover messy receipt wording, not just clean canonical item names.',
          category: QaFailureTriage.fixture,
        ),
      );
    }

    checked += 5;
    _checkProgressMemory(progress, failures);

    checked += _requiredMerchants.length + fixtures.length;
    _checkPriorityFixtureMerchants(fixtureMerchants, failures);

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'progressPath': _progressPath,
        'merchantCount': _requiredMerchants.length,
        'priorityFixtureMerchantCounts': fixtureMerchants,
        'contract':
            'Inventory parser merchant QA must prove major big-box, hardware, supply-house, unknown merchant, English, Spanish, and priority-trade receipt wording coverage before release accuracy claims.',
      },
    );
  }

  void _checkPriorityFixtureMerchants(
    Map<String, int> fixtureMerchants,
    List<QaFailure> failures,
  ) {
    for (final merchant in _requiredMerchants) {
      if ((fixtureMerchants[merchant] ?? 0) > 0) continue;
      failures.add(
        _failure(
          id: 'missing_priority_fixture_merchant:${_safeId(merchant)}',
          message:
              'Priority Core/Standard fixture corpus is missing a required merchant.',
          expected: merchant,
          actual: fixtureMerchants.keys.join(', '),
          fix:
              'Add a synthetic, non-proprietary priority fixture for this merchant before claiming release-one merchant readiness.',
          category: QaFailureTriage.fixture,
        ),
      );
    }
  }

  void _checkProgressMemory(String progress, List<QaFailure> failures) {
    const requiredTokens = {
      'inventory.merchant_matrix_contract',
      'focusedRerun',
      'doNotRerunUnless',
      'coveredInputs',
      'focused-validated',
    };
    for (final token in requiredTokens) {
      if (progress.contains(token)) continue;
      failures.add(
        _failure(
          id: 'missing_merchant_matrix_memory:${_safeId(token)}',
          message: 'Progress memory is missing merchant matrix batch tracking.',
          expected: token,
          actual: 'not found in $_progressPath',
          fix:
              'Track this merchant QA batch so it is not forgotten or rerun unnecessarily.',
          category: QaFailureTriage.governance,
        ),
      );
    }
  }

  QaFailure _failure({
    required String id,
    required String message,
    required String expected,
    required String actual,
    required String fix,
    required String category,
  }) {
    return QaFailure(
      suite: name,
      id: id,
      message: message,
      severity: QaSeverity.warning,
      expected: expected,
      actual: actual,
      suggestedFix: fix,
      metadata: {'triageCategory': category},
    );
  }
}

Map<String, int> _priorityFixtureMerchantCounts(
  List<_MerchantFixture> fixtures,
) {
  final counts = <String, int>{};
  for (final fixture in fixtures) {
    if (!const {'plumbing', 'electrical', 'hvac'}.contains(fixture.trade)) {
      continue;
    }
    if (!const {'core', 'standard'}.contains(fixture.tier)) continue;
    if (fixture.marketScope != 'residential') continue;
    counts.update(fixture.merchant, (count) => count + 1, ifAbsent: () => 1);
  }
  return counts;
}

List<_MerchantFixture> _loadFixtures() {
  final file = File(WorkSupplyParserMerchantMatrixSuite._goldenFixturePath);
  if (!file.existsSync()) return const [];
  final decoded = jsonDecode(file.readAsStringSync()) as List<dynamic>;
  return [
    for (final entry in decoded)
      _MerchantFixture.fromJson((entry as Map).cast<String, Object?>()),
  ];
}

class _MerchantFixture {
  const _MerchantFixture({
    required this.merchant,
    required this.trade,
    required this.marketScope,
    required this.tier,
  });

  final String merchant;
  final String trade;
  final String marketScope;
  final String tier;

  static _MerchantFixture fromJson(Map<String, Object?> json) {
    return _MerchantFixture(
      merchant: json['merchant'] as String? ?? 'unknown',
      trade: (json['trade'] as String? ?? '').toLowerCase(),
      marketScope: (json['marketScope'] as String? ?? '').toLowerCase(),
      tier: (json['tier'] as String? ?? '').toLowerCase(),
    );
  }
}

String _read(String path) {
  final file = File(path);
  if (!file.existsSync()) return '';
  return file.readAsStringSync();
}

String _safeId(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}
