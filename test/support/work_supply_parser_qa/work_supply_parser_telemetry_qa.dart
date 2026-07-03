import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserTelemetryContractSuite extends QaSuite {
  const WorkSupplyParserTelemetryContractSuite()
    : super('inventory.telemetry_contract');

  static const _sloMetricNames = [
    'failure_device_bucket',
    'no_raw_receipt_content',
    'no_live_hosted_writes',
  ];

  static const _scannedFiles = [
    'docs/materials_catalog_intelligence_contract.md',
    'docs/work_supplies_spec.md',
    'docs/materials_trade_pack_pass_roadmap.md',
    'test/support/qa_harness/qa_harness.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_security_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_boundary_qa.dart',
  ];

  static const _allowedDiagnostics = {
    'item_id': ['item ID', 'item id'],
    'trade': ['trade'],
    'category': ['category'],
    'pack_tier': ['pack tier'],
    'pack_version': ['pack version'],
    'merchant_bucket': ['merchant'],
    'failure_reason_code': ['failure reason code'],
    'device_class': ['device class', 'device capability/class'],
    'device_model_bucket': ['device model bucket'],
  };

  static const _blockedDiagnostics = {
    'raw_receipt_text': ['raw receipt text'],
    'receipt_image': ['receipt-photo diagnostics', 'receipt image'],
    'card_number': ['card number', 'card numbers'],
    'customer_identity': ['customer name', 'customer names'],
    'exact_device_identifier': [
      'full device serial',
      'exact device identifier',
    ],
  };

  static const _costControls = {
    'summary_not_per_event': [
      'summary',
      'not one Firestore read per catalog item',
    ],
    'read_budget': ['100 catalog reads per user per day'],
    'no_live_firebase_tests': ['Firebase writes are still off-limits'],
    'cloud_opt_in': ['Cloud fallback', 'opt-in'],
    'local_first': ['Local pack mode', 'offline capable'],
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final sourceByPath = <String, String>{};

    for (final path in _scannedFiles) {
      final file = File(path);
      if (!file.existsSync()) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'missing_telemetry_scan_file:$path',
            message: 'Telemetry contract scan file is missing.',
            expected: path,
            actual: 'not found',
            suggestedFix:
                'Update this suite if the parser diagnostics docs or harness files move.',
            metadata: const {'triageCategory': QaFailureTriage.schema},
          ),
        );
        continue;
      }
      sourceByPath[path] = file.readAsStringSync();
    }

    final source = sourceByPath.values.join('\n').toLowerCase();
    final presentAllowed = _checkTokenGroups(
      failures,
      source,
      _allowedDiagnostics,
      idPrefix: 'missing_allowed_diagnostic',
      message: 'Allowed parser diagnostic field is not documented.',
      category: QaFailureTriage.governance,
      severity: QaSeverity.warning,
    );
    final presentBlocked = _checkTokenGroups(
      failures,
      source,
      _blockedDiagnostics,
      idPrefix: 'missing_blocked_diagnostic',
      message: 'Blocked parser diagnostic field is not documented.',
      category: QaFailureTriage.privacy,
      severity: QaSeverity.error,
    );
    final presentCostControls = _checkTokenGroups(
      failures,
      source,
      _costControls,
      idPrefix: 'missing_cost_control',
      message: 'Parser diagnostics cost-control rule is not documented.',
      category: QaFailureTriage.economics,
      severity: QaSeverity.warning,
    );

    return timer.finish(
      suite: name,
      checked:
          _scannedFiles.length +
          _allowedDiagnostics.length +
          _blockedDiagnostics.length +
          _costControls.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'filesScanned': sourceByPath.keys.toList()..sort(),
        'presentAllowedDiagnostics': presentAllowed,
        'presentBlockedDiagnostics': presentBlocked,
        'presentCostControls': presentCostControls,
        'sloMetricNames': _sloMetricNames,
        'parserCalls': 0,
        'networkAllowed': false,
      },
    );
  }

  List<String> _checkTokenGroups(
    List<QaFailure> failures,
    String source,
    Map<String, List<String>> groups, {
    required String idPrefix,
    required String message,
    required String category,
    required QaSeverity severity,
  }) {
    final present = <String>[];
    for (final entry in groups.entries) {
      if (entry.value.any((token) => source.contains(token.toLowerCase()))) {
        present.add(entry.key);
        continue;
      }
      failures.add(
        QaFailure(
          suite: name,
          id: '$idPrefix:${entry.key}',
          message: message,
          severity: severity,
          expected: entry.value.join(' OR '),
          actual: 'not found',
          suggestedFix:
              'Update the Work Supplies parser diagnostics contract before admin health reporting is release-gated.',
          metadata: {'triageCategory': category},
        ),
      );
    }
    return present;
  }
}
