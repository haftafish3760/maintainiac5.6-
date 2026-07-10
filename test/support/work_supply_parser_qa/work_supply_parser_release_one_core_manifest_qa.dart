import '../qa_harness/qa_harness.dart';

class WorkSupplyParserReleaseOneCoreManifestSuite extends QaSuite {
  const WorkSupplyParserReleaseOneCoreManifestSuite()
    : super('inventory.release_one_core_manifest');

  static const expectedCoreCellCount = 6;
  static const corePriorityCells = {
    'plumbing.residential.core.en-US',
    'plumbing.residential.core.es-US',
    'electrical.residential.core.en-US',
    'electrical.residential.core.es-US',
    'hvac.residential.core.en-US',
    'hvac.residential.core.es-US',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final seen = <String>{};
    final tradeCounts = <String, int>{};
    final localeCounts = <String, int>{};
    final scopeCounts = <String, int>{};
    final tierCounts = <String, int>{};

    if (corePriorityCells.length != expectedCoreCellCount) {
      failures.add(
        _failure(
          id: 'invalid_release_one_core_cell_count',
          message: 'Release-one Core manifest has the wrong cell count.',
          actual: '${corePriorityCells.length}',
        ),
      );
    }

    for (final cell in corePriorityCells) {
      if (!seen.add(cell)) {
        failures.add(
          _failure(
            id: 'duplicate_release_one_core_cell:$cell',
            message: 'Release-one Core cell is duplicated.',
            actual: cell,
          ),
        );
      }
      final parts = cell.split('.');
      if (parts.length != 4) {
        failures.add(
          _failure(
            id: 'invalid_release_one_core_cell:$cell',
            message:
                'Release-one Core cell must be trade.scope.tier.locale.',
            actual: cell,
          ),
        );
        continue;
      }
      _increment(tradeCounts, parts[0]);
      _increment(scopeCounts, parts[1]);
      _increment(tierCounts, parts[2]);
      _increment(localeCounts, parts[3]);
    }

    for (final required in ['plumbing', 'electrical', 'hvac']) {
      if (tradeCounts[required] == 2) continue;
      failures.add(
        _failure(
          id: 'missing_release_one_core_trade:$required',
          message:
              'Release-one Core manifest must include both locales for every priority trade.',
          actual: tradeCounts.toString(),
        ),
      );
    }
    _expectOnly(
      failures,
      id: 'release_one_core_scope_not_residential_only',
      counts: scopeCounts,
      expectedKey: 'residential',
    );
    _expectOnly(
      failures,
      id: 'release_one_core_tier_not_core_only',
      counts: tierCounts,
      expectedKey: 'core',
    );
    for (final required in ['en-US', 'es-US']) {
      if (localeCounts[required] == 3) continue;
      failures.add(
        _failure(
          id: 'missing_release_one_core_locale:$required',
          message:
              'Release-one Core manifest must include every priority trade for each locale.',
          actual: localeCounts.toString(),
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: corePriorityCells.length + 9,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'activeNarrowedScope':
            'Residential Core only for Plumbing, Electrical, and HVAC.',
        'corePriorityCells': corePriorityCells.toList()..sort(),
        'tradeCounts': tradeCounts,
        'scopeCounts': scopeCounts,
        'tierCounts': tierCounts,
        'localeCounts': localeCounts,
        'standardDeferred':
            'Standard remains a later release-one priority after Core evidence is proven.',
      },
    );
  }

  void _expectOnly(
    List<QaFailure> failures, {
    required String id,
    required Map<String, int> counts,
    required String expectedKey,
  }) {
    if (counts.length == 1 && counts.containsKey(expectedKey)) return;
    failures.add(
      _failure(
        id: id,
        message: 'Release-one Core active lane must stay narrowly scoped.',
        actual: counts.toString(),
      ),
    );
  }

  QaFailure _failure({
    required String id,
    required String message,
    required String actual,
  }) {
    return QaFailure(
      suite: name,
      id: id,
      message: message,
      severity: QaSeverity.error,
      expected:
          'Residential Core Plumbing/Electrical/HVAC in en-US and es-US only',
      actual: actual,
      suggestedFix:
          'Keep the active Core lane explicit so QA, fixtures, and catalog expansion do not drift into Standard or unrelated modules.',
      metadata: const {'triageCategory': QaFailureTriage.governance},
    );
  }
}

void _increment(Map<String, int> counts, String key) {
  counts.update(key, (count) => count + 1, ifAbsent: () => 1);
}
