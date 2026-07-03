import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('QA run ledger skips only unchanged clean focused commands', () {
    final ledger = MaintainiacQaRunLedger([
      MaintainiacQaRunRecord(
        id: 'run_001',
        label: 'Inventory parser fixture runner',
        command:
            'flutter test test/work_supply_parser_generated_fixture_runner_test.dart '
            '--plain-name "inventory parser generated fixtures"',
        inputSignature: 'inventory-fixtures-v1',
        startedAt: DateTime.utc(2026, 7, 3, 12),
        completedAt: DateTime.utc(2026, 7, 3, 12, 2),
        status: MaintainiacQaRunStatus.passed,
        exitCode: 0,
        gitCommit: '757dd71',
        scope: [
          'test/work_supply_parser_generated_fixture_runner_test.dart',
          'test/fixtures/work_supply_parser/golden_fixtures.json',
        ],
        reportPath: 'build/qa/reports/run_001.json',
      ),
    ]);

    expect(ledger.validate(), isEmpty);
    expect(
      ledger.canSkip(
        command:
            'flutter test test/work_supply_parser_generated_fixture_runner_test.dart '
            '--plain-name "inventory parser generated fixtures"',
        inputSignature: 'inventory-fixtures-v1',
      ),
      isTrue,
    );
    expect(
      ledger.canSkip(
        command:
            'flutter test test/work_supply_parser_generated_fixture_runner_test.dart',
        inputSignature: 'inventory-fixtures-v2',
      ),
      isFalse,
    );
  });

  test(
    'QA run ledger keeps failed commands actionable before new feature work',
    () {
      final ledger = MaintainiacQaRunLedger([
        MaintainiacQaRunRecord(
          id: 'run_failed_001',
          label: 'Sync source-of-truth guard',
          command:
              'flutter test test/maintainiac_sync_lifecycle_test.dart '
              '--plain-name "sync lifecycle keeps local dirty before mirror"',
          inputSignature: 'sync-lifecycle-v1',
          startedAt: DateTime.utc(2026, 7, 3, 13),
          completedAt: DateTime.utc(2026, 7, 3, 13, 1),
          status: MaintainiacQaRunStatus.failed,
          exitCode: 1,
          scope: ['test/maintainiac_sync_lifecycle_test.dart'],
          actionableSummary:
              'Local write ordering regressed; fix before adding sync features.',
        ),
      ]);

      expect(ledger.validate(), isEmpty);
      expect(ledger.failuresNeedingFix(), hasLength(1));
      expect(
        ledger.failuresNeedingFix().single.actionableSummary,
        contains('fix before adding'),
      );
    },
  );

  test('QA run ledger rejects weak or misleading run evidence', () {
    final ledger = MaintainiacQaRunLedger([
      MaintainiacQaRunRecord(
        id: 'run_bad_001',
        label: '',
        command: 'flutter test test/example_test.dart',
        inputSignature: '',
        startedAt: DateTime.utc(2026, 7, 3, 14),
        status: MaintainiacQaRunStatus.passed,
        exitCode: 1,
      ),
    ]);

    final failures = ledger.validate().join('\n');

    expect(failures, contains('missing label'));
    expect(failures, contains('missing input signature'));
    expect(failures, contains('missing source scope'));
    expect(failures, contains('terminal run missing completedAt'));
    expect(failures, contains('passed run must have exitCode 0'));
  });

  test('QA run ledger rejects broad or chained commands', () {
    final ledger = MaintainiacQaRunLedger([
      MaintainiacQaRunRecord(
        id: 'run_bad_command',
        label: 'Unsafe batch command',
        command:
            'flutter test test/maintainiac_sync_lifecycle_test.dart && flutter test test/other_test.dart',
        inputSignature: 'sync-lifecycle-v1',
        startedAt: DateTime.utc(2026, 7, 3, 15),
        completedAt: DateTime.utc(2026, 7, 3, 15, 1),
        status: MaintainiacQaRunStatus.passed,
        exitCode: 0,
        scope: ['test/maintainiac_sync_lifecycle_test.dart'],
      ),
      MaintainiacQaRunRecord(
        id: 'run_bad_multi_file',
        label: 'Unsafe multi-file command',
        command:
            'flutter test test/maintainiac_sync_lifecycle_test.dart test/maintainiac_qa_backbone_test.dart --plain-name "sync lifecycle keeps local dirty before mirror"',
        inputSignature: 'sync-lifecycle-v1',
        startedAt: DateTime.utc(2026, 7, 3, 15),
        completedAt: DateTime.utc(2026, 7, 3, 15, 1),
        status: MaintainiacQaRunStatus.passed,
        exitCode: 0,
        scope: ['test/maintainiac_sync_lifecycle_test.dart'],
      ),
    ]);

    final failures = ledger.validate().join('\n');

    expect(failures, contains('run_bad_command must use --plain-name'));
    expect(failures, contains('run_bad_command must not chain commands'));
    expect(
      failures,
      contains('run_bad_multi_file must target exactly one test file'),
    );
  });
}
