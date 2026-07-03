import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('main Maintainiac QA backbone covers whole app modules', () async {
    final report = await const QaHarness(
      domain: 'maintainiac_main',
      suites: [MaintainiacQaBackboneSuite()],
    ).run(const QaContext(strict: true, redactor: QaRedactor()));

    expect(report.failures, isEmpty);
    expect(report.checked, greaterThanOrEqualTo(100));
    expect(report.adminHealth['status'], 'passing');
    expect(report.results.single.metrics['wholeAppBackbone'], isTrue);
    expect(report.results.single.metrics['inventoryIsConsumerOnly'], isTrue);
    final parserAdapters =
        report.results.single.metrics['parserDomainAdapters'] as List<Object?>;
    expect(parserAdapters, hasLength(greaterThanOrEqualTo(3)));
    expect(parserAdapters.toString(), contains('expense_receipt_parser'));
    expect(
      report.results.single.metrics['readiness'].toString(),
      contains('countsByStatus'),
    );
    expect(
      report.results.single.metrics['qaCaseRegistry'].toString(),
      contains('QA-BACKBONE-001'),
    );
    expect(
      report.results.single.metrics['deviceDeliveryMatrix'].toString(),
      contains('legacy_cloud_assist_opt_in'),
    );
    expect(
      report.results.single.metrics['executionManifest'].toString(),
      contains('failureAction'),
    );
    expect(
      report.results.single.metrics['runLedger'].toString(),
      contains('seed_backbone_run'),
    );
    expect(
      report.results.single.metrics['regressionRegistry'].toString(),
      contains('SYN-0001'),
    );
    expect(
      report.results.single.metrics['sourceFingerprint'].toString(),
      contains('qa-backbone-seed'),
    );
    expect(
      report.results.single.metrics['checkpointPolicy'].toString(),
      contains('30'),
    );
    expect(
      report.results.single.metrics['artifactPolicy'].toString(),
      contains('release_gate_report'),
    );
    expect(
      report.results.single.metrics['parserCandidateContract'].toString(),
      contains('seed_inventory_parser_candidate'),
    );
    expect(
      report.results.single.metrics['parserFixtureManifest'].toString(),
      contains('expense_en_us_fuel_core'),
    );
    expect(
      report.results.single.metrics['correctionLearning'].toString(),
      contains('seed_inventory_alias_proposal'),
    );
    expect(
      report.results.single.metrics['localFirstContract'].toString(),
      contains('localHive'),
    );
    expect(
      report.results.single.metrics['syncConflictContract'].toString(),
      contains('seed_expense_total_local_wins'),
    );
    expect(
      report.results.single.metrics['pricingContract'].toString(),
      contains('seed_material_price'),
    );
    expect(
      report.results.single.metrics['moduleSuiteMatrix'].toString(),
      contains('suite_jobs'),
    );
    expect(
      report.results.single.metrics['scheduleContract'].toString(),
      contains('seed_maintenance_reminder'),
    );
    expect(
      report.results.single.metrics['paymentContract'].toString(),
      contains('seed_payment'),
    );
    expect(
      report.results.single.metrics['jobContract'].toString(),
      contains('job_seed_material'),
    );
    expect(
      report.results.single.metrics['inventoryParserConsumer'].toString(),
      contains('locale_spanish_release_one'),
    );
    expect(
      report.results.single.metrics['expenseParserConsumer'].toString(),
      contains('draft_storage_lifecycle'),
    );
    expect(
      report.results.single.metrics['parserConsumerGate'].toString(),
      contains('totalFamilyCount'),
    );
    expect(
      report.results.single.metrics['parserReleaseCommandPlan'].toString(),
      contains('parser_consumer_gate_smoke'),
    );
    expect(
      report.results.single.metrics['parserRegressionBindings'].toString(),
      contains('EXPPARSER-0002'),
    );
    expect(
      report.results.single.metrics['surgicalTestSelectors'].toString(),
      contains('--plain-name'),
    );
    expect(
      report.results.single.metrics['surgicalRerunRouter'].toString(),
      contains('inventory_consumer_contract_changed'),
    );
    expect(
      report.results.single.metrics['surgicalSelectorCoverage'].toString(),
      contains('expectedBehaviorCount'),
    );
    expect(
      report.results.single.metrics['individualTestManifest'].toString(),
      contains('--plain-name'),
    );
    expect(
      report.results.single.metrics['sourceTruthGate'].toString(),
      contains('firestore_mirror_read_only_truth'),
    );
    expect(
      report.results.single.metrics['financialFormulaRegistry'].toString(),
      contains('invoice_grand_total_cents'),
    );
    expect(
      report.results.single.metrics['qaTelemetryPrivacyGate'].toString(),
      contains('parser_diagnostic_redaction'),
    );
    expect(
      report.results.single.metrics['releaseEvidenceBundle'].toString(),
      contains('github_push_checkpoint'),
    );
    expect(
      report.results.single.metrics['fixtureGovernanceGate'].toString(),
      contains('bug_regression_fixture_governance'),
    );
    expect(
      report.results.single.metrics['restartLifecycleGate'].toString(),
      contains('partial_sync_restart_recovery'),
    );
    expect(
      report.results.single.metrics['moduleBoundaryGate'].toString(),
      contains('inventory_parser_lane'),
    );
    expect(
      report.results.single.metrics['scopePolicyMatrix'].toString(),
      contains('vehicle_assignment_denied'),
    );
    expect(
      report.results.single.metrics['performanceBudgetRegistry'].toString(),
      contains('surgical_rerun_router_budget'),
    );
    expect(
      report.results.single.metrics['derivedOutputContract'].toString(),
      contains('invoices_read_sources_write_invoice_output'),
    );
    expect(
      report.results.single.metrics['sensitiveFieldRegistry'].toString(),
      contains('passengerPatient'),
    );
    expect(
      report.results.single.metrics['sourceAuditPolicy'].toString(),
      contains('production_dart_modularity'),
    );
    expect(
      report.results.single.metrics['syncTransportPolicy'].toString(),
      contains('manual_roaming_blocked'),
    );
  });

  test('shared builders cover app records without module-specific fakes', () {
    final records = [
      MaintainiacQaBuilders.user(),
      MaintainiacQaBuilders.account(),
      MaintainiacQaBuilders.profile(),
      MaintainiacQaBuilders.vehicle(),
      MaintainiacQaBuilders.odometerSnapshot(),
      MaintainiacQaBuilders.dayLog(),
      MaintainiacQaBuilders.trip(),
      MaintainiacQaBuilders.tripEvent(),
      MaintainiacQaBuilders.expense(),
      MaintainiacQaBuilders.receipt(),
      MaintainiacQaBuilders.receiptSegment(),
      MaintainiacQaBuilders.ocrResult(),
      MaintainiacQaBuilders.inventoryItem(),
      MaintainiacQaBuilders.catalogItem(),
      MaintainiacQaBuilders.inventoryMovement(),
      MaintainiacQaBuilders.job(),
      MaintainiacQaBuilders.estimate(),
      MaintainiacQaBuilders.invoice(),
      MaintainiacQaBuilders.maintenanceEntry(),
      MaintainiacQaBuilders.calendarEdit(),
      MaintainiacQaBuilders.auditEntry(),
      MaintainiacQaBuilders.syncConflict(),
      MaintainiacQaBuilders.exportRequest(),
      MaintainiacQaBuilders.notificationEvent(),
      MaintainiacQaBuilders.company(),
      MaintainiacQaBuilders.employee(),
      MaintainiacQaBuilders.fleetVehicle(),
    ];

    expect(records, hasLength(27));
    for (final record in records) {
      expect(record['id'], isNotNull);
    }
  });

  test('shared assertions enforce source-of-truth and privacy rules', () {
    final env = MaintainiacQaEnvironment.standard();
    env.hive.put('expenses', 'expense_1', {
      ...MaintainiacQaBuilders.expense(),
      'dirty': true,
    });
    env.firestoreMirror.mirror('accounts/acct_1/expenses/expense_1', {
      ...MaintainiacQaBuilders.expense(),
      'dirty': true,
    });

    MaintainiacQaAssertions.moneyEquals(1050, 1050);
    MaintainiacQaAssertions.odometerIsMonotonic(100, 101);
    MaintainiacQaAssertions.localWriteBeforeMirror(env);
    MaintainiacQaAssertions.dirtyFlagSet({'dirty': true});
    MaintainiacQaAssertions.dirtyFlagCleared({'dirty': false});
    MaintainiacQaAssertions.sameAccountOnly('acct_1', 'acct_1');
    MaintainiacQaAssertions.suggestionStayedSuggestion({
      'reviewStatus': 'suggested',
    });
    MaintainiacQaAssertions.auditTrailComplete([
      MaintainiacQaBuilders.auditEntry(),
    ]);
    MaintainiacQaAssertions.exportContainsOnlyOwnedRecords([
      {'ownerAccountId': 'acct_1'},
    ], 'acct_1');
    MaintainiacQaAssertions.conflictGeneratedWhenExpected(true);
    MaintainiacQaAssertions.regressionMatchedExpected(
      'review',
      'review',
      'INV-0001',
    );
  });

  test('fixture catalog and regression registry reject weak QA evidence', () {
    final fixtureCatalog = MaintainiacFixtureCatalog([
      const MaintainiacFixtureDescriptor(
        id: 'bug_fixture',
        kind: MaintainiacFixtureKind.bugRegression,
        module: 'inventory',
        path: 'test/fixtures/work_supply_parser/golden_fixtures.json',
        owner: 'qa',
        synthetic: true,
        reviewed: true,
        expectedBehavior: 'generic PVC stays review only',
      ),
    ]);
    final registry = MaintainiacRegressionRegistry([
      const MaintainiacRegressionCase(
        bugId: 'INV-0002',
        description: 'Regression fixture proves parser remains conservative.',
        rootCause: 'Dangerous word accepted as a final item.',
        inputFixture: 'bug_fixture',
        expectedBehavior: 'needs review',
        fixedVersion: '2026.07.03',
        area: 'inventory_parser',
        moduleTags: {'inventory', 'parser'},
        permanentTest: 'maintainiac_qa_backbone_test',
      ),
    ]);

    expect(fixtureCatalog.validate(), isEmpty);
    expect(registry.validate(), isEmpty);
  });

  test(
    'quality gate matrix covers release-one sync security money and load',
    () {
      final gates = MaintainiacQualityGateMatrix.releaseOne();
      final sync = const MaintainiacSyncPolicyProbe();
      final money = const MaintainiacMoneyProbe();
      final privacy = const MaintainiacPrivacyProbe();

      expect(gates.validate(), isEmpty);
      expect(
        sync.shouldSync(
          network: MaintainiacNetworkState.wifi,
          wifiOnly: true,
          cellularAllowed: false,
          batterySaver: false,
        ),
        isTrue,
      );
      expect(
        sync.shouldSync(
          network: MaintainiacNetworkState.cellular,
          wifiOnly: true,
          cellularAllowed: true,
          batterySaver: false,
        ),
        isFalse,
      );
      expect(
        sync.shouldSync(
          network: MaintainiacNetworkState.roaming,
          wifiOnly: false,
          cellularAllowed: true,
          batterySaver: false,
        ),
        isFalse,
      );
      expect(
        money.lineTotalCents(
          unitCents: 1000,
          quantity: 2,
          taxCents: 100,
          discountCents: 50,
        ),
        2050,
      );
      expect(money.allocateTaxPerUnit(taxCents: 99, quantity: 3), 33);
      expect(
        privacy.forbiddenMatches('VIN 1HGCM82633A004352 patient John'),
        isNotEmpty,
      );
    },
  );

  test('scenario runners execute release-one QA behavior contracts', () {
    final syncResults = const MaintainiacSyncScenarioRunner().runAll();
    final securityResults = const MaintainiacSecurityScenarioRunner().runAll();
    final financialResults = const MaintainiacFinancialScenarioRunner()
        .runAll();
    final performanceResults = const MaintainiacPerformanceBudgetRunner()
        .runAll();

    final allResults = [
      ...syncResults,
      ...securityResults,
      ...financialResults,
      ...performanceResults,
    ];

    expect(allResults, hasLength(greaterThanOrEqualTo(15)));
    for (final result in allResults) {
      expect(result.passed, isTrue, reason: result.scenario);
      expect(result.scenario, contains('.'));
      expect(result.detail, isNotEmpty);
    }

    expect(
      syncResults.map((result) => result.scenario),
      contains('sync.local_write_before_mirror'),
    );
    expect(
      securityResults.map((result) => result.scenario),
      contains('security.forbidden_data_scan'),
    );
    expect(
      financialResults.map((result) => result.scenario),
      contains('financial.invoice_estimate_read_only_math'),
    );
    expect(
      performanceResults.map((result) => result.scenario),
      contains('performance.search_index_budget'),
    );
  });
}
