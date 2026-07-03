import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserNextActionSuite extends QaSuite {
  const WorkSupplyParserNextActionSuite()
    : super('inventory.next_action_contract');

  static const _requiredTokens = {
    'QA_NEXT_ACTION',
    'QA_NEXT_ACTION_ARTIFACT',
    'readyForNextBatch',
    'releaseOneCellCount',
    'activeWaveCount',
    'activeWaves',
    'activeWaveUnsafeFindings',
    'activeWaveStatusStale',
    'activeWaveCellStale',
    'activeWaveFailedCells',
    'hasFailedCells',
    'maxStatusAgeMs',
    'maxActiveCellMs',
    'jsonReadError',
    'activeWaveStatusReadError',
    'missingArtifactNames',
    'unsafeFindings',
    'liveServicesAllowed',
    'writesProductionCatalog',
    'firebaseWritesAllowed',
    'ocrCameraExpensesTouched',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source =
        [
              File('tool/work_supply_parser_qa_next_action.dart'),
              File('test/work_supply_parser_qa_next_action_test.dart'),
            ]
            .where((file) => file.existsSync())
            .map((file) => file.readAsStringSync())
            .join('\n');

    for (final token in _requiredTokens) {
      if (source.contains(token)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_next_action_token:$token',
          message: 'Next-action planning contract token is missing.',
          severity: QaSeverity.error,
          expected: token,
          actual: 'not found',
          suggestedFix:
              'Keep local next-action artifacts wired so parser QA can continue without rerunning expensive Flutter batches.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: _requiredTokens.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'requiredTokens': _requiredTokens.toList()..sort(),
        'contract':
            'Parser QA continuation must be driven by local evidence, missing artifacts, unsafe flags, active wave state, and release-one cell coverage.',
      },
    );
  }
}
