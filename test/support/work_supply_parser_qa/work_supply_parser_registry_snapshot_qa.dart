import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserRegistrySnapshotSuite extends QaSuite {
  const WorkSupplyParserRegistrySnapshotSuite()
    : super('inventory.registry_snapshot_contract');

  static const _tokens = {
    'QA_REGISTRY_SNAPSHOT',
    'QA_REGISTRY_SNAPSHOT_ARTIFACT',
    'registeredSuiteCount',
    'registeredSuites',
    'artifactPresence',
    'latestHarnessReport',
    'latestPassEvidence',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source =
        [
              File('tool/work_supply_parser_qa_registry_snapshot.dart'),
              File('test/work_supply_parser_qa_registry_snapshot_test.dart'),
            ]
            .where((file) => file.existsSync())
            .map((file) => file.readAsStringSync())
            .join('\n');

    for (final token in _tokens) {
      if (source.contains(token)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_registry_snapshot_token:$token',
          message: 'Registry snapshot token is missing.',
          severity: QaSeverity.error,
          expected: token,
          actual: 'not found',
          suggestedFix:
              'Keep registry snapshot tooling available so harness coverage can be inspected without rerunning parser QA.',
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
            'The parser QA registry should be inspectable through a local artifact without running parser tests.',
      },
    );
  }
}
