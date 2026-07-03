import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserKnownDebtSuite extends QaSuite {
  const WorkSupplyParserKnownDebtSuite() : super('inventory.known_debt_ledger');

  static const _planPath = 'docs/inventory_parser_qa_harness_plan.md';

  static const _knownDebtIds = <String>[
    'repair_kit_full_profile_throughput_debt',
  ];

  static const _requiredLedgerTokens = [
    'Current Known QA Debt',
    'Known Debt Ledger',
    'Exit condition',
    'Do not remove a debt ID from this ledger just to make quick runs look clean',
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final file = File(_planPath);
    if (!file.existsSync()) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_known_debt_plan',
          message: 'Known-debt plan document is missing.',
          expected: _planPath,
          actual: 'not found',
          suggestedFix: 'Restore the QA harness plan before release gating.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
      return timer.finish(
        suite: name,
        checked: 1,
        failures: failures,
        maxFailures: context.maxFailuresPerSuite,
      );
    }

    final source = file.readAsStringSync();
    final present = <String>[];
    for (final token in _requiredLedgerTokens) {
      if (source.contains(token)) {
        present.add(token);
        continue;
      }
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_known_debt_ledger_token:$token',
          message: 'Known-debt ledger is missing a required guardrail.',
          expected: token,
          actual: 'not found',
          suggestedFix:
              'Document current parser debt with owner/exit guidance before accepting more catalog expansion.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    for (final debtId in _knownDebtIds) {
      if (source.contains(debtId)) {
        present.add(debtId);
        continue;
      }
      failures.add(
        QaFailure(
          suite: name,
          id: 'known_debt_id_missing_from_ledger:$debtId',
          message: 'Known QA debt is reported by quick runs but not tracked.',
          expected: debtId,
          actual: 'not found in known-debt ledger',
          suggestedFix:
              'Add the debt ID with impact and exit condition, or fix the underlying parser contract.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: _requiredLedgerTokens.length + _knownDebtIds.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'knownDebtCount': _knownDebtIds.length,
        'presentLedgerTokens': present,
      },
    );
  }
}
