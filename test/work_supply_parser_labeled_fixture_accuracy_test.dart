import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test(
    'reports actual PEH labeled-fixture matcher accuracy without making a release claim',
    () {
      final report = _scorePehFixtures();

      expect(report.fixtureCount, greaterThan(0));
      expect(
        report.fixtureCountByTrade.keys,
        containsAll(report.selectedTrades),
      );
      expect(
        report.invalidFixtureIds,
        isEmpty,
        reason:
            'Every measured fixture needs a complete expected-result label.',
      );

      // This is deliberately a measurement test, not a release threshold.
      // The checked-in corpus is small and synthetic; passing it cannot prove
      // the 92–95% supported-receipt accuracy target by itself.
      // ignore: avoid_print
      print(report.toMachineReadableSummary());
    },
  );
}

const _pehTrades = {'plumbing', 'electrical', 'hvac'};
const _matchedStatus = 'matched';
const _reviewStatus = 'needsreview';
const _unknownStatus = 'unknown';
const _minimumClaimFixturesPerTrade = 100;
const _minimumClaimAccuracyPerTrade = .92;
const _independentSourceTypes = {
  'anonymizedreal',
  'reviewedreal',
  'redactedreal',
};

_PehFixtureAccuracyReport _scorePehFixtures() {
  final allFixtures = [
    ..._loadFixtures('test/fixtures/work_supply_parser/golden_fixtures.json'),
    ..._loadFixtures('test/fixtures/work_supply_parser/holdout_fixtures.json'),
  ].where((fixture) => _pehTrades.contains(fixture.trade)).toList();
  final fixtures = _selectedFixtures(allFixtures);

  final outcomes = <_PehFixtureOutcome>[];
  final invalidFixtureIds = <String>[];
  for (final fixture in fixtures) {
    final missing = fixture.missingRequiredFields;
    if (missing.isNotEmpty) {
      invalidFixtureIds.add('${fixture.id}:${missing.join(',')}');
      continue;
    }
    final match = matchReceiptLineToCatalog(
      fixture.rawLine,
      tradeScope: fixture.tradeScope,
      localePackId: fixture.localePackId,
      maxCandidates: 24,
    );
    outcomes.add(_PehFixtureOutcome.fromMatch(fixture, match));
  }

  return _PehFixtureAccuracyReport(
    outcomes: outcomes,
    invalidFixtureIds: invalidFixtureIds,
  );
}

List<_PehFixture> _selectedFixtures(List<_PehFixture> fixtures) {
  const mode = String.fromEnvironment(
    'PARSER_QA_LABELED_FIXTURE_MODE',
    defaultValue: 'smoke',
  );
  const ids = String.fromEnvironment('PARSER_QA_LABELED_FIXTURE_IDS');
  final requestedIds = ids
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet();
  if (requestedIds.isNotEmpty) {
    return [
      for (final fixture in fixtures)
        if (requestedIds.contains(fixture.id)) fixture,
    ];
  }
  if (mode == 'full') return fixtures;
  return [
    for (final trade in _pehTrades)
      fixtures.firstWhere(
        (fixture) =>
            fixture.trade == trade && fixture.expectedStatus == _matchedStatus,
      ),
  ];
}

List<_PehFixture> _loadFixtures(String path) {
  final file = File(path);
  if (!file.existsSync()) return const [];
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! List) return const [];
  return [
    for (final entry in decoded)
      if (entry is Map)
        _PehFixture.fromJson(entry.cast<String, Object?>(), sourcePath: path),
  ];
}

class _PehFixture {
  const _PehFixture({
    required this.id,
    required this.sourcePath,
    required this.trade,
    required this.rawLine,
    required this.expectedStatus,
    required this.expectedTopCandidateId,
    required this.expectedReviewRequired,
    required this.expectedCandidateTrade,
    required this.expectedConfidenceBand,
    required this.expectedTrade,
    required this.expectedNameContains,
    required this.tradeScope,
    required this.localePackId,
    required this.sourceType,
  });

  final String id;
  final String sourcePath;
  final String trade;
  final String rawLine;
  final String expectedStatus;
  final String expectedTopCandidateId;
  final bool? expectedReviewRequired;
  final String expectedCandidateTrade;
  final String expectedConfidenceBand;
  final String expectedTrade;
  final String expectedNameContains;
  final String? tradeScope;
  final String localePackId;
  final String sourceType;

  List<String> get missingRequiredFields => [
    if (id.trim().isEmpty) 'id',
    if (trade.trim().isEmpty) 'trade',
    if (rawLine.trim().isEmpty) 'rawLine',
    if (expectedStatus.trim().isEmpty) 'expectedStatus',
    if (expectedTopCandidateId.trim().isEmpty) 'expectedTopCandidateId',
    if (expectedReviewRequired == null) 'expectedReviewRequired',
    if (expectedCandidateTrade.trim().isEmpty) 'expectedCandidateTrade',
    if (expectedConfidenceBand.trim().isEmpty) 'expectedConfidenceBand',
  ];

  factory _PehFixture.fromJson(
    Map<String, Object?> json, {
    required String sourcePath,
  }) {
    return _PehFixture(
      id: json['id'] as String? ?? '',
      sourcePath: sourcePath,
      trade: (json['trade'] as String? ?? '').toLowerCase(),
      rawLine: json['rawLine'] as String? ?? '',
      expectedStatus: (json['expectedStatus'] as String? ?? '').toLowerCase(),
      expectedTopCandidateId: json['expectedTopCandidateId'] as String? ?? '',
      expectedReviewRequired: json['expectedReviewRequired'] as bool?,
      expectedCandidateTrade: (json['expectedCandidateTrade'] as String? ?? '')
          .toLowerCase(),
      expectedConfidenceBand: (json['expectedConfidenceBand'] as String? ?? '')
          .toLowerCase(),
      expectedTrade: json['expectedTrade'] as String? ?? '',
      expectedNameContains: json['expectedNameContains'] as String? ?? '',
      tradeScope: json['tradeScope'] as String?,
      localePackId: json['localePackId'] as String? ?? '',
      // Golden fixtures predate sourceType; absence means synthetic until a
      // separately reviewed source type is added.
      sourceType: (json['sourceType'] as String? ?? 'synthetic').toLowerCase(),
    );
  }
}

class _PehFixtureOutcome {
  const _PehFixtureOutcome({
    required this.fixture,
    required this.correct,
    required this.reason,
    required this.actualItemId,
    required this.actualTrade,
  });

  final _PehFixture fixture;
  final bool correct;
  final String reason;
  final String actualItemId;
  final String actualTrade;

  factory _PehFixtureOutcome.fromMatch(
    _PehFixture fixture,
    ReceiptLineMatch? match,
  ) {
    final status = fixture.expectedStatus;
    if (status == _unknownStatus) {
      return _PehFixtureOutcome(
        fixture: fixture,
        correct: match == null,
        reason: match == null ? 'correct_unknown' : 'false_positive',
        actualItemId: match?.item.id ?? '',
        actualTrade: match?.item.trade ?? '',
      );
    }
    if (status == _reviewStatus) {
      return _PehFixtureOutcome(
        fixture: fixture,
        correct: match == null || match.needsReview,
        reason: match == null ? 'safe_no_match' : 'review_required',
        actualItemId: match?.item.id ?? '',
        actualTrade: match?.item.trade ?? '',
      );
    }
    if (status != _matchedStatus || match == null) {
      return _PehFixtureOutcome(
        fixture: fixture,
        correct: false,
        reason: status == _matchedStatus
            ? 'missing_match'
            : 'unsupported_status',
        actualItemId: match?.item.id ?? '',
        actualTrade: match?.item.trade ?? '',
      );
    }

    final tradeCorrect =
        fixture.expectedTrade.isEmpty ||
        _sameText(match.item.trade, fixture.expectedTrade);
    final nameCorrect =
        fixture.expectedNameContains.isEmpty ||
        _normalized(
          match.item.name,
        ).contains(_normalized(fixture.expectedNameContains));
    final semanticIdCorrect = _semanticIdMatches(
      fixture.expectedTopCandidateId,
      '${match.item.id} ${match.item.name} ${match.item.searchableText}',
    );
    final correct = tradeCorrect && nameCorrect && semanticIdCorrect;
    return _PehFixtureOutcome(
      fixture: fixture,
      correct: correct,
      reason: correct
          ? 'correct_match'
          : [
              if (!tradeCorrect) 'wrong_trade',
              if (!nameCorrect) 'wrong_name',
              if (!semanticIdCorrect) 'wrong_candidate_family',
            ].join(','),
      actualItemId: match.item.id,
      actualTrade: match.item.trade,
    );
  }
}

class _PehFixtureAccuracyReport {
  const _PehFixtureAccuracyReport({
    required this.outcomes,
    required this.invalidFixtureIds,
  });

  final List<_PehFixtureOutcome> outcomes;
  final List<String> invalidFixtureIds;

  int get fixtureCount => outcomes.length;

  Set<String> get selectedTrades => {
    for (final outcome in outcomes) outcome.fixture.trade,
  };

  Map<String, int> get fixtureCountByTrade =>
      _countBy(outcomes, (outcome) => outcome.fixture.trade);

  String toMachineReadableSummary() {
    const measurementMode = String.fromEnvironment(
      'PARSER_QA_LABELED_FIXTURE_MODE',
      defaultValue: 'smoke',
    );
    final byTrade = <String, Object?>{};
    final claimBlockers = <String>[];
    for (final trade in _pehTrades) {
      final tradeOutcomes = [
        for (final outcome in outcomes)
          if (outcome.fixture.trade == trade) outcome,
      ];
      final summary = _summaryFor(tradeOutcomes);
      byTrade[trade] = summary;
      final checked = summary['checked']! as int;
      final accuracy = summary['accuracy']! as double;
      if (checked < _minimumClaimFixturesPerTrade) {
        claimBlockers.add(
          '$trade:sample_size_below_$_minimumClaimFixturesPerTrade',
        );
      }
      if (accuracy < _minimumClaimAccuracyPerTrade) {
        claimBlockers.add(
          '$trade:accuracy_below_${_minimumClaimAccuracyPerTrade.toStringAsFixed(2)}',
        );
      }
    }
    final sourceTypes = <String>{
      for (final outcome in outcomes) outcome.fixture.sourceType,
    };
    final isIndependent = sourceTypes.any(_independentSourceTypes.contains);
    if (measurementMode != 'full')
      claimBlockers.add('full_measurement_required');
    if (!isIndependent) {
      claimBlockers.add('no_independent_or_reviewed_real_evidence');
    }
    claimBlockers.add(
      'synthetic_and_checked_in_holdout_results_must_not_be_used_as_release_claims',
    );
    final report = {
      'report': 'work_supply_parser_labeled_fixture_accuracy',
      'measurementMode': measurementMode,
      'fixtureCount': fixtureCount,
      'invalidFixtureIds': invalidFixtureIds,
      'overall': _summaryFor(outcomes),
      'byTrade': byTrade,
      'sourceTypes': sourceTypes.toList()..sort(),
      'releaseClaimThresholds': {
        'minimumFixturesPerTrade': _minimumClaimFixturesPerTrade,
        'minimumAccuracyPerTrade': _minimumClaimAccuracyPerTrade,
        'requiresIndependentEvidence': true,
      },
      'releaseClaimEligible': false,
      'releaseClaimBlockers': claimBlockers,
    };
    return 'PARSER_LABELED_FIXTURE_ACCURACY ${jsonEncode(report)}';
  }

  Map<String, Object?> _summaryFor(List<_PehFixtureOutcome> selected) {
    final correct = selected.where((outcome) => outcome.correct).length;
    final total = selected.length;
    return {
      'checked': total,
      'correct': correct,
      'accuracy': total == 0 ? 0.0 : correct / total,
      'failureReasons': _countBy(
        selected.where((outcome) => !outcome.correct),
        (outcome) => outcome.reason,
      ),
      'failures': [
        for (final outcome in selected)
          if (!outcome.correct)
            {
              'id': outcome.fixture.id,
              'reason': outcome.reason,
              'expectedStatus': outcome.fixture.expectedStatus,
              'expectedCandidate': outcome.fixture.expectedTopCandidateId,
              'actualItemId': outcome.actualItemId,
              'actualTrade': outcome.actualTrade,
            },
      ],
    };
  }
}

Map<String, int> _countBy<T>(Iterable<T> values, String Function(T) keyOf) {
  final counts = <String, int>{};
  for (final value in values) {
    counts.update(keyOf(value), (count) => count + 1, ifAbsent: () => 1);
  }
  return counts;
}

bool _semanticIdMatches(String expected, String actual) {
  if (expected.toLowerCase() == 'unknown') return actual.trim().isEmpty;
  final expectedTokens = _normalized(
    expected,
  ).split(' ').where((token) => token.length >= 3).toSet();
  final actualTokens = _normalized(actual).split(' ').toSet();
  return expectedTokens.isNotEmpty &&
      expectedTokens.every(actualTokens.contains);
}

bool _sameText(String left, String right) =>
    _normalized(left) == _normalized(right);

String _normalized(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .trim()
    .replaceAll(RegExp(r'\s+'), ' ');
