import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('source truth gate protects local truth and derived outputs', () {
    const gate = maintainiacSourceTruthGate;

    expect(gate.validate(), isEmpty);
    expect(gate.toJson()['ruleCount'], greaterThanOrEqualTo(10));
    expect(gate.mutableSourceRules(), hasLength(3));
    expect(
      gate.toJson().toString(),
      contains('firestore_mirror_read_only_truth'),
    );
    expect(gate.toJson().toString(), contains('parser_suggestion_review_only'));
    expect(gate.toJson().toString(), contains('invoice_output_read_only'));
  });

  test('source truth gate rejects mirror suggestion and derived mutations', () {
    const gate = MaintainiacSourceTruthGate([
      MaintainiacSourceTruthRule(
        id: 'bad_mirror',
        module: 'sync',
        recordFamily: 'firestore_payload',
        role: MaintainiacSourceTruthRole.mirror,
        allowedToMutateSource: true,
        mustBeUserConfirmed: false,
        reason: 'bad',
      ),
      MaintainiacSourceTruthRule(
        id: 'bad_suggestion',
        module: 'inventory',
        recordFamily: 'candidate',
        role: MaintainiacSourceTruthRole.suggestion,
        allowedToMutateSource: true,
        mustBeUserConfirmed: false,
        reason: 'bad',
      ),
      MaintainiacSourceTruthRule(
        id: 'bad_output',
        module: 'recap',
        recordFamily: 'summary',
        role: MaintainiacSourceTruthRole.derivedOutput,
        allowedToMutateSource: true,
        mustBeUserConfirmed: false,
        reason: 'bad',
      ),
    ]);

    final failures = gate.validate().join('\n');

    expect(
      failures,
      contains('bad_mirror mirror must not mutate source records'),
    );
    expect(
      failures,
      contains(
        'bad_suggestion suggestion cannot mutate source without confirmation',
      ),
    );
    expect(
      failures,
      contains('bad_output derived output must not mutate source records'),
    );
    expect(failures, contains('source truth gate missing module expenses'));
  });
}
