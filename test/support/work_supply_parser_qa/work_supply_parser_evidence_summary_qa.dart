import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserEvidenceSummarySuite extends QaSuite {
  const WorkSupplyParserEvidenceSummarySuite()
    : super('inventory.evidence_summary_contract');

  static const _requiredTokens = {
    'QA_EVIDENCE_SUMMARY',
    'QA_EVIDENCE_SUMMARY_ARTIFACT',
    '--queue-watchdog',
    'releaseOneCommands',
    'fixtureReadinessRollup',
    'queueWatchdog',
    'readyForParserExecution',
    'latestPassEvidence',
    'latestHarnessReport',
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
              File('tool/work_supply_parser_qa_evidence_summary.dart'),
              File('test/work_supply_parser_qa_evidence_summary_test.dart'),
            ]
            .where((file) => file.existsSync())
            .map((file) => file.readAsStringSync())
            .join('\n');

    for (final token in _requiredTokens) {
      if (_containsContractToken(source, token)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_evidence_summary_token:$token',
          message: 'Evidence summary command contract token is missing.',
          severity: QaSeverity.error,
          expected: token,
          actual: 'not found',
          suggestedFix:
              'Keep the local evidence summary command and test coverage wired before relying on accumulated QA artifacts.',
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
            'Accumulated parser QA evidence must be summarizable locally with explicit missing/unsafe findings.',
      },
    );
  }
}

bool _containsContractToken(String source, String token) {
  return _normalizeContractText(source).contains(_normalizeContractText(token));
}

String _normalizeContractText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
