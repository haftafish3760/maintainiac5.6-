import 'maintainiac_qa_environment.dart';
import 'maintainiac_qa_execution_manifest.dart';
import 'maintainiac_qa_fingerprint.dart';
import 'maintainiac_qa_fixtures.dart';
import 'maintainiac_qa_checkpoint_policy.dart';
import 'maintainiac_qa_artifact_policy.dart';
import 'maintainiac_qa_quality_gates.dart';
import 'maintainiac_qa_readiness.dart';
import 'maintainiac_qa_run_ledger.dart';
import 'maintainiac_qa_telemetry_privacy_gate.dart';
import 'maintainiac_qa_case_registry.dart';
import 'maintainiac_release_evidence_bundle.dart';
import 'maintainiac_restart_lifecycle_gate.dart';
import 'maintainiac_regression_registry.dart';
import 'maintainiac_derived_output_contract.dart';
import 'maintainiac_expense_parser_consumer_contract.dart';
import 'maintainiac_financial_formula_registry.dart';
import 'maintainiac_fixture_governance_gate.dart';
import 'maintainiac_individual_test_manifest.dart';
import 'maintainiac_parser_candidate_contract.dart';
import 'maintainiac_parser_consumer_gate.dart';
import 'maintainiac_parser_fixture_manifest.dart';
import 'maintainiac_parser_regression_binding.dart';
import 'maintainiac_parser_release_command_plan.dart';
import 'maintainiac_correction_learning_contract.dart';
import 'maintainiac_performance_budget_registry.dart';
import 'maintainiac_local_first_contract.dart';
import 'maintainiac_sync_conflict_contract.dart';
import 'maintainiac_pricing_contract.dart';
import 'maintainiac_inventory_parser_consumer_contract.dart';
import 'maintainiac_module_boundary_gate.dart';
import 'maintainiac_module_suite_contract.dart';
import 'maintainiac_schedule_contract.dart';
import 'maintainiac_payment_contract.dart';
import 'maintainiac_job_contract.dart';
import 'maintainiac_source_truth_gate.dart';
import 'maintainiac_surgical_rerun_router.dart';
import 'maintainiac_surgical_selector_coverage.dart';
import 'maintainiac_surgical_test_selector.dart';
import '../parser_qa_platform/parser_qa_domain_adapter.dart';
import 'qa_harness.dart'
    show QaContext, QaFailure, QaSeverity, QaStopwatch, QaSuite, QaSuiteResult;

const maintainiacQaBackboneModules = {
  MaintainiacQaModule.inventory,
  MaintainiacQaModule.receipts,
  MaintainiacQaModule.ocr,
  MaintainiacQaModule.expenses,
  MaintainiacQaModule.camera,
  MaintainiacQaModule.tripLog,
  MaintainiacQaModule.odometer,
  MaintainiacQaModule.recap,
  MaintainiacQaModule.estimates,
  MaintainiacQaModule.invoices,
  MaintainiacQaModule.jobs,
  MaintainiacQaModule.maintenance,
  MaintainiacQaModule.calendar,
  MaintainiacQaModule.sync,
  MaintainiacQaModule.profiles,
  MaintainiacQaModule.vehicles,
  MaintainiacQaModule.fleet,
  MaintainiacQaModule.employees,
  MaintainiacQaModule.exports,
  MaintainiacQaModule.payments,
  MaintainiacQaModule.security,
  MaintainiacQaModule.privacy,
  MaintainiacQaModule.performance,
};

class MaintainiacQaBackboneSuite extends QaSuite {
  const MaintainiacQaBackboneSuite()
    : super('maintainiac.qa_backbone_contract');

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final env = MaintainiacQaEnvironment.standard();
    if (maintainiacQaBackboneModules.length < 23) {
      failures.add(
        _failure('module_matrix_incomplete', 'Module matrix incomplete.'),
      );
    }
    if (env.firestoreMirror.writes.isNotEmpty) {
      failures.add(
        _failure('mirror_not_empty', 'Fake Firestore must start empty.'),
      );
    }
    if (env.hive.writes.isNotEmpty) {
      failures.add(_failure('hive_not_empty', 'Fake Hive must start empty.'));
    }
    if (!env.device.appCheckValid) {
      failures.add(
        _failure('app_check_invalid', 'Default fake device needs App Check.'),
      );
    }

    final fixtures = MaintainiacFixtureCatalog([
      const MaintainiacFixtureDescriptor(
        id: 'expense_json_smoke',
        kind: MaintainiacFixtureKind.json,
        module: 'expenses',
        path: 'test/fixtures/expenses/expense_smoke.json',
        owner: 'qa',
        synthetic: true,
        reviewed: true,
        expectedBehavior: 'expense total is deterministic',
      ),
      const MaintainiacFixtureDescriptor(
        id: 'inventory_parser_ambiguous_pvc',
        kind: MaintainiacFixtureKind.parser,
        module: 'inventory',
        path: 'test/fixtures/work_supply_parser/golden_fixtures.json',
        owner: 'qa',
        synthetic: true,
        reviewed: true,
        expectedBehavior: 'generic PVC lines require review',
      ),
    ]);
    for (final issue in fixtures.validate()) {
      failures.add(_failure('fixture_catalog_$issue', issue));
    }

    final registry = MaintainiacRegressionRegistry([
      const MaintainiacRegressionCase(
        bugId: 'INV-0001',
        description: 'Generic PVC elbow line was accepted too confidently.',
        rootCause: 'Alias expansion hid original receipt ambiguity.',
        inputFixture: 'inventory_parser_ambiguous_pvc',
        expectedBehavior: 'review or low confidence result',
        fixedVersion: '2026.07.03',
        area: 'inventory_parser',
        moduleTags: {'inventory', 'parser', 'regression'},
        permanentTest: 'work_supply_parser_generated_fixture_runner_test',
      ),
    ]);
    for (final issue in registry.validate()) {
      failures.add(_failure('regression_registry_$issue', issue));
    }

    for (final adapter in parserQaDomainAdapters) {
      for (final issue in adapter.validateContract()) {
        failures.add(_failure('parser_domain_${adapter.domain}_$issue', issue));
      }
      final contract = adapter.toJson();
      if (contract['liveServicesAllowed'] == true ||
          contract['firebaseWritesAllowed'] == true ||
          contract['writesProductionCatalog'] == true) {
        failures.add(
          _failure(
            'parser_domain_${adapter.domain}_unsafe_services',
            '${adapter.domain} parser QA adapter allows live services.',
          ),
        );
      }
    }

    final qualityGates = MaintainiacQualityGateMatrix.releaseOne();
    for (final issue in qualityGates.validate()) {
      failures.add(_failure('quality_gate_$issue', issue));
    }

    final readiness = MaintainiacQaReadinessLedger.currentBackbone();
    for (final issue in readiness.validate()) {
      failures.add(_failure('readiness_$issue', issue));
    }

    final caseRegistry = MaintainiacQaCaseRegistry.backboneSeed();
    for (final issue in caseRegistry.validate()) {
      failures.add(_failure('case_registry_$issue', issue));
    }

    final executionManifest = MaintainiacQaExecutionManifest.releaseOneCore();
    for (final issue in executionManifest.validate()) {
      failures.add(_failure('execution_manifest_$issue', issue));
    }

    final runLedger = MaintainiacQaRunLedger([
      MaintainiacQaRunRecord(
        id: 'seed_backbone_run',
        label: 'Main QA backbone smoke run',
        command: 'flutter test test/maintainiac_qa_backbone_test.dart',
        inputSignature: 'qa-backbone-seed',
        startedAt: DateTime.utc(2026, 7, 3, 12),
        completedAt: DateTime.utc(2026, 7, 3, 12, 1),
        status: MaintainiacQaRunStatus.passed,
        exitCode: 0,
        scope: const [
          'test/maintainiac_qa_backbone_test.dart',
          'test/support/qa_harness',
        ],
        reportPath: 'build/qa/reports/seed_backbone_run.json',
      ),
    ]);
    for (final issue in runLedger.validate()) {
      failures.add(_failure('run_ledger_$issue', issue));
    }

    final fingerprint = const MaintainiacQaFingerprintBuilder().build(
      label: 'qa-backbone-seed',
      files: const [
        MaintainiacQaSourceFile(
          path: 'test/maintainiac_qa_backbone_test.dart',
          content: 'main backbone test',
        ),
        MaintainiacQaSourceFile(
          path: 'test/support/qa_harness',
          content: 'shared qa harness',
        ),
      ],
    );
    const checkpointPolicy = MaintainiacQaCheckpointPolicy();
    for (final issue in checkpointPolicy.validate()) {
      failures.add(_failure('checkpoint_policy_$issue', issue));
    }
    const artifactPolicy = MaintainiacQaArtifactPolicy([
      MaintainiacQaArtifact(
        id: 'release_gate_report',
        kind: MaintainiacQaArtifactKind.report,
        path: 'build/qa/reports/release_gate.json',
        owner: 'maintainiac-qa',
        summary: 'Redacted release gate report artifact.',
        tags: {'release-gate', 'report', 'redacted'},
      ),
      MaintainiacQaArtifact(
        id: 'inventory_parser_fixture_index',
        kind: MaintainiacQaArtifactKind.fixture,
        path: 'test/fixtures/work_supply_parser/golden_fixtures.json',
        owner: 'maintainiac-qa',
        summary: 'Synthetic inventory parser fixture evidence.',
        tags: {'inventory', 'parser', 'fixture'},
      ),
    ]);
    for (final issue in artifactPolicy.validate()) {
      failures.add(_failure('artifact_policy_$issue', issue));
    }
    const parserContract = MaintainiacParserCandidateContract([
      MaintainiacParseCandidate(
        id: 'seed_inventory_parser_candidate',
        domain: 'inventory_parser',
        rawInputHash: 'sha256:seed-inventory',
        normalizedLabel: 'PVC EL 3/4',
        reviewStatus: MaintainiacParserReviewStatus.needsReview,
        confidence: 0.7,
        evidence: {
          'tokens': ['PVC', 'EL', '3/4'],
          'rankedCandidates': ['plumbing', 'electrical'],
        },
        confidenceReasons: ['Ambiguous cross-trade item.'],
        warnings: ['User review required before local write.'],
        missingFields: ['tradeContext'],
        suggestedAction: 'Require user selection.',
      ),
    ]);
    for (final issue in parserContract.validate()) {
      failures.add(_failure('parser_candidate_contract_$issue', issue));
    }
    final fixtureManifest = MaintainiacParserFixtureManifest([
      MaintainiacParserFixtureSet(
        id: 'inventory_en_us_core_ambiguous',
        domain: 'inventory_parser',
        path: 'test/fixtures/work_supply_parser/golden_fixtures.json',
        locale: 'en-US',
        country: 'US',
        owner: 'maintainiac-qa',
        source: MaintainiacParserFixtureSource.synthetic,
        merchant: 'mixed',
        trade: 'plumbing',
        expectedBehavior: 'Ambiguous inventory lines require review.',
        reviewedAt: DateTime.utc(2026, 7, 3),
        tags: const {'inventory', 'parser', 'dangerous-word'},
      ),
      MaintainiacParserFixtureSet(
        id: 'expense_en_us_fuel_core',
        domain: 'expense_receipt_parser',
        path: 'test/fixtures/expenses/fuel_receipts.json',
        locale: 'en-US',
        country: 'US',
        owner: 'maintainiac-qa',
        source: MaintainiacParserFixtureSource.synthetic,
        merchant: 'gas_station',
        trade: 'driver',
        expectedBehavior: 'Fuel receipt totals balance in cents.',
        reviewedAt: DateTime.utc(2026, 7, 3),
        tags: const {'expense', 'fuel', 'money'},
      ),
    ]);
    for (final issue in fixtureManifest.validate()) {
      failures.add(_failure('parser_fixture_manifest_$issue', issue));
    }
    const correctionLearning = MaintainiacCorrectionLearningContract([
      MaintainiacCorrectionProposal(
        id: 'seed_inventory_alias_proposal',
        domain: 'inventory_parser',
        kind: MaintainiacCorrectionProposalKind.alias,
        status: MaintainiacCorrectionProposalStatus.proposed,
        sourceCandidateId: 'seed_inventory_parser_candidate',
        userCorrectionHash: 'sha256:seed-correction',
        proposedChange: 'Propose context-scoped PVC EL alias.',
        reason: 'User correction should create proposal only.',
        tags: {'inventory', 'alias', 'review-required'},
      ),
    ]);
    for (final issue in correctionLearning.validate()) {
      failures.add(_failure('correction_learning_$issue', issue));
    }
    const localFirst = MaintainiacLocalFirstContract([
      MaintainiacWriteStep(
        order: 0,
        target: MaintainiacWriteTarget.localHive,
        collection: 'inventory',
        recordId: 'seed_item',
        sourceOperation: 'confirm_inventory_item',
        mutatesSource: true,
      ),
      MaintainiacWriteStep(
        order: 1,
        target: MaintainiacWriteTarget.firestoreMirror,
        collection: 'inventory',
        recordId: 'seed_item',
        sourceOperation: 'confirm_inventory_item',
        mirrorOnly: true,
      ),
    ]);
    for (final issue in localFirst.validate()) {
      failures.add(_failure('local_first_$issue', issue));
    }
    const syncConflicts = MaintainiacSyncConflictContract([
      MaintainiacSyncConflictCase(
        id: 'seed_expense_total_local_wins',
        collection: 'expenses',
        recordId: 'expense_seed',
        fields: [
          MaintainiacSyncConflictField(
            name: 'totalCents',
            localValue: 1060,
            remoteValue: 1006,
            userConfirmed: true,
            financial: true,
          ),
        ],
        resolution: MaintainiacConflictResolution.localWins,
        reason: 'User-confirmed local financial value outranks mirror.',
      ),
    ]);
    for (final issue in syncConflicts.validate()) {
      failures.add(_failure('sync_conflict_$issue', issue));
    }
    const pricing = MaintainiacPricingContract([
      MaintainiacPricedLine(
        id: 'seed_material_price',
        sourceId: 'inventory_seed',
        unitCostCents: 1000,
        quantity: 2,
        taxCents: 120,
        markupBasisPoints: 1000,
      ),
    ]);
    for (final issue in pricing.validate()) {
      failures.add(_failure('pricing_contract_$issue', issue));
    }
    final moduleSuites = MaintainiacModuleSuiteMatrix.releaseOnePlan();
    for (final issue in moduleSuites.validate()) {
      failures.add(_failure('module_suite_matrix_$issue', issue));
    }
    final schedule = MaintainiacScheduleContract([
      MaintainiacScheduleEntry(
        id: 'seed_job_schedule',
        kind: MaintainiacScheduleKind.job,
        accountId: 'acct_1',
        sourceId: 'job_seed',
        startsAt: DateTime.utc(2026, 7, 3, 13),
        timeZone: 'America/New_York',
        vehicleId: 'vehicle_1',
        auditId: 'AUD-SEED-JOB',
      ),
      MaintainiacScheduleEntry(
        id: 'seed_maintenance_reminder',
        kind: MaintainiacScheduleKind.maintenance,
        accountId: 'acct_1',
        sourceId: 'maintenance_seed',
        startsAt: DateTime.utc(2026, 7, 4, 13),
        timeZone: 'America/New_York',
        vehicleId: 'vehicle_1',
      ),
    ]);
    for (final issue in schedule.validate()) {
      failures.add(_failure('schedule_contract_$issue', issue));
    }
    const payments = MaintainiacPaymentContract([
      MaintainiacPaymentRecord(
        id: 'seed_payment',
        kind: MaintainiacPaymentKind.payment,
        accountId: 'acct_1',
        invoiceId: 'invoice_seed',
        amountCents: 10000,
        method: 'cash',
        auditId: 'AUD-SEED-PAY',
      ),
    ]);
    for (final issue in payments.validate()) {
      failures.add(_failure('payment_contract_$issue', issue));
    }
    const jobs = MaintainiacJobContract(
      jobId: 'job_seed',
      accountId: 'acct_1',
      confirmedEstimateId: 'estimate_seed',
      materials: [
        MaintainiacJobMaterialLine(
          id: 'job_seed_material',
          source: MaintainiacJobMaterialSource.estimate,
          sourceId: 'estimate_line_seed',
          quantity: 1,
          costCents: 1000,
          auditId: 'AUD-SEED-JOB-MAT',
        ),
      ],
      summary: MaintainiacJobSummary(
        jobId: 'job_seed',
        materialTotalCents: 1000,
        derivedFrom: ['job_seed_material'],
      ),
    );
    for (final issue in jobs.validate()) {
      failures.add(_failure('job_contract_$issue', issue));
    }
    for (final issue in maintainiacInventoryParserConsumerContract.validate()) {
      failures.add(_failure('inventory_parser_consumer_$issue', issue));
    }
    for (final issue in maintainiacExpenseParserConsumerContract.validate()) {
      failures.add(_failure('expense_parser_consumer_$issue', issue));
    }
    for (final issue in maintainiacParserConsumerGate.validate()) {
      failures.add(_failure('parser_consumer_gate_$issue', issue));
    }
    for (final issue in maintainiacParserReleaseCommandPlan.validate()) {
      failures.add(_failure('parser_release_command_plan_$issue', issue));
    }
    for (final issue in maintainiacParserRegressionBindingRegistry.validate()) {
      failures.add(_failure('parser_regression_binding_$issue', issue));
    }
    for (final issue in maintainiacSurgicalTestSelectorRegistry.validate()) {
      failures.add(_failure('surgical_test_selector_$issue', issue));
    }
    for (final issue in maintainiacSurgicalRerunRouter.validate()) {
      failures.add(_failure('surgical_rerun_router_$issue', issue));
    }
    for (final issue in maintainiacSurgicalSelectorCoverage.validate()) {
      failures.add(_failure('surgical_selector_coverage_$issue', issue));
    }
    for (final issue in maintainiacIndividualTestManifest.validate()) {
      failures.add(_failure('individual_test_manifest_$issue', issue));
    }
    for (final issue in maintainiacSourceTruthGate.validate()) {
      failures.add(_failure('source_truth_gate_$issue', issue));
    }
    for (final issue in maintainiacDerivedOutputContract.validate()) {
      failures.add(_failure('derived_output_contract_$issue', issue));
    }
    for (final issue in maintainiacFinancialFormulaRegistry.validate()) {
      failures.add(_failure('financial_formula_registry_$issue', issue));
    }
    for (final issue in maintainiacQaTelemetryPrivacyGate.validate()) {
      failures.add(_failure('qa_telemetry_privacy_gate_$issue', issue));
    }
    for (final issue in maintainiacReleaseEvidenceBundle.validate()) {
      failures.add(_failure('release_evidence_bundle_$issue', issue));
    }
    for (final issue in maintainiacFixtureGovernanceGate.validate()) {
      failures.add(_failure('fixture_governance_gate_$issue', issue));
    }
    for (final issue in maintainiacRestartLifecycleGate.validate()) {
      failures.add(_failure('restart_lifecycle_gate_$issue', issue));
    }
    for (final issue in maintainiacModuleBoundaryGate.validate()) {
      failures.add(_failure('module_boundary_gate_$issue', issue));
    }
    for (final issue in maintainiacPerformanceBudgetRegistry.validate()) {
      failures.add(_failure('performance_budget_registry_$issue', issue));
    }

    return timer.finish(
      suite: name,
      checked: 596,
      failures: failures,
      metrics: {
        'wholeAppBackbone': true,
        'inventoryIsConsumerOnly': true,
        'liveServicesAllowed': false,
        'firebaseWritesAllowed': false,
        'ocrCameraImplementationTouched': false,
        'modules': [
          for (final module in maintainiacQaBackboneModules) module.name,
        ],
        'parserDomainAdapters': [
          for (final adapter in parserQaDomainAdapters) adapter.toJson(),
        ],
        'qaCaseRegistry': caseRegistry.toJson(),
        'executionManifest': executionManifest.toJson(),
        'runLedger': runLedger.toJson(),
        'sourceFingerprint': fingerprint.toJson(),
        'checkpointPolicy': {
          'maxUnpushedMinutes': checkpointPolicy.maxUnpushedWork.inMinutes,
        },
        'artifactPolicy': artifactPolicy.toJson(),
        'parserCandidateContract': parserContract.toJson(),
        'parserFixtureManifest': fixtureManifest.toJson(),
        'correctionLearning': correctionLearning.toJson(),
        'localFirstContract': localFirst.toJson(),
        'syncConflictContract': syncConflicts.toJson(),
        'pricingContract': pricing.toJson(),
        'moduleSuiteMatrix': moduleSuites.toJson(),
        'scheduleContract': schedule.toJson(),
        'paymentContract': payments.toJson(),
        'jobContract': jobs.toJson(),
        'inventoryParserConsumer': maintainiacInventoryParserConsumerContract
            .toJson(),
        'expenseParserConsumer': maintainiacExpenseParserConsumerContract
            .toJson(),
        'parserConsumerGate': maintainiacParserConsumerGate.toJson(),
        'parserReleaseCommandPlan': maintainiacParserReleaseCommandPlan
            .toJson(),
        'parserRegressionBindings': maintainiacParserRegressionBindingRegistry
            .toJson(),
        'surgicalTestSelectors': maintainiacSurgicalTestSelectorRegistry
            .toJson(),
        'surgicalRerunRouter': maintainiacSurgicalRerunRouter.toJson(),
        'surgicalSelectorCoverage': maintainiacSurgicalSelectorCoverage
            .toJson(),
        'individualTestManifest': maintainiacIndividualTestManifest.toJson(),
        'sourceTruthGate': maintainiacSourceTruthGate.toJson(),
        'derivedOutputContract': maintainiacDerivedOutputContract.toJson(),
        'financialFormulaRegistry': maintainiacFinancialFormulaRegistry
            .toJson(),
        'qaTelemetryPrivacyGate': maintainiacQaTelemetryPrivacyGate.toJson(),
        'releaseEvidenceBundle': maintainiacReleaseEvidenceBundle.toJson(),
        'fixtureGovernanceGate': maintainiacFixtureGovernanceGate.toJson(),
        'restartLifecycleGate': maintainiacRestartLifecycleGate.toJson(),
        'moduleBoundaryGate': maintainiacModuleBoundaryGate.toJson(),
        'performanceBudgetRegistry': maintainiacPerformanceBudgetRegistry
            .toJson(),
        'qualityGates': qualityGates.toJson(),
        'readiness': readiness.toJson(),
      },
    );
  }

  QaFailure _failure(String id, String message) {
    return QaFailure(
      suite: name,
      id: id,
      message: message,
      severity: QaSeverity.critical,
    );
  }
}
