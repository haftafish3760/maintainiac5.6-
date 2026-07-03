import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserImportExportSafetySuite extends QaSuite {
  const WorkSupplyParserImportExportSafetySuite()
    : super('inventory.import_export_safety_contract');

  static const _sourcePaths = {
    'test/support/work_supply_parser_qa/work_supply_parser_import_export_safety_qa.dart',
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_security_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_boundary_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_result_contract_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_admin_privacy_rollup_qa.dart',
  };

  static const _importExportTokens = {
    'import',
    'export',
    'CSV',
    'JSON',
    'backup',
    'restore',
    'manifest',
    'schema version',
    'catalog version',
    'parser version',
    'dry run',
    'preview',
  };

  static const _safetyRules = {
    'import_runs_as_dry_run_before_write',
    'import_validates_schema_version',
    'import_validates_catalog_version',
    'import_rejects_unknown_required_fields',
    'import_does_not_mutate_official_pack',
    'import_custom_items_are_review_only',
    'export_redacts_private_receipt_text',
    'export_excludes_card_data',
    'export_preserves_stable_ids',
    'restore_can_rollback_on_failure',
  };

  static const _hostileImportCases = {
    'formula injection',
    '=cmd|',
    '+SUM',
    '@HYPERLINK',
    '../',
    'C:\\',
    '<script>',
    'DROP TABLE',
    'huge file',
    'invalid unicode',
    'duplicate id',
    'duplicate canonical name',
  };

  static const _sourceMutationGuards = {
    'does not mutate sources',
    'review candidate copy',
    'official pack immutable',
    'original raw evidence preserved',
    'generated flag',
    'manual promotion',
    'rollback',
    'audit trail',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _importExportTokens.length;
    _requireTokens(
      failures,
      source,
      _importExportTokens,
      idPrefix: 'missing_import_export_token',
      message: 'Import/export safety QA is missing data-portability vocabulary.',
      fix:
          'Inventory parser QA must cover import/export, CSV/JSON, backup/restore, manifests, versions, dry-run, and preview behavior.',
      triage: QaFailureTriage.governance,
    );

    checked += _safetyRules.length;
    _requireRules(failures, source, _safetyRules);

    checked += _hostileImportCases.length;
    _requireTokens(
      failures,
      source,
      _hostileImportCases,
      idPrefix: 'missing_hostile_import_case',
      message: 'Import/export safety QA is missing hostile import coverage.',
      fix:
          'Import QA must reject formula injection, path-like strings, script/SQL-like text, huge files, invalid Unicode, and duplicate identities.',
      triage: QaFailureTriage.security,
    );

    checked += _sourceMutationGuards.length;
    _requireTokens(
      failures,
      source,
      _sourceMutationGuards,
      idPrefix: 'missing_source_mutation_guard',
      message: 'Import/export safety QA is missing source mutation guards.',
      fix:
          'Imports and exports must preserve official pack sources, original evidence, audit trail, generated/manual flags, and rollback behavior.',
      triage: QaFailureTriage.reviewSafety,
    );

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'contract':
            'Import/export must be dry-run-first, schema/version checked, hostile-input safe, rollbackable, and unable to mutate official parser packs silently.',
      },
    );
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
          id: 'missing_import_export_rule:${_safeId(rule)}',
          message: 'Import/export safety QA is missing a named rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Add explicit import/export safety rules before user catalog data can move between devices, backups, or admin workflows.',
          triage: QaFailureTriage.security,
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
