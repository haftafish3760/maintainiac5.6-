import 'maintainiac_qa_environment.dart';
import 'maintainiac_qa_fixtures.dart';
import 'maintainiac_qa_quality_gates.dart';
import 'maintainiac_qa_readiness.dart';
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

    return timer.finish(
      suite: name,
      checked: 90,
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
