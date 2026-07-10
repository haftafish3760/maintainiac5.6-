import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserGateLedgerSuite extends QaSuite {
  const WorkSupplyParserGateLedgerSuite()
    : super('inventory.gate_ledger_contract');

  static const _tokens = {
    'QA_GATE_LEDGER',
    'QA_GATE_LEDGER_ARTIFACT',
    'QA_GATE_SHOULD_RUN',
    'gate',
    'command',
    'inputCount',
    'nextWorkWhileGateRuns',
    'fingerprint',
    'liveServicesAllowed',
    'firebaseWritesAllowed',
    'ocrCameraExpensesTouched',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source =
        [
              File('tool/work_supply_parser_qa_gate_ledger.dart'),
              File('tool/work_supply_parser_qa_gate_should_run.dart'),
              File('test/work_supply_parser_qa_gate_ledger_test.dart'),
            ]
            .where((file) => file.existsSync())
            .map((file) => file.readAsStringSync())
            .join('\n');

    for (final token in _tokens) {
      if (_containsContractToken(source, token)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_gate_ledger_token:$token',
          message: 'Quality-gate ledger token is missing.',
          severity: QaSeverity.error,
          expected: token,
          actual: 'not found',
          suggestedFix:
              'Keep quality-gate ledger evidence available so analyzer and QA reruns can be skipped when covered sources did not change.',
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
            'Quality gates should record covered source fingerprints and provide a should-run check so redundant reruns can be avoided.',
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
