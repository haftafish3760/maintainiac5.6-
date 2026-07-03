import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('main Maintainiac QA backbone covers whole app modules', () async {
    final report = await const QaHarness(
      domain: 'maintainiac_main',
      suites: [MaintainiacQaBackboneSuite()],
    ).run(const QaContext(strict: true, redactor: QaRedactor()));

    expect(report.failures, isEmpty);
    expect(report.checked, greaterThanOrEqualTo(35));
    expect(report.adminHealth['status'], 'passing');
    expect(report.results.single.metrics['wholeAppBackbone'], isTrue);
    expect(report.results.single.metrics['inventoryIsConsumerOnly'], isTrue);
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
}
