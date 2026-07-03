import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('release gate plan exposes release blocker and core command plan', () {
    final plan = MaintainiacReleaseGatePlan.releaseOne();

    expect(plan.validate(), isEmpty);
    expect(plan.requiredCases, hasLength(greaterThanOrEqualTo(10)));
    expect(
      plan.commands,
      contains('flutter test test/maintainiac_qa_backbone_test.dart'),
    );
    expect(
      plan.commands,
      contains('flutter test test/maintainiac_financial_ledger_test.dart'),
    );
    expect(plan.toJson().toString(), contains('release_one_core_gate'));
    expect(plan.toJson().toString(), contains('QA-MUTATION-001'));
  });

  test('release gate plan rejects missing name or priorities', () {
    const plan = MaintainiacReleaseGatePlan(
      name: '',
      registry: MaintainiacQaCaseRegistry([]),
      requiredPriorities: {},
    );

    expect(plan.validate(), contains('release gate missing name'));
    expect(
      plan.validate(),
      contains('release gate missing required priorities'),
    );
    expect(plan.validate(), contains('release gate has no required cases'));
  });

  test('release gate plan requires commands for release blockers', () {
    const plan = MaintainiacReleaseGatePlan(
      name: 'bad',
      registry: MaintainiacQaCaseRegistry([
        MaintainiacQaCase(
          id: 'QA-BAD-001',
          title: 'Bad blocker',
          module: MaintainiacQaModule.expenses,
          behavior: 'This blocker lacks a command.',
          evidenceTarget: 'bad_test',
          priority: MaintainiacQaCasePriority.releaseBlocker,
        ),
      ]),
      requiredPriorities: {MaintainiacQaCasePriority.releaseBlocker},
    );

    expect(
      plan.validate(),
      contains('QA-BAD-001 release blocker missing command'),
    );
  });
}
