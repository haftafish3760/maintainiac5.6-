import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserHiveFirestoreSyncSuite extends QaSuite {
  const WorkSupplyParserHiveFirestoreSyncSuite()
    : super('inventory.hive_firestore_sync_contract');

  static const _sourcePaths = {
    'test/support/work_supply_parser_qa/work_supply_parser_hive_firestore_sync_qa.dart',
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_cloud_local_mode_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_cloud_cost_guard_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_no_live_services_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_pack_lifecycle_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_pack_integrity_recovery_qa.dart',
  };

  static const _storageTokens = {
    'Hive',
    'local box',
    'local cache',
    'offline',
    'Firestore',
    'mirror',
    'sync queue',
    'pending write',
    'last synced',
    'server timestamp',
    'conflict',
    'rollback',
  };

  static const _syncRules = {
    'hive_is_local_source_for_offline_parser_state',
    'firestore_mirror_is_not_required_for_local_parse',
    'firestore_mirror_writes_are_batched',
    'firestore_mirror_respects_daily_budget',
    'parser_tests_do_not_hit_live_firestore',
    'sync_queue_is_idempotent',
    'failed_sync_keeps_local_review_candidate',
    'stale_firestore_mirror_does_not_overwrite_newer_hive_state',
    'server_timestamp_never_replaces_catalog_version',
    'pack_download_state_is_separate_from_parser_result',
  };

  static const _privacyCostTokens = {
    'no live Firebase',
    'firebaseWritesAllowed',
    'writesProductionCatalog',
    'read budget',
    'write budget',
    'redacted',
    'no raw receipt',
    'aggregate',
    'App Check',
    'auth',
  };

  static const _conflictCases = {
    'same item edited on two devices',
    'app killed mid-review',
    'offline correction later syncs',
    'duplicate receipt import',
    'old pack version',
    'missing locale pack',
    'permission denied',
    'sync retry',
    'partial failure',
    'rollback previous pack',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _storageTokens.length;
    _requireTokens(
      failures,
      source,
      _storageTokens,
      idPrefix: 'missing_storage_token',
      message: 'Hive/Firestore sync QA is missing storage vocabulary.',
      fix:
          'Inventory parser QA must explicitly cover Hive/local cache, Firestore mirror, sync queue, pending writes, timestamps, conflicts, and rollback.',
      triage: QaFailureTriage.schema,
    );

    checked += _syncRules.length;
    _requireRules(failures, source, _syncRules);

    checked += _privacyCostTokens.length;
    _requireTokens(
      failures,
      source,
      _privacyCostTokens,
      idPrefix: 'missing_privacy_cost_token',
      message: 'Hive/Firestore sync QA is missing privacy/cost boundaries.',
      fix:
          'Sync QA must prove no live Firebase in local tests, no raw receipt storage, redacted diagnostics, budgets, auth, and App Check planning.',
      triage: QaFailureTriage.security,
    );

    checked += _conflictCases.length;
    _requireTokens(
      failures,
      source,
      _conflictCases,
      idPrefix: 'missing_sync_conflict_case',
      message: 'Hive/Firestore sync QA is missing a sync conflict case.',
      fix:
          'Add multi-device/offline/retry/permission/duplicate/pack-version cases before Firestore mirror behavior is trusted.',
      triage: QaFailureTriage.conflict,
    );

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'contract':
            'Hive/local state drives offline parser review; Firestore mirror is budgeted, batched, idempotent, privacy-safe, and never exercised live by local QA.',
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
          id: 'missing_hive_firestore_rule:${_safeId(rule)}',
          message: 'Hive/Firestore sync QA is missing a named rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Add explicit local/mirror/sync/rollback/budget rules before parser review candidates sync to cloud mirrors.',
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

String _normalizeContractText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _safeId(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}
