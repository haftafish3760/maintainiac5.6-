import 'dart:convert';
import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserFixtureGovernanceSuite extends QaSuite {
  const WorkSupplyParserFixtureGovernanceSuite()
    : super('inventory.fixture_governance');

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final files = Directory('test/fixtures/work_supply_parser')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList(growable: false);
    final globalIds = <String, String>{};
    final rawLineOutcomes = <String, _FixtureOutcome>{};
    var checked = 0;

    for (final file in files) {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! List) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'fixture_file_not_list:${file.path}',
            message: 'Fixture file must contain a JSON array.',
            actual: file.path,
            suggestedFix: 'Store fixtures as a top-level array of cases.',
          ),
        );
        continue;
      }
      final ids = <String>{};
      for (final entry in decoded) {
        checked++;
        if (entry is! Map) {
          failures.add(
            QaFailure(
              suite: name,
              id: 'fixture_not_object:${file.path}:$checked',
              message: 'Fixture entry must be a JSON object.',
              actual: entry.toString(),
              suggestedFix: 'Use a structured fixture object.',
            ),
          );
          continue;
        }
        final fixture = entry.cast<String, Object?>();
        final id = (fixture['id'] as String? ?? '').trim();
        final rawLine = (fixture['rawLine'] as String? ?? '').trim();
        final normalizedRawLine = _normalizeRawLine(rawLine);
        _require(
          failures,
          id.isNotEmpty,
          id: 'fixture_missing_id:${file.path}:$checked',
          message: 'Fixture is missing stable id.',
          actual: file.path,
          fix: 'Give every fixture a stable id for regression tracking.',
        );
        if (id.isNotEmpty && !ids.add(id)) {
          failures.add(
            QaFailure(
              suite: name,
              id: 'fixture_duplicate_id:$id',
              message: 'Fixture id is duplicated within the same file.',
              actual: file.path,
              suggestedFix:
                  'Fixture ids must be unique so regressions are traceable.',
            ),
          );
        }
        final globalIdOwner = globalIds[id];
        if (id.isNotEmpty &&
            globalIdOwner != null &&
            globalIdOwner != file.path) {
          failures.add(
            QaFailure(
              suite: name,
              id: 'fixture_duplicate_global_id:$id',
              message: 'Fixture id is duplicated across fixture files.',
              expected: globalIdOwner,
              actual: file.path,
              suggestedFix:
                  'Fixture ids must be globally unique so baseline diffs and regressions are traceable.',
            ),
          );
        } else if (id.isNotEmpty) {
          globalIds[id] = file.path;
        }
        _require(
          failures,
          rawLine.isNotEmpty,
          id: 'fixture_missing_raw_line:$id',
          message: 'Fixture is missing rawLine.',
          actual: id,
          fix: 'Add the receipt-like line to test.',
        );
        _require(
          failures,
          (fixture['caseType'] as String? ?? '').trim().isNotEmpty,
          id: 'fixture_missing_case_type:$id',
          message: 'Fixture is missing caseType metadata.',
          actual: id,
          fix: 'Label the fixture by parser risk category.',
        );
        _require(
          failures,
          (fixture['merchant'] as String? ?? '').trim().isNotEmpty,
          id: 'fixture_missing_merchant:$id',
          message: 'Fixture is missing merchant metadata.',
          actual: id,
          fix: 'Set merchant to a known merchant name or unknown.',
        );
        final riskTags = fixture['riskTags'];
        if (riskTags is! List || riskTags.isEmpty) {
          failures.add(
            QaFailure(
              suite: name,
              id: 'fixture_missing_risk_tags:$id',
              message: 'Fixture is missing riskTags metadata.',
              severity: QaSeverity.warning,
              actual: id,
              suggestedFix:
                  'Add risk tags so fixture coverage can be measured.',
            ),
          );
        }

        final expectUnknown = fixture['expectUnknown'] == true;
        final expectedTrade = (fixture['expectedTrade'] as String? ?? '')
            .trim();
        final expectedNameContains =
            (fixture['expectedNameContains'] as String? ?? '').trim();
        if (!expectUnknown &&
            expectedTrade.isEmpty &&
            expectedNameContains.isEmpty) {
          failures.add(
            QaFailure(
              suite: name,
              id: 'fixture_missing_expected_outcome:$id',
              message:
                  'Fixture must declare unknown/review expectation or expected match evidence.',
              actual: id,
              suggestedFix:
                  'Set expectUnknown or add expectedTrade/expectedNameContains.',
            ),
          );
        }

        final maxConfidence = fixture['maxConfidence'];
        if (maxConfidence != null &&
            (maxConfidence is! num || maxConfidence < 0 || maxConfidence > 1)) {
          failures.add(
            QaFailure(
              suite: name,
              id: 'fixture_invalid_max_confidence:$id',
              message: 'Fixture maxConfidence must be between 0 and 1.',
              actual: maxConfidence.toString(),
              suggestedFix: 'Use a decimal confidence threshold from 0.0-1.0.',
            ),
          );
        }
        if (normalizedRawLine.isNotEmpty) {
          final outcome = _FixtureOutcome.fromFixture(fixture);
          final previous = rawLineOutcomes[normalizedRawLine];
          if (previous == null) {
            rawLineOutcomes[normalizedRawLine] = outcome;
          } else if (!previous.sameExpectationAs(outcome)) {
            failures.add(
              QaFailure(
                suite: name,
                id: 'fixture_conflicting_raw_line:$normalizedRawLine',
                message:
                    'Same raw fixture line has conflicting expected outcomes.',
                expected: previous.summary,
                actual: outcome.summary,
                suggestedFix:
                    'Use one stable expected outcome per normalized raw line, or make the lines distinct enough to test different behavior.',
              ),
            );
          } else {
            failures.add(
              QaFailure(
                suite: name,
                id: 'fixture_duplicate_raw_line:$normalizedRawLine',
                message: 'Fixture duplicates an existing raw receipt line.',
                severity: QaSeverity.warning,
                expected: previous.id,
                actual: id,
                suggestedFix:
                    'Remove duplicate fixture or mutate the line so it adds new coverage.',
              ),
            );
          }
        }
      }
    }

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'fixtureFileCount': files.length,
        'globalFixtureIds': globalIds.length,
        'uniqueRawLines': rawLineOutcomes.length,
      },
    );
  }
}

class _FixtureOutcome {
  const _FixtureOutcome({
    required this.id,
    required this.expectUnknown,
    required this.expectedTrade,
    required this.expectedNameContains,
    required this.maxConfidence,
  });

  final String id;
  final bool expectUnknown;
  final String expectedTrade;
  final String expectedNameContains;
  final String maxConfidence;

  String get summary {
    return [
      'id=$id',
      'expectUnknown=$expectUnknown',
      if (expectedTrade.isNotEmpty) 'expectedTrade=$expectedTrade',
      if (expectedNameContains.isNotEmpty)
        'expectedNameContains=$expectedNameContains',
      if (maxConfidence.isNotEmpty) 'maxConfidence=$maxConfidence',
    ].join('; ');
  }

  bool sameExpectationAs(_FixtureOutcome other) {
    return expectUnknown == other.expectUnknown &&
        expectedTrade == other.expectedTrade &&
        expectedNameContains == other.expectedNameContains &&
        maxConfidence == other.maxConfidence;
  }

  static _FixtureOutcome fromFixture(Map<String, Object?> fixture) {
    return _FixtureOutcome(
      id: (fixture['id'] as String? ?? '').trim(),
      expectUnknown: fixture['expectUnknown'] == true,
      expectedTrade: (fixture['expectedTrade'] as String? ?? '').trim(),
      expectedNameContains: (fixture['expectedNameContains'] as String? ?? '')
          .trim(),
      maxConfidence: fixture['maxConfidence']?.toString() ?? '',
    );
  }
}

String _normalizeRawLine(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9./\-\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

void _require(
  List<QaFailure> failures,
  bool condition, {
  required String id,
  required String message,
  required String actual,
  required String fix,
}) {
  if (condition) return;
  failures.add(
    QaFailure(
      suite: 'inventory.fixture_governance',
      id: id,
      message: message,
      actual: actual,
      suggestedFix: fix,
    ),
  );
}
