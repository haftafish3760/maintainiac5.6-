import 'dart:convert';
import 'dart:io';

import '../qa_harness/qa_harness.dart';
import 'work_supply_parser_release_one_cell_manifest_qa.dart';

class WorkSupplyParserFixtureCoverageSuite extends QaSuite {
  const WorkSupplyParserFixtureCoverageSuite()
    : super('inventory.fixture_coverage_matrix');

  static const _requiredCaseTypes = {
    'clear_match',
    'dangerous_generic',
    'receipt_noise',
    'ambiguous_review',
    'negative_match',
    'quantity_price',
  };

  static const _recommendedRiskTags = {
    'merchant_abbreviation',
    'dangerous_word',
    'noise_line',
    'privacy',
    'missing_trade_context',
    'not_pipe',
    'cross_trade',
    'quantity',
    'pack_quantity',
    'linear_feet',
    'line_subtotal',
    'unit_cost',
    'spanish',
    'locale_pack',
    'return_line',
    'discount_line',
    'canadian_format',
    'mixed_trade_receipt',
    'supply_house',
  };

  static const _recommendedMerchants = {
    'Home Depot',
    'Lowes',
    'Ace',
    'Ferguson',
    'Grainger',
    'Menards',
    'True Value',
    'Walmart',
    'Supply House',
    'unknown',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final fixtures = _loadFixtures();
    final caseTypes = <String, int>{};
    final merchants = <String, int>{};
    final riskTags = <String, int>{};
    final releaseOneCells = <String, int>{};

    for (final fixture in fixtures) {
      caseTypes.update(
        fixture.caseType,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      merchants.update(
        fixture.merchant,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      for (final tag in fixture.riskTags) {
        riskTags.update(tag, (count) => count + 1, ifAbsent: () => 1);
      }
      final cell = fixture.releaseOneCell;
      if (cell != null) {
        releaseOneCells.update(cell, (count) => count + 1, ifAbsent: () => 1);
      }
      if (fixture.caseType.isEmpty) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'fixture_missing_case_type:${fixture.id}',
            message: 'Fixture is missing caseType coverage metadata.',
            actual: fixture.id,
            suggestedFix:
                'Label fixture as clear_match, ambiguous_review, receipt_noise, negative_match, or another reviewed type.',
          ),
        );
      }
      if (fixture.riskTags.isEmpty) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'fixture_missing_risk_tags:${fixture.id}',
            message: 'Fixture has no riskTags coverage metadata.',
            severity: QaSeverity.warning,
            actual: fixture.id,
            suggestedFix:
                'Add risk tags so coverage reports show what this fixture protects.',
          ),
        );
      }
    }

    for (final type in _requiredCaseTypes) {
      if (caseTypes.containsKey(type)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_required_case_type:$type',
          message: 'Fixture library is missing a required case type.',
          expected: type,
          actual: caseTypes.keys.join(', '),
          suggestedFix:
              'Add at least one fixture for this parser risk category.',
        ),
      );
    }

    for (final tag in _recommendedRiskTags) {
      if (riskTags.containsKey(tag)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_recommended_risk_tag:$tag',
          message: 'Fixture library is missing a recommended risk tag.',
          severity: QaSeverity.warning,
          expected: tag,
          actual: riskTags.keys.join(', '),
          suggestedFix:
              'Add fixtures covering this risk before release-gate accuracy claims.',
        ),
      );
    }

    for (final merchant in _recommendedMerchants) {
      if (merchants.containsKey(merchant)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_recommended_merchant:$merchant',
          message: 'Fixture library is missing recommended merchant coverage.',
          severity: QaSeverity.warning,
          expected: merchant,
          actual: merchants.keys.join(', '),
          suggestedFix:
              'Add synthetic or reviewed real-style fixtures for this merchant.',
        ),
      );
    }

    for (final cell
        in WorkSupplyParserReleaseOneCellManifestSuite.priorityCells) {
      if (releaseOneCells.containsKey(cell)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_release_one_fixture_cell:$cell',
          message:
              'Fixture library is missing a release-one priority Core/Standard cell.',
          severity: QaSeverity.warning,
          expected: cell,
          actual: releaseOneCells.keys.join(', '),
          suggestedFix:
              'Add at least one real-style fixture for this Plumbing/Electrical/HVAC residential Core/Standard English/Spanish cell.',
          metadata: const {'triageCategory': QaFailureTriage.fixture},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked:
          fixtures.length +
          _requiredCaseTypes.length +
          _recommendedRiskTags.length +
          _recommendedMerchants.length +
          WorkSupplyParserReleaseOneCellManifestSuite.priorityCells.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'fixtureCount': fixtures.length,
        'caseTypes': caseTypes,
        'merchants': merchants,
        'riskTags': riskTags,
        'releaseOneCells': releaseOneCells,
      },
    );
  }
}

class _CoverageFixture {
  const _CoverageFixture({
    required this.id,
    required this.caseType,
    required this.merchant,
    required this.riskTags,
    required this.trade,
    required this.marketScope,
    required this.tier,
    required this.localePackId,
  });

  final String id;
  final String caseType;
  final String merchant;
  final List<String> riskTags;
  final String trade;
  final String marketScope;
  final String tier;
  final String localePackId;

  String? get releaseOneCell {
    if (trade.isEmpty ||
        marketScope.isEmpty ||
        tier.isEmpty ||
        localePackId.isEmpty) {
      return null;
    }
    return '$trade.$marketScope.$tier.$localePackId';
  }

  static _CoverageFixture fromJson(Map<String, Object?> json) {
    return _CoverageFixture(
      id: json['id'] as String? ?? 'fixture_without_id',
      caseType: json['caseType'] as String? ?? '',
      merchant: json['merchant'] as String? ?? 'unknown',
      riskTags: [
        for (final tag in json['riskTags'] as List<dynamic>? ?? const [])
          tag.toString(),
      ],
      trade: json['trade'] as String? ?? '',
      marketScope: json['marketScope'] as String? ?? '',
      tier: json['tier'] as String? ?? '',
      localePackId: json['localePackId'] as String? ?? '',
    );
  }
}

List<_CoverageFixture> _loadFixtures() {
  final file = File('test/fixtures/work_supply_parser/golden_fixtures.json');
  if (!file.existsSync()) return const [];
  final decoded = jsonDecode(file.readAsStringSync()) as List<dynamic>;
  return [
    for (final entry in decoded)
      _CoverageFixture.fromJson((entry as Map).cast<String, Object?>()),
  ];
}
