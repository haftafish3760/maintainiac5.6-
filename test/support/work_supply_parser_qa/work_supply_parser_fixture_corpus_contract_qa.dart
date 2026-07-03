import 'dart:convert';
import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserFixtureCorpusContractSuite extends QaSuite {
  const WorkSupplyParserFixtureCorpusContractSuite()
    : super('inventory.fixture_corpus_contract');

  static const _fixturePath =
      'test/fixtures/work_supply_parser/golden_fixtures.json';

  static const _requiredCaseTypes = {
    'clear_match',
    'quantity_price',
    'dangerous_generic',
    'receipt_noise',
    'ambiguous_review',
    'negative_match',
  };

  static const _requiredReleaseMerchants = {
    'Home Depot',
    'Lowes',
    'Ace',
    'Ferguson',
    'Grainger',
    'unknown',
  };

  static const _requiredRiskTags = {
    'merchant_abbreviation',
    'dangerous_word',
    'noise_line',
    'privacy',
    'missing_trade_context',
    'not_pipe',
    'quantity',
    'unit_cost',
    'spanish',
    'locale_pack',
  };

  static const _requiredLocaleIds = {'es-US'};

  static final _privatePatterns = {
    'card_like_number': RegExp(r'\b\d{12,19}\b'),
    'email': RegExp(r'\b[\w.+%-]+@[\w.-]+\.[A-Za-z]{2,}\b'),
    'phone': RegExp(r'\b\d{3}[-.]\d{3}[-.]\d{4}\b'),
    'address': RegExp(
      r'\b\d{1,6}\s+[A-Za-z0-9 .#-]{2,40}\s+'
      r'(?:st|street|rd|road|ave|avenue|blvd|lane|ln|dr|drive|ct|court)\b',
      caseSensitive: false,
    ),
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final file = File(_fixturePath);
    if (!file.existsSync()) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_fixture_corpus',
          message: 'Golden fixture corpus is missing.',
          expected: _fixturePath,
          actual: 'not found',
          suggestedFix:
              'Restore golden fixtures before claiming parser QA coverage.',
          metadata: const {'triageCategory': QaFailureTriage.fixture},
        ),
      );
      return timer.finish(
        suite: name,
        checked: 1,
        failures: failures,
        maxFailures: context.maxFailuresPerSuite,
      );
    }

    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! List) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'fixture_corpus_not_list',
          message: 'Golden fixture corpus must be a JSON array.',
          actual: decoded.runtimeType.toString(),
          suggestedFix: 'Store fixture cases as a top-level JSON array.',
          metadata: const {'triageCategory': QaFailureTriage.fixture},
        ),
      );
      return timer.finish(
        suite: name,
        checked: 1,
        failures: failures,
        maxFailures: context.maxFailuresPerSuite,
      );
    }

    final caseTypes = <String>{};
    final merchants = <String>{};
    final riskTags = <String>{};
    final localeIds = <String>{};
    final fixtureIds = <String>{};
    final rawLines = <String>{};
    var unknownOrReviewCount = 0;
    var expectedMatchCount = 0;

    for (final entry in decoded) {
      if (entry is! Map) continue;
      final fixture = entry.cast<String, Object?>();
      final id = fixture['id']?.toString() ?? 'fixture_without_id';
      final rawLine = fixture['rawLine']?.toString() ?? '';
      _require(
        failures,
        id.trim().isNotEmpty && id != 'fixture_without_id',
        id: 'fixture_missing_id:$id',
        message: 'Golden fixture is missing a stable id.',
        expected: 'non-empty fixture id',
        actual: id,
      );
      _require(
        failures,
        fixtureIds.add(id),
        id: 'duplicate_fixture_id:$id',
        message: 'Golden fixture id is duplicated.',
        expected: 'unique fixture id',
        actual: id,
      );
      final normalizedRawLine = _normalize(rawLine);
      _require(
        failures,
        normalizedRawLine.isNotEmpty,
        id: 'fixture_missing_raw_line:$id',
        message: 'Golden fixture is missing rawLine text.',
        expected: 'non-empty rawLine',
        actual: context.redactor(rawLine),
      );
      _require(
        failures,
        rawLines.add(normalizedRawLine),
        id: 'duplicate_fixture_raw_line:$id',
        message: 'Golden fixture rawLine is duplicated.',
        expected: 'unique normalized rawLine',
        actual: context.redactor(rawLine),
      );
      caseTypes.add(fixture['caseType']?.toString() ?? '');
      merchants.add(fixture['merchant']?.toString() ?? '');
      final localeId = fixture['localePackId']?.toString() ?? '';
      if (localeId.isNotEmpty) localeIds.add(localeId);
      for (final tag in fixture['riskTags'] as List<dynamic>? ?? const []) {
        riskTags.add(tag.toString());
      }
      if (fixture['expectUnknown'] == true) {
        unknownOrReviewCount++;
      }
      if ((fixture['expectedTrade']?.toString() ?? '').isNotEmpty ||
          (fixture['expectedNameContains']?.toString() ?? '').isNotEmpty) {
        expectedMatchCount++;
      }
      for (final pattern in _privatePatterns.entries) {
        if (!pattern.value.hasMatch(rawLine)) continue;
        failures.add(
          QaFailure(
            suite: name,
            id: 'fixture_raw_line_private_token:${pattern.key}:$id',
            message:
                'Fixture rawLine contains private-looking data instead of synthetic placeholders.',
            expected: 'privacy-safe synthetic fixture text',
            actual: context.redactor(rawLine),
            suggestedFix:
                'Replace private-looking fixture text with synthetic non-user data.',
            metadata: const {'triageCategory': QaFailureTriage.privacy},
          ),
        );
      }
    }

    for (final type in _requiredCaseTypes) {
      _requireContains(
        failures,
        caseTypes,
        type,
        idPrefix: 'missing_fixture_case_type',
        message: 'Fixture corpus is missing a required case type.',
      );
    }
    for (final merchant in _requiredReleaseMerchants) {
      _requireContains(
        failures,
        merchants,
        merchant,
        idPrefix: 'missing_fixture_merchant',
        message: 'Fixture corpus is missing release-one merchant coverage.',
      );
    }
    for (final tag in _requiredRiskTags) {
      _requireContains(
        failures,
        riskTags,
        tag,
        idPrefix: 'missing_fixture_risk_tag',
        message: 'Fixture corpus is missing required risk-tag coverage.',
      );
    }
    for (final localeId in _requiredLocaleIds) {
      _requireContains(
        failures,
        localeIds,
        localeId,
        idPrefix: 'missing_fixture_locale',
        message: 'Fixture corpus is missing release-one locale coverage.',
      );
    }

    if (expectedMatchCount == 0) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'fixture_corpus_missing_expected_matches',
          message: 'Fixture corpus has no expected-match cases.',
          expected: 'at least one clear expected match',
          actual: '0',
          suggestedFix:
              'Add clear-match fixtures with expectedTrade or expectedNameContains.',
          metadata: const {'triageCategory': QaFailureTriage.fixture},
        ),
      );
    }
    if (unknownOrReviewCount == 0) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'fixture_corpus_missing_review_cases',
          message: 'Fixture corpus has no review/unknown cases.',
          expected: 'at least one expectUnknown fixture',
          actual: '0',
          suggestedFix:
              'Add ambiguity, dangerous-word, noise, or negative-match review fixtures.',
          metadata: const {'triageCategory': QaFailureTriage.fixture},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked:
          decoded.length +
          fixtureIds.length +
          rawLines.length +
          _requiredCaseTypes.length +
          _requiredReleaseMerchants.length +
          _requiredRiskTags.length +
          _requiredLocaleIds.length +
          2,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'fixtureCount': decoded.length,
        'uniqueFixtureIds': fixtureIds.length,
        'uniqueRawLines': rawLines.length,
        'caseTypes': caseTypes.toList()..sort(),
        'merchants': merchants.toList()..sort(),
        'riskTags': riskTags.toList()..sort(),
        'localeIds': localeIds.toList()..sort(),
        'expectedMatchCount': expectedMatchCount,
        'unknownOrReviewCount': unknownOrReviewCount,
      },
    );
  }

  void _requireContains(
    List<QaFailure> failures,
    Set<String> values,
    String expected, {
    required String idPrefix,
    required String message,
  }) {
    if (values.contains(expected)) return;
    failures.add(
      QaFailure(
        suite: name,
        id: '$idPrefix:$expected',
        message: message,
        expected: expected,
        actual: values.where((value) => value.isNotEmpty).join(', '),
        suggestedFix:
            'Add fixture coverage before treating the corpus as release-ready.',
        metadata: const {'triageCategory': QaFailureTriage.fixture},
      ),
    );
  }

  void _require(
    List<QaFailure> failures,
    bool condition, {
    required String id,
    required String message,
    required String expected,
    required String actual,
  }) {
    if (condition) return;
    failures.add(
      QaFailure(
        suite: name,
        id: id,
        message: message,
        expected: expected,
        actual: actual,
        suggestedFix:
            'Keep golden parser fixtures stable, unique, privacy-safe, and suitable for regression evidence.',
        metadata: const {'triageCategory': QaFailureTriage.fixture},
      ),
    );
  }
}

String _normalize(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
