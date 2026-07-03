import 'dart:convert';
import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserFixtureExpectationSuite extends QaSuite {
  const WorkSupplyParserFixtureExpectationSuite()
    : super('inventory.fixture_expectation_contract');

  static const _requiredExpectationFields = {
    'expectedStatus',
    'expectedTopCandidateId',
    'expectedReviewRequired',
    'expectedCandidateTrade',
    'expectedConfidenceBand',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final fixtures = _loadFixtures();
    final statusCounts = <String, int>{};

    for (final fixture in fixtures) {
      _increment(statusCounts, fixture.expectedStatus);
      final missing = fixture.missingExpectationFields();
      if (missing.isEmpty) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'fixture_missing_expected_result:${fixture.id}',
          message:
              'Parser fixture is missing structured expected-result metadata.',
          severity: QaSeverity.warning,
          expected: _requiredExpectationFields.join(', '),
          actual: 'missing=${missing.join(', ')}',
          suggestedFix:
              'Add expected parser status, top candidate, review requirement, trade, and confidence band so fixture failures are explainable.',
          metadata: const {'triageCategory': QaFailureTriage.fixture},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: fixtures.length * _requiredExpectationFields.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'fixtureCount': fixtures.length,
        'expectedStatusCounts': statusCounts,
        'requiredExpectationFields': _requiredExpectationFields.toList()
          ..sort(),
      },
    );
  }
}

class _FixtureExpectation {
  const _FixtureExpectation({
    required this.id,
    required this.expectedStatus,
    required this.expectedTopCandidateId,
    required this.expectedReviewRequired,
    required this.expectedCandidateTrade,
    required this.expectedConfidenceBand,
  });

  final String id;
  final String expectedStatus;
  final String expectedTopCandidateId;
  final Object? expectedReviewRequired;
  final String expectedCandidateTrade;
  final String expectedConfidenceBand;

  List<String> missingExpectationFields() {
    return [
      if (expectedStatus.trim().isEmpty) 'expectedStatus',
      if (expectedTopCandidateId.trim().isEmpty) 'expectedTopCandidateId',
      if (expectedReviewRequired is! bool) 'expectedReviewRequired',
      if (expectedCandidateTrade.trim().isEmpty) 'expectedCandidateTrade',
      if (expectedConfidenceBand.trim().isEmpty) 'expectedConfidenceBand',
    ];
  }

  static _FixtureExpectation fromJson(Map<String, Object?> json) {
    return _FixtureExpectation(
      id: json['id'] as String? ?? 'fixture_without_id',
      expectedStatus: json['expectedStatus'] as String? ?? '',
      expectedTopCandidateId: json['expectedTopCandidateId'] as String? ?? '',
      expectedReviewRequired: json['expectedReviewRequired'],
      expectedCandidateTrade: json['expectedCandidateTrade'] as String? ?? '',
      expectedConfidenceBand: json['expectedConfidenceBand'] as String? ?? '',
    );
  }
}

List<_FixtureExpectation> _loadFixtures() {
  final files = [
    File('test/fixtures/work_supply_parser/golden_fixtures.json'),
    File('test/fixtures/work_supply_parser/holdout_fixtures.json'),
  ];
  final fixtures = <_FixtureExpectation>[];
  for (final file in files) {
    if (!file.existsSync()) continue;
    final decoded = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    fixtures.addAll([
      for (final entry in decoded)
        _FixtureExpectation.fromJson((entry as Map).cast<String, Object?>()),
    ]);
  }
  return fixtures;
}

void _increment(Map<String, int> counts, String key) {
  counts.update(
    key.isEmpty ? 'missing' : key,
    (count) => count + 1,
    ifAbsent: () => 1,
  );
}
