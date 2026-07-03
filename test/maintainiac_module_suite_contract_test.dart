import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('module suite matrix labels release-one module QA coverage', () {
    final matrix = MaintainiacModuleSuiteMatrix.releaseOnePlan();

    expect(matrix.validate(), isEmpty);
    expect(matrix.suites, hasLength(greaterThanOrEqualTo(9)));
    expect(
      matrix.executableCommands(),
      contains('flutter test test/maintainiac_pricing_contract_test.dart'),
    );
    expect(matrix.toJson().toString(), contains('suite_inventory_parser'));
    expect(matrix.toJson().toString(), contains('suite_payments'));
  });

  test(
    'module suite matrix distinguishes executable scaffolded and planned work',
    () {
      final matrix = MaintainiacModuleSuiteMatrix.releaseOnePlan();

      expect(
        matrix.suites.where(
          (suite) => suite.status == MaintainiacModuleSuiteStatus.executable,
        ),
        isNotEmpty,
      );
      expect(
        matrix.suites.where(
          (suite) => suite.status == MaintainiacModuleSuiteStatus.scaffolded,
        ),
        isNotEmpty,
      );
      expect(
        matrix.suites.where(
          (suite) => suite.status == MaintainiacModuleSuiteStatus.planned,
        ),
        isNotEmpty,
      );
    },
  );

  test('module suite matrix rejects unsafe or unlabeled suites', () {
    const matrix = MaintainiacModuleSuiteMatrix([
      MaintainiacModuleSuiteContract(
        id: 'bad_suite',
        module: MaintainiacQaModule.expenses,
        label: '',
        owner: '',
        status: MaintainiacModuleSuiteStatus.executable,
        priority: MaintainiacQaCasePriority.releaseBlocker,
        command: 'dart test bad',
        behaviors: [''],
        liveServicesAllowed: true,
        firebaseWritesAllowed: true,
      ),
    ]);

    final failures = matrix.validate().join('\n');

    expect(failures, contains('missing label'));
    expect(failures, contains('missing owner'));
    expect(failures, contains('blank behavior'));
    expect(failures, contains('needs searchable tags'));
    expect(failures, contains('must not allow live services'));
    expect(failures, contains('must not allow Firebase writes'));
    expect(
      failures,
      contains('executable suite needs focused flutter test command'),
    );
    expect(failures, contains('module suite matrix missing inventory'));
  });
}
