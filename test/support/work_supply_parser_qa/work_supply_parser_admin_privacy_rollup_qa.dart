import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserAdminPrivacyRollupSuite extends QaSuite {
  const WorkSupplyParserAdminPrivacyRollupSuite()
    : super('inventory.admin_privacy_rollup_contract');

  static const _sourcePaths = {
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_admin_report_contract_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_admin_diagnostic_batch_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_security_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_telemetry_qa.dart',
    'test/work_supply_parser_admin_privacy_rollup_behavior_test.dart',
  };

  static const _allowedAdminFields = {
    'device class',
    'device model',
    'os version',
    'app version',
    'parser version',
    'pack version',
    'trade',
    'item id',
    'failure category',
    'candidate count',
    'review status',
    'merchant type',
  };

  static const _blockedAdminFields = {
    'raw receipt text',
    'card number',
    'last four',
    'customer name',
    'email',
    'phone',
    'address',
    'GPS coordinates',
    'photo',
    'receipt image',
  };

  static const _rollupRules = {
    'admin_rollup_is_aggregate_first',
    'admin_rollup_redacts_private_data',
    'admin_rollup_does_not_store_raw_receipts',
    'admin_rollup_groups_by_failure_category',
    'admin_rollup_groups_by_trade',
    'admin_rollup_groups_by_device_class',
    'admin_rollup_groups_by_pack_version',
    'admin_rollup_has_read_budget',
    'admin_rollup_has_write_budget',
    'admin_rollup_is_not_real_time_required',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _allowedAdminFields.length;
    _requireTokens(
      failures,
      source,
      _allowedAdminFields,
      idPrefix: 'missing_allowed_admin_field',
      message: 'Admin parser rollup QA is missing an allowed diagnostic field.',
      fix:
          'Admin diagnostics should expose parser health by device, app/parser/pack version, trade, item, failure category, and candidate status.',
      triage: QaFailureTriage.governance,
    );

    checked += _blockedAdminFields.length;
    _requireBlockedFieldPolicy(failures, source);

    checked += _rollupRules.length;
    _requireRules(failures, source, _rollupRules);

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'contract':
            'Command One/admin parser diagnostics must be aggregate, privacy-safe, budgeted, and useful without raw receipt data.',
      },
    );
  }

  void _requireBlockedFieldPolicy(
    List<QaFailure> failures,
    String source,
  ) {
    final lower = source.toLowerCase();
    for (final field in _blockedAdminFields) {
      final hasField = lower.contains(field.toLowerCase());
      final hasPrivacyLanguage =
          lower.contains('blocked') ||
          lower.contains('redact') ||
          lower.contains('do not store') ||
          lower.contains('not logged');
      if (hasField && hasPrivacyLanguage) continue;
      failures.add(
        _failure(
          id: 'missing_blocked_admin_field:${_safeId(field)}',
          message: 'Admin parser rollup QA is missing blocked private data.',
          expected: field,
          actual: 'not covered with redaction/blocking language',
          fix:
              'Explicitly block raw receipt text, card data, customer contact data, GPS, photos, and receipt images from parser diagnostics.',
          triage: QaFailureTriage.privacy,
        ),
      );
    }
  }

  void _requireRules(
    List<QaFailure> failures,
    String source,
    Set<String> rules,
  ) {
    final lower = source.toLowerCase();
    for (final rule in rules) {
      if (lower.contains(rule.toLowerCase())) continue;
      failures.add(
        _failure(
          id: 'missing_admin_rollup_rule:${_safeId(rule)}',
          message: 'Admin parser rollup QA is missing a named rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Add explicit aggregate, privacy, grouping, budget, and non-real-time admin rollup rules.',
          triage: QaFailureTriage.governance,
        ),
      );
    }
  }

  void _requireTokens(
    List<QaFailure> failures,
    String source,
    Set<String> tokens, {
    required String idPrefix,
    required String message,
    required String fix,
    required String triage,
  }) {
    final lower = source.toLowerCase();
    for (final token in tokens) {
      if (lower.contains(token.toLowerCase())) continue;
      failures.add(
        _failure(
          id: '$idPrefix:${_safeId(token)}',
          message: message,
          expected: token,
          actual: 'not found',
          fix: fix,
          triage: triage,
        ),
      );
    }
  }

  String _readSources() {
    final buffer = StringBuffer();
    for (final path in _sourcePaths) {
      final file = File(path);
      if (!file.existsSync()) continue;
      buffer.writeln(file.readAsStringSync());
    }
    return buffer.toString();
  }

  QaFailure _failure({
    required String id,
    required String message,
    required String expected,
    required String actual,
    required String fix,
    required String triage,
  }) {
    return QaFailure(
      suite: name,
      id: id,
      message: message,
      severity: QaSeverity.warning,
      expected: expected,
      actual: actual,
      suggestedFix: fix,
      metadata: {'triageCategory': triage},
    );
  }
}

String _safeId(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}
