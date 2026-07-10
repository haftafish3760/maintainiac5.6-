import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserHiveAuthoritySuite extends QaSuite {
  const WorkSupplyParserHiveAuthoritySuite()
    : super('inventory.hive_authority_contract');

  static const _sourcePaths = {
    'test/support/work_supply_parser_qa/work_supply_parser_hive_authority_qa.dart',
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_hive_firestore_sync_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_workflow_routing_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_barcode_inventory_identity_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_duplicate_receipt_import_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_receipt_source_immutability_qa.dart',
  };

  static const _authorityTokens = {
    'Hive',
    'local box',
    'local cache',
    'source of truth',
    'authoritative',
    'Firestore',
    'Firebase',
    'mirror',
    'sync queue',
    'offline first',
    'pending write',
    'review candidate',
  };

  static const _authorityRules = {
    'hive_is_always_inventory_truth',
    'firebase_is_never_inventory_truth',
    'firestore_is_mirror_only',
    'inventory_add_commits_to_hive_first',
    'purchase_receipt_add_commits_to_hive_immediately',
    'job_material_add_commits_to_hive_first',
    'estimate_material_add_commits_to_hive_first',
    'offline_inventory_write_is_valid',
    'failed_firestore_sync_does_not_rollback_hive_inventory',
    'stale_firestore_never_overwrites_hive_inventory',
    'server_timestamp_never_wins_over_local_inventory_version',
    'sync_conflict_requires_review_not_remote_overwrite',
  };

  static const _inventoryWriteCases = {
    'add to inventory',
    'add more of this item',
    'mark out of stock',
    'purchased not in stock',
    'vehicle inventory',
    'shop inventory',
    'transfer vehicle',
    'active job material',
    'draft estimate material',
    'invoice material',
    'duplicate receipt',
    'return receipt',
  };

  static const _failureModes = {
    'offline',
    'app killed mid-review',
    'low storage',
    'Hive write failure',
    'Firestore unavailable',
    'permission denied',
    'sync retry',
    'stale mirror',
    'two devices',
    'rollback',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _authorityTokens.length;
    _requireTokens(
      failures,
      source,
      _authorityTokens,
      idPrefix: 'missing_hive_authority_token',
      message: 'Hive authority QA is missing required local/cloud vocabulary.',
      fix:
          'Inventory QA must explicitly say Hive/local storage is authoritative and Firebase/Firestore is mirror-only.',
      triage: QaFailureTriage.governance,
    );

    checked += _authorityRules.length;
    _requireRules(failures, source, _authorityRules);

    checked += _inventoryWriteCases.length;
    _requireTokens(
      failures,
      source,
      _inventoryWriteCases,
      idPrefix: 'missing_hive_inventory_write_case',
      message: 'Hive authority QA is missing an inventory write workflow.',
      fix:
          'Every inventory/job/estimate/invoice material write must commit locally to Hive first and only then enqueue mirror sync.',
      triage: QaFailureTriage.reviewSafety,
    );

    checked += _failureModes.length;
    _requireTokens(
      failures,
      source,
      _failureModes,
      idPrefix: 'missing_hive_failure_mode',
      message: 'Hive authority QA is missing a local/cloud failure mode.',
      fix:
          'Hive authority tests must prove offline, killed app, low storage, Hive failure, Firestore failure, permissions, stale mirrors, two-device conflicts, retries, and rollback behavior.',
      triage: QaFailureTriage.conflict,
    );

    checked += 4;
    _requireForbiddenTruthLanguage(source, failures);

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'contract':
            'Hive/local inventory state is the only source of truth; Firebase/Firestore can mirror, queue, and report, but never override local inventory truth.',
      },
    );
  }

  void _requireForbiddenTruthLanguage(
    String source,
    List<QaFailure> failures,
  ) {
    final lower = _normalizeContractText(source);
    const requiredGuards = {
      'firebase is never inventory truth',
      'firestore is mirror only',
      'hive is always inventory truth',
      'stale firestore never overwrites hive',
    };
    for (final guard in requiredGuards) {
      if (lower.contains(_normalizeContractText(guard))) continue;
      failures.add(
        _failure(
          id: 'missing_hive_truth_guard:${_safeId(guard)}',
          message: 'Hive authority QA is missing a hard truth-boundary guard.',
          expected: guard,
          actual: 'not found',
          fix:
              'Use direct language in the contract/tests: Hive is truth; Firebase/Firestore is mirror-only and never wins conflicts.',
          triage: QaFailureTriage.governance,
        ),
      );
    }
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
          id: 'missing_hive_authority_rule:${_safeId(rule)}',
          message: 'Hive authority QA is missing a named rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Add explicit authority rules before inventory write, sync, mirror, or recovery behavior is considered safe.',
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
