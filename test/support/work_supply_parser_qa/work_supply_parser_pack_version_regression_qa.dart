import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserPackVersionRegressionSuite extends QaSuite {
  const WorkSupplyParserPackVersionRegressionSuite()
    : super('inventory.pack_version_regression_contract');

  static const _sourcePaths = {
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_pack_lifecycle_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_pack_recovery_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_pack_integrity_recovery_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_release_manifest_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_release_signoff_qa.dart',
    'test/work_supply_parser_pack_version_regression_behavior_test.dart',
  };

  static const _versionAxes = {
    'catalog version',
    'parser version',
    'pack version',
    'manifest version',
    'locale pack version',
    'schema version',
    'migration version',
    'previous version',
    'current version',
    'rollback version',
  };

  static const _versionRules = {
    'new_pack_version_runs_old_regression_locks',
    'new_parser_version_runs_old_regression_locks',
    'new_locale_pack_runs_locale_regression_locks',
    'migration_preserves_confirmed_inventory_items',
    'migration_preserves_user_custom_items',
    'migration_preserves_review_candidates',
    'rollback_restores_previous_known_good_pack',
    'old_pack_missing_feature_falls_back_conservatively',
    'pack_version_mismatch_requires_review',
    'schema_version_mismatch_blocks_import',
    'confirmed_bug_fix_stays_fixed_across_pack_versions',
    'release_manifest_records_regression_evidence',
  };

  static const _versionFailureCases = {
    'old pack version',
    'missing locale pack',
    'corrupt pack',
    'partial install',
    'duplicate install',
    'failed migration',
    'stale search index',
    'stale Firestore mirror',
    'Hive rollback',
    'cache rebuild',
  };

  static const _protectedData = {
    'Hive',
    'source of truth',
    'inventory item',
    'vehicle inventory',
    'job material',
    'estimate material',
    'invoice material',
    'user correction',
    'custom item',
    'audit trail',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _versionAxes.length;
    _requireTokens(
      failures,
      source,
      _versionAxes,
      idPrefix: 'missing_version_axis',
      message: 'Pack-version regression QA is missing version axes.',
      fix:
          'Version regression must track catalog, parser, pack, manifest, locale, schema, migration, previous/current, and rollback versions.',
      triage: QaFailureTriage.governance,
    );

    checked += _versionRules.length;
    _requireRules(failures, source, _versionRules);

    checked += _versionFailureCases.length;
    _requireTokens(
      failures,
      source,
      _versionFailureCases,
      idPrefix: 'missing_version_failure_case',
      message: 'Pack-version regression QA is missing failure scenarios.',
      fix:
          'Version regression must cover old/missing/corrupt/partial/duplicate packs, migration failure, stale indexes/mirrors, Hive rollback, and cache rebuilds.',
      triage: QaFailureTriage.governance,
    );

    checked += _protectedData.length;
    _requireTokens(
      failures,
      source,
      _protectedData,
      idPrefix: 'missing_protected_version_data',
      message: 'Pack-version regression QA is missing protected user data.',
      fix:
          'Pack/parser migrations must preserve Hive truth, inventory, vehicle/job/estimate/invoice material records, corrections, custom items, and audit trails.',
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
            'New parser/catalog/pack versions must run old locks, preserve Hive/user data, and support conservative fallback or rollback.',
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
          id: 'missing_pack_version_regression_rule:${_safeId(rule)}',
          message: 'Pack-version regression QA is missing a named rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Add explicit pack/parser/catalog version rules before pack updates, migrations, or rollbacks are trusted.',
          triage: QaFailureTriage.baseline,
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
