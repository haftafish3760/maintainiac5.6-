import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserDeviceBudgetMatrixSuite extends QaSuite {
  const WorkSupplyParserDeviceBudgetMatrixSuite()
    : super('inventory.device_budget_matrix_contract');

  static const _sourcePaths = {
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_device_storage_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_cloud_local_mode_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_runtime_profile_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_generated_performance_qa.dart',
    'test/work_supply_parser_device_budget_matrix_behavior_test.dart',
  };

  static const _deviceClasses = {
    'older phone',
    'Galaxy S9',
    'midrange',
    'modern flagship',
    'Galaxy S24',
    'Galaxy S25',
    'low storage',
    'offline',
    'metered data',
    'cloud fallback',
  };

  static const _budgetRules = {
    'older_device_uses_conservative_parser_profile',
    'flagship_device_can_use_full_local_profile',
    'low_storage_blocks_large_pack_install',
    'safe_install_buffer_required',
    'cloud_fallback_is_online_only',
    'cloud_fallback_is_slower',
    'local_pack_is_fastest_path',
    'pack_download_estimates_megabytes',
    'runtime_profile_records_memory_budget',
    'runtime_profile_records_slowest_rule',
  };

  static const _runtimeSignals = {
    'cold start',
    'warm run',
    'indexing time',
    'memory growth',
    'slowest rule',
    'checks per second',
    'pack size',
    'available bytes',
    'read budget',
    'no live Firebase',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _deviceClasses.length;
    _requireTokens(
      failures,
      source,
      _deviceClasses,
      idPrefix: 'missing_device_class',
      message: 'Device budget QA is missing device/storage/network classes.',
      fix:
          'Parser QA must cover older phones, modern flagships, low storage, offline, metered-data, and cloud fallback behavior.',
      triage: QaFailureTriage.performance,
    );

    checked += _budgetRules.length;
    _requireRules(failures, source, _budgetRules);

    checked += _runtimeSignals.length;
    _requireTokens(
      failures,
      source,
      _runtimeSignals,
      idPrefix: 'missing_runtime_signal',
      message: 'Device budget QA is missing runtime measurement signals.',
      fix:
          'Runtime QA must track cold/warm runs, indexing, memory growth, slowest rules, pack size, available bytes, and local/cloud budgets.',
      triage: QaFailureTriage.performance,
    );

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'contract':
            'Parser profile, pack install, and cloud fallback must adapt to device class, storage, and network without live-service QA writes.',
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
          id: 'missing_device_budget_rule:${_safeId(rule)}',
          message: 'Device budget QA is missing a named rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Add explicit device/storage/runtime budget rules before releasing large parser packs.',
          triage: QaFailureTriage.performance,
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
