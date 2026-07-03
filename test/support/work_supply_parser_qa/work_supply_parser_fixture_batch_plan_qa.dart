import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserFixtureBatchPlanSuite extends QaSuite {
  const WorkSupplyParserFixtureBatchPlanSuite()
    : super('inventory.fixture_batch_plan_contract');

  static const _tokens = {
    'QA_FIXTURE_BATCH_PLAN',
    'QA_FIXTURE_BATCH_PLAN_ARTIFACT',
    'QA_FIXTURE_BATCH_STATUS',
    'QA_FIXTURE_READINESS_ROLLUP',
    'QA_FIXTURE_READINESS_ROLLUP_ARTIFACT',
    'cellCount',
    'generatedFixtureCount',
    'readyForParserExecution',
    'generateFixturesCommand',
    'missingFixtureCount',
    'runParserCommand',
    'residential',
    'en-US',
    'es-US',
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
              File('tool/work_supply_parser_qa_fixture_batch_plan.dart'),
              File('tool/work_supply_parser_qa_fixture_batch_status.dart'),
              File('tool/work_supply_parser_qa_fixture_readiness_rollup.dart'),
              File('test/work_supply_parser_qa_fixture_batch_plan_test.dart'),
              File('test/work_supply_parser_qa_fixture_batch_status_test.dart'),
              File(
                'test/work_supply_parser_qa_fixture_readiness_rollup_test.dart',
              ),
            ]
            .where((file) => file.existsSync())
            .map((file) => file.readAsStringSync())
            .join('\n');

    for (final token in _tokens) {
      if (source.contains(token)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_fixture_batch_plan_token:$token',
          message: 'Fixture batch plan token is missing.',
          severity: QaSeverity.error,
          expected: token,
          actual: 'not found',
          suggestedFix:
              'Keep residential fixture batch planning local, reproducible, and separated from parser execution.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: _tokens.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'requiredTokens': _tokens.toList()..sort(),
        'contract':
            'Residential fixture batches must be planned separately from parser execution and live services.',
      },
    );
  }
}
