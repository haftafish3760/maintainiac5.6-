import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('restart lifecycle gate covers offline and partial-sync recovery', () {
    const gate = maintainiacRestartLifecycleGate;

    expect(gate.validate(), isEmpty);
    expect(gate.toJson()['scenarioCount'], greaterThanOrEqualTo(5));
    expect(
      gate.toJson().toString(),
      contains('expense_draft_restart_recovery'),
    );
    expect(gate.toJson().toString(), contains('partial_sync_restart_recovery'));
    expect(
      gate.toJson().toString(),
      contains('parser_review_restart_recovery'),
    );
  });

  test('restart lifecycle gate rejects unsafe recovery scenarios', () {
    const gate = MaintainiacRestartLifecycleGate([
      MaintainiacRestartLifecycleScenario(
        id: 'bad',
        module: 'expenses',
        stages: {MaintainiacRestartLifecycleStage.draftCreated},
        mustRecoverLocalState: false,
        mustPreserveReviewState: false,
        mustAvoidSilentOverwrite: false,
        expectedOutcome: '',
      ),
    ]);

    final failures = gate.validate().join('\n');

    expect(failures, contains('bad must include app kill and restart stages'));
    expect(failures, contains('bad must recover local state'));
    expect(failures, contains('bad must avoid silent overwrite'));
    expect(failures, contains('bad missing expected outcome'));
    expect(
      failures,
      contains('restart lifecycle gate missing module inventory'),
    );
  });
}
