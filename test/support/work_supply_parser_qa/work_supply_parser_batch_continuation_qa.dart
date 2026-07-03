import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserBatchContinuationSuite extends QaSuite {
  const WorkSupplyParserBatchContinuationSuite()
    : super('inventory.batch_continuation_contract');

  static const _requiredTokens = {
    'resume',
    'previousWaveId',
    'accumulatedWaveIds',
    'continueOnFailure',
    'latest_wave_summary.json',
    'queueSummaryPath',
    'liveServicesAllowed',
    'writesProductionCatalog',
    'ocrCameraExpensesTouched',
    'firebaseWritesAllowed',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final waveTool = File('tool/work_supply_parser_qa_batch_wave.dart');
    final queueTool = File('tool/work_supply_parser_qa_background_queue.dart');
    final text = [
      if (waveTool.existsSync()) waveTool.readAsStringSync(),
      if (queueTool.existsSync()) queueTool.readAsStringSync(),
    ].join('\n');

    for (final token in _requiredTokens) {
      if (text.contains(token)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_batch_continuation_token:$token',
          message:
              'Batch QA pipeline is missing a required continuation/resume contract token.',
          severity: QaSeverity.error,
          expected: token,
          actual: 'not found in batch wave/background queue tools',
          suggestedFix:
              'Add continuation-safe batch metadata so verification can finish and the next batch can start without babysitting.',
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
        'requiredContinuationTokens': _requiredTokens.toList()..sort(),
        'contract':
            'Parser QA batch waves must be resumable, accumulated, local-only, and explicit about no OCR/camera/Expenses/Firebase-live work.',
      },
    );
  }
}
