import 'dart:convert';
import 'dart:io';

import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyGoldenFixtureSuite extends QaSuite {
  const WorkSupplyGoldenFixtureSuite() : super('inventory.golden_fixtures');

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final failures = <QaFailure>[];
    final fixtureFilter = _fixtureIdFilter();
    final fixtures = _filteredFixtures(_loadFixtures(), fixtureFilter);
    if (!context.isFullProfile) {
      final timer = QaStopwatch.start();
      return timer.finish(
        suite: name,
        checked: fixtures.length,
        failures: failures,
        maxFailures: context.maxFailuresPerSuite,
        metrics: {
          'mode': 'fixture-load-smoke',
          'fixturePath':
              'test/fixtures/work_supply_parser/golden_fixtures.json',
          'fixtureCount': fixtures.length,
          'fixtureIdFilter': fixtureFilter.toList()..sort(),
          'note':
              'Full fixture parser assertions run in full/release profiles.',
        },
      );
    }

    final warmupTimer = Stopwatch()..start();
    matchReceiptLineToCatalog(
      'HD 3/4 PVC SCH40 COUPLING',
      tradeScope: 'Plumbing',
      maxCandidates: 24,
    );
    warmupTimer.stop();

    final timer = QaStopwatch.start();
    final fixtureTimings = <Map<String, Object?>>[];
    for (final fixture in fixtures) {
      final rawLine = fixture.rawLine;
      final fixtureTimer = Stopwatch()..start();
      final match = matchReceiptLineToCatalog(
        rawLine,
        tradeScope: fixture.tradeScope,
        localePackId: fixture.localePackId,
        maxCandidates: 24,
      );
      fixtureTimer.stop();
      fixtureTimings.add({
        'id': fixture.id,
        'durationMs': fixtureTimer.elapsedMilliseconds,
        'caseType': fixture.caseType,
      });
      if (fixture.expectUnknown) {
        if (match != null && match.confidence >= fixture.maxConfidence) {
          failures.add(
            QaFailure(
              suite: name,
              id: fixture.id,
              message:
                  'Fixture expected unknown/review but got confident match.',
              expected: fixture.expectedSummary,
              actual:
                  '${match.item.path} / ${match.item.name} confidence=${match.confidence}',
              suggestedFix:
                  'Add noise, ambiguity, negative-match, or confidence rule.',
            ),
          );
        }
        continue;
      }
      if (match == null) {
        failures.add(
          QaFailure(
            suite: name,
            id: fixture.id,
            message: 'Fixture expected parser candidate but got no match.',
            expected: fixture.expectedSummary,
            actual: 'null',
            suggestedFix: 'Add alias, receipt pattern, or canonical metadata.',
          ),
        );
        continue;
      }
      if (fixture.expectedTrade.isNotEmpty &&
          match.item.trade != fixture.expectedTrade) {
        failures.add(
          QaFailure(
            suite: name,
            id: fixture.id,
            message: 'Fixture matched wrong trade.',
            expected: fixture.expectedTrade,
            actual: match.item.trade,
            suggestedFix: 'Add cross-trade conflict or context scoring rule.',
          ),
        );
      }
      if (fixture.expectedNameContains.isNotEmpty &&
          !match.item.name.toLowerCase().contains(
            fixture.expectedNameContains.toLowerCase(),
          )) {
        failures.add(
          QaFailure(
            suite: name,
            id: fixture.id,
            message: 'Fixture top candidate name did not match expectation.',
            expected: fixture.expectedNameContains,
            actual: match.item.name,
            suggestedFix:
                'Add canonical alias, merchant abbreviation, or negative rule.',
          ),
        );
      }
      if (fixture.maxConfidence < 1 &&
          match.confidence > fixture.maxConfidence) {
        failures.add(
          QaFailure(
            suite: name,
            id: fixture.id,
            message: 'Fixture confidence is too high for risky line.',
            expected: '<= ${fixture.maxConfidence}',
            actual: '${match.confidence}',
            suggestedFix: 'Make confidence conservative and explain ambiguity.',
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
        'fixturePath': 'test/fixtures/work_supply_parser/golden_fixtures.json',
        'fixtureCount': fixtures.length,
        'fixtureIdFilter': fixtureFilter.toList()..sort(),
        'warmupMs': warmupTimer.elapsedMilliseconds,
        'warmupLine': 'HD 3/4 PVC SCH40 COUPLING',
        'semanticTimingExcludesWarmup': true,
        'slowestFixtures':
            (fixtureTimings..sort(
                  (a, b) => (b['durationMs'] as int).compareTo(
                    a['durationMs'] as int,
                  ),
                ))
                .take(5)
                .toList(),
      },
    );
  }
}

Set<String> _fixtureIdFilter() {
  const csv = String.fromEnvironment('PARSER_QA_FIXTURE_IDS');
  return csv
      .split(',')
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toSet();
}

List<_GoldenFixture> _filteredFixtures(
  List<_GoldenFixture> fixtures,
  Set<String> filter,
) {
  if (filter.isEmpty) return fixtures;
  return [
    for (final fixture in fixtures)
      if (filter.contains(fixture.id)) fixture,
  ];
}

class WorkSupplyGeneratedCaseSuite extends QaSuite {
  const WorkSupplyGeneratedCaseSuite() : super('inventory.generated_cases');

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    if (!context.isFullProfile) {
      return timer.finish(
        suite: name,
        checked: context.maxGeneratedCases,
        failures: failures,
        maxFailures: context.maxFailuresPerSuite,
        metrics: {
          'mode': 'generated-case-build-smoke',
          'requestedLimit': context.maxGeneratedCases,
          'generationSeed': 'catalog-order-v1',
          'generatedCaseSource':
              'plumbing-residential-core-standard-first-receipt-pattern',
          'candidateMerchantPrefix': 'HD',
          'tradeScope': 'Plumbing',
          'catalogConstructionSkipped': true,
          'note': 'Generated parser assertions run in full/release profiles.',
        },
      );
    }
    final cases = _generatedCases(context.maxGeneratedCases);
    for (final generated in cases) {
      final match = matchReceiptLineToCatalog(
        generated.line,
        tradeScope: generated.item.trade,
        localePackId: generated.localePackId,
        maxCandidates: 24,
      );
      if (match == null) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'generated_missing:${generated.item.id}',
            message: 'Generated item line did not match any catalog item.',
            expected: generated.item.name,
            actual: context.redactor(generated.line),
            suggestedFix:
                'Add receipt pattern or parser alias for this family.',
          ),
        );
        continue;
      }
      if (!_sameGeneratedFamily(generated.item, match.item)) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'generated_wrong_family:${generated.item.id}',
            message: 'Generated item line matched wrong catalog family.',
            expected: generated.item.path,
            actual: '${match.item.path} / ${match.item.name}',
            suggestedFix:
                'Add exact variant matching, negative rule, or ambiguity ranking.',
          ),
        );
      }
      if (match.confidence < .62) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'generated_low_confidence:${generated.item.id}',
            message: 'Generated item line matched with low confidence.',
            expected: '>= 0.62',
            actual: '${match.confidence} for ${match.item.name}',
            suggestedFix:
                'Add stronger aliases, receipt patterns, or size/material tokens.',
          ),
        );
      }
    }
    return timer.finish(
      suite: name,
      checked: cases.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'requestedLimit': context.maxGeneratedCases,
        'generationSeed': 'catalog-order-v1',
        'generatedCaseSource':
            'plumbing-residential-core-standard-first-receipt-pattern',
        'candidateMerchantPrefix': 'HD',
        'tradeScope': 'Plumbing',
      },
    );
  }

  List<_GeneratedCase> _generatedCases(int limit) {
    final cases = <_GeneratedCase>[];
    for (final item in workSupplyCatalogItems) {
      if (item.trade != 'Plumbing') continue;
      if (!item.marketScopes.contains(WorkSupplyMarketScope.residential)) {
        continue;
      }
      if (item.packTier != WorkSupplyPackTier.core &&
          item.packTier != WorkSupplyPackTier.standard) {
        continue;
      }
      final phrase = item.intelligence.receiptPatterns.isNotEmpty
          ? item.intelligence.receiptPatterns.first
          : item.name;
      cases.add(_GeneratedCase('HD $phrase', item, ''));
      if (cases.length >= limit) break;
    }
    return cases;
  }
}

class _GoldenFixture {
  const _GoldenFixture({
    required this.id,
    required this.rawLine,
    this.caseType = '',
    this.expectedTrade = '',
    this.expectedNameContains = '',
    this.tradeScope,
    this.localePackId = '',
    this.expectUnknown = false,
    this.maxConfidence = 1,
  });

  final String id;
  final String rawLine;
  final String caseType;
  final String expectedTrade;
  final String expectedNameContains;
  final String? tradeScope;
  final String localePackId;
  final bool expectUnknown;
  final double maxConfidence;

  String get expectedSummary {
    if (expectUnknown) {
      return 'unknown/review with confidence <= $maxConfidence';
    }
    return [
      if (expectedTrade.isNotEmpty) 'trade=$expectedTrade',
      if (expectedNameContains.isNotEmpty)
        'name contains "$expectedNameContains"',
    ].join(', ');
  }

  static _GoldenFixture fromJson(Map<String, Object?> json) {
    return _GoldenFixture(
      id: json['id'] as String? ?? 'fixture_without_id',
      rawLine: json['rawLine'] as String? ?? '',
      caseType: json['caseType'] as String? ?? '',
      expectedTrade: json['expectedTrade'] as String? ?? '',
      expectedNameContains: json['expectedNameContains'] as String? ?? '',
      tradeScope: json['tradeScope'] as String?,
      localePackId: json['localePackId'] as String? ?? '',
      expectUnknown: json['expectUnknown'] as bool? ?? false,
      maxConfidence: (json['maxConfidence'] as num?)?.toDouble() ?? 1,
    );
  }
}

class _GeneratedCase {
  const _GeneratedCase(this.line, this.item, this.localePackId);

  final String line;
  final WorkSupplyItem item;
  final String localePackId;
}

List<_GoldenFixture> _loadFixtures() {
  final file = File('test/fixtures/work_supply_parser/golden_fixtures.json');
  if (!file.existsSync()) return const [];
  final decoded = jsonDecode(file.readAsStringSync()) as List<dynamic>;
  return [
    for (final entry in decoded)
      _GoldenFixture.fromJson((entry as Map).cast<String, Object?>()),
  ];
}

bool _sameGeneratedFamily(WorkSupplyItem expected, WorkSupplyItem actual) {
  if (expected.id == actual.id) return true;
  if (expected.trade != actual.trade) return false;
  if (expected.category != actual.category) return false;
  if (expected.system != actual.system) return false;
  if (expected.itemType != actual.itemType) return false;
  final expectedSize = _leadingSize(expected.name);
  final actualSize = _leadingSize(actual.name);
  return expectedSize.isEmpty ||
      actualSize.isEmpty ||
      expectedSize == actualSize;
}

String _leadingSize(String value) {
  final match = RegExp(
    r'^(\d+(?:-\d/\d|/\d)?(?:\.\d+)?)\s*(?:in|x|\b)',
  ).firstMatch(value.toLowerCase());
  return match?.group(1) ?? '';
}
