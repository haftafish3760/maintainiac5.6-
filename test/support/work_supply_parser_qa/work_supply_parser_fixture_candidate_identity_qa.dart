import 'dart:convert';
import 'dart:io';

import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserFixtureCandidateIdentitySuite extends QaSuite {
  const WorkSupplyParserFixtureCandidateIdentitySuite()
    : super('inventory.fixture_candidate_identity_contract');

  static const _fixturePaths = [
    'test/fixtures/work_supply_parser/golden_fixtures.json',
    'test/fixtures/work_supply_parser/holdout_fixtures.json',
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final fixtures = _loadFixtures(failures);

    for (final fixture in fixtures) {
      if (fixture.expectedStatus != 'matched') continue;
      if (fixture.expectedTopCandidateId == 'unknown') continue;
      final catalogItems = _semanticCandidateMatches(fixture);
      if (catalogItems.isEmpty) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'fixture_expected_candidate_identity_missing:${fixture.id}',
            message:
                'Fixture expectedTopCandidateId does not describe any matching catalog item.',
            expected: fixture.expectedTopCandidateId,
            actual: 'no semantic match in expected trade/name scope',
            suggestedFix:
                'Point the fixture to a stable semantic candidate key that appears in the intended catalog item name, type, aliases, or intelligence tokens.',
            metadata: const {'triageCategory': QaFailureTriage.fixture},
          ),
        );
      }
    }

    return timer.finish(
      suite: name,
      checked: fixtures.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'fixturePaths': _fixturePaths,
        'fixtureCount': fixtures.length,
        'catalogItemCount': workSupplyCatalogItems.length,
        'contract':
            'Fixture expectedTopCandidateId values are stable semantic keys. Matched fixtures must resolve to at least one catalog item in the expected trade/name scope before parser runtime evidence can be trusted.',
      },
    );
  }

  List<Object> _semanticCandidateMatches(_FixtureCandidateExpectation fixture) {
    final tokens = _tokens(fixture.expectedTopCandidateId);
    if (tokens.isEmpty) return const [];
    final expectedTrade = fixture.expectedCandidateTrade.toLowerCase();
    final expectedName = fixture.expectedNameContains.toLowerCase();
    return [
      for (final item in workSupplyCatalogItems)
        if ((expectedTrade.isEmpty ||
                expectedTrade == 'unknown' ||
                item.trade.toLowerCase() == expectedTrade) &&
            (expectedName.isEmpty ||
                item.name.toLowerCase().contains(expectedName)) &&
            tokens.every((token) => item.searchableText.contains(token)))
          item,
    ];
  }

  List<_FixtureCandidateExpectation> _loadFixtures(List<QaFailure> failures) {
    final fixtures = <_FixtureCandidateExpectation>[];
    for (final path in _fixturePaths) {
      final file = File(path);
      if (!file.existsSync()) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'missing_fixture_file:$path',
            message:
                'Fixture file needed for candidate identity QA is missing.',
            expected: path,
            actual: 'not found',
            suggestedFix:
                'Restore fixture files before validating expected candidate IDs.',
            metadata: const {'triageCategory': QaFailureTriage.fixture},
          ),
        );
        continue;
      }
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! List) continue;
      fixtures.addAll([
        for (final entry in decoded)
          if (entry is Map)
            _FixtureCandidateExpectation.fromJson(
              entry.cast<String, Object?>(),
            ),
      ]);
    }
    return fixtures;
  }
}

class _FixtureCandidateExpectation {
  const _FixtureCandidateExpectation({
    required this.id,
    required this.expectedStatus,
    required this.expectedTopCandidateId,
    required this.expectedCandidateTrade,
    required this.expectedNameContains,
  });

  final String id;
  final String expectedStatus;
  final String expectedTopCandidateId;
  final String expectedCandidateTrade;
  final String expectedNameContains;

  static _FixtureCandidateExpectation fromJson(Map<String, Object?> json) {
    return _FixtureCandidateExpectation(
      id: json['id'] as String? ?? 'fixture_without_id',
      expectedStatus: json['expectedStatus'] as String? ?? '',
      expectedTopCandidateId: json['expectedTopCandidateId'] as String? ?? '',
      expectedCandidateTrade: json['expectedCandidateTrade'] as String? ?? '',
      expectedNameContains: json['expectedNameContains'] as String? ?? '',
    );
  }
}

List<String> _tokens(String value) {
  return value
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((token) => token.isNotEmpty)
      .toList();
}
