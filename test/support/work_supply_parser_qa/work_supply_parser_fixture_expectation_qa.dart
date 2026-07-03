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

  static const _allowedExpectedStatuses = {'matched', 'needsReview', 'unknown'};

  static const _allowedConfidenceBands = {'high', 'review', 'low'};

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final fixtures = _loadFixtures();
    final statusCounts = <String, int>{};

    for (final fixture in fixtures) {
      _increment(statusCounts, fixture.expectedStatus);
      final missing = fixture.missingExpectationFields();
      if (missing.isNotEmpty) {
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
        continue;
      }
      _validateExpectationValues(failures, fixture);
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

  void _validateExpectationValues(
    List<QaFailure> failures,
    _FixtureExpectation fixture,
  ) {
    if (!_allowedExpectedStatuses.contains(fixture.expectedStatus)) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'fixture_invalid_expected_status:${fixture.id}',
          message: 'Parser fixture has an unsupported expectedStatus value.',
          severity: QaSeverity.warning,
          expected: _allowedExpectedStatuses.join(', '),
          actual: fixture.expectedStatus,
          suggestedFix:
              'Use the shared parser status vocabulary so reports and release gates can aggregate fixture outcomes safely.',
          metadata: const {'triageCategory': QaFailureTriage.fixture},
        ),
      );
    }

    if (!_allowedConfidenceBands.contains(fixture.expectedConfidenceBand)) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'fixture_invalid_confidence_band:${fixture.id}',
          message:
              'Parser fixture has an unsupported expectedConfidenceBand value.',
          severity: QaSeverity.warning,
          expected: _allowedConfidenceBands.join(', '),
          actual: fixture.expectedConfidenceBand,
          suggestedFix:
              'Use high, review, or low so fixture evidence remains comparable across parser suites.',
          metadata: const {'triageCategory': QaFailureTriage.fixture},
        ),
      );
    }

    if (fixture.expectedStatus == 'matched') {
      _expectReviewFlag(
        failures,
        fixture,
        expectedReviewRequired: false,
        expectedBand: 'high',
      );
    } else if (fixture.expectedStatus == 'needsReview') {
      _expectReviewFlag(
        failures,
        fixture,
        expectedReviewRequired: true,
        expectedBand: 'review',
      );
    } else if (fixture.expectedStatus == 'unknown') {
      _expectReviewFlag(
        failures,
        fixture,
        expectedReviewRequired: true,
        expectedBand: 'low',
      );
    }
  }

  void _expectReviewFlag(
    List<QaFailure> failures,
    _FixtureExpectation fixture, {
    required bool expectedReviewRequired,
    required String expectedBand,
  }) {
    if (fixture.expectedReviewRequired != expectedReviewRequired) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'fixture_inconsistent_review_status:${fixture.id}',
          message:
              'Parser fixture expectedReviewRequired does not match expectedStatus.',
          severity: QaSeverity.warning,
          expected:
              'expectedStatus=${fixture.expectedStatus} requires expectedReviewRequired=$expectedReviewRequired',
          actual: 'expectedReviewRequired=${fixture.expectedReviewRequired}',
          suggestedFix:
              'Keep fixture review flags aligned with the parser result contract: clear matches do not require review; review/unknown outcomes do.',
          metadata: const {'triageCategory': QaFailureTriage.fixture},
        ),
      );
    }

    if (fixture.expectedConfidenceBand != expectedBand) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'fixture_inconsistent_confidence_band:${fixture.id}',
          message:
              'Parser fixture expectedConfidenceBand does not match expectedStatus.',
          severity: QaSeverity.warning,
          expected:
              'expectedStatus=${fixture.expectedStatus} requires expectedConfidenceBand=$expectedBand',
          actual: 'expectedConfidenceBand=${fixture.expectedConfidenceBand}',
          suggestedFix:
              'Keep fixture confidence bands deterministic so threshold gates can reason over parser evidence.',
          metadata: const {'triageCategory': QaFailureTriage.fixture},
        ),
      );
    }
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
