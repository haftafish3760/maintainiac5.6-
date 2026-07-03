import 'maintainiac_qa_environment.dart';
import 'maintainiac_qa_execution_manifest.dart';
import 'maintainiac_qa_fingerprint.dart';
import 'maintainiac_qa_fixtures.dart';
import 'maintainiac_qa_checkpoint_policy.dart';
import 'maintainiac_qa_quality_gates.dart';
import 'maintainiac_qa_readiness.dart';
import 'maintainiac_qa_run_ledger.dart';
import 'maintainiac_qa_case_registry.dart';
import 'maintainiac_regression_registry.dart';
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

    return timer.finish(
      suite: name,
      checked: 126,
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
