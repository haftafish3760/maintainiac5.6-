import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserAdminReportContractSuite extends QaSuite {
  const WorkSupplyParserAdminReportContractSuite()
    : super('inventory.admin_report_contract');

  static const _scannedFiles = [
    'test/support/qa_harness/qa_harness.dart',
    'test/qa_admin_report_contract_test.dart',
    'test/qa_report_artifact_test.dart',
    'docs/inventory_parser_qa_harness_plan.md',
  ];

  static const _contracts = [
    _AdminReportContract('admin_health_json', [
      'adminHealth',
      "'status'",
      "'blockingFailureCount'",
    ]),
    _AdminReportContract('admin_health_summary_line', [
      'QA_ADMIN_HEALTH',
      'actualFailures',
      'blockingFailures',
    ]),
    _AdminReportContract('triage_rollup', [
      'failuresByTriageCategory',
      'QA_TRIAGE_GROUP',
    ]),
    _AdminReportContract('slow_suite_rollup', [
      'slowestSuites',
      'QA_SLOW_SUITE',
    ]),
    _AdminReportContract('pack_health_rollup', [
      'packHealth',
      'QA_PACK_HEALTH',
    ]),
    _AdminReportContract('redaction_artifact_test', [
      '[REDACTED_RECEIPT_ID]',
      '[REDACTED_CARD_LIKE_NUMBER]',
      '[REDACTED_CARD_LAST4]',
      '[REDACTED_PRIVATE_FIELD]',
      '[REDACTED_PHONE]',
    ]),
    _AdminReportContract('admin_contract_state_regression_test', [
      'blocked.adminHealth',
      'warningOnly.adminHealth',
      'passing.adminHealth',
    ]),
    _AdminReportContract('admin_contract_private_detail_regression_test', [
      'rawReceiptLine',
      'fullDeviceSerial',
      'isNot',
    ]),
    _AdminReportContract('command_one_safe_docs', [
      'Command One diagnostics',
      'no raw receipt content',
      'admin-safe',
      'admin-safe report',
    ]),
  ];

  static const _blockedTokens = [
    'rawReceiptText',
    'receiptImageBytes',
    'customerName',
    'cardLast4',
    'fullDeviceSerial',
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final sources = <String, String>{};

    for (final path in _scannedFiles) {
      final file = File(path);
      if (!file.existsSync()) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'missing_admin_report_scan_file:$path',
            message: 'Admin report contract scan file is missing.',
            expected: path,
            actual: 'not found',
            suggestedFix:
                'Update this suite if admin report contract files move.',
            metadata: const {'triageCategory': QaFailureTriage.schema},
          ),
        );
        continue;
      }
      sources[path] = file.readAsStringSync();
    }

    final source = sources.values.join('\n');
    final present = <String>[];
    for (final contract in _contracts) {
      if (contract.isPresentIn(source)) {
        present.add(contract.name);
        continue;
      }
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_admin_report_contract:${contract.name}',
          message: 'Admin-safe QA report contract is missing.',
          severity: QaSeverity.error,
          expected: contract.tokens.join(' + '),
          actual: 'not found',
          suggestedFix:
              'Keep Command One/admin parser monitoring summarized, redacted, and actionable before scaling catalog QA.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    final harnessSource =
        sources['test/support/qa_harness/qa_harness.dart'] ?? '';
    for (final token in _blockedTokens) {
      if (!harnessSource.contains(token)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'admin_report_private_field:$token',
          message: 'Admin health report must not expose private raw fields.',
          severity: QaSeverity.critical,
          expected: 'redacted aggregate/bucket only',
          actual: token,
          suggestedFix:
              'Remove raw private fields from adminHealth and keep details in redacted local artifacts only.',
          metadata: const {'triageCategory': QaFailureTriage.privacy},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: _scannedFiles.length + _contracts.length + _blockedTokens.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'presentContracts': present,
        'blockedTokensScanned': _blockedTokens,
        'filesScanned': sources.keys.toList()..sort(),
      },
    );
  }
}

class _AdminReportContract {
  const _AdminReportContract(this.name, this.tokens);

  final String name;
  final List<String> tokens;

  bool isPresentIn(String source) {
    final normalizedSource = _normalizeContractText(source);
    return tokens.every(
      (token) => normalizedSource.contains(_normalizeContractText(token)),
    );
  }
}

String _normalizeContractText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
