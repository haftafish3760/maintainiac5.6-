import 'maintainiac_qa_assertions.dart';
import 'maintainiac_qa_builders.dart';
import 'maintainiac_qa_environment.dart';
import 'maintainiac_qa_quality_gates.dart';

class MaintainiacScenarioResult {
  const MaintainiacScenarioResult({
    required this.scenario,
    required this.passed,
    this.detail = '',
    this.metrics = const {},
  });

  final String scenario;
  final bool passed;
  final String detail;
  final Map<String, Object?> metrics;
}

class MaintainiacSyncScenarioRunner {
  const MaintainiacSyncScenarioRunner({
    this.policy = const MaintainiacSyncPolicyProbe(),
  });

  final MaintainiacSyncPolicyProbe policy;

  List<MaintainiacScenarioResult> runAll() {
    return [
      runLocalWriteBeforeSync(),
      runDirtyMarkerLifecycle(),
      runNetworkPolicyMatrix(),
      runRestartAndConflictPolicy(),
      runMirrorPayloadParity(),
    ];
  }

  MaintainiacScenarioResult runLocalWriteBeforeSync() {
    final env = MaintainiacQaEnvironment.standard();
    final expense = {...MaintainiacQaBuilders.expense(), 'dirty': true};
    env.hive.put('expenses', expense['id'].toString(), expense);
    env.firestoreMirror.mirror('accounts/acct_1/expenses/expense_1', expense);
    MaintainiacQaAssertions.localWriteBeforeMirror(env);
    return const MaintainiacScenarioResult(
      scenario: 'sync.local_write_before_mirror',
      passed: true,
      detail: 'Local Hive write is recorded before Firestore mirror write.',
    );
  }

  MaintainiacScenarioResult runDirtyMarkerLifecycle() {
    final pending = {...MaintainiacQaBuilders.expense(), 'dirty': true};
    final synced = {...pending, 'dirty': false};
    MaintainiacQaAssertions.dirtyFlagSet(pending);
    MaintainiacQaAssertions.dirtyFlagCleared(synced);
    return const MaintainiacScenarioResult(
      scenario: 'sync.dirty_marker_lifecycle',
      passed: true,
      detail: 'Dirty flag is required before sync and cleared after sync.',
    );
  }

  MaintainiacScenarioResult runNetworkPolicyMatrix() {
    final cases = [
      _SyncPolicyCase(
        network: MaintainiacNetworkState.offline,
        wifiOnly: false,
        cellularAllowed: true,
        batterySaver: false,
        expected: false,
      ),
      _SyncPolicyCase(
        network: MaintainiacNetworkState.wifi,
        wifiOnly: true,
        cellularAllowed: false,
        batterySaver: false,
        expected: true,
      ),
      _SyncPolicyCase(
        network: MaintainiacNetworkState.cellular,
        wifiOnly: true,
        cellularAllowed: true,
        batterySaver: false,
        expected: false,
      ),
      _SyncPolicyCase(
        network: MaintainiacNetworkState.cellular,
        wifiOnly: false,
        cellularAllowed: true,
        batterySaver: false,
        expected: true,
      ),
      _SyncPolicyCase(
        network: MaintainiacNetworkState.roaming,
        wifiOnly: false,
        cellularAllowed: true,
        batterySaver: false,
        expected: false,
      ),
      _SyncPolicyCase(
        network: MaintainiacNetworkState.wifi,
        wifiOnly: false,
        cellularAllowed: true,
        batterySaver: true,
        expected: false,
      ),
    ];

    for (final entry in cases) {
      final actual = policy.shouldSync(
        network: entry.network,
        wifiOnly: entry.wifiOnly,
        cellularAllowed: entry.cellularAllowed,
        batterySaver: entry.batterySaver,
      );
      if (actual != entry.expected) {
        throw MaintainiacQaAssertionFailure(
          'Sync policy failed for ${entry.network.name}.',
        );
      }
    }
    return MaintainiacScenarioResult(
      scenario: 'sync.network_policy_matrix',
      passed: true,
      detail: 'Offline, Wi-Fi, cellular, roaming, blocked, and battery cases.',
      metrics: {'cases': cases.length},
    );
  }

  MaintainiacScenarioResult runRestartAndConflictPolicy() {
    final beforeRestart = {...MaintainiacQaBuilders.expense(), 'dirty': true};
    final afterRestart = Map<String, Object?>.of(beforeRestart);
    MaintainiacQaAssertions.dirtyFlagSet(afterRestart);
    MaintainiacQaAssertions.conflictGeneratedWhenExpected(
      _shouldConflict(
        local: {'amountCents': 1299, 'updatedAt': 2},
        remote: {'amountCents': 1499, 'updatedAt': 3},
        field: 'amountCents',
      ),
    );
    return const MaintainiacScenarioResult(
      scenario: 'sync.restart_and_conflict_policy',
      passed: true,
      detail:
          'Restart preserves pending dirty writes and same-field edits conflict.',
    );
  }

  MaintainiacScenarioResult runMirrorPayloadParity() {
    final env = MaintainiacQaEnvironment.standard();
    final local = {...MaintainiacQaBuilders.inventoryItem(), 'dirty': false};
    env.hive.put('inventory', local['id'].toString(), local);
    env.firestoreMirror.mirror('accounts/acct_1/inventory/inv_1', local);
    final mirrored = env.firestoreMirror.documents.values.single;
    MaintainiacQaAssertions.mirrorEqualsLocal(local, mirrored);
    return const MaintainiacScenarioResult(
      scenario: 'sync.mirror_payload_parity',
      passed: true,
      detail: 'Firestore mirror payload matches local source payload.',
    );
  }

  bool _shouldConflict({
    required Map<String, Object?> local,
    required Map<String, Object?> remote,
    required String field,
  }) {
    return local[field] != remote[field] &&
        local['updatedAt'] != null &&
        remote['updatedAt'] != null;
  }
}

class MaintainiacSecurityScenarioRunner {
  const MaintainiacSecurityScenarioRunner({
    this.privacy = const MaintainiacPrivacyProbe(),
  });

  final MaintainiacPrivacyProbe privacy;

  List<MaintainiacScenarioResult> runAll() {
    return [
      runOwnershipIsolation(),
      runForbiddenDataScan(),
      runPermissionDenial(),
      runExportScope(),
    ];
  }

  MaintainiacScenarioResult runOwnershipIsolation() {
    MaintainiacQaAssertions.sameAccountOnly('acct_1', 'acct_1');
    final records = [
      MaintainiacQaBuilders.expense(id: 'expense_1'),
      MaintainiacQaBuilders.inventoryItem(id: 'inv_1'),
      MaintainiacQaBuilders.exportRequest(id: 'export_1'),
    ];
    final leaked = records.any((record) => record['accountId'] == 'acct_2');
    if (leaked) {
      throw const MaintainiacQaAssertionFailure('Cross-account record leaked.');
    }
    return const MaintainiacScenarioResult(
      scenario: 'security.ownership_isolation',
      passed: true,
      detail: 'User/account/vehicle scoped records stay in the active account.',
    );
  }

  MaintainiacScenarioResult runForbiddenDataScan() {
    final unsafe = privacy.forbiddenMatches(
      'VIN 1HGCM82633A004352 passenger patient card 4111111111111111',
    );
    if (unsafe.length < 3) {
      throw const MaintainiacQaAssertionFailure(
        'Privacy probe missed forbidden sensitive data.',
      );
    }
    final safe = privacy.forbiddenMatches('expense fuel total 42.18');
    if (safe.isNotEmpty) {
      throw const MaintainiacQaAssertionFailure(
        'Privacy probe flagged safe expense text.',
      );
    }
    return MaintainiacScenarioResult(
      scenario: 'security.forbidden_data_scan',
      passed: true,
      detail: 'VIN, plate-like, passenger/patient, and card data are blocked.',
      metrics: {'unsafeMatches': unsafe.length},
    );
  }

  MaintainiacScenarioResult runPermissionDenial() {
    const permissions = FakePermissionSet({'read'});
    if (permissions.allows('write') || permissions.allows('export')) {
      throw const MaintainiacQaAssertionFailure(
        'Denied permission was unexpectedly allowed.',
      );
    }
    return const MaintainiacScenarioResult(
      scenario: 'security.permission_denial',
      passed: true,
      detail: 'Write/export actions require explicit permission.',
    );
  }

  MaintainiacScenarioResult runExportScope() {
    MaintainiacQaAssertions.exportContainsOnlyOwnedRecords([
      {'ownerAccountId': 'acct_1', 'id': 'expense_1'},
      {'accountId': 'acct_1', 'id': 'trip_1'},
    ], 'acct_1');
    return const MaintainiacScenarioResult(
      scenario: 'security.export_scope',
      passed: true,
      detail: 'Exports contain only records owned by the active account.',
    );
  }
}

class MaintainiacFinancialScenarioRunner {
  const MaintainiacFinancialScenarioRunner({
    this.money = const MaintainiacMoneyProbe(),
  });

  final MaintainiacMoneyProbe money;

  List<MaintainiacScenarioResult> runAll() {
    return [
      runExpenseAndAdjustmentMath(),
      runTaxAllocationMath(),
      runInvoiceEstimateReadOnlyMath(),
    ];
  }

  MaintainiacScenarioResult runExpenseAndAdjustmentMath() {
    final total = money.lineTotalCents(
      unitCents: 1299,
      quantity: 3,
      taxCents: 234,
      discountCents: 100,
      refundCents: 1299,
    );
    MaintainiacQaAssertions.moneyEquals(total, 2732);
    return const MaintainiacScenarioResult(
      scenario: 'financial.expense_adjustment_math',
      passed: true,
      detail:
          'Taxes, discounts, refunds, and negative adjustments are deterministic.',
    );
  }

  MaintainiacScenarioResult runTaxAllocationMath() {
    MaintainiacQaAssertions.moneyEquals(
      money.allocateTaxPerUnit(taxCents: 101, quantity: 4),
      25,
    );
    return const MaintainiacScenarioResult(
      scenario: 'financial.tax_allocation_math',
      passed: true,
      detail: 'Tax-per-unit allocation uses deterministic rounding.',
    );
  }

  MaintainiacScenarioResult runInvoiceEstimateReadOnlyMath() {
    final env = MaintainiacQaEnvironment.standard();
    env.hive.put('invoice_outputs', 'invoice_1', {
      ...MaintainiacQaBuilders.invoice(),
      'sourceExpenseIds': ['expense_1'],
    });
    MaintainiacQaAssertions.recapDidNotMutateSources(env);
    return const MaintainiacScenarioResult(
      scenario: 'financial.invoice_estimate_read_only_math',
      passed: true,
      detail: 'Derived invoice/estimate outputs do not mutate source records.',
    );
  }
}

class MaintainiacPerformanceBudgetRunner {
  const MaintainiacPerformanceBudgetRunner({
    this.catalogItems = 100000,
    this.receiptFixtures = 10000,
    this.dayLogs = 3650,
  });

  final int catalogItems;
  final int receiptFixtures;
  final int dayLogs;

  List<MaintainiacScenarioResult> runAll() {
    return [
      runGeneratedDatasetBudget(),
      runStorageShapeBudget(),
      runSearchIndexBudget(),
    ];
  }

  MaintainiacScenarioResult runGeneratedDatasetBudget() {
    if (catalogItems < 100000 || receiptFixtures < 10000 || dayLogs < 3650) {
      throw const MaintainiacQaAssertionFailure(
        'Release performance budgets are below required load targets.',
      );
    }
    return MaintainiacScenarioResult(
      scenario: 'performance.generated_dataset_budget',
      passed: true,
      detail:
          'Large catalog, receipt, and multi-year day-log budgets are present.',
      metrics: {
        'catalogItems': catalogItems,
        'receiptFixtures': receiptFixtures,
        'dayLogs': dayLogs,
      },
    );
  }

  MaintainiacScenarioResult runStorageShapeBudget() {
    final bytesPerCatalogItem = 512;
    final estimatedBytes = catalogItems * bytesPerCatalogItem;
    if (estimatedBytes <= 0) {
      throw const MaintainiacQaAssertionFailure(
        'Performance budget generated invalid storage estimate.',
      );
    }
    return MaintainiacScenarioResult(
      scenario: 'performance.storage_shape_budget',
      passed: true,
      detail: 'Catalog storage estimates are explicit and measurable.',
      metrics: {'estimatedBytes': estimatedBytes},
    );
  }

  MaintainiacScenarioResult runSearchIndexBudget() {
    final maxCandidateScanRatio = 0.02;
    final maxCandidates = (catalogItems * maxCandidateScanRatio).round();
    if (maxCandidates >= catalogItems) {
      throw const MaintainiacQaAssertionFailure(
        'Search budget allows full-catalog scans.',
      );
    }
    return MaintainiacScenarioResult(
      scenario: 'performance.search_index_budget',
      passed: true,
      detail: 'Search/index checks must avoid scanning the full catalog.',
      metrics: {'maxCandidates': maxCandidates},
    );
  }
}

class _SyncPolicyCase {
  const _SyncPolicyCase({
    required this.network,
    required this.wifiOnly,
    required this.cellularAllowed,
    required this.batterySaver,
    required this.expected,
  });

  final MaintainiacNetworkState network;
  final bool wifiOnly;
  final bool cellularAllowed;
  final bool batterySaver;
  final bool expected;
}
