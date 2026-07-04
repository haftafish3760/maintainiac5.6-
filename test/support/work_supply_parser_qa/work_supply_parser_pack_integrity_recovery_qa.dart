import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserPackIntegrityRecoverySuite extends QaSuite {
  const WorkSupplyParserPackIntegrityRecoverySuite()
    : super('inventory.pack_integrity_recovery_contract');

  static const _sourcePaths = {
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_pack_recovery_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_pack_lifecycle_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_pack_scope_gate_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_cloud_local_mode_qa.dart',
    'test/work_supply_parser_pack_integrity_recovery_behavior_test.dart',
    'test/work_supply_trade_pack_import_recovery_test.dart',
  };

  static const _integrityTokens = {
    'checksum',
    'signature',
    'manifest',
    'version',
    'migration',
    'rollback',
    'corrupt pack',
    'interrupted download',
    'duplicate install',
    'missing locale pack',
    'old pack version',
    'partial install',
  };

  static const _recoveryRules = {
    'corrupt_pack_never_loads_as_current',
    'interrupted_download_keeps_previous_pack',
    'duplicate_pack_install_is_idempotent',
    'old_pack_version_runs_migration_or_rollback',
    'missing_locale_pack_falls_back_conservatively',
    'failed_migration_keeps_previous_pack',
    'pack_manifest_controls_enabled_scope',
    'pack_integrity_checked_before_indexing',
    'pack_recovery_does_not_hit_live_firebase_in_qa',
    'pack_recovery_records_actionable_diagnostic',
  };

  static const _scopeTokens = {
    'plumbing',
    'electrical',
    'hvac',
    'fasteners',
    'residential',
    'core',
    'standard',
    'professional',
    'complete',
    'English',
    'Spanish',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _integrityTokens.length;
    _requireTokens(
      failures,
      source,
      _integrityTokens,
      idPrefix: 'missing_pack_integrity_token',
      message: 'Pack integrity/recovery QA is missing failure modes.',
      fix:
          'Pack QA must cover checksum/signature, manifests, versions, migrations, rollback, corruption, interrupted downloads, duplicate installs, and missing locale packs.',
      triage: QaFailureTriage.governance,
    );

    checked += _recoveryRules.length;
    _requireRules(failures, source, _recoveryRules);

    checked += _scopeTokens.length;
    _requireTokens(
      failures,
      source,
      _scopeTokens,
      idPrefix: 'missing_recovery_scope',
      message: 'Pack integrity/recovery QA is missing release-one scope.',
      fix:
          'Recovery tests must apply to release-one residential trades, fasteners, tiers, and language packs.',
      triage: QaFailureTriage.locale,
    );

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'contract':
            'Bad, partial, duplicate, old, or missing parser packs must fail safe and keep the last known-good pack available.',
      },
    );
  }

  void _requireRules(
    List<QaFailure> failures,
    String source,
    Set<String> rules,
  ) {
    final lower = _normalizeContractText(source);
    for (final rule in rules) {
      if (lower.contains(_normalizeContractText(rule))) continue;
      failures.add(
        _failure(
          id: 'missing_pack_recovery_rule:${_safeId(rule)}',
          message: 'Pack integrity/recovery QA is missing a named rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Add explicit recovery behavior before downloadable parser packs are shipped or cached locally.',
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
    final lower = _normalizeContractText(source);
    for (final token in tokens) {
      if (lower.contains(_normalizeContractText(token))) continue;
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

String _normalizeContractText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
