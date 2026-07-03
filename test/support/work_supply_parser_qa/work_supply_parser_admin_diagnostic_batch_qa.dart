import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserAdminDiagnosticBatchSuite extends QaSuite {
  const WorkSupplyParserAdminDiagnosticBatchSuite()
    : super('inventory.admin_diagnostic_batch_contract');

  static const _progressPath = 'docs/inventory_parser_qa_progress_memory.md';
  static const _adminContractPath =
      'test/support/work_supply_parser_qa/work_supply_parser_admin_report_contract_qa.dart';
  static const _telemetryPath =
      'test/support/work_supply_parser_qa/work_supply_parser_telemetry_qa.dart';
  static const _artifactPath =
      'test/support/work_supply_parser_qa/work_supply_parser_artifact_contract_qa.dart';
  static const _evidencePath =
      'test/support/work_supply_parser_qa/work_supply_parser_evidence_qa.dart';
  static const _catalogContractPath =
      'docs/materials_catalog_intelligence_contract.md';

  static const _allowedDiagnosticFields = {
    'event ID',
    'trade',
    'market scope',
    'pack tier',
    'pack version',
    'parser version',
    'catalog item ID',
    'catalog item display name',
    'item family/type/category',
    'matched candidate ID',
    'confidence bucket',
    'failure reason code',
    'device class',
    'device model bucket',
    'OS major version',
    'parser depth',
    'candidate limit',
    'duration bucket',
    'retry/correction/abandonment counts',
  };

  static const _blockedDiagnosticFields = {
    'raw receipt text',
    'receipt photo',
    'card numbers',
    'last four',
    'customer name',
    'job address',
    'exact location',
    'employee private data',
    'user-private inventory notes',
    'full device serial',
    'exact device identifier',
  };

  static const _requiredReportTokens = {
    '[REDACTED_CARD_LAST4]',
    '[REDACTED_PRIVATE_FIELD]',
    'no raw receipt content',
    'admin-safe report',
    'Command One diagnostics',
    'failuresByTriageCategory',
    'slowestSuites',
    'packHealth',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final progress = _read(_progressPath);
    final catalogContract = _read(_catalogContractPath);
    final reportSources = [
      _read(_adminContractPath),
      _read(_telemetryPath),
      _read(_artifactPath),
      _read(_evidencePath),
      progress,
    ].join('\n');
    var checked = 0;

    checked += _allowedDiagnosticFields.length;
    for (final field in _allowedDiagnosticFields) {
      if (catalogContract.contains(field) || reportSources.contains(field)) {
        continue;
      }
      failures.add(
        _failure(
          id: 'missing_allowed_admin_field:${_safeId(field)}',
          message: 'Admin diagnostics contract is missing an allowed parser field.',
          expected: field,
          actual: 'not found',
          fix:
              'Command One diagnostics must know which inventory parser fields are safe and useful.',
          category: QaFailureTriage.governance,
        ),
      );
    }

    checked += _blockedDiagnosticFields.length;
    for (final field in _blockedDiagnosticFields) {
      if (catalogContract.contains(field) || reportSources.contains(field)) {
        continue;
      }
      failures.add(
        _failure(
          id: 'missing_blocked_admin_field:${_safeId(field)}',
          message: 'Admin diagnostics contract is missing a blocked private field.',
          expected: field,
          actual: 'not found',
          fix:
              'Command One/admin reports must explicitly reject private receipt/user/device data.',
          category: QaFailureTriage.privacy,
        ),
      );
    }

    checked += _requiredReportTokens.length;
    for (final token in _requiredReportTokens) {
      if (reportSources.contains(token)) continue;
      failures.add(
        _failure(
          id: 'missing_admin_report_token:${_safeId(token)}',
          message:
              'Admin/parser report contract is missing a required safety or triage token.',
          expected: token,
          actual: 'not found in admin/telemetry/artifact sources',
          fix:
              'Parser QA reports must stay useful for diagnostics without leaking private data.',
          category: QaFailureTriage.privacy,
        ),
      );
    }

    checked += 5;
    _checkProgressMemory(progress, failures);

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'progressPath': _progressPath,
        'catalogContractPath': _catalogContractPath,
        'allowedFieldCount': _allowedDiagnosticFields.length,
        'blockedFieldCount': _blockedDiagnosticFields.length,
        'contract':
            'Inventory parser diagnostics for Command One/admin views must be item-level, device-class aware, triageable, and privacy-safe without raw receipt/user data.',
      },
    );
  }

  void _checkProgressMemory(String progress, List<QaFailure> failures) {
    const requiredTokens = {
      'inventory.admin_diagnostic_batch_contract',
      'focusedRerun',
      'doNotRerunUnless',
      'coveredInputs',
      'focused-validated',
    };
    for (final token in requiredTokens) {
      if (progress.contains(token)) continue;
      failures.add(
        _failure(
          id: 'missing_admin_diagnostic_memory:${_safeId(token)}',
          message:
              'Progress memory is missing admin diagnostic batch tracking.',
          expected: token,
          actual: 'not found in $_progressPath',
          fix:
              'Track admin diagnostic QA coverage so it is not repeated or forgotten.',
          category: QaFailureTriage.governance,
        ),
      );
    }
  }

  QaFailure _failure({
    required String id,
    required String message,
    required String expected,
    required String actual,
    required String fix,
    required String category,
  }) {
    return QaFailure(
      suite: name,
      id: id,
      message: message,
      severity: QaSeverity.warning,
      expected: expected,
      actual: actual,
      suggestedFix: fix,
      metadata: {'triageCategory': category},
    );
  }
}

String _read(String path) {
  final file = File(path);
  if (!file.existsSync()) return '';
  return file.readAsStringSync();
}

String _safeId(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}
