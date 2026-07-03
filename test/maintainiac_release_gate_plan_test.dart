import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('release gate plan exposes release blocker and core command plan', () {
    final plan = MaintainiacReleaseGatePlan.releaseOne();

    expect(plan.validate(), isEmpty);
    expect(plan.requiredCases, hasLength(greaterThanOrEqualTo(10)));
    expect(
      plan.commands,
      contains(
        'flutter test test/maintainiac_qa_backbone_test.dart --plain-name "main Maintainiac QA backbone covers whole app modules"',
      ),
    );
    expect(
      plan.commands,
      contains(
        'flutter test test/maintainiac_financial_ledger_test.dart --plain-name "financial ledger probe totals expenses deterministically"',
      ),
    );
    expect(plan.toJson().toString(), contains('release_one_core_gate'));
    expect(plan.toJson().toString(), contains('QA-MUTATION-001'));
    expect(plan.toJson().toString(), contains('QA-A11Y-L10N-001'));
    expect(plan.toJson().toString(), contains('QA-COST-001'));
    expect(
      plan.requiredCases
          .where((qaCase) => qaCase.priority == MaintainiacQaCasePriority.core)
          .every((qaCase) => qaCase.testCommand.contains(' --plain-name ')),
      isTrue,
    );
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
      contains('QA-BAD-001 required case missing command'),
    );
  });

  test('release gate plan requires surgical commands for release blockers', () {
    const plan = MaintainiacReleaseGatePlan(
      name: 'bad_blocker_command',
      registry: MaintainiacQaCaseRegistry([
        MaintainiacQaCase(
          id: 'QA-BAD-BLOCKER-001',
          title: 'Bad blocker command',
          module: MaintainiacQaModule.security,
          behavior: 'This blocker uses a broad chained Flutter command.',
          evidenceTarget: 'bad_blocker_test',
          priority: MaintainiacQaCasePriority.releaseBlocker,
          testCommand:
              'flutter test test/one_test.dart test/two_test.dart --plain-name "one behavior" && flutter test test/three_test.dart',
          tags: {'security'},
        ),
      ]),
      requiredPriorities: {MaintainiacQaCasePriority.releaseBlocker},
    );

    final failures = plan.validate().join('\n');

    expect(
      failures,
      contains(
        'QA-BAD-BLOCKER-001 required Flutter command must target one test file',
      ),
    );
    expect(
      failures,
      contains('QA-BAD-BLOCKER-001 required command must not be chained'),
    );
  });

  test('release gate plan requires surgical commands for core checks', () {
    const plan = MaintainiacReleaseGatePlan(
      name: 'bad_core',
      registry: MaintainiacQaCaseRegistry([
        MaintainiacQaCase(
          id: 'QA-BAD-CORE-001',
          title: 'Bad core',
          module: MaintainiacQaModule.performance,
          behavior: 'This core check uses a broad file command.',
          evidenceTarget: 'bad_core_test',
          priority: MaintainiacQaCasePriority.core,
          testCommand: 'flutter test test/bad_core_test.dart',
          tags: {'core'},
        ),
      ]),
      requiredPriorities: {MaintainiacQaCasePriority.core},
    );

    expect(
      plan.validate(),
      contains(
        'QA-BAD-CORE-001 required Flutter command must use --plain-name',
      ),
    );
  });
}
