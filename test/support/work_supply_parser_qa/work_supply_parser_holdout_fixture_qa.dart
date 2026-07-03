import 'dart:convert';
import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserHoldoutFixtureSuite extends QaSuite {
  const WorkSupplyParserHoldoutFixtureSuite()
    : super('inventory.holdout_fixture_contract');

  static const _goldenPath =
      'test/fixtures/work_supply_parser/golden_fixtures.json';
  static const _holdoutPath =
      'test/fixtures/work_supply_parser/holdout_fixtures.json';

  static const _requiredCaseTypes = {
    'clear_match',
    'ambiguous_review',
    'receipt_noise',
  };

  static const _requiredRiskTags = {
    'holdout',
    'merchant_abbreviation',
    'cross_trade',
    'privacy',
    'spanish',
    'canadian_format',
  };

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
    final golden = _loadFixtureFile(_goldenPath, failures);
    final holdout = _loadFixtureFile(_holdoutPath, failures);
    final goldenIds = {for (final fixture in golden) fixture.id};
    final goldenRawLines = {
      for (final fixture in golden) _normalize(fixture.rawLine),
    };
    final holdoutIds = <String>{};
    final holdoutRawLines = <String>{};
    final caseTypes = <String>{};
    final riskTags = <String>{};
    var expectedMatchCount = 0;
    var reviewCount = 0;

    for (final fixture in holdout) {
      caseTypes.add(fixture.caseType);
      riskTags.addAll(fixture.riskTags);
      if (fixture.hasExpectedMatch) expectedMatchCount++;
      if (fixture.expectUnknown) reviewCount++;

      _require(
        failures,
        fixture.holdoutOnly,
        id: 'holdout_flag_missing:${fixture.id}',
        message: 'Holdout fixture must be explicitly marked holdoutOnly.',
        expected: 'holdoutOnly=true',
        actual: '${fixture.holdoutOnly}',
      );
      _require(
        failures,
        holdoutIds.add(fixture.id),
        id: 'duplicate_holdout_id:${fixture.id}',
        message: 'Holdout fixture id is duplicated.',
        expected: 'unique id',
        actual: fixture.id,
      );
      _require(
        failures,
        !goldenIds.contains(fixture.id),
        id: 'holdout_id_also_in_golden:${fixture.id}',
        message: 'Holdout fixture id is also present in golden fixtures.',
        expected: 'holdout-only fixture id',
        actual: fixture.id,
      );
      final normalizedRawLine = _normalize(fixture.rawLine);
      _require(
        failures,
        holdoutRawLines.add(normalizedRawLine),
        id: 'duplicate_holdout_raw_line:${fixture.id}',
        message: 'Holdout fixture rawLine is duplicated.',
        expected: 'unique holdout rawLine',
        actual: context.redactor(fixture.rawLine),
      );
      _require(
        failures,
        !goldenRawLines.contains(normalizedRawLine),
        id: 'holdout_raw_line_also_in_golden:${fixture.id}',
        message:
            'Holdout fixture rawLine duplicates golden/tuning fixture text.',
        expected: 'independent holdout text',
        actual: context.redactor(fixture.rawLine),
      );
      for (final pattern in _privatePatterns.entries) {
        if (!pattern.value.hasMatch(fixture.rawLine)) continue;
        failures.add(
          QaFailure(
            suite: name,
            id: 'holdout_private_token:${pattern.key}:${fixture.id}',
            message:
                'Holdout fixture rawLine contains private-looking data instead of synthetic text.',
            expected: 'privacy-safe synthetic holdout text',
            actual: context.redactor(fixture.rawLine),
            suggestedFix:
                'Replace private-looking holdout text with synthetic non-user data.',
            metadata: const {'triageCategory': QaFailureTriage.privacy},
          ),
        );
      }
    }

    for (final type in _requiredCaseTypes) {
      _require(
        failures,
        caseTypes.contains(type),
        id: 'holdout_missing_case_type:$type',
        message: 'Holdout fixture set is missing a required case type.',
        expected: type,
        actual: caseTypes.join(', '),
      );
    }
    for (final tag in _requiredRiskTags) {
      _require(
        failures,
        riskTags.contains(tag),
        id: 'holdout_missing_risk_tag:$tag',
        message: 'Holdout fixture set is missing a required risk tag.',
        expected: tag,
        actual: riskTags.join(', '),
      );
    }
    _require(
      failures,
      expectedMatchCount > 0,
      id: 'holdout_missing_expected_matches',
      message: 'Holdout fixture set has no expected-match cases.',
      expected: '> 0',
      actual: '$expectedMatchCount',
    );
    _require(
      failures,
      reviewCount > 0,
      id: 'holdout_missing_review_cases',
      message: 'Holdout fixture set has no review/unknown cases.',
      expected: '> 0',
      actual: '$reviewCount',
    );

    return timer.finish(
      suite: name,
      checked:
          holdout.length +
          _requiredCaseTypes.length +
          _requiredRiskTags.length +
          2,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'goldenFixturePath': _goldenPath,
        'holdoutFixturePath': _holdoutPath,
        'holdoutFixtureCount': holdout.length,
        'caseTypes': caseTypes.toList()..sort(),
        'riskTags': riskTags.toList()..sort(),
        'expectedMatchCount': expectedMatchCount,
        'reviewCount': reviewCount,
        'parserCalls': 0,
        'releaseOnlySemanticUse': true,
      },
    );
  }

  List<_HoldoutFixture> _loadFixtureFile(
    String path,
    List<QaFailure> failures,
  ) {
    final file = File(path);
    if (!file.existsSync()) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_holdout_fixture_file:$path',
          message: 'Fixture file needed for holdout validation is missing.',
          expected: path,
          actual: 'not found',
          suggestedFix:
              'Restore the golden/holdout fixture file before release validation.',
          metadata: const {'triageCategory': QaFailureTriage.fixture},
        ),
      );
      return const [];
    }
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! List) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'holdout_fixture_file_not_list:$path',
          message: 'Fixture file must be a JSON array.',
          expected: 'JSON array',
          actual: decoded.runtimeType.toString(),
          metadata: const {'triageCategory': QaFailureTriage.fixture},
        ),
      );
      return const [];
    }
    return [
      for (final entry in decoded)
        if (entry is Map)
          _HoldoutFixture.fromJson(entry.cast<String, Object?>()),
    ];
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
            'Keep holdout validation independent, privacy-safe, and release-only before trusting broad parser accuracy claims.',
        metadata: const {'triageCategory': QaFailureTriage.fixture},
      ),
    );
  }
}

class _HoldoutFixture {
  const _HoldoutFixture({
    required this.id,
    required this.caseType,
    required this.rawLine,
    required this.riskTags,
    required this.holdoutOnly,
    required this.expectUnknown,
    required this.expectedTrade,
    required this.expectedNameContains,
  });

  final String id;
  final String caseType;
  final String rawLine;
  final List<String> riskTags;
  final bool holdoutOnly;
  final bool expectUnknown;
  final String expectedTrade;
  final String expectedNameContains;

  bool get hasExpectedMatch {
    return expectedTrade.trim().isNotEmpty ||
        expectedNameContains.trim().isNotEmpty;
  }

  static _HoldoutFixture fromJson(Map<String, Object?> json) {
    return _HoldoutFixture(
      id: json['id'] as String? ?? 'fixture_without_id',
      caseType: json['caseType'] as String? ?? '',
      rawLine: json['rawLine'] as String? ?? '',
      riskTags: [
        for (final tag in json['riskTags'] as List<dynamic>? ?? const [])
          tag.toString(),
      ],
      holdoutOnly: json['holdoutOnly'] == true,
      expectUnknown: json['expectUnknown'] == true,
      expectedTrade: json['expectedTrade'] as String? ?? '',
      expectedNameContains: json['expectedNameContains'] as String? ?? '',
    );
  }
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9/]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
