import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('fixture governance gate covers release fixture families', () {
    const gate = maintainiacFixtureGovernanceGate;

    expect(gate.validate(), isEmpty);
    expect(gate.toJson()['ruleCount'], greaterThanOrEqualTo(7));
    expect(gate.repoBlockedRules(), hasLength(1));
    expect(
      gate.toJson().toString(),
      contains('bug_regression_fixture_governance'),
    );
    expect(gate.toJson().toString(), contains('redactionProof'));
  });

  test('fixture governance gate rejects private or weak fixture rules', () {
    const gate = MaintainiacFixtureGovernanceGate([
      MaintainiacFixtureGovernanceRule(
        id: 'bad_private',
        fixtureFamily: 'parser',
        pathRoot: 'C:/Users/rjenk/private',
        owner: '',
        privacyLevel: MaintainiacFixturePrivacyLevel.privateBlocked,
        reviewCadence: MaintainiacFixtureReviewCadence.perChange,
        allowedInRepo: true,
        requiredMetadata: {'id'},
      ),
      MaintainiacFixtureGovernanceRule(
        id: 'bad_real',
        fixtureFamily: 'expense',
        pathRoot: 'test/fixtures/expense_receipts',
        owner: 'qa',
        privacyLevel: MaintainiacFixturePrivacyLevel.redactedReal,
        reviewCadence: MaintainiacFixtureReviewCadence.perRelease,
        allowedInRepo: true,
        requiredMetadata: {
          'id',
          'owner',
          'module',
          'reviewedAt',
          'expectedBehavior',
        },
      ),
    ]);

    final failures = gate.validate().join('\n');

    expect(
      failures,
      contains('fixture path must stay under test fixtures/support'),
    );
    expect(failures, contains('bad_private missing owner'));
    expect(
      failures,
      contains('bad_private needs rich fixture metadata requirements'),
    );
    expect(
      failures,
      contains('bad_private private fixtures must not be allowed in repo'),
    );
    expect(
      failures,
      contains('bad_real redacted real fixtures need redaction proof'),
    );
    expect(
      failures,
      contains('fixture governance missing family sync_conflict'),
    );
  });
}
