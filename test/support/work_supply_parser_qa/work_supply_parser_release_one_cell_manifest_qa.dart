import '../qa_harness/qa_harness.dart';

class WorkSupplyParserReleaseOneCellManifestSuite extends QaSuite {
  const WorkSupplyParserReleaseOneCellManifestSuite()
    : super('inventory.release_one_cell_manifest');

  static const priorityCells = {
    'plumbing.residential.core.en-US',
    'plumbing.residential.core.es-US',
    'plumbing.residential.standard.en-US',
    'plumbing.residential.standard.es-US',
    'electrical.residential.core.en-US',
    'electrical.residential.core.es-US',
    'electrical.residential.standard.en-US',
    'electrical.residential.standard.es-US',
    'hvac.residential.core.en-US',
    'hvac.residential.core.es-US',
    'hvac.residential.standard.en-US',
    'hvac.residential.standard.es-US',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final seen = <String>{};
    final tradeCounts = <String, int>{};
    final localeCounts = <String, int>{};
    final tierCounts = <String, int>{};

    for (final cell in priorityCells) {
      if (!seen.add(cell)) {
        failures.add(
          _failure(
            id: 'duplicate_release_one_cell:$cell',
            message: 'Release-one priority cell is duplicated.',
            actual: cell,
          ),
        );
      }
      final parts = cell.split('.');
      if (parts.length != 4) {
        failures.add(
          _failure(
            id: 'invalid_release_one_cell:$cell',
            message:
                'Release-one priority cell must be trade.scope.tier.locale.',
            actual: cell,
          ),
        );
        continue;
      }
      _increment(tradeCounts, parts[0]);
      _increment(tierCounts, parts[2]);
      _increment(localeCounts, parts[3]);
    }

    for (final required in ['plumbing', 'electrical', 'hvac']) {
      if (tradeCounts.containsKey(required)) continue;
      failures.add(
        _failure(
          id: 'missing_release_one_trade:$required',
          message: 'Release-one priority manifest is missing a trade.',
          actual: tradeCounts.keys.join(', '),
        ),
      );
    }
    for (final required in ['en-US', 'es-US']) {
      if (localeCounts.containsKey(required)) continue;
      failures.add(
        _failure(
          id: 'missing_release_one_locale:$required',
          message: 'Release-one priority manifest is missing a locale.',
          actual: localeCounts.keys.join(', '),
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: priorityCells.length + 5,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'priorityCells': priorityCells.toList()..sort(),
        'tradeCounts': tradeCounts,
        'tierCounts': tierCounts,
        'localeCounts': localeCounts,
      },
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
          'Residential Plumbing/Electrical/HVAC Core+Standard in en-US and es-US',
      actual: actual,
      suggestedFix:
          'Keep the release-one priority cell manifest explicit so batch generation and QA do not drift.',
      metadata: const {'triageCategory': QaFailureTriage.governance},
    );
  }
}

void _increment(Map<String, int> counts, String key) {
  counts.update(key, (count) => count + 1, ifAbsent: () => 1);
}
