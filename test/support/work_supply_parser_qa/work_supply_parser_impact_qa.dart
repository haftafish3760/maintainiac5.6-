import 'dart:convert';
import 'dart:io';

import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserChangedItemImpactSuite extends QaSuite {
  const WorkSupplyParserChangedItemImpactSuite()
    : super('inventory.changed_item_impact');

  static const _impactBaselinePath =
      'test/fixtures/work_supply_parser/baselines/changed_item_impact_baseline.json';

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final fixtures = _loadFixtures()
        .where((fixture) => fixture.hasExpectedCatalogEvidence)
        .toList(growable: false);
    final fixtureById = {for (final fixture in fixtures) fixture.id: fixture};
    final impactBaseline = _loadImpactBaseline();
    final baselineByFixture = {
      for (final baseline in impactBaseline) baseline.fixtureId: baseline,
    };
    if (!context.isFullProfile) {
      _checkImpactBaselineReferences(
        failures: failures,
        impactBaseline: impactBaseline,
        fixtureById: fixtureById,
      );
      return timer.finish(
        suite: name,
        checked: fixtures.length + impactBaseline.length,
        failures: failures,
        maxFailures: context.maxFailuresPerSuite,
        metrics: {
          'mode': 'impact-baseline-smoke',
          'fixtureEvidenceCount': fixtures.length,
          'impactBaselinePath': _impactBaselinePath,
          'impactBaselineEntries': impactBaseline.length,
          'oldNewRankedCandidateComparisons': 0,
          'catalogLoaded': false,
          'note':
              'Catalog ranked-candidate signature comparisons run in full/release profiles.',
        },
      );
    }
    final catalogIndex = _CatalogIndex(workSupplyCatalogItems);
    final protectedFamilies = <String>{};
    final protectedItems = <String>{};
    final fixturesByFamily = <String, Set<String>>{};
    var candidateTotal = 0;
    var widestCandidateSet = 0;
    var baselineComparisons = 0;

    _checkImpactBaselineReferences(
      failures: failures,
      impactBaseline: impactBaseline,
      fixtureById: fixtureById,
    );

    for (final fixture in fixtures) {
      final baseline = baselineByFixture[fixture.id];
      final candidates = catalogIndex.findCandidates(
        fixture,
        expectedNameOverride: baseline?.expectedTopCandidateContains,
      );
      candidateTotal += candidates.length;
      if (candidates.length > widestCandidateSet) {
        widestCandidateSet = candidates.length;
      }
      if (candidates.isEmpty) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'fixture_without_catalog_impact:${fixture.id}',
            message:
                'Fixture expected evidence does not map to any catalog item.',
            expected:
                '${fixture.expectedTrade} item containing ${fixture.expectedNameContains}',
            actual: '0 catalog candidates',
            suggestedFix:
                'Add or repair catalog item metadata before trusting this fixture as a regression guard.',
            metadata: {
              'fixtureId': fixture.id,
              'caseType': fixture.caseType,
              'expectedTrade': fixture.expectedTrade,
              'expectedNameContains': fixture.expectedNameContains,
            },
          ),
        );
        continue;
      }

      for (final item in candidates) {
        protectedItems.add(item.id);
        final family = _familyKey(item);
        protectedFamilies.add(family);
        fixturesByFamily.putIfAbsent(family, () => <String>{}).add(fixture.id);
      }
    }

    for (final baseline in impactBaseline) {
      baselineComparisons++;
      final fixture = fixtureById[baseline.fixtureId];
      if (fixture == null) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'impact_baseline_missing_fixture:${baseline.fixtureId}',
            message:
                'Changed-item impact baseline references a missing fixture.',
            expected: baseline.fixtureId,
            actual: 'not found',
            suggestedFix:
                'Restore the protected golden fixture or update the reviewed impact baseline.',
          ),
        );
        continue;
      }
      final candidates = catalogIndex.findCandidates(
        fixture,
        expectedNameOverride: baseline.expectedTopCandidateContains,
      );
      final rankedSignatures = _rankedSignatures(candidates);
      final expected = _normalize(baseline.expectedTopCandidateContains);
      final hasExpectedCandidate = rankedSignatures.any(
        (signature) => signature.contains(expected),
      );
      if (!hasExpectedCandidate) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'impact_ranked_candidate_changed:${baseline.fixtureId}',
            message:
                'Protected fixture lost its reviewed ranked candidate signature.',
            expected: baseline.expectedTopCandidateContains,
            actual: rankedSignatures.take(8).join(' | '),
            suggestedFix:
                'Review catalog/parser changes for this protected item family before accepting the new impact baseline.',
            metadata: {
              'fixtureId': baseline.fixtureId,
              'expectedTrade': baseline.expectedTrade,
              'baselinePath': _impactBaselinePath,
            },
          ),
        );
      }
      if (candidates.length > baseline.maxCandidateCount) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'impact_candidate_set_widened:${baseline.fixtureId}',
            message:
                'Protected fixture candidate set widened beyond reviewed baseline budget.',
            severity: QaSeverity.warning,
            expected: '<= ${baseline.maxCandidateCount}',
            actual: '${candidates.length}',
            suggestedFix:
                'Check alias breadth and negative-match rules before accepting a wider ranked candidate set.',
          ),
        );
      }
    }

    return timer.finish(
      suite: name,
      checked: fixtures.length + impactBaseline.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'fixtureEvidenceCount': fixtures.length,
        'candidateTotal': candidateTotal,
        'widestCandidateSet': widestCandidateSet,
        'protectedItemCount': protectedItems.length,
        'protectedFamilyCount': protectedFamilies.length,
        'impactBaselinePath': _impactBaselinePath,
        'oldNewRankedCandidateComparisons': baselineComparisons,
        'protectedFamilies': protectedFamilies.toList()..sort(),
        'fixturesByFamily': {
          for (final entry in fixturesByFamily.entries)
            entry.key: entry.value.toList()..sort(),
        },
      },
    );
  }

  String _familyKey(WorkSupplyItem item) {
    return [
      item.trade,
      item.category,
      item.system,
      item.itemType,
    ].map(_normalize).join('/');
  }

  List<String> _rankedSignatures(List<WorkSupplyItem> candidates) {
    final sorted = [...candidates]
      ..sort((left, right) {
        final priority = _priorityRank(left).compareTo(_priorityRank(right));
        if (priority != 0) return priority;
        return _normalize(left.name).compareTo(_normalize(right.name));
      });
    return [
      for (final item in sorted)
        [
          item.id,
          item.trade,
          item.category,
          item.system,
          item.itemType,
          item.name,
        ].map(_normalize).join('|'),
    ];
  }

  int _priorityRank(WorkSupplyItem item) {
    switch (item.parserPriority.name) {
      case 'everydayCore':
        return 0;
      case 'common':
        return 1;
      case 'occasional':
        return 2;
      case 'rareLegacy':
        return 3;
      case 'specialty':
        return 4;
    }
    return 5;
  }

  void _checkImpactBaselineReferences({
    required List<QaFailure> failures,
    required List<_ImpactBaseline> impactBaseline,
    required Map<String, _ImpactFixture> fixtureById,
  }) {
    for (final baseline in impactBaseline) {
      final fixture = fixtureById[baseline.fixtureId];
      if (fixture == null) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'impact_baseline_missing_fixture:${baseline.fixtureId}',
            message:
                'Changed-item impact baseline references a missing fixture.',
            expected: baseline.fixtureId,
            actual: 'not found',
            suggestedFix:
                'Restore the protected golden fixture or update the reviewed impact baseline.',
          ),
        );
        continue;
      }
      if (_normalize(baseline.expectedTopCandidateContains).isEmpty) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'impact_baseline_missing_signature:${baseline.fixtureId}',
            message:
                'Changed-item impact baseline is missing a ranked candidate signature.',
            expected: 'expectedTopCandidateContains',
            actual: 'empty',
            suggestedFix:
                'Add a reviewed protected candidate signature before using this fixture for impact diffs.',
          ),
        );
      }
    }
  }
}

class _CatalogIndex {
  _CatalogIndex(List<WorkSupplyItem> items)
    : _records = [
        for (final item in items)
          _CatalogRecord(
            item: item,
            normalizedTrade: _normalize(item.trade),
            normalizedName: _normalize(item.name),
            normalizedSearchableText: _normalize(item.searchableText),
          ),
      ];

  final List<_CatalogRecord> _records;

  List<WorkSupplyItem> findCandidates(
    _ImpactFixture fixture, {
    String? expectedNameOverride,
  }) {
    final expectedTrade = _normalize(fixture.expectedTrade);
    final expectedName = _normalize(
      expectedNameOverride?.trim().isNotEmpty == true
          ? expectedNameOverride!
          : fixture.expectedNameContains,
    );
    if (expectedTrade.isEmpty || expectedName.isEmpty) return const [];
    return [
      for (final record in _records)
        if (record.normalizedTrade == expectedTrade &&
            (record.normalizedName.contains(expectedName) ||
                record.normalizedSearchableText.contains(expectedName)))
          record.item,
    ];
  }
}

class _CatalogRecord {
  const _CatalogRecord({
    required this.item,
    required this.normalizedTrade,
    required this.normalizedName,
    required this.normalizedSearchableText,
  });

  final WorkSupplyItem item;
  final String normalizedTrade;
  final String normalizedName;
  final String normalizedSearchableText;
}

class _ImpactFixture {
  const _ImpactFixture({
    required this.id,
    required this.caseType,
    required this.expectedTrade,
    required this.expectedNameContains,
  });

  final String id;
  final String caseType;
  final String expectedTrade;
  final String expectedNameContains;

  bool get hasExpectedCatalogEvidence {
    return expectedTrade.trim().isNotEmpty &&
        expectedNameContains.trim().isNotEmpty;
  }

  static _ImpactFixture fromJson(Map<String, Object?> json) {
    return _ImpactFixture(
      id: json['id'] as String? ?? 'fixture_without_id',
      caseType: json['caseType'] as String? ?? '',
      expectedTrade: json['expectedTrade'] as String? ?? '',
      expectedNameContains: json['expectedNameContains'] as String? ?? '',
    );
  }
}

List<_ImpactFixture> _loadFixtures() {
  final file = File('test/fixtures/work_supply_parser/golden_fixtures.json');
  if (!file.existsSync()) return const [];
  final decoded = jsonDecode(file.readAsStringSync()) as List<dynamic>;
  return [
    for (final entry in decoded)
      _ImpactFixture.fromJson((entry as Map).cast<String, Object?>()),
  ];
}

List<_ImpactBaseline> _loadImpactBaseline() {
  final file = File(
    'test/fixtures/work_supply_parser/baselines/changed_item_impact_baseline.json',
  );
  if (!file.existsSync()) return const [];
  final decoded = jsonDecode(file.readAsStringSync()) as List<dynamic>;
  return [
    for (final entry in decoded)
      _ImpactBaseline.fromJson((entry as Map).cast<String, Object?>()),
  ];
}

class _ImpactBaseline {
  const _ImpactBaseline({
    required this.fixtureId,
    required this.expectedTrade,
    required this.expectedTopCandidateContains,
    required this.maxCandidateCount,
  });

  final String fixtureId;
  final String expectedTrade;
  final String expectedTopCandidateContains;
  final int maxCandidateCount;

  static _ImpactBaseline fromJson(Map<String, Object?> json) {
    return _ImpactBaseline(
      fixtureId: json['fixtureId'] as String? ?? '',
      expectedTrade: json['expectedTrade'] as String? ?? '',
      expectedTopCandidateContains:
          json['expectedTopCandidateContains'] as String? ?? '',
      maxCandidateCount: (json['maxCandidateCount'] as num?)?.toInt() ?? 24,
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
