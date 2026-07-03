import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('QA checkpoint policy pushes at milestones with local changes', () {
    const policy = MaintainiacQaCheckpointPolicy();

    final decision = policy.evaluate(
      now: DateTime.utc(2026, 7, 3, 12, 10),
      lastPushAt: DateTime.utc(2026, 7, 3, 12),
      milestoneReached: true,
      failingGate: false,
      userRequested: false,
      changedFileCount: 7,
    );

    expect(policy.validate(), isEmpty);
    expect(decision.shouldCheckpoint, isTrue);
    expect(decision.reason, MaintainiacQaCheckpointReason.milestone);
    expect(decision.message, contains('Milestone'));
  });

  test('QA checkpoint policy pushes after thirty minutes of changed work', () {
    const policy = MaintainiacQaCheckpointPolicy();

    final decision = policy.evaluate(
      now: DateTime.utc(2026, 7, 3, 12, 31),
      lastPushAt: DateTime.utc(2026, 7, 3, 12),
      milestoneReached: false,
      failingGate: false,
      userRequested: false,
      changedFileCount: 2,
    );

    expect(decision.shouldCheckpoint, isTrue);
    expect(decision.reason, MaintainiacQaCheckpointReason.elapsedTime);
  });

  test('QA checkpoint policy does not push empty or too-fresh batches', () {
    const policy = MaintainiacQaCheckpointPolicy();

    final noChanges = policy.evaluate(
      now: DateTime.utc(2026, 7, 3, 12, 45),
      lastPushAt: DateTime.utc(2026, 7, 3, 12),
      milestoneReached: true,
      failingGate: false,
      userRequested: false,
      changedFileCount: 0,
    );
    final tooFresh = policy.evaluate(
      now: DateTime.utc(2026, 7, 3, 12, 5),
      lastPushAt: DateTime.utc(2026, 7, 3, 12),
      milestoneReached: false,
      failingGate: false,
      userRequested: false,
      changedFileCount: 1,
    );

    expect(noChanges.shouldCheckpoint, isFalse);
    expect(tooFresh.shouldCheckpoint, isFalse);
  });

  test('QA checkpoint policy prioritizes failing gate evidence', () {
    const policy = MaintainiacQaCheckpointPolicy();

    final decision = policy.evaluate(
      now: DateTime.utc(2026, 7, 3, 12, 1),
      lastPushAt: DateTime.utc(2026, 7, 3, 12),
      milestoneReached: false,
      failingGate: true,
      userRequested: false,
      changedFileCount: 1,
    );

    expect(decision.shouldCheckpoint, isTrue);
    expect(decision.reason, MaintainiacQaCheckpointReason.failingGate);
    expect(decision.message, contains('failing evidence'));
  });

  test('QA checkpoint policy rejects unsafe checkpoint windows', () {
    const zeroWindow = MaintainiacQaCheckpointPolicy(
      maxUnpushedWork: Duration.zero,
    );
    const tooLongWindow = MaintainiacQaCheckpointPolicy(
      maxUnpushedWork: Duration(hours: 4),
    );

    expect(
      zeroWindow.validate(),
      contains('checkpoint window must be positive'),
    );
    expect(
      tooLongWindow.validate(),
      contains('checkpoint window must not exceed three hours'),
    );
  });
}
