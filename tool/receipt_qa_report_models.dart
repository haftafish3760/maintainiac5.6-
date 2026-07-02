part of 'receipt_qa_runner.dart';

class _ReceiptQaReport {
  const _ReceiptQaReport({
    required this.pack,
    required this.availablePacks,
    required this.score,
    required this.fixtures,
    required this.fixtureFieldCoverage,
    required this.blockers,
  });

  final String pack;
  final List<String> availablePacks;
  final double score;
  final List<_ReceiptFixtureReport> fixtures;
  final Map<String, Object?> fixtureFieldCoverage;
  final List<String> blockers;

  String get summary {
    return 'Receipt QA pack=$pack fixtures=${fixtures.length} '
        'score=${(score * 100).toStringAsFixed(1)}%';
  }

  Map<String, Object?> toJson({double? failUnder}) {
    return {
      'pack': pack,
      'availablePacks': availablePacks,
      'score': score,
      'fixtureCount': fixtures.length,
      'fixtureManifest': _fixtureManifestToJson(availablePacks),
      'fixtureFieldCoverage': fixtureFieldCoverage,
      'checkCount': _checkCount,
      'passedCheckCount': _passedCheckCount,
      'failedCheckCount': _checkCount - _passedCheckCount,
      'dimensionScores': _dimensionScores(),
      'fieldOutcomeCounts': _fieldOutcomeCounts(),
      'packScores': _packScores(),
      'fixtures': fixtures.map((fixture) => fixture.toJson()).toList(),
      'blockers': failUnder == null ? blockers : blockersFor(failUnder),
    };
  }

  Map<String, Object?> toSummaryJson({double? failUnder}) {
    final blockers = failUnder == null ? this.blockers : blockersFor(failUnder);
    return {
      'pack': pack,
      'availablePacks': availablePacks,
      'score': score,
      'fixtureCount': fixtures.length,
      'fixtureManifest': _fixtureManifestToJson(availablePacks),
      'fixtureFieldCoverage': fixtureFieldCoverage,
      'checkCount': _checkCount,
      'passedCheckCount': _passedCheckCount,
      'failedCheckCount': _checkCount - _passedCheckCount,
      'dimensionScores': _dimensionScores(),
      'fieldOutcomeCounts': _fieldOutcomeCounts(),
      'packScores': _packScores(),
      'failedFixtures': [
        for (final fixture in fixtures)
          if (fixture.issues.isNotEmpty)
            {
              'pack': fixture.pack,
              'name': fixture.name,
              'score': fixture.score,
              'issues': fixture.issues,
            },
      ],
      'blockers': blockers,
    };
  }

  List<String> blockersFor(double failUnder) {
    final qualityBlockers = <String>[];
    void addScoreBlocker(String scope, String name, double actual) {
      qualityBlockers.add(
        '$scope `$name` scored ${(actual * 100).toStringAsFixed(1)}%, below '
        'required ${(failUnder * 100).toStringAsFixed(1)}%.',
      );
    }

    if (score < failUnder) addScoreBlocker('overall', pack, score);
    for (final entry in _packScores().entries) {
      if (entry.value < failUnder) {
        addScoreBlocker('pack', entry.key, entry.value);
      }
    }
    for (final entry in _dimensionScores().entries) {
      if (entry.value < failUnder) {
        addScoreBlocker('dimension', entry.key, entry.value);
      }
    }
    for (final fixture in fixtures) {
      if (fixture.score < failUnder) {
        addScoreBlocker(
          'fixture',
          '${fixture.pack}/${fixture.name}',
          fixture.score,
        );
      }
    }
    return [...blockers, ...qualityBlockers];
  }

  Map<String, double> _dimensionScores() {
    final totals = <String, int>{};
    final passes = <String, int>{};
    for (final fixture in fixtures) {
      for (final check in fixture.checks) {
        totals[check.dimension] = (totals[check.dimension] ?? 0) + 1;
        if (check.passed) {
          passes[check.dimension] = (passes[check.dimension] ?? 0) + 1;
        }
      }
    }
    return {
      for (final entry in totals.entries)
        entry.key: (passes[entry.key] ?? 0) / entry.value,
    };
  }

  Map<String, Map<String, int>> _fieldOutcomeCounts() {
    final counts = <String, Map<String, int>>{};
    for (final fixture in fixtures) {
      for (final check in fixture.checks) {
        final field = check.fieldName;
        final outcome = check.outcomeName;
        counts.putIfAbsent(field, () => <String, int>{});
        counts[field]![outcome] = (counts[field]![outcome] ?? 0) + 1;
      }
    }
    for (final fieldCounts in counts.values) {
      for (final outcome in const [
        'exact_match',
        'acceptable_normalized_match',
        'missed',
        'false_positive',
        'privacy_violation',
      ]) {
        fieldCounts.putIfAbsent(outcome, () => 0);
      }
    }
    return counts;
  }

  int get _checkCount {
    return fixtures.fold<int>(
      0,
      (total, fixture) => total + fixture.checks.length,
    );
  }

  int get _passedCheckCount {
    return fixtures.fold<int>(0, (total, fixture) {
      return total + fixture.checks.where((check) => check.passed).length;
    });
  }

  Map<String, double> _packScores() {
    final grouped = <String, List<_ReceiptFixtureReport>>{};
    for (final fixture in fixtures) {
      grouped.putIfAbsent(fixture.pack, () => []).add(fixture);
    }
    return {
      for (final entry in grouped.entries)
        entry.key:
            entry.value
                .map((fixture) => fixture.score)
                .reduce((a, b) => a + b) /
            entry.value.length,
    };
  }
}

class _ReceiptFixtureReport {
  const _ReceiptFixtureReport({
    required this.name,
    required this.pack,
    required this.score,
    required this.issues,
    required this.checks,
  });

  final String name;
  final String pack;
  final double score;
  final List<String> issues;
  final List<_ReceiptQaCheck> checks;

  String get summary {
    return '${(score * 100).toStringAsFixed(1).padLeft(5)}%  [$pack] $name';
  }

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'pack': pack,
      'score': score,
      'issues': issues,
      'checks': checks.map((check) => check.toJson()).toList(),
    };
  }
}

class _ReceiptQaCheck {
  const _ReceiptQaCheck({
    required this.dimension,
    required this.name,
    required this.passed,
  });

  final String dimension;
  final String name;
  final bool passed;

  Map<String, Object?> toJson() {
    return {
      'dimension': dimension,
      'field': fieldName,
      'name': name,
      'passed': passed,
      'outcome': outcomeName,
    };
  }

  String get fieldName {
    if (name.contains('merchant')) return 'merchant';
    if (name.contains('date')) return 'date';
    if (name.contains('subtotal')) return 'subtotal';
    if (name.contains('tax')) return 'tax';
    if (name.contains('total')) return 'total';
    if (name.contains('fuel')) return 'fuel';
    if (name.contains('maintenance')) return 'maintenance';
    if (dimension == 'business_personal' ||
        name.contains('business') ||
        name.contains('personal') ||
        name.contains('allocation')) {
      return 'business_personal';
    }
    if (name.contains('line_')) return 'line_items';
    if (name.contains('photo_quality') || name.contains('bottom_total')) {
      return 'capture_quality';
    }
    if (dimension == 'privacy_admin' || name.contains('sensitive')) {
      return 'privacy_admin';
    }
    if (dimension == 'device_storage' || name.contains('budget')) {
      return 'device_storage';
    }
    if (name.contains('readiness') || name.contains('parser_task')) {
      return 'parser_readiness';
    }
    return dimension;
  }

  String get outcomeName {
    if (passed && name.contains('normalized')) {
      return 'acceptable_normalized_match';
    }
    if (passed) return 'exact_match';
    if (fieldName == 'privacy_admin') return 'privacy_violation';
    if (name.contains('exclusion') || name.contains('false_positive')) {
      return 'false_positive';
    }
    return 'missed';
  }
}
