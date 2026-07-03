import 'dart:convert';
import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserAccuracyBudgetSuite extends QaSuite {
  const WorkSupplyParserAccuracyBudgetSuite()
    : super('inventory.accuracy_budget');

  static const _minTop1ClearMatchAccuracy = .98;
  static const _maxFalseConfidentRate = .001;
  static const _maxNoiseFalsePositiveRate = .001;
  static const _minGeneratedFamilyAccuracy = .98;
  static const _rankedCandidateBudget = 'top3_pending_possible_matches';

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final fixtures = _loadFixtures();
    final failures = <QaFailure>[];
    _checkFixtureCoverage(failures, fixtures);

    return timer.finish(
      suite: name,
      checked: fixtures.length + 6,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'mode': context.isFullProfile
            ? 'accuracy-budget-full-contract'
            : 'accuracy-budget-smoke',
        'parserCallMode': 'delegated_to_golden_generated_and_release_suites',
        'top1AccuracyBudget': _minTop1ClearMatchAccuracy,
        'top3AccuracyBudget': _rankedCandidateBudget,
        'falseConfidentRateBudget': _maxFalseConfidentRate,
        'noiseFalsePositiveRateBudget': _maxNoiseFalsePositiveRate,
        'generatedFamilyAccuracyBudget': _minGeneratedFamilyAccuracy,
        'fixtureCount': fixtures.length,
      },
    );
  }

  void _checkFixtureCoverage(
    List<QaFailure> failures,
    List<_AccuracyFixture> fixtures,
  ) {
    final caseTypes = <String>{
      for (final fixture in fixtures) fixture.caseType,
    };
    const requiredTypes = {
      'clear_match',
      'dangerous_generic',
      'receipt_noise',
      'ambiguous_review',
      'negative_match',
      'quantity_price',
    };
    for (final type in requiredTypes) {
      if (caseTypes.contains(type)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_accuracy_case_type:$type',
          message: 'Accuracy-budget fixtures are missing a required case type.',
          severity: QaSeverity.warning,
          expected: type,
          actual: caseTypes.join(', '),
          suggestedFix:
              'Add fixture coverage before trusting parser accuracy budgets.',
          metadata: const {'triageCategory': QaFailureTriage.fixture},
        ),
      );
    }
  }
}

class _AccuracyFixture {
  const _AccuracyFixture({required this.caseType});

  final String caseType;

  static _AccuracyFixture fromJson(Map<String, Object?> json) {
    return _AccuracyFixture(caseType: json['caseType'] as String? ?? '');
  }
}

List<_AccuracyFixture> _loadFixtures() {
  final file = File('test/fixtures/work_supply_parser/golden_fixtures.json');
  if (!file.existsSync()) return const [];
  final decoded = jsonDecode(file.readAsStringSync()) as List<dynamic>;
  return [
    for (final entry in decoded)
      _AccuracyFixture.fromJson((entry as Map).cast<String, Object?>()),
  ];
}
