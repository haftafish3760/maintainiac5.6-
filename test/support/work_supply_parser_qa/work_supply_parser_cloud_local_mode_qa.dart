import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserCloudLocalModeSuite extends QaSuite {
  const WorkSupplyParserCloudLocalModeSuite()
    : super('inventory.cloud_local_mode_contract');

  static const _progressPath = 'docs/inventory_parser_qa_progress_memory.md';
  static const _catalogContractPath =
      'docs/materials_catalog_intelligence_contract.md';
  static const _deliveryPolicyPath =
      'lib/screens/work_supplies/data/work_supply_trade_pack_delivery_policy.dart';
  static const _installGuardPath =
      'lib/screens/work_supplies/data/work_supply_trade_pack_install_guard.dart';
  static const _deliveryPolicyQaPath =
      'test/support/work_supply_parser_qa/work_supply_parser_delivery_policy_qa.dart';
  static const _cloudCostQaPath =
      'test/support/work_supply_parser_qa/work_supply_parser_cloud_cost_guard_qa.dart';
  static const _deviceStorageQaPath =
      'test/support/work_supply_parser_qa/work_supply_parser_device_storage_qa.dart';
  static const _behaviorPath =
      'test/work_supply_parser_cloud_local_mode_behavior_test.dart';

  static const _localModeTokens = {
    'Local pack mode',
    'downloads gzipped pack chunks',
    'offline capable',
    'safe install buffer',
    'fastest',
  };

  static const _cloudModeTokens = {
    'Cloud fallback mode',
    'online-only',
    'slower',
    'subscription',
    'Do not implement cloud parsing as one read per catalog item',
    'Target no more than about 100 catalog reads per user per day',
  };

  static const _deliveryCodeTokens = {
    'cloudFallback',
    'local',
    'requiresInternet',
    'subscription',
    'readBudget',
    'storage',
    'install',
    'availableBytes',
  };

  static const _qaGuardTokens = {
    'no live Firebase',
    'cost flags',
    'local-only QA',
    'older-phone parser limits',
    'not-enough-storage',
    'cloud fallback',
    '100-read budget',
    'writesProductionCatalog',
    'firebaseWritesAllowed',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final progress = _read(_progressPath);
    final contract = _read(_catalogContractPath);
    final deliverySource =
        '${_read(_deliveryPolicyPath)}\n${_read(_installGuardPath)}';
    final qaSource =
        '${_read(_deliveryPolicyQaPath)}\n'
        '${_read(_cloudCostQaPath)}\n'
        '${_read(_deviceStorageQaPath)}\n'
        '${_read(_behaviorPath)}\n'
        '$progress';
    var checked = 0;

    checked += _localModeTokens.length;
    for (final token in _localModeTokens) {
      if (contract.contains(token) || deliverySource.contains(token)) continue;
      failures.add(
        _failure(
          id: 'missing_local_mode_token:${_safeId(token)}',
          message: 'Local inventory pack mode contract is incomplete.',
          expected: token,
          actual: 'not found',
          fix:
              'Local parser packs must remain downloadable, offline-capable, storage-checked, and fastest path.',
          category: QaFailureTriage.governance,
        ),
      );
    }

    checked += _cloudModeTokens.length;
    for (final token in _cloudModeTokens) {
      if (contract.contains(token) || deliverySource.contains(token)) continue;
      failures.add(
        _failure(
          id: 'missing_cloud_mode_token:${_safeId(token)}',
          message: 'Cloud fallback parser mode contract is incomplete.',
          expected: token,
          actual: 'not found',
          fix:
              'Cloud fallback must be online-only, subscription-aware, slower, read-budgeted, and never one read per item.',
          category: QaFailureTriage.governance,
        ),
      );
    }

    checked += _deliveryCodeTokens.length;
    for (final token in _deliveryCodeTokens) {
      if (deliverySource.toLowerCase().contains(token.toLowerCase())) continue;
      failures.add(
        _failure(
          id: 'missing_delivery_code_token:${_safeId(token)}',
          message:
              'Trade-pack delivery/install code is missing a local/cloud/storage concept.',
          expected: token,
          actual: 'not found in delivery/install sources',
          fix:
              'Delivery code must preserve storage checks, local/cloud mode, subscription/read-budget behavior, and install safety.',
          category: QaFailureTriage.schema,
        ),
      );
    }

    checked += _qaGuardTokens.length;
    for (final token in _qaGuardTokens) {
      if (qaSource.contains(token)) continue;
      failures.add(
        _failure(
          id: 'missing_cloud_local_qa_token:${_safeId(token)}',
          message:
              'Cloud/local parser mode QA guard is missing a required safety concept.',
          expected: token,
          actual: 'not found in QA sources or progress memory',
          fix:
              'QA must prove local-only tests, cloud read budgets, device storage limits, and no live Firebase writes.',
          category: QaFailureTriage.security,
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
        'deliveryPolicyPath': _deliveryPolicyPath,
        'installGuardPath': _installGuardPath,
        'contract':
            'Inventory parser packs must support local/offline mode and future cloud fallback without live Firebase QA, per-item reads, storage surprises, or older-device overload.',
      },
    );
  }

  void _checkProgressMemory(String progress, List<QaFailure> failures) {
    const requiredTokens = {
      'inventory.cloud_local_mode_contract',
      'focusedRerun',
      'doNotRerunUnless',
      'coveredInputs',
      'focused-validated',
    };
    for (final token in requiredTokens) {
      if (progress.contains(token)) continue;
      failures.add(
        _failure(
          id: 'missing_cloud_local_memory:${_safeId(token)}',
          message: 'Progress memory is missing cloud/local mode QA tracking.',
          expected: token,
          actual: 'not found in $_progressPath',
          fix:
              'Track this QA batch so cloud/local delivery work is not repeated or forgotten.',
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
